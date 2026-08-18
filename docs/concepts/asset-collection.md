# Asset collection

Assets are an optional built-in atom lane. A `DesyAssetEntry` declares exactly
four consumer-authored fields: stable `id`, familiar `fileName`, bundled Flutter
`assetKey`, and a concise `description` of when to use it.

The Assets board is present only when the lane is populated. It presents the
real packaged image, its filename and ID, the usage note, and two handoff
actions: copy the image and download the original bundled bytes. A hosted web
app does not need a public asset URL: Flutter bundles entries declared in the
consumer app's pubspec and Desy loads them through the asset key.

Copy image is a browser action for decodable raster assets and writes a PNG
bitmap to the system clipboard. Download always preserves the original bundled
file and its filename. Brand-specific choices such as which entries count as
logos remain opt-in configuration of the Brand Guide extension rather than
metadata every asset must carry.
