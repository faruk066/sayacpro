import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';
import '../../providers/device_provider.dart';
import '../../theme/app_theme.dart';

class ConnectionCard extends StatelessWidget {
  final DeviceProvider provider;

  const ConnectionCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Top USB Selection Area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary.withValues(alpha: 0.08), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.usb_rounded, color: colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: provider.devices.isEmpty
                            ? Text('USB cihaz bulunamadı',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant))
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<UsbDevice>(
                                  value: provider.selectedDevice,
                                  dropdownColor: colorScheme.surfaceContainerHigh,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface),
                                  isExpanded: true,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
                                  items: provider.devices.map((d) {
                                    return DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d.productName ?? d.deviceName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (d) {
                                    if (d != null) provider.selectDevice(d);
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatusChip(context, provider.status, provider.baudRate),
                      const Spacer(),
                      _buildConnectButton(context, provider),
                    ],
                  ),
                ],
              ),
            ),
            
            Divider(height: 1, thickness: 1, color: colorScheme.onSurface.withValues(alpha: 0.05)),
            
            // Settings Area
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Baud Rate & Mode
                  Row(
                    children: [
                      Expanded(
                        child: _buildSettingField(
                          context: context,
                          label: 'Baud Rate',
                          child: _buildMiniDropdown<int>(
                            context: context,
                            value: provider.baudRate,
                            items: const [
                              DropdownMenuItem(value: 300, child: Text('300')),
                              DropdownMenuItem(value: 2400, child: Text('2400')),
                              DropdownMenuItem(value: 9600, child: Text('9600')),
                            ],
                            onChanged: provider.isConnected
                                ? null
                                : (v) { if (v != null) provider.setBaudRate(v); },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSettingField(
                          context: context,
                          label: 'Okuma Modu',
                          child: _buildMiniDropdown<ReadingMode>(
                            context: context,
                            value: provider.selectedReadingMode,
                            items: const [
                              DropdownMenuItem(value: ReadingMode.heat, child: Text('Sadece Isı')),
                              DropdownMenuItem(value: ReadingMode.water, child: Text('Sadece Su')),
                              DropdownMenuItem(value: ReadingMode.both, child: Text('Her İkisi')),
                            ],
                            onChanged: provider.isReading
                                ? null
                                : (v) { if (v != null) provider.setReadingMode(v); },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Adres
                  _buildSettingField(
                    context: context,
                    label: 'Adresleme',
                    child: _buildMiniDropdown<MBusCommandOption>(
                      context: context,
                      value: provider.selectedCommand,
                      items: provider.addressOptions.map((opt) {
                        return DropdownMenuItem(
                          value: opt,
                          child: Text(opt.label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: provider.isReading
                          ? null
                          : (v) { if (v != null) provider.setSelectedCommand(v); },
                    ),
                  ),

                  // Birincil Adres Tarama
                  if (provider.selectedCommand.label == 'Birincil Adres ile Tara (0-250)') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSettingField(
                            context: context,
                            label: 'Başlangıç',
                            child: _buildNumberInput(
                              context: context,
                              hint: '1',
                              onChanged: (v) {
                                final val = int.tryParse(v);
                                if (val != null) provider.setPrimaryStart(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSettingField(
                            context: context,
                            label: 'Bitiş',
                            child: _buildNumberInput(
                              context: context,
                              hint: '50',
                              onChanged: (v) {
                                final val = int.tryParse(v);
                                if (val != null) provider.setPrimaryEnd(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingField({required BuildContext context, required String label, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, ConnectionStatus status, int baudRate) {
    final theme = Theme.of(context);
    String text;
    Color color;
    switch (status) {
      case ConnectionStatus.disconnected:
        text = 'Bağlı Değil'; color = theme.colorScheme.onSurfaceVariant;
        break;
      case ConnectionStatus.connecting:
        text = 'Bağlanıyor...'; color = AppTheme.warning;
        break;
      case ConnectionStatus.connected:
        text = 'Bağlı — $baudRate'; color = AppTheme.success;
        break;
      case ConnectionStatus.error:
        text = 'Hata'; color = theme.colorScheme.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: color,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildConnectButton(BuildContext context, DeviceProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnecting = provider.status == ConnectionStatus.connecting;
    final isConnected = provider.isConnected;

    return SizedBox(
      height: 38,
      child: ElevatedButton.icon(
        onPressed: isConnecting
            ? null
            : isConnected
                ? () => provider.disconnect()
                : () => provider.connect(),
        icon: isConnecting
            ? SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.onPrimary),
              )
            : Icon(isConnected ? Icons.link_off_rounded : Icons.link_rounded, size: 18),
        label: Text(
          isConnected ? 'Kopart' : 'Bağlan',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? colorScheme.error : colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildMiniDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: colorScheme.surfaceContainerHigh,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary, size: 24),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildNumberInput({
    required BuildContext context,
    required String hint,
    required void Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: TextField(
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.3)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

