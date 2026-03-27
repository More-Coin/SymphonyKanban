# Domain Layer

## Purpose

The Domain layer owns the core meaning of the system. It defines concepts, invariants, pure decision rules, capability contracts, and domain failures that should remain valid regardless of transport, storage, framework, or runtime provider.

## What Goes Here

- Entities that carry identity and domain state.
- Value objects that model identity-free concepts with value semantics.
- Enums and other small domain types when they express domain meaning.
- Domain policies for pure, reusable rule evaluation over normalized domain inputs.
- Repository protocols and other domain capability protocols when the domain needs to describe required behavior without choosing an implementation.
- Structured domain errors that describe business failures without transport or persistence vocabulary.
- Domain-specific carrier or payload-style types only when they represent stable business meaning rather than transport DTOs.

## Core Responsibilities

- Define the domain language and core concepts.
- Own invariants inside the entity or value object that the rule constrains.
- Own pure policies that classify, derive, or evaluate over already-valid inputs.
- Describe required persistence or external capabilities through protocols, not implementations.
- Stay independent of workflow orchestration, transport concerns, persistence details, and runtime wiring.

## Naming Taxonomy

- Entities: singular PascalCase nouns, for example `Order`, `Account`, `InventoryItem`.
- Value objects: noun phrases that describe domain meaning, for example `Money`, `EmailAddress`, `DateRange`.
- Policies: role-revealing names ending in `Policy`, for example `DiscountEligibilityPolicy`.
- Repository protocols: `<Concept>RepositoryProtocol`.
- Other capability protocols: role-revealing names ending in `Protocol`.
- Domain errors: a shared root such as `SharedDomainError`, or a feature/root error such as `<Feature>Error` or `<Feature>DomainError`.

## Structured Errors

- Domain structured errors describe business failures, invariant violations, missing entities, invalid state, and permission-independent domain rules.
- Domain structured errors must stay transport agnostic and must not use HTTP, database, SDK, provider, or other boundary vocabulary.
- Domain structured errors should conform to `StructuredErrorProtocol`.
- A structured domain error should expose:
  - `code`
  - `message`
  - `retryable`
  - `details`
- Keep `code` stable and machine-readable even if the human-readable `message` evolves.
- Prefer explicit typed errors such as enums or similarly clear error types over loose string failures.
- Presentation maps structured errors into external responses; Domain does not build transport failures directly.

## What Does Not Go Here

- Workflow orchestration or multi-step use-case coordination.
- Authorization sequencing, request-scoped validation, pagination normalization, or request context handling.
- Repository implementations, persistence models, provider SDK types, transport adapters, or external clients.
- Controllers, DTOs, request/response parsing, routing, or transport error mapping.
- Dependency injection, composition-root setup, or cross-feature wiring.

## Decision Rule

Put code here if it still makes sense after removing HTTP, database, framework, provider SDK, and request context. If it needs those to make sense, it belongs in an outer layer.

## Invariants Vs. Policies

- Invariants are validity rules owned by the entity or value object they constrain.
- Policies are pure domain decisions over normalized, already-valid inputs.
- Invariants should stay close to the model they protect.
- Policies should stay deterministic, side-effect free, and easy to test in isolation.

## Dependency Rule

The Domain layer depends only on inward-safe language primitives, Foundation-style primitives when needed, and other domain code. It must not depend on Application, Infrastructure, Presentation, transport frameworks, provider libraries, or runtime composition.

## Durable Structure

- `Entities/`
- `ValueObjects/`
- `Policies/`
- `Protocols/`
- `Errors/`

## Structure Notes

- Subdirectories are commonly grouped by capability or concept family when that improves navigation.
- Some domains place repository contracts under `Protocols/Repositories/`.
- Some domains add `Protocols/Gateways/` when gateway-style capability contracts are part of the domain surface.
- `Utilities/` appears in shared domain only; it is not a universal domain-layer requirement.
