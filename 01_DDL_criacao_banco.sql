-- Hospital Vida & Saúde - criação do banco e das tabelas
-- precisa de MySQL 8.0.16 ou mais novo por causa dos CHECK

CREATE DATABASE IF NOT EXISTS hospital_db;
USE hospital_db;

-- apaga na ordem contrária pra não dar erro de chave estrangeira
-- (assim dá pra rodar o script quantas vezes quiser)
DROP TABLE IF EXISTS prescricoes;
DROP TABLE IF EXISTS consultas;
DROP TABLE IF EXISTS internacoes;
DROP TABLE IF EXISTS quartos;
DROP TABLE IF EXISTS medicos;
DROP TABLE IF EXISTS pacientes;

CREATE TABLE pacientes (
    id_paciente       INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_paciente     VARCHAR(100) NOT NULL,
    cpf               VARCHAR(14)  NOT NULL UNIQUE,
    data_nascimento   DATE         NOT NULL,
    telefone_paciente VARCHAR(20),
    convenio          VARCHAR(50)  NOT NULL DEFAULT 'Particular'
);

CREATE TABLE medicos (
    id_medico     INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nome_medico   VARCHAR(100) NOT NULL,
    crm           VARCHAR(20)  NOT NULL UNIQUE,
    especialidade VARCHAR(60)  NOT NULL
);

CREATE TABLE quartos (
    id_quarto     INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    numero_quarto INT         NOT NULL UNIQUE,
    andar         INT         NOT NULL,
    tipo_quarto   VARCHAR(30) NOT NULL CHECK (tipo_quarto IN ('UTI', 'Enfermaria', 'Apartamento', 'Suíte VIP')),
    status_quarto VARCHAR(20) NOT NULL DEFAULT 'Livre' CHECK (status_quarto IN ('Livre', 'Ocupado'))
);

-- se data_saida for NULL o paciente ainda está internado
CREATE TABLE internacoes (
    id_internacao INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_paciente   INT           NOT NULL,
    id_quarto     INT           NOT NULL,
    data_entrada  DATE          NOT NULL,
    data_saida    DATE,
    valor_diaria  DECIMAL(10,2) NOT NULL CHECK (valor_diaria > 0),
    CHECK (data_saida IS NULL OR data_saida >= data_entrada),
    FOREIGN KEY (id_paciente) REFERENCES pacientes (id_paciente) ON DELETE RESTRICT,
    FOREIGN KEY (id_quarto)   REFERENCES quartos (id_quarto)     ON DELETE RESTRICT
);

-- o UNIQUE no final impede o mesmo médico de ter 2 consultas no mesmo horário
CREATE TABLE consultas (
    id_consulta     INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_paciente     INT           NOT NULL,
    id_medico       INT           NOT NULL,
    data_consulta   DATETIME      NOT NULL,
    status_consulta VARCHAR(20)   NOT NULL DEFAULT 'Agendada' CHECK (status_consulta IN ('Agendada', 'Realizada', 'Cancelada')),
    valor_consulta  DECIMAL(10,2) NOT NULL CHECK (valor_consulta >= 0),
    UNIQUE (id_medico, data_consulta),
    FOREIGN KEY (id_paciente) REFERENCES pacientes (id_paciente) ON DELETE RESTRICT,
    FOREIGN KEY (id_medico)   REFERENCES medicos (id_medico)     ON DELETE RESTRICT
);

CREATE TABLE prescricoes (
    id_prescricao INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_consulta   INT          NOT NULL,
    medicamento   VARCHAR(100) NOT NULL,
    dosagem       VARCHAR(150) NOT NULL,
    quantidade    INT          NOT NULL CHECK (quantidade > 0),
    FOREIGN KEY (id_consulta) REFERENCES consultas (id_consulta) ON DELETE RESTRICT
);

-- Triggers: não deixam o mesmo quarto ter duas internações com datas que se cruzam.
-- Não dá pra usar UNIQUE porque a internação é um período (entrada até saída).
DELIMITER $$

CREATE TRIGGER bloquear_quarto_ocupado_insert
BEFORE INSERT ON internacoes
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM internacoes AS outra
        WHERE outra.id_quarto = NEW.id_quarto
          AND NEW.data_entrada <= IFNULL(outra.data_saida, '9999-12-31')
          AND IFNULL(NEW.data_saida, '9999-12-31') >= outra.data_entrada
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Conflito: o quarto já possui internação neste período.';
    END IF;
END$$

CREATE TRIGGER bloquear_quarto_ocupado_update
BEFORE UPDATE ON internacoes
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM internacoes AS outra
        WHERE outra.id_quarto = NEW.id_quarto
          AND outra.id_internacao <> NEW.id_internacao
          AND NEW.data_entrada <= IFNULL(outra.data_saida, '9999-12-31')
          AND IFNULL(NEW.data_saida, '9999-12-31') >= outra.data_entrada
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Conflito: o quarto já possui internação neste período.';
    END IF;
END$$

DELIMITER ;
