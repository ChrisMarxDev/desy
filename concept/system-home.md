# System home

Desy has a neutral Home destination at `/home`. A registry with an optional
`DesySystemProfile` opens there; a minimal registry still opens on Atlas and can
navigate to Home without declaring extra metadata.

The profile owns only facts Desy cannot infer: a stable ID, short introduction,
purpose, principles, an optional hero asset ID, and typed links. Desy derives
the active theme, validation status, populated atom lanes, component count,
prototype count, and other inventory facts directly from the same registry.

The hero is a reference to a registered `DesyAssetEntry`, never a second image
declaration. Missing hero references and missing family members are validation
warnings so the workbench remains useful while a system is being assembled.

All profile collections are immutable, and profile, principle, and link IDs
participate in the registry's shared stable-ID validation.
