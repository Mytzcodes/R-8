# R&8_DV ImGui Framework (v6.2)

Framework **R&8_DV ImGui v6.2** adalah arsitektur UI Roblox berbasis Luau dengan desain **Colourful 2.5D / 3D Gradient Text**, **Illustrated Animated Canvas**, **Illustrated Smooth Loader**, serta tata letak 2 atau 3 panel yang ringan dan responsif.

---

## Daftar Pembaruan & Perbaikan Bug (v6.2)

1. **Perbaikan Crash `GetReadableTextColor`**: Menambahkan fungsi kalkulasi kontras luminansi `GetReadableTextColor` yang sebelumnya belum terdefinisi saat `BindTheme` dan `SetTheme` dipanggil.
2. **Perbaikan Transparansi Panel Utama (`BgTransparency`)**: Memisahkan transparansi `MainWindow` (`1` / transparan penuh tanpa kotak latar belakang) dengan transparansi panel (`0.04` default), sehingga `LeftSidebar`, `TopBar`, `CenterPanel`, dan `RightPanel` langsung tampil jelas sejak awal.
3. **Penghapusan Duplicate Border Color pada Popup Icon Menu**: Menghapus layer bezel ganda (`MinInnerBezel`) dan double stroke pada tombol *Floating Shortcut* (`R8DV_FloatingShortcut`), opsi `Dropdown`, `NavBtn`, serta `BarFill`/`Slider Fill` sehingga setiap elemen hanya memiliki **1 border bersih**.
4. **2.5D & 3D Colourful Gradient Text (Tetap Ringan)**: Menggunakan kombinasi `TextColor3` putih murni + `UIGradient` 3-titik warna (`TextGradTop`, `TextGradMid`, `TextGradBot` / `Accent3D` / `Body25D`) + 1 `UIStroke` bayangan kontekstual (`DepthShadow`) tanpa menduplikasi `TextLabel`.
5. **5 Tema Warna Colourful Sesuai Nama Tema**:
   - `Blue Night Sky` — Biru malam safir dengan gradasi langit sian & biru elektrik.
   - `Orange Sand` — Gurun senja hangat dengan gradasi emas pasir & oranye matahari.
   - `Midnight Monokai` — Charcoal gelap Monokai dengan aksen hijau neon, sian, dan magenta.
   - `Sakura Cyber Neon` — Ungu malam beludru dengan gradasi merah muda bunga sakura & neon rose.
   - `Emerald Aurora` — Hijau pinus kutub dengan gradasi zamrud aurora & kristal mint.
6. **Illustrated Animated Canvas & Loader Nyaman**:
   - Loader awal (`RunInternalLoader`) dilengkapi ilustrasi cincin orbital, partikel geometris melayang, persentase real-time, dan transisi *fade-out* halus.
   - Widget baru `c:IllustratedCanvas({...})` untuk menampilkan ilustrasi lanskap geometris & matahari/orbital 2.5D beranimasi lembut di dalam halaman.
7. **Perbaikan Live UI Scale & Dropdown Interaktif**: Menambahkan `UI:SetScale(scale)` untuk mengubah ukuran UI secara langsung dan membuat `Dropdown` membuka daftar pilihan interaktif dengan animasi chevron.

---

## Cara Penggunaan Cepat (Via GitHub RAW)

```lua
-- 1. Load Framework via GitHub RAW (Jangan ubah link ini)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"))()

-- 2. Inisialisasi Jendela Utama
local UI = ImGui({
    Title = "DRY CURSED  -  IMGUI",
    Theme = "Blue Night Sky",     -- "Blue Night Sky" | "Orange Sand" | "Midnight Monokai" | "Sakura Cyber Neon" | "Emerald Aurora"
    CheckboxStyle = "Modern",     -- "Modern" | "Classic" | "Biasa"
    LetterSpacing = 0,
    Text3D = true,                -- Teks 2.5D / 3D Berwarna
    AutoLoading = true            -- Animasi Loading Ilustrasi
}).Call(3)                        -- 3 Panel (Kiri, Tengah, Kanan) atau 2 Panel
```

---

## 5 Pilihan Tema Warna Colourful

| Nama Tema | Karakteristik Warna Utama | Gradasi Teks 2.5D / 3D |
| :--- | :--- | :--- |
| **`Blue Night Sky`** | Midnight Sapphire (`#0A0E18`) & Azure (`#58A6FF`) | Putih Es → Sian Bintang → Biru Langit Malam |
| **`Orange Sand`** | Desert Dusk (`#160F0C`) & Solar Amber (`#FF943A`) | Krem Terang → Emas Pasir → Oranye Senja |
| **`Midnight Monokai`** | Monokai Charcoal (`#10110E`) & Neon Lime (`#A6E22E`) | Putih Gading → Hijau Monokai → Sian Elektrik |
| **`Sakura Cyber Neon`** | Velvet Plum (`#140C18`) & Sakura Pink (`#FF5CB2`) | Putih Rose → Pink Pastel → Neon Magenta |
| **`Emerald Aurora`** | Abyssal Pine (`#0A1412`) & Aurora Mint (`#2EE6A6`) | Putih Kristal → Mint Cahaya → Hijau Zamrud |

Ganti tema kapan saja secara *real-time* menggunakan:
```lua
UI:SetTheme("Sakura Cyber Neon")
```

---

## Dokumentasi API & Widget

### 1. Konfigurasi `ImGui(config)`

| Parameter | Tipe | Default | Keterangan |
| :--- | :--- | :--- | :--- |
| `Title` | `string` | `"DRY CURSED  -  IMGUI"` | Judul pada TopBar dan Loader |
| `Theme` | `string` | `"Blue Night Sky"` | Nama tema warna awal (5 pilihan tersedia) |
| `CheckboxStyle` | `string` | `"Modern"` | Bentuk toggle default: `"Modern"`, `"Classic"`, `"Biasa"` |
| `Sides` | `number` | `3` | Jumlah kolom panel (`2` atau `3`) |
| `Scale` | `number` | `1` | Skala ukuran UI (`0.5` – `1.5`) |
| `BgTransparency` | `number` | `0.04` | Transparansi panel (`0` – `0.65`) |
| `Text3D` | `boolean` | `true` | Mengaktifkan shader gradasi teks 2.5D/3D |
| `AutoLoading` | `boolean` | `true` | Menjalankan animasi loading saat inisialisasi |
| `ToggleKey` | `Enum.KeyCode` | `Enum.KeyCode.RightShift` | Tombol keyboard untuk buka/tutup menu |

### 2. Method Instance `UI`

- `UI.Call(sideCount)` — Mengatur tata letak menjadi `2` atau `3` panel.
- `UI:SetTheme(themeName)` — Mengganti tema warna secara *real-time*.
- `UI:SetScale(scale)` — Mengubah skala ukuran jendela (`0.5` s/d `1.5`).
- `UI:SetTransparency(alpha)` — Mengubah transparansi latar panel (`0` s/d `0.65`).
- `UI:SetCheckboxStyle(styleName)` — Mengubah bentuk semua toggle (`"Modern"`, `"Classic"`, `"Biasa"`).
- `UI:SetRounded(state)` — Mengaktifkan/menonaktifkan sudut membulat (`true`/`false`).
- `UI:SetValue(flag, value)` / `UI:GetValue(flag)` — Mengatur atau membaca nilai flag.
- `UI:OnValueChanged(flag, callback)` — Mendengarkan perubahan nilai pada suatu flag.
- `UI:MinimizeToIcon()` / `UI:RestoreFromIcon()` / `UI:ToggleMenu()` — Mengatur kondisi minimize ke *Popup Icon Menu*.
- `UI:Destroy()` — Menghapus UI dan memutuskan seluruh koneksi event dengan bersih.

### 3. Membuat Tab / Feature & Widget Canvas

```lua
local feature = UI.feature

feature("Home", "Home")({
    center = function(c)
        -- Header Halaman
        c:Header("Home", "Subtitle deskripsi halaman", "Badge")

        -- Canvas Ilustrasi Animasi 2.5D
        c:IllustratedCanvas({
            Tag = "2.5D ILLUSTRATED",
            Title = "Judul Ilustrasi",
            Subtitle = "Deskripsi singkat pada kartu ilustrasi",
            Height = 108
        })

        -- Baris Statistik (StatRow)
        c:StatRow({
            { Icon = "Bolt",   Label = "Status",  Value = "Safe" },
            { Icon = "Clock",  Label = "Runtime", Value = "00:12:34" },
            { Icon = "Shield", Label = "Version", Value = "v6.2.0" }
        })

        -- Card Container
        local Card = c:Card("Judul Card", "Action Text", "Bolt")

        -- Grid Tombol Aksi Cepat
        Card:ActionGrid({
            { Icon = "AutoFarm", Name = "Auto Farm", Flag = "QuickAutoFarm", Callback = function(state) end }
        })

        -- Toggle / Checkbox (Mendukung "Modern", "Classic", "Biasa")
        Card:Toggle("Aktifkan Fitur", "FlagToggle", true, function(val)
            print("Toggle:", val)
        end, "Modern")

        -- Slider Angka
        Card:Slider("WalkSpeed", "FlagSpeed", 16, 200, 16, " studs", function(val)
            print("Slider:", val)
        end)

        -- Stepper (- / +)
        Card:Stepper("Prioritas", "FlagPrio", 1, 1, function(val)
            print("Stepper:", val)
        end)

        -- Dropdown Interaktif
        Card:Dropdown("Pilih Tema", "FlagTheme", UI:GetThemes(), "Blue Night Sky", function(opt)
            UI:SetTheme(opt)
        end)

        -- TextBox Input
        Card:Input("Target Player", "FlagTarget", "Username...", "", function(text)
            print("Input:", text)
        end)

        -- Linimasa Aktivitas
        Card:ActivityTimeline({
            { Text = "Engine Initialized", Time = "Just now" }
        })
    end,

    right = function(r)
        r:Section("Pengaturan Cepat", "Settings")
        r:Toggle("Lock Position", "LockPosition", false)
    end
})
```

---

## Struktur File Repository

- [`r&8_dv.lua`](r&8_dv.lua) — Core engine R&8_DV ImGui v6.2.
- [`Sample Gui/SampleGui.lua`](Sample%20Gui/SampleGui.lua) — Contoh implementasi lengkap beserta demo 5 tema warna, 3 gaya checkbox, dan *Illustrated Canvas*.
- [`Assets/icons.png`](Assets/icons.png) — Master logo/emblem resmi R&8_DV.
- [`Assets/Jersey25-Regular.ttf`](Assets/Jersey25-Regular.ttf) — Font kustom bawaan framework.
