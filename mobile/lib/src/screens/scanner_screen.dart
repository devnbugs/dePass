import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/gatepass_qr.dart';

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

  Color _statusColor(GatePassScanState state, ColorScheme scheme) {
    switch (state) {
      case GatePassScanState.valid:
        return const Color(0xFF1E7A49);
      case GatePassScanState.invalid:
        return const Color(0xFFB02A1D);
      case GatePassScanState.scanned:
        return const Color(0xFF996A00);
      case GatePassScanState.idle:
        return scheme.primary;
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final knownPasses = session.passes;
    final statusColor = _statusColor(_outcome.state, scheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GatePass QR Scanner'),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchEnabled = !_torchEnabled);
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [scheme.primary, const Color(0xFF1B1B18)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instant GatePass checks',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${knownPasses.length} synced passes ready for live validation.',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: statusColor,
                      child: Icon(_statusIcon(_outcome.state), color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _outcome.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _outcome.message,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (_outcome.passUid != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Pass UID: ${_outcome.passUid}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AspectRatio(
                aspectRatio: 0.75,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        fit: BoxFit.cover,
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
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Paste GatePass QR payload',
                  hintText: 'GPX1|PASS_UID|SIGNATURE',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleRawValue(_manualController.text, knownPasses),
                      child: const Text('Verify Payload'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
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
                    child: const Text('Reset'),
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
                const Text('No passes scanned yet.')
              else
                ..._scannedPassUids.map((passUid) {
                  final pass = knownPasses.firstWhere(
                    (entry) => entry['pass_uid']?.toString() == passUid,
                    orElse: () => <String, dynamic>{},
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_user, color: Color(0xFF1E7A49)),
                        title: Text(pass['attendee_name']?.toString() ?? passUid),
                        subtitle: Text(pass['company']?.toString() ?? 'GatePass already scanned'),
                      ),
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
