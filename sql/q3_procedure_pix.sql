-- =====================================================================
-- QUESTÃO 3 (2,5) – Procedure pix
-- =====================================================================
-- pix(IN p_origem INT, IN p_chave VARCHAR(80), IN p_valor DECIMAL(10,2),
--     OUT p_id_mov INT)
--
-- Envia p_valor da conta p_origem para a conta dona da chave p_chave.
-- Tudo dentro de UMA transação: ou faz tudo, ou não faz nada.
--
-- Valide, nesta ordem (SIGNAL SQLSTATE '45000'):
--  V1. p_valor > 0                          -> 'Valor inválido'
--  V2. a chave existe em chaves_pix         -> 'Chave Pix não encontrada'
--  V3. origem diferente do destino          -> 'Origem e destino são a mesma conta'
--  V4. origem existe e está 'ATIVA'         -> 'Conta de origem inválida'
--  V5. destino está 'ATIVA'                 -> 'Conta de destino não está ativa'
--  V6. saldo da origem >= p_valor           -> 'Saldo insuficiente'
--  V7. limite diário: (soma dos PIX enviados HOJE pela origem) + p_valor
--      <= limite_pix da origem              -> 'Limite diário do Pix excedido'
--      PIX enviado hoje = movimentacoes da origem com tipo 'debito',
--      descricao 'PIX enviado' e DATE(data_hora) = CURDATE().
--
-- Se tudo estiver certo:
--  * debita a origem e credita o destino (UPDATE contas);
--  * grava 2 movimentações: (origem, 'debito', valor, 'PIX enviado')
--    e (destino, 'credito', valor, 'PIX recebido');
--  * devolve em p_id_mov o id da movimentação de DÉBITO (LAST_INSERT_ID());
--  * COMMIT.
-- Em qualquer erro: ROLLBACK e repasse o erro (EXIT HANDLER + RESIGNAL).
-- Trave a conta de origem com SELECT ... FOR UPDATE.
-- =====================================================================
USE tadsbank;

DROP PROCEDURE IF EXISTS pix;
DELIMITER $$
CREATE PROCEDURE pix(IN  p_origem INT,
                     IN  p_chave  VARCHAR(80),
                     IN  p_valor  DECIMAL(10,2),
                     OUT p_id_mov INT)
BEGIN
  DECLARE v_destino    INT;
  DECLARE v_saldo      DECIMAL(10,2);
  DECLARE v_limite     DECIMAL(10,2);
  DECLARE v_status     VARCHAR(10);
  DECLARE v_enviado    DECIMAL(10,2);

  -- TODO: EXIT HANDLER FOR SQLEXCEPTION (ROLLBACK + RESIGNAL)

  -- TODO: START TRANSACTION

  -- TODO: validações V1 a V7

  -- TODO: UPDATEs, INSERTs, p_id_mov e COMMIT

END $$
DELIMITER ;

-- ======================= TESTES =======================
-- Tudo o que está abaixo desta linha NÃO é executado pelo verificador.
-- Rode em sequência, a partir dos dados iniciais (./resetar.sh).
--
-- CALL pix(2, 'carla@tadsbank.com', 100, @id);  SELECT @id;
--   -> Bruno 400.00, Carla 300.00; @id = 5 (o débito do Bruno)
-- CALL pix(2, 'carla@tadsbank.com', 0, @id);
--   -> ERROR 1644 (45000): Valor inválido
-- CALL pix(2, 'ninguem@tadsbank.com', 10, @id);
--   -> ERROR 1644 (45000): Chave Pix não encontrada
-- CALL pix(1, 'ana@tadsbank.com', 10, @id);
--   -> ERROR 1644 (45000): Origem e destino são a mesma conta
-- CALL pix(3, '11122233344', 1000, @id);
--   -> ERROR 1644 (45000): Saldo insuficiente
-- CALL pix(1, '11122233344', 400, @id);
--   -> ERROR 1644 (45000): Limite diário do Pix excedido  (150 + 400 > 500)
-- CALL pix(1, '11122233344', 350, @id);
--   -> funciona: Ana 650.00, Bruno 750.00  (150 + 350 = 500)
-- CALL pix(5, 'ana@tadsbank.com', 10, @id);
--   -> ERROR 1644 (45000): Conta de origem inválida
-- SELECT SUM(saldo) FROM contas;   -> continua 1795.00
-- SELECT * FROM movimentacoes;     -> 8 linhas
