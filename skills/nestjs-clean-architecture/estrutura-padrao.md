# Estrutura padrão — modelo obrigatório de feature

Status: **obrigatório para todos os projetos** da família (ERPCLASS / NFECLASS /
MOBICLASS / CLOUDCLASS / SHOPCLASS / CRMCLASS). Vale para toda feature nova e
todo agregado novo, sem exceção.

Este documento existe para eliminar o retrabalho de "fazer de um jeito e depois
refazer": ele é o **molde**, não uma sugestão. Copie os esqueletos daqui, troque
os nomes, e a feature nasce conforme. Se algo aqui não servir para o seu caso,
isso é uma divergência consciente — registre em ADR antes de escrever o código
(ver §"Divergência" no fim).

> Régua maior: [SKILL.md](SKILL.md) §2 (arquitetura), §2.9 ([swagger.md](swagger.md)),
> §5 (testes), §7 (checklist). Este arquivo é a materialização do §3 ("Fluxo para
> Criar uma Nova Feature") em arquivos concretos.

---

## 1. A cadeia (decore isto)

```
Controller ──▶ Application ──▶ Domain: Database ──▶ Domain: Repository ──▶ TypeORM
  (HTTP)        (caso de uso)     (queries+cache)      (CRUD genérico)
```

Regras que **nunca** se quebram:

| # | Regra |
|---|---|
| 1 | Controller injeta **só** `<FEATURE>_APPLICATION`. Nunca Database, nunca Repository. |
| 2 | Application injeta **só** `<FEATURE>_DATABASE`. **Nunca o Repository concreto.** |
| 3 | Database injeta o **Repository concreto** (classe), e só ele. |
| 4 | Repository injeta o `Repository<Entity>` do TypeORM via token `POSTGRES_<AGREGADO>`. |
| 5 | Toda travessia de camada é **interface + token**, nunca classe concreta. |
| 6 | Controller não tem regra de negócio. Repository não tem regra de negócio. |

## 2. Nomes: plural × singular (a fonte de metade dos erros)

- **Plural = feature** → controller, application, database, module: `users.*`, `accountings.*`
- **Singular = agregado** → entity, repository, provider: `user.*`, `accounting.*`

Nome de domínio em **português** quando o domínio já é português (`clientes`,
`pedidos`, `comissoes`) — o vocabulário técnico (`Repository`, `Database`,
`getById`) continua em inglês. Ver SKILL.md §1.2.

## 3. Mapa de arquivos (13 arquivos por feature+agregado)

Exemplo: feature `accountings`, agregado `accounting`.

```
src/domain/entities/accounting/
├── accounting.entity.ts          # @Entity, construtor privado + static factory()
├── accounting.interface.ts       # contrato de dados, extends BaseInterface
└── index.ts

src/domain/repositories/accounting/
├── accounting.provider.ts        # Repository<Entity> a partir do DataSource
├── accounting.repository.ts      # extends RepositoryBase<Entity> (+ invalidateCache)
├── accounting.module.ts          # AccountingRepositoryModule
└── index.ts

src/domain/database/accountings/
├── accountings.database.ts       # extends DatabaseBase<Entity>
├── accountings.interface.ts      # métodos de DOMÍNIO (não CRUD genérico)
├── accountings.types.ts          # ACCOUNTINGS_DATABASE
├── accountings.module.ts         # AccountingsDatabaseModule
└── index.ts

src/application/accountings/
├── accountings.application.ts
├── accountings.interface.ts
├── accountings.consts.ts         # ACCOUNTINGS_APPLICATION
├── accountings.exceptions.ts     # derivam BaseException, mensagem em PT
├── accountings.module.ts
└── index.ts

src/controllers/accountings/
├── accountings.controller.ts     # já com Swagger completo
├── accountings.request.ts        # class-validator
├── accountings.response.ts       # @Expose() campo a campo
└── index.ts
```

## 4. Os esqueletos

### 4.1 `accounting.provider.ts`

```ts
import { DataSource, Repository } from 'typeorm';

import { AccountingEntity } from '@/domain/entities';

export const AccountingProvider = [
  {
    provide: 'POSTGRES_ACCOUNTING',
    useFactory: (connection: DataSource): Repository<AccountingEntity> => {
      return connection.getRepository<AccountingEntity>(AccountingEntity);
    },
    // O DataSource certo para o banco desta entidade. Um projeto multi-banco
    // tem mais de um: POSTGRES_SOURCE, POSTGRES_ADMIN_SOURCE, ...
    inject: ['POSTGRES_SOURCE'],
  },
];
```

### 4.2 `accounting.repository.ts`

```ts
import { Inject } from '@nestjs/common';

import { DataSource, Repository } from 'typeorm';

import { AccountingEntity } from '@/domain/entities';

import { RepositoryBase } from '../repository.base';

export class AccountingRepository extends RepositoryBase<AccountingEntity> {
  constructor(
    @Inject('POSTGRES_ACCOUNTING') protected readonly repository: Repository<AccountingEntity>,
    @Inject('POSTGRES_SOURCE') private readonly dataSource: DataSource
  ) {
    super(repository);
  }

  /** Só métodos que exigem o DataSource. CRUD comum já vem do RepositoryBase. */
  async invalidateCache(identifiers: string[]): Promise<void> {
    await this.dataSource.queryResultCache?.remove(identifiers);
  }
}
```

### 4.3 `accounting.module.ts`

```ts
import { Module } from '@nestjs/common';

import { ConnectionModule } from '@/domain/connection';

import { AccountingProvider } from './accounting.provider';
import { AccountingRepository } from './accounting.repository';

@Module({
  imports: [ConnectionModule],
  providers: [AccountingRepository, ...AccountingProvider],
  exports: [AccountingRepository],
})
export class AccountingRepositoryModule {}
```

### 4.4 `accountings.interface.ts` (Database)

Métodos de **domínio**, nunca `save`/`find` cru:

```ts
import { AccountingInterface } from '@/domain/entities';

export interface AccountingsDatabaseInterface {
  createAccounting(data: AccountingInterface): Promise<AccountingInterface>;
  getAccountingById(id: string): Promise<AccountingInterface | undefined>;
  listAccountingsBySubscription(subscriptionId: string): Promise<AccountingInterface[]>;
  updateAccounting(id: string, data: Partial<AccountingInterface>): Promise<void>;
}
```

### 4.5 `accountings.database.ts`

```ts
import { Injectable } from '@nestjs/common';

import { DatabaseBase } from '@/domain/database/database.base';
import { DatabaseBaseInterface } from '@/domain/database/database.interface';
import { AccountingEntity, AccountingInterface } from '@/domain/entities';
import { AccountingRepository } from '@/domain/repositories';

import { AccountingsDatabaseInterface } from './accountings.interface';

/** Chave de cache por subscription — invalidada em todo write desta feature. */
const ACCOUNTINGS_CACHE_PREFIX = 'accountings:subscription';

@Injectable()
export class AccountingsDatabase
  extends DatabaseBase<AccountingEntity>
  implements DatabaseBaseInterface<AccountingEntity>, AccountingsDatabaseInterface
{
  constructor(protected repository: AccountingRepository) {
    super(repository);
  }

  async listAccountingsBySubscription(subscriptionId: string): Promise<AccountingInterface[]> {
    return await this.findWithCache({ where: { subscriptionId }, order: { name: 'ASC' } }, 'dynamic');
  }

  async createAccounting(data: AccountingInterface): Promise<AccountingInterface> {
    const created = await this.repository.upsert(AccountingEntity.factory(data));
    // Invalidação explícita: sem isso a lista serve dado velho pelo TTL inteiro.
    await this.repository.invalidateCache([`${ACCOUNTINGS_CACHE_PREFIX}:${data.subscriptionId}`]);
    return created;
  }
}
```

### 4.6 `accountings.types.ts` e `accountings.module.ts` (Database)

```ts
export const ACCOUNTINGS_DATABASE = 'ACCOUNTINGS_DATABASE';
```

```ts
import { Module } from '@nestjs/common';

import { AccountingRepositoryModule } from '@/domain/repositories';

import { AccountingsDatabase } from './accountings.database';
import { ACCOUNTINGS_DATABASE } from './accountings.types';

@Module({
  imports: [AccountingRepositoryModule],
  providers: [{ provide: ACCOUNTINGS_DATABASE, useClass: AccountingsDatabase }],
  exports: [ACCOUNTINGS_DATABASE],
})
export class AccountingsDatabaseModule {}
```

### 4.7 `accountings.application.ts`

```ts
import { Inject, Injectable } from '@nestjs/common';

import { ACCOUNTINGS_DATABASE, AccountingsDatabaseInterface } from '@/domain/database';

import { AccountingNotFoundException } from './accountings.exceptions';
import { AccountingsApplicationInterface } from './accountings.interface';

@Injectable()
export class AccountingsApplication implements AccountingsApplicationInterface {
  constructor(
    @Inject(ACCOUNTINGS_DATABASE) private readonly accountingsDatabase: AccountingsDatabaseInterface
  ) {}

  async getAccountingById(id: string): Promise<AccountingInterface> {
    const accounting = await this.accountingsDatabase.getAccountingById(id);
    if (!accounting) {
      throw new AccountingNotFoundException();
    }
    return accounting;
  }
}
```

### 4.8 `accountings.exceptions.ts`

```ts
import { HttpStatus } from '@nestjs/common';

import { BaseException } from '@/exceptions';

export class AccountingNotFoundException extends BaseException {
  constructor() {
    super('Contabilidade não encontrada', HttpStatus.NOT_FOUND);
  }
}
```

### 4.9 `accountings.controller.ts`

```ts
@ApiTags('accountings')
@ApiBearerAuth('JWT')
@Controller('api/v1/accountings')
@UseGuards(TokenGuard)
export class AccountingsController {
  constructor(
    @Inject(ACCOUNTINGS_APPLICATION) private readonly accountingsApplication: AccountingsApplicationInterface
  ) {}

  /** GET /:id — Retorna uma contabilidade. Rota administrativa (requer TokenGuard). */
  @Get(':id')
  @ApiOperation({ summary: 'Busca uma contabilidade por id' })
  @ApiResponse({ status: 200, description: 'Contabilidade encontrada', type: AccountingResponse })
  @ApiResponse({ status: 400, description: 'Id inválido' })
  @ApiResponse({ status: 401, description: 'JWT ausente ou inválido' })
  @ApiResponse({ status: 404, description: 'Contabilidade não encontrada' })
  async getById(@Param('id', ParseUUIDPipe) id: string): Promise<AccountingResponse> {
    const accounting = await this.accountingsApplication.getAccountingById(id);
    return plainToInstance(AccountingResponse, accounting, { excludeExtraneousValues: true });
  }
}
```

### 4.10 `accountings.response.ts`

`excludeExtraneousValues: true` só protege se **cada** campo permitido tiver
`@Expose()`. Campo sem `@Expose()` não sai — é isso que impede o vazamento.

```ts
import { Expose } from 'class-transformer';

export class AccountingResponse {
  @Expose()
  id!: string;

  @Expose()
  name!: string;
}
```

## 5. Wiring (o passo esquecido com mais frequência)

Um artefato criado e não registrado é código morto que só falha em runtime:

- [ ] Entidade no `entities: [...]` do **DataSource certo** (runtime) **e** no harness de teste
- [ ] `<Name>RepositoryModule` importado por quem usa (a Database da feature)
- [ ] `<Feature>DatabaseModule` registrado em `src/domain/database/database.module.ts`
- [ ] `<Feature>Module` (Application) registrado em `src/application/application.module.ts`
- [ ] `<Feature>Controller` registrado em `src/controllers/controllers.module.ts`

## 6. Checklist de conformidade (cole no PR)

- [ ] 13 arquivos do §3 criados, com plural/singular do §2
- [ ] Application **não** importa nada de `domain/repositories`
- [ ] Nenhuma classe concreta atravessando camada (só interface + token)
- [ ] Response DTO com `@Expose()` + `plainToInstance(..., { excludeExtraneousValues: true })`
- [ ] `*.exceptions.ts` derivando `BaseException`, mensagem em **português**
- [ ] Swagger completo por rota: `@ApiOperation` + `@ApiResponse` (2xx, 400, 401/403, 404/409 quando houver)
- [ ] Sem `relations: [...]` em query de lista (§4.1)
- [ ] Cache invalidado explicitamente após todo write (§4.2)
- [ ] Wiring do §5 completo
- [ ] **Testes (§5.1/§5.2):** unitário da Application e da Database; **integração** do Repository (query custom) e de **toda migration nova**; suíte rodada e **passando**
- [ ] `npm run lint` e `npm run build` limpos

## 7. Armadilhas reais (todas já custaram retrabalho)

| Armadilha | Sintoma | Evite assim |
|---|---|---|
| Entidade fora do `entities` do DataSource | `No metadata for "X" was found` — **só em runtime** | §5, primeiro item. Teste de integração do repository pega; teste de migration com SQL cru **não** pega |
| Cache do TypeORM com `type: 'redis'` num projeto que usa `ioredis` | `Cannot use cache because redis is not installed` **só quando a app real sobe** | Use o `type` do cliente instalado (`ioredis`) |
| `findWithCache` sem `cache` configurado no DataSource | Exceção na primeira chamada | Configure `cache` no DataSource antes de usar `DatabaseBase` |
| Teste que "prova" configuração usando harness próprio | Passa sem provar nada | Prove no boot real (e2e), não num DataSource paralelo |
| Paginação com `ORDER BY` de coluna não-única | Linha repete numa página e some da outra; teste "flaky" | Sempre desempate por chave única (`addOrderBy(id)`) |
| Copiar o módulo vizinho em vez deste modelo | Propaga o legado e gera retrabalho | Este arquivo é a fonte. O vizinho pode estar errado |
| Artefato criado sem registrar no módulo global | Provider não resolve; erro só no boot | §5 |
| `@SkipThrottle` em `/metrics` | Não funciona: a rota é do `PrometheusModule` | Guard próprio com allowlist de path |

## 8. Divergência

Precisou fugir deste modelo? Então:

1. **Não escreva o código ainda.**
2. Reporte a divergência, com custo/benefício, e **peça confirmação**.
3. Aprovada, registre em `docs/adr/` do repo (o quê, por quê, e o que fica de dívida).
4. Só então implemente.

Divergência não registrada é bug, não estilo.
