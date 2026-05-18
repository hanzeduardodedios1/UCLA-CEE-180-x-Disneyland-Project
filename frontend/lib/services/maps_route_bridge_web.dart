import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'maps_route_bridge.dart';

@JS('renderHotelRouteMap')
external void _renderHotelRouteMap(
  web.HTMLElement container,
  JSObject options,
);

void renderMapsRoutePlatform(Object container, RouteMapRequest request) {
  _renderHotelRouteMap(
    container as web.HTMLElement,
    (<String, String>{
      'apiKey': request.apiKey,
      'origin': request.origin,
      'destination': request.destination,
      'travelMode': request.travelMode,
      'polyline': request.encodedPolyline,
    }.jsify() as JSObject?)!,
  );
}
