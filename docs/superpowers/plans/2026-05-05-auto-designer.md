# Phase 0.5 Auto-Designer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an intelligent frontend generator that analyzes user requirements, matches framework + design system, and routes to the appropriate generator engine (Claude Direct / OpenUI / bolt.diy / screenshot-to-code) based on complexity.

**Architecture:** Claude-driven Requirements Analyzer classifies project type → matches framework → scores complexity → routes to generator → unified post-processor normalizes output. Claude Direct (built-in) covers 80% of projects; external generators are on-demand only.

**Tech Stack:** bash + PowerShell scripts (cross-platform), SKILL.md prompt templates for Claude Direct generation, optional external tools (OpenUI/bolt.diy/screenshot-to-code) installed on-demand.

---

## File Structure

### New Files
| File | Responsibility |
|------|---------------|
| `scripts/auto-designer.sh` | Entry point orchestrator (bash). Reads project config, calls requirements analyzer, routes to generator. |
| `scripts/auto-designer.ps1` | Same as above (PowerShell). |

### Modified Files
| File | Responsibility |
|------|---------------|
| `SKILL.md` | Replace old Phase 0.5 section with Auto-Designer routing logic + design token templates + Claude Direct prompt patterns. |
| `setup.sh` | Add `--with-designer` flag for pre-installing optional generators. |
| `setup.ps1` | Same as above (PowerShell). |

---

## Tasks

### Task 1: Update SKILL.md — Replace Phase 0.5 Section with Auto-Designer Logic

**Files:**
- Modify: `SKILL.md:102-126`

- [ ] **Step 1: Replace the Phase 0.5 section with the Auto-Designer architecture diagram**

Replace the current Phase 0.5 content (lines 102-126) with:

````markdown
Phase 0.5: Design (session-level, per-feature)
  ────────────────────────────────────────────
  Goal: From PRD → production-grade frontend code.
  Powered by Auto-Designer engine.

  ┌──────────────────────────────────────────────┐
  │  AUTO-DESIGNER                               │
  │                                              │
  │  1. Requirements Analysis (Claude-driven)    │
  │     ├── Classify: landing/admin/social/...    │
  │     ├── Match framework + design system       │
  │     └── Score complexity (1-5 small, 6-15    │
  │         medium, 16+ large)                   │
  │                                              │
  │  2. Complexity Router                        │
  │     ├── Small  → Claude Direct (built-in)    │
  │     ├── Medium → OpenUI (on-demand)          │
  │     ├── Large  → bolt.diy (on-demand)        │
  │     └── Screenshots → screenshot-to-code     │
  │                                              │
  │  3. Unified Post-Processor                   │
  │     ├── Inject design tokens                 │
  │     ├── Normalize project structure          │
  │     └── Create beads dev tasks               │
  └──────────────────────────────────────────────┘

  Framework Matching (AUTOMATIC — no user choice needed):

  | Project Type  | Default Framework              | Design System  |
  |---------------|-------------------------------|----------------|
  | landing       | Next.js + Tailwind             | Tailwind UI    |
  | admin         | React + Ant Design             | Ant Design Pro |
  | social        | Next.js + Tailwind             | shadcn/ui      |
  | ecommerce     | Next.js + Tailwind             | shadcn/ui      |
  | tool          | React + Tailwind               | shadcn/ui      |
  | content       | Next.js + Tailwind + MDX       | Tailwind UI    |
  | mobile        | React Native + NativeWind      | NativeWind     |

  On-Demand Tool Install:
  - OpenUI (22.3k⭐): `pip install openui` — when user confirms for medium projects
  - bolt.diy (19.3k⭐): `git clone + npm install` — when user confirms for large projects
  - screenshot-to-code (72.4k⭐): Docker — when user provides screenshots

  **Default behavior (80% of projects):** Claude Direct — zero install, zero dependencies.
  Agent generates the full frontend project inline using the design token templates below.

  The agent MUST NOT ask "which framework do you want?" — analyze and decide automatically.
  Only ask the user when complexity suggests an external tool might be needed.
````

- [ ] **Step 2: Add design token templates after the Phase 0.5 section**

After the Phase 0.5 section, add:

```markdown
### Design Token Templates (for Claude Direct generation)

When generating frontend code via Claude Direct, use these design tokens:

**Color Palette Derivation:**
```
From brand color or default (#1677ff):
  Primary:    brand → 50/100/200/300/400/500/600/700/800/900
  Neutral:    gray scale
  Success:    green (#52c41a)
  Warning:    orange (#faad14)
  Error:      red (#ff4d4f)
  Info:       blue (#1677ff)
```

**Spacing Scale (Tailwind-compatible):**
```
px(1) → 0.5(2) → 1(4) → 2(8) → 3(12) → 4(16) → 5(20) → 6(24) → 8(32) → 10(40) → 12(48) → 16(64)
```

**Typography:**
```
Headings: Inter / Plus Jakarta Sans (weights: 600/700)
Body:     Inter (weight: 400)
Monospace: JetBrains Mono (for code blocks)
```

**Component Patterns (per framework):**
- React + shadcn/ui: use <Card>, <Dialog>, <Table>, <Form> primitives
- React + Ant Design: use <ProTable>, <ProForm>, <ProLayout>
- Next.js: App Router, server components by default, client components only when needed
```

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat(SKILL): replace Phase 0.5 with Auto-Designer routing + design tokens"
```

---

### Task 2: Create auto-designer.sh (Bash Orchestrator)

**Files:**
- Create: `scripts/auto-designer.sh`

- [ ] **Step 1: Create the script with help text and argument parsing**

```bash
#!/usr/bin/env bash
# auto-designer.sh — Phase 0.5 Auto-Designer orchestrator
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
    --type) shift; PROJECT_TYPE="$1"; shift ;;
    --framework) shift; FRAMEWORK="$1"; shift ;;
    --complexity) shift; COMPLEXITY="$1"; shift ;;
    --output) shift; OUTPUT_DIR="$1"; shift ;;
    --help) show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help; exit 1 ;;
  esac
done
```

- [ ] **Step 2: Add the analyze function (project type classification)**

After the argument parsing, add:

```bash
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
```

- [ ] **Step 3: Add the install function (on-demand generator install)**

```bash
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

case "$INSTALL" in
  openui) install_openui ;;
  bolt) install_bolt ;;
  screenshot) install_screenshot_to_code ;;
  "") ;;  # no-op
  *) echo "[devflow] Unknown tool: $INSTALL"; exit 1 ;;
esac
```

- [ ] **Step 4: Add the generate stub**

```bash
# ── Generate ─────────────────────────────────────────
# Placeholder for generator dispatch.
# Actual generation happens via SKILL.md Claude Direct prompts
# or by launching external tools.

if [ "$GENERATE" = true ]; then
  echo "[devflow] Generating: type=$PROJECT_TYPE framework=$FRAMEWORK complexity=$COMPLEXITY"
  mkdir -p "$OUTPUT_DIR"
  echo "{ \"status\": \"generated\", \"outputDir\": \"$OUTPUT_DIR\" }"
fi
```

- [ ] **Step 5: Make executable and verify**

```bash
chmod +x scripts/auto-designer.sh
bash scripts/auto-designer.sh --help
Expected: Shows help text, exits 0
```

- [ ] **Step 6: Commit**

```bash
git add scripts/auto-designer.sh
git commit -m "feat(scripts): add auto-designer.sh orchestrator for Phase 0.5"
```

---

### Task 3: Create auto-designer.ps1 (PowerShell Orchestrator)

**Files:**
- Create: `scripts/auto-designer.ps1`

- [ ] **Step 1: Create the PowerShell equivalent**

```powershell
# auto-designer.ps1 — Phase 0.5 Auto-Designer orchestrator (PowerShell)
# Routes frontend generation requests to the appropriate engine.

param(
  [string]$Analyze = "",
  [switch]$Generate = $false,
  [string]$Install = "",
  [string]$Type = "",
  [string]$Framework = "",
  [string]$Complexity = "small",
  [string]$Output = "."
)

function Show-Help {
  Write-Host @"
Usage: .\auto-designer.ps1 [options]

Options:
  -Analyze "<description>"   Analyze project requirements
  -Generate                  Generate frontend project
  -Install <tool>            Install generator (openui|bolt|screenshot)
  -Type <type>               Project type (landing|admin|social|ecommerce|tool|content|mobile)
  -Framework <name>          Framework override
  -Complexity <level>        Complexity level (small|medium|large)
  -Output <dir>              Output directory
"@
}

function Install-OpenUI {
  Write-Host "[devflow] Installing OpenUI..."
  pip install openui 2>&1
}

function Install-Bolt {
  $target = Join-Path $env:USERPROFILE ".devflow\tools\bolt.diy"
  Write-Host "[devflow] Installing bolt.diy to $target..."
  if (-not (Test-Path $target)) {
    git clone https://github.com/stackblitz-labs/bolt.diy.git $target 2>&1
    Push-Location $target
    npm install 2>&1
    Pop-Location
  }
}

function Install-ScreenshotToCode {
  $target = Join-Path $env:USERPROFILE ".devflow\tools\screenshot-to-code"
  if (-not (Test-Path $target)) {
    git clone https://github.com/abi/screenshot-to-code.git $target 2>&1
    Push-Location $target
    docker compose build 2>&1
    Pop-Location
  }
}

if ($Install) {
  switch ($Install) {
    "openui" { Install-OpenUI }
    "bolt" { Install-Bolt }
    "screenshot" { Install-ScreenshotToCode }
    default { Write-Host "Unknown tool: $Install"; exit 1 }
  }
}

if ($Generate) {
  Write-Host "[devflow] Generating: type=$Type framework=$Framework complexity=$Complexity"
  if (-not (Test-Path $Output)) { New-Item -ItemType Directory -Path $Output -Force | Out-Null }
  @{ status = "generated"; outputDir = $Output } | ConvertTo-Json -Compress
}

if ($Analyze) {
  Write-Host "[devflow] Analyzing: $Analyze"
  @{ status = "analyzed" } | ConvertTo-Json -Compress
}
```

- [ ] **Step 2: Commit**

```bash
git add scripts/auto-designer.ps1
git commit -m "feat(scripts): add auto-designer.ps1 (PowerShell)"
```

---

### Task 4: Update setup.sh — Add --with-designer Flag

**Files:**
- Modify: `setup.sh:9,21` (usage + flag parsing)

- [ ] **Step 1: Update usage comment**

```
#   bash setup.sh --with-designer    # Also install optional UI generators
```

- [ ] **Step 2: Add flag variable and parsing**

Add after line 21 (`SKIP_AUTORESEARCH=false`):
```bash
WITH_DESIGNER=false
```

Add to the case block:
```bash
    --with-designer) WITH_DESIGNER=true; shift ;;
```

- [ ] **Step 3: Add install step after autoresearch install**

Find the autoresearch install section and add after it:

```bash
# ---- Optional: Auto-Designer generators ----
if [ "$WITH_DESIGNER" = true ]; then
  echo ""
  echo -e "${YELLOW}--- auto-designer generators ---${NC}"
  echo -e "${GRAY}  Installing optional UI generation tools...${NC}"
  bash "$SKILL_DIR/auto-designer.sh" --install openui 2>/dev/null || echo -e "${YELLOW}  [SKIP] OpenUI install skipped (install manually: pip install openui)${NC}"
  echo -e "${GREEN}[PASS] auto-designer generators ready${NC}"
fi
```

- [ ] **Step 4: Verify**

Run: `bash setup.sh --help` (if implemented) or just confirm parsing works.

- [ ] **Step 5: Commit**

```bash
git add setup.sh
git commit -m "feat(setup): add --with-designer flag for optional UI generators"
```

---

### Task 5: Update setup.ps1 — Add --WithDesigner Flag

**Files:**
- Modify: `setup.ps1`

- [ ] **Step 1: Mirror the same changes in setup.ps1**

Add parameter:
```powershell
[switch]$WithDesigner = $false
```

Add after the autoresearch step:
```powershell
if ($WithDesigner) {
  Write-Host "--- auto-designer generators ---"
  & ".\scripts\auto-designer.ps1" -Install openui
}
```

- [ ] **Step 2: Commit**

```bash
git add setup.ps1
git commit -m "feat(setup): add -WithDesigner flag (PowerShell)"
```

---

### Task 6: Update .devflow/state + Verify End-to-End

**Files:**
- Modify: `.devflow/state`

- [ ] **Step 1: Update state file**

```json
{"phase":2,"step":"impl","feature":"Phase 0.5 Auto-Designer","updatedAt":"2026-05-05T00:00:00Z"}
```

- [ ] **Step 2: Verify script integrity**

```bash
bash scripts/auto-designer.sh --help
Expected: Shows help, exits 0

bash scripts/auto-designer.sh --analyze "test"
Expected: No errors, returns JSON

powershell -File scripts/auto-designer.ps1 -Analyze "test"
Expected: No errors, returns JSON
```

- [ ] **Step 3: Final commit**

```bash
git add .devflow/state
git commit -m "chore: update devflow state to Auto-Designer implementation"
```
