# Alinhamento documental NestJS — 2026-10-03

## Escopo e resultado

Revisão autorizada para eliminar discrepâncias das instruções, preservando a arquitetura existente. Mantida a cadeia Controller → Application → Database → Repository, os geradores, os nomes de arquivos de tokens e a serialização explícita de Response DTOs.

Varredura nas seis famílias do catálogo: CLOUDCLASS, CRMCLASS, ERPCLASS, MOBICLASS, NFECLASS e SHOPCLASS. Foram encontrados 39 diretórios de projeto e examinados 1.345 arquivos Markdown/regras, incluindo 222 arquivos de instrução e 197 documentos com referências relevantes. A busca excluiu dependências, build, vendor, estado do instalador e índices de codegraph; não seguiu junctions recursivamente. Os links da skill foram verificados separadamente.

O trabalho altera apenas documentos. Não foram alterados código, loaders, valores de configuração, autenticação, bancos, contratos HTTP ou deploys. Não é uma auditoria da conformidade do código das APIs. Achados registrados em auditorias antigas não foram revalidados como defeitos atuais nem transformados em tarefas.

## Correções na fonte compartilhada

- Arquitetura descrita como camadas NestJS; `domain/` mantém seu nome histórico e inclui persistência TypeORM.
- Interface + token nas fronteiras Controller → Application e Application → Database; Repository concreto permitido dentro da camada de dados.
- Removida a permissão de `Entity.factory()` no Controller; a Application recebe contrato independente dos DTOs HTTP.
- Bases de persistência delimitadas ao padrão TypeORM; preservadas a variante Mongo somente-leitura e as exceções aceitas em ADRs.
- Mantida `BaseException` para erros expostos por HTTP; reconhecida a convenção já aceita de `Error` para erros internos tratados sem resposta HTTP.
- Preservados os sufixos de tokens, serviços, contratos e a injeção de infraestrutura transversal já aceita.
- Linhas em branco permitidas entre blocos lógicos; substantivos de negócio seguem o vocabulário do projeto.
- Contrato keyset CloudClass documentado como `{ items, nextCursor }`; outros contratos existentes não são migrados. ADR-0013 prevalece sobre o resumo genérico de helpers e timestamps.
- Swagger documenta rotas de produto e autenticação real; health/metrics/status e respostas sem corpo seguem suas exceções.
- JSON e loader preservados; removida a orientação de adicionar novos segredos reais ao Git, sem migrar valores existentes.
- Corrigidos links externos, a contagem do mapa TypeORM e exemplos que apresentavam dívida histórica como padrão aprovado.
- Incluída proteção explícita de escopo: consultar a skill não autoriza refatorações estruturais, renomeações nem reabertura de tarefas antigas.

O template `templates/agents/nestjs.md` e o exemplo em `docs/SKILLS-PLAYBOOK.md` também foram alinhados para não reinstalar ou ensinar a redação anterior.

## Documentos dos projetos

Foram ajustados 35 documentos, incluindo `AGENTS.md` de 19 repositórios NestJS e o `AGENTS.md` da pasta CLOUDCLASS. Os demais ajustes ficaram em ADRs, specs e planos com regras repetidas que contradiziam a skill ou podiam disparar migrações não solicitadas.

| Família | Repositórios com instruções ajustadas |
|---|---|
| CLOUDCLASS | cloudclass-api, cloudclass-auth, cloudclass-bot, cloudclass-crm, cloudclass-hook |
| CRMCLASS | crmclass-api |
| ERPCLASS | erpclass-api, erpclass-auth, erpclass-bot, erpclass-cob-api, erpclass-conn-api, erpclass-cota-api, erpclass-dash-api, erpclass-hook, erpclass-kb, erpclass-sync |
| MOBICLASS | mobiclass-api |
| NFECLASS | nfeclass-api |
| SHOPCLASS | shopclass-api |

As três ADRs de autoridade da skill em cloudclass-api/auth/hook receberam esclarecimento de escopo e da fronteira de injeção. O plano e o checklist de `arquitetura-4-camadas` foram identificados como registros históricos, com seus estados de conclusão preservados.

As regras repetidas em specs de KB, no setup operacional do Bot e nos planos de Financeiro foram alinhadas. Decisões antigas de configuração explicitamente aceitas foram mantidas como histórico da entrega, sem estendê-las a novos segredos.

Exceções preservadas: outbox transacional do cloudclass-bot; convenções de serviços/métricas/erros internos do ADR-0002; ausência de DatabaseBase no bot (ADR-0003); SQL somente leitura do CRM e sua atualização pelo ADR de billing. Referências antigas a 13 arquivos em registros de entregas não são uma nova obrigação de contagem; o mapa canônico esclarece os arquivos aplicáveis.

## Distribuição da skill e Claude

Foram conferidos 95 links para a fonte compartilhada. As 19 cópias físicas gerenciadas do Kiro eram idênticas à fonte anterior e foram sincronizadas com os sete documentos corrigidos. Não houve sobrescrita de customização independente nessas cópias.

A duplicação antiga não gerenciada em `erpclass-bot/.codex/skills/nestjs-clean-architecture` foi convertida em cinco pontes documentais para o hub, mantendo os arquivos e os metadados de skill. A instalação atual do Codex usa `.agents/skills`.

Claude Code instalado: `2.1.288`. Os dois `CLAUDE.md` encontrados (`CLOUDCLASS/CLAUDE.md` e `crmclass-www/CLAUDE.md`) continham apenas `@AGENTS.md`, sem regras duplicadas. A ponte da pasta pai CLOUDCLASS foi removida após backup: na configuração padrão, esse CLAUDE.md ancestral priorizava o fluxo CLAUDE.md e importava só o AGENTS.md do workspace, podendo impedir a leitura nativa das instruções dos subprojetos. Agora a família usa a descoberta nativa de AGENTS.md. A ponte local de crmclass-www foi preservada, pois importa o AGENTS.md do próprio projeto. Nenhuma configuração global do Claude foi alterada. Referência: [Claude Code — memória e AGENTS.md](https://code.claude.com/docs/en/memory#agentsmd).

## Verificação

- Links locais da skill e das pontes: 36 conferidos, todos existentes.
- Sete documentos de cada cópia gerenciada: comparação byte a byte com a fonte, sem divergências.
- Template NestJS: placeholders renderizados e proteção de escopo conferida.
- Inventário de skills do hub: execução concluída sem erros de inventário; não equivale a revisão de qualidade de todas as outras skills.
- `git diff --check`: aprovado no hub e nos 19 repositórios.
- Estados de checklists preservados; novos arquivos alterados nos projetos restritos aos documentos previstos.
- Suítes de aplicação não executadas: nenhum comportamento de aplicação foi alterado.

Evidências locais e cópias de segurança: `.audit-output/nestjs-doc-alignment-2026-10-03/`. `changes.json` lista os 35 documentos de projeto editados; `copy-changes.json` lista os 138 arquivos de cópia/ponte; `verification.json` registra os resultados. A ponte removida do workspace está preservada em `cloudclass-parent-CLAUDE-before.md`. O diretório de evidências é ignorado pelo Git.
