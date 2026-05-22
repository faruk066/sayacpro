import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'mbus_interface.dart';

class MBusMobile implements MBusInterface {
  UsbPort? _port;
  StreamSubscription<Uint8List>? _dataSubscription;

  List<int> _lastSentBytes = [];
  final List<int> _dataBuffer = [];

  final _dataController = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get dataStream => _dataController.stream;

  @override
  Future<List<dynamic>> listDevices() async {
    return await UsbSerial.listDevices();
  }

  @override
  Future<bool> connect(dynamic device, {int baudRate = 2400}) async {
    if (device is! UsbDevice) return false;

    try {
      _port = await device.create();
      if (_port == null) return false;

      final opened = await _port!.open();
      if (!opened) {
        _port = null;
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_EVEN,
      );

      _dataSubscription = _port!.inputStream!.listen(
        (Uint8List data) {
          _dataBuffer.addAll(data);

          if (_lastSentBytes.isNotEmpty && _dataBuffer.isNotEmpty) {
            bool stillMatching = true;
            for (int i = 0; i < _dataBuffer.length && i < _lastSentBytes.length; i++) {
              if (_dataBuffer[i] != _lastSentBytes[i]) {
                stillMatching = false;
                break;
              }
            }

            if (!stillMatching) {
              _lastSentBytes.clear();
            } else if (_dataBuffer.length >= _lastSentBytes.length) {
              _dataBuffer.removeRange(0, _lastSentBytes.length);
              _lastSentBytes.clear();
            }
          }

          if (_lastSentBytes.isEmpty && _dataBuffer.isNotEmpty) {
            _dataController.add(Uint8List.fromList(_dataBuffer));
            _dataBuffer.clear();
          }
        },
        onError: (error) {
          _dataController.addError(error);
        },
      );

      return true;
    } catch (e) {
      _port = null;
      rethrow;
    }
  }

  @override
  Future<void> write(Uint8List data) async {
    if (_port == null) {
      throw Exception('Port bağlı değil!');
    }
    _dataBuffer.clear();
    _lastSentBytes = data.toList();
    await _port!.write(data);
  }

  @override
  Future<void> sendReadRequest({String? targetSerial}) async {
    if (_port == null) {
      throw Exception('Port bağlı değil!');
    }

    if (targetSerial != null && targetSerial.length >= 8) {
      final b1 = int.parse(targetSerial.substring(6, 8), radix: 16);
      final b2 = int.parse(targetSerial.substring(4, 6), radix: 16);
      final b3 = int.parse(targetSerial.substring(2, 4), radix: 16);
      final b4 = int.parse(targetSerial.substring(0, 2), radix: 16);

      await write(Uint8List.fromList([0x10, 0x40, 0xFE, 0x3E, 0x16]));
      debugPrint('Ping gönderildi, 1sn bekleniyor');
      await Future.delayed(const Duration(milliseconds: 1000));

      await write(Uint8List.fromList([0x10, 0x40, 0xFD, 0x3D, 0x16]));
      debugPrint('SIFIRLAMA: 10 40 FD 3D 16');
      await Future.delayed(const Duration(milliseconds: 600));

      final baseFrame = [0x68, 0x0B, 0x0B, 0x68, 0x53, 0xFD, 0x52, b1, b2, b3, b4, 0xFF, 0xFF, 0xFF, 0xFF];
      int cs = 0;
      for (int i = 4; i < baseFrame.length; i++) {
        cs = (cs + baseFrame[i]) % 256;
      }
      final selectionFrame = Uint8List.fromList([...baseFrame, cs, 0x16]);

      Future<bool> waitForE5(Duration timeout) async {
        final completer = Completer<bool>();
        final sub = dataStream.listen((data) {
          if (data.contains(0xE5) && !completer.isCompleted) {
            completer.complete(true);
          }
        });
        try {
          return await completer.future.timeout(timeout);
        } catch (_) {
          return false;
        } finally {
          await sub.cancel();
        }
      }

      await write(selectionFrame);
      debugPrint("Seçim Çerçevesi gönderildi: $targetSerial");

      bool e5Received = await waitForE5(const Duration(milliseconds: 400));

      if (e5Received) {
        debugPrint("E5 Alındı. 7B okuma komutu gönderiliyor...");
      } else {
        debugPrint("E5 ALINAMADI! (Kör Okuma Aktif - Zorla 7B gönderiliyor...)");
      }

      await Future.delayed(const Duration(milliseconds: 150));
      await write(Uint8List.fromList([0x10, 0x7B, 0xFD, 0x78, 0x16]));
      debugPrint("Okuma Komutu (FD - 7B) hatta basıldı!");
    } else {
      final mBusCommand = Uint8List.fromList([0x10, 0x5B, 0xFE, 0x59, 0x16]);
      await write(mBusCommand);
    }
  }

  @override
  Future<void> disconnect() async {
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _port?.close();
    _port = null;
  }

  @override
  void dispose() {
    disconnect();
    _dataController.close();
  }
}

MBusInterface createMBusService() => MBusMobile();
