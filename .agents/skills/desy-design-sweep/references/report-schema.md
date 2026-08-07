# Design sweep report schema

## Evidence states

- **Verified** — reproduced in source, semantics, deterministic test output, or
  an inspected runtime state.
- **Hypothesis** — visually plausible but not yet reproducible from deterministic
  evidence.
- **Coverage gap** — an important state or viewport has no declaration or test,
  but no defect has been proven.

## Severity

- **Critical** — blocks a core workflow or creates a serious accessibility,
  data-loss, or security risk.
- **High** — prevents meaningful use for a supported state, theme, input method,
  or viewport.
- **Medium** — causes recurring inconsistency, confusion, or maintenance cost.
- **Low** — bounded polish or documentation defect with modest consequence.

## Required report structure

```md
# Desy design sweep

## Scope
- Registry: <name/path>
- Themes: <IDs>
- Scenarios and viewports: <covered set>
- Checks run: <commands or inspection methods>
- Exclusions: <unavailable evidence>

## Findings

### [High][Verified] Concise consequence-led title
- Evidence: <registry ID, source path/line, state, theme, viewport, output>
- Impact: <specific user or maintenance consequence>
- Recommendation: <smallest source-of-truth-preserving fix>
- Verify: <focused deterministic check>

## Hypotheses to verify
- [Hypothesis] <observation and exact reproduction step>

## Coverage gaps
- [Coverage gap] <missing state/test and why it matters>

## Next action
<highest-value issue-sized action and its completion check>
```

If there are no verified findings, say so plainly. Do not manufacture findings
to fill every category.
