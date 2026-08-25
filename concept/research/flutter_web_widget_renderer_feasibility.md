# Rendering new Flutter widget code for shared Desy workshops

Research date: 2026-08-10. This report considers only solutions that compile and run real Dart/Flutter source. It deliberately excludes RFW, a custom UI DSL, schema-driven renderers, and Flutter-like subsets. Sources are limited to official Flutter/Dart documentation and repositories, official GitHub documentation, and official Cloudflare documentation.

## Executive conclusion

This is feasible, but **not as a Dart evaluator inside the already-running Desy app**.

The viable renderer boundary is a separately compiled Flutter web application:

1. Desy or a GitHub revision supplies actual Flutter source.
2. A Flutter toolchain compiles a small preview application containing that source, its dependencies, assets, and the consumer's real theme wrapper.
3. Desy embeds the resulting preview URL in an isolated web element, preferably an iframe on a separate origin.
4. A workshop session stores immutable build/revision IDs alongside choices, comments, and presence. Every collaborator sees the same compiled build, while the collaborative state remains outside the preview app.

The best MVP is therefore a **remote, per-session Flutter build sandbox plus immutable web preview artifacts**. Keep the desktop/local workflow as the primary authoring path; add hosted compilation only when someone explicitly asks to share a workshop. This preserves Desy's local-first model while making sharing and later multiplayer possible.

An in-browser compiler is not a reasonable Desy MVP. The official toolchain exposes command-line compilers, and DartPad itself uses a server backend for analysis and compilation. A GitHub Actions-only version is feasible and much simpler operationally, but its job scheduling and clean-runner model make it a commit-preview system rather than an interactive workshop loop.

## What Flutter web gives us

Flutter compiles the framework and application together into deployable browser code. Default web builds compile Dart to JavaScript and render with CanvasKit; `flutter build web --wasm` also builds the Wasm/Skwasm path with CanvasKit fallback. The build output is static and can be served by a normal web server. Flutter web also supports hot reload and hot restart in debug mode. Sources: [Flutter web architecture](https://docs.flutter.dev/platform-integration/web), [web build modes and renderers](https://docs.flutter.dev/platform-integration/web/renderers), [web deployment](https://docs.flutter.dev/deployment/web), and [hot reload](https://docs.flutter.dev/tools/hot-reload).

Flutter can also be embedded within existing web content, and a Flutter web app can reserve a widget-sized region for arbitrary HTML content through `HtmlElementView`. Consequently, a web Desy shell can display a separately hosted preview app inside its canvas. Sources: [embedding Flutter in a web application](https://docs.flutter.dev/platform-integration/web/embedding-flutter-web) and [embedding web content in Flutter web](https://docs.flutter.dev/platform-integration/web/web-content-in-flutter).

This boundary has an important consequence: **the parent Desy widget tree cannot wrap a widget living in another Flutter bundle**. An iframe has another Flutter engine/application and another Dart runtime. The exact consumer theme must be imported and invoked by the compiled preview harness itself. It does not inherit `Theme`, inherited widgets, providers, registry state, or fonts from the parent Desy app.

That is still compatible with Desy's “real widgets in real context” principle. The renderer project can compile code equivalent to:

```dart
void main() {
  runApp(
    ConsumerPreviewRoot(
      registry: createDesyRegistry(),
      themeId: const String.fromEnvironment('DESY_THEME_ID'),
      child: const CandidateHomepage(),
    ),
  );
}
```

`ConsumerPreviewRoot` must call the same public theme wrapper used by local Desy previews. It should not reproduce theme values as JSON or CSS.

## A necessary source contract

Desy can build a complete Flutter repository at a specified entrypoint, but it cannot reliably discover and construct an arbitrary widget class from an arbitrary repository. Dart imports, constructor arguments, private names, application providers, and theme selection are compile-time source decisions.

A small, repository-native entry contract is therefore unavoidable. It can remain ordinary typed Flutter code rather than a DSL or annotation system. For example, each workshop session can export one or more zero-argument `WidgetBuilder`s and reference the consumer's `DesyRegistry` or public theme wrapper. The remote harness then imports that known library. The contract can be as small as a conventional file path such as `lib/desy_workshops.dart`.

This also gives a precise answer to “render straight out of GitHub”:

- **A complete Flutter app at a commit:** yes, if it supports web and has a usable `main()` entrypoint.
- **A Desy workshop widget at a commit:** yes, if the repository exposes the small Desy entry contract.
- **Any class that happens to extend `Widget`, with no repository cooperation:** no reliable general solution.

GitHub's repository archive API accepts a branch, tag, or commit ref. Public archives need no authentication; private archives require read-level Contents permission and use temporary download URLs. A GitHub App can request only read-level Contents access. Sources: [repository archive endpoints](https://docs.github.com/en/rest/repos/contents) and [choosing GitHub App permissions](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/choosing-permissions-for-a-github-app).

## Option 1: compile inside the user's browser

### Feasibility

There is no supported official path for loading new Dart source into a running Flutter web release and obtaining a `Widget`. Dart's documented browser outputs are produced by command-line compilation (`dart compile js` / `dart compile wasm`), and Flutter's output is produced by `flutter run` or `flutter build web`. Deferred imports can download code later on the web, but the imported libraries and their names are part of the original program at compile time; they do not turn arbitrary source text into a new library. Sources: [`dart compile`](https://dart.dev/tools/dart-compile), [Dart libraries and deferred loading](https://dart.dev/language/libraries), and [Flutter web deployment](https://docs.flutter.dev/deployment/web).

DartPad is useful evidence here. It accepts real Dart and Flutter code, but its official repository contains a separate, stateless `dart_services` server that performs analysis and JavaScript compilation. It precompiles SDK artifacts and maintains a pinned, whitelisted set of supported packages. DartPad's Flutter embed uses DDC, but compilation is still a backend concern. Sources: [DartPad repository](https://github.com/dart-lang/dart-pad), [Dart Services README](https://github.com/dart-lang/dart-pad/blob/main/pkgs/dart_services/README.md), and [DartPad embedding guide](https://github.com/dart-lang/dart-pad/wiki/Embedding-Guide).

### Possible variants

1. **Embed/fork DartPad.** This runs real Flutter syntax and could be useful for self-contained sketches. To render consumer code, however, Desy would have to maintain a compatible compiler service, precompile the correct Flutter SDK, and whitelist/pin the consumer package graph. DartPad's single-snippet model does not naturally reproduce an arbitrary repository, its assets, code generation, local path packages, and theme bootstrap.
2. **Port/self-host the Flutter compiler in browser Wasm.** This is theoretically researchable but is a compiler/toolchain product of its own. It would need pub resolution, Flutter SDK artifacts, plugin registration, incremental compilation, source maps, asset assembly, and a safe module loader. It has no documented official integration surface and should not be treated as a Desy feature-sized task.

### Verdict

Reject for the initial hosted renderer. It maximizes engineering risk while giving less repository fidelity than a normal remote Flutter toolchain. A DartPad-derived compiler service is worth revisiting only for a deliberately restricted “single-file sketch” product—not for arbitrary Desy consumer repositories.

## Option 2: remote per-session Flutter sandbox

### Feasibility

High. A sandbox image can contain a pinned Flutter SDK and run the standard commands that local developers already trust:

```text
download/restore repository revision
flutter pub get
generate/select Desy preview entrypoint
flutter run -d web-server       # interactive debug session
flutter build web               # immutable share artifact
```

Cloudflare's Sandbox SDK is one concrete host for this model. It runs untrusted code in isolated Linux containers, supports file operations and background processes, and can expose an HTTP service through a preview URL. Its Docker image can be extended with additional tools, or the sandbox binary can be copied into an arbitrary base image, so a pinned Flutter toolchain image is possible. Sources: [Sandbox overview](https://developers.cloudflare.com/sandbox/), [Dockerfile customization](https://developers.cloudflare.com/sandbox/configuration/dockerfile/), [command/process API](https://developers.cloudflare.com/sandbox/api/commands/), and [exposing services](https://developers.cloudflare.com/sandbox/guides/expose-services/).

Containers start lazily. Cloudflare documents typical container cold starts in the 1–3 second range, dependent on image size and startup work; Flutter dependency restoration and compilation come after that and must be measured separately. A sandbox sleeps after ten minutes by default and loses its filesystem/process state when stopped, unless it is kept alive. Persistent inputs and artifacts therefore belong in Git/GitHub and object storage, not only in `/workspace`. Sources: [container lifecycle](https://developers.cloudflare.com/containers/platform-details/architecture/), [Sandbox lifecycle API](https://developers.cloudflare.com/sandbox/api/lifecycle/), [Sandbox lifecycle model](https://developers.cloudflare.com/sandbox/concepts/sandboxes/), and [persistent storage with R2](https://developers.cloudflare.com/sandbox/tutorials/persistent-storage/).

Cloudflare preview URLs require production routing through a custom domain/wildcard DNS, and the docs warn that exposed previews are public by default. Authentication must be added by Desy. [Cloudflare's current guidance](https://developers.cloudflare.com/sandbox/guides/expose-services/) prefers Sandbox tunnels for most public URLs.

### Recommended two-speed renderer

Use one source/build service but expose two output modes:

1. **Live workshop preview:** a warm sandbox keeps `flutter run` resident. Desy writes changed Dart files and requests hot reload through the running Flutter process. Flutter documents that command-line `flutter run` accepts `r` for hot reload and that web supports hot reload. This is the closest hosted equivalent to the local development loop. It is ephemeral and should be owner/editor-only.
2. **Share snapshot:** after an accepted iteration, run `flutter build web`, store `build/web` under an immutable content-addressed build ID, and serve it from a preview origin/CDN. Read-only viewers never depend on a warm compiler process.

This separation matters. A debug development server is not a durable public artifact. Immutable release builds are cacheable, reproducible, cheap to view, and safe to retain as the record of a workshop round.

### Dependencies, assets, fonts, and themes

A repository-faithful remote build can support the same sources as local pub: hosted, Git, SDK, and path dependencies. Pub resolves transitive dependencies and maps them through `.dart_tool/package_config.json`; Git dependencies are cloned. Sources: [using packages](https://dart.dev/tools/pub/packages) and [package dependencies](https://dart.dev/tools/pub/dependencies).

The remote checkout must include every local path package used by the consumer workspace. Assets and fonts must remain declared in the actual `pubspec.yaml`, because Flutter builds its asset bundle from those declarations. The preview harness must be placed inside, or depend on, the consumer workspace so that the same asset/package graph is compiled. Sources: [Flutter pubspec options](https://docs.flutter.dev/tools/pubspec), [assets](https://docs.flutter.dev/ui/assets/assets-and-images), and [custom fonts](https://docs.flutter.dev/cookbook/design/fonts).

Not every Flutter project is a web project. Code that calls `dart:io`, packages without a web implementation, old JS interop incompatible with Wasm, or platform-only plugins can fail to compile or run. For the UI-only goal, Desy should default to the standard JavaScript/CanvasKit web build for the widest package compatibility and treat Wasm as a later opt-in. Sources: [Flutter web FAQ](https://docs.flutter.dev/platform-integration/web/faq) and [web renderer compatibility](https://docs.flutter.dev/platform-integration/web/renderers).

### Caching

Use immutable, content-addressed cache keys rather than session names:

```text
Flutter SDK + engine revision
repository commit/tree hash
pubspec.lock hash
preview entrypoint/harness hash
theme ID and compile-time defines
build mode/renderer
```

Cache at three layers:

- Bake the pinned Flutter SDK and precached web engine into the sandbox image.
- Restore a dependency cache keyed primarily by `pubspec.lock` and SDK revision. Treat restored caches as untrusted input and never store credentials in them.
- Store successful static builds by content hash, so the same candidate/commit is built once and shared by every session.

For the static host, keep the small boot/configuration files fresh while allowing hashed JS/Wasm/assets to be cached for a long time. Flutter's web FAQ explicitly warns that stale `Cache-Control` headers can keep an old app visible and provides separate cache guidance for scripts versus immutable assets. Source: [Flutter web FAQ caching guidance](https://docs.flutter.dev/platform-integration/web/faq).

### Security boundary

Both phases execute untrusted code:

- During build, repository scripts, build hooks, dependencies, tools, and the Flutter compiler run inside the sandbox.
- During viewing, the compiled Flutter application runs JavaScript/Wasm in every viewer's browser. It can make network requests and use whatever browser capabilities its origin and embedding policy grant.

The build sandbox must therefore be separate per tenant/session, resource-limited, short-lived, and credential-free. Cloudflare documents VM-backed filesystem/process/network isolation and per-sandbox resource limits, but explicitly leaves authentication, authorization, validation, rate limiting, and application security to the developer. It also supports deny-by-default outbound traffic and trusted outbound handlers that can inject credentials without putting the real secret in the sandbox. Sources: [Sandbox security model](https://developers.cloudflare.com/sandbox/concepts/security/) and [outbound traffic controls](https://developers.cloudflare.com/sandbox/guides/outbound-traffic/).

Recommended controls:

- Fetch private GitHub archives through a trusted service/Worker or a short-lived proxy; never copy a GitHub installation token into the build filesystem.
- Deny outbound traffic by default. Temporarily allow only the dependency hosts needed for an approved `pub get`, or proxy those downloads. Re-disable it during compilation/serving.
- Apply CPU, memory, disk, wall-time, output-size, and log-size quotas.
- Serve previews from an origin with no Desy cookies, local storage, service-worker scope, or API credentials. Put the preview in a restricted iframe and communicate only through an explicit, versioned message protocol.
- Require authentication or a revocable share token at the preview gateway. Cloudflare preview URLs are otherwise public by default.
- Never treat a successful compile as a security review. Display the repository/ref/build hash on the session and make the trust boundary visible to viewers.

## Option 3: GitHub Actions builds and artifacts

### Feasibility

High for commit-based previews, low for a tight edit-refresh loop.

A repository can contain a workflow that checks out a ref, installs/pins Flutter, runs `flutter build web`, and uploads the output. Workflows can be triggered by pushes, manual `workflow_dispatch`, or external `repository_dispatch` events. GitHub Pages can deploy a static artifact through a custom Actions workflow, and deployment environments can expose a preview URL in the repository/PR UI. Sources: [workflow triggers](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow), [workflow concepts](https://docs.github.com/en/actions/concepts/workflows-and-actions/workflows), [custom GitHub Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages), and [deployment environments](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/deploy-to-environment).

This approach naturally compiles the real repository with its lockfile, path packages, assets, and theme. It also keeps code and build logs in the consumer's GitHub security boundary.

Its weaknesses are product latency and artifact delivery:

- GitHub-hosted jobs start in a clean runner/VM, so tools and dependencies must be restored for every job. GitHub provides dependency caches, but a cache miss still performs a clean resolution/download. Sources: [GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) and [dependency caching](https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching).
- Actions is a queued CI system with concurrency and queue limits, not a resident hot-reload process. It provides no interactive latency guarantee suitable for every keystroke. Source: [Actions limits](https://docs.github.com/en/actions/reference/limits).
- Workflow artifacts are archives for build outputs, not public websites. They require repository read access and expire after a retention period (90 days by default). Source: [downloading workflow artifacts](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts).
- GitHub Pages is excellent for a project site but does not inherently provide one isolated deployment URL per Desy workshop session. A workflow would need to publish every build under an immutable path, or upload to a separate static preview host.

### Verdict

Offer this as a low-infrastructure beta or fallback:

- A “Build on GitHub” button commits/pushes the workshop source or selects an existing ref.
- A repository workflow builds it.
- Desy polls the workflow/deployment and embeds the final static URL.

This is enough to validate whether users value shared workshop journeys. It is not the final interactive renderer if the desired feeling is local hot reload.

## Option 4: prebuilt branch/commit previews

This is the simplest sharing model and can precede all hosted editing:

1. A push webhook identifies the new commit.
2. CI or the Desy build service compiles the Desy workshop entrypoint.
3. Static output is published at `/repo/<repo-id>/commit/<sha>/<build-hash>/`.
4. Workshop rounds reference that immutable preview URL.

GitHub supports downloading a repository archive at a specific ref, and GitHub Apps can subscribe to webhooks according to their granted permissions. Sources: [repository archive API](https://docs.github.com/en/rest/repos/contents), [GitHub App permissions](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/choosing-permissions-for-a-github-app), and [GitHub App webhooks](https://docs.github.com/en/apps/maintaining-github-apps/modifying-a-github-app-registration).

This can render code “straight out of GitHub” in the user-facing sense, but GitHub remains the source, not the renderer: a Flutter build must still happen somewhere.

The approach has excellent reproducibility and weak immediacy. It is a strong first shared-preview feature if Desy does not yet want to host mutable workspaces.

## Comparison

| Approach | Real arbitrary Flutter | Repository fidelity | Iteration loop | Shareability | Operational/security burden | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| Browser-hosted compiler | Syntax can be real, but no supported full-repo toolchain | Low without rebuilding Flutter/Dart tooling | Potentially excellent if it existed | Excellent | Extremely high client/toolchain complexity | Do not build now |
| DartPad-style compile service | Yes, within a pinned package/template universe | Low–medium | Fast compile API | Good | Medium–high; compiler service and package whitelist | Only for a future single-file mode |
| Warm remote Flutter sandbox | Yes | High | Best; resident debug process and hot reload | Good while alive | High but bounded by container isolation | Best interactive architecture |
| Immutable remote build artifact | Yes | High | Full build per accepted change | Excellent | Medium | Pair with warm sandbox |
| GitHub Actions + static host | Yes | Highest | CI-speed, not conversational | Excellent | Low for Desy; shifted to repo CI | Best cheap beta/fallback |
| Prebuilt branch/commit previews | Yes | Highest | Push-to-preview | Excellent | Low–medium | Strong first sharing milestone |

## Multiplayer model

Do not make the Flutter preview runtime the collaborative state authority. Each browser should load the same immutable build but run its own widget state. Desy's session service owns collaboration:

```text
Workshop session
  session metadata and participants
  ordered iteration rounds
    candidate build IDs / immutable preview URLs
    selected continuation
    comments and annotations
    source repository + exact commit/tree hash
  presence and cursors (ephemeral)
```

For the first multiplayer version, synchronize only workshop events—comments, selections, active round, presence—and keep code edits Git-based. A commit or saved source patch creates a build request; a successful build appends a new immutable candidate/round. This avoids inventing collaborative Dart editing before validating the workshop itself.

If Cloudflare is used, one Durable Object per workshop session is a plausible coordinator. Durable Objects provide a globally named, strongly consistent state/compute location for multiple clients, and their WebSocket hibernation API can keep clients connected while allowing idle compute to sleep. Sources: [Durable Objects overview](https://developers.cloudflare.com/durable-objects/) and [WebSockets with Durable Objects](https://developers.cloudflare.com/durable-objects/best-practices/websockets/).

Later, collaborative source editing can be added as an event log or CRDT, but compilation should still happen against explicit source snapshots. Never let “currently typing” become the identity of a workshop round; builds and comments must reference a durable snapshot/hash.

## Recommended Desy MVP

### Phase 0: prove the renderer contract locally

- Add a conventional, ordinary-Dart workshop entry file in the dogfood repository.
- Create a tiny preview harness that imports a candidate builder and applies the active registry's real theme wrapper.
- Build it with `flutter build web` and embed the output in the Widget Workshop screen through a web-only preview frame.
- Define a narrow parent/preview message protocol: ready, logical size, runtime error, console event, and optional theme/device selection.
- Confirm assets, fonts, multiple themes, local workspace path packages, interaction, and navigation behavior.

This phase needs no backend and tests the hardest Desy-specific boundary: producing a faithful standalone preview from the consumer registry.

### Phase 1: GitHub/commit sharing beta

- Require a GitHub repo/ref plus the conventional Desy workshop entrypoint.
- Build on GitHub Actions or one controlled builder.
- Publish immutable static output to a preview host, not merely an expiring Actions artifact.
- Store a workshop document containing ordered rounds, build URLs, selections, and comments.
- Allow a read-only share link. No live code editing yet.

This is enough to test whether teams actually use journeys and feedback asynchronously.

### Phase 2: hosted interactive builds

- Introduce one isolated sandbox per active editor/session with a pinned Flutter image.
- Restore the repository and cached packages by content hash.
- Keep `flutter run` resident for editor hot reload; stream compile diagnostics into Desy.
- On “share iteration,” create a release web build, upload it immutably, and append it to the journey.
- Shut down/sleep the sandbox when idle; restore from Git plus persisted source patches when resumed.

### Phase 3: multiplayer workshop coordination

- Add real-time presence, comments, selection, and active-round updates.
- Keep preview builds immutable and independently instantiated in each client.
- Add collaborative source editing only after observing a real need; continue compiling explicit snapshots.

## Decisions and open experiments

Before choosing a host, benchmark these on the real Desy dogfood repository:

1. Cold `flutter pub get` and cold `flutter build web` in a clean Linux container.
2. Warm dependency restore and incremental web hot reload after editing one candidate file.
3. Container image size and minimum reliable memory/CPU tier for Flutter web compilation.
4. CanvasKit asset loading, custom fonts, and nested workspace path packages from a preview origin.
5. Iframe restrictions/CSP that still allow CanvasKit/Wasm, text input, clipboard where desired, and accessibility while denying parent credentials.
6. Whether a shared debug preview needs per-viewer isolation; default to immutable release artifacts for viewers.
7. How private GitHub dependencies are retrieved without exposing installation credentials to untrusted build code.

The architectural recommendation does not depend on Cloudflare specifically. A Kubernetes pod, Firecracker VM, hosted development environment, or dedicated build worker can implement the same boundary. Cloudflare Sandbox is notable because its official API already covers isolated execution, custom images, lifecycle, files/processes, preview URLs, and outbound policy; it should be validated with an actual Flutter image and measured before being selected.

## Final recommendation

Build the **standalone Flutter web preview harness first**, then ship **commit-based immutable sharing**, and only then add **warm remote sandboxes for hot reload**.

The key product boundary should remain:

> A Desy workshop iteration is real Flutter source plus an immutable compiled preview, tied to an exact repository snapshot and rendered through the consumer's real theme wrapper.

That boundary supports local authoring, GitHub, hosted hot reload, share links, and multiplayer without turning Desy into a second Flutter language or weakening its real-widget principle.
