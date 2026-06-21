import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/providers/session_provider.dart';
import 'src/screens/login_screen_m3.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/event_detail_screen.dart';
import 'src/screens/passes_screen.dart';
import 'src/screens/scanner_screen.dart';
import 'src/screens/qr_wizard_screen.dart';
import 'src/theme.dart';

class GatePassXApp extends StatelessWidget {
  const GatePassXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionProvider(),
      child: MaterialApp(
        title: 'GatePassX Version 2026.07.22',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        routes: {
          '/': (context) => const AuthGate(),
          '/login': (context) => const LoginScreenM3(),
          '/home': (context) => const HomeScreen(),
          '/event': (context) => EventDetailScreen(
            eventIndex: ModalRoute.of(context)?.settings.arguments as int?,
          ),
          '/scanner': (context) => const ScannerScreen(),
          '/passes': (context) => const PassesScreen(),
          '/qr-wizard': (context) => const QrWizardScreen(),
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
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/icon/app-icon.png',
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.qr_code_2, color: AppColors.primary, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'GatePassX',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ],
              ),
            ),
          );
        }

        final session = context.watch<SessionProvider>();
        return session.isAuthenticated ? const HomeScreen() : const LoginScreenM3();
      },
    );
  }
}
