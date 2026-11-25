#!/usr/bin/env bash
# Volta o tadsbank aos dados iniciais e recria os seus triggers/procedures
# (sql/q1 ... q5, sem rodar os testes). Aceita as mesmas variáveis do verificar.sh.
cd "$(dirname "$0")"
SO_RESETAR=1 exec ./verificar.sh
