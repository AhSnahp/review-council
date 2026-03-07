# Design: /review-council init subcommand + first-run nudge

**Date:** 2026-03-07
**Status:** Approved

## Problem

Users don't know the config template exists. There's no first-run onboarding, and the config file must be manually copied from `references/config-template.md`. The Glob lookup for `review-council.config.md` during Phase 1 can also error and cascade-cancel parallel tool calls.

## Solution

Two changes to SKILL.md (Approach A: SKILL.md-only, no new scripts):

### 1. Init Mode

When the user invokes `/review-council init`, Claude follows a smart-detection flow instead of the normal review workflow.

**Detection phase:**
1. Check which CLIs are installed (`command -v claude`, `command -v gemini`, `command -v codex`)
2. Scan project for guardrails/architecture files (glob patterns: `**/guardrails.md`, `**/architecture.md`, `**/ARCHITECTURE.md`, `**/adr/**/*.md`, `**/docs/decisions/**`)
3. Scan for DoD files (`**/dod*.md`, `**/definition-of-done*`)
4. Check if `reviews/` directory already exists

**Generation phase:**
5. Build customized `review-council.config.md`:
   - Reviewers enabled/disabled based on CLI availability
   - Guardrails path filled if candidate found (comment-list alternatives if multiple)
   - DoD path filled if found
   - Defaults for everything else
6. Show generated config to user for approval
7. On approval, write to `./review-council.config.md` in project root

**Edge cases:**
- If config already exists: warn and ask if user wants to overwrite
- If zero CLIs found: warn that council can't run

**Argument detection:** If the user's message contains "init" (e.g., `/review-council init`, "review council init", "initialize review council"), enter Init Mode.

### 2. First-Run Nudge

In Phase 1 Step 2, after the config lookup: if no `review-council.config.md` is found, inform the user "No project config found. Using defaults. Run `/review-council init` to customize settings for this project." Then proceed with defaults.

## Files Changed

- `SKILL.md` — New Init Mode section + nudge in Phase 1 Step 2
- `README.md` — New Init section under Usage

## Approach Trade-offs

| Approach | Description | Verdict |
|----------|-------------|---------|
| A. SKILL.md-only (chosen) | Init logic as Claude instructions | Clean, no new files, consistent architecture |
| B. Init shell script + SKILL.md | Script does detection, Claude generates config | Overkill, more maintenance |
| C. Full init script | Script does everything | Loses conversational tailoring |
