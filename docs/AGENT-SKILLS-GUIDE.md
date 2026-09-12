# Guia de uso das skills do Agent Hub

O Agent Hub centraliza skills, ferramentas e orientações de desenvolvimento
para que diferentes projetos e agentes possam seguir práticas consistentes,
com carregamento sob demanda e configuração adequada para cada tecnologia.

## Repositórios utilizados pelo Hub

As skills e ferramentas externas são mantidas como submodules em `vendor/` e
espelhadas pelo instalador quando necessário. Estes são os repositórios usados:

| Repositório | Papel no Agent Hub |
|---|---|
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | Skills de ciclo de vida: especificação, planejamento, implementação, segurança, revisão e entrega |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Grilling, modelagem de domínio, tickets, implementação e TDD |
| [obra/superpowers](https://github.com/obra/superpowers) | Debugging sistemático, verificação, worktrees, delegação e manutenção de skills |
| [Leonxlnx/unlazy](https://github.com/Leonxlnx/unlazy) | Investigação e correção de carregamento lazy em aplicações web |
| [browser-use/browser-harness](https://github.com/browser-use/browser-harness) | Automação e verificação de navegadores reais |
| [Drjacky/claude-android-ninja](https://github.com/Drjacky/claude-android-ninja) | Skill específica para os projetos Android do hub |
| [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) | Ferramenta de grafo usada pelas skills de exploração, debugging e impacto |
| [akitaonrails/ai-memory](https://github.com/akitaonrails/ai-memory) | Memória compartilhada entre agentes; integração opcional e global |

Os repositórios acima têm funções diferentes. O hub não deve instalar todos os
plugins nativos simultaneamente: ele seleciona as skills pelo catálogo e cria
links apenas para os projetos e IDEs habilitados.

## Regra principal

As skills podem ser combinadas; os roteadores não devem competir.

| Necessidade | Skill/conjunto recomendado | Fonte de verdade |
|---|---|---|
| Entender uma ideia incompleta | `grill-me` ou `grill-with-docs` | decisões, `CONTEXT.md`, ADRs |
| Especificar feature compreendida | `spec-driven-development` ou `to-spec` | `SPEC.md` ou tracker |
| Planejar trabalho local | `planning-and-task-breakdown` | `tasks/plan.md`, `tasks/todo.md` |
| Criar trabalho compartilhado | `to-tickets` | issues/tickets |
| Implementar plano local | `incremental-implementation` + `tdd` | código, testes, commits |
| Implementar tickets | `implement` + `tdd` | tickets, código, commits |
| Corrigir falha | `systematic-debugging` + `tdd` | causa raiz e regressão |
| Revisar merge | `code-review-and-quality` e/ou `code-review` | relatório de review |

Quando houver dúvida, escolha primeiro o tipo de artefato que deve ser a fonte de verdade. Não mantenha duas listas independentes para o mesmo trabalho.

## Skills adicionadas

O catálogo comum agora inclui:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`

Elas são espelhadas do submodule `vendor/addyosmani-agent-skills` e distribuídas pelas mesmas junctions das demais skills.

### Exceção atual: Delphi

Todas as skills estão temporariamente desativadas para a família Delphi no
catálogo, incluindo as skills antigas de navegação. Elas continuam disponíveis
no hub para as demais famílias, mas não serão vinculadas nos projetos `*-erp`.
Para ativar uma skill no Delphi, adicione seu nome em `families.delphi.skills`
ou remova-o de `families.delphi.disabledCommonSkills`, conforme o tipo, e
execute novamente o instalador. O campo `disabledSkillsUntilSelected` documenta
que essa ausência é intencional até a escolha da equipe.

O instalador distribui `SKILL.md`, não os wrappers slash de uma IDE. Portanto, use os nomes diretamente quando necessário:

```text
@spec-driven-development
@planning-and-task-breakdown
@incremental-implementation
```

No Codex, o upstream recomenda invocar skills com `@`; no Cursor e Claude, elas são descobertas nas pastas nativas do projeto. Se uma IDE já possuir os wrappers `/spec`, `/plan` e `/build`, eles podem ser usados, mas continuam representando as skills acima.

## Fluxo A: Addy com artefatos locais

Use quando a mudança será especificada, planejada e executada dentro do checkout, sem publicar tickets.

```text
spec-driven-development
        ↓ aprovação da especificação
planning-and-task-breakdown
        ↓ aprovação do plano
incremental-implementation + tdd
        ↓ teste, verificação e commit por fatia
code-review-and-quality
```

Passos:

1. Use `spec-driven-development` para esclarecer objetivo, estrutura, comandos de teste, limites e critérios de sucesso.
2. Salve a especificação em `SPEC.md` ou caminho acordado.
3. Aguarde aprovação humana; não implemente uma especificação não aprovada.
4. Execute `planning-and-task-breakdown` lendo a especificação aprovada.
5. Gere `tasks/plan.md` e `tasks/todo.md` com dependências, aceitação e verificação.
6. Aguarde aprovação do plano.
7. Para cada tarefa, use `incremental-implementation` e `tdd`: teste focado, menor implementação, verificação, commit e próxima fatia.
8. Antes do merge, use `code-review-and-quality`; acrescente `security-and-hardening` quando houver autenticação, entrada externa, dados sensíveis ou integrações.

Exemplo:

```text
Usuário: "Quero exportar pedidos para Excel."

/spec
→ SPEC.md com formato, permissões, volume, testes e critérios.

/plan
→ tasks/plan.md e tasks/todo.md com fatias verticais.

/build
→ implementa somente a próxima tarefa, usando tdd, verifica e commita.
```

## Fluxo B: Pocock orientado a decisões e tracker

Use quando a mudança começa como decisão/conversa e precisa virar tickets compartilhados.

```text
grill-me ou grill-with-docs
        ↓ entendimento compartilhado
to-spec
        ↓ spec publicada no tracker
to-tickets
        ↓ tickets verticais com bloqueios
implement + tdd
        ↓ código e tickets atualizados
code-review / code-review-and-quality
```

Passos:

1. Use `grill-me` fora do checkout ou `grill-with-docs` quando decisões devem ir para `CONTEXT.md` e ADRs.
2. Quando as decisões estiverem maduras, use `to-spec`. Ele sintetiza o que já foi discutido e não reinicia a entrevista.
3. Publique uma única spec no tracker configurado.
4. Use `to-tickets` para criar tickets verticais, cada um com critérios, verificação e bloqueios.
5. Use `implement` para executar tickets e `tdd` nos seams combinados.
6. Atualize o tracker durante a execução e faça a revisão final.

Exemplo:

```text
Usuário: "Feche as decisões da issue #428, publique a spec e quebre em tickets."

grill-with-docs
→ decisões registradas e entendimento confirmado.

to-spec
→ uma spec na issue/tracker.

to-tickets
→ tickets 1, 2 e 3 com dependências.

implement
→ executa o ticket sem criar uma segunda tasks/todo.md.
```

## `/spec` versus `/to-spec`

### Use `spec-driven-development` ou `/spec` quando:

- ainda não existe uma especificação;
- requisitos, estrutura ou sucesso estão ambíguos;
- a fonte de verdade será um arquivo local;
- uma aprovação deve ocorrer antes do planejamento.

### Use `to-spec` quando:

- a conversa já contém as decisões necessárias;
- existe `CONTEXT.md`, ADR ou issue a respeitar;
- a spec deve ser publicada no tracker;
- não é desejável entrevistar novamente o usuário.

Não execute os dois para a mesma mudança sem uma razão explícita. Isso pode criar duas specs com critérios divergentes. Para converter uma spec local em trabalho compartilhado, publique a existente ou diga que `to-spec` deve apenas sintetizá-la.

## `/plan` versus `/to-tickets`

Use `planning-and-task-breakdown` ou `/plan` quando:

- o trabalho será controlado na branch;
- o resultado esperado é `tasks/plan.md` e `tasks/todo.md`;
- as tarefas são checkpoints locais;
- não há necessidade de atribuição e bloqueios no tracker.

Use `to-tickets` quando:

- cada fatia precisa ser uma issue independente;
- há várias pessoas ou agentes;
- bloqueios precisam ser visíveis fora do checkout;
- GitHub Issues, Linear ou `.scratch` é o tracker oficial.

Exemplo:

```text
Feature pequena, uma pessoa:
  SPEC.md → /plan → tasks/todo.md → /build

Feature compartilhada por três pessoas:
  grill-with-docs → /to-spec → /to-tickets → /implement
```

Não mantenha `tasks/todo.md` e tickets como duas fontes de verdade. Se o tracker for oficial, o arquivo local deve ser apenas índice, se necessário.

## `/build` versus `/implement`

Use `incremental-implementation` ou `/build` quando existe plano local aprovado e cada tarefa deve deixar a branch compilável e testável.

Use `implement` quando existe um conjunto de tickets Pocock e cada execução deve atualizar o tracker.

```text
Plano local aprovado:
  /build Task 2

Issue #428 pronta:
  /implement Issue #428
```

Não use os dois simultaneamente na mesma tarefa. Se começou em tickets, continue com `implement`; se começou em `tasks/plan.md`, continue com `incremental-implementation`.

## TDD

O hub mantém `tdd` do Pocock como TDD padrão para não ativar duas implementações automáticas da mesma disciplina.

Use:

```text
incremental-implementation + tdd
implement + tdd
systematic-debugging + tdd
```

O `test-driven-development` do pacote Addy permanece no vendor, mas não foi adicionado ao catálogo comum. Ele pode ser habilitado futuramente como perfil explícito, desde que `tdd` não seja a rota automática para os mesmos projetos.

## Combinações por caso de uso

### Feature nova em API NestJS

```text
spec-driven-development
planning-and-task-breakdown
api-and-interface-design
incremental-implementation + tdd
security-and-hardening (se aplicável)
code-review-and-quality
```

### Feature decidida em reunião e acompanhada no GitHub

```text
grill-with-docs
to-spec
to-tickets
implement + tdd
code-review
code-review-and-quality
```

### Bug em produção

```text
systematic-debugging
tdd para o teste de regressão
incremental-implementation para a correção
verification-before-completion
code-review-and-quality
```

### Mudança de UI Angular

```text
spec-driven-development (se o comportamento não estiver definido)
frontend-ui-engineering
incremental-implementation + tdd
browser-testing-with-devtools
code-review-and-quality
```

## Regras para agentes e equipe

- Não pré-carregue todos os `SKILL.md` em `AGENTS.md`; use descoberta progressiva.
- Não instale o plugin nativo Addy em paralelo com junctions do hub para os mesmos projetos sem definir precedência.
- Não rode `/spec` e `/to-spec` para produzir duas specs.
- Não rode `/plan` e `/to-tickets` para produzir duas listas.
- Não rode `/build` e `/implement` na mesma tarefa.
- Declare no início a fonte de verdade: `SPEC.md`, `tasks/`, issue ou tracker.
- Skills de domínio podem ser combinadas com skills de processo, por exemplo `nestjs-clean-architecture` + `api-and-interface-design`.
- Depois de cada mudança, verifique `git status`, testes focados, build e review.

## Prompts recomendados

```text
Leia SPEC.md e use planning-and-task-breakdown para criar tasks/plan.md e
tasks/todo.md. Não escreva código ainda.
```

```text
Implemente apenas a próxima tarefa de tasks/todo.md usando
incremental-implementation e tdd. Rode o teste focado antes de continuar.
```

```text
Use grill-with-docs para fechar as decisões. Após minha aprovação, use
to-spec e publique uma única spec no tracker.
```

```text
Implemente a issue #428 usando implement e tdd. Não crie tasks/todo.md;
o tracker é a fonte de verdade.
```

# Manual para desenvolvedores iniciantes

## O que é uma skill

Uma skill é um guia de trabalho para o agente. Ela explica quando usar um
processo, quais passos seguir e como verificar o resultado. Ela não é uma
biblioteca e não altera o programa sozinha.

Skills de processo explicam como trabalhar. Skills de domínio explicam os
cuidados de uma tecnologia ou projeto. Por exemplo:

    incremental-implementation = implementar em etapas pequenas
    nestjs-clean-architecture = padrões específicos de NestJS

As skills são carregadas sob demanda. Não é necessário ler todas no início.

## Como começar uma tarefa

Descreva o objetivo, o que não deve mudar e qual é a fonte de verdade:

    Quero adicionar recuperação de senha. Ainda não existe uma especificação.
    Use spec-driven-development, investigue as dúvidas e crie a spec.
    Não escreva código antes da aprovação.

Para uma correção:

    O endpoint retorna 500 quando o CPF é inválido. Reproduza o problema,
    use systematic-debugging e crie um teste de regressão antes da correção.

Para uma issue já preparada:

    Leia a issue 428 e implemente apenas o próximo ticket usando implement e tdd.

Sempre informe:

1. o que deseja mudar;
2. o que não deve ser alterado;
3. se a fonte de verdade é SPEC.md, tasks/, issue ou tracker;
4. como verificar o resultado, quando souber.

## Catálogo das skills comuns

| Skill | Quando usar |
|---|---|
| using-agent-skills | Começo da tarefa ou dúvida sobre qual skill escolher |
| git-workflow-and-versioning | Qualquer mudança de código |
| code-review-and-quality | Antes de merge ou entrega |
| security-and-hardening | Login, dados sensíveis, entrada externa ou integrações |
| observability-and-instrumentation | Logs, métricas, tracing e alertas |
| unlazy | Lazy loading, carregamento tardio e tamanho do bundle |
| spec-driven-development | Feature nova, mudança grande ou requisito ambíguo |
| planning-and-task-breakdown | Depois de uma spec aprovada |
| incremental-implementation | Implementação em várias etapas |

O unlazy está incluído no catálogo comum e deve ser usado quando o problema
envolver carregamento tardio. Exemplo:

    A tela de relatórios demora e o bundle inicial aumentou.
    Use unlazy para investigar a causa, sem alterar código ainda.

## Catálogo do Matt Pocock

| Skill | Finalidade |
|---|---|
| grilling | Questionar uma decisão até os pontos importantes ficarem claros |
| grill-me | Entrevistar sobre uma ideia |
| grill-with-docs | Entrevistar usando o projeto e registrar contexto |
| domain-modeling | Definir termos e entidades do negócio |
| codebase-design | Melhorar limites e seams de módulos |
| tdd | Testes antes da implementação |
| code-review | Review no fluxo Pocock |
| to-spec | Transformar decisões já discutidas em spec no tracker |
| to-tickets | Transformar spec em tickets verticais |
| implement | Executar tickets do tracker |
| handoff | Registrar estado ao mudar de sessão |
| wayfinder | Dividir decisões grandes em tickets |
| triage | Transformar relato vago em problema trabalhável |
| setup-matt-pocock-skills | Configurar tracker e arquivos do fluxo |
| improve-codebase-architecture | Aprofundar uma área arquitetural |

## Catálogo do Superpowers

| Skill | Finalidade |
|---|---|
| systematic-debugging | Reproduzir, localizar, corrigir e proteger contra regressão |
| receiving-code-review | Avaliar comentários de revisão com rigor |
| verification-before-completion | Exigir evidência antes de declarar conclusão |
| dispatching-parallel-agents | Delegar tarefas independentes |
| using-git-worktrees | Isolar branches e agentes |
| finishing-a-development-branch | Decidir merge, PR ou encerramento |
| writing-skills | Criar ou alterar skills do hub |

## Skills de tecnologia

| Skill | Uso |
|---|---|
| nestjs-clean-architecture | APIs NestJS |
| angular-coreui | Angular e CoreUI |
| coreui-styling | Layout, temas e componentes CoreUI |
| claude-android-ninja | Projetos Android |
| codegraph | Dependências e impacto no código |
| explore-codebase | Entender arquitetura antes de editar |
| debug-issue | Investigar bugs com o grafo |
| refactor-safely | Refatorações com análise de impacto |
| review-changes | Revisão de alterações |
| browser-harness | Verificação e interação com navegador |
| unlazy | Carregamento lazy e bundle |

A família Delphi está temporariamente sem skills instaladas. Isso é intencional.
Depois que a equipe escolher uma skill, adicione seu nome em
families.delphi.skills ou remova-o da lista de bloqueio e execute o instalador.

## Fluxo para criar uma feature

Use:

    spec-driven-development
    → aprovação da spec
    planning-and-task-breakdown
    → aprovação do plano
    incremental-implementation + tdd
    → testes, verificação e commit por fatia
    code-review-and-quality

Exemplo para uma feature NestJS:

    spec-driven-development
    planning-and-task-breakdown
    api-and-interface-design
    incremental-implementation + tdd
    security-and-hardening, se houver entrada externa
    code-review-and-quality

Peça assim:

    Leia SPEC.md e crie tasks/plan.md e tasks/todo.md.
    Não escreva código ainda.

Depois:

    Implemente apenas a próxima tarefa usando incremental-implementation e tdd.
    Rode o teste focado antes de continuar.

## Fluxo Pocock com tracker

Use:

    grill-with-docs
    → to-spec
    → to-tickets
    → implement + tdd
    → code-review

Use esse fluxo quando outras pessoas precisam acompanhar issues, bloqueios,
responsáveis e progresso. Não crie tasks/todo.md como uma segunda fonte de
verdade se o tracker for oficial.

Exemplo:

    Feche as decisões da issue 428 com grill-with-docs.
    Depois da minha aprovação, use to-spec e publique uma única spec.
    Em seguida use to-tickets para criar as fatias.

## Como escolher entre os fluxos

Use Addy quando o trabalho é local e a fonte de verdade será SPEC.md e tasks/.

Use Pocock quando o trabalho nasce de decisões e deve ser publicado em issues.

Não rode spec-driven-development e to-spec para criar duas specs. Não rode
planning-and-task-breakdown e to-tickets para criar duas listas. Não rode
incremental-implementation e implement na mesma tarefa.

## Fluxos para bugs, refatoração e navegador

Bug:

    systematic-debugging
    → tdd
    → incremental-implementation
    → verification-before-completion
    → code-review-and-quality

Refatoração:

    explore-codebase ou codegraph
    → refactor-safely
    → tdd
    → review-changes

Tela web:

    explore-codebase
    → coreui-styling ou angular-coreui
    → incremental-implementation + tdd
    → browser-harness
    → verification-before-completion

Lazy loading:

    unlazy
    → explore-codebase
    → incremental-implementation + tdd
    → browser-harness

## Regras simples para iniciantes

- Escolha uma skill de entrada e apenas as complementares necessárias.
- Diga sempre se quer análise, plano ou implementação.
- Faça uma tarefa por vez e peça o diff antes de ampliar o escopo.
- Teste o comportamento, não apenas a compilação.
- Não remova testes para obter um resultado verde.
- Não mantenha arquivo local e tracker como listas divergentes.
- Não instale o plugin nativo Addy em paralelo às junctions do hub sem definir precedência.
- Use verification-before-completion antes de dizer que terminou.
- Se o agente encontrar algo inesperado, pare e peça investigação antes de autorizar mudanças.

## Checklist de entrega

- [ ] A fonte de verdade foi definida.
- [ ] O escopo foi aprovado.
- [ ] A skill adequada foi usada.
- [ ] Existe teste ou justificativa para a mudança.
- [ ] Testes focados e build aplicável passaram.
- [ ] O comportamento real foi verificado quando necessário.
- [ ] O diff não contém alterações não relacionadas.
- [ ] Foi feita revisão.
- [ ] Nenhum segredo ou arquivo local foi incluído.


## Opções do instalador

Execute os comandos a partir de D:\AGENTS\scripts ou use o caminho completo.

### Instalação normal

    .\Install-AgentHub.ps1 -WriteAgents

Instala as skills previstas no catálogo, cria as junctions para as IDEs detectadas,
gera as configurações MCP e atualiza os arquivos de orientação permitidos.

| Opção | O que faz |
|---|---|
| -HubPath CAMINHO | Usa outro diretório como hub |
| -Roots CAMINHO... | Limita a instalação a determinadas raízes de projetos |
| -Ides Cursor,Claude,Codex | Define explicitamente as IDEs; evita depender da detecção automática |
| -WriteAgents | Cria ou atualiza AGENTS.md conforme os templates |
| -DryRun | Mostra o que seria feito, sem alterar arquivos |
| -RemoveUnusedIdeFolders | Avalia pastas IDE legadas; preserva conteúdo manual e emite avisos quando a remoção não é segura |
| -IncludeQoder | Inclui Qoder mesmo quando não está habilitado no catálogo |
| -ForceAgents | Permite atualizar AGENTS.md além dos blocos gerenciados quando necessário |
| -MigrateLegacyPaths | Analisa caminhos antigos e migra apenas artefatos comprovadamente gerenciados |
| -SkipCodegraphInit | Não executa codegraph init nos projetos |
| -SkipMattPocockSetup | Não cria ou atualiza os arquivos auxiliares do fluxo Pocock |
| -SkipAiMemory | Não executa a configuração opcional do ai-memory |
| -WriteAiMemoryToml | Cria .ai-memory.toml quando a integração ai-memory está habilitada |
| -GlobalSkills | Também cria links das skills no diretório global do Codex |
| -AdoptLegacyConfigs | Permite adotar configurações legadas quando o instalador solicitar isso |

Exemplo seguro antes de uma instalação real:

    .\Install-AgentHub.ps1 -Ides Cursor,Codex -DryRun

### Verificar vendors

    .\Install-AgentHub.ps1 -CheckVendorUpdates

Esse modo consulta os repositórios externos, faz fetch apenas dos metadados Git e
exibe somente:

- arquivos modificados localmente, que serão preservados;
- commits novos disponíveis;
- resumo das diferenças entre o vendor instalado e o remoto.

Ele não instala skills, não cria junctions, não percorre projetos, não altera MCP,
AGENTS.md ou arquivos do projeto. O fetch pode atualizar apenas referências internas
do Git do vendor; o conteúdo de trabalho não é alterado.

Use este comando antes de decidir uma atualização:

    .\Install-AgentHub.ps1 -CheckVendorUpdates

### Atualizar vendors

    .\Install-AgentHub.ps1 -UpdateVendors

Esse modo atualiza todos os vendors disponíveis por fast-forward. Ele não instala
skills nem altera os projetos. Um vendor com alterações locais é ignorado e recebe
um aviso, evitando sobrescrever trabalho humano. O commit apontado pelo repositório
principal também não é atualizado automaticamente.

Depois de revisar a saída:

    git status
    git diff --submodule=log
    git diff -- vendor

Se a atualização for aprovada, faça o commit do novo ponteiro do submodule no hub.
O fluxo recomendado é:

    .\Install-AgentHub.ps1 -CheckVendorUpdates
    .\Install-AgentHub.ps1 -UpdateVendors
    .\Install-AgentHub.ps1 -Ides Cursor,Claude,Codex -DryRun
    .\Install-AgentHub.ps1 -Ides Cursor,Claude,Codex -WriteAgents

As opções -CheckVendorUpdates e -UpdateVendors são exclusivas e não devem ser
combinadas. Elas terminam antes de carregar .env ou iniciar a instalação normal.

## Opções de desinstalação

O desinstalador remove somente artefatos comprovadamente criados pelo Agent Hub.
Pastas reais, junctions externas, conteúdo manual, AGENTS.md e a integração global
do ai-memory são preservados.

### Limpeza padrão

    .\Uninstall-AgentHub.ps1

Remove links de skills e a junction references dos projetos nas raízes configuradas.
Não remove MCPs, ponteiros ou AGENTS.md.

### Desinstalação completa

    .\Uninstall-AgentHub.ps1 -Full

Além dos links, remove configurações MCP e ponteiros que o hub reconhece como
gerenciados, incluindo configurações de IDE por projeto. AGENTS.md continua
preservado.

### Opções do desinstalador

| Opção | O que faz |
|---|---|
| -HubPath CAMINHO | Usa outro diretório como hub |
| -Roots CAMINHO... | Limita a limpeza a determinadas raízes |
| -Full | Remove MCPs, ponteiros e .ai-memory.toml gerenciados, além dos links |
| -GlobalSkills | Remove links globais do Codex que apontam para este hub |
| -RemoveLegacyCodexMcp | Remove apenas as entradas legadas globais de codegraph/context7 |
| -GlobalOnly | Não toca nos projetos; aplica somente a limpeza global solicitada |
| -DryRun | Mostra o que seria removido, sem alterar arquivos |

Exemplos:

    .\Uninstall-AgentHub.ps1 -Full -DryRun
    .\Uninstall-AgentHub.ps1 -Full -Roots D:\SISTEMAS\ERPCLASS
    .\Uninstall-AgentHub.ps1 -GlobalOnly -GlobalSkills
    .\Uninstall-AgentHub.ps1 -GlobalOnly -RemoveLegacyCodexMcp -DryRun

Faça sempre um DryRun antes de uma remoção completa. O ai-memory é global e pode
ser usado por projetos fora do hub; por isso o desinstalador não remove seus
hooks ou configurações globais.
