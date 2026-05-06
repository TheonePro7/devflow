# Beads (bd) — Deep Research Analysis

> Project: gastownhall/beads — "A memory upgrade for your coding agent"
> Language: Go (CLI), with MCP server (Python), npm package
> License: MIT
> Stars: ~23k
> Storage: Dolt (embedded or server mode — SQL database with Git-style versioning)
> Docs: https://gastownhall.github.io/beads/

---

## 1. Full CLI Command List with ALL Flags and Parameters

### Core Lifecycle Commands

#### `bd init`
Initialize beads in a project. Creates `.beads/` directory with Dolt database.
```
Flags:
  --server              Use external Dolt SQL server (vs embedded, which is default)
  --stealth             Don't commit beads files to the main repo (personal use)
  --contributor         Route planning issues to separate repo (~/.beads-planning)
  --skip-agents         Don't create/update AGENTS.md
  --reinit-local        Reinitialize local database (discard local-only data)
  --discard-remote      Discard remote database reference
  --team <name>         Set up for a team
  --team-name, --team-remote, etc.
```

#### `bd create "<title>"`
Create a new issue/task.
```
Flags:
  -p, --priority <0-4>            Priority (0=highest, default varies)
  -a, --assignee <name>           Assignee
  -d, --description <text>        Issue description
  --body <text>                   Alias for --description (GH CLI convention, hidden)
  -m, --message <text>            Alias for --description (git commit convention, hidden)
  --body-file <path>              Read description from file (use - for stdin)
  --description-file <path>       Alias for --body-file (hidden)
  --stdin                         Read description from stdin (alias for --body-file -)
  --design <text>                 Design notes
  --design-file <path>            Read design from file (use - for stdin)
  --acceptance <text>             Acceptance criteria
  --notes <text>                  Additional notes
  --external-ref <ref>            External reference (e.g., 'gh-9', 'jira-ABC')
  --type <type>                   Issue type (bug, task, feature, epic, chore, story)
  -t, --template <name>           Use a template for issue structure
  -l, --label <label>             Add label(s)
  --parent <id>                   Parent issue ID
  -L, --link <id>                 Link to related issue
  --dry-run                       Preview without creating
  -f, --file <path>               Batch create from markdown file
  --graph <file>                  Batch create from graph JSON
  --repo <name>                   Override routing database
  --waits-for-gate <name>         Block on a gate
  --waits-for <id>                Block on another issue
  --json                          JSON output
  --skills <text>                 Required skills section
  --context <text>                Context section
  --due <time>                    Due date (parsed as relative time)
  --defer <time>                  Defer until date
  --estimate <minutes>            Estimated minutes
  --spec-id <id>                  Specification ID
```

#### `bd show <id>`
Show issue details.
```
Flags:
  --short           Brief format
  --long            Full detail
  --json            JSON output
  --thread          Show message thread
  --children        Show child issues
  --refs            Show references
  --watch           Watch mode (polls every 2s)
  --current         Show currently active issue
  --as-of <commit>  Show as of a specific Dolt commit
  --local-time      Display times in local timezone
  --id              Show resolved internal ID
```

#### `bd update <id> [flags]`
Update an issue (auto-selects last-touched if no ID given).
```
Flags:
  --status <status>               Set status (open, in_progress, blocked, deferred, closed, + custom)
  -p, --priority <0-4>            Set priority
  --title <text>                  Change title
  -a, --assignee <name>           Set assignee (empty to unassign)
  -d, --description <text>        Update description
  --design <text>                 Update design notes
  --notes <text>                  Replace notes
  --append-notes <text>           Append to notes (with newline separator)
  --acceptance <text>             Update acceptance criteria
  --acceptance-criteria <text>    Alias for --acceptance
  --external-ref <ref>            Set external reference
  --spec-id <id>                  Set spec ID
  --estimate <minutes>            Set estimate
  --type <type>                   Change issue type
  --add-label <label>             Add a label
  --remove-label <label>          Remove a label
  --set-labels <l1,l2,...>        Replace all labels
  --parent <id>                   Re-parent
  --await-id <id>                 Set await ID
  --due <time>                    Set due date (empty clears it)
  --defer <time>                  Set defer date (empty clears, auto-sets status=deferred)
  --ephemeral / --persistent      Toggle ephemeral state (mutually exclusive)
  --no-history / --history        Toggle history tracking (mutually exclusive)
  --branch / --no-branch          Associate/un-associate branch
  --json                          JSON output
```

#### `bd close <id...> [reason]`
Close issue(s). Alias: `bd done`.
```
Flags:
  --reason <text>               Close reason
  --resolution <text>           Resolution description
  --message <text>              Close message
  --comment <text>              Add comment on close
  --reason-file <path>          Read reason from file (use - for stdin)
  --suggest-next                Suggest next steps
  --continue                    Advance to next step in molecule
  --claim-next                  Auto-claim highest-priority ready issue
  --force                       Force close even with blockers
  --json                        JSON output
```
Uses last-touched issue if no IDs provided.

#### `bd reopen <id...>`
Reopen closed issue(s).
```
Flags:
  -r, --reason <text>   Reason for reopening
  --json
```

#### `bd delete <id>`
Delete an issue.

### Listing & Searching

#### `bd list`
List issues with filtering.
```
Flags:
  -s, --status <status>         Filter by status (open, closed, in_progress, etc.)
  -t, --type <type>             Filter by issue type
  -p, --priority <n>            Filter by priority
  -a, --assignee <name>         Filter by assignee
  -l, --label <label>           Filter by label
  --label-mode <mode>           Label matching: any, all, none
  --parent <id>                 Filter by parent
  --exclude-parent <id>         Exclude parent's children
  --tree                        Show as tree
  --long                        Detailed format
  --json                        JSON output
  --csv                         CSV output
  --compact                     Compact view
  --limit <n>                   Limit results
  --offset <n>                  Pagination offset
  --sort <field>                Sort field (created, updated, priority, title)
  --reverse                     Reverse sort order
  --created-after <time>
  --created-before <time>
  --updated-after <time>
  --updated-before <time>
  --closed-after <time>
  --closed-before <time>
  --no-assignee                 Unassigned issues
  --no-labels                   Issues without labels
  --empty-description           Issues without description
  --metadata-field <k=v>        Filter by metadata key=value
  --has-metadata-key <key>      Has specific metadata key
  --desc-contains <text>        Description contains text
  --notes-contains <text>       Notes contains text
  --external-contains <text>    External ref contains text
  --all                         Include all statuses (ignore defaults)
```

#### `bd search <query>`
Full-text search.
```
Flags: (same as list for filtering)
  --query <text>                  Search query
  -s, --status, --type, --assignee, --label, --label-any
  --created-after/before, --updated-after/before, --closed-after/before
  --priority-min, --priority-max
  --desc-contains, --notes-contains, --external-contains
  --empty-description, --no-assignee, --no-labels
  --metadata-field <k=v>, --has-metadata-key
  --json, --long, --sort, --reverse
```

#### `bd ready`
List available work (issues with no open blockers).
```
Flags:
  --claim                    Atomically claim the first ready issue
  --gated                    Find molecules where a gate just closed
  --mol <id>                 Show ready steps within a specific molecule
  --explain                  Dependency-aware reasoning about why items aren't ready
  --include-deferred         Include deferred issues
  --include-ephemeral        Include ephemeral issues
  --metadata-field <k=v>     Filter by metadata
  --has-metadata-key <key>   Has metadata key
  --json                     JSON output
```

#### `bd blocked`
Show blocked issues.

#### `bd stale`
Show stale issues (not updated recently).
```
Flags:
  -d, --days <n>     Issues not updated in N days (default: 30)
  -s, --status <s>   Filter by status (open|in_progress|blocked|deferred)
  -n, --limit <n>    Maximum results (default: 50)
  --json
```

#### `bd count`
Count issues matching filter.

### Assignment & Labels

#### `bd assign <id> <name>`
Assign/unassign an issue (shorthand for `bd update --assignee`).

#### `bd tag <id> <label>`
Add label to issue (shorthand for `bd update --add-label`).

#### `bd label`
Label management.
```
Subcommands:
  label add <id...> <label>         Add label to one+ issues
  label remove <id...> <label>      Remove label from one+ issues
  label list <id>                   List labels for an issue
  label list-all                    List all unique labels with counts
  label propagate <parent-id> <label>  Propagate label to children
```

### Dependencies

#### `bd dep`
Dependency management.
```
Subcommands:
  dep add <child> <parent>       Add blocking dependency
  dep remove <child> <parent>    Remove dependency
  dep list <id>                  List dependencies for an issue
  dep check                      Check for dependency cycles
  dep batch <file>               Batch add deps from JSONL file
Flags for dep add:
  --blocks         Create in opposite direction (child blocks parent)
  -f, --file       Batch from JSONL
```

#### `bd link <id1> <id2>`
Create related-to link between two issues.

#### `bd relate <id1> <relationship> <id2>`
Advanced relationship types: relates_to, duplicates, supersedes, parent, blocks.

### Molecules & Formulas (Workflow Templates)

#### `bd mol`
Molecule commands — work templates for agent workflows.
```
Subcommands:
  mol show <id>                  Show proto/molecule structure
  mol pour <id> [--var k=v]      Instantiate proto as persistent mol (liquid)
  mol wisp <id> [--var k=v]      Instantiate proto as ephemeral wisp (vapor)
  mol bond <id1> <id2>           Combine protos/molecules
  mol squash <id>                Condense molecule to digest
  mol burn <id>                  Discard wisp
  mol distill <id>               Extract proto from ad-hoc epic
  mol seed                       Seed starter molecules from defaults
  mol current                    Show active molecule
  mol progress <id>              Show molecule progress
  mol last-activity              Show last molecule activity
  mol stale                      Show stale molecules
  mol ready-gated                Show molecules with gates ready
Global flags:
  --var key=value                Define variables for template substitution
```

#### `bd pour <id> [--var k=v]`
Alias for `bd mol pour` — instantiate a proto (template) as real issues.

#### `bd formula`
Formula management (source definitions for molecule templates).
```
Subcommands:
  formula list                    List available formulas
  formula show <name>             Show formula details
Flags:
  --type <type>                   Filter by type (workflow, expansion, aspect, convoy)
  --json                          JSON output
```

### Comments & Discussion

#### `bd comment <id> [text...]`
Add comment.
```
Flags:
  --stdin            Read from stdin
  --file <path>      Read from file
```

#### `bd comments <id>`
List comments for an issue.
```
Flags:
  --json
```

#### `bd comments add <id> <text>`
Add a comment (long form).

#### `bd thread <id>`
Show threaded conversation view.

### Gates (Async Coordination)

#### `bd gate`
Gate management for async coordination.
```
Subcommands:
  gate list                        List gates (open by default)
  gate create <name> [--blocks <id>]  Create ad-hoc gate
  gate add-waiter <gate> <agent>   Register agent for wake notification
  gate resolve <gate>              Close a gate manually
  gate check                       Evaluate all open gates
  gate discover <name>             Auto-discover gates from issue titles
Flags:
  --all                            Show closed gates too
```

#### `bd ship <capability>`
Publish a capability for cross-project dependencies.
```
Flags:
  --force           Ship even if issue not closed
  --dry-run         Preview only
```

### Memory System (Agent Persistence)

#### `bd remember "<insight>"`
Store a persistent memory (injected by `bd prime` in every session).
```
Flags:
  --key <key>       Explicit key (auto-generated from content if not set)
```

#### `bd memories [search]`
List or search memories.

#### `bd recall <key>`
Retrieve specific memory by key.

#### `bd forget <key>`
Remove a memory.

### Configuration

#### `bd config`
Configuration management.
```
Subcommands:
  config set <key> <value>         Set a config value
  config get <key>                 Get a config value
  config list                      List all config
  config unset <key>               Unset a config value
  config show                      Show effective config
  config apply <file>              Apply config from file
  config drift                     Detect config drift
Flags:
  --json
  --force-git-tracked              Force saving sensitive keys to git (dangerous)
```

#### `bd statuses`
List valid issue statuses (built-in + custom).
```
Flags:
  --json
```

### Backup & Export

#### `bd export [-o file]`
Export issues to JSONL format.
```
Flags:
  -o, --output <file>      Output file (stdout if omitted)
  --all                    Include everything (infra, templates, gates, memories)
  --include-infra          Include agents, rigs, roles, messages
  --scrub                  Exclude test/pollution records
  --include-memories       Include bd remember data
```

#### `bd import <file>`
Import issues from JSONL.

#### `bd backup`
Backup management.
```
Subcommands:
  backup init <path>               Set up backup destination
  backup sync                      Push backup
  backup restore --force <path>    Restore from backup
```

### Version Control (Dolt)

#### `bd dolt`
Dolt database commands.
```
Subcommands:
  dolt show                        Show Dolt config + connection status
  dolt set <key> <value>           Set Dolt config (database, host, port, user, data-dir)
  dolt test                        Ping Dolt server
  dolt push [remote]               Push commits to remote
  dolt pull [remote]               Pull from remote
  dolt remote add/list/remove      Manage remotes
  dolt commit                      Commit database changes
  dolt start                       Start Dolt server
  dolt stop                        Stop Dolt server
  dolt status                      Dolt status
```

### Administration & Maintenance

#### `bd admin <subcommand>`
Advanced database maintenance.
```
Subcommands:
  admin cleanup        Delete closed issues (lifecycle management)
  admin compact        Compact old closed issues to save space
  admin reset          Remove all beads data and configuration
```

#### `bd compact`
Compaction — semantic "memory decay" for old closed tasks.
```
Flags (mutually exclusive modes):
  --analyze            Export candidates for agent/manual review
  --apply              Accept a pre-written summary
  --auto               AI-powered compaction via API
  --dolt               Run Dolt garbage collection
Other flags:
  --id <id>            Compact specific issue
  --all                Compact all eligible
  --dry-run            Preview only
  --force              Force (requires --id)
  --stats              Show compaction statistics
  --json               JSON output
```

#### `bd doctor`
Health diagnostics and repair.
```
Subcommands:
  doctor               Run all checks
  doctor --fix         Auto-fix issues
  doctor validate      Validate database integrity
  doctor health        Health check
  doctor agent         Agent diagnostics
  doctor conventions   Check project conventions
  doctor artifacts     Check artifacts
  doctor repair        Repair database
  doctor pollution     Check for pollution
```

#### `bd lint [issue-id...]`
Check issues for missing template sections based on type.
```
Flags:
  -t, --type <type>    Filter by issue type
  -s, --status <s>     Filter by status (default: open, 'all' for all)
```

#### `bd preflight`
PR readiness checklist.
```
Flags:
  --check              Actually run checks (vs static checklist)
  --skip-lint          Skip golangci-lint check
  --fix                Placeholder for auto-fix
  --json               JSON output
```
8 checks: tests pass, lint passes, formatting, beads pollution, nix hash, version sync, AGENTS.md/CLAUDE.md divergence, flake freshness.

#### `bd gc`
Garbage collection.

#### `bd prune`
Prune old data.

#### `bd purge`
Purge deleted issues permanently.

### Quality & Analysis

#### `bd graph [issue-id]`
Dependency graph visualization.
```
Flags:
  --box             ASCII boxes with layer grouping
  --compact         Single-line-per-issue tree
  --dot             Graphviz DOT format
  --html            Self-contained D3.js interactive HTML
  --all             All open issues (grouped by component)
```
Subcommand: `bd graph check` — detect dependency cycles (exit 0=clean, 1=issues)

#### `bd orphans`
Find orphaned issues (no parent, no dependencies).

#### `bd duplicates`
Find duplicate issues.

#### `bd find-duplicates`
Advanced duplicate detection.

#### `bd critical-paths`
Find critical dependency paths.

#### `bd diff`
Show differences between Dolt commits.

#### `bd history <id>`
Show issue audit trail / change history.

#### `bd audit <id>`
Show audit trail for an issue.

#### `bd status` (alias: `stats`)
Show issue database overview and statistics.
```
Flags:
  --all             Show all (default behavior)
  --assigned        Show issues assigned to current user
  --no-activity     Skip git activity tracking
  --json
```

### Version Control & Sync

#### `bd sync`
Sync with remote Dolt database.

#### `bd vc commit`
Version control commit.

#### `bd branch`
Branch management.

#### `bd merge-slot`
Manage merge slots.

### Agent & Setup

#### `bd prime`
Print agent workflow context and persistent memories (for SessionStart/PreCompact hooks).
```
Flags:
  --full              Force full CLI output (ignore MCP detection)
  --stealth           No git commands in session close
  --memories-only     Only persistent memories (for compact hooks)
  --mcp               MCP mode (brief output, ~50 tokens)
```

#### `bd setup <agent-type>`
Install bead agent integration.
```
Agent types: codex, claude, factory, mux, cursor, aider, cline, windsurf, roo, gui, openai, genaiscript, continue.dev, github-copilot
```

#### `bd onboard`
Print onboarding snippet for manual agent setup.

#### `bd bootstrap`
Bootstrap a new beads workspace.

#### `bd quickstart`
Quick start wizard.

#### `bd edit [id]`
Edit an issue field in $EDITOR.
```
Flags:
  --title           Edit title
  --description     Edit description (default)
  --design          Edit design notes
  --notes           Edit notes
  --acceptance      Edit acceptance criteria
```

#### `bd batch <file>`
Batch operations from file.

### Children & Hierarchy

#### `bd children <id>`
List children (alias for `bd list --parent <id> --status all`).

#### `bd epic`
Epic management.
```
Subcommands:
  epic status [--eligible-only]           Show epic completion status
  epic close-eligible [--dry-run]         Close completed epics
```

#### `bd promote <id>`
Promote an issue (change type upward).

#### `bd flatten <id>`
Flatten hierarchy.

### Ephemeral & Messaging

#### `bd wisp <id>`
Spawn ephemeral work (vapor phase).

#### `bd burn <id>`
Discard ephemeral work.

#### `bd mail <id>`
Send message type (with threading via --thread, ephemeral lifecycle, mail delegation).

#### `bd note <id>`
Quick note to an issue.

### Federation & Cross-Project

#### `bd federation`
Federation management for cross-project dependencies.

#### `bd routed`
Show routing configuration.

#### `bd context`
Context management.
```
Subcommands:
  context bind           Bind context
  context show           Show context
```

### Utilities

#### `bd help`
Help system.
```
Subcommands:
  help --all              Generate complete markdown reference
  help --doc <command>    Generate single-command doc with Docusaurus frontmatter
  help --list             List all available commands
```

#### `bd completions [shell]`
Generate shell completions.

#### `bd tips`
Show tips.

#### `bd kv`
Key-value store (low-level).
```
Subcommands:
  kv set <key> <value>     Set a key
  kv get <key>             Get a value
  kv clear <key>           Delete a key
  kv list                  List all keys
```

#### `bd template`
Template management.

#### `bd sql`
Run direct SQL queries.

#### `bd cook`
Run recipes (formula execution).

#### `bd ping`
Health check.

#### `bd info`
Show beads info.

#### `bd version`
Show version.

#### `bd migrate`
Migrate database schema.

#### `bd undelete`
Restore a deleted issue.

---

## 2. Issue Data Model (all fields, types)

The `Issue` struct (from `internal/types/types.go`) has ~60+ fields organized into logical groups:

### Identification
| Field | Type | Description |
|-------|------|-------------|
| `ID` | `string` | Hash-based ID (e.g., `bd-a1b2`) |
| `Number` | `int` | Human-readable sequential number |
| `Title` | `string` | Issue title |
| `Slug` | `string` | URL-friendly slug |

### Content
| Field | Type | Description |
|-------|------|-------------|
| `Description` | `string` | Main description/body |
| `Design` | `string` | Design notes |
| `AcceptanceCriteria` | `string` | Acceptance criteria |
| `Notes` | `string` | Additional notes |
| `SpecID` | `string` | Specification ID (linked to external spec) |

### Status & Workflow
| Field | Type | Description |
|-------|------|-------------|
| `Status` | `Status` | Enum: open, in_progress, blocked, deferred, closed, pinned, hooked |
| `Priority` | `string` | P0-P4 or 0-4 (P0=highest) |
| `IssueType` | `IssueType` | Enum: bug, task, feature, epic, chore, story, message, spike, tech_debt, sub_epic, gate, rig, aspect, role, agent |
| `Pinned` | `bool` | Whether issue is pinned |
| `IsTemplate` | `bool` | Whether issue is a template |
| `IsEphemeral` | `bool` | Ephemeral lifecycle (auto-deleted on close) |

### Assignment
| Field | Type | Description |
|-------|------|-------------|
| `Assignee` | `string` | Current assignee |
| `Owner` | `string` | Owner (may differ from assignee) |
| `CreatedBy` | `string` | Creator |

### Timestamps
| Field | Type | Description |
|-------|------|-------------|
| `CreatedAt` | `time.Time` | Creation timestamp |
| `UpdatedAt` | `time.Time` | Last update timestamp |
| `ClosedAt` | `*time.Time` | Closure timestamp |
| `DueAt` | `*time.Time` | Due date |

### Scheduling
| Field | Type | Description |
|-------|------|-------------|
| `DeferUntil` | `*time.Time` | Deferred until date |
| `EstimatedMinutes` | `int` | Time estimate |
| `LeadTime` | `float64` | Lead time in hours |

### External Integration
| Field | Type | Description |
|-------|------|-------------|
| `ExternalRef` | `*string` | External reference (e.g., `gh-9`, `jira-ABC`, Linear URL) |
| `SourceSystem` | `string` | Source system name |

### Custom Metadata
| Field | Type | Description |
|-------|------|-------------|
| `Metadata` | `json.RawMessage` | Arbitrary JSON metadata (schema-validated) |

### Compaction
| Field | Type | Description |
|-------|------|-------------|
| `Compacted` | `bool` | Whether this issue has been compacted |
| `CompactedSummary` | `string` | AI-generated compact summary |
| `CompactedAt` | `*time.Time` | When compaction occurred |
| `CompactionTier` | `int` | Compaction tier (1=~70% reduction, 2=~95% reduction) |

### Routing
| Field | Type | Description |
|-------|------|-------------|
| `PrefixRoute` | `string` | Routing prefix (e.g., "xe-") |
| `DBName` | `string` | Target database name |

### Relational Data
| Field | Type | Description |
|-------|------|-------------|
| `ParentID` | `string` | Parent issue ID |
| `Dependencies` | `[]string` | IDs this issue depends on |
| `Dependents` | `[]string` | IDs that depend on this issue |
| `RelatedIDs` | `[]string` | Related issue IDs |
| `DuplicateIDs` | `[]string` | Duplicate issue IDs |
| `SupersedeIDs` | `[]string` | Superseded issue IDs |
| `Labels` | `[]string` | Labels |

### Messaging
| Field | Type | Description |
|-------|------|-------------|
| `ThreadID` | `string` | Message thread ID |
| `MailDelegation` | `string` | Mail delegation target |

### Context Markers
| Field | Type | Description |
|-------|------|-------------|
| `ContextMarkers` | `[]string` | Context markers for agents |
| `Waiters` | `[]string` | Agents waiting for resolution |

### Bonding (Molecule Compounds)
| Field | Type | Description |
|-------|------|-------------|
| `BondedFrom` | `[]BondRef` | Sources this issue was bonded from |
| `BondType` | `string` | Bond type |

### Gates
| Field | Type | Description |
|-------|------|-------------|
| `GateName` | `string` | Gate name |
| `GateBlocking` | `[]string` | Issues this gate blocks |

### Source Tracing
| Field | Type | Description |
|-------|------|-------------|
| `SourceProtoID` | `string` | Source proto/template ID |
| `SpawnedFrom` | `string` | Spawning parent |

### Molecule Types
| Field | Type | Description |
|-------|------|-------------|
| `MolType` | `MolType` | Enum: none, proto, molecule, compound, digest |

### Work Types
| Field | Type | Description |
|-------|------|-------------|
| `WorkType` | `WorkType` | Enum: step, gate, parallel, decision, approval |

### Events (for message issues)
| Field | Type | Description |
|-------|------|-------------|
| `EventKind` | `string` | Event type |
| `Actor` | `string` | Event actor |
| `Target` | `string` | Event target |
| `Payload` | `string` | Event payload |
| `Timeout` | `time.Duration` | Event timeout |
| `AwaitType` | `string` | Wait type |
| `AwaitID` | `string` | Wait target ID |

### Statistics (separate from Issue struct)
| Field | Type | Description |
|-------|------|-------------|
| `TotalIssues` | `int` | Total issue count |
| `OpenIssues` | `int` | Open issues |
| `InProgressIssues` | `int` | In-progress issues |
| `BlockedIssues` | `int` | Blocked issues |
| `DeferredIssues` | `int` | Deferred issues |
| `ClosedIssues` | `int` | Closed issues |
| `ReadyIssues` | `int` | Ready to work |
| `PinnedIssues` | `int` | Pinned issues |
| `EpicsEligibleForClosure` | `int` | Epics ready to close |
| `AverageLeadTime` | `float64` | Average lead time in hours |

### Status Constants
```
StatusOpen        = "open"
StatusInProgress  = "in_progress"
StatusBlocked     = "blocked"
StatusDeferred    = "deferred"
StatusClosed      = "closed"
StatusPinned      = "pinned"
StatusHooked      = "hooked"
```

### Status Categories
```
CategoryActive  = "active"   — appears in 'bd ready' and default 'bd list'
CategoryWIP     = "wip"      — excluded from 'bd ready', visible in default 'bd list'
CategoryDone    = "done"     — excluded from both
CategoryFrozen  = "frozen"   — excluded from both
```

### Issue Type Constants
```
TypeBug, TypeTask, TypeFeature, TypeEpic, TypeChore,
TypeStory, TypeSpike, TypeTechDebt, TypeSubEpic,
TypeGate, TypeRig, TypeAspect, TypeRole, TypeAgent,
TypeMessage, TypeStory
```

---

## 3. How Dependencies Work

### Adding Dependencies
```bash
bd dep add <child> <parent>      # child depends on parent (parent blocks child)
bd dep add <child> <parent> --blocks   # reverse: child blocks parent
bd dep add -f deps.jsonl          # batch add from JSONL file
```

### Dependency Semantics
- **Blocking**: The default relationship. Parent must be closed before child is "ready."
- **Related-to**: Created via `bd link <id1> <id2>` or `bd relate <id1> relates_to <id2>`.
- **Duplicate**: `bd relate <id1> duplicates <id2>`.
- **Supersedes**: `bd relate <id1> supersedes <id2>`.
- **Parent-Child**: Hierarchical relationship (epic -> task -> sub-task).

### Dependency Checking
- `bd dep check` — Detects cycles in the dependency graph.
- `bd ready` — Lists only issues with no open blockers.
- `bd graph check` — Validates graph integrity (cycle detection).
- `bd blocked` — Shows all blocked issues.

### Dependency Resolution via Routing
- `resolveIDWithRouting()` supports cross-store resolution (e.g., `xe-5ls` references an issue in a different rig/database).
- `isChildOf()` checks hierarchical parent/child relationships between issue IDs.

### Cross-Project Dependencies
```bash
# In consuming project:
bd dep add <issue> external:<project>:<capability>

# In providing project (must ship first):
bd ship <capability>
```
The `ship` command finds an issue with `export:<capability>` label, validates it's closed, and adds `provides:<capability>` label.

---

## 4. How Beads Integrates with Git/Dolt

### Two Storage Modes

#### Embedded Mode (default)
- Dolt runs in-process (no external server needed).
- Data lives in `.beads/embeddeddolt/`.
- Single-writer only (file locking enforced).

#### Server Mode (`--server` flag)
- Connects to external `dolt sql-server`.
- Data lives in `.beads/dolt/`.
- Supports multiple concurrent writers.
- Configurable via flags or env vars:
  - `--server-host` / `BEADS_DOLT_SERVER_HOST` (default: `127.0.0.1`)
  - `--server-port` / `BEADS_DOLT_SERVER_PORT` (default: `3307`)
  - `--server-socket` / `BEADS_DOLT_SERVER_SOCKET` (Unix socket)
  - `--server-user` / `BEADS_DOLT_SERVER_USER` (default: `root`)
  - `BEADS_DOLT_PASSWORD`
  - `BEADS_DOLT_CLI_DIR` — local Dolt DB path for CLI push/pull

### Dolt Commands within Beads
```bash
bd dolt show        # Show Dolt config + connection status
bd dolt set <k> <v> # Set config keys (database, host, port, user, data-dir)
bd dolt test        # Ping the configured Dolt server
bd dolt push        # Push commits to remote
bd dolt pull        # Pull from remote
bd dolt remote add/list/remove   # Manage remotes
bd dolt commit      # Commit database changes
bd dolt start/stop  # Server lifecycle
bd dolt status      # Dolt status
```

### Auto-Commit Strategy
- `commandDidWrite` — atomic bool tracking whether any command wrote to the DB.
- `commandDidExplicitDoltCommit` — prevents redundant commits.
- `commandDidWriteTipMetadata` — separate tracking for metadata writes.
- Auto-commit on mutation commands by default.

### Git Integration
- Git hooks are managed: pre-commit, post-merge, pre-push, post-checkout, prepare-commit-msg.
- Section-based hook injection (`BEGIN BEADS INTEGRATION` / `END BEADS INTEGRATION` markers).
- User customizations outside markers are preserved.
- `bd init` sets up hooks automatically.
- Auto-detects git hook frameworks (pre-commit, Husky, lefthook, Overcommit).
- `bd sync` uses Dolt remotes for push/pull.
- Git guardrails block 12 dangerous patterns.

### Workspace & Worktree Support
- `FindBeadsDir()` resolves symlinks, worktrees, and `BEADS_DIR` override.
- Multi-workspace support via workspace redirects.

---

## 5. Hooks System

### Git Hooks (Managed)
Five hooks managed via section injection:
- `pre-commit`
- `post-merge`
- `pre-push`
- `post-checkout`
- `prepare-commit-msg`

Each hook script:
1. Checks if `bd` is on `PATH`.
2. Sets configurable timeout (default 300s, env `BEADS_HOOK_TIMEOUT`).
3. Runs `bd hooks run <hookname> "$@"`.
4. Handles exit code 3 (uninitialized DB) gracefully — logs warning, exits 0.
5. Handles timeout (exit 124) the same way.

### Claude Hooks (settings.json)
Registered in `.claude/settings.json`:
- `SessionStart` — runs `bd prime` to inject workflow context.
- `PreToolUse` — guardrails for dangerous git commands.
- `PreCompact` — runs `bd prime --memories-only` to preserve context.

### Hook Runner (`bd hooks run <hookname>`)
- Loads registered hooks from database.
- Supports plugins (loaded from `.beads/plugins/`).
- Windows compatibility (uses `cmd /c` when `os.TempDir()` contains `\`).
- Exit code propagation (preserves nonzero exits to block git operations).
- Logging to `bd-hooks.log`.

### Prime System (`bd prime`)
Outputs AI-optimized workflow context in markdown:
- **CLI mode** (~1-2k tokens): Full command reference.
- **MCP mode** (~50 tokens): Brief workflow reminders.
- **Stealth mode**: No git commands in session close protocol.
- **Memories-only**: Only persistent memories for compact hooks.

Customization priority:
1. `.beads/PRIME.md` (clone-specific local override)
2. `<beadsDir>/PRIME.md` (workspace override via redirect)
3. `~/.config/beads/PRIME.md` (user-wide global override)
4. Built-in default `outputPrimeContextWithOptions()`

MCP auto-detection reads `~/.claude/settings.json` for any key containing `"beads"` under `mcpServers`.

---

## 6. Query/Filter Capabilities

### List Filters
- `--status` — Filter by status (open, closed, in_progress, blocked, deferred, custom).
- `--type` — Filter by issue type (bug, task, feature, epic, chore, story, etc.).
- `--priority` — Filter/sort by priority.
- `--assignee` — Filter by assignee.
- `--label` / `--label-mode` — Label filtering (any, all, none).
- `--parent` / `--exclude-parent` — Parent-based filtering.
- `--created-after/before`, `--updated-after/before`, `--closed-after/before` — Date ranges.
- `--priority-min`, `--priority-max` — Priority range.
- `--desc-contains`, `--notes-contains`, `--external-contains` — Pattern matching.
- `--empty-description`, `--no-assignee`, `--no-labels` — Absence checks.
- `--metadata-field <k=v>`, `--has-metadata-key <key>` — Metadata filters.
- `--limit`, `--offset` — Pagination.
- `--sort` — Sort field (created, updated, priority, title).
- `--reverse` — Reverse sort order.
- `--all` — Include all statuses.

### Search
- Full-text search across titles.
- ID-like queries (`bd-123`) use fast exact/prefix matching.
- Same filter flags as list.
- Default excludes closed issues.

### Query Language (`bd query`)
- Text-based query syntax with predicate filtering.
- Supports OR queries, label-based conditions, explicit status filters.
- Sorting, limiting, and JSON/formatted output.

### Ready Filter
- `bd ready` automatically filters issues with no open blockers.
- `--claim` auto-claims the first ready issue.
- `--gated` finds molecules where a gate just closed.
- `--explain` provides dependency-aware reasoning.
- `--include-deferred` / `--include-ephemeral` for edge cases.

---

## 7. Validation Features

### Issue Validation
- `validation.LintIssue()` checks for missing template sections by type:
  - bug: Steps to Reproduce, Acceptance Criteria
  - task: Acceptance Criteria
  - feature: Acceptance Criteria
  - epic: Success Criteria
  - chore: (none, always passes)
- Priority validation: P0-P4 or 0-4.
- Status validation: Custom statuses validated against `status.custom` config.
- Title emptiness check.

### Config Validation
- Key validation rejects protected init-only keys.
- Unrecognized keys get warning with suggestions.
- Git safety check prevents exposure of API keys/tokens.
- `status.custom` values parsed and validated before writing.

### Gate Validation
- Gate satisfaction checking before close.
- Open blocker validation.
- Epic children completeness validation.

### Database Validation
- `bd doctor validate` — Database integrity validation.
- `bd doctor health` — Health check.
- `bd doctor repair` — Repair common issues.
- `bd doctor pollution` — Check for pollution/test records.

### Preflight Checks (8 checks)
1. Tests pass (`go test -short ./...`)
2. Lint passes (`golangci-lint run`)
3. Formatting (`gofmt -l .`)
4. Beads pollution (`.beads/issues.jsonl` not accidentally modified)
5. Nix hash freshness
6. Version sync between `version.go` and `default.nix`
7. AGENTS.md/CLAUDE.md divergence detection
8. Nix flake lock freshness

### Close Validation
- `--reason` / `--resolution` / `--message` / `--comment` validation.
- Configurable `validation.on-close` mode (error/warn).
- Guard checks before close: force, gate satisfaction, open blockers, epic-children.
- Close reason file support (`--reason-file`, read from path or stdin).

---

## 8. Workflow Formulas (mol/pour)

### Molecule System
Molecules are work templates for agent workflows. They use a phase metaphor:
- **Proto**: Uninstantiated template (`protomolecule` alias). A template epic with the "template" label defining a DAG of work.
- **Molecule**: A spawned instance of a proto — real issues created from the template.
- **Spawn**: Instantiate a proto, creating real issues from the template.
- **Bond**: Polymorphic combine operation (proto+proto, proto+mol, mol+mol).
- **Distill**: Extract ad-hoc epic into a reusable proto.
- **Compound**: Result of bonding.
- **Digest**: Squashed/condensed molecule.
- **Liquid** phase: Persistent mol in `.beads/`.
- **Vapor** phase: Ephemeral wisp (auto-deleted on close).

### Pour Command
```bash
bd mol pour <id> --var key=value     # Instantiate proto -> persistent mol
bd mol wisp <id> --var key=value     # Instantiate proto -> ephemeral wisp
```
- Variable substitution: `{{key}}` in templates replaced with `--var key=value`.
- Dry-run preview, JSON output, vapor-phase warning.

### Formula System
Formulas are the source layer (TOML files) defining molecule templates:
- Search paths: project `.beads/formulas/`, user `~/.beads/`, orchestrator `$GT_ROOT`.
- Formula types: workflow, expansion, aspect, convoy.
- Each formula has: metadata, variables, steps, extends, advice rules, compose rules, bond points.
- Lifecycle: Rig -> Cook -> Run.

### Bond Command
```bash
bd mol bond <id1> <id2>
```
Polymorphic combine operation supporting all combinations.

---

## 9. Quality Tools

### Lint
```bash
bd lint [issue-id...]
```
- Checks issues for missing template sections based on type.
- Supports filtering by `--type` and `--status`.
- Exits with code 1 if warnings found (CI-friendly).
- JSON output.

### Preflight
```bash
bd preflight
```
- Static checklist or auto-check mode via `--check`.
- 8 checks: tests, lint, formatting, pollution, version sync, docs divergence.
- JSON output for CI integration.

### Stale
```bash
bd stale
```
- Finds issues not updated in N days (configurable via `--days`, default 30).
- Filters by status, JSON output.

### Orphans
```bash
bd orphans
```
- Finds issues with no parent and no dependencies.

### Duplicates
```bash
bd duplicates
bd find-duplicates
```
- Duplicate issue detection.

### Graph Check
```bash
bd graph check
```
- Validates graph integrity by detecting cycles.
- Exit code 0 (clean) or 1 (issues found).

### Doctor
```bash
bd doctor
bd doctor --fix
```
- Comprehensive health diagnostics with auto-repair capability.
- Validates: health, artifacts, conventions, pollution, agent setup.

### Compact
```bash
bd compact [--analyze|--apply|--auto|--dolt]
```
- Tier 1: Issues closed >= 30 days, ~70% reduction (semantic compression).
- Tier 2: Issues closed >= 90 days, ~95% reduction (not yet implemented).
- Agent-driven workflow recommended: analyze -> agent writes summary -> apply.

---

## 10. Configuration Options

### Config Backends
1. **YAML** (`config.yaml`): Startup settings like `no-db`, read before database opens. Sources in priority order:
   - `~/.beads/config.yaml` (legacy)
   - `~/.config/bd/config.yaml` (user-level)
   - Project-local `.beads/config.yaml`
   - `$BEADS_DIR/config.yaml` (highest priority)
2. **Git config**: `beads.role` (stored via `git config`).
3. **SQLite database**: All other config keys (requires direct mode).
4. **Environment variables**: `BD_*` prefixed env vars override config files.

### Configuration Keys (examples)
- `status.custom` — Custom status definitions (`name:category,...` format).
- `doctor.suppress.*` — Suppress specific doctor warnings.
- `validation.on-close` — Close reason validation mode (none/warn/error).
- `beads.role` — Contributor or maintainer.
- `dolt_mode` — Embedded or server.
- Federation: remote, sovereignty, allowed patterns, type exclusions.
- Metadata schema validation.
- `no-db` — Startup flag for database-less mode.

### Config Commands
```bash
bd config set <key> <value>          # Set value
bd config get <key>                  # Get value
bd config list                       # List all
bd config unset <key>                # Unset value
bd config show                       # Show effective config
bd config apply <file>               # Apply from file
bd config drift                      # Detect config drift
```

---

## 11. How Beads is MEANT to Be Used (Development Workflow)

### For Individual Developers

1. **Initialize**: `bd init` in project root — creates `.beads/` with Dolt database.
2. **Create work**: `bd create "Task title" -p 1 -a @me -l bug` with structured descriptions.
3. **Claim work**: `bd ready --claim` — see available tasks and atomically claim one.
4. **Track progress**: `bd update bd-abc --status in_progress` or `bd done bd-abc` to close.
5. **Add context**: `bd remember "key insight"` for persistent notes; `bd prime` injects them each session.
6. **Review state**: `bd status` for overview; `bd list` for filtered views.
7. **Manage dependencies**: `bd dep add <child> <parent>` to define blocking relationships.
8. **Sync**: `bd dolt push/pull` for remote collaboration.

### For AI Agents (Primary Use Case)

Beads is designed specifically for AI coding agents:

1. **Session start**: `bd prime` automatically runs via SessionStart hook, injecting workflow context + all `bd remember` memories into the agent's context window.
2. **Find work**: Agent runs `bd ready` to find unblocked tasks.
3. **Claim work**: Agent runs `bd update <id> --claim` to atomically claim a task (sets assignee + in_progress).
4. **Develop**: Agent follows task description, commits code.
5. **Close**: Agent runs `bd close <id>` when done (auto-suggests next steps).
6. **Persist knowledge**: Agent uses `bd remember "insight"` instead of writing MEMORY.md files.
7. **Pre-compact**: `bd prime --memories-only` runs to preserve critical context before compaction.
8. **Session close**: Agent commits all changes, runs quality gates, pushes.

### For Teams

1. **Distributed via Dolt remotes**: Multiple agents/developers sync through Dolt's Git-like branching.
2. **Zero conflict**: Hash-based IDs (`bd-a1b2`) prevent merge collisions.
3. **Multi-branch workflow**: Agents work on separate branches, merge via Dolt.
4. **Federation**: Cross-project dependencies via `bd ship` and `bd dep add external:...`.
5. **Gates**: Async coordination via `bd gate` for human-in-the-loop or timer-based gates.

### Best Practices (Inferred from CLI Design)

- **Use structured descriptions**: Include design notes, acceptance criteria, required skills, context sections.
- **Templates for consistency**: Create proto/molecules for repeatable work patterns.
- **Dependency-aware planning**: Use `bd dep add` to define work order, then `bd ready` shows what's actionable.
- **Compact old work**: Periodically run `bd compact` to summarize completed issues and save context window.
- **Export for safety**: `bd export -o backup.jsonl` for outside-Dolt portability.
- **Use `bd doctor --fix`** for routine maintenance before manual admin commands.
- **Lint before closing**: `bd lint` catches missing sections before work is marked done.
- **Stealth mode for personal use**: `bd init --stealth` on shared projects avoids committing beads files.
- **Agent workflow**: Prefer `bd remember` over MEMORY.md files; `bd prime` auto-injects all memories.
