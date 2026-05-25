import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:excel/excel.dart' as excel_pkg;
import '../providers/app_data_provider.dart';
import '../models/meter_data.dart';
import '../services/excel_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedFormat = 'excel'; // csv, excel
  String _separator = 'semicolon'; // semicolon, comma, tab
  String _selectedScope = 'all'; // all, heat, water, synced, pending
  bool _includeHeaders = true;
  bool _groupByBlock = false;
  bool _isExporting = false;
  bool _exportComplete = false;

  String _formatLabel(String fmt) {
    if (fmt == 'csv') return 'CSV';
    if (fmt == 'excel') return 'Excel (XLSX)';
    return fmt;
  }

  String _scopeLabel(String s) {
    if (s == 'all') return 'Tüm Veriler';
    if (s == 'heat') return 'Sadece Isı Sayaçları';
    if (s == 'water') return 'Sadece Su Sayaçları';
    if (s == 'synced') return 'Senkronize Edilmiş';
    if (s == 'pending') return 'Senkronize Bekleyen';
    return s;
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _exportComplete = false;
    });

    final provider = context.read<AppDataProvider>();
    final siteName = provider.siteName.isEmpty ? 'Bilinmeyen_Site' : provider.siteName;
    final List<MeterData> rawMeters = provider.meterList;

    // Filter by scope
    List<MeterData> metersToExport = rawMeters.where((m) {
      if (_selectedScope == 'heat') {
        if (m.type.name != 'heat' && m.heatMeterId.isEmpty) return false;
      } else if (_selectedScope == 'water') {
        if (m.type.name != 'water' && m.waterMeterId.isEmpty) return false;
      } else if (_selectedScope == 'synced') {
        if (m.overallStatus.name != 'success') return false;
      } else if (_selectedScope == 'pending') {
        if (m.overallStatus.name == 'success') return false;
      }
      return true;
    }).toList();

    if (_groupByBlock) {
      metersToExport.sort((a, b) => (a.blok ?? '').compareTo(b.blok ?? ''));
    }

    try {
      if (_selectedFormat == 'csv') {
        final csvContent = await compute<(List<MeterData>, bool, String), String>(
          _generateCSV,
          (metersToExport, _includeHeaders, _separator),
        );

        if (kIsWeb) {
          final fileName = 'SayacRapor_${siteName}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
          await ExcelService.saveAndShareExcel(Uint8List.fromList(csvContent.codeUnits), fileName);
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
          final file = File('${directory.path}/SayacRapor_${siteName}_$dateStr.csv');
          await file.writeAsString(csvContent);
          await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: '$siteName Sayaç Okuma Raporu (.csv)'));
        }
      } else {
        // excel
        final fileBytes = await compute<(List<MeterData>, String, bool), List<int>?>(
          _generateExcel,
          (metersToExport, siteName, _includeHeaders),
        );

        if (fileBytes != null) {
          final dateStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
          final fileName = 'SayacRapor_${siteName}_$dateStr.xlsx';
          await ExcelService.saveAndShareExcel(Uint8List.fromList(fileBytes), fileName);
        }
      }

      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportComplete = true;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _exportComplete = false);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Veri Dışa Aktarma',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          Text(
            'Sayaç verilerini CSV veya Excel formatında dışa aktarın',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Format & Scope
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              Widget formatSection = _buildFormatSection(isDark);
              Widget scopeSection = _buildScopeSection(isDark);

              if (isMobile) {
                return Column(
                  children: [
                    formatSection,
                    const SizedBox(height: 24),
                    scopeSection,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: formatSection),
                  const SizedBox(width: 24),
                  Expanded(child: scopeSection),
                ],
              );
            }
          ),
          const SizedBox(height: 24),

          // Action Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1120) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                ),
                child: Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatLabel(_selectedFormat)} - ${_scopeLabel(_selectedScope)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'Veri dosyası oluşturulacak',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (isMobile) const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _handleExport,
                      icon: Icon(_isExporting ? Icons.hourglass_top : (_exportComplete ? Icons.check_circle : Icons.download), size: 18),
                      label: Text(_isExporting ? 'Oluşturuluyor...' : (_exportComplete ? 'Tamamlandı!' : 'Dışa Aktar')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _exportComplete ? Colors.green : const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Format',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          _buildFormatOption('csv', 'CSV', isDark),
          const SizedBox(height: 12),
          _buildFormatOption('excel', 'Excel (XLSX)', isDark),

          if (_selectedFormat == 'csv') ...[
            const SizedBox(height: 24),
            Text(
              'Ayırıcı Karakter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSeparatorOption('semicolon', ';', isDark),
                const SizedBox(width: 8),
                _buildSeparatorOption('comma', ',', isDark),
                const SizedBox(width: 8),
                _buildSeparatorOption('tab', 'Tab', isDark),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormatOption(String value, String label, bool isDark) {
    final isSelected = _selectedFormat == value;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF8B5CF6).withValues(alpha: 0.2) : const Color(0xFF8B5CF6).withValues(alpha: 0.1)) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.5) : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.download, size: 20, color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, size: 20, color: Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparatorOption(String value, String label, bool isDark) {
    final isSelected = _separator == value;
    return InkWell(
      onTap: () => setState(() => _separator = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildScopeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Veri Kapsamı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedScope,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                icon: Icon(Icons.filter_list, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade900, fontSize: 14),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('Tüm Veriler')),
                  DropdownMenuItem(value: 'heat', child: Text('Sadece Isı Sayaçları')),
                  DropdownMenuItem(value: 'water', child: Text('Sadece Su Sayaçları')),
                  DropdownMenuItem(value: 'synced', child: Text('Senkronize Edilmiş')),
                  DropdownMenuItem(value: 'pending', child: Text('Senkronize Bekleyen')),
                ],
                onChanged: (val) => setState(() => _selectedScope = val!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSwitchOption('Başlık Satırı Ekle', _includeHeaders, (val) => setState(() => _includeHeaders = val), isDark),
          const SizedBox(height: 12),
          _buildSwitchOption('Bloklara Göre Grupla', _groupByBlock, (val) => setState(() => _groupByBlock = val), isDark),
        ],
      ),
    );
  }

  Widget _buildSwitchOption(String label, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

String _generateCSV((List<MeterData>, bool, String) data) {
  final meters = data.$1;
  final includeHeaders = data.$2;
  final sepType = data.$3;

  String sep = ';';
  if (sepType == 'comma') sep = ',';
  if (sepType == 'tab') sep = '\t';

  final buffer = StringBuffer();

  if (includeHeaders) {
    final headers = ['Daire No', 'Isı Sayaç No', 'Isı Enerji (kWh)', 'Su Sayaç No', 'Su Hacim (m³)', 'Son Okuma Tarihi', 'Durum', 'Blok'];
    buffer.writeln(headers.join(sep));
  }

  for (var m in meters) {
    String dateStr = '-';
    if (m.readTime != null) {
      final t = m.readTime!;
      dateStr = '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    final row = [
      m.flatNo,
      m.getHeatMeterIdDisplay(),
      m.getHeatIndexDisplay(),
      m.getWaterMeterIdDisplay(),
      m.getWaterIndexDisplay(),
      dateStr,
      m.getStatusText(),
      m.blok ?? '',
    ];
    buffer.writeln(row.join(sep));
  }
  return buffer.toString();
}

List<int>? _generateExcel((List<MeterData>, String, bool) data) {
  final meters = data.$1;
  final siteName = data.$2;
  final includeHeaders = data.$3;

  final excel = excel_pkg.Excel.createExcel();
  const sheetName = 'Sayfa1';
  final sheet = excel[sheetName];
  excel.setDefaultSheet(sheetName);

  if (includeHeaders) {
    final headers = ['Daire No', 'Isı Sayaç No', 'Isı Enerji (kWh)', 'Su Sayaç No', 'Su Hacim (m³)', 'Son Okuma Tarihi', 'Durum', 'Blok'];
    sheet.appendRow([excel_pkg.TextCellValue('Site/Apartman Adı: $siteName')]);
    sheet.merge(
      excel_pkg.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      excel_pkg.CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0),
    );
    sheet.appendRow(headers.map((h) => excel_pkg.TextCellValue(h)).toList());
  }

  for (var m in meters) {
    String dateStr = '-';
    if (m.readTime != null) {
      final t = m.readTime!;
      dateStr = '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }

    final row = [
      excel_pkg.TextCellValue(m.flatNo),
      excel_pkg.TextCellValue(m.getHeatMeterIdDisplay()),
      excel_pkg.TextCellValue(m.getHeatIndexDisplay()),
      excel_pkg.TextCellValue(m.getWaterMeterIdDisplay()),
      excel_pkg.TextCellValue(m.getWaterIndexDisplay()),
      excel_pkg.TextCellValue(dateStr),
      excel_pkg.TextCellValue(m.getStatusText()),
      excel_pkg.TextCellValue(m.blok ?? ''),
    ];
    sheet.appendRow(row);
  }

  for (int i=0; i<8; i++) {
    sheet.setColumnWidth(i, 20);
  }

  return excel.encode();
}
