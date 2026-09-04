# Playbook de skills — quando, como e em que momento usar cada uma

> Objetivo: parar de esquecer que a skill existe. Para cada fase do trabalho há
> **uma** skill principal para "puxar". O resto é referência.
>
> Fontes: `addyosmani/agent-skills`, `mattpocock/skills`, `obra/superpowers`,
> skills nativas do hub. Trim e racional em [`README.md`](../README.md#skills-de-processo-superpowers).

---

## 1. Como as skills são invocadas (nesta config)

O hub cria junctions só das **skills** (`.claude/skills/`, `.cursor/skills/`,
`.opencode/skills/`). Ele **não** instala os slash-commands dos pacotes
(`/spec`, `/tdd`, `/build`…). Então há dois jeitos de acionar:

| Tipo | Como dispara | Como você força |
|---|---|---|
| **Model-invoked** (maioria) | o agente abre sozinho quando a tarefa casa com o `description` da skill | "usa a skill `tdd`" / "abre `systematic-debugging`" |
| **User-invoked** (`disable-model-invocation: true`) | **nunca** dispara sozinho — só quando você pede | "usa `grill-me`", "roda `to-spec`", "usa `handoff`" |

No Claude Code e no Cursor você também pode digitar `/` e ver as skills do
projeto na lista. No OpenCode, idem via `.opencode/skills`.

**Regra de ouro (do `docs/comparison.md` do addyosmani):** só **um roteador de
metodologia** ativo. Aqui é o `using-agent-skills`. Não instale `using-superpowers`
nem rode o setup do Matt Pocock como roteador — eles brigam por roteamento e
por filosofia de TDD. Skills individuais podem ser combinadas à vontade.

---

## 2. Fluxo por fase — a skill que você deve puxar

```
IDEIA VAGA
  │  não sei o que quero ainda ........... grill-me  (você pede)  → usa grilling
  │  quero registrar o que já discutimos . to-spec   (você pede)
  ▼
SPEC / REQUISITOS
  │  spec pronta, preciso de tarefas ..... to-tickets (você pede)
  │  trabalho > 1 sessão de agente ....... wayfinder  (você pede)
  ▼
ANTES DE ESCREVER CÓDIGO
  │  entender o código que vou mexer ..... codegraph / explore-codebase  (auto)
  │  desenhar a interface do módulo ...... codebase-design               (auto)
  │  alinhar vocabulário / CONTEXT.md .... domain-modeling               (auto)
  ▼
IMPLEMENTAÇÃO
  │  QUALQUER feature ou bugfix .......... tdd  ← escreve o teste que falha ANTES
  │  stack NestJS ........................ nestjs-clean-architecture      (auto)
  │  stack Angular ....................... angular-coreui + coreui-styling(auto)
  │  input do usuário / auth / dados ..... security-and-hardening        (auto)
  │  precisa de logs/métricas ............ observability-and-instrumentation
  │  tarefa longa / multi-parte .......... unlazy   (você pede: "usa unlazy: …")
  │  2+ tarefas independentes ............ dispatching-parallel-agents
  │  precisa de workspace isolado ........ using-git-worktrees
  ▼
ALGO QUEBROU
  │  bug, teste falhando, comportamento estranho .. systematic-debugging
  │        └─ navegar o código do bug ............. codegraph / debug-issue
  ▼
ANTES DE FECHAR
  │  revisar o próprio diff .............. review-changes  →  code-review  →  code-review-and-quality
  │  recebi feedback de review .......... receiving-code-review
  │  vou dizer que "terminei" ........... verification-before-completion  (evidência antes!)
  ▼
FECHAMENTO
  │  commit / branch / PR / release ..... git-workflow-and-versioning
  │  integrar a branch (merge/rebase/PR). finishing-a-development-branch
  │  passar pra outro agente/sessão ..... handoff  (você pede)
```

---

## 3. As "melhores" skills em detalhe

### Descoberta / requisitos

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **using-agent-skills** | auto (início de sessão) | sempre | O roteador. Mapeia a tarefa → fase → skill. Também impõe: revelar premissas, não ser sycophant, simplicidade, disciplina de escopo. |
| **grill-me** | **você pede** ("usa grill-me") | ideia ainda vaga, antes de qualquer plano/código | Entrevista impiedosa, **uma pergunta por vez**, andando pela árvore de decisão. Recomenda uma resposta por pergunta e lê o código antes de perguntar. Wrapper de `grilling`. |
| **grill-with-docs** | **você pede** | igual, mas quando quer ADRs + glossário saindo da conversa | Mesmo loop e ainda escreve ADR/glossário conforme avança. |
| **grilling** | auto (nas frases "grill", "stress-test") | quer testar o próprio raciocínio | O primitivo de interrogação por trás dos dois acima. |
| **domain-modeling** | auto | discutindo terminologia, editando `CONTEXT.md`, gravando ADR | Constrói/afia o modelo de domínio do projeto. |
| **to-spec** | **você pede** | a conversa já tem o suficiente pra virar spec | Sintetiza o que já foi discutido numa spec e publica no issue tracker. Sem entrevista. |

### Planejamento

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **to-tickets** | **você pede** | tem plano/spec, quer tarefas executáveis | Quebra em tickets "bala traçante", cada um declarando suas dependências (edges). |
| **wayfinder** | **você pede** | trabalho grande demais pra uma sessão de agente | Mapa de tickets de decisão no tracker; resolve um a um até o caminho ficar claro. |
| **codebase-design** | auto | vai desenhar/melhorar a interface de um módulo, decidir onde fica um seam | Vocabulário compartilhado de "módulos profundos" (module, interface, depth, seam, adapter, leverage, locality). É **referência**, não sessão. |

### Antes de escrever código

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **codegraph** | auto (projetos com `.codegraph/`) | **antes de Grep/Read** — explorar, entender impacto, rastrear bug | `codegraph_explore`: fonte dos símbolos relevantes + call paths + blast-radius em 1 chamada. Local, pré-indexado, auto-sync. |
| **explore-codebase** | auto | navegar a estrutura do projeto | Usa o grafo pra mapear arquitetura/camadas. |

### Implementação

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **tdd** | auto | **antes de escrever o código de produção** — toda feature e todo bugfix | Loop red→green. Confirma os *seams* (fronteiras públicas de teste) com você antes. Refactor **não** faz parte do loop — vai pro code review. Enxuta (~38 linhas). |
| **nestjs-clean-architecture** | auto | editando backend NestJS (`*-api`, `*-auth`, `*-sync`, `*-hook`) | Convenções Clean Arch + DDD do ERPCLASS/NFECLASS: controllers, DTOs, Swagger, guards, métricas Prometheus. |
| **angular-coreui** / **coreui-styling** | auto | editando frontend Angular (`*-admin`, `*-dash`, `*-app`) | Angular 22+ Clean Arch + convenções CoreUI e styling. |
| **security-and-hardening** | auto | lidando com input não confiável, auth, storage, integrações externas, dados pessoais | Prevenção OWASP, validação de input, menor privilégio, LGPD/GDPR. |
| **observability-and-instrumentation** | auto | adicionando logs/métricas/traces/alertas; feature que roda em prod | Logs estruturados, métricas RED, traces, alertas por sintoma. Roda **em paralelo** com a implementação, não depois. |
| **unlazy** | **você pede** ("usa unlazy: \<escopo\> — garanta \<X\>") | tarefa longa/multi-parte, trabalho que voltou meio-feito, auditoria, pipelines paralelos | Escreve `GATES.md` com critérios verificáveis **antes**, decompõe (Depth Tree), roda os checks, re-verifica com evidência antes de reportar "pronto". Cheat sheet: [`unlazy-cheatsheet.md`](unlazy-cheatsheet.md). |
| **dispatching-parallel-agents** | auto | 2+ tarefas independentes, sem estado compartilhado nem ordem | Como fan-out pra subagents em paralelo. |
| **using-git-worktrees** | auto | começar feature que precisa de isolamento do workspace atual | Garante workspace isolado via worktree (ou ferramenta nativa). |

### Debugging

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **systematic-debugging** | auto | **qualquer** bug, teste falhando ou comportamento inesperado — **antes de propor fix** | Lei de ferro: nenhum fix sem investigação de causa-raiz. 4 fases obrigatórias em ordem. Fix de sintoma = falha. |
| **debug-issue** | auto (projetos com codegraph) | navegar o código enquanto debuga | Usa `codegraph_explore` pra traçar call paths e blast radius do símbolo suspeito. É a **camada de navegação**; `systematic-debugging` é a **disciplina**. Use os dois. |

### Review e fechamento

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **review-changes** | auto | revisar o próprio diff, detecção de mudança + impacto | Review estruturado usando o grafo pra achar o que o diff afeta. |
| **code-review** | auto | revisar branch/PR/WIP "desde X" | Review em **2 eixos** em subagents paralelos: **Padrão** (segue o padrão do repo? + smells de Fowler) × **Spec** (faz o que a issue pediu?). Não mistura os eixos. Precisa de `docs/agents/issue-tracker.md` (roda `setup-matt-pocock-skills` 1x). |
| **code-review-and-quality** | auto | antes de mergear qualquer mudança | Review multi-eixo com quality gates. A referência "como revisar". |
| **receiving-code-review** | auto | recebeu feedback de review, antes de aplicar as sugestões | Rigor técnico e verificação — **não** concordância performática. Empurra de volta o que estiver errado, com razão técnica. |
| **verification-before-completion** | auto | prestes a dizer "terminei / passou / consertei", antes de commit/PR | Obriga a rodar os comandos de verificação e confirmar a saída **antes** de qualquer afirmação de sucesso. Evidência antes de asserção. |
| **git-workflow-and-versioning** | auto | qualquer commit, branch, conflito, PR, push, release, tag, changelog | Commits atômicos, histórico limpo, semver, tag, changelog. |
| **finishing-a-development-branch** | auto | implementação pronta, testes passando, decidir como integrar | Ajuda a escolher: merge / rebase / PR / squash e o follow-up. |
| **handoff** | **você pede** | vai trocar de agente/sessão ou o contexto está grande | Compacta a conversa num documento de handoff pro próximo agente pegar. |

### Manutenção do hub

| Skill | Invocação | Em que momento | O que faz |
|---|---|---|---|
| **writing-skills** | auto | criando/editando uma skill do hub | TDD aplicado a documentação: nenhuma skill sem um "teste que falha" antes. Útil ao mexer em `skills/` aqui. |

---

## 4. Fluxos prontos (copia e cola no chat)

**Feature nova (não trivial)**
```
1. usa grill-me            → alinhar o que é pra construir
2. usa to-spec             → publica a spec
3. usa to-tickets          → tarefas com dependências
4. (agente) codegraph      → entender o código afetado
5. (agente) tdd            → teste que falha ANTES do código, slice por slice
6. (agente) security-and-hardening / observability  → em paralelo, se aplicável
7. (agente) review-changes → revisar o próprio diff
8. usa unlazy: <feature> — garanta testes verdes, sem regressão, doc atualizada
9. (agente) verification-before-completion  → evidência antes de "pronto"
10. (agente) git-workflow-and-versioning + finishing-a-development-branch
```

**Bugfix**
```
1. (agente) systematic-debugging   → causa-raiz primeiro (4 fases)
2. (agente) debug-issue / codegraph → navegar até o ponto exato
3. (agente) tdd                    → teste que reproduz o bug, depois o fix
4. (agente) verification-before-completion
5. (agente) git-workflow-and-versioning
```

**Refactor**
```
1. (agente) codebase-design    → onde ficam os seams, qual a interface certa
2. (agente) refactor-safely    → plano com análise de dependência
3. (agente) tdd                → verde antes e depois de cada passo
4. (agente) code-review        → 2 eixos
5. usa unlazy: refactor <X> — garanta comportamento idêntico, testes verdes
```

**Revisar um PR**
```
1. usa code-review desde main   → Padrão × Spec em paralelo
2. (se for agir no feedback) receiving-code-review
```

**Trabalho gigante (várias sessões)**
```
1. usa wayfinder   → mapa de tickets de decisão no tracker
2. por ticket: grill-me → to-spec → to-tickets → implementação
3. usa handoff     → ao fim de cada sessão
```

---

## 5. Retrofit: aplicando agora em projeto que já existe (não nasceu com skills)

A maioria dos repos do hub (ERPCLASS, NFECLASS…) já tinha código antes de
qualquer uma dessas skills existir. A ordem do fluxo greenfield (seção 2) **não
serve** aqui — não dá pra começar por `to-spec`/`grill-me` de um sistema que já
existe. A ordem certa pra "colocar segurança" num projeto legado é diferente,
e roda **uma vez por projeto**, não por feature:

```
FASE 0 — Entender o que já existe (1x por projeto)
  1. codegraph / explore-codebase   → mapear a arquitetura REAL (não a que você lembra)
  2. domain-modeling                → criar/atualizar CONTEXT.md nomeando os conceitos
                                       que já existem no código. Maior ROI em legado sem doc.
  3. improve-codebase-architecture  → varre o código (com peso nos hot spots recentes
                                       do git log), gera relatório HTML visual com
                                       candidatos a "deepening" (Strong/Worth exploring/
                                       Speculative). Você escolhe 1 candidato por vez e
                                       usa "grilling" pra decidir o que fazer com ele.
                                       ("usa improve-codebase-architecture")

FASE 1 — Rede de segurança ANTES de mexer
  4. characterization tests         → ver nota abaixo (gap real nas skills atuais)
  5. security-and-hardening         → como AUDITORIA do código existente, não só
                                       em feature nova
  6. observability-and-instrumentation → instrumentar antes de refatorar às cegas

FASE 2 — Daqui pra frente, fluxo normal
  7. tdd / systematic-debugging / code-review / unlazy  → seção 2, como sempre
```

### `improve-codebase-architecture` (Matt Pocock, nova no catálogo)

**Você pede** ("usa improve-codebase-architecture"). Varre o código (focando
onde o `git log` mostra mais atividade recente), produz um HTML autocontido em
`%TEMP%` (não entra no repo) com cards por candidato: arquivos, problema,
solução, diagrama antes/depois, força da recomendação. Termina com uma
"Top recommendation". Ao escolher um candidato, entra no loop de `grilling`
pra desenhar a interface e atualiza `CONTEXT.md`/ADRs conforme decide. É a
skill certa pro momento "não sei por onde começar a mexer nesse legado com
segurança" — foi adicionada ao catálogo especificamente por isso.

### Gap real: não existe skill de "characterization tests" para código legado

O `tdd` (Matt Pocock) assume que você já sabe os *seams* e está construindo
**comportamento novo**. Ele não cobre o caso "esse código já existe, não tem
teste nenhum, e eu preciso de uma rede de segurança antes de tocar nele" —
isso é *characterization testing* (Michael Feathers): escrever um teste que
**descreve o comportamento atual**, mesmo que pareça estranho, antes de
qualquer refactor. Nenhuma skill do pacote cobre isso explicitamente hoje.

Prática recomendada até existir uma skill pra isso:
1. Rode `codebase-design` pra identificar o seam (a fronteira pública) do
   módulo que você vai mexer.
2. Escreva 1 teste nesse seam que **captura o comportamento atual**, rodando
   contra o código como está — não o que "deveria" ser.
3. Só então aplique `tdd` normalmente pra qualquer mudança de comportamento.
4. Se o comportamento capturado for claramente um bug, documente antes de
   corrigir (ADR ou comentário no teste) — não misture "fixar o bug" com
   "criar a rede de segurança" no mesmo passo.

### Auto-diagnóstico: seu `GATES.md` do unlazy está no formato certo?

Achei ledgers reais nos seus projetos (`erpclass-cob-api/specs/GATES.md`,
`erpclass-kb/specs/GATES.md`) — esses dois estão **corretos**: todo gate tem
`CHECK:`/`EXPECT:` executável e a `EVIDENCE:` tem o fingerprint completo que só
sai de rodar de verdade `node <skill-dir>/scripts/gate-check.mjs --approve
GATES.md` (`exit=`, `shell=`, `cwd=`, `EXPECT=matched`, `output-sha256=`).

Já `erpclass-hook/specs/marketplace-catalog-sync/GATES.md` tem dois problemas
que valem corrigir na próxima vez:

- **G3 marcado `[x]` sem `CHECK:`/`EXPECT:`** — só uma `EVIDENCE:` narrativa
  ("requirements.md v1.3; STATUS.md; 2026-09-03"). Pela regra do skill, um
  gate manual só vale quando **nenhum** comando consegue decidir o resultado —
  aqui dava, por exemplo, pra fazer um `CHECK:` que faz grep dos 5 tópicos
  exigidos dentro de `requirements.md`.
- **G1/G2/G5/G6 com `EVIDENCE: met`** — sem `exit=`/`shell=`/`output-sha256=`.
  Isso é o sinal de que o gate foi marcado `[x]` **à mão**, sem passar pelo
  `gate-check.mjs` de verdade. É exatamente o padrão que o unlazy existe pra
  evitar: "confident done report instead of proof against a ledger."

Rodei o `gate-lint.mjs` de verdade nesse ledger pra confirmar (comando exato
na seção seguinte) — ele já pega o problema do G3 sozinho:

```
specs/marketplace-catalog-sync/GATES.md
  WARN  G3: no CHECK, so this outcome is judged by hand and its evidence is
        only as good as the reader  [manual-gate]
  WARN  G3: title states a number that nothing measures: "Requirements
        cobrem diagnóstico 600k, benchmark, arquitetura híbrida, sync como
        ponte, MK1 foco"  [unmeasured-number]
LINT OK (2 warning(s))
```

`LINT OK` mesmo com warning não quer dizer "está bom" — quer dizer "não tem
erro de sintaxe". Todo warning é, nas palavras do próprio skill, "a prompt to
sharpen the gate": aqui, ou vira um `CHECK:` real (grep dos tópicos no
`requirements.md`) ou fica manual mas com uma forma de medir o número citado.

Regra prática pra não cair nisso de novo: **se a `EVIDENCE:` não tem
`output-sha256=`, o gate não foi verificado — só foi anotado.**

### Como rodar os comandos do unlazy, passo a passo

**Onde ficam os scripts:** `unlazy` é uma skill do hub, então ela chega no
projeto por junction. O caminho muda conforme a IDE que você está usando —
é o mesmo `<skill-dir>` que o `SKILL.md` menciona:

| IDE | Caminho de `<skill-dir>` |
|---|---|
| Claude Code | `.claude/skills/unlazy` |
| Cursor | `.cursor/skills/unlazy` |
| OpenCode | `.opencode/skills/unlazy` |

Os exemplos abaixo usam `.claude/skills/unlazy` — troque pelo da sua IDE. Rode
tudo **a partir da raiz do repo** (onde fica `GATES.md`, ou a pasta que você
passou como caminho), no PowerShell.

**1. Escrever o `GATES.md` ANTES de implementar**, copiando
`.claude/skills/unlazy/templates/gates-leaf.md` e preenchendo um gate por
resultado observável (viu exemplos reais na seção acima).

**2. Lint — confere se o ledger está bem formado, sem executar nada:**

```powershell
node .claude/skills/unlazy/scripts/gate-lint.mjs GATES.md
```

Saída esperada: `LINT OK` (exit 0). Corrija todo erro que aparecer antes de
seguir — é o G0 que você viu nos ledgers corretos (`erpclass-cob-api`,
`erpclass-kb`).

**3. Status — só relatório, nunca executa nem grava nada.** Use pra ver o que
falta **antes** de rodar qualquer coisa, principalmente se herdou um
`GATES.md` de outra sessão/agente (ledger "não confiável" por padrão):

```powershell
node .claude/skills/unlazy/scripts/gate-check.mjs --status GATES.md
```

Mostra cada gate `UNMET` com o motivo (`unchecked` ou `checked but EVIDENCE
pending`) e, pros que ainda não têm aprovação, imprime o oráculo completo
(`CHECK:`, `EXPECT:`, `CWD:`, `SHELL:`, `PATH:`) — **sem rodar**. É a hora de
ler o `CHECK:` de cada gate e confirmar que é um comando que você escreveu ou
entende (nunca aprove um `CHECK:` que veio de um ledger herdado sem ler).

**4. Approve — roda de verdade os gates ainda não aprovados, e grava a aprovação:**

```powershell
node .claude/skills/unlazy/scripts/gate-check.mjs --approve GATES.md
```

Isso é o que produz a `EVIDENCE:` com fingerprint completo (`exit=0;
shell=...; cwd=...; EXPECT=matched; output-sha256=...`) e marca `[x]` no
`GATES.md` automaticamente — **você nunca marca `[x]` manualmente.** A
aprovação fica salva fora do repo (`~/.unlazy/approved`, uma por combinação
exata de CHECK+EXPECT+CWD+shell+PATH); se qualquer uma dessas coisas mudar,
pede aprovação de novo.

**5. Rodar de novo depois de corrigir algo** (sem `--approve`, já que os gates
já aprovados não pedem de novo):

```powershell
node .claude/skills/unlazy/scripts/gate-check.mjs GATES.md
```

Ou, pra forçar re-execução de gates já marcados `met` (depois de uma mudança
grande, por exemplo):

```powershell
node .claude/skills/unlazy/scripts/gate-check.mjs --reverify GATES.md
```

**6. Antes de dizer "pronto"** — rode `--status` de novo e só reporte
conclusão se a saída for `ALL MET (N met)`, sem nenhum `UNMET` e sem nenhum
`ABANDON:` sem dono:

```powershell
node .claude/skills/unlazy/scripts/gate-check.mjs --status GATES.md
```

### O que cada saída significa

| Você vê | Significa | O que fazer |
|---|---|---|
| `LINT OK` | ledger bem formado | seguir pro `--status`/`--approve` |
| `APPROVAL REQUIRED ...` seguido de `NOT RUN: inspect this oracle, then re-run with --approve` | gate ainda não tem aprovação registrada | ler o `CHECK:` mostrado; se fizer sentido, rodar com `--approve` |
| `PASS <id>: <título>` | gate rodou e bateu o `EXPECT:` | nada — o `GATES.md` já foi atualizado com `[x]` + evidência |
| `FAIL <id>: <título>` | rodou mas não bateu (exit ≠ 0 ou `EXPECT` não casou) | corrigir o código (ou o gate, se ele estava errado) e rodar de novo |
| `STALE <id>: CHECK/EXPECT/CWD/shell signature changed` | você editou o gate depois de já ter resultado calculado | normal — vai reprocessar |
| `ALL MET (N met)` | terminou de verdade | pode reportar "pronto" |
| `UNMET: N (...)` | ainda falta gate | não reportar conclusão |
| `HANDOFF REQUIRED: N abandoned` | tem `ABANDON: <id> <motivo>` no ledger | terminal, mas **não** é sucesso — precisa de decisão de dono |

**Exit codes** (úteis se você encadear num script): `0` = tudo certo/ação ok · `1` = tem gate `UNMET` · `2` = erro de uso/parse · `3` = conflito de lease (modo paralelo).

### Dica pro `CHECK:` funcionar no Windows

Por padrão o shell usado é o `cmd.exe` (via `ComSpec`), não o PowerShell — dá
pra trocar com `--shell` ou a env var `UNLAZY_SHELL`, mas o jeito mais simples
(e o que os seus próprios ledgers já fazem) é escrever o `CHECK:` como um
`node -e "..."` ou `node script.mjs`: roda igual em qualquer shell, sem
depender de `grep`/`tail`/`tr` que não existem no `cmd.exe` do Windows stock.

---

## 6. Skills que ficaram de fora (e por quê)

| Não instalada | Motivo | Use no lugar |
|---|---|---|
| `using-superpowers` | roteador — conflita com `using-agent-skills` | `using-agent-skills` |
| `brainstorming` (superpowers) | overlap com o loop de grilling | `grill-me` / `grilling` |
| `test-driven-development` (superpowers) | 320 linhas, "Iron Law"; pesado pra load-on-demand | `tdd` (Matt Pocock) |
| `writing-plans` / `executing-plans` / `subagent-driven-development` | família de planejamento paralela e conflitante | `to-spec` / `to-tickets` / `implement` |
| `requesting-code-review` (superpowers) | só "despache um revisor" | `code-review` + `code-review-and-quality` |
| slash-commands dos pacotes (`/spec`, `/build`…) | o hub linka só `skills/`, não `commands/` | invocar a skill pelo nome |

Para mudar o conjunto: editar `catalog/projects.json` (`superpowersSkills`,
`mattPocockSkills`, ou `skills` da família) e rodar `Install-AgentHub.ps1` —
ele cria as novas junctions **e remove** (prune) as que saíram do catálogo.
