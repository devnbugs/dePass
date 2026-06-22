import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../services/gatepass_qr.dart';
import '../theme.dart';
import '../widgets/material3_button.dart';
import '../widgets/material3_textfield.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualController = TextEditingController();
  final Set<String> _scannedPassUids = <String>{};
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  GatePassScanOutcome _outcome = const GatePassScanOutcome(
    state: GatePassScanState.idle,
    title: 'Ready to scan',
    message: 'Point the camera at the QR code',
  );

  DateTime? _lastHandledAt;
  String? _lastRawValue;
  bool _torchEnabled = false;
  int _scannerRestartKey = 0;
  bool _showHistory = false;
  bool _showManualEntry = false;
  Timer? _autoResetTimer;

  @override
  void initState() {
    super.initState();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _scanLineController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _autoResetTimer?.cancel();
    _scanLineController.dispose();
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _applyResult(GatePassScanOutcome outcome) {
    if (_outcome.state != GatePassScanState.idle) return;

    setState(() {
      _outcome = outcome;
      if (outcome.state == GatePassScanState.valid && outcome.passUid != null) {
        _scannedPassUids.add(outcome.passUid!);
      }
    });

    HapticFeedback.heavyImpact();

    if (outcome.state == GatePassScanState.valid) {
      _startAutoReset();
    }
  }

  void _startAutoReset() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _resetToIdle();
    });
  }

  void _resetToIdle() {
    setState(() {
      _outcome = const GatePassScanOutcome(
        state: GatePassScanState.idle,
        title: 'Ready to scan',
        message: 'Point the camera at the QR code',
      );
    });
  }

  void _handleRawValue(String rawValue, List<Map<String, dynamic>> knownPasses) {
    final normalized = rawValue.trim();
    if (normalized.isEmpty) return;

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

  void _handleManualVerify(List<Map<String, dynamic>> knownPasses) {
    _handleRawValue(_manualController.text, knownPasses);
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
        return Colors.white;
    }
  }

  // ─── iOS-style scan overlay ────────────────────────────────────

  Widget _buildScanOverlay(int syncedPassesCount) {
    final scanAreaSize = MediaQuery.sizeOf(context).shortestSide * 0.72;
    final topOffset = MediaQuery.sizeOf(context).height * 0.18;

    return Stack(
      children: [
        // Darkened edges (top, bottom, left, right of scan area)
        ClipPath(
          clipper: _ScanAreaClipper(
            scanSize: scanAreaSize,
            topOffset: topOffset,
          ),
          child: Container(color: Colors.black.withValues(alpha: 0.55)),
        ),

        // Corner brackets
        Positioned(
          top: topOffset,
          left: (MediaQuery.sizeOf(context).width - scanAreaSize) / 2,
          child: SizedBox(
            width: scanAreaSize,
            height: scanAreaSize,
            child: CustomPaint(
              painter: _CornerBracketPainter(
                color: Colors.white,
                lineWidth: 3.5,
                cornerLength: scanAreaSize * 0.12,
              ),
            ),
          ),
        ),

        // Animated scan line
        Positioned(
          top: topOffset,
          left: (MediaQuery.sizeOf(context).width - scanAreaSize) / 2 + 4,
          child: AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, _) {
              return Positioned(
                top: scanAreaSize * _scanLineAnimation.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 2.5,
                  width: scanAreaSize - 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // "Point at QR" label
        Positioned(
          top: topOffset + scanAreaSize + 28,
          left: 0,
          right: 0,
          child: AnimatedSwitcher(
            duration: 200.ms,
            child: _outcome.state == GatePassScanState.idle
                ? Column(
                    key: const ValueKey('idle'),
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Point camera at QR code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${_scannedPassUids.isEmpty ? '$syncedPassesCount synced' : '${_scannedPassUids.length} scanned'} passes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('result')),
          ),
        ),
      ],
    );
  }

  // ─── Top bar ───────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
            const Spacer(),
            Text(
              'GatePass Scanner',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                _torchEnabled ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              tooltip: 'Toggle torch',
              onPressed: _toggleTorch,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchEnabled = !_torchEnabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Torch is not available on this camera.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ─── Result banner ─────────────────────────────────────────────

  Widget _buildResultBanner() {
    final color = _statusColor(_outcome.state);

    return Positioned(
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
      left: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: color,
        shadowColor: color.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                _outcome.state == GatePassScanState.valid
                    ? Icons.check_circle
                    : _outcome.state == GatePassScanState.scanned
                        ? Icons.history
                        : Icons.cancel,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _outcome.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_outcome.pass != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _outcome.pass!['attendee_name'] as String? ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (_outcome.passUid != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _outcome.passUid!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_outcome.state == GatePassScanState.valid ||
                  _outcome.state == GatePassScanState.scanned)
                TextButton(
                  onPressed: _resetToIdle,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Dismiss'),
                ),
            ],
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2),
        ),
      ),
    );
  }

  // ─── Bottom panel ──────────────────────────────────────────────

  Widget _buildBottomPanel(List<Map<String, dynamic>> knownPasses) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 12,
      left: 12,
      right: 12,
      child: Material(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface.withValues(alpha: 0.96),
        elevation: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedSize(
            duration: 300.ms,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _showManualEntry ? _buildManualEntryPanel(knownPasses) : _buildCompactPanel(knownPasses),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPanel(List<Map<String, dynamic>> knownPasses) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Scan count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${_scannedPassUids.length} scanned',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Manual entry toggle
              TextButton.icon(
                onPressed: () => setState(() => _showManualEntry = true),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Manual'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              // History toggle
              if (_scannedPassUids.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _showHistory = !_showHistory),
                  icon: Icon(
                    _showHistory ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text('${_scannedPassUids.length}'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),

        // History list
        if (_showHistory && _scannedPassUids.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.18,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _scannedPassUids.length,
              itemBuilder: (context, index) {
                final passUid = _scannedPassUids.elementAt(index);
                final pass = knownPasses.firstWhere(
                  (entry) => entry['pass_uid']?.toString() == passUid,
                  orElse: () => <String, dynamic>{},
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pass['attendee_name']?.toString() ?? passUid,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        pass['company']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildManualEntryPanel(List<Map<String, dynamic>> knownPasses) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close
          Row(
            children: [
              const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Manual Entry',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _showManualEntry = false),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material3TextField(
            label: 'Paste GatePass QR payload',
            hint: 'GPX1|PASS_UID|SIGNATURE',
            controller: _manualController,
            minLines: 2,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material3Button(
                  label: 'Verify',
                  onPressed: _manualController.text.trim().isNotEmpty
                      ? () => _handleManualVerify(knownPasses)
                      : null,
                  leadingIcon: const Icon(Icons.verified, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Material3OutlinedButton(
                label: 'Clear',
                isFullWidth: false,
                onPressed: () {
                  _manualController.clear();
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final knownPasses = session.passes;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen camera
          MobileScanner(
            key: ValueKey(_scannerRestartKey),
            controller: _controller,
            fit: BoxFit.cover,
            errorBuilder: (context, error) {
              return Container(
                color: AppColors.secondary,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_photography,
                            color: Theme.of(context).colorScheme.onSecondary, size: 56),
                        const SizedBox(height: 16),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSecondary
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 24),
                        Material3Button(
                          label: 'Retry Camera',
                          onPressed: () {
                            setState(() => _scannerRestartKey++);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            onDetect: (capture) {
              if (_outcome.state != GatePassScanState.idle) return;

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

          // iOS-style scan overlay
          _buildScanOverlay(knownPasses.length),

          // Top bar
          _buildTopBar(),

          // Result banner
          if (_outcome.state != GatePassScanState.idle)
            _buildResultBanner(),

          // Bottom panel
          _buildBottomPanel(knownPasses),
        ],
      ),
    );
  }
}

// ─── Custom clipper for scan area cutout ────────────────────────

class _ScanAreaClipper extends CustomClipper<Path> {
  final double scanSize;
  final double topOffset;

  _ScanAreaClipper({required this.scanSize, required this.topOffset});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final left = (size.width - scanSize) / 2;
    final top = topOffset;

    final cutout = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanSize, scanSize),
        const Radius.circular(28),
      ));

    return Path.combine(PathOperation.reverseDifference, path, cutout);
  }

  @override
  bool shouldReclip(_ScanAreaClipper oldClipper) =>
      scanSize != oldClipper.scanSize || topOffset != oldClipper.topOffset;
}

// ─── Corner bracket painter ─────────────────────────────────────

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double lineWidth;
  final double cornerLength;

  _CornerBracketPainter({
    required this.color,
    required this.lineWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(
        Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(_CornerBracketPainter oldDelegate) =>
      color != oldDelegate.color ||
      lineWidth != oldDelegate.lineWidth ||
      cornerLength != oldDelegate.cornerLength;
}
