--[[
    FRAMEWORK : R&8_DV ImGui Architecture (v4.0 - Pure Vector & Auto-Asset Edition)
    COPYRIGHT : R&8_DV
    ASSET     : Hardcoded GitHub Auto-Fetch + Procedural Lucide Vector Icons (Zero Emoji / Zero [] Bug)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // HARDCODED MASTER LOGO DARI GITHUB //
local MASTER_LOGO_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Assets/icons.png"
local MASTER_CACHE_FILE = "R8DV_MasterLogo_v4.png"

local function GetSafeGuiParent()
    local ok, res = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if ok and res then return res end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- // AUTO-DOWNLOADER & ASSET RESOLVER //
local AssetCache = {}
local function ResolveImage(source)
    if not source or source == "" then return "" end
    if string.find(source, "^rbxassetid://") or string.find(source, "^rbxthumb://") then
        return source
    end
    if AssetCache[source] then return AssetCache[source] end

    local getAsset = getcustomasset or getsynasset
    if getAsset and writefile and isfile then
        local ok, assetId = pcall(function()
            if string.find(source, "^https?://") then
                local fileName = (source == MASTER_LOGO_URL) and MASTER_CACHE_FILE or ("R8DV_Cache_" .. tostring(#source * 17) .. ".png")
                if not isfile(fileName) then
                    local raw = game:HttpGet(source, true)
                    if raw and #raw > 0 then
                        writefile(fileName, raw)
                    end
                end
                if isfile(fileName) then
                    return getAsset(fileName)
                end
            elseif isfile(source) then
                return getAsset(source)
            end
            return ""
        end)
        if ok and assetId and assetId ~= "" then
            AssetCache[source] = assetId
            return assetId
        end
    end
    return ""
end

-- // CONTRAST GUARD (MENCEGAH TEKS GELAP DI ATAS BACKGROUND GELAP) //
local function GetReadableTextColor(bgColor, preferredTextColor)
    local function lum(c)
        return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    end
    if math.abs(lum(bgColor) - lum(preferredTextColor)) < 0.35 then
        return lum(bgColor) > 0.5 and Color3.fromRGB(18, 20, 26) or Color3.fromRGB(242, 245, 252)
    end
    return preferredTextColor
end

-- // PALET TEMA WARNA //
local Themes = {
    ["Blue Night Sky"] = {
        MainBg      = Color3.fromRGB(13, 15, 23),
        PanelBg     = Color3.fromRGB(18, 21, 32),
        CardBg      = Color3.fromRGB(24, 28, 42),
        ControlBg   = Color3.fromRGB(32, 38, 56),
        Accent      = Color3.fromRGB(98, 137, 255),
        Stroke      = Color3.fromRGB(45, 53, 78),
        TextPrimary = Color3.fromRGB(240, 244, 255),
        TextMuted   = Color3.fromRGB(142, 152, 178)
    },
    ["Orange Sand"] = {
        MainBg      = Color3.fromRGB(24, 19, 16),
        PanelBg     = Color3.fromRGB(33, 26, 22),
        CardBg      = Color3.fromRGB(43, 34, 29),
        ControlBg   = Color3.fromRGB(58, 46, 39),
        Accent      = Color3.fromRGB(245, 148, 66),
        Stroke      = Color3.fromRGB(78, 61, 50),
        TextPrimary = Color3.fromRGB(252, 243, 235),
        TextMuted   = Color3.fromRGB(184, 162, 145)
    },
    ["Midnight Monokai"] = {
        MainBg      = Color3.fromRGB(19, 20, 17),
        PanelBg     = Color3.fromRGB(27, 28, 24),
        CardBg      = Color3.fromRGB(36, 37, 32),
        ControlBg   = Color3.fromRGB(48, 50, 43),
        Accent      = Color3.fromRGB(166, 226, 46),
        Stroke      = Color3.fromRGB(64, 66, 56),
        TextPrimary = Color3.fromRGB(248, 248, 242),
        TextMuted   = Color3.fromRGB(145, 148, 135)
    }
}

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

-- =========================================================================
-- PROCEDURAL LUCIDE VECTOR ICON ENGINE (ZERO EMOJI & ANTI-BUG KOTAK [])
-- =========================================================================
local function DrawVectorIcon(parent, iconName, sizePx, themeKey, bindThemeFn)
    local Holder = Instance.new("Frame")
    Holder.Name = "VectorIcon_" .. tostring(iconName)
    Holder.Size = UDim2.fromOffset(sizePx, sizePx)
    Holder.BackgroundTransparency = 1
    Holder.Parent = parent

    local function Line(w, h, posX, posY, rot, radius)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromScale(posX, posY)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Rotation = rot or 0
        f.BorderSizePixel = 0
        f.Parent = Holder
        bindThemeFn(f, "BackgroundColor3", themeKey)
        if radius then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius)
            c.Parent = f
        end
        return f
    end

    local function Ring(w, h, posX, posY, radius, thickness, rot)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromScale(posX, posY)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundTransparency = 1
        f.Rotation = rot or 0
        f.Parent = Holder
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 4)
        c.Parent = f
        local s = Instance.new("UIStroke")
        s.Thickness = thickness or 1.8
        s.Parent = f
        bindThemeFn(s, "Color", themeKey)
        return f
    end

    local key = string.lower(tostring(iconName or "dot"))

    if key == "home" then
        Line(sizePx * 0.55, 2, 0.32, 0.30, -40, 1)
        Line(sizePx * 0.55, 2, 0.68, 0.30, 40, 1)
        Ring(sizePx * 0.62, sizePx * 0.48, 0.5, 0.64, 3, 1.8)
    elseif key == "autofarm" or key == "rocket" then
        Ring(sizePx * 0.46, sizePx * 0.46, 0.5, 0.5, 4, 1.8, 45)
        Line(sizePx * 0.22, sizePx * 0.22, 0.5, 0.5, 45, 2)
        Line(sizePx * 0.32, 2, 0.26, 0.74, -45, 1)
    elseif key == "teleports" or key == "teleport" or key == "pin" then
        Ring(sizePx * 0.58, sizePx * 0.58, 0.5, 0.42, sizePx, 1.8)
        Line(4, 4, 0.5, 0.42, 0, 2)
        Line(sizePx * 0.30, 2, 0.42, 0.76, 55, 1)
        Line(sizePx * 0.30, 2, 0.58, 0.76, -55, 1)
    elseif key == "player" or key == "user" then
        Ring(sizePx * 0.38, sizePx * 0.38, 0.5, 0.32, sizePx, 1.8)
        Ring(sizePx * 0.68, sizePx * 0.34, 0.5, 0.76, 6, 1.8)
    elseif key == "visuals" or key == "esp" or key == "eye" then
        Ring(sizePx * 0.82, sizePx * 0.46, 0.5, 0.5, sizePx, 1.8)
        Line(sizePx * 0.24, sizePx * 0.24, 0.5, 0.5, 0, sizePx)
    elseif key == "misc" or key == "settings" or key == "gear" then
        Ring(sizePx * 0.56, sizePx * 0.56, 0.5, 0.5, sizePx, 2)
        Line(sizePx * 0.82, 2, 0.5, 0.5, 0, 1)
        Line(sizePx * 0.82, 2, 0.5, 0.5, 90, 1)
        Line(sizePx * 0.82, 2, 0.5, 0.5, 45, 1)
        Line(sizePx * 0.82, 2, 0.5, 0.5, -45, 1)
        Line(sizePx * 0.24, sizePx * 0.24, 0.5, 0.5, 0, sizePx)
    elseif key == "sliders" then
        Line(sizePx * 0.76, 2, 0.5, 0.28, 0, 1)
        Line(4, 6, 0.35, 0.28, 0, 2)
        Line(sizePx * 0.76, 2, 0.5, 0.52, 0, 1)
        Line(4, 6, 0.68, 0.52, 0, 2)
        Line(sizePx * 0.76, 2, 0.5, 0.76, 0, 1)
        Line(4, 6, 0.45, 0.76, 0, 2)
    elseif key == "bolt" then
        Line(sizePx * 0.48, 2.2, 0.46, 0.34, -55, 1)
        Line(sizePx * 0.36, 2.2, 0.50, 0.50, 0, 1)
        Line(sizePx * 0.48, 2.2, 0.54, 0.66, -55, 1)
    elseif key == "clock" then
        Ring(sizePx * 0.76, sizePx * 0.76, 0.5, 0.5, sizePx, 1.8)
        Line(2, sizePx * 0.26, 0.5, 0.40, 0, 1)
        Line(sizePx * 0.22, 2, 0.58, 0.54, 25, 1)
    elseif key == "shield" then
        Ring(sizePx * 0.66, sizePx * 0.74, 0.5, 0.5, 5, 1.8)
        Line(2, sizePx * 0.38, 0.5, 0.5, 0, 1)
    elseif key == "speed" or key == "gauge" then
        Ring(sizePx * 0.78, sizePx * 0.78, 0.5, 0.54, sizePx, 1.8)
        Line(sizePx * 0.34, 2, 0.58, 0.46, -35, 1)
    elseif key == "jump" or key == "arrowup" then
        Line(2, sizePx * 0.64, 0.5, 0.54, 0, 1)
        Line(sizePx * 0.36, 2, 0.39, 0.32, -45, 1)
        Line(sizePx * 0.36, 2, 0.61, 0.32, 45, 1)
    elseif key == "collect" or key == "layers" then
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.38, 3, 1.6, 45)
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.60, 3, 1.6, 45)
    elseif key == "menu" then
        Line(14, 2, 0.5, 0.30, 0, 1)
        Line(14, 2, 0.5, 0.50, 0, 1)
        Line(10, 2, 0.4, 0.70, 0, 1)
    elseif key == "minimize" then
        Line(12, 2, 0.5, 0.5, 0, 1)
    elseif key == "maximize" then
        Ring(11, 11, 0.5, 0.5, 2, 1.6)
    elseif key == "close" then
        Line(14, 2, 0.5, 0.5, 45, 1)
        Line(14, 2, 0.5, 0.5, -45, 1)
    elseif key == "chevrondown" then
        Line(6, 1.8, 0.38, 0.5, 40, 1)
        Line(6, 1.8, 0.62, 0.5, -40, 1)
    elseif key == "arrowright" then
        Line(8, 1.8, 0.45, 0.5, 0, 1)
        Line(5, 1.8, 0.68, 0.38, 40, 1)
        Line(5, 1.8, 0.68, 0.62, -40, 1)
    else
        Ring(sizePx * 0.45, sizePx * 0.45, 0.5, 0.5, 3, 1.8, 45)
    end

    return Holder
end

-- // KONSTRUKTOR UTAMA IMGUI //
local function ImGui(config)
    config = config or {}
    local Self = {
        Title = config.Title or "DRY CURSED  -  IMGUI",
        Copyright = "R&8_DV",
        ThemeName = config.Theme or "Blue Night Sky",
        Rounded = (config.Rounded ~= false),
        SideCount = 3,
        UIScale = config.Scale or 1,
        BgTransparency = config.Transparency or 0.06,
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.82,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode ~= false),
        AutoLoading = (config.AutoLoading ~= false),
        IsMinimized = false,
        Flags = {},
        FlagListeners = {},
        Features = {},
        ActiveFeature = nil,
        ThemeBindings = {},
        RadiusBindings = {}
    }

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Blue Night Sky"]

    -- Otomatis tarik & cache logo utama dari GitHub di dalam framework
    local ResolvedMasterLogo = ResolveImage(MASTER_LOGO_URL)

    function Self:SetValue(flag, value)
        Self.Flags[flag] = value
        if Self.FlagListeners[flag] then
            for _, cb in ipairs(Self.FlagListeners[flag]) do
                task.spawn(cb, value)
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
    ScreenGui.Name = "R8_DV_Engine_" .. HttpService:GenerateGUID(false):sub(1, 6)
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = GetSafeGuiParent()

    -- Focus Mode Blocker
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

    -- =========================================================================
    -- FLOATING SQUIRCLE MINIMIZE ICON (OTOMATIS DI FRAMEWORK)
    -- =========================================================================
    local MinimizeIconBtn = Instance.new("ImageButton")
    MinimizeIconBtn.Name = "R8DV_FloatingSquircle"
    MinimizeIconBtn.Size = UDim2.fromOffset(64, 64)
    MinimizeIconBtn.Position = UDim2.new(0, 48, 0.5, 0)
    MinimizeIconBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIconBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
    MinimizeIconBtn.AutoButtonColor = false
    MinimizeIconBtn.Image = ""
    MinimizeIconBtn.Visible = false
    MinimizeIconBtn.ZIndex = 800
    MinimizeIconBtn.Parent = ScreenGui

    local MinOuterCorner = Instance.new("UICorner")
    MinOuterCorner.CornerRadius = UDim.new(0.28, 0)
    MinOuterCorner.Parent = MinimizeIconBtn

    local MinBgGrad = Instance.new("UIGradient")
    MinBgGrad.Rotation = 45
    MinBgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 41, 60)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(16, 20, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 12, 18))
    })
    MinBgGrad.Parent = MinimizeIconBtn

    local MinOuterStroke = Instance.new("UIStroke")
    MinOuterStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MinOuterStroke.Thickness = 2
    MinOuterStroke.Color = Color3.fromRGB(8, 10, 16)
    MinOuterStroke.Parent = MinimizeIconBtn

    local MinInnerBezel = Instance.new("Frame")
    MinInnerBezel.Size = UDim2.new(1, -6, 1, -6)
    MinInnerBezel.Position = UDim2.fromScale(0.5, 0.5)
    MinInnerBezel.AnchorPoint = Vector2.new(0.5, 0.5)
    MinInnerBezel.BackgroundTransparency = 1
    MinInnerBezel.ZIndex = 801
    MinInnerBezel.Parent = MinimizeIconBtn

    local MinInnerCorner = Instance.new("UICorner")
    MinInnerCorner.CornerRadius = UDim.new(0.25, 0)
    MinInnerCorner.Parent = MinInnerBezel

    local MinInnerStroke = Instance.new("UIStroke")
    MinInnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MinInnerStroke.Thickness = 1.6
    MinInnerStroke.Color = Color3.fromRGB(205, 220, 248)
    MinInnerStroke.Parent = MinInnerBezel

    local BezelGrad = Instance.new("UIGradient")
    BezelGrad.Rotation = 65
    BezelGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(225, 236, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(95, 112, 148)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(195, 212, 245))
    })
    BezelGrad.Parent = MinInnerStroke

    local MinEmblemImg = Instance.new("ImageLabel")
    MinEmblemImg.Size = UDim2.fromScale(0.84, 0.84)
    MinEmblemImg.Position = UDim2.fromScale(0.5, 0.5)
    MinEmblemImg.AnchorPoint = Vector2.new(0.5, 0.5)
    MinEmblemImg.BackgroundTransparency = 1
    MinEmblemImg.ScaleType = Enum.ScaleType.Fit
    MinEmblemImg.Image = ResolvedMasterLogo
    MinEmblemImg.ZIndex = 802
    MinEmblemImg.Parent = MinimizeIconBtn

    if ResolvedMasterLogo == "" then
        local fbVec = DrawVectorIcon(MinimizeIconBtn, "AutoFarm", 30, "Accent", BindTheme)
        fbVec.Position = UDim2.fromScale(0.5, 0.5)
        fbVec.AnchorPoint = Vector2.new(0.5, 0.5)
        fbVec.ZIndex = 803
    end

    -- =========================================================================
    -- MAIN WINDOW CONTAINER
    -- =========================================================================
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

    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainWindow

    local function ComputeTargetScale()
        local cam = workspace.CurrentCamera
        if not cam then return 1 end
        local vp = cam.ViewportSize
        local autoFit = math.min(1, (vp.X * 0.94) / 1020, (vp.Y * 0.92) / 600)
        return math.clamp(autoFit * Self.UIScale, 0.42, 1.5)
    end

    local function UpdateResponsiveScale()
        if not Self.IsMinimized then
            WindowScale.Scale = ComputeTargetScale()
        end
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(UpdateResponsiveScale)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
    end
    UpdateResponsiveScale()

    -- Custom Banner Layer
    local BannerLayer = Instance.new("ImageLabel")
    BannerLayer.Name = "CustomBanner"
    BannerLayer.Size = UDim2.fromScale(1, 1)
    BannerLayer.BackgroundTransparency = 1
    BannerLayer.ScaleType = Enum.ScaleType.Crop
    BannerLayer.Image = ResolveImage(Self.BannerImage)
    BannerLayer.ImageTransparency = Self.BannerImage ~= "" and Self.BannerTransparency or 1
    BannerLayer.Parent = MainWindow
    ApplySurfaceStyle(BannerLayer, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- Watermark Copyright R&8_DV (Murni ASCII, Tanpa Risiko [])
    local Watermark = Instance.new("TextLabel")
    Watermark.Size = UDim2.new(0, 160, 0, 16)
    Watermark.Position = UDim2.new(1, -168, 1, -18)
    Watermark.BackgroundTransparency = 1
    Watermark.Font = Enum.Font.GothamBold
    Watermark.Text = "(C) " .. Self.Copyright .. " ENGINE"
    Watermark.TextSize = 10
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    Watermark.TextTransparency = 0.45
    Watermark.Parent = MainWindow
    BindTheme(Watermark, "TextColor3", "TextMuted", "MainBg")

    -- 1. LEFT SIDEBAR (25%)
    local LeftSidebar = Instance.new("Frame")
    LeftSidebar.Name = "LeftSidebar"
    LeftSidebar.Position = UDim2.new(0, 12, 0, 12)
    LeftSidebar.Size = UDim2.new(0.25, -18, 1, -24)
    LeftSidebar.BackgroundTransparency = Self.BgTransparency
    LeftSidebar.Parent = MainWindow
    BindTheme(LeftSidebar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(LeftSidebar, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = UDim2.new(1, 0, 0, 130)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(86, 86)
    BrandLogo.Position = UDim2.fromScale(0.5, 0.52)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolvedMasterLogo
    BrandLogo.Parent = LogoHolder

    if ResolvedMasterLogo == "" then
        local fallbackCrest = DrawVectorIcon(LogoHolder, "AutoFarm", 48, "Accent", BindTheme)
        fallbackCrest.Position = UDim2.fromScale(0.5, 0.52)
        fallbackCrest.AnchorPoint = Vector2.new(0.5, 0.5)
    end

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

    -- 2. TOP IMGUI HEADER BAR
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.25, 2, 0, 12)
    TopBar.Size = UDim2.new(0.75, -14, 0, 42)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local TopLogoIcon = Instance.new("ImageLabel")
    TopLogoIcon.Position = UDim2.new(0, 14, 0.5, -10)
    TopLogoIcon.Size = UDim2.fromOffset(20, 20)
    TopLogoIcon.BackgroundTransparency = 1
    TopLogoIcon.ScaleType = Enum.ScaleType.Fit
    TopLogoIcon.Image = ResolvedMasterLogo
    TopLogoIcon.Parent = TopBar

    if ResolvedMasterLogo == "" then
        local vecTop = DrawVectorIcon(TopBar, "Layers", 18, "Accent", BindTheme)
        vecTop.Position = UDim2.new(0, 14, 0.5, -9)
    end

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Position = UDim2.new(0, 42, 0, 0)
    TopTitle.Size = UDim2.new(0.6, 0, 1, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Font = Enum.Font.GothamBold
    TopTitle.Text = Self.Title .. "   |   " .. Self.Copyright
    TopTitle.TextSize = 12
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    BindTheme(TopTitle, "TextColor3", "TextPrimary", "PanelBg")

    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Position = UDim2.new(1, -138, 0, 0)
    ControlsHolder.Size = UDim2.new(0, 130, 1, 0)
    ControlsHolder.BackgroundTransparency = 1
    ControlsHolder.Parent = TopBar

    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 6)
    ControlsLayout.Parent = ControlsHolder

    -- Tombol Window Menggunakan Ikon Vektor Murni (Bebas Risiko Kotak [])
    local function CreateVectorWindowBtn(vectorType, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(26, 26)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ControlsHolder
        local icon = DrawVectorIcon(btn, vectorType, 16, "TextMuted", BindTheme)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL (50% di mode 3-sisi, 75% di mode 2-sisi)
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.25, 2, 0, 64)
    CenterPanel.Size = UDim2.new(0.50, -8, 1, -76)
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- 4. RIGHT PANEL (25% di mode 3-sisi)
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.75, 2, 0, 64)
    RightPanel.Size = UDim2.new(0.25, -14, 1, -76)
    RightPanel.BackgroundTransparency = Self.BgTransparency
    RightPanel.ClipsDescendants = true
    RightPanel.Parent = MainWindow
    BindTheme(RightPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(RightPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- Dragging Jendela Utama
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

    -- =========================================================================
    -- LOGIKA OTOMATIS MINIMIZE (-) & CLOSE (X) KE FLOATING ICON
    -- =========================================================================
    function Self:MinimizeToIcon()
        if Self.IsMinimized then return end
        Self.IsMinimized = true
        FocusBlocker.Visible = false
        pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        end)

        local shrink = TweenService:Create(WindowScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Scale = 0
        })
        shrink:Play()
        shrink.Completed:Connect(function()
            if Self.IsMinimized then
                MainWindow.Visible = false
                MinimizeIconBtn.Size = UDim2.fromOffset(0, 0)
                MinimizeIconBtn.Visible = true
                TweenService:Create(MinimizeIconBtn, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(64, 64)
                }):Play()
            end
        end)
    end

    function Self:RestoreFromIcon()
        if not Self.IsMinimized then return end
        Self.IsMinimized = false

        local hideIcon = TweenService:Create(MinimizeIconBtn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        })
        hideIcon:Play()
        hideIcon.Completed:Connect(function()
            if not Self.IsMinimized then
                MinimizeIconBtn.Visible = false
                MainWindow.Visible = true
                FocusBlocker.Visible = Self.FocusMode
                pcall(function()
                    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
                end)
                TweenService:Create(WindowScale, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Scale = ComputeTargetScale()
                }):Play()
            end
        end)
    end

    function Self:ToggleMenu(forceState)
        local shouldOpen = (forceState ~= nil) and forceState or Self.IsMinimized
        if shouldOpen then
            Self:RestoreFromIcon()
        else
            Self:MinimizeToIcon()
        end
    end

    -- Smart Drag vs Click pada Floating Squircle Icon
    local iconDragging, iconDragInput, iconDragStart, iconStartPos
    local movedDist = 0

    MinimizeIconBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            iconDragging = true
            movedDist = 0
            iconDragStart = input.Position
            iconStartPos = MinimizeIconBtn.Position
            TweenService:Create(MinimizeIconBtn, TweenInfo.new(0.12), {Size = UDim2.fromOffset(58, 58)}):Play()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    iconDragging = false
                    TweenService:Create(MinimizeIconBtn, TweenInfo.new(0.15), {Size = UDim2.fromOffset(64, 64)}):Play()
                    if movedDist < 6 then
                        Self:RestoreFromIcon()
                    end
                end
            end)
        end
    end)
    MinimizeIconBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            iconDragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == iconDragInput and iconDragging then
            local delta = input.Position - iconDragStart
            movedDist = delta.Magnitude
            MinimizeIconBtn.Position = UDim2.new(
                iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
                iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Division Switcher (.Call(2) atau .Call(3))
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

    -- Pasang 4 Tombol Window Vektor di TopBar
    CreateVectorWindowBtn("Menu", function()
        Self.Call(Self.SideCount == 3 and 2 or 3)
    end)
    CreateVectorWindowBtn("Minimize", function()
        Self:MinimizeToIcon()
    end)
    local isMaximized = false
    CreateVectorWindowBtn("Maximize", function()
        isMaximized = not isMaximized
        TweenService:Create(MainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Size = isMaximized and UDim2.fromOffset(1180, 680) or UDim2.fromOffset(1020, 600)
        }):Play()
    end)
    CreateVectorWindowBtn("Close", function()
        Self:MinimizeToIcon()
    end)

    -- Live Updaters
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
        local asset = ResolveImage(Self.BannerImage)
        BannerLayer.Image = asset
        BannerLayer.ImageTransparency = (asset ~= "") and Self.BannerTransparency or 1
    end

    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Self.ToggleKey then
            Self:ToggleMenu()
        end
    end)

    -- =========================================================================
    -- AUTO-LOADING SCREEN & ASSET PRELOADER (TERTANAM DI FRAMEWORK)
    -- =========================================================================
    function Self:RunInternalLoader(duration)
        duration = duration or 1.4
        local Loader = Instance.new("Frame")
        Loader.Name = "FrameworkLoader"
        Loader.Size = UDim2.fromScale(1, 1)
        Loader.BackgroundColor3 = CurrentTheme.MainBg
        Loader.ZIndex = 500
        Loader.Parent = MainWindow
        ApplySurfaceStyle(Loader, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local LoaderIcon = Instance.new("ImageLabel")
        LoaderIcon.Size = UDim2.fromOffset(78, 78)
        LoaderIcon.Position = UDim2.new(0.5, -39, 0.25, 0)
        LoaderIcon.BackgroundTransparency = 1
        LoaderIcon.ScaleType = Enum.ScaleType.Fit
        LoaderIcon.Image = ResolvedMasterLogo
        LoaderIcon.ZIndex = 501
        LoaderIcon.Parent = Loader

        local LoadTitle = Instance.new("TextLabel")
        LoadTitle.Size = UDim2.new(1, 0, 0, 32)
        LoadTitle.Position = UDim2.new(0, 0, 0.43, 0)
        LoadTitle.BackgroundTransparency = 1
        LoadTitle.Font = Enum.Font.GothamBlack
        LoadTitle.Text = Self.Title
        LoadTitle.TextSize = 22
        LoadTitle.ZIndex = 501
        LoadTitle.Parent = Loader
        BindTheme(LoadTitle, "TextColor3", "TextPrimary", "MainBg")

        local LoadSub = Instance.new("TextLabel")
        LoadSub.Size = UDim2.new(1, 0, 0, 20)
        LoadSub.Position = UDim2.new(0, 0, 0.49, 0)
        LoadSub.BackgroundTransparency = 1
        LoadSub.Font = Enum.Font.GothamMedium
        LoadSub.Text = "Preloading R&8_DV Vector Icons & GitHub Assets..."
        LoadSub.TextSize = 12
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

        task.spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync({BrandLogo, TopLogoIcon, MinEmblemImg, LoaderIcon})
            end)
        end)

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.85, Enum.EasingStyle.Quart), {
            Size = UDim2.fromScale(1, 1)
        }):Play()

        task.delay(duration, function()
            if Loader and Loader.Parent then
                TweenService:Create(Loader, TweenInfo.new(0.28), {BackgroundTransparency = 1}):Play()
                task.wait(0.28)
                Loader:Destroy()
            end
        end)
    end

    if Self.AutoLoading then
        Self:RunInternalLoader(1.4)
    end

    -- =========================================================================
    -- WIDGET FACTORY (`center()` & `right()`) - MURNI VEKTOR TANPA EMOJI
    -- =========================================================================
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

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
                Pill.Size = UDim2.fromOffset(124, 30)
                Pill.Position = UDim2.new(1, -126, 0, 12)
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

                local vecIcon = DrawVectorIcon(Card, item.Icon or "Bolt", 24, "Accent", BindTheme)
                vecIcon.Position = UDim2.new(0, 16, 0.5, -12)

                local Lbl = Instance.new("TextLabel")
                Lbl.Position = UDim2.new(0, 52, 0, 16)
                Lbl.Size = UDim2.new(1, -58, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.Gotham
                Lbl.Text = item.Label
                Lbl.TextSize = 11
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Card
                BindTheme(Lbl, "TextColor3", "TextMuted", "CardBg")

                local Val = Instance.new("TextLabel")
                Val.Position = UDim2.new(0, 52, 0, 34)
                Val.Size = UDim2.new(1, -58, 0, 22)
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

        function Builder:Card(title, rightActionText, iconName)
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
            Pad.PaddingRight = UDim.new(0, 14)
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

                local leftOffset = 0
                if iconName then
                    local hdrIcon = DrawVectorIcon(TopRow, iconName, 16, "Accent", BindTheme)
                    hdrIcon.Position = UDim2.new(0, 0, 0.5, -8)
                    leftOffset = 24
                end

                local TitleTxt = Instance.new("TextLabel")
                TitleTxt.Position = UDim2.new(0, leftOffset, 0, 0)
                TitleTxt.Size = UDim2.new(0.7, -leftOffset, 1, 0)
                TitleTxt.BackgroundTransparency = 1
                TitleTxt.Font = Enum.Font.GothamBold
                TitleTxt.Text = title
                TitleTxt.TextSize = 13
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
                TitleTxt.Parent = TopRow
                BindTheme(TitleTxt, "TextColor3", "TextPrimary", "CardBg")

                if rightActionText then
                    local ActionTxt = Instance.new("TextLabel")
                    ActionTxt.Size = UDim2.new(0.3, -16, 1, 0)
                    ActionTxt.Position = UDim2.new(0.7, 0, 0, 0)
                    ActionTxt.BackgroundTransparency = 1
                    ActionTxt.Font = Enum.Font.GothamMedium
                    ActionTxt.Text = rightActionText
                    ActionTxt.TextSize = 11
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right
                    ActionTxt.Parent = TopRow
                    BindTheme(ActionTxt, "TextColor3", "TextMuted", "CardBg")

                    local arr = DrawVectorIcon(TopRow, "ArrowRight", 12, "TextMuted", BindTheme)
                    arr.Position = UDim2.new(1, -12, 0.5, -6)
                end
            end

            return CreateCanvasBuilder(CardFrame)
        end

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

                local vec = DrawVectorIcon(Tile, action.Icon or "Bolt", 22, "Accent", BindTheme)
                vec.Position = UDim2.new(0.5, -11, 0, 15)

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

        function Builder:Section(text, iconName)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 24)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local offset = 0
            if iconName then
                local ic = DrawVectorIcon(Row, iconName, 15, "Accent", BindTheme)
                ic.Position = UDim2.new(0, 0, 0.5, -7)
                offset = 22
            end

            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, offset, 0, 0)
            Lbl.Size = UDim2.new(1, -offset, 1, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBold
            Lbl.Text = text
            Lbl.TextSize = 12
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row
            BindTheme(Lbl, "TextColor3", "TextPrimary", "PanelBg")
        end

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

            SwitchBg.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                SwitchBg.BackgroundColor3 = nextVal and CurrentTheme.Accent or CurrentTheme.ControlBg
                TweenService:Create(Knob, TweenInfo.new(0.16, Enum.EasingStyle.Quart), {
                    Position = nextVal and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                }):Play()
                if callback then task.spawn(callback, nextVal) end
            end)
        end

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
            DropBtn.Text = ""
            DropBtn.AutoButtonColor = false
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(DropBtn, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local SelectedTxt = Instance.new("TextLabel")
            SelectedTxt.Position = UDim2.new(0, 10, 0, 0)
            SelectedTxt.Size = UDim2.new(1, -28, 1, 0)
            SelectedTxt.BackgroundTransparency = 1
            SelectedTxt.Font = Enum.Font.GothamMedium
            SelectedTxt.Text = tostring(Self.Flags[flag])
            SelectedTxt.TextSize = 11
            SelectedTxt.TextXAlignment = Enum.TextXAlignment.Left
            SelectedTxt.Parent = DropBtn
            BindTheme(SelectedTxt, "TextColor3", "TextPrimary", "ControlBg")

            local chev = DrawVectorIcon(DropBtn, "ChevronDown", 12, "TextMuted", BindTheme)
            chev.Position = UDim2.new(1, -18, 0.5, -6)

            DropBtn.MouseButton1Click:Connect(function()
                idx = (idx % #options) + 1
                local chosen = options[idx]
                SelectedTxt.Text = tostring(chosen)
                Self:SetValue(flag, chosen)
                if callback then task.spawn(callback, chosen) end
            end)
        end

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
    -- DECLARATIVE FEATURE DSL: `feature(Logo, name)({ center = ..., right = ... })`
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

        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(1, 0, 0, 38)
        NavBtn.BackgroundTransparency = 1
        NavBtn.Text = ""
        NavBtn.AutoButtonColor = false
        NavBtn.Parent = NavScroll
        ApplySurfaceStyle(NavBtn, 8, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local isAssetLogo = (type(logo) == "string" and (string.find(logo, "^https?://") or string.find(logo, "^rbxassetid://")))
        if isAssetLogo then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Position = UDim2.new(0, 12, 0.5, -9)
            IconImg.Size = UDim2.fromOffset(18, 18)
            IconImg.BackgroundTransparency = 1
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.Image = ResolveImage(logo)
            IconImg.Parent = NavBtn
        else
            local vecTabIcon = DrawVectorIcon(NavBtn, logo or name, 18, "TextMuted", BindTheme)
            vecTabIcon.Position = UDim2.new(0, 12, 0.5, -9)
        end

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
