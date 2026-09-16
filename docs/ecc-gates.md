# ECC integration acceptance

OWNS: catalog/projects.json, scripts/*Ecc*, scripts/AgentHub.Ecc.ps1, scripts/Install-AgentHub.ps1, scripts/Test-AgentHub.ps1, scripts/tests/*ecc*, scripts/tests/*Ecc*, skills/contract-first/**, skills/api-design/**, skills/e2e-testing/**, skills/skill-stocktake/**, skills/eval-harness/**, skills/security-scan/**, docs/ecc*, .gitmodules, vendor/ecc, README.md

Scope: Integrate only the six approved ECC skills, with portable adapters and scoped installation.

- [x] G1: Six selected skills, provenance and scoped mapping are valid; excluded skills stay excluded.
  CHECK: pwsh -NoProfile -File scripts/tests/Test-Ecc.ps1
  EXPECT: ECC integration checks passed
  EVIDENCE: 2026-09-16, PowerShell 7, D:/AGENTS: Test-Ecc.ps1 exit 0, ECC integration checks passed. Selection, negative scope controls, manual collision, removal, real junctions and vendor refusal verified.
- [x] G2: Portable stocktake handles aliases, missing telemetry and changes; existing Python checks pass.
  CHECK: python -m unittest discover -s scripts/tests -v
  EXPECT: OK
  EVIDENCE: 2026-09-16, D:/AGENTS, Python unittest exit 0: 20 tests passed, including regression rejecting incomplete-current comparisons.
- [x] G3: All six scenario reviews pass and dependency limitations are documented.
  EVIDENCE: Independent skill_scenarios agent applied six scenarios and found no final blocking issues. AgentShield 1.6.0 fixture scan returned exit 1 and the seeded permissions-permissive-Bash(*) finding; that exit denotes findings, not installation failure. Limitations in ecc-integration.md.
- [x] G4: Actual scoped skills-only distribution is inspected; manual content is preserved.
  EVIDENCE: 2026-09-16, Test-EccInstallation.ps1 -GlobalSkills exit 0: 31 projects inspected, 227 links verified, no scope/content errors. Repeated sync dry-run proposes no changes. Manual preservation tested with a positive collision fixture. IDE discovery is not claimed.

All four task gates met; none abandoned. The broader legacy integration suite
still fails its preexisting Delphi assertion, documented in ecc-integration.md.
