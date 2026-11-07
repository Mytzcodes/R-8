-- Load Framework (Replace with your raw GitHub link or keep inline)
local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_REPO/R8_DV_ImGui.lua"))() 
-- Note: If running in a single script inside your executor, just put the module code above and assign `local UI = ImGui({...})`

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- 1. Initialize Full Canvas & Call(3) for 25% Left | 50% Center | 25% Right
local UI = ImGui({
    Title = "DRY CURSED  •  IMGUI",
    Theme = "Blue Night Sky",
    Rounded = true,
    FocusMode = true,
    -- Optional: Pass a raw URL or local executor image for the crest logo or background banner
    LogoImage = "", 
    BannerImage = ""
}).Call(3)

-- Show Optional Startup Loading Screen
UI:ShowLoading("DRY CURSED  •  IMGUI", "Powered by R&8_DV 3-Side Architecture", 1.4)

-- Global Helpers for Syntax Sugar requested: `feature(Logo, name) { center(...), right(...) }`
local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

-- =========================================================================
-- TAB 1: HOME (Matches Reference Screenshot Layout)
-- =========================================================================
local StatLabels
feature("Home", "Home")({
    center = center(function(c)
        c:Header("Home", "Welcome back, keep going!", "Game Ready  📊")

        StatLabels = c:StatRow({
            { Icon = "Bolt",   Label = "Status",  Value = "Safe" },
            { Icon = "Clock",  Label = "Runtime", Value = "00:00:00" },
            { Icon = "Shield", Label = "Version", Value = "v1.0.0" }
        })

        local QuickCard = c:Card("⚡  Quick Actions", "View All →")
        QuickCard:ActionGrid({
            { Icon = "AutoFarm",  Name = "Auto Farm",     Flag = "QuickAutoFarm", Callback = function(state)
                print("[R&8_DV] Auto Farm state:", state)
            end },
            { Icon = "Teleports", Name = "Teleport",      Flag = "QuickTP", Callback = function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
                end
            end },
            { Icon = "Visuals",   Name = "ESP",           Flag = "QuickESP" },
            { Icon = "Bolt",      Name = "Speed Hack",    Flag = "QuickSpeed", Callback = function(state)
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = state and 48 or 16 end
            end },
            { Icon = "Player",    Name = "Infinite Jump", Flag = "QuickInfJump" },
            { Icon = "Misc",      Name = "Collect All",   Flag = "QuickCollect" }
        })

        local ActivityCard = c:Card("🕒  Recent Activity", "View Logs →")
        ActivityCard:ActivityTimeline({
            { Text = "Script Loaded (R&8_DV Engine)", Time = "Just now" },
            { Text = "Auto Farm Activated",           Time = "2m ago" },
            { Text = "Teleported to Spawn",           Time = "5m ago" },
            { Text = "ESP Enabled",                   Time = "8m ago" }
        })
    end),

    -- Right Inspector Panel (25% Width)
    right = right(function(r)
        r:Section("⚙  Settings")
        r:Section("General")
        r:Slider("UI Scale", "UIScalePct", 60, 130, 100, "%", function(val)
            UI.UIScale = val / 100
        end)
        r:Slider("Transparency", "BgTransPct", 0, 60, 8, "%", function(val)
            UI:SetTransparency(val / 100)
        end)
        r:Toggle("Lock Position", "LockPosition", false)
        r:Toggle("Rounded Borders", "RoundedState", true, function(state)
            UI:SetRounded(state)
        end)

        r:Section("Performance")
        r:Toggle("FPS Boost", "FPSBoost", false, function(state)
            if state then settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end
        end)
        r:Toggle("Reduce Effects", "ReduceEffects", false)

        r:Section("Theme")
        r:Dropdown("Color Style", "ThemeSelect", {
            "Blue Night Sky",
            "Orange Sand",
            "Midnight Monokai"
        }, "Blue Night Sky", function(selectedTheme)
            UI:SetTheme(selectedTheme)
        end)
        r:Input("Custom Banner", "BannerURL", "rbxassetid:// or https://...", "", function(url)
            UI:SetBanner(url, 0.82)
        end)

        r:Section("Other")
        r:Toggle("Notifications", "NotifyToggle", true)
        r:Stepper("Target Priority", "PriorityLevel", 1, 1)
    end)
})

-- =========================================================================
-- TAB 2: AUTO FARM
-- =========================================================================
feature("AutoFarm", "Auto Farm")({
    center = center(function(c)
        c:Header("Auto Farm", "Configure automated farming loops & combat radius", "Active  ⚡")
        local FarmCard = c:Card("🚀  Farming Configuration", "Backend Ready")
        FarmCard:Toggle("Enable Master Auto Farm", "MasterFarm", false)
        FarmCard:Slider("Attack Distance", "FarmDist", 5, 50, 18, " studs")
        FarmCard:Stepper("Farm Loop Delay (ms)", "FarmDelay", 100, 25)
        FarmCard:Dropdown("Attack Method", "FarmMethod", {"Behind Target", "Above Target", "Orbit"}, "Above Target")
    end)
})

-- =========================================================================
-- TAB 3: PLAYER
-- =========================================================================
feature("Player", "Player")({
    center = center(function(c)
        c:Header("Player", "Real-time character movement & physics overrides", "LocalPlayer")
        local PhysCard = c:Card("👤  Movement Overrides")
        PhysCard:Slider("WalkSpeed", "WalkSpeedVal", 16, 200, 16, " ws", function(v)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end)
        PhysCard:Slider("JumpPower", "JumpPowerVal", 50, 300, 50, " jp", function(v)
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true; hum.JumpPower = v end
        end)
    end)
})

-- =========================================================================
-- TAB 4: TELEPORTS / VISUALS / MISC / SETTINGS
-- =========================================================================
feature("Teleports", "Teleports")({
    center = center(function(c)
        c:Header("Teleports", "Instant coordinate & player warping")
        local TpCard = c:Card("📍  Destination Input")
        TpCard:Input("Target Player", "TpTargetName", "Username...", "", function(name)
            local target = Players:FindFirstChild(name)
            if target and target.Character and LocalPlayer.Character then
                LocalPlayer.Character:PivotTo(target.Character:GetPivot())
            end
        end)
    end)
})

feature("Visuals", "Visuals")({
    center = center(function(c)
        c:Header("Visuals", "ESP highlights and field-of-view control")
        local VisCard = c:Card("👁  Camera & ESP")
        VisCard:Slider("Field of View", "CameraFOV", 70, 120, 70, "°", function(v)
            if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
        end)
    end)
})

-- Live Runtime Counter Update
local startTime = os.time()
task.spawn(function()
    while task.wait(1) do
        local elapsed = os.time() - startTime
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = elapsed % 60
        if StatLabels and StatLabels[2] then
            StatLabels[2].Text = string.format("%02d:%02d:%02d", h, m, s)
        end
    end
end)