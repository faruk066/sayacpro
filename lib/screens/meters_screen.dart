import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meter_data.dart';
import '../providers/app_data_provider.dart';

class MetersScreen extends StatefulWidget {
  const MetersScreen({super.key});

  @override
  State<MetersScreen> createState() => _MetersScreenState();
}

class _MetersScreenState extends State<MetersScreen> {
  String _filterType = 'all'; // all, heat, water
  String _filterStatus = 'all'; // all, active, pending, error
  String _viewMode = 'list'; // list, grid

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AppDataProvider>(
      builder: (context, provider, child) {
        final meters = provider.meterList;

        final filteredMeters = meters.where((m) {
          if (_filterType == 'heat') {
            if (m.type.name != 'heat' && m.heatMeterId.isEmpty) return false;
          } else if (_filterType == 'water') {
            if (m.type.name != 'water' && m.waterMeterId.isEmpty) return false;
          }

          final isSuccess = m.overallStatus.name == 'success';
          final isError = m.overallStatus.name == 'failed';
          if (_filterStatus == 'active' && !isSuccess) return false;
          if (_filterStatus == 'error' && !isError) return false;
          if (_filterStatus == 'pending' && (isSuccess || isError))
            return false;

          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sayaç Yönetimi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'Tüm sayaçlarınızı görüntüleyin ve yönetin',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.grid_view,
                                color: _viewMode == 'grid'
                                    ? const Color(0xFF8B5CF6)
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _viewMode = 'grid'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.list,
                                color: _viewMode == 'list'
                                    ? const Color(0xFF8B5CF6)
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _viewMode = 'list'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Yenile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filters
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  if (width < 600) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                isDark,
                                'Tip Seçimi',
                                ['all', 'heat', 'water'],
                                ['Tüm Tipler', 'Isı Sayacı', 'Su Sayacı'],
                                _filterType,
                                (val) => setState(() => _filterType = val!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                isDark,
                                'Durum',
                                ['all', 'active', 'pending', 'error'],
                                [
                                  'Tüm Durumlar',
                                  'Aktif/Başarılı',
                                  'Beklemede',
                                  'Hata',
                                ],
                                _filterStatus,
                                (val) => setState(() => _filterStatus = val!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildQuickTag('all', 'Tümü', isDark),
                            _buildQuickTag('heat', 'Isı', isDark),
                            _buildQuickTag('water', 'Su', isDark),
                          ],
                        ),
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildDropdown(
                        isDark,
                        'Tip Seçimi',
                        ['all', 'heat', 'water'],
                        ['Tüm Tipler', 'Isı Sayacı', 'Su Sayacı'],
                        _filterType,
                        (val) => setState(() => _filterType = val!),
                      ),
                      _buildDropdown(
                        isDark,
                        'Durum',
                        ['all', 'active', 'pending', 'error'],
                        ['Tüm Durumlar', 'Aktif/Başarılı', 'Beklemede', 'Hata'],
                        _filterStatus,
                        (val) => setState(() => _filterStatus = val!),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickTag('all', 'Tümü', isDark),
                      _buildQuickTag('heat', 'Isı', isDark),
                      _buildQuickTag('water', 'Su', isDark),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              if (meters.isEmpty)
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
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.speed_outlined,
                        size: 48,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz sayaç yok',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Excel içe aktararak veya cihaz bağlayarak başlayın.',
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

              // Content
              if (meters.isNotEmpty)
                _viewMode == 'grid'
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 4;
                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 900) {
                            crossAxisCount = 2;
                          } else if (constraints.maxWidth < 1200) {
                            crossAxisCount = 3;
                          }
                          return _buildGridView(
                            filteredMeters,
                            isDark,
                            crossAxisCount,
                          );
                        },
                      )
                    : _buildListView(filteredMeters, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(
    bool isDark,
    String hint,
    List<String> values,
    List<String> labels,
    String currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
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
            fontSize: 14,
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade700,
          ),
          onChanged: onChanged,
          items: List.generate(values.length, (index) {
            return DropdownMenuItem<String>(
              value: values[index],
              child: Text(labels[index]),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildQuickTag(String type, String label, bool isDark) {
    final isActive = _filterType == type;
    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8B5CF6)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(
    List<MeterData> meters,
    bool isDark,
    int crossAxisCount,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: meters.length,
      itemBuilder: (context, index) {
        final m = meters[index];
        final overallStatusName = m.overallStatus.name;
        final isSuccess = overallStatusName == 'success';
        final isError = overallStatusName == 'failed';

        String typeStr = 'Isı';
        String meterId = m.heatMeterId;
        String valueStr = m.getHeatIndexDisplay();
        IconData typeIcon = Icons.local_fire_department;
        Color typeColor = Colors.orange;

        if (m.heatMeterId.isEmpty && m.waterMeterId.isNotEmpty) {
          typeStr = 'Su';
          meterId = m.waterMeterId;
          valueStr = m.getWaterIndexDisplay();
          typeIcon = Icons.water_drop;
          typeColor = Colors.blue;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1120) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(typeIcon, size: 16, color: typeColor),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meterId.isEmpty ? 'Bilinmiyor' : meterId,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            typeStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withValues(alpha: 0.1)
                          : (isError
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSuccess
                              ? Icons.wifi
                              : (isError ? Icons.warning : Icons.access_time),
                          size: 12,
                          color: isSuccess
                              ? Colors.green
                              : (isError ? Colors.red : Colors.orange),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSuccess
                              ? 'Aktif'
                              : (isError ? 'Hata' : 'Beklemede'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSuccess
                                ? Colors.green
                                : (isError ? Colors.red : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(),
              const SizedBox(height: 8),
              _buildGridRow('Blok/Daire', m.flatNo, isDark),
              const SizedBox(height: 4),
              _buildGridRow('Son Okuma', valueStr, isDark, isValueBold: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridRow(
    String label,
    String value,
    bool isDark, {
    bool isValueBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isValueBold ? FontWeight.bold : FontWeight.w500,
            color: isDark ? Colors.white : Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildListView(List<MeterData> meters, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
            ),
            columnSpacing: 24,
            columns: const [
              DataColumn(
                label: Text(
                  'Durum',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Sayaç No',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tip',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Daire',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Son Okuma',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Tarih',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            rows: meters.map((m) {
              final overallStatusName = m.overallStatus.name;
              final isSuccess = overallStatusName == 'success';
              final isError = overallStatusName == 'failed';

              String typeStr = 'Isı';
              String meterId = m.heatMeterId;
              String valueStr = m.getHeatIndexDisplay();
              IconData typeIcon = Icons.local_fire_department;
              Color typeColor = Colors.orange;

              if (m.heatMeterId.isEmpty && m.waterMeterId.isNotEmpty) {
                typeStr = 'Su';
                meterId = m.waterMeterId;
                valueStr = m.getWaterIndexDisplay();
                typeIcon = Icons.water_drop;
                typeColor = Colors.blue;
              }

              final readTime = m.readTime;
              String dateStr = '-';
              if (readTime != null) {
                dateStr =
                    '${readTime.day.toString().padLeft(2, '0')}.${readTime.month.toString().padLeft(2, '0')} ${readTime.hour.toString().padLeft(2, '0')}:${readTime.minute.toString().padLeft(2, '0')}';
              }

              return DataRow(
                cells: [
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? Colors.green.withValues(alpha: 0.1)
                            : (isError
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSuccess
                                ? Icons.wifi
                                : (isError ? Icons.warning : Icons.access_time),
                            size: 12,
                            color: isSuccess
                                ? Colors.green
                                : (isError ? Colors.red : Colors.orange),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSuccess
                                ? 'Aktif'
                                : (isError ? 'Hata' : 'Beklemede'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSuccess
                                  ? Colors.green
                                  : (isError ? Colors.red : Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      meterId.isEmpty ? 'Bilinmiyor' : meterId,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: isDark ? Colors.white : Colors.grey.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 16, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          typeStr,
                          style: TextStyle(fontSize: 14, color: typeColor),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      m.flatNo,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      valueStr,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
