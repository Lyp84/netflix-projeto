
create index idx_conteudo_genero_conteudo_id on conteudo_genero(conteudo_id);

create index idx_conteudo_genero_genero_id on conteudo_genero(genero_id);

create index idx_conteudo_genero_ambos on conteudo_genero(conteudo_id, genero_id);
CREATE INDEX idx_historico_perfil ON historico(perfil_id);
create index idx_historico_conteudo ON historico(conteudo_id);
create index idx_perfil_usuario ON perfil(usuario_id);
create index idx_usuario_email ON usuario(email);
create index idx_conteudo_popularidade on conteudo(popularidade_geral desc);

CREATE INDEX idx_acao_usuario_perfil ON acao_usuario(perfil_id);
create INDEX idx_acao_usuario_conteudo ON acao_usuario(conteudo_id);