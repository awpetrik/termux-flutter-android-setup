# 01 — Prasyarat

## Perangkat

| Item | Syarat |
|---|---|
| CPU | **ARM64 / aarch64** (`arm64-v8a`). 32-bit ARM dan x86 tidak didukung. |
| Android | 11+ disarankan (diuji di Android 16) |
| RAM | ≥ 6 GB (build memakai Gradle + Kotlin daemon; diuji di 10 GB) |
| Storage | **≥ 6–8 GB bebas** di partisi `/data` |

> ⚠️ **Ini penyebab kegagalan paling umum.** Partisi `/data` harus punya ruang bebas cukup.
> Cek dengan:
> ```bash
> df -h /data
> ```

## Termux

- Install Termux dari **F-Droid** atau [GitHub Releases](https://github.com/termux/termux-app/releases).
  Versi Play Store sudah usang dan bermasalah.
- **Jangan** pakai Termux dari Play Store.

## Akses storage (opsional tapi disarankan)

Untuk copy APK ke folder Download:

```bash
termux-setup-storage
```

Tap **Allow**. Setelah itu `/sdcard` dan `~/storage/*` bisa dipakai.

## Setelan Android yang penting

1. **Matikan optimasi baterai untuk Termux** — kalau tidak, Android bisa mematikan proses
   build di tengah jalan (di Android 12+ dikenal sebagai *phantom process killer*):
   `Settings → Apps → Termux → Battery → Unrestricted`.

2. **(Opsional, Android 12+)** Naikkan batas phantom process via ADB di device yang sama:
   ```bash
   adb shell "device_config put activity_manager max_phantom_processes 2147483647"
   ```

3. **Wake lock** selama build panjang:
   ```bash
   termux-wake-lock
   # ... build ...
   termux-wake-unlock
   ```

## Utilitas dasar

Beberapa perintah standar Linux tidak ada di Termux secara default dan sempat bikin proses
setup gagal (lihat [Troubleshooting](09-troubleshooting.md) #10):

```bash
pkg install -y file which
```

> **Catatan shell:** Termux default pakai `sh` (bukan `bash`) untuk `sh -c`. Fitur bash seperti
> `${PIPESTATUS[0]}` **tidak jalan**. Pakai `bash` eksplisit atau hindari.

## Ringkasan path yang dipakai

| Variabel | Path |
|---|---|
| `$PREFIX` | `/data/data/com.termux/files/usr` |
| `$HOME` | `/data/data/com.termux/files/home` |
| Flutter | `$PREFIX/opt/flutter` |
| Android SDK | `$HOME/android-sdk` |
| Android NDK | `$HOME/Android/android-ndk-r29` |

Lanjut → [02 — Paket Termux](02-packages.md)
