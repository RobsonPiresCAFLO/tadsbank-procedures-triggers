-- =====================================================================
-- IFPI Campus Floriano · TADS – Módulo III · Banco de Dados II
-- Atividade 04 – Stored Procedures e Triggers no TADSBank Pix
--
-- 00_tadsbank.sql – cria o banco tadsbank com os dados iniciais.
-- ATENÇÃO: apaga e recria o banco tadsbank (DROP DATABASE).
-- Testado no MySQL 5.7.44.
-- =====================================================================

DROP DATABASE IF EXISTS tadsbank;
CREATE DATABASE tadsbank CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE tadsbank;

-- ---------------------------------------------------------------------
-- Tabelas
-- ---------------------------------------------------------------------
CREATE TABLE contas (
  id_conta   INT PRIMARY KEY AUTO_INCREMENT,
  titular    VARCHAR(50)            NOT NULL,
  saldo      DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 0,
  limite_pix DECIMAL(10,2) UNSIGNED NOT NULL DEFAULT 1000,  -- limite diário de PIX enviado
  status     VARCHAR(10)            NOT NULL DEFAULT 'ATIVA' -- ATIVA, BLOQUEADA ou ENCERRADA
) ENGINE = InnoDB;

CREATE TABLE chaves_pix (
  id_chave  INT PRIMARY KEY AUTO_INCREMENT,
  id_conta  INT         NOT NULL,
  tipo      VARCHAR(10) NOT NULL,                  -- cpf, email ou aleatoria
  chave     VARCHAR(80) NOT NULL,
  criada_em DATETIME    DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uk_chave UNIQUE (chave),
  CONSTRAINT fk_chave_conta FOREIGN KEY (id_conta) REFERENCES contas (id_conta)
) ENGINE = InnoDB;

CREATE TABLE movimentacoes (
  id_mov    INT PRIMARY KEY AUTO_INCREMENT,
  id_conta  INT                    NOT NULL,
  tipo      VARCHAR(7)             NOT NULL,       -- credito ou debito
  valor     DECIMAL(10,2) UNSIGNED NOT NULL,
  descricao VARCHAR(40)            NOT NULL DEFAULT '',
  data_hora DATETIME               DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_mov_conta FOREIGN KEY (id_conta) REFERENCES contas (id_conta)
) ENGINE = InnoDB;

CREATE TABLE auditoria_saldo (
  id_aud       INT PRIMARY KEY AUTO_INCREMENT,
  id_conta     INT           NOT NULL,
  saldo_antigo DECIMAL(10,2) NOT NULL,
  saldo_novo   DECIMAL(10,2) NOT NULL,
  usuario      VARCHAR(80)   NOT NULL,
  data_hora    DATETIME      NOT NULL
) ENGINE = InnoDB;

-- ---------------------------------------------------------------------
-- Dados iniciais
-- ---------------------------------------------------------------------
INSERT INTO contas (id_conta, titular, saldo, limite_pix, status) VALUES
  (1, 'Ana',   1000.00,  500.00, 'ATIVA'),
  (2, 'Bruno',  500.00, 1000.00, 'ATIVA'),
  (3, 'Carla',  200.00, 1000.00, 'ATIVA'),
  (4, 'Diego',    0.00, 1000.00, 'ATIVA'),
  (5, 'Elisa',   80.00, 1000.00, 'BLOQUEADA'),
  (6, 'Fábio',   15.00, 1000.00, 'ATIVA');

INSERT INTO chaves_pix (id_chave, id_conta, tipo, chave) VALUES
  (1, 1, 'email',     'ana@tadsbank.com'),
  (2, 1, 'aleatoria', '7f3c2a10-5b1e-4c7d-9a2e-0d1f2e3a4b5c'),
  (3, 2, 'cpf',       '11122233344'),
  (4, 3, 'email',     'carla@tadsbank.com'),
  (5, 6, 'email',     'fabio@tadsbank.com');

-- a Ana já enviou 300 ontem e 150 hoje (limite diário dela: 500)
INSERT INTO movimentacoes (id_mov, id_conta, tipo, valor, descricao, data_hora) VALUES
  (1, 1, 'debito',  300.00, 'PIX enviado',  NOW() - INTERVAL 1 DAY),
  (2, 2, 'credito', 300.00, 'PIX recebido', NOW() - INTERVAL 1 DAY),
  (3, 1, 'debito',  150.00, 'PIX enviado',  NOW()),
  (4, 3, 'credito', 150.00, 'PIX recebido', NOW());

-- ---------------------------------------------------------------------
-- Conferência
-- ---------------------------------------------------------------------
SELECT * FROM contas;          -- 6 contas, soma dos saldos = 1795.00
SELECT * FROM chaves_pix;      -- 5 chaves
SELECT * FROM movimentacoes;   -- 4 movimentações
