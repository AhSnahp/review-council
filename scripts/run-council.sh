#!/usr/bin/env bash
#
# run-council.sh — Fan out a review prompt to 3 LLM CLIs in parallel.
# Collects output files and writes status.json when all complete.
#
# Usage:
#   run-council.sh --artifact <path> --prompt-file <path> --output-dir <path> \
#     --name <name> [--claude-model <model>] [--gemini-model <model>] [--codex-model <model>]

set -euo pipefail

# Defaults
ARTIFACT=""
PROMPT_FILE=""
OUTPUT_DIR=""
NAME=""
CLAUDE_MODEL="opus"
GEMINI_MODEL="pro"
CODEX_MODEL=""

# ── Parse arguments ──────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --artifact)
      ARTIFACT="$2"
      shift 2
      ;;
    --prompt-file)
      PROMPT_FILE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --name)
      NAME="$2"
      shift 2
      ;;
    --claude-model)
      CLAUDE_MODEL="$2"
      shift 2
      ;;
    --gemini-model)
      GEMINI_MODEL="$2"
      shift 2
      ;;
    --codex-model)
      CODEX_MODEL="$2"
      shift 2
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

# ── Validate required arguments ──────────────────────────────────
if [ -z "$ARTIFACT" ] || [ -z "$PROMPT_FILE" ] || [ -z "$OUTPUT_DIR" ] || [ -z "$NAME" ]; then
  echo "ERROR: Missing required arguments." >&2
  echo "Usage: run-council.sh --artifact <path> --prompt-file <path> --output-dir <path> --name <name>" >&2
  exit 1
fi

if [ ! -f "$ARTIFACT" ]; then
  echo "ERROR: Artifact file not found: $ARTIFACT" >&2
  exit 1
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: Prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

# ── Verify all 3 CLIs are installed ─────────────────────────────
MISSING=""
for cli in claude gemini codex; do
  if ! command -v "$cli" > /dev/null 2>&1; then
    MISSING="$MISSING $cli"
  fi
done

if [ -n "$MISSING" ]; then
  echo "ERROR: Missing required CLI tools:$MISSING" >&2
  echo "All 3 CLIs (claude, gemini, codex) must be installed." >&2
  exit 1
fi

# ── Prepare output directory ─────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

PROMPT_CONTENT="$(cat "$PROMPT_FILE")"

echo "=== Review Council ==="
echo "Artifact: $ARTIFACT"
echo "Name: $NAME"
echo "Output: $OUTPUT_DIR"
echo "Models: claude=$CLAUDE_MODEL gemini=$GEMINI_MODEL codex=$CODEX_MODEL"
echo ""
echo "Launching 3 parallel reviewers..."

# ── Launch reviewers in parallel ─────────────────────────────────
# Note: CLAUDECODE env var must be unset so claude CLI doesn't refuse
# to launch inside a parent Claude Code session (the subprocess is
# non-interactive print mode, so there's no resource conflict).

env -u CLAUDECODE claude -p "$PROMPT_CONTENT" --output-format text --model "$CLAUDE_MODEL" \
  > "$OUTPUT_DIR/claude-review.md" 2>"$OUTPUT_DIR/claude-err.log" &
PID_CLAUDE=$!

gemini "$PROMPT_CONTENT" -m "$GEMINI_MODEL" -y -o text \
  > "$OUTPUT_DIR/gemini-review.md" 2>"$OUTPUT_DIR/gemini-err.log" &
PID_GEMINI=$!

# Codex: pipe prompt via stdin (-) to avoid shell arg length limits.
# --ephemeral skips session persistence (one-shot review, no resume needed).
# Omit -m flag when CODEX_MODEL is empty to use CLI default.
if [ -n "$CODEX_MODEL" ]; then
  cat "$PROMPT_FILE" | codex exec - -m "$CODEX_MODEL" --full-auto --skip-git-repo-check --ephemeral \
    > "$OUTPUT_DIR/codex-review.md" 2>"$OUTPUT_DIR/codex-err.log" &
else
  cat "$PROMPT_FILE" | codex exec - --full-auto --skip-git-repo-check --ephemeral \
    > "$OUTPUT_DIR/codex-review.md" 2>"$OUTPUT_DIR/codex-err.log" &
fi
PID_CODEX=$!

# ── Wait for all and capture exit codes ──────────────────────────
EXIT_CLAUDE=0
EXIT_GEMINI=0
EXIT_CODEX=0

wait $PID_CLAUDE || EXIT_CLAUDE=$?
wait $PID_GEMINI || EXIT_GEMINI=$?
wait $PID_CODEX  || EXIT_CODEX=$?

# ── Write status.json (no jq dependency) ─────────────────────────
printf '{\n' > "$OUTPUT_DIR/status.json"
printf '  "artifact": "%s",\n' "$ARTIFACT" >> "$OUTPUT_DIR/status.json"
printf '  "name": "%s",\n' "$NAME" >> "$OUTPUT_DIR/status.json"
printf '  "reviewers": {\n' >> "$OUTPUT_DIR/status.json"
printf '    "claude": {\n' >> "$OUTPUT_DIR/status.json"
printf '      "exit_code": %d,\n' "$EXIT_CLAUDE" >> "$OUTPUT_DIR/status.json"
printf '      "model": "%s",\n' "$CLAUDE_MODEL" >> "$OUTPUT_DIR/status.json"
printf '      "output": "%s/claude-review.md",\n' "$OUTPUT_DIR" >> "$OUTPUT_DIR/status.json"
printf '      "errors": "%s/claude-err.log"\n' "$OUTPUT_DIR" >> "$OUTPUT_DIR/status.json"
printf '    },\n' >> "$OUTPUT_DIR/status.json"
printf '    "gemini": {\n' >> "$OUTPUT_DIR/status.json"
printf '      "exit_code": %d,\n' "$EXIT_GEMINI" >> "$OUTPUT_DIR/status.json"
printf '      "model": "%s",\n' "$GEMINI_MODEL" >> "$OUTPUT_DIR/status.json"
printf '      "output": "%s/gemini-review.md",\n' "$OUTPUT_DIR" >> "$OUTPUT_DIR/status.json"
printf '      "errors": "%s/gemini-err.log"\n' "$OUTPUT_DIR" >> "$OUTPUT_DIR/status.json"
printf '    },\n' >> "$OUTPUT_DIR/status.json"
printf '    "codex": {\n' >> "$OUTPUT_DIR/status.json"
printf '      "exit_code": %d,\n' "$EXIT_CODEX" >> "$OUTPUT_DIR/status.json"
printf '      "model": "%s",\n' "$CODEX_MODEL" >> "$OUTPUT_DIR/status.json"
printf '      "output": "%s/codex-review.md",\n' "$OUTPUT_DIR" >> "$OUTPUT_DIR/status.json"
printf '      "errors": "%s/codex-err.log"\n' "$OUTPUT_DIR" >> "$OUTPUT_DIR/status.json"
printf '    }\n' >> "$OUTPUT_DIR/status.json"
printf '  }\n' >> "$OUTPUT_DIR/status.json"
printf '}\n' >> "$OUTPUT_DIR/status.json"

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "=== Review Council Complete ==="
echo "Claude:  exit=$EXIT_CLAUDE  output=$OUTPUT_DIR/claude-review.md"
echo "Gemini:  exit=$EXIT_GEMINI  output=$OUTPUT_DIR/gemini-review.md"
echo "Codex:   exit=$EXIT_CODEX   output=$OUTPUT_DIR/codex-review.md"
echo "Status:  $OUTPUT_DIR/status.json"

# Exit non-zero if any reviewer failed
if [ "$EXIT_CLAUDE" -ne 0 ] || [ "$EXIT_GEMINI" -ne 0 ] || [ "$EXIT_CODEX" -ne 0 ]; then
  echo ""
  echo "WARNING: One or more reviewers exited with errors. Check error logs."
  exit 1
fi
