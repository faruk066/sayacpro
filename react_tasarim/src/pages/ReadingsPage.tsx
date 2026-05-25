import React, { useMemo, useState } from 'react';
import { useTheme } from '../contexts/ThemeContext';
import { useApp } from '../contexts/AppContext';
import {
  ThermometerSnowflake,
  Droplet,
  CheckCircle2,
  Clock,
  UploadCloud,
  Download,
  Filter,
  ChevronDown,
  ArrowUpRight,

} from 'lucide-react';

export const ReadingsPage: React.FC = () => {
  const { theme } = useTheme();
  const { readings } = useApp();
  const isDark = theme === 'dark';

  const [filterType, setFilterType] = useState<'all' | 'heat' | 'water'>('all');
  const [filterSynced, setFilterSynced] = useState<'all' | 'synced' | 'pending'>('all');
  const [sortField, setSortField] = useState<'date' | 'value'>('date');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc');
  const [currentPage, setCurrentPage] = useState(1);
  const perPage = 15;

  const filteredReadings = useMemo(() => {
    let result = readings.filter((r) => {
      const matchesType = filterType === 'all' || r.type === filterType;
      const matchesSynced = filterSynced === 'all' ||
        (filterSynced === 'synced' && r.synced) ||
        (filterSynced === 'pending' && !r.synced);
      return matchesType && matchesSynced;
    });

    result.sort((a, b) => {
      const aVal = sortField === 'date' ? `${a.date}${a.time}` : a.value;
      const bVal = sortField === 'date' ? `${b.date}${b.time}` : b.value;
      const cmp = aVal < bVal ? -1 : aVal > bVal ? 1 : 0;
      return sortDir === 'desc' ? -cmp : cmp;
    });

    return result;
  }, [readings, filterType, filterSynced, sortField, sortDir]);

  const totalPages = Math.ceil(filteredReadings.length / perPage);
  const paginatedReadings = filteredReadings.slice((currentPage - 1) * perPage, currentPage * perPage);

  const totalValue = filteredReadings.reduce((s, r) => s + r.value, 0);
  const syncedCount = filteredReadings.filter((r) => r.synced).length;
  const pendingCount = filteredReadings.length - syncedCount;

  return (
    <div className="animate-fade-in">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>Okuma Kayıtları</h2>
          <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{filteredReadings.length} okuma kaydı</p>
        </div>
        <div className="flex items-center gap-2">
          <button className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-colors ${
            isDark ? 'bg-green-500/10 text-green-400 hover:bg-green-500/20' : 'bg-green-50 text-green-600 hover:bg-green-100'
          }`} title="Senkronize Et">
            <UploadCloud className="w-4 h-4" />
            Senkronize
          </button>
          <button className={`flex items-center gap-2 px-3 py-2 rounded-xl text-sm font-medium transition-colors ${
            isDark ? 'bg-primary-500/10 text-primary-400 hover:bg-primary-500/20' : 'bg-blue-50 text-blue-600 hover:bg-blue-100'
          }`} title="Excel İndir">
            <Download className="w-4 h-4" />
            Dışa Aktar
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div className={`p-4 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-primary-500/10"><ArrowUpRight className="w-5 h-5 text-primary-500" /></div>
            <div>
              <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Toplam Değer</p>
              <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{totalValue.toLocaleString()}</p>
            </div>
          </div>
        </div>
        <div className={`p-4 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-green-500/10"><CheckCircle2 className="w-5 h-5 text-green-500" /></div>
            <div>
              <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Senkronize</p>
              <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{syncedCount}</p>
            </div>
          </div>
        </div>
        <div className={`p-4 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-lg bg-yellow-500/10"><Clock className="w-5 h-5 text-yellow-500" /></div>
            <div>
              <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Bekleyen</p>
              <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{pendingCount}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className={`flex flex-wrap items-center gap-3 mb-6 p-4 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <Filter className={`w-4 h-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
        <select
          value={filterType}
          onChange={(e) => setFilterType(e.target.value as 'all' | 'heat' | 'water')}
          className={`px-3 py-1.5 rounded-lg text-sm border cursor-pointer outline-none ${isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'}`}
        >
          <option value="all">Tüm Tipler</option>
          <option value="heat">Isı Sayacı</option>
          <option value="water">Su Sayacı</option>
        </select>
        <select
          value={filterSynced}
          onChange={(e) => setFilterSynced(e.target.value as 'all' | 'synced' | 'pending')}
          className={`px-3 py-1.5 rounded-lg text-sm border cursor-pointer outline-none ${isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'}`}
        >
          <option value="all">Tüm Durumlar</option>
          <option value="synced">Senkronize</option>
          <option value="pending">Bekleyen</option>
        </select>
        <div className="relative ml-auto">
          <select
            value={`${sortField}-${sortDir}`}
            onChange={(e) => {
              const [f, d] = e.target.value.split('-');
              setSortField(f as 'date' | 'value');
              setSortDir(d as 'asc' | 'desc');
            }}
            className={`appearance-none pl-3 pr-8 py-1.5 rounded-lg text-sm border cursor-pointer outline-none ${isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'}`}
          >
            <option value="date-desc">Tarih (Yeniden Eskiye)</option>
            <option value="date-asc">Tarih (Eskiden Yeniye)</option>
            <option value="value-desc">Değer (Çoktan Aza)</option>
            <option value="value-asc">Değer (Azdan Çoğa)</option>
          </select>
          <ChevronDown className={`absolute right-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 pointer-events-none ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
        </div>
      </div>

      {/* Readings Table */}
      <div className={`rounded-2xl overflow-hidden ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className={isDark ? 'bg-dark-card/50' : 'bg-gray-50'}>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Daire</th>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Tip</th>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Sayaç No</th>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Değer</th>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Tarih</th>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Saat</th>
                <th className={`text-left px-4 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Durum</th>
              </tr>
            </thead>
            <tbody>
              {paginatedReadings.map((r, i) => (
                <tr key={r.id} className={`transition-colors ${isDark ? 'hover:bg-dark-card/50' : 'hover:bg-gray-50'} ${i !== paginatedReadings.length - 1 ? (isDark ? 'border-b border-dark-border/50' : 'border-b border-gray-50') : ''}`}>
                  <td className={`px-4 py-3 text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{r.block}-{r.flatNo}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-xs font-medium ${
                      r.type === 'heat'
                        ? isDark ? 'bg-heat-500/10 text-heat-400' : 'bg-red-50 text-red-600'
                        : isDark ? 'bg-water-500/10 text-water-400' : 'bg-blue-50 text-blue-600'
                    }`}>
                      {r.type === 'heat' ? <ThermometerSnowflake className="w-3 h-3" /> : <Droplet className="w-3 h-3" />}
                      {r.type === 'heat' ? 'Isı' : 'Su'}
                    </span>
                  </td>
                  <td className={`px-4 py-3 text-sm font-mono ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{r.meterSerialNo}</td>
                  <td className={`px-4 py-3 text-sm font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>{r.value.toLocaleString()}</td>
                  <td className={`px-4 py-3 text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{r.date}</td>
                  <td className={`px-4 py-3 text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{r.time}</td>
                  <td className="px-4 py-3">
                    {r.synced
                      ? <span className="flex items-center gap-1 text-green-500 text-xs"><CheckCircle2 className="w-3.5 h-3.5" />Senkronize</span>
                      : <span className="flex items-center gap-1 text-yellow-500 text-xs"><Clock className="w-3.5 h-3.5" />Bekliyor</span>
                    }
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className={`flex items-center justify-between px-4 py-3 border-t ${isDark ? 'border-dark-border' : 'border-gray-100'}`}>
          <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            {(currentPage - 1) * perPage + 1}-{Math.min(currentPage * perPage, filteredReadings.length)} / {filteredReadings.length}
          </p>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors disabled:opacity-40 ${
                isDark ? 'bg-dark-card text-gray-300 hover:bg-dark-border' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              Önceki
            </button>
            {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setCurrentPage(pageNum)}
                  className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${
                    currentPage === pageNum
                      ? 'bg-primary-500 text-white'
                      : isDark ? 'text-gray-300 hover:bg-dark-card' : 'text-gray-600 hover:bg-gray-100'
                  }`}
                >
                  {pageNum}
                </button>
              );
            })}
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors disabled:opacity-40 ${
                isDark ? 'bg-dark-card text-gray-300 hover:bg-dark-border' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              Sonraki
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
