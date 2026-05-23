import 'package:flutter_test/flutter_test.dart';
import 'package:sayac_pro/services/mbus/mbus_mobile.dart';

void main() {
  group('MBusMobile Tests', () {
    test(
      'sendReadRequest throws exception when port is not connected',
      () async {
        final mbusMobile = MBusMobile();

        // We are expecting an Exception to be thrown
        expect(
          () async => await mbusMobile.sendReadRequest(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Port bağlı değil!'),
            ),
          ),
        );
      },
    );
  });
}
