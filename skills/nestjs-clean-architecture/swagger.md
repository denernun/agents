---
name: swagger-openapi
description: Padrão obrigatório de Swagger/OpenAPI para **toda API NestJS** da família ERPCLASS/NFECLASS/MOBICLASS. Use ao criar ou revisar controllers, DTOs, DocumentBuilder ou nest-cli.json.
---

# Swagger / OpenAPI — padrão ERPCLASS

**Rota nova já nasce documentada.** Sem OpenAPI a rota não está pronta. Summaries e tags em **português**; identificadores e JSDoc em inglês.

**Todo projeto NestJS da família deve expor OpenAPI e documentar 100% dos endpoints de produto** (`/api/v1/...`). Health, metrics e raiz ficam fora da spec (`@ApiExcludeController`). Rotas de ops sem contrato de produto não contam como gap.

UI: `/swagger` · spec JSON: `/swagger/json` (`jsonDocumentUrl: 'swagger/json'`). Exceção legada: `erpclass-auth` usa `/docs` + `/docs-json` — não migrar.

## Referência viva

| App | Título | Esquemas no DocumentBuilder | Path |
|---|---|---|---|
| `erpclass-dash-api` | ERPClass Dash API | _(rotas públicas; JWT opcional repassado)_ | `/swagger` (dev) |
| `erpclass-kb` | ERPClass KB API | `apiKey` (`x-api-key`) | `/swagger` |
| `erpclass-bot` | ERPClass Bot API | `apikey` + `apiKey` (`x-api-key`) | `/swagger` |
| `erpclass-auth` | ERPClass Auth API | `JWT` Bearer | `/docs` (dev) |

Plugin CLI (`nest-cli.json`): `classValidatorShim`, `introspectComments`, `dtoFileNameSuffix`: `.dto.ts`, `.entity.ts`, `.request.ts`, `.response.ts`. Sem isso o schema sai vazio.

## Auditoria atual

### erpclass-dash-api

| Escopo | Auth real | Swagger | Notas |
|---|---|---|---|
| `POST /api/v1/financeiro/*` (7 rotas) | público | `@ApiTags('Financeiro')` + `@ApiDashboardPost` | Body genérico até DTOs dedicados |
| `POST /api/v1/vendas/*` (17 rotas) | público | `@ApiTags('Vendas')` + `@ApiDashboardPost` | Idem |
| `POST /api/v1/receber/*`, `pagar/*` | público | tags Contas a receber/pagar | Idem |
| `POST /api/v1/vendasExternas/*` | público + JWT opcional | `@ApiHeader authorization` opcional | `VendasExternasRequest` tipado |
| `POST /api/v1/agent/ask` | público + JWT opcional | `AgentAskRequest` tipado | Idem |
| `GET /health`, `GET /metrics`, `/` | ops | `@ApiExcludeController` | Intencional |

Helper compartilhado: `src/controllers/shared/swagger/dashboard-swagger.decorators.ts` (`ApiDashboardPost`).

### erpclass-kb

| Endpoint | Auth real | Swagger | Gaps |
|---|---|---|---|
| `POST /api/v1/kb/search` | `x-api-key` (global) | `@ApiTags` `@ApiSecurity('apiKey')` `@ApiOperation` 200 + `type` | Falta 400, 401; sem example |
| `GET /api/v1/kb/authorized-groups` | `x-api-key` | 200 + `type` | Falta 400 (UUID), 401 |
| `POST /api/v1/kb/ingest` | `x-api-key` | 201 + `type` | Falta 400, 401 |
| `GET/PUT /api/v1/connect/*` | JWT + `AccountAccessGuard` (`@Public` bypass da API key) | `@ApiBearerAuth('JWT')` 200/201 | **JWT não está no `DocumentBuilder`** — Authorize da UI não envia Bearer. Falta 400/401/403 |
| `POST/GET /api/v1/evolution/*` (exceto webhook) | JWT + account | Bearer + 400/401/404/409 | Mesmo gap: scheme `JWT` não registrado no builder |
| `POST /api/v1/evolution/webhook` | header `apikey` (Evolution) | `@ApiHeader` `@ApiBody` 204/401 | Completo o suficiente |
| `GET /health`, `GET /metrics`, `GET/POST /` | público / Prometheus | `@ApiExcludeController` | Intencional (ops) |

### erpclass-bot

| Endpoint | Auth real | Swagger | Gaps |
|---|---|---|---|
| `POST /webhook/evolution` | `apikey` (tenant + Evolution) | `@ApiTags` `@ApiOperation` 200 | Falta `@ApiHeader('apikey')`, 401, body schema |
| `POST /api/v1/tenants/provision` | `x-api-key` (`ApiKeyGuard`) | `@ApiSecurity('apiKey')` 200/400/401 | OK |
| `POST /api/v1/tenants/deactivate` | `x-api-key` | 204/400/401 | OK |
| `GET /health`, `GET /metrics`, `GET/POST /` | público | excluídos | Intencional |

Ao criar endpoint **novo**, feche os gaps da tabela (status + scheme no builder). Não reescreva DTOs só para documentar.

## Checklist obrigatório (todo endpoint novo)

Copie e marque no PR:

```
- [ ] DocumentBuilder já tem o scheme usado (JWT e/ou apiKey / apikey)
- [ ] nest-cli.json plugin com dtoFileNameSuffix completo
- [ ] @ApiTags('<feature>') na classe
- [ ] @ApiOperation({ summary }) em português, um por rota
- [ ] @ApiResponse sucesso (200/201/204) com type: do *.response.ts se existir
- [ ] @ApiResponse 400 se body/query é validado
- [ ] @ApiResponse 401/403 se há guard (API key, JWT, account)
- [ ] @ApiBearerAuth('JWT') se TokenGuard — nome idêntico ao addBearerAuth
- [ ] @ApiSecurity('apiKey') se x-api-key
- [ ] @ApiHeader({ name: 'apikey' }) se webhook Evolution
- [ ] Rota pública de produto: omitir Bearer; não inventar 401
- [ ] Health/metrics: @ApiExcludeController (não poluir a spec)
- [ ] Helmet CSP já libera script/style do Swagger UI
- [ ] Conferir UI /swagger e JSON /swagger/json
```

## Template de controller

```ts
@ApiTags('kb')
@ApiSecurity('apiKey')
@Controller('api/v1/kb')
export class KbSearchController {
  @Post('search')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Busca respostas na base de conhecimento curada' })
  @ApiResponse({ status: 200, description: 'Resultado da busca', type: KbSearchResponse })
  @ApiResponse({ status: 400, description: 'Validação do body' })
  @ApiResponse({ status: 401, description: 'x-api-key ausente ou inválida' })
  search(@Body() body: KbSearchRequest): Promise<KbSearchResponse> { /* ... */ }
}
```

JWT (Connect no KB):

```ts
@ApiTags('connect')
@ApiBearerAuth('JWT')
@Controller('api/v1/connect')
export class ConnectController {
  @Public()
  @UseGuards(TokenGuard, AccountAccessGuard)
  @Get('groups')
  @ApiOperation({ summary: 'Listar grupos WhatsApp da instância conectada' })
  @ApiResponse({ status: 200, description: 'Grupos retornados', type: [ConnectWhatsappGroupResponse] })
  @ApiResponse({ status: 400, description: 'accountId não é um UUID válido' })
  @ApiResponse({ status: 401, description: 'JWT ausente ou inválido' })
  @ApiResponse({ status: 403, description: 'Conta não pertence ao usuário' })
  listGroups(@Query('accountId', ParseUUIDPipe) accountId: string): Promise<ConnectWhatsappGroupResponse[]> { /* ... */ }
}
```

No `main.ts`, schemes usados nas anotações **têm** de existir:

```ts
.addApiKey({ type: 'apiKey', name: 'x-api-key', in: 'header' }, 'apiKey')
.addApiKey({ type: 'apiKey', name: 'apikey', in: 'header' }, 'apikey') // só se a API recebe webhook Evolution
.addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }, 'JWT') // se houver TokenGuard
.addTag('kb', 'Base de conhecimento')
```

## Schemas, exemplos e DTOs

- Plugin infere campos dos `*.request.ts` / `*.response.ts`. **Não** enfeitar todo campo com `@ApiProperty`.
- `@ApiProperty` / `@ApiPropertyOptional` só quando o plugin não basta (descrição, example, array aninhado). O KB search já faz isso em `history`/`namespace`.
- Exemplo de sucesso: `type:` no `@ApiResponse`. Exemplo de webhook livre: `@ApiBody({ schema: { type: 'object', additionalProperties: true } })`.
- `@Expose()` nos response DTOs continua obrigatório para o `plainToInstance` — não é substituto do Swagger.

## Health

`GET /health` e `GET /metrics` ficam **fora** da spec (`@ApiExcludeController`). Quem precisa de contrato HTTP de produto documenta em `/api/v1/...`.
