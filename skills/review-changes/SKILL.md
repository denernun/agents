---
name: review-changes
description: Fast risk-focused review of a local diff via codegraph — flags blast radius and untested impact. This is the default day-to-day review. For a deep multi-axis quality checklist (correctness/readability/architecture/security/performance) before merge, use code-review-and-quality; to review a branch/PR against its originating spec from a fixed point, use code-review.
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
