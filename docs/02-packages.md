# 02 — Paket Termux

## Update index dulu

```bash
pkg update -y
```

> Kalau `pkg update` tidak dijalankan, index paket bisa basi dan muncul error `404 Not Found`
> untuk paket seperti `ca-certificates-java`. Lihat [Troubleshooting](09-troubleshooting.md) #1.

## Paket inti

```bash
pkg install -y \
  openjdk-17 \
  aapt aapt2 aidl apksigner d8 \
  android-tools \
  cmake ninja \
  clang \
  file which \
  git curl unzip zip
```

### Kenapa masing-masing

| Paket | Fungsi |
|---|---|
| `openjdk-17` | JDK untuk Gradle/AGP. AGP 8.7 butuh JDK 17. |
| `aapt2` | **Kritis.** Binary aarch64 pengganti `aapt2` x86-64 bawaan build-tools. |
| `aapt` | Sama, untuk `aapt` (binary x86-64 di build-tools). |
| `aidl` | Pengganti `aidl` x86-64 di build-tools. |
| `apksigner` | Sudah aarch64 (script → jar). |
| `d8` | Dexer (script → jar). |
| `android-tools` | Menyediakan `adb` **aarch64**. `adb` bawaan platform-tools x86-64. |
| `cmake` | CMake aarch64 (versi 4.x). Dipakai lewat `cmake.dir`. |
| `ninja` | Build tool untuk CMake. |
| `clang` | Toolchain C/C++ Termux (dipakai sebagian proyek). |
| `file` | Cek arsitektur binary (dipakai saat diagnosa). |
| `which` | Dibutuhkan beberapa script. |
| `gengetopt pkg-config` dsb. | Sesuai kebutuhan proyek. |

## Paket yang **tidak** ada di Termux

| Tool | Status | Dampak |
|---|---|---|
| `zipalign` | **Tidak tersedia** | Umumnya tidak masalah: AGP modern menyejajarkan APK lewat `zipflinger` (Java), bukan binary `zipalign`. |
| `llvm-strip` aarch64 android | — | Tidak perlu; NDK r29 sudah menyertakan versi aarch64. |

> Cek ketersediaan paket sebelum mengandalkannya:
> ```bash
> apt-cache policy <nama-paket>
> ```
> Contoh, `zipalign`:
> ```bash
> apt-cache policy zipalign   # → kosong (tidak ada)
> ```

## Catatan versi Java

`apksigner`/`d8` menarik `openjdk-21`, sehingga `java` di `PATH` bisa berubah jadi 21.
Ini **tidak masalah** selama `JAVA_HOME` untuk Gradle tetap diarahkan ke 17 (lihat
[Konfigurasi Sistem](05-system-configuration.md)).

```bash
java -version                                    # bisa jadi 21
$PREFIX/lib/jvm/java-17-openjdk/bin/java -version # pastikan ini yang dipakai Gradle
```

Lanjut → [03 — Flutter SDK](03-flutter-sdk.md)
