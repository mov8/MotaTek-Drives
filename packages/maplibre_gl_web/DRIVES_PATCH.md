# Local copy of maplibre_gl_web 0.27.1

Used through `dependency_overrides` in the app's pubspec.yaml, like the
maplibre_gl copy beside it. The tests are left out, and `resolution: workspace`
is removed from pubspec.yaml (it only works inside the plugin's own monorepo).

## The patch

`queryRenderedFeatures()` and `queryRenderedFeaturesInRect()`
(`lib/src/maplibre_web_gl_platform.dart`) no longer return an empty list when
`map.isStyleLoaded()` is false. They query anyway, and only answer nothing if
the query throws (no style yet).

`isStyleLoaded()` is false not just before the style loads but whenever a
source is being updated or a filter changed - and Drives updates its GeoJSON
sources and filters on every onIdle in Explore. So on the web the queries
nearly always answered nothing:

- the waypoint under the crosshair was never found (`MapService
  .waypointTargetted()`), so the chips never offered Remove waypoint;
- AI assist couldn't name the place under the crosshair;
- great roads under the crosshair, and trips tapped in Published, used the
  same calls.

Android and iOS have no such check.

## Upgrading maplibre_gl_web

Copy the new version from the pub cache over this folder, reapply the change
above (and the pubspec edit), or drop the override if upstream answers queries
while sources are updating.
