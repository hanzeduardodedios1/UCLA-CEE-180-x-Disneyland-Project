import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Display walking route calls route API and shows map section', (tester) async {
    var routeEndpointCalled = false;

    final client = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/api/hotels/names')) {
        return http.Response(jsonEncode(['Disneyland Hotel']), 200);
      }
      if (path.endsWith('/api/hotels/search')) {
        return http.Response(
          jsonEncode({
            'hotel': 'Disneyland Hotel',
            'address': '1150 W Magic Way, Anaheim, CA 92802',
            'nightly_rate': 400,
            'walk_mins': 5.0,
            'transit_mins': null,
            'transit_saved_mins': 0.0,
          }),
          200,
        );
      }
      if (path.endsWith('/api/hotels/route')) {
        routeEndpointCalled = true;
        expect(request.url.queryParameters['hotel'], 'Disneyland Hotel');
        return http.Response(
          jsonEncode({
            'hotel': 'Disneyland Hotel',
            'origin': '1150 W Magic Way, Anaheim, CA 92802',
            'destination': '1313 S Harbor Blvd, Anaheim, CA 92802',
            'distance_text': '0.4 mi',
            'distance_meters': 650,
            'duration_text': '9 mins',
            'duration_seconds': 540,
            'duration_mins': 9.0,
            'polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
          }),
          200,
        );
      }
      return http.Response('not found', 404);
    });

    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(DisneylandHotelsApp(api: HotelApi(client: client)));
    await tester.pumpAndSettle();

    final hotelCard = find.ancestor(
      of: find.text('Disneyland Hotel'),
      matching: find.byType(InkWell),
    );
    await tester.scrollUntilVisible(
      hotelCard,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(hotelCard);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compare').first);
    await tester.pumpAndSettle();

    final routeButton = find.text('Display walking route');
    await tester.scrollUntilVisible(
      routeButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(routeButton);
    await tester.pumpAndSettle();

    expect(routeEndpointCalled, isTrue);
    expect(find.text('9 mins walk · 0.4 mi'), findsOneWidget);
    expect(find.text('Walking route to Disneyland'), findsOneWidget);
  });
}
