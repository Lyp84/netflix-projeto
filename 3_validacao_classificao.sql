-- FUNÇÃO DE VALIDAÇÃO 
create or replace function fc_validar_classificacao_perfil(
    p_perfil_id integer,
    p_conteudo_id integer
)
returns boolean as $$
declare
    v_idade_perfil integer;
    v_classificacao conteudo.classificacao_indicativa%type;
    v_is_infantil boolean;
    v_min_idade integer;
begin
    -- buscar dados do perfil
    select idade, is_infantil 
    into v_idade_perfil, v_is_infantil
    from perfil 
    where id = p_perfil_id;
    
    if v_idade_perfil is null then
        return false;
    end if;
    
    -- buscar classificação do conteúdo
    select classificacao 
    into v_classificacao
    from conteudo 
    where id = p_conteudo_id;
    
    -- bloqueio de conteudo p perfil infantil
    if v_is_infantil then
        return v_classificacao = 'L';
    end if;

    v_min_idade := case v_classificacao
        when 'L' then 0
        when '10+' then 10
        when '12+' then 12
        when '14+' then 14
        when '16+' then 16
        when '18+' then 18
        else 18 
    end;
    
    return v_idade_perfil >= v_min_idade;
end;
$$ language plpgsql;

-- TRIGGER PARA BLOQUEAR CONTEÚDO INADEQUADO
create or replace function fc_bloquear_conteudo_inadequado()
returns trigger as $$
begin
    -- verifica se o conteúdo existe
    if not exists (select 1 from conteudo where id = new.conteudo_id) then
        raise exception 'Conteúdo não encontrado.';
    end if;
    
    -- verifca se o perfil existe
    if not exists (select 1 from perfil where id = new.perfil_id) then
        raise exception 'Perfil não encontrado.';
    end if;
    
    -- valida classificação indicativa
    if not validar_classificacao_perfil(new.perfil_id, new.conteudo_id) then
        raise exception 'Conteúdo não permitido para este perfil. Classificação inadequada.';
    end if;

    return new;
end;
$$ language plpgsql;

-- TRIGGER CLASSIFICAÇÃO
create trigger trg_validar_classificacao
before insert on historico
for each row
execute function bloquear_conteudo_inadequado();

-- TRIGGER UPDATE CLASSIFICAÇÃO
create trigger trg_validar_classificacao_update
before update on historico
for each row
when (new.conteudo_id <> old.conteudo_id)
execute function bloquear_conteudo_inadequado();


