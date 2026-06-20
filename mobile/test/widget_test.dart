import 'package:depass_mobile/src/providers/session_provider.dart';
import 'package:depass_mobile/src/screens/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows the login screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SessionProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('GatePassX'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Device approval required'), findsOneWidget);
  });
}
