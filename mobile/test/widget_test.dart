import 'package:depass_mobile/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the login screen', (tester) async {
    await tester.pumpWidget(const GatePassXApp());

    expect(find.text('GatePassX'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
