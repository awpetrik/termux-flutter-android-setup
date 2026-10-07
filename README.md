# Termux Flutter + Android Build Toolkit (ARM64)

Dokumentasi lengkap cara menyiapkan environment **build APK Flutter secara native di
Android/Termux (aarch64)** — tanpa PC, tanpa proot, tanpa QEMU, tanpa emulasi x86-64.

Semua langkah di repo ini sudah diuji sampai menghasilkan APK nyata (debug **dan** release)
di perangkat fisik.

---

## Kenapa repo ini ada

Flutter **tidak** mendukung Android/Termux sebagai host resmi. Masalah utamanya bukan Flutter,
tapi toolchain Android-nya:

- **`aapt2`** yang diunduh Gradle adalah binary `linux-x86_64` → tidak bisa jalan di aarch64.
- **NDK resmi Google** hanya punya host `linux-x86_64` (clang-nya x86-64) → CMake gagal
  mengidentifikasi compiler.
- **`gen_snapshot`** (generator snapshot AOT) yang beredar juga x86_64 → build release gagal.
- Ada juga bug kecil di AGP 8.x saat Flutter memaksa unduh NDK lewat CMake project kosong.

Repo ini mendokumentasikan semua solusi yang sudah terverifikasi, plus script untuk
mengulanginya. Setiap "hack" dijelaskan **penyebabnya**, bukan cuma perintahnya.

---

## Environment teruji

| Item | Nilai |
|---|---|
| Device | Android aarch64 (arm64-v8a), Android 16 |
| Termux | F-Droid build |
| Flutter | 3.29.2 (`user-branch`) |
| Dart | 3.7.2 |
| Engine | `18b71d647a292a980abb405ac7d16fe1f0b20434` |
| JDK | OpenJDK 17.0.20 |
| Android SDK | platform `android-34`, build-tools `34.0.0` |
| NDK | r29 `29.0.14206865` (aarch64, dari `lzhiyong/termux-ndk`) |
| CMake / Ninja | 4.4.4 / 1.13.2 (Termux) |

> Hasil uji: `app-debug.apk` 84 MB (4 ABI) dan `app-release.apk` 7.5 MB (arm64, V2-signed).

---

## TL;DR

```bash
# 1. Setup global (sekali saja, ~6-8 GB ruang disk dibutuhkan)
git clone <repo-ini> ~/termux-flutter-android-setup
bash ~/termux-flutter-android-setup/scripts/setup.sh
source ~/.bashrc

# 2. Verifikasi
bash ~/termux-flutter-android-setup/scripts/verify.sh

# 3. Untuk tiap project Flutter
bash ~/termux-flutter-android-setup/scripts/patch-project.sh ~/my_app
cd ~/my_app
flutter build apk --debug
```

---

## Struktur repo

```
termux-flutter-android-setup/
├── README.md                        # file ini
├── docs/
│   ├── 01-prerequisites.md          # perangkat, disk, prasyarat
│   ├── 02-packages.md               # paket Termux (+ kenapa masing-masing)
│   ├── 03-flutter-sdk.md            # install Flutter aarch64
│   ├── 04-android-sdk-and-ndk.md    # Android SDK + NDK aarch64
│   ├── 05-system-configuration.md   # env, gradle global, symlink build-tools
│   ├── 06-sdk-patches.md            # patch CMakeLists & cache engine
│   ├── 07-project-setup.md          # konfigurasi per-project
│   ├── 08-building.md               # cara build debug/release
│   ├── 09-troubleshooting.md        # semua error + akar masalah + solusi
│   └── 10-reference.md              # versi, path, checksum, URL
├── scripts/
│   ├── setup.sh                     # otomasi setup global (idempoten)
│   ├── patch-project.sh             # otomasi konfigurasi project
│   └── verify.sh                    # cek toolchain + smoke test
└── .gitignore
```

---

## Daftar isi

1. [Prasyarat](docs/01-prerequisites.md)
2. [Paket Termux](docs/02-packages.md)
3. [Flutter SDK](docs/03-flutter-sdk.md)
4. [Android SDK & NDK](docs/04-android-sdk-and-ndk.md)
5. [Konfigurasi Sistem](docs/05-system-configuration.md)
6. [Patch SDK](docs/06-sdk-patches.md)
7. [Setup per-Project](docs/07-project-setup.md)
8. [Building](docs/08-building.md)
9. [Troubleshooting](docs/09-troubleshooting.md)
10. [Reference](docs/10-reference.md)

---

## Batasan penting (baca sebelum pakai)

- **Release hanya `arm64`.** Selalu pakai `--target-platform android-arm64`. ABI lain tidak
  punya `gen_snapshot` aarch64.
- **`compileSdk`/`targetSdk` = 34.** Naikkan dengan hati-hati.
- **Gunakan `--no-tree-shake-icons`** untuk build release.
- **`adb`** dari `platform-tools` Google itu x86-64; pakai `android-tools` Termux.
- **Ruang disk** minimal ~6–8 GB untuk Flutter + SDK + NDK + cache Gradle.
- Ini **bukan** lingkungan resmi yang didukung Google/Flutter. Update Flutter bisa merusak
  patch ini (lihat [Reference](docs/10-reference.md) untuk cara re-apply).

---

## Lisensi

Bebas dipakai dan dimodifikasi. Toolchain pihak ketiga mengikuti lisensinya masing-masing
(Flutter BSD, Android SDK/NDK Apache-2.0, `termux-flutter` GPL-3.0, `termux-ndk` sesuai repo asal).
