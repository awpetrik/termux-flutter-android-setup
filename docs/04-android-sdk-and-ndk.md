# 04 — Android SDK & NDK

## Bagian A — Android SDK (command-line tools)

`cmdline-tools` dari Google berbasis **Java** (portable), jadi bisa jalan di aarch64. Yang
x86-64 hanyalah sebagian binary di dalam **build-tools** — itu akan kita patch di
[05](05-system-configuration.md).

### 1. Unduh & extract

```bash
cd ~
curl -L --fail -o cmdline-tools.zip \
  https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip

mkdir -p android-sdk/cmdline-tools
unzip -q cmdline-tools.zip -d android-sdk/cmdline-tools
mv android-sdk/cmdline-tools/cmdline-tools android-sdk/cmdline-tools/latest
rm -f cmdline-tools.zip
```

Struktur hasil:

```
~/android-sdk/cmdline-tools/latest/bin/{sdkmanager,avdmanager,apkanalyzer,…}
```

### 2. Set environment sementara

```bash
export ANDROID_HOME="$HOME/android-sdk"
export JAVA_HOME="$PREFIX/lib/jvm/java-17-openjdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
```

### 3. Terima lisensi

```bash
yes | sdkmanager --licenses
```

### 4. Install komponen

```bash
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

> **Kenapa `android-34`?** Patch `aapt2` versi Termux paling aman untuk `android.jar` API 34.
> Naikkan compileSdk dengan sadar risikonya.

### 5. Cek hasil

```bash
ls ~/android-sdk/platforms        # → android-34
ls ~/android-sdk/build-tools      # → 34.0.0
```

---

## Bagian B — Android NDK aarch64

### Kenapa NDK buatan komunitas?

NDK resmi Google **hanya** menyediakan host `linux-x86_64`: `toolchains/llvm/prebuilt/linux-x86_64/bin/clang`
adalah ELF x86-64 dan tidak bisa dieksekusi di Termux. Akibatnya CMake di Gradle gagal dengan:

```
The CMAKE_C_COMPILER / CMAKE_CXX_COMPILER … identification is unknown
```

Solusi: NDK yang di-build untuk host aarch64 oleh
[`lzhiyong/termux-ndk`](https://github.com/lzhiyong/termux-ndk).

### 1. Unduh & verifikasi

```bash
mkdir -p ~/Android && cd ~/Android
curl -L --fail -o android-ndk-r29-aarch64.tar.xz \
  https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.tar.xz

sha256sum android-ndk-r29-aarch64.tar.xz
# harus:
# 02e10e4ddfe8deaeb0bd0cf29d04c981ed5bc8a5d6b560ebb9e7661f472d684b
```

### 2. Extract

```bash
tar -xf android-ndk-r29-aarch64.tar.xz
rm -f android-ndk-r29-aarch64.tar.xz
```

Hasil: `~/Android/android-ndk-r29` (± 1.8 GB setelah extract).

### 3. Verifikasi clang benar-benar aarch64 & jalan

```bash
file ~/Android/android-ndk-r29/toolchains/llvm/prebuilt/linux-aarch64/bin/clang
~/Android/android-ndk-r29/toolchains/llvm/prebuilt/linux-aarch64/bin/clang --version
grep Pkg.Revision ~/Android/android-ndk-r29/source.properties
```

Yang diharapkan:

- `file` → `ELF 64-bit … ARM aarch64`
- `--version` → `clang version 21.0.0`, target `aarch64-unknown-linux-musl`
- `Pkg.Revision = 29.0.14206865`

> Catat versi `Pkg.Revision` — dipakai sebagai `ndkVersion` di project
> (lihat [07](07-project-setup.md)).

Lanjut → [05 — Konfigurasi Sistem](05-system-configuration.md)
