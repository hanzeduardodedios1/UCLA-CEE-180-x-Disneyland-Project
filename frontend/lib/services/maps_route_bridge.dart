import 'maps_route_bridge_impl.dart'
    if (dart.library.js_interop) 'maps_route_bridge_web.dart';

/// Parameters passed to the Google Maps JavaScript API route renderer.
class RouteMapRequest {
  const RouteMapRequest({
    required this.apiKey,
    required this.origin,
    required this.destination,
    this.travelMode = 'WALKING',
    this.encodedPolyline = '',
  });

  final String apiKey;
  final String origin;
  final String destination;
  final String travelMode;
  /// Encoded polyline from backend Directions API (preferred for map display).
  final String encodedPolyline;
}

/// Invokes [renderHotelRouteMap] in the browser (Maps JavaScript API).
void invokeMapsRouteRender(Object container, RouteMapRequest request) {
  renderMapsRoutePlatform(container, request);
}
