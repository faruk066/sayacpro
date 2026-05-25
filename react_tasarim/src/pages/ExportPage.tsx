import React, { useState } from 'react';
import { useTheme } from '../contexts/ThemeContext';
import {
  Download,
  FileText,
  FileSpreadsheet,
  Database,
  CheckCircle2,
  Settings2,
  Copy,
  Check,
  Clock,
  Filter,
} from 'lucide-react';

type ExportFormat = 'csv' | 'excel' | 'json';
type ExportScope = 'all' | 'heat' | 'water' | 'synced' | 'pending';

const exportTemplates = [
  { id: 'full', label: 'Tam Rapor', desc: 'Tüm sayaç verileri ve okumalar', icon: Database },
  { id: 'readings', label: 'Okuma Raporu', desc: 'Sadece okuma kayıtları', icon: FileText },
  { id: 'meters', label: 'Sayaç Listesi', desc: 'Sayaç bilgileri ve durumları', icon: FileSpreadsheet },
];

export const ExportPage: React.FC = () => {
  const { theme } = useTheme();
  const isDark = theme === 'dark';

  const [selectedFormat, setSelectedFormat] = useState<ExportFormat>('csv');
  const [selectedScope, setSelectedScope] = useState<ExportScope>('all');
  const [selectedTemplate, setSelectedTemplate] = useState('full');
  const [isExporting, setIsExporting] = useState(false);
  const [exportComplete, setExportComplete] = useState(false);
  const [copied, setCopied] = useState(false);
  const [includeHeaders, setIncludeHeaders] = useState(true);
  const [groupByBlock, setGroupByBlock] = useState(false);
  const [separator, setSeparator] = useState<'comma' | 'semicolon' | 'tab'>('semicolon');

  const handleExport = async () => {
    setIsExporting(true);
    setExportComplete(false);
    await new Promise((r) => setTimeout(r, 2000));
    setIsExporting(false);
    setExportComplete(true);
  };

  const handleCopyPreview = () => {
    const sampleData = `Daire;Blok;Tip;Sayaç No;Son Okuma;Birim;Durum
A-01;A;Isı;IS0001;1245.8;kWh;Aktif
A-02;A;Su;SS0017;567.2;L;Aktif
A-03;A;Isı;IS0003;2156.3;kWh;Aktif
B-01;B;Isı;IS0017;892.1;kWh;Beklemede
B-02;B;Su;SS0021;382.4;L;Aktif`;
    navigator.clipboard.writeText(sampleData);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const formatLabel = (f: ExportFormat): string => {
    const labels: Record<ExportFormat, string> = { csv: 'CSV', excel: 'Excel (XLSX)', json: 'JSON' };
    return labels[f];
  };

  const scopeLabel = (s: ExportScope): string => {
    const labels: Record<ExportScope, string> = { all: 'Tüm Veriler', heat: 'Sadece Isı Sayaçları', water: 'Sadece Su Sayaçları', synced: 'Senkronize Edilmiş', pending: 'Senkronize Bekleyen' };
    return labels[s];
  };

  return (
    <div className="animate-fade-in">
      <div className="mb-6">
        <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>Veri Dışa Aktarma</h2>
        <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Sayaç verilerini CSV, Excel veya JSON formatında dışa aktarın</p>
      </div>

      {/* Export Templates */}
      <div className={`p-5 rounded-2xl mb-6 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Şablon Seçimi</h3>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {exportTemplates.map((tpl) => (
            <button
              key={tpl.id}
              onClick={() => setSelectedTemplate(tpl.id)}
              className={`p-4 rounded-xl border-2 text-left transition-all ${
                selectedTemplate === tpl.id
                  ? isDark ? 'border-primary-500 bg-primary-500/10' : 'border-primary-500 bg-primary-50'
                  : isDark ? 'border-dark-border hover:border-dark-border/70' : 'border-gray-200 hover:border-gray-300'
              }`}
            >
              <tpl.icon className={`w-5 h-5 mb-2 ${selectedTemplate === tpl.id ? 'text-primary-500' : isDark ? 'text-gray-400' : 'text-gray-500'}`} />
              <p className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{tpl.label}</p>
              <p className={`text-xs mt-1 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{tpl.desc}</p>
            </button>
          ))}
        </div>
      </div>

      {/* Format Selection */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* Export Format */}
        <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Format</h3>
          <div className="space-y-2">
            {(['csv', 'excel', 'json'] as ExportFormat[]).map((fmt) => (
              <button
                key={fmt}
                onClick={() => setSelectedFormat(fmt)}
                className={`w-full flex items-center justify-between p-3 rounded-xl transition-all ${
                  selectedFormat === fmt
                    ? isDark ? 'bg-primary-600/20 border border-primary-500/50' : 'bg-primary-50 border border-primary-200'
                    : isDark ? 'bg-dark-card border border-dark-border hover:border-dark-border/70' : 'bg-gray-50 border border-gray-100 hover:border-gray-200'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Download className={`w-4 h-4 ${selectedFormat === fmt ? 'text-primary-500' : isDark ? 'text-gray-400' : 'text-gray-500'}`} />
                  <span className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{formatLabel(fmt)}</span>
                </div>
                {selectedFormat === fmt && <CheckCircle2 className="w-4 h-4 text-primary-500" />}
              </button>
            ))}
          </div>

          {/* Separator */}
          {selectedFormat === 'csv' && (
            <div className="mt-4">
              <label className={`text-xs font-medium ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Ayırıcı Karakter</label>
              <div className="flex gap-2 mt-2">
                {([['semicolon', ';'], ['comma', ','], ['tab', 'Tab']] as const).map(([val, label]) => (
                  <button
                    key={val}
                    onClick={() => setSeparator(val)}
                    className={`px-3 py-1.5 rounded-lg text-sm font-mono transition-colors ${
                      separator === val
                        ? 'bg-primary-500 text-white'
                        : isDark ? 'bg-dark-card text-gray-300' : 'bg-gray-100 text-gray-600'
                    }`}
                  >
                    {label}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Scope & Options */}
        <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
          <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Veri Kapsamı</h3>
          <div className="relative mb-4">
            <select
              value={selectedScope}
              onChange={(e) => setSelectedScope(e.target.value as ExportScope)}
              className={`w-full px-3 py-2.5 rounded-xl text-sm border cursor-pointer outline-none ${
                isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'
              }`}
            >
              <option value="all">Tüm Veriler</option>
              <option value="heat">Sadece Isı Sayaçları</option>
              <option value="water">Sadece Su Sayaçları</option>
              <option value="synced">Senkronize Edilmiş</option>
              <option value="pending">Senkronize Bekleyen</option>
            </select>
            <Filter className={`absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 pointer-events-none ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
          </div>

          <div className="space-y-3">
            {[
              { label: 'Başlık Satırı Ekle', checked: includeHeaders, onChange: () => setIncludeHeaders(!includeHeaders) },
              { label: 'Bloklara Göre Grupla', checked: groupByBlock, onChange: () => setGroupByBlock(!groupByBlock) },
            ].map((opt) => (
              <label key={opt.label} className={`flex items-center justify-between p-3 rounded-xl cursor-pointer ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
                <span className={`text-sm ${isDark ? 'text-gray-300' : 'text-gray-600'}`}>{opt.label}</span>
                <div className={`relative w-10 h-6 rounded-full transition-colors ${opt.checked ? 'bg-primary-500' : isDark ? 'bg-dark-border' : 'bg-gray-300'}`} onClick={opt.onChange}>
                  <div className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${opt.checked ? 'left-4.5 translate-x-0' : 'left-0.5'}`} />
                </div>
              </label>
            ))}
          </div>
        </div>
      </div>

      {/* Preview */}
      <div className={`p-5 rounded-2xl mb-6 ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <div className="flex items-center justify-between mb-4">
          <h3 className={`text-sm font-semibold ${isDark ? 'text-white' : 'text-gray-900'}`}>Önizleme</h3>
          <button
            onClick={handleCopyPreview}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
              isDark ? 'bg-dark-card text-gray-300 hover:text-white' : 'bg-gray-100 text-gray-600 hover:text-gray-900'
            }`}
          >
            {copied ? <Check className="w-3.5 h-3.5 text-green-500" /> : <Copy className="w-3.5 h-3.5" />}
            {copied ? 'Kopyalandı!' : 'Kopyala'}
          </button>
        </div>
        <pre className={`p-4 rounded-xl text-xs font-mono overflow-x-auto ${isDark ? 'bg-dark-bg text-gray-300' : 'bg-gray-50 text-gray-600'}`}>
{`Daire;Blok;Tip;Sayaç No;Son Okuma;Birim;Durum
A-01;A;Isı;IS0001;1245.8;kWh;Aktif
A-02;A;Su;SS0017;567.2;L;Aktif
A-03;A;Isı;IS0003;2156.3;kWh;Aktif
B-01;B;Isı;IS0017;892.1;kWh;Beklemede
B-02;B;Su;SS0021;382.4;L;Aktif
C-01;C;Isı;IS0033;3421.5;kWh;Aktif
... (${selectedScope})`}
        </pre>
      </div>

      {/* Export Button */}
      <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
        <div className="flex items-center justify-between">
          <div>
            <p className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>
              {formatLabel(selectedFormat)} - {scopeLabel(selectedScope)}
            </p>
            <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>
              Veri dosyası oluşturulacak
            </p>
          </div>
          <button
            onClick={handleExport}
            disabled={isExporting}
            className={`flex items-center gap-2 px-6 py-3 rounded-xl text-sm font-semibold transition-all ${
              isExporting
                ? 'bg-gray-500 cursor-wait'
                : exportComplete
                ? 'bg-green-500 hover:bg-green-600'
                : 'bg-primary-500 hover:bg-primary-600'
            } text-white`}
          >
            {isExporting ? (
              <>
                <Clock className="w-4 h-4 animate-spin" />
                Oluşturuluyor...
              </>
            ) : exportComplete ? (
              <>
                <CheckCircle2 className="w-4 h-4" />
                Tamamlandı!
              </>
            ) : (
              <>
                <Settings2 className="w-4 h-4" />
                Dışa Aktar
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
