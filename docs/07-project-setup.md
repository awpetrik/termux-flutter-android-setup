# 07 — Setup per-Project

Setelah setup global ([05](05-system-configuration.md)) dan patch SDK ([06](06-sdk-patches.md)),
**tiap** project Flutter masih perlu sedikit konfigurasi. Bisa manual, atau otomatis dengan
`scripts/patch-project.sh`.

---

## 1. `android/local.properties`

Flutter mengisi `sdk.dir`, `flutter.sdk`, dll. Tambahkan `ndk.dir` dan `cmake.dir`:

```properties
sdk.dir=/data/data/com.termux/files/home/android-sdk
ndk.dir=/data/data/com.termux/files/home/Android/android-ndk-r29
cmake.dir=/data/data/com.termux/files/usr
flutter.sdk=/data/data/com.termux/files/usr/opt/flutter
```

| Kunci | Kenapa |
|---|---|
| `ndk.dir` | Arahkan ke NDK **aarch64** (bukan NDK x86-64 yang diunduh AGP). |
| `cmake.dir` | Pakai CMake Termux (`$PREFIX/bin/cmake`), bukan CMake x86-64 yang diunduh AGP. |

> `cmake.dir` harus menunjuk direktori yang berisi `bin/cmake` dan `bin/ninja` → yaitu `$PREFIX`.

---

## 2. `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.example.app"
    compileSdk = 34
    ndkVersion = "29.0.14206865"   // ← samakan dengan Pkg.Revision NDK aarch64

    defaultConfig {
        targetSdk = 34
        // ...
    }
}
```

### Kenapa di-pin (bukan `flutter.compileSdkVersion`)

- `compileSdk = 34` menghindari masalah kompatibilitas `aapt2` Termux dengan `android.jar` baru.
- `ndkVersion` **harus** sama dengan versi NDK aarch64 yang terpasang (`Pkg.Revision`).
  Default `flutter.ndkVersion` (mis. `26.3.11579264`) tidak cocok dengan NDK r29 kita dan bisa
  memicu error mismatch.

---

## 3. `android/gradle.properties`

```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true

# --- Workaround Termux/aarch64 ---
android.aapt2FromMavenOverride=/data/data/com.termux/files/usr/bin/aapt2
android.enableResourceOptimizations=false
```

- `aapt2FromMavenOverride` di sini sebagai lapis kedua (global sudah ada, tapi aman untuk eksplisit).
- `enableResourceOptimizations=false` mengurangi beban memori/CPU saat packaging.

> Sesuaikan `-Xmx` dengan RAM device. Di device 10 GB nilai `4G` aman; kalau RAM lebih kecil,
> turunkan (mis. `2G`) agar tidak kena OOM-killer Android.

---

## Ringkas: yang perlu diubah

| File | Perubahan |
|---|---|
| `android/local.properties` | tambah `ndk.dir`, `cmake.dir` |
| `android/app/build.gradle.kts` | `compileSdk = 34`, `targetSdk = 34`, `ndkVersion = "29.0.14206865"` |
| `android/gradle.properties` | `jvmargs`, `aapt2FromMavenOverride`, `enableResourceOptimizations=false` |

Tidak ada file source (`lib/`) yang perlu diubah.

---

## Pakai script

```bash
bash scripts/patch-project.sh /path/ke/project
```

Script akan:
1. membuat/menyunting `local.properties`,
2. menimpa `compileSdk`/`targetSdk`/`ndkVersion` di `build.gradle(.kts)`,
3. menambahkan properti Termux ke `gradle.properties`,
4. membuat backup (`.bak`) sebelum mengubah.

Lanjut → [08 — Building](08-building.md)
