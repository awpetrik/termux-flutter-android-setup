# 06 — Patch SDK

Tiga patch berikut mengubah file **di dalam SDK Flutter** (bukan project). Semuanya idempoten
dan hanya perlu dilakukan sekali per instalasi Flutter.

> ⚠️ **Patch ini bisa hilang** kalau Flutter di-update/reinstall. Setelah update, jalankan ulang
> langkah di dokumen ini.

---

## 1. Patch `CMakeLists.txt` milik Flutter Gradle plugin

**File:**
`$PREFIX/opt/flutter/packages/flutter_tools/gradle/src/main/groovy/CMakeLists.txt`

**Isi:**

```cmake
cmake_minimum_required(VERSION 3.10)
project(flutter_ndk_stub C CXX)
```

### Kenapa

Flutter Gradle plugin (`forceNdkDownload()` di `flutter.groovy`) sengaja menunjuk sebuah
`externalNativeBuild.cmake` ke file kosong ini **hanya** untuk memaksa AGP mengunduh NDK
(AGP butuh NDK untuk strip debug symbol). Isi aslinya hanya komentar (tanpa `project()`),
yang membuat CMake memakai `project()` implisit tanpa compiler yang jelas.

Di AGP 8.x + CMake 4.x, project kosong tanpa deklarasi bahasa membuat AGP melempar:

```
Execution failed for task ':app:configureCMakeDebug[arm64-v8a]'.
> java.lang.NullPointerException
  at com.android.build.gradle.internal.cxx.cmake.CmakeFileApiV1Kt.readCmakeFileApiReply(CmakeFileApiV1.kt:110)
```

Mendeklarasikan `project(... C CXX)` eksplisit membuat CMake menghasilkan *reply* yang bisa
di-parse AGP. Project tetap kosong (tidak ada target yang dibangun).

> Jangan ganti dengan `LANGUAGES NONE` — itu justru memicu NullPointerException lagi.

---

## 2. Lengkapi `flutter_patched_sdk_product`

Release/profile build butuh *product SDK summary* yang **tidak disertakan** di `.deb`:

```
Error: SDK summary not found: …/artifacts/engine/common/flutter_patched_sdk_product/platform_strong.dill
```

Ambil dari storage Flutter, cocokkan dengan **engine revision** yang dipakai:

```bash
ENGINE=18b71d647a292a980abb405ac7d16fe1f0b20434   # lihat `flutter --version` / flutter.version.json
DST="$PREFIX/opt/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product"

mkdir -p "$DST"
cd ~
curl -L --fail -o flutter_patched_sdk_product.zip \
  "https://storage.googleapis.com/flutter_infra_release/flutter/${ENGINE}/flutter_patched_sdk_product.zip"
unzip -o flutter_patched_sdk_product.zip -d "$DST"

# ZIP berisi satu folder pembungkus — ratakan supaya file .dill ada langsung di $DST
if [ -d "$DST/flutter_patched_sdk_product" ]; then
  mv "$DST/flutter_patched_sdk_product"/* "$DST/"
  rmdir "$DST/flutter_patched_sdk_product"
fi
```

Hasil yang benar:

```
$DST/platform_strong.dill
$DST/vm_outline_strong.dill
```

> Cek `engineRevision` dari `$PREFIX/opt/flutter/bin/cache/flutter.version.json`.

---

## 3. Symlink `gen_snapshot` aarch64 untuk target Android

`.deb` Flutter menyertakan `gen_snapshot` untuk target Android tapi **versi x86-64**, dan
menaruhnya di folder `linux-x64`. Saat release build, tool mencari folder `linux-arm64`:

```
Target android_aot_release_android-arm64 failed: Failed to find
"…/artifacts/engine/android-arm64-release/linux-arm64/gen_snapshot"
```

Sementara binary aarch64 yang **bisa jalan** ada di `…/artifacts/engine/linux-arm64/gen_snapshot`.

```bash
E="$PREFIX/opt/flutter/bin/cache/artifacts/engine"

for d in android-arm-release android-arm-profile \
         android-arm64-release android-arm64-profile \
         android-x64-release android-x64-profile; do
  mkdir -p "$E/$d/linux-arm64"
  ln -sf "$E/linux-arm64/gen_snapshot" "$E/$d/linux-arm64/gen_snapshot"
done
```

Verifikasi:

```bash
file              "$E/linux-arm64/gen_snapshot"     # ARM aarch64
"$E/linux-arm64/gen_snapshot" --version              # Dart SDK 3.7.2 … on "linux_arm64"
ls -la            "$E/android-arm64-release/linux-arm64/"
```

> Nama folder di `.deb` (`linux-x64`) menyesatkan: isinya binary yang dibutuhkan tapi salah
> label. Yang kita pakai adalah `gen_snapshot` aarch64 dari `linux-arm64`.

Lanjut → [07 — Setup per-Project](07-project-setup.md)
