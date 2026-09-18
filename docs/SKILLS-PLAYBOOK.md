# Skills e AgentHub — guia prático para devs juniores

> Descubra qual skill usar, como pedir ajuda ao agente e como conferir o resultado.

Revisado em **18/09/2026**, a partir do catálogo, dos SKILL.md e dos scripts deste checkout. São **47 skills selecionadas**: 9 comuns, 15 Matt Pocock, 7 Superpowers, 10 de tecnologia/navegação e 6 ECC. Isso é o catálogo do hub, não a quantidade carregada em cada IDE. Plugins pessoais e outras skills presentes apenas em vendor não entram nessa conta.

<style>
#main-content { line-height: 1.75; overflow-wrap: anywhere; }
#main-content h2 { font-size: 1.5rem; font-weight: 750; margin: 2.5rem 0 1rem; scroll-margin-top: 1.5rem; }
#main-content h3 { font-size: 1.13rem; font-weight: 650; margin: 1.8rem 0 .7rem; }
#main-content p, #main-content ul, #main-content ol { margin: .8rem 0; }
#main-content ul { padding-left: 1.4rem; list-style: disc; }
#main-content ol { padding-left: 1.4rem; list-style: decimal; }
#main-content .modern-table { min-width: 620px; table-layout: auto; }
#main-content .modern-table td { white-space: normal; vertical-align: top; min-width: 130px; }
#main-content .modern-table td:first-child { overflow-wrap: anywhere; min-width: 180px; }
#main-content .code-block-container pre { white-space: pre-wrap; padding-top: 2.4rem; }
#main-content .code-copy-btn { opacity: 1; }
#main-content a:focus-visible, #main-content button:focus-visible { outline: 2px solid #818cf8; outline-offset: 3px; }
</style>

**Comece por aqui:** [Primeiro uso](#primeiro-uso) · [Qual escolher](#escolher) · [Catálogo completo](#catalogo) · [Receitas](#receitas) · [MCPs e memória](#ferramentas) · [Instalação](#instalacao) · [Problemas comuns](#problemas) · [Glossário](#glossario).

<h2 id="primeiro-uso">1. Primeiro uso: você não precisa decorar 47 nomes</h2>

Uma **skill** é um manual de trabalho que a IA consulta quando precisa. Ela ensina um método: investigar um erro, planejar uma mudança, escrever testes ou seguir os padrões do projeto. Não é uma biblioteca adicionada à sua aplicação e não garante, sozinha, que o resultado está correto.

O **AgentHub** é o repositório que reúne esses manuais e distribui os escolhidos para cada projeto e IDE. Você descreve a tarefa; o agente consulta as orientações e usa as ferramentas disponíveis.

| Peça | Em linguagem simples | Exemplo neste hub |
|---|---|---|
| Skill | O roteiro de como trabalhar | systematic-debugging orienta a investigação de um bug. |
| MCP | A conexão que permite à IA usar uma ferramenta | codegraph consulta relações entre partes do código. |
| AGENTS.md e regras | O lembrete curto do projeto, carregado com frequência | Indica a stack, os comandos e quais guias consultar. |
| Referências | O material detalhado consultado quando necessário | Padrões de Swagger, CSS e arquitetura. |
| Hook | Uma ação ligada a um evento da sessão | Integrações de memória podem usar hooks; ter uma skill não instala seus hooks. |
| ai-memory | Memória compartilhada entre sessões e agentes | Recupera decisões anteriores; depende de serviço e integração configurados. |
| Catálogo | A lista que decide o que distribuir e para quem | catalog/projects.json. |
| Junction | Um atalho de pasta do Windows | A pasta de skills do projeto aponta para a fonte no hub. |

### Passo a passo no chat da sua IDE

1. Abra a pasta do projeto em que vai trabalhar.
2. Diga o problema, o resultado esperado e se quer **entender**, **planejar** ou **implementar**.
3. Se souber o nome, escreva “Use a skill ...”. Se não souber, peça ao agente que escolha.
4. Informe o arquivo, tela, erro ou issue envolvido. Use dados de exemplo sem credenciais.
5. No final, confira o que mudou, os testes executados e o que não foi possível verificar.

**Copie no chat, não no terminal:**

```text
Sou dev júnior e estou trabalhando neste projeto.
Quero entender como o cadastro de clientes funciona, sem alterar arquivos.
Use explore-codebase se estiver disponível.
Explique o caminho da tela até a API, cite os arquivos e traduza os termos técnicos.
```

Para pedir uma mudança:

```text
Quero impedir o cadastro de cliente com e-mail inválido.
Primeiro confira como a validação já funciona neste projeto.
Use as skills adequadas à stack e proponha a menor mudança necessária.
Implemente a validação e teste entradas válidas e inválidas.
Ao terminar, explique o diff e mostre os comandos e resultados da verificação.
```

### Como chamar uma skill

A forma mais portátil é escrever **“Use a skill nome-da-skill para...”**. A maioria permite seleção automática quando a tarefa combina com sua descrição. Algumas exigem pedido explícito; estão marcadas como **Pedido** no catálogo abaixo.

O seletor de skills e os atalhos variam conforme a IDE. Não presuma que digitar /spec, /plan, /build ou /eval funcionará: o hub distribui os arquivos das skills, mas não instala todos os comandos dos plugins originais. Se o nome não aparecer, consulte [Problemas comuns](#problemas).

<h2 id="escolher">2. Qual skill escolher agora?</h2>

| Sua situação | Comece com | Resultado que deve receber |
|---|---|---|
| “Não conheço este projeto” | explore-codebase | Explicação da estrutura e dos arquivos relevantes. |
| “Tenho uma ideia, mas faltam decisões” | grill-me | Perguntas em rodadas, com recomendações, até esclarecer a ideia. |
| “Preciso escrever o que será feito” | spec-driven-development | Uma especificação com escopo e critérios verificáveis. |
| “Já decidimos e precisamos registrar no tracker” | to-spec | Uma spec publicada no local configurado para issues. |
| “A tarefa é grande demais” | planning-and-task-breakdown ou to-tickets | Etapas pequenas, com dependências e forma de validar. |
| “Quero implementar um plano local” | incremental-implementation | Uma parte funcional de cada vez. |
| “Quero implementar uma issue/spec do fluxo Pocock” | implement | Implementação, verificações, revisão e commit conforme o fluxo. |
| “Quebrou e não sei por quê” | systematic-debugging | Reprodução, evidências e causa antes da correção. |
| “Vou mudar dados trocados entre tela e API” | contract-first | Contrato e consumidores alinhados antes da integração. |
| “Quero criar teste antes do código” | tdd | Teste que falha, mudança mínima e teste passando. |
| “Preciso testar uma jornada na tela” | e2e-testing | Teste Playwright repetível, com evidências. |
| “A tarefa sempre volta pela metade” | unlazy | Critérios de conclusão registrados e verificados. |
| “Quero revisar o que mudou” | review-changes ou code-review | Achados com arquivos, impacto e contexto. |
| “O agente disse pronto; como comprovar?” | verification-before-completion | Verificação executada e limitações explícitas. |
| “Vou trocar de sessão ou agente” | handoff | Documento de continuidade com referências e pendências. |

Escolha **uma entrada** e acrescente complementos conforme a necessidade. Por exemplo: systematic-debugging organiza a investigação; debug-issue usa o grafo para localizar o código; tdd protege a correção. Não é necessário pedir todas as skills em uma tarefa pequena.

<h2 id="catalogo">3. Catálogo completo: usos e prompts</h2>

**Automática/pedido** significa que a skill pode ser escolhida pela tarefa ou chamada pelo nome. **Pedido** significa que seu SKILL.md desabilita a invocação automática. Disponibilidade depende do projeto, da instalação e da IDE.

### 3.1 Skills comuns — 9

Distribuídas como base, com exceções por família. No Delphi, as nove estão bloqueadas no catálogo atual.

| Skill | Quando usar e o que faz | Como pedir no chat |
|---|---|---|
| using-agent-skills | Escolhe o processo adequado à fase da tarefa e orienta escopo e verificação. | Use using-agent-skills para indicar o melhor ponto de partida para esta tarefa. |
| spec-driven-development | Quando requisitos estão vagos; registra objetivo, limites, comportamento e critérios de sucesso antes do código. | Use spec-driven-development para especificar recuperação de senha. Não implemente ainda. |
| planning-and-task-breakdown | Com requisitos definidos; divide em etapas verificáveis. Produz tasks/plan.md e, por padrão, tasks/todo.md; pode usar o tracker definido pelo projeto. | Leia a spec e use planning-and-task-breakdown para planejar as etapas e dependências. |
| incremental-implementation | Para executar o plano em partes pequenas que funcionem e possam ser verificadas. | Use incremental-implementation para concluir apenas a próxima tarefa do plano. |
| git-workflow-and-versioning | Ao trabalhar com branches, commits, conflitos e versões; mantém mudanças compreensíveis e separadas. | Use git-workflow-and-versioning para revisar o diff e preparar um commit só desta correção. |
| code-review-and-quality | Antes de integrar uma mudança; avalia correção, clareza, arquitetura, segurança e desempenho. | Use code-review-and-quality para revisar estas alterações e explicar os riscos. |
| security-and-hardening | Em login, permissões, dados e integrações; verifica proteção das entradas, segredos e acesso. | Use security-and-hardening para revisar a autorização deste endpoint por empresa. |
| observability-and-instrumentation | Quando precisa entender o sistema em execução; orienta logs, métricas, rastreamento e alertas úteis. | Use observability-and-instrumentation para diagnosticar falhas de sincronização sem registrar dados sensíveis. |
| unlazy | Em trabalho longo ou incompleto; registra critérios em GATES.md e exige evidências de conclusão. **Não é uma skill de lazy loading.** | Use unlazy nesta migração: registre critérios verificáveis e só considere concluído o que tiver evidência. |

### 3.2 Matt Pocock — 15

Ajudam a esclarecer decisões, organizar issues e desenvolver com testes. O tracker pode ser remoto ou arquivos locais, conforme docs/agents/issue-tracker.md.

| Skill / acionamento | Quando usar e o que entrega | Como pedir no chat |
|---|---|---|
| grilling — Automática/pedido | Testa a solidez de uma ideia com perguntas em rodadas. Cada decisão desbloqueia as próximas. | Use grilling para questionar meu plano de sincronização offline. |
| grill-me — Pedido | Entrada simples para a entrevista de grilling. | Use grill-me para esclarecer como deve funcionar a recuperação de senha. |
| grill-with-docs — Pedido | Combina entrevista e modelagem; registra termos e decisões em documentação. | Use grill-with-docs para definir cancelamento de pedido e registrar as decisões. |
| domain-modeling — Automática/pedido | Alinha o significado de termos do negócio e registra CONTEXT.md/ADRs. | Use domain-modeling para esclarecer cliente, conta e empresa neste código. |
| codebase-design — Automática/pedido | Ajuda a definir módulos com interfaces simples e bons pontos públicos de teste. | Use codebase-design para avaliar a interface do módulo de cobrança. |
| tdd — Automática/pedido | Combina primeiro o ponto público de teste; faz um teste falhar, implementa o mínimo e verifica. | Use tdd para impedir pedido sem itens; vamos testar pela interface pública do caso de uso. |
| code-review — Automática/pedido | Compara alterações com uma referência Git em dois eixos: padrões do projeto e requisitos da spec. Prevê revisões em subagentes. | Use code-review desde main e confira também os requisitos da issue 428. |
| to-spec — Pedido | Sintetiza decisões já discutidas e publica uma spec no tracker; não recomeça a entrevista. | Use to-spec para registrar no tracker a recuperação de senha que acabamos de definir. |
| to-tickets — Pedido | Divide uma spec em entregas completas pequenas e registra os bloqueios entre tickets. | Use to-tickets nesta spec; cada ticket deve ter critérios e dependências. |
| implement — Pedido | Implementa uma spec ou tickets, verifica tipos/testes, chama revisão e prevê commit na branch atual. | Use implement na issue 428, seguindo os critérios e o tracker do projeto. |
| handoff — Pedido | Salva no diretório temporário um documento para a próxima sessão, com referências e skills sugeridas. | Use handoff: a próxima sessão continuará os testes desta integração. |
| wayfinder — Pedido | Organiza trabalho muito incerto em um mapa de tickets de decisão; por padrão planeja, sem executar a implementação. | Use wayfinder para descobrir as decisões necessárias para migrar o faturamento. |
| triage — Pedido | Qualifica issues e PRs externos, verifica informações e atribui estados que deixam a tarefa pronta para execução. Pode escrever no tracker. | Use triage na issue 428 para identificar informações faltantes e preparar o trabalho. |
| setup-matt-pocock-skills — Pedido | Configura tracker, vocabulário de triagem e organização dos documentos do domínio. | Use setup-matt-pocock-skills e configure o fluxo deste repositório com o tracker que usamos. |
| improve-codebase-architecture — Pedido | Investiga áreas de atrito e apresenta candidatos de melhoria em relatório HTML; você escolhe o que aprofundar. | Use improve-codebase-architecture no módulo de pedidos e mostre por onde começar. |

**Pré-requisito do fluxo com tracker:** confira docs/agents/issue-tracker.md. O instalador pode criar o setup local quando ele não existe; -SkipMattPocockSetup pula esse passo. Não suponha que publicar no tracker significa GitHub: leia a configuração do projeto. Especifique “somente rascunho local” quando ainda não quiser publicar.

### 3.3 Superpowers — 7

| Skill | Quando usar e o que faz | Como pedir no chat |
|---|---|---|
| systematic-debugging | Investiga causa, padrões e hipóteses antes de corrigir. | Use systematic-debugging neste erro 500. Primeiro reproduza e explique a causa. |
| receiving-code-review | Avalia sugestões recebidas e verifica se fazem sentido antes de aplicá-las. | Use receiving-code-review para analisar estes comentários do PR e corrigir os procedentes. |
| verification-before-completion | Exige verificação recente antes de afirmar que terminou. | Use verification-before-completion e confira os critérios desta entrega. |
| dispatching-parallel-agents | Divide problemas independentes entre agentes quando o ambiente e o escopo permitem. | Use dispatching-parallel-agents para investigar estes dois bugs independentes, sem editar os mesmos arquivos. |
| using-git-worktrees | Confere se já há isolamento e prepara outro diretório de trabalho para uma branch quando necessário. | Use using-git-worktrees para isolar esta feature das mudanças em andamento. |
| finishing-a-development-branch | Após testes passando, ajuda a escolher e executar o encerramento da branch. | Use finishing-a-development-branch e apresente as opções de integração desta feature. |
| writing-skills | Desenvolve skills com cenários que demonstram a falha antes e a melhoria depois. Voltada a mantenedores. | Use writing-skills para criar um guia de revisão de migrações e validar seu comportamento. |

São skills individuais: o hub não instala automaticamente o plugin e os hooks completos do Superpowers.

### 3.4 Tecnologia, código e navegador — 10

| Skill / distribuição | Quando usar e o que faz | Como pedir no chat |
|---|---|---|
| nestjs-clean-architecture — NestJS | Segue as camadas e convenções dos backends: controllers, aplicação, domínio, persistência, DTOs, Swagger e validação. | Use nestjs-clean-architecture para adicionar consulta de pedidos seguindo o módulo vizinho. |
| angular-coreui — Angular | Orienta TypeScript, arquitetura, reatividade e componentes Angular/CoreUI conforme o projeto. | Use angular-coreui para implementar o formulário de edição de cliente. |
| coreui-styling — Angular | Aplica o design system compartilhado: shell CoreUI, ds-*, layout/shared, cards, grids, contraste e temas. | Use coreui-styling para ajustar esta tela ao padrão do sistema e verificar claro/escuro. |
| claude-android-ninja — Android | Guia Kotlin, Compose, ViewModels, injeção, persistência, navegação e Gradle. Requer o ambiente Android. | Use claude-android-ninja para criar a tela de leitura offline respeitando as versões do app. |
| codegraph — NestJS, Angular, Android e minimal | Orienta o uso do MCP de grafo para entender símbolos, chamadas e impacto. Precisa de índice acessível. | Use codegraph para mostrar quem chama a função de cancelamento e o que pode ser afetado. |
| explore-codebase — mesmas quatro famílias | Usa o grafo para explicar estrutura e fluxo antes de editar. | Use explore-codebase para mapear o login, com arquivos e responsabilidades. |
| debug-issue — mesmas quatro famílias | Rastreia o erro pelo grafo; complementa a investigação de causa. | Use debug-issue para rastrear de onde vem este valor nulo. |
| refactor-safely — mesmas quatro famílias | Confere dependências e chamadores antes e depois de uma refatoração. | Use refactor-safely para renomear este método preservando o comportamento. |
| review-changes — mesmas quatro famílias | Parte do diff Git e verifica impacto e cobertura das áreas afetadas. | Use review-changes no diff atual e destaque os pontos sem teste. |
| browser-harness — Angular e minimal | Controla navegador real por CDP: navegação, cliques, preenchimento e sessões autenticadas. Exige instalação/conexão próprias. | Use browser-harness para verificar o formulário no ambiente local com dados de teste. |

A versão descrita em uma skill não autoriza atualizar a stack do produto. O agente deve ler as dependências reais antes de aplicar exemplos.

### 3.5 ECC adaptado para o AgentHub — 6

| Skill / distribuição | Quando usar e o que faz | Como pedir no chat |
|---|---|---|
| contract-first — Angular e NestJS | Alinha campos, tipos, valores nulos, erros e compatibilidade entre consumidor e API. Em NestJS code-first, mantém DTOs/Swagger como fonte do contrato. | Use contract-first antes de acrescentar status ao pedido; confira a API e os consumidores Angular. |
| api-design — NestJS | Orienta rotas REST, códigos HTTP, paginação, filtros, autorização e versões, respeitando o formato atual do produto. | Use api-design para planejar paginação de pedidos sem mudar o envelope já consumido. |
| e2e-testing — Angular e nomes *-www / *-ajuda | Cria e mantém testes Playwright de jornadas reais, evidências e diagnóstico de testes intermitentes. | Use e2e-testing para testar login inválido e válido no ambiente de teste. |
| skill-stocktake — manutenção do hub / global opcional | Inventaria fontes sem contar junctions repetidas, identifica mudanças, sobreposições e referências quebradas. Não mede uso real. | Use skill-stocktake para revisar as skills do hub e listar o que precisa de atualização. |
| eval-harness — manutenção do hub / global opcional | Compara uma versão atual e uma candidata da skill/prompt usando os mesmos casos e critérios. | Use eval-harness para medir se esta mudança de prompt melhora os resultados, incluindo regressões. |
| security-scan — manutenção do hub / global opcional | Audita instruções, MCPs, hooks e permissões com scanner e revisão manual; sem correção automática. | Use security-scan nas configurações deste projeto e informe quais arquivos foram realmente cobertos. |

A integração ECC não ativa o restante das skills, hooks ou plugin do vendor. O security-scan usa Node 20+ e pode baixar o pacote fixado na primeira execução. O eval-harness não registra /eval e seu executor ECC fixado recusa execução de candidatos com gate.isolation_required; essa recusa não deve ser contornada.

<h2 id="receitas">4. Receitas de trabalho, do pedido à entrega</h2>

### Feature pequena, acompanhada em arquivos locais

1. spec-driven-development esclarece o que construir.
2. planning-and-task-breakdown organiza o plano e as tarefas.
3. incremental-implementation executa uma parte de cada vez, com a skill da stack e tdd quando o trabalho pede teste primeiro.
4. code-review-and-quality revisa; verification-before-completion confere a entrega.

```text
Quero adicionar um filtro por status na lista de pedidos.
Use spec-driven-development para definir o comportamento.
Depois da definição, planeje com planning-and-task-breakdown.
Nossa fonte de verdade será a spec e o plano local; não publique issues.
```

### Feature compartilhada em issues

**grill-with-docs → to-spec → to-tickets → implement + tdd → code-review.**

```text
Use grill-with-docs para esclarecer a issue 428.
Quando fecharmos as decisões, use to-spec e to-tickets no tracker configurado.
Quero tickets pequenos, com dependências e critérios de aceite.
O tracker será a lista oficial de tarefas.
```

Escolha um lugar oficial para acompanhar o trabalho. Um plano pode apontar para issues, mas evite manter duas listas divergentes. to-spec registra decisões já tomadas; spec-driven-development ajuda a produzi-las. Não é preciso rodar ambos para criar duas specs.

### Bug: investigar, corrigir e proteger contra repetição

```text
Ao salvar um cliente sem telefone, a API retorna 500.
Esperado: aceitar telefone ausente, conforme o contrato atual.
Use systematic-debugging e debug-issue se o grafo estiver disponível.
Reproduza o erro, encontre a causa e corrija com um teste de regressão.
Informe o resultado do teste e quais outros fluxos podem ser afetados.
```

Para pedir **somente diagnóstico**, troque “corrija” por “explique a causa sem alterar arquivos”.

### Alteração conjunta de frontend e backend

```text
Precisamos exibir o status do pedido na tela.
Use contract-first para conferir DTOs/Swagger, tipos e consumidores existentes.
Preserve clientes antigos e documente campo ausente, nulo e valor desconhecido.
Depois use nestjs-clean-architecture no backend e angular-coreui no frontend.
Verifique uma resposta real da API e o resultado renderizado.
```

### Tela Angular e jornada no navegador

```text
Ajuste a tela de pedidos usando angular-coreui e coreui-styling.
Mantenha o design system do projeto e confira temas claro e escuro.
Com e2e-testing, cubra filtro, lista vazia, erro e resultado encontrado.
Use o comando de inicialização que já existe neste projeto.
```

browser-harness ajuda a interagir com uma página; e2e-testing ajuda a deixar um teste repetível no projeto. O MCP Playwright é uma ferramenta de navegador, não a skill em si.

### Projeto legado sem testes

Comece com explore-codebase e domain-modeling para entender código e vocabulário. Se a arquitetura atrapalha, peça improve-codebase-architecture e escolha uma área. Antes de refatorar, capture o comportamento atual em testes na interface pública.

Isso se chama **teste de caracterização**. Não há uma skill com esse nome selecionada no catálogo. Peça a tarefa diretamente e use codebase-design/refactor-safely como apoio. Se o comportamento atual for um bug, registre essa diferença antes de misturar correção e refatoração.

### Trabalho longo com unlazy

```text
Use unlazy para acompanhar esta migração.
Registre critérios em GATES.md: cenários antigos preservados, novos cenários
funcionando e documentação atualizada.
Para cada critério, defina uma verificação e a evidência esperada.
Mostre qualquer pendência ou impedimento sem marcá-lo como concluído.
```

GATES.md é uma lista de resultados verificáveis. CHECK é o comando; EXPECT é o resultado esperado; EVIDENCE registra a execução. Uma caixa marcada à mão não substitui o teste.

Os comandos abaixo são para o **terminal, na raiz do projeto**. O exemplo usa a pasta do Claude; troque por .agents/skills/unlazy no Codex ou .cursor/skills/unlazy no Cursor.

```powershell
# Verifica a estrutura do arquivo.
node .claude/skills/unlazy/scripts/gate-lint.mjs GATES.md
# Mostra o estado; não executa os CHECKs.
node .claude/skills/unlazy/scripts/gate-check.mjs --status GATES.md
```

Leia cada CHECK e os scripts chamados antes de autorizar sua execução. Eles são comandos reais. Depois da revisão e aprovação explícita:

```powershell
node .claude/skills/unlazy/scripts/gate-check.mjs --approve GATES.md
# Executa novamente para obter evidência atual.
node .claude/skills/unlazy/scripts/gate-check.mjs --reverify GATES.md
```

O hook opcional do unlazy é uma instalação separada; não é ativado por simplesmente carregar a skill.

<h2 id="distribuicao">5. O que chega a cada projeto?</h2>

O instalador usa exceções explícitas de projectFamilies, depois arquivos/dependências de Angular e NestJS, e então os padrões de nome. Uma pasta terminada em -www também pode ser reconhecida como Angular pelo conteúdo.

| Família | Seleção específica | MCPs adicionais aos comuns |
|---|---|---|
| NestJS | nestjs-clean-architecture, as 5 skills de grafo, contract-first e api-design | mongodb; openapi quando Swagger/configuração forem detectados. |
| Angular | angular-coreui, coreui-styling, browser-harness, as 5 de grafo, contract-first e e2e-testing | playwright e coreui. |
| Android | claude-android-ninja e as 5 de grafo | Nenhum adicional. |
| minimal | browser-harness e as 5 de grafo | playwright para nomes *-www e *-ajuda; esses nomes também recebem e2e-testing. |
| Delphi | Lista de stack vazia; as 9 comuns bloqueadas. **O instalador ainda soma as 15 Pocock e as 7 Superpowers.** | Nenhum adicional; o código ainda inclui os MCPs comuns. |
| Manutenção do hub | skill-stocktake, eval-harness e security-scan | Não instala novos MCPs por causa dessas skills. |

**Atenção ao Delphi:** o catálogo contém disabledSkillsUntilSelected, mas o instalador atual não consulta essa flag. Portanto “Delphi não recebe nenhuma skill” não descreve o código atual. Também existe skills/delphi-erpclass sem SKILL.md válido; não deve ser anunciada como skill utilizável. A documentação registra essa divergência, sem alterar a instalação.

Os MCPs comuns são codegraph, context7 e filesystem. Ter o MCP codegraph configurado não significa que o índice do projeto já esteja disponível.

<h2 id="ferramentas">6. Funcionalidades do hub além das skills</h2>

### MCPs: o que permitem fazer

| Ferramenta | Para que serve | Exemplo de pedido / pré-requisito |
|---|---|---|
| codegraph | Encontra símbolos, chamadas e áreas afetadas por mudanças. | “Mostre o fluxo de autenticação usando codegraph.” Requer binário e índice do projeto. |
| context7 | Consulta documentação de bibliotecas para apoiar a implementação. | “Consulte a documentação de Guards usada por este projeto.” Requer conexão; chave pode ampliar limites. |
| filesystem | Oferece operações de arquivo dentro dos caminhos configurados. | “Leia os arquivos de configuração deste projeto.” Respeita as permissões do ambiente. |
| mongodb | Permite inspecionar o MongoDB; o template do hub usa modo somente leitura. | “Mostre os nomes das collections do banco local de teste.” Requer banco acessível e configuração válida. |
| openapi | Expõe o contrato da API para consulta e ferramentas conforme o servidor. | “Mostre parâmetros e respostas do endpoint de pedidos.” Requer a API e o Swagger acessíveis. |
| playwright | Dá ao agente ferramentas para interagir com páginas e conferir a interface. | “Abra a tela local e confira o filtro com dados de teste.” Requer navegador e aplicação acessíveis. |
| coreui | Consulta documentação dos componentes CoreUI. | “Confira as propriedades deste componente antes de alterá-lo.” Disponível na configuração Angular. |

### Memória, regras e contexto

**ai-memory** é opcional e global por agente. Ajuda a continuar trabalho entre sessões quando o servidor e a integração estão ativos. O instalador usa AI_MEMORY_ENABLED e opções como -SkipAiMemory. Não grava uma cópia desse MCP em cada projeto.

**handoff** produz um documento de continuidade; **ai-memory** fornece um serviço de memória. São recursos complementares. Decisões importantes continuam devendo apontar para spec, issue, código ou ADR atualizados.

**Regras curtas e skills sob demanda** evitam repetir guias enormes em todas as conversas. A meta do hub para orientações sempre carregadas é aproximadamente 2 KB por arquivo. Consulte [Higiene de Contexto](context.html).

### Scripts e manutenção

Todos os caminhos abaixo são relativos a D:\AGENTS.

| Script / recurso | O que faz | Quando usar |
|---|---|---|
| scripts/Install-AgentHub.ps1 | Seleciona skills, cria links, gera/mescla MCPs e ponteiros; pode atualizar AGENTS.md e preparar integrações. | Instalação inicial ou mudança do catálogo/configuração. |
| scripts/Test-AgentHub.ps1 | Diagnóstico de arquivos de skills, sintaxe e MCPs esperados. Não comprova conexão ou aprovação na IDE. | Depois de instalar ou ao investigar skill ausente. |
| scripts/Inventory-AgentFiles.ps1 | Inventaria orientações e aponta arquivos sempre carregados que cresceram demais. | Manutenção de contexto. |
| scripts/Sync-EccSkills.ps1 | Sincroniza somente o escopo das seis skills ECC, preservando conteúdo manual. | Atualização isolada dessas skills. |
| scripts/Test-EccInstallation.ps1 | Confere a instalação das skills ECC. | Depois do sync ECC. |
| scripts/Sync-Codegraph.ps1 | Atualiza somente integração/skills de grafo; -Projects recebe raízes exatas e -Initialize solicita indexação. | Ajuste direcionado do codegraph. |
| scripts/Test-CodegraphMcp.py | Verifica a integração MCP do codegraph conforme as opções do script. | Diagnóstico de grafo; consulte --help antes de executar. |
| scripts/Uninstall-AgentHub.ps1 | Remove links ou, com -Full, artefatos gerenciados que pode remover com segurança. | Desinstalação planejada; faça preview. |
| catalog/projects.json | Define famílias, seleção de skills, fornecedores e política padrão de IDEs. | Fonte para decidir o que deve ser distribuído. |
| templates/ e mcp/ | Modelos de regras, AGENTS.md e conexões MCP. | Manutenção do hub; as próximas instalações usam essas fontes. |
| .agenthub-state/ | Registros de propriedade e backups para preservar alterações manuais. | Diagnóstico/recuperação; mantenha local, pois pode conter dados sensíveis. |
| scripts/tests/ | Testes de instalação, preservação de arquivos e integrações. | Ao modificar o instalador e seus auxiliares. |

<h2 id="instalacao">7. How-to: instalar, atualizar e conferir</h2>

### Para quem só quer usar

Se o projeto já tem as skills, abra uma nova sessão da IDE e faça um pedido do catálogo. Não é preciso reinstalar para cada tarefa. Arquivos no disco, skill descoberta e ferramenta conectada são três verificações diferentes.

### Para preparar ou manter a máquina

Use **PowerShell 7**, Git, Python 3.11+ e Node compatível com as ferramentas; security-scan exige Node 20+. Mantenha os submodules do clone e configure as IDEs no .env local a partir de .env.example. O .env contém opções da máquina e não deve ser publicado.

Os comandos seguintes são para o **terminal**. Primeiro veja o que será feito:

```powershell
Set-Location D:\AGENTS
.\scripts\Install-AgentHub.ps1 -WriteAgents -DryRun
```

**Dry-run é simulação.** Não significa que as skills foram instaladas. Para aplicar o mesmo pedido, remova -DryRun e depois diagnostique:

```powershell
.\scripts\Install-AgentHub.ps1 -WriteAgents
.\scripts\Test-AgentHub.ps1
```

O instalador pode afetar vários projetos nas raízes do catálogo. -Roots limita as pastas de famílias; o instalador percorre seus projetos filhos. Para ERPCLASS, por exemplo:

```powershell
.\scripts\Install-AgentHub.ps1 -Roots D:\SISTEMAS\ERPCLASS -Ides Cursor,Codex -WriteAgents -DryRun
```

A opção -Ides restringe a seleção da execução, mas não ignora a política de exclusão. Confira AGENTHUB_IDES e AGENTHUB_EXCLUDE_IDES no .env da máquina.

| Opção | Efeito e cuidado |
|---|---|
| -DryRun | Mostra operações sem aplicar a instalação. |
| -WriteAgents | Atualiza a orientação enxuta do projeto, preservando a seção Local conforme o escritor. |
| -GlobalSkills | Também disponibiliza skills comuns/de processo e de manutenção ECC no escopo pessoal do Codex. Skills de stack continuam locais. |
| -SkipCodegraphInit | Pula a inicialização dos índices de código. |
| -SkipMattPocockSetup | Pula o preparo local dos arquivos do fluxo Pocock. |
| -SkipAiMemory | Pula a configuração da integração opcional de memória nesta execução. |
| -WriteAiMemoryToml | Com ai-memory habilitado, tenta criar o vínculo de projeto quando necessário; não sobrescreve arquivo existente. |
| -AdoptLegacyConfigs | Permite adotar configurações antigas reconhecidas. Revise o preview antes. |
| -ForceAgents | Solicita atualização forçada de AGENTS.md; confira o diff e os backups. |
| -RemoveUnusedIdeFolders / -MigrateLegacyPaths | No código atual, emitem avisos sobre pastas legadas; a remoção automática de pastas inteiras está desativada. |
| -CheckVendorUpdates | Busca metadados remotos e mostra novidades/alterações locais. Não instala skills nem modifica arquivos dos produtos. |
| -UpdateVendors | Tenta avançar os seis vendors dessa rotina por fast-forward; ignora os que têm mudanças locais. Não instala nos produtos nem faz commit dos ponteiros. |

ECC fica fora de -UpdateVendors: suas adaptações exigem revisão específica. -CheckVendorUpdates e -UpdateVendors são modos exclusivos entre si e encerram antes da instalação normal.

**Rotina de atualização:** consultar novidades, revisar, atualizar vendors, revisar o diff, simular a instalação, aplicar e diagnosticar. Comandos para as primeiras etapas:

```powershell
.\scripts\Install-AgentHub.ps1 -CheckVendorUpdates
# Após revisar as novidades:
.\scripts\Install-AgentHub.ps1 -UpdateVendors
git diff --submodule=log
```

**Somente ECC:**

```powershell
.\scripts\Sync-EccSkills.ps1 -GlobalSkills -DryRun
# Após revisar o preview:
.\scripts\Sync-EccSkills.ps1 -GlobalSkills
.\scripts\Test-EccInstallation.ps1 -GlobalSkills
```

**Antes de remover:** o modo padrão remove links; -Full também trata MCPs e ponteiros gerenciados. Configurações manuais, AGENTS.md e ai-memory global são preservados. Veja o preview:

```powershell
.\scripts\Uninstall-AgentHub.ps1 -Full -DryRun
```

### Onde procurar a instalação

| IDE | Skills do projeto | Configuração MCP do projeto |
|---|---|---|
| Cursor | .cursor/skills | .cursor/mcp.json |
| Claude | .claude/skills | .mcp.json |
| Codex | .agents/skills | .codex/config.toml |
| Antigravity | .agents/skills | .agents/mcp_config.json |
| OpenCode | .opencode/skills | opencode.json |
| Kiro | .kiro/skills | .kiro/settings/mcp.json |
| VS Code | .github/skills | .vscode/mcp.json |
| Devin | .devin/skills | .devin/mcp_config.json |

São caminhos gerados pelo hub. O catálogo padrão exclui VS Code e Devin; a política local pode mudar isso. Codex e Antigravity compartilham a pasta .agents/skills.

<h2 id="problemas">8. Problemas comuns e como agir</h2>

| Sintoma | O que conferir | Próximo passo |
|---|---|---|
| A skill não aparece | Está no catálogo da família? Foi instalação real ou apenas -DryRun? A IDE foi selecionada? | Confira o SKILL.md no caminho da IDE, rode o diagnóstico e reabra a sessão. |
| O nome aparece duas vezes | Pode existir escopo pessoal e do projeto, ou plugin adicional. | Confira a origem; não apague uma pasta manual só pelo nome repetido. |
| Um comando /spec ou /eval não existe | Os comandos completos dos fornecedores não são todos instalados. | Peça “Use a skill spec-driven-development...” ou “Use eval-harness...”. |
| codegraph não responde | Binário, índice e projeto correto. | Confira codegraph status no projeto; use o sync direcionado se necessário. Não rode codegraph install por cima dos MCPs mesclados do hub. |
| openapi falha | API parada, Swagger não detectado ou endereço inacessível. | Inicie a API com o comando do projeto e confira a URL real do contrato. |
| mongodb falha | Banco local e configuração de conexão. | Confira o serviço e a entrada do projeto; evite uma segunda instância global/plugin duplicada. |
| Configuração existe, mas MCP não conecta | Aprovação, descoberta e conexão são etapas separadas. | Confira o painel de MCPs da IDE, os logs e a confiança no projeto quando exigida. |
| “Preserved manual file” | O instalador detectou conteúdo que deve preservar. | Leia o arquivo e compare com o modelo; não use exclusão/force como resposta automática. |
| “Configuration update failed ... file preserved” | Sintaxe ou conflito com edição manual. | Inspecione o arquivo indicado e o backup antes de repetir. Não conte esse item como instalado. |
| Diagnóstico acusa skills no Delphi | O diagnóstico atual não filtra as comuns bloqueadas como o instalador faz. | Compare catálogo e instalação efetiva antes de concluir que faltou instalar tudo. |
| O agente afirma “pronto”, mas não mostrou teste | Faltam evidências da entrega. | Peça verification-before-completion com os critérios originais. |

Se precisar de ajuda, envie o nome do projeto, a IDE, o comando executado, se usou -DryRun e a mensagem de erro sem tokens/senhas.

### Checklist de uma boa entrega

- O comportamento solicitado está demonstrado.
- Você consegue entender o diff e os arquivos alterados.
- Testes apropriados foram executados; falhas e verificações não realizadas aparecem no relato.
- A interface foi conferida no navegador quando a tarefa envolve comportamento visual.
- Nenhuma mudança fora do escopo foi misturada silenciosamente.
- A documentação, a spec ou a issue relevante reflete o resultado.

<h2 id="glossario">9. Glossário sem complicação</h2>

| Termo | Significado prático |
|---|---|
| Agente | IA que pode consultar arquivos e executar ferramentas conforme a tarefa e as permissões. |
| Prompt | O pedido escrito no chat. |
| Stack | Tecnologias usadas pelo projeto, como Angular, NestJS ou Android. |
| Spec | Descrição do que deve ser construído e de como saber que funciona. |
| Critério de aceite | Uma condição objetiva para aceitar a entrega: “e-mail inválido é rejeitado”. |
| Tracker / issue / ticket | Lugar de acompanhamento e cada item de trabalho registrado nele. |
| TDD | Criar um teste que falha antes da mudança e depois implementar o necessário para passar. |
| E2E | Teste de uma jornada completa, como abrir a tela, preencher e confirmar o resultado. |
| Regressão | Algo que funcionava e deixou de funcionar após uma mudança. |
| Interface pública / seam | Ponto pelo qual um módulo é usado e testado, sem depender de seus detalhes internos. |
| Contrato / DTO / OpenAPI | Acordo de dados entre sistemas; DTO descreve os dados e OpenAPI documenta a API. |
| ADR | Registro de uma decisão técnica e de seu motivo. |
| Diff / PR / merge | Diferença dos arquivos; pedido de revisão; integração das mudanças. |
| Worktree | Outra pasta de trabalho do mesmo repositório, normalmente para outra branch. |
| Vendor / submodule | Código de fornecedor mantido no hub / referência Git para esse repositório externo. |
| Gate / evidência | Condição para concluir uma etapa / prova de que ela foi verificada. |
| Dry-run | Simulação: mostra o que aconteceria, sem aplicar aquela instalação. |

<h2 id="fontes">10. Fontes e como manter esta página atualizada</h2>

A referência desta página é o **checkout local**, inclusive suas adaptações. Estar presente em vendor não significa estar habilitado. O hub escolhe um subconjunto; por exemplo, using-superpowers e os fluxos completos de instalação ECC não são ativados por essa seleção.

Para conferir detalhes no repositório D:\AGENTS:

- catalog/projects.json: seleção e escopos.
- skills/&lt;nome&gt;/SKILL.md: comportamento e pré-requisitos de cada skill.
- scripts/Install-AgentHub.ps1 e scripts/AgentHub.Ecc.ps1: distribuição efetivamente implementada.
- docs/ecc-integration.md, docs/CODEGRAPH.md e docs/unlazy-cheatsheet.md: detalhes das integrações.
- docs/SKILLS-PLAYBOOK.md: **fonte desta página**.

Fluxo de publicação existente: docs/SKILLS-PLAYBOOK.md → D:\WEB\infra\skills.md → D:\WEB\infra\skills.html. O script D:\WEB\infra\sync-skills.ps1 sincroniza as fontes e chama D:\WEB\build-site.mjs quando há mudanças; a geração completa também atualiza outras páginas do site.

Edite a fonte no hub, confira os nomes e escopos contra o catálogo e gere o HTML novamente. Evite editar apenas o HTML, pois a próxima geração substitui essa edição. Depois abra a página e teste leitura, busca nas tabelas, links e cópia dos exemplos.
