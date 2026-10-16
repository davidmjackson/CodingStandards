# {{Project name}}

Done means: {{one sentence}}. Anything else is a new project.

**Where the weight is earned:** {{the one place that gets depth: e.g. RLS, the
untrusted-input boundary, the deterministic compute layer}}. Everything else gets
ordinary care.

## Code quality

This repo follows the shared standard. Before changing code, read
`/var/www/CodingStandards/CLAUDE.md`; thresholds are in
`/var/www/CodingStandards/core/THRESHOLDS.md`, scope rules in
`/var/www/CodingStandards/core/SCOPE-DISCIPLINE.md`. Do not copy them here.

The gate is `{{the repo's verify command}}`. Any deviation from a threshold is an
ADR in `docs/adr/`, never an inline disable.
