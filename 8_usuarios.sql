
-- Usuário 1: Administrador do sistema (total acesso)
create user admin_netflix with password 'Admin@123';
grant all privileges on database postgres to admin_netflix;
grant all on all tables in schema public to admin_netflix;
grant all on all sequences in schema public to admin_netflix;

-- Usuário 2: Aplicativo/serviço 
create user app_netflix with password 'App@456';
GRANT USAGE ON SCHEMA public TO app_netflix;

grant connect on database postgres to app_netflix;
grant select on all tables in schema public to app_netflix;
grant insert, update on historico, acao_usuario to app_netflix;
grant insert on preferencia_perfil to app_netflix;
grant usage on all sequences in schema public to app_netflix;

-- Usuário 3: Relatórios 
create user relatorios_netflix with password 'Report@789';
GRANT USAGE ON SCHEMA public TO relatorios_netflix;
grant connect on database postgres to relatorios_netflix;
grant select on all tables in schema public to relatorios_netflix;
grant select on all sequences in schema public to relatorios_netflix;

create user dev_netflix with password 'Dev@101112';
GRANT USAGE ON SCHEMA public TO dev_netflix;
grant connect on database postgres to dev_netflix;
grant select, insert, update, delete on all tables in schema public to dev_netflix;
grant all on all sequences in schema public to dev_netflix;

grant select on vw_visualizacoes_ativas to app_netflix, relatorios_netflix;


revoke delete on perfil, usuario from app_netflix;
revoke delete on historico from relatorios_netflix;


-- admin_netflix: Acesso total para manutenção do sistema
-- app_netflix: Aplicativo pode registrar visualizações e preferências
-- relatorios_netflix: Apenas consultas para gerar relatórios
-- dev_netflix: Desenvolvedor pode modificar dados para testes