# Frontend Architecture Overview

Disneyland hotel comparison UI built with **Flutter** (Material 3). The app is a single-page experience: one root screen (`HotelSearchPage`) with two primary tabs (Browse / Compare), optional desktop sidebar, and backend HTTP for hotel data and walking routes. Maps on web use a **Dart ↔ JavaScript** bridge into `frontend/web/maps_route.js`.

---

## Directory layout (`frontend/lib`)

| Path | Role |
|------|------|
| `main.dart` | App entry, routing shell, all primary screens and most UI widgets |
| `config.dart` | Compile-time constants (`API_BASE_URL`, `GOOGLE_MAPS_JS_API_KEY`, `DISNEYLAND_DESTINATION`) |
| `theme/app_theme.dart` | `AppColors`, `AppDecor`, `buildAppTheme()` |
| `models/hotel.dart` | `HotelRow` JSON model |
| `models/route.dart` | `HotelRoute` JSON model |
| `services/api.dart` | `HotelApi` HTTP client |
| `services/maps_route_bridge.dart` | Conditional export + `RouteMapRequest` + `invokeMapsRouteRender` |
| `services/maps_route_bridge_impl.dart` | No-op stub (non-web) |
| `services/maps_route_bridge_web.dart` | `@JS('renderHotelRouteMap')` interop (web) |
| `utils/static_map.dart` | Google Static Maps URL builder (non-web map fallback) |
| `widgets/hotel_search_field.dart` | Autocomplete search field |
| `widgets/hotel_route_map.dart` | Conditional export: web vs stub |
| `widgets/hotel_route_map_web.dart` | `HtmlElementView` + platform view (web) |
| `widgets/hotel_route_map_stub.dart` | `Image.network` static map (desktop/mobile) |

Related (not under `lib`): `frontend/web/maps_route.js` (loaded from `index.html`), `frontend/web/index.html`.

---

## High-level architecture

```
main()
  └── DisneylandHotelsApp (StatelessWidget)
        └── MaterialApp
              └── HotelSearchPage (StatefulWidget)  ← single “screen”, tab state via _navIndex
                    ├── [wide] _buildSidebar()
                    ├── _buildTopNav() → search + pill nav
                    └── _navIndex == 0 ? _buildBrowseTab() : _buildCompareTab()
```

**State management:** No Provider, Riverpod, Bloc, or similar. All application state lives in `_HotelSearchPageState` (`setState`). Child widgets receive data and callbacks as constructor parameters.

**Navigation:** Not named routes. Tab switching is `int _navIndex` (0 = Browse, 1 = Compare). Sidebar and pill nav call `setState(() => _navIndex = …)`.

**Responsive layout:** `MediaQuery.sizeOf(context).width >= 900` enables left sidebar; compare cards use `>= 640` for side-by-side layout.

---

## Screens and entry points

There is only one routed screen in `MaterialApp.home`:

| Widget | Type | Description |
|--------|------|-------------|
| `DisneylandHotelsApp` | `StatelessWidget` | Root app; optional `HotelApi? api` for tests |
| `HotelSearchPage` | `StatefulWidget` | Entire UX: browse, compare, search, sidebar |

**Logical “screens”** (same `HotelSearchPage`, different builders):

| Tab | Builder | When shown |
|-----|---------|------------|
| Browse | `_buildBrowseTab(wide)` | `_navIndex == 0` |
| Compare | `_buildCompareTab(wide)` | `_navIndex == 1` |

Compare empty state is inline in `_buildCompareTab` (not a separate route).

---

## State in `_HotelSearchPageState`

| Variable | Type | Purpose |
|----------|------|---------|
| `_api` | `HotelApi` | HTTP client (`widget.api ?? HotelApi()`) |
| `_navIndex` | `int` | 0 = Browse, 1 = Compare |
| `_categoryIndex` | `int` | Sidebar category filter (Browse only) |
| `_hotelNames` | `List<String>` | Full hotel list from backend (autocomplete source) |
| `_comparison` | `List<HotelRow>` | Up to 2 hotels in compare queue |
| `_routeVisibleHotels` | `Set<String>` | Hotels whose route map section is expanded |
| `_routes` | `Map<String, HotelRoute>` | Cached route payloads by hotel name |
| `_routeLoading` | `Map<String, bool>` | Per-hotel route fetch in progress |
| `_routeErrors` | `Map<String, String>` | Per-hotel route error messages |
| `_error` | `String?` | Global search/load error banner |
| `_loadingNames` | `bool` | Initial `/api/hotels/names` load |
| `_searching` | `bool` | Hotel search in progress |

**Constants / derived (not mutable state):**

- `_maxCompare = 2`
- `_quickPicks`, `_sidebarCategories` — static curated data
- `_filteredPicks` — getter filtering `_quickPicks` by `_categoryIndex`

**Key actions:**

| Method | Triggers API | Updates state |
|--------|--------------|---------------|
| `_loadNames()` | `GET /api/hotels/names` | `_hotelNames`, `_loadingNames`, `_error` |
| `_search(query)` | `GET /api/hotels/search` | `_comparison`, `_searching`, `_error`, may set `_navIndex = 1` |
| `_removeHotel(name)` | — | Clears hotel from compare + route maps |
| `_displayRoute(name)` | `GET /api/hotels/route` | `_routes`, `_routeVisibleHotels`, `_routeLoading`, `_routeErrors` |
| `_scoreHotel(a, b)` | — | Local compare scoring (3 metrics) |

---

## Widget inventory

### Extracted widgets (`lib/widgets/`)

| Widget | State | Role |
|--------|-------|------|
| `HotelSearchField` | Stateful | Text field + overlay dropdown; client-side filter on `allHotels`; calls `onSearch` |
| `HotelRouteMap` | Web: Stateful; Stub: Stateless | Route map (JS embed vs static image) |

### Widgets in `main.dart`

| Widget | Scope |
|--------|--------|
| `_SidebarNavTile` | Sidebar nav rows |
| `_LogoMark` | Mobile header logo |
| `_PillNavBar` / `_PillNavItem` | Browse / Compare pill navigation |
| `_HeroBanner` | Browse hero CTA |
| `_SpotlightCard` | Browse spotlight cards (wide only) |
| `_FeaturedHotelCard` | Browse featured hotel grid |
| `_CompactCompareTile` | Browse section “Your comparison” |
| `_ErrorBanner` | Search error display |
| `ComparisonSummaryCard` | Compare tab winner chips (public class) |
| `_ComparePlanCard` | Full compare card + route button + map |
| `_CompareFeatureLine` | Single metric row with win/tie/lose icon |
| `_FeatureRow` | Data holder for compare lines |

### Shell structure (all tabs)

```
Scaffold
  └── SafeArea
        └── Row
              ├── [if wide] _buildSidebar()
              └── Expanded Column
                    ├── _buildTopNav()
                    │     ├── Row (logo, _PillNavBar, compare badge, help)
                    │     └── _buildSearchBar() → HotelSearchField | loading | error
                    └── Expanded → Browse OR Compare body
  └── [optional] FloatingActionButton → switch to Compare
```

---

## API connection points

Base URL: `config.dart` → `apiBaseUrl` (`--dart-define=API_BASE_URL`, default `http://localhost:8000`).

| Client method | HTTP | Used by |
|---------------|------|---------|
| `fetchHotelNames()` | `GET {base}/api/hotels/names` | `_loadNames()` on init |
| `suggestHotels(q)` | `GET {base}/api/hotels/suggest?q=` | **Defined but unused**; search uses client-side filtering in `HotelSearchField` |
| `searchHotel(q, {exact})` | `GET {base}/api/hotels/search?q=&exact=true` | `_search()`; `exact` when query matches a loaded name exactly |
| `fetchRoute(hotelName)` | `GET {base}/api/hotels/route?hotel=` | `_displayRoute()` |

Errors surface as `HotelApiException` or generic network messages referencing `apiBaseUrl`.

**External APIs (browser only, not backend):**

- Google Maps JavaScript API — via `maps_route.js` (web interactive map)
- Google Static Maps API — via `static_map.dart` (non-web `HotelRouteMap` stub)

Keys: `GOOGLE_MAPS_JS_API_KEY` dart-define (shared naming for JS and static map).

---

## Data models

### `HotelRow` (`models/hotel.dart`)

| Field | JSON key |
|-------|----------|
| `hotel` | `hotel` |
| `address` | `address` |
| `nightlyRate` | `nightly_rate` |
| `walkMins` | `walk_mins` |
| `transitMins` | `transit_mins` (nullable) |
| `transitSavedMins` | `transit_saved_mins` |

### `HotelRoute` (`models/route.dart`)

| Field | JSON key |
|-------|----------|
| `hotel`, `origin`, `destination` | same |
| `distanceText`, `distanceMeters` | `distance_text`, `distance_meters` |
| `durationText`, `durationSeconds`, `durationMins` | `duration_text`, `duration_seconds`, `duration_mins` |
| `polyline` | `polyline` (encoded polyline for map) |

---

## Browse tab — component hierarchy

`_buildBrowseTab(wide)` → `SingleChildScrollView`

```
SingleChildScrollView
  └── Column
        ├── Title: "Hotels overview"
        ├── Subtitle
        ├── _HeroBanner(onCompare → _navIndex=1, slotsFilled)
        ├── [if wide] Row
        │     ├── _SpotlightCard "Top picks" → _search(first quick pick)
        │     └── _SpotlightCard "Side-by-side" → _navIndex=1
        ├── Section header "Featured hotels" + count
        ├── LayoutBuilder → Wrap
        │     └── [_FeaturedHotelCard × N]  ← N = _filteredPicks
        │           onTap → _search(pick.hotelName)
        │           inCompare ← _comparison contains pick
        └── [if _comparison.isNotEmpty]
              ├── "Your comparison" + TextButton → _navIndex=1
              └── [_CompactCompareTile × len(_comparison)]
                    onRemove → _removeHotel
```

**Category filtering (sidebar, Browse only):**

| `_categoryIndex` | Label | `_filteredPicks` |
|------------------|-------|------------------|
| 0 | All hotels | All 4 `_quickPicks` |
| 1 | Disney properties | Names containing `"disney"` |
| 2 | Budget picks | Clarion only |
| 3 | Walk-friendly | Park Vue + Clarion |

Sidebar “Filter hotels…” `TextField` is **UI only** (no handler).

**Data flow into Browse:**

- Featured cards → `_search()` → API → append/replace in `_comparison`
- Hero / spotlight / “Full compare” → `_navIndex = 1` only
- Compact tiles at bottom mirror compare queue (no route maps on Browse)

---

## Compare tab — component hierarchy

`_buildCompareTab(wide)`

### Empty state (`_comparison.isEmpty`)

```
Center
  └── Column (icon, copy, FilledButton "Browse hotels" → _navIndex=0)
```

### With hotels

```
SingleChildScrollView
  └── Column
        ├── Title "Compare hotels"
        ├── Status line (count / max)
        ├── [if length == 2]
        │     ├── ComparisonSummaryCard(a, b)   ← win chips: rate, walk, transit saved
        │     └── LayoutBuilder
        │           ├── [wide ≥640] IntrinsicHeight Row
        │           │     ├── _ComparePlanCard(hotel 0, other=1, isPremium=score)
        │           │     └── _ComparePlanCard(hotel 1, other=0, isPremium=score)
        │           └── [narrow] Column of two cards
        ├── [if length == 1] single _ComparePlanCard (isPremium=false, no other)
        └── [if length < 2] OutlinedButton "Add second hotel" → _navIndex=0
```

### `_ComparePlanCard` internal tree

```
Container (premium dark styling if isPremium)
  └── Column
        ├── Header Row (name, address, remove)
        ├── Feature lines (_CompareFeatureLine × 4)
        │     nightly rate, walk, transit, transit saved vs other
        ├── Divider
        ├── TextButton "Display walking route" → onDisplayRoute
        ├── [optional] routeError text
        └── [if routeVisible && route != null]
              ├── duration / distance text
              └── ClipRRect → HotelRouteMap(
                    key: ValueKey(address-polyline),
                    origin: route.origin,
                    destination: route.destination,
                    encodedPolyline: route.polyline,
                  )
```

**Premium card:** `_scoreHotel` counts wins on rate ≤, walk ≤, transit saved ≥; higher score gets `isPremium` and dark theme (“Better value” badge).

**Route flow:** Button → `_displayRoute` → API → set `_routeVisibleHotels` → map renders with backend polyline.

---

## `maps_route.js` interop (web)

End-to-end path from Flutter web to Google Maps:

```
index.html
  <script src="maps_route.js"></script>   ← defines window.renderHotelRouteMap

_ComparePlanCard
  └── HotelRouteMap (hotel_route_map_web.dart)
        └── platformViewRegistry.registerViewFactory
              └── HTMLDivElement
              └── Future.microtask → invokeMapsRouteRender(div, RouteMapRequest)

maps_route_bridge.dart (conditional import)
  └── maps_route_bridge_web.dart
        @JS('renderHotelRouteMap') _renderHotelRouteMap(container, options JSObject)
        options = { apiKey, origin, destination, travelMode, polyline }.jsify()

maps_route.js
  window.renderHotelRouteMap(container, options)
```

### Conditional compilation

| Condition | Bridge | Map widget |
|-----------|--------|------------|
| `dart.library.js_interop` (Flutter web) | `maps_route_bridge_web.dart` | `hotel_route_map_web.dart` |
| Otherwise | `maps_route_bridge_impl.dart` (no-op) | `hotel_route_map_stub.dart` (Static Maps image) |

### `RouteMapRequest` → JS `options`

| Dart field | JS key | Notes |
|------------|--------|-------|
| `apiKey` | `apiKey` | From `googleMapsApiKey` |
| `origin` | `origin` | Hotel address (labels / fallback directions) |
| `destination` | `destination` | Default `disneylandDestination` |
| `travelMode` | `travelMode` | Default `'WALKING'` |
| `encodedPolyline` | `polyline` | Preferred path from backend |

### JavaScript behavior (`renderHotelRouteMap`)

1. Validates `apiKey` (rejects placeholder `your_google_maps_js_api_key_here`).
2. Shows “Loading map…”.
3. **If `polyline` is non-empty:** `loadGoogleMaps` → decode with `google.maps.geometry.encoding.decodePath` → `Map` + `Polyline` + markers A/B at path ends → `fitBounds`.
4. **Else if `origin` and `destination`:** client-side `DirectionsService.route` + `DirectionsRenderer` (walking).
5. **Else:** error message in container.

`loadGoogleMaps` injects `https://maps.googleapis.com/maps/api/js?key=…&libraries=geometry` once per API key (cached promise).

### Web embedding details

- `HotelRouteMap` registers a unique `viewType` (`hotel-route-map-{counter}`).
- `HtmlElementView(viewType: _viewType)` embeds the DOM div in the widget tree.
- `invokeMapsRouteRender` runs in `Future.microtask` after the factory returns the element.

### Non-web fallback

`hotel_route_map_stub.dart` builds a URL with `staticRouteMapUrl(encodedPolyline)` (`maps/api/staticmap` with `path=enc:…`). No JS interop; requires Static Maps API enabled for the same key.

---

## Theme and configuration

**`AppColors` / `AppDecor`:** SaaS-style palette (purple accent `#6D28D9`, gray surfaces, premium dark `#111827`).

**Build-time defines (`config.dart`):**

| Define | Default | Use |
|--------|---------|-----|
| `API_BASE_URL` | `http://localhost:8000` | All `HotelApi` requests |
| `GOOGLE_MAPS_JS_API_KEY` | placeholder string | Maps JS + Static Maps |
| `DISNEYLAND_DESTINATION` | Harbor Blvd address | Map destination / directions fallback |

---

## Dependencies (`pubspec.yaml`)

- `flutter` / Material icons
- `http` — REST client
- `web` — `dart:js_interop` / DOM on web
- `url_launcher` — declared; **not referenced in `lib/`**
- `cupertino_icons` — standard; minimal direct use in reviewed files

---

## User flows (summary)

1. **App start** → load hotel names → enable search field.
2. **Add hotel** → search (field, featured card, or spotlight) → `HotelRow` in `_comparison` (max 2; auto-switch to Compare when full).
3. **Browse** → filter featured list via sidebar categories; preview comparison tiles; navigate to Compare.
4. **Compare** → side-by-side metrics; optional “Display walking route” → backend route → interactive map (web) or static image (other platforms).
5. **Remove** → clears compare slot and all route state for that hotel.

---

## Testing hook

`DisneylandHotelsApp` and `HotelSearchPage` accept optional `HotelApi? api` to inject a mock client in widget tests without hitting the network.
