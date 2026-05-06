#!/usr/bin/env bash
# auto-designer.sh — Phase 2 Auto-Designer orchestrator
# Routes frontend generation requests to the appropriate engine.
#
# Usage:
#   bash auto-designer.sh --analyze "project description"
#   bash auto-designer.sh --generate --type=admin --framework=react --complexity=small
#   bash auto-designer.sh --install openui|bolt|screenshot
#   bash auto-designer.sh --help

set -euo pipefail

show_help() {
  cat <<'HELP'
Usage: bash auto-designer.sh [OPTIONS]

Options:
  --analyze "<description>"   Analyze project requirements and output JSON
  --generate                  Generate frontend project (requires --type, --framework, --complexity)
  --install <tool>            Install a generator tool (openui|bolt|screenshot)
  --type <type>               Project type (landing|admin|social|ecommerce|tool|content|mobile)
  --framework <name>          Framework override (react|next|vue|rn)
  --complexity <level>        Complexity level (small|medium|large)
  --output <dir>              Output directory (default: ./)
  --help                      Show this help

Examples:
  bash auto-designer.sh --analyze "Build me an e-commerce site"
  bash auto-designer.sh --generate --type=admin --framework=react --complexity=small --output=./generated
HELP
}

if [ $# -eq 0 ]; then show_help; exit 0; fi

ANALYZE=""
GENERATE=false
INSTALL=""
PROJECT_TYPE=""
FRAMEWORK=""
COMPLEXITY="small"
OUTPUT_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --analyze) shift; ANALYZE="$1"; shift ;;
    --generate) GENERATE=true; shift ;;
    --install) shift; INSTALL="$1"; shift ;;
    --type=*) PROJECT_TYPE="${1#*=}"; shift ;;
    --type) shift; PROJECT_TYPE="$1"; shift ;;
    --framework=*) FRAMEWORK="${1#*=}"; shift ;;
    --framework) shift; FRAMEWORK="$1"; shift ;;
    --complexity=*) COMPLEXITY="${1#*=}"; shift ;;
    --complexity) shift; COMPLEXITY="$1"; shift ;;
    --output=*) OUTPUT_DIR="${1#*=}"; shift ;;
    --output) shift; OUTPUT_DIR="$1"; shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done

# ── Analyze ──────────────────────────────────────────
# Called by Claude to classify a project description.
# Outputs JSON that Claude uses to decide routing.

classify_project_type() {
  local desc="$1"
  # Claude handles classification via SKILL.md prompts.
  # This script just echoes the expected JSON structure.
  # Actual classification happens in Claude's reasoning.
  echo '{"status":"analyzed","hint":"Use SKILL.md framework matching table to classify"}'
}

analyze_requirements() {
  local desc="$1"
  echo "[devflow] Analyzing: $desc" >&2
  echo '{"projectType":"pending","framework":"pending","complexity":"pending","generator":"pending"}'
}

# ── Install ──────────────────────────────────────────
# On-demand installation of external generators.

install_openui() {
  echo "[devflow] Installing OpenUI..."
  if command -v pip &>/dev/null; then
    pip install openui 2>&1 || pip3 install openui 2>&1
    echo "[devflow] OpenUI installed. Run: openui"
  else
    echo "[devflow] Python/pip not found. Try: brew install openui"
    return 1
  fi
}

install_bolt() {
  local target="$HOME/.devflow/tools/bolt.diy"
  echo "[devflow] Installing bolt.diy to $target..."
  mkdir -p "$HOME/.devflow/tools"
  if [ ! -d "$target" ]; then
    git clone https://github.com/stackblitz-labs/bolt.diy.git "$target" 2>&1
    cd "$target" && npm install 2>&1
    echo "[devflow] bolt.diy installed at $target"
  else
    echo "[devflow] bolt.diy already installed at $target"
  fi
}

install_screenshot_to_code() {
  local target="$HOME/.devflow/tools/screenshot-to-code"
  echo "[devflow] Installing screenshot-to-code..."
  mkdir -p "$HOME/.devflow/tools"
  if [ ! -d "$target" ]; then
    git clone https://github.com/abi/screenshot-to-code.git "$target" 2>&1
    cd "$target" && docker compose build 2>&1
    echo "[devflow] screenshot-to-code ready at $target"
  else
    echo "[devflow] screenshot-to-code already installed at $target"
  fi
}

# ── Dispatch ────────────────────────────────────────

if [ -n "$ANALYZE" ]; then
  classify_project_type "$ANALYZE"
  analyze_requirements "$ANALYZE"
fi

case "$INSTALL" in
  openui) install_openui ;;
  bolt) install_bolt ;;
  screenshot) install_screenshot_to_code ;;
  "") ;;  # no-op
  *) echo "[devflow] Unknown tool: $INSTALL"; exit 1 ;;
esac

# ── Generate ─────────────────────────────────────────
# Placeholder for generator dispatch.
# Actual generation happens via SKILL.md Claude Direct prompts
# or by launching external tools.

if [ "$GENERATE" = true ]; then
  echo "[devflow] Generating: type=$PROJECT_TYPE framework=$FRAMEWORK complexity=$COMPLEXITY"
  mkdir -p "$OUTPUT_DIR"
  echo "{ \"status\": \"generated\", \"outputDir\": \"$OUTPUT_DIR\" }"
fi
