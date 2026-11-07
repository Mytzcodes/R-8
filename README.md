# R&8_DV ImGui Framework (v5.2 — Full Colourful Gradient & Heavy Display Typography Edition)

Framework **R&8_DV ImGui v5.2** adalah arsitektur UI Roblox berbasis Luau dengan **Full Dual-Hue Colourful Gradients** di seluruh elemen antarmuka, **Heavy Display Typography (`GothamBlack`)** untuk menekankan hierarki & maksud fitur, **Circular Palette Swatches**, **Vibrant CTA Buttons**, serta jaminan **60 FPS Stabil (0% FPS Drop)** di PC maupun Android/Mobile (`OpenGL ES` Safe).

---

## Ringkasan Pembaruan & Fitur Utama (v5.2)

1. **Full Colourful Dual-Hue Gradients di Seluruh Isi Menu (`2-Point Vertex Safe`)**:
   - Seluruh komponen kini hidup dengan gradasi 2 warna (*dual-hue* `Accent -> AccentEnd` & `HeroBgStart -> HeroBgEnd`): **Hero Page Header**, **`HighlightBanner`**, **Tab Navigasi Aktif**, **Badge Icon Kartu**, **Garis Pemisah `Card` & `Section`**, **Switch / Checkbox Aktif**, **Progress Bar `Slider` + Value Pill**, **Grid Tile Aktif**, **Tag Tema TopBar**, serta **Tombol `Button` CTA**.
   - Menggunakan murni **2-keypoint `ColorSequence.new(colorA, colorB)`** tanpa `UIStroke` pada teks sehingga aman 100% dari *black ramp texture bug* di shader `OpenGL ES` Roblox Mobile dan tetap ringan di **60 FPS**.
2. **Heavy Display Typography & Penekanan Makna (`GothamBlack` + Ukuran Besar)**:
   - Hierarki font dipertebal dan diperbesar agar maksud tiap bagian langsung menonjol: `Header` (`26px GothamBlack`), `HighlightBanner` (`22px GothamBlack`), `BrandMainTitle` di bawah logo (`22px GothamBlack`), `Card` (`18px GothamBlack`), `StatRow` (`18px GothamBlack`), `FeatureCard` (`16px GothamBlack`), dan `Section` / `Button` (`15px GothamBlack`).
   - Setiap kontrol (`Toggle`, `Slider`, `ActionGrid`, `Dropdown`) otomatis menebalkan font dari `GothamBold` ke **`GothamBlack` dengan gradasi warna aksen (`ActiveTop -> ActiveBot`)** saat aktif/dipilih.
3. **Komponen Baru Sesuai Referensi Desain Modern**:
   - **`HighlightBanner(eyebrow, headline, subtext, badgeText)`**: Kartu poster bergradasi warna penuh dengan *headline* ekstra-tebal huruf besar untuk highlight utama.
   - **`ThemeSwatches(label)`**: Pemilih 5 palet warna berbentuk **lingkaran gradasi bulat (*circular swatches*)** lengkap dengan *selection ring* + tanda centang `✓` yang tersinkronisasi langsung dengan tema aktif.
4. **Tata Letak Lega (`1100x560`), `Maximize` Proporsional, Single-Border Popup Icon & GitHub RAW Utuh**:
   - Proporsi 3 kolom (`22% | 46% | 32%`) bebas kepotong, *hard-cap* `Maximize` agar pas di semua layar, **1 border bersih** pada Popup Icon Menu (`R8DV_FloatingSquircle`), transisi instan `0ms` (`AutoLoading = false`), dan seluruh link **GitHub RAW** tetap utuh.

---

## Cara Penggunaan (Via GitHub RAW)

> **Penting:** Pastikan file `r&8_dv.lua` terbaru sudah di-*push* ke repositori GitHub `Mytzcodes/R-8` (branch `main`). Nama file `r&8_dv.lua` menggunakan URL-encode `%26` (`r%268_dv.lua`) agar tidak terkena **HTTP 404**.

```lua
-- 1. Panggil Framework R&8_DV langsung via GitHub RAW
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"))()

-- 2. Inisialisasi Jendela Utama (3 Panel atau 2 Panel)
local UI = ImGui({
    Title = "DRY CURSED - IMGUI",
    BrandTitle = "R&8_DV",           -- Judul huruf besar ekstra-tebal di bawah logo sidebar
    BrandSubtitle = "IMGUI SUITE",   -- Sub-judul bergradasi aksen di bawah logo sidebar
    Theme = "Blue Night Sky",        -- Pilihan 5 tema bergradasi warna hidup di bawah
    CheckboxStyle = "Modern",        -- "Modern" | "Checkbox"
    Text3D = true,                   -- Tipografi berwarna dual-hue gradient (60 FPS)
    LetterSpacing = 1,               -- Spasi antar huruf judul & header (0 - 3)
    AutoLoading = false              -- Buka instan 0ms tanpa delay!
}).Call(3)
```

---

## Daftar 5 Tema Warna (Dual-Hue Colourful Gradients)

| Nama Tema | Surface Dasar | Gradasi Aksen Utama (`Accent -> AccentEnd`) & Font Display |
| :--- | :--- | :--- |
| **`Blue Night Sky`** | Deep Navy (`#080C16`) & Slate (`#10182A`) | **Electric Sky (`#12A8FF`) → Royal Indigo (`#4E68FF`)** |
| **`Violet Amethyst`** | Onyx Plum (`#0B0914`) & Velvet (`#161226`) | **Electric Violet (`#9852FF`) → Coral Rose (`#F44EA6`)** |
| **`Orange Sand`** | Warm Espresso (`#0E0B0A`) & Umber (`#1B1514`) | **Coral Pop (`#FF5E7A`) → Sunset Gold (`#FFB644`)** |
| **`Midnight Monokai`** | Monokai Abyss (`#090D0B`) & Charcoal (`#131A16`) | **Neon Lime (`#A4F23C`) → Cyber Mint (`#22E2A8`)** |
| **`Minimalist Monochrome`** | Obsidian (`#090B0F`) & Graphite (`#12151D`) | **Pure Platinum (`#FCFEFF`) → Chrome Ice (`#B2CEF6`)** |

Mengganti tema secara langsung kapan saja:
```lua
UI:SetTheme("Orange Sand")
```

---

## Dokumentasi API Lengkap

### 1. Konfigurasi `ImGui(config)`

| Parameter | Tipe | Default | Keterangan |
| :--- | :--- | :--- | :--- |
| `Title` | `string` | `"DRY CURSED  -  IMGUI"` | Judul utama pada TopBar dan Loader |
| `BrandTitle` | `string` | `"R&8_DV"` | Judul huruf besar `22px GothamBlack` di bawah logo sidebar kiri |
| `BrandSubtitle` | `string` | `"IMGUI SUITE"` | Sub-judul bergradasi aksen di bawah `BrandTitle` |
| `Theme` | `string` | `"Blue Night Sky"` | Nama tema awal dari 5 pilihan tema bergradasi |
| `CheckboxStyle` | `string` | `"Modern"` | Gaya toggle: `"Modern"` (pill switch) atau `"Checkbox"` (kotak centang) |
| `Text3D` | `boolean` | `true` | Mengaktifkan tipografi berwarna gradasi 2.5D / 3D |
| `LetterSpacing` | `number` | `1` | Spasi antar huruf untuk judul, header, section, dan kategori (`0` – `3`) |
| `Sides` | `number` | `3` | Jumlah panel kolom (`2` atau `3`) |
| `Scale` | `number` | `1` | Skala ukuran jendela (`0.5` – `1.5`) |
| `Transparency` | `number` | `0.04` | Transparansi panel (`0` – `0.65`) |
| `Rounded` | `boolean` | `true` | Sudut membulat pada jendela, kartu, dan kontrol |
| `ReduceEffects` | `boolean` | `false` | Mode instan tanpa animasi tween (0% beban transisi) |
| `ToggleKey` | `Enum.KeyCode` | `Enum.KeyCode.RightShift` | Tombol keyboard untuk menyembunyikan/menampilkan menu |
| `AutoLoading` | `boolean` | `false` | Default `false` agar menu langsung terbuka 0ms tanpa jeda |

### 2. Method Instance `UI`

- `UI.Call(sideCount)` — Mengubah tata letak menjadi `2` atau `3` panel.
- `UI:Category(label)` — Menambahkan label grup kategori bergradasi aksen pada sidebar kiri.
- `UI:GetThemes()` — Mengembalikan tabel daftar ke-5 nama tema.
- `UI:SetTheme(themeName)` — Mengganti tema, swatches, dan seluruh gradasi permukaan/teks secara *real-time*.
- `UI:SetText3D(state)` — Mengaktifkan/mematikan efek gradasi warna pada teks.
- `UI:SetLetterSpacing(amount)` — Mengatur kerenggangan huruf (`0` – `3`) secara *live*.
- `UI:SetCheckboxStyle(style)` — Mengubah seluruh toggle antara `"Modern"` dan `"Checkbox"`.
- `UI:SetScale(scale)` — Mengubah skala UI secara langsung (`0.5` – `1.5`).
- `UI:SetTransparency(alpha)` — Mengubah transparansi permukaan panel (`0` – `0.65`).
- `UI:SetRounded(state)` — Mengatur sudut membulat (`true` / `false`).
- `UI:SetValue(flag, value)` / `UI:GetValue(flag)` — Mengatur atau membaca nilai flag serta memperbarui visual kontrol terkait.
- `UI:OnValueChanged(flag, callback)` — Mendaftarkan listener perubahan nilai flag.
- `UI:MinimizeToIcon()` / `UI:RestoreFromIcon()` / `UI:ToggleMenu()` — Mengatur status minimize ke *Popup Icon Menu*.
- `UI:Destroy()` — Menghapus UI dan memutus seluruh koneksi input dengan bersih.

### 3. Komponen Canvas, Banner, Swatches & Card (`center` / `right`)

```lua
UI:Category("Modules")

UI.feature("Combat", "Combat")({
    center = function(c)
        -- Hero Header Bergradasi + Font Display 26px + Gradient Badge Pill
        c:Header("Combat", "Target assistance & smoothing policy", "Active")

        -- Poster Highlight Banner Bergradasi Penuh (Headline Besar & Tebal)
        c:HighlightBanner(
            "COMBAT ENGINE",
            "BIG PRECISION. ZERO FRAME DROP.",
            "Instant target acquisition with smooth 60 FPS rendering.",
            "LIVE"
        )

        -- Baris Kartu Statistik dengan Badge Icon Bergradasi
        c:StatRow({
            { Icon = "Shield", Label = "Status", Value = "Safe" },
            { Icon = "Bolt",   Label = "FPS",    Value = "60 FPS" }
        })

        -- Card Container dengan Badge Icon Bergradasi & Master Gradient Switch
        local Card = c:Card("Target Selection", nil, "Target", {
            Subtitle = "Choose which targets assistance follows",
            ToggleFlag = "MasterTarget",
            Default = true,
            Callback = function(on) print("Master:", on) end
        })

        -- Toggle Switch / Checkbox Bergradasi Penuh Saat Aktif
        Card:Toggle("Visible Targets", "VisTargets", true, function(val)
            print("Visible Targets:", val)
        end)

        -- Slider dengan Gradient Fill Bar + Value Pill Bergradasi
        Card:Slider("Smoothness", "SmoothVal", 0.1, 1.0, 0.5, "x", function(val)
            print("Smoothness:", val)
        end, 0.05)

        -- Dropdown, Keybind, Stepper, Input, dan Vibrant Gradient CTA Button
        Card:Dropdown("Target Priority", "PrioMode", {"Automatic", "Nearest"}, "Automatic")
        Card:Keybind("Activation Key", "AimKey", Enum.KeyCode.Q)
        Card:Stepper("Target Limit", "LimCount", 1, 1)
        Card:Input("Target Name", "TargetUser", "Username...", "")
        Card:Button("Execute Action", "RUN", "Bolt", function() end)

        -- Interactive Feature Hover Card
        c:FeatureCard({
            Icon = "Bot",
            Title = "Autofarm",
            Description = "Automatically farming without effort touching the screen.",
            Flag = "AutoFarmCard",
            Default = true
        })
    end,

    right = function(r)
        r:Section("Palette & Matrix", "Palette")
        -- 5 Circular Colour Palette Swatches dengan Selection Ring + Checkmark
        r:ThemeSwatches("Colour Palette")
        -- Grid Pemilihan Tile Interaktif (5x5 dengan posisi Player di tengah)
        r:TileGrid("Select tile to break (P = Player)", "TileMatrix", 5, 5)
    end
})
```

---

## Struktur File

- [`r&8_dv.lua`](r&8_dv.lua) — Core engine **R&8_DV ImGui v5.2** (Full Colourful Dual-Hue Gradients, Heavy Display Typography, `HighlightBanner`, `ThemeSwatches`, Single-Border Popup Icon, 60 FPS Smooth).
- [`Sample Gui/SampleGui.lua`](Sample%20Gui/SampleGui.lua) — Contoh implementasi lengkap dengan `HighlightBanner`, `ThemeSwatches`, 5 Tema Warna, Combat, Auto Farm + Tile Matrix, Visuals, dan Player.
- [`Assets/icons.png`](Assets/icons.png) — Master emblem resmi R&8_DV yang ditarik otomatis via GitHub RAW.
- [`Assets/Jersey25-Regular.ttf`](Assets/Jersey25-Regular.ttf) — Aset font repositori.
