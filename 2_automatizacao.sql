-- FUNÇÃO FORMATAÇÃO MINUTOS
create or replace function fc_formatar_duracao_com_segundos_filmes(duracao_segundos)
returns VARCHAR(20) as $$
BEGIN
    RETURN concat(
        floor(duracao_segundos / 3600), ':',
        lpad(floor((duracao_segundos % 3600) / 60), 2, '0'), ':',
        LPAD(duracao_segundos % 60, 2, '0'), ':'
    );
    return new;
end;
$$ language plpgsql;
select formatar_duracao_com_segundos_filmes(select duracao_segundos from filmes)

create or replace function fc_assistir_conteudo(
    p_perfil_id integer,
    p_conteudo_id integer,
    p_porcentagem decimal default 100.00,
    p_avaliacao integer default null
)
returns integer as $$
declare
    v_historico_id integer;
begin
    -- validação
    if not fc_validar_classificacao_perfil(p_perfil_id, p_conteudo_id) then
        raise exception 'Conteúdo não permitido para este perfil.';
    end if;
    
    insert into acao_usuario (perfil_id, conteudo_id, acao, porcentagem)
    values (p_perfil_id, p_conteudo_id, 'concluir', p_porcentagem)
    returning id into v_historico_id;
    
    -- atualiza o histórico
    if p_avaliacao is not null then
        update historico 
        set avaliacao = p_avaliacao
        where perfil_id = p_perfil_id 
          and conteudo_id = p_conteudo_id
          and porcentagem_assistida = p_porcentagem
        order by data_hora_inicio desc
        limit 1;
    end if;
    
    return v_historico_id;
end;
$$ language plpgsql;

-- FUNÇÃO AÇAO USUÁRIO 
create or replace function fc_processar_acao_usuario()
returns trigger as $$
declare
    v_historico_id integer;
    v_duracao_total integer;
    v_minutos_assistidos integer;
begin
    -- perfil pode acessar o conteúdo?
    if not fc_validar_classificacao_perfil(new.perfil_id, new.conteudo_id) then
        raise exception 'Perfil não tem permissão para acessar este conteúdo.';
    end if;
    
    if new.acao = 'iniciar' then
        -- verifica historico
        select id into v_historico_id
        from historico 
        where perfil_id = new.perfil_id 
          and conteudo_id = new.conteudo_id
          and data_hora_fim is null  
          and porcentagem_assistida < 100
        order by data_hora_inicio desc 
        limit 1;
        
        if v_historico_id is not null then
            -- verifica historico 
            update historico 
            set data_hora_inicio = new.data_hora
            where id = v_historico_id;
            
        else
            -- cria novo registro de histórico
            insert into historico (
                perfil_id, 
                conteudo_id, 
                data_hora_inicio, 
                porcentagem_assistida
            ) values (
                new.perfil_id, 
                new.conteudo_id, 
                new.data_hora, 
                0.00
            ) returning id into v_historico_id;
            
        end if;
        
    elsif new.acao = 'pausar' then
        -- busca o histórico ativo mais recente
        select id into v_historico_id
        from historico 
        where perfil_id = new.perfil_id 
          and conteudo_id = new.conteudo_id
          and data_hora_fim is null
        order by data_hora_inicio desc 
        limit 1;
        
        if v_historico_id is not null and new.porcentagem is not null then
            -- atualiza com porcentagem atual
            update historico 
            set 
                porcentagem_assistida = new.porcentagem
            where id = v_historico_id;
        end if;
        
    elsif new.acao = 'concluir' then
        -- busca o histórico ativo
        select id into v_historico_id
        from historico 
        where perfil_id = new.perfil_id 
          and conteudo_id = new.conteudo_id
          and data_hora_fim is null
        order by data_hora_inicio desc 
        limit 1;
        
        if v_historico_id is not null then
            -- marca como concluído 
            update historico 
            set 
                data_hora_fim = new.data_hora,
                porcentagem_assistida = 100.00
            where id = v_historico_id;
            
            -- atualiza preferências do perfil
            perform fc_atualizar_preferencias_perfil(new.perfil_id);
            
        end if;
        
    elsif new.acao = 'parar' then
        -- busca o histórico ativo
        select id into v_historico_id
        from historico 
        where perfil_id = new.perfil_id 
          and conteudo_id = new.conteudo_id
          and data_hora_fim is null
        order by data_hora_inicio desc 
        limit 1;
        
        if v_historico_id is not null then
            -- calcula porcentagem baseada no tempo
            select duracao_segundos into v_duracao_total
            from conteudo 
            where id = new.conteudo_id;
            
            if v_duracao_total > 0 and new.porcentagem is null then
                -- calcula automaticamente se não informou porcentagem
                select extract(epoch from (new.data_hora - h.data_hora_inicio)) / v_duracao_total * 100
                into new.porcentagem
                from historico h
                where h.id = v_historico_id;
            end if;
            
            -- atualiza histórico
            update historico 
            set 
                data_hora_fim = new.data_hora,
                porcentagem_assistida = coalesce(new.porcentagem, 0.00)
            where id = v_historico_id;
            
            -- se assistiu mais de 50%, atualiza preferências
            if coalesce(new.porcentagem, 0.00) > 50.00 then
                perform fc_atualizar_preferencias_perfil(new.perfil_id);
            end if;
            
            raise notice 'Visualização interrompida em %%%. Histórico ID: %', 
                         coalesce(new.porcentagem, 0.00), v_historico_id;
        end if;
    end if;
    
    return new;
end;
$$ language plpgsql;

-- cria o trigger
create trigger trg_processar_acao
after insert on acao_usuario
for each row
execute function fc_processar_acao_usuario();