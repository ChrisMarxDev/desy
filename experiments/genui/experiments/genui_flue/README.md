# genui_flue experiment

An intentionally small, direct bridge between Flutter GenUI and a Flue agent.
It proves the actual seam without introducing A2A, AG-UI, MCP, or a custom
TypeScript proxy.

## The two required components

1. **Dart driver** (`lib/src/flue_genui_driver.dart`) posts a `ChatMessage` to
   one Flue conversation, reads the response from Flue's native SSE updates
   stream, sends only text A2UI deltas to `A2uiTransportAdapter`, and exposes
   reasoning/tool lifecycle data on a separate telemetry stream.
2. **Flue agent** (`flue/src/orbit_agent.ts`) is the TypeScript runtime that
   owns model selection, tools, credentials, and authorization. It has one
   harmless fixture tool today; real Jira/GitHub/calendar integrations belong
   here (or behind MCP connections), never in Flutter.

There is deliberately **no extra TypeScript proxy**. The Dart driver speaks
Flue's documented `POST /:id` admission plus `GET /:id?view=updates&live=sse`
protocol directly. A future gateway is justified only for cross-provider
normalization, shared authorization, or hiding the Flue protocol from clients.

```text
Flutter Conversation
  -> FlueGenUiDriver / A2uiTransportAdapter
  -> POST /agents/orbit/<conversation-id>
  <- GET  /agents/orbit/<conversation-id>?view=updates&live=sse
       |- text deltas      -> A2UI parser -> SurfaceController
       |- reasoning/tools  -> telemetry   -> normal app UI
```

## Run the agent

```sh
cd experiments/genui/experiments/genui_flue/flue
npm install
cp .env.example .env
npm run dev
```

The Vite server defaults to `http://localhost:5173`; a Dart endpoint should
include a stable conversation id, for example:

```dart
final driver = FlueGenUiDriver.start(
  endpoint: Uri.parse('http://localhost:5173/agents/orbit/orbit-local'),
  catalog: catalog,
  systemPromptFragments: const ['Render an actionable workspace view.'],
);
final conversation = Conversation(
  controller: surfaceController,
  transport: driver.transport,
);
```

The caller renders `Surface` widgets through `surfaceController` and listens to
`driver.telemetry` for tool activity. The current Orbit sample deliberately
does not select this driver yet: the next step is wiring this transport through
its provider-neutral `GenUiBackend` boundary after we choose whether the app
should use streamed native GenUI surfaces or preserve its current complete-tree
backend contract.

## Verification

```sh
task genui_flue:analyze
task genui_flue:test
cd experiments/genui/experiments/genui_flue/flue && npm run check
```

References: [Flutter GenUI provider integration](https://docs.flutter.dev/ai/genui/get-started), [Flue streaming protocol](https://flueframework.com/docs/reference/streaming-protocol/), and [Flue tools](https://flueframework.com/docs/guide/tools/).
