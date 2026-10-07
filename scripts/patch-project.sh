#!/data/data/com.termux/files/usr/bin/bash
#
# patch-project.sh — Konfigurasi sebuah project Flutter agar bisa di-build di Termux.
#
#   bash scripts/patch-project.sh /path/ke/project
#
# Mengubah (dengan backup .bak):
#   - android/local.properties          : tambah ndk.dir + cmake.dir
#   - android/app/build.gradle(.kts)    : compileSdk=34, targetSdk=34, ndkVersion
#   - android/gradle.properties         : jvmargs + aapt2 override
#
set -eu

NDK_VERSION="29.0.14206865"
ANDROID_HOME_DEFAULT="$HOME/android-sdk"
NDK_DIR_DEFAULT="$HOME/Android/android-ndk-r29"
PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$*" >&2; exit 1; }

set_prop() { # file key value
  local f="$1" k="$2" v="$3"
  [ -f "$f" ] || : > "$f"
  if grep -qE "^[[:space:]]*${k}=" "$f"; then
    sed -i "s|^[[:space:]]*${k}=.*|${k}=${v}|" "$f"
  else
    # pastikan file diakhiri newline sebelum menambah baris (banyak file Flutter
    # tidak diakhiri newline -> tanpa ini, baris baru akan tersambung).
    if [ -s "$f" ] && [ -n "$(tail -c1 "$f")" ]; then printf '\n' >> "$f"; fi
    printf '%s=%s\n' "$k" "$v" >> "$f"
  fi
}

backup() { [ -f "$1" ] && cp -f "$1" "$1.bak" || true; }

PROJ="${1:-}"
[ -n "$PROJ" ] || die "Usage: patch-project.sh /path/ke/project"
[ -d "$PROJ/android" ] || die "Bukan project Flutter: '$PROJ/android' tidak ada."

ANDROID_HOME="${ANDROID_HOME:-$ANDROID_HOME_DEFAULT}"
NDK_DIR="${NDK_DIR:-$NDK_DIR_DEFAULT}"
FLUTTER_ROOT="$PREFIX_DIR/opt/flutter"

# ---------- 1. local.properties ----------
log "android/local.properties"
LP="$PROJ/android/local.properties"
backup "$LP"
# pertahankan baris yang sudah ada (sdk.dir, flutter.sdk, ...) - hanya set yang kita butuh
set_prop "$LP" "ndk.dir" "$NDK_DIR"
set_prop "$LP" "cmake.dir" "$PREFIX_DIR"
# pastikan sdk.dir & flutter.sdk ada
grep -q '^sdk.dir=' "$LP" 2>/dev/null || set_prop "$LP" "sdk.dir" "$ANDROID_HOME"
grep -q '^flutter.sdk=' "$LP" 2>/dev/null || set_prop "$LP" "flutter.sdk" "$FLUTTER_ROOT"
echo "    ndk.dir  = $NDK_DIR"
echo "    cmake.dir = $PREFIX_DIR"

# ---------- 2. build.gradle / build.gradle.kts ----------
log "android/app/build.gradle(.kts)"
BUILDFILE=""
for f in "$PROJ/android/app/build.gradle.kts" "$PROJ/android/app/build.gradle"; do
  [ -f "$f" ] && BUILDFILE="$f" && break
done
[ -n "$BUILDFILE" ] || die "build.gradle(.kts) tidak ditemukan di android/app/"

backup "$BUILDFILE"

# compileSdk
sed -i -E 's/(compileSdk(Version)?[[:space:]]*[:=]?[[:space:]]*(flutter\.compileSdkVersion|[0-9]+))/compileSdk = 34/' "$BUILDFILE"
# targetSdk
sed -i -E 's/(targetSdk(Version)?[[:space:]]*[:=]?[[:space:]]*(flutter\.targetSdkVersion|[0-9]+))/targetSdk = 34/' "$BUILDFILE"
# ndkVersion
if grep -qE 'ndkVersion' "$BUILDFILE"; then
  sed -i -E "s/ndkVersion[[:space:]]*[:=]?[[:space:]]*.*/ndkVersion = \"$NDK_VERSION\"/" "$BUILDFILE"
else
  warn "Baris ndkVersion tidak ada; tambahkan manual di blok android{}:"
  warn "  ndkVersion = \"$NDK_VERSION\""
fi

# Rapikan: untuk Groovy, sintaks "compileSdk = 34" tetap valid di AGP modern.
echo "    compileSdk=34  targetSdk=34  ndkVersion=$NDK_VERSION"

# ---------- 3. gradle.properties ----------
log "android/gradle.properties"
GP="$PROJ/android/gradle.properties"
backup "$GP"
set_prop "$GP" "android.aapt2FromMavenOverride" "$PREFIX_DIR/bin/aapt2"
set_prop "$GP" "android.enableResourceOptimizations" "false"
# jvmargs: JANGAN timpa setelan custom user. Hanya:
#   - set bila belum ada, atau
#   - turunkan default template Flutter (-Xmx8G) yang terlalu besar untuk Termux.
JVM_SAFE="-Xmx4G -XX:MaxMetaspaceSize=2G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError"
if grep -q '^org.gradle.jvmargs=' "$GP" 2>/dev/null; then
  if grep -q -- '-Xmx8G' "$GP"; then
    sed -i "s|^org.gradle.jvmargs=.*|org.gradle.jvmargs=$JVM_SAFE|" "$GP"
    echo "    jvmargs: -Xmx8G (default template) -> -Xmx4G (aman di Termux)"
  else
    echo "    jvmargs: dibiarkan (setelan custom)"
  fi
else
  set_prop "$GP" "org.gradle.jvmargs" "$JVM_SAFE"
  echo "    jvmargs: diset -Xmx4G"
fi
echo "    aapt2 override + resource opts off"

# ---------- selesai ----------
log "Selesai — project siap"
cat <<EOF
  cd "$PROJ"
  flutter build apk --debug
  flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
EOF
