import React, { useMemo, useState } from 'react';
import { useTheme } from '../contexts/ThemeContext';
import { useApp } from '../contexts/AppContext';
import type { Meter, MeterStatus } from '../types';
import {
  ThermometerSnowflake,
  Droplet,
  Wifi,
  AlertTriangle,
  PauseCircle,
  Filter,
  ChevronDown,
  Grid3X3,
  List,
  RefreshCw,
} from 'lucide-react';

const statusConfig: Record<MeterStatus, { label: string; bg: string; text: string; icon: React.FC<{ className?: string }> }> = {
  active: { label: 'Aktif', bg: 'bg-green-500/10', text: 'text-green-500', icon: Wifi },
  inactive: { label: 'Pasif', bg: 'bg-gray-500/10', text: 'text-gray-500', icon: PauseCircle },
  error: { label: 'Hata', bg: 'bg-red-500/10', text: 'text-red-500', icon: AlertTriangle },
  pending: { label: 'Beklemede', bg: 'bg-yellow-500/10', text: 'text-yellow-500', icon: RefreshCw },
};

export const MetersPage: React.FC = () => {
  const { theme } = useTheme();
  const { meters, searchQuery } = useApp();
  const isDark = theme === 'dark';

  const [filterType, setFilterType] = useState<'all' | 'heat' | 'water'>('all');
  const [filterStatus, setFilterStatus] = useState<'all' | MeterStatus>('all');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [selectedMeter, setSelectedMeter] = useState<Meter | null>(null);

  const filteredMeters = useMemo(() => {
    return meters.filter((m) => {
      const matchesSearch = !searchQuery ||
        m.serialNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        m.flatNo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        m.brand.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesType = filterType === 'all' || m.type === filterType;
      const matchesStatus = filterStatus === 'all' || m.status === filterStatus;
      return matchesSearch && matchesType && matchesStatus;
    });
  }, [meters, searchQuery, filterType, filterStatus]);

  const typeLabel = (type: 'heat' | 'water') => type === 'heat' ? 'Isı Sayacı' : 'Su Sayacı';
  const typeIcon = (type: 'heat' | 'water') => type === 'heat' ? ThermometerSnowflake : Droplet;
  const typeColor = (type: 'heat' | 'water') => type === 'heat' ? 'text-red-500' : 'text-blue-500';

  return (
    <div className="animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>Sayaç Yönetimi</h2>
          <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{filteredMeters.length} sayaç görüntüleniyor</p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center rounded-lg overflow-hidden border border-gray-200 dark:border-dark-border">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 transition-colors ${viewMode === 'grid'
                ? 'bg-primary-500 text-white'
                : isDark ? 'bg-dark-surface text-gray-400 hover:text-white' : 'bg-white text-gray-400 hover:text-gray-600'
              }`}
              title="Izgara Görünümü"
            >
              <Grid3X3 className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 transition-colors ${viewMode === 'list'
                ? 'bg-primary-500 text-white'
                : isDark ? 'bg-dark-surface text-gray-400 hover:text-white' : 'bg-white text-gray-400 hover:text-gray-600'
              }`}
              title="Liste Görünümü"
            >
              <List className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className={`flex flex-wrap gap-3 mb-6 p-4 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <div className="flex items-center gap-2">
          <Filter className={`w-4 h-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
          <span className={`text-sm font-medium ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>Filtrele:</span>
        </div>
        {/* Type filter */}
        <div className="relative">
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value as 'all' | 'heat' | 'water')}
            className={`appearance-none pl-3 pr-8 py-1.5 rounded-lg text-sm border cursor-pointer outline-none ${
              isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'
            }`}
          >
            <option value="all">Tüm Tipler</option>
            <option value="heat">Isı Sayacı</option>
            <option value="water">Su Sayacı</option>
          </select>
          <ChevronDown className={`absolute right-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 pointer-events-none ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
        </div>
        {/* Status filter */}
        <div className="relative">
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value as 'all' | MeterStatus)}
            className={`appearance-none pl-3 pr-8 py-1.5 rounded-lg text-sm border cursor-pointer outline-none ${
              isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'
            }`}
          >
            <option value="all">Tüm Durumlar</option>
            <option value="active">Aktif</option>
            <option value="inactive">Pasif</option>
            <option value="error">Hata</option>
            <option value="pending">Beklemede</option>
          </select>
          <ChevronDown className={`absolute right-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 pointer-events-none ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
        </div>
        {/* Quick tags */}
        <div className="flex gap-2 ml-auto">
          {(['all', 'heat', 'water'] as const).map((type) => (
            <button
              key={type}
              onClick={() => setFilterType(type)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                filterType === type
                  ? 'bg-primary-500 text-white'
                  : isDark ? 'bg-dark-bg text-gray-400 hover:text-white' : 'bg-gray-100 text-gray-500 hover:text-gray-700'
              }`}
            >
              {type === 'all' ? 'Tümü' : type === 'heat' ? 'Isı' : 'Su'}
            </button>
          ))}
        </div>
      </div>

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {filteredMeters.map((meter) => {
            const StatusIcon = statusConfig[meter.status].icon;
            const MeterIcon = typeIcon(meter.type);
            return (
              <div
                key={meter.id}
                onClick={() => setSelectedMeter(selectedMeter?.id === meter.id ? null : meter)}
                className={`group p-4 rounded-2xl cursor-pointer transition-all duration-200 hover:scale-[1.02] ${
                  selectedMeter?.id === meter.id
                    ? isDark ? 'bg-primary-600/20 border-2 border-primary-500/50' : 'bg-primary-50 border-2 border-primary-500/50'
                    : isDark ? 'bg-dark-surface border border-dark-border hover:border-primary-500/30' : 'bg-white border border-gray-100 shadow-sm hover:border-primary-300'
                }`}
              >
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className={`p-2 rounded-lg ${meter.type === 'heat' ? 'bg-red-500/10' : 'bg-blue-500/10'}`}>
                      <MeterIcon className={`w-4 h-4 ${typeColor(meter.type)}`} />
                    </div>
                    <div>
                      <p className={`text-sm font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>{meter.serialNo}</p>
                      <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{typeLabel(meter.type)}</p>
                    </div>
                  </div>
                  <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${statusConfig[meter.status].bg} ${statusConfig[meter.status].text}`}>
                    <StatusIcon className="w-3 h-3" />
                    {statusConfig[meter.status].label}
                  </span>
                </div>

                {/* Details */}
                <div className={`space-y-2 pt-3 border-t ${isDark ? 'border-dark-border/50' : 'border-gray-100'}`}>
                  <div className="flex justify-between">
                    <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Blok/Daire</span>
                    <span className={`text-xs font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{meter.block}-{meter.flatNo}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Marka</span>
                    <span className={`text-xs font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{meter.brand}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Son Okuma</span>
                    <span className={`text-xs font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>{meter.lastReading.toLocaleString()} {meter.unit}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>M-Bus Adres</span>
                    <span className={`text-xs font-mono ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>0x{meter.mbusAddress.toString(16).toUpperCase().padStart(2, '0')}</span>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* List View */}
      {viewMode === 'list' && (
        <div className={`rounded-2xl overflow-hidden ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className={isDark ? 'bg-dark-card/50' : 'bg-gray-50'}>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Durum</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Sayaç No</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Tip</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Blok/Daire</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Marka</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Son Okuma</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>M-Bus</th>
                  <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Tarih</th>
                </tr>
              </thead>
              <tbody>
                {filteredMeters.map((meter) => {
                  const StatusIcon = statusConfig[meter.status].icon;
                  const MeterIcon = typeIcon(meter.type);
                  return (
                    <tr key={meter.id} className={`transition-colors ${isDark ? 'hover:bg-dark-card/50 border-b border-dark-border/50' : 'hover:bg-gray-50 border-b border-gray-50'}`}>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${statusConfig[meter.status].bg} ${statusConfig[meter.status].text}`}>
                          <StatusIcon className="w-3 h-3" />
                          {statusConfig[meter.status].label}
                        </span>
                      </td>
                      <td className={`px-4 py-3 text-sm font-mono font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{meter.serialNo}</td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center gap-1.5 text-sm ${typeColor(meter.type)}`}>
                          <MeterIcon className="w-4 h-4" />
                          {typeLabel(meter.type)}
                        </span>
                      </td>
                      <td className={`px-4 py-3 text-sm font-medium ${isDark ? 'text-gray-300' : 'text-gray-700'}`}>{meter.block}-{meter.flatNo}</td>
                      <td className={`px-4 py-3 text-sm ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{meter.brand}</td>
                      <td className={`px-4 py-3 text-sm font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>{meter.lastReading.toLocaleString()} <span className={`text-xs font-normal ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{meter.unit}</span></td>
                      <td className={`px-4 py-3 text-sm font-mono ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>0x{meter.mbusAddress.toString(16).toUpperCase().padStart(2, '0')}</td>
                      <td className={`px-4 py-3 text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{meter.lastReadingDate}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};
