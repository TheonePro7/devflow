# Phase 0 Ideate Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade devflow Phase 0 from a basic 4-question prompt to a 4-stage adaptive discovery engine that outputs structured context for `to-prd` to format into a final PRD.

**Architecture:** Keep the design as pure SKILL.md prompt changes — no scripts, no external tools. The 4 stages (Problem → Users → Features → Constraints) are guided by Claude's conversation; to-prd is called at the end for formatting.

**Tech Stack:** Markdown edits to SKILL.md only (two sections: the 5 Phases overview and the ⓪ Injection section). Plus a small state file update.

---

## File Structure

| File | Change |
|------|--------|
| `SKILL.md:81-100` | Replace Phase 0 overview with 4-stage architecture diagram |
| `SKILL.md:318-340` | Replace Phase 0 Ideate Injection with full 4-stage process definition including adaptive logic, to-prd handoff, edge cases |
| `SKILL.md:54` | Minor update: Phase 0 now produces structured context → to-prd |
| `.devflow/state` | No structural change, but Phase 0 step sequence expanded |

---

### Task 1: Update Phase 0 Overview in the 5 Phases Section

**Files:**
- Modify: `SKILL.md:81-100`

- [ ] **Step 1: Replace lines 81-100 with the new Phase 0 overview**

Replace:
```
Phase 0: Ideate (session-level, per-feature)
  ────────────────────────────────────────
  Goal: Turn a raw idea into a structured product brief.
  
  1. User shares raw idea/vision
  2. Claude guides structured exploration:
     - What problem are we solving?
     - Who are the target users?
     - What existing solutions exist?
     - How do we measure success?
  3. Generate product brief:
     - Product vision statement
     - User personas (2-3)
     - Feature hypotheses (MoSCoW: Must/Should/Could/Won't)
     - Risk & constraint analysis
  4. Output: PRD draft saved to docs/prd/
  
  No external tools needed — everything happens through
  Claude-guided conversation. Phase 0 ends with a PRD
  that feeds into Phase 0.5 and Phase 2.
```

With:
```
Phase 0: Ideate (session-level, per-feature)
  ────────────────────────────────────────
  Goal: Raw idea → structured PRD via adaptive discovery.
  Powered by 4-stage exploration engine + to-prd for output.

  ┌──────────────────────────────────────────────┐
  │  STRUCTURED DISCOVERY ENGINE                 │
  │                                              │
  │  Stage 1: Problem Discovery                  │
  │    ├── Pain point → current state → timing   │
  │    ├── Competitive landscape                  │
  │    └── Output: Problem Statement             │
  │                                              │
  │  Stage 2: Users & Scenarios                  │
  │    ├── Persona derivation (2-3 roles)        │
  │    ├── Scenario mapping                      │
  │    └── Output: Personas + User Stories       │
  │                                              │
  │  Stage 3: Feature Discovery                  │
  │    ├── Divergent: brainstorm all features    │
  │    ├── Convergent: MoSCoW priority sort      │
  │    └── Output: Prioritized feature list      │
  │                                              │
  │  Stage 4: Constraints & Success              │
  │    ├── Technical/business/platform/ timeline │
  │    ├── Success metrics (qual + quant)        │
  │    └── Risk assessment                       │
  │                                              │
  │  KEY: Adaptive — skip stages user already    │
  │  covered. Only probe gaps.                   │
  └──────────────────────┬───────────────────────┘
                         │ structured context
                         ▼
  ┌──────────────────────────────────────────────┐
  │  to-prd skill                                │
  │  ├── Writes formatted PRD to GitHub Issues   │
  │  └── Also saves to docs/prd/<feature>.md     │
  └──────────────────────────────────────────────┘

  Phase 0 outputs structured JSON to .devflow/prd-context.json,
  then invokes to-prd for formatting. End result is a production-
  ready PRD that feeds into Phase 0.5 (Design) and Phase 2.
```

- [ ] **Step 2: Update line 54 to reflect the enhanced Phase 0**

Current (line 54):
```
3. **Phase 0 (Ideate) comes first.** No design or coding before the idea is clarified. Phase 0 produces a PRD draft. Phase 0.5 (Design) follows — frontend architecture + UI generation before any backend code.
```

Replace with:
```
3. **Phase 0 (Ideate) comes first.** No design or coding before the idea is clarified. Phase 0 runs a 4-stage adaptive discovery, then invokes to-prd to produce the final PRD. Phase 0.5 (Design) follows — frontend architecture + UI generation before any backend code.
```

- [ ] **Step 3: Commit**

```bash
git add SKILL.md
git commit -m "feat(SKILL): replace Phase 0 overview with 4-stage discovery engine"
```

---

### Task 2: Replace Phase 0 Ideate Injection Section

**Files:**
- Modify: `SKILL.md:318-340`

- [ ] **Step 1: Replace the ⓪ — Phase 0 Ideate Injection section**

Replace lines 318-340 (the current YAML process block) with the complete 4-stage process definition.

Current content to replace:
````
### ⓪ — Phase 0 Ideate Injection

When user shares a raw idea, guide them through structured exploration:

```yaml
Process:
  1. Listen to the user's idea — do NOT jump to solutions
  2. Ask clarifying questions:
     - "Who is this for?" (target users)
     - "What problem does it solve?" (pain point)
     - "How is it solved today?" (existing alternatives)
     - "What does success look like?" (KPIs)
  3. Synthesize into product brief:
     - Product vision (1-2 sentences)
     - User personas (2-3 archetypes)
     - Feature hypotheses (MoSCoW priority)
     - Risks & constraints
  4. Save PRD to docs/prd/<feature-slug>.md
  5. Confirm with user before proceeding to Phase 0.5 or Phase 1

Note: This is Claude-guided collaboration — no HITL gate needed.
      The user can always redirect. End with a clear "ready to design?"
```
````

Replace with:
````
### ⓪ — Phase 0 Ideate Injection

When user shares a raw idea, run the 4-stage adaptive discovery engine.
Each stage auto-detects if the user has already covered that dimension.
Only probe gaps. Never ask mechanical questions.

**Important references before starting:**
- Load docs/CONTEXT.md for domain vocabulary (if exists)
- Check docs/adr/ for relevant past decisions
- Create docs/prd/ directory if it doesn't exist

```yaml
Process Overview:
  Adaptive 4-stage discovery → structured JSON → to-prd output

  Stage 1: Problem Discovery
    Goal: Validate that this problem is worth solving.
    Triggers (auto-detect, only ask if missing):
      - Pain point: "What specific problem are we solving? Who feels it?"
      - Current state: "How is this handled today?"
      - Timing: "Why now? What changed?"
      - Competition: "Are there existing solutions? What's missing?"
    Output: Problem Statement (1-2 paragraphs)
    Skip: If user already described all four dimensions → just confirm
    Edge case: User vague → ask "Let me make sure I understand the problem..."
    Edge case: User has strong opinions on implementation → "Let's park the 
               implementation details for now. First I want to understand..."

  Stage 2: Users & Scenarios
    Goal: Identify who this is for and what they need.
    Process:
      1. Derive 2-3 persona archetypes from context (identity → need → pain)
      2. Show to user: "Does this sound right?"
      3. For each persona, generate 3-5 User Stories
    User Story format (from to-prd):
      As a <role>, I want <capability>, so that <benefit>
    Example:
      As a small shop owner, I want one-click product poster generation,
      so that I can promote on social media without hiring a designer
    Output: 2-3 Personas + 6-15 User Stories
    Skip: If user already named target users → refine, don't re-ask
    Edge case: User says "everyone" → help segment: "Who needs this most?"

  Stage 3: Feature Discovery
    Goal: From divergent brainstorm to prioritized scope.
    Phase A — Divergent:
      1. Ask: "What features do you envision for this?"
      2. If user runs dry, suggest based on domain knowledge + competitors
    Phase B — Convergent (MoSCoW):
      - Must: core path, unusable without
      - Should: important but has workaround
      - Could: nice-to-have, only with extra resource
      - Won't: explicitly defer to future
    Deep Module check (from to-prd):
      After listing features, look for one that encapsulates complexity
      behind a simple interface — that's a deep module candidate.
      Flag it: "I notice <feature> could be a deep module..."
    Output: MoSCoW-sorted feature list, each Must/Should mapped to User Stories
    Skip: If user has a clear feature list → go straight to MoSCoW sorting

  Stage 4: Constraints & Success
    Goal: Ensure the PRD is feasible and testable.
    Scan systematically for gaps (only ask what's missing):
      - Tech stack: Languages, frameworks, hosting?
      - Timeline: When should this ship?
      - Platform: Web / iOS / Android / all?
      - Business: Compliance, security, auth model?
      - Success (qual): What does "using it" look like?
      - Success (quant): DAU, conversion rate, response time, coverage?
      - Risks: Top 3 risks and mitigations?
    ADR check: Scan docs/adr/ for decisions affecting this feature
    Output: Constraints + Success Metrics + Risk matrix

  Handoff — to-prd integration:
    After all 4 stages complete:
    1. Collect all outputs into structured JSON
    2. Save to .devflow/prd-context.json:
       {
         "phase": 0,
         "stage": "complete",
         "outputs": {
           "problemStatement": "<from Stage 1>",
           "personas": [{"name":"...", "needs":"...", "painPoints":"..."}],
           "userStories": ["As a ..., I want ..., so that ..."],
           "featurePriority": {"must":["..."], "should":["..."], "could":["..."], "wont":["..."]},
           "constraints": {"tech":"...", "timeline":"...", "platform":"...", "business":"..."},
           "successMetrics": {"qualitative":"...", "quantitative":"..."},
           "risks": [{"risk":"...", "mitigation":"..."}]
         }
       }
    3. Confirm with user: "Ready to turn this into a formal PRD?"
    4. Run: /to-prd (let to-prd format and publish)
    5. Also save final PRD to docs/prd/<feature-slug>.md

Edge Cases:
  - User already has a full PRD: Skip Stages 1-3. Stage 4 validates
    completeness, then directly hand off to to-prd.
  - User changes mind mid-stream: Restart from Stage 1, but preserve
    confirmed info. Don't re-ask settled questions.
  - User is in a hurry: "Quick mode" — one question per stage,
    only the most critical gap.
  - No CONTEXT.md exists: Create it during Stage 2 with domain terms.

Note: This is Claude-guided collaboration — no HITL gate needed.
      The user can always redirect. End each stage with confirmation.
      End the full discovery with "Ready to turn this into a PRD?"
```
````

- [ ] **Step 2: Commit**

```bash
git add SKILL.md
git commit -m "feat(SKILL): replace Phase 0 Ideate Injection with 4-stage process + to-prd handoff"
```

---

### Task 3: Update Critical Rules and References

**Files:**
- Modify: `SKILL.md:55` (Phase 0/0.5 description)

- [ ] **Step 1: Update line 55 to reference to-prd**

Current:
```
4. **Phase 0/0.5 are Claude-guided, not HITL gates.** The user provides vision and feedback; Claude structures and drives the process. Hard gates (grill, autoresearch) apply from Phase 2 onward.
```

Replace with:
```
4. **Phase 0/0.5 are Claude-guided, not HITL gates.** The user provides vision and feedback; Claude drives the 4-stage discovery and invokes to-prd for formatting. Hard gates (grill, autoresearch) apply from Phase 2 onward.
```

Also update the `docs/prd/` reference in the Project Structure section (line 581):
Current:
```
│   ├── prd/              # Phase 0: Product Requirements Documents
```
This is still correct — to-prd also saves to docs/prd/. No change needed.

- [ ] **Step 2: Commit**

```bash
git add SKILL.md
git commit -m "docs: update Phase 0/0.5 rule to reference to-prd integration"
```

---

### Task 4: Update .devflow/state Step Values for Phase 0

**Files:**
- Modify: `.devflow/state`

- [ ] **Step 1: Update the state for this feature's current brainstorming phase**

The state currently reads:
```json
{"phase":2,"step":"brainstorming","feature":"Phase 0 Ideate 增强 — 想法到可开发 PRD 的智能引导","prd":"","blocker":"","updatedAt":"2026-05-05T00:00:00Z"}
```

This is correct for the current brainstorming phase. After the plan is executed and the feature is implemented, future Phase 0 sessions should use these step values:

| Phase 0 Step | Meaning |
|-------------|---------|
| `problem` | Stage 1: Problem Discovery in progress |
| `users` | Stage 2: Users & Scenarios in progress |
| `features` | Stage 3: Feature Discovery in progress |
| `constraints` | Stage 4: Constraints & Success in progress |
| `prd` | to-prd handoff: generating final PRD |

This is documented in SKILL.md's state file section. No immediate code change needed — the state file values are set dynamically per session. Just verify the SKILL.md state documentation covers these values.

- [ ] **Step 1 (alternate): Add Phase 0 step values to the state field documentation**

Find line 252-257 in SKILL.md (State File section), add a row to the step values:

Add after line 257 (before the **更新规则** line):
```
| | Phase 0 steps: `problem` → `users` → `features` → `constraints` → `prd` |
```

- [ ] **Step 2: Commit state update**

```bash
git add SKILL.md
git commit -m "docs: add Phase 0 step values to state documentation"
```

---

### Task 5: End-to-End Verification

- [ ] **Step 1: Verify SKILL.md Phase 0 sections**

Read the modified sections and verify:
- The 5 Phases Phase 0 section (lines 81-117) shows the 4-stage architecture
- The ⓪ injection section has complete process YAML with all 4 stages
- to-prd handoff is documented with JSON schema
- Edge cases are covered (quick mode, already have PRD, change mind, no CONTEXT.md)
- All to-prd borrowed elements are integrated: User Story format, Deep Module, domain vocab, ADR

- [ ] **Step 2: Verify the old Phase 0 content is fully replaced**

Search for any remaining mentions of the old 4-question pattern:
```
Grep SKILL.md for "What problem are we solving"
Grep SKILL.md for "Who are the target users"
```
Expected: 0 results after replacement.

- [ ] **Step 3: Verify state consistency**

Confirm `.devflow/state` reflects current phase.

- [ ] **Step 4: Verify guards and hooks don't conflict**

Read `.claude/hooks/devflow-phase-check.ps1` and `.sh` — confirm the phase-check hook allows Phase 0 editing (the spec says Phase 0 is Claude-guided, so editing SKILL.md is expected during Phase 2 development of the feature).

- [ ] **Step 5: Final commit**

```bash
git add SKILL.md .devflow/state
git commit -m "chore: Phase 0 Ideate enhancement complete — verification passed"
```
