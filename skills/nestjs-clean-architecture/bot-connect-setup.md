---
name: bot-connect-setup
description: Visão do fluxo Connect + KB + Bot + Evolution. O passo a passo operacional completo está em erpclass-bot/docs/bot-connect-setup.md. Use ao implantar, debugar webhook ou provisionar tenant WhatsApp.
---

# Connect + Bot — mapa rápido

Passo a passo com riscos de omissão: **`erpclass-bot/docs/bot-connect-setup.md`**.

```
Connect (Angular, JWT)
    → erpclass-kb  /api/v1/evolution/*  e  /api/v1/connect/*
         → Evolution API (cria instância acc_{accountId}, registra webhook)
         → erpclass-bot  POST /api/v1/tenants/provision  (x-api-key)
Evolution
    → erpclass-kb  POST /api/v1/evolution/webhook  (header apikey)
         → erpclass-bot  POST /webhook/evolution  (header apikey, forward)
Bot
    → erpclass-kb  POST /api/v1/kb/search  e  GET /authorized-groups  (x-api-key)
```

## Crítico (não pular)

1. `jwt.tokenSecret` do KB = `erpclass-auth` — senão o Connect toma 401.
2. `x-api-key` do Bot = `auth.apiKey` / `bot.apiKey` do KB — senão provision e search falham em silêncio (KB loga warn).
3. `source.evolution.webhookUrl` **público** apontando para o KB — Evolution na vm07 não alcança `localhost` do seu PC.
4. `bot.webhookUrl` alcançável **a partir do processo KB** (no servidor: `http://localhost:3004/webhook/evolution`).
5. Instância sempre `acc_{accountId}` (UUID). Sem isso o tenant resolver ignora o webhook.
6. Header de webhook é **`apikey`**, não `x-api-key`.
7. OpenAI `apiKey` no KB — search sem chave não gera resposta útil.
8. Redis db **12** no bot; prefixo `bot:{tenantId}:`.
9. Certificados `certs/localhost.*` em dev HTTPS; em prod o nginx termina TLS.
10. Config JSON versionada — não gitignorar.

Ordem de subida: PostgreSQL/Redis → auth → Evolution → **kb** → **bot** → Connect.
