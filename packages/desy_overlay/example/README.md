# desy_overlay example

From this directory, run:

```sh
flutter run
```

Use the crosshair in the lower-right corner, click a component, type feedback,
and send it. Sending exits selection mode and removes the annotation overlay.
Drag anywhere on the card to move it and close it with the × action to cancel.

The sample deliberately uses `DesyOverlayMode.always` so the beta release-mode
metadata path can also be tested. The package default remains debug-only.

The same example can be launched on a connected phone or simulator with
`flutter run -d <device-id>`. Mobile chrome respects safe areas and moves above
the software keyboard while feedback is being entered.
