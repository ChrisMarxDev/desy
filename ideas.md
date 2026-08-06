# Desy Bench — Future Ideas

This is an exploratory list, not a roadmap or a commitment. Each idea should be
considered only after the registry API and core workbench experience are stable.
The common constraint is that the consumer registry remains the source of truth;
new capabilities should derive from it rather than introduce a competing model.

## Relative impact and complexity

These are directional estimates on a 1–5 scale: **impact** reflects potential
value to Desy and its consumers, while **complexity** reflects the likely
product, API, and implementation effort for a useful first version—not just
the amount of code. They are comparisons, not commitments or sequencing.

| Idea | Impact | Complexity | Why |
| --- | ---: | ---: | --- |
| GenUI catalogue export | 4/5 | 3/5 | It can make the existing registry valuable to AI-assisted interfaces, provided the export contract stays deliberately small and derived. |
| Agent annotations and feedback loops | 5/5 | 3/5 | A focused feedback payload and consumer-owned `onAnnotate` delivery could close a high-value review loop without requiring hosted infrastructure. |
| Extension packages | 5/5 | 4/5 | A good extension boundary keeps the core focused and unlocks many workflows, but the initial API must be stable enough to avoid fragmentation. |
| Post-decoupling showcase | 4/5 | 4/5 | It could demonstrate Desy’s neutrality and reach, though it depends on mature registry contracts and representative consumer integrations. |
| AI-assisted screen composition | 5/5 | 5/5 | It is potentially transformative, but dependable suggestions, legal composition constraints, evaluation, and review UX make it a substantial system. |
| Samples and larger compositions | 4/5 | 2/5 | It offers immediate demonstrative value and exercises the registry’s screen extension point with comparatively contained scope. |
| Marketing-material generation | 4/5 | 3/5 | Reproducible capture recipes can create useful outward-facing assets, particularly once curated compositions and export hooks exist. |
| Animation builder | 3/5 | 5/5 | Motion is compelling, but a useful builder risks becoming a broad authoring tool unless its scope is kept exceptionally narrow. |

## 1. GenUI catalogue export

Explore exporting selected Desy catalogue content into a GenUI-friendly format.
This could give AI-assisted interfaces a structured view of the consumer's real
components, tokens, available themes, supported slots, and preview metadata.
The export should be generated from the registry and remain optional, so a
minimal Flutter integration never needs GenUI-specific declarations.

Questions worth testing include what an export needs to describe component
capabilities without leaking application logic, and whether it should represent
only approved showcase components or the full registry tree.

## 2. Agent annotations and feedback loops

Allow a reviewer or agent to annotate a rendered screen, component preview, or
specific region with structured feedback. An annotation could capture the
target registry or manifest IDs, viewport and theme context, a screenshot or
reference, and the comment itself—enough context for an agent to act without
having to reconstruct the screen manually.

Desy could offer destinations such as a local Mac workflow or a GitHub Issue,
with consumers providing the final integration through an explicit callback,
for example `onAnnotate`. The package should own the annotation experience and
payload shape, while the consumer decides whether and where it is delivered.
No remote service should be required for the local-first baseline.

## 3. Extension packages

Provide a narrow extension model for optional workbench surfaces instead of
letting the core package grow into every adjacent tool. Extensions could add
screens, actions, or export targets while resolving their inputs through the
same active registry and preview context.

Potential extensions include a store-screenshot builder, a video builder, and
other release or documentation workflows. They should be installable only when
needed and must not make their metadata or dependencies mandatory for ordinary
catalogue use.

## 4. A showcase for the post-decoupling design-system ecosystem

Once design frameworks and consumers are more cleanly decoupled, Desy could
become a strong comparative showcase: one workbench capable of presenting
multiple design systems through their own real widgets and themes. The value is
not in normalizing every framework into one visual language, but in giving each
system a consistent way to declare and explore what it owns.

This would need careful boundaries so the bench stays neutral and registry-led,
rather than becoming a second design-system implementation.

## 5. AI-assisted screen composition

Explore an agent that proposes screens from registered elements: selecting
compatible components, filling legal slots, and producing a serializable screen
manifest for review. The output should use registered IDs and supported values,
never callbacks, hidden application logic, or invented production widgets.

The useful first step may be suggestion and iteration rather than one-click
generation: show the proposed composition, let a person adjust it, then save
only an explicit manifest. This preserves consumer ownership while making the
registry more useful to agents.

## 6. Samples and larger compositions

Add an opt-in area for complete, ready-to-show compositions built from the
consumer's registered primitives and components. These could demonstrate common
patterns such as onboarding, settings, commerce, or editorial layouts, while
remaining examples rather than a required design-system category.

The same registry extension point should support both code-defined showcase
screens and user-composed manifests. That keeps individual components,
catalogue entries, and larger examples connected to one declared system.

## 7. Marketing-material generation

Use curated registry entries and compositions to produce repeatable marketing
assets: social images, launch-page captures, release notes, app-store artwork,
or short product demonstrations. A deliberate capture specification—theme,
viewport, device frame, state, and output dimensions—would make these assets
reproducible instead of relying on ad hoc screenshots.

This likely overlaps with extensions for screenshots and video, but the core
opportunity is to turn already-approved design-system examples into polished,
consistent communications material.

## 8. Animation builder

Investigate a studio surface for previewing and composing motion around real
registered widgets. It could expose simple timelines, transitions, and state
changes for demonstrations, documentation, or marketing captures, while
leaving production animation ownership with the consumer.

An early version should focus on non-destructive previews and exportable
recipes rather than trying to become a general animation authoring tool. Any
animation configuration should be typed, serializable where appropriate, and
optional for consumers that do not need it.
