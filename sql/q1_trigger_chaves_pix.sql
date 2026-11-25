-- =====================================================================
-- QUESTÃO 1 (2,0) – Trigger trg_chaves_bi (BEFORE INSERT em chaves_pix)
-- =====================================================================
-- Toda chave Pix cadastrada deve ser PADRONIZADA e VALIDADA antes de
-- ser gravada. Crie o trigger trg_chaves_bi que:
--
--  R1. Padroniza o tipo: minúsculo e sem espaços (LOWER + TRIM).
--      Só aceita 'cpf', 'email' ou 'aleatoria'.
--      Senão -> SIGNAL 'Tipo de chave inválido'
--  R2. cpf: remove pontos, traço e espaços (REPLACE) e só aceita
--      11 dígitos  (dica: NEW.chave REGEXP '^[0-9]{11}$').
--      Senão -> SIGNAL 'CPF inválido'
--  R3. email: minúsculo e sem espaços nas pontas; precisa ter o formato
--      algo@algo.algo  (dica: LIKE '%_@_%._%').
--      Senão -> SIGNAL 'E-mail inválido'
--  R4. aleatoria: ignora o que foi digitado e gera a chave com UUID().
--  R5. A conta precisa estar com status 'ATIVA'.
--      Senão -> SIGNAL 'Conta não está ativa'
--  R6. Cada conta pode ter no máximo 3 chaves.
--      Senão -> SIGNAL 'Limite de 3 chaves por conta'
--
-- Lembretes: no BEFORE INSERT você pode alterar NEW.coluna (SET NEW.x = ...).
-- O MySQL 5.7 não tem REGEXP_REPLACE: use REPLACE uma vez para cada caractere.
-- Chave repetida já é barrada pela UNIQUE uk_chave (ERROR 1062).
-- =====================================================================
USE tadsbank;

DROP TRIGGER IF EXISTS trg_chaves_bi;
DELIMITER $$
CREATE TRIGGER trg_chaves_bi
BEFORE INSERT ON chaves_pix
FOR EACH ROW
BEGIN
  DECLARE v_status VARCHAR(10);
  DECLARE v_qtd    INT;

  -- TODO R1: padronizar e validar NEW.tipo

  -- TODO R2, R3 e R4: tratar NEW.chave conforme o tipo (IF / ELSEIF)

  -- TODO R5: buscar o status da conta (SELECT ... INTO v_status)

  -- TODO R6: contar as chaves da conta (SELECT COUNT(*) INTO v_qtd)

END $$
DELIMITER ;

-- ======================= TESTES =======================
-- Tudo o que está abaixo desta linha NÃO é executado pelo verificador.
-- Rode um por vez. Para voltar aos dados iniciais: ./resetar.sh
--
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (2, ' EMAIL ', '  Bruno.Silva@TADSbank.COM ');
--   -> gravada como tipo 'email' e chave 'bruno.silva@tadsbank.com'
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (3, 'cpf', '123.456.789-09');
--   -> gravada como '12345678909'
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (3, 'cpf', '123.456.789');
--   -> ERROR 1644 (45000): CPF inválido
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (4, 'email', 'diego.tadsbank.com');
--   -> ERROR 1644 (45000): E-mail inválido
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (1, 'aleatoria', '');
--   -> gravada com uma chave de 36 caracteres (3ª chave da Ana)
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (1, 'email', 'ana2@tadsbank.com');
--   -> ERROR 1644 (45000): Limite de 3 chaves por conta
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (5, 'email', 'elisa@tadsbank.com');
--   -> ERROR 1644 (45000): Conta não está ativa
-- INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (2, 'telefone', '86999990000');
--   -> ERROR 1644 (45000): Tipo de chave inválido
-- SELECT * FROM chaves_pix;
