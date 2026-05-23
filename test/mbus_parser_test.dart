import 'package:flutter_test/flutter_test.dart';
import 'package:sayac_pro/services/mbus_parser.dart';

void main() {
  group('MBusParser', () {
    test('parses a valid MBus packet and decodes BCD correctly', () {
      // Construction of a minimal valid packet to trigger _decodeBcd
      // Start byte: 0x68
      // Length needs to be at least 19
      final bytes = <int>[
        0x68, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 0..6: header stuff
        // Meter ID bytes (sublist 7 to 11): 0x78 0x56 0x34 0x12 -> BCD -> "12345678"
        0x78, 0x56, 0x34, 0x12,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 // fill to reach 19 length
      ];

      final data = MBusParser.parseData(bytes);

      expect(data, isNotNull);
      expect(data!.meterId, '12345678');
      expect(data.energy, 0.0);
      expect(data.volume, 0.0);
    });

    test('returns null for empty packet', () {
      expect(MBusParser.parseData([]), isNull);
    });

    test('returns null for packet lacking start byte 0x68', () {
      final bytes = <int>[0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x00, 0x00];
      expect(MBusParser.parseData(bytes), isNull);
    });

    test('returns null for packet too short', () {
      final bytes = <int>[0x68, 0x00, 0x00, 0x00];
      expect(MBusParser.parseData(bytes), isNull);
    });
  });
}
