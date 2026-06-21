import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/session_provider.dart';
import '../services/gatepass_qr.dart';
import '../theme.dart';
import '../widgets/material3_button.dart';
import '../widgets/material3_card.dart';
import '../widgets/material3_textfield.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  final Set<String> _scannedPassUids = <String>{};
  GatePassScanOutcome _outcome = const GatePassScanOutcome(
    state: GatePassScanState.idle,
    title: 'Ready to scan',
    message: 'Point the camera at a GatePass QR code or paste the payload below.',
  );
  DateTime? _lastHandledAt;
  String? _lastRawValue;
  bool _torchEnabled = false;
  int _scannerRestartKey = 0;

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _applyResult(GatePassScanOutcome outcome) {
    setState(() {
      _outcome = outcome;
      if (outcome.state == GatePassScanState.valid && outcome.passUid != null) {
        _scannedPassUids.add(outcome.passUid!);
      }
    });
  }

  void _handleRawValue(String rawValue, List<Map<String, dynamic>> knownPasses) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) {
      return;
    }

    final now = DateTime.now();
    if (_lastRawValue == normalized &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2)) {
      return;
    }

    _lastRawValue = normalized;
    _lastHandledAt = now;

    final outcome = evaluateGatePassQr(
      rawValue: normalized,
      knownPasses: knownPasses,
      scannedPassUids: _scannedPassUids,
    );

    _applyResult(outcome);
  }

  Color _statusColor(GatePassScanState state) {
    switch (state) {
      case GatePassScanState.valid:
        return AppColors.success;
      case GatePassScanState.invalid:
        return AppColors.error;
      case GatePassScanState.scanned:
        return AppColors.warning;
      case GatePassScanState.idle:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _statusIcon(GatePassScanState state) {
    switch (state) {
      case GatePassScanState.valid:
        return Icons.verified;
      case GatePassScanState.invalid:
        return Icons.report_problem;
      case GatePassScanState.scanned:
        return Icons.history;
      case GatePassScanState.idle:
        return Icons.qr_code_scanner;
    }
  }

  Widget _buildStatusBanner(GatePassScanOutcome outcome, Color statusColor) {
    return Material3Card(
      padding: const EdgeInsets.all(16),
      backgroundColor: statusColor.withValues(alpha: 0.08),
      showBorder: true,
      child: AnimatedSwitcher(
        duration: 300.ms,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: Row(
          key: ValueKey('${outcome.state}_${outcome.passUid}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: statusColor,
              child: Icon(_statusIcon(outcome.state), color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outcome.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    outcome.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (outcome.passUid != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pass UID: ${outcome.passUid}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildScannerWidget(List<Map<String, dynamic>> knownPasses) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              key: ValueKey(_scannerRestartKey),
              controller: _controller,
              fit: BoxFit.cover,
              errorBuilder: (context, error) {
                return Container(
                  color: AppColors.secondary,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_photography, color: Theme.of(context).colorScheme.onSecondary, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'Camera unavailable',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Material3Button(
                          label: 'Retry Camera',
                          onPressed: () {
                            setState(() => _scannerRestartKey++);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              onDetect: (capture) {
                String? rawValue;
                for (final barcode in capture.barcodes) {
                  final candidate = barcode.rawValue;
                  if (candidate != null && candidate.trim().isNotEmpty) {
                    rawValue = candidate;
                    break;
                  }
                }
                if (rawValue != null) {
                  _handleRawValue(rawValue, knownPasses);
                }
              },
            ),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 188,
                        height: 188,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final theme = Theme.of(context);
    final knownPasses = session.passes;
    final statusColor = _statusColor(_outcome.state);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GatePass QR Scanner'),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _controller.toggleTorch();
                if (mounted) {
                  setState(() => _torchEnabled = !_torchEnabled);
                }
              } catch (_) {
                if (!mounted) return;

                messenger.showSnackBar(
                  const SnackBar(content: Text('Torch is not available on this camera.')),
                );
              }
            },
            icon: Icon(_torchEnabled ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material3Card(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                          child: Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Instant GatePass checks',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${knownPasses.length} synced passes ready for live validation.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusBanner(_outcome, statusColor),
              const SizedBox(height: 18),
              _buildScannerWidget(knownPasses),
              const SizedBox(height: 16),
              Material3TextField(
                label: 'Paste GatePass QR payload',
                hint: 'GPX1|PASS_UID|SIGNATURE',
                controller: _manualController,
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Material3Button(
                      label: 'Verify Payload',
                      onPressed: () => _handleRawValue(_manualController.text, knownPasses),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material3OutlinedButton(
                    label: 'Reset',
                    isFullWidth: false,
                    onPressed: () {
                      setState(() {
                        _scannedPassUids.clear();
                        _outcome = const GatePassScanOutcome(
                          state: GatePassScanState.idle,
                          title: 'Ready to scan',
                          message: 'Point the camera at a GatePass QR code or paste the payload below.',
                        );
                        _manualController.clear();
                        _lastRawValue = null;
                        _lastHandledAt = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Scanned this session',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (_scannedPassUids.isEmpty)
                Material3Card(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No passes scanned yet.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scan a QR code or paste a payload above.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._scannedPassUids.map((passUid) {
                  final pass = knownPasses.firstWhere(
                    (entry) => entry['pass_uid']?.toString() == passUid,
                    orElse: () => <String, dynamic>{},
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material3ListCard(
                      leading: const Icon(Icons.verified_user, color: AppColors.success),
                      title: pass['attendee_name']?.toString() ?? passUid,
                      subtitle: pass['company']?.toString() ?? 'GatePass already scanned',
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
