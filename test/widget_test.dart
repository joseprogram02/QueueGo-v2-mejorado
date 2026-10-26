import 'package:flutter_test/flutter_test.dart';

import 'package:queuego/main.dart';

void main() {
  testWidgets(
    'QueueGo inicia correctamente',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const QueueGoApp(),
      );

      expect(
        find.text('QueueGo'),
        findsOneWidget,
      );
    },
  );
}