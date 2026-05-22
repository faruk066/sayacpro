import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/site_data.dart';
import '../models/meter_data.dart';

class FirebaseService {
  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      throw Exception("Firebase is not initialized");
    }
  }

  Future<void> updateSiteData(String siteId, SiteData data) async {
    await _db.collection('sites').doc(siteId).set(data.toJson(), SetOptions(merge: true));
  }

  Future<void> updateMeterData(String siteId, String flatNo, MeterData meterData) async {
    final data = meterData.toJson();
    data['readTime'] = meterData.readTime != null ? Timestamp.fromDate(meterData.readTime!) : null;

    await _db
        .collection('sites')
        .doc(siteId)
        .collection('meters')
        .doc(flatNo)
        .set(data, SetOptions(merge: true));
  }

  Stream<SiteData?> watchSiteData(String siteId) {
    return _db.collection('sites').doc(siteId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return SiteData.fromJson(doc.data()!);
      }
      return null;
    });
  }

  Stream<List<MeterData>> watchMeters(String siteId) {
    return _db
        .collection('sites')
        .doc(siteId)
        .collection('meters')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['readTime'] is Timestamp) {
           data['readTime'] = (data['readTime'] as Timestamp).toDate().toIso8601String();
        }
        return MeterData.fromJson(data);
      }).toList();
    });
  }
}
