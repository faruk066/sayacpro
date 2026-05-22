enum ReadingMode { heat, water, both }
enum MeterType { heat, water }
enum MeterStatus { pending, success, failed }

class MeterData {
  String flatNo;
  String heatMeterId;
  String heatIndex;
  MeterStatus heatStatus;
  String waterMeterId;
  String waterIndex;
  MeterStatus waterStatus;
  MeterStatus overallStatus; // Genel durum (her ikisi de tamam mı?)
  MeterType type;
  DateTime? readTime;

  String? blok;
  String? adSoyad;
  String? sonOkumaTarihi;
  String? sonEndeks;

  String get status => getStatusText();

  MeterData({
    required this.flatNo,
    required this.heatMeterId,
    required this.heatIndex,
    this.heatStatus = MeterStatus.pending,
    required this.waterMeterId,
    required this.waterIndex,
    this.waterStatus = MeterStatus.pending,
    required this.overallStatus,
    this.type = MeterType.heat,
    this.readTime,
    this.blok,
    this.adSoyad,
    this.sonOkumaTarihi,
    this.sonEndeks,
  });

  Map<String, dynamic> toJson() {
    return {
      'flatNo': flatNo,
      'heatMeterId': heatMeterId,
      'heatIndex': heatIndex,
      'heatStatus': heatStatus.name,
      'waterMeterId': waterMeterId,
      'waterIndex': waterIndex,
      'waterStatus': waterStatus.name,
      'overallStatus': overallStatus.name,
      'type': type.name,
      'readTime': readTime?.toIso8601String(),
      if (blok != null) 'blok': blok,
      if (adSoyad != null) 'adSoyad': adSoyad,
      if (sonOkumaTarihi != null) 'sonOkumaTarihi': sonOkumaTarihi,
      if (sonEndeks != null) 'sonEndeks': sonEndeks,
    };
  }

  factory MeterData.fromJson(Map<String, dynamic> json) {
    return MeterData(
      flatNo: json['flatNo'] as String? ?? '',
      heatMeterId: json['heatMeterId'] as String? ?? '',
      heatIndex: json['heatIndex'] as String? ?? '',
      heatStatus: MeterStatus.values.byName(json['heatStatus'] as String? ?? 'pending'),
      waterMeterId: json['waterMeterId'] as String? ?? '',
      waterIndex: json['waterIndex'] as String? ?? '',
      waterStatus: MeterStatus.values.byName(json['waterStatus'] as String? ?? 'pending'),
      overallStatus: MeterStatus.values.byName(json['overallStatus'] as String? ?? json['status'] as String? ?? 'pending'),
      type: MeterType.values.byName(json['type'] as String? ?? 'heat'),
      readTime: json['readTime'] != null ? DateTime.parse(json['readTime'] as String) : null,
      blok: json['blok'] as String?,
      adSoyad: json['adSoyad'] as String?,
      sonOkumaTarihi: json['sonOkumaTarihi'] as String?,
      sonEndeks: json['sonEndeks'] as String?,
    );
  }

  @override
  String toString() {
    return 'MeterData(flatNo: $flatNo, heat: $heatMeterId, water: $waterMeterId, heatStatus: $heatStatus, waterStatus: $waterStatus)';
  }

  String getStatusText() {
    if (heatStatus == MeterStatus.success && waterStatus == MeterStatus.success) {
      return "Başarılı";
    }
    if (heatStatus == MeterStatus.failed && waterStatus == MeterStatus.failed) {
      return "Su, Kalori Okunamadı";
    }
    if (heatStatus == MeterStatus.failed) {
      return "Kalori Okunamadı";
    }
    if (waterStatus == MeterStatus.failed) {
      return "Su Okunamadı";
    }
    return "Bekliyor";
  }

  String getHeatIndexDisplay() {
    if (heatMeterId.isEmpty) return "Okunamadı";
    if (heatStatus == MeterStatus.failed) return "Okunamadı";

    if (heatIndex.isEmpty || heatIndex == "null") {
      return "Okunamadı";
    }

    try {
      double val = double.parse(heatIndex);
      if (val == 0) return "0";
      
      // Remove the dot to convert "56.205" into "56205"
      return heatIndex.replaceAll('.', '');
    } catch (e) {
      return heatIndex.replaceAll('.', '');
    }
  }

  String getWaterIndexDisplay() {
    if (waterMeterId.isEmpty) return "Okunamadı";
    if (waterStatus == MeterStatus.failed) return "Okunamadı";

    if (waterIndex.isEmpty || waterIndex == "null") {
      return "Okunamadı";
    }

    try {
      double val = double.parse(waterIndex);
      if (val == 0) return "0";
      return waterIndex;
    } catch (e) {
      return waterIndex;
    }
  }
  String getHeatMeterIdDisplay() {
    return (heatMeterId.isEmpty || heatMeterId == "null") ? "Seri No Bulunamadı" : heatMeterId;
  }

  String getWaterMeterIdDisplay() {
    return (waterMeterId.isEmpty || waterMeterId == "null") ? "Seri No Bulunamadı" : waterMeterId;
  }
}
