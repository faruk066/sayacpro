// ignore_for_file: avoid_print
import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  var bytes = File('buformat..xlsx').readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);
  for (var table in excel.tables.keys) {
    print('Table: $table');
    var sheet = excel.tables[table]!;
    for (var i = 0; i < (sheet.maxRows < 10 ? sheet.maxRows : 10); i++) {
      print('Row $i: ${sheet.rows[i].map((e) => e?.value).toList()}');
    }
  }
}
