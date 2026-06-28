# 🔧 maintenance-ticketz

Script de manutenção preventiva para instalações [Ticketz](https://github.com/ticketz-oss/ticketz) usando Docker Compose.

## 📋 Sobre

Este script automatiza tarefas de manutenção que evitam lentidão e instabilidade no envio de mensagens do Ticketz:

- ✅ Remove sessões `BaileysKeys` do tipo `session` que se acumulam e causam loop de CPU/reconexões
- ✅ Remove `UserSocketSessions` antigas (>2h) que crescem indefinidamente
- ✅ Executa `VACUUM ANALYZE` em tabelas críticas sem bloquear o banco
- ✅ Reinicia toda a stack Ticketz para limpar sessões em memória
- ✅ Gera log com estatísticas antes/depois da limpeza

> ⚠️ **Compatibilidade**: Desenvolvido para instalações Ticketz via auto-instalador `ticketz-docker-acme`. Ajuste o nome do container PostgreSQL se necessário.

## 🏗️ Arquitetura

```
~/ticketz-docker-acme/    instalação Ticketz (auto-instalador)
~/maintenance-ticketz/    este projeto
  maintenance-ticketz.sh
  README.md
  LICENSE
  CONTRIBUTING.md
```

## 🚀 Instalação

### Pré-requisitos

- Ticketz instalado via `ticketz-docker-acme`
- Acesso root/sudo ao servidor
- Container PostgreSQL rodando com nome `ticketz-docker-acme-postgres-1`

### Setup

```bash
# Clone o repositório
git clone https://github.com/leostrongGG/maintenance-ticketz.git ~/maintenance-ticketz
cd ~/maintenance-ticketz
chmod +x maintenance-ticketz.sh
sudo touch /var/log/maintenance-ticketz.log
```

### Ajuste o nome do container (se necessário)

Edite a variável `CONTAINER` no início do script se o seu container PostgreSQL tiver outro nome:

```bash
CONTAINER="ticketz-docker-acme-postgres-1"
```

Verifique com:

```bash
docker ps --format '{{.Names}}' | grep postgres
```

## ⏰ Configuração do Cron

Recomenda-se executar aos domingos de madrugada, quando o uso do sistema é mínimo.

```bash
sudo crontab -e
```

Adicione a linha:

```cron
# Manutenção preventiva Ticketz - domingo 03h30
30 3 * * 0 cd ~/maintenance-ticketz && ./maintenance-ticketz.sh >> /var/log/maintenance-ticketz.log 2>&1
```

## 📊 O que o script faz

| Etapa | Descrição | Bloqueia tabelas? |
|---|---|---|
| Verificação | Confirma que o container PostgreSQL está rodando | — |
| Before stats | Conta sessões Baileys e UserSocketSessions antigas | — |
| Limpeza Baileys | `DELETE FROM "BaileysKeys" WHERE type = 'session'` | Não |
| Limpeza sockets | `DELETE FROM "UserSocketSessions" WHERE "createdAt" < NOW() - INTERVAL '2 hours'` | Não |
| VACUUM ANALYZE | Atualiza estatísticas do planner em tabelas críticas | Não |
| After stats | Conta novamente para o log | — |
| Restart stack | `docker compose down && docker compose up -d` | Indisponibilidade temporária (~30-90s) |

## 📝 Log

A saída é salva em `/var/log/maintenance-ticketz.log`. Acompanhe a última execução:

```bash
sudo tail -n 100 /var/log/maintenance-ticketz.log
```

## ⚠️ Avisos

- **Downtime**: o script reinicia toda a stack Ticketz. Em geral causa 30-90 segundos de indisponibilidade.
- **Execução manual**: para rodar fora do horário agendado:
  ```bash
  cd ~/maintenance-ticketz && sudo ./maintenance-ticketz.sh
  ```
- **Backup**: embora o script não altere dados de negócio, recomenda-se manter backups regulares do banco de dados.

## 🔧 Personalização

Você pode editar o script para:
- Adicionar mais tabelas no `VACUUM ANALYZE`
- Mudar o horário do cron
- Mudar o caminho do log

## 🤝 Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes.

## 📄 Licença

MIT License — veja [LICENSE](LICENSE) para detalhes.
