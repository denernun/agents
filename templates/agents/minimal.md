# {{PROJECT}}

## Agent instructions
> Keep this file short — stack guides live in `D:\AGENTS` skills (on demand).
- Chat in **Portuguese**; code in **English**.
- Prefer skill **codegraph** (`codegraph_explore`) before broad Grep/Glob when the graph MCP is configured.
- Load the stack skill that matches this repo (nestjs / angular / android) from `D:\AGENTS`.

## Eficiência de execução
- Entregue o resultado primeiro; não repita o pedido nem narre passos rotineiros.
- Use detalhes, alternativas ou tabelas apenas quando o pedido, o risco ou uma decisão exigir.
- Pesquise símbolos antes de abrir arquivos e limite a saída na origem; preserve por completo resultados de Read/Edit/Write.
- Nunca economize em segurança, validação, testes, acessibilidade, diagnóstico ou requisitos explícitos.

## Seleção do projeto e debug local
- A pasta aberta define o repositório-alvo. A família é a pasta de produto mais próxima sob `D:\SISTEMAS` (ERPCLASS, NFECLASS, MOBICLASS, SHOPCLASS, CRMCLASS ou CLOUDCLASS); confirme o caminho antes de escolher outro repositório.
- Quando o pedido disser “verifique a API”, procure o repositório `*-api` dentro dessa mesma pasta de família e confirme o nome/caminho. Se o repositório atual já for a API, use-o. Não atravesse para outra família sem pedido explícito.
- Antes de iniciar uma API para debug, leia a porta configurada e verifique se já há listener. Identifique o serviço e reutilize a API em execução quando servir ao pedido; não inicie outra instância na mesma porta.
- Se iniciar um processo de debug, registre o PID raiz que você iniciou. Ao terminar, encerre a árvore desse PID sem matar o terminal pai e confirme que a porta foi liberada. Nunca encerre um listener preexistente ou de outro projeto.

## Skills (from `D:\AGENTS`)
- `codegraph`
- `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes`
- `using-agent-skills` / `git-workflow-and-versioning` / `code-review-and-quality` / `security-and-hardening` / `observability-and-instrumentation`

## Local
<!-- Keep project-only notes below. Install-AgentHub preserves this section. -->
