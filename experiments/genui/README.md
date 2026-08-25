# GenUI exploration

This experimental workspace area contains all GenUI work. It is kept in the
repository with Desy, but it is not part of Desy's core product surface.

- `desy_genui/` is the optional adapter from a consumer-owned `DesyRegistry`
  to a Flutter GenUI catalog.
- `example/` is Orbit, the standalone GenUI demo app and its consumer-owned
  Orbit design system.
- `experiments/codex_app_server/` is a pure-Dart client for local Codex
  app-server JSON-RPC.
- `experiments/genui_codex/` maps local Codex turns to GenUI/A2UI messages.
- `experiments/genui_flue/` is a direct Flutter GenUI-to-Flue HTTP/SSE bridge,
  with a small Flue tool-owning TypeScript agent.

The workspace tasks remain `genui:*`, `genui_example:*`,
`codex_app_server:*`, and `genui_codex:*` while the experiments mature.
