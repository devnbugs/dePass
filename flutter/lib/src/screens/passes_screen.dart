import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../theme.dart';
import '../widgets/material3_card.dart';

class PassesScreen extends StatefulWidget {
  const PassesScreen({super.key});

  @override
  State<PassesScreen> createState() => _PassesScreenState();
}

class _PassesScreenState extends State<PassesScreen> {
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    setState(() => _isLoading = true);
    final session = context.read<SessionProvider>();
    await session.refreshData();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passes'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                key: const ValueKey('content'),
                onRefresh: _handleRefresh,
                child: session.passes.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No passes loaded yet',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Visit an event and fetch packages to sync passes.',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: session.passes.length,
                        itemBuilder: (context, index) {
                          final pass = session.passes[index];
                          final attendeeName =
                              pass['attendee_name'] as String? ?? 'Unnamed attendee';
                          final company =
                              pass['company'] as String? ?? 'No company';
                          final status =
                              pass['status'] as String? ?? 'unknown';

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Material3ListCard(
                              title: attendeeName,
                              subtitle: company,
                              trailing: Chip(
                                label: Text(
                                  status,
                                  style: textTheme.labelSmall,
                                ),
                              ),
                            ).animate().fadeIn(
                                  duration: 300.ms,
                                  delay: (50 * index).ms,
                                ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
