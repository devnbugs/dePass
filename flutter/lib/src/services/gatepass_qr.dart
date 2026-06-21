import 'package:flutter/foundation.dart';

enum GatePassScanState {
  idle,
  valid,
  invalid,
  scanned,
}

@immutable
class GatePassScanOutcome {
  const GatePassScanOutcome({
    required this.state,
    required this.title,
    required this.message,
    this.passUid,
    this.signature,
    this.pass,
  });

  final GatePassScanState state;
  final String title;
  final String message;
  final String? passUid;
  final String? signature;
  final Map<String, dynamic>? pass;
}

@immutable
class GatePassQrPayload {
  const GatePassQrPayload({
    required this.passUid,
    required this.signature,
  });

  final String passUid;
  final String signature;
}

GatePassQrPayload? parseGatePassQr(String rawValue) {
  final normalized = rawValue.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final parts = normalized.split('|');
  if (parts.length != 3 || parts.first != 'GPX1') {
    return null;
  }

  final passUid = parts[1].trim();
  final signature = parts[2].trim();
  if (passUid.isEmpty || signature.isEmpty) {
    return null;
  }

  return GatePassQrPayload(
    passUid: passUid,
    signature: signature,
  );
}

GatePassScanOutcome evaluateGatePassQr({
  required String rawValue,
  required List<Map<String, dynamic>> knownPasses,
  required Set<String> scannedPassUids,
}) {
  final payload = parseGatePassQr(rawValue);
  if (payload == null) {
    return const GatePassScanOutcome(
      state: GatePassScanState.invalid,
      title: 'Invalid QR',
      message: 'This code is not a valid GatePass QR payload.',
    );
  }

  Map<String, dynamic>? matchedPass;
  for (final pass in knownPasses) {
    final uid = pass['pass_uid']?.toString();
    final signature = pass['signature']?.toString();
    if (uid == payload.passUid && signature == payload.signature) {
      matchedPass = pass;
      break;
    }
  }

  if (matchedPass == null) {
    return GatePassScanOutcome(
      state: GatePassScanState.invalid,
      title: 'Invalid Pass',
      message: 'No active pass matches this GatePass QR.',
      passUid: payload.passUid,
      signature: payload.signature,
    );
  }

  final passStatus = matchedPass['status']?.toString().toLowerCase();
  if (passStatus != null && passStatus != 'active') {
    return GatePassScanOutcome(
      state: GatePassScanState.invalid,
      title: 'Pass Blocked',
      message: 'This pass is marked as $passStatus and cannot be accepted.',
      passUid: payload.passUid,
      signature: payload.signature,
      pass: matchedPass,
    );
  }

  if (scannedPassUids.contains(payload.passUid)) {
    return GatePassScanOutcome(
      state: GatePassScanState.scanned,
      title: 'Already Scanned',
      message: 'This GatePass has already been scanned during this session.',
      passUid: payload.passUid,
      signature: payload.signature,
      pass: matchedPass,
    );
  }

  return GatePassScanOutcome(
    state: GatePassScanState.valid,
    title: 'Valid Pass',
    message: 'GatePass verified successfully and ready for check-in.',
    passUid: payload.passUid,
    signature: payload.signature,
    pass: matchedPass,
  );
}
