# MyFinance (Android & iOS)

Aplikasi dibungkus dengan Capacitor. Data disimpan di penyimpanan lokal aplikasi
(tetap ada saat aplikasi ditutup atau HP dimatikan, hilang jika aplikasi di-uninstall,
jadi rutin pakai Atur > Unduh backup).

## Persiapan (sekali saja)
Butuh Node.js 18+. Android: Android Studio. iOS: Mac + Xcode.

    npm install
    npx cap add android      # untuk Android
    npx cap add ios          # untuk iOS (hanya di Mac)

## Menjalankan / membuat aplikasi
    npm run android          # buka di Android Studio, lalu Run, atau Build > Build APK
    npm run ios              # buka di Xcode, pilih device, lalu Run

Setiap mengubah isi `www/index.html`, jalankan lagi `npm run sync`.

## Catatan
- `npm run prep` menyalin library Excel ke `www/` agar export/import bisa dipakai offline.
- Export Excel dan backup membuka menu bagikan HP, pilih "Simpan ke File/Drive".
- Rilis ke Play Store/App Store butuh akun developer dan ikon (opsional: `npx @capacitor/assets generate`).

## Sinkronisasi Android <-> Web (Supabase)
1. Buat project gratis di supabase.com, buka SQL Editor, jalankan isi `supabase.sql`.
2. Authentication > Providers > Email: matikan "Confirm email" (agar bisa langsung masuk).
3. Settings > API: salin Project URL dan anon public key ke `www/config.js`.
4. Unggah ke GitHub (repo Public), Settings > Pages > Source: GitHub Actions. Jalankan workflow "Deploy Web" lalu "Build APK".
5. iPhone: buka alamat web (https://USERNAME.github.io/NAMA-REPO/) di Safari > Bagikan > Tambah ke Layar Utama.
Android (APK) dan web memakai akun yang sama, data otomatis sinkron.
