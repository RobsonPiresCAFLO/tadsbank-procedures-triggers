-- =====================================================================
-- QUESTÃO 2 (2,0) – Triggers trg_contas_bu e trg_contas_au (contas)
-- =====================================================================
-- a) trg_contas_bu (BEFORE UPDATE em contas)
--    Conta que NÃO está 'ATIVA' (BLOQUEADA ou ENCERRADA) não pode ter o
--    SALDO alterado. Outras colunas (titular, status, limite) podem mudar.
--    -> SIGNAL 'Conta não está ativa: saldo não pode ser alterado'
--    (dica: compare OLD.status, OLD.saldo e NEW.saldo)
--
-- b) trg_contas_au (AFTER UPDATE em contas)
--    Sempre que o saldo MUDAR de verdade, grave uma linha em
--    auditoria_saldo com: id_conta, saldo_antigo, saldo_novo,
--    usuario (CURRENT_USER()) e data_hora (NOW()).
--    Se o UPDATE não mexeu no saldo, NÃO grave nada.
-- =====================================================================
USE tadsbank;

DROP TRIGGER IF EXISTS trg_contas_bu;
DELIMITER $$
CREATE TRIGGER trg_contas_bu
BEFORE UPDATE ON contas
FOR EACH ROW
BEGIN
  -- TODO a)

END $$
DELIMITER ;

DROP TRIGGER IF EXISTS trg_contas_au;
DELIMITER $$
CREATE TRIGGER trg_contas_au
AFTER UPDATE ON contas
FOR EACH ROW
BEGIN
  -- TODO b)

END $$
DELIMITER ;

-- ======================= TESTES =======================
-- Tudo o que está abaixo desta linha NÃO é executado pelo verificador.
-- Rode um por vez. Para voltar aos dados iniciais: ./resetar.sh
--
-- UPDATE contas SET saldo = saldo + 100 WHERE id_conta = 5;
--   -> ERROR 1644 (45000): Conta não está ativa: saldo não pode ser alterado
-- UPDATE contas SET titular = 'Elisa M.' WHERE id_conta = 5;
--   -> funciona (não mexeu no saldo)
-- UPDATE contas SET saldo = saldo + 100 WHERE id_conta = 2;
--   -> Bruno 600.00 e 1 linha em auditoria_saldo (500.00 -> 600.00)
-- UPDATE contas SET titular = 'Bruno S.' WHERE id_conta = 2;
--   -> nenhuma linha nova na auditoria
-- UPDATE contas SET saldo = saldo + 1 WHERE status = 'ATIVA';
--   -> 5 linhas novas na auditoria (uma por conta ativa)
-- SELECT * FROM auditoria_saldo;
