---
name: eval-harness
description: Use when comparing AgentHub skill or prompt changes, defining capability evaluations, or measuring agent regressions, reliability, cost and duration.
metadata:
  origin: ECC (AgentHub adaptation)
---

# Evaluate agent behavior

Define an evaluation before changing the skill/prompt. Use a fixed task fixture,
baseline revision, model/runtime configuration and a decisive expected result.
Include counterexamples and regressions, not only successful demonstrations.

1. Write a definition in `docs/evals/<task>.md`: input, capability, independent
   success criteria, regression cases, actual checker command and allowed effects.
2. Run the baseline in the host's authorized environment. Save outputs separately
   from the definition, under `.audit-output/evals` in the hub. Record exit status,
   relevant artifacts, duration, model/version and available token measurements.
3. Apply the candidate and repeat the same cases. Use actual repository tests,
   schema checks or application scenarios. Prefer deterministic behavioral checks
   over matching implementation text. Use an explicit rubric for model/human
   judgments and identify the reviewer separately from the implementation agent.
4. Report per-case PASS, FAIL or NOT RUN, baseline/candidate comparison, and
   untested constraints. Missing tooling or unavailable scenarios are NOT RUN.
   Measured improvement requires comparable runs; do not invent usage/cost data.

`pass@1` is first-attempt success. For multiple attempts, state the number of
tasks/trials, sampling method and retry policy. Distinguish success in any of k
attempts from all k succeeding. Three successful examples alone do not establish
a production reliability percentage. Do not promote changes on flaky graders.

## ECC utilities (optional)

This skill does not register `/eval define`, `/eval check` or `/eval report`.
If the host has no such commands, follow the workflow above with real tools.
No ECC hooks, continuous-learning service or model-provider settings are required.

The pinned source checkout retains `vendor/ecc/scripts/eval-harness.js` and
`scripts/lib/eval-harness/`. These are outside the installed skill folder. Locate
the hub through this skill's resolved source path. Initialize the pinned submodule
with the hub's normal clone/setup if it is absent; do not install the full plugin.

From the hub, an existing trusted capsule can be inspected read-only with:

```powershell
node vendor/ecc/scripts/eval-harness.js capsule verify <capsule-directory>
```

The pinned runtime refuses candidate execution on every OS with
`gate.isolation_required`. Preserve that refusal. Do not bypass it with trust
flags, custom executors or changes to the vendor. Run ordinary authorized project
checks using the host's existing tools, never as a substitute containment backend.
A capsule/receipt verifies record integrity, not OS containment or candidate safety.

Source: [ECC eval-harness](https://github.com/affaan-m/ECC/tree/8321021c54d670126ce3b2969d5deb880b4b0c2a/skills/eval-harness), MIT; see [LICENSE](LICENSE).
