import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'dashboard_screen.dart';
import 'meters_screen.dart';
import 'import_screen.dart';
import 'export_screen.dart';
import 'readings_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _sidebarOpen = true;
  String _currentPage = 'dashboard';

  void _toggleSidebar() {
    setState(() {
      _sidebarOpen = !_sidebarOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: Drawer(
              child: SafeArea(child: _buildSidebar(isDark, isMobile: true)),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark, isMobile: true),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Row(
                children: [
                  _buildSidebar(isDark, isMobile: false),
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(isDark, isMobile: false),
                        Expanded(child: _buildBody()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSidebar(bool isDark, {required bool isMobile}) {
    final width = isMobile ? 280.0 : (_sidebarOpen ? 280.0 : 80.0);
    final isExpanded = isMobile || _sidebarOpen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sayaç Pro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        'M-Bus Yönetim',
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
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildNavItem(
                  'dashboard',
                  'Dashboard',
                  Icons.dashboard_outlined,
                  'Genel Bakış',
                  isDark,
                  isExpanded,
                ),
                _buildNavItem(
                  'meters',
                  'Sayaçlar',
                  Icons.speed_outlined,
                  'Sayaç Yönetimi',
                  isDark,
                  isExpanded,
                ),
                _buildNavItem(
                  'readings',
                  'Okumalar',
                  Icons.list_alt_outlined,
                  'Okuma Kayıtları',
                  isDark,
                  isExpanded,
                ),
                _buildNavItem(
                  'import',
                  'Excel İçe Aktar',
                  Icons.table_chart_outlined,
                  'Veri Aktarımı',
                  isDark,
                  isExpanded,
                ),
                _buildNavItem(
                  'export',
                  'Dışa Aktar',
                  Icons.download_outlined,
                  'CSV/Excel Çıktısı',
                  isDark,
                  isExpanded,
                ),
                _buildNavItem(
                  'settings',
                  'Ayarlar',
                  Icons.settings_outlined,
                  'Yapılandırma',
                  isDark,
                  isExpanded,
                ),
              ],
            ),
          ),

          // Toggle Button
          if (!isMobile)
            InkWell(
              onTap: _toggleSidebar,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(
                    _sidebarOpen ? Icons.chevron_left : Icons.chevron_right,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String id,
    String label,
    IconData icon,
    String description,
    bool isDark,
    bool isExpanded,
  ) {
    final isActive = _currentPage == id;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = id;
        });
        // In mobile view, close the drawer when a navigation item is tapped
        if (Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive
              ? (isDark
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                    : const Color(0xFF8B5CF6).withValues(alpha: 0.1))
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? const Color(0xFF8B5CF6)
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF8B5CF6)
                            : (isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700),
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive
                            ? const Color(0xFF8B5CF6).withValues(alpha: 0.7)
                            : (isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, {required bool isMobile}) {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0B1120).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: isDark ? Colors.white : Colors.grey.shade900,
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
              ],
              // Search
              if (!isMobile)
                Container(
                  width: 280,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Sayaç, daire veya blok ara...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(bottom: 12),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade200
                                : Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Right side actions
          Row(
            children: [
              // Theme Toggle
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: themeProvider.isDarkMode
                          ? Colors.yellow.shade400
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () => themeProvider.toggleTheme(),
                  );
                },
              ),

              // Notifications
              IconButton(
                icon: Stack(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {},
              ),

              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              ),
              const SizedBox(width: 16),

              // User Profile
              Row(
                children: [
                  if (!isMobile) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'Teknisyen',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentPage) {
      case 'dashboard':
        return const DashboardScreen();
      case 'meters':
        return const MetersScreen();
      case 'readings':
        return const ReadingsScreen();
      case 'import':
        return const ImportScreen();
      case 'export':
        return const ExportScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return Center(child: Text('Sayfa Yapım Aşamasında: $_currentPage'));
    }
  }
}
