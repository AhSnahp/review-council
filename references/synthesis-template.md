# Synthesis Template

You are the orchestrating agent. Three independent reviewers — Claude, Gemini, and Codex — have each evaluated the same artifact. Their reviews are below.

## Claude Review
{{CLAUDE_REVIEW}}

## Gemini Review
{{GEMINI_REVIEW}}

## Codex Review
{{CODEX_REVIEW}}

---

## Instructions

Produce a unified synthesis following this EXACT structure:

### 1. Consensus Issues
Problems flagged by 2 or more reviewers. These are almost certainly real issues.
- For each: state the issue, which reviewers flagged it, severity (CRITICAL/IMPORTANT/SUGGESTION), and recommended action.
- Prioritize by severity.

### 2. Unique Findings
Issues flagged by only one reviewer. Evaluate each:
- Is the finding valid? Could the other reviewers have missed it?
- If uncertain, flag for human review with a brief explanation of why it might or might not be real.

### 3. Conflicts
Cases where reviewers explicitly disagree on approach or assessment.
- Present both sides fairly.
- Do NOT resolve — flag for human decision.
- Note which reviewers are on each side.

### 4. Combined Verdict
Based on all three reviews, determine overall status. The most conservative verdict wins:
- If ANY reviewer says REJECT → REJECT
- If ANY reviewer says REQUEST_CHANGES → REQUEST_CHANGES
- If ANY reviewer says APPROVE_WITH_CHANGES → APPROVE_WITH_CHANGES
- Only APPROVE if all three approve

State the combined verdict and each reviewer's individual verdict.

### 5. Action Items
Prioritized numbered list of concrete changes to make:
1. [CRITICAL] ... (from consensus or valid unique findings)
2. [CRITICAL] ...
3. [IMPORTANT] ...
4. [SUGGESTION] ...

Stop when you hit diminishing returns (cosmetic changes, style preferences).

### 6. Reviewer Agreement Matrix

| Dimension | Claude | Gemini | Codex | Agreement |
|-----------|--------|--------|-------|-----------|
| Completeness | pass/fail | pass/fail | pass/fail | full/partial/none |
| Consistency | pass/fail | pass/fail | pass/fail | full/partial/none |
| Correctness | pass/fail | pass/fail | pass/fail | full/partial/none |
| Architecture | pass/fail | pass/fail | pass/fail | full/partial/none |
| Risk | pass/fail | pass/fail | pass/fail | full/partial/none |
