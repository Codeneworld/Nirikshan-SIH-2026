import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('Nirikshan app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NirikshanApp());

    expect(find.text('NIRIKSHAN'), findsOneWidget);
  });
}
