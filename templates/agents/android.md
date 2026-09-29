# {{PROJECT}}

Android app — {{FAMILY}} (Java + XML Views today).

## Stack
- Java 11, AndroidX AppCompat / Material, XML layouts
- Gradle version catalog, Room, Retrofit, WorkManager
- minSdk 26, compile/targetSdk 36 (confirm in the module `build.gradle`)

## Commands
```bash
# Gradle lives under src/ in leitor and comanda
./gradlew :app:assembleDebug
./gradlew :app:lintDebug
```

## Agent instructions (keep this file small)
> Do **not** paste stack guides here — they live in `D:\AGENTS` skills (on demand). Keep this file organized and short.
- Chat in **Portuguese**; code/comments/identifiers in **English**.
- Before exploring with Grep/Glob/Read, use skill **codegraph** (`codegraph_explore`) when available.
- Load skill **claude-android-ninja** for Android work (Gradle, tests, security, permissions, performance, Gradle catalog).
- These apps are **Java + XML**, not Kotlin Compose. Follow the existing stack. Do **not** migrate to Compose, Navigation3, or Hilt unless the user asks.
- Gradle project root may be `src/` (not the git root). Read `settings.gradle` / `build.gradle` there before changing the build.

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
- `claude-android-ninja`
- `codegraph`
- `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes`
- `using-agent-skills` / `git-workflow-and-versioning` / `code-review-and-quality` / `security-and-hardening` / `observability-and-instrumentation`

## Local
<!-- Keep project-only notes below. Install-AgentHub preserves this section. -->
