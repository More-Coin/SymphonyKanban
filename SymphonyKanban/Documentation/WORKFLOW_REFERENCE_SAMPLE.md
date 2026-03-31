# WORKFLOW.md Reference Sample

This document is an evidence-backed sample for Symphony's current `WORKFLOW.md` format.

It is based on:

- The current local codebase on this branch.
- The local spec in `SymphonyKanban/Documentation/SYMPHONY_SERVICE_SPECIFICATION.md`.
- A GitHub cross-check of the repository spec and config resolver.

Important note about source drift:

- The GitHub `main` branch currently still documents older tracker keys such as `tracker.active_states` and `tracker.terminal_states`.
- The current local app code and the local spec on this branch use `tracker.active_state_types` and `tracker.terminal_state_types`, and they also support `tracker.team_id`.
- This sample follows the current local implementation so it matches the app you are running now.

## What This File Covers

- The verified top-level sections currently consumed by Symphony.
- The verified keys inside each section.
- The verified prompt-template syntax and variables.
- The spec-documented extensions I could find, clearly marked when I did not find local implementation evidence.

## Verified Top-Level Sections

These are the top-level front-matter objects the current resolver reads:

- `tracker`
- `polling`
- `workspace`
- `hooks`
- `agent`
- `codex`

Unknown top-level keys are ignored by the current resolver because it only reads the sections above.

## Runnable-Style Example

This is a sample of the current supported shape. It is meant as a reference example, not as a guarantee that every placeholder value below is appropriate for your environment.

```md
---
tracker:
  kind: linear
  endpoint: https://api.linear.app/graphql
  project_slug: your-project-slug
  # team_id: your-linear-team-id
  active_state_types:
    - backlog
    - unstarted
    - started
  terminal_state_types:
    - completed
    - canceled

polling:
  interval_ms: 30000

workspace:
  root: ~/symphony_workspaces

hooks:
  after_create: |
    echo "Workspace created for this issue."
  before_run: |
    echo "About to launch Codex for this issue."
  after_run: |
    echo "Codex attempt finished."
  before_remove: |
    echo "Removing workspace for terminal issue."
  timeout_ms: 60000

agent:
  max_concurrent_agents: 10
  max_turns: 20
  max_retry_backoff_ms: 300000
  max_concurrent_agents_by_state:
    backlog: 2
    unstarted: 4
    started: 6

codex:
  command: codex app-server
  # approval_policy is passed straight through to Codex.
  # Verified local literals include:
  # - never
  # - unlessTrusted
  # Other valid values depend on the installed Codex app-server schema.
  approval_policy: unlessTrusted
  thread_sandbox: workspaceWrite
  turn_sandbox_policy:
    type: workspaceWrite
    writableRoots:
      - ~/symphony_workspaces
    networkAccess: false
    readOnlyAccess: true
  turn_timeout_ms: 3600000
  read_timeout_ms: 5000
  stall_timeout_ms: 300000
---
# Symphony Prompt

You are working on {{ issue.identifier }}: {{ issue.title }}

Current state: {{ issue.state }}
Attempt: {{ attempt }}

Description:
{{ issue.description }}

Labels:
{% for label in issue.labels %}
- {{ label }}
{% endfor %}

Blockers:
{% for blocker in issue.blockedBy %}
- {{ blocker.identifier }} (state: {{ blocker.state }})
{% endfor %}

If a branch name is available, prefer using it:
{{ issue.branchName }}
```

## Field-By-Field Reference

### `tracker`

- `kind`
  - Required for startup and dispatch.
  - Current supported value in local code: `linear`.
  - Used by Symphony to decide which tracker adapter rules to use.

- `endpoint`
  - Optional.
  - Defaults to `https://api.linear.app/graphql` when `kind` is `linear`.
  - Used by the Linear adapter.

- `project_slug`
  - Optional by itself, but one tracker scope is required overall.
  - Current startup validation requires exactly one of:
    - `project_slug`
    - `team_id`
  - If neither is set, startup validation fails.
  - If both are set, startup validation fails.

- `team_id`
  - Optional by itself, but one tracker scope is required overall.
  - Current startup validation requires exactly one of:
    - `project_slug`
    - `team_id`
  - Used for team-scoped Linear queries and workflow-state lookup during issue updates.

- `active_state_types`
  - Optional.
  - Default: `["backlog", "unstarted", "started"]`
  - These are Linear semantic state types, not display labels.
  - Used for candidate fetching, eligibility checks, retries, and continuation logic.

- `terminal_state_types`
  - Optional.
  - Default: `["completed", "canceled"]`
  - These are Linear semantic state types, not display labels.
  - Used for eligibility, reconciliation, cleanup, and startup terminal cleanup.

### `polling`

- `interval_ms`
  - Optional.
  - Default: `30000`
  - Controls how often Symphony runs the dispatch tick.
  - Reloading the workflow can change the live poll cadence for future ticks.

### `workspace`

- `root`
  - Optional.
  - Default: `<system temp>/symphony_workspaces`
  - Supports:
    - `~`
    - `$VAR`
    - normal path standardization
  - Used to decide where per-issue workspaces are created.

### `hooks`

- `after_create`
  - Optional multiline shell script.
  - Runs only when a workspace directory is newly created.
  - Failure is fatal to workspace creation.

- `before_run`
  - Optional multiline shell script.
  - Runs before each agent attempt.
  - Failure is fatal to the current attempt.

- `after_run`
  - Optional multiline shell script.
  - Runs after each attempt.
  - Failure is logged and ignored.

- `before_remove`
  - Optional multiline shell script.
  - Runs before workspace cleanup.
  - Failure is logged and ignored.

- `timeout_ms`
  - Optional.
  - Default: `60000`
  - Applies to all hooks.
  - Non-positive values fall back to the default in the current resolver.

### `agent`

- `max_concurrent_agents`
  - Optional.
  - Default: `10`
  - Controls global dispatch capacity.

- `max_turns`
  - Optional.
  - Default: `20`
  - Limits how many back-to-back turns one worker can take before it stops continuing the same issue.

- `max_retry_backoff_ms`
  - Optional.
  - Default: `300000`
  - Caps retry backoff delay.

- `max_concurrent_agents_by_state`
  - Optional map of `state_name -> positive integer`.
  - Default: empty map.
  - Keys are normalized to lowercase in the current resolver.
  - Invalid and non-positive entries are ignored.

### `codex`

- `command`
  - Optional.
  - Default: `codex app-server`
  - Used as the shell command to launch the Codex app-server process.
  - The current resolver attempts to resolve the executable via login-shell lookup before launch.

- `approval_policy`
  - Optional.
  - Passed through to Codex for both thread start and turn start.
  - The current codebase does not define a full enum of allowed values in the workflow layer.
  - Verified local literals from the current approval posture:
    - `never`
    - `unlessTrusted`
  - Additional valid values depend on the installed Codex app-server schema and should not be guessed.

- `thread_sandbox`
  - Optional.
  - Passed through to Codex thread start.
  - Verified local default if not set after normalization: `workspaceWrite`
  - Verified local literal in code: `workspaceWrite`

- `turn_sandbox_policy`
  - Optional object.
  - Passed through to Codex turn start.
  - Verified supported subkeys in local code:
    - `type`
    - `writableRoots`
    - `networkAccess`
    - `access`
    - `readOnlyAccess`
  - Verified synthesized default if the whole object is omitted:
    - `type: workspaceWrite`
    - `writableRoots: [workspacePath]`
    - `networkAccess: false`

- `turn_timeout_ms`
  - Optional.
  - Default: `3600000`
  - Used in the Codex session startup contract.

- `read_timeout_ms`
  - Optional.
  - Default: `5000`
  - Used in the Codex session startup contract.

- `stall_timeout_ms`
  - Optional.
  - Default: `300000`
  - Used by Symphony's own stall detection.
  - This is runtime behavior in Symphony, not a field sent directly into the Codex request factory.
  - If `<= 0`, stall detection is effectively disabled in the runtime.

## Prompt Template Reference

The Markdown body of `WORKFLOW.md` is the prompt template.

If the prompt body is empty, Symphony falls back to:

```text
You are working on an issue from Linear.
```

### Verified Prompt Syntax

The current local prompt parser supports:

- Variable interpolation:
  - `{{ issue.identifier }}`
  - `{{ attempt }}`

- `for` loops:
  - `{% for label in issue.labels %}...{% endfor %}`

### Verified Prompt Variables

These are the exact prompt variables I could verify in the current local context builder:

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
- `attempt`

### Verified Nested Loop Variables

Inside `{% for blocker in issue.blockedBy %}`, the current local code exposes:

- `blocker.id`
- `blocker.identifier`
- `blocker.state`

### Things I Did Not Verify, So They Are Not Included As Supported

- `if` / `else` prompt conditionals
- Built-in filters such as `upcase`
- `issue.stateType`
- `blocker.stateType`

In fact, the current renderer explicitly fails unknown filters.

## Spec-Documented Extensions With No Local Swift Implementation Evidence

The local spec mentions some optional extensions, but I did not find local Swift implementation evidence for them in the current codebase:

- `server.port`
- `worker.ssh_hosts`
- `worker.max_concurrent_agents_per_host`

Because I could not verify local implementation, they are not included in the runnable-style example above.

## Evidence Summary

Primary local implementation evidence:

- `SymphonyKanban/Infrastructure/PortAdapters/Symphony/SymphonyConfigResolverPortAdapter.swift`
- `SymphonyKanban/Application/Contracts/Workflow/Symphony/SymphonyServiceConfigContract.swift`
- `SymphonyKanban/Infrastructure/PortAdapters/Symphony/ValidateSymphonyStartupConfigurationPortAdapter.swift`
- `SymphonyKanban/Infrastructure/Translation/Models/Symphony/SymphonyConfigPathModel.swift`
- `SymphonyKanban/Infrastructure/Gateways/Symphony/SymphonyWorkspaceLifecycleGateway.swift`
- `SymphonyKanban/Infrastructure/Translation/Models/Symphony/SymphonyPromptTemplateModels.swift`
- `SymphonyKanban/Infrastructure/PortAdapters/Symphony/SymphonyPromptRendererPortAdapter.swift`
- `SymphonyKanban/Application/UseCases/Symphony/Workflow/RenderSymphonyPromptUseCase.swift`
- `SymphonyKanban/Infrastructure/Translation/Models/Symphony/SymphonyCodexConfigurationModel.swift`
- `SymphonyKanban/Infrastructure/PortAdapters/Symphony/SymphonyCodexRequestFactoryPortAdapter.swift`
- `SymphonyKanban/Infrastructure/PortAdapters/Symphony/SymphonyCodexCommandResolverPortAdapter.swift`
- `SymphonyKanban/Application/Services/Symphony/SymphonyOrchestratorRuntimeService.swift`
- `SymphonyKanban/Infrastructure/Gateways/Symphony/SymphonyWorkflowReloadMonitorGateway.swift`

Primary local documentation evidence:

- `SymphonyKanban/Documentation/SYMPHONY_SERVICE_SPECIFICATION.md`

Prompt behavior test evidence:

- `SymphonyKanbanTests/Infrastructure/Symphony/SymphonyPromptRendererPortAdapterTests.swift`
- `SymphonyKanbanTests/Application/Symphony/SymphonyOrchestratorWorkflowReloadTests.swift`

GitHub cross-check result:

- The GitHub repository spec and resolver were checked, but the current local branch is ahead of `main` for workflow key names.
- Where GitHub `main` and local code disagreed, this document follows the current local code and local spec.
