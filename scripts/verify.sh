#!/data/data/com.termux/files/usr/bin/bash
#
# verify.sh — Cek kesehatan toolchain Termux Flutter + Android.
#
#   bash scripts/verify.sh            # cek toolchain
#   bash scripts/verify.sh --smoke    # + build APK debug hello-world (butuh waktu)
#
set -u

PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
NDK_DIR="${NDK_DIR:-$HOME/Android/android-ndk-r29}"
FLUTTER_ROOT="$PREFIX_DIR/opt/flutter"
E="$FLUTTER_ROOT/bin/cache/artifacts/engine"

ok=0; bad=0
chk() { # label condition-result-string
  if [ "$1" = "1" ]; then printf '  \033[1;32m✓\033[0m %s\n' "$2"; ok=$((ok+1));
  else printf '  \033[1;31m✗\033[0m %s\n' "$2"; bad=$((bad+1)); fi
}

echo "== Versi =="
command -v flutter >/dev/null && flutter --version 2>/dev/null | head -1 || echo "  flutter: TIDAK ADA"
[ -x "$PREFIX_DIR/lib/jvm/java-17-openjdk/bin/java" ] && \
  echo "  JDK17: $("$PREFIX_DIR/lib/jvm/java-17-openjdk/bin/java" -version 2>&1 | head -1)"

echo
echo "== Binary kunci (harus aarch64/ARM, bukan x86-64) =="
for b in "$PREFIX_DIR/bin/aapt2" "$E/linux-arm64/gen_snapshot" "$NDK_DIR/toolchains/llvm/prebuilt/linux-aarch64/bin/clang"; do
  if [ -e "$b" ]; then
    t="$(file -Lb "$b" 2>/dev/null)"
    case "$t" in
      *"ARM aarch64"*) chk 1 "$b" ;;
      *x86-64*)        chk 0 "$b  → x86-64! (lihat docs/09 #4)" ;;
      *)               chk 0 "$b  → $t" ;;
    esac
  else
    chk 0 "$b  → tidak ada"
  fi
done

echo
echo "== build-tools sudah di-patch? =="
BT="$(ls -d "$ANDROID_HOME"/build-tools/*/ 2>/dev/null | head -1)"
if [ -n "$BT" ]; then
  for tool in aapt2 aidl; do
    if [ -L "${BT}${tool}" ]; then chk 1 "${BT}${tool} -> symlink"
    else chk 0 "${BT}${tool} masih binary SDK (lihat docs/05)"; fi
  done
else
  chk 0 "build-tools tidak ditemukan"
fi

echo
echo "== Patch SDK Flutter =="
CML="$FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/groovy/CMakeLists.txt"
grep -q 'project(flutter_ndk_stub' "$CML" 2>/dev/null && chk 1 "CMakeLists.txt di-patch" || chk 0 "CMakeLists.txt belum di-patch (docs/06 #1)"
[ -f "$E/common/flutter_patched_sdk_product/platform_strong.dill" ] && \
  chk 1 "flutter_patched_sdk_product ada" || chk 0 "flutter_patched_sdk_product kosong (docs/06 #2)"
[ -e "$E/android-arm64-release/linux-arm64/gen_snapshot" ] && \
  chk 1 "gen_snapshot android-arm64-release ada" || chk 0 "gen_snapshot symlink belum dibuat (docs/06 #3)"

echo
echo "== Konfigurasi global =="
[ -f "$HOME/.gradle/gradle.properties" ] && grep -q aapt2FromMavenOverride "$HOME/.gradle/gradle.properties" && \
  chk 1 "~/.gradle/gradle.properties punya aapt2 override" || chk 0 "gradle.properties global belum diset (docs/05 #2)"
grep -q 'android-sdk' "$HOME/.bashrc" 2>/dev/null && chk 1 "~/.bashrc sudah diset" || chk 0 "~/.bashrc belum diset (docs/05 #1)"

echo
echo "== Ringkasan: $ok ok, $bad bermasalah =="
[ "$bad" -eq 0 ] || echo "  Perbaiki item di atas (lihat docs/09 troubleshooting)."

if [ "${1:-}" = "--smoke" ]; then
  echo
  echo "== Smoke test: build APK debug =="
  D="$HOME/.termux-flutter-smoke"
  rm -rf "$D"
  flutter create --platforms=android --project-name smoke "$D" >/dev/null 2>&1 || { echo "  flutter create gagal"; exit 1; }
  bash "$(dirname "$0")/patch-project.sh" "$D" >/dev/null 2>&1 || true
  ( cd "$D" && flutter build apk --debug ) && echo "  SMOKE OK" || echo "  SMOKE GAGAL"
  rm -rf "$D"
fi
