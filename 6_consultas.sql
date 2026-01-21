create view vw_visualizacoes_ativas as
select 
    p.nome as perfil,
    c.titulo as conteudo,
    fc_formatar_duracao(c.duracao_segundos) as duracao_total,
    h.porcentagem_assistida || '%' as progresso,
    h.data_hora_inicio as inicio,
    case 
        when h.data_hora_fim is null then 'em andamento'
        else 'concluído'
    end as status,
    c.classificacao,
    p.idade
from historico h
join perfil p on p.id = h.perfil_id
join conteudo c on c.id = h.conteudo_id
where h.data_hora_fim is null
   or (h.data_hora_fim > current_timestamp - interval '1 hour' and h.porcentagem_assistida < 100)
order by h.data_hora_inicio desc;

create view vw_conteudos_populares as
select 
    c.id,
    c.titulo,
    c.tipo,
    c.classificacao,
    fc_formatar_duracao(c.duracao_segundos) as duracao,
    c.popularidade_geral,
    count(distinct h.id) as total_visualizacoes,
    round(avg(h.avaliacao), 2) as avaliacao_media,
    string_agg(distinct g.nome, ', ') as generos
from conteudo c
left join historico h on h.conteudo_id = c.id
left join conteudo_genero cg on cg.conteudo_id = c.id
left join genero g on g.id = cg.genero_id
group by c.id, c.titulo, c.tipo, c.classificacao, c.duracao_segundos, c.popularidade_geral
order by c.popularidade_geral desc, total_visualizacoes desc;

select 
    u.id as usuario_id,
    u.email,
    u.plano,
    u.data_cadastro,
    count(p.id) as qtd_perfis,
    string_agg(p.nome, ', ') as perfis,
    sum(case when p.is_infantil then 1 else 0 end) as perfis_infantis
from usuario u
left join perfil p on p.usuario_id = u.id
group by u.id, u.email, u.plano, u.data_cadastro
order by u.data_cadastro desc;

select 
    c.id,
    c.titulo,
    c.tipo,
    c.classificacao,
    fc_formatar_duracao(c.duracao_segundos) as duracao,
    c.popularidade_geral,
    count(cg.genero_id) as qtd_generos,
    string_agg(g.nome, ', ') as generos
from conteudo c
left join conteudo_genero cg on cg.conteudo_id = c.id
left join genero g on g.id = cg.genero_id
group by c.id, c.titulo, c.tipo, c.classificacao, c.duracao_segundos, c.popularidade_geral
order by c.popularidade_geral desc
limit 10;

select 
    p.nome as perfil,
    p.idade,
    p.is_infantil,
    count(h.id) as total_assistidos,
    round(avg(h.porcentagem_assistida), 2) as media_completude,
    round(avg(h.avaliacao), 2) as media_avaliacao,
    sum(case when h.porcentagem_assistida = 100 then 1 else 0 end) as completos,
    min(h.data_hora_inicio) as primeira_visualizacao,
    max(h.data_hora_inicio) as ultima_visualizacao
from perfil p
left join historico h on h.perfil_id = p.id
group by p.id, p.nome, p.idade, p.is_infantil
having count(h.id) > 0
order by total_assistidos desc;

select 
    c.classificacao,
    count(c.id) as qtd_conteudos,
    round(avg(c.popularidade_geral), 2) as popularidade_media,
    round(avg(c.duracao_segundos) / 60, 2) as duracao_media_minutos,
    string_agg(distinct c.tipo, ', ') as tipos_presentes,
    sum(case when c.tipo = 'filme' then 1 else 0 end) as filmes,
    sum(case when c.tipo = 'série' then 1 else 0 end) as series,
    sum(case when c.tipo = 'documentário' then 1 else 0 end) as documentarios
from conteudo c
group by c.classificacao
having count(c.id) > 1
order by 
    case c.classificacao
        when 'L' then 1
        when '10+' then 2
        when '12+' then 3
        when '14+' then 4
        when '16+' then 5
        when '18+' then 6
        else 7
    end;

select 
    titulo,
    tipo,
    classificacao,
    fc_formatar_duracao(duracao_segundos) as duracao_formatada
from conteudo 
where duracao_segundos between 3600 and 7200 
  and tipo = 'filme'
order by duracao_segundos;

select 
    c.titulo,
    c.tipo,
    c.classificacao,
    fc_formatar_duracao(c.duracao_segundos) as duracao_formatada,
    string_agg(g.nome, ', ') as generos
from conteudo c
join conteudo_genero cg on cg.conteudo_id = c.id
join genero g on g.id = cg.genero_id
where g.nome ilike '%suspense%'
  and c.tipo = 'filme'
group by c.id, c.titulo, c.tipo, c.classificacao, c.duracao_segundos;


SELECT fc_criar_sessao_grupo(1, 1, 1);

SELECT * FROM vw_sessoes_ativas;