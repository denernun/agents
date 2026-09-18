# Guia geral do AgentHub — do primeiro pedido à entrega

> Um manual para devs juniores escolherem skills, orientarem o agente e verificarem o trabalho.

**Revisado em 18/09/2026.** Conferido contra catalog/projects.json, os SKILL.md selecionados e os scripts deste checkout. O hub seleciona **47 skills**; cada projeto recebe um subconjunto. A instalação no disco não comprova que a IDE carregou a skill ou conectou suas ferramentas.

Este guia ensina o processo completo. O [Playbook de Skills](skills.html) complementa a leitura com consultas por situação e prompts para cada skill.

<style>
#main-content { line-height: 1.75; overflow-wrap: anywhere; }
#main-content h2 { font-size: 1.5rem; font-weight: 750; margin: 2.5rem 0 1rem; scroll-margin-top: 1.5rem; }
#main-content h3 { font-size: 1.13rem; font-weight: 650; margin: 1.8rem 0 .7rem; }
#main-content p, #main-content ul, #main-content ol { margin: .8rem 0; }
#main-content ul { padding-left: 1.4rem; list-style: disc; }
#main-content ol { padding-left: 1.4rem; list-style: decimal; }
#main-content a { color: #a5b4fc; text-decoration: underline; text-underline-offset: 3px; }
#main-content a:hover { color: #c7d2fe; }
#main-content .modern-table { min-width: 620px; }
#main-content .modern-table td { white-space: normal; vertical-align: top; min-width: 130px; }
#main-content .modern-table td:first-child { overflow-wrap: anywhere; min-width: 180px; }
#main-content .code-block-container pre { white-space: pre-wrap; padding-top: 2.4rem; }
#main-content .code-copy-btn { opacity: 1; }
#main-content a:focus-visible, #main-content button:focus-visible { outline: 2px solid #818cf8; outline-offset: 3px; }
</style>

**Navegação:** [Conceitos](#conceitos) · [Primeiro pedido](#primeiro-pedido) · [Escolher o fluxo](#fluxos) · [Passo a passo local](#fluxo-local) · [Fluxo com issues](#fluxo-tracker) · [Receitas](#receitas) · [47 skills](#catalogo) · [Distribuição](#distribuicao) · [Ferramentas](#ferramentas) · [Instalação](#instalacao) · [Diagnóstico](#diagnostico) · [Entrega](#entrega).

<h2 id="conceitos">1. Entenda as peças antes de começar</h2>

Uma **skill** é um guia que o agente de IA consulta para realizar um tipo de trabalho. Ela pode ensinar a investigar um erro, planejar uma feature ou seguir a arquitetura da equipe. Você continua definindo o objetivo e conferindo o resultado.

O **AgentHub** reúne esses guias e distribui os selecionados para projetos e IDEs. Ele também prepara configurações de ferramentas e orientações curtas. Não é necessário aprender todos os nomes para começar.

| Conceito | O que significa | Exemplo |
|---|---|---|
| Agente | A IA com acesso às ferramentas permitidas no seu ambiente. | Lê o projeto, propõe uma mudança, edita e testa quando solicitado. |
| Skill | Um roteiro de trabalho carregado quando necessário. | systematic-debugging organiza a investigação de um erro. |
| MCP | Uma conexão entre o agente e uma ferramenta. | codegraph consulta relações entre partes do código. |
| AGENTS.md / regras | Orientações curtas do projeto, consultadas com frequência. | Comandos, stack e ponteiros para guias detalhados. |
| Referências | Material complementar da skill. | Exemplos de Swagger ou padrões de CSS. |
| Hook | Uma ação executada em um evento da sessão. | Uma integração de memória pode usar hooks. Instalar a skill não ativa todos os hooks do fornecedor. |
| Junction | Atalho de pasta do Windows. | A pasta de skills do projeto aponta para a fonte no hub. |
| Catálogo | A seleção de skills e ferramentas por projeto. | catalog/projects.json. |
| Tracker | Onde a equipe registra e acompanha o trabalho. | GitHub Issues ou arquivos locais, conforme a configuração. |
| Fonte de verdade | O registro que vale quando dois documentos divergem. | A spec aprovada ou a issue oficial da tarefa. |

**Exemplo completo:** você pede uma correção; systematic-debugging orienta a investigação; o MCP codegraph ajuda a encontrar o código; o agente altera os arquivos e executa testes; você recebe o diff e as evidências.

<h2 id="primeiro-pedido">2. Seu primeiro pedido, em cinco passos</h2>

1. Abra a pasta do projeto correto.
2. Diga se quer **entender**, **planejar**, **revisar** ou **implementar**.
3. Descreva o comportamento atual e o esperado, com tela, arquivo ou issue.
4. Informe os limites e onde o trabalho será acompanhado.
5. Peça uma explicação do resultado e das verificações realizadas.

**Copie no chat da IDE, não no terminal:**

```text
Sou dev júnior neste projeto.
Quero entender como o cadastro de clientes funciona, sem alterar arquivos.
Use explore-codebase se estiver disponível.
Mostre o caminho da tela até a API, os arquivos principais e a função de cada um.
Explique os termos técnicos que aparecerem.
```

Um pedido de implementação deve deixar o resultado observável:

```text
No cadastro de clientes, um e-mail sem @ está sendo aceito.
Quero rejeitar esse valor e mostrar a mensagem no padrão do projeto.
Confira a validação existente, implemente a menor correção e teste os cenários.
Não altere os demais campos.
Ao terminar, explique os arquivos modificados e mostre os testes executados.
```

### Como chamar uma skill sem depender de atalhos

Escreva **“Use a skill nome-da-skill para...”**. Esse formato não depende de um comando específico da IDE. Muitas skills também permitem que o agente as selecione pela descrição da tarefa.

As skills marcadas como **Pedido** no catálogo exigem solicitação explícita. O seletor e os atalhos variam por ambiente. O hub distribui SKILL.md; ele não instala todos os comandos dos fornecedores. Portanto, /spec, /plan, /build e /eval não são garantidos. Prefira os nomes completos nos exemplos deste guia.

### Quanto processo uma tarefa precisa?

Corrigir um texto de botão normalmente pede uma edição e conferência visual. Alterar permissões de faturamento exige entender regras, testar acesso e revisar impacto. Use um processo proporcional ao trabalho. Não peça as 47 skills juntas.

Se já há uma spec aprovada e tarefas claras, continue de onde o projeto está. Não gere uma segunda especificação ou uma nova lista só para repetir o fluxo.

<h2 id="fluxos">3. Escolha um fluxo e um lugar para acompanhar o trabalho</h2>

| Situação | Caminho inicial | Registro principal |
|---|---|---|
| Não conheço o código | explore-codebase | Explicação com arquivos e fluxo real. |
| Tenho dúvidas sobre a ideia | grill-me ou grill-with-docs | Decisões; CONTEXT.md e ADRs quando apropriado. |
| Falta definir o que construir | spec-driven-development | Spec no formato e local do projeto. |
| Preciso transformar a conversa em spec no tracker | to-spec | Spec no tracker configurado. |
| Quero planejar uma mudança local | planning-and-task-breakdown | tasks/plan.md e, por padrão, tasks/todo.md. |
| Preciso de tickets compartilhados e bloqueios visíveis | to-tickets | Tickets do tracker. |
| O plano já está pronto | incremental-implementation | Tarefas, código e evidências por etapa. |
| A spec/issue do fluxo Pocock está pronta | implement | Spec/tickets, código, revisão e commit. |
| Existe um erro reproduzível | systematic-debugging | Causa, correção e teste de regressão. |

**Addy e Pocock são conjuntos de práticas, não tipos diferentes de projeto.** O planejamento Addy também aceita tracker quando o projeto o define. O importante é escolher onde ficam os requisitos e as tarefas, e manter esse registro atualizado.

<h2 id="fluxo-local">4. Fluxo A: da ideia ao código com arquivos locais</h2>

Exemplo: adicionar um filtro de status à lista de pedidos.

### Etapa 1 — Definir o comportamento

Use spec-driven-development para esclarecer requisitos. Uma spec simples deve dizer o objetivo, o que entra e o que fica fora, as regras, os testes aplicáveis e os critérios de aceite.

```text
Use spec-driven-development para definir um filtro de status na lista de pedidos.
Confira como os filtros atuais funcionam.
Precisamos definir status disponíveis, valor inicial, lista vazia e erros.
Registre a spec no padrão do projeto e apresente para revisão.
Nesta etapa não implemente o código.
```

**O que conferir:** o filtro deve ser explicado pela experiência do usuário. “Alterar três arquivos” não é critério de sucesso; “selecionar Cancelado mostra apenas pedidos cancelados” é.

SPEC.md é uma convenção possível. Se o projeto já usa outro formato, mantenha-o. Para várias capacidades independentes, a skill prevê um mapa dos módulos e dependências antes das specs.

### Etapa 2 — Dividir em entregas pequenas

Após a definição aprovada:

```text
Leia a spec aprovada e use planning-and-task-breakdown.
Crie tasks/plan.md e tasks/todo.md, se forem os locais oficiais deste projeto.
Cada tarefa deve entregar um comportamento verificável.
Inclua dependências, critérios de aceite e os comandos reais de verificação.
Não sobrescreva tarefas pendentes de outro trabalho.
```

Uma boa etapa é “o usuário consegue filtrar por um status”. “Criar todos os DTOs, depois todas as telas” pode deixar o projeto sem uma parte utilizável por muito tempo.

### Etapa 3 — Implementar e testar por parte

```text
O plano foi aprovado. Use incremental-implementation na próxima tarefa.
Aplique as skills da stack e use tdd para o comportamento que vamos testar.
Confira o ponto público de teste antes de escrever o teste.
Execute as verificações aplicáveis e explique o resultado antes de ampliar o escopo.
```

A skill tdd trabalha com **um teste que falha → implementação mínima → teste passando**. Ela pede alinhamento dos pontos públicos de teste e deixa a refatoração para a revisão. Prefira testes do comportamento, não testes de detalhes internos que mudam a cada refatoração.

### Etapa 4 — Revisar e demonstrar

```text
Use code-review-and-quality para revisar esta entrega contra a spec.
Depois use verification-before-completion.
Mostre o que passou, o que falhou e o que não foi verificado.
Explique como eu posso conferir o comportamento no ambiente local.
```

Compilar é uma evidência útil, mas não prova sozinho que o filtro mostra os pedidos corretos.

<h2 id="fluxo-tracker">5. Fluxo B: decisões e tickets compartilhados</h2>

Use quando a equipe acompanha issues, responsáveis e dependências.

**grill-with-docs → to-spec → to-tickets → implement + tdd → code-review.**

1. Confira docs/agents/issue-tracker.md para saber onde as issues vivem.
2. Use grill-me para esclarecer a ideia; use grill-with-docs quando também quiser registrar termos e decisões.
3. Peça to-spec quando as decisões estiverem maduras.
4. Peça to-tickets para dividir a spec em entregas com dependências.
5. Execute a próxima parte com implement, mantendo o tracker atualizado conforme o combinado.
6. Revise contra uma referência Git e contra os requisitos.

```text
Use grill-with-docs para esclarecer a issue 428.
Quando fecharmos as decisões, use to-spec para publicar uma única spec
no tracker configurado e to-tickets para criar tarefas pequenas.
Cada ticket deve ter comportamento esperado, verificação e dependências.
O tracker será nossa lista oficial de trabalho.
```

**Se ainda não quiser publicar:** diga “Prepare somente um rascunho local”. to-spec, to-tickets e triage podem escrever no tracker; implement prevê revisão e commit. Informe o limite no pedido.

### Preparar o fluxo uma vez por repositório

setup-matt-pocock-skills configura tracker, triagem e documentos de domínio. O instalador do hub também tem um preparo local: cria arquivos ausentes, escolhe o modelo GitHub quando detecta uma origem GitHub e o modelo Markdown local nos demais casos. Isso não configura automaticamente qualquer tracker externo nem cria labels remotas.

Confira a configuração gerada. A skill de setup permite adequá-la ao fluxo real da equipe; -SkipMattPocockSetup pula esse preparo durante a instalação.

### Diferenças que costumam confundir

| Comparação | Escolha prática |
|---|---|
| spec-driven-development × to-spec | A primeira ajuda a esclarecer e especificar. A segunda sintetiza decisões existentes e publica no tracker. |
| planning-and-task-breakdown × to-tickets | A primeira produz o plano e usa a lista oficial definida, local ou externa. A segunda produz tickets completos com bloqueios. |
| incremental-implementation × implement | A primeira orienta execução em partes pequenas. A segunda executa uma spec/tickets do fluxo Pocock e prevê testes, revisão e commit. |
| grill-me × grill-with-docs | Ambas entrevistam; a segunda também registra o modelo de domínio e decisões. |
| code-review × code-review-and-quality | A primeira compara diff com padrões e spec; a segunda oferece critérios amplos de qualidade. |
| handoff × ai-memory | A skill escreve um documento de continuidade; o serviço de memória integra sessões quando configurado. |

Um plano pode apontar para tickets. Evite duplicar o estado de cada tarefa em dois lugares que podem divergir.

<h2 id="receitas">6. Receitas para o dia a dia</h2>

### Corrigir um bug

```text
Salvar cliente sem telefone retorna 500.
Esperado: telefone ausente é permitido pelo contrato atual.
Use systematic-debugging para reproduzir e identificar a causa.
Use debug-issue se o codegraph estiver disponível.
Corrija e adicione um teste de regressão; mostre o resultado.
```

Se quer apenas entender, diga “Diagnostique sem alterar arquivos”. A investigação não depende de você saber a causa.

### Criar ou alterar uma API NestJS

```text
Use nestjs-clean-architecture e api-design para adicionar paginação à consulta.
Primeiro confira DTOs, Swagger, autorização e o envelope existente.
Se o contrato mudar, use contract-first e identifique os consumidores afetados.
Verifique sucesso, entrada inválida, acesso negado, página vazia e ordenação.
```

api-design e contract-first são as adaptações ECC selecionadas. Preserve DTOs/Swagger como fonte do contrato nos projetos NestJS code-first; não crie uma especificação paralela manual que possa divergir.

### Implementar uma tela Angular

```text
Use angular-coreui e coreui-styling para implementar o filtro de pedidos.
Siga o design system existente, incluindo temas claro e escuro.
Se precisar mudar dados da API, use contract-first.
Use e2e-testing para deixar um teste repetível da jornada principal.
Confira também lista vazia, erro e navegação por teclado.
```

browser-harness ajuda a operar um navegador real. e2e-testing orienta testes Playwright mantidos no projeto. A existência de um não garante que o outro esteja configurado.

### Refatorar código antigo

```text
Use explore-codebase e codebase-design para entender o módulo de cobrança.
Antes de refatorar, proponha testes que capturem o comportamento atual
pela interface pública. Depois use refactor-safely e confira os chamadores.
Mantenha as regras de negócio e revise o diff com review-changes.
```

Esses testes iniciais são chamados de **caracterização**. Não existe uma skill específica com esse nome no catálogo. Se descobrir um bug no comportamento atual, registre-o para não misturar correção e refatoração sem perceber.

### Concluir trabalho longo e trocar de sessão

```text
Use unlazy para acompanhar esta migração.
Registre critérios de conclusão em GATES.md e verificações para cada resultado.
Mostre pendências e evidências; uma caixa marcada sozinha não prova conclusão.
Ao fim da sessão, use handoff para registrar o próximo passo e os arquivos relevantes.
```

unlazy é disciplina de conclusão, não otimização de lazy loading. CHECK e EXPECT representam comando e resultado esperado; os comandos precisam ser inspecionados antes de aprovação e execução. O hook opcional não é instalado só por usar a skill.

<h2 id="catalogo">7. As 47 skills selecionadas</h2>

Esta é a seleção do hub, sem incluir plugins pessoais ou tudo que existe nos fornecedores. **Pedido** identifica SKILL.md com disable-model-invocation: true; as demais podem ser chamadas pelo nome ou selecionadas pela tarefa, conforme o agente. Cada nome abaixo tem um prompt de exemplo no [Playbook](skills.html#catalogo).

### Comuns — 9

| Skill | Use para | O que esperar |
|---|---|---|
| using-agent-skills | Escolher o método conforme a tarefa. | Roteamento por fase e disciplina de escopo. |
| spec-driven-development | Definir uma mudança antes do código. | Spec com requisitos e critérios de aceite. |
| planning-and-task-breakdown | Dividir trabalho já compreendido. | Plano, tarefas, dependências e verificações. |
| incremental-implementation | Implementar por partes funcionais. | Uma etapa verificável por vez. |
| git-workflow-and-versioning | Organizar branches, commits e versões. | Histórico e mudanças compreensíveis. |
| code-review-and-quality | Revisar antes da integração. | Análise de correção, clareza, arquitetura, segurança e desempenho. |
| security-and-hardening | Proteger entradas, dados e acesso. | Validações e riscos fundamentados no projeto. |
| observability-and-instrumentation | Tornar falhas e comportamento visíveis. | Logs, métricas, rastreamento e alertas úteis. |
| unlazy | Evitar entregas longas pela metade. | Critérios e evidências em GATES.md. |

### Matt Pocock — 15

| Skill | Use para | O que esperar / acionamento |
|---|---|---|
| grilling | Questionar e amadurecer decisões. | Perguntas em rodadas, com recomendações e dependências. |
| grill-me | Iniciar a entrevista sobre a ideia. | Usa grilling. Pedido. |
| grill-with-docs | Entrevistar e registrar contexto. | Combina grilling e domain-modeling. Pedido. |
| domain-modeling | Alinhar conceitos do negócio. | CONTEXT.md e decisões em ADRs. |
| codebase-design | Definir boas interfaces e módulos. | Limites claros e pontos públicos de teste. |
| tdd | Escrever teste antes da implementação. | Ciclo teste falhando → implementação → teste passando. |
| code-review | Revisar desde uma referência Git. | Padrões e spec em dois eixos; prevê subagentes. |
| to-spec | Registrar o que já foi decidido. | Spec no tracker. Pedido. |
| to-tickets | Dividir uma spec em entregas. | Tickets e seus bloqueios. Pedido. |
| implement | Executar uma spec ou tickets. | Implementação, testes, revisão e commit. Pedido. |
| handoff | Continuar em outra sessão. | Documento no diretório temporário, referências e pendências. Pedido. |
| wayfinder | Esclarecer trabalho maior que uma sessão. | Mapa de tickets de decisão; planejamento por padrão. Pedido. |
| triage | Qualificar issues e PRs externos. | Informações faltantes, estados e tarefa pronta para execução. Pedido. |
| setup-matt-pocock-skills | Preparar o fluxo no repositório. | Configuração do tracker, triagem e documentos. Pedido. |
| improve-codebase-architecture | Identificar melhorias arquiteturais. | Relatório HTML com candidatos para você escolher. Pedido. |

### Superpowers — 7

| Skill | Use para | O que esperar |
|---|---|---|
| systematic-debugging | Investigar falhas antes de corrigir. | Causa sustentada por reprodução e evidências. |
| receiving-code-review | Avaliar sugestões recebidas. | Verificação técnica antes de aceitar ou contestar. |
| verification-before-completion | Conferir se a entrega está pronta. | Verificação recente e limitações explícitas. |
| dispatching-parallel-agents | Dividir tarefas independentes. | Agentes com escopos separados, quando autorizados e disponíveis. |
| using-git-worktrees | Isolar uma mudança em outra pasta de trabalho. | Checagem do isolamento existente e worktree quando necessário. |
| finishing-a-development-branch | Encerrar a branch após testes. | Opções de integração e execução da escolha. |
| writing-skills | Criar ou melhorar skills. | Cenários que demonstram falha antes e melhora depois. |

### Tecnologia e navegação — 10

| Skill | Use para | O que esperar |
|---|---|---|
| nestjs-clean-architecture | Backend NestJS. | Camadas, DTOs, Swagger e convenções do produto. |
| angular-coreui | Frontend Angular/CoreUI. | Arquitetura, tipos, reatividade e componentes. |
| coreui-styling | Layout e estilos dos frontends Angular. | Shell CoreUI, ds-*, layout/shared, cards e contraste consistentes. |
| claude-android-ninja | Apps Android Kotlin/Compose. | Orientação de telas, estado, persistência, navegação e Gradle. |
| codegraph | Navegar relações do código. | Consulta ao MCP e ao índice do projeto. |
| explore-codebase | Entender código antes de editar. | Mapa de estrutura e fluxo usando o grafo. |
| debug-issue | Rastrear o código envolvido no erro. | Chamadas e áreas suspeitas para investigar. |
| refactor-safely | Refatorar preservando comportamento. | Análise dos chamadores e impacto antes/depois. |
| review-changes | Revisar o diff e seu alcance. | Riscos e pontos sem cobertura nas áreas afetadas. |
| browser-harness | Operar um navegador real. | Navegação, cliques e preenchimento; requer conexão CDP. |

### ECC adaptado — 6

| Skill | Use para | Distribuição / limites |
|---|---|---|
| contract-first | Alinhar o contrato entre API e consumidores. | Angular e NestJS; preserva DTOs/Swagger canônicos. |
| api-design | Desenhar ou revisar rotas REST. | NestJS; mantém convenções de respostas, filtros e paginação. |
| e2e-testing | Criar testes de jornada com Playwright. | Angular e nomes *-www / *-ajuda; usa ambiente e dados de teste. |
| skill-stocktake | Inventariar e revisar skills. | Manutenção do hub e global opcional; não mede uso real. |
| eval-harness | Comparar skills/prompts com casos fixos. | Manutenção; registra PASS, FAIL e NOT RUN. Não registra /eval. |
| security-scan | Auditar configurações dos agentes. | Manutenção; scanner e revisão manual, sem auto-fix. Node 20+. |

O executor ECC fixado recusa executar candidatos com gate.isolation_required. O fluxo de avaliação usa verificações autorizadas do ambiente e não deve contornar essa recusa. O security-scan pode baixar o pacote fixado na primeira execução; a cobertura dos arquivos deve ser comprovada.

<h2 id="distribuicao">8. Origem e distribuição: o que está realmente disponível?</h2>

### De onde vêm as peças

| Fonte | Como entra no hub | Função |
|---|---|---|
| addyosmani/agent-skills | Submodule vendor/addyosmani-agent-skills; seleção espelhada. | 8 skills comuns de processo. |
| mattpocock/skills | Submodule vendor/mattpocock-skills; seleção espelhada. | 15 skills de decisões, domínio e execução. |
| obra/superpowers | Submodule vendor/superpowers; seleção espelhada. | 7 skills de processo. |
| Leonxlnx/unlazy | Submodule vendor/unlazy. | 1 skill comum de conclusão verificável. |
| browser-use/browser-harness | Submodule vendor/browser-harness. | 1 skill de controle de navegador. |
| Drjacky/claude-android-ninja | Submodule vendor/claude-android-ninja. | 1 skill Android. |
| affaan-m/ECC | Submodule vendor/ecc; 6 adaptações versionadas em skills/. | Contratos, APIs, E2E e manutenção. |
| Guias locais do AgentHub | Arquivos em skills/. | 8 skills de stack, estilo e navegação por grafo. |
| colbymchenry/codegraph | Ferramenta externa configurada pelo hub; não é submodule deste checkout. | Índice e MCP de código. |
| akitaonrails/ai-memory | Integração externa opcional; não é submodule deste checkout. | Memória global compartilhada. |

As fontes são identificadas pelos arquivos locais .gitmodules e catalog/projects.json. Instalar as skills selecionadas não ativa todo o plugin do fornecedor. O roteador comum é using-agent-skills; não é necessário adicionar using-superpowers como segundo roteador.

### Por família de projeto

Além da base comum, Pocock e Superpowers, o instalador aplica a seleção específica:

| Família | Skills específicas / complementos | Ferramentas adicionais |
|---|---|---|
| NestJS | nestjs-clean-architecture, as 5 de grafo, contract-first e api-design. | mongodb e openapi, conforme os pré-requisitos detectados. |
| Angular | angular-coreui, coreui-styling, browser-harness, as 5 de grafo, contract-first e e2e-testing. | playwright e coreui. |
| Android | claude-android-ninja e as 5 de grafo. | Nenhum MCP adicional. |
| minimal | browser-harness e as 5 de grafo. | Nomes *-www / *-ajuda recebem playwright e também a skill e2e-testing. |
| Delphi | Sem skills de stack; bloqueia as 9 comuns, mas o código ainda soma as 15 Pocock e as 7 Superpowers. | O código ainda inclui os MCPs comuns. |
| Manutenção do hub | skill-stocktake, eval-harness e security-scan. | Sem novos MCPs por essas skills; escopo pessoal opcional com -GlobalSkills. |

As cinco de grafo são codegraph, explore-codebase, debug-issue, refactor-safely e review-changes. Os MCPs comuns são codegraph, context7 e filesystem.

A classificação usa projectFamilies para exceções, depois conteúdo Angular/NestJS e então padrões de nome. O sufixo da pasta sozinho não resolve todos os casos.

**Divergência Delphi confirmada no código:** disabledSkillsUntilSelected existe no catálogo, mas o instalador não consulta essa flag. A frase antiga “todas as skills estão desativadas para Delphi” era incorreta. O diagnóstico Test-AgentHub também não filtra as comuns bloqueadas como o instalador faz, podendo acusar ausências esperadas. A pasta skills/delphi-erpclass não contém SKILL.md válido e não conta nas 47 skills.

**Exemplos antigos removidos dos fluxos:** api-and-interface-design, frontend-ui-engineering e browser-testing-with-devtools não estão selecionadas no catálogo atual. Para os casos deste guia, use api-design/contract-first, angular-coreui/coreui-styling e e2e-testing, conforme a necessidade.

<h2 id="ferramentas">9. MCPs, memória e contexto</h2>

| Recurso | Uso simples | O que precisa funcionar |
|---|---|---|
| codegraph | “Mostre quem chama o cancelamento do pedido.” | Binário, índice e projeto correto. Configuração não prova indexação. |
| context7 | “Consulte a documentação desta biblioteca.” | Conexão com o servidor; chave pode ampliar limites. |
| filesystem | “Leia os arquivos necessários deste projeto.” | Caminhos e permissões configurados. |
| mongodb | “Liste collections do banco local de teste.” | Banco acessível e configuração válida; template em modo somente leitura. |
| openapi | “Mostre os parâmetros e respostas desta rota.” | API rodando e Swagger acessível. |
| playwright | “Abra a tela local e confira o filtro.” | Navegador e aplicação acessíveis. |
| coreui | “Confira as propriedades deste componente.” | MCP da família Angular conectado. |
| ai-memory | “Recupere as decisões anteriores deste projeto.” | Serviço e integração global habilitados. |

ai-memory é configurado por agente, não duplicado em cada projeto. O instalador usa AI_MEMORY_ENABLED e pode pular a integração com -SkipAiMemory. A memória ajuda na continuidade; decisões atuais devem apontar para código, spec, issue ou ADR.

AGENTS.md e regras devem permanecer curtos, com ponteiros. Os guias detalhados ficam nas skills e referências, carregados sob demanda. A meta do hub para arquivos sempre carregados é aproximadamente 2 KB. Veja [Higiene de Contexto](context.html).

<h2 id="instalacao">10. How-to de instalação e manutenção</h2>

### Usuário de um projeto já preparado

Abra uma nova sessão do agente, peça a skill pelo nome e confira a origem informada. Não é necessário reinstalar a cada tarefa. Se faltar algo, use o diagnóstico abaixo.

### Preparação da máquina

O hub usa Git, PowerShell 7+, Python 3.11+ e Node compatível com as ferramentas. security-scan exige Node 20+. Projetos Android também dependem do ambiente Android/JDK. Confira os pré-requisitos específicos antes de executar seus fluxos.

Em um clone novo, use os submodules do repositório. Configure as IDEs da máquina no .env a partir de .env.example. Não publique o .env nem .agenthub-state, pois podem conter dados sensíveis.

Os próximos exemplos são para o **terminal PowerShell**, na raiz do hub. As operações de instalação podem alcançar várias famílias de projetos. Para limitar o exemplo a ERPCLASS:

```powershell
Set-Location D:\AGENTS
.\scripts\Install-AgentHub.ps1 -Roots D:\SISTEMAS\ERPCLASS -Ides Cursor,Codex -WriteAgents -DryRun
```

**Dry-run é simulação.** Para executar o mesmo pedido de verdade, remova apenas -DryRun:

```powershell
.\scripts\Install-AgentHub.ps1 -Roots D:\SISTEMAS\ERPCLASS -Ides Cursor,Codex -WriteAgents
.\scripts\Test-AgentHub.ps1 -Roots D:\SISTEMAS\ERPCLASS -Ides Cursor,Codex
```

Depois confira a descoberta da skill e a conexão dos MCPs na IDE. O diagnóstico de arquivos não observa essas etapas.

### Opções do instalador

| Opção | Efeito real / orientação |
|---|---|
| -HubPath CAMINHO | Usa outro diretório como fonte do hub. |
| -Roots CAMINHO | Limita as pastas de famílias cujos projetos filhos serão percorridos. Não é um seletor de repositório individual. |
| -Ides Cursor,Codex | Define candidatos para esta execução; ainda respeita allowlist e exclusões. |
| -WriteAgents | Solicita orientação enxuta conforme template; o modo normal preserva a seção Local na composição. |
| -DryRun | Simula a instalação sem aplicar as mudanças. |
| -GlobalSkills | Acrescenta skills comuns/de processo e manutenção ECC ao escopo pessoal do Codex; stack continua local. |
| -SkipCodegraphInit | Pula a criação dos índices codegraph. |
| -SkipMattPocockSetup | Pula o preparo local do tracker e documentos de domínio. |
| -SkipAiMemory | Pula a integração opcional de memória nesta execução. |
| -WriteAiMemoryToml | Com a integração habilitada, cria vínculo de projeto quando o arquivo não existe. |
| -AdoptLegacyConfigs | Permite adotar entradas antigas reconhecidas; exige revisar conflitos e preview. |
| -ForceAgents | Não reaproveita a seção Local ao compor AGENTS.md. A escrita ainda passa pelas proteções do gerenciador; não use como solução automática para conflitos. |
| -IncludeQoder | Habilita a opção de detecção do Qoder; confira também a política de IDEs. |
| -RemoveUnusedIdeFolders | A rotina atual avisa sobre pastas legadas; não remove pastas inteiras automaticamente. |
| -MigrateLegacyPaths | A rotina atual avisa sobre caminhos legados; não é uma limpeza geral de diretórios. |
| -CheckVendorUpdates | Faz fetch de metadados e relata novidades/alterações locais dos seis vendors dessa rotina. |
| -UpdateVendors | Tenta fast-forward nesses seis vendors, pulando os que têm mudanças locais. ECC fica fora. |

A política local usa AGENTHUB_IDES e AGENTHUB_EXCLUDE_IDES; variáveis já definidas no processo prevalecem sobre o .env. O catálogo é o padrão quando não há override. Sem lista explícita, o instalador detecta IDEs e aplica essa política. VS Code e Devin estão excluídos no catálogo atual.

### Atualizar fornecedores

```powershell
# Consulta; não instala nos projetos.
.\scripts\Install-AgentHub.ps1 -CheckVendorUpdates
# Depois de revisar, atualiza os vendors elegíveis.
.\scripts\Install-AgentHub.ps1 -UpdateVendors
git diff --submodule=log
```

Esses dois modos são exclusivos entre si e encerram antes da instalação normal. -UpdateVendors muda o checkout dos submodules, mas não faz commit dos novos ponteiros nem reinstala nos produtos. Revise o diff; depois simule e aplique a instalação.

ECC exige revisão das seis adaptações e da revisão fixada no catálogo. Não copie os SKILL.md upstream por cima das adaptações locais.

### Sincronizar somente ECC ou codegraph

```powershell
.\scripts\Sync-EccSkills.ps1 -GlobalSkills -DryRun
# Depois de revisar:
.\scripts\Sync-EccSkills.ps1 -GlobalSkills
.\scripts\Test-EccInstallation.ps1 -GlobalSkills
```

Para codegraph, -Projects recebe **raízes exatas de repositórios**, diferente de -Roots do instalador geral:

```powershell
.\scripts\Sync-Codegraph.ps1 -Projects D:\SISTEMAS\ERPCLASS\erpclass-admin -DryRun
```

-Initialize solicita indexação; -Global acrescenta o fallback global do Codex. Não execute codegraph install sobre as configurações mescladas do hub.

### Desinstalar com escopo claro

Primeiro faça uma simulação. O exemplo limita a família ERPCLASS:

```powershell
.\scripts\Uninstall-AgentHub.ps1 -Roots D:\SISTEMAS\ERPCLASS -Full -DryRun
```

Após revisar, retirar -DryRun aplica a remoção. Não execute desinstalação como tentativa inicial de corrigir um aviso de arquivo manual.

| Opção do desinstalador | O que remove ou controla |
|---|---|
| Sem -Full | Links de skills reconhecidos e a junction references. |
| -Full | Também MCPs e ponteiros gerenciados inalterados, além de .ai-memory.toml gerenciado. |
| -GlobalSkills | Links pessoais que apontam para este hub. |
| -RemoveLegacyCodexMcp | Apenas entradas globais legadas reconhecidas de codegraph/context7. |
| -GlobalOnly | Evita percorrer projetos; executa somente a limpeza global solicitada. |
| -Roots / -HubPath | Limitam raízes percorridas e a fonte do hub. |
| -DryRun | Mostra o que seria removido. |

AGENTS.md, conteúdo manual, backups e integração global ai-memory são preservados. A remoção depende de reconhecer a propriedade e as alterações do artefato; não equivale a apagar todas as pastas de IDE.

<h2 id="diagnostico">11. Onde conferir e como resolver problemas</h2>

### Caminhos usados pelo hub

| IDE | Skills por projeto | Configuração MCP |
|---|---|---|
| Cursor | .cursor/skills | .cursor/mcp.json |
| Claude | .claude/skills | .mcp.json |
| Codex | .agents/skills | .codex/config.toml |
| Antigravity | .agents/skills | .agents/mcp_config.json |
| OpenCode | .opencode/skills | opencode.json |
| Kiro | .kiro/skills | .kiro/settings/mcp.json |
| VS Code | .github/skills | .vscode/mcp.json |
| Devin | .devin/skills | .devin/mcp_config.json |

Codex e Antigravity compartilham .agents/skills. Skills globais e locais podem aparecer repetidas; confira a fonte antes de remover qualquer uma.

### Diagnóstico em ordem

1. Confirme se a skill está no catálogo da família.
2. Confira se houve instalação real ou só -DryRun.
3. Verifique a IDE selecionada e o SKILL.md no caminho esperado.
4. Abra uma nova sessão para atualizar a descoberta.
5. Se a skill depende de MCP, confira aprovação, conexão e serviço necessário separadamente.
6. Leia o erro antes de reinstalar ou forçar alterações.

| Sintoma | Interpretação / próximo passo |
|---|---|
| Skill ausente | Pode ser seleção por família, exclusão de IDE ou link faltante. Confira catálogo e diagnóstico. |
| “Preserved manual file” | Conteúdo manual foi preservado. Compare o arquivo com o template antes de decidir. |
| “Configuration update failed ... file preserved” | Há falha de sintaxe ou conflito que precisa de revisão. Não considere esse item atualizado. |
| MCP configurado mas indisponível | Arquivo válido não comprova aprovação, confiança no projeto ou conexão. Confira o painel e logs da IDE. |
| OpenAPI indisponível | Confira se a API e o Swagger estão acessíveis no endereço configurado. |
| MongoDB indisponível | Confira o serviço local e evite instância global/plugin duplicada com a do projeto. |
| codegraph sem resultados | Confira índice, binário e projeto consultado. Ter a configuração MCP não prova que houve indexação. |
| Diagnóstico aponta skills ausentes no Delphi | Compare com a exceção documentada; o diagnóstico atual não filtra as comuns bloqueadas. |
| Página ainda mostra texto antigo | Recarregue com Ctrl+F5; o navegador pode ter guardado a versão anterior. |

Ferramentas de apoio: Test-AgentHub.ps1 verifica arquivos/configuração; Inventory-AgentFiles.ps1 ajuda a encontrar regras grandes; Test-EccInstallation.ps1 verifica ECC; Test-CodegraphMcp.py oferece diagnóstico específico do MCP, com opções em --help.

Ao pedir ajuda, envie projeto, IDE, comando executado, uso ou não de -DryRun e mensagem de erro sem credenciais.

<h2 id="entrega">12. Como saber se ficou pronto</h2>

| Pergunta | Evidência útil |
|---|---|
| Fez o que eu pedi? | Cada critério da spec/issue ligado a um resultado observado. |
| O código continua funcionando? | Comandos e resultados dos testes aplicáveis, com falhas e itens não executados. |
| A tela funciona de verdade? | Jornada conferida no navegador, incluindo estados relevantes. |
| A mudança é compreensível? | Diff focado e explicação dos arquivos alterados. |
| A API continua compatível? | Contrato e consumidores verificados quando foram afetados. |
| A próxima pessoa consegue continuar? | Spec/issue atualizada, pendências claras e handoff quando necessário. |

Peça assim:

```text
Use verification-before-completion e compare a entrega com o pedido original.
Mostre os critérios atendidos, os comandos executados e seus resultados.
Separe o que falhou do que não foi executado.
Explique em linguagem simples o diff e como conferir o resultado.
```

### Glossário rápido

| Termo | Tradução prática |
|---|---|
| Feature / stack | Funcionalidade / tecnologias do projeto. |
| Spec / critério de aceite | O que construir / condição objetiva para aceitar. |
| Ticket / dependência | Item de trabalho / o que precisa estar pronto antes dele. |
| ADR / domínio | Registro de decisão técnica / conceitos e regras do negócio. |
| Seam | Interface pública pela qual se observa e testa um comportamento. |
| E2E / regressão | Teste de uma jornada completa / algo que deixou de funcionar após uma mudança. |
| DTO / contrato | Estrutura dos dados / acordo de comunicação entre sistemas. |
| Diff / PR / merge | Alterações dos arquivos / pedido de revisão / integração. |
| Worktree / submodule | Outra pasta de trabalho do repo / referência a um repositório externo. |
| Gate / evidência | Condição de conclusão / comprovação de que foi verificada. |

<h2 id="manutencao">13. Manutenção deste guia</h2>

Fonte editável: **D:\AGENTS\docs\AGENT-SKILLS-GUIDE.md**. O fluxo existente é:

**Fonte no hub → D:\WEB\infra\agent-skills-guide.md → D:\WEB\infra\agent-skills-guide.html.**

sync-skills.ps1 sincroniza os documentos e chama build-site.mjs quando há alterações. O build completo também gera outras páginas; edições manuais somente no HTML se perdem na próxima geração.

Ao revisar este guia, confira:

- catalog/projects.json e .gitmodules: seleção, escopos e fontes.
- skills/&lt;nome&gt;/SKILL.md: finalidade, acionamento e pré-requisitos.
- scripts/Install-AgentHub.ps1, scripts/AgentHub.Ecc.ps1 e scripts/Uninstall-AgentHub.ps1: comportamento efetivo.
- docs/ecc-integration.md, docs/CODEGRAPH.md e docs/unlazy-cheatsheet.md: detalhes das integrações.
- O [Playbook de Skills](skills.html) e [Higiene de Contexto](context.html): coerência entre os guias publicados.

Mudanças no catálogo pedem revisão da contagem e das tabelas; mudanças no instalador pedem revisão dos comandos e exceções. Valide a geração, os links internos, a busca nas tabelas e a cópia dos exemplos.
