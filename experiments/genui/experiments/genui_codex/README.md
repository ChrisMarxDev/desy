# genui_codex experiment

Desktop-only `genui` transport backed by a child `codex app-server` process.
It is not A2A or ACP: outbound requests use Codex JSON-RPC, while inbound UI
uses canonical A2UI v0.9 messages.
