# {{PROJECT}}

Delphi VCL ERP — Domain / Providers / legado convivendo.

## Stack
- Delphi 12 / VCL · Firebird · FireDAC/UniDAC · ACBr · Horse

## Agent instructions (keep this file small)
> Do **not** paste the full Delphi guide here — use skill **delphi-erpclass** from `D:\AGENTS`. Keep this file organized and short.
- Responder em **Português do Brasil**.
- Antes de alterar código: plano resumido e confirmação (exceto trivial / "pode fazer").
- Código novo: Domain + Providers/Services; não expandir `Global.pas` / `Funcoes.pas`.
- `.pas`/`.dfm`: preservar encoding (ANSI vs UTF-8); não usar edit cego em linhas com acento.
- Guia completo: skill **delphi-erpclass**.
- Docs do projeto: `source/docs/` (forms, relatórios, observer) e `docs/reforma/`.

## Eficiência de execução
- A pasta aberta define o repositório-alvo. A família de produto é a pasta pai imediata sob `D:\SISTEMAS` (ERPCLASS, NFECLASS, MOBICLASS, SHOPCLASS, CRMCLASS ou CLOUDCLASS); confirme o caminho antes de escolher outro repositório.
- “Verifique a API” significa procurar o repositório `*-api` irmão dentro dessa mesma pasta de família e confirmar o nome/caminho. Não atravesse para outra família sem pedido explícito.
- Antes de iniciar uma API para debug, leia a porta configurada e verifique se já há listener. Identifique o processo e reutilize a API em execução quando servir ao pedido; não inicie outra instância na mesma porta.
- Se iniciar um processo de debug, registre o PID raiz que você iniciou. Ao terminar, encerre a árvore desse PID sem matar o terminal pai e confirme que a porta foi liberada. Nunca encerre um listener preexistente ou de outro projeto.
- Entregue o resultado primeiro; não repita o pedido nem narre passos rotineiros.
- Use detalhes, alternativas ou tabelas apenas quando o pedido, o risco ou uma decisão exigir.
- Pesquise símbolos antes de abrir arquivos e limite a saída na origem; preserve por completo resultados de Read/Edit/Write.
- Nunca economize em segurança, validação, testes, acessibilidade, diagnóstico ou requisitos explícitos.

## Skills (from `D:\AGENTS`)
- `delphi-erpclass`
- `codegraph` / `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes`
- `using-agent-skills` / `git-workflow-and-versioning` / `security-and-hardening` / `observability-and-instrumentation`

## Local
<!-- Keep project-only notes below. Install-AgentHub preserves this section. -->
