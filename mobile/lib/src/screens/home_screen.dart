import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final session = context.read<SessionProvider>();
    final loaded = await session.refreshData();
    if (mounted) {
      setState(() {
        _loading = false;
        _error = !loaded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final events = session.events;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4EF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Image.asset('assets/icon/app-icon.png'),
            ),
            const SizedBox(width: 10),
            const Text('GatePassX Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await session.logout();
              if (!context.mounted) {
                return;
              }

              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              session.userName ?? 'Organizer',
              style: const TextStyle(fontSize: 16, color: Color(0xFF4B4A45)),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Unable to load event data from the Laravel backend.', style: TextStyle(color: Color(0xFFB02A1D))),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Color(0xFFFA3E2C)),
                        title: const Text('Events'),
                        subtitle: Text('${events.length} events loaded from backend'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.pushNamed(context, '/event');
                        },
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.qr_code, color: Color(0xFF1B1B18)),
                        title: const Text('GatePass Scanner'),
                        subtitle: Text('${session.passes.length} passes ready for instant validation'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.pushNamed(context, '/scanner');
                        },
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long, color: Color(0xFFFA3E2C)),
                        title: const Text('Passes'),
                        subtitle: Text('${session.passes.length} pass records synced'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.pushNamed(context, '/passes');
                        },
                      ),
                    ),
                    if (events.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text('Recent events', style: Theme.of(context).textTheme.titleLarge),
                      ),
                      ...events.take(3).map((event) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(event['name'] as String? ?? 'Unnamed event'),
                            subtitle: Text(event['date'] as String? ?? 'No date provided'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () {
                              Navigator.pushNamed(context, '/event');
                            },
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
