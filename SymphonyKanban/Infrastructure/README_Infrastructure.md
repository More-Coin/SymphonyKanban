# Infrastructure Layer

## Purpose

The Infrastructure layer is the concrete adapter boundary. It implements persistence adapters, external-system gateways, and other concrete port adapters that satisfy inward-facing Domain and Application contracts while isolating provider-specific and storage-specific details from the rest of the system.

## What Goes Here

- Repositories that implement persistence-facing contracts.
- Gateways that cross external or runtime boundaries such as network, process, queue, provider, or service boundaries.
- Port adapters that implement application-owned ports when the implementation is not best described as a repository or gateway.
- Evaluators that consume already-shaped technical boundary inputs and return technical classifications, selections, or resolutions without parsing raw boundary data or executing the boundary.
- Request factories, launch or startup builders, and configuration normalizers that only prepare boundary inputs for another adapter to execute should usually be `PortAdapters/` or `Translation/Models/`, not `Gateways/`.
- Translation models for storage-facing, adapter-owned, parser-owned, normalized, or other non-DTO technical shapes that must be translated into app-usable meaning.
- Separate translation models for boundary configuration normalization and for query/request-definition shaping when a gateway needs both responsibilities.
- Translation models for staged intermediary carriers that participate in inward normalization and therefore should not remain nested inside gateways.
- Translation models for DSL or syntax parser subsystems that convert raw template, command, storage, configuration, parser, AST, expression, context, or value shapes into app-usable meaning.
- Translation DTOs for API-facing, protocol-facing, provider-facing, or transport-facing inbound and outbound shapes.
- DTO-side translators, parsers, or builders in `Translation/DTOs` when API/protocol/provider/transport shapes must be translated into app-usable meaning or assembled from app-usable meaning without executing the boundary.
- Infrastructure-local errors that describe adapter, provider, transport, or storage concerns.

## Positive Examples

- A repository that saves and fetches domain-facing entities through a database client.
- A gateway that calls an external API, queue, webhook target, or runtime service.
- A port adapter that implements a technical seam such as verification, secret resolution, storage lookup, or other application-owned boundary behavior.
- An evaluator that classifies a translated technical state, selects one translated technical option, or resolves one technical boundary decision from already-shaped inputs.
- A translation model that normalizes database rows, storage records, provider config, parser output, or other non-DTO technical shapes into app-usable meaning.
- A translation DTO that represents an HTTP request body, GraphQL payload, JSON-RPC message, response envelope, or other API/protocol/provider/transport-facing shape.
- A DTO-side translator adjacent to those DTO shapes that parses or assembles API/protocol/provider/transport-facing data without executing the boundary.
- A translation type that parses DSL or template syntax into Infrastructure-owned parser-model shapes which a port adapter later interprets into a final prompt or command string.

## Negative Examples

- A domain invariant, business rule, or pure policy.
- A service that coordinates authorization, retries, or multi-step workflow order.
- A use case that represents one focused application operation.
- A controller, route, middleware component, request parser, or response mapper.
- Composition-root wiring, bootstrapping, or top-level dependency registration.

## Core Responsibilities

- Talk to datastores, provider SDKs, queues, runtime services, and other external systems.
- Implement inward-facing repository, gateway, and port contracts.
- Keep provider-specific serialization, identifier handling, transport codecs, auth propagation, and storage-shape translation inside the adapter boundary.
- Translate storage-facing, provider-facing, transport-facing, and other adapter-owned technical shapes into normalized Domain types, Application contracts, or explicit Infrastructure error surfaces.
- Evaluate already-shaped technical boundary facts into technical classifications, selections, or resolutions without re-parsing those inputs or executing the boundary.
- Keep runtime boundary execution flow in the gateway, but move staged inward-normalization carriers into `Translation/Models` instead of building bespoke nested normalization pipelines inside the gateway.
- Move normalized provider config, storage shapes, parser-owned shapes, and adapter-owned intermediary request-definition carriers into `Translation/Models` when they are non-DTO technical translation work.
- When a gateway needs both boundary configuration normalization and query/request-definition shaping, keep those responsibilities in separate translation models rather than a single combined helper model.
- Keep API-facing, protocol-facing, provider-facing, or transport-facing inbound/outbound shapes in `Translation/DTOs`, along with any DTO-side parser, directional translator, or builder that translates those DTO-class shapes into app-usable meaning or assembles them from app-usable meaning without executing the boundary.
- Gateways may consume DTO-side translation results, but they should not keep final outbound API/protocol/provider/transport translation inline in public methods or gateway-local helpers before handing that result to send/write/execute transport logic.
- Move adapter-owned parser mechanics, AST or expression carriers, parser context or value carriers, and business-data-to-context projection helpers into `Translation/Models` when they translate non-DTO technical shapes into internal shapes.
- Keep public render entry points, final rendering or interpretation to the boundary output, and parse-plus-render orchestration in the port adapter rather than in `Translation/Models`.
- Once those translation shapes exist, the gateway should not keep inline query/request text, operation-name assembly, variables assembly, URLRequest assembly, request-body assembly, response-envelope shaping, raw protocol parsing, or equivalent translation ingredients.
- Once those translation shapes exist, pure decision-shaped technical logic such as classification, option selection, or resolution should move to `Evaluators` when it no longer performs parsing or execution.
- Keep pagination, request execution, HTTP or status handling, and response decode orchestration in the gateway rather than in `Translation/Models` or `Translation/DTOs`.
- Do not label a type as a gateway when it only assembles requests, startup contracts, payloads, or normalized config for another adapter; that role belongs in `PortAdapters/` or `Translation/Models/` depending on whether a concrete seam implementation remains.
- Do not hide intermediary shaping or DTO-side final request/response shaping inside private nested gateway helpers such as local request builders; nested helper existence alone is not the issue, but shaping ownership is.
- Prevent provider-specific and storage-specific details from leaking inward.

## Naming Taxonomy

- Persistence adapters: `...Repository`
- External-system adapters: `...Gateway`
- Other concrete port implementations: `...PortAdapter`
- Technical decision types: prefer `...Classifier`, `...Selector`, or `...Resolver` under `Evaluators`
- Translation shapes: role-revealing names under `Translation/Models` or `Translation/DTOs`
- Infrastructure-local errors: role-revealing names that make the adapter, provider, or boundary concern explicit
- Discourage vague evaluator names such as `...Helper`, `...Utils`, `...Service`, `...Manager`, or `...Policy`

### Evaluator Shape Meanings

- Use a `...Classifier` when typed technical facts come in and a categorized technical outcome comes out.
- Use a `...Selector` when several already-allowed typed technical options come in and one option is chosen.
- Use a `...Resolver` when multiple typed technical facts must be combined into one resolved technical decision or result.
- Prefer these names only when the behavior actually matches the shape.
- Do not use them as generic aliases for miscellaneous helper logic.

## Structured Errors

- Infrastructure structured errors describe storage failures, provider failures, gateway failures, translation failures, and other boundary-specific technical problems.
- Their names should make the adapter, provider, or boundary concern explicit, for example `<Boundary>InfrastructureError` or `<Provider>GatewayError`.
- Infrastructure structured errors should conform to `StructuredErrorProtocol` from Domain.
- A structured infrastructure error should expose:
  - `code`
  - `message`
  - `retryable`
  - `details`
- Keep provider-specific or storage-specific detail in `details`, not in inner-layer contracts.
- Prefer explicit typed errors over broad untyped string failures.
- Infrastructure reports the structured adapter failure; Presentation still owns final transport mapping.

## Repository Vs. Gateway Vs. Port Adapter

- Use a `Repository` when the type owns persistence-facing implementation of an inward contract.
- Use a `Gateway` when the type crosses an external or runtime boundary such as network, process, queue, or provider service.
- Use a `PortAdapter` when the type concretely implements an inward-facing application port but is not primarily a repository or gateway.
- Use an `Evaluator` when the type consumes already-shaped technical inputs and returns a technical classification, selection, or resolution without executing the boundary.
- Use `Translation/Models` when the type's main job is translating storage-facing, parser-owned, config-owned, or other non-DTO technical shapes into app-usable meaning.
- Use `Translation/DTOs` when the type's main job is translating API-facing, protocol-facing, provider-facing, or transport-facing inbound/outbound shapes into app-usable meaning, or assembling those DTO-class shapes from app-usable meaning without executing them.
- None of these are catch-all buckets for miscellaneous technical code.

## Models Vs. DTOs Vs. Evaluators Vs. Gateways

- `Translation/Models`
  - translation of storage-facing, parser-owned, config-owned, or other non-DTO technical shapes
  - normalized config
  - intermediary request-definition carriers
  - adapter-owned shaping that is not best described as API/protocol/provider/transport DTO translation
- `Translation/DTOs`
  - translation of API-facing, protocol-facing, provider-facing, or transport-facing inbound/outbound shapes
  - request bodies, response envelopes, protocol messages, and other DTO-class shapes
  - adjacent DTO-side parsers, directional translators, or builders that translate those shapes into app-usable meaning or assemble them from app-usable meaning
- `Evaluators`
  - typed technical decision logic over already-shaped boundary data
  - classification, selection, and resolution work that follows translation
  - no raw parsing, extraction, request assembly, or boundary execution
- `Gateways`
  - execution and orchestration only

- Use `Translation/Models` when the type answers:
  - "What non-DTO technical shape are we translating into app-usable meaning?"
- Use `Translation/DTOs` when the type answers:
  - "What API/protocol/provider/transport-facing shape are we translating into app-usable meaning, or assembling from app-usable meaning?"
- Use `Evaluators` when the type answers:
  - "Given already-shaped technical inputs, what technical classification, selection, or resolution follows?"
- Use `Gateways` when the type answers:
  - "How is the boundary interaction executed, paginated, retried, streamed, or otherwise orchestrated?"

- Translation turns raw technical shapes into typed technical meaning.
- Evaluation consumes that typed technical meaning and returns a technical decision.
- Execution sends, reads, waits, streams, loads, saves, retries, or otherwise performs live boundary work.
- If logic is still mixed extraction plus evaluation, decompose it before moving it.

- Concrete `URLRequest` assembly is DTO-side boundary request translation.
- It does not belong in `Translation/Models`.
- It does not belong in `Gateways`.
- DTO files may contain DTO shapes plus adjacent DTO-side translators, parsers, or builders when those are still DTO-class translation work.
- Gateways may use those DTO-side translation results, but may not own that DTO-class translation logic themselves.
- Model files may contain model shapes plus adjacent model-side translators when those are still non-DTO technical translation work.

## What Does Not Go Here

- Domain entities, value objects, invariants, repository or gateway protocols, or pure domain policy.
- Application workflow orchestration, permission sequencing, use-case composition, or business decision-making.
- Presentation behavior such as controllers, routes, middleware, request parsing, or response shaping.
- Composition-root setup, environment bootstrapping, or cross-feature wiring.

## Dependency Rule

The Infrastructure layer may depend on Domain contracts, Application contracts, shared inward-facing abstractions, technical libraries, storage clients, and provider SDKs. It must not depend on Presentation, and it must not own domain business policy or application workflow decisions.

## Durable Structure

- `Repositories/`
- `Gateways/`
- `PortAdapters/`
- `Evaluators/`
- `Translation/Models/`
- `Translation/DTOs/`
- `Errors/`

## Structure Notes

- These are preferred structural categories, not a requirement that every feature must contain all of them.
- Subfolders may be grouped by business capability, technical boundary, provider, or runtime when that improves clarity.
- Add `Gateways/` or `PortAdapters/` only when there are concrete occupants that honestly fit those roles.

## Linter Guidance

- Infrastructure linter rules should preserve a consistent remediation structure.
- In order, remediation should include:
  - likely categories
  - signs
  - architectural note
  - destination
  - explicit decomposition guidance
- Use that structure to explain how to classify mixed Infrastructure responsibilities before relocating them.
- Keep remediation destination-aware rather than prohibition-only.
