---
name: codegraph
description: Use codegraph MCP before Grep/Glob/Read when the project has a knowledge graph. Use when exploring code, reviewing changes, or tracing impact.
---
<!-- codegraph MCP tools -->
## MCP Tools: codegraph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
`codegraph_explore` MCP tool BEFORE using Grep/Glob/Read to explore
the codebase.** It's local, pre-indexed (`.codegraph/`, auto-synced on file
changes), and answers most structural questions in one call — relevant
symbols' verbatim source grouped by file, call paths between them, and a
blast-radius summary — typically with zero file reads.

### When to use it FIRST

- **Exploring code**: describe what you're looking for (a feature, a symbol,
  a file) to `codegraph_explore` instead of Grep.
- **Understanding impact / blast radius of a change**: ask `codegraph_explore`
  about the symbol or area you're changing — it returns callers/callees and
  affected code inline.
- **Code review / tracing a bug**: ask `codegraph_explore` about the changed
  function or the reported symptom to get source + call paths in one shot.
- **Architecture questions**: ask `codegraph_explore` about the subsystem or
  feature by name.

Fall back to Grep/Glob/Read **only** when `codegraph_explore` doesn't cover
what you need (e.g. non-code files, generated assets, or content outside the
indexed languages).

### Notes

- Only `codegraph_explore` is enabled by default — it already inlines what
  the narrower tools (`codegraph_node`, `codegraph_search`, `codegraph_callers`,
  `codegraph_callees`, `codegraph_impact`, `codegraph_files`, `codegraph_status`)
  would return, so prefer one well-phrased `codegraph_explore` call over
  several narrow ones.
- The index auto-syncs on file changes (file watcher in `codegraph serve`);
  no manual rebuild step is needed during a session.
