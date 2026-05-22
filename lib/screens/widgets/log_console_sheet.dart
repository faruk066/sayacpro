import 'package:flutter/material.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_theme.dart';

class LogConsoleSheet extends StatelessWidget {
  final DeviceProvider provider;
  final ScrollController scrollController;

  const LogConsoleSheet({
    super.key,
    required this.provider,
    required this.scrollController,
  });

  static void show(BuildContext context, DeviceProvider provider, ScrollController sc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      builder: (_) => LogConsoleSheet(provider: provider, scrollController: sc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Tutamak
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Başlık
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.terminal, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Konsol',
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${provider.logLines.length} satır',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete_sweep, color: colorScheme.onSurfaceVariant, size: 20),
                onPressed: () {
                  provider.clearLog();
                  Navigator.pop(context);
                },
                tooltip: 'Temizle',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
        // Log listesi
        Expanded(
          child: provider.logLines.isEmpty
              ? Center(
                  child: Text(
                    'Henüz log yok.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.logLines.length,
                  itemBuilder: (_, i) {
                    final line = provider.logLines[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        line,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _logColor(context, line),
                          height: 1.5,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _logColor(BuildContext context, String line) {
    final colorScheme = Theme.of(context).colorScheme;
    if (line.startsWith('❌')) return AppTheme.error;
    if (line.startsWith('✅')) return AppTheme.success;
    if (line.startsWith('📥')) return AppTheme.info;
    if (line.startsWith('📤')) return AppTheme.purple;
    if (line.startsWith('⚠️')) return AppTheme.warning;
    if (line.startsWith('🔌')) return colorScheme.primary;
    if (line.startsWith('🔴')) return AppTheme.error;
    if (line.startsWith('🔍')) return AppTheme.success;
    return colorScheme.onSurface.withValues(alpha: 0.7);
  }
}
