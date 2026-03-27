# Application Layer

## Purpose

The Application layer owns workflow orchestration. It coordinates domain behavior through abstractions, keeps validation and authorization flow out of controllers and adapters, and executes use-case flows without implementing infrastructure concerns.

## What Goes Here

- Services that orchestrate workflows across one or more use cases, validation steps, authorization checks, and execution gates.
- Use cases that define one focused application operation across a protocol-backed seam.
- State transitions that define pure application-level next-state semantics without crossing a boundary or orchestrating collaborators.
- Command contracts that represent external input in application-owned form.
- Workflow contracts that represent validated, ready-to-execute workflow input.
- Port contracts for request/response shapes at technical boundaries when the Application layer needs them.
- Narrow, pure, side-effect-free contract-local evaluators on Application contracts when they only derive from the contract's own data and explicit passive value or contract inputs.
- Application-owned port protocols that describe technical seams the layer depends on.
- Application-layer errors for workflow failures and orchestration-specific failures.

## Service Examples

- Positive:
  - A service that validates input, resolves the acting user, checks permissions, and then calls one or more use cases in sequence.
  - A service that coordinates retries, status transitions, or workflow order across several use case operations.
- Negative:
  - A thin wrapper around one technical port call with no orchestration.
  - A no-op placeholder that does not orchestrate any use case.
  - A pure domain rule or invariant.
  - A public state-transition, bookkeeping, or evaluator helper that does not operationally use an injected Application use case.
  - A service-to-service facade where the exposed method delegates only to another service and never reaches a focused Application use case.
  - A concrete adapter that talks directly to a database, SDK, queue, or HTTP client.
  - A controller, request parser, or response mapper.

## Use Case Examples

- Positive:
  - A use case that defines one focused application operation such as create, update, delete, or fetch.
  - A use case that depends on an application-facing protocol or domain protocol rather than a concrete boundary implementation.
- Negative:
  - A type that performs broad workflow sequencing across multiple operations.
  - A type that mixes authorization, retries, cross-feature coordination, and persistence orchestration.
  - A concrete persistence, filesystem, runtime, parsing, or provider implementation.
  - A general-purpose helper with no clear application operation.

## Core Responsibilities

- Orchestrate workflow order and sequencing.
- Define pure application-level next-state semantics when application-owned state must evolve without boundary calls or collaborator orchestration.
- Perform validation flow, authorization flow, ownership checks, and other request-scoped execution gates.
- Translate external input into validated workflow input before execution.
- Compose use cases rather than calling repositories directly from controllers.
- Keep domain rules in Domain and implementation details in Infrastructure.

## Canonical Flow

1. External input enters through a command contract.
2. The command contract is transformed into a validated workflow contract through a builder or factory port.
3. One or more focused use cases define the application operations needed for the workflow.
4. Infrastructure provides the concrete boundary implementations behind the protocols those use cases depend on.
5. The composition root wires the concrete Infrastructure implementation into the Application-facing seam.
6. A service composes one or more use cases when broader workflow orchestration is required.

## Naming Taxonomy

- Services: `...Service`
- Use cases: `...UseCase`
- State transitions: `...Transition`
- Application ports: `...PortProtocol`
- Anything under `Contracts`: `...Contract`
- Single-operation use cases may expose a generic entry point such as `execute(...)`, `perform(...)`, or `callAsFunction(...)`
- Grouped use cases may expose multiple methods when they remain variants of one focused action, but each public operation must use its own explicit semantic name
- Multi-method use cases must not rely on overloaded generic operation names

## Contract Notes

- Application contracts are primarily carrier shapes for command, workflow, and port data.
- A contract may expose a narrow pure observational evaluator when the logic is strictly contract-local and depends only on stored contract state plus explicit passive inputs.
- Observational evaluators may include predicates, derived-value accessors, normalization helpers, and local invariant checks.
- Those evaluators must not orchestrate workflows, define next-state semantics, map errors, call ports, depend on services or use cases, or translate to boundary-specific request or provider shapes.
- Keep reusable domain meaning, cross-contract policy, and true business invariants in Domain rather than treating Application contracts as mini-services or general helper buckets.
- Existing translation-oriented helper methods in contracts are not the model to expand from; this allowance is for local evaluation only.

## State Transition Notes

- Application state transitions define pure application-level next-state semantics.
- They are used when application-owned state must evolve in response to an event, workflow outcome, or internal application event without crossing a boundary or orchestrating collaborators.
- They may transform one or more Application contracts into updated contracts or transition results.
- They must remain deterministic, side-effect free, and inward-facing.
- They must not call ports, services, use cases, repositories, gateways, infrastructure, or platform APIs.
- They must not perform logging, scheduling, transport shaping, error mapping, or boundary work.
- State transitions answer "what should this state become next?"; contracts answer "what is true right now?"

## Structured Errors

- Application structured errors describe orchestration failures, invalid application input, timeouts, and workflow-level service failures.
- Application structured errors must not build transport responses directly.
- Application structured errors should conform to `StructuredErrorProtocol` from Domain.
- A structured application error should expose:
  - `code`
  - `message`
  - `retryable`
  - `details`
- Prefer `ApplicationError` for shared application-wide failures and role-revealing workflow error names when a narrower error type is clearer.
- Keep codes stable, messages readable, retryability explicit, and details optional.
- Let Presentation map structured application errors into external responses.

## Service Vs. Use Case Split

- Use a `UseCase` for one focused application operation across a protocol-backed seam.
- A `UseCase` should depend on abstractions, not on concrete boundary implementations.
- Concrete boundary-specific implementation belongs in Infrastructure behind protocols or ports and is wired in from the composition root.
- Use a `Service` when validation, authorization, sequencing, or coordination across one or more use cases is required.
- Use a `StateTransition` when pure application-owned state must evolve without boundary calls or collaborator orchestration.
- Exposed Application service methods should operationally use at least one injected Application use case.
- Services orchestrate use cases and state transitions; they do not replace them and they are not thin technical wrappers.
- An exposed service method that merely forwards to a single injected use case without adding meaningful orchestration is still a facade helper and should be collapsed back into the use case or decomposed further.
- When an exposed service method fails this split, decompose it first if needed and then classify the parts into these buckets:
  - invariant or evaluator logic
  - next-state semantics
  - concrete boundary implementation logic
  - orchestration logic or mixed orchestration of invariants and implementation
- Remediation by bucket:
  - invariant or evaluator logic: move inward to the relevant Application contract or Domain entity or value object
  - next-state semantics: move to `Application/StateTransitions` and keep the logic pure, deterministic, and inward-facing
  - concrete boundary implementation logic: move to Infrastructure behind an Application or Domain protocol seam, then consume it from a focused use case through dependency injection; do not call Infrastructure directly from the service
  - orchestration logic or mixed orchestration of invariants, state transitions, and implementation: decompose mixed methods, move evaluators inward, move next-state semantics to state transitions, move implementation behind protocols and focused use cases, and keep only actual use-case orchestration on the exposed service surface
- Thin forwarding or facade helpers and state-transition or bookkeeping helpers are decomposition signals, not final destination buckets.
- Use cases do not own broad workflow orchestration.

## What Does Not Go Here

- Domain entities, value objects, invariants, or pure domain policies.
- Concrete persistence code, provider SDK calls, transport adapters, or infrastructure implementations.
- Controllers, routes, middleware, request parsing, or response shaping.
- Composition-root wiring or dependency injection setup.

## Dependency Rule

The Application layer depends inward on Domain and abstractions only. It must not instantiate concrete infrastructure types, and it must not contain presentation or transport behavior.

## Durable Structure

- `Contracts/Commands`
- `Contracts/Ports`
- `Contracts/Workflow`
- `StateTransitions`
- `UseCases`
- `Services`
- `Ports/Protocols`
- `Errors`

## Structure Notes

- These are durable categories, not a rule that every feature must contain every folder.
- Some features may implement only a subset of these categories.
- Cross-feature coordination may live at the Application boundary, but concrete wiring belongs in the composition root.
