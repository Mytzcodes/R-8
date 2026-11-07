# R&8_DV ImGui Framework (v5.3 — Solid High-Contrast Text, Spacious Controls & Bug-Free Checklist)

Framework **R&8_DV ImGui v5.3** adalah arsitektur UI Roblox berbasis Luau dengan **100% Teks Solid Kontras Tinggi (Tanpa 2.5D / 3D Gradient Teks)** sehingga huruf tidak pernah rusak atau hilang di semua perangkat PC & Mobile, **Checklist / Switch Bebas Bug dengan Animasi Halus Natural (`Quad Out`)**, **Ukuran Tombol Besar & Tidak Kedekatan**, struktur **Card Lengkap**, serta **60 FPS Stabil**.

---

## Ringkasan Perbaikan & Pembaruan (v5.3)

1. **Penghapusan Total Efek Teks 2.5D / 3D (`Zero Text UIGradient`) & Kontras Otomatis**:
   - Seluruh `UIGradient` pada `TextLabel` / `TextButton` telah **dihapus 100%** karena membuat teks pecah/hilang di shader GPU Mobile.
   - Menggunakan sistem penjaga kontras otomatis (`GetOnFillColor` & `GetReadableTextColor`): di atas tombol/tab/badge berwarna terang (`Minimalist Monochrome`, `Orange Sand`, `Midnight Monokai`), teks & tanda centang **otomatis menggunakan warna gelap pekat (`#0C0E14`)**; sedangkan di atas permukaan gelap atau aksen biru/ungu tua (`Blue Night Sky`, `Violet Amethyst`), teks **otomatis menggunakan warna putih tajam (`#FFFFFF`)**.
2. **Perbaikan Bug Checklist (`Checkbox` & `Modern` Switch) & Animasi Smooth Natural**:
   - Ikon centang `Check` dibangun ulang dengan struktur sudut menyatu (`-45° Connected L-Bar`) sehingga tidak pernah terpisah atau melenceng di skala layar berapapun.
   - Menghilangkan *motion* aneh (tanpa loncatan ketebalan font, tanpa efek membal/mengecil ekstrem ke `0`) dan menggantinya dengan transisi halus natural **`0.14s Quad Out`**.
   - Switch pada header `Card` maupun baris `Toggle` kini tersinkronisasi penuh dengan pilihan `"Modern"` maupun `"Checkbox"`.
3. **Perbaikan Tombol Kecil, Tombol Mepet, Tombol Kedekatan & Penambahan Card**:
   - **TopBar (`54px`)**: Tombol `Menu`, `Minimize`, `Maximize`, dan `Close` diperbesar menjadi **`36 x 36 px`** dengan jarak antar tombol **`10px`** dan margin kanan **`16px`**.
   - **Kontrol di Dalam Card**: Setiap `Toggle`, `Slider`, `Dropdown`, `Stepper`, `Input`, dan `Keybind` memiliki tinggi baris **`42px – 58px`** dengan *padding* dalam **`14px`**, jarak antar kontrol **`12px`**, serta opsi `Dropdown` setinggi **`34px`** berjarak **`6px`**.
   - **Card Lengkap**: Seluruh pengaturan pada panel kanan maupun setiap tab (`Home`, `Combat`, `Auto Farm`, `Visuals`, `Player`, `Misc`) kini terbungkus rapi di dalam **Card** dengan *padding* `20px` tanpa desain poster/ilustrasi aneh.
4. **Popup Icon Single-Border & Link GitHub RAW Tetap Utuh**:
   - Popup Icon Menu (`R8DV_FloatingSquircle`) tetap memakai **1 border tunggal**, dan seluruh URL **GitHub RAW** dipertahankan tanpa perubahan.

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

- [`r&8_dv.lua`](r&8_dv.lua) — Core engine **R&8_DV ImGui v5.3** (100% Solid High-Contrast Text, Bug-Free Checklist, Spacious Controls, Single-Border Popup Icon, 60 FPS Smooth).
- [`Sample Gui/SampleGui.lua`](Sample%20Gui/SampleGui.lua) — Implementasi contoh lengkap dengan Card terstruktur di semua panel & tab.
- [`Assets/icons.png`](Assets/icons.png) — Master emblem resmi R&8_DV via GitHub RAW.
- [`Assets/Jersey25-Regular.ttf`](Assets/Jersey25-Regular.ttf) — Aset font repositori.
