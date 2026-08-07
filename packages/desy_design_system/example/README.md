# Desy Design System catalogue

This executable is the inside-out dogfood consumer: it catalogues the design
system used to build the catalogue workbench itself.

Its registry is intentionally owned by this app rather than by
`desy_design_system`. That keeps the dependency graph acyclic:

- `desy_design_system` owns real production foundations and widgets.
- `desy_bench` consumes those widgets for workbench chrome.
- this app imports both and passes `desyDesignSystemRegistry` to
  `DesyBenchApp`.

The dogfood executable also installs `DesyAgentAnnotationsExtension` in every
registry-entry detail. On macOS, the first annotation opens a native Save
dialog for one Markdown file (suggested name: `desy-agent-annotations.md`). Every later
annotation in that app session is appended to the same file, and the success
receipt shows its `file:` URI so the file can be handed to an agent. Other
platforms use a non-persistent demonstration callback. Tests and deployments
can inject another callback through
`buildDesyDesignSystemDogfoodApp(onSubmit: ...)`.

Run it from the repository root with `task dogfood:run_mac` or
`task dogfood:web`.
