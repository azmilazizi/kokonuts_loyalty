import 'package:flutter_test/flutter_test.dart';
import 'package:kokonuts_loyalty/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const KokonutsLoyaltyApp());
  });
}
