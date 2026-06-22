import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../widgets/material3_button.dart';
import '../widgets/material3_card.dart';
import '../theme.dart';

class EventDetailScreen extends StatefulWidget {
  final int? eventIndex;

  const EventDetailScreen({super.key, this.eventIndex});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<SessionProvider>();
    final loaded = await session.refreshData();
    if (mounted) {
      setState(() {
        _loading = false;
        _error = !loaded;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'used':
      case 'checked_in':
        return AppColors.info;
      case 'expired':
        return AppColors.warning;
      case 'cancelled':
      case 'blocked':
        return AppColors.error;
      default:
        return AppColors.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final events = session.events;
    final idx = widget.eventIndex ?? 0;
    final event = idx >= 0 && idx < events.length ? events[idx] : null;
    final eventId = event?['id'];
    final eventPasses = session.passes.where((p) {
      final eid = p['event_id'];
      return eid != null && eventId != null && eid == eventId;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(event?['name'] as String? ?? 'Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
              .animate()
              .fadeIn(duration: 300.ms)
          : _error
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Unable to load event details',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to connect to the backend.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Material3Button(
                          label: 'Retry',
                          onPressed: _load,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 300.ms)
              : event == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: AppColors.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No event found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material3Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.event, color: AppColors.primary, size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          event['name'] as String? ?? 'Unnamed Event',
                                          style: Theme.of(context).textTheme.headlineSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(Icons.calendar_today, 'Date',
                                      event['date'] as String? ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _infoRow(Icons.location_on, 'Location',
                                      event['location'] as String? ?? 'N/A'),
                                  const SizedBox(height: 8),
                                  _infoRow(Icons.info_outline, 'Status',
                                      event['status'] as String? ?? 'N/A'),
                                ],
                              ),
                            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),

                            const SizedBox(height: 24),

                            Text(
                              'Pass Types',
                              style: Theme.of(context).textTheme.titleMedium,
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                            const SizedBox(height: 12),

                            if (eventPasses.isEmpty)
                              Material3Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No passes available for this event.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms)
                            else
                              ...eventPasses.take(5).map((pass) {
                                final name = pass['attendee_name'] as String?;
                                final company = pass['company'] as String?;
                                final status = pass['status'] as String? ?? 'unknown';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material3ListCard(
                                    title: name ?? 'Unnamed Attendee',
                                    subtitle: company ?? 'No company',
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Icon(Icons.person, color: AppColors.primary, size: 20),
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        status,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: _statusColor(status),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 400.ms, delay: (100 * eventPasses.indexOf(pass)).ms);
                              }),

                            const SizedBox(height: 24),

                            Text(
                              'All Passes',
                              style: Theme.of(context).textTheme.titleMedium,
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                            const SizedBox(height: 12),

                            if (eventPasses.isEmpty)
                              Material3Card(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No passes to display.',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 400.ms)
                            else
                              ...eventPasses.map((pass) {
                                final name = pass['attendee_name'] as String?;
                                final company = pass['company'] as String?;
                                final status = pass['status'] as String? ?? 'unknown';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Material3ListCard(
                                    title: name ?? 'Unnamed Attendee',
                                    subtitle: company ?? 'No company',
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryContainer,
                                      child: Icon(Icons.receipt, color: AppColors.primary, size: 20),
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        status,
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: _statusColor(status),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 300.ms, delay: (80 * eventPasses.indexOf(pass)).ms);
                              }),

                            const SizedBox(height: 24),

                            Material3Button(
                              label: 'Refresh Data',
                              onPressed: _load,
                              leadingIcon: const Icon(Icons.refresh),
                            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
