# 08 — Building

## Debug APK

```bash
cd ~/my_app
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`.

Debug build memakai JIT (snapshot kernel) sehingga **tidak** butuh `gen_snapshot` AOT.
Ini jalur paling cepat untuk memvalidasi bahwa toolchain sehat.

## Release APK

```bash
flutter build apk --release \
  --target-platform android-arm64 \
  --no-tree-shake-icons
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

### Kenapa flag-nya begitu

| Flag | Alasan |
|---|---|
| `--target-platform android-arm64` | **Wajib.** Hanya arm64 yang punya `gen_snapshot` aarch64. ABI lain akan gagal di tahap AOT. |
| `--no-tree-shake-icons` | Menghindari langkah icon tree-shaking yang bermasalah pada Dart JIT/AOT di setup ini. |

> Ukuran contoh: debug 84 MB (4 ABI), release arm64 7.5 MB.

## Per-ABI (memperkecil debug)

Debug default membangun **semua** ABI. Untuk lebih cepat/kecil:

```bash
flutter build apk --debug --target-platform android-arm64
```

## Install ke device (opsional)

Gunakan `adb` aarch64 dari `android-tools` Termux:

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Atau copy APK ke folder Download:

```bash
cp build/app/outputs/flutter-apk/app-release.apk ~/storage/downloads/
```

## Verifikasi APK tanpa install

```bash
APK=build/app/outputs/flutter-apk/app-release.apk

# metadata & SDK target
$PREFIX/bin/aapt2 dump badging "$APK" | head

# isi penting
unzip -l "$APK" | grep -E 'lib/|classes.dex|AndroidManifest'

# tanda tangan
$PREFIX/bin/apksigner verify --print-certs "$APK"
```

APK release dari template Flutter default ditandatangani dengan **debug key**
(`CN=Android Debug`) — cukup untuk sideload, **tidak** untuk Play Store. Ganti
`signingConfig` untuk produksi.

## Tips

- **Wake lock** selama build panjang:
  ```bash
  termux-wake-lock
  flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons
  termux-wake-unlock
  ```
- **Build pertama lambat** (Gradle mengunduh distribusi + dependensi). Build berikutnya jauh
  lebih cepat.
- Setelah build sukses pertama, bisa tambahkan `--offline` untuk build berikutnya bila
  dependensi tidak berubah.
- Bersihkan bila perlu:
  ```bash
  flutter clean
  rm -rf android/app/.cxx
  ```

## Cheat sheet

```bash
# debug (semua ABI)
flutter build apk --debug

# debug (arm64 saja, lebih cepat)
flutter build apk --debug --target-platform android-arm64

# release (arm64) — gunakan ini
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

# via Gradle langsung (misal untuk inspeksi)
cd android && ./gradlew assembleRelease --stacktrace
```

Lanjut → [09 — Troubleshooting](09-troubleshooting.md)
