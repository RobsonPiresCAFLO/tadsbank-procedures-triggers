#!/usr/bin/env bash
# =====================================================================
# Atividade 04 – verificador automático
#
# 1. recria o banco tadsbank com os dados iniciais (sql/00_tadsbank.sql);
# 2. cria os seus triggers e procedures (sql/q1 ... q5, só a parte ANTES
#    da linha "TESTES");
# 3. roda os testes automáticos (testes/verificar.sql) e mostra a nota.
#
# Uso:
#   ./verificar.sh                      # container mysql-db (pede a senha do root)
#   CONTAINER=meu-mysql ./verificar.sh  # outro container
#   MYSQL_HOST=127.0.0.1 ./verificar.sh # cliente mysql instalado na máquina
#   ./resetar.sh                        # só os passos 1 e 2 (sem testes)
# =====================================================================
set -u
cd "$(dirname "$0")"

CONTAINER="${CONTAINER:-mysql-db}"
MYSQL_USER="${MYSQL_USER:-root}"
SO_RESETAR="${SO_RESETAR:-0}"

if [ -z "${MYSQL_PWD+x}" ]; then
  read -rsp "Senha do usuário $MYSQL_USER do MySQL: " MYSQL_PWD
  echo
fi
export MYSQL_PWD

mysql_cmd() {
  if [ -n "${MYSQL_HOST:-}" ]; then
    mysql -h "$MYSQL_HOST" -P "${MYSQL_PORT:-3306}" -u "$MYSQL_USER" \
          --default-character-set=utf8mb4 "$@"
  else
    docker exec -i -e MYSQL_PWD "$CONTAINER" \
          mysql -u "$MYSQL_USER" --default-character-set=utf8mb4 "$@"
  fi
}

# parte da questão que vale para o verificador: tudo antes da linha TESTES
sem_testes() {
  sed -e 's/\r$//' -e '/^-- *=\{3,\} *TESTES/,$d' "$1"
}

echo "== 1. Recriando o banco tadsbank (dados iniciais)"
if ! mysql_cmd < sql/00_tadsbank.sql > /dev/null; then
  echo "Não foi possível conectar ao MySQL ou criar o banco. Confira a senha e se o container está ligado (docker ps)."
  exit 1
fi

echo "== 2. Criando os seus triggers e procedures"
for f in sql/q[1-5]_*.sql; do
  echo "   - $f"
  sem_testes "$f" | mysql_cmd --force > /dev/null
done

if [ "$SO_RESETAR" = "1" ]; then
  echo "== Pronto: tadsbank com os dados iniciais e com os seus objetos."
  exit 0
fi

echo "== 3. Rodando os testes automáticos"
echo
mysql_cmd -t < testes/verificar.sql
