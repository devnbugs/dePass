import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/session_provider.dart';
import '../widgets/material3_button.dart';
import '../widgets/material3_card.dart';
import '../theme.dart';

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
    final passes = session.passes;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/icon/app-icon.png',
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.qr_code_2, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'GatePassX',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final navigator = Navigator.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout?'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                await session.logout();
                if (mounted) {
                  navigator.pushReplacementNamed('/');
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      session.userName ?? 'Organizer',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideX(begin: -0.05),
                  ],
                ),
              ),
            ),

            if (_loading)
              SliverFillRemaining(
                child: Shimmer.fromColors(
                  baseColor: AppColors.disabledBackground,
                  highlightColor: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _shimmerCard(80)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: _shimmerCard(80)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _shimmerCard(60),
                        const SizedBox(height: AppSpacing.sm),
                        _shimmerCard(60),
                        const SizedBox(height: AppSpacing.sm),
                        _shimmerCard(60),
                      ],
                    ),
                  ),
                ),
              )
            else if (_error)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Unable to load dashboard',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Failed to connect to the backend. Please check your connection.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Material3Button(
                          label: 'Retry',
                          onPressed: _loadDashboard,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: Material3StatusCard(
                            status: 'Events',
                            value: events.length.toString(),
                            icon: const Icon(Icons.event, color: AppColors.primary),
                            backgroundColor: AppColors.primaryContainer,
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Material3StatusCard(
                            status: 'Passes',
                            value: passes.length.toString(),
                            icon: const Icon(Icons.receipt_long, color: AppColors.secondary),
                            backgroundColor: AppColors.secondaryContainer,
                          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).slideY(begin: 0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                    const SizedBox(height: AppSpacing.sm),

                    Material3ListCard(
                      title: 'Events',
                      subtitle: 'Browse and manage events',
                      leading: const Icon(Icons.event, color: AppColors.primary),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => events.isNotEmpty
                          ? Navigator.pushNamed(context, '/event', arguments: 0)
                          : null,
                    ).animate().fadeIn(duration: 300.ms, delay: 250.ms).slideX(begin: -0.05),
                    const SizedBox(height: AppSpacing.sm),

                    Material3ListCard(
                      title: 'QR Scanner',
                      subtitle: 'Validate passes instantly',
                      leading: const Icon(Icons.qr_code_2, color: AppColors.primary),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => Navigator.pushNamed(context, '/scanner'),
                    ).animate().fadeIn(duration: 300.ms, delay: 300.ms).slideX(begin: -0.05),
                    const SizedBox(height: AppSpacing.sm),

                    Material3ListCard(
                      title: 'QR Wizard',
                      subtitle: 'Generate QR codes for passes',
                      leading: const Icon(Icons.auto_fix_high, color: AppColors.primary),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => Navigator.pushNamed(context, '/qr-wizard'),
                    ).animate().fadeIn(duration: 300.ms, delay: 325.ms).slideX(begin: -0.05),
                    const SizedBox(height: AppSpacing.sm),

                    Material3ListCard(
                      title: 'Passes',
                      subtitle: '${passes.length} passes synced',
                      leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () => Navigator.pushNamed(context, '/passes'),
                    ).animate().fadeIn(duration: 300.ms, delay: 350.ms).slideX(begin: -0.05),
                    const SizedBox(height: AppSpacing.lg),

                    if (events.isNotEmpty) ...[
                      Text(
                        'Recent Events',
                        style: Theme.of(context).textTheme.titleMedium,
                      ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
                      const SizedBox(height: AppSpacing.sm),
                      ...events.take(3).toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final event = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Material3ListCard(
                            title: event['name'] as String? ?? 'Unnamed event',
                            subtitle: event['date'] as String? ?? 'No date provided',
                            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                            onTap: () => Navigator.pushNamed(
                              context, '/event',
                              arguments: events.indexOf(event),
                            ),
                          ).animate().fadeIn(
                            duration: 300.ms,
                            delay: Duration(milliseconds: 450 + index * 50),
                          ).slideX(begin: -0.05),
                        );
                      }),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerCard(double height) {
    return Card(
      child: SizedBox(
        height: height,
        width: double.infinity,
      ),
    );
  }
}
