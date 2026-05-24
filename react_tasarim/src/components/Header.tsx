import React from 'react';
import { useTheme } from '../contexts/ThemeContext';
import { useApp } from '../contexts/AppContext';
import {
  Search,
  Sun,
  Moon,
  Bell,
  Menu,
  User,
} from 'lucide-react';

export const Header: React.FC = () => {
  const { theme, toggleTheme } = useTheme();
  const { sidebarOpen, toggleSidebar, searchQuery, setSearchQuery } = useApp();
  const isDark = theme === 'dark';

  return (
    <header className={`fixed top-0 right-0 z-30 h-16 transition-all duration-300 ${
      isDark ? 'bg-dark-bg/80 border-b border-dark-border' : 'bg-white/80 border-b border-gray-200'
    } backdrop-blur-xl`} style={{ left: sidebarOpen ? '18rem' : '5rem' }}>
      <div className="flex items-center justify-between h-full px-6">
        {/* Left side */}
        <div className="flex items-center gap-4">
          <button
            onClick={toggleSidebar}
            className={`lg:hidden p-2 rounded-lg transition-colors ${isDark ? 'hover:bg-dark-card text-gray-400' : 'hover:bg-gray-100 text-gray-600'}`}
            title="Menü"
          >
            <Menu className="w-5 h-5" />
          </button>
          {/* Search */}
          <div className={`relative hidden sm:block`}>
            <Search className={`absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 ${isDark ? 'text-gray-500' : 'text-gray-400'}`} />
            <input
              type="text"
              placeholder="Sayaç, daire veya blok ara..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className={`pl-10 pr-4 py-2 w-72 rounded-xl text-sm transition-colors outline-none ${
                isDark
                  ? 'bg-dark-card border border-dark-border text-gray-200 placeholder-gray-500 focus:border-primary-500 focus:ring-1 focus:ring-primary-500/20'
                  : 'bg-gray-100 border border-gray-200 text-gray-900 placeholder-gray-400 focus:border-primary-500 focus:ring-1 focus:ring-primary-500/20'
              }`}
            />
          </div>
        </div>

        {/* Right side */}
        <div className="flex items-center gap-2">
          {/* Theme toggle */}
          <button
            onClick={toggleTheme}
            className={`p-2.5 rounded-xl transition-colors ${isDark ? 'hover:bg-dark-card text-yellow-400' : 'hover:bg-gray-100 text-gray-600'}`}
            title={isDark ? 'Açık Tema' : 'Koyu Tema'}
          >
            {isDark ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          </button>

          {/* Notifications */}
          <button
            className={`relative p-2.5 rounded-xl transition-colors ${isDark ? 'hover:bg-dark-card text-gray-400' : 'hover:bg-gray-100 text-gray-600'}`}
            title="Bildirimler"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full animate-pulse-dot" />
          </button>

          {/* User */}
          <div className={`flex items-center gap-3 ml-2 pl-4 border-l ${isDark ? 'border-dark-border' : 'border-gray-200'}`}>
            <div className="hidden sm:block text-right">
              <p className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>Admin</p>
              <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Teknisyen</p>
            </div>
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center">
              <User className="w-4 h-4 text-white" />
            </div>
          </div>
        </div>
      </div>
    </header>
  );
};
