# PROJECT: SCORCHED

Fast-paced retro boomer shooter terinspirasi oleh **ULTRAKILL** dan classic **DOOM**. Mengusung gaya visual 2.5D retro pixel-art billboard sprites di dalam arena 3D low-poly bertema scorched inferno.

---

## 🚀 Cara Menjalankan (Quick Start)

### Opsi 1: Menjalankan via Local Web Server (Direkomendasikan)
Gunakan Python bawaan untuk menjalankan server ringan di root direktori proyek:

```bash
# Jalankan server lokal
python3 -m http.server 8080
```
Buka browser dan akses:
👉 **`http://localhost:8080`**

### Opsi 2: Buka Langsung File HTML
Buka file `index.html` langsung menggunakan browser modern (Chrome, Firefox, Zen, Edge):
```bash
# Contoh menggunakan browser langsung
xdg-open index.html
```

---

## 🎮 Kontrol Permainan

| Tombol | Aksi | Deskripsi |
| :--- | :--- | :--- |
| **W, A, S, D** | Gerak | Kecepatan lari tinggi |
| **Mouse** | Arah Pandang | Putar kamera (Klik layar untuk Pointer Lock) |
| **SPACE** | Lompat | Lompatan vertikal responsif |
| **SHIFT** | Dash | Tele-dash cepat ke arah depan (konsumsi 1 stamina) |
| **KLIK KIRI** | Tembak | Menembak dengan senjata aktif |
| **KLIK KANAN** | Melee Knife | Serang jarak dekat & **Menghisap Darah (+20 HP, +1 Stamina)** |
| **E** | Push / Parry | Mendorong musuh atau **Memantulkan Fireball musuh** |
| **1, 2, 3** | Ganti Senjata | `1` Shotgun, `2` Revolver, `3` Cryo-Rifle |

---

## ⚔️ Senjata & Mekanik Tempur

1. **[1] SHOTGUN**: Tembakan 7 pellet menyebar, damage mematikan pada jarak dekat.
2. **[2] REVOLVER**: Proyektil berkecepatan tinggi, akurasi tajam untuk target jauh.
3. **[3] CRYO-RIFLE**: Peluru berelemen es, penetrasi tinggi terhadap musuh api.
4. **MELEE KNIFE (Blood Heal)**: Sumber utama regen HP. Menyerang musuh jarak dekat menyerap darah untuk memulihkan +20 HP & +1 Stamina.
5. **PARRY MECHANIC (Tombol E)**: Menepis bola api musuh dalam jarak dekat akan memantulkan bola api tersebut kembali ke arah bidikan dengan kecepatan 90 unit/detik dan memberikan instant kill (100 damage).
6. **STYLE METER**: Skor gaya bermain kombat (`DESTRUCTIVE` → `ANARCHY` → `BRUTAL` → `CHAOS` → `SSSLAYER` → `ULTRAKILL`).

---

## 👾 Daftar Musuh (Fire Monsters)

Game ini menghadirkan 10 variasi monster dengan perilaku dan pola serang berbeda:

- **Devil**: Monster perapal proyektil bola api jarak menengah.
- **Golem**: Monster tank lava bertubuh besar dengan serangan melee kontak.
- **Hound**: Musuh pelari cepat yang mengejar pemain secara agresif.
- **Dragon**: Mini-boss berukuran besar dengan HP tebal dan proyektil beruntun.
- **Elemental**: Musuh lincah dengan manuver serangan tak terduga.
- **Flower**: Turret api stasioner yang menembakkan proyektil berkala.
- **Ghost**: Entitas melayang yang mengejar sambil menembak.
- **Lantern**: Musuh patroli cepat penabrak melee.
- **Magma**: Slime lava kecil penembak proyektil.
- **Crab**: Monster bercangkang keras tahan serangan ringan.

---

## 📁 Struktur Direktori Proyek

```text
.
├── index.html                  # Main entry point game (HTML5, Three.js, UI, Audio)
├── monsters_data.js            # Database Base64 spritesheet 10 monster (CORS-safe)
├── README.md                   # Panduan cepat proyek
├── Docs/
│   └── DOKUMENTASI.txt         # Dokumentasi teknis & arsitektur lengkap
├── assets/
│   ├── monsters/               # Spritesheet 4-frame PNG hasil ekstraksi
│   └── fire_monsters/          # Arsip mentah asset pack dari itch.io
├── scripts/                    # Script GDScript (Persiapan porting Godot)
└── project.godot               # Konfigurasi project Godot
```

---

## 🗺️ Roadmap Pengembangan

- [x] Prototype WebGL/Three.js playable di browser.
- [x] Sistem UI / HUD bergaya retro ULTRAKILL (Health, Stamina, Style Meter, Wave Indicator).
- [x] Integrasi 10 monster animated billboard pixel-art dari itch.io.
- [x] Sistem audio synthesizer procedural Web Audio API (tanpa file audio eksternal).
- [ ] Porting arsitektur gameplay ke **Godot Engine 4.x** (3D Environment + `AnimatedSprite3D`).
- [ ] Penambahan sound effects WAV/OGG retro berkualitas tinggi dan BGM synth-metal.
- [ ] Desain level multi-room dengan arena trap dan boss fight.

---

## 📜 Credits & Attribution

- **Monster Assets**: ["16 Fire Monsters Animated Pixel Art Creature Pack"](https://sassion.itch.io/16-fire-monsters-animated-pixel-art-creature-pack) oleh **sassion** via itch.io.
- **Engine Framework**: [Three.js](https://threejs.org/) (r128).
