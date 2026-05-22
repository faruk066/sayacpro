import 'dart:async';
import 'dart:typed_data';

abstract class MBusInterface {
  Stream<Uint8List> get dataStream;
  Future<List<dynamic>> listDevices();
  Future<bool> connect(dynamic device, {int baudRate = 2400});
  Future<void> write(Uint8List data);
  Future<void> sendReadRequest({String? targetSerial});
  Future<void> disconnect();
  void dispose();
}
