-- 1. Panggil Framework R&8_DV (Ganti URL dengan link RAW tempat Anda menyimpan R8_DV_ImGui.lua)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/R8_DV_ImGui.lua"))()

-- 2. Panggil Canvas 3 Sisi (25% Kiri | 50% Tengah | 25% Kanan)
-- Logo GitHub, Vector Icon, Loading Screen, dan Minimize Icon otomatis diurus Framework!
local UI = ImGui({
    Title = "DRY CURSED  -  IMGUI",
    Theme = "Blue Night Sky"
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

-- =========================================================================
-- FEATURE 1: HOME
-- =========================================================================
feature("Home", "Home")({
    center = center(function(c)
        c:Header("Home", "Welcome back, keep going!", "Game Ready")

        c:StatRow({
            { Icon = "Bolt",   Label = "Status",  Value = "Safe" },
            { Icon = "Clock",  Label = "Runtime", Value = "00:12:34" },
            { Icon = "Shield", Label = "Version", Value = "v4.0.0" }
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
            { Text = "Script Loaded",        Time = "2m ago" },
            { Text = "Auto Farm Activated",  Time = "4m ago" },
            { Text = "Teleported to Spawn",  Time = "7m ago" },
            { Text = "ESP Enabled",          Time = "10m ago" }
        })
    end),

    right = right(function(r)
        r:Section("Settings", "Settings")
        r:Section("General")
        r:Slider("UI Scale", "UIScalePct", 60, 130, 100, "%", function(val)
            UI.UIScale = val / 100
        end)
        r:Slider("Transparency", "BgTransPct", 0, 60, 6, "%", function(val)
            UI:SetTransparency(val / 100)
        end)
        r:Toggle("Lock Position", "LockPosition", false)
        r:Toggle("Rounded Borders", "RoundedState", true, function(state)
            UI:SetRounded(state)
        end)

        r:Section("Performance")
        r:Toggle("FPS Boost", "FPSBoost", false)
        r:Toggle("Reduce Effects", "ReduceEffects", false)

        r:Section("Theme")
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
-- FEATURE LAINNYA (SIDEBAR KIRI)
-- =========================================================================
feature("AutoFarm", "Auto Farm")({
    center = center(function(c)
        c:Header("Auto Farm", "Automated farming configuration", "Active")
        local Card = c:Card("Farming Controls", "Ready", "AutoFarm")
        Card:Toggle("Enable Auto Farm", "MasterFarm", false)
        Card:Slider("Attack Distance", "FarmDist", 5, 50, 18, " studs")
    end)
})

feature("Teleports", "Teleports")({
    center = center(function(c)
        c:Header("Teleports", "Instant world & player warping")
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
