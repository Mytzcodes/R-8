# R&8_DV ImGui Framework (v5.4 — Large Effortless Canvas Typography, High-Contrast Solid UI & Spacious Cards)

Framework **R&8_DV ImGui v5.4** adalah arsitektur UI Roblox berbasis Luau dengan **Ukuran Huruf Canvas Besar & Mudah Dibaca Tanpa Mendekat ke Layar**, **100% Teks Solid Kontras Tinggi (Tanpa 2.5D / 3D Gradient Teks)**, **Checklist / Switch Bebas Bug dengan Animasi Halus Natural (`Quad Out`)**, **Layout Dropdown & Input 2-Baris Lebar Penuh Anti-Terpotong**, struktur **Card Lengkap**, serta **60 FPS Stabil**.

---

## Ringkasan Perbaikan & Pembaruan (v5.4)

1. **Ukuran Huruf Canvas Layout Diperbesar Secara Signifikan & Skala Layar Optimal**:
   - **Skala Jendela Responsif (`ComputeTargetScale`)**: Rasio fit layar Mobile & PC ditingkatkan hingga **`92% x 90%`** pada basis kanvas **`1040 x 520`**, menaikkan skala efektif di layar HP sekitar **`+20%`** secara otomatis tanpa terpotong di tepi layar.
   - **Tipografi Canvas Besar & Jelas**:
     - Judul `Header`: **`26px`** (`GothamBlack`) + Subjudul **`15px`** + Badge **`13px`**.
     - Judul `Card`: **`20px`** (`GothamBlack`) + Subjudul **`15px`** (`TextWrapped` otomatis).
     - Judul `FeatureCard`: **`19px`** (`GothamBlack`) + Deskripsi **`15px`** + Status Pill **`13px`**.
     - Nilai `StatRow`: **`20px`** (`GothamBlack`, lebar penuh 2-tingkat) + Label **`13px`**.
     - Seluruh Kontrol (`Toggle`, `Slider`, `Stepper`, `Dropdown`, `Input`, `Keybind`, `Button`) & Tab Sidebar: **`17px`**!
     - Nilai `Slider` Badge, Opsi & Pilihan `Dropdown`, `InputBox`, `Keybind`, `ActionGrid`, dan `ActivityTimeline`: **`15px`**.
   - **Layout 2-Baris Lebar Penuh untuk `Dropdown` & `Input` (`78px`)**: Label `17px` berada di baris atas dan kotak pilihan/input `15px` memakai **100% lebar penuh di baris bawah**, sehingga teks panjang seperti `"Minimalist Monochrome"` atau `"Closest to Crosshair"` terbaca utuh tanpa terpotong (`...`) di Panel Kanan maupun Tengah.
2. **100% Teks Solid Kontras Tinggi (`Zero Text UIGradient`)**:
   - Seluruh `UIGradient` pada teks dihapus permanen dan dijaga oleh `GetOnFillColor` + `GetReadableTextColor` agar teks selalu tajam baik di atas aksen terang maupun gelap.
3. **Checklist (`Checkbox` `28x28` & `Modern` `50x26`) Bebas Bug & Animasi Smooth (`0.14s Quad Out`)**:
   - Ikon centang `-45° Connected L-Bar` menyatu presisi pada skala layar berapapun.
4. **Popup Icon Single-Border & Link GitHub RAW Tetap Utuh**:
   - Popup Icon Menu (`R8DV_FloatingSquircle`) tetap memakai **1 border tunggal**, dan seluruh URL **GitHub RAW** dipertahankan 100% tanpa perubahan.

---

## Cara Penggunaan (Via GitHub RAW)

> **Penting:** Pastikan file `r&8_dv.lua` terbaru sudah di-*push* ke repositori GitHub `Mytzcodes/R-8` (branch `main`). Nama file `r&8_dv.lua` menggunakan URL-encode `%26` (`r%268_dv.lua`) agar bebas dari **HTTP 404**.

```lua
-- 1. Panggil Framework R&8_DV langsung via GitHub RAW
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"))()

-- 2. Inisialisasi Jendela Utama (3 Panel atau 2 Panel)
local UI = ImGui({
    Title = "DRY CURSED - IMGUI",
    BrandTitle = "R&8_DV",            -- Judul utama solid di bawah logo sidebar
    BrandSubtitle = "IMGUI SUITE",    -- Sub-judul di bawah logo sidebar
    Theme = "Minimalist Monochrome",  -- Pilihan 5 tema tersedia di bawah
    CheckboxStyle = "Modern",         -- "Modern" (Switch) | "Checkbox" (Checklist)
    LetterSpacing = 1,                -- Spasi antar huruf judul & header (0 - 3)
    AutoLoading = false               -- Buka instan 0ms tanpa delay!
}).Call(3)
```

---

## Daftar 5 Tema Warna (Kontras Teks Otomatis)

| Nama Tema | Surface Dasar | Warna Aksen (`Accent`) | Kontras Teks di Atas Aksen |
| :--- | :--- | :--- | :--- |
| **`Minimalist Monochrome`** | Obsidian (`#0A0B0F`) & Slate (`#151820`) | Platinum (`#F2F6FC`) | **Gelap Pekat (`#0C0E14`)** |
| **`Blue Night Sky`** | Midnight (`#080C14`) & Navy (`#121A2C`) | Electric Sapphire (`#2480FF`) | **Putih Tajam (`#FFFFFF`)** |
| **`Violet Amethyst`** | Onyx Plum (`#0B0913`) & Velvet (`#181428`) | Royal Amethyst (`#7E4AFC`) | **Putih Tajam (`#FFFFFF`)** |
| **`Orange Sand`** | Espresso (`#0E0B09`) & Warm Umber (`#1D1713`) | Amber Sand (`#F69C34`) | **Gelap Pekat (`#100C08`)** |
| **`Midnight Monokai`** | Monokai Dark (`#0A0D0B`) & Charcoal (`#151C18`) | Monokai Lime (`#A2EC36`) | **Gelap Pekat (`#0A0F0B`)** |

---

## Dokumentasi API Lengkap

### 1. Method Instance `UI`

- `UI.Call(sideCount)` — Mengubah tata letak menjadi `2` atau `3` panel.
- `UI:Category(label)` — Menambahkan label grup kategori pada sidebar kiri.
- `UI:GetThemes()` — Mengembalikan daftar ke-5 nama tema.
- `UI:SetTheme(themeName)` — Mengganti tema dan menyesuaikan kontras teks/ikon secara *real-time*.
- `UI:SetCheckboxStyle(style)` — Mengubah seluruh switch antara `"Modern"` dan `"Checkbox"`.
- `UI:SetLetterSpacing(amount)` — Mengatur kerenggangan huruf judul (`0` – `3`).
- `UI:SetScale(scale)` — Mengubah skala UI (`0.5` – `1.5`).
- `UI:SetTransparency(alpha)` — Mengubah transparansi panel (`0` – `0.65`).
- `UI:SetRounded(state)` — Mengatur sudut membulat (`true` / `false`).
- `UI:SetValue(flag, value)` / `UI:GetValue(flag)` — Mengatur atau membaca nilai flag.
- `UI:OnValueChanged(flag, callback)` — Mendaftarkan listener perubahan nilai flag.
- `UI:MinimizeToIcon()` / `UI:RestoreFromIcon()` / `UI:ToggleMenu()` — Mengatur status minimize ke *Popup Icon Menu*.
- `UI:Destroy()` — Menghapus UI dan memutus semua koneksi input.

### 2. Komponen Card & Kontrol (`center` / `right`)

```lua
UI:Category("Modules")

UI.feature("Combat", "Combat")({
    center = function(c)
        c:Header("Combat", "Target assistance & smoothing policy", "Active")

        local Card = c:Card("Target Selection", nil, "Target", {
            Subtitle = "Choose which targets assistance follows",
            ToggleFlag = "MasterTarget",
            Default = true
        })

        Card:Toggle("Visible Targets", "VisTargets", true)
        Card:Slider("Smoothness", "SmoothVal", 0.1, 1.0, 0.5, "x", nil, 0.05)
        Card:Dropdown("Priority", "PrioMode", {"Automatic", "Nearest"}, "Automatic")
        Card:Keybind("Activation Key", "AimKey", Enum.KeyCode.Q)
        Card:Stepper("Target Limit", "LimCount", 1, 1)
        Card:Input("Target Name", "TargetUser", "Username...", "")
        Card:Button("Execute Action", "RUN", "Bolt", function() end)
    end,

    right = function(r)
        local StyleCard = r:Card("Theme & Matrix", nil, "Palette", {
            Subtitle = "Quick palette selector & tile matrix"
        })
        StyleCard:ThemeSwatches("Colour Palette")
        StyleCard:TileGrid("Select tile to break (P = Player)", "TileMatrix", 5, 5)
    end
})
```

---

## Struktur File

- [`r&8_dv.lua`](r&8_dv.lua) — Core engine **R&8_DV ImGui v5.4** (Large Effortless Canvas Text, 100% Solid High-Contrast Typography, Bug-Free Checklist, Single-Border Popup Icon, 60 FPS Smooth).
- [`Sample Gui/SampleGui.lua`](Sample%20Gui/SampleGui.lua) — Implementasi contoh lengkap dengan Card terstruktur di semua panel & tab.
- [`Assets/icons.png`](Assets/icons.png) — Master emblem resmi R&8_DV via GitHub RAW.
- [`Assets/Jersey25-Regular.ttf`](Assets/Jersey25-Regular.ttf) — Aset font repositori.
