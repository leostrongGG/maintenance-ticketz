#!/bin/bash
# maintenance-ticketz.sh
# Manutencao preventiva do banco Ticketz.
# Recomendado: executar em horario de baixo uso (ex: domingo 03h30 via cron).
#
# O que faz:
# - Limpa sessoes Baileys corrompidas/acumuladas (BaileysKeys.type='session')
# - Limpa UserSocketSessions antigas (>2h)
# - Executa VACUUM ANALYZE em tabelas criticas (nao bloqueia)
# - Reinicia toda a stack Ticketz via docker compose
# - Loga saida em /var/log/maintenance-ticketz.log

set -euo pipefail

CONTAINER="ticketz-docker-acme-postgres-1"
DB="ticketz"
USER="ticketz"
LOG="/var/log/maintenance-ticketz.log"

exec > >(tee -a "${LOG}") 2>&1

echo "==================================================================="
echo "  Ticketz Weekly Maintenance - $(date -Iseconds)"
echo "==================================================================="

# Verifica se o container postgres esta rodando
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERRO: Container ${CONTAINER} nao encontrado. Abortando."
  exit 1
fi

PSQL="docker exec ${CONTAINER} psql -U ${USER} -d ${DB} -q"

echo ""
echo "--- Antes da limpeza ---"
${PSQL} -c "SELECT 'BaileysKeys sessions' AS item, COUNT(*) AS qtd FROM \"BaileysKeys\" WHERE type = 'session' UNION ALL SELECT 'UserSocketSessions >2h', COUNT(*) FROM \"UserSocketSessions\" WHERE \"createdAt\" < NOW() - INTERVAL '2 hours';"

echo ""
echo "--- Limpando BaileysKeys sessions ---"
${PSQL} -c "DELETE FROM \"BaileysKeys\" WHERE type = 'session';"

echo ""
echo "--- Limpando UserSocketSessions antigas ---"
${PSQL} -c "DELETE FROM \"UserSocketSessions\" WHERE \"createdAt\" < NOW() - INTERVAL '2 hours';"

echo ""
echo "--- Executando VACUUM ANALYZE ---"
${PSQL} -c "VACUUM ANALYZE \"Messages\";"
${PSQL} -c "VACUUM ANALYZE \"Contacts\";"
${PSQL} -c "VACUUM ANALYZE \"TicketTraking\";"
${PSQL} -c "VACUUM ANALYZE \"Tickets\";"
${PSQL} -c "VACUUM ANALYZE \"BaileysKeys\";"
${PSQL} -c "VACUUM ANALYZE \"UserSocketSessions\";"

echo ""
echo "--- Depois da limpeza ---"
${PSQL} -c "SELECT 'BaileysKeys sessions' AS item, COUNT(*) AS qtd FROM \"BaileysKeys\" WHERE type = 'session' UNION ALL SELECT 'UserSocketSessions >2h', COUNT(*) FROM \"UserSocketSessions\" WHERE \"createdAt\" < NOW() - INTERVAL '2 hours';"

echo ""
echo "--- Reiniciando toda a stack Ticketz ---"
cd ~/ticketz-docker-acme || exit 1
docker compose down
docker compose up -d

echo ""
echo "==================================================================="
echo "  Manutencao concluida - $(date -Iseconds)"
echo "==================================================================="
echo ""
