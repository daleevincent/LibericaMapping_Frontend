// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:liberica_map/main.dart';

void main() {
  testWidgets('App smoke test — launches without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LibericaMapApp());
    expect(find.byType(LibericaMapApp), findsOneWidget);
  });
}