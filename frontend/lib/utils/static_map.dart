import '../config.dart';

/// Google Static Maps image URL for an encoded route polyline.
String? staticRouteMapUrl(String encodedPolyline) {
  if (encodedPolyline.isEmpty) return null;
  if (googleMapsApiKey.isEmpty || googleMapsApiKey == 'your_google_maps_js_api_key_here') {
    return null;
  }
  return Uri.https(
    'maps.googleapis.com',
    '/maps/api/staticmap',
    {
      'size': '480x280',
      'scale': '2',
      'maptype': 'roadmap',
      'path': 'weight:5|color:0x7c3aedFF|enc:$encodedPolyline',
      'key': googleMapsApiKey,
    },
  ).toString();
}
