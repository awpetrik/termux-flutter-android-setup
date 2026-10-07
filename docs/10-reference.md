# 10 — Reference

## Versi teruji

| Komponen | Versi | Sumber |
|---|---|---|
| Flutter | 3.29.2 | `mumumusuc/termux-flutter` (`.deb`) |
| Dart | 3.7.2 | bundled |
| Flutter Engine | `18b71d647a292a980abb405ac7d16fe1f0b20434` | bundled |
| OpenJDK | 17.0.20 | repo Termux |
| Android SDK platform | `android-34` | Google cmdline-tools |
| Android build-tools | `34.0.0` | Google |
| Android NDK | r29 `29.0.14206865` | `lzhiyong/termux-ndk` |
| CMake | 4.4.4 | repo Termux |
| Ninja | 1.13.2 | repo Termux |
| Clang (NDK) | 21.0.0 | `lzhiyong/termux-ndk` |
| gradle (AGP) | AGP 8.7.0 / Kotlin 1.8.22 | template Flutter 3.29.2 |

## Path penting

| Item | Path |
|---|---|
| `$PREFIX` | `/data/data/com.termux/files/usr` |
| `$HOME` | `/data/data/com.termux/files/home` |
| Flutter SDK | `$PREFIX/opt/flutter` |
| Cache engine | `$PREFIX/opt/flutter/bin/cache/artifacts/engine` |
| Android SDK | `$HOME/android-sdk` |
| Android NDK | `$HOME/Android/android-ndk-r29` |
| Gradle global props | `$HOME/.gradle/gradle.properties` |
| CMakeLists patched | `$PREFIX/opt/flutter/packages/flutter_tools/gradle/src/main/groovy/CMakeLists.txt` |
| gh config | `$HOME/.config/gh/hosts.yml` |

## Unduhan & checksum

### Flutter SDK

```
URL    : https://github.com/mumumusuc/termux-flutter/releases/download/3.29.2/flutter_3.29.2_aarch64.deb
Size   : 476544780 bytes (455 MiB)
SHA256 : 5146c9db44b6fdcaf932b08d6f2d033a3470df26dca16070cab70e35f0b0dd9d
```

### Android NDK aarch64

```
URL    : https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.tar.xz
Size   : 360538712 bytes (344 MiB)
SHA256 : 02e10e4ddfe8deaeb0bd0cf29d04c981ed5bc8a5d6b560ebb9e7661f472d684b
```

### Android cmdline-tools

```
URL    : https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
```

### Product SDK (release/profile)

```
URL    : https://storage.googleapis.com/flutter_infra_release/flutter/<ENGINE_REVISION>/flutter_patched_sdk_product.zip
Contoh : https://storage.googleapis.com/flutter_infra_release/flutter/18b71d647a292a980abb405ac7d16fe1f0b20434/flutter_patched_sdk_product.zip
```

## Daftar file yang dimodifikasi

### Di luar project (global)

| File | Perubahan |
|---|---|
| `~/.bashrc` | `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `JAVA_HOME`, `PATH` |
| `~/.gradle/gradle.properties` | `aapt2FromMavenOverride`, `java.home`, auto-download off |
| `~/android-sdk/build-tools/*/{aapt,aapt2,aidl,apksigner,d8}` | symlink ke `$PREFIX/bin/*` |
| `$PREFIX/opt/flutter/…/flutter_tools/gradle/…/CMakeLists.txt` | jadi CMake project kosong yang valid |
| `$PREFIX/opt/flutter/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/` | diisi |
| `$PREFIX/opt/flutter/bin/cache/artifacts/engine/android-*/{release,profile}/linux-arm64/gen_snapshot` | symlink aarch64 |

### Di dalam project (per-project)

| File | Perubahan |
|---|---|
| `android/local.properties` | `ndk.dir`, `cmake.dir` |
| `android/app/build.gradle.kts` | `compileSdk=34`, `targetSdk=34`, `ndkVersion` |
| `android/gradle.properties` | `jvmargs`, `aapt2FromMavenOverride`, `enableResourceOptimizations=false` |

## Cara update Flutter & re-apply patch

1. Unduh `.deb` versi baru dari `mumumusuc/termux-flutter`.
2. `dpkg -i flutter_<versi>_aarch64.deb`.
3. **Ulangi seluruh [Patch SDK](06-sdk-patches.md)**, dengan penyesuaian:
   - Engine revision baru (dari `flutter --version` / `flutter.version.json`) untuk
     `flutter_patched_sdk_product.zip`.
   - Cek ulang tipe binary build-tools (`file`) dan patch bila perlu.
4. Perbarui dokumen ini (versi & checksum) dan `README.md` (tabel environment).

## Pranala

- Flutter SDK Termux: https://github.com/mumumusuc/termux-flutter
- NDK aarch64: https://github.com/lzhiyong/termux-ndk
- Android cmdline-tools: https://developer.android.com/studio#command-tools
- Termux: https://termux.dev / https://github.com/termux/termux-app
