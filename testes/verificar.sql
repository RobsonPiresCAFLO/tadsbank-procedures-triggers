-- =====================================================================
-- Verificador automático da Atividade 04 (NÃO EDITE ESTE ARQUIVO)
--
-- É executado pelo ./verificar.sh DEPOIS de recriar o banco (00_tadsbank.sql)
-- e de criar os seus triggers/procedures (q1 a q5, só a parte de cima,
-- antes da linha "TESTES"). Cada questão começa com os dados iniciais.
-- A nota mostrada é uma ESTIMATIVA: o professor também lê o código.
-- =====================================================================
DELIMITER ;
USE tadsbank;
SET NAMES utf8mb4;

DROP TABLE IF EXISTS _resultado;
CREATE TABLE _resultado (
  id      INT PRIMARY KEY AUTO_INCREMENT,
  questao CHAR(2),
  teste   VARCHAR(70),
  ok      TINYINT,
  pontos  DECIMAL(3,1),
  detalhe VARCHAR(255)
);

DROP PROCEDURE IF EXISTS _ok;
DROP PROCEDURE IF EXISTS _tenta;
DROP PROCEDURE IF EXISTS _foto;
DROP PROCEDURE IF EXISTS _existe;
DROP PROCEDURE IF EXISTS _reset;
DROP PROCEDURE IF EXISTS _q1;
DROP PROCEDURE IF EXISTS _q2;
DROP PROCEDURE IF EXISTS _q3;
DROP PROCEDURE IF EXISTS _q4;
DROP PROCEDURE IF EXISTS _q5;

DELIMITER $$

-- registra o resultado de um teste
CREATE PROCEDURE _ok(IN p_q CHAR(2), IN p_teste VARCHAR(70), IN p_cond INT,
                     IN p_pontos DECIMAL(3,1), IN p_detalhe VARCHAR(255))
BEGIN
  INSERT INTO _resultado (questao, teste, ok, pontos, detalhe)
  VALUES (p_q, p_teste, IFNULL(p_cond, 0) <> 0, p_pontos,
          IFNULL(p_detalhe, 'sem erro'));
END $$

-- executa um comando e devolve a mensagem de erro (NULL = não deu erro)
CREATE PROCEDURE _tenta(IN p_sql TEXT, OUT p_erro VARCHAR(255))
BEGIN
  DECLARE v_msg VARCHAR(255);
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
    IF p_erro IS NULL THEN SET p_erro = LEFT(v_msg, 255); END IF;
  END;
  SET p_erro = NULL;
  SET @_sql = p_sql;
  PREPARE _st FROM @_sql;
  EXECUTE _st;
  DEALLOCATE PREPARE _st;
END $$

-- "fotografia" do banco: serve para saber se um comando com erro mudou algo
CREATE PROCEDURE _foto(OUT p_foto TEXT)
BEGIN
  SELECT CONCAT(
    (SELECT GROUP_CONCAT(id_conta, ':', saldo, ':', status ORDER BY id_conta) FROM contas), '|',
    (SELECT COUNT(*) FROM movimentacoes), '|',
    (SELECT COUNT(*) FROM chaves_pix), '|',
    (SELECT COUNT(*) FROM auditoria_saldo))
  INTO p_foto;
END $$

-- o objeto (TRIGGER ou PROCEDURE) foi criado?
CREATE PROCEDURE _existe(IN p_tipo VARCHAR(10), IN p_nome VARCHAR(64), OUT p_sim INT)
BEGIN
  IF p_tipo = 'TRIGGER' THEN
    SELECT COUNT(*) INTO p_sim FROM information_schema.triggers
     WHERE trigger_schema = 'tadsbank' AND trigger_name = p_nome;
  ELSE
    SELECT COUNT(*) INTO p_sim FROM information_schema.routines
     WHERE routine_schema = 'tadsbank' AND routine_name = p_nome
       AND routine_type = p_tipo;
  END IF;
END $$

-- volta aos dados iniciais (TRUNCATE não dispara triggers)
CREATE PROCEDURE _reset()
BEGIN
  SET FOREIGN_KEY_CHECKS = 0;
  TRUNCATE TABLE auditoria_saldo;
  TRUNCATE TABLE movimentacoes;
  TRUNCATE TABLE contas;
  SET FOREIGN_KEY_CHECKS = 1;
  DELETE FROM chaves_pix WHERE id_chave > 5;

  INSERT INTO contas (id_conta, titular, saldo, limite_pix, status) VALUES
    (1, 'Ana',   1000.00,  500.00, 'ATIVA'),
    (2, 'Bruno',  500.00, 1000.00, 'ATIVA'),
    (3, 'Carla',  200.00, 1000.00, 'ATIVA'),
    (4, 'Diego',    0.00, 1000.00, 'ATIVA'),
    (5, 'Elisa',   80.00, 1000.00, 'BLOQUEADA'),
    (6, 'Fábio',   15.00, 1000.00, 'ATIVA');

  INSERT INTO movimentacoes (id_mov, id_conta, tipo, valor, descricao, data_hora) VALUES
    (1, 1, 'debito',  300.00, 'PIX enviado',  NOW() - INTERVAL 1 DAY),
    (2, 2, 'credito', 300.00, 'PIX recebido', NOW() - INTERVAL 1 DAY),
    (3, 1, 'debito',  150.00, 'PIX enviado',  NOW()),
    (4, 3, 'credito', 150.00, 'PIX recebido', NOW());
END $$

-- ---------------------------------------------------------------------
-- QUESTÃO 1 – trg_chaves_bi (2,0)
-- ---------------------------------------------------------------------
CREATE PROCEDURE _q1()
BEGIN
  DECLARE e VARCHAR(255);
  DECLARE t INT;
  CALL _reset();
  CALL _existe('TRIGGER', 'trg_chaves_bi', t);
  IF t = 0 THEN
    CALL _ok('Q1', 'trigger trg_chaves_bi criado', 0, 0, 'trigger não encontrado');
  END IF;

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (2, ' EMAIL ', '  Bruno.Silva@TADSbank.COM ')", e);
  CALL _ok('Q1', 'e-mail padronizado (tipo e chave)',
    (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 2 AND BINARY tipo = 'email'
        AND BINARY chave = 'bruno.silva@tadsbank.com') = 1, 0.4, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (3, 'cpf', '123.456.789-09')", e);
  CALL _ok('Q1', 'CPF 123.456.789-09 gravado como 12345678909',
    (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 3 AND BINARY tipo = 'cpf'
        AND BINARY chave = '12345678909') = 1, 0.4, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (3, 'cpf', '123.456.789')", e);
  CALL _ok('Q1', 'CPF com 9 dígitos é recusado',
    t > 0 AND e IS NOT NULL AND
    (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 3) = 2, 0.2, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (4, 'email', 'diego.tadsbank.com')", e);
  CALL _ok('Q1', 'e-mail sem @ é recusado',
    t > 0 AND e IS NOT NULL AND
    (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 4) = 0, 0.2, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (1, 'aleatoria', '')", e);
  CALL _ok('Q1', 'chave aleatória gerada com UUID()',
    (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 1 AND id_chave > 5
        AND BINARY tipo = 'aleatoria' AND CHAR_LENGTH(chave) = 36) = 1, 0.3, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (1, 'email', 'ana2@tadsbank.com')", e);
  CALL _ok('Q1', '4ª chave da mesma conta é recusada',
    t > 0 AND e IS NOT NULL AND
    (SELECT COUNT(*) FROM chaves_pix WHERE chave LIKE 'ana2%') = 0, 0.2, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (5, 'email', 'elisa@tadsbank.com')", e);
  CALL _ok('Q1', 'conta BLOQUEADA não cadastra chave',
    t > 0 AND e IS NOT NULL AND
    (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 5) = 0, 0.2, e);

  CALL _tenta("INSERT INTO chaves_pix (id_conta, tipo, chave) VALUES (2, 'telefone', '86999990000')", e);
  CALL _ok('Q1', 'tipo telefone é recusado',
    t > 0 AND e IS NOT NULL AND
    (SELECT COUNT(*) FROM chaves_pix WHERE chave LIKE '%86999990000%') = 0, 0.1, e);

  DELETE FROM chaves_pix WHERE id_chave > 5;
END $$

-- ---------------------------------------------------------------------
-- QUESTÃO 2 – trg_contas_bu e trg_contas_au (2,0)
-- ---------------------------------------------------------------------
CREATE PROCEDURE _q2()
BEGIN
  DECLARE e, e1 VARCHAR(255);
  DECLARE bu, au INT;
  CALL _reset();
  CALL _existe('TRIGGER', 'trg_contas_bu', bu);
  CALL _existe('TRIGGER', 'trg_contas_au', au);
  IF bu = 0 THEN CALL _ok('Q2', 'trigger trg_contas_bu criado', 0, 0, 'trigger não encontrado'); END IF;
  IF au = 0 THEN CALL _ok('Q2', 'trigger trg_contas_au criado', 0, 0, 'trigger não encontrado'); END IF;

  CALL _tenta("UPDATE contas SET saldo = saldo + 100 WHERE id_conta = 5", e);
  CALL _ok('Q2', 'a) saldo de conta BLOQUEADA não muda',
    bu > 0 AND e IS NOT NULL AND
    (SELECT saldo FROM contas WHERE id_conta = 5) = 80, 0.5, e);
  SET e1 = e;

  CALL _tenta("UPDATE contas SET titular = 'Elisa M.' WHERE id_conta = 5", e);
  CALL _ok('Q2', 'a) titular de conta BLOQUEADA pode mudar',
    bu > 0 AND e1 IS NOT NULL AND e IS NULL AND
    (SELECT titular FROM contas WHERE id_conta = 5) = 'Elisa M.', 0.2, e);

  CALL _tenta("UPDATE contas SET saldo = saldo + 100 WHERE id_conta = 2", e);
  CALL _ok('Q2', 'b) auditoria grava 500.00 -> 600.00 do Bruno',
    au > 0 AND (SELECT COUNT(*) FROM auditoria_saldo) = 1 AND
    (SELECT COUNT(*) FROM auditoria_saldo
      WHERE id_conta = 2 AND saldo_antigo = 500 AND saldo_novo = 600
        AND usuario <> '' AND data_hora IS NOT NULL) = 1, 0.6, e);

  CALL _tenta("UPDATE contas SET titular = 'Bruno S.' WHERE id_conta = 2", e);
  CALL _ok('Q2', 'b) mudar só o titular não gera auditoria',
    au > 0 AND e IS NULL AND (SELECT COUNT(*) FROM auditoria_saldo) = 1, 0.3, e);

  CALL _tenta("UPDATE contas SET saldo = saldo WHERE id_conta IN (1, 2, 3)", e);
  CALL _ok('Q2', 'b) saldo = saldo não gera auditoria',
    au > 0 AND e IS NULL AND (SELECT COUNT(*) FROM auditoria_saldo) = 1, 0.2, e);

  CALL _tenta("UPDATE contas SET saldo = saldo + 1 WHERE status = 'ATIVA'", e);
  CALL _ok('Q2', 'b) UPDATE em 5 contas gera 5 linhas',
    au > 0 AND e IS NULL AND (SELECT COUNT(*) FROM auditoria_saldo) = 6, 0.2, e);
END $$

-- ---------------------------------------------------------------------
-- QUESTÃO 3 – procedure pix (2,5)
-- ---------------------------------------------------------------------
CREATE PROCEDURE _q3()
BEGIN
  DECLARE e VARCHAR(255);
  DECLARE p INT;
  DECLARE antes, depois TEXT;
  CALL _reset();
  CALL _existe('PROCEDURE', 'pix', p);
  IF p = 0 THEN CALL _ok('Q3', 'procedure pix criada', 0, 0, 'procedure não encontrada'); END IF;

  SET @_id = NULL;
  CALL _tenta("CALL pix(2, 'carla@tadsbank.com', 100, @_id)", e);
  CALL _ok('Q3', 'Pix Bruno -> Carla 100: saldos 400 e 300',
    (SELECT saldo FROM contas WHERE id_conta = 2) = 400 AND
    (SELECT saldo FROM contas WHERE id_conta = 3) = 300, 0.3, e);
  CALL _ok('Q3', 'Pix Bruno -> Carla 100: 2 movimentações',
    (SELECT COUNT(*) FROM movimentacoes) = 6 AND
    (SELECT COUNT(*) FROM movimentacoes WHERE id_conta = 2 AND tipo = 'debito'
        AND valor = 100 AND descricao = 'PIX enviado') = 1 AND
    (SELECT COUNT(*) FROM movimentacoes WHERE id_conta = 3 AND tipo = 'credito'
        AND valor = 100 AND descricao = 'PIX recebido') = 1, 0.2, e);
  CALL _ok('Q3', 'p_id_mov = id do débito',
    @_id IS NOT NULL AND
    @_id = (SELECT MAX(id_mov) FROM movimentacoes WHERE id_conta = 2 AND tipo = 'debito'),
    0.2, CONCAT('p_id_mov = ', IFNULL(@_id, 'NULL')));

  CALL _foto(antes);
  CALL _tenta("CALL pix(2, 'carla@tadsbank.com', 0, @_id)", e);
  CALL _foto(depois);
  CALL _ok('Q3', 'V1 valor 0 é recusado',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.2, e);

  CALL _tenta("CALL pix(2, 'ninguem@tadsbank.com', 10, @_id)", e);
  CALL _foto(depois);
  CALL _ok('Q3', 'V2 chave inexistente é recusada',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.2, e);

  CALL _tenta("CALL pix(1, 'ana@tadsbank.com', 10, @_id)", e);
  CALL _foto(depois);
  CALL _ok('Q3', 'V3 Pix para a própria conta é recusado',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.1, e);

  CALL _tenta("CALL pix(3, '11122233344', 1000, @_id)", e);
  CALL _foto(depois);
  CALL _ok('Q3', 'V6 saldo insuficiente (Carla 1000)',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.3, e);

  CALL _tenta("CALL pix(1, '11122233344', 400, @_id)", e);
  CALL _foto(depois);
  CALL _ok('Q3', 'V7 limite diário: Ana 150 + 400 > 500',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.4, e);

  CALL _tenta("CALL pix(1, '11122233344', 350, @_id)", e);
  CALL _ok('Q3', 'V7 limite diário: Ana 150 + 350 = 500 passa',
    e IS NULL AND
    (SELECT saldo FROM contas WHERE id_conta = 1) = 650 AND
    (SELECT saldo FROM contas WHERE id_conta = 2) = 750, 0.2, e);

  CALL _foto(antes);
  CALL _tenta("CALL pix(5, 'ana@tadsbank.com', 10, @_id)", e);
  CALL _foto(depois);
  CALL _ok('Q3', 'V4 origem BLOQUEADA é recusada',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.2, e);

  CALL _ok('Q3', 'no fim: soma 1795.00 e 8 movimentações',
    p > 0 AND (SELECT SUM(saldo) FROM contas) = 1795 AND
    (SELECT COUNT(*) FROM movimentacoes) = 8, 0.2, NULL);
END $$

-- ---------------------------------------------------------------------
-- QUESTÃO 4 – procedure cobrar_tarifa (1,5)
-- ---------------------------------------------------------------------
CREATE PROCEDURE _q4()
BEGIN
  DECLARE e VARCHAR(255);
  DECLARE p INT;
  DECLARE antes, depois TEXT;
  CALL _reset();
  CALL _existe('PROCEDURE', 'cobrar_tarifa', p);
  IF p = 0 THEN CALL _ok('Q4', 'procedure cobrar_tarifa criada', 0, 0, 'procedure não encontrada'); END IF;

  SET @_c = NULL, @_i = NULL;
  CALL _tenta("CALL cobrar_tarifa(20, @_c, @_i)", e);
  CALL _ok('Q4', 'tarifa 20: 3 cobradas e 2 isentas',
    @_c = 3 AND @_i = 2, 0.4,
    CONCAT(IFNULL(e, 'sem erro'), ' | cobradas=', IFNULL(@_c, 'NULL'), ' isentas=', IFNULL(@_i, 'NULL')));
  CALL _ok('Q4', 'tarifa 20: saldos 980/480/180/0/80/15',
    (SELECT GROUP_CONCAT(saldo ORDER BY id_conta) FROM contas)
      = '980.00,480.00,180.00,0.00,80.00,15.00', 0.4,
    (SELECT GROUP_CONCAT(saldo ORDER BY id_conta) FROM contas));
  CALL _ok('Q4', 'tarifa 20: 3 movimentações Tarifa mensal',
    (SELECT COUNT(*) FROM movimentacoes WHERE descricao = 'Tarifa mensal') = 3 AND
    (SELECT COUNT(*) FROM movimentacoes WHERE descricao = 'Tarifa mensal'
        AND tipo = 'debito' AND valor = 20 AND id_conta IN (1, 2, 3)) = 3, 0.3, e);

  CALL _foto(antes);
  CALL _tenta("CALL cobrar_tarifa(0, @_c, @_i)", e);
  CALL _foto(depois);
  CALL _ok('Q4', 'tarifa 0 é recusada',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.2, e);

  SET @_c = NULL, @_i = NULL;
  CALL _tenta("CALL cobrar_tarifa(500, @_c, @_i)", e);
  CALL _ok('Q4', 'tarifa 500: 1 cobrada (Ana 480) e 4 isentas',
    @_c = 1 AND @_i = 4 AND (SELECT saldo FROM contas WHERE id_conta = 1) = 480, 0.2,
    CONCAT(IFNULL(e, 'sem erro'), ' | cobradas=', IFNULL(@_c, 'NULL'), ' isentas=', IFNULL(@_i, 'NULL')));
END $$

-- ---------------------------------------------------------------------
-- QUESTÃO 5 – trg_contas_bd e encerrar_conta (2,0)
-- ---------------------------------------------------------------------
CREATE PROCEDURE _q5()
BEGIN
  DECLARE e VARCHAR(255);
  DECLARE t, p INT;
  DECLARE antes, depois TEXT;
  CALL _reset();
  CALL _existe('TRIGGER', 'trg_contas_bd', t);
  CALL _existe('PROCEDURE', 'encerrar_conta', p);
  IF t = 0 THEN CALL _ok('Q5', 'trigger trg_contas_bd criado', 0, 0, 'trigger não encontrado'); END IF;
  IF p = 0 THEN CALL _ok('Q5', 'procedure encerrar_conta criada', 0, 0, 'procedure não encontrada'); END IF;

  CALL _tenta("CALL encerrar_conta(3, 2)", e);
  CALL _ok('Q5', 'b) Carla fica com 0.00 e ENCERRADA',
    (SELECT COUNT(*) FROM contas WHERE id_conta = 3 AND saldo = 0 AND status = 'ENCERRADA') = 1, 0.3, e);
  CALL _ok('Q5', 'b) Bruno recebe os 200.00 (fica com 700.00)',
    (SELECT saldo FROM contas WHERE id_conta = 2) = 700, 0.2, e);
  CALL _ok('Q5', 'b) 2 movimentações Encerramento de 200.00',
    (SELECT COUNT(*) FROM movimentacoes WHERE descricao = 'Encerramento') = 2 AND
    (SELECT COUNT(*) FROM movimentacoes WHERE descricao = 'Encerramento' AND valor = 200
        AND ((id_conta = 3 AND tipo = 'debito') OR (id_conta = 2 AND tipo = 'credito'))) = 2, 0.3, e);
  CALL _ok('Q5', 'b) chaves Pix da Carla apagadas',
    p > 0 AND (SELECT COUNT(*) FROM chaves_pix WHERE id_conta = 3) = 0 AND
    (SELECT COUNT(*) FROM chaves_pix) = 4, 0.2, e);

  CALL _foto(antes);
  CALL _tenta("CALL encerrar_conta(2, 5)", e);
  CALL _foto(depois);
  CALL _ok('Q5', 'b) destino BLOQUEADO é recusado',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.3, e);

  CALL _tenta("CALL encerrar_conta(3, 1)", e);
  CALL _foto(depois);
  CALL _ok('Q5', 'b) conta já ENCERRADA é recusada',
    p > 0 AND e IS NOT NULL AND antes = depois, 0.2, e);

  CALL _tenta("CALL encerrar_conta(4, 1)", e);
  CALL _ok('Q5', 'b) Diego (saldo 0) encerrado sem movimentação',
    e IS NULL AND
    (SELECT status FROM contas WHERE id_conta = 4) = 'ENCERRADA' AND
    (SELECT COUNT(*) FROM movimentacoes WHERE id_conta = 4) = 0, 0.2, e);

  CALL _tenta("DELETE FROM contas WHERE id_conta = 4", e);
  CALL _ok('Q5', 'a) DELETE em contas é barrado',
    t > 0 AND e IS NOT NULL AND
    (SELECT COUNT(*) FROM contas WHERE id_conta = 4) = 1, 0.3, e);
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- Execução
-- ---------------------------------------------------------------------
CALL _q1();
CALL _q2();
CALL _q3();
CALL _q4();
CALL _q5();

SELECT questao AS `Q`, teste AS `Teste`,
       IF(ok, 'OK', 'FALHOU') AS `Resultado`,
       CONCAT(IF(ok, pontos, 0.0), ' / ', pontos) AS `Pontos`,
       detalhe AS `Mensagem do MySQL`
FROM _resultado
ORDER BY id;

SELECT questao AS `Questão`,
       SUM(IF(ok, pontos, 0)) AS `Obtido`,
       SUM(pontos) AS `Valor`
FROM _resultado
GROUP BY questao
ORDER BY questao;

SELECT CONCAT(SUM(IF(ok, pontos, 0)), ' de 10,0') AS `NOTA ESTIMADA (o professor também lê o código)`
FROM _resultado;

-- deixa o banco com os dados iniciais e apaga os objetos do verificador
CALL _reset();
DROP TABLE _resultado;
DROP PROCEDURE _ok;
DROP PROCEDURE _tenta;
DROP PROCEDURE _foto;
DROP PROCEDURE _existe;
DROP PROCEDURE _reset;
DROP PROCEDURE _q1;
DROP PROCEDURE _q2;
DROP PROCEDURE _q3;
DROP PROCEDURE _q4;
DROP PROCEDURE _q5;
