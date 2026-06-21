import 'package:depass_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app loads and shows splash', (tester) async {
    await tester.pumpWidget(const GatePassXApp());
    expect(find.text('GatePassX'), findsOneWidget);
  });
}
