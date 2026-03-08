---
name: review-council
description: Fan out any artifact to 3 independent LLM CLI reviewers (Claude Code, Gemini CLI, Codex CLI) for parallel review, then synthesize feedback into a prioritized action list. Supports multiple audit types including general review, security audit, performance audit, database schema audit, prompt engineering audit, and accessibility audit. Trigger on "review council", "multi-model review", "council review", "LLM review panel", "get multiple AI opinions", "consensus review", "security audit", "performance audit", "database audit", "schema audit", "accessibility audit", "a11y audit", "prompt audit", "AI audit", "review this plan", "plan review", "check my plan", "review council init", "initialize review council", or any request to review/audit specs/code/designs/plans with multiple models.
---

# Review Council

Fan out any artifact to 3 independent LLM CLI reviewers running different models, then synthesize their feedback into a prioritized action list with consensus analysis.

## Architecture

```
                    +------------------+
                    |  Orchestrator    |
                    |  (Claude Code)   |
                    +--------+---------+
                             |
              +--------------+--------------+
              |              |              |
        +-----v----+  +-----v----+  +------v-----+
        | Claude    |  | Gemini   |  | Codex CLI  |
        | Code CLI  |  | CLI      |  | (OpenAI)   |
        +-----+----+  +-----+----+  +------+-----+
              |              |              |
              +--------------+--------------+
                             |
                    +--------v---------+
                    |  Synthesizer     |
                    |  (Claude Code)   |
                    +------------------+
```

| Reviewer | CLI | Default Model | Strength |
|----------|-----|---------------|----------|
| Claude | `claude` | opus | Architectural reasoning, nuanced tradeoffs, logical gaps |
| Gemini | `gemini` | pro (alias for latest pro model) | Broad knowledge, alternative approaches, integration concerns |
| Codex | `codex` | CLI default (e.g. gpt-5.3-codex) | Code correctness, edge cases, performance implications |

Different models trained by different teams catch different classes of issues. This is about coverage through diversity, not finding the "best" model.

## Audit Types

The council supports multiple specialized audit types. Each uses a different prompt template tuned to specific evaluation dimensions.

| Audit Type | Prompt Template | Trigger Phrases | Best For |
|------------|----------------|-----------------|----------|
| **General Review** | `prompts/general-review.md` | "review council", "multi-model review" | Specs, design docs, architecture decisions |
| **Security Audit** | `prompts/security-audit.md` | "security audit", "security review" | Auth flows, API routes, secrets, OWASP |
| **Performance Audit** | `prompts/performance-audit.md` | "performance audit", "perf review" | Next.js bundles, data fetching, DB queries |
| **Database Audit** | `prompts/database-audit.md` | "database audit", "schema audit", "DB review" | Prisma schemas, migrations, indexes, queries |
| **Prompt Engineering Audit** | `prompts/prompt-engineering-audit.md` | "prompt audit", "AI audit", "LLM review" | Claude API usage, prompt injection, token cost |
| **Accessibility Audit** | `prompts/accessibility-audit.md` | "accessibility audit", "a11y audit" | WCAG 2.1 AA, keyboard nav, screen readers |
| **Plan Review** | `prompts/plan-review.md` | "review this plan", "plan review", "check my plan" | Implementation plans, sequencing, dependencies, scope |

**Routing rule:** Match the user's request to the most specific audit type. If ambiguous or the user just says "review council", default to General Review. If the user asks for multiple audit types (e.g., "security and performance audit"), run them as separate council sessions.

## Prerequisites

Before starting, verify all 3 CLIs are installed:

```bash
command -v claude && command -v gemini && command -v codex
```

If any CLI is missing, stop and inform the user. All 3 are required.

## Workflow

### Mode Detection

If the user's message contains "init" (e.g., `/review-council init`, "review council init", "initialize review council"), enter **Init Mode** below. Otherwise, proceed to Phase 1.

### Init Mode

Run this instead of the normal review workflow.

#### Step 1: Check for existing config

Try to Read `review-council.config.md` from the project root. If it already exists, warn the user and ask if they want to overwrite. If they say no, stop.

#### Step 2: Detect environment

Run the following checks. These can all run in parallel since they are independent:

1. **CLI availability** (run each as a separate Bash call to avoid cascade failures):
   ```bash
   command -v claude 2>/dev/null && echo "found" || echo "missing"
   ```
   ```bash
   command -v gemini 2>/dev/null && echo "found" || echo "missing"
   ```
   ```bash
   command -v codex 2>/dev/null && echo "found" || echo "missing"
   ```

2. **Guardrails/architecture files** — Glob for candidates:
   - `**/guardrails.md`
   - `**/ARCHITECTURE.md`
   - `**/architecture.md`
   - `**/adr/**/*.md`
   - `**/docs/decisions/**`

3. **Definition of Done files** — Glob for candidates:
   - `**/dod*.md`
   - `**/definition-of-done*`
   - `**/DoD*`

4. **Existing output directory** — Check if `reviews/` exists.

#### Step 3: Generate config

Read the config template from `references/config-template.md` (relative to this skill's directory). Using the detection results, build a customized `review-council.config.md`:

- Set each reviewer to `enabled` or `disabled` based on CLI availability
- If guardrails candidates were found:
  - If exactly one: set it as the guardrails path
  - If multiple: set the most likely one (prefer paths containing `guardrails` > `architecture` > `adr`) and add the others as markdown comments
- If DoD candidates were found: same logic as guardrails
- Leave model overrides at defaults (opus, pro, CLI default)
- Leave review depth at defaults (thorough for all)

#### Step 4: Present for approval

Show the user the generated config content. Summarize what was detected:
- Which CLIs were found/missing
- Which guardrails/DoD files were discovered (if any)
- Any other notable findings

Ask: "Write this to `./review-council.config.md`?"

#### Step 5: Write config

On approval, write the config to `./review-council.config.md` in the project root. Confirm to the user with the file path.

If zero CLIs were found, add a warning: "No reviewer CLIs were found. The council cannot run until at least one is installed."

### Phase 0: Interaction Mode

Before doing anything else, ask the user:

> **Review mode:** Would you like to review the prompt before I send it to the council, or should I use my best judgment and run it automatically?
>
> 1. **Review first** — I'll show you the setup and get your OK before launching
> 2. **Auto-run** — I'll prepare and launch immediately, you can walk away

If the user picks **Auto-run** (or says anything like "just go", "send it", "fire and forget", "auto"), skip Phase 1 step 7 (the pre-fanout confirmation) and proceed straight from prompt construction to fan-out without pausing. All other steps remain the same.

If the user picks **Review first** (or doesn't specify), follow the full workflow including the step 7 confirmation.

If the user's original message already contains clear intent (e.g., "review council, just run it" or "auto-review this plan"), infer the mode without asking.

### Phase 1: Prepare

1. **Read the artifact** the user wants reviewed. Note its type (spec, code, design doc, etc.) and name.

2. **Check for project config.** Try to Read `review-council.config.md` from the project root (do not use Glob — Read fails gracefully if the file doesn't exist, avoiding cascade cancellation of parallel tool calls). If found, read it and extract:
   - Enabled reviewers and model overrides
   - Review depth setting for this artifact type
   - Guardrails file path
   - DoD template path
   - Output directory (default: `reviews`)

   If no config file is found, inform the user: "No project config found. Using defaults. Run `/review-council init` to customize settings for this project." Then proceed with defaults.

3. **Load context files** (if configured):
   - Read the guardrails file if the config specifies one
   - Read the DoD template if the config specifies one

4. **Select and load the prompt template** based on the audit type (see Audit Types table above). Load from `references/prompts/<template>.md` (relative to this skill's directory). Default to `references/prompts/general-review.md` if no specific audit type is requested.

5. **Construct the review prompt** by substituting placeholders in the template:
   - `{{ARTIFACT_TYPE}}` → the type (e.g., "specification", "source code", "design document")
   - `{{ARTIFACT_NAME}}` → the artifact's name or filename
   - `{{ARTIFACT_CONTENT}}` → the full artifact content (see large artifact handling below)
   - `{{GUARDRAILS_SECTION}}` → either the guardrails content wrapped in a header, or empty string if none
   - `{{DOD_SECTION}}` → either the DoD content wrapped in a header, or empty string if none

6. **Write the constructed prompt to a temp file** (e.g., `/tmp/review-council-prompt-XXXXX.md`). This avoids shell argument length limits on Windows.

7. **Review the constructed prompt before fanning out.** Present a summary to the user showing:
   - Audit type selected
   - Artifact name and approximate size
   - Models that will be used (claude=opus, gemini=pro, codex=CLI default, or overrides from project config)
   - Whether guardrails/DoD context was injected
   - A brief excerpt of the prompt (first ~10 lines of the artifact content section)

   Ask the user to confirm before proceeding. This catches misrouted audit types, wrong artifacts, or missing context before burning tokens across 3 models. If the user says to proceed, continue to Phase 2. If they want changes, loop back to the relevant preparation step.

### Phase 2: Fan Out

**ABSOLUTELY CRITICAL — READ THIS ENTIRE SECTION BEFORE ACTING:**

You MUST use `run-council.sh` to launch reviewers. The script contains essential, non-obvious workarounds that you cannot replicate by constructing CLI commands yourself:
- Environment variable stripping for nested session detection
- Stdin piping to bypass Windows ARG_MAX limits
- Tool disabling flags to prevent agentic file-reading behavior
- Model default logic with conditional flag omission

**You do NOT know the correct CLI flags.** The flags change across versions and operating systems. The script is the single source of truth. Do not read the script and extract commands from it. Do not construct your own `claude`, `gemini`, or `codex` commands under any circumstances.

Run this command (only substitute the 4 angle-bracket values):

```bash
bash ~/.agents/skills/review-council/scripts/run-council.sh \
  --artifact "<artifact-path>" \
  --prompt-file "<temp-prompt-path>" \
  --output-dir "<project-root>/reviews/<name>-<date>" \
  --name "<artifact-name>"
```

The script handles model selection internally. Do NOT pass `--claude-model`, `--gemini-model`, or `--codex-model` unless the user's project config explicitly overrides them.

**Timeout:** 600000ms (10 minutes). The script launches all 3 reviewers in parallel.

### Phase 3: Collect

After the script completes:

1. **Read `status.json`** from the output directory. Check exit codes for each reviewer.
2. **Read the 3 review files**: `claude-review.md`, `gemini-review.md`, `codex-review.md`
3. If any reviewer failed (non-zero exit code), **read its error log** and report the failure to the user.

**DO NOT retry failed reviewers.** Do not attempt to re-run individual CLIs. Do not construct alternative commands. Do not "fix" the failure by launching CLIs yourself. If a reviewer failed, proceed with the reviews you have — partial results (2 of 3, or even 1 of 3) are still valuable. Report which reviewers succeeded and which failed, then move to Phase 4 with available reviews.

### Phase 4: Synthesize

1. **Read the synthesis template** from `references/synthesis-template.md` (relative to this skill's directory).
2. **Construct the synthesis prompt** by substituting the 3 review contents into the template placeholders:
   - `{{CLAUDE_REVIEW}}` → content of claude-review.md
   - `{{GEMINI_REVIEW}}` → content of gemini-review.md
   - `{{CODEX_REVIEW}}` → content of codex-review.md
3. **Perform the synthesis yourself** (as Claude Code, the orchestrator). Analyze all three reviews and produce the unified synthesis following the template structure.
4. **Write the synthesis** to `reviews/<name>-<date>-synthesis.md`

### Phase 5: Verdict

Present to the user:

1. The **combined verdict** (most conservative wins)
2. Each reviewer's individual verdict
3. The **reviewer agreement matrix**
4. The **prioritized action items** list
5. Any **conflicts** requiring human decision
6. File paths to the full synthesis and individual reviews

## Large Artifact Handling

If the artifact exceeds **80,000 characters**:

1. Create a structured summary that preserves:
   - All section headings and hierarchy
   - Function/method signatures and type definitions
   - Key logic and control flow
   - Comments and documentation
   - Import/export statements
2. Drop: verbose implementations of straightforward functions, repetitive boilerplate, large data literals
3. Mark omissions with `[... N lines of implementation omitted ...]`
4. Use this summary as `{{ARTIFACT_CONTENT}}` instead of the raw artifact
5. Inform the user that the artifact was summarized for review

## Per-Project Configuration

Projects can customize behavior by placing a `review-council.config.md` file in the project root. See `references/config-template.md` for the full format.

Key settings:
- **Enabled reviewers** — disable any CLI you don't have
- **Model overrides** — use specific models per reviewer
- **Review depth** — thorough (all 5 dimensions) or quick (correctness + architecture + risk)
- **Guardrails/DoD paths** — inject project context into review prompts
- **Convergence threshold** — max iterations and stop condition

## Convergence Rule

If the user runs the council iteratively (make changes, re-review):
- If **2 consecutive runs** produce only SUGGEST-level items (no CRITICAL or IMPORTANT), **stop iterating**
- You're past the point of diminishing returns. Inform the user and recommend proceeding.

## Cost Awareness

Each council run burns tokens across 3 models. Match effort to stakes:

| Artifact Type | Recommended Action |
|---------------|-------------------|
| Specs, architecture decisions, critical path features | Full council (all 3 reviewers) |
| Routine code changes, bug fixes, documentation | Single reviewer (Claude only) |
| One-line fixes, config changes, typo corrections | Skip council entirely |

If the user asks for a council review on something trivial, suggest a lighter approach. Don't refuse — just advise.

## Output Files

Each council run produces files in the output directory:

- `reviews/<name>-<date>/` — Raw output from each reviewer (`claude-review.md`, `gemini-review.md`, `codex-review.md`), error logs, and `status.json`
- `reviews/<name>-<date>-synthesis.md` — The unified synthesis with consensus, conflicts, verdicts, and action items

These accumulate as a decision log over time.

## Iteration Flow

Based on the combined verdict:

| Verdict | Action |
|---------|--------|
| APPROVE | Proceed. No changes needed. |
| APPROVE_WITH_CHANGES | Make the listed changes. No re-review needed. |
| REQUEST_CHANGES | Make changes, then run the council again. |
| REJECT | Significant rework needed. Consider revisiting the source doc. |

## Handling Ping-Pong

When Reviewer A says "do X" and Reviewer B says "undo X" across iterations:
1. The synthesis flags this as a CONFLICT
2. Present both sides to the user for a human decision
3. Suggest adding the decision to the project's guardrails file to prevent recurrence
