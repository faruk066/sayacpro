import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/device_provider.dart';
import 'export_screen.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  String _filterType = 'all'; // all, heat, water
  String _filterSynced = 'all'; // all, synced, pending
  String _sortField = 'date'; // date, value
  String _sortDir = 'desc'; // asc, desc
  int _currentPage = 1;
  static const int _perPage = 15;

  void _handleExport(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExportScreen()));
  }

  Future<void> _handleSync(BuildContext context) async {
    final provider = context.read<AppDataProvider>();
    if (provider is DeviceProvider) {
      await provider.saveSession(immediate: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler senkronize edildi.')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cloud modunda veriler zaten senkronize.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AppDataProvider>(
      builder: (context, provider, child) {
        final meters = provider.meterList;

        // Convert meters to "readings" representation
        List<_ReadingRow> allReadings = [];
        for (final m in meters) {
          final isSuccess = m.overallStatus.name == 'success';

          if (m.heatMeterId.isNotEmpty) {
            final valStr = m.getHeatIndexDisplay();
            final val = double.tryParse(valStr) ?? 0;
            final readTime = m.readTime;
            allReadings.add(
              _ReadingRow(
                id: '${m.flatNo}_heat',
                flatNo: m.flatNo,
                block: m.blok ?? '-',
                type: 'heat',
                meterSerialNo: m.heatMeterId,
                value: val,
                valueDisplay: valStr,
                date: readTime != null
                    ? '${readTime.day.toString().padLeft(2, '0')}.${readTime.month.toString().padLeft(2, '0')}.${readTime.year}'
                    : '-',
                time: readTime != null
                    ? '${readTime.hour.toString().padLeft(2, '0')}:${readTime.minute.toString().padLeft(2, '0')}'
                    : '-',
                synced: isSuccess,
              ),
            );
          }

          if (m.waterMeterId.isNotEmpty) {
            final valStr = m.getWaterIndexDisplay();
            final val = double.tryParse(valStr) ?? 0;
            final readTime = m.readTime;
            allReadings.add(
              _ReadingRow(
                id: '${m.flatNo}_water',
                flatNo: m.flatNo,
                block: m.blok ?? '-',
                type: 'water',
                meterSerialNo: m.waterMeterId,
                value: val,
                valueDisplay: valStr,
                date: readTime != null
                    ? '${readTime.day.toString().padLeft(2, '0')}.${readTime.month.toString().padLeft(2, '0')}.${readTime.year}'
                    : '-',
                time: readTime != null
                    ? '${readTime.hour.toString().padLeft(2, '0')}:${readTime.minute.toString().padLeft(2, '0')}'
                    : '-',
                synced: isSuccess,
              ),
            );
          }
        }

        // Filter by type
        List<_ReadingRow> filtered = allReadings.where((r) {
          if (_filterType != 'all' && r.type != _filterType) return false;
          if (_filterSynced == 'synced' && !r.synced) return false;
          if (_filterSynced == 'pending' && r.synced) return false;
          return true;
        }).toList();

        // Sort
        filtered.sort((a, b) {
          int cmp;
          if (_sortField == 'date') {
            final aKey = '${a.date}${a.time}';
            final bKey = '${b.date}${b.time}';
            cmp = aKey.compareTo(bKey);
          } else {
            cmp = a.value.compareTo(b.value);
          }
          return _sortDir == 'desc' ? -cmp : cmp;
        });

        final totalPages = (filtered.length / _perPage).ceil().clamp(1, 999999);
        if (_currentPage > totalPages) {
          _currentPage = totalPages;
        }
        final start = (_currentPage - 1) * _perPage;
        final end = (start + _perPage).clamp(0, filtered.length);
        final paginated = filtered.sublist(start, end);

        final totalValue = filtered.fold<double>(0, (s, r) => s + r.value);
        final syncedCount = filtered.where((r) => r.synced).length;
        final pendingCount = filtered.length - syncedCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Okuma Kayıtları',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        '${filtered.length} okuma kaydı',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        child: _buildActionButton(
                          isDark,
                          Icons.cloud_upload_outlined,
                          'Senkronize',
                          Colors.green,
                          () => _handleSync(context),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: _buildActionButton(
                          isDark,
                          Icons.download_outlined,
                          'Dışa Aktar',
                          const Color(0xFF8B5CF6),
                          () => _handleExport(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  int cols = 3;
                  if (w < 600)
                    cols = 1;
                  else if (w < 900)
                    cols = 2;

                  return Column(
                    children: [
                      GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: w < 600 ? 3 : 2.5,
                        children: [
                          _buildSummaryCard(
                            isDark,
                            Icons.trending_up,
                            'Toplam Değer',
                            totalValue.toStringAsFixed(0),
                            const Color(0xFF8B5CF6),
                          ),
                          _buildSummaryCard(
                            isDark,
                            Icons.check_circle_outline,
                            'Senkronize',
                            syncedCount.toString(),
                            Colors.green,
                          ),
                          _buildSummaryCard(
                            isDark,
                            Icons.access_time,
                            'Bekleyen',
                            pendingCount.toString(),
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0B1120) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade200,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    if (w < 600) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildFilterDropdown(
                                  isDark,
                                  'Tip',
                                  _filterType,
                                  ['all', 'heat', 'water'],
                                  ['Tüm Tipler', 'Isı Sayacı', 'Su Sayacı'],
                                  (v) => setState(() {
                                    _filterType = v!;
                                    _currentPage = 1;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildFilterDropdown(
                                  isDark,
                                  'Durum',
                                  _filterSynced,
                                  ['all', 'synced', 'pending'],
                                  ['Tüm Durumlar', 'Senkronize', 'Bekleyen'],
                                  (v) => setState(() {
                                    _filterSynced = v!;
                                    _currentPage = 1;
                                  }),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSortDropdown(isDark),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        const Icon(Icons.filter_list, size: 18),
                        const SizedBox(width: 8),
                        _buildFilterDropdown(
                          isDark,
                          'Tip',
                          _filterType,
                          ['all', 'heat', 'water'],
                          ['Tüm Tipler', 'Isı Sayacı', 'Su Sayacı'],
                          (v) => setState(() {
                            _filterType = v!;
                            _currentPage = 1;
                          }),
                        ),
                        const SizedBox(width: 12),
                        _buildFilterDropdown(
                          isDark,
                          'Durum',
                          _filterSynced,
                          ['all', 'synced', 'pending'],
                          ['Tüm Durumlar', 'Senkronize', 'Bekleyen'],
                          (v) => setState(() {
                            _filterSynced = v!;
                            _currentPage = 1;
                          }),
                        ),
                        const Spacer(),
                        _buildSortDropdown(isDark),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Table
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.list_alt_outlined,
                        size: 48,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz okuma kaydı yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cihaz bağlayarak veya Excel içe aktararak başlayın.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

              if (filtered.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1120) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            isDark
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade50,
                          ),
                          columns: [
                            DataColumn(
                              label: Text(
                                'Daire',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Tip',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Sayaç No',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Değer',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Tarih',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Saat',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Durum',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                          rows: paginated.map((r) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    '${r.block}-${r.flatNo}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: r.type == 'heat'
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          r.type == 'heat'
                                              ? Icons.local_fire_department
                                              : Icons.water_drop,
                                          size: 12,
                                          color: r.type == 'heat'
                                              ? Colors.orange
                                              : Colors.blue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r.type == 'heat' ? 'Isı' : 'Su',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: r.type == 'heat'
                                                ? Colors.orange
                                                : Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.meterSerialNo,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      color: isDark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.valueDisplay,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.date,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    r.time,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  r.synced
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Senkronize',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Bekliyor',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      // Pagination
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${start + 1}-$end / ${filtered.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                            ),
                            Row(
                              children: [
                                _buildPageButton(
                                  isDark,
                                  'Önceki',
                                  _currentPage > 1,
                                  () => setState(
                                    () => _currentPage = (_currentPage - 1)
                                        .clamp(1, totalPages),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                ...List.generate(totalPages.clamp(0, 5), (i) {
                                  final pageNum = i + 1;
                                  final isActive = _currentPage == pageNum;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: InkWell(
                                      onTap: () => setState(
                                        () => _currentPage = pageNum,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? const Color(0xFF8B5CF6)
                                              : (isDark
                                                    ? const Color(0xFF1E293B)
                                                    : Colors.grey.shade100),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$pageNum',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isActive
                                                  ? Colors.white
                                                  : (isDark
                                                        ? Colors.grey.shade300
                                                        : Colors.grey.shade600),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 4),
                                _buildPageButton(
                                  isDark,
                                  'Sonraki',
                                  _currentPage < totalPages,
                                  () => setState(
                                    () => _currentPage = (_currentPage + 1)
                                        .clamp(1, totalPages),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    bool isDark,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 13, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        backgroundColor: color.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    bool isDark,
    String hint,
    String currentValue,
    List<String> values,
    List<String> labels,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
          ),
          onChanged: onChanged,
          items: List.generate(values.length, (i) {
            return DropdownMenuItem<String>(
              value: values[i],
              child: Text(labels[i]),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSortDropdown(bool isDark) {
    final currentSort = '$_sortField-$_sortDir';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSort,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
          ),
          onChanged: (v) {
            if (v == null) return;
            final parts = v.split('-');
            setState(() {
              _sortField = parts[0];
              _sortDir = parts[1];
              _currentPage = 1;
            });
          },
          items: const [
            DropdownMenuItem(
              value: 'date-desc',
              child: Text('Tarih (Yeniden Eskiye)'),
            ),
            DropdownMenuItem(
              value: 'date-asc',
              child: Text('Tarih (Eskiden Yeniye)'),
            ),
            DropdownMenuItem(
              value: 'value-desc',
              child: Text('Değer (Çoktan Aza)'),
            ),
            DropdownMenuItem(
              value: 'value-asc',
              child: Text('Değer (Azdan Çoğa)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageButton(
    bool isDark,
    String label,
    bool enabled,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: enabled
                ? (isDark ? Colors.grey.shade300 : Colors.grey.shade600)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}

class _ReadingRow {
  final String id;
  final String flatNo;
  final String block;
  final String type;
  final String meterSerialNo;
  final double value;
  final String valueDisplay;
  final String date;
  final String time;
  final bool synced;

  const _ReadingRow({
    required this.id,
    required this.flatNo,
    required this.block,
    required this.type,
    required this.meterSerialNo,
    required this.value,
    required this.valueDisplay,
    required this.date,
    required this.time,
    required this.synced,
  });
}
