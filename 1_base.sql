create type tipo_midia as enum ('filme', 'série', 'documentário', 'standup');
create type classificacao_indicativa as enum ('L', '10+', '12+', '14+', '16+', '18+'); 
create type nivel_plano as enum ('básico', 'padrao', 'premium');
create type tipo_acao as enum ('iniciar', 'pausar', 'continuar', 'parar', 'concluir');


-- tabela principal de conteudo
create table conteudo (
    id serial primary key,
    titulo varchar(255) not null,
    tipo tipo_midia not null, 
    duracao_segundos integer,
    classificacao classificacao_indicativa not null,
    data_lancamento date,
    popularidade_geral decimal(3,2) default 0.00
);

-- Genero conteudo
create table genero (
    id serial primary key,
    nome varchar(50) unique not null
);

create table conteudo_genero (
    conteudo_id integer references conteudo(id) on delete cascade,
    genero_id integer references genero(id) on delete cascade,
    primary key (conteudo_id, genero_id)
);

-- tabela de usuarios
create table usuario (
    id serial primary key, 
    email varchar(255) unique not null,
    data_cadastro timestamp default current_timestamp,
    plano nivel_plano not null
);
-- perfil
create table perfil (
    id serial primary key,
    usuario_id integer not null references usuario(id) on delete cascade,
    nome varchar(50) not null,
    idade integer not null,
    is_infantil boolean default false,
    idioma_preferido varchar(10) default 'pt',
    unique(usuario_id, nome)
);
-- mapear ações do usuário 

create table acao_usuario (
    id serial primary key,
    perfil_id integer not null references perfil(id) on delete cascade,
    conteudo_id integer not null references conteudo(id) on delete cascade,
    acao tipo_acao not null,  
    porcentagem decimal(5,2) check (porcentagem between 0 and 100),
    data_hora timestamp default current_timestamp
);


-- histórico de visualização 
create table historico (
    id serial primary key,
    perfil_id integer references perfil(id) on delete cascade,
    conteudo_id integer references conteudo(id) on delete cascade,
    data_hora_inicio timestamp not null default current_timestamp,
    data_hora_fim timestamp,
    porcentagem_assistida decimal(5,2) check (porcentagem_assistida between 0 and 100),
    avaliacao integer check (avaliacao between 1 and 5),
    unique(perfil_id, conteudo_id, data_hora_inicio)
);

-- compatibilidade_perfis 
create table compatibilidade_perfis (
    perfil_a_id integer references perfil(id) on delete cascade,
    perfil_b_id integer references perfil(id) on delete cascade,
    score_compatibilidade decimal(5,4) default 0.0000,
    generos_comuns text[], 
    ultima_calculo timestamp default current_timestamp,
    primary key (perfil_a_id, perfil_b_id),
    check (perfil_a_id <> perfil_b_id) 
);


create table preferencia_perfil (
    perfil_id integer references perfil(id) on delete cascade,
    genero_id integer references genero(id) on delete cascade,
    score decimal(5,4) default 0.0000,
    ultima_atualizacao timestamp default current_timestamp,
    primary key (perfil_id, genero_id)
);
