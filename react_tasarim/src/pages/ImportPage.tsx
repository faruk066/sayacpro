import React, { useState, useCallback, useRef } from 'react';
import { useTheme } from '../contexts/ThemeContext';
import { useApp } from '../contexts/AppContext';
import type { ImportResult } from '../types';
import {
  Upload,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Loader2,
  Database,
  ArrowRight,
  Table2,
  RefreshCw,
  Zap,
  Layers,
  FileCheck,
} from 'lucide-react';

export const ImportPage: React.FC = () => {
  const { theme } = useTheme();
  const { setImportResult } = useApp();
  const isDark = theme === 'dark';
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [isDragging, setIsDragging] = useState(false);
  const [isProcessing, setIsProcessing] = useState(false);
  const [importResult, setLocalResult] = useState<ImportResult | null>(null);
  const [selectedFormat, setSelectedFormat] = useState<'auto' | 'telegram' | 'polimeter'>('auto');
  const [previewData, setPreviewData] = useState<Record<string, string>[]>([]);
  const [fileName, setFileName] = useState('');
  const [fileSize, setFileSize] = useState(0);

  const simulateImport = useCallback(async () => {
    setIsProcessing(true);

    // Simulate file reading and parsing
    await new Promise((r) => setTimeout(r, 1500));

    // Generate mock preview data
    const mockPreview = [
      { 'DAİRE NO': '1', 'SAYAÇ NO': 'IS0001', 'SAYAÇ TİPİ': '4', 'BLOK': 'A' },
      { 'DAİRE NO': '2', 'SAYAÇ NO': 'IS0002', 'SAYAÇ TİPİ': '4', 'BLOK': 'A' },
      { 'DAİRE NO': '3', 'SAYAÇ NO': 'SS0003', 'SAYAÇ TİPİ': '6', 'BLOK': 'A' },
      { 'DAİRE NO': '4', 'SAYAÇ NO': 'IS0004', 'SAYAÇ TİPİ': '4', 'BLOK': 'A' },
      { 'DAİRE NO': '5', 'SAYAÇ NO': 'IS0005', 'SAYAÇ TİPİ': '4', 'BLOK': 'B' },
      { 'DAİRE NO': '6', 'SAYAÇ NO': 'SS0006', 'SAYAÇ TİPİ': '6', 'BLOK': 'B' },
    ];

    const result: ImportResult = {
      totalRows: mockPreview.length,
      successRows: mockPreview.length - 1,
      errorRows: 1,
      format: selectedFormat === 'auto' ? 'telegram' : selectedFormat,
      errors: ['Satır 3: Eksik sayaç numarası'],
    };

    setLocalResult(result);
    setImportResult(result);
    setPreviewData(mockPreview);
    setIsProcessing(false);
  }, [selectedFormat, setImportResult]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file && (file.name.endsWith('.xls') || file.name.endsWith('.xlsx') || file.name.endsWith('.csv'))) {
      setFileName(file.name);
      setFileSize(file.size);
      simulateImport();
    }
  }, [simulateImport]);

  const handleFileSelect = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setFileName(file.name);
      setFileSize(file.size);
      simulateImport();
    }
  }, [simulateImport]);

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const resetImport = () => {
    setImportResult(null);
    setLocalResult(null);
    setPreviewData([]);
    setFileName('');
    setFileSize(0);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  return (
    <div className="animate-fade-in">
      <div className="mb-6">
        <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>Excel İçe Aktarma</h2>
        <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Apartman ve daire listelerini Excel dosyalarından aktarın</p>
      </div>

      {/* Format Selection */}
      <div className={`p-5 rounded-2xl mb-6 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <h3 className={`text-sm font-semibold mb-3 ${isDark ? 'text-white' : 'text-gray-900'}`}>Format Seçimi</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {[
            { id: 'auto' as const, label: 'Otomatik Algıla', icon: Zap, desc: 'Format otomatik tespit edilir' },
            { id: 'telegram' as const, label: 'Telegram Format', icon: Table2, desc: 'DAİRE NO, SAYAÇ NO, TİP' },
            { id: 'polimeter' as const, label: 'Polimeter Format', icon: Layers, desc: 'blok, daire, tip, ıd2' },
          ].map((fmt) => (
            <button
              key={fmt.id}
              onClick={() => setSelectedFormat(fmt.id)}
              className={`p-4 rounded-xl border-2 text-left transition-all ${
                selectedFormat === fmt.id
                  ? isDark ? 'border-primary-500 bg-primary-500/10' : 'border-primary-500 bg-primary-50'
                  : isDark ? 'border-dark-border hover:border-dark-border/70' : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <fmt.icon className={`w-5 h-5 mb-2 ${selectedFormat === fmt.id ? 'text-primary-500' : isDark ? 'text-gray-400' : 'text-gray-500'}`} />
              <p className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{fmt.label}</p>
              <p className={`text-xs mt-1 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{fmt.desc}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Upload Area */}
      {!fileName && (
        <div
          onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
          onDragLeave={() => setIsDragging(false)}
          onDrop={handleDrop}
          className={`relative rounded-2xl border-2 border-dashed p-12 text-center transition-all ${
            isDragging
              ? 'border-primary-500 bg-primary-500/10'
              : isDark ? 'border-dark-border hover:border-primary-500/50 bg-dark-surface' : 'border-gray-300 hover:border-primary-400 bg-white'
          }`}
        >
          <input
            ref={fileInputRef}
            type="file"
            accept=".xls,.xlsx,.csv"
            onChange={handleFileSelect}
            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
          />
          <div className={`mx-auto w-16 h-16 rounded-2xl flex items-center justify-center mb-4 ${
            isDragging ? 'bg-primary-500/20' : isDark ? 'bg-dark-card' : 'bg-gray-100'
          }`}>
            <Upload className={`w-8 h-8 ${isDragging ? 'text-primary-500' : isDark ? 'text-gray-400' : 'text-gray-500'}`} />
          </div>
          <h3 className={`text-lg font-semibold mb-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
            {isDragging ? 'Bırakın' : 'Excel Dosyasını Yükleyin'}
          </h3>
          <p className={`text-sm mb-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
            Dosyanızı sürükleyin veya tıklayarak seçin
          </p>
          <div className="flex items-center justify-center gap-4">
            {['.xls', '.xlsx', '.csv'].map((ext) => (
              <span key={ext} className={`px-3 py-1 rounded-lg text-xs font-mono ${isDark ? 'bg-dark-card text-gray-300' : 'bg-gray-100 text-gray-600'}`}>
                {ext}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Processing */}
      {isProcessing && (
        <div className={`rounded-2xl p-8 text-center ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <Loader2 className={`w-12 h-12 mx-auto mb-4 animate-spin ${isDark ? 'text-primary-400' : 'text-primary-500'}`} />
          <h3 className={`text-lg font-semibold mb-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>Dosya İşleniyor...</h3>
          <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Excel dosyası analiz ediliyor ve veriler çıkarılıyor</p>
          <div className={`mt-4 mx-auto max-w-xs h-2 rounded-full overflow-hidden ${isDark ? 'bg-dark-card' : 'bg-gray-200'}`}>
            <div className="h-full bg-primary-500 rounded-full animate-pulse" style={{ width: '60%' }} />
          </div>
        </div>
      )}

      {/* Result */}
      {importResult && !isProcessing && (
        <div className="space-y-6">
          {/* File Info */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-green-500/10">
                  <FileCheck className="w-5 h-5 text-green-500" />
                </div>
                <div>
                  <p className={`text-sm font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>{fileName}</p>
                  <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{formatFileSize(fileSize)} • {importResult.format} formatı</p>
                </div>
              </div>
              <button
                onClick={resetImport}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  isDark ? 'bg-dark-card text-gray-300 hover:text-white' : 'bg-gray-100 text-gray-600 hover:text-gray-900'
                }`}
              >
                <RefreshCw className="w-3.5 h-3.5" />
                Yeni Dosya
              </button>
            </div>

            {/* Result Stats */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className={`p-3 rounded-xl text-center ${isDark ? 'bg-dark-bg' : 'bg-gray-50'}`}>
                <p className={`text-2xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{importResult.totalRows}</p>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Toplam Satır</p>
              </div>
              <div className={`p-3 rounded-xl text-center ${isDark ? 'bg-dark-bg' : 'bg-gray-50'}`}>
                <p className="text-2xl font-bold text-green-500">{importResult.successRows}</p>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Başarılı</p>
              </div>
              <div className={`p-3 rounded-xl text-center ${isDark ? 'bg-dark-bg' : 'bg-gray-50'}`}>
                <p className="text-2xl font-bold text-red-500">{importResult.errorRows}</p>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Hatalı</p>
              </div>
              <div className={`p-3 rounded-xl text-center ${isDark ? 'bg-dark-bg' : 'bg-gray-50'}`}>
                <p className="text-2xl font-bold text-blue-500">{importResult.format === 'telegram' ? 'Telegram' : importResult.format === 'polimeter' ? 'Polimeter' : 'Otomatik'}</p>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Format</p>
              </div>
            </div>
          </div>

          {/* Errors */}
          {importResult.errors.length > 0 && (
            <div className={`p-5 rounded-2xl border ${isDark ? 'bg-red-500/5 border-red-500/20' : 'bg-red-50 border-red-100'}`}>
              <div className="flex items-center gap-2 mb-3">
                <AlertTriangle className="w-4 h-4 text-red-500" />
                <h4 className={`text-sm font-semibold ${isDark ? 'text-red-400' : 'text-red-600'}`}>Hatalar</h4>
              </div>
              {importResult.errors.map((err, i) => (
                <div key={i} className="flex items-start gap-2 mb-2">
                  <XCircle className="w-4 h-4 text-red-500 mt-0.5 flex-shrink-0" />
                  <p className={`text-sm ${isDark ? 'text-red-300' : 'text-red-600'}`}>{err}</p>
                </div>
              ))}
            </div>
          )}

          {/* Preview Table */}
          <div className={`rounded-2xl overflow-hidden ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <div className="p-5 pb-0">
              <h3 className={`text-sm font-semibold mb-1 ${isDark ? 'text-white' : 'text-gray-900'}`}>Veri Önizleme</h3>
              <p className={`text-xs mb-4 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>İlk {previewData.length} satır</p>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className={isDark ? 'bg-dark-card/50' : 'bg-gray-50'}>
                    {previewData.length > 0 && Object.keys(previewData[0]).map((key) => (
                      <th key={key} className={`text-left px-4 py-2.5 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{key}</th>
                    ))}
                    <th className={`text-left px-4 py-2.5 text-xs font-medium uppercase tracking-wider ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Durum</th>
                  </tr>
                </thead>
                <tbody>
                  {previewData.map((row, i) => (
                    <tr key={i} className={`transition-colors ${isDark ? 'hover:bg-dark-card/50 border-b border-dark-border/50' : 'hover:bg-gray-50 border-b border-gray-50'}`}>
                      {Object.values(row).map((val, j) => (
                        <td key={j} className={`px-4 py-2.5 text-sm font-mono ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{val}</td>
                      ))}
                      <td className="px-4 py-2.5">
                        {i === 2
                          ? <span className="flex items-center gap-1 text-red-500 text-xs"><XCircle className="w-3.5 h-3.5" />Hata</span>
                          : <span className="flex items-center gap-1 text-green-500 text-xs"><CheckCircle className="w-3.5 h-3.5" />Tamam</span>
                        }
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Action Button */}
          <button
            className={`w-full py-3 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 ${
              isDark
                ? 'bg-primary-500 hover:bg-primary-600 text-white'
                : 'bg-primary-500 hover:bg-primary-600 text-white'
            }`}
          >
            <Database className="w-4 h-4" />
            Verileri Firestore'a Kaydet
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Import Info */}
      {!fileName && !isProcessing && (
        <div className={`mt-6 p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Desteklenen Formatlar</h3>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className={`p-4 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
              <h4 className={`text-sm font-medium mb-2 ${isDark ? 'text-primary-400' : 'text-primary-600'}`}>Telegram Formatı</h4>
              <div className={`text-xs font-mono space-y-1 ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>
                <p>DAİRE NO | SAYAÇ NO | SAYAÇ TİPİ</p>
                <p>1 | IS0001 | 4 (Isı)</p>
                <p>1 | SS0001 | 6 (Su)</p>
              </div>
            </div>
            <div className={`p-4 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
              <h4 className={`text-sm font-medium mb-2 ${isDark ? 'text-primary-400' : 'text-primary-600'}`}>Polimeter Formatı</h4>
              <div className={`text-xs font-mono space-y-1 ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>
                <p>blok | daire | tip | ıd2</p>
                <p>A | 1 | 4 | 1001</p>
                <p>A | 2 | 6 | 1002</p>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
