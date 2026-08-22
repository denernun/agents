---
name: nestjs-clean-architecture
description: NestJS Clean Architecture + DDD conventions for ERPCLASS/NFECLASS/MOBICLASS APIs. Use when editing NestJS/TypeScript backend code in *-api, *-auth, *-sync, *-hook, or when adding controllers, endpoints, DTOs, or Swagger/OpenAPI.
---
Você é um(a) programador(a) sênior em TypeScript com experiência em NestJS, Clean Architecture e Domain-Driven Design (DDD), atuando em APIs NestJS desta família (ERPCLASS / NFECLASS / MOBICLASS).

Gere código, correções e refatorações que sigam **rigorosamente** as diretrizes deste documento — elas refletem a arquitetura real do projeto, não um padrão genérico.

- Interaja em **português** no chat.
- Escreva **todo o código, identificadores, comentários e JSDoc em inglês**.
- Em caso de conflito entre "boas práticas genéricas" e "padrões observados no projeto", **os padrões do projeto vencem**.

---

## 1. Diretrizes Gerais de TypeScript

### 1.1 Princípios Básicos

- Declare o tipo de toda variável, parâmetro e retorno de função. **Nunca use `any`** — crie os tipos/interfaces necessários.
- Um único artefato principal exportado por arquivo (a interface associada pode conviver no mesmo arquivo quando trivial).
- Documente classes e métodos públicos com **JSDoc** explicando o _porquê_ (regra de negócio, decisão de cache, contrato com o ERP), não o _o quê_.
- Não deixe linhas em branco dentro do corpo de uma função.
- Prefira **imutabilidade**: `readonly` para dados que não mudam, `as const` para literais.
- **Decorators de propriedade sempre acima do campo** — nunca inline. O Prettier não corrige isso; o agente/IDE deve gerar assim:
  ```ts
  // ❌ @Expose() id!: string;
  // ✅
  @Expose()
  id!: string;
  ```

### 1.2 Nomenclatura

- `PascalCase` para classes, tipos e interfaces (`AccountsApplication`, `AccountInterface`).
- `camelCase` para variáveis, funções e métodos.
- `kebab-case` para diretórios; arquivos seguem o padrão `<name>.<artifact>.ts` (ex: `accounts.controller.ts`, `account.entity.ts`).
- `UPPERCASE_SNAKE_CASE` para constantes de tempo de compilação, variáveis de ambiente e **tokens de injeção** (`ACCOUNTS_APPLICATION`, `ACCOUNTS_DATABASE`, `POSTGRES_ACCOUNT`).
- **Regra de plural/singular do projeto** (importante):
  - **Plural** (`accounts.*`): controllers, applications, databases, modules — nomeados pela _feature_.
  - **Singular** (`account.*`): entities, repositories, providers — nomeados pelo _agregado_.
- Prefixos verbais para booleanos: `isLoading`, `hasError`, `canDelete`, `businessChanged`.
- Toda função começa com um verbo (`getAccountById`, `createAccount`, `invalidateAllAccountsCache`).
- Evite abreviações, exceto as universais (`API`, `URL`, `DTO`, `TTL`) e as convenções curtas: `i`/`j` em loops, `err`, `ctx`, `req`/`res`/`next`.

### 1.3 Funções e Métodos

- Curtas, com **um único propósito**, idealmente < 20 instruções.
- Um único nível de abstração por função.
- Use **early returns** para evitar aninhamento.
- Higher-order functions (`map`/`filter`/`reduce`) em vez de loops aninhados.
- Arrow functions para expressões simples (< 3 instruções); funções nomeadas para o resto.
- Use parâmetros default em vez de checar `null`/`undefined`.
- **RO-RO** (Request Object / Response Object): quando uma função tiver mais de 2–3 parâmetros, receba um objeto tipado e devolva um objeto tipado.

### 1.4 Dados

- Não abuse de tipos primitivos — encapsule em tipos compostos (interfaces do domínio).
- Validação de dados **na fronteira** (DTOs com `class-validator`), não espalhada em cada função.

### 1.5 Classes

- Siga **SOLID**; prefira **composição sobre herança**.
- Toda dependência entre camadas é feita via **interface + token de injeção**.
- Mantenha classes pequenas: idealmente < 200 linhas, < 10 métodos públicos, < 10 propriedades.

### 1.6 Exceções

- Exceções para erros **inesperados** ou eventos de negócio nomeados.
- **Cada feature tem seu `*.exceptions.ts`** com classes que estendem `BaseException` (`src/exceptions/base.exception.ts`), com mensagem em português e `HttpStatus` apropriado. Exemplo: `AccountNotFoundException extends BaseException`.
- Capture uma exceção apenas para **corrigir um caso esperado** ou **adicionar contexto**. Caso contrário, deixe o filtro global `AppException` tratar.

---

## 2. Arquitetura do Projeto (erpclass-api)

O projeto segue uma arquitetura em camadas com **quatro camadas de dados**, orquestradas por módulos globais em `src/app.module.ts`.

```
Controller (HTTP)
    │  injeta ACCOUNTS_APPLICATION
    ▼
Application (use case + cache Redis + regra de fluxo)
    │  injeta ACCOUNTS_DATABASE
    ▼
Database (queries por feature + cache TypeORM + invalidação)
    │  injeta AccountRepository (classe)
    ▼
Repository (wrapper CRUD genérico sobre TypeORM)
    │  injeta POSTGRES_ACCOUNT (Repository<AccountEntity>)
    ▼
TypeORM / PostgreSQL
```

### 2.1 Mapa de Diretórios

| Camada / Papel            | Caminho                           | Responsabilidade                                                               |
| ------------------------- | --------------------------------- | ------------------------------------------------------------------------------ |
| **Presentation**          | `src/controllers/<feature>/`      | HTTP: rotas, DTOs, guards, throttling                                          |
| **Application**           | `src/application/<feature>/`      | Casos de uso, orquestração, cache Redis                                        |
| **Domain — Entities**     | `src/domain/entities/<name>/`     | Entidades TypeORM + interface de dados                                         |
| **Domain — Database**     | `src/domain/database/<feature>/`  | Serviço de acesso a dados por feature + cache TypeORM                          |
| **Domain — Repositories** | `src/domain/repositories/<name>/` | Wrapper genérico sobre `Repository<T>` do TypeORM                              |
| **Domain — Connection**   | `src/domain/connection/`          | DataSources (`POSTGRES_SOURCE`, `POSTGRES_CONNECTION`)                         |
| **Auth**                  | `src/auth/`                       | Autenticação, guards, strategies, social providers                             |
| **Config**                | `src/config/`                     | `ConfigService` + `.<env>.json`                                                |
| **Services**              | `src/services/`                   | Serviços transversais: `cache`, `logger`, `notify`, `queue`                    |
| **Gateway**               | `src/gateway/`                    | Comunicação externa: `api`, `geo`, `mail`, `socket`, `upload`                  |
| **Decorators**            | `src/decorators/`                 | Decorators customizados (`@User`, `@Device`, `@Role`, `@Logger`)               |
| **Pipes**                 | `src/pipes/`                      | Pipes customizados                                                             |
| **Exceptions**            | `src/exceptions/`                 | `BaseException` e derivadas transversais                                       |
| **Metrics**               | `src/metrics/`                    | Pyroscope, tracing                                                             |
| **Helper**                | `src/helper/`                     | Utilidades puras (`toDate`, `toInteger`, `ColumnIntTransformer`)               |
| **Core**                  | `src/app.*.ts`                    | `AppModule`, `AppException` (global filter), `AppInterceptor`, `AppMiddleware` |

### 2.2 Camada de Apresentação — `src/controllers/<feature>/`

Arquivos por feature: `<feature>.controller.ts`, `<feature>.request.ts`, `<feature>.response.ts`, `index.ts`.

**Regras:**

- **DEVE** injetar apenas serviços da Application via token (`@Inject(ACCOUNTS_APPLICATION) private accountsApplication: AccountsApplicationInterface`).
- **NÃO DEVE** conter lógica de negócio nem acessar Database/Repository/Entity diretamente (exceto `Entity.factory()` para construir o objeto a partir do request).
- **DEVE** usar `Guards` (`TokenGuard`), `Interceptors` (`ClassSerializerInterceptor`), `Pipes` (`ParseUUIDPipe`), `@Throttle`, `@HttpCode`.
- **DEVE** transformar a resposta com `plainToInstance(FeatureResponse, data, { excludeExtraneousValues: true })`.
- Prefixo de rota padrão: `api/v1/<feature>`.
- Cada método público tem JSDoc no formato: `<VERB> /rota — <descrição de negócio>. <Rota pública ou administrativa (requer TokenGuard)>`.
- **DEVE** sair com Swagger (ver §2.9): `@ApiTags`, `@ApiOperation`, `@ApiResponse`, e `@ApiBearerAuth` se a rota usa JWT/`TokenGuard`. Sem documentação OpenAPI a rota não está pronta.

**DTOs de request** (`*.request.ts`): classes com `class-validator` (`@IsString`, `@IsNumber`, `@IsOptional`, `@IsBoolean`) e `class-transformer` (`@Transform(({ value }) => toDate(value))` para coerção). Um arquivo pode conter várias `Request` classes relacionadas.

**DTOs de response** (`*.response.ts`): classes marcadas com `@Expose()` em cada campo permitido. Nunca vaze relações ou campos administrativos internos por acidente — o `excludeExtraneousValues: true` depende disso.

### 2.3 Camada de Aplicação — `src/application/<feature>/`

Arquivos por feature: `<feature>.application.ts`, `<feature>.interface.ts`, `<feature>.consts.ts`, `<feature>.exceptions.ts`, `<feature>.module.ts`, `index.ts`.

**Regras:**

- Classe `@Injectable()` implementando `FeatureApplicationInterface`.
- Injeta:
  - `@Inject(ACCOUNTS_DATABASE) private accountsDatabase: AccountsDatabaseInterface` (nunca o repositório concreto).
  - `@Inject(CACHE_SERVICE) private cacheService: CacheServiceInterface` e outros serviços transversais quando necessário.
- **DEVE** orquestrar o caso de uso: consultar cache Redis, decidir se o write no banco é necessário (padrão de _fingerprint_), lançar exceções de negócio (`AccountNotFoundException`).
- **NÃO DEVE** conhecer HTTP (`req`/`res`) nem TypeORM.
- **NÃO DEVE** importar de `src/domain/repositories` diretamente — sempre pela camada Database.
- Constantes de cache/TTL declaradas no topo do arquivo, com comentário explicando o motivo do valor.
- Token de injeção no `*.consts.ts`: `export const ACCOUNTS_APPLICATION = 'ACCOUNTS_APPLICATION';`.
- Módulo registra o binding: `{ provide: ACCOUNTS_APPLICATION, useClass: AccountsApplication }` e exporta o token.

### 2.4 Camada de Domínio — Entidades

Arquivos por agregado (singular): `src/domain/entities/<name>/<name>.entity.ts` + `<name>.interface.ts` + `index.ts`.

**Regras:**

- `<Name>Entity extends BaseEntity implements <Name>Interface`.
- Decoradores TypeORM: `@Entity({ name: '<table>' })`, `@Index(...)`, `@Column(...)`, relacionamentos.
- **Construtor `private`** + método estático `factory(data?: Partial<Interface>): Interface` para instanciar. Isso garante que a construção passe sempre por um ponto controlado.
- Relacionamentos declarados como **opcionais** (`user?: UserEntity`) — carregar sob demanda, ver §4.
- `<name>.interface.ts` define o contrato de dados (`extends BaseInterface`), sem dependências de TypeORM. É o tipo usado nas fronteiras entre camadas.

### 2.5 Camada de Domínio — Database

Arquivos por feature: `src/domain/database/<feature>/<feature>.database.ts` + `.interface.ts` + `.types.ts` + `.module.ts` + `index.ts`.

**Regras:**

- Classe `@Injectable()` `extends DatabaseBase<Entity> implements DatabaseBaseInterface<Entity>, FeatureDatabaseInterface`.
- Injeta o repositório concreto: `constructor(protected repository: AccountRepository)`.
- Métodos com nome de **domínio**, não CRUD genérico: `createAccount`, `getAllAccounts`, `updateAccountDashboard`, `getAccountById`. Nunca exponha `save`/`find` diretamente pela interface pública.
- **DEVE** gerenciar cache TypeORM via `findWithCache` / `findOneWithCache` (estratégias `'static' | 'dynamic' | 'volatile'`) e invalidar via `repository.invalidateCache([...])` após writes.
- Token no `*.types.ts`: `export const <FEATURE>_DATABASE = '<FEATURE>_DATABASE';`.
- Módulo: `{ provide: <FEATURE>_DATABASE, useClass: FeatureDatabase }`.

### 2.6 Camada de Domínio — Repository

Arquivos por agregado (singular): `src/domain/repositories/<name>/<name>.repository.ts` + `.provider.ts` + `.module.ts` + `index.ts`.

**Regras:**

- Classe `extends RepositoryBase<Entity>` — herda `count`, `exists`, `upsert`, `upsertNative`, `find`, `findOne`, `bulkInsert`, `bulkUpdate`, `findWithCache`, etc.
- Injeta o `DataSource` (`POSTGRES_CONNECTION`) e o `Repository<Entity>` do TypeORM (`POSTGRES_ACCOUNT`) — os tokens vêm do `<name>.provider.ts`.
- Adiciona **apenas** métodos específicos que exigem acesso direto ao `DataSource` (ex: `invalidateCache`). CRUD comum fica no `RepositoryBase`.
- `*.provider.ts` produz o `Repository<Entity>` a partir do `POSTGRES_SOURCE`:
  ```ts
  { provide: 'POSTGRES_ACCOUNT', useFactory: (c: DataSource) => c.getRepository(AccountEntity), inject: ['POSTGRES_SOURCE'] }
  ```

### 2.7 Camada de Infraestrutura Compartilhada

- **`src/services/`** — serviços globais (`CacheService`, `LoggerService`, `NotifyService`, `QueueService`), registrados como `@Global()` em `ServicesModule`. Injetáveis via token (`CACHE_SERVICE`, `LOGGER_SERVICE`, ...).
- **`src/gateway/`** — integrações externas (`mail`, `socket`, `upload`, `api`, `geo`).
- **`src/config/`** — `ConfigService` carrega `.<NODE_ENV>.json`. Acesso: `configService.getConfig.<área>.<chave>`.
- **`src/exceptions/base.exception.ts`** — `BaseException extends HttpException` com status default `BAD_REQUEST`.

### 2.8 Módulos Globais

`AppModule` importa `ConfigModule`, `AuthModule`, `ApplicationModule`, `ServicesModule`, `ControllersModule`, `PipesModule`, `DomainModule`, `GatewayModule`, `MetricsModule`. Filtros/interceptors/guards globais são registrados via `APP_FILTER`, `APP_INTERCEPTOR`, `APP_GUARD`.

### 2.9 Swagger / OpenAPI

Toda API NestJS desta família expõe OpenAPI. **Rota nova já nasce documentada.** Não altere lógica de negócio nem DTOs só para documentar. Summaries e tags do Swagger em **português** (como no `erpclass-auth`); identificadores e JSDoc continuam em inglês.

O MCP `openapi` (`@ivotoby/openapi-mcp-server`, modo `dynamic`) lê a spec em `/swagger/json` (ou o path do projeto) para validar requisitos e gerar testes. A API precisa estar no ar. Use `list-api-endpoints`, `get-api-endpoint-schema` e `invoke-api-endpoint` — não chame a API de produção.

**Se o projeto já tem Swagger** (ex: `erpclass-auth` em `/docs`): siga o path, o nome do Bearer e o idioma das tags que já existem. Não migre path.

**Se ainda não tem**, instale `@nestjs/swagger` (e `swagger-ui-express` se o Nest do repo ainda pedir) e configure no `main.ts` **antes** de `listen`:

- Título `{Produto} {App} API` (ex: `ERPClass Cob API`); versão lida de `package.json`.
- UI em `/swagger`; spec JSON em `/swagger/json` (`jsonDocumentUrl: 'swagger/json'`).
- `.addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }, 'JWT')` quando a API usa JWT/`TokenGuard`.
- Plugin do CLI em `nest-cli.json` para inferir tipos dos DTOs — **não** decore campo a campo com `@ApiProperty`. Configure `dtoFileNameSuffix` com **todos** os sufixos usados pelo projeto (`*.request.ts`, `*.response.ts`, `*.dto.ts`, `*.entity.ts`); sem isso, as classes de request/response saem com **schema vazio** no Swagger:

```json
"compilerOptions": {
  "plugins": [{
    "name": "@nestjs/swagger",
    "options": {
      "classValidatorShim": true,
      "introspectComments": true,
      "dtoFileNameSuffix": [".dto.ts", ".entity.ts", ".request.ts", ".response.ts"]
    }
  }]
}
```

- Se Helmet CSP bloquear a UI, libere scripts do Swagger; não desligue o Helmet inteiro.

**Em todo controller** (feature = pasta/domínio, ex: `titulos`, `cobrancas`, `evolution`):

```ts
@ApiTags('titulos')
@ApiBearerAuth('JWT')
@UseGuards(TokenGuard)
@Controller('api/v1/titulos')
export class TitulosController {
  @Get()
  @ApiOperation({ summary: 'Lista títulos com filtros e paginação' })
  @ApiResponse({ status: 200, description: 'Lista paginada' })
  @ApiResponse({ status: 400, description: 'Validação' })
  @ApiResponse({ status: 401, description: 'JWT ausente ou inválido' })
  listTitulos(): Promise<TitulosResponse> { /* ... */ }
}
```

| Obrigatório | Quando |
|---|---|
| `@ApiTags('<feature>')` | classe do controller |
| `@ApiOperation({ summary })` | cada rota; summary curto em português |
| `@ApiResponse` 200 ou 201 | sucesso (`type:` do Response DTO se já existir) |
| `@ApiResponse` 400 | body/query validado |
| `@ApiResponse` 401 e/ou 403 | rota com `TokenGuard` / roles |
| `@ApiBearerAuth('JWT')` | classe ou método com JWT (o nome `'JWT'` tem de bater com o `addBearerAuth`) |
| rotas públicas | omitir Bearer; não inventar 401 |

Ao pedir para “adicionar Swagger” num repo: só setup + decorators + plugin CLI. Ao criar endpoint: os decorators vão no mesmo PR da rota. Confirme UI em `/swagger` (ou o path do projeto) e JSON válido no endpoint da spec.

---

## 3. Fluxo para Criar uma Nova Feature

Ordem **de dentro para fora** (domínio → infraestrutura → aplicação → apresentação):

1. **Entidade** (`src/domain/entities/<name>/`)
   - `<name>.interface.ts` — contrato de dados estendendo `BaseInterface`.
   - `<name>.entity.ts` — classe TypeORM com `factory()` estático.
   - `index.ts` — reexporta ambos.
   - Registre a entidade em `src/domain/entities/index.ts`.

2. **Repository** (`src/domain/repositories/<name>/`)
   - `<name>.provider.ts` — factory do `Repository<Entity>` via `POSTGRES_SOURCE`.
   - `<name>.repository.ts` — classe `extends RepositoryBase<Entity>`.
   - `<name>.module.ts` — importa `ConnectionModule`, exporta o repositório concreto.
   - `index.ts`.

3. **Database** (`src/domain/database/<feature>/`)
   - `<feature>.interface.ts` — contrato de métodos de domínio (`createFeature`, `getFeatureById`, ...).
   - `<feature>.database.ts` — classe `extends DatabaseBase<Entity>` implementando o contrato, com cache/invalidação.
   - `<feature>.types.ts` — `export const <FEATURE>_DATABASE = '<FEATURE>_DATABASE';`.
   - `<feature>.module.ts` — `{ provide: <FEATURE>_DATABASE, useClass: FeatureDatabase }`.
   - `index.ts`.
   - Registre no `src/domain/database/database.module.ts`.

4. **Application** (`src/application/<feature>/`)
   - `<feature>.interface.ts` — contrato do caso de uso.
   - `<feature>.consts.ts` — `export const <FEATURE>_APPLICATION = '<FEATURE>_APPLICATION';`.
   - `<feature>.exceptions.ts` — exceções de negócio da feature.
   - `<feature>.application.ts` — orquestração com Database + serviços.
   - `<feature>.module.ts` — provider por token.
   - `index.ts`.
   - Registre em `src/application/application.module.ts`.

5. **Controller** (`src/controllers/<feature>/`)
   - `<feature>.request.ts` — DTOs de entrada com `class-validator`.
   - `<feature>.response.ts` — DTOs de saída com `@Expose()`.
   - `<feature>.controller.ts` — rotas HTTP chamando a Application, **já com** `@ApiTags` / `@ApiOperation` / `@ApiResponse` / `@ApiBearerAuth` (§2.9).
   - `index.ts`.
   - Registre em `src/controllers/controllers.module.ts`.

6. **Verificação:** rode `npm run lint` e `npm run build`. Erros de circular import geralmente indicam violação do fluxo de camadas (ex: Application importando Repository direto).

---

## 4. Regras Críticas de Performance e Cache

### 4.1 Nunca use eager loading em list queries

**Problema comprovado no projeto:** queries com `relations: ['user', 'update']` custaram 10–19s. Removendo, caíram para <100 ms (**197× mais rápido**).

- ❌ NÃO: `repository.find({ relations: ['user', 'update'] })` em listas.
- ✅ SIM: `repository.find({ order: { fantasia: 'ASC' } })` — sem relações.
- Se precisar dos dados relacionados, crie **endpoints dedicados**:
  - `GET /accounts` — lista sem relações.
  - `GET /accounts/:id` — dados básicos sem relações.
  - `GET /accounts/:id/details` — dados completos com relações.

**Regra de ouro:** carregue relações **apenas quando o dado será usado imediatamente**.

### 4.2 Cache em duas camadas

- **Redis (Application):** para fingerprints, contadores, status voláteis. TTL explícito, chave prefixada (`account:fingerprint:{id}`).
- **TypeORM (Database):** via `findWithCache`/`findOneWithCache` para listas e leituras frequentes. **Sempre invalide** com `repository.invalidateCache([...])` após writes.
- Documente no JSDoc _quando_ e _por que_ o cache é invalidado.

### 4.3 Writes desnecessários

Se uma rota pública recebe dados repetidos (ex: heartbeat do ERP), aplique o padrão **fingerprint** na Application: hash SHA-256 dos campos de negócio + comparação com o Redis antes de tocar o banco. Ver `AccountsApplication.createAccount` como referência.

### 4.4 Upsert em alta frequência

Use `repository.upsertNative(data, conflictPaths, overwrite)` (INSERT ... ON CONFLICT DO UPDATE) em vez de `save()` para eliminar o SELECT prévio do TypeORM em caminhos quentes.

---

## 5. Testing

- Framework: **Jest** (`jest -i --no-cache --detectOpenHandles --passWithNoTests --runInBand --forceExit`).
- **Arrange-Act-Assert** para testes unitários; **Given-When-Then** para testes de aceitação de módulo.
- Nomenclatura de variáveis de teste: `inputX`, `mockX`, `actualX`, `expectedX`.
- Um teste unitário para cada método público de controller/service/application/database.
- Use test doubles para dependências internas; dependências de terceiros baratas (ex: `class-transformer`) podem ser usadas de verdade.
- End-to-end tests por módulo de API.
- Cada controller pode expor um método `admin/test` como smoke test.

---

## 6. Checklist Antes de Entregar Código

- [ ] Camadas respeitadas: Controller → Application → Database → Repository. Sem "atalhos".
- [ ] Interfaces + tokens em uso; nenhuma classe concreta injetada onde deveria ser interface.
- [ ] Nomes de arquivos seguem `<name>.<artifact>.ts` com o plural/singular correto.
- [ ] JSDoc explicando **o porquê** em métodos públicos e em qualquer lógica de cache/fingerprint.
- [ ] Nenhum `any`, nenhuma magic number, nenhum campo vazando via `Response` DTO.
- [ ] Nenhuma relação eager em listas; `relations: [...]` só quando o dado é usado imediatamente.
- [ ] Cache invalidado explicitamente após writes.
- [ ] Exceções de negócio como classes derivadas de `BaseException`, mensagens em português.
- [ ] Novo módulo registrado no módulo global correspondente (`ApplicationModule`, `ControllersModule`, `DatabaseModule`).
- [ ] Swagger: `@ApiTags` + `@ApiOperation` + `@ApiResponse` (200/201, 400, 401/403 se autenticado); Bearer se JWT. Plugin CLI ligado com `dtoFileNameSuffix` cobrindo `.dto.ts`, `.entity.ts`, `.request.ts`, `.response.ts`. Sem `@ApiProperty` nos DTOs.
- [ ] `npm run lint` e `npm run build` sem erros.

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes_tool` or `query_graph_tool` instead of Grep
- **Understanding impact**: `get_impact_radius_tool` instead of manually tracing imports
- **Code review**: `detect_changes_tool` + `get_review_context_tool` instead of reading entire files
- **Finding relationships**: `query_graph_tool` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview_tool` + `list_communities_tool`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
| ------ | ---------- |
| `detect_changes_tool` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context_tool` | Need source snippets for review — token-efficient |
| `get_impact_radius_tool` | Understanding blast radius of a change |
| `get_affected_flows_tool` | Finding which execution paths are impacted |
| `query_graph_tool` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes_tool` | Finding functions/classes by name or keyword |
| `get_architecture_overview_tool` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes_tool` for code review.
3. Use `get_affected_flows_tool` to understand impact.
4. Use `query_graph_tool` pattern="tests_for" to check coverage.

