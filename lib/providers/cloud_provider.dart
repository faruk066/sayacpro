import 'dart:async';
import '../services/firebase_service.dart';
import '../models/site_data.dart';
import '../models/meter_data.dart';
import 'app_data_provider.dart';

class CloudProvider extends AppDataProvider {
  final FirebaseService _firebaseService = FirebaseService();

  String _currentSiteId = '';
  SiteData? _siteData;
  List<MeterData> _meters = [];

  StreamSubscription<SiteData?>? _siteSub;
  StreamSubscription<List<MeterData>>? _metersSub;

  String get currentSiteId => _currentSiteId;
  SiteData? get siteData => _siteData;

  @override
  List<MeterData> get meterList => _meters;

  @override
  String get siteName => _siteData?.siteName ?? '';

  @override
  ReadingMode get selectedReadingMode {
    if (_siteData?.readingMode == 'heat') return ReadingMode.heat;
    if (_siteData?.readingMode == 'water') return ReadingMode.water;
    return ReadingMode.both;
  }

  @override
  bool get isReading => false;

  void listenToSite(String siteId) {
    if (_currentSiteId == siteId) return;

    _currentSiteId = siteId;
    _siteSub?.cancel();
    _metersSub?.cancel();

    if (siteId.isEmpty) {
      _siteData = null;
      _meters = [];
      notifyListeners();
      return;
    }

    _siteSub = _firebaseService.watchSiteData(siteId).listen((data) {
      _siteData = data;
      notifyListeners();
    });

    _metersSub = _firebaseService.watchMeters(siteId).listen((data) {
      _meters = data;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _siteSub?.cancel();
    _metersSub?.cancel();
    super.dispose();
  }
}
