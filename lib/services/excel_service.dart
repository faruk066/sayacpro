import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:excel/excel.dart' as excel_pkg;
import '../models/meter_data.dart';

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

  static List<MeterData> parseExcel(Uint8List bytes) {
    var excel = excel_pkg.Excel.decodeBytes(bytes);
    var sheet = excel.tables.values.first;

    if (sheet.maxRows == 0) return [];

    // Analyze headers to detect format
    var headerRow = sheet.rows[0];
    List<String> headers = headerRow.map((e) => _extractRawValue(e?.value).toLowerCase()).toList();

    bool isTelegram = headers.contains('sayaç tipi');
    bool isPolimeter = headers.contains('ıd2') || headers.contains('tip');

    if (isTelegram) {
      return _parseTelegramFormat(sheet, headers);
    } else if (isPolimeter) {
      return _parsePolimeterFormat(sheet, headers);
    } else {
      return _parseStandardFormat(sheet);
    }
  }

  static List<MeterData> _parseTelegramFormat(excel_pkg.Sheet sheet, List<String> headers) {
    Map<String, MeterData> map = {};
    int daireIdx = headers.indexOf('daire no');
    int sayacNoIdx = headers.indexOf('sayaç no');
    int sayacTipiIdx = headers.indexOf('sayaç tipi');
    int tarihIdx = headers.indexOf('son okuma tarihi');
    int endeksIdx = headers.indexOf('son endeks');

    for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      String daire = daireIdx >= 0 && daireIdx < row.length ? _extractRawValue(row[daireIdx]?.value) : "";
      if (daire.isEmpty) continue;

      String sayacNo = sayacNoIdx >= 0 && sayacNoIdx < row.length ? _extractRawValue(row[sayacNoIdx]?.value) : "";
      String tip = sayacTipiIdx >= 0 && sayacTipiIdx < row.length ? _extractRawValue(row[sayacTipiIdx]?.value) : "";
      String tarih = tarihIdx >= 0 && tarihIdx < row.length ? _extractRawValue(row[tarihIdx]?.value) : "";
      String endeks = endeksIdx >= 0 && endeksIdx < row.length ? _extractRawValue(row[endeksIdx]?.value) : "";

      if (!map.containsKey(daire)) {
        map[daire] = MeterData(
          flatNo: daire,
          heatMeterId: '',
          heatIndex: '',
          waterMeterId: '',
          waterIndex: '',
          overallStatus: MeterStatus.pending,
        );
      }

      var meter = map[daire]!;
      if (tip == '4') {
        meter.heatMeterId = sayacNo.isEmpty ? "Seri No Bulunamadı" : sayacNo;
        meter.heatIndex = endeks;
        meter.sonOkumaTarihi = tarih;
        meter.sonEndeks = endeks;
      } else if (tip == '6') {
        meter.waterMeterId = sayacNo.isEmpty ? "Seri No Bulunamadı" : sayacNo;
        meter.waterIndex = endeks;
      }
    }

    // Default missing meters
    for (var meter in map.values) {
      if (meter.heatMeterId.isEmpty) meter.heatMeterId = "Seri No Bulunamadı";
      if (meter.waterMeterId.isEmpty) meter.waterMeterId = "Seri No Bulunamadı";
    }

    return map.values.toList();
  }

  static List<MeterData> _parsePolimeterFormat(excel_pkg.Sheet sheet, List<String> headers) {
    Map<String, MeterData> map = {};
    int blokIdx = headers.indexOf('blok');
    int daireIdx = headers.indexOf('daire');
    int adSoyadIdx = headers.indexOf('ad soyad');
    int tipIdx = headers.indexOf('tip');
    int id2Idx = headers.indexOf('ıd2');

    for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      String daire = daireIdx >= 0 && daireIdx < row.length ? _extractRawValue(row[daireIdx]?.value) : "";
      if (daire.isEmpty) continue;

      String blok = blokIdx >= 0 && blokIdx < row.length ? _extractRawValue(row[blokIdx]?.value) : "";
      String adSoyad = adSoyadIdx >= 0 && adSoyadIdx < row.length ? _extractRawValue(row[adSoyadIdx]?.value) : "";
      String tip = tipIdx >= 0 && tipIdx < row.length ? _extractRawValue(row[tipIdx]?.value) : "";
      String id2 = id2Idx >= 0 && id2Idx < row.length ? _extractRawValue(row[id2Idx]?.value) : "";

      if (!map.containsKey(daire)) {
        map[daire] = MeterData(
          flatNo: daire,
          heatMeterId: '',
          heatIndex: '',
          waterMeterId: '',
          waterIndex: '',
          overallStatus: MeterStatus.pending,
          blok: blok,
          adSoyad: adSoyad,
        );
      }

      var meter = map[daire]!;
      if (tip == '4') {
        meter.heatMeterId = id2.isEmpty ? "Seri No Bulunamadı" : id2;
      } else if (tip == '6') {
        meter.waterMeterId = id2.isEmpty ? "Seri No Bulunamadı" : id2;
      }
    }

    for (var meter in map.values) {
      if (meter.heatMeterId.isEmpty) meter.heatMeterId = "Seri No Bulunamadı";
      if (meter.waterMeterId.isEmpty) meter.waterMeterId = "Seri No Bulunamadı";
    }

    return map.values.toList();
  }

  static List<MeterData> _parseStandardFormat(excel_pkg.Sheet sheet) {
    List<MeterData> list = [];

    for (var i = 1; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty) continue;

      if (row[0] == null || row[0]?.value == null || _extractRawValue(row[0]?.value).isEmpty) {
        continue;
      }

      String daire = _extractRawValue(row[0]?.value);
      String heat = _extractRawValue(row.length > 1 ? row[1]?.value : null);
      String water = _extractRawValue(row.length > 2 ? row[2]?.value : null);

      if (heat.isEmpty) heat = "Seri No Bulunamadı";
      if (water.isEmpty) water = "Seri No Bulunamadı";

      list.add(MeterData(
        flatNo: daire,
        heatMeterId: heat,
        heatIndex: '',
        waterMeterId: water,
        waterIndex: '',
        overallStatus: MeterStatus.pending,
      ));
    }
    return list;
  }

  static String _extractRawValue(dynamic cell) {
    if (cell == null) return "";

    if (cell is excel_pkg.TextCellValue) return cell.value.toString().trim();
    if (cell is excel_pkg.IntCellValue) return cell.value.toString().trim();
    if (cell is excel_pkg.DoubleCellValue) {
      double d = (cell as dynamic).value;
      if (d == d.toInt().toDouble()) {
        return d.toInt().toString();
      }
      return cell.value.toString().trim();
    }

    return cell.toString().trim();
  }
}
