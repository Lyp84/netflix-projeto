-- view para ver o que está sendo assistido agora
create view vw_visualizacoes_ativas as
select 
    p.nome as perfil,
    c.titulo as conteudo,
    fc_formatar_duracao(c.duracao_segundos) as duracao_total,
    h.porcentagem_assistida || '%' as progresso,
    h.data_hora_inicio as inicio,
    case 
        when h.data_hora_fim is null then 'Em andamento'
        else 'Concluído'
    end as status,
    c.classificacao,
    p.idade
from historico h
join perfil p on p.id = h.perfil_id
join conteudo c on c.id = h.conteudo_id
where h.data_hora_fim is null
   or (h.data_hora_fim > current_timestamp - interval '1 hour' and h.porcentagem_assistida < 100)
order by h.data_hora_inicio desc;

--seleciona filmes e exibe duração
select 
    titulo,
    tipo,
    fc_formatar_duracao_com_segundos_filmes(duracao_segundos) as duracao_formatada  -- SÓ AQUI
from conteudo 
where duracao_segundos between 3600 and 7200 
  and tipo = 'filme';
select 
    c.titulo,
    c.tipo,
    fc_formatar_duracao_com_segundos_filmes(c.duracao_segundos) as duracao_formatada
from conteudo c
join conteudo_genero cg on cg.conteudo_id = c.id
join genero g on g.id = cg.genero_id
where g.nome = 'Terror Sobrenatural'
  and c.tipo = 'filme';

-- Mostra perfil, conteúdo assistido e gêneros
select 
    p.nome as perfil,
    p.idade,
    c.titulo as conteudo_assistido,
    c.tipo,
    c.classificacao,
    string_agg(g.nome, ', ') as generos,
    h.data_hora_inicio as quando_assistiu,
    h.porcentagem_assistida || '%' as progresso
from historico h
join perfil p on p.id = h.perfil_id
join conteudo c on c.id = h.conteudo_id
join conteudo_genero cg on cg.conteudo_id = c.id
join genero g on g.id = cg.genero_id
where h.porcentagem_assistida > 50
group by p.id, p.nome, p.idade, c.id, c.titulo, c.tipo, c.classificacao, 
         h.data_hora_inicio, h.porcentagem_assistida
order by h.data_hora_inicio desc
limit 10;

-- Estatísticas de visualização por perfil
select 
    p.nome as perfil,
    count(h.id) as total_assistidos,
    round(avg(h.porcentagem_assistida), 2) as media_completude,
    round(avg(h.avaliacao), 2) as media_avaliacao,
    sum(case when h.porcentagem_assistida = 100 then 1 else 0 end) as completos,
    min(h.data_hora_inicio) as primeira_visualizacao,
    max(h.data_hora_inicio) as ultima_visualizacao
from perfil p
left join historico h on h.perfil_id = p.id
group by p.id, p.nome
having count(h.id) > 0
order by total_assistidos desc;


-- Conteúdos mais populares por gênero
select 
    g.nome as genero,
    count(distinct c.id) as qtd_conteudos,
    round(avg(c.popularidade_geral), 2) as popularidade_media,
    string_agg(c.titulo, '; ') as exemplos
from genero g
join conteudo_genero cg on cg.genero_id = g.id
join conteudo c on c.id = cg.conteudo_id
group by g.id, g.nome
having count(distinct c.id) >= 2
order by popularidade_media desc, qtd_conteudos desc;


-- Recomendações baseadas em compatibilidade
select 
    p1.nome as perfil,
    p2.nome as perfil_compativel,
    cp.score_compatibilidade * 100 || '%' as compatibilidade,
    string_agg(cp.generos_comuns[g], ', ') as generos_em_comum,
    (select string_agg(c.titulo, ', ') 
     from historico h 
     join conteudo c on c.id = h.conteudo_id 
     where h.perfil_id = p2.id 
     and h.porcentagem_assistida > 80
     and not exists (
         select 1 from historico h2 
         where h2.perfil_id = p1.id 
         and h2.conteudo_id = h.conteudo_id
     )
     limit 3
    ) as sugestoes
from compatibilidade_perfis cp
join perfil p1 on p1.id = cp.perfil_a_id
join perfil p2 on p2.id = cp.perfil_b_id
where cp.score_compatibilidade > 0.5
order by cp.score_compatibilidade desc
limit 10;

