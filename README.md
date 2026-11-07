# R&8_DV ImGui Framework (v5.0 — Minimalist Monochrome & 2.5D/3D Colourful Typography)

Framework **R&8_DV ImGui v5.0** adalah arsitektur UI Roblox berbasis Luau dengan pendekatan **Minimalist Monochrome Surface** (tanpa animasi berlebih / **0% FPS Drop**), **2.5D & 3D Colourful Gradient Typography** dengan proporsi font **Bold** yang tegas dan mudah dibaca, **Card & Feature Card Hover Micro-Interactions**, serta **5 Tema Warna** yang disesuaikan langsung dengan nama temanya.

---

## Ringkasan Perbaikan Bug & Fitur Baru (v5.0)

1. **Penghapusan Duplicate Border Color pada Popup Icon Menu & Seluruh Elemen**:
   - Menghapus `MinInnerBezel` dan `MinInnerStroke` pada *Floating Popup Icon* (`R8DV_FloatingSquircle`), sehingga ikon popup kini hanya memiliki **1 border bersih (`UIStroke`)** yang menyala halus saat *hover*.
   - Menghapus double `UIStroke` pada `MainWindow` vs `BannerLayer`, `Slider Fill`, `Loader BarFill`, serta opsi `Dropdown` ketika tertutup.
2. **2.5D & 3D Colourful Gradient Font (Tetap Sangat Ringan — Zero FPS Drop)**:
   - Setiap judul, header kartu, nilai statistik, tab aktif, dan label kontrol menu menggunakan kombinasi **1 `TextLabel` + 1 `UIGradient` statis 3-titik warna + 1 `UIStroke` bayangan kedalaman (`TextShadow`)** tanpa menduplikasi layer teks dan tanpa *loop* `RenderStepped`/`Heartbeat`.
   - Proporsi ukuran dan ketebalan font ditingkatkan ke **`GothamBlack` / `GothamBold`** agar hierarki menu terlihat tegas seperti menu ImGui modern.
3. **5 Tema Warna Sesuai Nama Tema (Berbasis Minimalist Monochrome Surface)**:
   - Permukaan kartu tetap gelap minimalis dan nyaman di mata, sementara aksen kontrol dan gradasi font 2.5D/3D berubah penuh warna sesuai nama tema:
     1. **`Minimalist Monochrome`** — Obsidian & Graphite dengan gradasi font *Platinum Chrome / Titanium Ice* serta switch putih kontras tinggi.
     2. **`Blue Night Sky`** — Midnight Abyss dengan gradasi font *Starlight Ice → Sky Cyan → Deep Sapphire*.
     3. **`Violet Amethyst`** — Deep Onyx Plum dengan gradasi font *Pearl Rose → Lavender Neon → Royal Amethyst*.
     4. **`Orange Sand`** — Matte Basalt Espresso dengan gradasi font *Sunlit Ivory → Golden Sand → Sunset Amber*.
     5. **`Midnight Monokai`** — Monokai Charcoal dengan gradasi font *Crisp Mint → Monokai Lime → Cyber Emerald*.
4. **Event-Driven Micro-Interactions & Card Hover**:
   - Seluruh animasi bersifat *event-driven* (`0.12s–0.18s` `Quart Out`, **0% CPU saat diam**), mencakup *Card Hover* (elevasi warna kartu & border), *FeatureCard Hover & Active Highlight*, *Slider Circular Thumb Scale*, *Dropdown Chevron Rotation*, *Sidebar Vertical Pill Indicator*, dan *Button Tactile Press*.
   - Mendukung mode **`FPS Boost` / `Reduce Effects`** yang otomatis mematikan tween transisi untuk perangkat spesifikasi rendah.
5. **Perbaikan Bug Fungsional pada Engine**:
   - **Perbaikan `UI Scale` Live**: Baik `UI:SetScale(scale)` maupun `UI.UIScale = scale` kini langsung memperbarui skala jendela secara *real-time*.
   - **Perbaikan Sinkronisasi Warna `Toggle`, `ActionGrid`, & Tab saat Ganti Tema**: Status aktif (`ON`/`OFF`) tidak lagi ter-reset warnanya saat `UI:SetTheme(...)` dipanggil.
   - **Perbaikan Tumpukan `RightPanel`**: Memperbaiki bug di mana halaman panel kanan saling bertumpuk saat berpindah antar tab.
   - **Perbaikan `Dropdown` Interaktif & `Slider` Presisi**: `Dropdown` kini membuka daftar pilihan yang bisa diklik langsung (bukan sekadar *cycle* buta), dan `Slider` mendukung angka desimal (`step`) serta memiliki *circular thumb knob* tanpa risiko *division-by-zero*.
   - **Pembersihan Koneksi Otomatis (`UI:Destroy()`)**: Mencegah kebocoran memori (*memory leak*) pada `UserInputService` saat script dijalankan ulang.

---

## Cara Penggunaan (Via GitHub RAW)

> **Catatan:** Link GitHub RAW dipertahankan sepenuhnya untuk pemanggilan aset & script langsung dari repositori GitHub.

```lua
-- 1. Panggil Framework R&8_DV (Jangan ubah link GitHub RAW Anda)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/R8_DV_ImGui.lua"))()
-- (Atau gunakan .../r%268_dv.lua sesuai nama file pada branch main GitHub Anda)

-- 2. Inisialisasi Jendela Utama (3 Panel atau 2 Panel)
local UI = ImGui({
    Title = "DRY CURSED  -  IMGUI",
    Theme = "Minimalist Monochrome", -- Pilihan 5 tema tersedia di bawah
    CheckboxStyle = "Modern",        -- "Modern" | "Checkbox"
    Text3D = true,                   -- Teks berwarna 2.5D / 3D ringan
    AutoLoading = true
}).Call(3)
```

---

## Daftar 5 Tema Warna

| Nama Tema | Surface Dasar | Karakteristik Aksen & Gradasi Font 2.5D / 3D |
| :--- | :--- | :--- |
| **`Minimalist Monochrome`** | Obsidian (`#0A0B0E`) & Graphite (`#13151B`) | Putih Platinum → Silver Chrome → Titanium Slate |
| **`Blue Night Sky`** | Midnight Abyss (`#090C14`) & Slate (`#121826`) | Putih Es → Sian Langit (`#70CAFF`) → Biru Safir (`#3476FF`) |
| **`Violet Amethyst`** | Onyx Plum (`#0B0A12`) & Velvet (`#161323`) | Putih Mutiara → Lavender Neon (`#C494FF`) → Ungu Amethyst (`#7C52FF`) |
| **`Orange Sand`** | Basalt Espresso (`#0E0C0A`) & Warm Slate (`#1B1713`) | Gading Hangat → Emas Pasir (`#FFC666`) → Oranye Senja (`#EE7C2A`) |
| **`Midnight Monokai`** | Monokai Obsidian (`#0C0D0B`) & Charcoal (`#171A16`) | Putih Mint → Hijau Monokai (`#B6F244`) → Zamrud Siber (`#2ED688`) |

Mengganti tema secara langsung kapan saja:
```lua
UI:SetTheme("Violet Amethyst")
```

---

## Dokumentasi API Lengkap

### 1. Konfigurasi `ImGui(config)`

| Parameter | Tipe | Default | Keterangan |
| :--- | :--- | :--- | :--- |
| `Title` | `string` | `"DRY CURSED  -  IMGUI"` | Judul utama pada TopBar dan Loader |
| `Theme` | `string` | `"Blue Night Sky"` | Nama tema awal dari 5 pilihan tema |
| `CheckboxStyle` | `string` | `"Modern"` | Gaya toggle: `"Modern"` (pill switch) atau `"Checkbox"` (kotak centang) |
| `Text3D` | `boolean` | `true` | Mengaktifkan tipografi berwarna gradasi 2.5D / 3D |
| `Sides` | `number` | `3` | Jumlah panel kolom (`2` atau `3`) |
| `Scale` | `number` | `1` | Skala ukuran jendela (`0.5` – `1.5`) |
| `Transparency` | `number` | `0.04` | Transparansi panel (`0` – `0.65`) |
| `Rounded` | `boolean` | `true` | Sudut membulat pada jendela, kartu, dan kontrol |
| `ReduceEffects` | `boolean` | `false` | Mode instan tanpa animasi tween (0% beban transisi) |
| `ToggleKey` | `Enum.KeyCode` | `Enum.KeyCode.RightShift` | Tombol keyboard untuk menyembunyikan/menampilkan menu |
| `AutoLoading` | `boolean` | `true` | Menjalankan layar preloader singkat saat inisialisasi |

### 2. Method Instance `UI`

- `UI.Call(sideCount)` — Mengubah tata letak menjadi `2` atau `3` panel.
- `UI:Category(label)` — Menambahkan label grup kategori pada sidebar kiri.
- `UI:GetThemes()` — Mengembalikan tabel daftar ke-5 nama tema.
- `UI:SetTheme(themeName)` — Mengganti tema dan seluruh gradasi font secara *real-time*.
- `UI:SetText3D(state)` — Mengaktifkan/mematikan efek gradasi 2.5D/3D pada teks.
- `UI:SetCheckboxStyle(style)` — Mengubah seluruh toggle antara `"Modern"` dan `"Checkbox"`.
- `UI:SetScale(scale)` — Mengubah skala UI secara langsung (`0.5` – `1.5`).
- `UI:SetTransparency(alpha)` — Mengubah transparansi permukaan panel (`0` – `0.65`).
- `UI:SetRounded(state)` — Mengatur sudut membulat (`true` / `false`).
- `UI:SetValue(flag, value)` / `UI:GetValue(flag)` — Mengatur atau membaca nilai flag serta memperbarui visual kontrol terkait.
- `UI:OnValueChanged(flag, callback)` — Mendaftarkan listener perubahan nilai flag.
- `UI:MinimizeToIcon()` / `UI:RestoreFromIcon()` / `UI:ToggleMenu()` — Mengatur status minimize ke *Popup Icon Menu*.
- `UI:Destroy()` — Menghapus UI dan memutus seluruh koneksi input dengan bersih.

### 3. Komponen Canvas & Card (`center` / `right`)

```lua
UI:Category("Modules")

UI.feature("Combat", "Combat")({
    center = function(c)
        -- Header Halaman (Font Bold Display 3D + Status Pill)
        c:Header("Combat", "Deskripsi singkat halaman", "Active")

        -- Baris Kartu Statistik (Dengan Card Hover Micro-Interaction)
        c:StatRow({
            { Icon = "Shield", Label = "Status", Value = "Safe" },
            { Icon = "Bolt",   Label = "FPS",    Value = "Stable" }
        })

        -- Card Container dengan Subtitle & Master Switch di Header Card
        local Card = c:Card("Target Selection", nil, "Target", {
            Subtitle = "Choose which targets assistance follows",
            ToggleFlag = "MasterTarget",
            Default = true,
            Callback = function(on) print("Master:", on) end
        })

        -- Toggle Switch / Checkbox (Otomatis mengikuti CheckboxStyle atau override argumen ke-5)
        Card:Toggle("Visible Targets", "VisTargets", true, function(val)
            print("Visible Targets:", val)
        end)

        -- Slider dengan Circular Thumb & Dukungan Step Desimal
        Card:Slider("Smoothness", "SmoothVal", 0.1, 1.0, 0.5, "x", function(val)
            print("Smoothness:", val)
        end, 0.05)

        -- Dropdown Expandable Interaktif
        Card:Dropdown("Target Priority", "PrioMode", {"Automatic", "Nearest"}, "Automatic", function(opt)
            print("Priority:", opt)
        end)

        -- Keybind Picker Interaktif (Tekan Esc/Backspace untuk mengosongkan ke None)
        Card:Keybind("Activation Key", "AimKey", Enum.KeyCode.Q, function(keyCode)
            print("Bound key:", keyCode)
        end)

        -- Stepper (- / +), Input TextBox, dan Action Button
        Card:Stepper("Target Limit", "LimCount", 1, 1)
        Card:Input("Target Name", "TargetUser", "Username...", "")
        Card:Button("Execute Action", "RUN", "Bolt", function() end)

        -- Interactive Feature Hover Card (Gaya Automation Card dengan Hover & Active Highlight)
        c:FeatureCard({
            Icon = "Bot",
            Title = "Autofarm",
            Description = "Automatically farming without effort touching the screen.",
            Flag = "AutoFarmCard",
            Default = true,
            Callback = function(active) print("Autofarm:", active) end
        })
    end,

    right = function(r)
        r:Section("Matrix Selector", "Grid")
        -- Grid Pemilihan Tile Interaktif (5x5 dengan posisi Player di tengah)
        r:TileGrid("Select tile to break (P = Player)", "TileMatrix", 5, 5, function(index, state)
            print("Tile", index, state)
        end)
    end
})
```

---

## Struktur File

- [`r&8_dv.lua`](r&8_dv.lua) — Core engine **R&8_DV ImGui v5.0** (Minimalist Monochrome, 2.5D/3D Colourful Font, Card Hover, Single-Border Popup Icon).
- [`Sample Gui/SampleGui.lua`](Sample%20Gui/SampleGui.lua) — Contoh implementasi lengkap (Home, Combat, Auto Farm + Tile Matrix, Visuals, Player, dan Pengaturan 5 Tema).
- [`Assets/icons.png`](Assets/icons.png) — Master emblem resmi R&8_DV yang ditarik otomatis via GitHub RAW.
- [`Assets/Jersey25-Regular.ttf`](Assets/Jersey25-Regular.ttf) — Aset font repositori.
