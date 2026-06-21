# Docker MenuBar

macOS için Docker konteynerlerini yöneten MenuBar uygulaması.

## Özellikler

✅ **MenuBar ikonu**: Docker ikonu ile menü çubuğunda görüntülenir  
✅ **Dock'ta gözükmez**: Sadece menü çubuğunda çalışır  
✅ **Docker konteyner listesi**: Aktif ve durmuş konteynerları listeler  
✅ **Konteyner yönetimi**: Her konteyner için işlem menüleri  
✅ **Otomatik başlangıç**: Sistem açılışında otomatik çalışır  
✅ **Gerçek zamanlı güncelleme**: Her 5 saniyede menü otomatik güncellenir  
✅ **Çoklu dil desteği**: Türkçe ve İngilizce dil desteği  
✅ **Bağış desteği**: Tıklayınca IDDEF destek sayfası açılır

## Konteyner İşlemleri

Her Docker konteyneri için aşağıdaki işlemler mevcuttur:

- **Başlat** (durdurulmuş konteynerler için)
- **Durdur** (çalışan konteynerler için)  
- **Yeniden Başlat** (çalışan konteynerler için)
- **Bash Ekranını Aç** (Terminal'de bash oturumu açar)
- **Logları Göster** (Terminal'de logları izler)
- **Sil** (konteyneri kaldırır)

## Kurulum

1. Projeyi klonlayın:
   ```bash
   git clone [repo-url]
   cd DockerMenuBar
   ```

2. Xcode ile açın:
   ```bash
   open DockerMenuBar.xcodeproj
   ```

3. Uygulamayı derleyin ve çalıştırın (Cmd+R)

## Gereksinimler

- macOS 15.5 veya üzeri
- **Docker Engine** (Docker Desktop GEREKLİ DEĞİL!)
- Xcode 16 veya üzeri (geliştirme için)

### Docker Kurulumu

#### Seçenek 1: Homebrew ile Docker Engine
```bash
brew install docker
brew install colima  # Docker daemon için
colima start
```

#### Seçenek 2: Docker Desktop (isteğe bağlı)
Docker Desktop kurabilirsiniz ama gerekli değil.

#### Seçenek 3: Manuel Docker Engine Kurulumu
Docker Engine'i doğrudan kurabilirsiniz.

## Teknik Detaylar

- **SwiftUI** ve **AppKit** ile geliştirildi
- **NSStatusItem** ile MenuBar entegrasyonu
- **Process** sınıfı ile Docker CLI komutları
- **NSAppleScript** ile Terminal entegrasyonu
- **Launch Agent** ile otomatik başlangıç

## Güvenlik

Uygulama Docker komutlarını çalıştırabilmek için sandbox dışında çalışır. Bu güvenlik nedeniyle aşağıdaki izinler gereklidir:

- Network erişimi (Docker daemon bağlantısı)
- Apple Events (Terminal kontrolü)

## Kullanım

1. Uygulamayı başlattıktan sonra menü çubuğunda Docker ikonu görünecek
2. İkona tıklayın ve mevcut konteynerları görün
3. Her konteyner için alt menüden istediğiniz işlemi seçin
4. "Yenile" ile manuel güncelleme yapabilirsiniz
5. "Çıkış" ile uygulamayı kapatabilirsiniz

## Docker Durum Göstergeleri

- 🟢 Çalışan konteyner
- 🔴 Durdurulmuş konteyner

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'i push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## Dil Desteği

Uygulama şu dilleri destekler:

- **🇹🇷 Türkçe**: Varsayılan dil (sistem dilini otomatik tespit eder)
- **🇺🇸 İngilizce**: System Preferences > Language & Region'dan İngilizce seçtiğinizde aktif olur

### Dil Değiştirme

1. macOS **System Preferences** > **Language & Region** açın
2. **Preferred Languages** listesinde istediğiniz dili en üste çıkarın
3. Uygulamayı yeniden başlatın

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır.