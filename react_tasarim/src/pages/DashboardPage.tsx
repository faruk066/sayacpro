import React from 'react';
import { useTheme } from '../contexts/ThemeContext';
import { useApp } from '../contexts/AppContext';
import {
  Gauge,
  ThermometerSnowflake,
  Droplet,
  Wifi,
  ArrowUpRight,
  ArrowDownRight,
  Activity,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Zap,
} from 'lucide-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip as RechartsTooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  LineChart,
  Line,

} from 'recharts';

const COLORS = ['#3b82f6', '#22c55e', '#ef4444', '#f59e0b'];
const HEAT_WATER_COLORS = ['#ef4444', '#3b82f6'];

const weeklyData = [
  { name: 'Pzt', isi: 420, su: 280, okuma: 52 },
  { name: 'Sal', isi: 380, su: 310, okuma: 48 },
  { name: 'Car', isi: 510, su: 260, okuma: 61 },
  { name: 'Per', isi: 470, su: 290, okuma: 55 },
  { name: 'Cum', isi: 560, su: 340, okuma: 68 },
  { name: 'Cmt', isi: 320, su: 190, okuma: 38 },
  { name: 'Paz', isi: 290, su: 180, okuma: 32 },
];

const monthlyReadings = [
  { name: 'Oca', count: 420 },
  { name: 'Sub', count: 380 },
  { name: 'Mar', count: 510 },
  { name: 'Nis', count: 470 },
  { name: 'May', count: 560 },
  { name: 'Haz', count: 620 },
];

const meterTypeData = [
  { name: 'Isı Sayacı', value: 32 },
  { name: 'Su Sayacı', value: 16 },
];

const statusData = [
  { name: 'Aktif', value: 38 },
  { name: 'Beklemede', value: 5 },
  { name: 'Hata', value: 3 },
  { name: 'Pasif', value: 2 },
];

const recentReadings = [
  { id: 'r-1', flatNo: 'A-12', type: 'Isı', serial: 'IS0012', value: 1245.8, unit: 'kWh', time: '14:32', date: '2025-06-15', synced: true, status: 'normal' as const },
  { id: 'r-2', flatNo: 'B-05', type: 'Su', serial: 'SS0021', value: 382.4, unit: 'L', time: '14:28', date: '2025-06-15', synced: true, status: 'normal' as const },
  { id: 'r-3', flatNo: 'A-08', type: 'Isı', serial: 'IS0008', value: 2156.3, unit: 'kWh', time: '14:15', date: '2025-06-15', synced: false, status: 'high' as const },
  { id: 'r-4', flatNo: 'C-14', type: 'Su', serial: 'SS0046', value: 124.7, unit: 'L', time: '13:58', date: '2025-06-15', synced: true, status: 'normal' as const },
  { id: 'r-5', flatNo: 'B-03', type: 'Isı', serial: 'IS0019', value: 892.1, unit: 'kWh', time: '13:42', date: '2025-06-15', synced: false, status: 'low' as const },
  { id: 'r-6', flatNo: 'A-01', type: 'Su', serial: 'SS0017', value: 567.2, unit: 'L', time: '13:30', date: '2025-06-15', synced: true, status: 'normal' as const },
];

const statusBadgeClass = (status: 'normal' | 'high' | 'low'): string => {
  switch (status) {
    case 'normal': return 'bg-green-500/10 text-green-500';
    case 'high': return 'bg-red-500/10 text-red-500';
    case 'low': return 'bg-yellow-500/10 text-yellow-500';
  }
};

interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.FC<{ className?: string }>;
  iconBg: string;
  trend?: { value: number; positive: boolean };
  subtitle?: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon: Icon, iconBg, trend, subtitle }) => {
  const { theme } = useTheme();
  const isDark = theme === 'dark';
  return (
    <div className={`p-5 rounded-2xl transition-all duration-200 hover:scale-[1.02] ${
      isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'
    }`}>
      <div className="flex items-start justify-between">
        <div>
          <p className={`text-sm font-medium ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{title}</p>
          <p className={`text-2xl font-bold mt-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>{value}</p>
          {subtitle && <p className={`text-xs mt-1 ${isDark ? 'text-gray-500' : 'text-gray-400'}`}>{subtitle}</p>}
        </div>
        <div className={`p-2.5 rounded-xl ${iconBg}`}>
          <Icon className="w-5 h-5 text-white" />
        </div>
      </div>
      {trend && (
        <div className="flex items-center gap-1 mt-3">
          {trend.positive ? <ArrowUpRight className="w-3.5 h-3.5 text-green-500" /> : <ArrowDownRight className="w-3.5 h-3.5 text-red-500" />}
          <span className={`text-xs font-medium ${trend.positive ? 'text-green-500' : 'text-red-500'}`}>
            {trend.positive ? '+' : ''}{trend.value}%
          </span>
          <span className={`text-xs ${isDark ? 'text-gray-500' : 'text-gray-400'}`}>geçen haftaya göre</span>
        </div>
      )}
    </div>
  );
};

export const DashboardPage: React.FC = () => {
  const { theme } = useTheme();
  const { stats } = useApp();
  const isDark = theme === 'dark';

  return (
    <div className="animate-fade-in">
      {/* Welcome Banner */}
      <div className={`relative overflow-hidden rounded-2xl p-6 mb-6 bg-gradient-to-r from-primary-600 via-primary-500 to-primary-400`}>
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full -translate-y-1/2 translate-x-1/2" />
        <div className="absolute bottom-0 left-1/3 w-32 h-32 bg-white/5 rounded-full translate-y-1/2" />
        <div className="relative z-10">
          <div className="flex items-center gap-2 mb-1">
            <Zap className="w-5 h-5 text-yellow-300" />
            <h2 className="text-xl font-bold text-white">Sayaç Pro Dashboard</h2>
          </div>
          <p className="text-primary-100 text-sm mb-4">M-Bus Isı ve Su Sayaçları Yönetim Paneli</p>
          <div className="flex flex-wrap gap-4">
            <div className="flex items-center gap-2 bg-white/10 backdrop-blur-sm px-3 py-1.5 rounded-lg">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse-dot" />
              <span className="text-sm text-white font-medium">M-Bus Bağlı</span>
            </div>
            <div className="flex items-center gap-2 bg-white/10 backdrop-blur-sm px-3 py-1.5 rounded-lg">
              <Wifi className="w-4 h-4 text-green-300" />
              <span className="text-sm text-white font-medium">Firestore: europe-west1</span>
            </div>
            <div className="flex items-center gap-2 bg-white/10 backdrop-blur-sm px-3 py-1.5 rounded-lg">
              <CheckCircle2 className="w-4 h-4 text-green-300" />
              <span className="text-sm text-white font-medium">{stats.syncedReadings.toLocaleString()} Senkronize</span>
            </div>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard title="Toplam Sayaç" value={stats.totalMeters} icon={Gauge} iconBg="bg-gradient-to-br from-primary-500 to-primary-700" trend={{ value: 12, positive: true }} />
        <StatCard title="Isı Sayaçları" value={stats.heatMeters} icon={ThermometerSnowflake} iconBg="bg-gradient-to-br from-heat-500 to-heat-600" subtitle="Tip 4 - Isı Sayacı" />
        <StatCard title="Su Sayaçları" value={stats.waterMeters} icon={Droplet} iconBg="bg-gradient-to-br from-water-500 to-water-600" subtitle="Tip 6 - Su Sayacı" />
        <StatCard title="Aktif Bağlantı" value={`${stats.activeMeters}/${stats.totalMeters}`} icon={Wifi} iconBg="bg-gradient-to-br from-green-500 to-green-600" trend={{ value: 3, positive: true }} />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        {/* Weekly Trend */}
        <div className={`col-span-2 p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className={`text-base font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>Haftalık Tüketim</h3>
              <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Isı ve Su sayaçları karşılaştırması</p>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-full bg-red-500" />
                <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Isı</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded-full bg-blue-500" />
                <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Su</span>
              </div>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={250}>
            <AreaChart data={weeklyData}>
              <defs>
                <linearGradient id="colorIsi" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#ef4444" stopOpacity={0} />
                </linearGradient>
                <linearGradient id="colorSu" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={isDark ? '#334155' : '#e5e7eb'} />
              <XAxis dataKey="name" tick={{ fill: isDark ? '#94a3b8' : '#6b7280', fontSize: 12 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: isDark ? '#94a3b8' : '#6b7280', fontSize: 12 }} axisLine={false} tickLine={false} />
              <RechartsTooltip
                contentStyle={{
                  backgroundColor: isDark ? '#1e293b' : '#ffffff',
                  borderColor: isDark ? '#334155' : '#e5e7eb',
                  borderRadius: '12px',
                  color: isDark ? '#e2e8f0' : '#1f2937',
                }}
              />
              <Area type="monotone" dataKey="isi" stroke="#ef4444" strokeWidth={2} fillOpacity={1} fill="url(#colorIsi)" />
              <Area type="monotone" dataKey="su" stroke="#3b82f6" strokeWidth={2} fillOpacity={1} fill="url(#colorSu)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Meter Types Pie */}
        <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-base font-semibold mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Sayaç Tipleri</h3>
          <p className={`text-xs mb-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Toplam {stats.totalMeters} sayaç</p>
          <ResponsiveContainer width="100%" height={180}>
            <PieChart>
              <Pie data={meterTypeData} cx="50%" cy="50%" innerRadius={50} outerRadius={75} paddingAngle={4} dataKey="value" strokeWidth={0}>
                {meterTypeData.map((_entry, index) => (
                  <Cell key={index} fill={HEAT_WATER_COLORS[index % HEAT_WATER_COLORS.length]} />
                ))}
              </Pie>
              <RechartsTooltip />
            </PieChart>
          </ResponsiveContainer>
          <div className="flex justify-center gap-6 mt-2">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-red-500" />
              <span className={`text-sm ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>Isı ({stats.heatMeters})</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-blue-500" />
              <span className={`text-sm ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>Su ({stats.waterMeters})</span>
            </div>
          </div>
        </div>
      </div>

      {/* Second Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        {/* Monthly Readings */}
        <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-base font-semibold mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Aylık Okuma</h3>
          <p className={`text-xs mb-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Okuma sayısı dağılımı</p>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={monthlyReadings}>
              <CartesianGrid strokeDasharray="3 3" stroke={isDark ? '#334155' : '#e5e7eb'} />
              <XAxis dataKey="name" tick={{ fill: isDark ? '#94a3b8' : '#6b7280', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: isDark ? '#94a3b8' : '#6b7280', fontSize: 11 }} axisLine={false} tickLine={false} />
              <RechartsTooltip
                contentStyle={{
                  backgroundColor: isDark ? '#1e293b' : '#ffffff',
                  borderColor: isDark ? '#334155' : '#e5e7eb',
                  borderRadius: '12px',
                  color: isDark ? '#e2e8f0' : '#1f2937',
                }}
              />
              <Bar dataKey="count" fill="#3b82f6" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Sync Status */}
        <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-base font-semibold mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Senkronizasyon</h3>
          <p className={`text-xs mb-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Veri durumları</p>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={statusData} cx="50%" cy="50%" innerRadius={50} outerRadius={80} paddingAngle={4} dataKey="value" strokeWidth={0}>
                {statusData.map((_entry, index) => (
                  <Cell key={index} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <RechartsTooltip />
            </PieChart>
          </ResponsiveContainer>
          <div className="grid grid-cols-2 gap-2 mt-2">
            {statusData.map((item, i) => (
              <div key={i} className="flex items-center gap-1.5">
                <div className="w-2 h-2 rounded-full" style={{ backgroundColor: COLORS[i] }} />
                <span className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{item.name}: {item.value}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Reading Trends */}
        <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-base font-semibold mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Okuma Trendi</h3>
          <p className={`text-xs mb-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Haftalık okuma sayısı</p>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={weeklyData}>
              <CartesianGrid strokeDasharray="3 3" stroke={isDark ? '#334155' : '#e5e7eb'} />
              <XAxis dataKey="name" tick={{ fill: isDark ? '#94a3b8' : '#6b7280', fontSize: 11 }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fill: isDark ? '#94a3b8' : '#6b7280', fontSize: 11 }} axisLine={false} tickLine={false} />
              <RechartsTooltip
                contentStyle={{
                  backgroundColor: isDark ? '#1e293b' : '#ffffff',
                  borderColor: isDark ? '#334155' : '#e5e7eb',
                  borderRadius: '12px',
                  color: isDark ? '#e2e8f0' : '#1f2937',
                }}
              />
              <Line type="monotone" dataKey="okuma" stroke="#8b5cf6" strokeWidth={2.5} dot={{ fill: '#8b5cf6', r: 4 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Readings Table */}
      <div className={`rounded-2xl overflow-hidden ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <div className="flex items-center justify-between p-5 pb-0">
          <div>
            <h3 className={`text-base font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>Son Okumalar</h3>
            <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>En son yapılan sayaç okumaları</p>
          </div>
          <div className="flex items-center gap-2">
            <span className={`flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-medium ${isDark ? 'bg-green-500/10 text-green-400' : 'bg-green-50 text-green-600'}`}>
              <Activity className="w-3 h-3" />
              Canlı
            </span>
          </div>
        </div>
        <div className="overflow-x-auto mt-4">
          <table className="w-full">
            <thead>
              <tr className={isDark ? 'border-b border-dark-border' : 'border-b border-gray-100'}>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Daire</th>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Tip</th>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Sayaç No</th>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Değer</th>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Tarih</th>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Senkronize</th>
                <th className={`text-left px-5 py-3 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Durum</th>
              </tr>
            </thead>
            <tbody>
              {recentReadings.map((r, i) => (
                <tr
                  key={r.id}
                  className={`transition-colors ${isDark ? 'hover:bg-dark-card' : 'hover:bg-gray-50'} ${i !== recentReadings.length - 1 ? (isDark ? 'border-b border-dark-border/50' : 'border-b border-gray-50') : ''}`}
                >
                  <td className="px-5 py-3.5">
                    <span className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{r.flatNo}</span>
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-medium ${
                      r.type === 'Isı'
                        ? isDark ? 'bg-heat-500/10 text-heat-400' : 'bg-red-50 text-red-600'
                        : isDark ? 'bg-water-500/10 text-water-400' : 'bg-blue-50 text-blue-600'
                    }`}>
                      {r.type === 'Isı' ? <ThermometerSnowflake className="w-3 h-3" /> : <Droplet className="w-3 h-3" />}
                      {r.type}
                    </span>
                  </td>
                  <td className={`px-5 py-3.5 text-sm font-mono ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{r.serial}</td>
                  <td className={`px-5 py-3.5 text-sm font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>
                    {r.value.toLocaleString()} <span className={`text-xs font-normal ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{r.unit}</span>
                  </td>
                  <td className={`px-5 py-3.5 text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{r.date}</td>
                  <td className="px-5 py-3.5">
                    {r.synced
                      ? <span className="flex items-center gap-1 text-green-500 text-xs"><CheckCircle2 className="w-3.5 h-3.5" />Senkronize</span>
                      : <span className="flex items-center gap-1 text-yellow-500 text-xs"><Clock className="w-3.5 h-3.5" />Bekliyor</span>
                    }
                  </td>
                  <td className="px-5 py-3.5">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${statusBadgeClass(r.status)}`}>
                      {r.status === 'normal' ? 'Normal' : r.status === 'high' ? 'Yüksek' : 'Düşük'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Quick Stats Bar */}
      <div className={`mt-6 grid grid-cols-2 sm:grid-cols-4 gap-4`}>
        <div className={`p-4 rounded-xl flex items-center gap-3 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="p-2 rounded-lg bg-green-500/10">
            <CheckCircle2 className="w-5 h-5 text-green-500" />
          </div>
          <div>
            <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{stats.syncedReadings.toLocaleString()}</p>
            <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Senkronize</p>
          </div>
        </div>
        <div className={`p-4 rounded-xl flex items-center gap-3 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="p-2 rounded-lg bg-yellow-500/10">
            <Clock className="w-5 h-5 text-yellow-500" />
          </div>
          <div>
            <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{stats.pendingReadings.toLocaleString()}</p>
            <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Bekleyen</p>
          </div>
        </div>
        <div className={`p-4 rounded-xl flex items-center gap-3 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="p-2 rounded-lg bg-red-500/10">
            <AlertTriangle className="w-5 h-5 text-red-500" />
          </div>
          <div>
            <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{stats.errorMeters}</p>
            <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Hatalı</p>
          </div>
        </div>
        <div className={`p-4 rounded-xl flex items-center gap-3 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <div className="p-2 rounded-lg bg-primary-500/10">
            <Activity className="w-5 h-5 text-primary-500" />
          </div>
          <div>
            <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{stats.todayReadings}</p>
            <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Bugün</p>
          </div>
        </div>
      </div>
    </div>
  );
};
