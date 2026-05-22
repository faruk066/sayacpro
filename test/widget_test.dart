import 'package:flutter_test/flutter_test.dart';
import 'package:sayac_pro/main.dart';

void main() {
  testWidgets('SayacPro app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SayacProApp());
    expect(find.text('SayacPro'), findsOneWidget);
  });
}
