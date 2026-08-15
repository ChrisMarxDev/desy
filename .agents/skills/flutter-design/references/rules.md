# Accepted Flutter design rules

Use the relevant rules for the task. They are heuristics, not mandates.

## Spacing and grouping

- Reuse a small spacing scale.
- Use a visibly larger spacing jump to separate sections or decisions.
- Give important content enough empty space to read and act on it.
- Keep related labels, values, and explanations close together.

## Hierarchy and layout

- Give each screen one primary job.
- Separate a title and context from its configurable properties.
- Align repeated content to shared edges and baselines.
- Do not put every group in a card; use spacing, headings, and quiet dividers first.

## Type and language

- Use named type roles instead of arbitrary one-off text sizes.
- Keep descriptive copy readable at normal and increased text scales.
- Name what a person recognises and controls in plain language.
- Design settings and data panels to scan: lead with key words and make values comparable.

## Colour and states

- Give each signal colour a stable semantic meaning.
- Never communicate state by colour alone.
- Maintain adequate contrast for default, muted, selected, disabled, focus, and error states.
- Use quiet surfaces, borders, and elevation for structure; reserve saturated colour for meaningful signals.

## Controls and access

- Make interactive targets generous; aim for 44×44 logical pixels where practical.
- Keep keyboard focus visible and unobscured.
- Label the outcome a control changes and expose its current state.
- Show an understandable result, error, or recovery path after an action.

## Flutter context

- Constrain long explanatory text to a readable measure.
- Preserve a widget's intended constraints in demos and previews.
- Review the real Flutter widget inside its real app theme.
- Keep shared design decisions in one theme or token source rather than locally duplicated values.
- Reveal advanced options only when they become relevant.
- Prototype focused alternatives before turning an experiment into a shared component API.
