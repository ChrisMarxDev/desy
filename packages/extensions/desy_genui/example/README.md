# Desy GenUI OpenAI sample

This Flutter app compiles Desy's maintained dogfood registry into a real GenUI
`Catalog`, feeds typed A2UI v0.9 messages to `SurfaceController`, and renders
the surface with the real Desy theme. A small loopback-only Dart server calls
OpenAI's Responses API and keeps the API key outside the Flutter web build.

## Which Desy project does it use?

This executable directly uses `desyDesignSystemRegistry` from
`packages/desy_design_system/example/lib/src/desy_design_system_registry.dart`.
There is no second sample registry. The same declarations drive the maintained
workbench catalogue, backend artifact, runtime GenUI builders, and this chat.

The dogfood registry includes real `DesyChatThread`, `DesyChatMessage`, and
`DesyChatComposer` components. Agent output uses Desy's signal-pink inspection
trace, prompts use the recessed panel surface, and submission uses Desy's
native text field plus primary action.

## Configure OpenAI

From `packages/extensions/desy_genui/example`, copy `.env.example` to `.env`
on a fresh checkout and put the secret only in `.env`:

```dotenv
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-5-mini
GENUI_SERVER_PORT=8787
```

`.env` and environment variants are ignored workspace-wide; `.env.example` is
the explicitly committed exception. Shell environment values override `.env`.

## Run

Start the provider server in one terminal from the workspace root:

```sh
task genui_example:server
```

Then start the Flutter web app in another terminal:


```sh
task genui_example:run
```

`run` targets Chrome explicitly, so Flutter will not select an iOS device or
download iOS artifacts. Enter a prompt and choose **Generate UI**. The app sends
the serializable `compiled.backendArtifact`; the server derives a strict output
schema from it and returns a complete component tree. Only the app retains
Flutter widget builders. The server sees schemas, prompts, examples, version,
and digest.

## Generated UI events

An event emitted by generated UI is not only displayed by the sample. The app
parses GenUI's A2UI v0.9 interaction envelope into a typed `GenUiAction`, then
creates a `GenUiActionTurn` containing the action and the complete current
component surface. The backend sends that structured continuation to the model
and the returned component graph replaces the active surface.

This agent-only sample forwards generated user actions by default. Applications
that mix generated UI with business logic can supply `shouldForwardAction` to
`DesyGenUiExampleApp` and keep navigation, persistence, or other named actions
local. Desy only declares and dispatches the event; the application continues
to own its meaning and forwarding policy.

The loopback server and permissive development CORS header are for local
experimentation. A deployed app should use an authenticated backend and keep
the same `GenUiBackend` client boundary.
