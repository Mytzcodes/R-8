-- 1. Panggil Framework R&8_DV (Link GitHub RAW dipertahankan sesuai repo)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/R8_DV_ImGui.lua"))()

-- 2. Inisialisasi Jendela Minimalist Monochrome dengan 2.5D / 3D Colourful Typography
-- Logo GitHub, Vector Icon, Smooth Loader, dan Single-Border Popup Minimize Icon diurus otomatis!
local UI = ImGui({
    Title = "DRY CURSED  -  IMGUI",
    Theme = "Minimalist Monochrome", -- "Minimalist Monochrome" | "Blue Night Sky" | "Violet Amethyst" | "Orange Sand" | "Midnight Monokai"
    CheckboxStyle = "Modern",        -- "Modern" (Pill Switch) | "Checkbox" (Square Check)
    Text3D = true,                   -- Aktifkan 2.5D / 3D Colourful Gradient Text (Ringan, 0% FPS Drop)
    AutoLoading = true
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

-- =========================================================================
-- KATEGORI 1: OVERVIEW
-- =========================================================================
UI:Category("Overview")

feature("Home", "Home")({
    center = center(function(c)
        c:Header("Home", "Minimalist monochrome surface with colourful 2.5D / 3D typography", "Game Ready")

        c:StatRow({
            { Icon = "Shield", Label = "Status",  Value = "Undetected" },
            { Icon = "Bolt",   Label = "Render",  Value = "0% FPS Drop" },
            { Icon = "Clock",  Label = "Engine",  Value = "v5.0 Minimal" }
        })

        local QuickCard = c:Card("Quick Actions", "6 Shortcuts", "Bolt")
        QuickCard:ActionGrid({
            { Icon = "AutoFarm",  Name = "Auto Farm",     Flag = "QuickAutoFarm" },
            { Icon = "Teleports", Name = "Teleport",      Flag = "QuickTP" },
            { Icon = "Visuals",   Name = "ESP Box",       Flag = "QuickESP" },
            { Icon = "Speed",     Name = "Speed Override",Flag = "QuickSpeed" },
            { Icon = "Jump",      Name = "Infinite Jump", Flag = "QuickInfJump" },
            { Icon = "Collect",   Name = "Collect All",   Flag = "QuickCollect" }
        })

        local ActivityCard = c:Card("Recent Activity", "Live Logs", "Clock")
        ActivityCard:ActivityTimeline({
            { Text = "R&8_DV Minimalist v5.0 Initialized", Time = "Just now" },
            { Text = "2.5D / 3D Colourful Font Active",    Time = "1m ago" },
            { Text = "Single-Border Popup Icon Ready",     Time = "2m ago" },
            { Text = "GitHub Master Crest Cached",         Time = "4m ago" }
        })
    end),

    -- Panel Kanan Global (Otomatis tampil di tab yang tidak memiliki panel kanan khusus)
    right = right(function(r)
        r:Section("Theme & Typography", "Palette")
        r:Dropdown("Color Style", "ThemeSelect", UI:GetThemes(), "Minimalist Monochrome", function(selectedTheme)
            UI:SetTheme(selectedTheme)
        end)
        r:Toggle("2.5D / 3D Colourful Font", "Text3DToggle", true, function(state)
            UI:SetText3D(state)
        end)
        r:Dropdown("Checkbox Style", "CheckboxStyleMode", {
            "Modern",
            "Checkbox"
        }, "Modern", function(mode)
            UI:SetCheckboxStyle(mode)
        end)

        r:Section("Window & Layout", "Sliders")
        r:Slider("UI Scale", "UIScalePct", 60, 130, 100, "%", function(val)
            UI:SetScale(val / 100)
        end)
        r:Slider("Transparency", "BgTransPct", 0, 55, 4, "%", function(val)
            UI:SetTransparency(val / 100)
        end)
        r:Toggle("Lock Position", "LockPosition", false)
        r:Toggle("Rounded Borders", "RoundedState", true, function(state)
            UI:SetRounded(state)
        end)
        r:Keybind("Toggle Menu Key", "MenuHotkey", Enum.KeyCode.RightShift, function(newKey)
            if newKey then
                UI.ToggleKey = newKey
            end
        end)

        r:Section("Performance", "Bolt")
        r:Toggle("FPS Boost", "FPSBoost", false)
        r:Toggle("Reduce Effects", "ReduceEffects", false)
    end)
})

-- =========================================================================
-- KATEGORI 2: MODULES (SESUAI REFERENSI MENU)
-- =========================================================================
UI:Category("Modules")

-- Tab Combat (Referensi Card dengan Subtitle & Master Header Switch + Keybind)
feature("Combat", "Combat")({
    center = center(function(c)
        c:Header("Combat", "Target assistance, response policy & keybind limits", "Targets")

        local TargetCard = c:Card("Target Selection", nil, "Target", {
            Subtitle = "Choose which targets assistance follows",
            ToggleFlag = "MasterTargetSelection",
            Default = true
        })
        TargetCard:Toggle("Visible Targets", "VisibleTargets", true)
        TargetCard:Toggle("Skip Teammates", "SkipTeammates", true)
        TargetCard:Toggle("Prefer Nearest", "PreferNearest", false)
        TargetCard:Slider("Detection Radius", "DetectionRadius", 20, 360, 120, " px")
        TargetCard:Dropdown("Target Priority", "TargetPriorityMode", {
            "Automatic",
            "Closest to Crosshair",
            "Lowest Health",
            "Nearest Distance"
        }, "Automatic")

        local ProfileCard = c:Card("Aimbot Profile", nil, "Shield", {
            Subtitle = "Activation keybind and smoothing behaviour",
            ToggleFlag = "MasterAimProfile",
            Default = false
        })
        ProfileCard:Keybind("Activation Key", "AimActivationKey", Enum.KeyCode.Q)
        ProfileCard:Slider("Response Smoothness", "AimSmoothness", 0.10, 1.00, 0.50, "x", nil, 0.05)
        ProfileCard:Stepper("Target Priority Slot", "PriorityLevel", 1, 1)
    end)
})

-- Tab Auto Farm (Referensi Interactive Feature Hover Cards + 5x5 Tile Breaker Grid)
feature("Bot", "Auto Farm")({
    center = center(function(c)
        c:Header("Automation", "Interactive hover cards & automated farming routines", "Active")

        c:FeatureCard({
            Icon = "Bot",
            Title = "Autofarm",
            Description = "Automatically farming without effort touching the screen.",
            Flag = "CardAutofarm",
            Default = true
        })

        c:FeatureCard({
            Icon = "Chat",
            Title = "Spammer",
            Description = "Automatically send chat messages without typing manually.",
            Flag = "CardSpammer",
            Default = false
        })

        c:FeatureCard({
            Icon = "Collect",
            Title = "Collect",
            Description = "Automation utility for collecting nearby dropped items.",
            Flag = "CardCollect",
            Default = false
        })

        c:FeatureCard({
            Icon = "Fish",
            Title = "Fishing",
            Description = "Automatically pull rod when fish bite is detected.",
            Flag = "CardFishing",
            Default = false
        })
    end),

    right = right(function(r)
        r:Section("Autofarm Matrix", "Grid")
        local TileCard = r:Card("Block to Break", nil, "Bot", {
            Subtitle = "Configure target block & surrounding break matrix"
        })
        TileCard:Input("Target Block", "BlockToBreak", "Block name...", "Bountiful Lattice Fence")
        TileCard:Slider("Hit Delay", "FarmHitDelay", 60, 400, 160, " ms")
        TileCard:TileGrid("Select tile to break (P = Player)", "BreakMatrix", 5, 5)
    end)
})

-- Tab Visuals (Referensi Player Geometry & Overlay Style Cards)
feature("Visuals", "Visuals")({
    center = center(function(c)
        c:Header("Visuals", "Player geometry, status flags & world overlay style", "Overlay")

        local GeoCard = c:Card("Player Geometry", nil, "Visuals", {
            Subtitle = "Bounding box, skeleton and health bar indicators",
            ToggleFlag = "MasterPlayerGeo",
            Default = true
        })
        GeoCard:Toggle("Bounding Box", "BoxESP", true)
        GeoCard:Toggle("Skeleton Overlay", "SkeletonESP", false)
        GeoCard:Toggle("Health Bar", "HealthBarESP", true)
        GeoCard:Slider("Display Range", "ESPRange", 50, 1000, 450, "m")

        local StyleCard = c:Card("Overlay Style", nil, "Palette", {
            Subtitle = "Customize ESP stroke thickness and health bar mode"
        })
        StyleCard:Slider("Line Width", "ESPLineWidth", 1.0, 4.0, 1.5, " px", nil, 0.5)
        StyleCard:Dropdown("Health Style", "ESPHealthStyle", {
            "Gradient",
            "Solid",
            "Minimal"
        }, "Gradient")
    end)
})

-- Tab Player & Teleports
feature("Player", "Player")({
    center = center(function(c)
        c:Header("Player & World", "Character movement overrides and instant teleportation", "LocalPlayer")

        local MoveCard = c:Card("Movement Overrides", nil, "Speed", {
            Subtitle = "Adjust WalkSpeed and JumpPower safely"
        })
        MoveCard:Slider("WalkSpeed", "WalkSpeedVal", 16, 200, 16, "", function(val)
            local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end)
        MoveCard:Slider("JumpPower", "JumpPowerVal", 50, 300, 50, "", function(val)
            local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = val end
        end)

        local TpCard = c:Card("Destination Warp", nil, "Teleports", {
            Subtitle = "Instant player & world coordinate warping"
        })
        TpCard:Input("Target Player", "TpTarget", "Username...", "")
        TpCard:Button("Warp to Target Player", "EXECUTE", "Teleports", function()
            print("[R&8_DV] Teleport target:", UI:GetValue("TpTarget"))
        end)
    end)
})

-- Tab Misc
feature("Misc", "Misc")({
    center = center(function(c)
        c:Header("Misc", "Additional utility shortcuts & configuration tools", "Utility")
        local UtilCard = c:Card("Session Utilities", nil, "Misc", {
            Subtitle = "Quick server & interface actions"
        })
        UtilCard:Toggle("Notifications", "NotifyToggle", true)
        UtilCard:Button("Minimize to Popup Icon", "HIDE", "Minimize", function()
            UI:MinimizeToIcon()
        end)
    end)
})
