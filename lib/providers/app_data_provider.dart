import 'package:flutter/foundation.dart';
import '../models/meter_data.dart';

abstract class AppDataProvider extends ChangeNotifier {
  String get siteName;
  ReadingMode get selectedReadingMode;
  List<MeterData> get meterList;
  bool get isReading;
}
