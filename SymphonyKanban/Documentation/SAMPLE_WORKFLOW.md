# Sample `WORKFLOW.md`

This file is a documentation sample for Symphony's workflow contract.

It is based on concrete evidence from:

- Current implementation:
  - `SymphonyKanban/Infrastructure/PortAdapters/Symphony/SymphonyWorkflowLoaderPortAdapter.swift`
  - `SymphonyKanban/Infrastructure/PortAdapters/Symphony/SymphonyConfigResolverPortAdapter.swift`
  - `SymphonyKanban/Infrastructure/Translation/Models/Symphony/SymphonyConfigPathModel.swift`
  - `SymphonyKanban/Infrastructure/Translation/Models/Symphony/SymphonyPromptTemplateModels.swift`
  - `SymphonyKanban/Infrastructure/Translation/Models/Symphony/SymphonyCodexConfigurationModel.swift`
  - `SymphonyKanban/Infrastructure/Gateways/Symphony/SymphonyWorkspaceLifecycleGateway.swift`
  - `SymphonyKanban/Infrastructure/PortAdapters/Symphony/ValidateSymphonyStartupConfigurationPortAdapter.swift`
- Local tests:
  - `SymphonyKanbanTests/Infrastructure/Symphony/SymphonyWorkflowResolverPortAdapterTests.swift`
  - `SymphonyKanbanTests/SymphonyWorkflowFrontMatterParserTests.swift`
- Repository docs/spec:
  - `SymphonyKanban/Documentation/SYMPHONY_SERVICE_SPECIFICATION.md`
  - `SymphonyKanban/Documentation/SYMPHONY_PHASE_PLAN.md`

Important note:

- This sample follows the current codebase, not every historical field name in the spec docs.
- Where the docs and code disagree, this file favors the code that currently runs.

## Verified Sample

```md
---
# Top-level section: tracker
# Purpose: tells Symphony which Linear scope to watch and which state types count as active/terminal.
tracker:
  # Required at startup.
  # Current startup validation only accepts: linear
  kind: linear

  # Optional.
  # If omitted and kind == linear, the runtime defaults to:
  # https://api.linear.app/graphql
  endpoint: https://api.linear.app/graphql

  # Use exactly one of project_slug or team_id.
  # Startup validation fails if both are missing or both are present.
  project_slug: "<your-linear-project-slug>"
  # team_id: "<your-linear-team-id>"

  # Optional.
  # Current code uses these exact field names:
  # active_state_types and terminal_state_types
  #
  # Defaults when omitted:
  # active_state_types: [backlog, unstarted, started]
  # terminal_state_types: [completed, canceled]
  active_state_types:
    - backlog
    - unstarted
    - started
  terminal_state_types:
    - completed
    - canceled

# Top-level section: polling
# Purpose: how often Symphony checks for work.
polling:
  # Optional.
  # Integer or string integer.
  # Default: 30000
  interval_ms: 30000

# Top-level section: workspace
# Purpose: where issue workspaces live on disk.
workspace:
  # Optional.
  # Default: <system-temp>/symphony_workspaces
  #
  # Current code expands:
  # - ~
  # - $VARNAME for workspace.root only
  #
  # Current code does NOT expand $VARNAME in tracker.endpoint or codex.command.
  root: ~/symphony-workspaces

# Top-level section: hooks
# Purpose: shell scripts Symphony runs around workspace lifecycle.
hooks:
  # Optional.
  # Runs only when the workspace directory is created for the first time.
  # Failure aborts workspace preparation.
  after_create: |
    echo "Workspace created"

  # Optional.
  # Runs before each agent attempt.
  # Failure aborts the current attempt.
  before_run: |
    echo "About to start Codex"

  # Optional.
  # Runs after each attempt.
  # Failure is logged and ignored.
  after_run: |
    echo "Codex run finished"

  # Optional.
  # Runs before workspace deletion.
  # Failure is logged and ignored.
  before_remove: |
    echo "Removing workspace"

  # Optional.
  # Default: 60000
  # Non-positive values fall back to the default.
  timeout_ms: 60000

# Top-level section: agent
# Purpose: controls Symphony worker concurrency and retry behavior.
agent:
  # Optional.
  # Integer or string integer.
  # Default: 10
  max_concurrent_agents: 10

  # Optional.
  # Integer or string integer.
  # Default: 20
  max_turns: 20

  # Optional.
  # Integer or string integer.
  # Default: 300000
  max_retry_backoff_ms: 300000

  # Optional.
  # Map of state name -> positive integer.
  # Invalid or non-positive values are ignored.
  # Keys are normalized to lowercase for lookup.
  max_concurrent_agents_by_state:
    backlog: 2
    started: 4

# Top-level section: codex
# Purpose: controls how Symphony starts Codex and how turns are sandboxed/timed.
codex:
  # Optional.
  # Default: codex app-server
  #
  # Current code preserves this as a literal shell command string.
  # It does not expand $VARNAME here.
  command: "codex app-server"

  # Optional.
  # Pass-through Codex field.
  # Accepted values are owned by the installed Codex app-server schema,
  # not by Symphony's local config parser.
  approval_policy: "<Codex AskForApproval value>"

  # Optional.
  # Pass-through Codex field.
  # If omitted, Symphony's current runtime default is workspaceWrite.
  thread_sandbox: "<Codex SandboxMode value>"

  # Optional.
  # Raw object preserved by the workflow resolver, then partially interpreted
  # by the current Codex session builder.
  turn_sandbox_policy:
    # Current session builder reads this key:
    type: "<Codex SandboxPolicy.type value>"

    # Current session builder reads this key:
    # if omitted or empty, it defaults to the current workspace path.
    writableRoots:
      - "/absolute/path/allowed/to/write"

    # Current session builder reads this key:
    # bool or string bool
    networkAccess: false

    # Current session builder preserves this raw config key:
    access: null

    # Current session builder preserves this raw config key:
    readOnlyAccess: null

  # Optional.
  # Default: 3600000
  turn_timeout_ms: 3600000

  # Optional.
  # Default: 5000
  read_timeout_ms: 5000

  # Optional.
  # Default: 300000
  # When <= 0, the current runtime disables stall detection.
  stall_timeout_ms: 300000
---

# Prompt Template

You are working on Linear issue {{ issue.identifier }}: {{ issue.title }}.

Current state: {{ issue.state }}
Attempt: {{ attempt }}

{% for label in issue.labels %}
- Label: {{ label }}
{% endfor %}

{% for blocker in issue.blockedBy %}
- Blocked by: {{ blocker.identifier }} (state: {{ blocker.state }})
{% endfor %}

Issue URL: {{ issue.url }}
Branch name: {{ issue.branchName }}

Description:
{{ issue.description }}
```

## Prompt Template Values Verified In Code

The current prompt renderer supports these root variables:

- `issue`
- `attempt`

The current prompt context exposes these `issue.*` fields:

- `issue.id`
- `issue.identifier`
- `issue.title`
- `issue.description`
- `issue.priority`
- `issue.state`
- `issue.branchName`
- `issue.url`
- `issue.labels`
- `issue.blockedBy`
- `issue.createdAt`
- `issue.updatedAt`

The current prompt context exposes these blocker fields inside `issue.blockedBy`:

- `blocker.id`
- `blocker.identifier`
- `blocker.state`

The current prompt syntax verified in code is:

- Variable output:
  - `{{ issue.title }}`
  - `{{ attempt }}`
- Loops:
  - `{% for label in issue.labels %} ... {% endfor %}`
  - `{% for blocker in issue.blockedBy %} ... {% endfor %}`

Strict behavior verified in code:

- Unknown variables fail rendering.
- Unknown filters fail rendering.
- Filters are not implemented as a supported feature in the current local renderer.
- If the prompt body is empty, the current fallback prompt is:
  - `You are working on an issue from Linear.`

## Current Code vs Historical/Spec Documentation

These items are documented in repo docs or older planning/spec material, but are not clearly wired in the current local implementation shown above, so they are intentionally not used in the sample:

- `tracker.active_states`
  - Historical docs mention this name.
  - Current code uses `tracker.active_state_types`.
- `tracker.terminal_states`
  - Historical docs mention this name.
  - Current code uses `tracker.terminal_state_types`.
- `server.port`
  - Documented as an optional extension in repo docs/spec.
  - No current local workflow config resolver support was found.
- `worker.ssh_hosts`
  - Documented in repo docs/spec as an optional extension.
  - No current local workflow config resolver support was found.
- `worker.max_concurrent_agents_per_host`
  - Documented in repo docs/spec as an optional extension.
  - No current local workflow config resolver support was found.
- `linear_graphql`
  - Mentioned in repo docs/spec as an optional tool extension.
  - It is not a `WORKFLOW.md` config field implemented by the current workflow resolver.

## Practical Rules Backed By Current Code

- `WORKFLOW.md` path resolution order:
  - explicit runtime path first
  - otherwise `./WORKFLOW.md`
- Unknown top-level keys are ignored by the current config resolver.
- `tracker.kind` is required for startup validation.
- Current startup validation only accepts `linear`.
- Current startup validation requires exactly one of:
  - `tracker.project_slug`
  - `tracker.team_id`
- `codex.command` must not be empty.
- `workspace.root` is the only field in the verified config surface where the current code clearly expands `$VARNAME`.
- The current code preserves `codex.command` and `tracker.endpoint` literally, even if they start with `$`.
