# App / Composition Root Layer

## Purpose

The App or composition-root layer owns process startup, environment-aware bootstrapping, dependency injection, module assembly, and the explicit top-level wiring needed to produce a runnable application instance.

This directory is the main entry point for the application. It answers how the process starts, how the runtime is configured, and how lower-layer collaborators are assembled into a runnable app.

## What Goes Here

- Process-entry code that starts the runtime and hands control to the configured application.
- App-wide bootstrapping such as environment loading, middleware registration, serialization defaults, runtime configuration, and runtime client initialization.
- Dependency-injection modules that assemble repositories, use cases, services, controllers, route groups, and other lower-layer collaborators.
- Cross-feature or cross-module wiring that must stay outside feature internals, including bridging collaborators and assembly-time dependency ordering.
- Runtime-only configuration profiles, environment-backed defaults, and startup-only registration code.

## Positive Examples

- A startup entrypoint that creates the app host and delegates into a bootstrap or configuration function.
- A bootstrap file that registers global middleware, serializer settings, runtime clients, and shared services.
- A dependency-assembly module that constructs one feature’s repository, use cases, services, and controllers.
- A runtime configuration file that loads environment-backed values and produces startup settings.

## Negative Examples

- A domain invariant, business rule, or pure policy.
- A service that performs workflow sequencing or authorization decisions.
- A repository that talks directly to storage.
- A controller that parses request bodies or maps response DTOs.
- Provider-specific translation logic that belongs inside Infrastructure.
- Feature-local business orchestration that should stay in Application.

## Core Responsibilities

- Start the process and hand off to the configured runtime.
- Load environment-aware configuration and startup defaults.
- Register global middleware, serializers, runtime clients, and shared host-level behavior.
- Assemble dependency graphs from lower-layer building blocks.
- Perform cross-feature or cross-module composition that inner layers should not know about.

## Decision Rule

Put code here when it answers “how is this application instance assembled and started?” If the rule should remain true outside startup or wiring, it belongs in Domain, Application, Infrastructure, or Presentation instead.

## Naming Taxonomy

- Process entrypoint: `main` or an equivalent startup entry file
- Bootstrap / app assembly: `configure`, `bootstrap`, or similarly explicit startup file
- Dependency-assembly modules: `...DI` or another consistent assembly/module suffix
- Runtime-only configuration: names under `Configuration`
- Runtime/provider startup registration: names under `Runtime`

## What Does Not Go Here

- Business logic, authorization decisions, validation rules, or workflow orchestration.
- Repository behavior, persistence mapping, and external-client implementation details.
- Request decoding, response DTO mapping, and route-local transport behavior.
- Repository-wide architecture guidance or operational procedures.

## Dependency Rule

The composition root may depend on any lower layer needed for assembly. Other layers should not depend on the composition root.

## Durable Structure

- `main.swift` or an equivalent process-entry file
- `bootstrap.swift` or `configure.swift`
- `Configuration/`
- `Runtime/`
- `DependencyInjection/`

## Structure Notes

- These are durable categories, not a rule that every project must use these exact folder names.
- Feature-local assembly may live in per-feature DI modules, while the composition root owns top-level composition across features.
- If the project centralizes final route attachment at startup, keep that wiring small and explicit; route definitions, endpoint handlers, request parsing, and transport mapping stay in Presentation.
