import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<Uint8List?> readPlatformFileAsBytes(String? path) async {
  if (path == null) return null;
  final file = File(path);
  return await file.readAsBytes();
}

Future<void> savePlatformExcel(Uint8List bytes, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/$fileName';

  final file = File(filePath);
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(filePath)],
      text: '$fileName Raporu',
    ),
  );
}
