import React, { createContext, useContext, useState, useCallback } from 'react';
import type { Page, Meter, Reading, StatsData, ImportResult, FlatData } from '../types';
import { mockMeters, mockReadings, mockStats, mockFlatData } from '../data/mockData';

interface AppContextType {
  currentPage: Page;
  setCurrentPage: (page: Page) => void;
  sidebarOpen: boolean;
  toggleSidebar: () => void;
  meters: Meter[];
  readings: Reading[];
  flatData: FlatData[];
  stats: StatsData;
  importResult: ImportResult | null;
  setImportResult: (result: ImportResult | null) => void;
  searchQuery: string;
  setSearchQuery: (query: string) => void;
  addReading: (reading: Reading) => void;
  updateMeterStatus: (meterId: string, status: Meter['status']) => void;
}

const AppContext = createContext<AppContextType>({
  currentPage: 'dashboard',
  setCurrentPage: () => {},
  sidebarOpen: true,
  toggleSidebar: () => {},
  meters: [],
  readings: [],
  flatData: [],
  stats: { totalMeters: 0, heatMeters: 0, waterMeters: 0, activeMeters: 0, errorMeters: 0, totalReadings: 0, syncedReadings: 0, pendingReadings: 0, todayReadings: 0, weekReadings: 0 },
  importResult: null,
  setImportResult: () => {},
  searchQuery: '',
  setSearchQuery: () => {},
  addReading: () => {},
  updateMeterStatus: () => {},
});

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currentPage, setCurrentPage] = useState<Page>('dashboard');
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [meters] = useState<Meter[]>(mockMeters);
  const [readings, setReadings] = useState<Reading[]>(mockReadings);
  const [flatData] = useState<FlatData[]>(mockFlatData);
  const [stats] = useState<StatsData>(mockStats);
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const [searchQuery, setSearchQuery] = useState('');

  const toggleSidebar = useCallback(() => setSidebarOpen((prev) => !prev), []);
  const addReading = useCallback((reading: Reading) => setReadings((prev) => [reading, ...prev]), []);
  const updateMeterStatus = useCallback((_meterId: string, _status: Meter['status']) => {}, []);

  return (
    <AppContext.Provider value={{
      currentPage, setCurrentPage, sidebarOpen, toggleSidebar,
      meters, readings, flatData, stats, importResult, setImportResult,
      searchQuery, setSearchQuery, addReading, updateMeterStatus,
    }}>
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => useContext(AppContext);
