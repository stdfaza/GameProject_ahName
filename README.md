# PROJECT: SCORCHED

Game FPS retro terinspirasi ULTRAKILL dan DOOM. Prototype saat ini berjalan di browser menggunakan Three.js sebelum di-port ke Godot Engine 4.

## Cara Menjalankan

Jalankan web server lokal di folder proyek:

```bash
python3 -m http.server 8080
```

Lalu buka browser di `http://localhost:8080`. Bisa juga langsung buka file `index.html` lewat browser.

## Kontrol

- **WASD**: Jalan
- **Mouse**: Arah bidik (klik layar untuk kunci kursor)
- **Space**: Lompat
- **Shift**: Dash (pakai 1 stamina)
- **Klik Kiri**: Tembak
- **Klik Kanan**: Pisau melee (nyerap darah: +20 HP, +1 stamina)
- **E**: Push / Parry (tepis bola api musuh buat mantul balik)
- **1, 2, 3**: Ganti senjata (1: Shotgun, 2: Revolver, 3: Cryo-Rifle)

## Mekanik Utama

- **Blood Absorption**: HP tidak regen otomatis. Cara utama isi darah adalah tusuk musuh dari jarak dekat pakai pisau (klik kanan).
- **Parry**: Tekan E saat bola api musuh mendekat (<6.5 unit). Bola api akan berbalik warna jadi cyan dan memantul ke arah kursor dengan damage 100 (instant kill).
- **Style Meter**: Nilai gaya bermain di pojok kanan bawah (Destructive sampai Ultrakill). Naik jika membunuh cepat, ganti senjata, dan parry.

## Musuh

Ada 10 tipe monster api dari pack itch.io dengan behavior berbeda:
- **Devil / Dragon / Elemental / Flower / Ghost / Magma**: Tipe ranged (menembakkan bola api).
- **Golem / Hound / Lantern / Crab**: Tipe melee (mengejar dan kontak fisik).

Detail stat tiap monster (HP multiplier, kecepatan, skala) ada di file `Docs/DOKUMENTASI.txt`.

## Struktur File

- `index.html`: File utama game (logika player, Three.js loop, HUD, Web Audio synth).
- `monsters_data.js`: Data base64 spritesheet 10 monster (supaya aman dari error CORS browser).
- `assets/monsters/`: Spritesheet PNG bersih (256x64 px) untuk bahan SpriteFrames Godot.
- `assets/fire_monsters/`: Asset mentah dari itch.io.
- `Docs/DOKUMENTASI.txt`: Dokumentasi teknis lengkap gameplay, behavior musuh, dan rencana scene Godot.
- `scripts/` & `project.godot`: Konfigurasi Godot untuk tahap porting berikutnya.

## Kredit Asset

- Monster sprites: [16 Fire Monsters Animated Pixel Art Creature Pack](https://sassion.itch.io/16-fire-monsters-animated-pixel-art-creature-pack) oleh sassion (itch.io).
- Framework 3D web: Three.js r128 via CDN.
