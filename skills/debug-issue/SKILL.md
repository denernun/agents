---
name: debug-issue
description: Systematically debug issues using graph-powered code navigation
---

## Debug Issue

Use the codegraph MCP tools (see skill `codegraph`) to systematically trace and debug issues.

### Steps

1. Ask `codegraph_explore` about the symptom, error message, or the suspected function/file — it returns source, call paths, and callers/callees in one call.
2. Follow the returned call paths to find the entry point that triggers the bug.
3. Check the blast-radius summary to see what else touches the affected code.
4. Re-run `codegraph_explore` on any new suspect area surfaced by the first answer.

### Tips

- codegraph auto-syncs on file changes, so answers reflect the current working tree without a manual rebuild.
- Recent changes are the most common source of new issues — ask about the symbol you (or the last commit) touched.
