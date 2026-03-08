# Review Council

A Claude Code skill that fans out any artifact to 3 independent LLM CLI reviewers (Claude Code, Gemini CLI, Codex CLI) for parallel review, then synthesizes their feedback into a prioritized action list.

Different models trained by different teams catch different classes of issues. This is about maximizing coverage through diversity, not finding the "best" model.

## How It Works

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
        | (Opus)    |  | (Pro)    |  | (GPT-5.3)  |
        +-----+----+  +-----+----+  +------+-----+
              |              |              |
              +--------------+--------------+
                             |
                    +--------v---------+
                    |  Synthesizer     |
                    |  (Claude Code)   |
                    +------------------+
```

1. **Prepare** -- Read artifact, select audit type, build review prompt
2. **Fan Out** -- Launch all 3 CLIs in parallel via `run-council.sh`
3. **Collect** -- Read the 3 review files + status.json
4. **Synthesize** -- Claude analyzes all reviews, finds consensus/conflicts/unique findings
5. **Verdict** -- Present combined verdict, agreement matrix, and prioritized action items

## Prerequisites

All 3 CLIs must be installed:

```bash
command -v claude && command -v gemini && command -v codex
```

## Usage

Invoke from Claude Code using natural language:

```
# General review
"Run a review council on this spec"
"Get multi-model review of docs/architecture.md"

# Specific audit types
"Run a security audit on the auth module"
"Performance audit this page component"
"Database audit the Prisma schema"
"Review this plan before we execute it"
"Accessibility audit the dashboard"
"Prompt engineering audit on our Claude API calls"
```

Or use the slash command:

```
/review-council
```

### Initialize Project Config

Run init to auto-detect your environment and scaffold a `review-council.config.md`:

```
/review-council init
```

This will:
- Check which CLIs are installed (claude, gemini, codex)
- Scan for guardrails and Definition of Done files in your project
- Generate a customized config with detected values
- Show you the config for approval before writing it

## Audit Types

| Type | Trigger Phrases | What It Evaluates |
|------|----------------|-------------------|
| **General Review** | "review council", "multi-model review" | Completeness, consistency, correctness, architecture, risk |
| **Security Audit** | "security audit", "security review" | Auth, injection, secrets, data protection, API security, dependencies |
| **Performance Audit** | "performance audit", "perf review" | Rendering/bundle, data fetching, DB queries, caching, scaling |
| **Database Audit** | "database audit", "schema audit" | Schema design, indexes, migration safety, data integrity, N+1 queries |
| **Prompt Engineering Audit** | "prompt audit", "AI audit" | Prompt quality, injection defense, output parsing, token cost, model selection |
| **Accessibility Audit** | "accessibility audit", "a11y audit" | WCAG 2.1 AA, keyboard nav, screen readers, contrast, forms |
| **Plan Review** | "plan review", "review this plan" | Sequencing, dependencies, scope, rollback, verification checkpoints |

## Script Usage

The orchestration script can also be run directly:

```bash
bash ~/.agents/skills/review-council/scripts/run-council.sh \
  --artifact "/path/to/file-to-review" \
  --prompt-file "/path/to/constructed-prompt.md" \
  --output-dir "./reviews/my-review-2026-03-05" \
  --name "my-artifact" \
  --claude-model "opus" \
  --gemini-model "pro" \
  --codex-model "gpt-5.3-codex"
```

**Arguments:**

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--artifact` | Yes | -- | Path to the file being reviewed |
| `--prompt-file` | Yes | -- | Path to the constructed review prompt |
| `--output-dir` | Yes | -- | Where to write review output files |
| `--name` | Yes | -- | Artifact name (used in output filenames) |
| `--claude-model` | No | `opus` | Claude model to use |
| `--gemini-model` | No | `pro` | Gemini model alias |
| `--codex-model` | No | CLI default | Codex model (omit to use CLI default) |

## Output

Each council run produces files in the output directory:

```
reviews/<name>-<date>/
  claude-review.md      # Raw Claude review
  gemini-review.md      # Raw Gemini review
  codex-review.md       # Raw Codex review
  claude-err.log        # Claude stderr (if any)
  gemini-err.log        # Gemini stderr
  codex-err.log         # Codex stderr
  status.json           # Exit codes and file paths

reviews/<name>-<date>-synthesis.md    # Unified synthesis with verdicts
```

The synthesis includes:

- **Consensus Issues** -- Flagged by 2+ reviewers (almost certainly real)
- **Unique Findings** -- 1 reviewer only (evaluated for validity)
- **Conflicts** -- Disagreements (both sides presented for human decision)
- **Combined Verdict** -- Most conservative wins (APPROVE / APPROVE_WITH_CHANGES / REQUEST_CHANGES / REJECT)
- **Action Items** -- Prioritized: [CRITICAL] > [IMPORTANT] > [SUGGESTION]
- **Reviewer Agreement Matrix** -- Dimensions x reviewers

## Per-Project Configuration

Drop a `review-council.config.md` in your project root to customize behavior. See `references/config-template.md` for the full format.

Key settings: enabled reviewers, model overrides, review depth per artifact type, guardrails/DoD file paths, convergence threshold, output directory.

## Cost Awareness

Each council run uses tokens across 3 models. Match effort to stakes:

| Artifact | Recommendation |
|----------|---------------|
| Specs, architecture, critical features | Full council |
| Routine code, bug fixes, docs | Single reviewer (Claude only) |
| One-line fixes, config, typos | Skip council |

## File Structure

```
review-council/
  SKILL.md                              # Skill definition (triggers, workflow)
  README.md                             # This file
  scripts/
    run-council.sh                      # Parallel fan-out orchestration
  references/
    synthesis-template.md               # Template for synthesis step
    config-template.md                  # Per-project config reference
    prompts/
      general-review.md                 # General review (default)
      security-audit.md                 # Security audit
      performance-audit.md              # Performance audit
      database-audit.md                 # Database schema audit
      prompt-engineering-audit.md       # LLM integration audit
      accessibility-audit.md            # WCAG accessibility audit
      plan-review.md                    # Implementation plan review
```

## Installation

Already installed via Windows junction:

```
~/.claude/skills/review-council  →  ~/.agents/skills/review-council/
```

To install on another machine:

```bash
git clone https://github.com/AhSnahp/review-council.git ~/.agents/skills/review-council

# Linux/macOS:
ln -s ~/.agents/skills/review-council ~/.claude/skills/review-council

# Windows (Git Bash — ln -s creates copies, not symlinks!):
cmd //c "mklink /J %USERPROFILE%\.claude\skills\review-council %USERPROFILE%\.agents\skills\review-council"
```
