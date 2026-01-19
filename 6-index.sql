
create index idx_conteudo_genero_conteudo_id on conteudo_genero(conteudo_id);

create index idx_conteudo_genero_genero_id on conteudo_genero(genero_id);

create index idx_conteudo_genero_ambos on conteudo_genero(conteudo_id, genero_id);

create index idx_conteudo_genero_ambos_inverso on conteudo_genero(genero_id, conteudo_id);

create index idx_conteudo_popularidade on conteudo(popularidade_geral desc);