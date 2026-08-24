---
name: refactor-safely
description: Plan and execute safe refactoring using dependency analysis
---

## Refactor Safely

Use the codegraph MCP tools (see skill `codegraph`) to plan and execute refactoring with confidence.

### Steps

1. Ask `codegraph_explore` about the symbol/area you plan to change to see its current callers, callees, and blast radius.
2. For a rename or signature change, treat every caller returned as an edit site — verify each before editing.
3. After changes, ask `codegraph_explore` again about the same symbol (the index auto-syncs) to confirm the impact matches what you expected.

### Safety Checks

- Always check the blast-radius summary before a major refactor — it's the fastest way to see what breaks.
- If `codegraph_explore` doesn't surface something you expect to be affected (e.g. dynamic dispatch, reflection, string-based lookups), verify manually with Grep.
