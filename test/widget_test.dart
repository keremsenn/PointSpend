import 'package:flutter_test/flutter_test.dart';

import 'package:pointspend/main.dart';

void main() {
  testWidgets('PointSpend starts with dashboard content', (tester) async {
    await tester.pumpWidget(const PointSpendApp());
    await tester.pumpAndSettle();

    expect(find.text('PointSpend'), findsOneWidget);
    expect(find.text('Toplam Puan'), findsOneWidget);
    expect(find.textContaining('İşlemler'), findsWidgets);
  });
}
