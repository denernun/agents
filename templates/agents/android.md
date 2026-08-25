# {{PROJECT}}

Android app — MOBICLASS (Java + XML Views today).

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

## Skills (from `D:\AGENTS`)
- `claude-android-ninja`
- `codegraph`
- `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes`
- `using-agent-skills` / `git-workflow-and-versioning` / `code-review-and-quality` / `security-and-hardening` / `observability-and-instrumentation`

## Local
<!-- Keep project-only notes below. Install-AgentHub preserves this section. -->
