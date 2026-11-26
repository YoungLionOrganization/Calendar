# YoungLion Calendar

[![Qt 6.8+](https://img.shields.io/badge/Qt-6.8%2B-41cd52)](https://www.qt.io/)
[![Linux CI](https://github.com/YoungLionOrganization/Calendar/actions/workflows/linux.yml/badge.svg?branch=main)](https://github.com/YoungLionOrganization/Calendar/actions/workflows/linux.yml)
[![GPLv3](https://img.shields.io/badge/Lisans-GPLv3-blue)](COPYING)

YoungLion Calendar, kişisel etkinlikleri yıl, ay, hafta ve ajanda görünümlerinde düzenleyen bir Qt Quick takvimi. Yerel etkinlikler çevrimdışı çalışır. Uygulama Türkçe, Azerbaycanca ve İngilizce kullanılabilir.

## Linux’ta çalıştır

Qt 6.8 veya daha yeni bir masaüstü kiti, SQLite Qt sürücüsü, CMake, C++ derleyicisi ve libical geliştirme paketi gerekir.

```sh
qt-cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
./build/CalendarApp
```

Masaüstü menüsü ve dosya ilişkisi için `cmake --install build` ile kur. Uygulamanın **Ayarlar** ekranında ICS dosyaları için varsayılan uygulamayı seçebilirsin. Dosya yöneticisinden açılan ICS dosyaları içe aktarma onayına gelir. Birden fazla takvimin varsa hedefi onay ekranında seçebilirsin.

Dağıtım paket tarifleri `packaging` altında. [Linux derleme iş akışı](.github/workflows/linux.yml) Arch, Debian, Ubuntu, Fedora ve Alpine için derleme, test ve kurulum denetimini tanımlar.

| Hedef | Derleme ve paket tarifi |
| --- | --- |
| Arch | `packaging/arch/PKGBUILD` |
| Debian ve Ubuntu | `packaging/deb/debian/` |
| Fedora | `packaging/fedora/younglion-calendar.spec` |
| Alpine | `packaging/alpine/APKBUILD` |
| Flatpak | `packaging/flatpak/xyz.younglion.Calendar.yml` |

Arch ve Fedora tarifleri `younglion-calendar-0.2.0.tar.gz` kaynak arşivini kullanır. Alpine’da kaynak arşivini tarifin yanına koyduktan sonra `abuild checksum` çalıştır. Debian ve Ubuntu için `packaging/deb/debian` dizinini kaynak ağacının köküne kopyalayıp `dpkg-buildpackage -us -uc` çalıştır. Flatpak tarifini proje kökünden `flatpak-builder --user --install build-flatpak packaging/flatpak/xyz.younglion.Calendar.yml` ile çalıştırabilirsin. Bunun için KDE SDK ve Platform’un tarifte belirtilen sürümleri gerekir.

## Android

Android için Qt kiti, kitin desteklediği SDK ve NDK, JDK ve hedef ABI için derlenmiş libical gerekir. `qt-cmake` komutunu Android kitinden çalıştır ve `LibIcal_DIR` ile hedef libical’ın CMake paketini göster. `cmake --build build-android --target apk` APK üretir.

Ayarlar’dan bildirimleri etkinleştirip Android izinlerini verebilirsin. Android kesin alarm izni vermediğinde sistem hatırlatıcıyı geciktirebilir. **Sistem takvimleri** bölümünde Calendar Provider erişimini isteyebilir ve bağlanacak takvimi seçebilirsin. Uygulama düzenleyebildiği kayıtları kaynağa yazar. Salt okunur kaynak ve karmaşık tekrarlar düzenlemeye kapalı gösterilir.

## Veriler ve Design Studio

- Masaüstü ilk açılışta eski `YoungLion/Calendar/events.ini` verisini SQLite’a taşır. Geçiş işlemi tamamlanana kadar veritabanı kayıtları değişmez. Eski dosya yerinde kalır. Ayarlar mevcut INI konumunda Qt Settings üzerinden okunur.
- Ay görünümü seçili yıl ile önceki ve sonraki yılın ay verilerini ayrı bir Qt iş parçacığında hazırlar. Yalnızca görünen ay ve komşu sayfaları canlı tutulur.
- `Calendar.qmlproject` Qt Design Studio’da açılır. Önizleme oturum içi örnek etkinlikleri kullanır. C++ veri deposunu ve platform işlevlerini doğrulamak için uygulamayı CMake üzerinden çalıştır.
- Lisans metni `COPYING` dosyasındadır. Paketlerdeki Qt Design Studio bileşenleri kendi kaynak bildirimlerini taşır.

## Doğrulama kapsamı

SQLite testleri veri taşıma, yeniden açılış, ICS dosyasını tekrar içe aktarma, karmaşık bir ICS tekrar kuralını koruma ve tek tekrar düzenlemeyi kapsar. QML testleri telefon, tablet ve masaüstü genişlikleri ile yıl sınırını, önbellek tahliyesini ve saat dilimi kaynaklı gün değişimini dener.

10.000 tek seferlik etkinlik ve 100 Aralık–Ocak geçişiyle yapılan Qt 6.12.0 ekran dışı QML karşılaştırmasında yüzde 95’lik kare aralığı eski arşivde yaklaşık 229 ms, yeni sürümde 42 ms oldu. Test sürecinin tepe belleği yaklaşık 170 MiB’den 244 MiB’ye çıktı. Bu ölçüm kaynak önizlemesindeki sentetik yükü gösterir. Yerel Release sürümü ve fiziksel cihazlar için aynı metrikler henüz ölçülmedi.

GNOME Evolution Data Server ve KDE Akonadi takvim bağlayıcıları bu teslimatta eksik. Flatpak portallarının canlı oturum akışı ve Android Calendar Provider ile bildirim izinlerinin cihaz üzerindeki akışları doğrulama bekliyor.
