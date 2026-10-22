# Local copy of maplibre_gl 0.27.1

Used through `dependency_overrides` in the app's pubspec.yaml. The example,
screenshots and tests are left out, and `resolution: workspace` is removed from
pubspec.yaml (it only works inside the plugin's own monorepo).

## The patch

`takeSnapshot()` on Android
(`android/src/main/java/org/maplibre/maplibregl/MapLibreMapController.java`,
`case "map#takeSnapshot"`) uses `MapLibreMap.snapshot()` - the map as displayed -
instead of `MapSnapshotter`.

`MapSnapshotter` renders a separate copy of the map from the style's URI, so:

- it never returns when the style was loaded as JSON (Drives downloads its style
  once per session and passes the JSON, so the URI is empty);
- it leaves out the sources and layers added at runtime - the route, waypoints
  and points of interest, which are what the trip's map image is for.

iOS (`ios/.../MapLibreMapController.swift`, `case "map#takeSnapshot"`) still uses
`MLNMapSnapshotter` with `mapView.styleURL` and has the same problem.

## Upgrading maplibre_gl

Copy the new version from the pub cache over this folder, reapply the change
above (and the pubspec edit), or drop the override if upstream has fixed
`takeSnapshot` for JSON styles and runtime layers.
