# Regras obrigatórias — cloudclass-api (persona app / cadastros)

Este anexo **complementa** [SKILL.md](SKILL.md) e **vence** código legado neste repositório. Divergência exige ADR em `docs/adr/`.

Aplicação limitada ao trabalho solicitado: não migre features existentes ou revogue
exceções aceitas automaticamente. As referências externas deste anexo pertencem ao
repositório `D:/SISTEMAS/CLOUDCLASS/cloudclass-api`, não ao AgentHub.

## Paths reais (dois bancos)

| Banco | Entities / Repositories / Migrations / Database |
|-------|--------------------------------------------------|
| `cloudclass` (app) | `src/domain/app/{entities,repositories,migrations,database}/` |
| `cloudclass_admin` | `src/domain/admin/{entities,repositories,migrations,database}/` |

Controllers e applications da persona operador: `src/controllers/app/`, `src/application/app/`.  
Rotas: `api/v1/app/<feature>`.

Não use `src/domain/entities/` neste repo — isso é template genérico do skill (ver [ADR-0005](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/docs/adr/0005-skill-como-autoridade-de-arquitetura.md) divergência admin/app).

## Copiar modelo, não vizinho

Feature nova: [estrutura-padrao.md](estrutura-padrao.md) com paths `domain/app/...`. Spec em `specs/cadastros/SPEC-<module-id>.md` antes do código ([CAPABILITY-MAP](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/specs/cadastros/CAPABILITY-MAP.md)).

## Índices de busca (não opcional)

Antes de mergear agregado com busca UX:

1. Listar campos em [INDEX-POLICY.md](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/specs/cadastros/INDEX-POLICY.md).
2. `@Index` na entity + migration (`up`/`down`).
3. Teste migration assertando índice.
4. Query no repository usando o índice; spec de integração.

**Cliente:** cpf, cnpj, nome (trgm). **Fornecedor:** cpf, cnpj, nome, razao. **Produto:** descrições, referencia, barra em `produto_estoque` / `fornecedor_produto`, códigos conforme spec.

## Paginação

| Lista | Mecanismo |
|-------|-----------|
| Catálogo pequeno (dezenas/centenas por tenant) | offset `findPaginated` + JSDoc "unpaginated on purpose" se aplicável |
| **produto**, **cliente**, **fornecedor** (fichas) | **keyset** — `{ items, nextCursor }`, sem `total` |
| Busca filtrada | keyset + filtros indexados |

Helpers: `src/domain/shared/repositories/keyset-pagination.ts`, `RepositoryBase.findKeyset`.

**Toda lista keyset segue o [ADR-0013](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/docs/adr/0013-keyset-cursor-tipado-e-contrato-de-teste.md):** `decodeKeysetCursor(cursor, spec)` (cursor tipado), `fetchKeysetPage` (lê `limit + 1`), e `expectKeysetContract` no spec de integração do repositório. O teste-portão `keyset-usage.spec.ts` derruba o build sem isso. Ordenar por coluna de timestamp não é suportado (o cursor perde microssegundos).

## FK e integridade

- Relações **transporte** e agregados novos: FK Postgres + validação application.
- FK só na application sem DDL: **proibido** salvo ADR (catálogo legado / import).
- **Relacionamento só por uuid ([ADR-0014](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/docs/adr/0014-relacionamento-so-por-uuid.md)):** toda relação é FK composta `(company_id, <tabela>_id)` sobre chave uuid. O inteiro `id` (o `ID_<TABELA>` do ERP) existe em toda tabela de empresa como código de exibição e de pesquisa direta nas telas (texto ou código), único por empresa e sem FK: nunca é chave, FK, filtro de relacionamento nem rota. Coluna do ERP cujo pai ainda não existe **não é gerada**; ela volta como FK uuid na task do pai. Coluna inteira `*_id` nova derruba o build (`integer-references.spec.ts`); o legado está em `SPEC-referencias-inteiras.md`.
- Cidade e UF, e os cadastros fiscais nacionais (NCM, CFOP, alíquotas IBPT e demais tabelas da emissão), **não** têm `company_id`. A ficha guarda o `id` uuid dessas tabelas globais (`city`, `state` e as tabelas fiscais quando existirem).

## Testes por campo persistido

Todo campo writable no DTO:

- Teste de **rejeição** (validation ou exceção de negócio).
- Teste de **persistência válida** ou normalização.

Registrar em [FIELD-TEST-MATRIX.md](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/specs/cadastros/FIELD-TEST-MATRIX.md). Gate: [SPEC-platform-hardening.md](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/specs/cadastros/SPEC-platform-hardening.md).

## Migrations

- Pasta app: `src/domain/app/migrations/`.
- Toda migration nova: `migrations/__tests__/<nome>.spec.ts` (run, schema, revert).
- Índices GIN: migration `pg_trgm` antes.

## HTTP validation (meta)

Rotas app: DTOs completos; meta `forbidNonWhitelisted: true` ([ADR-0010](/D:/SISTEMAS/CLOUDCLASS/cloudclass-api/docs/adr/0010-cadastros-indices-busca-e-keyset.md)). Até lá, não depender de strip silencioso de campos extras.

## Checklist extra (além do §7 do SKILL)

- [ ] Spec de módulo atualizada (busca + índices se ficha).
- [ ] CAPABILITY-MAP se módulo novo.
- [ ] FIELD-TEST-MATRIX atualizada para campos tocados.
- [ ] Listagem ficha grande não usa OFFSET.
- [ ] ADR se fugir de qualquer item acima.

## Dívida de arquitetura (auditoria de 2026-10-02)

Snapshot histórico de 2026-10-02, medido em 143 controllers, 582 rotas, 140 applications e 140 databases; não é uma verificação atual nem uma ordem de correção. A auditoria registrou conformidade do código gerado por `scripts/cadastros-gen`, exceto a regra de negócio no Repository (item 5 abaixo), e desvios no legado de `admin` e de poucas fichas antigas. Confira cada achado no código atual antes de propor trabalho. As regras são as do §0 do [SKILL.md](SKILL.md).

| # | Desvio | Onde | Regra |
|---|---|---|---|
| 1 | Database que não estende `DatabaseBase<>` nem implementa `DatabaseBaseInterface<>` | `companies`, `membership` (admin), `catalog` e `parametros` (app) | §0.1 |
| 2 | Controller devolve entidade (`CompanyEntity`, `MemberEntity`, `StateEntity`...) em vez de Response; pastas sem `*.request.ts` e `*.response.ts` | `admin`: `catalog`, `company`, `membership`, `subscription`, `accountings` | §0.4 |
| 3 | `@ApiResponse` de sucesso sem `type` (18 rotas) e rotas sem 400 ou 404 documentados | `admin`: `company`, `catalog`, `membership`, `accountings` | §0.5 |
| 4 | Application injeta `CompanyRepository` e Controller importa `@/domain/admin/repositories` | `membership` (admin) | §0.3 |
| 5 | Decisão de ciclo de vida dentro do Repository (32 repositórios) e guarda de status do pedido sobre leitura em cache (12 applications) | `pdv-pedido*`, `pedido-venda*`, `titulo*`, `cliente`, `grupo-faturamento` | §0.2 |
| 6 | Exceções do framework lançadas na Application e no Controller | `company.application` (12), `membership.application` (12), `company.controller` (5), `produtos.controller` (2) | §0.6 |
| 7 | Applications importam o erro de cursor de `@/domain/shared/repositories/keyset-pagination` | 27 applications | §0.3 (menor: é um tipo de erro de domínio compartilhado, não um Repository) |
| 8 | Controller de infraestrutura sem Request e Response (`app.controller`, `metrics.controller`) | raiz | exceção aceita: saúde e status, sem corpo de negócio |

Códigos de erro: nas features de `app` (exceto `parametros`) toda classe de exceção tem o status correspondente documentado no controller; nas de `admin` as exceções são do framework e não há `*.exceptions.ts`.
