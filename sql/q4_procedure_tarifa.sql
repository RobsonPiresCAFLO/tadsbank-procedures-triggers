-- =====================================================================
-- QUESTÃO 4 (1,5) – Procedure cobrar_tarifa
-- =====================================================================
-- cobrar_tarifa(IN p_valor DECIMAL(10,2), OUT p_cobradas INT, OUT p_isentas INT)
--
-- Cobra a tarifa mensal de TODAS as contas 'ATIVA':
--  * se p_valor <= 0                 -> SIGNAL 'Valor da tarifa inválido'
--  * conta ATIVA com saldo >= p_valor: debita p_valor e grava a
--    movimentação (conta, 'debito', p_valor, 'Tarifa mensal');
--    conta no p_cobradas.
--  * conta ATIVA com saldo menor que p_valor: não cobra (isenta);
--    conta no p_isentas.
--  * contas BLOQUEADA/ENCERRADA: ignoradas (não entram em nenhuma contagem).
--  * Tudo numa transação: se der erro no meio, nenhuma conta é cobrada
--    (EXIT HANDLER + ROLLBACK + RESIGNAL).
--
-- Pode resolver com um laço (WHILE percorrendo os id_conta) ou com
-- comandos que tratam várias linhas de uma vez (INSERT ... SELECT, UPDATE).
-- =====================================================================
USE tadsbank;

DROP PROCEDURE IF EXISTS cobrar_tarifa;
DELIMITER $$
CREATE PROCEDURE cobrar_tarifa(IN  p_valor    DECIMAL(10,2),
                               OUT p_cobradas INT,
                               OUT p_isentas  INT)
BEGIN
  -- TODO

END $$
DELIMITER ;

-- ======================= TESTES =======================
-- Tudo o que está abaixo desta linha NÃO é executado pelo verificador.
-- Rode em sequência, a partir dos dados iniciais (./resetar.sh).
--
-- CALL cobrar_tarifa(20, @c, @i);  SELECT @c, @i;
--   -> 3 cobradas (Ana, Bruno, Carla) e 2 isentas (Diego, Fábio)
--   -> Ana 980 · Bruno 480 · Carla 180 · Diego 0 · Elisa 80 · Fábio 15
-- CALL cobrar_tarifa(0, @c, @i);
--   -> ERROR 1644 (45000): Valor da tarifa inválido
-- CALL cobrar_tarifa(500, @c, @i);  SELECT @c, @i;
--   -> 1 cobrada (Ana, que fica com 480) e 4 isentas
-- SELECT * FROM movimentacoes WHERE descricao = 'Tarifa mensal';  -> 4 linhas
