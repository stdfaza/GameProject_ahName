# PROJECT: SCORCHED

Game FPS retro terinspirasi ULTRAKILL dan DOOM. Tersedia dalam dua versi: native Godot Engine 4 dan versi web HTML5/Three.js.

## Cara Menjalankan

### 1. Godot Engine 4 (Versi Native)
Buka terminal di root proyek:

```bash
godot
```
Atau buka di editor:
```bash
godot -e
```

### 2. Browser (Versi Web)
Jalankan web server lokal di folder proyek:

```bash
python3 -m http.server 8080
```
Buka browser di `http://localhost:8080` (atau langsung buka file `index.html`).

## Kontrol

- **WASD**: Jalan
- **Mouse**: Arah bidik (klik layar untuk kunci kursor)
- **Space**: Lompat
- **Shift**: Dash (pakai 1 stamina)
- **Klik Kiri**: Tembak
- **Klik Kanan**: Pisau melee (nyerap darah: +20 HP, +1 stamina)
- **E**: Push / Parry (tepis bola api musuh buat pantul balik)
- **1, 2, 3**: Ganti senjata (1: Shotgun, 2: Revolver, 3: Cryo-Rifle)

## Mekanik Utama

- **Codename / Nickname**: Masukkan nama di menu awal sebelum misi dimulai. Nama otomatis tersimpan lokal (`user://player_data.cfg` di Godot / `localStorage` di web) jadi tidak perlu ketik ulang.
- **Online Scoreboard**: Skor akhir otomatis dikirim lewat HTTP POST ke server scoreboard (`/api/scores`) saat pemain gugur atau menyelesaikan Wave 3.
- **Blood Absorption**: Darah tidak regenerasi otomatis. Satu-satunya cara memulihkan HP adalah menusuk musuh dari jarak dekat pakai pisau (klik kanan).
- **Parry**: Tekan E saat bola api musuh mendekat (<6.5 unit). Bola api berubah jadi cyan dan memantul balik ke arah crosshair dengan kecepatan 90 unit/detik dan damage 100 (instant kill).
- **Style Meter**: Rating kombat di pojok kanan bawah (Destructive sampai Ultrakill). Poin bertambah lewat kill cepat, pergantian senjata, dash, dan parry.

## Roster Musuh

Ada 10 tipe monster api dari pack itch.io:
- **Ranged (Tembak bola api)**: Devil, Dragon, Elemental, Flower, Ghost, Magma.
- **Melee (Kejar & serang kontak)**: Golem, Hound, Lantern, Crab.

Detail stat lengkap (HP multiplier, kecepatan, skala visual) tersedia di `Docs/DOKUMENTASI.txt`.

## Struktur Direktori

- `scenes/`: Scene Godot 4 (`main.tscn`, `player.tscn`, `enemy.tscn`, `bullet.tscn`, `fireball.tscn`).
- `scripts/`: Script gameplay Godot (`main.gd`, `player.gd`, `enemy.gd`, `bullet.gd`, `fireball.gd`, `synth_audio.gd`).
- `assets/frames/`: Resource animasi `SpriteFrames` (.tres) 10 monster untuk AnimatedSprite3D.
- `assets/monsters/`: Spritesheet PNG bersih (256x64 px).
- `assets/fire_monsters/`: Arsip asset asli dari itch.io.
- `index.html`: Entry point versi web prototype (Three.js + procedural audio synth).
- `monsters_data.js`: Database Base64 spritesheet monster untuk versi web (bebas CORS).
- `Docs/DOKUMENTASI.txt`: Dokumentasi teknis lengkap dan arsitektur game.
- `project.godot`: Konfigurasi project Godot 4 & Input Map.

## Kredit Asset

- Monster sprites: [16 Fire Monsters Animated Pixel Art Creature Pack](https://sassion.itch.io/16-fire-monsters-animated-pixel-art-creature-pack) oleh sassion (itch.io).
- 3D engine web: Three.js r128 via CDN.
