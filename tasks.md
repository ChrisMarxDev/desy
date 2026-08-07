# Desy Project Backlog

This is a forward-looking task list for the new Desy project. It is intentionally
written as product and engineering work to refine later, not as an immediate
implementation plan. The current checkout is not assumed to be properly rebased
for feature work; do not begin implementation from this document until the
working branch/base has been confirmed.

## Product direction

Desy should become a polished, repository-native Flutter design-system
workbench that helps people and agents inspect, compose, prototype, validate,
and improve real consumer-owned widgets. The consumer registry remains the
source of truth. New capabilities should derive from declared registry IDs,
real widget builders, themes, contracts, and typed values rather than creating a
parallel catalogue or hosted backend.

## Priority and dependency legend

- **P0** — foundational or blocking capability.
- **P1** — high-value product capability for the next major iteration.
- **P2** — exploratory or advanced capability.
- **Discovery** means the interface and contract need to be designed before implementation.

---

## 1. Deploy the dogfood sample to the web with automatic deployments

**Priority:** P0  
**Outcome:** The Harbor Operations dogfood sample is available from a stable web
URL and every approved change automatically produces a new deployment.

### Scope

- Choose and document the hosting target and deployment model.
- Build the sample Flutter web app in release mode.
- Add a GitHub Actions workflow triggered by pushes to the selected branch and,
  where useful, pull requests for preview deployments.
- Configure immutable or preview URLs for pull requests and a stable production
  URL for the main branch.
- Add build metadata such as commit SHA and deployment timestamp.
- Define caching, asset headers, SPA fallback behavior, and rollback strategy.
- Keep secrets and hosting credentials in GitHub Actions secrets; never commit
  them to the repository.
- Add a deployment status badge and a short contributor runbook.

### Acceptance criteria

- A clean checkout can build the sample web app reproducibly.
- Merging to the deployment branch triggers an automatic deployment.
- A failed build does not replace the last known-good deployment.
- The deployed sample loads on desktop and narrow web layouts.
- The URL, hosting configuration, and rollback procedure are documented.

### Open decisions

- Hosting provider and domain.
- Whether pull requests receive ephemeral previews.
- Whether deployment is from `main` directly or from a release environment.

---

## 2. Improve sketching with predefined rows, columns, and spacing primitives

**Priority:** P1  
**Outcome:** The Components sketch becomes a useful layout playground instead of
only a freeform canvas. Users can create repeatable layouts using declared
spacing values and sensible row/column presets.

### Scope

- Add explicit layout primitives for rows, columns, stacks, grids, and gaps.
- Offer predefined presets such as:
  - single-column stack;
  - two-column split;
  - three-column grid;
  - responsive card grid;
  - repeated list rows;
  - form or settings layout.
- Populate spacing choices from the consumer registry’s typed numeric entries
  under `Atoms/Measurements` rather than hard-coding a second spacing catalogue.
- Show layout guides, alignment lines, padding, gap values, and container bounds.
- Allow registered components and component instances to be inserted into legal
  slots in the layout.
- Preserve the current principle that sketches are ephemeral unless and until a
  separate serializable manifest feature is deliberately designed.
- Make layouts responsive to the selected viewport/device frame.

### Acceptance criteria

- A user can choose a row/column preset and place real registered widgets into it.
- Available spacing values are derived from the active registry.
- Layouts remain understandable at desktop, tablet, and mobile widths.
- The sketch does not introduce a competing token or component inventory.
- Existing freeform device-artboard interactions remain functional.

### Open decisions

- Whether layout primitives are registry declarations, workbench-only objects,
  or both.
- How nested layouts are represented before manifests exist.
- Whether constraints are flex-like, grid-like, or a small Desy-specific model.

---

## 3. Build better agent integration, Desy teaching skills, and design-sweep skills

**Priority:** P0/P1  
**Outcome:** Agents can reliably understand a consumer’s Desy registry, inspect
real components, propose changes within project constraints, and perform a
repeatable design-quality sweep.

### Workstream A — Teach agents Desy

- Create a canonical Desy agent skill covering registry concepts, stable IDs,
  real-theme previews, typed primitives, component contracts, scenarios, knobs,
  extensions, and non-goals.
- Add project-local instructions for safe repository exploration and source-of-
  truth rules.
- Define compact commands or queries for retrieving registry context by folder,
  component, theme, token, scenario, or source path.
- Include examples of good and bad declarations.
- Document how agents should validate changes with focused tests and `task check`.

### Workstream B — Design sweep skill

Create a repeatable review skill that can inspect a Desy consumer and report:

- inconsistent spacing, typography, color, and radius usage;
- missing semantic tokens or duplicated values;
- components without meaningful states or contracts;
- previews that use fake widgets or artificial compact constraints;
- accessibility and semantics gaps;
- inconsistent loading, empty, error, disabled, and focus states;
- visual hierarchy and responsive-layout issues;
- registry IDs, folder placement, and documentation quality;
- unused or duplicated declarations.

The skill should distinguish verified findings from visual hypotheses and produce
small, actionable issue-sized recommendations.

### Acceptance criteria

- An agent can explain a new consumer registry without inventing a parallel model.
- The design sweep produces a structured report with evidence, severity, and
  suggested fixes.
- The workflow can run in review-only mode before making changes.
- The skill is usable both from the Desy repository and from a consuming project.

### Open decisions

- Whether agent integration is local CLI, MCP-like inspection, generated
  context, or a combination.
- Which visual checks can be deterministic and which require screenshots or an
  LLM.
- Whether sweep results should become GitHub issues, annotations, or both.

---

## 4. Automatic or AI-driven golden tests

**Priority:** P1  
**Outcome:** Desy can help create, update, review, and run visual regression
tests for real registered widgets and states without making golden files noisy
or untrustworthy.

### Scope

- Define a golden-test model keyed by stable registry IDs, theme IDs, scenario
  IDs, viewport/device frame, and relevant knob values.
- Provide deterministic capture commands for selected registry entries.
- Support reviewable golden updates with clear diffs and metadata.
- Add an AI-assisted mode that can suggest missing coverage, identify likely
  intentional changes, and summarize visual differences.
- Keep the final pass/fail decision deterministic wherever possible.
- Add masking or normalization rules for timestamps, random content, animation,
  and platform-specific rendering.
- Consider accessibility-tree and semantic snapshots alongside pixel goldens.

### Acceptance criteria

- A component can have goldens for its normal, loading, error, empty, disabled,
  and selected states.
- Goldens are reproducible in CI and locally.
- Updates show the registry entry, theme, viewport, and scenario that changed.
- AI suggestions never silently rewrite approved goldens.
- The workflow supports both package-level and consumer-level tests.

### Open decisions

- Flutter golden tooling and image-diff format.
- Whether goldens live beside registry declarations or in a dedicated directory.
- How approval works locally and in pull requests.
- Whether AI review is optional and provider-neutral.

---

## 5. Build a CLI for setup, golden tests, and future Desy workflows

**Priority:** P1/P2  
**Outcome:** A CLI makes Desy setup and repeatable repository workflows easy,
while keeping the registry API and workbench useful without the CLI.

### Initial commands to explore

```text
desy init                 Add the minimum Desy integration to a Flutter app
desy doctor               Check Flutter, package, registry, and tooling setup
desy registry             Inspect declared themes, folders, IDs, and entries
desy catalogue            Export a compact registry-derived catalogue
desy golden capture       Capture selected registry entries and scenarios
desy golden review        Review or approve visual changes
desy golden test          Run focused or complete golden coverage
desy sweep                Run deterministic and AI-assisted design checks
desy deploy               Validate/build deployment artifacts
desy context              Produce agent-readable project context
```

### Design constraints

- The CLI must derive information from the consumer registry.
- It must not create a second configuration source of truth.
- Setup should be additive, explain every file it changes, and support dry runs.
- Commands should work in monorepos and package workspaces.
- Output should be machine-readable as well as human-readable.
- The CLI should remain optional; a consumer can use the package without it.

### Acceptance criteria

- `desy doctor` gives actionable diagnostics on a clean sample project.
- `desy init --dry-run` previews changes without writing files.
- Golden commands can target stable IDs and scenarios.
- The CLI has focused tests and a documented compatibility policy.

### Dependency

Stabilize the registry API and golden-test contract before making the CLI a
primary integration surface.

---

## 6. Better animation support and animation scrubbing

**Priority:** P1/P2 — Discovery first  
**Outcome:** Users can inspect, control, and scrub real component animations in
Desy without turning the workbench into a general animation authoring tool.

### Proposed direction

Introduce a singular, typed animation controller abstraction that can coordinate
one preview’s timeline, playback state, and inspection lifecycle. The controller
should be usable by real consumer widgets and by Desy-owned preview surfaces.

### Discovery questions

- Is the controller a Desy interface that consumers optionally implement, a
  wrapper around Flutter `AnimationController`, or a higher-level timeline API?
- How are multiple animations represented: one master timeline, named tracks, or
  synchronized controllers?
- What does scrubbing mean for implicit animations, timers, physics, and async
  state transitions?
- Can a widget render deterministically at an arbitrary progress value?
- How should reduced-motion preferences affect previews and captures?
- How are animation durations, curves, and named states declared in the registry?

### Possible first release

- A preview-only `DesyAnimationController` with play, pause, restart, seek,
  speed, loop, and current progress.
- An opt-in consumer adapter for deterministic animation specimens.
- A timeline strip with a draggable scrubber and named markers.
- Golden-test integration that captures a declared animation at fixed progress
  values.
- Reduced-motion and non-animated fallback modes.

### Acceptance criteria

- A supported specimen can be paused and scrubbed deterministically.
- Animation inspection does not require production widgets to expose arbitrary
  internal application state.
- Golden captures can reproduce a declared animation frame.
- Unsupported animation types fail clearly instead of pretending to scrub.

---

## 7. Add a Lab function for component prototyping flows

**Priority:** P1/P2 — Discovery first  
**Outcome:** Desy provides a fast, low-friction place to prototype component
combinations and interaction flows using real registered building blocks.

### Product concept

A **Lab** is an experimental workspace for assembling a small flow from real
registry components, themes, scenarios, layouts, and knobs. It should feel like
the current prototyping flow, but remain clearly separate from production screen
code and from the canonical registry.

### Candidate capabilities

- Start from a blank lab or a predefined flow template.
- Add registered components and component instances.
- Connect a small set of typed interactions such as tap, submit, select, next,
  back, show, hide, loading, success, and error.
- Switch themes and viewport/device frames.
- Preview a multi-step flow without writing application business logic.
- Annotate assumptions and unresolved decisions.
- Save/export only a declarative, reviewable prototype manifest if persistence is
  later approved.
- Generate a handoff summary linking every prototype element to registry IDs.

### Boundaries

- No production Dart generation in the first version.
- No arbitrary callbacks or serialized business logic.
- No second component catalogue.
- Prototype state is local and disposable until a manifest design is agreed.

### Discovery questions

- Is a Lab a sequence of screens, a state machine, or a graph of transitions?
- Which interaction vocabulary is small enough to stay safe and useful?
- Should Labs be code-registered extensions, user-composed documents, or both?
- How should a Lab distinguish illustrative behavior from production behavior?

---

## 8. Hit testing and accessibility testing

**Priority:** P0/P1  
**Outcome:** Desy can verify that registered previews are interactable,
semantically meaningful, and usable across supported viewport sizes.

### Hit-testing work

- Add a debug inspection mode that visualizes hit regions and reports the target
  widget or semantic node under a pointer location.
- Test gesture targets, overlays, clipping, device-frame transforms, and nested
  sketch elements.
- Detect likely issues such as invisible blockers, unreachable controls, and
  touch targets smaller than the project’s declared minimum.
- Provide deterministic hit-test probes for golden or integration tests.

### Accessibility work

- Inspect the Flutter semantics tree for labels, roles, values, hints, actions,
  focus order, and duplicate or empty semantics.
- Check keyboard traversal and focus visibility.
- Check text scaling, contrast where measurable, and minimum interactive target
  sizes.
- Support audits for each theme, scenario, viewport, and component state.
- Produce evidence-backed reports that link findings to registry IDs and source
  locations.
- Keep consumer preview semantics intact while ensuring Desy-owned chrome meets
  Desy’s own accessibility principles.

### Acceptance criteria

- A component can be audited in a named scenario under a selected theme.
- Findings identify the semantic node, registry entry, viewport, and evidence.
- Tests cover both the workbench shell and consumer previews.
- Reports distinguish framework limitations from actual consumer defects.

### Open decisions

- Whether to build on Flutter semantics APIs, integration tests, or an external
  inspector bridge.
- How much contrast checking can be reliable across platform renderers.
- Whether accessibility reports should block CI or be advisory initially.

---

## 9. Set up a GitHub issue loop and annotation flow

**Priority:** P0/P1  
**Outcome:** Design findings, visual review notes, accessibility failures, and
agent suggestions can move through a traceable GitHub issue workflow.

### Scope

- Define issue templates for:
  - design-sweep finding;
  - accessibility or hit-test failure;
  - golden-test change;
  - product/discovery proposal;
  - bug or regression.
- Require issue comments to use a consistent structure:

  ```md
  ## Implementation plan
  1. ...

  ## Reasoning
  ...

  ## Result
  ...
  ```

- Add an issue loop that can periodically inspect open issues, classify them,
  propose plans, detect duplicates, and report blockers without silently
  changing scope.
- Add annotation support from Desy previews or design sweeps. An annotation
  should include, when available:
  - registry ID and source path;
  - theme and scenario;
  - viewport/device frame;
  - screenshot or region reference;
  - semantic/hit-test evidence;
  - reviewer comment;
  - suggested severity and labels.
- Support creating a GitHub issue or adding a comment only after explicit user
  or workflow authorization.
- Link implementation commits, PRs, golden updates, and verification results.
- Keep tokens and credentials outside the repository and logs.

### Acceptance criteria

- A finding can be created with enough context to reproduce it.
- Every automated issue-handling comment contains plan, reasoning, and result.
- The loop re-fetches issue state before transitions and does not overwrite user
  decisions.
- An annotation can be traced from preview to issue to fix/verification.
- The workflow supports review-only and report-only modes.

### Open decisions

- GitHub App, Actions, CLI, or local agent as the execution surface.
- Annotation storage format and image hosting strategy.
- Whether the issue loop is scheduled, manually triggered, or both.
- Label and milestone taxonomy.

---

## 10. Deliver a substantially better UX

**Priority:** P0/P1 — Continuous product track  
**Outcome:** Desy feels fast, coherent, discoverable, and trustworthy for both
first-time users and daily design-system work.

This should be treated as a cross-cutting UX program rather than a single visual
polish pass.

### Workstreams

#### Onboarding and first value

- Make the first-run path obvious: register a theme, open the sample, inspect a
  component, change a theme, and run a focused check.
- Add empty states that explain what to declare next without requiring a full
  registry.
- Provide diagnostics with concrete fixes for duplicate IDs, missing themes,
  invalid folders, and broken builders.

#### Navigation and orientation

- Improve search, breadcrumbs, route persistence, back behavior, and keyboard
  shortcuts.
- Make the registry tree, Atlas, Components sketch, Lab, and extensions feel like
  one coherent information architecture.
- Clearly show the active theme, scenario, viewport, and selected entry.

#### Preview and inspection

- Reduce chrome noise and preserve the preview as the primary focus.
- Improve responsive behavior, device-frame selection, zoom, pan, and reset.
- Make knobs, contracts, source links, scenarios, and accessibility findings
  easy to discover without overwhelming simple previews.

#### Sketching and composition

- Make drag, resize, snap, alignment, selection, and layering predictable.
- Provide undo/redo, duplicate, delete, multi-select, and clear escape paths.
- Keep transient composition state visibly distinct from durable registry data.

#### Feedback and trust

- Explain loading, capture, test, and validation states.
- Make destructive or irreversible actions explicit.
- Provide clear error recovery and preserve user work when a preview fails.
- Ensure keyboard operation, text scaling, focus visibility, and semantics are
  first-class across the workbench.

#### Performance

- Measure startup, registry indexing, Atlas search, preview rebuilds, and canvas
  interactions.
- Avoid rebuilding unrelated previews when changing one knob or route.
- Add large-registry fixtures before optimizing based on assumptions.

### Acceptance criteria

- A new user can reach a meaningful preview without reading internal docs.
- Common inspection and navigation tasks require fewer, clearer actions.
- The workbench remains usable at narrow widths and enlarged text scales.
- UX improvements are backed by focused widget tests and, where appropriate,
  dogfood review on the deployed sample.

### Discovery method

Maintain a short UX scorecard covering onboarding, navigation, previewing,
sketching, validation, accessibility, and performance. Re-run it after each
meaningful workbench change rather than treating UX as an unbounded redesign.

---

## Suggested sequencing

### Phase 0 — Foundations

1. Confirm branch/rebase strategy and repository ownership.
2. Deploy the dogfood sample with automatic web deployments.
3. Set up the GitHub issue loop and annotation contract.
4. Write the Desy agent skill and initial design-sweep skill.
5. Fix the current analysis lint failures and stabilize the canonical check.

### Phase 1 — Trustworthy inspection

1. Hit testing and accessibility reports.
2. Deterministic golden-test model and focused capture commands.
3. UX scorecard, onboarding, diagnostics, and preview navigation improvements.

### Phase 2 — Better composition

1. Predefined sketch layouts driven by registry measurements.
2. Lab discovery and a small prototype-flow experiment.
3. CLI support for setup, registry inspection, and golden workflows.

### Phase 3 — Advanced inspection and authoring support

1. Animation controller contract and deterministic scrubbing prototype.
2. AI-assisted golden review and design sweeps.
3. Expanded Lab and annotation workflows based on validated usage.

## Definition of done for future tasks

Every implementation task should:

- start from a confirmed, current base branch;
- preserve the single consumer-owned registry source of truth;
- include a focused implementation plan and reasoning;
- add or update tests where behavior is deterministic;
- document known limitations and deferred decisions;
- run the narrowest meaningful validation plus the canonical check when possible;
- leave a traceable commit/PR or issue with the result and verification evidence.
