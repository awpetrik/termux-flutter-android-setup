#!/data/data/com.termux/files/usr/bin/bash
#
# setup.sh — Setup GLOBAL Termux Flutter + Android build toolkit (aarch64).
#
# Menjalankan seluruh langkah di docs/02..06 secara idempoten. Aman dijalankan
# berulang: langkah yang sudah selesai akan dilewati.
#
#   bash scripts/setup.sh
#
# Butuh ruang disk ~6-8 GB. Baca docs/ dulu sebelum menjalankan.
#
set -eu

# ---------- konfigurasi ----------
FLUTTER_DEB_URL="https://github.com/mumumusuc/termux-flutter/releases/download/3.29.2/flutter_3.29.2_aarch64.deb"
FLUTTER_DEB_SHA256="5146c9db44b6fdcaf932b08d6f2d033a3470df26dca16070cab70e35f0b0dd9d"
NDK_URL="https://github.com/lzhiyong/termux-ndk/releases/download/android-ndk/android-ndk-r29-aarch64.tar.xz"
NDK_SHA256="02e10e4ddfe8deaeb0bd0cf29d04c981ed5bc8a5d6b560ebb9e7661f472d684b"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
NDK_VERSION="29.0.14206865"

HOME_DIR="$HOME"
ANDROID_HOME="$HOME_DIR/android-sdk"
NDK_DIR="$HOME_DIR/Android/android-ndk-r29"
JAVA_HOME="${PREFIX:-/data/data/com.termux/files/usr}/lib/jvm/java-17-openjdk"
FLUTTER_ROOT="${PREFIX:-/data/data/com.termux/files/usr}/opt/flutter"

# ---------- util ----------
log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }

verify_sha() { # file expected
  local got
  got="$(sha256sum "$1" | awk '{print $1}')"
  [ "$got" = "$2" ] || die "Checksum tidak cocok untuk $1 (dapat $got)"
  echo "    checksum OK"
}

set_prop() { # file key value
  local f="$1" k="$2" v="$3"
  [ -f "$f" ] || : > "$f"
  if grep -qE "^[[:space:]]*${k}=" "$f"; then
    sed -i "s|^[[:space:]]*${k}=.*|${k}=${v}|" "$f"
  else
    if [ -s "$f" ] && [ -n "$(tail -c1 "$f")" ]; then printf '\n' >> "$f"; fi
    printf '%s=%s\n' "$k" "$v" >> "$f"
  fi
}

# ---------- 0. cek dasar ----------
[ "$(uname -m)" = "aarch64" ] || die "Script ini hanya untuk aarch64/arm64."
[ -n "${PREFIX:-}" ] || die "Jalankan di dalam Termux (PREFIX tidak diset)."

log "Ruang disk"
df -h /data | tail -1
avail_kb="$(df -Pk /data | awk 'NR==2{print $4}')"
if [ "$avail_kb" -lt $((5 * 1024 * 1024)) ]; then
  warn "Ruang bebas < 5 GB. Kemungkinan build gagal. Lihat docs/01 & 09 #11."
fi

# ---------- 1. paket ----------
log "Update index & install paket Termux"
pkg update -y
pkg install -y openjdk-17 aapt aapt2 aidl apksigner d8 android-tools \
  cmake ninja clang file which git curl unzip zip

log "Dependensi runtime Flutter (x11/gtk)"
pkg install -y x11-repo
pkg update -y
pkg install -y which gtk3 xorgproto ninja cmake clang pkg-config

# ---------- 2. Flutter SDK ----------
if [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
  log "Flutter sudah terpasang — lewati unduh/install"
else
  log "Unduh & install Flutter .deb"
  cd "$HOME_DIR"
  curl -L --fail -o flutter_3.29.2_aarch64.deb "$FLUTTER_DEB_URL"
  verify_sha flutter_3.29.2_aarch64.deb "$FLUTTER_DEB_SHA256"
  dpkg -i flutter_3.29.2_aarch64.deb
  apt --fix-broken install -y || true
  rm -f flutter_3.29.2_aarch64.deb
fi

# ---------- 3. Android SDK ----------
log "Android SDK command-line tools"
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  cd "$HOME_DIR"
  curl -L --fail -o cmdline-tools.zip "$CMDLINE_TOOLS_URL"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  unzip -q cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -f cmdline-tools.zip
else
  echo "    sudah ada"
fi

export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME" JAVA_HOME
export PATH="$PATH:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

log "Terima lisensi & install komponen SDK"
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# ---------- 4. NDK aarch64 ----------
log "Android NDK aarch64 (r29)"
if [ -d "$NDK_DIR" ]; then
  echo "    sudah ada: $NDK_DIR"
else
  mkdir -p "$HOME_DIR/Android"
  cd "$HOME_DIR/Android"
  curl -L --fail -o android-ndk-r29-aarch64.tar.xz "$NDK_URL"
  verify_sha android-ndk-r29-aarch64.tar.xz "$NDK_SHA256"
  tar -xf android-ndk-r29-aarch64.tar.xz
  rm -f android-ndk-r29-aarch64.tar.xz
fi

# ---------- 5. Env di ~/.bashrc ----------
log "Environment ~/.bashrc"
if grep -q 'termux-flutter-android-setup' "$HOME_DIR/.bashrc" 2>/dev/null; then
  echo "    sudah ada"
else
  cat >> "$HOME_DIR/.bashrc" <<EOF

# --- termux-flutter-android-setup ---
export ANDROID_HOME="\${HOME}/android-sdk"
export ANDROID_SDK_ROOT="\${ANDROID_HOME}"
export JAVA_HOME="\${PREFIX:-/data/data/com.termux/files/usr}/lib/jvm/java-17-openjdk"
export PATH="\${PATH}:\${JAVA_HOME}/bin:\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/platform-tools"
EOF
fi

# ---------- 6. Gradle override global ----------
log "Gradle override global (~/.gradle/gradle.properties)"
mkdir -p "$HOME_DIR/.gradle"
GP="$HOME_DIR/.gradle/gradle.properties"
[ -f "$GP" ] && cp "$GP" "$GP.bak"
set_prop "$GP" "org.gradle.java.home" "$JAVA_HOME"
set_prop "$GP" "android.aapt2FromMavenOverride" "$PREFIX/bin/aapt2"
set_prop "$GP" "org.gradle.java.installations.auto-download" "false"
set_prop "$GP" "org.gradle.java.installations.auto-detect" "true"
set_prop "$GP" "android.sync.suppressAgpWarnings" "UNSUPPORTED_PROJECT_OPTION_USE,EXTERNAL_NATIVE_BUILD_CONFIGURATION"

# ---------- 7. Patch build-tools ----------
log "Patch binary build-tools -> Termux native"
for dir in "$ANDROID_HOME"/build-tools/*/; do
  [ -d "$dir" ] || continue
  for tool in aapt aapt2 aidl apksigner d8; do
    if [ -e "$PREFIX/bin/$tool" ]; then
      rm -f "${dir}${tool}"
      ln -s "$PREFIX/bin/$tool" "${dir}${tool}"
    fi
  done
  echo "    patched: $dir"
done

# ---------- 8. Patch SDK Flutter ----------
log "Patch CMakeLists.txt Flutter Gradle plugin"
CML="$FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/groovy/CMakeLists.txt"
if [ -f "$CML" ]; then
  cat > "$CML" <<'EOF'
# Termux/aarch64 patch: file ini hanya dipakai Flutter Gradle plugin untuk memaksa
# AGP mengunduh NDK. Deklarasi bahasa eksplisit membuat CMake menghasilkan reply
# yang bisa di-parse AGP (file kosong tanpa project() memicu NullPointerException).
# Sengaja tanpa target - tidak ada yang benar-benar dikompilasi.
cmake_minimum_required(VERSION 3.10)
project(flutter_ndk_stub C CXX)
EOF
  echo "    OK"
else
  warn "CMakeLists.txt tidak ditemukan (Flutter belum terpasang?)"
fi

log "Lengkapi flutter_patched_sdk_product"
ENGINE="$(sed -n 's/.*"engineRevision"[^"]*"\([^"]*\)".*/\1/p' "$FLUTTER_ROOT/bin/cache/flutter.version.json" 2>/dev/null || true)"
if [ -n "$ENGINE" ]; then
  DST="$FLUTTER_ROOT/bin/cache/artifacts/engine/common/flutter_patched_sdk_product"
  if [ -f "$DST/platform_strong.dill" ]; then
    echo "    sudah ada"
  else
    mkdir -p "$DST"
    cd "$HOME_DIR"
    curl -L --fail -o flutter_patched_sdk_product.zip \
      "https://storage.googleapis.com/flutter_infra_release/flutter/${ENGINE}/flutter_patched_sdk_product.zip"
    unzip -o flutter_patched_sdk_product.zip -d "$DST" >/dev/null
    if [ -d "$DST/flutter_patched_sdk_product" ]; then
      mv "$DST/flutter_patched_sdk_product"/* "$DST/"
      rmdir "$DST/flutter_patched_sdk_product"
    fi
    rm -f flutter_patched_sdk_product.zip
    echo "    engine $ENGINE"
  fi
else
  warn "Engine revision tidak terbaca; lewati. Lihat docs/06."
fi

log "Symlink gen_snapshot aarch64 untuk target Android"
E="$FLUTTER_ROOT/bin/cache/artifacts/engine"
if [ -x "$E/linux-arm64/gen_snapshot" ]; then
  for d in android-arm-release android-arm-profile \
           android-arm64-release android-arm64-profile \
           android-x64-release android-x64-profile; do
    mkdir -p "$E/$d/linux-arm64"
    ln -sf "$E/linux-arm64/gen_snapshot" "$E/$d/linux-arm64/gen_snapshot"
  done
  echo "    OK"
else
  warn "linux-arm64/gen_snapshot tidak ditemukan; lewati. Lihat docs/06."
fi

# ---------- selesai ----------
log "Selesai"
cat <<EOF

Langkah berikutnya:
  1. source ~/.bashrc
  2. bash scripts/verify.sh
  3. bash scripts/patch-project.sh /path/ke/project
     cd /path/ke/project && flutter build apk --debug

Build release (arm64 saja):
  flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
EOF
