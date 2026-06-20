import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/session_provider.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/event_detail_screen.dart';
import 'src/screens/passes_screen.dart';
import 'src/screens/scanner_screen.dart';
import 'src/theme.dart';

class GatePassXApp extends StatelessWidget {
  const GatePassXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        title: 'GatePassX',
        theme: AppTheme.lightTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/event': (context) => const EventDetailScreen(),
          '/scanner': (context) => const ScannerScreen(),
          '/passes': (context) => const PassesScreen(),
        },
      ),
    );
  }
}
