<div align="center">

# 🏥 Sistema de Gestão Hospitalar — Vida & Saúde

**Banco de dados relacional (MySQL) para substituir planilhas e registros em papel no Hospital Geral Vida & Saúde.**

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white)
![MySQL Workbench](https://img.shields.io/badge/MySQL_Workbench-modelagem-00758F?logo=mysql&logoColor=white)
![Normalização](https://img.shields.io/badge/Normaliza%C3%A7%C3%A3o-3FN-success)
![Status](https://img.shields.io/badge/status-homologa%C3%A7%C3%A3o-orange)

</div>

---

## 📑 Sumário

1. [Contexto do projeto](#-contexto-do-projeto)
2. [Objetivos](#-objetivos)
3. [Modelagem (MER/DER)](#-modelagem-merder)
4. [Regras de integridade](#-regras-de-integridade)
5. [Estrutura do repositório](#-estrutura-do-repositório)
6. [Como executar](#-como-executar)
7. [Queries estratégicas (DQL)](#-queries-estratégicas-dql)
8. [Resultados (prints)](#-resultados-prints)
9. [Equipe](#-equipe)

---

## 📌 Contexto do projeto

O Hospital Geral Vida & Saúde operava com planilhas isoladas e registros em papel. A ausência de um sistema centralizado gerou, no último trimestre:

| Problema | Impacto |
|---|---|
| Cobranças incorretas | **15%** dos atendimentos |
| Perda de histórico clínico de pacientes crônicos | **8%** |
| Sobreposição de agendas médicas | **45 consultas** canceladas em uma semana |

Como **DBAs Júniores**, nossa equipe projetou e implementou a primeira versão do banco de dados relacional da instituição, em ambiente de homologação, antes que o hospital sofra sanções dos órgãos de saúde.

## 🎯 Objetivos

- Levantar requisitos a partir dos problemas relatados;
- Modelar o esquema **normalizado até a 3ª Forma Normal (3FN)**;
- Impedir **sobreposição de horários** para o mesmo médico ou leito;
- Garantir **integridade referencial**, impedindo a exclusão acidental de históricos clínicos;
- Responder a **consultas de negócio** complexas para apoiar a tomada de decisão da diretoria.

## 🗂️ Modelagem (MER/DER)

### DER (MySQL Workbench)

<img width="868" height="668" alt="hospital_db" src="https://github.com/user-attachments/assets/a568bcb3-1841-4259-a7a8-e6f073f03c54" />

### Cardinalidades

| Relacionamento | Cardinalidade |
|---|---|
| Paciente → Consultas | 1 : N |
| Médico → Consultas | 1 : N |
| Consulta → Prescrições | 1 : N |
| Paciente → Internações | 1 : N |
| Quarto → Internações | 1 : N |

`pacientes` e `quartos` se relacionam N:N através da tabela associativa `internacoes`; `pacientes` e `medicos` através de `consultas`.

## 🔒 Regras de integridade

| Regra de negócio | Como foi implementada |
|---|---|
| Sem dois atendimentos do mesmo médico no mesmo horário | `UNIQUE (id_medico, data_consulta)` em `consultas` |
| Sem dois pacientes no mesmo quarto ao mesmo tempo | Triggers `bloquear_quarto_ocupado_insert` e `bloquear_quarto_ocupado_update` em `internacoes` |
| Histórico clínico não pode ser apagado acidentalmente | Todas as FKs com `ON DELETE RESTRICT` |
| CPF e CRM únicos | `UNIQUE` em `pacientes.cpf` e `medicos.crm` |
| Dados consistentes | `NOT NULL` e `CHECK` (status, tipo de quarto, valores positivos, `data_saida >= data_entrada`) |
| 3ª Forma Normal | Sem dependências parciais ou transitivas; cada entidade em sua própria tabela |

## 📁 Estrutura do repositório

```
hospital-vida-saude/
├── README.md
├── sql/
│   ├── 01_DDL_criacao_banco.sql     # Banco, tabelas e constraints
│   ├── 02_DML_carga_dados.sql       # Dados de teste (10 registros por tabela)
│   └── 03_DQL_consultas.sql         # 15 queries estratégicas
└── docs/
    ├── Sistema_de_Gestao_Hospitalar.pdf   # Enunciado do desafio
    ├── DER_hospital_db.mwb                # Modelo do MySQL Workbench
    └── img/
        ├── DER_hospital_db.png
        └── query_01.png ... query_15.png
```

## ▶️ Como executar

**Pré-requisitos:** MySQL Server **8.0.16+** (necessário para `CHECK`) e MySQL Workbench.

1. Clone o repositório:
   ```bash
   git clone https://github.com/<seu-usuario>/hospital-vida-saude.git
   cd hospital-vida-saude/sql
   ```
2. Execute os scripts **na ordem**, pelo Workbench (`File > Open SQL Script` → ⚡ Execute) ou pelo terminal:
   ```bash
   mysql -u root -p < 01_DDL_criacao_banco.sql
   mysql -u root -p < 02_DML_carga_dados.sql
   mysql -u root -p < 03_DQL_consultas.sql
   ```

> ⚠️ O script DDL recria as tabelas (`DROP TABLE IF EXISTS`). Use apenas em ambiente de homologação.

## 📊 Queries estratégicas (DQL)

Arquivo: [`sql/03_DQL_consultas.sql`](https://github.com/suawpe/hospital_db/blob/main/03_DQL_consultas.sql)

| # | Pergunta de negócio | Técnicas |
|:-:|---|---|
| 1 | Relatório da farmácia: paciente, médico, data, medicamento e quantidade | `INNER JOIN` (4 tabelas) |
| 2 | Histórico de internações: paciente, quarto, andar, entrada e diária | `INNER JOIN` |
| 3 | Recepção: pacientes, convênios, médicos e especialidades | `LEFT JOIN` (inclui quem nunca consultou) |
| 4 | Prescrições: médico, especialidade, paciente e remédio | `INNER JOIN` |
| 5 | Pacientes internados que também tiveram consulta, sem duplicidades | `DISTINCT` + 5 tabelas |
| 6 | Consultas das mais recentes às mais antigas | `ORDER BY DESC` |
| 7 | Diárias do menor para o maior valor | `ORDER BY ASC` |
| 8 | Valor médio das consultas | `AVG` |
| 9 | Total arrecadado com consultas agendadas/realizadas | `SUM` + `WHERE IN` |
| 10 | Consultas de pacientes com família "Silva" | `LIKE` |
| 11 | Consultas de médicos ligados à Cardiologia | `LIKE '%Cardio%'` |
| 12 | Internações no 1º semestre de 2026 | `BETWEEN` |
| 13 | Gasto em consultas por pacientes Unimed | `GROUP BY` + `SUM` + `LIKE` |
| 14 | Custo das diárias por andar (pacientes "Oliveira") | `GROUP BY` + `SUM` |
| 15 | Faturamento por especialidade cirúrgica | `GROUP BY` + `SUM` + `LIKE` |
