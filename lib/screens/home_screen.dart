import 'dart:io';
import 'package:flutter/foundation.dart';
import 'widgets/meter_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as excel_pkg;
import '../providers/device_provider.dart';
import '../providers/theme_provider.dart';
import 'widgets/section_header.dart';
import 'widgets/connection_card.dart';
import 'widgets/log_console_sheet.dart';
import '../theme/app_theme.dart';
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAutoScrollPaused = false;
  final ScrollController _logScrollController = ScrollController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _inputListScrollController = ScrollController();
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _daireController = TextEditingController();
  final TextEditingController _heatController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DeviceProvider>();
      provider.scanDevices();

      // activeIndex değişimini dinle
      provider.addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    final provider = context.read<DeviceProvider>();
    if (!provider.isReading) {
      if (_isAutoScrollPaused) {
        setState(() {
          _isAutoScrollPaused = false;
        });
      }
      return;
    }
    if (provider.activeIndex != -1) {
      if (!_isAutoScrollPaused) {
        _scrollToIndex(provider.activeIndex);
      }
      
      // Veri girişi tablosundaki listeyi otomatik kaydır
      if (_inputListScrollController.hasClients && !_isInputScrolling) {
        _isInputScrolling = true;
        _inputListScrollController.animateTo(
          provider.activeIndex * 48.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) {
          _isInputScrolling = false;
        });
      }
    }
  }

  bool _isInputScrolling = false;

  @override
  void dispose() {
    context.read<DeviceProvider>().removeListener(_onProviderChange);
    _logScrollController.dispose();
    _scrollController.dispose();
    _inputListScrollController.dispose();
    _siteNameController.dispose();
    _daireController.dispose();
    _heatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Controller senkronizasyonu için dinlemeyen bir provider alalım
    final provider = context.read<DeviceProvider>();

    // Controller'ları provider ile senkronize et (sadece build sırasında)
    if (_siteNameController.text != provider.siteName) {
      _siteNameController.text = provider.siteName;
    }
    if (_daireController.text != provider.daireIds) {
      _daireController.text = provider.daireIds;
    }
    if (_heatController.text != provider.heatSecondaryIds) {
      _heatController.text = provider.heatSecondaryIds;
    }
    if (_waterController.text != provider.waterSecondaryIds) {
      _waterController.text = provider.waterSecondaryIds;
    }

    // Provider'ı dinlemek için Consumer kullanmıyoruz çünkü CustomScrollView içindeki sliver'lar
    // Selector ile kendi parçalarını dinliyor. Ancak ana controller'ların güncellenmesi için
    // provider'daki değişiklikleri takip etmeliyiz. (Artık context.watch yok)

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is UserScrollNotification) {
                  if (notification.direction != ScrollDirection.idle) {
                    final provider = context.read<DeviceProvider>();
                    if (provider.isReading && !_isAutoScrollPaused) {
                      setState(() {
                        _isAutoScrollPaused = true;
                      });
                    }
                  }
                }
                return false;
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                // ── Bölüm 1: Bağlantı & Ayarlar ──
                const SliverToBoxAdapter(
                  child: SectionHeader(
                    icon: Icons.settings_input_hdmi,
                    title: 'BAĞLANTI & AYARLAR',
                  ),
                ),
                SliverToBoxAdapter(child: ConnectionCard(provider: provider)),

                // ── Bölüm 2: Veri Girişi & İşlem ──
                Selector<DeviceProvider, String>(
                  selector: (_, p) => p.selectedCommand.label,
                  builder: (context, label, _) {
                    if (label == 'İkincil Adres (Seri No ile)') {
                      return SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SectionHeader(
                              icon: Icons.edit_note,
                              title: 'VERİ GİRİŞİ & İŞLEM',
                              iconColor: AppTheme.purple,
                            ),
                            _buildInputSection(),
                          ],
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                // ── Sayaçları Oku Butonu ──
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: _buildReadButton()),

                // Bölüm 3: Sonuç Listesi
                Selector<DeviceProvider, bool>(
                  selector: (_, p) => p.meterList.isNotEmpty,
                  builder: (context, hasMeters, _) {
                    if (hasMeters) {
                      return SliverMainAxisGroup(
                        slivers: [
                          const SliverToBoxAdapter(
                            child: SectionHeader(
                              icon: Icons.analytics,
                              title: 'SONUÇLAR',
                              iconColor: AppTheme.success,
                            ),
                          ),
                          SliverToBoxAdapter(child: _buildResultHeader()),
                          _buildMetersSliverList(),
                          _buildRetryButtonSliver(),
                        ],
                      );
                    }
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  },
                ),

                // Alt boşluk
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
            ),
          ),
        ),
      ),

      // ── FAB: Yeni Sayaç Ekle & Sonuçları Paylaş ──
      floatingActionButton: Selector<DeviceProvider, bool>(
        selector: (_, p) => p.isReading,
        builder: (context, isReading, _) {
          if (isReading) {
            if (_isAutoScrollPaused) {
              return FloatingActionButton(
                heroTag: 'resume_scroll_btn',
                mini: true,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _isAutoScrollPaused = false;
                  });
                  final provider = context.read<DeviceProvider>();
                  if (provider.activeIndex != -1) {
                    _scrollToIndex(provider.activeIndex);
                  }
                },
              );
            }
            return const SizedBox.shrink();
          }

          return Selector<DeviceProvider, bool>(
            selector: (_, p) => p.meterList.isNotEmpty,
            builder: (context, hasMeters, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'add_manual_btn',
                      onPressed: () => _showAddManualMeterDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Sayaç Ekle'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    if (hasMeters) ...[
                      const SizedBox(width: 16),
                      FloatingActionButton.extended(
                        heroTag: 'export_btn',
                        onPressed: () => _showExportOptionsDialog(context, provider),
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Sonuçları Paylaş'),
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: provider.isReading
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerFloat,

      // ── Bottom Navigation Bar: Okuma Yapılırken Altta Sabit Butonlar (Locked) ──
      bottomNavigationBar: Selector<DeviceProvider, (bool, bool, String)>(
        selector: (_, p) => (p.isReading, p.isPaused, p.readingStatus),
        builder: (context, data, _) {
          final isReading = data.$1;
          final isPaused = data.$2;
          final readingStatus = data.$3;

          if (!isReading) return const SizedBox.shrink();

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    readingStatus.isNotEmpty ? readingStatus : 'Okunuyor...',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final provider = context.read<DeviceProvider>();
                            if (isPaused) {
                              provider.resumeReading();
                            } else {
                              provider.pauseReading();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused
                                ? AppTheme.success
                                : AppTheme.warning,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            color: Colors.white,
                          ),
                          label: Text(
                            isPaused ? 'Devam Et' : 'Duraklat',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<DeviceProvider>().stopReading();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text(
                            'Durdur',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Selector<DeviceProvider, ConnectionStatus>(
            selector: (_, p) => p.status,
            builder: (context, status, _) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor(status),
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor(status).withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          const Text('SayacPro'),
        ],
      ),
      actions: [
        // Tema Değiştirme Butonu
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 22,
              ),
              tooltip: themeProvider.isDarkMode
                  ? 'Açık Temaya Geç'
                  : 'Koyu Temaya Geç',
              onPressed: () => themeProvider.toggleTheme(),
            );
          },
        ),
        // Ses butonu
        Selector<DeviceProvider, bool>(
          selector: (_, p) => p.isSoundEnabled,
          builder: (context, isEnabled, _) {
            final colorScheme = Theme.of(context).colorScheme;
            return IconButton(
              icon: Icon(
                isEnabled ? Icons.volume_up : Icons.volume_off,
                color: isEnabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.38),
                size: 22,
              ),
              tooltip: isEnabled ? 'Sesi Kapat' : 'Sesi Aç',
              onPressed: () => context.read<DeviceProvider>().toggleSound(),
            );
          },
        ),
        // Konsol butonu
        Selector<DeviceProvider, int>(
          selector: (_, p) => p.logLines.length,
          builder: (context, logCount, _) {
            return IconButton(
              icon: Badge(
                isLabelVisible: logCount > 0,
                label: Text('$logCount', style: const TextStyle(fontSize: 9)),
                child: const Icon(Icons.terminal, size: 22),
              ),
              tooltip: 'Konsol',
              onPressed: () {
                final provider = context.read<DeviceProvider>();
                LogConsoleSheet.show(context, provider, _logScrollController);
              },
            );
          },
        ),
        // Cihaz tara
        IconButton(
          icon: const Icon(Icons.refresh, size: 22),
          tooltip: 'Cihazları Tara',
          onPressed: () => context.read<DeviceProvider>().scanDevices(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ── Veri Girişi Bölümü ─────────────────────────────────────────────────────

  Widget _buildInputSection() {
    return Selector<DeviceProvider, (String, String, String, ReadingMode)>(
      selector: (_, p) => (p.heatSecondaryIds, p.waterSecondaryIds, p.daireIds, p.selectedReadingMode),
      builder: (context, data, _) {
        final heatSecondaryIds = data.$1;
        final waterSecondaryIds = data.$2;
        final daireIds = data.$3;
        final selectedReadingMode = data.$4;

        int heatLines = heatSecondaryIds.split('\n').length;
        int waterLines = waterSecondaryIds.split('\n').length;
        int daireLines = daireIds.split('\n').length;
        int linesCount = [
          heatLines,
          waterLines,
          daireLines,
        ].reduce((a, b) => a > b ? a : b);
        if (linesCount < 4) linesCount = 4;

        // Satır listelerini oluştur
        final daireList = daireIds.split('\n');
        final heatList = heatSecondaryIds.split('\n');
        final waterList = waterSecondaryIds.split('\n');

        String getRow(List<String> list, int i) =>
            (i < list.length) ? list[i] : '';

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        // Dinamik Tema Renkleri — Light/Dark otomatik uyumlu
        final Color bgSurface = isDark ? const Color(0xFF1E293B) : Colors.white;
        final Color bgHeader  = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5EFE6);
        final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFD6CFC4);
        final Color textMain  = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1C1917);
        final Color textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF78716C);
        final Color inputBg   = isDark ? const Color(0xFF0F172A) : Colors.white;

        const int flexDaire = 2;
        const int flexSayac = 4;

        // ── Satır Widget'ı ──────────────────────────────────────────────────
        Widget buildDataRow(int i) {
          final mode = selectedReadingMode;
          return Container(
            height: 48, // Sabit yükseklik — uzun metin bile satırı kaydıramaz
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                // DAİRE
                Expanded(
                  flex: flexDaire,
                  child: Center(
                    child: Text(
                      getRow(daireList, i).isEmpty ? '${i + 1}' : getRow(daireList, i),
                      style: TextStyle(
                        color: textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // ISI SAYACI
                if (mode == ReadingMode.heat || mode == ReadingMode.both)
                  Expanded(
                    flex: flexSayac,
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          getRow(heatList, i),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                // SICAK SU
                if (mode == ReadingMode.water || mode == ReadingMode.both)
                  Expanded(
                    flex: flexSayac,
                    child: Container(
                      height: 36,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: borderColor, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          getRow(waterList, i),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bgSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: isDark ? 15 : 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: borderColor, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Üst Başlık ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.purple.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.list_alt,
                              color: AppTheme.purple,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sayaç Listesi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textMain,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final provider = context.read<DeviceProvider>();
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final success = await provider.importFromExcel();
                          if (success && mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: colorScheme.onPrimary),
                                    const SizedBox(width: 8),
                                    const Text('Excel Listesi Başarıyla Yüklendi'),
                                  ],
                                ),
                                backgroundColor: AppTheme.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.file_upload, size: 18),
                        label: const Text("Excel'den Yükle"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: AppTheme.purple.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, thickness: 1, color: borderColor),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Site Adı ──────────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          key: const ValueKey('siteNameInput'),
                          controller: _siteNameController,
                          style: TextStyle(color: textMain, fontSize: 14),
                          onChanged: (val) =>
                              context.read<DeviceProvider>().setSiteName(val),
                          decoration: InputDecoration(
                            labelText: 'Site / Apartman Adı',
                            labelStyle: TextStyle(color: textMuted),
                            hintText: 'örn: A Blok',
                            hintStyle: TextStyle(color: textMuted),
                            prefixIcon: Icon(Icons.location_city, color: textMuted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Gizli Controller TextField’ları (state güncelleme için) ──
                      Offstage(
                        offstage: true,
                        child: Column(
                          children: [
                            TextField(
                              key: const ValueKey('daireInput'),
                              controller: _daireController,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              onChanged: (val) =>
                                  context.read<DeviceProvider>().setDaireIds(val),
                            ),
                            TextField(
                              key: const ValueKey('heatInput'),
                              controller: _heatController,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              onChanged: (val) =>
                                  context.read<DeviceProvider>().setHeatSecondaryIds(val),
                            ),
                            TextField(
                              key: const ValueKey('waterInput'),
                              controller: _waterController,
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              onChanged: (val) =>
                                  context.read<DeviceProvider>().setWaterSecondaryIds(val),
                            ),
                          ],
                        ),
                      ),

                      // ── Modern Sayac Tablosu (Daraltılabilir & Scrollable) ───────────────────
                      const SizedBox(height: 16),
                      Theme(
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const ValueKey('meters_expansion_tile'),
                          tilePadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Icon(Icons.table_rows, color: textMuted, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Daire & Sayaç Listesi ($linesCount Daire)",
                                style: TextStyle(
                                  color: textMain,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          initiallyExpanded: false,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: bgSurface,
                                border: Border.all(color: borderColor, width: 1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  // BAŞLIK SATIRI
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgHeader,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                      border: Border(
                                        bottom: BorderSide(color: borderColor, width: 1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: flexDaire,
                                          child: Text(
                                            'DAİRE',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        if (selectedReadingMode == ReadingMode.heat || selectedReadingMode == ReadingMode.both)
                                          Expanded(
                                            flex: flexSayac,
                                            child: Text(
                                              'ISI SAYACI',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppTheme.heat,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        if (selectedReadingMode == ReadingMode.water || selectedReadingMode == ReadingMode.both)
                                          Expanded(
                                            flex: flexSayac,
                                            child: Text(
                                              'SICAK SU',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppTheme.water,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // VERİ SATIRLARI (Virtualized & Scrollable)
                                  SizedBox(
                                    height: linesCount * 48.0 > 240 ? 240 : linesCount * 48.0,
                                    child: ListView.builder(
                                      controller: _inputListScrollController,
                                      itemCount: linesCount,
                                      itemExtent: 48.0,
                                      itemBuilder: (context, i) => buildDataRow(i),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sayaçları Oku Butonu ───────────────────────────────────────────────────

  Widget _buildReadButton() {
    return Selector<DeviceProvider, (bool, bool)>(
      selector: (_, p) => (p.isConnected, p.isReading),
      builder: (context, data, _) {
        final isConnected = data.$1;
        final isReading = data.$2;
        final enabled = isConnected && !isReading;

        if (isReading) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: enabled
                  ? () async {
                      FocusScope.of(context).unfocus();
                      final provider = context.read<DeviceProvider>();
                      await provider.readMeters();
                      if (!provider.isStopped) {
                        _showCompletionDialog();
                      }
                    }
                  : null,
              icon: const Icon(Icons.sensors, size: 24),
              label: const Text(
                'Sayaçları Oku',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled
                    ? AppTheme.success
                    : Theme.of(context).colorScheme.surfaceContainer,
                foregroundColor: Colors.white,
                disabledForegroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.38),
                disabledBackgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainer,
                elevation: enabled ? 6 : 0,
                shadowColor: AppTheme.success.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sonuç Başlık Satırı ────────────────────────────────────────────────────

  Widget _buildResultHeader() {
    return Selector<DeviceProvider, int>(
      selector: (_, p) => p.meterList.length,
      builder: (context, length, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      size: 14,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$length sayaç bulundu',
                      style: const TextStyle(
                        color: AppTheme.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.read<DeviceProvider>().clearMeters(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Temizle'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: colorScheme.error.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRetryButtonSliver() {
    return Selector<DeviceProvider, (bool, bool)>(
      selector: (_, p) => (
        p.isReading,
        p.meterList.any((m) => m.overallStatus == MeterStatus.failed),
      ),
      builder: (context, data, _) {
        final isReading = data.$1;
        final hasFailed = data.$2;

        if (!hasFailed) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ElevatedButton.icon(
              onPressed: isReading
                  ? null
                  : () async {
                      final provider = context.read<DeviceProvider>();
                      await provider.retryFailedMeters();
                      if (!provider.isStopped) {
                        _showCompletionDialog();
                      }
                    },
              icon: const Icon(Icons.replay),
              label: const Text('Okunamayanları Tekrar Oku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sayaç Kartları Listesi (Sliver) ──────────────────────────────────────────

  Widget _buildMetersSliverList() {
    return Selector<DeviceProvider, int>(
      selector: (_, provider) => provider.meterList.length,
      builder: (context, length, _) {
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return Selector<DeviceProvider, (MeterData, ReadingMode)>(
              key: ValueKey('selector_$index'),
              selector: (_, provider) => (provider.meterList[index], provider.selectedReadingMode),
              builder: (context, data, _) {
                final meter = data.$1;
                final mode = data.$2;
                
                bool isSuccess = false;
                if (mode == ReadingMode.heat) {
                  isSuccess = meter.heatStatus == MeterStatus.success;
                } else if (mode == ReadingMode.water) {
                  isSuccess = meter.waterStatus == MeterStatus.success;
                } else if (mode == ReadingMode.both) {
                  isSuccess = meter.heatStatus == MeterStatus.success &&
                              meter.waterStatus == MeterStatus.success;
                }

                return MeterCard(
                  key: ValueKey('meter_${meter.flatNo}'),
                  daireNo: meter.flatNo,
                  isiEndeks: meter.getHeatIndexDisplay(),
                  suEndeks: meter.getWaterIndexDisplay(),
                  isSuccess: isSuccess,
                );
              },
            );
          }, childCount: length),
        );
      },
    );
  }

  // ── Boş Durum ──────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.speed_outlined,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz sayaç verisi yok',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cihazı bağlayıp ayarlarınızı tamamladıktan sonra\n"Sayaçları Oku" butonuna basarak işleme başlayabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CSV Export ─────────────────────────────────────────────────────────────

  Future<void> _exportToCSV(DeviceProvider provider) async {
    try {
      final siteName = provider.siteName.isEmpty
          ? 'Bilinmeyen_Site'
          : provider.siteName;
      final meterList = provider.meterList;
      final mode = provider.selectedReadingMode;

      // CSV içeriğini arka planda oluştur
      final csvContent = await compute(_generateCSVString, (meterList, mode));

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')[0];
      final file = File(
        '${directory.path}/SayacRapor_${siteName}_$dateStr.csv',
      );
      await file.writeAsString(csvContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '$siteName Sayaç Okuma Raporu (.csv)',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dışa aktarma hatası: $e')));
      }
    }
  }

  // ── Excel Export ───────────────────────────────────────────────────────────

  Future<void> _exportToExcel(DeviceProvider provider) async {
    try {
      final siteName = provider.siteName.isEmpty
          ? 'Bilinmeyen_Site'
          : provider.siteName;
      final meterList = provider.meterList;
      final mode = provider.selectedReadingMode;

      // Excel dosyasını arka planda oluştur
      final fileBytes = await compute(_generateExcelBytes, (
        meterList,
        siteName,
        mode,
      ));

      if (fileBytes != null) {
        final directory = await getApplicationDocumentsDirectory();
        final dateStr = DateTime.now()
            .toIso8601String()
            .replaceAll(':', '-')
            .split('.')[0];
        final filePath =
            '${directory.path}/SayacRapor_${siteName}_$dateStr.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            text: '$siteName Sayaç Okuma Raporu (.xlsx)',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Excel oluşturma hatası: $e')));
      }
    }
  }

  // ── Dışa Aktarma Format Seçimi (BottomSheet) ───────────────────────────────

  void _showExportOptionsDialog(BuildContext context, DeviceProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Dışa Aktarma Formatı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.table_view, color: AppTheme.success),
                title: const Text('Excel Raporu (.xlsx)'),
                subtitle: const Text('Önerilen (Formatlı tablo)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToExcel(provider);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.description,
                  color: Colors.blueAccent,
                ),
                title: const Text('CSV Raporu (.csv)'),
                subtitle: const Text('Düz metin formatında'),
                onTap: () {
                  Navigator.pop(context);
                  _exportToCSV(provider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Yardımcılar ────────────────────────────────────────────────────────────

  void _showCompletionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            const SizedBox(width: 12),
            Text(
              'Okuma Tamamlandı',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
        content: const Text(
          'Listedeki tüm sayaçların okuma işlemi tamamlandı.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.amber;
      case ConnectionStatus.connected:
        return const Color(0xFF3FB950);
      case ConnectionStatus.error:
        return const Color(0xFFF85149);
    }
  }

  bool _isScrolling = false;

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients || _isScrolling || _isAutoScrollPaused) return;

    // Yeni, daha büyük kart tasarımına göre (yaklaşık 115 birim) offset hesapla.
    // 650 birim üstteki ayarlar, başlıklar ve giriş alanları için tahmini başlangıç noktasıdır.
    double itemHeight = 115.0;
    double topOffset = 650.0;

    double targetOffset = topOffset + (index * itemHeight);

    _isScrolling = true;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    ).then((_) {
      _isScrolling = false;
    });
  }

  void _showAddManualMeterDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final daireController = TextEditingController();
    final heatSerialController = TextEditingController();
    final heatIndexController = TextEditingController(text: '0');
    final waterSerialController = TextEditingController();
    final waterIndexController = TextEditingController(text: '0');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.playlist_add_circle_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Yeni Sayaç Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Manuel olarak yeni bir daire ve sayaç endeks bilgisi ekleyin.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  
                  // Daire No
                  TextFormField(
                    controller: daireController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Daire No *',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      prefixIcon: Icon(Icons.meeting_room_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Lütfen daire numarası girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Isı Sayacı Seri No
                  TextFormField(
                    controller: heatSerialController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Isı Sayacı Seri No',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      prefixIcon: Icon(Icons.numbers_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Isı Enerji Endeksi
                  TextFormField(
                    controller: heatIndexController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Isı Enerji Endeksi (kWh)',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      prefixIcon: Icon(Icons.flash_on_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Divider(height: 24, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                  // Sıcak Su Seri No
                  TextFormField(
                    controller: waterSerialController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      labelText: 'Sıcak Su Seri No',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      prefixIcon: Icon(Icons.numbers_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sıcak Su Endeksi
                  TextFormField(
                    controller: waterIndexController,
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Sıcak Su Endeksi (m³)',
                      labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      prefixIcon: Icon(Icons.water_drop_outlined, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'İptal',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final provider = context.read<DeviceProvider>();
                  provider.addManualMeter(
                    daireNo: daireController.text,
                    heatMeterId: heatSerialController.text.isEmpty ? 'Manuel' : heatSerialController.text,
                    waterMeterId: waterSerialController.text.isEmpty ? 'Manuel' : waterSerialController.text,
                    heatIndex: heatIndexController.text,
                    waterIndex: waterIndexController.text,
                  );
                  
                  Navigator.pop(dialogContext);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Text('${daireController.text} Nolu Daire Manuel Olarak Eklendi'),
                        ],
                      ),
                      backgroundColor: AppTheme.success,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Kaydet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Isolate içinde çalışacak ağır işlem fonksiyonları (Top-level)
String _generateCSVString((List<MeterData>, ReadingMode) data) {
  final meters = data.$1;
  final mode = data.$2;
  final buffer = StringBuffer();

  final headers = <String>[];
  headers.add('Daire No');
  
  if (mode == ReadingMode.heat || mode == ReadingMode.both) {
    headers.add('Isı Sayaç No');
    headers.add('Isı Enerji (kWh)');
  }
  
  if (mode == ReadingMode.water || mode == ReadingMode.both) {
    headers.add('Su Sayaç No');
    headers.add('Su Hacim (m³)');
  }
  
  headers.add('Son Okuma Tarihi');
  headers.add('Durum');

  buffer.writeln(headers.join(','));

  for (var i = 0; i < meters.length; i++) {
    final m = meters[i];
    final dateStr = m.readTime != null
        ? '${m.readTime!.day.toString().padLeft(2, '0')}.${m.readTime!.month.toString().padLeft(2, '0')}.${m.readTime!.year} ${m.readTime!.hour.toString().padLeft(2, '0')}:${m.readTime!.minute.toString().padLeft(2, '0')}'
        : '-';
    final statusStr = m.getStatusText();

    final rowData = <String>[];
    rowData.add(m.flatNo);
    
    if (mode == ReadingMode.heat || mode == ReadingMode.both) {
      rowData.add(m.getHeatMeterIdDisplay());
      rowData.add(m.getHeatIndexDisplay());
    }
    
    if (mode == ReadingMode.water || mode == ReadingMode.both) {
      rowData.add(m.getWaterMeterIdDisplay());
      rowData.add(m.getWaterIndexDisplay());
    }
    
    rowData.add(dateStr);
    rowData.add(statusStr);

    buffer.writeln(rowData.join(','));
  }
  return buffer.toString();
}

List<int>? _generateExcelBytes((List<MeterData>, String, ReadingMode) data) {
  final meters = data.$1;
  final siteName = data.$2;
  final mode = data.$3;
  final excel = excel_pkg.Excel.createExcel();

  // Varsayılan sayfayı temizle veya al
  const sheetName = 'Sayfa1';
  final sheet = excel[sheetName];
  excel.setDefaultSheet(sheetName);

  // Başlık Stili (Bold)
  final headerStyle = excel_pkg.CellStyle(
    bold: true,
    fontFamily: excel_pkg.getFontFamily(excel_pkg.FontFamily.Calibri),
    fontSize: 11,
    horizontalAlign: excel_pkg.HorizontalAlign.Center,
  );

  // Başlıklar (Row 1) - Seçilen Okuma Moduna göre dinamik oluştur
  final headers = <String>[];
  headers.add('Daire No');
  
  if (mode == ReadingMode.heat || mode == ReadingMode.both) {
    headers.add('Isı Sayaç No');
    headers.add('Isı Enerji (kWh)');
  }
  
  if (mode == ReadingMode.water || mode == ReadingMode.both) {
    headers.add('Su Sayaç No');
    headers.add('Su Hacim (m³)');
  }
  
  headers.add('Son Okuma Tarihi');
  headers.add('Durum');

  // Row 0: Site/Apartman Adı (Şablondaki gibi A1 hücresine yazıp genişleteceğiz)
  sheet.appendRow([excel_pkg.TextCellValue('Site/Apartman Adı: $siteName')]);
  // İlk satırı birleştirebiliriz (A1'den son sütuna kadar)
  sheet.merge(
    excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    excel_pkg.CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0),
  );

  sheet.appendRow(headers.map((h) => excel_pkg.TextCellValue(h)).toList());

  // Başlıklara stil uygula (Row index 1)
  for (var i = 0; i < headers.length; i++) {
    var cell = sheet.cell(
      excel_pkg.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
    );
    cell.cellStyle = headerStyle;
  }

  // Veriler (Row 2'den başlar)
  for (var i = 0; i < meters.length; i++) {
    final m = meters[i];
    final dateStr = m.readTime != null
        ? '${m.readTime!.day.toString().padLeft(2, '0')}.${m.readTime!.month.toString().padLeft(2, '0')}.${m.readTime!.year} ${m.readTime!.hour.toString().padLeft(2, '0')}:${m.readTime!.minute.toString().padLeft(2, '0')}'
        : '-';
    final statusStr = m.getStatusText();

    final rowData = <excel_pkg.CellValue>[];
    rowData.add(excel_pkg.TextCellValue(m.flatNo));
    
    if (mode == ReadingMode.heat || mode == ReadingMode.both) {
      rowData.add(excel_pkg.TextCellValue(m.getHeatMeterIdDisplay()));
      rowData.add(excel_pkg.TextCellValue(m.getHeatIndexDisplay()));
    }
    
    if (mode == ReadingMode.water || mode == ReadingMode.both) {
      rowData.add(excel_pkg.TextCellValue(m.getWaterMeterIdDisplay()));
      rowData.add(excel_pkg.TextCellValue(m.getWaterIndexDisplay()));
    }
    
    rowData.add(excel_pkg.TextCellValue(dateStr));
    rowData.add(excel_pkg.TextCellValue(statusStr));

    sheet.appendRow(rowData);
  }

  // Sütun Genişlikleri (Tahmini AutoFit)
  int colIndex = 0;
  sheet.setColumnWidth(colIndex++, 15); // Daire No
  
  if (mode == ReadingMode.heat || mode == ReadingMode.both) {
    sheet.setColumnWidth(colIndex++, 20); // Isı No
    sheet.setColumnWidth(colIndex++, 20); // Isı Enerji
  }
  
  if (mode == ReadingMode.water || mode == ReadingMode.both) {
    sheet.setColumnWidth(colIndex++, 20); // Su No
    sheet.setColumnWidth(colIndex++, 20); // Su Hacim
  }
  
  sheet.setColumnWidth(colIndex++, 25); // Tarih
  sheet.setColumnWidth(colIndex++, 15); // Durum

  return excel.encode();
}
