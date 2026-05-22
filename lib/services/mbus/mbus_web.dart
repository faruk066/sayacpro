import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mbus_interface.dart';

class MBusWeb implements MBusInterface {
  final _dataController = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get dataStream => _dataController.stream;

  @override
  Future<List<dynamic>> listDevices() async {
    debugPrint("Web modunda donanım okuması kapalıdır.");
    return [];
  }

  @override
  Future<bool> connect(dynamic device, {int baudRate = 2400}) async {
    debugPrint("Web modunda donanım okuması kapalıdır.");
    return false;
  }

  @override
  Future<void> write(Uint8List data) async {
    debugPrint("Web modunda donanım okuması kapalıdır.");
  }

  @override
  Future<void> sendReadRequest({String? targetSerial}) async {
    debugPrint("Web modunda donanım okuması kapalıdır.");
  }

  @override
  Future<void> disconnect() async {
    debugPrint("Web modunda donanım okuması kapalıdır.");
  }

  @override
  void dispose() {
    _dataController.close();
  }
}

MBusInterface createMBusService() => MBusWeb();
