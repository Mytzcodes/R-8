--[[
    FRAMEWORK: R&8_DV ImGui Architecture (v2.5)
    COPYRIGHT: © R&8_DV - All Rights Reserved
    DESIGN: 2/3-Side Responsive Division (25% / 50% / 25%), Auto-Contrast, Focus Sink
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // SAFE PARENTING FOR EXECUTORS //
local function GetSafeGuiParent()
    local success, result = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if success and result then return result end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- // CUSTOM ASSET / RAW URL LOADER //
local AssetCache = {}
local function ResolveImage(source)
    if not source or source == "" then return "" end
    if string.find(source, "^rbxassetid://") or string.find(source, "^rbxthumb://") then
        return source
    end
    if AssetCache[source] then return AssetCache[source] end

    -- If executor supports getcustomasset & writefile, download raw URL or load local file
    local getAsset = getcustomasset or getsynasset
    if getAsset and writefile and isfile then
        local success, assetId = pcall(function()
            if string.find(source, "^https?://") then
                local fileName = "R8DV_Cache_" .. tostring( math.abs( string.byte(source, 1, 1) * #source ) ) .. ".png"
                if not isfile(fileName) then
                    local rawData = game:HttpGet(source)
                    writefile(fileName, rawData)
                end
                return getAsset(fileName)
            elseif isfile(source) then
                return getAsset(source)
            end
        end)
        if success and assetId then
            AssetCache[source] = assetId
            return assetId
        end
    end
    return source
end

-- // CONTRAST GUARD (PREVENTS BLACK-ON-BLACK TEXT) //
local function GetReadableTextColor(bgColor, preferredTextColor)
    local function luminance(c)
        return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    end
    local bgLum = luminance(bgColor)
    local txtLum = luminance(preferredTextColor)
    if math.abs(bgLum - txtLum) < 0.35 then
        return bgLum > 0.5 and Color3.fromRGB(18, 20, 26) or Color3.fromRGB(242, 245, 252)
    end
    return preferredTextColor
end

-- // BUILT-IN CURATED THEMES //
local Themes = {
    ["Blue Night Sky"] = {
        MainBg       = Color3.fromRGB(13, 15, 23),
        PanelBg      = Color3.fromRGB(18, 21, 32),
        CardBg       = Color3.fromRGB(24, 28, 42),
        ControlBg    = Color3.fromRGB(32, 38, 56),
        Accent       = Color3.fromRGB(98, 137, 255),
        Stroke       = Color3.fromRGB(45, 53, 78),
        TextPrimary  = Color3.fromRGB(240, 244, 255),
        TextMuted    = Color3.fromRGB(142, 152, 178),
        Success      = Color3.fromRGB(72, 219, 151)
    },
    ["Orange Sand"] = {
        MainBg       = Color3.fromRGB(24, 19, 16),
        PanelBg      = Color3.fromRGB(33, 26, 22),
        CardBg       = Color3.fromRGB(43, 34, 29),
        ControlBg    = Color3.fromRGB(58, 46, 39),
        Accent       = Color3.fromRGB(245, 148, 66),
        Stroke       = Color3.fromRGB(78, 61, 50),
        TextPrimary  = Color3.fromRGB(252, 243, 235),
        TextMuted    = Color3.fromRGB(184, 162, 145),
        Success      = Color3.fromRGB(108, 214, 130)
    },
    ["Midnight Monokai"] = {
        MainBg       = Color3.fromRGB(19, 20, 17),
        PanelBg      = Color3.fromRGB(27, 28, 24),
        CardBg       = Color3.fromRGB(36, 37, 32),
        ControlBg    = Color3.fromRGB(48, 50, 43),
        Accent       = Color3.fromRGB(166, 226, 46),
        Stroke       = Color3.fromRGB(64, 66, 56),
        TextPrimary  = Color3.fromRGB(248, 248, 242),
        TextMuted    = Color3.fromRGB(145, 148, 135),
        Success      = Color3.fromRGB(102, 217, 239)
    }
}

-- // FALLBACK GLYPHS //
local IconGlyphs = {
    Home      = "⌂",
    AutoFarm  = "🚀",
    Teleports = "📍",
    Player    = "👤",
    Visuals   = "👁",
    Misc      = "⚙",
    Settings  = "☰",
    Bolt      = "⚡",
    Clock     = "🕒",
    Shield    = "🛡",
    Check     = "✓"
}

-- // ROUNDED + BORDER HELPER //
local function ApplySurfaceStyle(frame, radiusScale, strokeColor, themeBindings, radiusBindings, strokeType)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radiusScale)
    corner.Parent = frame
    table.insert(radiusBindings, {Instance = corner, BaseRadius = radiusScale})

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1
    stroke.Color = strokeColor
    stroke.Transparency = 0.25
    stroke.Parent = frame
    table.insert(themeBindings, {Instance = stroke, Prop = "Color", Key = strokeType or "Stroke"})
    return corner, stroke
end

-- // MAIN CONSTRUCTOR //
local function ImGui(config)
    config = config or {}
    local Self = {
        Title = config.Title or "DRY CURSED  •  IMGUI",
        Copyright = "R&8_DV",
        ThemeName = config.Theme or "Blue Night Sky",
        Rounded = (config.Rounded ~= false),
        SideCount = 3,
        UIScale = config.Scale or 1,
        BgTransparency = config.Transparency or 0.06,
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.82,
        LogoImage = config.LogoImage or "",
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode ~= false),
        Flags = {},
        FlagListeners = {},
        Features = {},
        ActiveFeature = nil,
        ThemeBindings = {},
        RadiusBindings = {}
    }

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Blue Night Sky"]

    -- Reactive State API
    function Self:SetValue(flag, value)
        Self.Flags[flag] = value
        if Self.FlagListeners[flag] then
            for _, callback in ipairs(Self.FlagListeners[flag]) do
                task.spawn(callback, value)
            end
        end
    end

    function Self:GetValue(flag)
        return Self.Flags[flag]
    end

    function Self:OnValueChanged(flag, callback)
        Self.FlagListeners[flag] = Self.FlagListeners[flag] or {}
        table.insert(Self.FlagListeners[flag], callback)
    end

    local function BindTheme(instance, prop, themeKey, bgKeyForContrast)
        table.insert(Self.ThemeBindings, {
            Instance = instance,
            Prop = prop,
            Key = themeKey,
            BgKey = bgKeyForContrast
        })
        local col = CurrentTheme[themeKey]
        if bgKeyForContrast then
            col = GetReadableTextColor(CurrentTheme[bgKeyForContrast], col)
        end
        instance[prop] = col
    end

    -- Root ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "R8_DV_ImGui_" .. HttpService:GenerateGUID(false):sub(1, 6)
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = GetSafeGuiParent()

    -- Focus Mode Input Sink (Blocks clicks behind menu & unlocks mouse)
    local FocusBlocker = Instance.new("TextButton")
    FocusBlocker.Name = "FocusSink"
    FocusBlocker.Size = UDim2.fromScale(1, 1)
    FocusBlocker.BackgroundTransparency = 0.45
    FocusBlocker.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
    FocusBlocker.Text = ""
    FocusBlocker.AutoButtonColor = false
    FocusBlocker.Active = true
    FocusBlocker.Modal = true
    FocusBlocker.Visible = Self.FocusMode
    FocusBlocker.Parent = ScreenGui

    -- Main Window Container
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.fromOffset(1020, 600)
    MainWindow.Position = UDim2.fromScale(0.5, 0.5)
    MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    MainWindow.BackgroundTransparency = Self.BgTransparency
    MainWindow.Active = true
    MainWindow.Parent = ScreenGui
    BindTheme(MainWindow, "BackgroundColor3", "MainBg")
    ApplySurfaceStyle(MainWindow, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- Responsive Scale Engine (Desktop & Phone Auto-Scaling)
    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainWindow

    local function UpdateResponsiveScale()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local scaleX = (vp.X * 0.94) / 1020
        local scaleY = (vp.Y * 0.92) / 600
        local autoFit = math.min(1, scaleX, scaleY)
        WindowScale.Scale = math.clamp(autoFit * Self.UIScale, 0.42, 1.5)
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(UpdateResponsiveScale)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
    end
    UpdateResponsiveScale()

    -- Optional Custom Banner / Background Image Layer
    local BannerLayer = Instance.new("ImageLabel")
    BannerLayer.Name = "CustomBanner"
    BannerLayer.Size = UDim2.fromScale(1, 1)
    BannerLayer.BackgroundTransparency = 1
    BannerLayer.ScaleType = Enum.ScaleType.Crop
    BannerLayer.Image = ResolveImage(Self.BannerImage)
    BannerLayer.ImageTransparency = Self.BannerImage ~= "" and Self.BannerTransparency or 1
    BannerLayer.Parent = MainWindow
    ApplySurfaceStyle(BannerLayer, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- Copyright Watermark
    local Watermark = Instance.new("TextLabel")
    Watermark.Size = UDim2.new(0, 140, 0, 16)
    Watermark.Position = UDim2.new(1, -148, 1, -18)
    Watermark.BackgroundTransparency = 1
    Watermark.Font = Enum.Font.GothamBold
    Watermark.Text = "© " .. Self.Copyright .. " ENGINE"
    Watermark.TextSize = 10
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    Watermark.TextTransparency = 0.45
    Watermark.Parent = MainWindow
    BindTheme(Watermark, "TextColor3", "TextMuted", "MainBg")

    -- =========================================================================
    -- 3-SIDE LAYOUT ARCHITECTURE: LEFT (25%) | TOPBAR + CENTER (50%) + RIGHT (25%)
    -- =========================================================================

    -- 1. LEFT SIDEBAR (25% Width, Full Height like Reference Image)
    local LeftSidebar = Instance.new("Frame")
    LeftSidebar.Name = "LeftSidebar"
    LeftSidebar.Position = UDim2.new(0, 12, 0, 12)
    LeftSidebar.Size = UDim2.new(0.25, -18, 1, -24)
    LeftSidebar.BackgroundTransparency = Self.BgTransparency
    LeftSidebar.Parent = MainWindow
    BindTheme(LeftSidebar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(LeftSidebar, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- Brand Emblem Area (Top of Left Sidebar)
    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = UDim2.new(1, 0, 0, 130)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(78, 92)
    BrandLogo.Position = UDim2.fromScale(0.5, 0.52)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolveImage(Self.LogoImage)
    BrandLogo.Parent = LogoHolder

    -- Fallback Stylized Emblem if no custom image is loaded
    local FallbackCrest = Instance.new("TextLabel")
    FallbackCrest.Size = UDim2.fromScale(1, 1)
    FallbackCrest.BackgroundTransparency = 1
    FallbackCrest.Font = Enum.Font.GothamBlack
    FallbackCrest.Text = "❖"
    FallbackCrest.TextSize = 62
    FallbackCrest.Visible = (Self.LogoImage == "")
    FallbackCrest.Parent = BrandLogo
    BindTheme(FallbackCrest, "TextColor3", "Accent", "PanelBg")

    -- Navigation List inside Left Sidebar
    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Position = UDim2.new(0, 10, 0, 135)
    NavScroll.Size = UDim2.new(1, -20, 1, -147)
    NavScroll.BackgroundTransparency = 1
    NavScroll.ScrollBarThickness = 2
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.Parent = LeftSidebar
    BindTheme(NavScroll, "ScrollBarImageColor3", "Accent")

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 6)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = NavScroll

    -- 2. TOP IMGUI HEADER BAR (Spans across Center + Right 75% Area)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.25, 2, 0, 12)
    TopBar.Size = UDim2.new(0.75, -14, 0, 42)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local TopIcon = Instance.new("TextLabel")
    TopIcon.Position = UDim2.new(0, 14, 0, 0)
    TopIcon.Size = UDim2.new(0, 24, 1, 0)
    TopIcon.BackgroundTransparency = 1
    TopIcon.Font = Enum.Font.GothamBold
    TopIcon.Text = "❐"
    TopIcon.TextSize = 15
    TopIcon.Parent = TopBar
    BindTheme(TopIcon, "TextColor3", "TextPrimary", "PanelBg")

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Position = UDim2.new(0, 42, 0, 0)
    TopTitle.Size = UDim2.new(0.6, 0, 1, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Font = Enum.Font.GothamBold
    TopTitle.Text = "•   " .. Self.Title .. "   •   " .. Self.Copyright
    TopTitle.TextSize = 12
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    BindTheme(TopTitle, "TextColor3", "TextPrimary", "PanelBg")

    -- Window Control Buttons ( ☰  —  □  ✕ )
    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Position = UDim2.new(1, -136, 0, 0)
    ControlsHolder.Size = UDim2.new(0, 128, 1, 0)
    ControlsHolder.BackgroundTransparency = 1
    ControlsHolder.Parent = TopBar

    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 6)
    ControlsLayout.Parent = ControlsHolder

    local function CreateWindowBtn(symbol, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(26, 26)
        btn.BackgroundTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.Text = symbol
        btn.TextSize = 13
        btn.Parent = ControlsHolder
        BindTheme(btn, "TextColor3", "TextMuted", "PanelBg")
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL (50% Width in 3-side mode, 75% Width in 2-side mode)
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.25, 2, 0, 64)
    CenterPanel.Size = UDim2.new(0.50, -8, 1, -76)
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- 4. RIGHT PANEL (25% Width in 3-side mode)
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.75, 2, 0, 64)
    RightPanel.Size = UDim2.new(0.25, -14, 1, -76)
    RightPanel.BackgroundTransparency = Self.BgTransparency
    RightPanel.ClipsDescendants = true
    RightPanel.Parent = MainWindow
    BindTheme(RightPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(RightPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- Smooth Dragging on TopBar
    local dragging, dragInput, dragStart, startPos
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if Self.Flags["LockPosition"] then return end
            dragging = true
            dragStart = input.Position
            startPos = MainWindow.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Division Recalculation (.Call(2) or .Call(3))
    function Self.Call(sideCount)
        Self.SideCount = (sideCount == 2) and 2 or 3
        if Self.SideCount == 3 then
            RightPanel.Visible = true
            TweenService:Create(CenterPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0.50, -8, 1, -76)
            }):Play()
        else
            RightPanel.Visible = false
            TweenService:Create(CenterPanel, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0.75, -14, 1, -76)
            }):Play()
        end
        return Self
    end

    -- TopBar Window Buttons Logic
    CreateWindowBtn("☰", function()
        Self.Call(Self.SideCount == 3 and 2 or 3)
    end)
    local isMinimized = false
    CreateWindowBtn("—", function()
        isMinimized = not isMinimized
        LeftSidebar.Visible = not isMinimized
        CenterPanel.Visible = not isMinimized
        RightPanel.Visible = (not isMinimized and Self.SideCount == 3)
        TweenService:Create(MainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = isMinimized and UDim2.fromOffset(1020, 66) or UDim2.fromOffset(1020, 600)
        }):Play()
    end)
    local isMaximized = false
    CreateWindowBtn("□", function()
        isMaximized = not isMaximized
        TweenService:Create(MainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = isMaximized and UDim2.fromOffset(1180, 680) or UDim2.fromOffset(1020, 600)
        }):Play()
    end)
    CreateWindowBtn("✕", function()
        Self:ToggleMenu(false)
    end)

    -- Theme, Radius & Transparency Live Updaters
    function Self:SetTheme(themeName)
        if not Themes[themeName] then return end
        Self.ThemeName = themeName
        CurrentTheme = Themes[themeName]
        for _, b in ipairs(Self.ThemeBindings) do
            if b.Instance and b.Instance.Parent then
                local col = CurrentTheme[b.Key]
                if b.BgKey then
                    col = GetReadableTextColor(CurrentTheme[b.BgKey], col)
                end
                b.Instance[b.Prop] = col
            end
        end
    end

    function Self:SetRounded(state)
        Self.Rounded = state
        for _, r in ipairs(Self.RadiusBindings) do
            if r.Instance and r.Instance.Parent then
                r.Instance.CornerRadius = UDim.new(0, state and r.BaseRadius or 0)
            end
        end
    end

    function Self:SetTransparency(alpha)
        Self.BgTransparency = math.clamp(alpha, 0, 0.65)
        MainWindow.BackgroundTransparency = Self.BgTransparency
        LeftSidebar.BackgroundTransparency = Self.BgTransparency
        TopBar.BackgroundTransparency = Self.BgTransparency
        CenterPanel.BackgroundTransparency = Self.BgTransparency
        RightPanel.BackgroundTransparency = Self.BgTransparency
    end

    function Self:SetBanner(imgSource, transparency)
        Self.BannerImage = imgSource or ""
        Self.BannerTransparency = transparency or Self.BannerTransparency
        BannerLayer.Image = ResolveImage(Self.BannerImage)
        BannerLayer.ImageTransparency = (Self.BannerImage ~= "") and Self.BannerTransparency or 1
    end

    function Self:ToggleMenu(forceState)
        local nextState = (forceState ~= nil) and forceState or (not MainWindow.Visible)
        MainWindow.Visible = nextState
        FocusBlocker.Visible = nextState and Self.FocusMode
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not nextState)
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Self.ToggleKey then
            Self:ToggleMenu()
        end
    end)

    -- Optional Loading Splash Screen
    function Self:ShowLoading(titleText, subtitleText, duration)
        duration = duration or 1.6
        local Loader = Instance.new("Frame")
        Loader.Size = UDim2.fromScale(1, 1)
        Loader.BackgroundColor3 = CurrentTheme.MainBg
        Loader.ZIndex = 500
        Loader.Parent = MainWindow
        ApplySurfaceStyle(Loader, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local LoadTitle = Instance.new("TextLabel")
        LoadTitle.Size = UDim2.new(1, 0, 0, 34)
        LoadTitle.Position = UDim2.new(0, 0, 0.42, 0)
        LoadTitle.BackgroundTransparency = 1
        LoadTitle.Font = Enum.Font.GothamBlack
        LoadTitle.Text = titleText or "R&8_DV FRAMEWORK"
        LoadTitle.TextSize = 24
        LoadTitle.ZIndex = 501
        LoadTitle.Parent = Loader
        BindTheme(LoadTitle, "TextColor3", "TextPrimary", "MainBg")

        local LoadSub = Instance.new("TextLabel")
        LoadSub.Size = UDim2.new(1, 0, 0, 20)
        LoadSub.Position = UDim2.new(0, 0, 0.49, 0)
        LoadSub.BackgroundTransparency = 1
        LoadSub.Font = Enum.Font.GothamMedium
        LoadSub.Text = subtitleText or "Initializing 3-Side ImGui Canvas..."
        LoadSub.TextSize = 13
        LoadSub.ZIndex = 501
        LoadSub.Parent = Loader
        BindTheme(LoadSub, "TextColor3", "TextMuted", "MainBg")

        local BarBg = Instance.new("Frame")
        BarBg.Size = UDim2.fromOffset(280, 6)
        BarBg.Position = UDim2.new(0.5, -140, 0.57, 0)
        BarBg.ZIndex = 501
        BarBg.Parent = Loader
        BindTheme(BarBg, "BackgroundColor3", "ControlBg")
        ApplySurfaceStyle(BarBg, 4, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local BarFill = Instance.new("Frame")
        BarFill.Size = UDim2.new(0, 0, 1, 0)
        BarFill.ZIndex = 502
        BarFill.Parent = BarBg
        BindTheme(BarFill, "BackgroundColor3", "Accent")
        ApplySurfaceStyle(BarFill, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.85, Enum.EasingStyle.Quart), {
            Size = UDim2.fromScale(1, 1)
        }):Play()

        task.delay(duration, function()
            TweenService:Create(Loader, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            Loader:Destroy()
        end)
    end

    -- =========================================================================
    -- WIDGET FACTORY (SHARED BY `center()` AND `right()`)
    -- =========================================================================
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

        -- Page Header (e.g., "Home" + "Welcome back, keep going!" + Game Ready Pill)
        function Builder:Header(title, subtitle, badgeText)
            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Size = UDim2.new(1, 0, 0, 58)
            HeaderFrame.BackgroundTransparency = 1
            HeaderFrame.Parent = scrollingPage

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(0, 4, 0, 46)
            AccentBar.Position = UDim2.new(0, 0, 0, 6)
            AccentBar.Parent = HeaderFrame
            BindTheme(AccentBar, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(AccentBar, 3, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 14, 0, 4)
            TitleLbl.Size = UDim2.new(0.65, 0, 0, 28)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBold
            TitleLbl.Text = title
            TitleLbl.TextSize = 23
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = HeaderFrame
            BindTheme(TitleLbl, "TextColor3", "TextPrimary", "PanelBg")

            local SubLbl = Instance.new("TextLabel")
            SubLbl.Position = UDim2.new(0, 14, 0, 33)
            SubLbl.Size = UDim2.new(0.65, 0, 0, 18)
            SubLbl.BackgroundTransparency = 1
            SubLbl.Font = Enum.Font.Gotham
            SubLbl.Text = subtitle or ""
            SubLbl.TextSize = 12
            SubLbl.TextXAlignment = Enum.TextXAlignment.Left
            SubLbl.Parent = HeaderFrame
            BindTheme(SubLbl, "TextColor3", "TextMuted", "PanelBg")

            if badgeText then
                local Pill = Instance.new("Frame")
                Pill.Size = UDim2.fromOffset(122, 30)
                Pill.Position = UDim2.new(1, -124, 0, 12)
                Pill.Parent = HeaderFrame
                BindTheme(Pill, "BackgroundColor3", "CardBg")
                ApplySurfaceStyle(Pill, 15, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(8, 8)
                Dot.Position = UDim2.new(0, 12, 0.5, -4)
                Dot.Parent = Pill
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplySurfaceStyle(Dot, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

                local PillTxt = Instance.new("TextLabel")
                PillTxt.Position = UDim2.new(0, 26, 0, 0)
                PillTxt.Size = UDim2.new(1, -32, 1, 0)
                PillTxt.BackgroundTransparency = 1
                PillTxt.Font = Enum.Font.GothamMedium
                PillTxt.Text = badgeText
                PillTxt.TextSize = 11
                PillTxt.TextXAlignment = Enum.TextXAlignment.Left
                PillTxt.Parent = Pill
                BindTheme(PillTxt, "TextColor3", "TextPrimary", "CardBg")
            end
        end

        -- 3-Stat Row (Status / Runtime / Version Cards)
        function Builder:StatRow(statsList)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 74)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / #statsList, -8, 1, 0)
            Grid.CellPadding = UDim2.new(0, 10, 0, 0)
            Grid.Parent = Row

            local ValueLabels = {}
            for i, item in ipairs(statsList) do
                local Card = Instance.new("Frame")
                Card.Parent = Row
                BindTheme(Card, "BackgroundColor3", "CardBg")
                ApplySurfaceStyle(Card, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

                local Icon = Instance.new("TextLabel")
                Icon.Position = UDim2.new(0, 14, 0.5, -16)
                Icon.Size = UDim2.fromOffset(32, 32)
                Icon.BackgroundTransparency = 1
                Icon.Font = Enum.Font.GothamBold
                Icon.Text = IconGlyphs[item.Icon] or item.Icon or "⚡"
                Icon.TextSize = 22
                Icon.Parent = Card
                BindTheme(Icon, "TextColor3", "Accent", "CardBg")

                local Lbl = Instance.new("TextLabel")
                Lbl.Position = UDim2.new(0, 54, 0, 16)
                Lbl.Size = UDim2.new(1, -60, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.Gotham
                Lbl.Text = item.Label
                Lbl.TextSize = 11
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Card
                BindTheme(Lbl, "TextColor3", "TextMuted", "CardBg")

                local Val = Instance.new("TextLabel")
                Val.Position = UDim2.new(0, 54, 0, 34)
                Val.Size = UDim2.new(1, -60, 0, 22)
                Val.BackgroundTransparency = 1
                Val.Font = Enum.Font.GothamBold
                Val.Text = item.Value
                Val.TextSize = 15
                Val.TextXAlignment = Enum.TextXAlignment.Left
                Val.Parent = Card
                BindTheme(Val, "TextColor3", "TextPrimary", "CardBg")
                ValueLabels[i] = Val
            end
            return ValueLabels
        end

        -- Rounded Bordered Card Section (Auto-Expanding)
        function Builder:Card(title, rightActionText)
            local CardFrame = Instance.new("Frame")
            CardFrame.Size = UDim2.new(1, 0, 0, 40)
            CardFrame.AutomaticSize = Enum.AutomaticSize.Y
            CardFrame.Parent = scrollingPage
            BindTheme(CardFrame, "BackgroundColor3", "CardBg")
            ApplySurfaceStyle(CardFrame, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingTop = UDim.new(0, 12)
            Pad.PaddingBottom = UDim.new(0, 12)
            Pad.PaddingLeft = UDim.new(0, 14)
            Pad.PaddingRight = UDim2.new(0, 14).X
            Pad.Parent = CardFrame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 8)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = CardFrame

            if title then
                local TopRow = Instance.new("Frame")
                TopRow.Size = UDim2.new(1, 0, 0, 22)
                TopRow.BackgroundTransparency = 1
                TopRow.Parent = CardFrame

                local TitleTxt = Instance.new("TextLabel")
                TitleTxt.Size = UDim2.new(0.7, 0, 1, 0)
                TitleTxt.BackgroundTransparency = 1
                TitleTxt.Font = Enum.Font.GothamBold
                TitleTxt.Text = title
                TitleTxt.TextSize = 13
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
                TitleTxt.Parent = TopRow
                BindTheme(TitleTxt, "TextColor3", "TextPrimary", "CardBg")

                if rightActionText then
                    local ActionTxt = Instance.new("TextLabel")
                    ActionTxt.Size = UDim2.new(0.3, 0, 1, 0)
                    ActionTxt.Position = UDim2.new(0.7, 0, 0, 0)
                    ActionTxt.BackgroundTransparency = 1
                    ActionTxt.Font = Enum.Font.GothamMedium
                    ActionTxt.Text = rightActionText
                    ActionTxt.TextSize = 11
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right
                    ActionTxt.Parent = TopRow
                    BindTheme(ActionTxt, "TextColor3", "TextMuted", "CardBg")
                end
            end

            return CreateCanvasBuilder(CardFrame)
        end

        -- Quick Action Grid (Interactive Tile Buttons like Reference Image)
        function Builder:ActionGrid(items)
            local GridHolder = Instance.new("Frame")
            GridHolder.Size = UDim2.new(1, 0, 0, 84)
            GridHolder.AutomaticSize = Enum.AutomaticSize.Y
            GridHolder.BackgroundTransparency = 1
            GridHolder.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / math.min(#items, 6), -7, 0, 78)
            Grid.CellPadding = UDim2.new(0, 8, 0, 8)
            Grid.Parent = GridHolder

            for _, action in ipairs(items) do
                local flag = action.Flag or action.Name
                Self.Flags[flag] = action.Default or false

                local Tile = Instance.new("TextButton")
                Tile.Text = ""
                Tile.AutoButtonColor = false
                Tile.Parent = GridHolder
                BindTheme(Tile, "BackgroundColor3", "ControlBg")
                local _, tileStroke = ApplySurfaceStyle(Tile, 9, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

                local Icon = Instance.new("TextLabel")
                Icon.Size = UDim2.new(1, 0, 0, 34)
                Icon.Position = UDim2.new(0, 0, 0, 12)
                Icon.BackgroundTransparency = 1
                Icon.Font = Enum.Font.GothamBold
                Icon.Text = IconGlyphs[action.Icon] or action.Icon or "⚡"
                Icon.TextSize = 20
                Icon.Parent = Tile
                BindTheme(Icon, "TextColor3", "Accent", "ControlBg")

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -6, 0, 18)
                Lbl.Position = UDim2.new(0, 3, 1, -24)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamMedium
                Lbl.Text = action.Name
                Lbl.TextSize = 10
                Lbl.Parent = Tile
                BindTheme(Lbl, "TextColor3", "TextPrimary", "ControlBg")

                Tile.MouseButton1Click:Connect(function()
                    local nextVal = not Self.Flags[flag]
                    Self:SetValue(flag, nextVal)
                    tileStroke.Color = nextVal and CurrentTheme.Accent or CurrentTheme.Stroke
                    tileStroke.Transparency = nextVal and 0 or 0.25
                    if action.Callback then task.spawn(action.Callback, nextVal) end
                end)
            end
        end

        -- Section Subheader (Used in Right Settings Panel)
        function Builder:Section(text)
            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, 0, 0, 22)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBold
            Lbl.Text = text
            Lbl.TextSize = 12
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = scrollingPage
            BindTheme(Lbl, "TextColor3", "TextPrimary", "PanelBg")
        end

        -- Toggle Switch (Checkbox / Switch)
        function Builder:Toggle(label, flag, default, callback)
            Self.Flags[flag] = (default == true)

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 28)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -52, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamMedium
            Title.Text = label
            Title.TextSize = 12
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextMuted", "PanelBg")

            local SwitchBg = Instance.new("TextButton")
            SwitchBg.Size = UDim2.fromOffset(38, 20)
            SwitchBg.Position = UDim2.new(1, -38, 0.5, -10)
            SwitchBg.Text = ""
            SwitchBg.AutoButtonColor = false
            SwitchBg.Parent = Row
            BindTheme(SwitchBg, "BackgroundColor3", default and "Accent" or "ControlBg")
            ApplySurfaceStyle(SwitchBg, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.fromOffset(14, 14)
            Knob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            Knob.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
            Knob.Parent = SwitchBg
            ApplySurfaceStyle(Knob, 7, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local function UpdateVisual(val)
                SwitchBg.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                TweenService:Create(Knob, TweenInfo.new(0.16, Enum.EasingStyle.Quart), {
                    Position = val and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                }):Play()
            end

            SwitchBg.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                UpdateVisual(nextVal)
                if callback then task.spawn(callback, nextVal) end
            end)
        end

        -- Interactive Slider
        function Builder:Slider(label, flag, min, max, default, suffix, callback)
            suffix = suffix or ""
            Self.Flags[flag] = default or min

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.42, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamMedium
            Title.Text = label
            Title.TextSize = 12
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextMuted", "PanelBg")

            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(0.38, 0, 0, 5)
            Track.Position = UDim2.new(0.43, 0, 0.5, -2)
            Track.Text = ""
            Track.AutoButtonColor = false
            Track.Parent = Row
            BindTheme(Track, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(Track, 3, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local initPct = math.clamp((Self.Flags[flag] - min) / (max - min), 0, 1)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(initPct, 0, 1, 0)
            Fill.Parent = Track
            BindTheme(Fill, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(Fill, 3, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

            local ValTxt = Instance.new("TextLabel")
            ValTxt.Size = UDim2.new(0.18, 0, 1, 0)
            ValTxt.Position = UDim2.new(0.82, 0, 0, 0)
            ValTxt.BackgroundTransparency = 1
            ValTxt.Font = Enum.Font.GothamBold
            ValTxt.Text = tostring(Self.Flags[flag]) .. suffix
            ValTxt.TextSize = 11
            ValTxt.TextXAlignment = Enum.TextXAlignment.Right
            ValTxt.Parent = Row
            BindTheme(ValTxt, "TextColor3", "TextPrimary", "PanelBg")

            local sliding = false
            local function UpdateFromInput(input)
                local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pct)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                ValTxt.Text = tostring(value) .. suffix
                Self:SetValue(flag, value)
                if callback then task.spawn(callback, value) end
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    UpdateFromInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end)
        end

        -- Up/Down Interactive Value Stepper
        function Builder:Stepper(label, flag, default, step, callback)
            step = step or 1
            Self.Flags[flag] = default or 0

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.55, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamMedium
            Title.Text = label
            Title.TextSize = 12
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextMuted", "PanelBg")

            local Controls = Instance.new("Frame")
            Controls.Size = UDim2.fromOffset(96, 24)
            Controls.Position = UDim2.new(1, -96, 0.5, -12)
            Controls.Parent = Row
            BindTheme(Controls, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(Controls, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local Minus = Instance.new("TextButton")
            Minus.Size = UDim2.new(0, 26, 1, 0)
            Minus.BackgroundTransparency = 1
            Minus.Font = Enum.Font.GothamBold
            Minus.Text = "-"
            Minus.TextSize = 14
            Minus.Parent = Controls
            BindTheme(Minus, "TextColor3", "TextPrimary", "ControlBg")

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Size = UDim2.new(1, -52, 1, 0)
            ValLbl.Position = UDim2.new(0, 26, 0, 0)
            ValLbl.BackgroundTransparency = 1
            ValLbl.Font = Enum.Font.GothamBold
            ValLbl.Text = tostring(Self.Flags[flag])
            ValLbl.TextSize = 11
            ValLbl.Parent = Controls
            BindTheme(ValLbl, "TextColor3", "Accent", "ControlBg")

            local Plus = Instance.new("TextButton")
            Plus.Size = UDim2.new(0, 26, 1, 0)
            Plus.Position = UDim2.new(1, -26, 0, 0)
            Plus.BackgroundTransparency = 1
            Plus.Font = Enum.Font.GothamBold
            Plus.Text = "+"
            Plus.TextSize = 14
            Plus.Parent = Controls
            BindTheme(Plus, "TextColor3", "TextPrimary", "ControlBg")

            Minus.MouseButton1Click:Connect(function()
                local v = Self.Flags[flag] - step
                ValLbl.Text = tostring(v)
                Self:SetValue(flag, v)
                if callback then task.spawn(callback, v) end
            end)
            Plus.MouseButton1Click:Connect(function()
                local v = Self.Flags[flag] + step
                ValLbl.Text = tostring(v)
                Self:SetValue(flag, v)
                if callback then task.spawn(callback, v) end
            end)
        end

        -- Dropdown / Radio Selector
        function Builder:Dropdown(label, flag, options, default, callback)
            Self.Flags[flag] = default or options[1]
            local idx = table.find(options, Self.Flags[flag]) or 1

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.45, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamMedium
            Title.Text = label
            Title.TextSize = 12
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextMuted", "PanelBg")

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.52, 0, 0, 24)
            DropBtn.Position = UDim2.new(0.48, 0, 0.5, -12)
            DropBtn.Font = Enum.Font.GothamMedium
            DropBtn.Text = tostring(Self.Flags[flag]) .. "  ▾"
            DropBtn.TextSize = 11
            DropBtn.AutoButtonColor = false
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            BindTheme(DropBtn, "TextColor3", "TextPrimary", "ControlBg")
            ApplySurfaceStyle(DropBtn, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            DropBtn.MouseButton1Click:Connect(function()
                idx = (idx % #options) + 1
                local chosen = options[idx]
                DropBtn.Text = tostring(chosen) .. "  ▾"
                Self:SetValue(flag, chosen)
                if callback then task.spawn(callback, chosen) end
            end)
        end

        --Readable TextBox Input (Fixes Small/Unreadable Input Problem)
        function Builder:Input(label, flag, placeholder, default, callback)
            Self.Flags[flag] = default or ""

            local BoxHolder = Instance.new("Frame")
            BoxHolder.Size = UDim2.new(1, 0, 0, 34)
            BoxHolder.BackgroundTransparency = 1
            BoxHolder.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.4, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamMedium
            Title.Text = label
            Title.TextSize = 12
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = BoxHolder
            BindTheme(Title, "TextColor3", "TextMuted", "PanelBg")

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0.58, 0, 0, 28)
            InputBox.Position = UDim2.new(0.42, 0, 0.5, -14)
            InputBox.Font = Enum.Font.GothamMedium
            InputBox.PlaceholderText = placeholder or "Enter value..."
            InputBox.Text = Self.Flags[flag]
            InputBox.TextSize = 12
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = BoxHolder
            BindTheme(InputBox, "BackgroundColor3", "ControlBg")
            BindTheme(InputBox, "TextColor3", "TextPrimary", "ControlBg")
            BindTheme(InputBox, "PlaceholderColor3", "TextMuted", "ControlBg")
            ApplySurfaceStyle(InputBox, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            InputBox.FocusLost:Connect(function()
                Self:SetValue(flag, InputBox.Text)
                if callback then task.spawn(callback, InputBox.Text) end
            end)
        end

        -- Timeline / Activity Log Item
        function Builder:ActivityTimeline(entries)
            for _, item in ipairs(entries) do
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 24)
                Row.BackgroundTransparency = 1
                Row.Parent = scrollingPage

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(7, 7)
                Dot.Position = UDim2.new(0, 4, 0.5, -3)
                Dot.Parent = Row
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplySurfaceStyle(Dot, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

                local EventTxt = Instance.new("TextLabel")
                EventTxt.Position = UDim2.new(0, 22, 0, 0)
                EventTxt.Size = UDim2.new(0.7, 0, 1, 0)
                EventTxt.BackgroundTransparency = 1
                EventTxt.Font = Enum.Font.GothamMedium
                EventTxt.Text = item.Text
                EventTxt.TextSize = 12
                EventTxt.TextXAlignment = Enum.TextXAlignment.Left
                EventTxt.Parent = Row
                BindTheme(EventTxt, "TextColor3", "TextPrimary", "CardBg")

                local TimeTxt = Instance.new("TextLabel")
                TimeTxt.Position = UDim2.new(0.72, 0, 0, 0)
                TimeTxt.Size = UDim2.new(0.28, 0, 1, 0)
                TimeTxt.BackgroundTransparency = 1
                TimeTxt.Font = Enum.Font.Gotham
                TimeTxt.Text = item.Time
                TimeTxt.TextSize = 11
                TimeTxt.TextXAlignment = Enum.TextXAlignment.Right
                TimeTxt.Parent = Row
                BindTheme(TimeTxt, "TextColor3", "TextMuted", "CardBg")
            end
        end

        return Builder
    end

    -- =========================================================================
    -- DECLARATIVE DSL: `feature(Logo, name)({ center = ..., right = ... })`
    -- =========================================================================
    local function CreateScrollPage(parent)
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.fromScale(1, 1)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Visible = false
        Page.Parent = parent
        BindTheme(Page, "ScrollBarImageColor3", "Accent")

        local Pad = Instance.new("UIPadding")
        Pad.PaddingTop = UDim.new(0, 16)
        Pad.PaddingBottom = UDim.new(0, 16)
        Pad.PaddingLeft = UDim.new(0, 16)
        Pad.PaddingRight = UDim.new(0, 16)
        Pad.Parent = Page

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 12)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Page
        return Page
    end

    function Self.feature(logo, name)
        local CenterPage = CreateScrollPage(CenterPanel)
        local RightPage = CreateScrollPage(RightPanel)

        -- Sidebar Button
        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(1, 0, 0, 38)
        NavBtn.BackgroundTransparency = 1
        NavBtn.Text = ""
        NavBtn.AutoButtonColor = false
        NavBtn.Parent = NavScroll
        ApplySurfaceStyle(NavBtn, 8, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local IconLbl = Instance.new("TextLabel")
        IconLbl.Position = UDim2.new(0, 12, 0.5, -10)
        IconLbl.Size = UDim2.fromOffset(20, 20)
        IconLbl.BackgroundTransparency = 1
        IconLbl.Font = Enum.Font.GothamBold
        IconLbl.Text = IconGlyphs[logo] or logo or "•"
        IconLbl.TextSize = 15
        IconLbl.Parent = NavBtn
        BindTheme(IconLbl, "TextColor3", "TextMuted", "PanelBg")

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Position = UDim2.new(0, 42, 0, 0)
        NameLbl.Size = UDim2.new(1, -48, 1, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Font = Enum.Font.GothamMedium
        NameLbl.Text = name
        NameLbl.TextSize = 13
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.Parent = NavBtn
        BindTheme(NameLbl, "TextColor3", "TextMuted", "PanelBg")

        local ActiveLine = Instance.new("Frame")
        ActiveLine.Size = UDim2.new(0.84, 0, 0, 2)
        ActiveLine.Position = UDim2.new(0.08, 0, 1, -2)
        ActiveLine.Visible = false
        ActiveLine.Parent = NavBtn
        BindTheme(ActiveLine, "BackgroundColor3", "Accent")

        local FeatureObj = {
            Name = name,
            CenterPage = CenterPage,
            RightPage = RightPage,
            NavBtn = NavBtn,
            ActiveLine = ActiveLine,
            NameLbl = NameLbl,
            IconLbl = IconLbl,
            HasCustomRight = false
        }
        table.insert(Self.Features, FeatureObj)

        local function ActivateFeature()
            for _, f in ipairs(Self.Features) do
                f.CenterPage.Visible = false
                if f.HasCustomRight then f.RightPage.Visible = false end
                f.ActiveLine.Visible = false
                f.NavBtn.BackgroundTransparency = 1
                f.NameLbl.Font = Enum.Font.GothamMedium
            end
            CenterPage.Visible = true
            if FeatureObj.HasCustomRight then
                RightPage.Visible = true
            elseif Self.Features[1] then
                Self.Features[1].RightPage.Visible = true
            end
            ActiveLine.Visible = true
            NavBtn.BackgroundTransparency = 0.88
            NameLbl.Font = Enum.Font.GothamBold
            Self.ActiveFeature = FeatureObj
        end

        NavBtn.MouseButton1Click:Connect(ActivateFeature)
        if #Self.Features == 1 then ActivateFeature() end

        -- Curried block handler supporting `feature(Logo, name)({ center = ..., right = ... })`
        return function(definition)
            if type(definition) == "table" then
                if type(definition.center) == "function" then
                    definition.center(CreateCanvasBuilder(CenterPage))
                end
                if type(definition.right) == "function" then
                    FeatureObj.HasCustomRight = true
                    definition.right(CreateCanvasBuilder(RightPage))
                    if Self.ActiveFeature == FeatureObj then
                        RightPage.Visible = true
                    end
                end
            end
            return FeatureObj
        end
    end

    return Self
end

return ImGui