import 'package:flutter_test/flutter_test.dart';
import 'package:sayac_pro/models/meter_data.dart';

void main() {
  group('MeterData.fromJson', () {
    test('parses correctly with all fields provided', () {
      final json = {
        'flatNo': '10',
        'heatMeterId': 'HEAT123',
        'heatIndex': '100.5',
        'heatStatus': 'success',
        'waterMeterId': 'WATER123',
        'waterIndex': '50.2',
        'waterStatus': 'success',
        'overallStatus': 'success',
        'type': 'heat',
        'readTime': '2023-01-01T12:00:00.000',
        'blok': 'A',
        'adSoyad': 'John Doe',
        'sonOkumaTarihi': '2022-12-01',
        'sonEndeks': '90.0',
      };

      final data = MeterData.fromJson(json);

      expect(data.flatNo, '10');
      expect(data.heatMeterId, 'HEAT123');
      expect(data.heatIndex, '100.5');
      expect(data.heatStatus, MeterStatus.success);
      expect(data.waterMeterId, 'WATER123');
      expect(data.waterIndex, '50.2');
      expect(data.waterStatus, MeterStatus.success);
      expect(data.overallStatus, MeterStatus.success);
      expect(data.type, MeterType.heat);
      expect(data.readTime, DateTime.parse('2023-01-01T12:00:00.000'));
      expect(data.blok, 'A');
      expect(data.adSoyad, 'John Doe');
      expect(data.sonOkumaTarihi, '2022-12-01');
      expect(data.sonEndeks, '90.0');
    });

    test('uses default values when fields are missing', () {
      final json = <String, dynamic>{};

      final data = MeterData.fromJson(json);

      expect(data.flatNo, '');
      expect(data.heatMeterId, '');
      expect(data.heatIndex, '');
      expect(data.heatStatus, MeterStatus.pending);
      expect(data.waterMeterId, '');
      expect(data.waterIndex, '');
      expect(data.waterStatus, MeterStatus.pending);
      expect(data.overallStatus, MeterStatus.pending);
      expect(data.type, MeterType.heat);
      expect(data.readTime, isNull);
      expect(data.blok, isNull);
      expect(data.adSoyad, isNull);
      expect(data.sonOkumaTarihi, isNull);
      expect(data.sonEndeks, isNull);
    });

    test('uses default values when fields are null', () {
      final json = {
        'flatNo': null,
        'heatMeterId': null,
        'heatIndex': null,
        'heatStatus': null,
        'waterMeterId': null,
        'waterIndex': null,
        'waterStatus': null,
        'overallStatus': null,
        'type': null,
        'readTime': null,
        'blok': null,
        'adSoyad': null,
        'sonOkumaTarihi': null,
        'sonEndeks': null,
      };

      final data = MeterData.fromJson(json);

      expect(data.flatNo, '');
      expect(data.heatMeterId, '');
      expect(data.heatIndex, '');
      expect(data.heatStatus, MeterStatus.pending);
      expect(data.waterMeterId, '');
      expect(data.waterIndex, '');
      expect(data.waterStatus, MeterStatus.pending);
      expect(data.overallStatus, MeterStatus.pending);
      expect(data.type, MeterType.heat);
      expect(data.readTime, isNull);
      expect(data.blok, isNull);
      expect(data.adSoyad, isNull);
      expect(data.sonOkumaTarihi, isNull);
      expect(data.sonEndeks, isNull);
    });

    test('falls back to status key when overallStatus is missing', () {
      final json = {
        'status': 'success',
      };

      final data = MeterData.fromJson(json);

      expect(data.overallStatus, MeterStatus.success);
    });

    test('falls back to status key when overallStatus is null', () {
      final json = {
        'overallStatus': null,
        'status': 'failed',
      };

      final data = MeterData.fromJson(json);

      expect(data.overallStatus, MeterStatus.failed);
    });

    test('throws ArgumentError on invalid enum values', () {
      final jsonInvalidHeatStatus = {'heatStatus': 'invalid_status'};
      expect(() => MeterData.fromJson(jsonInvalidHeatStatus), throwsArgumentError);

      final jsonInvalidType = {'type': 'invalid_type'};
      expect(() => MeterData.fromJson(jsonInvalidType), throwsArgumentError);
    });
  });
}
