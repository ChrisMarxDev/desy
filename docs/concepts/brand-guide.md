# Brand Guide extension

`desy_brand_guide` is an optional, read-only workspace extension. It receives
the active `DesyRegistry` through the standard extension context and assembles
a scrollable guideline from the system profile, logo assets, colors,
typography, motion, and the complete asset collection.

`DesyBrandGuideConfig` adds only brand declarations that ordinary component
libraries should not be forced to provide: immutable voice principles with
positive and negative examples, plus imagery guidance that references existing
asset IDs. Empty sections are omitted. An unresolved imagery reference is
reported in the guide rather than silently becoming a parallel asset.

Consumer widgets and assets render through the active preview theme. The
extension depends on Desy-owned controls from `desy_design_system` and does not
import Forui directly, mutate the registry, or create another inventory.
