-- =====================================================================
-- QUESTÃO 5 (2,0) – Trigger trg_contas_bd + procedure encerrar_conta
-- =====================================================================
-- a) trg_contas_bd (BEFORE DELETE em contas)
--    Banco não apaga conta: o histórico precisa ser mantido.
--    Qualquer DELETE em contas -> SIGNAL
--    'Conta não pode ser excluída. Use encerrar_conta'
--
-- b) encerrar_conta(IN p_conta INT, IN p_destino INT)
--    Encerra p_conta e manda o saldo que sobrou para p_destino.
--    Valide (SIGNAL SQLSTATE '45000'):
--     * p_conta existe e está 'ATIVA'     -> 'Conta a encerrar inválida'
--     * p_destino existe, está 'ATIVA' e
--       é diferente de p_conta             -> 'Conta de destino inválida'
--    Depois, numa transação:
--     1. se o saldo for maior que zero, transfere TUDO para p_destino e
--        grava 2 movimentações com descricao 'Encerramento'
--        (p_conta 'debito' e p_destino 'credito');
--     2. apaga as chaves Pix de p_conta;
--     3. muda o status de p_conta para 'ENCERRADA';
--     4. COMMIT. Em erro: ROLLBACK + RESIGNAL.
--    ATENÇÃO à ordem dos passos: lembre do trigger da Questão 2!
-- =====================================================================
USE tadsbank;

DROP TRIGGER IF EXISTS trg_contas_bd;
DELIMITER $$
CREATE TRIGGER trg_contas_bd
BEFORE DELETE ON contas
FOR EACH ROW
BEGIN
  -- TODO a)

END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS encerrar_conta;
DELIMITER $$
CREATE PROCEDURE encerrar_conta(IN p_conta INT, IN p_destino INT)
BEGIN
  -- TODO b)

END $$
DELIMITER ;

-- ======================= TESTES =======================
-- Tudo o que está abaixo desta linha NÃO é executado pelo verificador.
-- Rode em sequência, a partir dos dados iniciais (./resetar.sh).
--
-- DELETE FROM contas WHERE id_conta = 4;
--   -> ERROR 1644 (45000): Conta não pode ser excluída. Use encerrar_conta
-- CALL encerrar_conta(3, 2);
--   -> Carla 0.00 ENCERRADA, sem chaves Pix; Bruno 700.00;
--      2 movimentações 'Encerramento' de 200.00
-- CALL encerrar_conta(2, 5);
--   -> ERROR 1644 (45000): Conta de destino inválida  (Elisa está BLOQUEADA)
-- CALL encerrar_conta(3, 1);
--   -> ERROR 1644 (45000): Conta a encerrar inválida  (Carla já foi encerrada)
-- CALL encerrar_conta(4, 1);
--   -> Diego ENCERRADA, sem movimentação nova (saldo era 0)
-- SELECT * FROM contas;  SELECT * FROM chaves_pix;
