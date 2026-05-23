import 'package:flutter_test/flutter_test.dart';
import 'package:sayac_pro/services/mbus_parser.dart';

void main() {
  group('MBusParser _decodeBcdInt', () {
    test('Empty array returns 0.0', () {
      expect(MBusParser.decodeBcdIntForTesting([]), 0.0);
    });

    test('Single byte 0x00 returns 0.0', () {
      expect(MBusParser.decodeBcdIntForTesting([0x00]), 0.0);
    });

    test('Single byte 0x09 returns 9.0', () {
      expect(MBusParser.decodeBcdIntForTesting([0x09]), 9.0);
    });

    test('Single byte 0x90 returns 90.0', () {
      expect(MBusParser.decodeBcdIntForTesting([0x90]), 90.0);
    });

    test('Single byte 0x99 returns 99.0', () {
      expect(MBusParser.decodeBcdIntForTesting([0x99]), 99.0);
    });

    test('Multi-byte typical value: 1234 (0x34, 0x12)', () {
      expect(MBusParser.decodeBcdIntForTesting([0x34, 0x12]), 1234.0);
    });

    test('4-byte max valid BCD: 99999999 (0x99, 0x99, 0x99, 0x99)', () {
      expect(MBusParser.decodeBcdIntForTesting([0x99, 0x99, 0x99, 0x99]), 99999999.0);
    });

    test('Large 6-byte value: 999999999999 (0x99, 0x99, 0x99, 0x99, 0x99, 0x99)', () {
      expect(MBusParser.decodeBcdIntForTesting([0x99, 0x99, 0x99, 0x99, 0x99, 0x99]), 999999999999.0);
    });

    // BCD parsing in this code does not strictly validate the nibbles, it just uses standard math.
    // E.g. A (10) would result in `10 * 1 = 10`. B (11) * 10 = 110, so 0xBA -> 10 + 110 = 120.
    // We should test to assert the deterministic behavior as it stands.
    test('Invalid BCD nibbles (A-F) calculate deterministically', () {
      // 0x1A: A is 10, 1 is 1 -> 10*1 + 1*10 = 20
      expect(MBusParser.decodeBcdIntForTesting([0x1A]), 20.0);

      // 0xFF: F is 15 -> 15*1 + 15*10 = 165
      expect(MBusParser.decodeBcdIntForTesting([0xFF]), 165.0);
    });
  });
}
