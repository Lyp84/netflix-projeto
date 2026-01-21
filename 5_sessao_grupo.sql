create table grupo (
    id serial primary key,
    nome varchar(100) not null,
    usuario_id integer references usuario(id) on delete cascade,
    descricao text
);

create table grupo_membro (
    grupo_id integer references grupo(id) on delete cascade,
    perfil_id integer references perfil(id) on delete cascade,
    data_entrada timestamp default current_timestamp,
    primary key (grupo_id, perfil_id)
);

create table sessao_grupo (
    id serial primary key,
    grupo_id integer references grupo(id) on delete cascade,
    conteudo_id integer references conteudo(id) on delete cascade,
    data_hora_inicio timestamp not null default current_timestamp,
    data_hora_fim timestamp,
    status varchar(20) default 'ativa' check (status in ('ativa', 'concluida', 'cancelada')),
    criador_perfil_id integer references perfil(id),
    unique(grupo_id, conteudo_id)
);

create table sessao_participante (
    sessao_id integer references sessao_grupo(id) on delete cascade,
    perfil_id integer references perfil(id) on delete cascade,
    data_entrada timestamp default current_timestamp,
    data_saida timestamp,
    porcentagem_assistida decimal(5,2) default 0.00,
    primary key (sessao_id, perfil_id)
);

create or replace function fc_criar_sessao_grupo(
    p_grupo_id integer,
    p_conteudo_id integer,
    p_criador_perfil_id integer
)
returns integer as $$
declare
    v_sessao_id integer;
    v_perfil_valido boolean;
begin
    if not exists (
        select 1 from grupo_membro 
        where grupo_id = p_grupo_id 
        and perfil_id = p_criador_perfil_id
    ) then
        raise exception 'Perfil criador não pertence a este grupo.';
    end if;
    
    select fc_validar_classificacao_perfil(p_criador_perfil_id, p_conteudo_id)
    into v_perfil_valido;
    
    if not v_perfil_valido then
        raise exception 'Criador não tem permissão para este conteúdo.';
    end if;
    
    insert into sessao_grupo (
        grupo_id,
        conteudo_id,
        criador_perfil_id,
        status
    ) values (
        p_grupo_id,
        p_conteudo_id,
        p_criador_perfil_id,
        'ativa'
    ) returning id into v_sessao_id;
    
    insert into sessao_participante (sessao_id, perfil_id)
    values (v_sessao_id, p_criador_perfil_id);
    
    return v_sessao_id;
end;
$$ language plpgsql;

create or replace function fc_convidar_para_sessao(
    p_sessao_id integer,
    p_convidante_perfil_id integer,
    p_convidado_perfil_id integer
)
returns boolean as $$
declare
    v_sessao_grupo_id integer;
    v_convidado_no_grupo boolean;
    v_permissao_conteudo boolean;
    v_conteudo_id integer;
begin
    select grupo_id, conteudo_id into v_sessao_grupo_id, v_conteudo_id
    from sessao_grupo 
    where id = p_sessao_id 
    and status = 'ativa';
    
    if v_sessao_grupo_id is null then
        raise exception 'Sessão não encontrada ou não está ativa.';
    end if;
    
    if not exists (
        select 1 from sessao_participante 
        where sessao_id = p_sessao_id 
        and perfil_id = p_convidante_perfil_id
    ) then
        raise exception 'Convidante não é participante desta sessão.';
    end if;
    
    select exists (
        select 1 from grupo_membro 
        where grupo_id = v_sessao_grupo_id 
        and perfil_id = p_convidado_perfil_id
    ) into v_convidado_no_grupo;
    
    if not v_convidado_no_grupo then
        raise exception 'Convidado não pertence ao grupo desta sessão.';
    end if;
    
    select fc_validar_classificacao_perfil(p_convidado_perfil_id, v_conteudo_id)
    into v_permissao_conteudo;
    
    if not v_permissao_conteudo then
        raise exception 'Convidado não tem permissão para este conteúdo.';
    end if;
    
    insert into sessao_participante (sessao_id, perfil_id)
    values (p_sessao_id, p_convidado_perfil_id)
    on conflict (sessao_id, perfil_id) do nothing;
    
    return true;
end;
$$ language plpgsql;

create or replace function fc_registrar_progresso_sessao(
    p_sessao_id integer,
    p_perfil_id integer,
    p_porcentagem decimal
)
returns void as $$
begin
    if not exists (
        select 1 
        from sessao_grupo sg
        join sessao_participante sp on sp.sessao_id = sg.id
        where sg.id = p_sessao_id
        and sg.status = 'ativa'
        and sp.perfil_id = p_perfil_id
        and sp.data_saida is null
    ) then
        raise exception 'Sessão não encontrada ou perfil não participa.';
    end if;
    
    update sessao_participante 
    set porcentagem_assistida = p_porcentagem
    where sessao_id = p_sessao_id 
    and perfil_id = p_perfil_id;
    
    if p_porcentagem = 100.00 then
        if not exists (
            select 1 from sessao_participante
            where sessao_id = p_sessao_id
            and porcentagem_assistida < 100
            and data_saida is null
        ) then
            update sessao_grupo 
            set 
                status = 'concluida',
                data_hora_fim = current_timestamp
            where id = p_sessao_id;
            
            perform fc_registrar_historico_sessao(p_sessao_id);
        end if;
    end if;
end;
$$ language plpgsql;

create or replace function fc_registrar_historico_sessao(p_sessao_id integer)
returns void as $$
declare
    v_conteudo_id integer;
    v_data_inicio timestamp;
    v_data_fim timestamp;
    rec_participante record;
begin
    select conteudo_id, data_hora_inicio, data_hora_fim 
    into v_conteudo_id, v_data_inicio, v_data_fim
    from sessao_grupo 
    where id = p_sessao_id;
    
    for rec_participante in 
        select perfil_id, porcentagem_assistida
        from sessao_participante
        where sessao_id = p_sessao_id
        and porcentagem_assistida > 0
    loop
        insert into historico (
            perfil_id,
            conteudo_id,
            data_hora_inicio,
            data_hora_fim,
            porcentagem_assistida
        ) values (
            rec_participante.perfil_id,
            v_conteudo_id,
            v_data_inicio,
            v_data_fim,
            rec_participante.porcentagem_assistida
        );
        
        perform fc_atualizar_preferencias_perfil(rec_participante.perfil_id);
    end loop;
end;
$$ language plpgsql;

create or replace function trg_sincronizar_sessao()
returns trigger as $$
begin
    if exists (
        select 1 from sessao_participante sp
        join sessao_grupo sg on sg.id = sp.sessao_id
        where sp.perfil_id = new.perfil_id
        and sp.sessao_id = (
            select sessao_id from sessao_participante sp2
            join sessao_grupo sg2 on sg2.id = sp2.sessao_id
            where sp2.perfil_id = new.perfil_id
            and sg2.conteudo_id = new.conteudo_id
            and sg2.status = 'ativa'
            order by sg2.data_hora_inicio desc
            limit 1
        )
    ) then
        update sessao_participante 
        set porcentagem_assistida = new.porcentagem
        where perfil_id = new.perfil_id
        and sessao_id = (
            select sessao_id from sessao_participante sp2
            join sessao_grupo sg2 on sg2.id = sp2.sessao_id
            where sp2.perfil_id = new.perfil_id
            and sg2.conteudo_id = new.conteudo_id
            and sg2.status = 'ativa'
            order by sg2.data_hora_inicio desc
            limit 1
        );
    end if;
    
    return new;
end;
$$ language plpgsql;

create trigger trg_sincroniza_sessao_acao
after insert or update on acao_usuario
for each row
execute function trg_sincronizar_sessao();


create view vw_sessoes_ativas as
select 
    sg.id as sessao_id,
    g.nome as grupo,
    c.titulo as conteudo,
    fc_formatar_duracao(c.duracao_segundos) as duracao,
    c.classificacao,
    p_criador.nome as criador,
    sg.data_hora_inicio,
    count(sp.perfil_id) as participantes,
    string_agg(p.nome, ', ') as lista_participantes,
    round(avg(sp.porcentagem_assistida), 2) as progresso_medio
from sessao_grupo sg
join grupo g on g.id = sg.grupo_id
join conteudo c on c.id = sg.conteudo_id
join perfil p_criador on p_criador.id = sg.criador_perfil_id
left join sessao_participante sp on sp.sessao_id = sg.id
left join perfil p on p.id = sp.perfil_id
where sg.status = 'ativa'
group by sg.id, g.nome, c.titulo, c.duracao_segundos, c.classificacao, 
         p_criador.nome, sg.data_hora_inicio
order by sg.data_hora_inicio desc;

select 
    g.nome as grupo,
    count(sg.id) as total_sessoes,
    count(distinct sg.conteudo_id) as conteudos_diferentes,
    round(avg(
        extract(epoch from (sg.data_hora_fim - sg.data_hora_inicio)) / 60
    ), 1) as duracao_media_minutos,
    round(avg(sp.porcentagem_assistida), 2) as completude_media,
    string_agg(distinct c.titulo, '; ') as conteudos_assistidos
from grupo g
left join sessao_grupo sg on sg.grupo_id = g.id
left join sessao_participante sp on sp.sessao_id = sg.id
left join conteudo c on c.id = sg.conteudo_id
where sg.status = 'concluida'
group by g.id, g.nome
order by total_sessoes desc;
