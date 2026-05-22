# 🏢 Sayaç Pro | Cloud SaaS Meter Reading Platform

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![M-Bus](https://img.shields.io/badge/Protocol-M--Bus%20%2F%20RS485-red?style=for-the-badge)](#)

[🇹🇷 Türkçe Sürüm İçin Tıklayın (Turkish Version)](#-türkçe-sürüm-sayaç-pro)

An industrial, cross-platform meter reading and management system. **Sayaç Pro** bridges the gap between low-level hardware communication (RS485/M-Bus) and high-level Cloud SaaS architecture. It operates as an offline-first mobile reading tool in the field and a real-time web dashboard in the office.

## 🚀 Key Features

* **Dual Architecture (Mobile + Web):** * **Mobile:** Communicates directly with hardware via USB/Serial or Bluetooth to read Water and Heat meters using the M-Bus protocol.
  * **Web Dashboard:** A completely hardware-isolated SaaS panel that listens to Firebase in real-time, allowing managers to monitor field operations live.
* **Hardware Isolation & Conditional Imports:** Uses advanced Dart stubbing (`mbus_stub.dart`) to ensure hardware packages (`usb_serial`, `flutter_bluetooth_serial`, `dart:io`) are never compiled for the web, preventing crashes and maintaining a single codebase.
* **Real-time Cloud Sync:** Meter readings are parsed (HEX to structured data), verified via CRC, and instantly pushed to Firebase Firestore (`sites/{siteId}/meters`).
* **Dynamic Proxy Provider:** Utilizes an `AppDataProvider` base class to dynamically switch state sources. The UI seamlessly listens to `DeviceProvider` on mobile and `CloudProvider` on the web without messy conditional UI code.
* **Advanced Excel I/O:** Import and export operations are fully supported on both mobile and web (`file_picker` and `universal_html` with Anchor elements).
* **Smart UI Filtering:** Dynamically hides/shows data columns based on the selected "Reading Mode" (Water Only, Heat Only, or Both) without breaking the strict `height: 48` layout constraints.

## 🛠️ Tech Stack & Architecture
* **Framework:** Flutter (Android, Web)
* **Backend:** Firebase (Cloud Firestore)
* **State Management:** Provider (Proxy Architecture)
* **Hardware Protocols:** M-Bus, RS485, Serial Port, Bluetooth
* **File Handling:** `excel`, `file_picker`, `universal_html`

---

# 🇹🇷 Türkçe Sürüm: Sayaç Pro

Düşük seviyeli donanım haberleşmesini (RS485/M-Bus), yüksek seviyeli Cloud SaaS mimarisiyle birleştiren endüstriyel, çapraz platform sayaç okuma ve yönetim sistemi. Sahada donanıma bağlı bir mobil okuma terminali, ofiste ise gerçek zamanlı bir web yönetim paneli olarak tek kod tabanından çalışır.

## 🚀 Temel Özellikler

* **Çift Yönlü Mimari (Mobil + Web):**
  * **Mobil Sürüm:** Su ve Isı sayaçlarını M-Bus protokolüyle okumak için USB/Seri Port veya Bluetooth üzerinden donanımla doğrudan iletişim kurar.
  * **Web Dashboard:** Firebase'i gerçek zamanlı dinleyen, donanımdan tamamen izole edilmiş SaaS paneli. Yöneticilerin sahadaki okuma operasyonlarını saniye saniye izlemesini sağlar.
* **Donanım İzolasyonu (Koşullu İçe Aktarma):** Gelişmiş Dart "stub" yapısı (`mbus_stub.dart`) sayesinde donanım paketleri (`usb_serial`, `dart:io`) web ortamında asla derlenmez. Bu sayede tek kod tabanı "Unsupported operation" hatası vermeden iki platformda da çalışır.
* **Gerçek Zamanlı Bulut Senkronizasyonu:** Sayaçlardan gelen M-Bus HEX paketleri ayrıştırılır (parse edilir), CRC kontrolünden geçer ve anında Firebase Firestore'a (`sites/{siteId}/meters`) aktarılır.
* **Dinamik Proxy Provider Mantığı:** `AppDataProvider` soyut sınıfı sayesinde arayüz, verinin nereden geldiğini bilmeden çalışır. Mobil tarafta `DeviceProvider`'ı, web tarafında ise `CloudProvider`'ı dinleyerek "spaghetti" kod oluşumunu engeller.
* **Evrensel Excel Girdi/Çıktısı (I/O):** Excel yükleme ve rapor dışa aktarma (export) işlemleri hem mobil cihazlarda hem de web tarayıcılarında (`universal_html` Anchor elementleri ile) tam uyumlu çalışır.
* **Akıllı UI Filtreleme:** Seçilen "Okuma Modu"na (Sadece Su, Sadece Isı, Her İkisi) göre listedeki gereksiz sütunları akıllıca gizler/gösterir. Sayfa yeniden çizimi (full-page rebuild) engellenerek maksimum FPS performansı sağlanmıştır.

## 🛠️ Kullanılan Teknolojiler ve Mimari
* **Framework:** Flutter (Android, Web)
* **Veritabanı:** Firebase (Cloud Firestore)
* **Durum Yönetimi (State Management):** Provider (Proxy Mimarisi)
* **Donanım Protokolleri:** M-Bus, RS485, Seri Port, Bluetooth
* **Dosya İşlemleri:** `excel`, `file_picker`, `universal_html`

## 📦 Kurulum ve Başlangıç

1. Projeyi klonlayın:
   ```bash
   git clone https://github.com/faruk066/sayacpro.git

2. Gerekli paketleri indirin:
   ```bash
   flutter pub get

3. Firebase entegrasyonu için FlutterFire CLI ile projenizi bağlayın:
   ```bash
   flutterfire configure

4. Uygulamayı çalıştırın:
   ```bash
   Mobil (Donanım Modu): flutter run -d android
   Web Dashboard (Canlı İzleme Modu): flutter run -d chrome


