---
name: review-changes
description: Perform a structured code review using change detection and impact
---

## Review Changes

Perform a thorough, risk-aware code review using the codegraph MCP tools (see skill `codegraph`).

### Steps

1. Get the literal change set from `git diff` / `git log` first.
2. For each changed file/symbol, ask `codegraph_explore` about it to get its source, callers, and blast radius in one call.
3. Flag changes whose blast radius touches code with no visible test coverage.

### Output Format

Provide findings grouped by risk level (high/medium/low) with:
- What changed and why it matters
- Blast radius / what else could break
- Suggested improvements
- Overall merge recommendation
