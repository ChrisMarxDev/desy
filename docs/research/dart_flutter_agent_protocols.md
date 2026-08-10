# Agent protocols and runtimes for Dart and Flutter

Date: 2026-08-10

## Executive conclusion

There is enough in Dart today to build a real agent product, but not one
single, official, current SDK that covers the entire stack.

- **Agent runtime:** Google's first-party preview of Genkit for Dart is the
  strongest conservative starting point. It provides models, typed tools,
  streaming, flows, interrupts, middleware, telemetry, and an MCP plugin.
- **MCP (agent/host to tools and context):** Dart has two credible choices.
  The Dart team maintains experimental `dart_mcp`, while community-maintained
  `mcp_dart` is currently much broader and already targets the breaking MCP
  `2026-07-28` specification. Neither is an official MCP SDK.
- **ACP (editor to coding agent):** several community packages exist, but ACP
  has no official Dart SDK. The ACP project lists `acp_dart` as a community
  library; the richer `acp` package is an unlisted release candidate. Both
  trail the latest schema artifacts.
- **A2A (remote agent to agent):** there is an active community `a2a` package,
  but it implements A2A v0.3 while the official protocol is v1.0.1. It should
  not be treated as a current production implementation.
- **Flutter-facing protocols:** `ag_ui` supplies a cross-platform AG-UI client
  for event streaming, tools, and shared state. Flutter's own `genui` package
  implements A2UI v0.9 for constrained, catalog-backed generated interfaces.
  These solve UI delivery, not agent reasoning or agent-to-agent delegation.

The practical architecture is therefore a **pure-Dart agent core behind typed
protocol adapters**, with Flutter responsible for presentation and explicit
user approval. Do not bake MCP, ACP, A2A, or an LLM provider's message types
into the product's domain model.

## The protocols solve different boundaries

| Boundary | Relevant technology | Purpose |
|---|---|---|
| Agent runtime | Genkit, ADK-style frameworks, Dartantic | Runs model/tool loops, workflows, memory, approvals, and telemetry |
| Agent/host ↔ tools and data | MCP | Discovers and invokes tools, prompts, and resources |
| Editor/workbench ↔ coding agent | ACP | Carries sessions, prompts, streamed updates, permissions, file access, and terminal requests |
| Agent ↔ remote agent | A2A | Discovers agents and manages messages, tasks, artifacts, streaming, and long-running work |
| Agent backend ↔ application UI | AG-UI | Streams run, text, tool, reasoning, activity, and shared-state events |
| Agent → constrained generated UI | A2UI / Flutter GenUI | Describes UI from a client-owned catalog without generating executable widget code |

MCP, ACP, and A2A are complementary rather than competing abstractions. The
[official A2A comparison](https://github.com/a2aproject/A2A/blob/main/docs/topics/a2a-and-mcp.md)
likewise describes MCP as the tool/resource boundary and A2A as the
agent-collaboration boundary.

## MCP

### Upstream state

MCP `2026-07-28` is a major breaking revision. It removes the mandatory
`initialize` / `initialized` lifecycle and session ID header in favor of a
stateless request core, moves tasks to an extension, and deprecates roots,
sampling, logging, and legacy HTTP+SSE. The official announcement is the most
useful migration summary: [MCP 2026-07-28](https://blog.modelcontextprotocol.io/posts/2026-07-28/).

The MCP project's [official SDK list](https://modelcontextprotocol.io/docs/2026-07-28/sdk)
does not include Dart. It currently gives Tier 1 status to TypeScript, Python,
C#, and Go, with other official languages in lower tiers.

### `mcp_dart`: broadest current Dart implementation

- Current stable package: [`mcp_dart` 2.4.0](https://pub.dev/packages/mcp_dart),
  published by the verified `leehack.com` publisher.
- Source: [`leehack/mcp_dart`](https://github.com/leehack/mcp_dart).
- Scope: client, server, and host APIs; stdio, Streamable HTTP, legacy HTTP+SSE,
  and custom streams; OAuth and transport-security helpers; Flutter recipes;
  compatibility profiles for both the stateless 2026 protocol and older
  initialization-based peers.
- Protocol status: the project states that 2.4.0 implements the complete core
  client/server wire surface of MCP `2026-07-28`, passes the official alpha
  conformance suites, and interoperates with published TypeScript and Python
  SDKs.
- Governance caveat: it is a community SDK and explicitly says its Tier 1
  application has **not** yet been assigned. Treat its conformance claims as
  strong evidence, not an upstream support guarantee.
- Platform caveat: browser and Flutter Web cannot spawn stdio servers; mobile
  needs an app-managed native helper for stdio. Remote Streamable HTTP client
  use is the natural mobile/web path.

This is the best Dart protocol foundation when latest-spec coverage, remote
transport, auth, or both client and server roles matter today. Pin a known
release and retain interoperability/conformance fixtures in the consuming
project.

### `dart_mcp`: Dart-team implementation, narrower and experimental

- Current package: [`dart_mcp` 0.5.2](https://pub.dev/packages/dart_mcp),
  published by `labs.dart.dev` and maintained in
  [`dart-lang/ai`](https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp).
- The package labels itself experimental.
- It supports both client and server roles, core tools/resources/prompts,
  roots, and sampling, but its current matrix reports no cancellation,
  incomplete pagination, no Streamable HTTP, and no authorization. It is
  primarily aimed at local stdio usage.
- Its documented protocol range ends in the initialization-era 2025 revision,
  not the new stateless `2026-07-28` core.

Use this when Dart-team ownership is more important than feature breadth, or
for small local stdio integrations. It is not currently the stronger base for
a remote, security-sensitive MCP host.

### Genkit's MCP integration

Google's [`genkit_mcp` 0.2.4](https://pub.dev/packages/genkit_mcp) is a
first-party Genkit Dart plugin. It can expose Genkit tools, prompts, and
resources as a server, connect as a client, or aggregate multiple servers as a
host over stdio or Streamable HTTP. Its declared protocol target is
`2025-11-25`, one revision behind the new stateless MCP core.

This is the shortest path when Genkit is already the runtime. Put it behind an
adapter so that moving to `mcp_dart`, or to a future updated Genkit plugin,
does not leak wire types into agent logic.

### Dart and Flutter development MCP server

`dart mcp-server` is an official, experimental **server product**, not a
general MCP SDK. It exposes analysis, symbol lookup, package management,
tests, formatting, running-app inspection, screenshots, input, and hot reload
to compatible assistants. It requires Dart 3.9 or later and currently uses
stdio. Its [official Flutter documentation](https://docs.flutter.dev/ai/mcp-server)
is useful both as a ready-made tool server and as evidence that Dart/Flutter
tooling is already adopting MCP.

## ACP

### Upstream state

ACP connects code editors and coding agents. The official wire protocol is
currently `1`; `2` is draft. The upstream repository recommends generating
SDKs from released JSON Schema artifacts and warns that schema artifact
versions are distinct from the negotiated wire `protocolVersion`:
[`agentclientprotocol/agent-client-protocol`](https://github.com/agentclientprotocol/agent-client-protocol).
The latest stable schema artifact observed during this review is
`schema-v1.20.0` from 2026-07-21; `v2.0.0-alpha.2` is prerelease in the
[official releases](https://github.com/agentclientprotocol/agent-client-protocol/releases).

ACP's official library list covers Kotlin, Java, Python, Rust, and TypeScript.
There is no organization-owned Dart SDK. The project lists `acp_dart` under
[community libraries](https://agentclientprotocol.com/libraries/community).

### Dart choices

| Package | Ownership and status | Useful surface | Main caveat |
|---|---|---|---|
| [`acp_dart` 0.4.0](https://pub.dev/packages/acp_dart) | Personal repo [`SkrOYC/acp-dart`](https://github.com/SkrOYC/acp-dart); unverified pub uploader; last package/source update 2026-03-06; ACP-listed community library | Agent and client roles, typed schema/RPC unions, stdio NDJSON, cancellation, stable and selected unstable methods | It calls itself “official,” but upstream categorizes it as community-maintained; pre-1.0 and predates schema-v1.20.0 |
| [`acp` 0.1.0-rc.3](https://pub.dev/packages/acp) | Personal repo [`HelgeSverre/dart-agentclientprotocol`](https://github.com/HelgeSverre/dart-agentclientprotocol); verified publisher; last source update 2026-05-25; package is unlisted | Generated types, strict capabilities, cancellation, forward-compatible unknown unions, stdio/process, HTTP+SSE, Streamable HTTP, VM/browser WebSocket, reconnect transport | RC/unlisted and targets its checked-in ACP v0.12.0 schema rather than the current schema artifact |
| [`dart_acp` 0.1.1](https://pub.dev/packages/dart_acp) | [`csells/dart_acp`](https://github.com/csells/dart_acp); verified publisher; last update 2025-11-29 | Higher-level client/CLI, filesystem/terminal/permission providers, streaming/replay, experimental compliance tooling | Client-oriented, dormant relative to current ACP changes, and not listed by ACP upstream |

For a production Dart ACP implementation, use the official released schema as
the source of truth and generate immutable sealed models/unions. `acp_dart` is
the upstream-listed community scaffold; `acp` has the more interesting
transport and forward-compatibility design. In either case, resync the schema,
add golden wire fixtures against a current official SDK, and own the parity
tests.

Local ACP is fundamentally desktop/server oriented because the client spawns a
coding-agent subprocess and may service privileged filesystem and terminal
requests. A Flutter mobile or web client should use a remote HTTP/WebSocket
transport and keep those privileged capabilities in a backend or desktop
helper.

## A2A

### Upstream state

A2A is now hosted by the Linux Foundation and was originally contributed by
Google. The current protocol release is v1.0.1; v1.0 introduced substantial
breaking changes. The canonical sources are the
[A2A specification](https://a2a-protocol.org/latest/) and
[`a2aproject/A2A` releases](https://github.com/a2aproject/A2A/releases).

The project supplies official Python, JavaScript/TypeScript, Java, .NET, Go,
and Rust SDKs, but no Dart SDK. Its
[project overview](https://github.com/a2aproject) also provides an official
Technology Compatibility Kit and inspector.

### Dart `a2a` package

- Current package: [`a2a` 4.3.1](https://pub.dev/packages/a2a), published
  2026-08-07 by verified publisher `darticulate.com`.
- Source: [`shamblett/a2a`](https://github.com/shamblett/a2a).
- It is active and substantial: typed models, a client and CLI, a Darto-based
  server/executor, agent cards, tasks, SSE streaming/resubscription, and push
  notification APIs.
- Critical gap: its own protocol notes say it implements **A2A v0.3**, supports
  only JSON-RPC, omits protocol authorization and authenticated extended agent
  cards, and always treats server send-message as blocking.
- pub.dev currently marks Android, iOS, Linux, macOS, and Windows, but not web.

Use this package for v0.3 peers, prototypes, and implementation reference—not
as evidence of A2A v1.0.1 compatibility. For current production A2A, either:

1. bridge Flutter/Dart over HTTP to a service using an official SDK; or
2. generate Dart types from the canonical v1 proto, implement a v1 client
   first, then validate against the official
   [`a2a-tck`](https://github.com/a2aproject/a2a-tck) and
   [`a2a-inspector`](https://github.com/a2aproject/a2a-inspector) before adding
   server task storage and push delivery.

## Flutter-facing interoperability

### AG-UI

AG-UI is a bidirectional, event-based boundary between an agent backend and a
user-facing application. It carries lifecycle, text, tool, reasoning, activity,
message snapshot, and JSON Patch state events. It does not define the agent's
internal reasoning loop. See the [official AG-UI overview](https://docs.ag-ui.com/).

[`ag_ui` 0.3.0](https://pub.dev/packages/ag_ui) is published by
`community.ag-ui.com` and maintained as part of the AG-UI project. It supports
all Dart/Flutter platforms and provides a typed HTTP/SSE client, event codecs,
shared-state reduction, and tool/generative-UI interactions. It is the most
direct starting point for a Flutter-native agent console.

Important pre-1.0 caveats from its own documentation:

- cancellation stops delivery to the Dart stream but does not necessarily
  abort the underlying HTTP socket;
- deserialization accepts camelCase and snake_case but serialization always
  emits camelCase, which matters when Dart is used as a strict proxy; and
- the SDK is a client/event layer, not a durable workflow runtime.

### A2UI and Flutter GenUI

Flutter's first-party [`genui` 0.10.1](https://pub.dev/packages/genui),
published by `labs.flutter.dev`, composes runtime UI from a developer-owned
widget catalog and currently implements A2UI v0.9. The
[`flutter/genui` repository](https://github.com/flutter/genui) labels the
package **highly experimental** and warns that APIs may change drastically.

This is relevant when the agent should render a form, card, chart, or other
constrained UI, but it is not an agent runtime or replacement for ACP/A2A.
Pin the version and isolate it behind a catalog adapter. For Desy specifically,
that adapter should resolve existing registry IDs to the consumer's real
widgets; it must not create a second component inventory or accept executable
Dart/callbacks from the wire. This follows the repository's “one declared
system,” “real widgets,” typed-interface, and local-first principles.

## Agent runtimes and frameworks

### Recommended baseline: Genkit Dart

[`genkit` 0.15.1](https://pub.dev/packages/genkit) is a Google-built preview
for pure Dart and Flutter. It supports all Dart/Flutter platforms and provides
multi-provider plugins, typed structured output, tools, streaming, flows,
human-in-the-loop interrupts, middleware, a local developer UI, and
OpenTelemetry. The source lives in
[`genkit-ai/genkit-dart`](https://github.com/genkit-ai/genkit-dart).

Its strengths are runtime structure and first-party stewardship, not complete
multi-agent protocol coverage. Pair it with protocol adapters rather than
treating its flow/action transport as a universal agent protocol.

### Community alternatives

- [`dartantic_ai` 3.4.2](https://pub.dev/packages/dartantic_ai) is an active,
  multi-provider, all-platform community agent framework with multi-step tool
  calling and `mcp_dart` integration. It is a reasonable lighter-weight choice
  when provider independence is the priority.
- [`adk_dart` 2026.7.30](https://pub.dev/packages/adk_dart) and
  `flutter_adk` are an unusually broad community port of Google ADK concepts,
  including runners, multi-agent workflows, MCP, A2A, sessions, evaluation,
  and telemetry. The package is actively updated but comes from the personal
  [`adk-labs/adk_dart`](https://github.com/adk-labs/adk_dart) organization and
  an unverified pub uploader. Google's official ADK repositories currently
  point to Python, Java, and Go—not Dart. Treat its claimed parity matrices as
  project claims requiring independent verification, and avoid presenting it
  as Google's Dart ADK.

## Recommended implementation shape

```text
Flutter UI
  ├─ AG-UI event adapter
  ├─ optional A2UI/GenUI catalog adapter
  └─ approval + credential UX
          │
          ▼
pure-Dart agent domain
  ├─ AgentRun / Turn / ToolCall / Approval / Artifact
  ├─ typed events and cancellation
  ├─ runtime port (Genkit first)
  └─ persistence and telemetry ports
          │
          ├─ MCP adapter → tools/resources
          ├─ ACP adapter → editor/coding-agent sessions
          └─ A2A adapter → remote agent tasks
```

Suggested package boundaries:

- `agent_core`: pure Dart domain objects and runtime interfaces;
- `agent_runtime_genkit`: Genkit implementation;
- `agent_protocol_mcp`: `mcp_dart` or `genkit_mcp` adapter;
- `agent_protocol_acp`: generated current-schema models and transport;
- `agent_protocol_a2a`: current-v1 client, initially perhaps a remote bridge;
- `agent_ui_agui`: AG-UI event mapping;
- `agent_ui_flutter`: widgets, permission surfaces, and optional GenUI catalog.

This arrangement makes protocol churn survivable. It also lets the Flutter app
run on every target while isolating process spawning, filesystem access,
terminal execution, local model runtimes, and server hosting in VM-only
implementations.

## What to build on now

1. **Start the agent loop with Genkit Dart** unless a small multi-provider
   abstraction such as Dartantic is a better product fit.
2. **Use `mcp_dart` behind an adapter** for current MCP protocol work. Use
   `genkit_mcp` for rapid Genkit integration only with an explicit
   `2025-11-25` compatibility decision.
3. **For ACP, contribute to or fork the upstream-listed `acp_dart`, but generate
   from the current official schema and add interop fixtures.** Borrow the
   transport and unknown-union ideas from `acp` rather than starting from raw
   JSON-RPC.
4. **Do not base new production A2A on the Dart v0.3 package.** Use an official
   SDK sidecar first, or make a current-v1 Dart client a deliberate standalone
   package validated with the TCK.
5. **Use AG-UI for Flutter run/event delivery and A2UI only for constrained
   catalog-backed UI.** Keep permission checks, credential storage, and
   executable tools outside generated UI payloads.

The largest opportunity for the Dart ecosystem is not another monolithic agent
framework. It is a small set of generated, conformance-tested, independently
versioned protocol packages with excellent Flutter-safe client surfaces.
