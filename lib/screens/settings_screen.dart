import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/device_provider.dart';

enum _SettingSection { general, connection, data, security }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingSection _activeSection = _SettingSection.general;
  bool _saved = false;

  // General
  String _language = 'tr';
  bool _autoSync = true;
  bool _soundEffects = false;
  bool _vibration = true;

  // Connection
  String _mbusBaudRate = '2400';
  bool _offlineMode = false;
  bool _autoRetry = true;

  // Data
  bool _clearOnLogout = true;

  // Security
  bool _biometric = true;
  bool _autoLock = true;
  bool _encryptLocal = true;

  void _handleSave() {
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Ayarlar',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Uygulama yapılandırması ve tercihler',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),

          // Section Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSectionTab(
                  isDark,
                  _SettingSection.general,
                  Icons.public,
                  'Genel',
                ),
                const SizedBox(width: 8),
                _buildSectionTab(
                  isDark,
                  _SettingSection.connection,
                  Icons.wifi,
                  'Bağlantı',
                ),
                const SizedBox(width: 8),
                _buildSectionTab(
                  isDark,
                  _SettingSection.data,
                  Icons.storage,
                  'Veri',
                ),
                const SizedBox(width: 8),
                _buildSectionTab(
                  isDark,
                  _SettingSection.security,
                  Icons.shield,
                  'Güvenlik',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content per section
          if (_activeSection == _SettingSection.general)
            _buildGeneralSection(isDark, themeProvider),
          if (_activeSection == _SettingSection.connection)
            _buildConnectionSection(isDark),
          if (_activeSection == _SettingSection.data) _buildDataSection(isDark),
          if (_activeSection == _SettingSection.security)
            _buildSecuritySection(isDark),
        ],
      ),
    );
  }

  // ─── SECTION TAB ──────────────────────────────────────────────

  Widget _buildSectionTab(
    bool isDark,
    _SettingSection section,
    IconData icon,
    String label,
  ) {
    final isActive = _activeSection == section;
    return InkWell(
      onTap: () => setState(() => _activeSection = section),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive
                  ? const Color(0xFF8B5CF6)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF8B5CF6)
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOGGLE ROW ───────────────────────────────────────────────

  Widget _buildToggleRow({
    required bool isDark,
    required String label,
    required String description,
    required bool value,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onToggle(),
              activeTrackColor: const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECTION CARD ─────────────────────────────────────────────

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          if (icon != null)
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            )
          else
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ─── GENERAL ──────────────────────────────────────────────────

  Widget _buildGeneralSection(bool isDark, ThemeProvider themeProvider) {
    return Column(
      children: [
        // Theme Picker
        _buildSectionCard(
          isDark: isDark,
          title: 'Tema',
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                int cols = 3;
                if (w < 400)
                  cols = 1;
                else if (w < 600)
                  cols = 2;

                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildThemeOption(
                      isDark: isDark,
                      isDarkMode: false,
                      label: 'Açık',
                      icon: Icons.light_mode,
                      gradientColors: const [
                        Color(0xFFFBBF24),
                        Color(0xFFF97316),
                      ],
                      isSelected: !themeProvider.isDarkMode,
                      onTap: () {
                        if (themeProvider.isDarkMode)
                          themeProvider.toggleTheme();
                      },
                    ),
                    _buildThemeOption(
                      isDark: isDark,
                      isDarkMode: true,
                      label: 'Koyu',
                      icon: Icons.dark_mode,
                      gradientColors: const [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                      isSelected: themeProvider.isDarkMode,
                      onTap: () {
                        if (!themeProvider.isDarkMode)
                          themeProvider.toggleTheme();
                      },
                    ),
                    _buildThemeOption(
                      isDark: isDark,
                      isDarkMode: isDark,
                      label: 'Sistem',
                      icon: Icons.desktop_windows,
                      gradientColors: const [
                        Color(0xFF9CA3AF),
                        Color(0xFF6B7280),
                      ],
                      isSelected: false,
                      onTap: () {},
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Language
        _buildSectionCard(
          isDark: isDark,
          title: 'Dil ve Bölge',
          children: [
            _buildDropdownSelect(
              isDark: isDark,
              value: _language,
              items: const [
                DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
              ],
              onChanged: (v) => setState(() => _language = v!),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Notifications
        _buildSectionCard(
          isDark: isDark,
          title: 'Bildirimler ve Ses',
          children: [
            _buildToggleRow(
              isDark: isDark,
              label: 'Otomatik Senkronizasyon',
              description: "Okumalar otomatik olarak Firestore'a gönderilir",
              value: _autoSync,
              onToggle: () => setState(() => _autoSync = !_autoSync),
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              isDark: isDark,
              label: 'Ses Efektleri',
              description: 'İşlem tamamlandığında ses çal',
              value: _soundEffects,
              onToggle: () => setState(() => _soundEffects = !_soundEffects),
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              isDark: isDark,
              label: 'Titreşim',
              description: 'Başarılı okumada titreşim bildirimi',
              value: _vibration,
              onToggle: () => setState(() => _vibration = !_vibration),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Save button
        _buildSaveButton(isDark),
      ],
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required bool isDarkMode,
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                    : const Color(0xFF8B5CF6).withValues(alpha: 0.1))
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5CF6)
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CONNECTION ───────────────────────────────────────────────

  Widget _buildConnectionSection(bool isDark) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        final isDeviceConnected = deviceProvider.isConnected;
        final portName = deviceProvider.selectedDevice != null
            ? (deviceProvider.selectedDevice?.productName ??
                  deviceProvider.selectedDevice?.deviceName ??
                  'USB')
            : 'Bağlı Değil';

        return Column(
          children: [
            // M-Bus Config
            _buildSectionCard(
              isDark: isDark,
              title: 'M-Bus Bağlantısı',
              icon: Icons.wifi,
              children: [
                _buildDropdownSelect(
                  isDark: isDark,
                  value: _mbusBaudRate,
                  items: const [
                    DropdownMenuItem(
                      value: '2400',
                      child: Text('2400 (Varsayılan)'),
                    ),
                    DropdownMenuItem(value: '4800', child: Text('4800')),
                    DropdownMenuItem(value: '9600', child: Text('9600')),
                  ],
                  onChanged: (v) => setState(() => _mbusBaudRate = v!),
                  label: 'Baud Rate',
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    int cols = 2;
                    if (w < 400) cols = 1;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 3,
                      children: [
                        _buildInfoCard(
                          isDark,
                          'Bağlantı',
                          isDeviceConnected ? 'Bağlı' : 'Bağlantı Yok',
                          isDeviceConnected
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          isDeviceConnected
                              ? Colors.green
                              : Colors.red.shade400,
                        ),
                        _buildInfoCard(
                          isDark,
                          'Port',
                          portName,
                          isDeviceConnected
                              ? Icons.usb
                              : Icons.usb_off_outlined,
                          isDeviceConnected
                              ? const Color(0xFF8B5CF6)
                              : Colors.grey,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Firebase
            _buildSectionCard(
              isDark: isDark,
              title: 'Firebase Firestore',
              icon: Icons.cloud,
              children: [
                _buildInfoCard(
                  isDark,
                  'Bölge',
                  'europe-west1',
                  Icons.public,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildToggleRow(
                  isDark: isDark,
                  label: 'Çevrimdışı Mod',
                  description: 'İnternet bağlantısı olmadan yerel depolama',
                  value: _offlineMode,
                  onToggle: () => setState(() => _offlineMode = !_offlineMode),
                ),
                const SizedBox(height: 12),
                _buildToggleRow(
                  isDark: isDark,
                  label: 'Otomatik Tekrar Dene',
                  description: 'Başarısız senkronizasyonlarda otomatik tekrar',
                  value: _autoRetry,
                  onToggle: () => setState(() => _autoRetry = !_autoRetry),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSaveButton(isDark),
          ],
        );
      },
    );
  }

  // ─── DATA ─────────────────────────────────────────────────────

  Widget _buildDataSection(bool isDark) {
    return Column(
      children: [
        // Storage Info
        _buildSectionCard(
          isDark: isDark,
          title: 'Depolama Bilgisi',
          icon: Icons.dns,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                int cols = 2;
                if (w < 400) cols = 1;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 3 : 1.8,
                  children: [
                    _buildInfoCard(
                      isDark,
                      'Önbellek',
                      '24.5 MB',
                      Icons.storage,
                      const Color(0xFF8B5CF6),
                    ),
                    _buildInfoCard(
                      isDark,
                      'Okuma Kaydı',
                      '12,847',
                      Icons.list_alt,
                      Colors.green,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Data Management
        _buildSectionCard(
          isDark: isDark,
          title: 'Veri Yönetimi',
          children: [
            _buildToggleRow(
              isDark: isDark,
              label: 'Çıkış Yapınca Temizle',
              description: 'Güvenli olmayan veriler oturum sonunda silinir',
              value: _clearOnLogout,
              onToggle: () => setState(() => _clearOnLogout = !_clearOnLogout),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Danger Zone
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFFFF5555).withValues(alpha: 0.05)
                : const Color(0xFFFF0000).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFF5555).withValues(alpha: 0.2)
                  : const Color(0xFFFF0000).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Tehlike Bölgesi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final tightWidth = constraints.maxWidth;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SizedBox(
                        width: tightWidth < 400
                            ? tightWidth
                            : (tightWidth - 8) / 2,
                        child: _buildDangerButton(
                          isDark,
                          Icons.refresh,
                          'Okumaları Sıfırla',
                          'Tüm yerel okuma kayıtları silinir',
                        ),
                      ),
                      SizedBox(
                        width: tightWidth < 400
                            ? tightWidth
                            : (tightWidth - 8) / 2,
                        child: _buildDangerButton(
                          isDark,
                          Icons.delete_forever,
                          'Tüm Verileri Temizle',
                          'Sayaç ve okuma verileri tamamen silinir',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SECURITY ─────────────────────────────────────────────────

  Widget _buildSecuritySection(bool isDark) {
    return Column(
      children: [
        // Auth
        _buildSectionCard(
          isDark: isDark,
          title: 'Kimlik Doğrulama',
          icon: Icons.lock,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.vpn_key,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'API Anahtarı',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'AIzaS...8bF2k',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
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
        const SizedBox(height: 16),

        // Security Options
        _buildSectionCard(
          isDark: isDark,
          title: 'Güvenlik',
          children: [
            _buildToggleRow(
              isDark: isDark,
              label: 'Biyometrik Doğrulama',
              description: 'Parmak izi veya yüz tanıma ile giriş',
              value: _biometric,
              onToggle: () => setState(() => _biometric = !_biometric),
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              isDark: isDark,
              label: 'Otomatik Kilit',
              description: '5 dakika hareketsizlikte oturum kilitle',
              value: _autoLock,
              onToggle: () => setState(() => _autoLock = !_autoLock),
            ),
            const SizedBox(height: 12),
            _buildToggleRow(
              isDark: isDark,
              label: 'Yerel Şifreleme',
              description: 'Hassas veriler flutter_secure_storage ile saklanır',
              value: _encryptLocal,
              onToggle: () => setState(() => _encryptLocal = !_encryptLocal),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSaveButton(isDark),
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────

  Widget _buildDropdownSelect({
    required bool isDark,
    required String value,
    required List<DropdownMenuItem<String>> items,
    ValueChanged<String?>? onChanged,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
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
              items: items,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton(
    bool isDark,
    IconData icon,
    String title,
    String description,
  ) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFFF5555).withValues(alpha: 0.1)
              : const Color(0xFFFF0000).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.red.shade200.withValues(alpha: 0.7)
                          : Colors.red.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleSave,
        icon: Icon(_saved ? Icons.check_circle : Icons.save, size: 18),
        label: Text(_saved ? 'Kaydedildi!' : 'Kaydet'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _saved ? Colors.green : const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
