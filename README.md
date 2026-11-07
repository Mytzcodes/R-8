# R&8_DV ImGui Framework (v6.3)

Framework **R&8_DV ImGui v6.3** adalah arsitektur UI Roblox berbasis Luau dengan desain **Clean Flat Colourful**, **Font Besar & Mudah Dibaca**, **Illustrated Animated Canvas**, **Illustrated Smooth Loader**, serta tombol aktif yang bersih tanpa garis border yang mengganggu.

---

## Daftar Pembaruan & Perbaikan Bug (v6.3)

1. **Penghapusan Efek 2.5D / 3D pada Teks**: Menghapus `UIStroke` dan `UIGradient` pada `TextLabel` yang sebelumnya membuat font `Jersey25` terlihat pecah/rusak. Kini seluruh teks menggunakan warna solid ber-kontras tinggi (`TextPrimary`, `Accent`, `AccentSecondary`, `TextMuted`) yang tajam dan jernih.
2. **Ukuran Font Diperbesar agar Mudah Dibaca User**:
   - Header: `34px` | Card Title: `22px` | Section & Body: `20px` | Small/Value: `18px` | Sidebar Tab: `21px`.
   - Tinggi baris (`RowHeight`) diperbesar menjadi `38px` agar teks memiliki ruang yang lega.
3. **Perbaikan Total Fitur Checklist / Toggle (`Modern`, `Classic`, `Biasa`)**:
   - Seluruh baris (`Row`) kini dapat diklik dengan responsif (`Active = false` pada sub-elemen agar tidak memblokir klik).
   - Ikon centang (`Classic`) diperbaiki sudut geometrinya dan menggunakan warna kontras gelap (`OnAccentText`) di atas latar `Accent` sehingga terlihat sangat jelas di semua tema.
   - Posisi awal `Knob` pada gaya `Modern` langsung presisi sejak inisialisasi (tidak melenceng saat berada di tab yang belum dibuka).
4. **Penghapusan Border Aneh pada Tombol Aktif**:
   - Tombol tab Sidebar (`NavBtn`), tombol `ActionGrid`, `Toggle` (`HitBtn`), `Dropdown`, `Stepper`, `Input`, dan *Popup Icon Menu* (`R8DV_FloatingShortcut`) kini **bebas dari garis border ganda/kotak**. Status aktif ditampilkan menggunakan perubahan warna permukaan (`ControlActiveBg` / `Accent`) yang halus.
5. **5 Tema Warna Colourful Sesuai Nama Tema**:
   - `Blue Night Sky` — Biru malam safir dengan aksen biru langit & sian terang.
   - `Orange Sand` — Gurun senja hangat dengan aksen oranye matahari & emas pasir.
   - `Midnight Monokai` — Charcoal gelap Monokai dengan aksen hijau neon & sian.
   - `Sakura Cyber Neon` — Ungu malam dengan aksen merah muda bunga sakura & neon rose.
   - `Emerald Aurora` — Hijau pinus kutub dengan aksen zamrud aurora & mint kristal.

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
    AutoLoading = true            -- Animasi Loading Ilustrasi
}).Call(3)                        -- 3 Panel (Kiri, Tengah, Kanan) atau 2 Panel
```

---

## 5 Pilihan Tema Warna Colourful

| Nama Tema | Latar Utama (`PanelBg`) | Warna Aksen (`Accent`) | Aksen Kedua (`AccentSecondary`) |
| :--- | :--- | :--- | :--- |
| **`Blue Night Sky`** | `#101624` (Midnight Sapphire) | `#4EA8FF` (Electric Azure) | `#91E4FF` (Sky Cyan) |
| **`Orange Sand`** | `#1F1612` (Desert Dusk) | `#FF983C` (Solar Amber) | `#FFDA82` (Golden Sand) |
| **`Midnight Monokai`** | `#191B16` (Monokai Charcoal) | `#A6E22E` (Neon Lime) | `#66D9EF` (Cyber Cyan) |
| **`Sakura Cyber Neon`** | `#1F1326` (Velvet Plum) | `#FF60B4` (Sakura Pink) | `#FFBAE6` (Pastel Rose) |
| **`Emerald Aurora`** | `#0F1E1B` (Abyssal Pine) | `#2EE6A6` (Aurora Emerald) | `#8EFFD6` (Mint Crystal) |

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

        -- Canvas Ilustrasi Animasi
        c:IllustratedCanvas({
            Tag = "ILLUSTRATED UI",
            Title = "Judul Ilustrasi",
            Subtitle = "Deskripsi singkat pada kartu ilustrasi",
            Height = 114
        })

        -- Baris Statistik (StatRow)
        c:StatRow({
            { Icon = "Bolt",   Label = "Status",  Value = "Safe" },
            { Icon = "Clock",  Label = "Runtime", Value = "00:12:34" },
            { Icon = "Shield", Label = "Version", Value = "v6.3.0" }
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
