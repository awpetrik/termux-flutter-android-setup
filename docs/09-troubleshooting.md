# 09 — Troubleshooting

Semua error di bawah adalah yang benar-benar muncul saat setup dan sudah teratasi. Format:
**gejala → akar masalah → solusi**.

---

## 1. `404 Not Found` saat `pkg install` (mis. `ca-certificates-java`)

**Gejala**
```
E: Failed to fetch …/ca-certificates-java_…deb  404  Not Found
```

**Akar masalah** — Index paket basi; `pkg update` belum benar-benar dijalankan. Kadang `pkg update`
"gagal diam-diam" karena output di-redirect ke lokasi yang tidak bisa ditulis.

**Solusi**
```bash
pkg update -y
pkg install -y <paket>
```

> Jangan redirect log `pkg` ke `/tmp` (di Termux sering tidak writable). Pakai `$HOME`.
> Ingat juga shell default `sh` tidak punya `${PIPESTATUS[@]}` — pakai `bash` bila butuh.

---

## 2. Flutter release asset yang diklaim ada ternyata kosong

**Gejala** — Repo tampak lengkap, tapi `.deb`/asset rilis 404 atau script installer menunjuk
repo yang tidak ada.

**Solusi** — Cek asset via API sebelum memakai:
```bash
curl -s https://api.github.com/repos/<owner>/<repo>/releases | grep browser_download_url
```
Kalau kosong, jangan dipakai.

---

## 3. `flutter --version` terlihat hang

**Akar masalah** — Run pertama menyiapkan cache dan menulis `flutter_tools.snapshot`
(± 40 MB). Butuh puluhan detik.

**Solusi** — Tunggu. Jangan Ctrl-C di tengah proses.

---

## 4. `Syntax error: ")" unexpected` / `cannot execute binary file`

**Gejala**
```
/data/…/android-sdk/cmake/3.22.1/bin/cmake: 1: Syntax error: ")" unexpected
```

**Akar masalah** — Shell mencoba menjalankan **ELF x86-64** di perangkat aarch64. Shell gagal
`exec`, lalu mencoba membacanya sebagai script → error sintaks.

**Cara tahu binary mana yang masalah**
```bash
file <path-binary>
# "ELF 64-bit … x86-64" → inilah biang keroknya
```

**Solusi** — Ganti/arahkan ke versi aarch64:
- `aapt`, `aapt2`, `aidl` → symlink ke `$PREFIX/bin/*` ([05](05-system-configuration.md)).
- `cmake` → set `cmake.dir=$PREFIX` ([07](07-project-setup.md)).
- `adb` → install `android-tools` ([Troubleshooting #9](#9-adb--syntax-error-word-unexpected)).

---

## 5. CMake: `CMAKE_C_COMPILER … identification is unknown`

**Gejala**
```
[CXX1429] error when building with cmake using …/CMakeLists.txt:
-- The C compiler identification is unknown
-- The CXX compiler identification is unknown
```

**Akar masalah** — NDK yang dipakai punya clang host `linux-x86_64` (tidak bisa jalan).

**Solusi** — Pakai NDK **aarch64** dari `lzhiyong/termux-ndk`, lalu set di project:
```properties
# android/local.properties
ndk.dir=/data/data/com.termux/files/home/Android/android-ndk-r29
cmake.dir=/data/data/com.termux/files/usr
```
dan
```kotlin
// android/app/build.gradle.kts
ndkVersion = "29.0.14206865"
```

---

## 6. `configureCMakeDebug … NullPointerException` (`CmakeFileApiV1Kt.readCmakeFileApiReply`)

**Gejala**
```
> java.lang.NullPointerException
  at com.android.build.gradle.internal.cxx.cmake.CmakeFileApiV1Kt.readCmakeFileApiReply(CmakeFileApiV1.kt:110)
Execution failed for task ':app:configureCMakeDebug[arm64-v8a]'.
```

**Akar masalah** — `CMakeLists.txt` kosong (hanya komentar) yang ditunjuk Flutter Gradle plugin
menghasilkan *reply* yang tidak bisa di-parse AGP 8.x.

**Solusi** — Beri deklarasi bahasa eksplisit ([06](06-sdk-patches.md) #1):
```cmake
cmake_minimum_required(VERSION 3.10)
project(flutter_ndk_stub C CXX)
```
Jangan gunakan `LANGUAGES NONE` (memicu NPE yang sama).

---

## 7. `SDK summary not found … flutter_patched_sdk_product/platform_strong.dill`

**Gejala**
```
Error: SDK summary not found: …/artifacts/engine/common/flutter_patched_sdk_product/platform_strong.dill
Target kernel_snapshot_program failed: Exception
```
Sering diikuti rentetan `Dart library 'dart:async' is not available on this platform` —
itu **gejala turunan**, bukan masalah terpisah.

**Akar masalah** — `.deb` tidak menyertakan *product SDK* yang dibutuhkan release/profile build.

**Solusi** — Unduh `flutter_patched_sdk_product.zip` sesuai engine revision, ratakan isinya
([06](06-sdk-patches.md) #2).

---

## 8. `Failed to find …/linux-arm64/gen_snapshot`

**Gejala**
```
Target android_aot_release_android-arm64 failed: ProcessException:
Failed to find "…/android-arm64-release/linux-arm64/gen_snapshot" in the search path.
```

**Akar masalah** — `.deb` menaruh `gen_snapshot` **x86-64** di folder `linux-x64`; tool mencari
folder `linux-arm64` untuk host aarch64.

**Solusi** — Symlink `gen_snapshot` aarch64 dari `…/engine/linux-arm64/gen_snapshot` ke
tiap folder `android-*/{release,profile}/linux-arm64/` ([06](06-sdk-patches.md) #3).

---

## 9. `adb` — `Syntax error: word unexpected`

**Gejala** — `flutter doctor` crash di "Connected device", atau `adb` gagal jalan.
```
…/platform-tools/adb: 1: Syntax error: word unexpected (expecting ")")
```
Ini **kosmetik** untuk build (build tidak butuh device), tapi mengganggu.

**Akar masalah** — `adb` dari Google `platform-tools` adalah ELF x86-64.

**Solusi** — Pakai `adb` aarch64 dari Termux (otomatis lebih awal di `PATH` setelah install):
```bash
pkg install -y android-tools
command -v adb    # → $PREFIX/bin/adb (aarch64)
```

---

## 10. `time: not found` / `which: not found` / `file: not found`

**Akar masalah** — Beberapa utilitas tidak ada di Termux default.

**Solusi**
```bash
pkg install -y file which
# `time` bukan binary standalone; pakai `date`/`SECONDS` atau bash builtin `time`
```

---

## 11. `No space left on device`

**Akar masalah** — Toolchain butuh ± 6–8 GB. Partisi `/data` (tempat Termux) sering penuh.

**Solusi**
- Bebaskan ruang di `/data`. Cek:
  ```bash
  df -h /data
  du -sh ~/.gradle ~/.pub-cache ~/.cache ~/.npm 2>/dev/null
  ```
- **Tidak bisa** memindahkan SDK ke SD card: storage eksternal Android di-mount **`noexec`**,
  jadi binary di sana tidak bisa dieksekusi.

---

## 12. Build mati mendadak / OOM

**Gejala** — Proses berhenti tiba-tiba, `Process completed (signal 9)`.

**Akar masalah** — Android *phantom process killer* / memori tidak cukup.

**Solusi**
- Set Termux baterai ke **Unrestricted**.
- Turunkan `org.gradle.jvmargs` (mis. `-Xmx2G`).
- `termux-wake-lock` sebelum build.
- (Android 12+) naikkan batas phantom process:
  ```bash
  adb shell "device_config put activity_manager max_phantom_processes 2147483647"
  ```

---

## 13. Release gagal untuk ABI selain arm64

**Akar masalah** — Hanya ada `gen_snapshot` aarch64. Memaksa ABI lain akan menghasilkan snapshot
yang salah/tidak bisa dibangun.

**Solusi** — Selalu:
```bash
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
```

---

## 14. Tanda tangan APK release = debug key

**Bukan error.** Template Flutter menandatangani release dengan debug key agar
`flutter run --release` langsung bisa. Untuk distribusi, ganti `signingConfig` di
`android/app/build.gradle(.kts)`.

---

## 15. Setelah update Flutter, build rusak lagi

**Akar masalah** — Patch di [06](06-sdk-patches.md) hilang/tertimpa saat Flutter diperbarui.

**Solusi** — Jalankan ulang seluruh [06](06-sdk-patches.md) (CMakeLists, product SDK, symlink
`gen_snapshot`). Sesuaikan juga engine revision pada langkah product SDK.

Lanjut → [10 — Reference](10-reference.md)
