import type { Meter, Reading, StatsData, FlatData } from '../types';

const generateMeters = (): Meter[] => {
  const brands = ['Engelmann', 'Techem', 'Itron', 'Diehl', 'Zenner', 'Kamstrup'];
  const meters: Meter[] = [];
  for (let i = 1; i <= 48; i++) {
    const block = i <= 16 ? 'A' : i <= 32 ? 'B' : 'C';
    const type: 'heat' | 'water' = i % 3 === 0 ? 'water' : 'heat';
    const statuses: ('active' | 'inactive' | 'error' | 'pending')[] = ['active', 'active', 'active', 'active', 'active', 'active', 'active', 'inactive', 'error', 'pending'];
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    meters.push({
      id: `m-${i}`,
      serialNo: `${type === 'heat' ? 'IS' : 'SS'}${String(i).padStart(4, '0')}`,
      type,
      status,
      flatNo: String(i),
      block,
      lastReading: type === 'heat' ? Math.floor(Math.random() * 50000 + 1000) : Math.floor(Math.random() * 90000 + 5000),
      lastReadingDate: `2025-0${Math.floor(Math.random() * 6 + 1)}-${String(Math.floor(Math.random() * 28 + 1)).padStart(2, '0')}`,
      unit: type === 'heat' ? 'kWh' : 'L',
      brand: brands[Math.floor(Math.random() * brands.length)],
      mbusAddress: i * 10,
      installedDate: `202${Math.floor(Math.random() * 4)}-${String(Math.floor(Math.random() * 12 + 1)).padStart(2, '0')}-${String(Math.floor(Math.random() * 28 + 1)).padStart(2, '0')}`,
    });
  }
  return meters;
};

export const mockMeters: Meter[] = generateMeters();

export const mockReadings: Reading[] = Array.from({ length: 120 }, (_, i) => {
  const meter = mockMeters[i % mockMeters.length];
  const d = new Date();
  d.setDate(d.getDate() - Math.floor(i / 5));
  return {
    id: `r-${i}`,
    meterId: meter.id,
    meterSerialNo: meter.serialNo,
    flatNo: meter.flatNo,
    block: meter.block,
    type: meter.type,
    value: meter.type === 'heat' ? Math.floor(Math.random() * 5000 + 500) : Math.floor(Math.random() * 5000 + 200),
    date: d.toISOString().split('T')[0],
    time: `${String(Math.floor(Math.random() * 12 + 8)).padStart(2, '0')}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}`,
    synced: Math.random() > 0.15,
  };
});

export const mockStats: StatsData = {
  totalMeters: 48,
  heatMeters: 32,
  waterMeters: 16,
  activeMeters: 38,
  errorMeters: 3,
  totalReadings: 12847,
  syncedReadings: 11932,
  pendingReadings: 915,
  todayReadings: 24,
  weekReadings: 156,
};

export const mockFlatData: FlatData[] = Array.from({ length: 16 }, (_, i) => {
  const flatNum = String(i + 1);
  const meters = mockMeters
    .filter((m) => m.flatNo === flatNum || m.flatNo === String(i + 1 + 16) || m.flatNo === String(i + 1 + 32))
    .map((m) => ({
      type: m.type,
      meterId: m.id,
      serialNo: m.serialNo,
      status: m.status,
    }));
  return {
    flatNo: flatNum,
    block: i < 16 ? 'A' : 'B',
    meters,
  };
});
