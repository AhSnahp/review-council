# Review Council Configuration Template

Copy this file to your project root as `review-council.config.md` and customize.

---

```markdown
# Review Council Configuration

## Reviewers
Which CLI reviewers to include. Disable any you don't have installed.
- claude: enabled
- gemini: enabled
- codex: enabled

## Model Overrides
Override the default model for each reviewer. Leave blank for defaults.
- claude-model: opus
- gemini-model: pro
- codex-model: (leave blank for CLI default)

## Review Depth
How thoroughly to review each artifact type. Options: thorough, quick.
- specs: thorough
- design-docs: thorough
- code-changes: quick
- documentation: quick

## Guardrails File
Path to your project's architectural guardrails file (relative to project root).
- path: docs/architecture/guardrails.md

## Definition of Done Template
Path to your DoD template (relative to project root).
- path: docs/dod/feature.md

## Convergence
- max_iterations: 3
- stop_when: only SUGGEST-level items remain

## Output Directory
Where to write review output files (relative to project root).
- output_dir: reviews
```

---

## Field Reference

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| Reviewers | No | All enabled | Which CLIs to use |
| Model Overrides | No | opus / pro / CLI default | Model per reviewer |
| Review Depth | No | thorough for all | thorough = all 5 dimensions, quick = correctness + architecture + risk |
| Guardrails File | No | None | Injected into review prompt as context |
| DoD Template | No | None | Injected into review prompt as context |
| max_iterations | No | 3 | Max council re-runs on REQUEST_CHANGES |
| stop_when | No | SUGGEST-level only | Convergence condition |
| output_dir | No | reviews | Where output files go |
