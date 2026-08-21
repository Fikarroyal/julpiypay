# Julpiypay

**Your money, Clearly managed.**

Aplikasi mobile pencatatan dan manajemen keuangan pribadi yang dibangun dengan Flutter. Aplikasi ini berfungsi baik dan seluruh data tersimpan secara lokal di device menggunakan SQLite.

---

## 1. Requirements

- Flutter SDK 3.22+ (Dart 3.3+)
- Android Studio *atau* Xcode (untuk emulator/simulator)
- VS Code dengan extension **Flutter** dan **Dart**
- Koneksi internet saat build pertama kali (untuk `flutter pub get` dan mengunduh font Google Fonts saat runtime)

## 2. Flutter Version

Proyek ini menargetkan Flutter versi stabil terbaru dengan Dart SDK `>=3.3.0 <4.0.0`. Cek versi Anda:

```bash
flutter --version
flutter doctor
```

## 3. Installation

Delivery ini berisi kode aplikasi (`lib/`, `pubspec.yaml`, `analysis_options.yaml`) tetapi **tidak** menyertakan folder platform native (`android/`, `ios/`, dll) karena folder tersebut berisi file biner/project spesifik, platform yang harus digenerate oleh Flutter SDK di komputer Anda, bukan sesuatu yang bisa didistribusikan sebagai teks. Ini langkah sekali jalan:

```bash
# 1. Masuk ke folder project ini (yang berisi pubspec.yaml)
cd julpiypay

# 2. Generate folder platform (android, ios, web, dst) di tempat
flutter create --org com.julpiypay --project-name julpiypay .

# 3. Install seluruh dependency
flutter pub get
```

Perintah `flutter create .` **tidak akan menimpa** `lib/main.dart` atau `pubspec.yaml` yang sudah ada secara signifikan (Flutter akan mendeteksi project sudah ada dan hanya melengkapi folder platform yang hilang). Jika Flutter menanyakan konfirmasi overwrite untuk `pubspec.yaml`, pilih **No**/batalkan penimpaan pada file tersebut dan biarkan hanya folder platform yang dibuat.

## 4. VS Code Setup

1. Buka folder `julpiypay/` di VS Code.
2. Install extension **Flutter** (otomatis menyertakan Dart).
3. Buka Command Palette → `Flutter: Select Device` untuk memilih emulator/device.
4. Jalankan lewat menu **Run and Debug** (F5), atau lewat terminal (lihat bagian 6).

## 5. Android Emulator Setup

1. Buka **Android Studio** → **Device Manager** → buat Virtual Device baru (disarankan Pixel 6, API 34).
2. Jalankan emulator.
3. Cek device terdeteksi:
   ```bash
   flutter devices
   ```
4. Jalankan aplikasi (lihat bagian 6).

## 6. Running the Project

```bash
flutter pub get
flutter run
```

Untuk build rilis:

```bash
flutter build apk        # Android
flutter build ios        # iOS (butuh Xcode & macOS)
```

Cek kualitas kode:

```bash
flutter analyze
```

## 7. Project Architecture

```text
lib/
├── main.dart                     # Entry point
│
├── app/
│   ├── app.dart                  # MaterialApp.router + tema
│   ├── router.dart                # Seluruh route go_router
│   └── theme/
│       └── app_theme.dart         # AppColors, AppTextStyles, ThemeData light/dark
│
├── core/
│   ├── utils.dart                 # CurrencyFormatter, DateFormatter, Validators, ContextX
│   └── widgets.dart                # AppCard, AppButton, AppTextField, AmountInput, AppChip,
│                                    # StatCard, IconBadge, EmptyState, ErrorState, LoadingSkeleton,
│                                    # TransactionTile, ProgressStatusBar, bottom sheet & dialog helpers,
│                                    # icon/color key mapping
│
├── data/
│   ├── database.dart               # AppDatabase — skema SQLite (sqflite), migrasi
│   ├── demo_seeder.dart            # Seed data demo untuk onboarding
│   ├── models.dart                  # Seluruh model data (Transaction, Category, Account, dst)
│   ├── repositories.dart            # AccountRepository, CategoryRepository, TransactionRepository
│   └── repositories_extra.dart      # BudgetRepository, SavingGoalRepository, BillRepository,
│                                     # TagRepository, RecurringRepository, ProfileRepository
│
├── providers/
│   └── providers.dart               # Seluruh Riverpod provider (data, tema, dashboard, laporan, insight)
│
└── features/
    ├── splash/                      # Splash screen
    ├── onboarding/                  # 3-page onboarding + pilihan demo data
    ├── home/                        # HomeShell — bottom navigation
    ├── dashboard/                   # Dashboard utama
    ├── transactions/                # List, add/edit, detail — search/filter/sort
    ├── categories/                  # CRUD kategori (tab income/expense)
    ├── accounts/                    # CRUD akun + transfer antar rekening
    ├── budgets/                     # CRUD budget dengan progress
    ├── saving_goals/                # CRUD target tabungan
    ├── bills/                       # CRUD tagihan + mark as paid
    ├── tags/                        # CRUD tag
    ├── recurring/                   # CRUD transaksi berulang
    ├── reports/                     # Overview, Categories, Income, Expense, Cash Flow
    └── profile/                     # Profile, edit profile, data management
```

**State management:** Riverpod (`flutter_riverpod`). Setiap mutasi data (create/update/delete) memanggil `notifyDataChanged(ref)` yang menaikkan `refreshTickProvider`, kemudian seluruh provider data (`dashboardSummaryProvider`, `transactionsProvider`, dll) meng-*watch* provider ini sehingga Dashboard dan semua layar lain otomatis refresh tanpa perlu manual `setState` lintas layar.

**Navigasi:** `go_router`, dengan bottom navigation dikelola manual di `HomeShell` (`IndexedStack`) supaya state tiap tab tetap terjaga, dan seluruh layar form/detail didorong sebagai route terpisah lewat `context.push(...)`.

## 8. Database

SQLite lokal via `sqflite`, disimpan di *application documents directory* device (`julpiypay.db`) **tidak pernah** dikirim ke server manapun. Tabel:

```text
accounts, categories, transactions, transaction_tags, tags,
budgets, saving_goals, bills, recurring_transactions, user_profile
```

Relasi menggunakan `FOREIGN KEY` (mis. `transactions.account_id → accounts.id`, `budgets.category_id → categories.id`) dengan `ON DELETE CASCADE`/`SET NULL` yang sesuai. Saldo akun **tidak** disimpan sebagai kolom statis dan dihitung real-time dari `initial_balance` + agregasi transaksi (`AccountRepository.getBalance`), sehingga selalu akurat.

## 9. Troubleshooting

| Masalah | Solusi |
|---|---|
| `flutter create .` menolak berjalan / bilang folder sudah ada | Jalankan tetap dengan `flutter create --org com.julpiypay --project-name julpiypay .` Flutter akan melengkapi file yang hilang tanpa menghapus `lib/` Anda. |
| Font Plus Jakarta Sans tidak muncul (device offline) | `google_fonts` mengunduh font saat runtime; pastikan koneksi internet aktif saat pertama kali menjalankan app, atau bundling font sebagai asset lokal untuk mode offline penuh. |
| Error `MissingPluginException` pada sqflite/path_provider | Jalankan `flutter clean && flutter pub get` lalu build ulang, biasanya terjadi setelah `flutter create .` dijalankan belakangan. |
| Data tidak muncul setelah restore | Tutup dan buka ulang aplikasi sepenuhnya (hot restart tidak cukup) karena koneksi database lama perlu benar-benar ditutup. |
| Import CSV gagal sebagian | Pastikan nama kategori/akun pada CSV persis sama dengan yang ada di aplikasi (case-insensitive), format tanggal `yyyy-MM-dd`, dan kolom sesuai urutan hasil export Julpiypay. |
