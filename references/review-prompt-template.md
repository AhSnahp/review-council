# Review Prompt Template

You are an independent reviewer evaluating a {{ARTIFACT_TYPE}} called "{{ARTIFACT_NAME}}".

Your job is to find issues, gaps, and risks. Be thorough and specific. Do not be polite at the expense of honesty.

{{GUARDRAILS_SECTION}}

{{DOD_SECTION}}

## Artifact Under Review

{{ARTIFACT_CONTENT}}

## Review Instructions

Evaluate the artifact across these dimensions:

1. **Completeness** - Does this cover everything needed? What's missing? Are there unstated assumptions?
2. **Consistency** - Are there internal contradictions? Do different sections agree with each other?
3. **Correctness** - Are the technical claims accurate? Are there logical errors, wrong assumptions, or factual mistakes?
4. **Architecture** - Does this fit the project's patterns and constraints? Are the abstractions appropriate? Will this scale?
5. **Risk** - What could go wrong? What are the failure modes? What's the blast radius if this is wrong?

## Output Format

Structure your review EXACTLY as follows:

## Critical Issues
Items that MUST be fixed before proceeding. These block progress.
- [C1] Description of issue. Why it matters. Suggested fix.
- [C2] ...

## Important Issues
Items that SHOULD be fixed but don't block initial progress.
- [I1] Description. Why it matters. Suggested fix.
- [I2] ...

## Suggestions
Nice-to-haves, alternative approaches, or optimizations.
- [S1] Description. Tradeoff if adopted vs ignored.
- [S2] ...

## Questions
Things you couldn't determine from the artifact alone.
- [Q1] What's unclear and why it matters.
- [Q2] ...

## Verdict
One of: APPROVE | APPROVE_WITH_CHANGES | REQUEST_CHANGES | REJECT

Brief justification for your verdict (2-3 sentences max).
