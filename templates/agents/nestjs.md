# {{PROJECT}}

NestJS API — established layered architecture ({{FAMILY}} family).

## Stack
- TypeScript + NestJS + TypeORM + PostgreSQL + Redis
- Layers: Controller → Application → Database → Repository

## Commands
```bash
npm install
npm run start:dev
npm run lint
npm run build
npm test
```

## Agent instructions (keep this file small)
> Do **not** paste stack guides here — they live in `D:\AGENTS` skills (on demand). Keep this file organized and short.
- Chat in **Portuguese**; technical identifiers/comments/JSDoc in **English**; business nouns follow the project's established vocabulary.
- Before exploring code with Grep/Glob/Read, use skill **codegraph** (`codegraph_explore`, MCP) when available.
- For architecture, naming, cache, and feature checklist, load skill **nestjs-clean-architecture**.
- Preserve existing features and accepted ADR exceptions. Apply the skill within the requested scope; historical findings do not authorize structural migrations or renames.
- Property decorators always on their own line above the field.

## Eficiência de execução
- Entregue o resultado primeiro; não repita o pedido nem narre passos rotineiros.
- Use detalhes, alternativas ou tabelas apenas quando o pedido, o risco ou uma decisão exigir.
- Pesquise símbolos antes de abrir arquivos e limite a saída na origem; preserve por completo resultados de Read/Edit/Write.
- Nunca economize em segurança, validação, testes, acessibilidade, diagnóstico ou requisitos explícitos.

## Seleção do projeto e debug local
- A pasta aberta define o repositório-alvo. A família é a pasta de produto mais próxima sob `D:\SISTEMAS` (ERPCLASS, NFECLASS, MOBICLASS, SHOPCLASS, CRMCLASS ou CLOUDCLASS); confirme o caminho antes de escolher outro repositório.
- Quando o pedido disser “verifique a API”, procure o repositório `*-api` dentro dessa mesma pasta de família e confirme o nome/caminho. Se o repositório atual já for a API, use-o. Não atravesse para outra família sem pedido explícito.
- Antes de iniciar API para debug, leia a porta configurada no projeto e verifique se já há listener nela. Se estiver ativa, identifique o serviço e reutilize a API em execução quando servir ao pedido; não inicie uma segunda instância na mesma porta.
- Se iniciar um processo de debug, registre o PID raiz que você iniciou. Ao terminar, encerre a árvore desse PID sem matar o terminal pai e confirme que a porta foi liberada. Nunca encerre um listener preexistente ou de outro projeto.

## Skills (from `D:\AGENTS`)
- `nestjs-clean-architecture`
- `codegraph`
- `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes`
- `using-agent-skills` / `git-workflow-and-versioning` / `code-review-and-quality` / `security-and-hardening` / `observability-and-instrumentation`

## Local
<!-- Keep project-only notes below. Install-AgentHub preserves this section. -->
