---
name: icon-batch-importer
description: Step-by-step procedure for importing, background-stripping, optimizing, and integrating new icon batches (SVG or Canva/Blender PNG) for Production.INC.
---

# Icon Batch Importer Runbook

Use this workflow whenever the user drops a new batch of icons into the project (e.g. `Batch 2: Factory Machinery & Logistics Fleet`).

## Step 1: Inspect Incoming Assets
1. Identify all files in the drop folder:
   - Identify which are native vector SVGs (Illustrator / Inkscape / Figma).
   - Identify which are 3D / raster PNGs (Canva / Blender) that may have solid backgrounds (`hasAlpha: no`).
2. Map each file to its canonical target in `assets/images/icons/<category>/<prefix>_<id>.svg` per [`ICON_DESIGN_ROADMAP.md`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/ICON_DESIGN_ROADMAP.md).

## Step 2: Native Vector SVG Processing
For vector SVGs:
1. Verify `viewBox` is standard (`0 0 256 256` or `0 0 512 512`).
2. Remove any unsupported `<filter>` tags that cause `flutter_svg` unhandled element warnings when feasible.
3. Move/copy directly to the appropriate target directory.

## Step 3: Canva / 3D Raster PNG Background Removal & Packaging
For raster renders with solid/off-white backgrounds:
1. **Choose Removal Algorithm**:
   - **Apple Vision Segmentation** (`VNGenerateForegroundInstanceMaskRequest`): Use for high-contrast objects with clean silhouette borders (machinery, tools, vehicles, glass, box).
   - **Edge BFS Flood-Fill**: Use when the subject contains delicate elements sharing tone with the background (white polymer pellets, pedestals, fine wires).
2. **Verify Alpha**: Ensure corner pixels have `alpha = 0.0` and the center subject is 100% opaque.
3. **Downsample**: Downscale to 512×512 using `sips -z 512 512` with Lanczos resampling for crisp, high-DPI rendering without ballooning memory.
4. **SVG Packaging**: Wrap the transparent PNG into standard SVG container:
   ```xml
   <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
     <image href="data:image/png;base64,{BASE64_DATA}" width="512" height="512"/>
   </svg>
   ```

## Step 4: Wire into GameIcon
1. Open [`lib/widgets/game_icon.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/lib/widgets/game_icon.dart).
2. Add the new category mapping (or expand `_materialAssetMap` / `_productAssetMap`).
3. If introducing a new category (e.g., machines or fleet), add factory constructors `GameIcon.forMachine` / `GameIcon.forFleet` or update `resolveAssetPath`.

## Step 5: Test & Validate
1. Update [`test/game_icon_test.dart`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/test/game_icon_test.dart) to assert path resolution and `SvgPicture` rendering.
2. Run `flutter test test/game_icon_test.dart`.
3. Run `flutter analyze` to ensure 0 errors or warnings.

## Step 6: Roadmap & Documentation Sync
1. Check off completed items in [`ICON_DESIGN_ROADMAP.md`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/ICON_DESIGN_ROADMAP.md) and sync [`docs/sprints/04_v2.0_major_update/ICON_DESIGN_ROADMAP.md`](file:///Users/Kamish/Desktop/JEBZ%20DEVVV/Main%20Projects/Game1/docs/sprints/04_v2.0_major_update/ICON_DESIGN_ROADMAP.md).
2. Update the progress counter and master dashboard.

## Step 7: Clean Up Staging Files
1. Remove temporary drop folders (`assets/images/Batch X ...`).
2. Remove any temporary scripts in `/tmp`.
3. Verify `git status` shows only clean SVG assets and expected code updates.
