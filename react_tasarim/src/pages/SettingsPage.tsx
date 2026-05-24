import React, { useState } from 'react';
import { useTheme } from '../contexts/ThemeContext';
import {
  Sun,
  Moon,
  Globe,
  Database,
  Shield,
  Wifi,
  Key,
  Trash2,
  HardDrive,
  RotateCcw,
  Save,
  CheckCircle2,
  Monitor,
  Cloud,
  Lock,
} from 'lucide-react';

type SettingSection = 'general' | 'connection' | 'data' | 'security';

interface ToggleOption {
  label: string;
  desc: string;
  checked: boolean;
  onChange: () => void;
}

const ToggleSetting: React.FC<{ option: ToggleOption; isDark: boolean }> = ({ option, isDark }) => (
  <label className={`flex items-center justify-between p-4 rounded-xl cursor-pointer transition-colors ${isDark ? 'bg-dark-card hover:bg-dark-card/80' : 'bg-gray-50 hover:bg-gray-100'}`}>
    <div>
      <p className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{option.label}</p>
      <p className={`text-xs mt-0.5 ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>{option.desc}</p>
    </div>
    <button
      onClick={option.onChange}
      className={`relative w-11 h-6 rounded-full transition-colors ${option.checked ? 'bg-primary-500' : isDark ? 'bg-dark-border' : 'bg-gray-300'}`}
    >
      <div className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${option.checked ? 'translate-x-5' : 'translate-x-0.5'}`} />
    </button>
  </label>
);

export const SettingsPage: React.FC = () => {
  const { theme, toggleTheme } = useTheme();
  const isDark = theme === 'dark';
  const [activeSection, setActiveSection] = useState<SettingSection>('general');
  const [saved, setSaved] = useState(false);

  // General settings
  const [language, setLanguage] = useState('tr');
  const [autoSync, setAutoSync] = useState(true);
  const [soundEffects, setSoundEffects] = useState(false);
  const [vibration, setVibration] = useState(true);

  // Connection settings
  const [mbusBaudRate, setMbusBaudRate] = useState('2400');
  const [firebaseRegion] = useState('europe-west1');
  const [offlineMode, setOfflineMode] = useState(false);
  const [autoRetry, setAutoRetry] = useState(true);

  // Data settings
  const [cacheSize] = useState('24.5 MB');
  const [totalReadings] = useState('12,847');
  const [clearOnLogout, setClearOnLogout] = useState(true);

  // Security settings
  const [biometric, setBiometric] = useState(true);
  const [autoLock, setAutoLock] = useState(true);
  const [encryptLocal, setEncryptLocal] = useState(true);

  const handleSave = () => {
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const sections: { id: SettingSection; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'general', label: 'Genel', icon: Globe },
    { id: 'connection', label: 'Bağlantı', icon: Wifi },
    { id: 'data', label: 'Veri', icon: Database },
    { id: 'security', label: 'Güvenlik', icon: Shield },
  ];

  return (
    <div className="animate-fade-in">
      <div className="mb-6">
        <h2 className={`text-xl font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>Ayarlar</h2>
        <p className={`text-sm ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Uygulama yapılandırması ve tercihler</p>
      </div>

      {/* Section Tabs */}
      <div className={`flex gap-2 mb-6 overflow-x-auto pb-2`}>
        {sections.map((sec) => (
          <button
            key={sec.id}
            onClick={() => setActiveSection(sec.id)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium whitespace-nowrap transition-colors ${
              activeSection === sec.id
                ? isDark ? 'bg-primary-600/20 text-primary-400' : 'bg-primary-50 text-primary-600'
                : isDark ? 'text-gray-400 hover:bg-dark-surface' : 'text-gray-500 hover:bg-gray-100'
            }`}
          >
            <sec.icon className="w-4 h-4" />
            {sec.label}
          </button>
        ))}
      </div>

      {/* General Settings */}
      {activeSection === 'general' && (
        <div className="space-y-4">
          {/* Theme */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Tema</h3>
            <div className="grid grid-cols-3 gap-3">
              {[
                { id: 'light', label: 'Açık', icon: Sun, color: 'from-yellow-400 to-orange-500' },
                { id: 'dark', label: 'Koyu', icon: Moon, color: 'from-indigo-500 to-purple-600' },
                { id: 'system', label: 'Sistem', icon: Monitor, color: 'from-gray-400 to-gray-600' },
              ].map((t) => (
                <button
                  key={t.id}
                  onClick={() => { if (t.id === 'dark') toggleTheme(); else if (t.id === 'light') toggleTheme(); }}
                  className={`p-4 rounded-xl text-center transition-all ${
                    (t.id === 'dark' && isDark) || (t.id === 'light' && !isDark)
                      ? isDark ? 'bg-primary-600/20 border-2 border-primary-500' : 'bg-primary-50 border-2 border-primary-500'
                      : isDark ? 'bg-dark-card border-2 border-dark-border' : 'bg-gray-50 border-2 border-gray-200'
                  }`}
                >
                  <div className={`w-10 h-10 mx-auto rounded-xl bg-gradient-to-br ${t.color} flex items-center justify-center mb-2`}>
                    <t.icon className="w-5 h-5 text-white" />
                  </div>
                  <p className={`text-xs font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{t.label}</p>
                </button>
              ))}
            </div>
          </div>

          {/* Language */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Dil ve Bölge</h3>
            <select
              value={language}
              onChange={(e) => setLanguage(e.target.value)}
              className={`w-full px-4 py-2.5 rounded-xl text-sm border outline-none ${
                isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'
              }`}
            >
              <option value="tr">Türkçe</option>
              <option value="en">English</option>
              <option value="de">Deutsch</option>
            </select>
          </div>

          {/* Toggles */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Bildirimler ve Ses</h3>
            <div className="space-y-3">
              <ToggleSetting option={{ label: 'Otomatik Senkronizasyon', desc: 'Okumalar otomatik olarak Firestore\'a gönderilir', checked: autoSync, onChange: () => setAutoSync(!autoSync) }} isDark={isDark} />
              <ToggleSetting option={{ label: 'Ses Efektleri', desc: 'İşlem tamamlandığında ses çal', checked: soundEffects, onChange: () => setSoundEffects(!soundEffects) }} isDark={isDark} />
              <ToggleSetting option={{ label: 'Titreşim', desc: 'Başarılı okumada titreşim bildirimi', checked: vibration, onChange: () => setVibration(!vibration) }} isDark={isDark} />
            </div>
          </div>

          {/* Save */}
          <button
            onClick={handleSave}
            className={`w-full py-3 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 ${
              saved
                ? 'bg-green-500 text-white'
                : isDark ? 'bg-primary-500 hover:bg-primary-600 text-white' : 'bg-primary-500 hover:bg-primary-600 text-white'
            }`}
          >
            {saved ? <><CheckCircle2 className="w-4 h-4" />Kaydedildi!</> : <><Save className="w-4 h-4" />Kaydet</>}
          </button>
        </div>
      )}

      {/* Connection Settings */}
      {activeSection === 'connection' && (
        <div className="space-y-4">
          {/* M-Bus Config */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 flex items-center gap-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              <Wifi className="w-4 h-4 text-primary-500" />
              M-Bus Bağlantısı
            </h3>
            <div className="space-y-4">
              <div>
                <label className={`text-xs font-medium mb-1 block ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Baud Rate</label>
                <select
                  value={mbusBaudRate}
                  onChange={(e) => setMbusBaudRate(e.target.value)}
                  className={`w-full px-4 py-2.5 rounded-xl text-sm border outline-none ${
                    isDark ? 'bg-dark-bg border-dark-border text-gray-200' : 'bg-gray-50 border-gray-200 text-gray-700'
                  }`}
                >
                  <option value="2400">2400 (Varsayılan)</option>
                  <option value="4800">4800</option>
                  <option value="9600">9600</option>
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className={`p-3 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
                  <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Bağlantı</p>
                  <div className="flex items-center gap-1.5 mt-1">
                    <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse-dot" />
                    <span className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>Bağlı</span>
                  </div>
                </div>
                <div className={`p-3 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
                  <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Port</p>
                  <p className={`text-sm font-mono font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>USB0</p>
                </div>
              </div>
            </div>
          </div>

          {/* Firebase */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 flex items-center gap-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              <Cloud className="w-4 h-4 text-blue-500" />
              Firebase Firestore
            </h3>
            <div className="space-y-3">
              <div className={`p-3 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Bölge</p>
                <p className={`text-sm font-mono font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>{firebaseRegion}</p>
              </div>
              <ToggleSetting option={{ label: 'Çevrimdışı Mod', desc: 'İnternet bağlantısı olmadan yerel depolama', checked: offlineMode, onChange: () => setOfflineMode(!offlineMode) }} isDark={isDark} />
              <ToggleSetting option={{ label: 'Otomatik Tekrar Dene', desc: 'Başarısız senkronizasyonlarda otomatik tekrar', checked: autoRetry, onChange: () => setAutoRetry(!autoRetry) }} isDark={isDark} />
            </div>
          </div>

          <button onClick={handleSave} className={`w-full py-3 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 ${saved ? 'bg-green-500 text-white' : isDark ? 'bg-primary-500 hover:bg-primary-600 text-white' : 'bg-primary-500 hover:bg-primary-600 text-white'}`}>
            {saved ? <><CheckCircle2 className="w-4 h-4" />Kaydedildi!</> : <><Save className="w-4 h-4" />Kaydet</>}
          </button>
        </div>
      )}

      {/* Data Settings */}
      {activeSection === 'data' && (
        <div className="space-y-4">
          {/* Storage Info */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 flex items-center gap-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              <HardDrive className="w-4 h-4 text-primary-500" />
              Depolama Bilgisi
            </h3>
            <div className="grid grid-cols-2 gap-3">
              <div className={`p-4 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
                <Database className={`w-5 h-5 mb-2 ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
                <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{cacheSize}</p>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Önbellek</p>
              </div>
              <div className={`p-4 rounded-xl ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
                <Database className={`w-5 h-5 mb-2 ${isDark ? 'text-gray-400' : 'text-gray-500'}`} />
                <p className={`text-lg font-bold ${isDark ? 'text-white' : 'text-gray-900'}`}>{totalReadings}</p>
                <p className={`text-xs ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>Okuma Kaydı</p>
              </div>
            </div>
          </div>

          {/* Data Options */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Veri Yönetimi</h3>
            <div className="space-y-3">
              <ToggleSetting option={{ label: 'Çıkış Yapınca Temizle', desc: 'Güvenli olmayan veriler oturum sonunda silinir', checked: clearOnLogout, onChange: () => setClearOnLogout(!clearOnLogout) }} isDark={isDark} />
            </div>
          </div>

          {/* Danger Zone */}
          <div className={`p-5 rounded-2xl border ${isDark ? 'border-red-500/20 bg-red-500/5' : 'border-red-200 bg-red-50'}`}>
            <h3 className={`text-sm font-semibold mb-4 flex items-center gap-2 ${isDark ? 'text-red-400' : 'text-red-600'}`}>
              <Trash2 className="w-4 h-4" />
              Tehlike Bölgesi
            </h3>
            <div className="space-y-3">
              <button className={`w-full flex items-center justify-between p-3 rounded-xl transition-colors ${isDark ? 'bg-red-500/10 hover:bg-red-500/20' : 'bg-red-100 hover:bg-red-200'}`}>
                <div className="flex items-center gap-3">
                  <RotateCcw className="w-4 h-4 text-red-500" />
                  <div className="text-left">
                    <p className={`text-sm font-medium ${isDark ? 'text-red-300' : 'text-red-700'}`}>Okumaları Sıfırla</p>
                    <p className={`text-xs ${isDark ? 'text-red-400/70' : 'text-red-500'}`}>Tüm yerel okuma kayıtları silinir</p>
                  </div>
                </div>
              </button>
              <button className={`w-full flex items-center justify-between p-3 rounded-xl transition-colors ${isDark ? 'bg-red-500/10 hover:bg-red-500/20' : 'bg-red-100 hover:bg-red-200'}`}>
                <div className="flex items-center gap-3">
                  <Trash2 className="w-4 h-4 text-red-500" />
                  <div className="text-left">
                    <p className={`text-sm font-medium ${isDark ? 'text-red-300' : 'text-red-700'}`}>Tüm Verileri Temizle</p>
                    <p className={`text-xs ${isDark ? 'text-red-400/70' : 'text-red-500'}`}>Sayaç ve okuma verileri tamamen silinir</p>
                  </div>
                </div>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Security Settings */}
      {activeSection === 'security' && (
        <div className="space-y-4">
          {/* Auth */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 flex items-center gap-2 ${isDark ? 'text-white' : 'text-gray-900'}`}>
              <Lock className="w-4 h-4 text-primary-500" />
              Kimlik Doğrulama
            </h3>
            <div className={`p-4 rounded-xl mb-4 ${isDark ? 'bg-dark-card' : 'bg-gray-50'}`}>
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary-500 to-primary-700 flex items-center justify-center">
                  <Key className="w-5 h-5 text-white" />
                </div>
                <div>
                  <p className={`text-sm font-medium ${isDark ? 'text-white' : 'text-gray-900'}`}>API Anahtarı</p>
                  <p className={`text-xs font-mono ${isDark ? 'text-gray-400' : 'text-gray-500'}`}>AIzaS...8bF2k</p>
                </div>
              </div>
            </div>
          </div>

          {/* Security Options */}
          <div className={`p-5 rounded-2xl ${isDark ? 'bg-dark-surface border border-dark-border' : 'bg-white border border-gray-100 shadow-sm'}`}>
            <h3 className={`text-sm font-semibold mb-4 ${isDark ? 'text-white' : 'text-gray-900'}`}>Güvenlik</h3>
            <div className="space-y-3">
              <ToggleSetting option={{ label: 'Biyometrik Doğrulama', desc: 'Parmak izi veya yüz tanıma ile giriş', checked: biometric, onChange: () => setBiometric(!biometric) }} isDark={isDark} />
              <ToggleSetting option={{ label: 'Otomatik Kilit', desc: '5 dakika hareketsizlikte oturum kilitle', checked: autoLock, onChange: () => setAutoLock(!autoLock) }} isDark={isDark} />
              <ToggleSetting option={{ label: 'Yerel Şifreleme', desc: 'Hassas veriler flutter_secure_storage ile saklanır', checked: encryptLocal, onChange: () => setEncryptLocal(!encryptLocal) }} isDark={isDark} />
            </div>
          </div>

          <button onClick={handleSave} className={`w-full py-3 rounded-xl text-sm font-semibold transition-all flex items-center justify-center gap-2 ${saved ? 'bg-green-500 text-white' : isDark ? 'bg-primary-500 hover:bg-primary-600 text-white' : 'bg-primary-500 hover:bg-primary-600 text-white'}`}>
            {saved ? <><CheckCircle2 className="w-4 h-4" />Kaydedildi!</> : <><Save className="w-4 h-4" />Kaydet</>}
          </button>
        </div>
      )}
    </div>
  );
};
