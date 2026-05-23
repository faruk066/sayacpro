import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import 'package:audioplayers/audioplayers.dart';
import '../services/firebase_service.dart';
import '../models/site_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/mbus/connection_status.dart';
import '../services/mbus/mbus_interface.dart';
import '../services/mbus/mbus_stub.dart';
import '../services/excel_service.dart';
import '../services/mbus_parser.dart';
import '../models/meter_data.dart';

export '../services/mbus/connection_status.dart';
export '../models/meter_data.dart';
import 'app_data_provider.dart';

class MBusCommandOption {
  final String label;
  final List<int> command;

  const MBusCommandOption(this.label, this.command);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MBusCommandOption && label == other.label;

  @override
  int get hashCode => label.hashCode;
}

class DeviceProvider extends AppDataProvider {
  final MBusInterface _service = getMBusService();
  final FirebaseService _firebaseService = FirebaseService();

  final List<MBusCommandOption> addressOptions = const [
    MBusCommandOption('Tümü (FE - Broadcast)', [0x10, 0x5B, 0xFE, 0x59, 0x16]),
    MBusCommandOption('Adres 00 (Sıfır Sayaç)', [0x10, 0x5B, 0x00, 0x5B, 0x16]),
    MBusCommandOption('Adres 01', [0x10, 0x5B, 0x01, 0x5C, 0x16]),
    MBusCommandOption('Adres FD (Standart Ağ)', [0x10, 0x5B, 0xFD, 0x58, 0x16]),
    MBusCommandOption('İkincil Adres (Seri No ile)', []),
    MBusCommandOption('Birincil Adres ile Tara (0-250)', []),
  ];

  late MBusCommandOption _selectedCommand = addressOptions[0];

  List<dynamic> _devices = [];
  dynamic _selectedDevice;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  final List<String> _logLines = [];
  bool _isReading = false;
  StreamSubscription<Uint8List>? _dataSubscription;

  final Map<String, MeterData> _meters = {};
  final List<int> _rxBuffer = [];
  Timer? _bufferTimer;
  Timer? _timeoutTimer;
  Timer? _saveTimer;

  int _baudRate = 2400;
  String _heatSecondaryIds = '';
  String _waterSecondaryIds = '';
  String _daireIds = '';
  int _primaryStart = 1;
  int _primaryEnd = 50;
  MeterType _selectedMeterType = MeterType.heat;
  ReadingMode _selectedReadingMode = ReadingMode.both;
  String _readingStatus = '';
  int _activeIndex = -1;
  Completer<bool>? _readCompleter;
  Completer<bool>? _e5Completer;

  bool _isPaused = false;
  bool _isStopped = false;
  Completer<void>? _pauseCompleter;

  String _siteName = '';
  String get siteId => _siteName.isEmpty
      ? 'default_site'
      : _siteName.replaceAll(' ', '_').toLowerCase();
  String _currentReadingFlat = '';
  final Map<String, int> _expectedDaireNo = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;

  DeviceProvider() {
    loadSession();
  }

  List<dynamic> get devices => _devices;
  dynamic get selectedDevice => _selectedDevice;
  ConnectionStatus get status => _status;
  List<String> get logLines => List.unmodifiable(_logLines);
  @override
  bool get isReading => _isReading;
  bool get isConnected => _status == ConnectionStatus.connected;
  Map<String, MeterData> get meters => Map.unmodifiable(_meters);
  @override
  List<MeterData> get meterList => _meters.values.toList();
  int get baudRate => _baudRate;
  MBusCommandOption get selectedCommand => _selectedCommand;
  String get heatSecondaryIds => _heatSecondaryIds;
  String get waterSecondaryIds => _waterSecondaryIds;
  String get daireIds => _daireIds;
  int get primaryStart => _primaryStart;
  int get primaryEnd => _primaryEnd;
  @override
  ReadingMode get selectedReadingMode => _selectedReadingMode;
  String get readingStatus => _readingStatus;
  bool get isPaused => _isPaused;
  bool get isStopped => _isStopped;
  @override
  String get siteName => _siteName;
  bool get isSoundEnabled => _isSoundEnabled;
  int get activeIndex => _activeIndex;
  String get currentReadingFlat => _currentReadingFlat;

  void toggleSound() {
    _isSoundEnabled = !_isSoundEnabled;
    notifyListeners();
  }

  Future<void> _playSound(String type) async {
    if (!_isSoundEnabled) return;
    try {
      if (type == 'success') {
        await _audioPlayer.play(AssetSource('audio/success.wav'));
      } else if (type == 'error') {
        await _audioPlayer.play(AssetSource('audio/error.wav'));
      } else if (type == 'complete') {
        await _audioPlayer.play(AssetSource('audio/complete.wav'));
      }
    } catch (e) {
      _addLog('Ses çalma hatası: $e');
    }
  }

  void setSiteName(String value) {
    _siteName = value;
    _updateFirebaseSiteData();
    notifyListeners();
  }

  void _updateFirebaseSiteData() {
    if (kIsWeb) return;
    final data = SiteData(
      siteId: siteId,
      siteName: _siteName,
      readingMode: _selectedReadingMode.name,
      status: _isReading ? 'reading' : 'idle',
      lastUpdated: DateTime.now(),
      createdAt: DateTime.now(),
      totalMeters: _meters.length,
      readCount: _meters.values
          .where((m) => m.overallStatus == MeterStatus.success)
          .length,
    );
    _firebaseService.updateSiteData(siteId, data).catchError((e) {
      if (kDebugMode) debugPrint("Firebase sync error: $e");
    });
  }

  void setBaudRate(int value) {
    _baudRate = value;
    notifyListeners();
  }

  void setSelectedCommand(MBusCommandOption cmd) {
    _selectedCommand = cmd;
    notifyListeners();
  }

  void setHeatSecondaryIds(String value) {
    _heatSecondaryIds = value;
    notifyListeners();
  }

  void setWaterSecondaryIds(String value) {
    _waterSecondaryIds = value;
    notifyListeners();
  }

  void setDaireIds(String value) {
    _daireIds = value;
    notifyListeners();
  }

  void setPrimaryStart(int value) {
    _primaryStart = value;
    notifyListeners();
  }

  void setPrimaryEnd(int value) {
    _primaryEnd = value;
    notifyListeners();
  }

  void setReadingMode(ReadingMode value) {
    _selectedReadingMode = value;
    _updateFirebaseSiteData();
    notifyListeners();
  }

  void pauseReading() {
    if (!_isReading || _isStopped) return;
    _isPaused = true;
    _pauseCompleter = Completer<void>();
    _addLog('⏸️ Okuma duraklatıldı.');
    notifyListeners();
  }

  void resumeReading() {
    if (!_isPaused || _isStopped) return;
    _isPaused = false;
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    _addLog('▶️ Okuma devam ediyor.');
    notifyListeners();
  }

  void stopReading() {
    if (!_isReading) return;
    _isStopped = true;
    _isPaused = false;
    if (_pauseCompleter != null && !_pauseCompleter!.isCompleted) {
      _pauseCompleter!.complete();
    }
    if (_e5Completer != null && !_e5Completer!.isCompleted) {
      _e5Completer!.complete(false);
    }
    if (_readCompleter != null && !_readCompleter!.isCompleted) {
      _readCompleter!.complete(false);
    }
    _addLog('⏹️ Okuma sonlandırılıyor...');
    notifyListeners();
  }

  Future<void> scanDevices() async {
    try {
      _devices = await _service.listDevices();
      if (_devices.isNotEmpty && _selectedDevice == null) {
        _selectedDevice = _devices.first;
      }
      notifyListeners();
    } catch (e) {
      _addLog('⚠️ Cihaz tarama hatası: $e');
    }
  }

  void selectDevice(dynamic device) {
    _selectedDevice = device;
    notifyListeners();
  }

  Future<void> connect() async {
    if (_selectedDevice == null) {
      _addLog('⚠️ Lütfen önce bir cihaz seçin.');
      return;
    }

    _setStatus(ConnectionStatus.connecting);
    _addLog(
      '🔌 Bağlanılıyor: ${_selectedDevice!.productName ?? _selectedDevice!.deviceName}...',
    );

    try {
      final success = await _service.connect(
        _selectedDevice!,
        baudRate: _baudRate,
      );
      if (success) {
        _setStatus(ConnectionStatus.connected);
        _addLog('✅ Bağlantı kuruldu. ($_baudRate/8/E/1)');
        _startListening();
      } else {
        _setStatus(ConnectionStatus.error);
        _addLog('❌ Bağlantı kurulamadı.');
      }
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      _addLog('❌ Hata: $e');
    }
  }

  Future<void> disconnect() async {
    _bufferTimer?.cancel();
    _rxBuffer.clear();
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _service.disconnect();
    _setStatus(ConnectionStatus.disconnected);
    _addLog('🔴 Bağlantı kesildi.');
  }

  Future<void> readMeters() async {
    if (!isConnected) {
      _addLog('⚠️ Cihaz bağlı değil!');
      return;
    }

    if (_selectedCommand.label == 'İkincil Adres (Seri No ile)') {
      final heatTargets = _heatSecondaryIds
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .toList();
      final waterTargets = _waterSecondaryIds
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .toList();
      final daireTargets = _daireIds
          .split(RegExp(r'\r?\n'))
          .map((e) => e.trim())
          .toList();

      final maxLines = [
        heatTargets.length,
        waterTargets.length,
        daireTargets.length,
      ].reduce((a, b) => a > b ? a : b);

      if (maxLines == 0 ||
          (heatTargets.where((e) => e.isNotEmpty).isEmpty &&
              waterTargets.where((e) => e.isNotEmpty).isEmpty)) {
        _addLog('⚠️ Liste boş. Lütfen seri numarası girin.');
        return;
      }

      _expectedDaireNo.clear();
      _isPaused = false;
      _isStopped = false;
      _isReading = true;
      _rxBuffer.clear();
      _timeoutTimer?.cancel();
      // Reset statuses instead of completely wiping metadata like adSoyad
      for (var meter in _meters.values) {
        meter.heatStatus = MeterStatus.pending;
        meter.waterStatus = MeterStatus.pending;
        meter.overallStatus = MeterStatus.pending;
        meter.heatIndex = '';
        meter.waterIndex = '';
      }
      _activeIndex = -1;
      notifyListeners();

      try {
        int readCount = 0;
        final totalMeters =
            heatTargets.where((e) => e.isNotEmpty).length +
            waterTargets.where((e) => e.isNotEmpty).length;

        for (int i = 0; i < maxLines; i++) {
          if (_isStopped) break;

          if (_isPaused) {
            _readingStatus = 'Duraklatıldı...';
            notifyListeners();
            await _pauseCompleter?.future;
            if (_isStopped) break;
          }

          dynamic daire;
          if (i < daireTargets.length && daireTargets[i].isNotEmpty) {
            daire = int.tryParse(daireTargets[i]) ?? daireTargets[i];
          } else {
            daire = i + 1;
          }

          if (_selectedReadingMode == ReadingMode.heat ||
              _selectedReadingMode == ReadingMode.both) {
            String targetSerial = i < heatTargets.length
                ? heatTargets[i].trim()
                : '';

            if (targetSerial.isNotEmpty) {
              _activeIndex = i;
              _currentReadingFlat = daire.toString();
              targetSerial = targetSerial.padLeft(8, '0');
              _expectedDaireNo[targetSerial] = daire;

              readCount++;
              _readingStatus =
                  'Okunuyor (Isı): $targetSerial... ($readCount/$totalMeters)';
              _selectedMeterType = MeterType.heat;
              notifyListeners();

              bool success = await _readSingleSecondary(targetSerial);
              if (!success) {
                _handleFailedRead(
                  daire.toString(),
                  targetSerial,
                  MeterType.heat,
                  i < waterTargets.length ? waterTargets[i] : '',
                );
                _playSound('error');
              } else {
                _playSound('success');
              }
              saveSession();
              if (_isStopped) break;
              if (readCount < totalMeters) {
                await Future.delayed(const Duration(milliseconds: 300));
              }
            } else if (i < heatTargets.length) {
              _handleFailedRead(
                daire.toString(),
                '',
                MeterType.heat,
                i < waterTargets.length ? waterTargets[i] : '',
              );
              _addLog(
                '⚠️ Daire $daire: Isı sayacı seri no boş, okuma atlandı.',
              );
              saveSession();
            }
          }

          if (_isStopped) break;

          if (_isPaused) {
            _readingStatus = 'Duraklatıldı...';
            notifyListeners();
            await _pauseCompleter?.future;
            if (_isStopped) break;
          }

          if (_selectedReadingMode == ReadingMode.water ||
              _selectedReadingMode == ReadingMode.both) {
            String targetSerial = i < waterTargets.length
                ? waterTargets[i].trim()
                : '';

            if (targetSerial.isNotEmpty) {
              _activeIndex = i;
              _currentReadingFlat = daire.toString();
              targetSerial = targetSerial.padLeft(8, '0');
              _expectedDaireNo[targetSerial] = daire;

              readCount++;
              _readingStatus =
                  'Okunuyor (Su): $targetSerial... ($readCount/$totalMeters)';
              _selectedMeterType = MeterType.water;
              notifyListeners();

              bool success = await _readSingleSecondary(targetSerial);
              if (!success) {
                _handleFailedRead(
                  daire.toString(),
                  targetSerial,
                  MeterType.water,
                  i < heatTargets.length ? heatTargets[i] : '',
                );
                _playSound('error');
              } else {
                _playSound('success');
              }
              saveSession();
              if (readCount < totalMeters) {
                await Future.delayed(const Duration(milliseconds: 300));
              }
            } else if (i < waterTargets.length) {
              _handleFailedRead(
                daire.toString(),
                '',
                MeterType.water,
                i < heatTargets.length ? heatTargets[i] : '',
              );
              _addLog('⚠️ Daire $daire: Su sayacı seri no boş, okuma atlandı.');
              saveSession();
            }
          }
          if (_isStopped) break;
        }
      } catch (e) {
        _addLog('❌ Toplu okuma hatası: $e');
      } finally {
        if (!_isStopped) {
          _playSound('complete');
        }
        _isReading = false;
        _isPaused = false;
        _isStopped = false;
        _activeIndex = -1;
        _readingStatus = 'Okuma Tamamlandı';
        _currentReadingFlat = '';
        saveSession(immediate: true);
        notifyListeners();
      }
      return;
    }

    if (_selectedCommand.label == 'Birincil Adres ile Tara (0-250)') {
      _isReading = true;
      _rxBuffer.clear();
      _timeoutTimer?.cancel();
      _meters.clear();
      notifyListeners();

      try {
        final total = _primaryEnd - _primaryStart + 1;
        int currentCount = 1;
        for (int addr = _primaryStart; addr <= _primaryEnd; addr++) {
          _readingStatus = 'Okunuyor: Adres $addr... ($currentCount/$total)';
          notifyListeners();

          await _readSinglePrimary(addr);

          if (addr < _primaryEnd) {
            _addLog('⏳ Diğer sayaca geçiliyor (Sakinleşme: 300ms)...');
            await Future.delayed(const Duration(milliseconds: 300));
          }
          currentCount++;
        }
      } catch (e) {
        _addLog('❌ Toplu okuma hatası: $e');
      } finally {
        _isReading = false;
        _readingStatus = 'Okuma Tamamlandı';
        saveSession(immediate: true);
        notifyListeners();
      }
      return;
    }

    _isReading = true;
    _rxBuffer.clear();
    _timeoutTimer?.cancel();
    notifyListeners();

    try {
      final cmdStr = _toHexString(Uint8List.fromList(_selectedCommand.command));
      _addLog('📤 Gönderiliyor (${_selectedCommand.label}): $cmdStr');
      await _service.write(Uint8List.fromList(_selectedCommand.command));

      _timeoutTimer = Timer(const Duration(seconds: 2), () {
        if (_isReading) {
          _isReading = false;
          _addLog('⏳ Zaman Aşımı: Sayaç cevap vermedi veya eksik veri geldi');
          notifyListeners();
        }
      });
    } catch (e) {
      _addLog('❌ Gönderme hatası: $e');
      _isReading = false;
      notifyListeners();
    }
  }

  Future<void> retryFailedMeters() async {
    if (!isConnected) {
      _addLog('⚠️ Cihaz bağlı değil!');
      return;
    }

    final failedMeters = _meters.values
        .where((m) => m.overallStatus == MeterStatus.failed)
        .toList();
    if (failedMeters.isEmpty) {
      _addLog('⚠️ Okunamayan sayaç bulunamadı.');
      return;
    }

    _isPaused = false;
    _isStopped = false;
    _isReading = true;
    _rxBuffer.clear();
    _activeIndex = -1;
    _timeoutTimer?.cancel();
    notifyListeners();

    try {
      int readCount = 0;
      final totalMeters = failedMeters.length;

      for (var failedMeter in failedMeters) {
        if (_isStopped) break;

        if (_isPaused) {
          _readingStatus = 'Duraklatıldı...';
          notifyListeners();
          await _pauseCompleter?.future;
          if (_isStopped) break;
        }

        readCount++;

        if ((_selectedReadingMode == ReadingMode.heat ||
                _selectedReadingMode == ReadingMode.both) &&
            failedMeter.heatMeterId.isNotEmpty) {
          _activeIndex = _meters.values.toList().indexOf(failedMeter);
          _readingStatus =
              'Tekrar Okunuyor (Isı): ${failedMeter.heatMeterId}... ($readCount/$totalMeters)';
          _selectedMeterType = MeterType.heat;
          notifyListeners();
          await _readSingleSecondary(failedMeter.heatMeterId);
        }

        if ((_selectedReadingMode == ReadingMode.water ||
                _selectedReadingMode == ReadingMode.both) &&
            failedMeter.waterMeterId.isNotEmpty) {
          _readingStatus =
              'Tekrar Okunuyor (Su): ${failedMeter.waterMeterId}... ($readCount/$totalMeters)';
          _selectedMeterType = MeterType.water;
          notifyListeners();
          await _readSingleSecondary(failedMeter.waterMeterId);
        }

        if (readCount < totalMeters) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } catch (e) {
      _addLog('❌ Tekrar okuma hatası: $e');
    } finally {
      if (!_isStopped) {
        _playSound('complete');
      }
      _isReading = false;
      _isPaused = false;
      _isStopped = false;
      _readingStatus = 'Tekrar Okuma Tamamlandı';
      saveSession(immediate: true);
      notifyListeners();
    }
  }

  Future<bool> importFromExcel() async {
    try {
      final Uint8List? bytes = await ExcelService.pickAndReadExcel();

      if (bytes != null) {
        final parsedMeters = await compute(ExcelService.parseExcel, bytes);

        _daireIds = parsedMeters.map((m) => m.flatNo).join("\n");
        _heatSecondaryIds = parsedMeters.map((m) => m.heatMeterId).join("\n");
        _waterSecondaryIds = parsedMeters.map((m) => m.waterMeterId).join("\n");

        _meters.clear();
        for (var meter in parsedMeters) {
          _meters[meter.flatNo] = meter;
        }

        _addLog("✅ Excel'den ${parsedMeters.length} daire içe aktarıldı.");
        saveSession(immediate: true);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _addLog('❌ Excel içe aktarma hatası: $e');
      return false;
    }
  }

  Future<bool> _readSingleSecondary(String targetSerial) async {
    _rxBuffer.clear();
    _readCompleter = Completer<bool>();
    if (_e5Completer != null && !_e5Completer!.isCompleted) {
      _e5Completer!.completeError("cancelled");
    }
    _e5Completer = null;
    _timeoutTimer?.cancel();

    try {
      final b1 = int.parse(targetSerial.substring(6, 8), radix: 16);
      final b2 = int.parse(targetSerial.substring(4, 6), radix: 16);
      final b3 = int.parse(targetSerial.substring(2, 4), radix: 16);
      final b4 = int.parse(targetSerial.substring(0, 2), radix: 16);

      final wakeupCmd = [0x10, 0x40, 0xFE, 0x3E, 0x16];
      _addLog('📤 UYANDIRMA: 10 40 FE 3E 16');
      await _service.write(Uint8List.fromList(wakeupCmd));
      _addLog('Ping gönderildi, 1sn bekleniyor');
      await Future.delayed(const Duration(milliseconds: 1000));

      final resetCmd = [0x10, 0x40, 0xFD, 0x3D, 0x16];
      _addLog('📤 SIFIRLAMA: 10 40 FD 3D 16');
      await _service.write(Uint8List.fromList(resetCmd));
      await Future.delayed(const Duration(milliseconds: 600));

      final baseFrame = [
        0x68,
        0x0B,
        0x0B,
        0x68,
        0x53,
        0xFD,
        0x52,
        b1,
        b2,
        b3,
        b4,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
      ];
      int cs = 0;
      for (int i = 4; i < baseFrame.length; i++) {
        cs = (cs + baseFrame[i]) % 256;
      }
      final selectionFrame = [...baseFrame, cs, 0x16];

      _addLog(
        '📤 Seçim Çerçevesi ($targetSerial): ${_toHexString(Uint8List.fromList(selectionFrame))}',
      );
      await _service.write(Uint8List.fromList(selectionFrame));

      bool e5Received = false;
      _e5Completer = Completer<bool>();
      try {
        e5Received = await _e5Completer!.future.timeout(
          const Duration(milliseconds: 500),
        );
      } catch (e) {
        e5Received = false;
      }

      if (!e5Received) {
        _addLog(
          '⏳ E5 alınamadı, sayaç derin uykuda olabilir. 500ms bekleniyor...',
        );
        await Future.delayed(const Duration(milliseconds: 500));

        _addLog('📤 Seçim Çerçevesi İkinci Kez Gönderiliyor ($targetSerial)');
        await _service.write(Uint8List.fromList(selectionFrame));

        _e5Completer = Completer<bool>();
        try {
          e5Received = await _e5Completer!.future.timeout(
            const Duration(milliseconds: 500),
          );
        } catch (e) {
          e5Received = false;
        }
      }

      if (e5Received) {
        _addLog('✅ E5 Alındı. 400ms beklenip okuma komutu gönderilecek.');
      } else {
        _addLog(
          '❌ İkinci denemede de E5 alınamadı! (Kör Okuma Aktif - Zorla 7B gönderiliyor...)',
        );
      }

      await Future.delayed(const Duration(milliseconds: 400));

      final readCmd7B = [0x10, 0x7B, 0xFD, 0x78, 0x16];
      _addLog(
        '📤 Okuma Komutu (FD - 7B): ${_toHexString(Uint8List.fromList(readCmd7B))}',
      );
      await _service.write(Uint8List.fromList(readCmd7B));

      _timeoutTimer = Timer(const Duration(seconds: 2), () async {
        if (!_readCompleter!.isCompleted) {
          _addLog('⏳ 7B Komutuna cevap yok, 5B ile tekrar deneniyor...');
          final readCmd5B = [0x10, 0x5B, 0xFD, 0x58, 0x16];
          _addLog(
            '📤 Okuma Komutu (FD - 5B): ${_toHexString(Uint8List.fromList(readCmd5B))}',
          );
          await _service.write(Uint8List.fromList(readCmd5B));

          _timeoutTimer = Timer(const Duration(seconds: 2), () {
            if (!_readCompleter!.isCompleted) {
              _addLog('❌ Zaman Aşımı: $targetSerial cevap vermedi (Retry)');
              _readCompleter!.complete(false);
            }
          });
        }
      });

      return await _readCompleter!.future;
    } catch (e) {
      _addLog('❌ Hata ($targetSerial): $e');
      if (!_readCompleter!.isCompleted) {
        _readCompleter!.complete(false);
      }
      return false;
    }
  }

  Future<bool> _readSinglePrimary(int addr) async {
    _rxBuffer.clear();
    _readCompleter = Completer<bool>();
    _timeoutTimer?.cancel();

    try {
      final resetCmd = [0x10, 0x40, addr, 0x00, 0x16];
      resetCmd[3] = (0x40 + addr) % 256;
      _addLog(
        '📤 Sıfırlama (Reset) Adres $addr: ${_toHexString(Uint8List.fromList(resetCmd))}',
      );
      await _service.write(Uint8List.fromList(resetCmd));
      await Future.delayed(const Duration(milliseconds: 150));

      final readCmd7B = [0x10, 0x7B, addr, 0x00, 0x16];
      readCmd7B[3] = (0x7B + addr) % 256;
      _addLog(
        '📤 Okuma Komutu ($addr - 7B): ${_toHexString(Uint8List.fromList(readCmd7B))}',
      );
      await _service.write(Uint8List.fromList(readCmd7B));

      _timeoutTimer = Timer(const Duration(seconds: 2), () async {
        if (!_readCompleter!.isCompleted) {
          _addLog('⏳ 7B Komutuna cevap yok, 5B ile tekrar deneniyor...');
          final readCmd5B = [0x10, 0x5B, addr, 0x00, 0x16];
          readCmd5B[3] = (0x5B + addr) % 256;
          _addLog(
            '📤 Okuma Komutu ($addr - 5B): ${_toHexString(Uint8List.fromList(readCmd5B))}',
          );
          await _service.write(Uint8List.fromList(readCmd5B));

          _timeoutTimer = Timer(const Duration(seconds: 2), () {
            if (!_readCompleter!.isCompleted) {
              _addLog('❌ Zaman Aşımı: Adres $addr cevap vermedi (Retry)');
              _readCompleter!.complete(false);
            }
          });
        }
      });

      return await _readCompleter!.future;
    } catch (e) {
      _addLog('❌ Hata (Adres $addr): $e');
      if (!_readCompleter!.isCompleted) {
        _readCompleter!.complete(false);
      }
      return false;
    }
  }

  void clearMeters() {
    _meters.clear();
    clearSessionData();
    notifyListeners();
  }

  void addManualMeter({
    required String daireNo,
    required String heatMeterId,
    required String waterMeterId,
    String heatIndex = '0',
    String waterIndex = '0',
  }) {
    final key = daireNo.trim();
    if (key.isEmpty) return;

    _meters[key] = MeterData(
      flatNo: key,
      heatMeterId: heatMeterId.trim(),
      heatIndex: heatIndex.trim(),
      heatStatus: MeterStatus.success,
      waterMeterId: waterMeterId.trim(),
      waterIndex: waterIndex.trim(),
      waterStatus: MeterStatus.success,
      overallStatus: MeterStatus.success,
      type: MeterType.heat,
      readTime: DateTime.now(),
    );
    saveSession();
    if (!kIsWeb) {
      _firebaseService.updateMeterData(siteId, key, _meters[key]!).catchError((
        e,
      ) {
        if (kDebugMode) debugPrint("Firebase sync error: $e");
      });
    }
    notifyListeners();
  }

  void _startListening() {
    _dataSubscription = _service.dataStream.listen(
      (Uint8List data) {
        _rxBuffer.addAll(data);
        _processBuffer();
      },
      onError: (e) {
        _addLog('❌ Veri hatası: $e');
        _isReading = false;
        notifyListeners();
      },
    );
  }

  void _processBuffer() {
    bool hasChanges = false;

    while (_rxBuffer.isNotEmpty) {
      if (_rxBuffer[0] != 0x68) {
        if (_rxBuffer[0] == 0xE5) {
          _addLog('📥 Tam Paket: E5');
          if (_e5Completer != null && !_e5Completer!.isCompleted) {
            _e5Completer!.complete(true);
          }
        }
        _rxBuffer.removeAt(0);
        continue;
      }

      if (_rxBuffer.length < 4) {
        break;
      }

      final l1 = _rxBuffer[1];
      final l2 = _rxBuffer[2];

      if (l1 != l2 || _rxBuffer[3] != 0x68) {
        _addLog(
          '⚠️ Hatalı Başlangıç Çerçevesi (l1 != l2 veya eksik 0x68). Kaydırılıyor...',
        );
        _rxBuffer.removeAt(0);
        continue;
      }

      final totalLength = l1 + 6;

      if (_rxBuffer.length >= totalLength) {
        if (_rxBuffer[totalLength - 1] == 0x16) {
          int cs = 0;
          for (int i = 4; i < totalLength - 2; i++) {
            cs = (cs + _rxBuffer[i]) % 256;
          }

          if (cs == _rxBuffer[totalLength - 2]) {
            final frameBytes = Uint8List.fromList(
              _rxBuffer.sublist(0, totalLength),
            );
            _addLog('📥 Tam Paket (CRC OK): ${_toHexString(frameBytes)}');

            try {
              final meterData = MBusParser.parseData(
                frameBytes,
                isWaterMeter: _selectedMeterType == MeterType.water,
              );
              if (meterData != null) {
                final flatNo =
                    _expectedDaireNo[meterData.meterId]?.toString() ?? '';

                if (_meters.containsKey(flatNo)) {
                  final existing = _meters[flatNo]!;
                  if (_selectedMeterType == MeterType.heat) {
                    existing.heatIndex = _formatHeatIndex(meterData.energy);
                    existing.heatMeterId = meterData.meterId;
                    existing.heatStatus = MeterStatus.success;
                  } else {
                    existing.waterIndex = _formatWaterIndex(meterData.volume);
                    existing.waterMeterId = meterData.meterId;
                    existing.waterStatus = MeterStatus.success;
                  }

                  if (existing.heatStatus == MeterStatus.success &&
                      existing.waterStatus == MeterStatus.success) {
                    existing.overallStatus = MeterStatus.success;
                  } else if (existing.heatStatus == MeterStatus.failed ||
                      existing.waterStatus == MeterStatus.failed) {
                    existing.overallStatus = MeterStatus.failed;
                  }

                  existing.readTime = DateTime.now();
                } else {
                  _meters[flatNo] = MeterData(
                    flatNo: flatNo,
                    heatMeterId: _selectedMeterType == MeterType.heat
                        ? meterData.meterId
                        : '',
                    heatIndex: _selectedMeterType == MeterType.heat
                        ? _formatHeatIndex(meterData.energy)
                        : '0.0',
                    heatStatus: _selectedMeterType == MeterType.heat
                        ? MeterStatus.success
                        : MeterStatus.pending,
                    waterMeterId: _selectedMeterType == MeterType.water
                        ? meterData.meterId
                        : '',
                    waterIndex: _selectedMeterType == MeterType.water
                        ? _formatWaterIndex(meterData.volume)
                        : '0.0',
                    waterStatus: _selectedMeterType == MeterType.water
                        ? MeterStatus.success
                        : MeterStatus.pending,
                    overallStatus: MeterStatus.pending,
                    type: _selectedMeterType,
                    readTime: DateTime.now(),
                  );
                }

                if (!kIsWeb) {
                  _firebaseService
                      .updateMeterData(siteId, flatNo, _meters[flatNo]!)
                      .catchError((e) {
                        if (kDebugMode) debugPrint("Firebase sync error: $e");
                      });
                }

                _addLog('🔍 Sayaç parse edildi → ID: ${meterData.meterId}');
                hasChanges = true;

                if (_readCompleter != null && !_readCompleter!.isCompleted) {
                  _readCompleter!.complete(true);
                }
              }
            } catch (e) {
              _addLog('❌ Parse hatası: $e');
            }
          } else {
            _addLog(
              '⚠️ CRC Hatalı (Beklenen: 0x${cs.toRadixString(16).padLeft(2, '0').toUpperCase()}, Gelen: 0x${_rxBuffer[totalLength - 2].toRadixString(16).padLeft(2, '0').toUpperCase()}). Kaydırılıyor...',
            );
            _rxBuffer.removeAt(0);
            continue;
          }
        } else {
          _addLog(
            '⚠️ Hatalı Çerçeve Bitişi: 0x${_rxBuffer[totalLength - 1].toRadixString(16).padLeft(2, '0').toUpperCase()}. Kaydırılıyor...',
          );
          _rxBuffer.removeAt(0);
          continue;
        }

        _rxBuffer.removeRange(0, totalLength);

        if (hasChanges && _isReading) {
          _timeoutTimer?.cancel();
          _isReading = false;
        }
      } else {
        break;
      }
    }

    if (hasChanges) {
      saveSession();
      notifyListeners();
    }
  }

  String _formatHeatIndex(double val) {
    if (val == 0) return "0";

    double energy = val;
    if (val > 100000) {
      energy = val / 1000;
    }

    if (energy == energy.toInt()) {
      return energy.toInt().toString();
    }
    return energy.toString();
  }

  String _formatWaterIndex(double val) {
    String str = val.toStringAsFixed(3);
    if (str.contains('.')) {
      str = str.replaceAll(RegExp(r'0*$'), '');
      str = str.replaceAll(RegExp(r'\.$'), '');
    }
    return str;
  }

  static String _serializeSession(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  Future<void> saveSession({bool immediate = false}) async {
    if (immediate) {
      _saveTimer?.cancel();
      await _performSave();
      return;
    }

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      await _performSave();
    });
  }

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _getPrefs async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> _performSave() async {
    try {
      final secureStorage = const FlutterSecureStorage();
      
      final List<Map<String, dynamic>> metersJson = _meters.values
          .map((m) => m.toJson())
          .toList();

      final sessionData = {
        'siteName': _siteName,
        'daireIds': _daireIds,
        'heatSecondaryIds': _heatSecondaryIds,
        'waterSecondaryIds': _waterSecondaryIds,
        'meters': metersJson,
        'readingMode': _selectedReadingMode.name,
      };

      final String encodedData = await compute(_serializeSession, sessionData);
      await secureStorage.write(key: 'sayac_pro_session', value: encodedData);
      
      if (kDebugMode) {
        debugPrint('💾 Oturum kaydedildi.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Oturum kaydedilemedi: $e');
      }
    }
  }

  Future<void> loadSession() async {
    try {
      final secureStorage = const FlutterSecureStorage();
      String? sessionJson = await secureStorage.read(key: 'sayac_pro_session');
      if (sessionJson == null) {
        final prefs = await SharedPreferences.getInstance();
        sessionJson = prefs.getString('sayac_pro_session');
        if (sessionJson != null) {
          await secureStorage.write(key: 'sayac_pro_session', value: sessionJson);
          await prefs.remove('sayac_pro_session');
        }
      }
      
      if (sessionJson == null) return;

      final Map<String, dynamic> sessionData = jsonDecode(sessionJson);

      _siteName = sessionData['siteName'] ?? '';
      _daireIds = sessionData['daireIds'] ?? '';
      _heatSecondaryIds = sessionData['heatSecondaryIds'] ?? '';
      _waterSecondaryIds = sessionData['waterSecondaryIds'] ?? '';

      if (sessionData['readingMode'] != null) {
        _selectedReadingMode = ReadingMode.values.byName(
          sessionData['readingMode'],
        );
      }

      if (sessionData['meters'] != null) {
        final List<dynamic> metersList = sessionData['meters'];
        for (var mJson in metersList) {
          final meter = MeterData.fromJson(mJson as Map<String, dynamic>);
          _meters[meter.flatNo] = meter;
        }
      }

      _addLog('📂 Eski oturum geri yüklendi.');
      notifyListeners();
    } catch (e) {
      _addLog('⚠️ Oturum yüklenirken hata: $e');
    }
  }

  Future<void> clearSessionData() async {
    try {
      final secureStorage = const FlutterSecureStorage();
      await secureStorage.delete(key: 'sayac_pro_session');
      _addLog('🗑️ Oturum verileri temizlendi.');
    } catch (e) {
      _addLog('⚠️ Oturum verileri temizlenemedi: $e');
    }
  }

  void _handleFailedRead(
    String flatNo,
    String currentSerial,
    MeterType type,
    String otherSerial,
  ) {
    if (!_meters.containsKey(flatNo)) {
      _meters[flatNo] = MeterData(
        flatNo: flatNo,
        heatMeterId: type == MeterType.heat ? currentSerial : otherSerial,
        heatIndex: '0.0',
        heatStatus: type == MeterType.heat
            ? MeterStatus.failed
            : MeterStatus.pending,
        waterMeterId: type == MeterType.water ? currentSerial : otherSerial,
        waterIndex: '0.0',
        waterStatus: type == MeterType.water
            ? MeterStatus.failed
            : MeterStatus.pending,
        overallStatus: MeterStatus.failed,
        type: type,
        readTime: DateTime.now(),
      );
    } else {
      final meter = _meters[flatNo]!;
      if (type == MeterType.heat) {
        meter.heatStatus = MeterStatus.failed;
        meter.heatMeterId = currentSerial;
      } else {
        meter.waterStatus = MeterStatus.failed;
        meter.waterMeterId = currentSerial;
      }
      meter.overallStatus = MeterStatus.failed;
      meter.readTime = DateTime.now();
    }

    if (!kIsWeb) {
      _firebaseService
          .updateMeterData(siteId, flatNo, _meters[flatNo]!)
          .catchError((e) {
            if (kDebugMode) debugPrint("Firebase sync error: $e");
          });
    }
    notifyListeners();
  }

  String _toHexString(Uint8List bytes) {
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  void _addLog(String line) {
    _logLines.add(line);
    notifyListeners();
  }

  void clearLog() {
    _logLines.clear();
    notifyListeners();
  }

  void _setStatus(ConnectionStatus s) {
    _status = s;
    notifyListeners();
  }

  void dispose() {
    _audioPlayer.dispose();
    _timeoutTimer?.cancel();
    _bufferTimer?.cancel();
    _saveTimer?.cancel();
    _dataSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
