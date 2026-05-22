import 'dart:typed_data';

Future<Uint8List?> readPlatformFileAsBytes(String? path) async {
  throw UnsupportedError('Cannot read file on this platform');
}

Future<void> savePlatformExcel(Uint8List bytes, String fileName) async {
  throw UnsupportedError('Cannot save file on this platform');
}
