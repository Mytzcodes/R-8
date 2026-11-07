-- 1. Panggil Framework R&8_DV v6.3 (Jangan ubah link karena di-load via GitHub RAW)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"))()

-- 2. Inisialisasi Standar (Font Besar & Tajam, 5 Tema Colourful, Illustrated Loader & Layout 3 Sisi)
local UI = ImGui({
    Title = "DRY CURSED  -  IMGUI",
    Theme = "Blue Night Sky",     -- Pilihan 5 Tema: "Blue Night Sky" | "Orange Sand" | "Midnight Monokai" | "Sakura Cyber Neon" | "Emerald Aurora"
    CheckboxStyle = "Modern",     -- Pilihan default: "Modern" | "Classic" | "Biasa"
    LetterSpacing = 0,
    AutoLoading = true            -- Aktifkan Illustrated Animated Loader yang nyaman
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

-- =========================================================================
-- FEATURE 1: HOME (Tengah + Illustrated Canvas + Panel Pengaturan Kanan)
-- =========================================================================
feature("Home", "Home")({
    center = center(function(c)
        c:Header("Home", "Welcome back, keep going!", "v6.3 Ready")

        -- Canvas Ilustrasi Animasi yang ringan & nyaman dilihat
        c:IllustratedCanvas({
            Tag = "ILLUSTRATED UI",
            Title = "Colourful Minimalist Engine",
            Subtitle = "5 Dynamic Themes • Large Readable Font • Clean Active Buttons",
            Height = 114
        })

        c:StatRow({
            { Icon = "Bolt",   Label = "Status",  Value = "Safe" },
            { Icon = "Clock",  Label = "Runtime", Value = "00:12:34" },
            { Icon = "Shield", Label = "Version", Value = "v6.3.0" }
        })

        local QuickCard = c:Card("Quick Actions", "View All", "Bolt")
        QuickCard:ActionGrid({
            { Icon = "AutoFarm",  Name = "Auto Farm",     Flag = "QuickAutoFarm" },
            { Icon = "Teleports", Name = "Teleport",      Flag = "QuickTP" },
            { Icon = "Visuals",   Name = "ESP",           Flag = "QuickESP" },
            { Icon = "Speed",     Name = "Speed Hack",    Flag = "QuickSpeed" },
            { Icon = "Jump",      Name = "Infinite Jump", Flag = "QuickInfJump" },
            { Icon = "Collect",   Name = "Collect All",   Flag = "QuickCollect" }
        })

        local ActivityCard = c:Card("Recent Activity", "View Logs", "Clock")
        ActivityCard:ActivityTimeline({
            { Text = "Large Jersey25 Font & Clean UI Loaded", Time = "Just now" },
            { Text = "5 Colourful Themes Initialized",        Time = "1m ago" },
            { Text = "Auto Farm Activated",                   Time = "2m ago" },
            { Text = "Teleported to Spawn",                   Time = "5m ago" }
        })
    end),

    right = right(function(r)
        r:Section("Settings", "Settings")

        r:Section("Theme & Colourful Palette")
        r:Dropdown("Color Theme", "ThemeSelect", {
            "Blue Night Sky",
            "Orange Sand",
            "Midnight Monokai",
            "Sakura Cyber Neon",
            "Emerald Aurora"
        }, "Blue Night Sky", function(selectedTheme)
            UI:SetTheme(selectedTheme)
        end)

        r:Section("General")
        r:Slider("UI Scale", "UIScalePct", 65, 130, 100, "%", function(val)
            UI:SetScale(val / 100)
        end)
        r:Slider("Transparency", "BgTransPct", 0, 60, 4, "%", function(val)
            UI:SetTransparency(val / 100)
        end)
        -- Mengubah bentuk seluruh Checkbox secara real-time ("Modern", "Classic", "Biasa")
        r:Dropdown("Checkbox Style", "ChkStyle", {
            "Modern",
            "Classic",
            "Biasa"
        }, "Modern", function(selectedStyle)
            UI:SetCheckboxStyle(selectedStyle)
        end)
        r:Toggle("Lock Position", "LockPosition", false)
        r:Toggle("Rounded Borders", "RoundedState", true, function(state)
            UI:SetRounded(state)
        end)

        r:Section("Performance")
        r:Toggle("FPS Boost", "FPSBoost", false)
        r:Toggle("Reduce Effects", "ReduceEffects", false)

        r:Section("Other")
        r:Toggle("Notifications", "NotifyToggle", true)
        r:Stepper("Target Priority", "PriorityLevel", 1, 1)
    end)
})

-- =========================================================================
-- FEATURE 2: AUTO FARM (Mendemonstrasikan 3 Bentuk Checkbox Sekaligus)
-- =========================================================================
feature("AutoFarm", "Auto Farm")({
    center = center(function(c)
        c:Header("Auto Farm", "Compare all 3 checkbox designs & farming controls", "Active")

        local StyleCard = c:Card("3 Checkbox Variations Demo", "Interactive", "AutoFarm")
        StyleCard:Toggle("Modern Switch Style", "DemoModern", true, nil, "Modern")
        StyleCard:Toggle("Classic Checkmark Box", "DemoClassic", true, nil, "Classic")
        StyleCard:Toggle("Desain Biasa (ON / OFF)", "DemoBiasa", false, nil, "Biasa")

        local ConfigCard = c:Card("Farming Parameters", "Presets", "Sliders")
        ConfigCard:Dropdown("Farm Mode", "FarmModeSelect", {
            "Nearest Mob",
            "Boss Only",
            "Quest Target",
            "Resource Node"
        }, "Nearest Mob")
        ConfigCard:Slider("Attack Distance", "FarmDist", 5, 50, 20, " studs")
        ConfigCard:Stepper("Loop Priority", "LoopPrio", 2, 1)
    end)
})

-- =========================================================================
-- FEATURE LAINNYA
-- =========================================================================
feature("Teleports", "Teleports")({
    center = center(function(c)
        c:Header("Teleports", "Instant coordinate & player warping", "Ready")
        local Card = c:Card("Destination", nil, "Teleports")
        Card:Input("Target Player", "TpTarget", "Username...", "")
        Card:Dropdown("Zone Select", "TpZone", {
            "Spawn Island",
            "Crystal Cavern",
            "Volcano Fortress",
            "Sky Sanctuary"
        }, "Spawn Island")
    end)
})

feature("Player", "Player")({
    center = center(function(c)
        c:Header("Player", "Character movement overrides", "LocalPlayer")
        local Card = c:Card("Movement", nil, "Player")
        Card:Slider("WalkSpeed", "WalkSpeedVal", 16, 200, 16, "")
        Card:Slider("JumpPower", "JumpPowerVal", 50, 300, 50, "")
        Card:Toggle("Infinite Jump", "InfJumpToggle", false)
    end)
})

feature("Visuals", "Visuals")({
    center = center(function(c)
        c:Header("Visuals", "ESP and camera field of view", "Render")
        local Card = c:Card("Visual Settings", nil, "Visuals")
        Card:Toggle("Player Box ESP", "BoxESP", false)
        Card:Toggle("Tracer Lines", "TracerESP", false)
        Card:Slider("Field of View", "CameraFOV", 70, 120, 70, " deg")
    end)
})

feature("Misc", "Misc")({
    center = center(function(c)
        c:Header("Misc", "Additional utility tools", "Utils")
        local Card = c:Card("Server Utilities", nil, "Misc")
        Card:Toggle("Anti-AFK", "AntiAFK", true)
        Card:Toggle("Auto Rejoin on Kick", "AutoRejoin", false)
    end)
})

feature("Sliders", "Settings")({
    center = center(function(c)
        c:Header("Settings", "Framework configuration & theme preview", "v6.3")
        c:IllustratedCanvas({
            Tag = "THEME ENGINE",
            Title = "5 Custom Colourful Palettes",
            Subtitle = "Blue Night Sky • Orange Sand • Midnight Monokai • Sakura Cyber Neon • Emerald Aurora",
            Height = 110
        })
    end)
})
