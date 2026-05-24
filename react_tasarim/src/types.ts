export type MeterType = 'heat' | 'water';
export type MeterStatus = 'active' | 'inactive' | 'error' | 'pending';
export type Page = 'dashboard' | 'meters' | 'readings' | 'import' | 'export' | 'settings';

export interface Meter {
  id: string;
  serialNo: string;
  type: MeterType;
  status: MeterStatus;
  flatNo: string;
  block: string;
  lastReading: number;
  lastReadingDate: string;
  unit: string;
  brand: string;
  mbusAddress: number;
  installedDate: string;
}

export interface Reading {
  id: string;
  meterId: string;
  meterSerialNo: string;
  flatNo: string;
  block: string;
  type: MeterType;
  value: number;
  date: string;
  time: string;
  synced: boolean;
  mbusRaw?: string;
}

export interface FlatData {
  flatNo: string;
  block: string;
  meters: {
    type: MeterType;
    meterId: string;
    serialNo: string;
    status: MeterStatus;
  }[];
}

export interface StatsData {
  totalMeters: number;
  heatMeters: number;
  waterMeters: number;
  activeMeters: number;
  errorMeters: number;
  totalReadings: number;
  syncedReadings: number;
  pendingReadings: number;
  todayReadings: number;
  weekReadings: number;
}

export interface ImportResult {
  totalRows: number;
  successRows: number;
  errorRows: number;
  format: 'telegram' | 'polimeter' | 'unknown';
  errors: string[];
}
