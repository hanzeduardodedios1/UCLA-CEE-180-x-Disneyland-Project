import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App loads search page', (WidgetTester tester) async {
    await tester.pumpWidget(const DisneylandHotelsApp());
    expect(find.textContaining('Disneyland'), findsWidgets);
  });
}
