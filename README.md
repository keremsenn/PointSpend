# 💎 PointSpend

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Lisans-MIT-blue.svg?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <strong>PointSpend</strong>, kullanıcıların günlük görevleri ve aktiviteleri tamamlayarak puan kazandığı, kazandıkları puanları ise çeşitli ödüllere veya harcamalara dönüştürebildiği modern bir <strong>Gamification (Oyunlaştırma) ve Ödül Takip Mobil Uygulamasıdır</strong>.
</p>

---

## 📱 Ekran Görüntüleri & Önizleme

> [!NOTE]
> Uygulama hem **Açık Tema (Light Mode)** hem de **Koyu Tema (Dark Mode)** desteğine sahiptir.

| Ana Sayfa & Puan Durumu | Aktiviteler & Görevler | Ödül Vitrini & Talep | Profil & Tema Yönetimi |
| :---: | :---: | :---: | :---: |
| 📊 | 🎯 | 🎁 | ⚙️ |
| Toplam puan, kampanyalar ve son işlemler | Günlük/periyodik aktiviteleri tamamlama | Puan karşılığı ödül satın alma ve geçmiş | Profil düzenleme, avatar yükleme & ayarlar |

---

## ✨ Temel Özellikler

- 🔐 **Kimlik Doğrulama & Kullanıcı Yönetimi:**
  - Firebase Authentication ile güvenli giriş ve kayıt.
  - Dinamik profil bilgileri ve profil fotoğrafı yükleme (Firebase Storage).

- 🎯 **Aktivite ve Görev Yönetimi:**
  - Özel aktiviteler ve görevler oluşturma, düzenleme ve silme.
  - Aktivite tamamlama ile anlık puan kazanma mekanizması.

- 🎁 **Ödül Mağazası & Harcama:**
  - Tanımlanan ödüller için puan harcama (Claim) sistemi.
  - Harcama geçmişi ve bakiye loglama (Point Transactions).

- 🔔 **Akıllı Bildirim Sistemi:**
  - Firebase Cloud Messaging (FCM) ve `flutter_local_notifications` entegrasyonu.
  - Bildirim geçmişi ekranı ve anlık sistem bilgilendirmeleri.

- 🌗 **Dinamik Tema Motoru:**
  - Material 3 destekli Açık ve Koyu tema seçenekleri.
  - `SharedPreferences` ile tema tercihini kalıcı saklama.

- 💎 **Premium / Satın Alma (Paywall):**
  - Uygulama içi satın alma diyaloğu ve paket seçenekleri.

---

## 🛠️ Kullanılan Teknolojiler ve Kütüphaneler

| Teknoloji / Kütüphane | Sürüm | Açıklama |
| :--- | :--- | :--- |
| **Flutter SDK** | `^3.8.1` | Çapraz platform UI kütüphanesi |
| **Firebase Core** | `^4.15.0` | Firebase temel altyapısı |
| **Cloud Firestore** | `^6.10.0` | NoSQL bulut veritabanı |
| **Firebase Auth** | `^6.7.0` | Kullanıcı kimlik doğrulama |
| **Firebase Storage** | `^13.6.0` | Görsel ve dosya depolama |
| **Firebase Messaging** | `^16.7.0` | Push bildirim servisi |
| **Flutter Local Notifications**| `^20.1.0` | Cihaz içi yerel bildirim yönetimi |
| **Shared Preferences** | `^2.5.2` | Yerel ayarlar ve tema saklama |
| **Image Picker** | `^1.2.1` | Galeri/kameradan görsel seçme |
| **URL Launcher** | `^6.3.2` | Harici bağlantıları açma |

---

## 📂 Proje Dizin Yapısı

```bash
lib/
├── core/
│   ├── constants/           # Uygulama metinleri ve Firestore koleksiyon isimleri
│   ├── theme/               # Açık/Koyu tema tanımları ve ThemeController
│   └── utils/               # URL açıcı ve genel yardımcı araçlar
├── models/                  # Firestore veri modelleri (User, Activity, Reward, vb.)
├── services/                # Firebase, Auth, Bildirim ve Veritabanı servisleri
├── views/                   # Kullanıcı arayüz ekranları (Screens)
│   ├── dialogs/             # Ekleme, düzenleme ve satın alma pencereleri
│   └── widgets/             # Yeniden kullanılabilir UI bileşenleri
├── firebase_options.dart    # Firebase yapılandırma dosyası
└── main.dart                # Uygulama başlangıç noktası
```

---

## 🚀 Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları takip edebilirsiniz:

### 1. Projeyi Klonlayın
```bash
git clone https://github.com/keremsenn/PointSpend.git
cd PointSpend
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. Firebase Yapılandırması
1. [Firebase Console](https://console.firebase.google.com/) üzerinden yeni bir proje oluşturun.
2. `google-services.json` dosyanızı `android/app/` dizinine yerleştirin.
3. Firebase CLI kullanarak yapılandırmanızı tamamlayın:
```bash
flutterfire configure
```

### 4. Uygulamayı Başlatın
```bash
# Android cihazda veya emülatörde çalıştırmak için
flutter run
```

---

## 🤝 Katkıda Bulunma

1. Bu depoyu Fork'layın (`Fork`).
2. Yeni bir özellik dalı oluşturun (`git checkout -b feature/YeniOzellik`).
3. Değişikliklerinizi commit edin (`git commit -m 'feat: yeni ozellik eklendi'`).
4. Dalınıza push yapın (`git push origin feature/YeniOzellik`).
5. Bir **Pull Request** açın.

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında lisanslanmıştır. Detaylar için lisans dosyasına göz atabilirsiniz.
