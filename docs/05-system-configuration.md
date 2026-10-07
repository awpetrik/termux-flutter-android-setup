# 05 — Konfigurasi Sistem

Tiga hal di level sistem yang membuat **semua** project Gradle/Flutter memakai binary aarch64
native, tanpa perlu mengubah file project satu-satu.

---

## 1. Environment variables (`~/.bashrc`)

```bash
cat >> ~/.bashrc <<'EOF'
# Flutter + Android SDK environment
export ANDROID_HOME="${HOME}/android-sdk"
export ANDROID_SDK_ROOT="${ANDROID_HOME}"
export JAVA_HOME="${PREFIX:-/data/data/com.termux/files/usr}/lib/jvm/java-17-openjdk"
export PATH="${PATH}:${JAVA_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools"
EOF
source ~/.bashrc
```

| Variabel | Kenapa |
|---|---|
| `ANDROID_HOME` / `ANDROID_SDK_ROOT` | Gradle & Flutter mencari SDK di sini. |
| `JAVA_HOME` | Mengunci Gradle ke JDK 17 (walau `java` di PATH bisa jadi 21). |
| `PATH` | Akses `sdkmanager`, `adb` (aarch64 dari `android-tools`), dll. |

---

## 2. Gradle override global (`~/.gradle/gradle.properties`)

File ini dibaca Gradle untuk **semua** build di device ini.

```bash
mkdir -p ~/.gradle
cat > ~/.gradle/gradle.properties <<'EOF'
org.gradle.java.home=/data/data/com.termux/files/usr/lib/jvm/java-17-openjdk
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
org.gradle.java.installations.auto-download=false
org.gradle.java.installations.auto-detect=true
android.sync.suppressAgpWarnings=UNSUPPORTED_PROJECT_OPTION_USE,EXTERNAL_NATIVE_BUILD_CONFIGURATION
EOF
```

| Properti | Fungsi |
|---|---|
| `android.aapt2FromMavenOverride` | **Kritis.** Memaksa AGP memakai `aapt2` aarch64 Termux, bukan versi x86-64 yang diunduh dari Maven. |
| `org.gradle.java.home` | JDK 17 untuk semua build. |
| `org.gradle.java.installations.auto-download=false` | Cegah Gradle mengunduh JDK x86-64. |
| `android.sync.suppressAgpWarnings` | Menyembunyikan warning yang tidak relevan di setup ini. |

---

## 3. Patch binary `build-tools`

Beberapa executable di `build-tools` adalah ELF x86-64. Ganti dengan versi Termux:

```bash
for dir in "$HOME"/android-sdk/build-tools/*/; do
  for tool in aapt aapt2 aidl apksigner d8; do
    if [ -e "$PREFIX/bin/$tool" ]; then
      rm -f "$dir/$tool"
      ln -s "$PREFIX/bin/$tool" "$dir/$tool"
      echo "patched: $dir$tool"
    fi
  done
done
```

Cek hasilnya:

```bash
file ~/android-sdk/build-tools/34.0.0/aapt2
# → symbolic link → /data/data/com.termux/files/usr/bin/aapt2
```

### Kenapa `zipalign` tidak di-patch

`zipalign` **tidak tersedia** di repo Termux, dan binary x86-64-nya tidak bisa jalan.
Umumnya aman karena AGP modern menyejajarkan APK lewat `zipflinger` (Java) saat release.
Kalau nanti benar-benar dibutuhkan, solusinya adalah menyediakan shim/implementasi sendiri —
bukan sekadar symlink.

### Ringkasan binary build-tools

| Tool | Tipe asli | Aksi |
|---|---|---|
| `aapt` | ELF x86-64 | diganti ke Termux |
| `aapt2` | ELF x86-64 | diganti ke Termux |
| `aidl` | ELF x86-64 | diganti ke Termux |
| `apksigner` | shell script | diganti (opsional, tetap aman) |
| `d8` | shell script | diganti (opsional, tetap aman) |
| `zipalign` | ELF x86-64 | **dibiarkan** (tidak dipakai AGP modern) |

Lanjut → [06 — Patch SDK](06-sdk-patches.md)
