# Orbit — Desy GenUI experiment

Orbit is the desktop experimentation app for `desy_genui`. It takes an
app-owned chat prompt, asks a backend for an A2UI component graph, and renders
that graph using the application's own real Flutter widgets.

It is a deliberate replacement for the old Material-shaped demo. Orbit uses a
Shadcn-inspired semantic foundation and [Mix](https://pub.dev/packages/mix)
for its reusable surface styling; it does not render `MaterialApp`, `Scaffold`,
`TextField`, `InkWell`, Material icons, or Material progress indicators.

## Orbit design system

`lib/orbit/` is a separate consumer-owned design system:

- `orbit_theme.dart` defines the semantic light and dark palettes, typography,
  spacing, radius, motion, focus treatment, pointer cursors, native editable
  text area, buttons, badges, progress, and spinner.
- `orbit_components.dart` defines the generated-content vocabulary: insight,
  task list and row, recommendation, approval request, tool activity, metric
  grid and tile, source card, and response stack.
- `orbit_registry.dart` registers those exact widgets with Desy under stable
  IDs and validated paths. The registry has two real themes: Midnight and
  Daylight.

The app shell owns chat input, backend communication, shortcut policy, and
business routing. Generated UI owns only declared component props, legal child
slots, and emitted events. `DesyGenUiCatalog.compile(orbitRegistry)` produces
the executable Flutter catalog and serializable backend artifact from that one
registry.

Desktop interaction is intentionally explicit:

- buttons expose focus, hover, disabled, pointer-cursor, semantic, and
  keyboard activation states;
- the composer is native `EditableText`, retaining selection, IME, and assistive
  technology behavior;
- `Ctrl/⌘ + K` focuses the composer and `Ctrl/⌘ + Enter` generates a response;
- agent updates use a live semantic region, while approval and recommendation
  events remain typed GenUI actions.

The component choices take inspiration from the compact agent patterns at
[Beautiful UI](https://www.beautifului.dev/), without copying its code or
assets. The token roles and neutral defaults follow
[Shadcn's theming model](https://ui.shadcn.com/docs/theming).

## Configure OpenAI

From `genui/example`, copy `.env.example` to `.env`:

```dotenv
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-5-mini
GENUI_SERVER_PORT=8787
```

The secret stays in the loopback-only Dart server, not in the Flutter web app.

## Run

From the workspace root, start the local backend and then the Chrome app:

```sh
task genui_example:server
task genui_example:run
```

The backend receives the catalog artifact, digest, and either a prompt or a
typed generated-UI action. It returns one complete A2UI surface, which Orbit
swaps into the conversation. Generated actions are forwarded by default;
`DesyGenUiExampleApp.shouldForwardAction` lets a production consumer keep
navigation, persistence, and other business actions local.

The included server is a development bridge: loopback-only, unauthenticated,
and permissive-CORS. Keep the `GenUiBackend` boundary when replacing it with an
authenticated production gateway.

## Local Codex experiment

On macOS, the example can also launch `codex app-server` itself; no Shelf
server or API key is involved. It uses the signed-in local Codex CLI, asks it
for a JSON-schema-constrained A2UI response, and only applies decoded A2UI
messages. This experiment is desktop-only and uses read-only/no-approval Codex
turns. Its macOS runner is deliberately **not App-Sandboxed**, because App
Sandbox prevents an application from spawning the local Codex executable.
Ensure `codex` is on `PATH`, then run:

```sh
task genui_example:run:codex
```

The reusable experiment is deliberately separated from Orbit:

- `experiments/codex_app_server/`: pure-Dart Codex app-server JSON-RPC client.
- `experiments/genui_codex/`: GenUI-to-Codex adapter emitting A2UI.
- `lib/experiments/codex/`: Orbit's thin adapter to its existing demo backend.

## Run Orbit in Desy Bench

Orbit's GenUI catalog and its Desy workbench use the same `orbitRegistry`.
Launch the registry in the Desy Bench workbench with:

```sh
task genui_example:run:bench
```
