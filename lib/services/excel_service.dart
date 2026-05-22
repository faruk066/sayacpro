import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart' as fp;

import 'excel_io_stub.dart'
    if (dart.library.io) 'excel_io_mobile.dart'
    if (dart.library.html) 'excel_io_web.dart';

class ExcelService {
  static Future<Uint8List?> pickAndReadExcel() async {
    try {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null) {
        if (kIsWeb) {
          return result.files.single.bytes;
        } else {
          return result.files.single.bytes ?? await readPlatformFileAsBytes(result.files.single.path);
        }
      }
    } catch (e) {
      debugPrint("Excel okuma hatası: $e");
    }
    return null;
  }

  static Future<void> saveAndShareExcel(Uint8List bytes, String fileName) async {
    await savePlatformExcel(bytes, fileName);
  }
}
