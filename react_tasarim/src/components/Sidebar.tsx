import React from 'react';
import { useTheme } from '../contexts/ThemeContext';
import { useApp } from '../contexts/AppContext';
import type { Page } from '../types';
import {
  LayoutDashboard,
  Gauge,
  ClipboardList,
  FileSpreadsheet,
  Download,
  Settings,
  ChevronLeft,
  ChevronRight,
  ThermometerSnowflake,
  Droplet,
  Wifi,
  WifiOff,
  Zap,
} from 'lucide-react';

const menuItems: { id: Page; label: string; icon: React.FC<{ className?: string }>; description: string }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, description: 'Genel Bakış' },
  { id: 'meters', label: 'Sayaçlar', icon: Gauge, description: 'Sayaç Yönetimi' },
  { id: 'readings', label: 'Okumalar', icon: ClipboardList, description: 'Okuma Kayıtları' },
  { id: 'import', label: 'Excel İçe Aktar', icon: FileSpreadsheet, description: 'Veri Aktarımı' },
  { id: 'export', label: 'Dışa Aktar', icon: Download, description: 'CSV/Excel Çıktısı' },
  { id: 'settings', label: 'Ayarlar', icon: Settings, description: 'Yapılandırma' },
];

export const Sidebar: React.FC = () => {
  const { theme } = useTheme();
  const { currentPage, setCurrentPage, sidebarOpen, toggleSidebar, stats } = useApp();
  const isDark = theme === 'dark';

  return (
    <div className="relative">
      <aside className={`fixed top-0 left-0 z-40 h-full transition-all duration-300 ease-in-out flex flex-col ${
        isDark ? 'bg-dark-bg border-r border-dark-border' : 'bg-white border-r border-gray-200'
      } ${sidebarOpen ? 'w-72' : 'w-20'}`}>
        {/* Logo */}
        <div className={`flex items-center h-16 px-4 border-b ${isDark ? 'border-dark-border' : 'border-gray-200'} ${!sidebarOpen ? 'justify-center' : ''}`}>
          <div className="flex items-center gap-3">
            <div className="relative flex-shrink-0">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center shadow-lg shadow-primary-500/20">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <div className="absolute -top-0.5 -right-0.5 w-3 h-3 bg-green-400 rounded-full border-2 border-dark-bg animate-pulse-dot" />
            </div>
            {sidebarOpen && (
              <div className="animate-fade-in">
                <h1 className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>Sayaç Pro</h1>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>M-Bus Yönetim</p>
              </div>
            )}
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto scrollbar-thin">
          {menuItems.map((item, index) => {
            const isActive = currentPage === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentPage(item.id)}
                className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 group relative ${
                  sidebarOpen ? '' : 'justify-center'
                } ${
                  isActive
                    ? isDark ? 'bg-primary-600/20 text-primary-400 shadow-sm' : 'bg-primary-50 text-primary-600 shadow-sm'
                    : isDark ? 'text-gray-400 hover:bg-dark-card hover:text-gray-200' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                }`}
                style={{ animationDelay: `${index * 50}ms` }}
                title={item.label}
              >
                <item.icon className="w-5 h-5 flex-shrink-0" />
                {sidebarOpen && (
                  <div className="flex-1 text-left animate-fade-in">
                    <span className="text-sm font-medium">{item.label}</span>
                    <p className={`text-[10px] ${isActive ? 'text-primary-400/70' : isDark ? 'text-gray-500' : 'text-gray-400'}`}>{item.description}</p>
                  </div>
                )}
                {sidebarOpen && isActive && (
                  <div className="w-1.5 h-6 rounded-full bg-primary-500 animate-scale-in" />
                )}
                {!sidebarOpen && (
                  <div className={`absolute left-full ml-2 px-2 py-1 rounded-lg text-xs font-medium whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none z-50 ${isDark ? 'bg-dark-card text-white' : 'bg-gray-800 text-white'}`}>{item.label}</div>
                )}
              </button>
            );
          })}
        </nav>

        {/* Device Status */}
        {sidebarOpen && (
          <div className={`mx-3 mb-2 p-3 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
            <div className="flex items-center gap-2 mb-2">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse-dot" />
              <span className={`text-xs font-medium ${isDark ? 'text-gray-300' : 'text-gray-700'}`}>M-Bus Bağlantısı</span>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <div className={`flex items-center gap-1.5 px-2 py-1 rounded-lg ${isDark ? 'bg-dark-bg' : 'bg-white'}`}>
                <ThermometerSnowflake className="w-3.5 h-3.5 text-heat-500" />
                <span className={`text-xs ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{stats.heatMeters} Isı</span>
              </div>
              <div className={`flex items-center gap-1.5 px-2 py-1 rounded-lg ${isDark ? 'bg-dark-bg' : 'bg-white'}`}>
                <Droplet className="w-3.5 h-3.5 text-water-500" />
                <span className={`text-xs ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{stats.waterMeters} Su</span>
              </div>
              <div className={`flex items-center gap-1.5 px-2 py-1 rounded-lg ${isDark ? 'bg-dark-bg' : 'bg-white'}`}>
                <Wifi className="w-3.5 h-3.5 text-green-500" />
                <span className={`text-xs ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{stats.activeMeters} Aktif</span>
              </div>
              <div className={`flex items-center gap-1.5 px-2 py-1 rounded-lg ${isDark ? 'bg-dark-bg' : 'bg-white'}`}>
                <WifiOff className="w-3.5 h-3.5 text-red-500" />
                <span className={`text-xs ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{stats.errorMeters} Hata</span>
              </div>
            </div>
          </div>
        )}

        {/* Toggle */}
        <button
          onClick={toggleSidebar}
          className={`flex items-center justify-center h-12 border-t transition-colors ${isDark ? 'border-dark-border hover:bg-dark-card text-gray-400' : 'border-gray-200 hover:bg-gray-100 text-gray-600'}`}
          title={sidebarOpen ? 'Daralt' : 'Genişlet'}
        >
          {sidebarOpen ? <ChevronLeft className="w-5 h-5" /> : <ChevronRight className="w-5 h-5" />}
        </button>
      </aside>
    </div>
  );
};
