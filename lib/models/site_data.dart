import 'package:cloud_firestore/cloud_firestore.dart';

class SiteData {
  final String siteId;
  final String siteName;
  final String readingMode;
  final String status;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final int totalMeters;
  final int readCount;

  SiteData({
    required this.siteId,
    required this.siteName,
    required this.readingMode,
    required this.status,
    required this.lastUpdated,
    required this.createdAt,
    required this.totalMeters,
    required this.readCount,
  });

  factory SiteData.fromJson(Map<String, dynamic> json) {
    return SiteData(
      siteId: json['siteId'] ?? '',
      siteName: json['siteName'] ?? '',
      readingMode: json['readingMode'] ?? '',
      status: json['status'] ?? 'idle',
      lastUpdated: (json['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalMeters: json['totalMeters'] ?? 0,
      readCount: json['readCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'siteId': siteId,
      'siteName': siteName,
      'readingMode': readingMode,
      'status': status,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.fromDate(createdAt),
      'totalMeters': totalMeters,
      'readCount': readCount,
    };
  }
}
