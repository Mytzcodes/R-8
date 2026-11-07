-- 1. Panggil Framework R&8_DV v5.0 (Ganti dengan link RAW Anda jika di-host di GitHub)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"))()

-- 2. Inisialisasi Standar (Scale, Font Jersey25, 2.5D Text, & Layout 3 Sisi langsung aktif!)
local UI = ImGui({
    Title = "DRY CURSED  -  IMGUI",
    Theme = "Blue Night Sky",
    CheckboxStyle = "Modern", -- Pilihan default: "Modern" | "Classic" | "Biasa"
    LetterSpacing = 0
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

-- =========================================================================
-- FEATURE 1: HOME (Tengah + Panel Pengaturan Kanan)
-- =========================================================================
feature("Home", "Home")({
    center = center(function(c)
        c:Header("Home", "Welcome back, keep going!", "Game Ready")

        c:StatRow({
            { Icon = "Bolt",   Label = "Status",  Value = "Safe" },
            { Icon = "Clock",  Label = "Runtime", Value = "00:12:34" },
            { Icon = "Shield", Label = "Version", Value = "v5.0.0" }
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
            { Text = "Jersey25 Font & 2.5D Text Loaded", Time = "Just now" },
            { Text = "Auto Farm Activated",              Time = "2m ago" },
            { Text = "Teleported to Spawn",              Time = "5m ago" },
            { Text = "ESP Enabled",                      Time = "8m ago" }
        })
    end),

    right = right(function(r)
        r:Section("Settings", "Settings")

        r:Section("General")
        r:Slider("UI Scale", "UIScalePct", 65, 130, 100, "%", function(val)
            UI.UIScale = val / 100
        end)
        r:Slider("Transparency", "BgTransPct", 0, 60, 5, "%", function(val)
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

        r:Section("Theme & 2.5D Palette")
        r:Dropdown("Color Style", "ThemeSelect", {
            "Blue Night Sky",
            "Orange Sand",
            "Midnight Monokai"
        }, "Blue Night Sky", function(selectedTheme)
            UI:SetTheme(selectedTheme)
        end)

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

        local ConfigCard = c:Card("Farming Parameters", nil, "Sliders")
        ConfigCard:Slider("Attack Distance", "FarmDist", 5, 50, 20, " studs")
        ConfigCard:Stepper("Loop Priority", "LoopPrio", 2, 1)
    end)
})

-- =========================================================================
-- FEATURE LAINNYA
-- =========================================================================
feature("Teleports", "Teleports")({
    center = center(function(c)
        c:Header("Teleports", "Instant coordinate & player warping")
        local Card = c:Card("Destination", nil, "Teleports")
        Card:Input("Target Player", "TpTarget", "Username...", "")
    end)
})

feature("Player", "Player")({
    center = center(function(c)
        c:Header("Player", "Character movement overrides")
        local Card = c:Card("Movement", nil, "Player")
        Card:Slider("WalkSpeed", "WalkSpeedVal", 16, 200, 16, "")
        Card:Slider("JumpPower", "JumpPowerVal", 50, 300, 50, "")
    end)
})

feature("Visuals", "Visuals")({
    center = center(function(c)
        c:Header("Visuals", "ESP and camera field of view")
        local Card = c:Card("Visual Settings", nil, "Visuals")
        Card:Toggle("Player Box ESP", "BoxESP", false)
    end)
})

feature("Misc", "Misc")({
    center = center(function(c)
        c:Header("Misc", "Additional utility tools")
    end)
})

feature("Sliders", "Settings")({
    center = center(function(c)
        c:Header("Settings", "Framework configuration")
    end)
})
