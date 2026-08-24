---
name: explore-codebase
description: Navigate and understand codebase structure using the knowledge graph
---

## Explore Codebase

Use the codegraph MCP tools (see skill `codegraph`) to explore and understand the codebase.

### Steps

1. Describe the area/feature/symbol you're looking for to `codegraph_explore` — it returns relevant symbols' verbatim source grouped by file, call paths between them, and a blast-radius summary in one call.
2. Narrow the query (symbol name, file, or subsystem) if the first answer is too broad.
3. Only fall back to Grep/Glob/Read for content codegraph doesn't index (non-code files, generated assets, content outside the indexed languages).

### Tips

- Prefer one well-phrased `codegraph_explore` call over several narrow greps.
- Ask architecture-level questions directly ("how does X flow through the app") — codegraph resolves framework routing (NestJS, Angular, etc.) automatically.
- The index auto-syncs on file changes; no manual rebuild needed mid-session.
