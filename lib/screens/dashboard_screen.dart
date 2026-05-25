import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_data_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AppDataProvider>(
      builder: (context, provider, child) {
        final meters = provider.meterList;

        int totalMeters = meters.length;
        int heatMeters = meters.where((m) => m.type.name == 'heat' || m.heatMeterId.isNotEmpty).length;
        int waterMeters = meters.where((m) => m.type.name == 'water' || m.waterMeterId.isNotEmpty).length;
        int errorMeters = meters.where((m) => m.overallStatus.name == 'failed').length;

        int syncedReadings = meters.where((m) => m.overallStatus.name == 'success').length;
        int pendingReadings = totalMeters - syncedReadings - errorMeters;
        if (pendingReadings < 0) pendingReadings = 0;
        int todayReadings = syncedReadings;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Genel Bakış',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        'Sistem durumu ve okuma özetleri',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Son 30 Gün',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (meters.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200, style: BorderStyle.solid, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Henüz veri yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade900)),
                      const SizedBox(height: 8),
                      Text('Excel içe aktararak veya cihaz bağlayarak başlayın.', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                    ],
                  ),
                ),

              if (meters.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount = 4;
                  if (width < 600) {
                    crossAxisCount = 1;
                  } else if (width < 900) {
                    crossAxisCount = 2;
                  }

                  return Column(
                    children: [
                      // Overview Cards
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: width < 600 ? 2.5 : 1.5,
                        children: [
                          _buildStatCard(context, 'Toplam Sayaç', totalMeters.toString(), Icons.speed, Colors.purple, '+12', true),
                          _buildStatCard(context, 'Isı Sayacı', heatMeters.toString(), Icons.local_fire_department, Colors.orange, '+5', true),
                          _buildStatCard(context, 'Su Sayacı', waterMeters.toString(), Icons.water_drop, Colors.blue, '+7', true),
                          _buildStatCard(context, 'Hatalı', errorMeters.toString(), Icons.warning_amber_rounded, Colors.red, '-2', false),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Charts Row
                      if (width < 900) ...[
                        _buildBarChartCard(context),
                        const SizedBox(height: 16),
                        _buildPieChartCard(context, syncedReadings, pendingReadings, errorMeters),
                        const SizedBox(height: 16),
                        _buildLineChartCard(context),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildBarChartCard(context),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _buildPieChartCard(context, syncedReadings, pendingReadings, errorMeters),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 4,
                              child: _buildLineChartCard(context),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Recent Readings Table
                      _buildRecentReadingsTable(context, meters),
                      const SizedBox(height: 24),

                      // Quick Stats Bar
                      GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: width < 600 ? 3.5 : 2.5,
                        children: [
                          _buildQuickStat(context, syncedReadings.toString(), 'Senkronize', Icons.check_circle, Colors.green),
                          _buildQuickStat(context, pendingReadings.toString(), 'Bekleyen', Icons.access_time, Colors.orange),
                          _buildQuickStat(context, errorMeters.toString(), 'Hatalı', Icons.error_outline, Colors.red),
                          _buildQuickStat(context, todayReadings.toString(), 'Bugün', Icons.show_chart, Colors.purple),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, String trend, bool isPositive) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Okuma İstatistiği',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aylık okunan sayaç türleri',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(fontSize: 10);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('Oca', style: style); break;
                          case 1: text = const Text('Şub', style: style); break;
                          case 2: text = const Text('Mar', style: style); break;
                          case 3: text = const Text('Nis', style: style); break;
                          case 4: text = const Text('May', style: style); break;
                          case 5: text = const Text('Haz', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 65, 45),
                  _makeGroupData(1, 59, 40),
                  _makeGroupData(2, 80, 55),
                  _makeGroupData(3, 81, 60),
                  _makeGroupData(4, 56, 42),
                  _makeGroupData(5, 55, 38),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: const Color(0xFFEF4444),
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: y2,
          color: const Color(0xFF3B82F6),
          width: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(BuildContext context, int synced, int pending, int error) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fallback data if everything is 0
    if (synced == 0 && pending == 0 && error == 0) pending = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Senkronizasyon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Veri durumları',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: synced.toDouble(),
                    title: '',
                    radius: 20,
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pending.toDouble(),
                    title: '',
                    radius: 20,
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: error.toDouble(),
                    title: '',
                    radius: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPieLegendItem('Senkronize', synced.toString(), Colors.green, isDark),
              _buildPieLegendItem('Bekliyor', pending.toString(), Colors.orange, isDark),
              _buildPieLegendItem('Hata', error.toString(), Colors.red, isDark),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPieLegendItem(String label, String value, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChartCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Okuma Trendi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Haftalık okuma sayısı',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(fontSize: 10);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('Pzt', style: style); break;
                          case 1: text = const Text('Sal', style: style); break;
                          case 2: text = const Text('Çar', style: style); break;
                          case 3: text = const Text('Per', style: style); break;
                          case 4: text = const Text('Cum', style: style); break;
                          case 5: text = const Text('Cmt', style: style); break;
                          case 6: text = const Text('Paz', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 45),
                      FlSpot(1, 52),
                      FlSpot(2, 48),
                      FlSpot(3, 70),
                      FlSpot(4, 85),
                      FlSpot(5, 65),
                      FlSpot(6, 90),
                    ],
                    isCurved: true,
                    color: const Color(0xFF8B5CF6),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReadingsTable(BuildContext context, List<dynamic> meters) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sort or get latest from meters. We just take first 5.
    final recentMeters = meters.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Son Okumalar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'En son yapılan sayaç okumaları',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.show_chart, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Canlı',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.green.shade400 : Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              ),
              columns: [
                DataColumn(label: Text('Daire', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                DataColumn(label: Text('Tip', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                DataColumn(label: Text('Sayaç No', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                DataColumn(label: Text('Değer', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                DataColumn(label: Text('Tarih', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                DataColumn(label: Text('Durum', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
              ],
              rows: recentMeters.map((m) {
                final String overallStatusName = (m.overallStatus?.name ?? 'pending') as String;
                final isSuccess = overallStatusName == 'success';

                // Determine representation based on what is available
                String typeStr = 'Isı';
                String meterId = (m.heatMeterId ?? '') as String;
                String valueStr = (m.getHeatIndexDisplay() ?? '-') as String;
                IconData typeIcon = Icons.local_fire_department;
                Color typeColor = Colors.orange;

                final String heatId = (m.heatMeterId ?? '') as String;
                final String waterId = (m.waterMeterId ?? '') as String;
                if (heatId.isEmpty && waterId.isNotEmpty) {
                  typeStr = 'Su';
                  meterId = waterId;
                  valueStr = (m.getWaterIndexDisplay() ?? '-') as String;
                  typeIcon = Icons.water_drop;
                  typeColor = Colors.blue;
                }

                String dateStr = '-';
                final DateTime? readTime = m.readTime as DateTime?;
                if (readTime != null) {
                  dateStr = '${readTime.day.toString().padLeft(2, '0')}.${readTime.month.toString().padLeft(2, '0')} ${readTime.hour.toString().padLeft(2, '0')}:${readTime.minute.toString().padLeft(2, '0')}';
                }

                return DataRow(
                  cells: [
                    DataCell(Text(m.flatNo ?? '-', style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade900, fontWeight: FontWeight.w500))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 12, color: typeColor),
                            const SizedBox(width: 4),
                            Text(typeStr, style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text(meterId, style: TextStyle(fontFamily: 'monospace', color: isDark ? Colors.grey.shade300 : Colors.grey.shade600))),
                    DataCell(Text(valueStr, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey.shade900))),
                    DataCell(Text(dateStr, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500))),
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle : Icons.warning,
                            size: 16,
                            color: isSuccess ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSuccess ? 'Başarılı' : 'Bekliyor/Hata',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSuccess ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      )
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String value, String label, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}