-- Hospital Vida & Saúde - as 15 consultas
-- rodar depois do 01 (DDL) e do 02 (carga de dados)

USE hospital_db;

-- 1. Farmácia: quem foi atendido, por qual médico, e o que foi receitado
SELECT
    pacientes.nome_paciente,
    medicos.nome_medico,
    consultas.data_consulta,
    prescricoes.medicamento,
    prescricoes.quantidade
FROM prescricoes
INNER JOIN consultas ON consultas.id_consulta = prescricoes.id_consulta
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
INNER JOIN medicos   ON medicos.id_medico     = consultas.id_medico
ORDER BY consultas.data_consulta;

-- 2. Auditoria: histórico de internações
SELECT
    pacientes.nome_paciente,
    quartos.numero_quarto,
    quartos.andar,
    internacoes.data_entrada,
    internacoes.valor_diaria
FROM internacoes
INNER JOIN pacientes ON pacientes.id_paciente = internacoes.id_paciente
INNER JOIN quartos   ON quartos.id_quarto     = internacoes.id_quarto
ORDER BY internacoes.data_entrada;

-- 3. Recepção: todos os pacientes com o médico que atendeu
--    uso LEFT JOIN pra aparecer também quem nunca fez consulta
SELECT
    pacientes.nome_paciente,
    pacientes.convenio,
    medicos.nome_medico,
    medicos.especialidade
FROM pacientes
LEFT JOIN consultas ON consultas.id_paciente = pacientes.id_paciente
LEFT JOIN medicos   ON medicos.id_medico     = consultas.id_medico
ORDER BY pacientes.nome_paciente;

-- 4. Coordenação médica: todas as prescrições
SELECT
    medicos.nome_medico,
    medicos.especialidade,
    pacientes.nome_paciente,
    prescricoes.medicamento
FROM prescricoes
INNER JOIN consultas ON consultas.id_consulta = prescricoes.id_consulta
INNER JOIN medicos   ON medicos.id_medico     = consultas.id_medico
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
ORDER BY medicos.nome_medico, pacientes.nome_paciente;

-- 5. Diretoria: pacientes que foram internados e também fizeram consulta
--    DISTINCT pra não repetir linha
SELECT DISTINCT
    pacientes.nome_paciente,
    quartos.numero_quarto,
    medicos.nome_medico,
    consultas.data_consulta
FROM pacientes
INNER JOIN internacoes ON internacoes.id_paciente = pacientes.id_paciente
INNER JOIN quartos     ON quartos.id_quarto       = internacoes.id_quarto
INNER JOIN consultas   ON consultas.id_paciente   = pacientes.id_paciente
INNER JOIN medicos     ON medicos.id_medico       = consultas.id_medico
ORDER BY pacientes.nome_paciente, consultas.data_consulta;

-- 6. Consultas da mais recente pra mais antiga
SELECT
    pacientes.nome_paciente,
    medicos.nome_medico,
    consultas.data_consulta
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
INNER JOIN medicos   ON medicos.id_medico     = consultas.id_medico
ORDER BY consultas.data_consulta DESC;

-- 7. Financeiro: diárias da menor pra maior
SELECT
    pacientes.nome_paciente,
    quartos.numero_quarto,
    internacoes.valor_diaria
FROM internacoes
INNER JOIN pacientes ON pacientes.id_paciente = internacoes.id_paciente
INNER JOIN quartos   ON quartos.id_quarto     = internacoes.id_quarto
ORDER BY internacoes.valor_diaria ASC;

-- 8. Valor médio das consultas
SELECT AVG(valor_consulta) AS valor_medio_consulta
FROM consultas;

-- 9. Total das consultas (as canceladas não entram)
SELECT SUM(valor_consulta) AS total_arrecadado
FROM consultas
WHERE status_consulta IN ('Agendada', 'Realizada');

-- 10. Consultas dos pacientes com Silva no nome
SELECT
    pacientes.nome_paciente,
    medicos.nome_medico,
    consultas.data_consulta
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
INNER JOIN medicos   ON medicos.id_medico     = consultas.id_medico
WHERE pacientes.nome_paciente LIKE '%Silva%'
ORDER BY consultas.data_consulta;

-- 11. Consultas com médicos de Cardiologia (qualquer variação)
SELECT
    pacientes.nome_paciente,
    medicos.nome_medico,
    medicos.especialidade
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
INNER JOIN medicos   ON medicos.id_medico     = consultas.id_medico
WHERE medicos.especialidade LIKE '%Cardio%'
ORDER BY medicos.especialidade, pacientes.nome_paciente;

-- 12. Internações que começaram no 1º semestre de 2026
SELECT
    pacientes.nome_paciente,
    quartos.numero_quarto,
    internacoes.data_entrada
FROM internacoes
INNER JOIN pacientes ON pacientes.id_paciente = internacoes.id_paciente
INNER JOIN quartos   ON quartos.id_quarto     = internacoes.id_quarto
WHERE internacoes.data_entrada BETWEEN '2026-01-01' AND '2026-06-30'
ORDER BY internacoes.data_entrada;

-- 13. Quanto cada paciente Unimed gastou em consultas
SELECT
    pacientes.nome_paciente,
    pacientes.convenio,
    SUM(consultas.valor_consulta) AS total_gasto
FROM consultas
INNER JOIN pacientes ON pacientes.id_paciente = consultas.id_paciente
WHERE pacientes.convenio LIKE '%Unimed%'
GROUP BY pacientes.id_paciente, pacientes.nome_paciente, pacientes.convenio
ORDER BY total_gasto DESC;

-- 14. Soma das diárias por andar, só dos pacientes Oliveira
SELECT
    quartos.andar,
    SUM(internacoes.valor_diaria) AS custo_total_diarias
FROM internacoes
INNER JOIN pacientes ON pacientes.id_paciente = internacoes.id_paciente
INNER JOIN quartos   ON quartos.id_quarto     = internacoes.id_quarto
WHERE pacientes.nome_paciente LIKE '%Oliveira%'
GROUP BY quartos.andar
ORDER BY quartos.andar ASC;

-- outra opção pra 14: multiplicar a diária pelos dias de internação
-- SELECT
--     quartos.andar,
--     SUM(internacoes.valor_diaria * DATEDIFF(internacoes.data_saida, internacoes.data_entrada)) AS custo_total
-- FROM internacoes
-- INNER JOIN pacientes ON pacientes.id_paciente = internacoes.id_paciente
-- INNER JOIN quartos   ON quartos.id_quarto     = internacoes.id_quarto
-- WHERE pacientes.nome_paciente LIKE '%Oliveira%'
-- GROUP BY quartos.andar
-- ORDER BY quartos.andar ASC;

-- 15. Faturamento por especialidade cirúrgica
SELECT
    medicos.especialidade,
    SUM(consultas.valor_consulta) AS total_arrecadado
FROM consultas
INNER JOIN medicos ON medicos.id_medico = consultas.id_medico
WHERE medicos.especialidade LIKE '%Cirurgia%'
GROUP BY medicos.especialidade
ORDER BY total_arrecadado DESC;
