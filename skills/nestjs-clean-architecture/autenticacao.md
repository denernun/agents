---
name: autenticacao-nestjs
description: Padrão de autenticação das APIs NestJS ERPCLASS (JWT, x-api-key, apikey Evolution). Use ao criar projeto novo, endpoint, guard ou integração Connect/Bot/KB.
---

# Autenticação — padrão ERPCLASS

Três mecanismos. Não misture o header errado.

| Scheme | Header | Quem usa | Onde vive |
|---|---|---|---|
| JWT Bearer | `Authorization: Bearer <accessToken>` | Frontends (Connect, Cob, Dash, Admin…) contra APIs de produto | `erpclass-auth` emite; `TokenGuard` + `passport-jwt` nas APIs |
| API key de serviço | `x-api-key` | Bot → KB; KB → Bot (provision) | `ConfigInterface.auth.apiKey` (KB) / `knowledgeBase.apiKey` (bot) |
| API key Evolution | `apikey` | Evolution → KB webhook; KB → Bot webhook | `source.evolution.apiKey` (KB) / `evolution.apiKey` + `tenant.webhookSecret` (bot) |

OAuth2 social (Google/Facebook) existe só no **erpclass-auth** (login). APIs kb/bot **não** implementam OAuth.

## Como aplicar em API nova

### 1. Serviço machine-to-machine (padrão kb↔bot)

1. Guard com `timingSafeEqual` no header `x-api-key`.
2. Registrar `APP_GUARD` **ou** `@UseGuards` na classe (bot tenants usa o segundo).
3. Bypass de health/metrics: path `/metrics` e `/health` (ou `@Public()`).
4. Swagger: `.addApiKey({ name: 'x-api-key', in: 'header' }, 'apiKey')` + `@ApiSecurity('apiKey')`.

Referência: `erpclass-kb/src/guards/api-key.guard.ts`, `erpclass-bot/src/controllers/tenants/tenants.guard.ts`.

### 2. Frontend usuário (padrão Connect no KB)

1. `AuthModule` com `PassportModule` + `TokenStrategy` (`secretOrKey` = **o mesmo** `jwt.tokenSecret` do `erpclass-auth`).
2. **Não** registrar `TokenGuard` como `APP_GUARD` se a API já tem `ApiKeyGuard` global.
3. Rotas JWT: `@Public()` (bypass da API key) + `@UseGuards(TokenGuard, AccountAccessGuard)`.
4. `AccountAccessGuard`: admin passa; demais só `accountId` / `idAccounts` que o profile do auth devolver.
5. Swagger: `.addBearerAuth(..., 'JWT')` + `@ApiBearerAuth('JWT')`.

Referência: `erpclass-kb/src/auth/`.

O **erpclass-bot** valida o mesmo JWT **sem Passport** (`verifyHs256Jwt` + `TokenGuard` + `AccountAccessGuard`) nas rotas da inbox (`/api/v1/conversations`, `/api/v1/contacts`). Webhooks e provision continuam em API key.

### 3. Webhook Evolution (padrão kb + bot)

1. Header **`apikey`** (não é `x-api-key`).
2. KB: valida na Application (`EvolutionWebhookUnauthorizedException`).
3. Bot: valida no controller contra `tenant.webhookSecret`, `evolution.apiKey` e `evolution.webhookSecret`.
4. Rota sem throttling (`@SkipThrottle`) — o provedor dispara em rajada.
5. Resposta rápida (200/204). Processamento pesado em background.

`WebhookAuthGuard` no bot existe mas o webhook **atual** valida inline (multi-tenant). Não reative o guard antigo sem revisar o segredo por tenant.

## Onde configurar

| Segredo | KB `src/config/.<env>.json` | Bot `src/config/.<env>.json` |
|---|---|---|
| JWT | `jwt.tokenSecret` | `jwt.tokenSecret` (inbox Connect/CRM — `TokenGuard` HS256, sem Passport) |
| Key Bot↔KB | `auth.apiKey` **e** `bot.apiKey` | `knowledgeBase.apiKey` |
| Evolution | `source.evolution.apiKey` | `evolution.apiKey` / `evolution.webhookSecret` |
| Auth HTTP | `auth.apiUrl` | `auth.apiUrl` (profile para `AccountAccessGuard`) |
| Bot HTTP | `bot.apiUrl`, `bot.webhookUrl` | `api.port` |

JSON de config **entra no git** (sem `.example`). Não commitar valores de outro ambiente no arquivo errado.

## Throttling

`ThrottlerGuard` é `APP_GUARD` nos dois. Webhooks e provision usam `@SkipThrottle()`. Health/metrics: `@SkipThrottle()` + `@Public()` no KB.

## CORS

Liberar `Authorization`, `x-api-key` e `apikey` em `allowedHeaders` (já está no `main.ts` de kb/bot).

## Projeto novo — modelo a copiar

1. Guard global `x-api-key` se a API for só serviço.
2. Se houver UI: JWT local (não global) + `@Public()` nas rotas de usuário.
3. Se houver WhatsApp: webhook com `apikey`, nunca com JWT.
4. `timingSafeEqual` em toda comparação de secret.
5. Documentar os schemes no Swagger no **mesmo PR**.
