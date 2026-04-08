# Symphony Phase Checklist

Use this document as the execution checklist for Symphony delivery. Each phase keeps the original scope, acceptance gates, verification expectations, and repo-specific constraints, but the work is now organized as actionable checklist items.

## Phase 1. Package Topology and Workflow/Config Foundation

**Goal**

- Establish a Symphony-specific product topology without destabilizing the existing architecture-linter product.
- Implement the minimum startup foundation required by the spec:
  - workflow file discovery
  - front-matter parsing
  - forward-compatible typed config resolution across the full core field surface
  - startup validation
  - clean CLI error surfacing
  - baseline operator-visible startup/config failure reporting

**Why this phase boundary exists**

- `Package.swift` is currently curated for a single executable target and one Domain library target.
- A substantial Symphony runtime cannot be added cleanly until the target topology is settled.
- The layer READMEs require:
  - App-only startup/DI
  - Presentation-owned CLI parsing/rendering
  - Application-owned orchestration
- Workflow/config loading is the smallest reviewable slice that exercises those boundaries correctly without mixing in tracker, workspace, or Codex subprocess work.

**Expected touched areas**

- `Package.swift`
- `Codex Symphony Kanban/App/**`
- `Codex Symphony Kanban/Application/Contracts/Workflow/**`
- `Codex Symphony Kanban/Application/Contracts/Ports/**`
- `Codex Symphony Kanban/Application/Ports/Protocols/**`
- `Codex Symphony Kanban/Application/UseCases/**`
- `Codex Symphony Kanban/Application/Services/**`
- `Codex Symphony Kanban/Infrastructure/PortAdapters/**`
- `Codex Symphony Kanban/Infrastructure/Errors/**`
- `Codex Symphony Kanban/Presentation/DTOs/**`
- `Codex Symphony Kanban/Presentation/Controllers/**`
- `Codex Symphony Kanban/Presentation/Renderers/**`
- `Codex Symphony Kanban/Presentation/Errors/**`
- `Tests/**`

**Implementation checklist**

- [x] `1.1` Decide and implement Symphony package topology.
  - [x] Preserve `architecture-linter`.
  - [x] Add a Symphony executable path.
  - [x] Add a reusable Symphony target/test topology that avoids file-by-file `Package.swift` churn.
- [x] `1.2` Implement `WORKFLOW.md` loader and typed config layer.
  - [x] Support explicit runtime path resolution.
  - [x] Support default `./WORKFLOW.md` resolution.
  - [x] Parse YAML front matter.
  - [x] Extract prompt/body content.
  - [x] Resolve `$VAR` values.
  - [x] Support `~` and path expansion where applicable.
  - [x] Apply defaults and coercion.
  - [x] Ignore unknown top-level keys for forward compatibility.
  - [x] Keep typed loader failures explicit for:
    - `missing_workflow_file`
    - `workflow_parse_error`
    - `workflow_front_matter_not_a_map`
  - [x] Implement config precedence as:
    - workflow path selection from runtime setting, otherwise `./WORKFLOW.md`
    - YAML front matter values
    - `$VAR_NAME` indirection inside selected YAML values
    - built-in defaults
  - [x] Make the typed config surface explicit and acceptance-tested for:
    - `tracker.kind`
    - `tracker.endpoint`
    - `tracker.project_slug`
    - `tracker.active_state_types`
    - `tracker.terminal_state_types`
    - `polling.interval_ms`
    - `workspace.root`
    - `hooks.after_create`
    - `hooks.before_run`
    - `hooks.after_run`
    - `hooks.before_remove`
    - `hooks.timeout_ms`
    - `agent.max_concurrent_agents`
    - `agent.max_turns`
    - `agent.max_retry_backoff_ms`
    - `agent.max_concurrent_agents_by_state`
    - `codex.command`
    - `codex.approval_policy`
    - `codex.thread_sandbox`
    - `codex.turn_sandbox_policy`
    - `codex.turn_timeout_ms`
    - `codex.read_timeout_ms`
    - `codex.stall_timeout_ms`
  - [x] Lock exact defaults/coercion behavior where the spec defines them:
    - `tracker.endpoint` defaults to `https://api.linear.app/graphql` when `tracker.kind == "linear"`
    - `tracker.active_state_types` defaults to `["backlog", "unstarted", "started"]`
    - `tracker.terminal_state_types` defaults to `["completed", "canceled"]`
    - `polling.interval_ms` defaults to `30000` and accepts integer or string integer input
    - `workspace.root` defaults to `<system-temp>/symphony_workspaces`
    - `hooks.timeout_ms` defaults to `60000` and non-positive values fall back to the default
    - `agent.max_concurrent_agents` defaults to `10` and accepts integer or string integer input
    - `agent.max_turns` defaults to `20`
    - `agent.max_retry_backoff_ms` defaults to `300000` and accepts integer or string integer input
    - `agent.max_concurrent_agents_by_state` defaults to `{}` and ignores invalid entries
    - `codex.command` defaults to `codex app-server`
    - `codex.turn_timeout_ms` defaults to `3600000`
    - `codex.read_timeout_ms` defaults to `5000`
    - `codex.stall_timeout_ms` defaults to `300000` and disables stall detection when `<= 0`
  - [x] Expand `~` and `$VAR` only for filesystem-path values, preserve bare relative `workspace.root` names that have no path separators, and do not rewrite arbitrary URIs or shell command strings such as `tracker.endpoint` or `codex.command`.
  - [x] Treat legacy `tracker.api_key` input as ignored for interactive Linear auth, and keep secrets out of logs.
  - [x] Normalize `agent.max_concurrent_agents_by_state` keys to lowercase for lookup and ignore invalid entries while preserving global fallback behavior.
  - [x] Keep `codex.approval_policy`, `codex.thread_sandbox`, and `codex.turn_sandbox_policy` as pass-through Codex-owned config values unless the repo explicitly chooses stricter local validation.
  - Accepted `2026-03-21`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift test --package-path .`
  - Assumptions and remaining low-severity follow-ups:
    - `codex.approval_policy` and `codex.thread_sandbox` remain pass-through optional strings in the typed config layer.
    - `codex.turn_sandbox_policy` remains raw `SymphonyConfigValueContract?` pass-through until the downstream runtime payload contract is implemented.
    - The typed config layer now leaves `tracker.endpoint` unset for non-Linear trackers, while the Linear gateway keeps its boundary-local fallback to the default Linear endpoint.
- [x] `1.3` Wire startup flow.
  - [x] Run startup validation.
  - [x] Map typed failures.
  - [x] Keep CLI parsing/rendering in Presentation.
  - [x] Keep DI/bootstrap in App.
  - [x] Do not add tracker polling or worker execution yet.
  - [x] Distinguish startup validation from per-tick dispatch preflight validation so startup failure exits cleanly, while later per-tick failures only skip dispatch and keep reconciliation active.
  - [x] Validate the startup dispatch prerequisites required by the spec:
    - workflow file can be loaded and parsed
    - `tracker.kind` is present and supported
    - `tracker.project_slug` is present when required by the tracker kind
    - tracker auth/session status is connected and not stale
    - `codex.command` is present and non-empty
  - [x] Treat workflow/config read and YAML failures as new-dispatch blockers until fixed; do not treat prompt-template failures the same way.
  - Accepted `2026-03-21`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --product symphony`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift test --package-path .`
  - Assumptions and remaining low-severity follow-ups:
    - `SymphonyDispatchPreflightValidationService` reuses `ValidateSymphonyStartupConfigurationUseCase` internally; the behavior split is explicit at the service/result boundary, while the validation rule set remains shared.
    - The non-fatal dispatch-preflight path is modeled as an Application contract/result now, but the actual poll/reconciliation loop that consumes it remains Phase 4 work.
    - Prompt-template parse/render failures remain deferred until the template engine exists, and current tests only prove prompt-template content is not treated as a startup/preflight blocker.
- [x] `1.4` Add baseline structured logging and failure surfacing.
  - [x] Surface startup/config parse failures.
  - [x] Surface validation failures.
  - [ ] Surface workflow reload failures once reload exists.
  - [x] Keep a stable issue-free service lifecycle log format for operator visibility.
  - [x] Use stable `key=value` phrasing with concise reasons for startup/config failures, and avoid logging raw payloads or secrets by default.
  - [ ] Surface clean host-lifecycle exit status once the long-running runtime exists:
    - success when the application starts and shuts down normally
    - nonzero when startup fails or the host process exits abnormally
  - Accepted `2026-03-21`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift build --package-path . --product symphony`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift test --package-path .`
  - Assumptions and remaining low-severity follow-ups:
    - Baseline startup failure surfacing now uses stable `key=value` output with concise `reason="..."` messaging, but reload-failure surfacing remains deferred until the live reload path exists in Phase 4.
    - The executable/runtime smoke coverage now proves the App wiring path through `SymphonyCLIDI.makeRuntime().run(arguments:)`, but the long-running host lifecycle and exit-status reporting remain deferred until the host runtime exists.

**Phase completion checklist**

- [x] A distinct Symphony executable path exists and builds alongside the existing linter.
- [x] The Phase `1.1` topology decision is explicit, not a placeholder.
- [x] Explicit workflow path and default `./WORKFLOW.md` resolution both work.
- [x] Missing file, invalid YAML, non-map front matter, missing required dispatch config, and invalid `codex.command` surface typed failures.
- [x] Unknown top-level front-matter keys do not break parsing.
- [x] Operators can see startup/config/load failures through the baseline logging/failure sink without attaching a debugger.
- [x] Existing linter behavior remains intact.
- [x] The full core workflow/config surface is represented explicitly in the typed layer, including defaults, coercion rules, path-only expansion, and pass-through Codex-owned values.
- [x] Interactive Linear readiness no longer depends on `tracker.api_key`, and legacy key input is ignored without exposing secret values.
- [x] Startup validation vs per-tick dispatch preflight validation is explicit and testable rather than implied.
- [x] Workflow/config read and YAML errors are defined as dispatch blockers until corrected.
- [x] CLI workflow-path semantics are explicit:
  - optional positional workflow path argument
  - default `./WORKFLOW.md`
  - clean typed failure on nonexistent explicit path or missing default file

**Verification checklist**

- [x] Add focused tests for:
  - [x] package/CLI startup
  - [x] workflow parsing
  - [x] config defaults/coercion
  - [x] env/path resolution
  - [x] typed error cases
  - [x] baseline startup failure surfacing
  - [x] Extend Phase 1 tests to cover:
  - [x] full core config field coverage and default values
  - [x] config precedence ordering
  - [x] path expansion on filesystem-path values only
  - [x] legacy `tracker.api_key` input is ignored for interactive Linear auth
  - [x] lowercase normalization and invalid-entry ignoring for `agent.max_concurrent_agents_by_state`
  - [x] CLI explicit path vs default `./WORKFLOW.md` behavior
- [x] Run `swift test --package-path .`
- [x] Run `swift run --package-path . architecture-linter .`
- [x] Add a Symphony-specific startup smoke check after the executable exists.

**Phase checkpoint**

- Phase 1 accepted `2026-03-21`.
- Final verification:
  - `swift run --package-path . architecture-linter .`
  - `swift build --package-path . --target SymphonyRuntime`
  - `swift build --package-path . --product symphony`
  - `swift test --package-path . --filter SymphonyRuntimeTests`
  - `swift test --package-path .`
- Deferred low-severity follow-ups:
  - Workflow reload failure surfacing remains tied to the reload implementation in Phase 4.
  - Clean long-running host lifecycle exit reporting remains tied to the host/runtime lifecycle work in later phases.

**Risks / notes**

- The package-topology choice is the main rework lever in the whole plan, so `1.1` must settle it cleanly.
- The spec assumes a repo-owned `WORKFLOW.md`, but this repo currently has none, so fixtures/examples and default-path semantics need deliberate coverage.
- Dynamic reload is required for conformance. Phase 1 should build the loader/validation foundation, and Phase 4 must complete the live watch/re-read/re-apply behavior.
- Codex-owned config fields should remain pass-through by default; avoid hand-maintained local enums unless the repo explicitly accepts that maintenance cost.

**Dependencies**

- [x] Start here first.
- [x] Complete before later phases.

## Phase 2. Issue Intake, Workspace Safety, and Prompt Construction Foundation

**Goal**

- Build the normalized issue/workspace surface plus the concrete tracker/workspace/prompt prerequisites the runner and orchestrator will need.

**Why this phase boundary exists**

- These concerns map cleanly onto the repo’s layer split:
  - Domain for stable issue concepts and pure policies
  - Infrastructure for Linear access, template adapters, hook execution, and filesystem behavior
  - Application for focused use cases and orchestration services that stay platform-agnostic
- They can be verified independently from the Codex app-server protocol and independently from the long-running orchestrator.

**Expected touched areas**

- `Codex Symphony Kanban/Domain/Entities/**`
- `Codex Symphony Kanban/Domain/ValueObjects/**`
- `Codex Symphony Kanban/Domain/Policies/**`
- `Codex Symphony Kanban/Domain/Protocols/**`
- `Codex Symphony Kanban/Application/Contracts/Workflow/**`
- `Codex Symphony Kanban/Application/Contracts/Ports/**`
- `Codex Symphony Kanban/Application/Ports/Protocols/**`
- `Codex Symphony Kanban/Application/UseCases/**`
- `Codex Symphony Kanban/Application/Services/**`
- `Codex Symphony Kanban/Infrastructure/Gateways/**`
- `Codex Symphony Kanban/Infrastructure/PortAdapters/**`
- `Codex Symphony Kanban/Infrastructure/Translation/DTOs/**`
- `Codex Symphony Kanban/Infrastructure/Translation/Models/**`
- `Codex Symphony Kanban/Infrastructure/Errors/**`
- `Tests/**`

**Implementation checklist**

- [x] `2.1` Add stable normalized issue/workspace concepts and pure policies.
  - [x] Define issue normalization model.
  - [x] Add workspace-key sanitization.
  - [x] Add blocker eligibility rules.
  - [x] Add priority/creation-date dispatch ordering.
  - [x] Add pure backoff helpers only where they remain runtime-independent.
  - Accepted `2026-03-21`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift test --package-path .`
  - Follow-up accepted `2026-03-21`: reorganized `Domain/Policies` into `Linter` and `Symphony` subdirectories to separate architecture policies from Symphony domain policies without changing policy behavior.
  - Follow-up verification:
    - `swift test --package-path .`
    - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - `state type` blocker eligibility currently treats missing blocker state as non-terminal.
    - Dispatch ordering currently sorts `created_at == nil` after known dates.
    - `identifier` is the spec tie-break and `id` is used only as a deterministic final fallback.
    - Sanitized workspace-key collision handling remains deferred until workspace-management work in `2.3`.
- [x] `2.2` Implement Linear read adapter operations, GraphQL normalization, pagination, and error mapping.
  - Accepted `2026-03-21`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift test --package-path .`
  - Follow-up accepted `2026-03-21`: consolidated the three tracker-read use cases into grouped `FetchSymphonyIssuesUseCase` overloads without changing the port or gateway seams.
  - Follow-up verification:
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - Follow-up accepted `2026-03-21`: tightened the Application use-case naming policy so multi-method use cases must use distinct semantic method names, and renamed the grouped Symphony tracker-read methods to comply.
  - Follow-up verification:
    - `swift test --package-path . --filter ArchitectureLinterTests`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - [x] Make the three required tracker read operations explicit and acceptance-tested:
    - `fetch_candidate_issues()`
    - `fetch_issues_by_states(state_names)`
    - `fetch_issue_states_by_ids(issue_ids)`
  - [x] Keep `tracker.project_slug` mapped to Linear `slugId`, and filter candidate issues with `project: { slugId: { eq: $projectSlug } }`.
  - [x] Use the configured Linear token in the `Authorization` header and keep the default Linear endpoint at `https://api.linear.app/graphql`.
  - [x] Paginate candidate issues with the required page size default (`50`), preserve issue order across pages, and enforce the `30000 ms` network timeout.
  - [x] Return empty from `fetch_issues_by_states([])` without issuing an API call.
  - [x] Use GraphQL issue IDs with variable type `[ID!]` for state-refresh queries.
  - [x] Normalize labels to lowercase, derive blockers from inverse relations of type `blocks`, coerce `priority` to integer-or-null, and parse `created_at` / `updated_at` as ISO-8601 timestamps.
  - [x] Keep state-refresh reads minimal but sufficient for reconciliation and prompt compatibility.
  - [x] Map tracker failures explicitly for:
    - transport/request failures
    - non-200 status
    - top-level GraphQL errors
    - malformed or unknown payloads
    - missing pagination cursor integrity (`linear_missing_end_cursor`)
  - [x] Keep tracker writes out of orchestrator core; optional `linear_graphql` remains an agent-side extension, not a scheduler requirement.
- [x] `2.3` Implement workspace manager, root-containment checks, sanitized workspace keys, hook execution semantics, and cleanup behavior.
  - [x] Derive the workspace path deterministically as `<workspace.root>/<sanitized issue identifier>`.
  - [x] Reuse an existing workspace directory when it is already present.
  - [x] Create a missing workspace directory and mark `created_now=true` only when the directory was created during the current call.
  - [x] Define and implement an explicit policy for an existing non-directory path at the workspace location.
  - [x] Surface optional workspace population or synchronization failures as current-attempt errors without silently resetting reused workspaces.
  - [x] Remove required temporary artifacts during prep, including `tmp` and `.elixir_ls`.
  - [x] Run `after_create` only when the workspace directory is newly created; treat failure or timeout as fatal to workspace creation.
  - [x] Run `before_run` before each attempt; treat failure or timeout as fatal to the current attempt.
  - [x] Run `after_run` after each attempt, including success, failure, timeout, and cancellation; log and ignore failure or timeout.
  - [x] Run `before_remove` before cleanup when the workspace directory exists; log and ignore failure or timeout.
  - [x] Execute hooks in a local shell context with the workspace directory as `cwd`.
  - [x] Use `hooks.timeout_ms` for every hook, default to `60000`, and fall back to the default when the configured value is non-positive.
  - [x] Log hook start, failure, and timeout while truncating script output and avoiding secret leakage.
  - [x] Normalize workspace root and workspace path to absolute paths for containment checks and reject any workspace outside the configured root.
  - [x] Validate `cwd == workspace_path` before every coding-agent launch.
  - [x] Preserve successful workspaces; only clean them for terminal issues during startup sweep or active terminal transitions.
  - Accepted `2026-03-21`.
  - Verification:
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - Follow-up accepted `2026-03-22`: limited the default hook runner to macOS process execution so the workspace lifecycle gateway compiles cleanly in the Xcode workspace while non-macOS targets now fail configured hooks explicitly instead of breaking the build.
  - Follow-up verification:
    - Xcode workspace build (active workspace)
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - Existing non-directory paths at the computed workspace location now fail fast with a typed workspace error instead of being replaced.
    - Relative `workspace.root` values are normalized against the current process working directory before containment validation.
    - Hook logging no longer depends on `tracker.api_key` redaction because Linear auth is session-backed, and captured hook output previews remain truncated.
    - Sanitized workspace-key collisions still resolve to the same deterministic path because the plan and spec do not yet define a secondary disambiguation contract.
- [x] `2.4` Implement strict prompt rendering for `issue` and `attempt`.
  - [x] Use strict variable checking.
  - [x] Use strict filter checking.
  - [x] Provide exactly these template inputs:
    - `issue`
    - `attempt`
  - [x] Pass `attempt` as `null` or absent on the first run and as an integer on retry or continuation turns.
  - [x] Keep normalized `issue` content iterable in templates, including labels and blockers, and convert object keys to strings where the template adapter requires it.
  - [x] Fail unknown variables as `template_render_error`.
  - [x] Fail unknown filters as `template_render_error`.
  - [x] Distinguish `template_parse_error` from `template_render_error`.
  - [x] Allow an empty workflow prompt body to fall back to the minimal default prompt only when the workflow file was read and parsed successfully.
  - [x] Do not silently fall back to a prompt when workflow file read or parse fails.
  - [x] Fail the run attempt immediately when prompt parse or render fails and let orchestrator retry policy handle the attempt outcome.
  - Accepted `2026-03-21`.
  - Verification:
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - First-run prompt rendering now exposes `attempt` as `null` rather than omitting it so templates may reference the variable safely on first dispatch.
    - The strict repo-owned renderer intentionally supports only interpolation plus `{% for %}` loops for now; any filter usage is treated as an unknown-filter render error.
    - Existing Phase 1 workflow/startup tests remain the verification source for “workflow read/parse failures do not silently fall back to a prompt,” while the new prompt suite covers empty-body fallback after a successful workflow load.
- [x] `2.5` Add non-Domain runtime carriers where needed.
  - [x] live-session metadata
  - [x] retry-entry shapes
  - [x] runner result/state payloads
  - [x] keep timer/process handles out of Domain
  - [x] make the runtime carriers explicit enough for acceptance tests, including:
    - `LiveSession` fields for `session_id`, `thread_id`, `turn_id`, PID, last event/message/timestamp, token totals, last reported totals, and `turn_count`
    - `RetryEntry` fields for `issue_id`, `identifier`, `attempt`, `due_at_ms`, `timer_handle`, and `error`
    - runtime aggregate state for `running`, `claimed`, `retry_attempts`, `completed`, `codex_totals`, and `codex_rate_limits`
  - Accepted `2026-03-21`.
  - Verification:
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - Runtime/session carriers remain in `Application/Contracts/Ports/Symphony` because they describe runtime boundary state for scheduling and observability rather than stable Domain meaning.
    - Timer, worker, and monitor handles stay generic `Equatable & Sendable` placeholders so runtime-only process/timer ownership remains outside Domain while still allowing contract-level acceptance tests.
    - The Codex rate-limit snapshot remains an opaque `SymphonyConfigValueContract` payload until later phases settle the concrete app-server telemetry schema.

**Phase completion checklist**

- [x] Linear candidate/state/terminal fetch operations exist behind inward ports and return normalized issue models.
- [x] Tracker contract coverage is explicit for:
  - `slugId` project filtering
  - `Authorization` header auth
  - default Linear endpoint
  - candidate pagination with preserved order
  - empty-state short-circuit for `fetch_issues_by_states([])`
  - `[ID!]`-typed state-refresh queries
  - typed tracker error mapping
- [x] Workspace creation/reuse, non-directory conflict policy, temp-artifact cleanup, hook execution semantics, and root-containment invariants are enforced.
- [x] Prompt rendering is strict, accepts only `issue` and `attempt`, and produces the right typed parse/render failures.
- [x] Runtime/session bookkeeping types live outside Domain and are explicit enough for scheduler and observability acceptance tests.

**Verification checklist**

- [x] Add focused normalization tests.
- [x] Add tracker contract tests for:
  - [x] candidate query project filter by `slugId`
  - [x] auth header and default endpoint
  - [x] ordered pagination across multiple pages
  - [x] empty `fetch_issues_by_states([])` short-circuit
  - [x] `[ID!]`-typed state refresh query
  - [x] error mapping for request/status/GraphQL/malformed/pagination-cursor failures
- [x] Add workspace safety and hook tests for:
  - [x] deterministic path creation and reuse
  - [x] non-directory conflict handling
  - [x] temp-artifact cleanup
  - [x] hook ordering plus fatal/non-fatal timeout behavior
  - [x] root containment and `cwd == workspace_path` validation
  - [x] terminal cleanup behavior
- [x] Add prompt-render tests for:
  - [x] strict unknown variable failure
  - [x] strict unknown filter failure
  - [x] parse vs render error classification
  - [x] empty-body default prompt fallback
  - [x] workflow read/parse no-fallback behavior
  - [x] `attempt` null vs integer semantics
- [x] Prefer fakes for tracker transport and process/filesystem seams where practical.
- [x] Run `swift test --package-path .`
- [x] Run `swift run --package-path . architecture-linter .`

**Phase checkpoint**

- Phase 2 accepted `2026-03-21`.
- Final verification:
  - Xcode workspace build (active workspace)
  - `swift build --package-path . --target SymphonyRuntime`
  - `swift test --package-path . --filter SymphonyRuntimeTests`
  - `swift test --package-path .`
  - `swift run --package-path . architecture-linter .`
- Reopened acceptance verification `2026-03-22`:
  - Xcode workspace build (active workspace)
  - `swift build --package-path . --target SymphonyRuntime`
  - `swift test --package-path . --filter SymphonyRuntimeTests`
  - `swift test --package-path .`
  - `swift run --package-path . architecture-linter .`
- Reopened acceptance note `2026-03-22`: Xcode diagnostics for `SymphonyWorkspaceLifecycleGateway` were cleared after limiting the default hook runner to macOS process execution and rerunning the active workspace build; no remaining Xcode navigator errors were present after refresh.
- Deferred low-severity follow-ups:
  - Sanitized workspace-key collisions still resolve to the same deterministic workspace path until a later phase defines a disambiguation contract.
  - Hook log redaction currently targets the configured tracker API key only; there is still no broader secret-redaction policy for arbitrary workflow values.
  - Codex rate-limit telemetry remains an opaque config-value payload until the concrete app-server event schema is finalized.
  - `Package.swift` still warns about a stale `App/bootstrap.swift` exclude during SwiftPM builds and tests, but this does not currently fail package verification.

**Risks / notes**

- Hook execution is shell/process behavior and therefore cannot live in Application despite being workflow-driven.
- The exact boundary between Domain policies and Application support contracts must stay disciplined during implementation.
- Optional workspace population remains implementation-defined, but failure behavior is not optional and must be explicit.
- The optional `linear_graphql` client-side tool belongs to the agent toolchain, not the orchestrator core.

**Dependencies**

- [x] Depends on Phase 1.
- [x] Finish before agent runner and orchestrator work.

## Phase 3. Codex App-Server Runner and Worker Attempt Lifecycle

**Goal**

- Decide and document the required runner trust/safety posture.
- Implement the Codex app-server integration and the per-issue worker attempt flow without introducing the full poll/retry scheduler yet.

**Why this phase boundary exists**

- The app-server protocol is the most integration-heavy and failure-prone part of the specification.
- Isolating it behind ports/gateways keeps the later orchestrator phase from mixing subprocess protocol bugs with scheduling logic.
- The worker attempt is a vertical slice across Application and Infrastructure that can be tested with fake process/stdout streams and fake tracker refreshes.

**Expected touched areas**

- `Codex Symphony Kanban/Application/Contracts/Ports/**`
- `Codex Symphony Kanban/Application/Contracts/Workflow/**`
- `Codex Symphony Kanban/Application/Ports/Protocols/**`
- `Codex Symphony Kanban/Application/UseCases/**`
- `Codex Symphony Kanban/Application/Services/**`
- `Codex Symphony Kanban/Infrastructure/Gateways/**`
- `Codex Symphony Kanban/Infrastructure/PortAdapters/**`
- `Codex Symphony Kanban/Infrastructure/Translation/DTOs/**`
- `Codex Symphony Kanban/Infrastructure/Translation/Models/**`
- `Codex Symphony Kanban/Infrastructure/Errors/**`
- `Tests/**`

**Implementation checklist**

- [x] `3.1` Decide and document the runner trust/safety posture needed for execution and verification.
  - [x] Define the trust boundary statement for this implementation.
  - [x] Define approval handling policy.
  - [x] Define sandbox posture/defaults.
  - [x] Define unsupported tool-call behavior.
  - [x] Define `turn_input_required` handling.
  - [x] Define runner-facing failure semantics tied to that policy.
  - [x] Make command-approval and file-change approval behavior explicit as part of the documented trust/safety posture.
  - [x] If the implementation chooses hard failure on user input requirement, document it explicitly and reflect it in tests/logs.
  - Accepted `2026-03-22`.
  - Documentation:
    - `Codex Symphony Kanban/Documentation/SYMPHONY_RUNNER_TRUST_POSTURE.md`
  - Verification:
    - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - The repository posture is now fixed to a trusted single-tenant operator environment with untrusted tracker, repository, and workflow content.
    - Thread defaults are documented as `approvalPolicy = never` and `sandbox = workspaceWrite`, while turn defaults are documented as `approvalPolicy = unlessTrusted` and `sandboxPolicy = { type = workspaceWrite, writableRoots = [workspace_path], networkAccess = false }` unless a later workflow-backed override is explicitly implemented.
    - Command approvals and file-change approvals are documented as distinct request types and both auto-approved by Symphony; the concrete request/response handling remains Phase `3.3` work.
    - `tool/requestUserInput` and `turn_input_required` are documented as hard run-attempt failures mapped to the normalized `turn_input_required` category; the concrete tests and operator-visible log emission for that behavior remain Phase `3.2` to `3.4` work.
    - Compatibility discovery via `configRequirements/read` remains deferred to later subphases and must fail explicitly on incompatible requirements rather than silently weakening the documented posture.
- [x] `3.2` Add protocol/event/result contracts for:
  - [x] session startup
  - [x] turn execution
  - [x] usage/rate-limit extraction
  - [x] normalized runner failure categories
  - [x] any policy/config shapes needed by the chosen posture
  - [x] handshake payloads for `initialize`, `thread/start`, and `turn/start`, including client identity/capabilities plus approval/sandbox posture fields
  - [x] nested `thread_id` / `turn_id` extraction and `session_id = "<thread_id>-<turn_id>"`
  - [x] runtime event timestamps and metadata needed for orchestrator stall detection and observability
  - Accepted `2026-03-22`.
  - Verification:
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - The new Application contract layer now owns the typed Codex runner posture, handshake payloads, runtime event metadata, and normalized failure categories, while JSON-RPC wire-shape parsing remains deferred to the Infrastructure gateway in Phase `3.3`.
    - The new `SymphonyCodexRunnerPortProtocol` is intentionally thin and stateful enough for a live gateway implementation, but it still omits explicit cancellation or shutdown calls until the worker lifecycle and reconciliation flows are wired in later subphases.
    - The typed turn sandbox contract currently models the accepted `workspaceWrite` posture with writable roots and `networkAccess`, while any broader object-form sandbox fields remain deferred until a later subphase proves they are needed by the targeted app-server version.
    - Policy incompatibility is now an explicit normalized runner failure category, and `turn_input_required` is preserved as a separate hard-failure category rather than a generic response error.
- [x] `3.3` Implement the concrete app-server gateway.
  - [x] resolve the first `codex.command` token via login-shell `command -v`, retry with an interactive login shell when needed, then invoke `bash -lc <effective resolved command>`
  - [x] stdout line buffering
  - [x] stderr diagnostics
  - [x] startup handshake
  - [x] session/turn ID extraction
  - [x] timeout handling
  - [x] unsupported tool response
  - [x] user-input-required handling
  - [x] launch with the workspace path as `cwd`, and fail fast with `invalid_workspace_cwd` if the launch directory is not the validated workspace path
  - [x] keep stdout and stderr as separate streams, and read line-delimited protocol JSON from stdout only
  - [x] buffer partial stdout lines until newline before attempting JSON parsing
  - [x] log stderr diagnostics and ignore them for protocol parsing
  - [x] send the startup handshake in the required order:
    - `initialize`
    - `initialized`
    - `thread/start`
    - `turn/start`
  - [x] include the `initialize` client identity/capabilities payload required by the targeted Codex app-server protocol version
  - [x] use the implementation’s documented approval/sandbox posture in `thread/start` and `turn/start`
  - [x] parse nested IDs from `thread/start` and `turn/start`, emit `session_id = "<thread_id>-<turn_id>"`, and reuse the same `thread_id` for continuation turns in one worker lifetime
  - [x] enforce `codex.read_timeout_ms` for request/response waits distinctly from `codex.turn_timeout_ms`
  - [x] do not enforce `codex.stall_timeout_ms` inside the gateway; emit events/timestamps so the orchestrator can enforce inactivity externally
  - [x] tolerate equivalent payload shapes when they preserve the same semantics for IDs, approval events, user-input-required events, and usage/rate-limit telemetry
  - [x] extract usage and latest rate-limit metadata from compatible absolute-total payload variants without double-counting
  - [x] reject unsupported tool calls without stalling the session
  - [x] surface user-input-required according to the documented policy and never wait indefinitely
  - [x] map runner failures explicitly enough to test:
    - `codex_not_found`
    - `invalid_workspace_cwd`
    - `response_timeout`
    - `turn_timeout`
    - `port_exit`
    - `response_error`
    - `turn_failed`
    - `turn_cancelled`
    - `turn_input_required`
  - Accepted `2026-03-22`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyCodexRunnerGatewayTests`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
  - Assumptions and remaining low-severity follow-ups:
    - The concrete gateway now sends `initialize`, `initialized`, `configRequirements/read`, `thread/start`, and `turn/start` in that order so compatibility can fail explicitly before posture-sensitive startup continues.
    - The minimal `SymphonyCodexSessionStartupContract` extension for `command`, `readTimeoutMs`, and `turnTimeoutMs` remains in place because the live gateway needs those values at the `startSession` boundary; corresponding contract coverage now records that delta.
    - The gateway keeps stdout and stderr separate, buffers partial stdout lines until newline, and treats stderr only as diagnostics events, while broader worker lifecycle orchestration and retry semantics remain Phase `3.4` work.
- [x] `3.4` Implement the worker attempt orchestration service.
  - [x] workspace preparation
  - [x] before/after hooks
  - [x] first-turn vs continuation-turn prompting
  - [x] in-run tracker refresh
  - [x] `max_turns`
  - [x] terminal outcome mapping
  - [x] baseline structured runner lifecycle logging for operator-visible worker failures
  - [x] use the full rendered task prompt only on the first turn and send continuation guidance on later turns within the same live thread
  - [x] keep the same live `thread_id` across continuation turns in one worker lifetime
  - [x] bound continuation turns inside one worker lifetime by `agent.max_turns`
  - [x] refresh tracker state after successful turns and stop or continue based on active, terminal, and non-active/non-terminal outcomes
  - [x] ensure `after_run` executes for success, failure, timeout, and cancellation paths
  - [x] keep distinct run-attempt terminal reasons explicit enough to test and log:
    - `Succeeded`
    - `Failed`
    - `TimedOut`
    - `Stalled`
    - `CanceledByReconciliation`
  - [x] emit structured operator-visible logs for startup failure, timeout, cancellation, abnormal exit, policy-driven failure, unsupported tool events, and user-input-required events
  - Accepted `2026-03-22`.
  - Verification:
    - `swift run --package-path . architecture-linter .`
    - `swift build --package-path . --target SymphonyRuntime`
    - `swift test --package-path . --filter SymphonyWorkerAttemptServiceTests`
    - `swift test --package-path . --filter SymphonyRuntimeTests`
    - `swift test --package-path .`
  - Assumptions and remaining low-severity follow-ups:
    - The worker attempt service now owns only one bounded per-issue lifetime; long-running poll cadence, retry queue ownership, reconciliation scheduling, and startup cleanup remain Phase `4` work.
    - `CanceledByReconciliation` is produced directly through the minimal worker-scoped runner interruption seam, while `Stalled` remains preserved in the typed result surface with direct production deferred to Phase `4` stall detection.
    - Codex-specific request shaping now sits behind `SymphonyCodexRequestFactoryPortProtocol` and `SymphonyCodexRequestFactoryGateway`, keeping Application orchestration decoupled from concrete request-policy mapping details.

**Phase completion checklist**

- [x] Worker attempt flow can run against a fake or fixture app-server transport and produce the right normalized outcomes.
- [x] Session IDs, usage totals, and rate-limit payloads are normalized and surfaced upward.
- [x] The implementation has a documented trust boundary plus approval/sandbox/user-input posture before runner behavior is accepted.
- [x] Unsupported tool calls do not stall the session.
- [x] User-input-required is handled according to the documented policy and does not hang.
- [x] Runner startup, turn failure, timeout, cancellation, and policy-driven failures are operator-visible through structured logs.
- [x] The launch contract, handshake order, stdout-only JSON parsing, nested ID extraction, and split read-vs-turn timeouts are acceptance-tested.
- [x] Continuation turns reuse a single `thread_id` and send continuation guidance instead of replaying the original prompt.
- [x] Normalized error mapping is explicit and covers the required `codex_*` / timeout / exit / turn categories.
- [x] Distinct run-attempt terminal reasons are preserved through worker results, retry decisions, and logs.

**Verification checklist**

- [x] Add high-signal protocol fixture tests for:
  - [x] handshake order
  - [x] buffering
  - [x] timeout/error mapping
  - [x] chosen approval/user-input/tool-call policy behavior
  - [x] worker multi-turn flow
  - [x] nested `thread_id` / `turn_id` parsing and `session_id` emission
  - [x] stdout-only JSON parsing with stderr diagnostics ignored
  - [x] continuation turns on the same thread using continuation guidance
  - [x] compatible payload variants for approvals, user-input-required, and usage/rate-limit telemetry
  - [x] distinct terminal reasons for success, failure, timeout, stall, and reconciliation-driven cancellation
- [x] Keep tests mostly unit or narrow integration local.
- [x] Avoid broad end-to-end orchestration runs at this phase.
- [x] Run `swift test --package-path .`
- [x] Run `swift run --package-path . architecture-linter .`

**Risks / notes**

- Codex app-server payload shape can drift across versions; the implementation should normalize logical meaning rather than overfit one exact JSON shape.
- The chosen approval/sandbox posture affects both runtime behavior and test design, so it must be fixed before gateway behavior is reviewed.
- The runner should document its policy decisions explicitly instead of relying on implied default behaviors for approvals, unsupported tools, or user input.

**Dependencies**

- [x] Depends on Phases 1 and 2.
- [x] Finish before long-running scheduler work starts.

**Phase 3 checkpoint**

- Phase `3` completed and checkpointed on `2026-03-22`.
- Implemented subphases:
  - `3.1` runner trust and safety posture
  - `3.2` runner contract layer
  - `3.3` concrete app-server gateway
  - `3.4` worker attempt orchestration service
- Phase-level verification:
  - `swift run --package-path . architecture-linter .`
  - `swift build --package-path . --target SymphonyRuntime`
  - `swift test --package-path . --filter SymphonyWorkerAttemptServiceTests`
  - `swift test --package-path . --filter SymphonyRuntimeTests`
  - `swift test --package-path .`
- Remaining follow-up carried forward to Phase `4`:
  - runtime poll cadence
  - retry queue ownership
  - reconciliation scheduling
  - direct `Stalled` production
  - startup terminal-workspace cleanup

## Phase 4. Orchestrator State Machine, Polling, Retry, and Recovery

**Goal**

- Build the long-running Symphony service:
  - authoritative in-memory state
  - polling cadence
  - dispatch/retry/reconciliation logic
  - stall handling
  - startup cleanup
  - runtime config re-application

**Why this phase boundary exists**

- By this point the repo will already have:
  - config loading
  - tracker reads
  - workspace preparation
  - prompt rendering
  - runner execution
- The orchestrator can then stay what the repo says Application services should be: workflow coordination over ports and use cases, with timers/watchers/process details remaining in App or Infrastructure.
- This phase is where the specification’s central service behavior lives, so it should remain isolated from earlier foundation work.

**Expected touched areas**

- `Codex Symphony Kanban/App/Runtime/**`
- `Codex Symphony Kanban/App/DependencyInjection/**`
- `Codex Symphony Kanban/Application/Contracts/Ports/**`
- `Codex Symphony Kanban/Application/Contracts/Workflow/**`
- `Codex Symphony Kanban/Application/Ports/Protocols/**`
- `Codex Symphony Kanban/Application/UseCases/**`
- `Codex Symphony Kanban/Application/Services/**`
- `Codex Symphony Kanban/Infrastructure/PortAdapters/**`
- `Codex Symphony Kanban/Infrastructure/Gateways/**`
- `Codex Symphony Kanban/Infrastructure/Errors/**`
- `Tests/**`

**Implementation checklist**

- [x] `4.1` Implement pure scheduling state transitions and helpers.
  - [x] claim/release
  - [x] eligibility
  - [x] sorting
  - [x] per-state concurrency
  - [x] retry-delay calculation
  - [x] continuation retry
  - [x] runtime aggregates
  - [x] keep the orchestrator as the sole owner of mutable runtime state:
    - `running`
    - `claimed`
    - `retry_attempts`
    - `completed`
    - `codex_totals`
    - `codex_rate_limits`
  - [x] enforce dispatch sort order exactly:
    - `priority` ascending with null or unknown last
    - `created_at` oldest first
    - `identifier` lexicographic tie-breaker
  - [x] make blocker eligibility explicit:
    - `unstarted` or `backlog` issues with any non-terminal blocker are not eligible
    - `unstarted` or `backlog` issues with only terminal blockers are eligible
  - [x] normalize state keys to lowercase for per-state concurrency lookup and fall back to the global limit when no state override exists
  - [x] keep retry queue entries explicit enough for acceptance tests:
    - `issue_id`
    - `identifier`
    - `attempt`
    - `due_at_ms`
    - `timer_handle`
    - `error`
  - Accepted `2026-03-22`.
  - Verification:
    - Worker:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift test --package-path . --filter SymphonyOrchestratorStateServiceTests`
      - `swift test --package-path . --filter SymphonyRuntimeCarrierContractTests`
      - `swift test --package-path . --filter SymphonyDomainPolicyTests`
      - `swift test --package-path . --filter SymphonyRuntimeTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
    - Orchestrator rerun:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift test --package-path . --filter SymphonyOrchestratorStateServiceTests`
      - `swift test --package-path . --filter SymphonyRuntimeCarrierContractTests`
      - `swift test --package-path . --filter SymphonyDomainPolicyTests`
      - `swift test --package-path . --filter SymphonyRuntimeTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - `SymphonyOrchestratorStateService` is the single public `4.1` scheduling surface, while focused use cases and narrow Domain policy protocols sit underneath it to satisfy the repo's Application use-case and abstraction rules without moving mutable state ownership out of Application.
    - `eligibleIssuesForDispatch` currently returns the ordered eligible candidate list without decrementing per-state slots across that returned list; Phase `4.2` remains responsible for consuming slots as it claims and dispatches issues.
    - Swift Testing suite selection in this repo uses suite-name filters such as `SymphonyOrchestratorStateServiceTests` rather than target-prefixed filters such as `SymphonyRuntimeTests/SymphonyOrchestratorStateServiceTests`.
- [x] `4.2` Implement runtime poll loop, candidate dispatch, retry timer handling, reconciliation, stall detection, and startup terminal-workspace cleanup.
  - [x] schedule an immediate tick after successful startup validation and startup cleanup, then continue at the current effective `polling.interval_ms`
  - [x] run each tick in the required order:
    - reconcile running issues
    - dispatch preflight validation
    - candidate fetch
    - sort
    - dispatch while slots remain
    - observability notification
  - [x] on candidate fetch failure, log the tracker error and skip dispatch for that tick
  - [x] on startup terminal-cleanup fetch failure, log a warning and continue startup
  - [x] on normal worker exit, schedule a continuation retry with attempt `1` after about `1000 ms`
  - [x] on abnormal worker exit, schedule exponential backoff using `min(10000 * 2^(attempt - 1), agent.max_retry_backoff_ms)`
  - [x] make retry handling explicit:
    - fetch active candidates only
    - re-dispatch when the issue is still eligible
    - release the claim when the issue is missing or no longer active
    - requeue slot exhaustion with explicit error `no available orchestrator slots`
  - [x] run reconciliation every tick in two parts:
    - stall detection
    - tracker state refresh
  - [x] compute stall elapsed time from `last_codex_timestamp` when present, otherwise `started_at`
  - [x] disable stall detection entirely when `codex.stall_timeout_ms <= 0`
  - [x] on state refresh:
    - terminal state -> terminate worker and clean workspace
    - active state -> update the in-memory issue snapshot
    - neither active nor terminal -> terminate worker without workspace cleanup
    - refresh failure -> keep workers running and try again next tick
  - [x] treat reconciliation with no running issues as a no-op
  - [x] perform startup terminal workspace cleanup by querying terminal states and removing matching workspaces
  - [x] recover after restart from tracker state plus filesystem state without a durable database
  - Accepted `2026-03-22`.
  - Verification:
    - Worker:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyStartupFlowTests`
      - `swift test --package-path . --filter SymphonyWorkerAttemptServiceTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeServiceTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
    - Orchestrator rerun:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyStartupFlowTests`
      - `swift test --package-path . --filter SymphonyWorkerAttemptServiceTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeServiceTests`
      - `swift test --package-path . --filter SymphonyOrchestratorStateServiceTests`
      - `swift test --package-path . --filter SymphonyWorkspaceLifecycleGatewayTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - `SymphonyServiceHostRuntime` and the new runtime scheduler, clock, worker-execution, and log-sink seams keep timers, subprocess management, and host lifetime out of `Application/Services`, matching the repo's layering rules for orchestrators.
    - Stall detection now reads neutral application-facing accessors (`workerStallTimeoutMs`, `lastActivityTimestamp`) even though the underlying workflow and live-session contracts still retain Codex-specific storage names needed elsewhere in the runtime stack.
    - Restart recovery currently relies on tracker-backed redispatch plus startup terminal-workspace cleanup rather than any durable runtime journal; reload semantics and last-known-good retention remain `4.3` work.
- [x] `4.3` Implement `WORKFLOW.md` watch/reload/re-apply behavior with last-known-good config retention and future-launch reconfiguration.
  - [x] watch `WORKFLOW.md` for changes
  - [x] re-read and re-apply workflow config and prompt template without restart
  - [x] re-apply reloads to future live behavior required by the spec:
    - polling cadence
    - concurrency limits
    - active and terminal states
    - codex settings
    - workspace paths and hooks
    - prompt content for future runs
  - [x] apply reloaded config to future:
    - dispatch decisions
    - retry scheduling
    - reconciliation decisions
    - hook execution
    - agent launches
  - [x] keep the last known good effective config when a reload is invalid and emit an operator-visible error
  - [x] re-validate and re-read defensively during runtime operations, especially before dispatch, in case file-watch events are missed
  - [x] if per-tick validation fails after reload, skip dispatch for that tick but keep reconciliation active
  - [x] do not automatically restart in-flight sessions on config change
  - [x] allow restart-required listener rebinding only for optional extensions that manage their own listeners or resources
  - Accepted `2026-03-22`.
  - Verification:
    - Worker:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeServiceTests`
      - `swift test --package-path . --filter SymphonyStartupFlowTests`
      - `swift test --package-path . --filter SymphonyWorkflowConfigurationTests`
      - `swift test --package-path . --filter SymphonyWorkflowReloadMonitorGatewayTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
    - Orchestrator rerun:
      - `swift test --package-path . --filter SymphonyWorkflowReloadMonitorGatewayTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeServiceTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - The workflow reload monitor now watches the containing directory and filters by target-file snapshots so atomic save/replace flows keep triggering reloads without moving file-watch mechanics into `Application/Services`.
    - Reload reuses `SymphonyDispatchPreflightValidationService` and the existing workflow/config resolution path for both watch-triggered reload and missed-watch defensive revalidation, keeping one validated source of truth for runtime config.
    - Future-only application is enforced by swapping the effective workflow configuration used for later dispatch, retry, reconciliation, hook execution, and worker launches while leaving already-running worker requests untouched.
  - Architecture review follow-up:
    - `ManageSymphonyRuntimeStateUseCase` currently reads more like a runtime-state helper bag than one focused application operation under `Application/README.md`; Phase `4` behavior is accepted, but the use-case/service split should be revisited in a later cleanup pass if architecture fidelity is prioritized over the current compromise.

**Phase completion checklist**

- [x] The orchestrator is the sole owner of mutable runtime state.
- [x] Polling, reconciliation, retry, and cleanup behavior match the specification’s state-machine semantics.
- [x] Invalid workflow reloads do not crash the service and preserve the last known good config.
- [x] Restart recovery works from tracker state plus filesystem state without a durable database.
- [x] Dispatch, reconciliation, retry, and cleanup failures are operator-visible through structured logs, not only through debugger inspection.
- [x] Runtime state ownership is explicit enough for acceptance testing, including `running`, `claimed`, `retry_attempts`, `completed`, `codex_totals`, and `codex_rate_limits`.
- [x] Dispatch eligibility, sorting, per-state concurrency, continuation retry, failure backoff, and stall logic are specified concretely enough to test.
- [x] Reloaded config changes future poll cadence, future dispatch/retry/reconciliation behavior, future hook execution, and future agent launches without requiring a service restart.
- [x] Per-tick validation failure skips dispatch for that tick but keeps reconciliation active.

**Verification checklist**

- [x] Add focused state-machine tests first.
- [x] Add narrow runtime integration tests with fake tracker/runner/workspace collaborators.
- [x] Add only the highest-signal invariant tests for retries, cancellation on state changes, and reload behavior.
- [x] Verify structured dispatch/reconciliation/retry logging in the highest-signal failure paths without overfitting log text.
- [ ] Add acceptance tests for:
  - [x] `unstarted` / `backlog` blocker eligibility with terminal vs non-terminal blockers
  - [x] per-state concurrency normalization and global fallback
  - [x] normal-exit continuation retry (`~1000 ms`)
  - [x] abnormal-exit exponential backoff cap
  - [x] retry release when the issue is missing or no longer active
  - [x] slot-exhaustion requeue with explicit error
  - [x] stall detection timestamp source and disablement when `stall_timeout_ms <= 0`
  - [x] reconciliation no-op when nothing is running
  - [x] terminal cleanup on startup sweep and active terminal transitions
  - [x] watch-triggered reload and missed-watch defensive revalidation
  - [x] invalid reload keeps last known good config and surfaces an error
- [x] Run `swift test --package-path .`
- [x] Run `swift run --package-path . architecture-linter .`

**Risks / notes**

- Application services cannot directly own timers, file watchers, or subprocess management under this repo’s rules; those must stay behind ports or in App runtime assembly.
- The specification’s `Orchestrator` terminology conflicts slightly with the repo’s naming convention that Application orchestrators should be `...Service` types.
- Dynamic reload and per-tick validation are core conformance behavior, not optional polish.

**Dependencies**

- [x] Depends on Phases 1 through 3.
- [x] This is the last required phase for core scheduler correctness.
- Phase 4 checkpoint `2026-03-22`: `4.1`, `4.2`, and `4.3` are accepted with worker and orchestrator verification recorded above; Phase 4 is complete, with a noted architecture follow-up on the `ManageSymphonyRuntimeStateUseCase` split and an unresolved continuity mismatch because `Documentation/SYMPHONY_RUNNER_TRUST_POSTURE.md` is still deleted in the worktree despite earlier acceptance being recorded.

## Phase 5. Extended Observability Surfaces and Optional Extensions

**Goal**

- Add richer observability surfaces, finalize non-optional observability and host-lifecycle acceptance, and keep optional extensions isolated from core conformance.

**Why this phase boundary exists**

- Baseline operator visibility is already established in earlier phases through structured startup, runner, and orchestrator logs.
- This phase can therefore focus on richer snapshots, host-lifecycle acceptance, dashboards, HTTP surfaces, and production-hardening guidance rather than first-use failure visibility.

**Expected touched areas**

- `Codex Symphony Kanban/App/Runtime/**`
- `Codex Symphony Kanban/Application/Contracts/Ports/**`
- `Codex Symphony Kanban/Application/Ports/Protocols/**`
- `Codex Symphony Kanban/Application/Services/**`
- `Codex Symphony Kanban/Infrastructure/Gateways/**`
- `Codex Symphony Kanban/Infrastructure/PortAdapters/**`
- `Codex Symphony Kanban/Infrastructure/Errors/**`
- `Codex Symphony Kanban/Presentation/DTOs/**`
- `Codex Symphony Kanban/Presentation/Controllers/**`
- `Codex Symphony Kanban/Presentation/Renderers/**`
- `Codex Symphony Kanban/Presentation/Routes/**`
- `Codex Symphony Kanban/Documentation/**`
- `scripts/**`
- `Tests/**`

**Implementation checklist**

- [x] `5.1` Implement richer observability surfaces.
  - [x] session/runtime snapshots
  - [x] aggregate counters and rate-limit presentation
  - [x] any human-readable status views that stay observability-only
  - [x] keep structured logs stable with required context fields:
    - `issue_id`
    - `issue_identifier`
    - `session_id`
  - [x] keep log phrasing stable with `key=value` output, explicit action outcomes (`completed`, `failed`, `retrying`, etc.), and concise failure reasons where present
  - [x] keep startup, validation, dispatch, reload, and runner failures operator-visible through structured logs without requiring a debugger
  - [x] avoid large raw payload dumps except where necessary to diagnose malformed tracker or protocol payloads
  - [x] keep token and rate-limit aggregation accurate across repeated agent updates and snapshot rendering
  - [x] ensure logging sink failure does not crash orchestration and emits a warning through remaining sink(s)
  - Accepted `2026-03-24`.
  - Verification:
    - Worker:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyConsoleRuntimeObservabilityAdapterTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeStartupTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeSchedulingTests`
      - `swift test --package-path . --filter SymphonyCLIRuntimeTests`
      - Partial run only: `swift test --package-path . --filter SymphonyRuntimeTests`
    - Orchestrator rerun:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyConsoleRuntimeObservabilityAdapterTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeStartupTests`
      - `swift test --package-path . --filter SymphonyOrchestratorRuntimeSchedulingTests`
      - `swift test --package-path . --filter SymphonyCLIRuntimeTests`
      - `swift test --package-path . --filter SymphonyRuntimeTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - `5.1` is satisfied by a console-only runtime status surface that emits once after startup cleanup and once after each completed orchestrator tick; no HTTP or dashboard transport was added.
    - The worker verification pass was interrupted by two stale `swift-test` processes that held the shared `.build` directory; the orchestrator cleared those processes and completed the required reruns.
    - Compact rate-limit rendering remains intentionally minimal because the underlying payload is still an opaque config-value contract.
- [ ] `5.2` Add optional HTTP dashboard/API surface only if it is still in scope after core conformance.
  - [ ] Keep the HTTP extension observability-only.
  - [ ] Keep CLI `--port` precedence over any optional `server.port` extension config.
  - [ ] Treat listener rebinding as restart-required unless explicitly supported.
  - Deferred `2026-03-24`: optional HTTP surface was not prioritized, was not required for core conformance, and remains unshipped in this phase.
- [x] `5.3` Extend documentation and production validation guidance.
  - [x] harness hardening guidance
  - [x] hook safety and operational notes
  - [x] production validation steps
  - [x] repo-standard verification script updates if Symphony becomes a first-class CI path
  - [x] document CLI and host-lifecycle semantics:
    - optional positional workflow path argument
    - default `./WORKFLOW.md`
    - clean startup failure surfacing
    - success exit when the application starts and shuts down normally
    - nonzero exit when startup fails or the host exits abnormally
  - [x] document the final trust boundary, approval/sandbox posture, secret-handling rules, and user-input policy
  - [x] keep recommended real tracker integration validation separate from core conformance
  - Accepted `2026-03-24`.
  - Verification:
    - Worker:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyHostRuntimeLifecycleTests`
      - `swift test --package-path . --filter SymphonyCLIRuntimeTests`
      - `swift test --package-path . --filter SymphonyStartupControllerTests`
      - `swift test --package-path . --filter SymphonyStartupRendererTests`
      - `swift test --package-path . --filter SymphonyRuntimeTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
    - Orchestrator rerun:
      - `swift build --package-path . --target SymphonyRuntime`
      - `swift build --package-path . --product symphony`
      - `swift test --package-path . --filter SymphonyHostRuntimeLifecycleTests`
      - `swift test --package-path . --filter SymphonyCLIRuntimeTests`
      - `swift test --package-path . --filter SymphonyStartupControllerTests`
      - `swift test --package-path . --filter SymphonyStartupRendererTests`
      - `swift test --package-path . --filter SymphonyRuntimeTests`
      - `swift test --package-path .`
      - `swift run --package-path . architecture-linter .`
  - Assumptions and remaining low-severity follow-ups:
    - `SYMPHONY_RUNNER_TRUST_POSTURE.md` is restored as the canonical filename because that is the artifact already referenced by the plan ledger.
    - `scripts/run_architecture_linter.sh` remains unchanged in this phase; Symphony verification is documented as a separate required validation path until the repo explicitly promotes it into shared CI or script entrypoints.
    - The abnormal host-exit test currently allows the startup success line to print during the test run; this is acceptable behavior and may be cosmetically tightened later without changing the contract.

**Phase completion checklist**

- [x] Operators have access to richer runtime snapshots or status surfaces beyond baseline logs.
- [x] Baseline and richer observability both meet the structured logging conventions required by the spec.
- [x] CLI and host-lifecycle behavior are documented and verified as core conformance behavior.
- [x] If the HTTP extension is shipped, it follows the specification’s optional endpoint semantics and remains observability-only.
- [x] Production-facing hardening and validation guidance is documented at a level suitable for deployment review.

**Verification checklist**

- [x] Add focused tests for snapshot shape, aggregate metrics presentation, and optional endpoint behavior.
- [x] Add focused observability tests for:
  - [x] structured `issue_id` / `issue_identifier` / `session_id` context
  - [x] `key=value` phrasing with action outcomes and concise reasons
  - [x] token and rate-limit aggregation correctness
  - [x] sink failure fallback behavior
- [x] Add CLI/host-lifecycle tests for:
  - [x] explicit workflow path argument
  - [x] default `./WORKFLOW.md`
  - [x] nonexistent explicit path or missing default path failure
  - [x] clean startup failure surfacing
  - [x] success exit on normal start and shutdown
  - [x] nonzero exit on abnormal host exit
- [x] If HTTP is shipped, add endpoint contract tests only for the minimum supported routes.
- [x] Preserve repo-standard verification and extend it deliberately if Symphony should become part of CI.
- [x] Keep recommended real integration validation as recommended:
  - [x] report skipped real-integration checks as skipped
  - [x] fail only profiles/jobs that explicitly enable the real-integration path

**Phase checkpoint**

- Phase `5` completed `2026-03-24`.
- Implemented subphases:
  - `5.1` richer observability surfaces
  - `5.3` documentation and production validation guidance
- Deferred optional subphase:
  - `5.2` HTTP dashboard/API surface remains unshipped and out of scope until explicitly prioritized.
- Phase-level verification:
  - `swift build --package-path . --target SymphonyRuntime`
  - `swift build --package-path . --product symphony`
  - `swift test --package-path . --filter SymphonyHostRuntimeLifecycleTests`
  - `swift test --package-path . --filter SymphonyCLIRuntimeTests`
  - `swift test --package-path . --filter SymphonyStartupControllerTests`
  - `swift test --package-path . --filter SymphonyStartupRendererTests`
  - `swift test --package-path . --filter SymphonyRuntimeTests`
  - `swift test --package-path .`
  - `swift run --package-path . architecture-linter .`
- Phase decisions carried forward:
  - Optional HTTP support remains deferred.
  - Repo-standard linter scripting remains unchanged; Symphony verification is still documented as a separate required validation path.

**Risks / notes**

- Core observability, structured logging, and host-lifecycle semantics are not optional even if richer dashboards remain deferred.
- The HTTP server and `linear_graphql` tool extension are optional in the specification and should not delay core conformance unless explicitly prioritized.
- CI expectations need an explicit decision: keep the current architecture-linter-only script, or promote Symphony checks into the repo-standard path.

**Dependencies**

- [x] Depends on core completion of Phases 1 through 4.
- [x] `5.2` remains optional unless explicitly prioritized.

## Architecture/Spec Conflicts and Repo-Specific Cautions

- [ ] Confirm `Package.swift` changes before large Symphony feature work. The repo currently has no Symphony executable target or shared non-Domain library target.
- [ ] Preserve repo naming conventions even when the spec uses `Orchestrator`. Concrete workflow coordinators should still align with `Application/Services` and `...Service` naming.
- [ ] Keep dynamic `WORKFLOW.md` reload, polling timers, subprocess control, and file watching behind App-runtime or Infrastructure seams rather than embedding platform mechanics directly in Application services.
- [ ] Keep Codex-owned config values pass-through by default. Only add repo-local enums or stricter validation when the repo explicitly accepts the maintenance burden for the targeted app-server version.
- [ ] Fix approval, sandbox, unsupported-tool, and `turn_input_required` behavior by Phase 3 so implementation and verification stay coherent.
- [ ] Treat baseline operator-visible failures as core conformance work in Phases 1, 3, 4, and 5 rather than deferring them to dashboards or HTTP surfaces.
- [ ] Treat dynamic reload, dispatch preflight validation, hook failure semantics, tracker query semantics, and runner error mapping as required work, not deferred low-severity follow-ups.
- [ ] Decide whether Symphony verification stays separate or becomes part of the repo-standard verification script. The current repo-standard path proves the linter, not Symphony.
- [ ] Decide in Phase `1.1` whether a dedicated Symphony test target should be added instead of overloading `Tests/ArchitectureLinterTests`.
- [ ] Make an explicit repo decision for a repository-owned `WORKFLOW.md`. The specification expects one, but the repo currently has none.
- [ ] Keep tracker writes and the optional `linear_graphql` tool out of orchestrator core.
- [ ] Keep optional specification sections optional. The HTTP server, `linear_graphql` tool extension, and SSH worker extension should not be pulled into core phases unless explicitly prioritized.

## Core Conformance Addendum

- Core conformance is not complete until the plan explicitly delivers all of these non-optional gates:
  - workflow/config parsing plus reload: explicit/default path selection, typed load errors, full core field surface/defaults/coercion, dynamic watch/re-read/re-apply, last-known-good retention, and per-tick dispatch preflight validation
  - workspace manager plus hooks plus safety: deterministic sanitized workspace paths, create/reuse/non-directory handling, temp-artifact cleanup, exact hook order/timeouts/failure semantics, root containment, and `cwd == workspace_path` enforcement
  - issue tracker client: the three required read operations, Linear `slugId` project filtering, auth header/default endpoint, ordered pagination, minimal state-refresh reads, and typed tracker error mapping
  - orchestrator dispatch/reconciliation/retry: single mutable state owner, explicit eligibility/sorting/concurrency rules, retry queue shape, continuation vs failure backoff, stall detection, reconciliation outcomes, and restart recovery
  - coding-agent app-server client: login-shell executable resolution for `codex.command` with interactive-login fallback, `bash -lc <effective resolved command>`, required handshake order, stdout-only JSON line parsing, session ID emission, continuation turns on one thread, documented approval/sandbox/user-input behavior, and normalized runner error mapping
  - structured logs and operator-visible observability: `issue_id`, `issue_identifier`, `session_id`, stable `key=value` phrasing, startup/validation/dispatch/reload/runner failure visibility, sink-failure survival, and accurate token/rate-limit aggregation
  - CLI and host lifecycle: optional positional workflow path, default `./WORKFLOW.md`, clean startup failure surfacing, success exit on normal start/shutdown, and nonzero exit on startup failure or abnormal host exit
- Optional extensions remain explicitly outside core conformance unless separately prioritized:
  - HTTP server/dashboard
  - `linear_graphql` client-side tool
  - SSH worker extension
