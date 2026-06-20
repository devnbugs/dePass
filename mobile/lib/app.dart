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
        routes: {
          '/': (context) => const AuthGate(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/event': (context) => const EventDetailScreen(),
          '/scanner': (context) => const ScannerScreen(),
          '/passes': (context) => const PassesScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = context.read<SessionProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = context.watch<SessionProvider>();
        return session.isAuthenticated ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}
