-- 1. Panggil Framework R&8_DV via GitHub RAW (Mendukung semua Executor PC & Mobile)
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"
local okFetch, rawScript = pcall(function()
    return game:HttpGet(GITHUB_RAW_URL)
end)
if not okFetch or type(rawScript) ~= "string" or #rawScript < 128 or string.sub(rawScript, 1, 4) == "404:" then
    okFetch, rawScript = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r&8_dv.lua")
    end)
end
assert(okFetch and type(rawScript) == "string" and #rawScript > 128, "[R&8_DV] HTTP 404: Pastikan file r&8_dv.lua sudah di-upload ke GitHub Mytzcodes/R-8 (branch main).")

local ImGui = loadstring(rawScript)()

-- 2. Inisialisasi Jendela R&8_DV (Teks Solid Tajam Anti-Rusak, Tombol Lega & Smooth 60 FPS)
local UI = ImGui({
    Title = "DRY CURSED - IMGUI",
    BrandTitle = "R&8_DV",            -- Judul utama solid & tegas di bawah logo sidebar
    BrandSubtitle = "IMGUI SUITE",    -- Sub-judul di bawah logo sidebar
    Theme = "Minimalist Monochrome",  -- "Minimalist Monochrome" | "Blue Night Sky" | "Violet Amethyst" | "Orange Sand" | "Midnight Monokai"
    CheckboxStyle = "Modern",         -- "Modern" (Pill Switch) | "Checkbox" (Checklist Kotak)
    LetterSpacing = 1,                -- Spasi antar huruf header & judul (0 - 3)
    AutoLoading = false               -- Langsung buka instan 0ms tanpa delay!
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

local ThemeChoices = UI.GetThemes and UI:GetThemes() or {
    "Minimalist Monochrome",
    "Blue Night Sky",
    "Violet Amethyst",
    "Orange Sand",
    "Midnight Monokai"
}

-- =========================================================================
-- KATEGORI 1: OVERVIEW
-- =========================================================================
if UI.Category then UI:Category("Overview") end

feature("Home", "Home")({
    center = center(function(c)
        c:Header("Dashboard", "Clean minimalist interface with high-contrast solid typography", "Ready")

        c:StatRow({
            { Icon = "Shield", Label = "Status",  Value = "Undetected" },
            { Icon = "Bolt",   Label = "Render",  Value = "60 FPS Smooth" },
            { Icon = "Clock",  Label = "Version", Value = "v5.3 Stable" }
        })

        local QuickCard = c:Card("Quick Actions", "6 Shortcuts", "Bolt", {
            Subtitle = "Toggle frequently used modules directly from home"
        })
        QuickCard:ActionGrid({
            { Icon = "AutoFarm",  Name = "Auto Farm",      Flag = "QuickAutoFarm", Default = true },
            { Icon = "Teleports", Name = "Teleport",       Flag = "QuickTP" },
            { Icon = "Visuals",   Name = "ESP Box",        Flag = "QuickESP", Default = true },
            { Icon = "Speed",     Name = "Speed Override", Flag = "QuickSpeed" },
            { Icon = "Jump",      Name = "Infinite Jump",  Flag = "QuickInfJump" },
            { Icon = "Collect",   Name = "Collect All",    Flag = "QuickCollect" }
        })

        local SessionCard = c:Card("Session Control", nil, "Shield", {
            Subtitle = "Core protection & automatic session safeguards",
            ToggleFlag = "MasterSessionGuard",
            Default = true
        })
        SessionCard:Toggle("Anti-AFK Idle Guard", "AntiAFK", true)
        SessionCard:Toggle("Auto Reconnect on Kick", "AutoReconnect", false)

        local ActivityCard = c:Card("Recent Activity", "Live Logs", "Clock", {
            Subtitle = "Latest framework and module events"
        })
        ActivityCard:ActivityTimeline({
            { Text = "R&8_DV v5.3 Solid UI Initialized",   Time = "Just now" },
            { Text = "High-Contrast Text Guard Verified",  Time = "1m ago" },
            { Text = "Single-Border Popup Icon Ready",     Time = "2m ago" },
            { Text = "GitHub Master Crest Cached",         Time = "4m ago" }
        })
    end),

    -- Panel Kanan Global: Seluruh pengaturan dibungkus rapi di dalam Card!
    right = right(function(r)
        local ThemeCard = r:Card("Theme & Checklist", nil, "Palette", {
            Subtitle = "Choose colour palette and switch/checkbox style"
        })
        if ThemeCard.ThemeSwatches then
            ThemeCard:ThemeSwatches("Colour Palette")
        end
        ThemeCard:Dropdown("Color Style", "ThemeSelect", ThemeChoices, "Minimalist Monochrome", function(selectedTheme)
            UI:SetTheme(selectedTheme)
        end)
        ThemeCard:Dropdown("Checkbox Style", "CheckboxStyleMode", {
            "Modern",
            "Checkbox"
        }, "Modern", function(mode)
            if UI.SetCheckboxStyle then UI:SetCheckboxStyle(mode) end
        end)
        ThemeCard:Slider("Letter Spacing", "LetterSpacingVal", 0, 3, 1, "x", function(val)
            if UI.SetLetterSpacing then UI:SetLetterSpacing(val) end
        end)

        local LayoutCard = r:Card("Window & Layout", nil, "Sliders", {
            Subtitle = "Scale, surface opacity, corners and menu hotkey"
        })
        LayoutCard:Slider("UI Scale", "UIScalePct", 60, 130, 100, "%", function(val)
            if UI.SetScale then
                UI:SetScale(val / 100)
            else
                UI.UIScale = val / 100
            end
        end)
        LayoutCard:Slider("Transparency", "BgTransPct", 0, 55, 4, "%", function(val)
            UI:SetTransparency(val / 100)
        end)
        LayoutCard:Toggle("Rounded Borders", "RoundedState", true, function(state)
            UI:SetRounded(state)
        end)
        LayoutCard:Toggle("Lock Position", "LockPosition", false)
        if LayoutCard.Keybind then
            LayoutCard:Keybind("Toggle Menu Key", "MenuHotkey", Enum.KeyCode.RightShift, function(newKey)
                if newKey then
                    UI.ToggleKey = newKey
                end
            end)
        end

        local PerfCard = r:Card("Performance", nil, "Bolt", {
            Subtitle = "Instant zero-tween mode for low-end devices"
        })
        PerfCard:Toggle("FPS Boost", "FPSBoost", false)
        PerfCard:Toggle("Reduce Effects", "ReduceEffects", false)
    end)
})

-- =========================================================================
-- KATEGORI 2: MODULES
-- =========================================================================
if UI.Category then UI:Category("Modules") end

-- Tab Combat (3 Card Lengkap)
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
        if ProfileCard.Keybind then
            ProfileCard:Keybind("Activation Key", "AimActivationKey", Enum.KeyCode.Q)
        end
        ProfileCard:Slider("Response Smoothness", "AimSmoothness", 0.10, 1.00, 0.50, "x", nil, 0.05)
        ProfileCard:Stepper("Target Priority Slot", "PriorityLevel", 1, 1)

        local TriggerCard = c:Card("Trigger & Limits", nil, "Bolt", {
            Subtitle = "Reaction delay and automatic fire safety",
            ToggleFlag = "MasterTrigger",
            Default = false
        })
        TriggerCard:Toggle("Team Check Safety", "TriggerTeamCheck", true)
        TriggerCard:Slider("Reaction Delay", "TriggerDelay", 0, 250, 45, " ms", nil, 5)
    end)
})

-- Tab Auto Farm (Feature Hover Cards + Farming Settings Card + Right Matrix Cards)
feature("Bot", "Auto Farm")({
    center = center(function(c)
        c:Header("Automation", "Interactive feature cards & automated farming routines", "Active")

        if c.FeatureCard then
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
                Icon = "Bot",
                Title = "Auto Quest",
                Description = "Claim and repeat active farming quests automatically.",
                Flag = "CardAutoQuest",
                Default = false
            })
        end

        local FarmCfgCard = c:Card("Farming Behaviour", nil, "Sliders", {
            Subtitle = "Fine-tune collection radius and spammer interval"
        })
        FarmCfgCard:Slider("Collect Radius", "CollectRadius", 10, 120, 40, " studs")
        FarmCfgCard:Slider("Chat Interval", "SpamInterval", 1, 30, 5, " s")
    end),

    right = right(function(r)
        local TileCard = r:Card("Block to Break", nil, "Bot", {
            Subtitle = "Configure target block & surrounding 5x5 break matrix"
        })
        TileCard:Input("Target Block", "BlockToBreak", "Block name...", "Bountiful Lattice Fence")
        TileCard:Slider("Hit Delay", "FarmHitDelay", 60, 400, 160, " ms")
        if TileCard.TileGrid then
            TileCard:TileGrid("Select tile to break (P = Player)", "BreakMatrix", 5, 5)
        end

        local SafetyCard = r:Card("Farm Safety", nil, "Shield", {
            Subtitle = "Stop automation when staff or players approach"
        })
        SafetyCard:Toggle("Pause on Nearby Player", "PauseNearPlayer", true)
        SafetyCard:Toggle("Auto Store Inventory", "AutoStoreInv", false)
    end)
})

-- Tab Visuals (3 Card Lengkap)
feature("Visuals", "Visuals")({
    center = center(function(c)
        c:Header("Visuals", "Player geometry, world items & overlay customization", "Overlay")

        local GeoCard = c:Card("Player Geometry", nil, "Visuals", {
            Subtitle = "Bounding box, tracers and health bar indicators",
            ToggleFlag = "MasterPlayerGeo",
            Default = true
        })
        GeoCard:Toggle("Bounding Box", "BoxESP", true)
        GeoCard:Toggle("Name & Distance Tag", "NameESP", true)
        GeoCard:Toggle("Health Bar", "HealthBarESP", true)
        GeoCard:Slider("Display Range", "ESPRange", 50, 1000, 450, " m")

        local WorldCard = c:Card("World & Dropped Items", nil, "Collect", {
            Subtitle = "Highlight chests, collectibles and objectives",
            ToggleFlag = "MasterWorldESP",
            Default = false
        })
        WorldCard:Toggle("Show Dropped Loot", "LootESP", true)
        WorldCard:Toggle("Show Spawn Chests", "ChestESP", false)

        local StyleCard = c:Card("Overlay Style", nil, "Palette", {
            Subtitle = "Customize ESP stroke thickness and bar mode"
        })
        StyleCard:Slider("Line Width", "ESPLineWidth", 1.0, 4.0, 1.5, " px", nil, 0.5)
        StyleCard:Dropdown("Health Bar Mode", "ESPHealthStyle", {
            "Solid",
            "Dynamic",
            "Minimal"
        }, "Solid")
    end)
})

-- Tab Player (3 Card Lengkap)
feature("Player", "Player")({
    center = center(function(c)
        c:Header("Player & World", "Character movement overrides and instant teleportation", "LocalPlayer")

        local MoveCard = c:Card("Movement Overrides", nil, "Speed", {
            Subtitle = "Adjust WalkSpeed and JumpPower safely"
        })
        MoveCard:Slider("WalkSpeed", "WalkSpeedVal", 16, 200, 16, "", function(val)
            local lp = game:GetService("Players").LocalPlayer
            local char = lp and lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end)
        MoveCard:Slider("JumpPower", "JumpPowerVal", 50, 300, 50, "", function(val)
            local lp = game:GetService("Players").LocalPlayer
            local char = lp and lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = val end
        end)

        local CharCard = c:Card("Character Utility", nil, "Player", {
            Subtitle = "Physics and camera helpers"
        })
        CharCard:Toggle("NoClip Collision", "NoClipToggle", false)
        CharCard:Toggle("Infinite Jump", "PlayerInfJump", false)
        CharCard:Slider("Field of View", "CameraFOV", 70, 120, 70, " deg", function(val)
            if workspace.CurrentCamera then
                workspace.CurrentCamera.FieldOfView = val
            end
        end)

        local TpCard = c:Card("Destination Warp", nil, "Teleports", {
            Subtitle = "Instant player & world coordinate warping"
        })
        TpCard:Input("Target Player", "TpTarget", "Username...", "")
        if TpCard.Button then
            TpCard:Button("Warp to Target Player", "EXECUTE", "Teleports", function()
                print("[R&8_DV] Teleport target:", UI:GetValue("TpTarget"))
            end)
        end
    end)
})

-- Tab Misc (3 Card Lengkap)
feature("Misc", "Misc")({
    center = center(function(c)
        c:Header("Misc", "Session utilities, configuration & window shortcuts", "Utility")

        local UtilCard = c:Card("Session Utilities", nil, "Misc", {
            Subtitle = "Interface notifications and stream privacy"
        })
        UtilCard:Toggle("System Notifications", "NotifyToggle", true)
        UtilCard:Toggle("Stream Proof Mode", "StreamProof", false)

        local CfgCard = c:Card("Configuration Profile", nil, "Sliders", {
            Subtitle = "Manage active preset slot"
        })
        CfgCard:Dropdown("Active Preset", "ConfigSlot", {
            "Default",
            "Legit",
            "Farming",
            "Custom"
        }, "Default")
        CfgCard:Button("Apply Selected Preset", "LOAD", "Check", function()
            print("[R&8_DV] Loaded preset:", UI:GetValue("ConfigSlot"))
        end)

        local WinActionCard = c:Card("Window Controls", nil, "Menu", {
            Subtitle = "Quickly dock menu into floating squircle icon"
        })
        WinActionCard:Button("Minimize to Popup Icon", "HIDE", "Minimize", function()
            UI:MinimizeToIcon()
        end)
    end)
})
