# USO-SKILLS — Cheat sheet do dia a dia

Não é documentação. É o que você relê de manhã pra lembrar de acionar a skill certa.
Regra mental: **skill de contexto entra sozinha** quando você mexe no stack dela;
**skill vendor você chama pelo nome** da lib/ferramenta.

## Tabela rápida — Skill | Quando usar

| Skill | Quando usar |
|---|---|
| nestjs-clean-architecture | Mexeu em API NestJS (`*-api`, `*-auth`, `*-sync`, `*-hook`, `*-bot`, `*-kb`) |
| angular-coreui | Mexeu em front Angular (`*-admin`, `*-dash`, `*-app`) |
| coreui-styling | Criando/ajustando UI Angular — cards, tokens, dark mode padronizado |
| api-design | Desenhando endpoint REST: paginação, status, formato de resposta |
| contract-first | Vai mudar contrato HTTP compartilhado entre front e API |
| e2e-testing | Escrevendo teste Playwright de tela Angular ou site |
| codegraph | Explorar/rastrear código num repo com knowledge graph (antes de grep) |
| debug-issue | Caçar bug seguindo call paths no codegraph |
| explore-codebase | Entender a estrutura de um repo novo via grafo |
| refactor-safely | Refatorar checando dependências/impacto antes |
| review-changes | Revisar um diff de forma estruturada |
| security-scan | Auditar config de agentes/MCP/hooks do próprio hub |
| skill-stocktake | Auditar as skills do hub (overlap, links quebrados) |
| eval-harness | Comparar mudança de skill/prompt antes de mergear |
| claude-android-ninja | App Android Kotlin/Compose (MOBICLASS APKs) |
| browser-harness | Precisa clicar/logar/renderizar JS num navegador real |
| unlazy | Tarefa longa que não pode voltar pela metade |
| tdd | Construir feature/bug fix test-first (red-green-refactor) |
| systematic-debugging | Bug/teste falhando, antes de propor fix |
| verification-before-completion | Antes de dizer "está pronto/passa" |
| git-workflow-and-versioning | Commit, branch, PR, release, changelog |
| using-git-worktrees | Isolar feature nova num worktree |
| finishing-a-development-branch | Feature pronta, decidir como integrar |
| spec-driven-development | Feature nova sem spec — escrever a spec antes |
| planning-and-task-breakdown | Quebrar spec em tarefas ordenadas |
| incremental-implementation | Entregar mudança em fatias finas verificáveis |
| implement | Executar uma spec/conjunto de tickets |
| dispatching-parallel-agents | 2+ tarefas independentes em paralelo |
| code-review / code-review-and-quality | Revisar mudança antes de mergear |
| receiving-code-review | Recebeu review e vai aplicar sugestões |
| codebase-design | Desenhar módulo com interface enxuta (deep modules) |
| improve-codebase-architecture | Achar oportunidades de refatoração e priorizar |
| domain-modeling | Escrever/editar CONTEXT.md, glossário, ADR |
| security-and-hardening | Código com input não confiável, auth, dados pessoais |
| observability-and-instrumentation | Adicionar log/métrica/trace/alerta |
| grilling / grill-me / grill-with-docs | Estressar um plano/decisão com perguntas duras |
| wayfinder | Planejar trabalho gigante como mapa de tickets |
| to-spec / to-tickets / triage / handoff | Transformar conversa em spec/tickets/brief/handoff |
| using-agent-skills / writing-skills / setup-matt-pocock-skills | Descobrir, criar e configurar skills |

---

## 🧩 Skills de contexto (Angular / NestJS / etc.)

Entram sozinhas pelo padrão do projeto ou do arquivo que você está editando.

**nestjs-clean-architecture** — convenções NestJS + Clean Arch/DDD das APIs.
Gatilho: editar backend em `*-api`/`*-auth`/`*-sync`/`*-hook`; criar controller, DTO, guard, Swagger, métrica.
Ex.: `cria um DTO de validação pro endpoint de cobrança`

**angular-coreui** — convenções Angular 22+ Clean Arch para os fronts.
Gatilho: editar TypeScript/UI em `*-admin`/`*-dash`/`*-app`.
Ex.: `cria o componente de listagem de clientes no dash`

**coreui-styling** — o design system único (shell CoreUI + `ds-*`), mesmo card/token/dark mode em todo projeto.
Gatilho: criar ou ajustar qualquer UI Angular.
Ex.: `estiliza esse card de estatística seguindo o padrão`

**api-design** — REST: paginação, status codes, formato de resposta, filtros, rate limit.
Gatilho: desenhar ou revisar endpoint NestJS.
Ex.: `revisa a paginação desse endpoint de pedidos`

**contract-first** — coordena mudança de contrato HTTP entre consumidor e provedor.
Gatilho: alterar campos/enums/nullability que front e API compartilham.
Ex.: `preciso adicionar um campo opcional na resposta sem quebrar o front`

**e2e-testing** — testes Playwright de Angular/site: page objects, traces, flaky.
Gatilho: escrever ou consertar teste end-to-end.
Ex.: `escreve um e2e pro fluxo de login`

**codegraph** — usa o MCP do knowledge graph antes de grep/read.
Gatilho: explorar/rever/rastrear código num repo com `.codegraph/`.
Ex.: `mostra quem chama a função de faturamento`

**debug-issue** — caça bug seguindo call paths no codegraph.
Gatilho: rastrear a origem de um erro/sintoma.
Ex.: `de onde vem esse erro de saldo negativo?`

**explore-codebase** — entende estrutura de repo novo via grafo.
Gatilho: chegar num repo desconhecido.
Ex.: `me dá o mapa dos módulos dessa API`

**refactor-safely** — refatora checando dependências e impacto primeiro.
Gatilho: renomear/mover/reestruturar código.
Ex.: `renomeia esse serviço e ajusta tudo que depende`

**review-changes** — revisão estruturada de diff com detecção de impacto.
Gatilho: revisar mudanças antes de fechar.
Ex.: `revisa o diff dessa branch`

**security-scan / skill-stocktake / eval-harness** — meta-skills do hub.
Gatilho: auditar config de agentes/MCP (`security-scan`), auditar as skills (`skill-stocktake`), medir mudança de skill/prompt (`eval-harness`).
Ex.: `roda um stocktake pra ver skills com overlap`

---

## 📦 Skills de biblioteca / vendor

Você aciona citando o nome da lib/ferramenta; a skill injeta a referência dela.

**claude-android-ninja** — Android Kotlin/Compose/MVVM/Hilt/Room 3/Gradle (MOBICLASS APKs).
Gatilho: novo módulo/tela Android, ViewModel, migração targetSdk.
Ex.: `cria a tela de comanda em Compose com o ViewModel`

**browser-harness** — controla um navegador real via CDP (clicar, logar, JS, anti-bot).
Gatilho: a tarefa precisa de interação/sessão logada, não de um `curl`.
Ex.: `entra no painel logado e baixa o relatório da tela X`

**unlazy** — disciplina de conclusão pra trabalho longo (gates + verificação antes de reportar).
Gatilho: tarefa grande/multi-parte ou que voltou pela metade.
Ex.: `$unlazy: audita todos os módulos e não para até terminar`

**tdd / systematic-debugging / verification-before-completion** — ciclo test-first, debug metódico, e provar antes de dizer "pronto".
Gatilho: construir feature test-first / bug persistente / antes de declarar sucesso.
Ex.: `implementa isso via TDD` · `esse teste falha, investiga antes de mexer`

**git-workflow-and-versioning / using-git-worktrees / finishing-a-development-branch** — commit/branch/PR/release, worktree isolado, e como integrar branch pronta.
Gatilho: qualquer operação git relevante.
Ex.: `abre um worktree pra essa feature` · `essa branch tá pronta, como integro?`

**spec-driven-development / planning-and-task-breakdown / incremental-implementation / implement** — spec antes de codar, quebra em tarefas, entrega em fatias, executa tickets.
Gatilho: feature nova/significativa do zero até a entrega.
Ex.: `escreve a spec antes de começar` · `quebra essa spec em tarefas`

**dispatching-parallel-agents** — despacha um agente por problema independente.
Gatilho: 2+ tarefas sem dependência entre si.
Ex.: `esses 3 bugs são independentes, resolve em paralelo`

**code-review / code-review-and-quality / receiving-code-review** — revisão multi-eixo antes de mergear e como aplicar feedback recebido.
Gatilho: revisar código (seu, de agente ou humano) / receber review.
Ex.: `revisa essa mudança antes do merge`

**codebase-design / improve-codebase-architecture / domain-modeling** — desenhar módulos profundos, achar refatorações, e manter glossário/ADR.
Gatilho: decisões de design/arquitetura/vocabulário.
Ex.: `esse módulo tá raso, sugere uma interface melhor`

**security-and-hardening / observability-and-instrumentation** — endurecer contra input não confiável e instrumentar pra produção.
Gatilho: auth/dados pessoais/integrações externas / falta de visibilidade em prod.
Ex.: `adiciona validação e log nesse endpoint que recebe upload`

**grilling / grill-me / grill-with-docs** — entrevista dura pra afiar um plano (com docs no `grill-with-docs`).
Gatilho: quer estressar seu raciocínio antes de executar.
Ex.: `me grila sobre esse plano de migração`

**wayfinder / to-spec / to-tickets / triage / handoff** — planejar trabalho gigante como mapa; virar conversa em spec/tickets/brief; passar bastão.
Gatilho: escopo grande demais pra uma sessão, ou fim de sessão.
Ex.: `transforma essa conversa em tickets` · `faz o handoff pro próximo agente`

**using-agent-skills / writing-skills / setup-matt-pocock-skills** — descobrir qual skill aplica, criar/editar skills, e configurar o repo pras skills de engenharia.
Gatilho: mexer nas próprias skills.
Ex.: `cria uma skill nova pra convenção de logging`

---

## Roteiro do dia a dia (releia isto)

1. **Abro um repo** (`erpclass-api`, `-dash`, etc.). A skill de contexto do stack
   (nestjs-clean-architecture / angular-coreui) entra sozinha pelo nome do projeto.
2. **Vou entender o código**: peço `explore-codebase` / pergunto ao **codegraph**
   antes de sair fazendo grep — ele responde estrutura e call paths em uma chamada.
3. **Crio algo novo** (endpoint, componente): descrevo a tarefa e a skill de convenção
   já aplica os padrões. Ex.: `cria um DTO de validação pro endpoint de cobrança`.
   Se for UI, o **coreui-styling** garante o card/token/dark mode padrão.
4. **Preciso de uma lib/ferramenta específica**: cito o nome — "Android/Compose"
   puxa **claude-android-ninja**, "navegador logado" puxa **browser-harness**.
   Citar o nome é o que injeta a referência vendor.
5. **Vou mudar um contrato compartilhado**: aciono **contract-first** pra não quebrar
   o consumidor do outro lado (front ↔ API).
6. **Acho um bug**: **systematic-debugging** + **debug-issue** (codegraph) pra rastrear
   antes de propor fix; conserto via **tdd** quando dá.
7. **Antes de fechar**: **verification-before-completion** (rodo o comando e leio a saída),
   depois **review-changes** / **code-review** no diff.
8. **Fecho o trabalho**: **git-workflow-and-versioning** pro commit/PR e
   **finishing-a-development-branch** pra decidir a integração. Se ficou pela metade,
   **handoff** pro próximo agente.
