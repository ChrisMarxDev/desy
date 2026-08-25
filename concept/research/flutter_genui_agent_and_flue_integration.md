# Flutter GenUI: agent, tool, and Flue integration seams

Research date: 2026-08-24  
Scope: official Flutter/GenUI, A2UI, and Flue documentation only. This is an
implementation investigation, not a commitment to a backend choice.

## Short answer

Flutter GenUI is **not an agent runtime or a backend**. It is a Flutter-side
runtime that constrains and renders agent-produced UI from an app-owned catalog.
The backend/provider boundary is deliberately open, so an app can use a direct
model client, a local agent, or a remote agent service. The integration must
bridge that agent's input and stream into GenUI's `A2uiTransportAdapter`, and
the agent must emit valid A2UI messages that name only catalogued components.

That means a Flue agent is viable, but there is no documented ready-made
`genui_flue` or A2UI adapter. Flue needs a small application-owned bridge that
turns its HTTP/SSE conversation stream into A2UI text/messages for GenUI. Do
not make Flutter understand Flue's complete native event protocol.

## What GenUI owns versus what it does not

| Concern | Owner |
| --- | --- |
| Actual Flutter widgets, schemas, and the allowed UI vocabulary | App-owned `Catalog` / `CatalogItem` |
| Applying A2UI operations; surfaces and local reactive data | `SurfaceController` and `DataModel` |
| User turn/action loop and parsing incoming A2UI | `Conversation` and `A2uiTransportAdapter` |
| Model choice, agent loop, tool calls, credentials, authorization, persistence | Application/provider/agent backend |
| A2UI JSON transport | Any adapter; A2A is one optional choice |

Flutter documents `Catalog` as the allowed widget set, `DataModel` as the
observable state store, `A2uiTransportAdapter` as the raw-stream parser, and
`SurfaceController` as the A2UI/state manager. UI actions create a follow-up
user message carrying current state and restart the turn. [Flutter GenUI
components](https://docs.flutter.dev/ai/genui/components)

So it is **more than a single system prompt**: the client must have the catalog
and widget builders, handle the A2UI state/action protocol, and keep a transport
connection. `PromptBuilder` is a useful helper that derives prompt material
from the catalog, but GenUI cannot know how an arbitrary provider accepts or
persists system instructions. The application's adapter must pass that prompt
or equivalent structured capability data to its selected agent. Flutter's
guide explicitly says to build a `PromptBuilder`, include the tools supplied by
`SurfaceController`, and add the result to the LLM system prompt. [Flutter
GenUI get-started](https://docs.flutter.dev/ai/genui/get-started)

`PromptBuilder.chat()` may be 3,000–5,000+ tokens; use a compact tailored
instruction or selected prompt fragments for small/local models. [Flutter
GenUI get-started](https://docs.flutter.dev/ai/genui/get-started)

## The two supported integration shapes

### 1. Any callable model or agent: custom transport

This is the most general route. Create `A2uiTransportAdapter(onSend: ...)`.
In `onSend`, forward the `ChatMessage` to the chosen provider/agent; as it
streams text, call `transport.addChunk(...)`. The adapter parses text into
A2UI messages and sends them to the controller. Flutter presents this as the
way to connect another agent provider. [GenUI package README](https://github.com/flutter/genui/blob/main/packages/genui/README.md)

Use it for a local Codex bridge, Ollama, a custom HTTP service, or Flue. The
chosen system must either generate A2UI JSON in its text stream or the bridge
must translate its native output into A2UI before it reaches GenUI. A provider
which cannot be called from Dart must sit behind a local/remote service; that
does not change the GenUI integration boundary.

### 2. A remote A2A agent that supports the A2UI extension: `genui_a2a`

`genui_a2a` is an optional connector for an A2A server that implements the
A2UI streaming extension. It is not a generic adapter for every agent HTTP API
and it does not turn a bare local Codex/Flue endpoint into an A2A agent. The
server needs the corresponding A2A/A2UI contract; the A2UI extension uses
`application/a2ui+json` parts and exchanges catalog capabilities. [GenUI A2A
package](https://pub.dev/packages/genui_a2a), [A2UI A2A
extension](https://github.com/a2ui-project/a2ui/blob/main/specification/v0_9/docs/a2ui_extension_specification.md)

## Protocol map

```text
Flutter GenUI                         Application-owned agent service
---------------                        --------------------------------
Catalog + real widgets   <------->    catalog prompt / capability artifact
SurfaceController        <--- A2UI --- output adapter / validator
DataModel                --- action -> agent input and tool loop
A2uiTransportAdapter     <-- stream -- HTTP, SSE, WebSocket, or A2A binding
                                      |
                                      +-- Flue / Codex / other runtime
                                      +-- Jira, calendar, GitHub, etc. tools
```

- **A2UI** is the declarative agent-to-client UI format: it creates/updates
  surfaces and data, while the Flutter app resolves those declarations to its
  own native widgets. It is not a model API or backend framework. [A2UI
  architecture](https://github.com/a2ui-project/a2ui)
- **A2A** is one optional agent-to-agent transport/binding. It can carry A2UI,
  but is not required for GenUI. [A2UI transport
  decoupling](https://github.com/a2ui-project/a2ui/blob/main/specification/v0_9/docs/a2ui_protocol.md)
- **MCP** is a useful agent-to-tool/resource protocol; it is separate from
  GenUI/A2UI. A backend can use MCP tools and return A2UI to the Flutter app.

## How Flue fits

Flue is a TypeScript agent runtime for Node and Cloudflare. Its agent functions
declare model, tools, skills, state, and remote MCP connections through hooks.
`defineTool` plus `useTool` registers model-callable tools, and
`useMcpConnection` mounts remote MCP-server tools. [Flue agent
hooks](https://flueframework.com/docs/reference/agent-hooks-api/), [Flue Agent
API](https://flueframework.com/docs/reference/agent-api/)

Its HTTP router admits a conversation message with `POST /:id` and exposes
incremental updates through SSE. Those events include text deltas, reasoning
deltas, named data parts, and tool lifecycle events. [Flue streaming
protocol](https://flueframework.com/docs/reference/streaming-protocol/)

Recommended bridge:

1. Flutter sends a user message/action to a small Flue-facing endpoint.
2. The bridge supplies the Flue agent with the versioned catalog prompt (or
   equivalent capability artifact) and an instruction to emit A2UI.
3. Flue calls approved tools—Jira, calendar, GitHub, etc.—under server-side
   credentials and authorization.
4. The bridge consumes the Flue SSE stream. It sends only the ordered A2UI
   output to `A2uiTransportAdapter.addChunk()` (or decoded messages to the
   corresponding structured API).
5. It exposes Flue text, reasoning, and tool progress in a **parallel**, normal
   app UI stream. They should not be passed to the A2UI parser as if they were
   UI commands.

Flue supports custom model providers using Pi's `Provider` contract and
`setProvider()`, including custom endpoints. That is a Flue model-selection
concern; it remains independent of the GenUI client. [Flue provider
API](https://flueframework.com/docs/reference/provider-api/)

## Tools and generated UI

GenUI does not supply Jira or other external application tools. Add those to
the **agent backend** (direct tools or MCP servers), enforce the user's auth
and approvals there, then let the agent turn the tool result into a catalog-safe
A2UI view. The UI catalog remains a client security boundary: it maps declared
component types to developer-owned widgets rather than accepting generated Dart
code. [A2UI architecture](https://github.com/a2ui-project/a2ui)

For a multi-app personal cockpit, the useful first vertical slice is:

1. a Flue (or local Codex) agent with read-only Jira/GitHub/calendar tools;
2. a small, task-focused catalog: status card, list, filters, approval row,
   and link/action buttons;
3. A2UI output for the agent's selected view;
4. deterministic client/backend requests for refresh, pagination, and direct
   actions—without invoking the model for every interaction.

This last point is native to the model: A2UI separates component-tree updates
from data-model updates, and GenUI rebuilds only widgets bound to changed data.
An app/backend can update known data directly and reserve the model for
planning, UI composition, interpretation, or exceptional transitions. [Flutter
GenUI data model](https://docs.flutter.dev/ai/genui/get-started), [A2UI
protocol](https://github.com/a2ui-project/a2ui/blob/main/specification/v0_9/docs/a2ui_protocol.md)

## Practical recommendation for this exploration

Build one application-owned `GenUiAgentTransport` interface with adapters such
as `CodexTransport`, `FlueTransport`, and `FixtureTransport`. Each adapter
normalizes a turn to ordered text/A2UI events and keeps provider-specific
reasoning/tool telemetry separate. Start with the custom adapter route; add
`genui_a2a` only if the selected agent actually implements A2A plus the A2UI
extension. This keeps the Flutter app portable across agent runtimes while
preserving the same catalog and renderer.

## Compatibility note

GenUI is alpha/experimental and its API changes quickly. Pin the package
version, isolate integration code, and validate captured A2UI fixtures when
upgrading. [Flutter GenUI get-started](https://docs.flutter.dev/ai/genui/get-started),
[GenUI changelog](https://pub.dev/packages/genui/changelog)
