import React from 'react';
import { ThemeProvider } from './contexts/ThemeContext';
import { AppProvider, useApp } from './contexts/AppContext';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { DashboardPage } from './pages/DashboardPage';
import { MetersPage } from './pages/MetersPage';
import { ReadingsPage } from './pages/ReadingsPage';
import { ImportPage } from './pages/ImportPage';
import { ExportPage } from './pages/ExportPage';
import { SettingsPage } from './pages/SettingsPage';
import { useTheme } from './contexts/ThemeContext';

const PageRouter: React.FC = () => {
  const { currentPage } = useApp();

  switch (currentPage) {
    case 'dashboard': return <DashboardPage />;
    case 'meters': return <MetersPage />;
    case 'readings': return <ReadingsPage />;
    case 'import': return <ImportPage />;
    case 'export': return <ExportPage />;
    case 'settings': return <SettingsPage />;
    default: return <DashboardPage />;
  }
};

const MobileNav: React.FC = () => {
  const { theme } = useTheme();
  const { currentPage, setCurrentPage } = useApp();
  const isDark = theme === 'dark';

  const navItems = [
    { id: 'dashboard' as const, label: 'Dashboard', icon: '📊' },
    { id: 'meters' as const, label: 'Sayaçlar', icon: '🔧' },
    { id: 'readings' as const, label: 'Okumalar', icon: '📋' },
    { id: 'import' as const, label: 'İçe Aktar', icon: '📥' },
    { id: 'settings' as const, label: 'Ayarlar', icon: '⚙️' },
  ];

  return (
    <div className={`lg:hidden fixed bottom-0 left-0 right-0 z-30 h-16 border-t ${
      isDark ? 'bg-dark-bg/90 border-dark-border backdrop-blur-xl' : 'bg-white/90 border-gray-200 backdrop-blur-xl'
    }`}>
      <div className="flex items-center justify-around h-full px-2">
        {navItems.map((item) => (
          <button
            key={item.id}
            onClick={() => setCurrentPage(item.id)}
            className={`flex flex-col items-center gap-0.5 px-3 py-1 rounded-lg transition-colors ${
              currentPage === item.id
                ? 'text-primary-500'
                : isDark ? 'text-gray-400' : 'text-gray-500'
            }`}
          >
            <span className="text-lg">{item.icon}</span>
            <span className="text-[10px] font-medium">{item.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

const AppContent: React.FC = () => {
  const { theme } = useTheme();
  const { sidebarOpen } = useApp();
  const isDark = theme === 'dark';

  return (
    <div className={`min-h-screen transition-colors duration-300 ${isDark ? 'bg-dark-bg' : 'bg-gray-50'}`}>
      <Sidebar />
      <div
        className="transition-all duration-300 min-h-screen"
        style={{ marginLeft: sidebarOpen ? '18rem' : '5rem' }}
      >
        <Header />
        <main className="pt-16 px-6 py-6">
          <PageRouter />
        </main>
        <MobileNav />
        <div className="lg:hidden h-16" />
      </div>
    </div>
  );
};

const App: React.FC = () => {
  return (
    <ThemeProvider>
      <AppProvider>
        <AppContent />
      </AppProvider>
    </ThemeProvider>
  );
};

export default App;
