# 03 — Flutter SDK (aarch64)

## Kenapa tidak pakai Flutter resmi?

Flutter resmi mengasumsikan host **glibc** (`linux-x64`/`linux-arm64` dari Google). Termux
memakai **bionic** (libc Android), linker berbeda, dan layout toolchain berbeda. Flutter SDK
resmi **tidak bisa** dijalankan langsung di Termux.

Satu-satunya jalur praktis adalah SDK Flutter yang sudah di-cross-compile untuk Termux:
[`mumumusuc/termux-flutter`](https://github.com/mumumusuc/termux-flutter) (rilis `.deb` aarch64).

> ⚠️ Hindari fork/klaim lain yang tampak lengkap di mesin pencari tapi **asset rilisnya kosong**
> (contoh: `Leonisaurov/termux-flutter` — API GitHub mengembalikan `[]` dan installer-nya
> menunjuk repo 404). Selalu cek asset rilis benar-benar ada.

## 1. Dependensi runtime

`.deb` Flutter butuh `x11-repo` dan beberapa library GTK (dipakai untuk build desktop/Linux):

```bash
pkg install -y x11-repo
pkg update -y
pkg install -y which gtk3 xorgproto ninja cmake clang pkg-config
```

> GTK3 menarik banyak paket — wajar, dan perlu, karena `.deb` mendeklarasikannya sebagai
> dependensi (`Pre-Depends: x11-repo`, `Depends: which, gtk3, ...`).

## 2. Unduh `.deb`

```bash
cd ~
curl -L --fail -o flutter_3.29.2_aarch64.deb \
  https://github.com/mumumusuc/termux-flutter/releases/download/3.29.2/flutter_3.29.2_aarch64.deb
```

## 3. Verifikasi checksum

```bash
sha256sum flutter_3.29.2_aarch64.deb
# harus:
# 5146c9db44b6fdcaf932b08d6f2d033a3470df26dca16070cab70e35f0b0dd9d
```

Ukuran file ± 476 MB (455 MiB).

## 4. Install

```bash
dpkg -i flutter_3.29.2_aarch64.deb
apt --fix-broken install -y    # kalau ada dependensi kurang
```

Paket terinstall ke `$PREFIX/opt/flutter`, dan `dpkg` membuat wrapper `$PREFIX/bin/flutter`.

Isi wrapper:

```sh
#!/data/data/com.termux/files/usr/bin/sh
exec /data/data/com.termux/files/usr/opt/flutter/bin/flutter "$@"
```

## 5. Uji

```bash
flutter --version
```

Output yang diharapkan:

```
Flutter 3.29.2 • channel [user-branch] • unknown source
Framework • revision c236373904 (…)
Engine • revision 18b71d647a
Tools • Dart 3.7.2 • DevTools 2.42.0
```

> Run pertama lebih lambat karena Flutter menyiapkan cache & `flutter_tools.snapshot`.
> Kalau perintah terlihat "hang", tunggu — jangan langsung Ctrl-C.

## 6. Daftarkan Android SDK ke Flutter

Setelah Android SDK terpasang ([04](04-android-sdk-and-ndk.md)):

```bash
flutter config --android-sdk "$HOME/android-sdk"
```

## Peringatan `flutter doctor` yang **normal** di Termux

Ini bukan error yang perlu diperbaiki:

- `Currently on an unknown channel`
- `flutter on your path resolves to … which is not inside your current Flutter SDK checkout`
- `The dart binary is not on your path`
- `Upstream repository unknown source is not a standard remote`
- `Android Studio (not installed)`

Yang penting: bagian **Android toolchain** harus centang hijau.

Lanjut → [04 — Android SDK & NDK](04-android-sdk-and-ndk.md)
