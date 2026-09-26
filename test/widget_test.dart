import 'package:flutter_test/flutter_test.dart';
import 'package:procat_moto_turizm/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const ProcatApp());
    expect(find.textContaining('Оборудование'), findsWidgets);
  });
}
