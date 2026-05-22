import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

Future<Uint8List?> readPlatformFileAsBytes(String? path) async {
  return null;
}

Future<void> savePlatformExcel(Uint8List bytes, String fileName) async {
  final base64Encoded = base64Encode(bytes);

  final anchor = html.AnchorElement(
      href: 'data:application/octet-stream;base64,$base64Encoded')
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
