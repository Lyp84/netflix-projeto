-- CONTEUDO

insert into conteudo (titulo, tipo, duracao_segundos, classificacao, data_lancamento, popularidade_geral) values
-- Filmes
('O Poderoso Chefão', 'filme', 10500, '16+', '1972-03-24', 9.2),  -- 2h55min
('Parasita', 'filme', 7920, '16+', '2019-05-30', 8.6),  -- 2h12min
('Cidade de Deus', 'filme', 7800, '18+', '2002-08-30', 8.6),  -- 2h10min
('Toy Story', 'filme', 4860, 'L', '1995-11-22', 8.3),  -- 1h21min
('O Labirinto do Fauno', 'filme', 7140, '16+', '2006-10-20', 8.2),  -- 1h59min

-- Séries
('Stranger Things', 'série', 3600, '16+', '2016-07-15', 8.7),  -- 1h por episódio
('La Casa de Papel', 'série', 3300, '18+', '2017-05-02', 8.2),  -- 55min por episódio
('The Crown', 'série', 3600, '14+', '2016-11-04', 8.6),  -- 1h por episódio
('Round 6', 'série', 4500, '18+', '2021-09-17', 8.0),  -- 1h15min por episódio
('Dark', 'série', 4500, '16+', '2017-12-01', 8.8),  -- 1h15min por episódio

-- Documentários
('Meu Amigo Totoro', 'documentário', 5160, 'L', '1988-04-16', 8.2),  -- 1h26min
('13ª Emenda', 'documentário', 6000, '14+', '2016-09-30', 8.2),  -- 1h40min
('Amy', 'documentário', 7680, '12+', '2015-05-16', 7.8),  -- 2h08min
('O Dilema das Redes', 'documentário', 5640, '12+', '2020-09-09', 7.6),  -- 1h34min

-- Standups
('Rafael Portugal: Pode Rir', 'standup', 3420, '14+', '2021-11-25', 7.5),  -- 57min
('Whindersson: Adulto?', 'standup', 4500, '14+', '2023-03-10', 7.8),  -- 1h15min
('Afonso Padilha: A Vida é Bela', 'standup', 3900, '16+', '2022-06-15', 7.9),  -- 1h05min
('Thiago Ventura: Pisa na Fulô', 'standup', 3600, '18+', '2023-08-20', 8.0),  -- 1h
('Paulo Vieira: Hora do Rush', 'standup', 3300, '16+', '2022-12-05', 7.7);  -- 55min

-- USUÁRIOS 
insert into usuario (email, plano, data_cadastro) values
('familia.silva@email.com', 'premium', '2023-01-15 10:30:00'),
('familia.oliveira@email.com', 'premium', '2023-03-20 14:15:00'),
('familia.santos@email.com', 'padrao', '2023-06-10 09:45:00'),
('familia.costa@email.com', 'padrao', '2023-08-05 16:20:00'),
('familia.pereira@email.com', 'básico', '2023-11-12 11:30:00'),

('joao.individual@email.com', 'básico', '2024-01-10 08:15:00'),
('maria.solteira@email.com', 'padrao', '2024-01-25 13:40:00'),
('carlos.gamer@email.com', 'premium', '2024-02-05 19:20:00'),
('ana.professora@email.com', 'padrao', '2024-02-18 10:10:00'),
('pedro.estudante@email.com', 'básico', '2024-03-01 15:30:00'),

('casal.ribeiro@email.com', 'premium', '2024-01-08 12:00:00'),
('casal.almeida@email.com', 'padrao', '2024-02-14 20:00:00'),


('amigos.faculdade@email.com', 'premium', '2023-09-15 17:25:00'),
('salao.empresa@email.com', 'padrao', '2023-12-01 09:00:00'),
('grupo.esportes@email.com', 'básico', '2024-01-20 18:45:00');


-- PERFIL
insert into perfil (usuario_id, nome, idade, is_infantil) values
(1, 'Carlos Silva', 42, false),
(1, 'Ana Silva', 38, false),
(1, 'Pedro Silva', 15, false),
(1, 'Luiza Silva', 8, true);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(2, 'Roberto Oliveira', 45, false),
(2, 'Cláudia Oliveira', 40, false),
(2, 'Lucas Oliveira', 10, true);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(3, 'Fernando Santos', 35, false),
(3, 'Patrícia Santos', 32, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(4, 'Miguel Costa', 50, false),
(4, 'Sofia Costa', 48, false),
(4, 'Gabriel Costa', 16, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(5, 'Antônio Pereira', 65, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(6, 'João Mendes', 28, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(7, 'Maria Souza', 25, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(8, 'Carlos Lima', 22, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(9, 'Ana Rodrigues', 35, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(10, 'Pedro Alves', 19, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(11, 'Ricardo Ribeiro', 40, false),
(11, 'Camila Ribeiro', 38, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(12, 'Marcos Almeida', 30, false),
(12, 'Juliana Almeida', 29, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(13, 'Bruno Faculdade', 21, false),
(13, 'Paula Faculdade', 22, false),
(13, 'André Faculdade', 20, false);

insert into perfil (usuario_id, nome, idade, is_infantil) values
(14, 'Recepção Empresa', 99, false),
(14, 'Sala Reunião', 99, false);      

insert into perfil (usuario_id, nome, idade, is_infantil) values
(15, 'Academia Central', 99, false);





insert into genero (nome, descricao) values
('suspense psicológico', 'suspense focado em tensão mental'),
('comédia romântica adolescente', 'comédias leves com romance juvenil'),
('drama familiar emocionante', 'dramas focados em relações familiares'),
('ficção científica distópica', 'futuros alternativos sombrios'),
('documentário true crime', 'documentários sobre crimes reais'),
('anime shonen', 'anime voltado para público jovem masculino'),
('reality show culinário', 'competições de culinária'),
('stand-up brasileiro', 'comédia stand-up de comediantes brasileiros'),
('drama histórico', 'dramas baseados em eventos históricos'),
('thriller de ação', 'filmes de ação com muita tensão'),
('animação infantil', 'animação para crianças'),
('documentário político', 'documentários sobre política'),
('série de fantasia', 'séries com elementos fantásticos'),
('comédia dramática', 'mistura de comédia e drama'),
('terror sobrenatural', 'filmes de terror com elementos sobrenaturais');