-- função auxiliar para formatação de duração
create or replace function fc_formatar_duracao(duracao_segundos integer)
returns text as $$
begin
    if duracao_segundos is null then
        return '--:--';
    end if;
    
    if duracao_segundos < 3600 then
        return floor(duracao_segundos / 60) || 'min';
    else
        return floor(duracao_segundos / 3600) || 'h ' || 
               lpad(floor((duracao_segundos % 3600) / 60)::text, 2, '0') || 'min';
    end if;
end;
$$ language plpgsql;


create or replace function fc_assistir_conteudo(
    p_perfil_id integer,
    p_conteudo_id integer,
    p_porcentagem decimal default 100.00,
    p_avaliacao integer default null
)
returns integer as $$
declare
    v_historico_id integer;
    v_ultimo_historico_id integer;
begin
    -- validação
    if not fc_validar_classificacao_perfil(p_perfil_id, p_conteudo_id) then
        raise exception 'Conteúdo não permitido para este perfil.';
    end if;
    
    insert into acao_usuario (perfil_id, conteudo_id, acao, porcentagem)
    values (p_perfil_id, p_conteudo_id, 'concluir', p_porcentagem)
    returning id into v_historico_id;
    
    -- atualiza o histórico SE houver avaliação
    if p_avaliacao is not null then
        select id into v_ultimo_historico_id
        from historico 
        where perfil_id = p_perfil_id 
          and conteudo_id = p_conteudo_id
          and porcentagem_assistida = p_porcentagem
        order by data_hora_inicio desc
        limit 1;
        
        if v_ultimo_historico_id is not null then
            update historico 
            set avaliacao = p_avaliacao
            where id = v_ultimo_historico_id;
        end if;
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


--Atualizar preferências automaticamente
create or replace function fc_atualizar_preferencias_perfil(p_perfil_id integer)
returns void as $$
declare
    v_total_assistidos integer;
begin
    -- Primeiro calcula o total
    select count(*) into v_total_assistidos
    from historico 
    where perfil_id = p_perfil_id 
    and porcentagem_assistida > 50;
    
    -- Depois verifica
    IF v_total_assistidos = 0 THEN
        RETURN;
    END IF;
    
    -- limpa preferências antigas
    delete from preferencia_perfil where perfil_id = p_perfil_id;
    
    -- recalcula baseado no histórico
    insert into preferencia_perfil (perfil_id, genero_id, score)
    select 
        h.perfil_id,
        cg.genero_id,
        (count(*) * 1.0 / v_total_assistidos) 
        * coalesce(avg(h.avaliacao/5.0), 0.5)
        * case 
            when max(h.data_hora_fim) > current_timestamp - interval '30 days' 
            then 1.2 else 0.8 
          end as score_final
    from historico h
    join conteudo_genero cg on cg.conteudo_id = h.conteudo_id
    where h.perfil_id = p_perfil_id
    and h.porcentagem_assistida > 50
    group by h.perfil_id, cg.genero_id;
end;
$$ language plpgsql;

--Atualizar preferências quando histórico muda
create or replace function trg_atualizar_preferencias_historico()
returns trigger as $$
begin
    -- Quando um histórico é inserido/atualizado com mais de 50% assistido
    if (new.porcentagem_assistida > 50.00) or 
       (old.porcentagem_assistida <= 50.00 and new.porcentagem_assistida > 50.00) then
        perform fc_atualizar_preferencias_perfil(new.perfil_id);
    end if;
    return new;
end;
$$ language plpgsql;

create trigger trg_historico_atualiza_preferencias
after insert or update of porcentagem_assistida on historico
for each row
execute function trg_atualizar_preferencias_historico();

-- TRIGGER: Atualizar compatibilidade automaticamente
create or replace function trg_atualizar_compatibilidade()
returns trigger as $$
begin
    -- Recalcula compatibilidade para o perfil
    perform fc_atualizar_preferencias_perfil(new.perfil_id);
    return new;
end;
$$ language plpgsql;

--atualizar compatibilidade
create or replace function trg_atualizar_compatibilidade()
returns trigger as $$
begin
    -- Recalcula compatibilidade apenas para o perfil afetado
    perform fc_atualizar_preferencias_perfil(new.perfil_id);
    
    update compatibilidade_perfis cp
    set 
        score_compatibilidade = (
            select round(avg(pp1.score * pp2.score), 4)
            from preferencia_perfil pp1
            join preferencia_perfil pp2 on pp1.genero_id = pp2.genero_id
            where pp1.perfil_id = cp.perfil_a_id
            and pp2.perfil_id = cp.perfil_b_id
        ),
        generos_comuns = (
            select array_agg(g.nome)
            from preferencia_perfil pp1
            join preferencia_perfil pp2 on pp1.genero_id = pp2.genero_id
            join genero g on g.id = pp1.genero_id
            where pp1.perfil_id = cp.perfil_a_id
            and pp2.perfil_id = cp.perfil_b_id
            and pp1.score > 0.3
            and pp2.score > 0.3
        ),
        ultima_calculo = current_timestamp
    where cp.perfil_a_id = new.perfil_id 
       or cp.perfil_b_id = new.perfil_id;
    
    return new;
end;
$$ language plpgsql;

--trigger
create trigger trg_preferencia_atualiza_compatibilidade
after insert or update on preferencia_perfil
for each row
execute function trg_atualizar_compatibilidade();


--histórico de mudanças
create table log_acao_usuario (
    id serial primary key,
    acao_usuario_id integer references acao_usuario(id),
    perfil_id integer,
    conteudo_id integer,
    acao_antiga tipo_acao,
    acao_nova tipo_acao,
    porcentagem_antiga decimal(5,2),
    porcentagem_nova decimal(5,2),
    data_modificacao timestamp default current_timestamp,
    usuario_modificacao varchar(50)
);

create or replace function trg_log_acao_usuario()
returns trigger as $$
begin
    insert into log_acao_usuario (
        acao_usuario_id, perfil_id, conteudo_id,
        acao_antiga, acao_nova,
        porcentagem_antiga, porcentagem_nova,
        usuario_modificacao
    ) values (
        new.id, new.perfil_id, new.conteudo_id,
        old.acao, new.acao,
        old.porcentagem, new.porcentagem,
        current_user
    );
    return new;
end;
$$ language plpgsql;

create trigger trg_log_modificacoes_acao
after insert or update on acao_usuario
for each row
execute function trg_log_acao_usuario();