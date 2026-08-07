# Sample Design System

This is a runnable Flutter application and the reference consumer for
`desy_bench`. Its registry, themes, and production widgets all live under
`lib/src/`; Desy Bench only renders them.

Run it from this directory:

```sh
flutter run
```

To launch the browser version in Chrome, run:

```sh
task web
```

To create a deployable production build, run `task web:build`. From the
repository root, the same commands are available as `task sample:web` and
`task sample:web:build`.

## Agent annotation sample

The sample registers `DesyAgentAnnotationsExtension` through
`DesyBenchApp.detailExtensions`. On macOS its consumer-owned callback writes
Markdown files under `.desy/agent_annotations/` in a repository the user
selects through the sandboxed macOS folder picker. The canonical selection is
cached only by the callback for the running session; cancellation opens the
picker again on the next submission. The sample stores no security-scoped
bookmark. Conditional imports keep that `dart:io` adapter out of the web
build, and neither `desy_agent_annotations` nor `desy_bench` receives filesystem
privileges.

The callback publishes atomically: it writes and flushes a same-directory
pending file claimed with exclusive creation, then renames it to a `.md`
filename with a fresh random 128-bit token. This is UUID-style probabilistic
uniqueness, not a filesystem-wide no-clobber guarantee. Cleanup touches only
the pending file owned by that invocation. Its output directory is fixed, and
existing `.desy` or `agent_annotations` symlinks are rejected rather than
followed.

Hosted deployments should replace the checked-in, deliberately unconfigured
web callback with `createHostedGitHubIssueSubmit(createIssue: ...)`. The
`createIssue` function calls an authenticated server-side endpoint and returns
the public GitHub issue URI. Never embed a GitHub token in Flutter web code.

Platform compilation is maintained through Taskfile commands:

```sh
task compile:web
task compile:macos # macOS only
```

From the repository root these are `task sample:compile:web` and
`task sample:compile:macos`. The canonical `task check` includes the production
web compile; the macOS compile remains an explicit platform gate.
