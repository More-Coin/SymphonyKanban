# Presentation Layer

## Purpose

The Presentation layer owns the transport boundary. It receives transport-specific input, validates and parses that input, calls the Application layer, and maps results into transport-safe output without owning business rules or infrastructure behavior.

## What Goes Here

- Routes that expose the transport surface and bind endpoints or entry points to controllers.
- Controllers that parse transport input, obtain request context when needed, call Application services only, and hand results to the next presentation step.
- Presenters that translate application results into presentation models without choosing the final transport encoding.
- Renderers that translate presentation models into concrete transport output such as response bodies, status codes, frames, or serialized payloads.
- Request and response DTOs, query-parameter models, and other transport-shape types.
- Middleware that enforces transport-level concerns such as authentication hooks, rate-limit responses, or shared request/response normalization.
- Presentation-specific error mapping that converts structured failures into transport responses.
- Boundary translation helpers that keep field naming, optional-field handling, formatting, and transport-specific mapping at the edge.
- View models that prepare presentation-facing state for transport or UI rendering.
- Views that render presentation-facing models into a concrete edge experience.
- Styles that define presentation-local visual rules and edge-facing appearance concerns.

## Positive Examples

- A controller that parses headers, route params, query params, or body input and then calls one service.
- A request DTO that validates transport shape and converts it into application-friendly input.
- A presenter that reshapes an application result into a presentation model.
- A renderer that turns a presentation model into an HTTP response, a websocket frame, or another transport-safe output.
- Middleware that applies transport-facing enforcement or normalization at the request/response boundary.
- A view model that prepares already-decided application output for rendering.
- A view that renders a presentation model without moving business logic inward.

## Negative Examples

- A service that orchestrates workflow, authorization flow, retries, or sequencing across use cases.
- A use case that performs a focused application operation.
- A repository, gateway, SDK client, persistence mapper, or storage adapter.
- A domain entity, value object, invariant, or pure policy.
- Dependency injection setup, bootstrapping, or composition-root wiring.

## Core Responsibilities

- Parse and validate transport input.
- Translate transport input into application-facing input.
- Call Application services only.
- Translate application results into presentation models and transport-safe output.
- Select transport status codes, response shapes, and edge-specific error mapping.
- Keep transport-specific naming, formatting, request/response concerns, and edge presentation concerns out of inner layers.

## Canonical Flow

1. Route receives the transport request or event.
2. Controller parses input and calls an Application service.
3. Presenter translates the application result into a presentation model.
4. Renderer translates the presentation model into concrete transport output.
5. The transport response is returned.

## Naming Taxonomy

- Controllers: `...Controller`
- Presenters: `...Presenter`
- Renderers: `...Renderer`
- Route binders: `...Routes`
- Middleware: `...Middleware`
- Transport models: `...DTO`, `...DTOs`, or `...QueryParams`
- Presentation-local errors: `...PresentationError` or similar transport-facing error names
- View models: `...ViewModel`
- Views: `...View`
- Styles: role-revealing names ending in `Style` when styles are explicitly modeled as types

## Structured Errors

- Presentation structured errors describe request-shape problems, invalid headers, query parsing failures, missing required fields, and response-mapping failures at the edge.
- Presentation also owns final error mapping from structured errors into transport responses.
- Presentation structured errors should conform to `StructuredErrorProtocol` from Domain.
- A structured presentation error should expose:
  - `code`
  - `message`
  - `retryable`
  - `details`
- Presentation error names should be transport-facing, such as `...PresentationError` or `...PresentationErrors`.
- Inner layers throw structured errors without building transport behavior too early; Presentation decides final status, headers, and serialization.

## Decision Rule

Put code here when it exists only because the transport has a specific request shape, response shape, route surface, header format, query format, status-code rule, middleware requirement, or rendering concern. If the logic still matters after removing the transport boundary, it likely belongs in an inner layer.

## What Does Not Go Here

- Business rules, invariants, or domain concepts that must remain transport-agnostic.
- Workflow orchestration, permission sequencing, use-case composition, or cross-entity business decisions.
- Repository access, provider SDK calls, persistence-model handling, or infrastructure translation.
- Composition-root setup and runtime bootstrapping.

## Dependency Rule

The Presentation layer may depend on Application services and Domain types only when needed for transport mapping. It must not depend on Infrastructure implementations.

## Durable Structure

- `Routes/`
- `Controllers/`
- `DTOs/`
- `Presenters/`
- `Renderers/`
- `Middleware/`
- `Errors/`
- `ViewModels/`
- `Views/`
- `Styles/`

## Structure Notes

- These are durable categories, not a rule that every feature must contain every folder.
- Some features may implement only routes, controllers, DTOs, and errors at first.
- Presenters and renderers become useful when response translation needs a distinct presentation-model step.
- View models, views, and styles belong here when they exist only to support the edge experience.
- Transport-native inbound payloads still belong here when they exist only to satisfy the edge contract.
