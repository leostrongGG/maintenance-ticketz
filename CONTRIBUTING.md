# Contribuindo para o maintenance-ticketz

Obrigado por considerar contribuir! 🎉

## Como Contribuir

1. **Fork** o projeto
2. Crie uma **branch** para sua feature (`git checkout -b feature/MinhaFeature`)
3. **Commit** suas mudanças (`git commit -m 'Add: descrição da feature'`)
4. **Push** para a branch (`git push origin feature/MinhaFeature`)
5. Abra um **Pull Request**

## Padrões de Commit

Use prefixos claros:
- `Add:` nova funcionalidade
- `Fix:` correção de bug
- `Docs:` documentação
- `Refactor:` refatoração sem mudança de comportamento
- `Test:` adicionar testes

## Reportar Bugs

Ao reportar bugs, inclua:
- Versão do sistema operacional
- Versão do Docker e Docker Compose
- Nome do container PostgreSQL no seu ambiente
- Log da execução (`/var/log/maintenance-ticketz.log`)
- Passos para reproduzir

## Sugestões de Features

Abra uma issue descrevendo:
- Problema que resolve
- Como funcionaria
- Exemplos de uso

## Testes

Antes de enviar PR:
1. Teste em ambiente não-produção
2. Verifique se o script não altera dados de negócio
3. Valide que o VACUUM ANALYZE não bloqueia consultas
4. Confirme que o log é gerado corretamente

## Dúvidas?

Abra uma issue ou discussion no GitHub!
