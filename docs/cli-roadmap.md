# Desy CLI roadmap

The CLI is on hold while `desy_bench` proves its registry and embedding API in
the sample consumer. When that contract is stable, `desy_cli` should provide:

- `desy init` to add a consumer-owned registry template.
- `desy run` to launch a configured workbench target.
- `desy verify` to validate registry contracts and run configured checks.

The CLI must never become the source of truth; generated files and consumer
registries stay in the consuming repository.
