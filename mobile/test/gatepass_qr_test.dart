import 'package:depass_mobile/src/services/gatepass_qr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final passes = [
    {
      'pass_uid': 'ABC123',
      'signature': 'sig-1',
      'attendee_name': 'Test Guest',
      'company': 'GatePassX',
      'status': 'active',
    },
  ];

  test('parses valid GatePass payloads', () {
    final parsed = parseGatePassQr('GPX1|ABC123|sig-1');

    expect(parsed, isNotNull);
    expect(parsed?.passUid, 'ABC123');
    expect(parsed?.signature, 'sig-1');
  });

  test('marks unknown payloads invalid', () {
    final outcome = evaluateGatePassQr(
      rawValue: 'GPX1|UNKNOWN|sig-x',
      knownPasses: passes,
      scannedPassUids: {},
    );

    expect(outcome.state, GatePassScanState.invalid);
    expect(outcome.title, 'Invalid Pass');
  });

  test('marks repeat scans as scanned', () {
    final outcome = evaluateGatePassQr(
      rawValue: 'GPX1|ABC123|sig-1',
      knownPasses: passes,
      scannedPassUids: {'ABC123'},
    );

    expect(outcome.state, GatePassScanState.scanned);
    expect(outcome.title, 'Already Scanned');
  });

  test('marks fresh matches as valid', () {
    final outcome = evaluateGatePassQr(
      rawValue: 'GPX1|ABC123|sig-1',
      knownPasses: passes,
      scannedPassUids: {},
    );

    expect(outcome.state, GatePassScanState.valid);
    expect(outcome.pass?.['attendee_name'], 'Test Guest');
  });
}
