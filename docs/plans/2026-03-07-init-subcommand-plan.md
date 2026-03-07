# Init Subcommand Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `/review-council init` subcommand with smart detection and a first-run nudge when no config exists.

**Architecture:** All changes are SKILL.md instruction edits (Approach A). Claude Code reads the instructions and follows them — no new scripts. The init flow uses existing tools (Bash, Glob, Read, Write) to detect CLIs, scan for project files, and scaffold a config.

**Tech Stack:** Markdown (SKILL.md, README.md)

---

### Task 1: Add Init Mode routing to SKILL.md

**Files:**
- Modify: `SKILL.md:67` (insert new section before "### Phase 1: Prepare")

**Step 1: Add the mode routing section**

Insert the following between `## Workflow` (line 67) and `### Phase 1: Prepare` (line 69):

```markdown
### Mode Detection

If the user's message contains "init" (e.g., `/review-council init`, "review council init", "initialize review council"), enter **Init Mode** below. Otherwise, proceed to Phase 1.

### Init Mode

Run this instead of the normal review workflow.

#### Step 1: Check for existing config

Look for `review-council.config.md` in the project root using Read (not Glob — Read fails gracefully if the file doesn't exist). If it already exists, warn the user and ask if they want to overwrite. If they say no, stop.

#### Step 2: Detect environment

Run the following checks (all can run in parallel):

1. **CLI availability:** Run each separately to avoid cascade failures:
   ```bash
   command -v claude 2>/dev/null && echo "found" || echo "missing"
   ```
   ```bash
   command -v gemini 2>/dev/null && echo "found" || echo "missing"
   ```
   ```bash
   command -v codex 2>/dev/null && echo "found" || echo "missing"
   ```

2. **Guardrails/architecture files:** Glob for candidates:
   - `**/guardrails.md`
   - `**/ARCHITECTURE.md`
   - `**/architecture.md`
   - `**/adr/**/*.md`
   - `**/docs/decisions/**`

3. **DoD files:** Glob for candidates:
   - `**/dod*.md`
   - `**/definition-of-done*`
   - `**/DoD*`

4. **Existing output directory:** Check if `reviews/` exists.

#### Step 3: Generate config

Using the detection results, build a customized `review-council.config.md`:

- Set each reviewer to `enabled` or `disabled` based on CLI availability
- If guardrails candidates were found:
  - If exactly one: set it as the guardrails path
  - If multiple: set the most likely one (prefer paths containing `guardrails` > `architecture` > `adr`) and add the others as comments
- If DoD candidates were found: same logic as guardrails
- If `reviews/` already exists, keep the default output_dir. Otherwise keep default too.
- Leave model overrides at defaults (opus, pro, CLI default)
- Leave review depth at defaults (thorough for all)

Use the template from `references/config-template.md` as the base structure. Customize it with the detected values.

#### Step 4: Present for approval

Show the user the generated config content. Summarize what was detected:
- Which CLIs were found/missing
- Which guardrails/DoD files were discovered
- Any other notable findings

Ask: "Write this to `./review-council.config.md`?"

#### Step 5: Write config

On approval, write the config to `./review-council.config.md` in the project root. Confirm to the user with the file path.

If zero CLIs were found, add an extra warning: "No reviewer CLIs were found. The council cannot run until at least one is installed."
```

**Step 2: Verify the edit**

Read `SKILL.md:67-130` to confirm the new section is correctly placed between `## Workflow` and `### Phase 1: Prepare`.

**Step 3: Commit**

```bash
git add SKILL.md
git commit -m "Add Init Mode routing and workflow to SKILL.md"
```

---

### Task 2: Add first-run nudge to Phase 1 Step 2

**Files:**
- Modify: `SKILL.md:73` (the "Check for project config" step — line number will have shifted after Task 1)

**Step 1: Edit the config check step**

Find this existing text in SKILL.md:

```
2. **Check for project config.** Look for `review-council.config.md` in the project root. If found, read it and extract:
   - Enabled reviewers and model overrides
   - Review depth setting for this artifact type
   - Guardrails file path
   - DoD template path
   - Output directory (default: `reviews`)
```

Replace with:

```
2. **Check for project config.** Try to Read `review-council.config.md` from the project root (do not use Glob — Read fails gracefully if the file doesn't exist, avoiding cascade cancellation of parallel tool calls). If found, read it and extract:
   - Enabled reviewers and model overrides
   - Review depth setting for this artifact type
   - Guardrails file path
   - DoD template path
   - Output directory (default: `reviews`)

   If no config file is found, inform the user: "No project config found. Using defaults. Run `/review-council init` to customize settings for this project." Then proceed with defaults.
```

**Step 2: Verify the edit**

Read the modified section to confirm the nudge text and the Read-not-Glob instruction are both present.

**Step 3: Commit**

```bash
git add SKILL.md
git commit -m "Add first-run nudge and fix Glob-to-Read in Phase 1 config check"
```

---

### Task 3: Update trigger description in SKILL.md frontmatter

**Files:**
- Modify: `SKILL.md:3` (the `description` field in the YAML frontmatter)

**Step 1: Add init triggers to the description**

Find the end of the description's trigger list and append: `"review council init", "initialize review council",` to the trigger phrase list.

**Step 2: Verify the edit**

Read `SKILL.md:1-4` to confirm the frontmatter is valid YAML and includes the new triggers.

**Step 3: Commit**

```bash
git add SKILL.md
git commit -m "Add init trigger phrases to SKILL.md frontmatter"
```

---

### Task 4: Update README.md with init usage

**Files:**
- Modify: `README.md` (insert after the existing Usage section's slash command block, around line 66)

**Step 1: Add init section to README**

Find this text in README.md:

```
Or use the slash command:

```
/review-council
```
```

After it, insert:

```markdown

### Initialize Project Config

Run init to auto-detect your environment and scaffold a `review-council.config.md`:

```
/review-council init
```

This will:
- Check which CLIs are installed (claude, gemini, codex)
- Scan for guardrails and Definition of Done files
- Generate a customized config with detected values
- Show you the config for approval before writing it
```

**Step 2: Verify the edit**

Read `README.md:60-85` to confirm the new section appears after the slash command block and before the Audit Types section.

**Step 3: Commit**

```bash
git add README.md
git commit -m "Add init subcommand documentation to README"
```

---

### Task 5: Final verification

**Step 1: Read full SKILL.md and verify structure**

Read the entire SKILL.md and confirm:
- Mode Detection section exists between `## Workflow` and `### Phase 1`
- Init Mode has all 5 steps
- Phase 1 Step 2 has the nudge text and Read-not-Glob instruction
- Frontmatter includes init triggers
- No broken markdown formatting

**Step 2: Read full README.md and verify**

Read the entire README.md and confirm the init section is properly placed and formatted.

**Step 3: Run git log to confirm all commits**

```bash
git log --oneline -5
```

Expected: 4 new commits for Tasks 1-4.
