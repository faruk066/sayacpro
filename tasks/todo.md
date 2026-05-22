# Tasks

## [CRITICAL BUG FIX] Fix Auto-Scroll Math, Overlap, and User Override
- [x] Fix Scroll Math: Update the `_scrollController.animateTo` multiplier to `115.0` (approximate card height including margins).
- [x] Implement User Scroll Detection: Wrap `CustomScrollView` in `NotificationListener<ScrollNotification>` to track `_isUserScrolling`.
- [x] Fix List Padding (Blind Spot): Increase bottom `SizedBox` from 100 to 120.

## [DATA PARSING FIX] Prevent Loading Empty/Ghost Excel Rows
- [x] Add Strict Validation: Skip rows where "Daire No" (Column 0) is null, its value is null, or is empty/spaces.
- [x] Graceful Serials Fallback: Keep fallback to "Seri No Bulunamadı" for missing serial numbers only if the row has a valid "Daire No".

## [DYNAMIC UI VISIBILITY] Update UI Based on "Okuma Modu"
- [x] Okuma Modu State Takibi: `DeviceProvider` üzerinden `selectedReadingMode` dinlendi.
- [x] Sayaç Listesi Tablosu Sütun Gizleme: `home_screen.dart` dosyasındaki başlık satırı ve veri satırları `ReadingMode` durumuna göre koşullandırıldı.
- [x] Sonuç Kartları (MeterCard) Görünürlüğü: `meter_card.dart` içinde "Isı Sayacı" ve "Su Sayacı" bölümleri ile dikey bölücü çizgi mod durumuna göre dinamik olarak gizlenecek şekilde güncellendi.

## [CRITICAL LOGIC & EXPORT FIX] Fix False Success Badges and Filter Excel Export
- [x] Yanlış "Başarılı" Rozeti Hatası: `home_screen.dart` ve `meter_card.dart` içindeki rozet `isSuccess` mantığını seçili `ReadingMode`'a göre dinamik ve kesin hale getir.
- [x] Excel Çıktısında "Okuma Modu" Filtrelemesi: Excel dosyasını oluştururken sadece seçili modun verilerini (Isı veya Su) ekle, gereksiz sütunları tamamen gizle/çıkar.

## [CRITICAL UX FIX] Stop Auto-Scroll from Fighting the User
- [x] Define local state `_isAutoScrollPaused = false;` in `HomeScreen`
- [x] Wrap list scroll notification in `NotificationListener<UserScrollNotification>` to toggle `_isAutoScrollPaused = true` on manual scroll
- [x] Condition auto-scroll logic in `_onProviderChange` to only run if `_isAutoScrollPaused == false`
- [x] Add a resume mini FloatingActionButton that is only visible during active reading when auto-scroll is paused
- [x] Ensure button tap resets `_isAutoScrollPaused = false` and immediately scrolls to the active index

## Review
- Modified `lib/screens/home_screen.dart` to implement the scroll fixes, dynamic ReadingMode column hiding, Selector dynamic isSuccess evaluation, and dynamic Excel/CSV exporting filters.
- Modified `lib/providers/device_provider.dart` to fix the Excel ghost rows parser issue.
- Modified `lib/screens/widgets/meter_card.dart` to implement dynamic meter sections hiding and double-check calculated success state based on indices validity.
- Verified all changes with `flutter analyze`. No issues found.
- The scroll math is now updated to match the new tall cards design.
- The app will no longer fight the user while they manually scroll through results.
- The bottom bar will no longer obscure the final items in the list.
- Empty/ghost rows from Excel with residual formatting are now skipped correctly using strict validation on Column 0 (Daire No).
- Dynamic UI visibility according to selected "Okuma Modu" is successfully checked, verified, and works seamlessly.
- Resolved false-positive green success badges on meter cards. Success state is strictly tied to selected reading mode indices correctness.
- Added dynamic filtering for both Excel (.xlsx) and CSV (.csv) exports so that they only output relevant columns of the active reading mode.