# Widgetbook inspiration and Desy Bench boundary

Widgetbook validates the useful baseline for a Flutter workbench: catalogue real
widgets, render them under selectable application themes, and make component
states interactive. Desy Bench adopts the catalogue and consumer-theme pattern.

Desy Bench intentionally differs by making a consumer-owned semantic registry
its first-class contract. Tokens, component intent, accessibility guidance, and
source paths are declared together so future validation and agent guidance can
derive from the same source rather than from a separate widget gallery.

The next package milestone is structured use cases and typed knobs. Device,
locale, text-scale, cloud collaboration, code generation, and the CLI stay out
of the first release.
