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