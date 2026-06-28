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

# Executa psql dentro do container PostgreSQL, onde /dev/shm tem o shm_size configurado no compose.
PSQL="docker exec ${CONTAINER} psql -U ${USER} -d ${DB} -q"

echo ""
echo "--- Parando backend do Ticketz ---"
cd ~/ticketz-docker-acme || exit 1
docker compose stop backend

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
# Reduz maintenance_work_mem para caber no /dev/shm do container (256 MB).
# Sem isso o PostgreSQL tenta alocar 512 MB (valor do override) e falha.
VACUUM_SQL=$(cat <<'EOF'
SET maintenance_work_mem = '128MB';
SET max_parallel_maintenance_workers = 0;
SET max_parallel_workers_per_gather = 0;
VACUUM ANALYZE "Messages";
VACUUM ANALYZE "Contacts";
VACUUM ANALYZE "TicketTraking";
VACUUM ANALYZE "Tickets";
VACUUM ANALYZE "BaileysKeys";
VACUUM ANALYZE "UserSocketSessions";
EOF
)

echo "${VACUUM_SQL}" | docker exec -i ${CONTAINER} psql -U ${USER} -d ${DB} -q

echo ""
echo "--- Depois da limpeza ---"
${PSQL} -c "SELECT 'BaileysKeys sessions' AS item, COUNT(*) AS qtd FROM \"BaileysKeys\" WHERE type = 'session' UNION ALL SELECT 'UserSocketSessions >2h', COUNT(*) FROM \"UserSocketSessions\" WHERE \"createdAt\" < NOW() - INTERVAL '2 hours';"

echo ""
echo "--- Reiniciando toda a stack Ticketz ---"
docker compose down
docker compose up -d

echo ""
echo "==================================================================="
echo "  Manutencao concluida - $(date -Iseconds)"
echo "==================================================================="
echo ""
