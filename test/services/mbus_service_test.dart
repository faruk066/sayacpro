import 'package:flutter_test/flutter_test.dart';
import 'package:sayac_pro/services/mbus/mbus_mobile.dart';

void main() {
  group('MBusService Disconnected Tests', () {
    late MBusMobile mbusService;

    setUp(() {
      mbusService = MBusMobile();
    });

    test('sendReadRequest throws Exception when port is null', () async {
      expect(
        () => mbusService.sendReadRequest(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Port bağlı değil!'))),
      );
    });

    test('sendReadRequest with targetSerial throws Exception when port is null', () async {
      expect(
        () => mbusService.sendReadRequest(targetSerial: "12345678"),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Port bağlı değil!'))),
      );
    });
  });
}
