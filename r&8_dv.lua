--[[
    FRAMEWORK : R&8_DV ImGui Architecture (v6.0 - Polished Spacing, Colourful 2.5D & Clean Background)
    COPYRIGHT : R&8_DV
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local MASTER_LOGO_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Assets/icons.png"
local MASTER_FONT_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Assets/Jersey25-Regular.ttf"

local MASTER_LOGO_FILE = "R8DV_MasterLogo_v6.png"
local MASTER_FONT_TTF  = "R8DV_Jersey25_v6.ttf"
local MASTER_FONT_JSON = "R8DV_Jersey25_v6.json"

local TWEEN_FAST   = TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MEDIUM = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_POP    = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local LayoutPreset = {
    WindowWidth   = 1020,
    WindowHeight  = 600,
    OuterMargin   = 12,
    PanelPadding  = 16,
    ItemSpacing   = 10,
    CardPadding   = 14,
    CardSpacing   = 8,
    RowHeight     = 32,
    FontHeader    = 28,
    FontCardTitle = 17,
    FontSection   = 16,
    FontBody      = 16,
    FontSmall     = 14
}

local function GetSafeGuiParent()
    local ok, res = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if ok and res then return res end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local AssetCache = {}
local function ResolveImage(source)
    if not source or source == "" then return "" end
    if string.find(source, "^rbxassetid://") or string.find(source, "^rbxthumb://") then return source end
    if AssetCache[source] then return AssetCache[source] end

    local getAsset = getcustomasset or getsynasset
    if getAsset and writefile and isfile then
        local ok, assetId = pcall(function()
            if string.find(source, "^https?://") then
                local fileName = (source == MASTER_LOGO_URL) and MASTER_LOGO_FILE or ("R8DV_Img_" .. tostring(#source * 17) .. ".png")
                if not isfile(fileName) then
                    local raw = game:HttpGet(source, true)
                    if raw and #raw > 0 then writefile(fileName, raw) end
                end
                if isfile(fileName) then return getAsset(fileName) end
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

local LoadedCustomFont = nil
local function GetFrameworkFont()
    if LoadedCustomFont then return LoadedCustomFont end
    local getAsset = getcustomasset or getsynasset
    if getAsset and writefile and isfile then
        local ok, fontFace = pcall(function()
            if not isfile(MASTER_FONT_TTF) then
                local rawTtf = game:HttpGet(MASTER_FONT_URL, true)
                if rawTtf and #rawTtf > 0 then writefile(MASTER_FONT_TTF, rawTtf) end
            end
            if isfile(MASTER_FONT_TTF) then
                local ttfId = getAsset(MASTER_FONT_TTF)
                local desc = {
                    name = "Jersey25_v6",
                    faces = {{ name = "Regular", weight = 400, style = "normal", assetId = ttfId }}
                }
                writefile(MASTER_FONT_JSON, HttpService:JSONEncode(desc))
                return Font.new(getAsset(MASTER_FONT_JSON), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            end
            return nil
        end)
        if ok and fontFace then
            LoadedCustomFont = fontFace
            return LoadedCustomFont
        end
    end
    LoadedCustomFont = Font.fromEnum(Enum.Font.GothamBold)
    return LoadedCustomFont
end

local function ApplyLetterSpacing(text, spacingCount)
    text = tostring(text or "")
    spacingCount = spacingCount or 0
    if spacingCount <= 0 or #text <= 1 then return text end
    local spacer = string.rep(" ", spacingCount)
    local chars = {}
    for i = 1, #text do table.insert(chars, string.sub(text, i, i)) end
    return table.concat(chars, spacer)
end

-- PALET TEMA WARNA (COLOURFUL MINIMALIST)
local Themes = {
    ["Blue Night Sky"] = {
        MainBg          = Color3.fromRGB(10, 13, 20),
        PanelBg         = Color3.fromRGB(16, 20, 32),
        CardBg          = Color3.fromRGB(23, 29, 46),
        ControlBg       = Color3.fromRGB(32, 40, 64),
        Accent          = Color3.fromRGB(110, 155, 255),
        AccentSecondary = Color3.fromRGB(175, 212, 255),
        Stroke          = Color3.fromRGB(52, 65, 96),
        TextPrimary     = Color3.fromRGB(245, 248, 255),
        TextMuted       = Color3.fromRGB(160, 175, 208),
        DepthShadow     = Color3.fromRGB(4, 6, 10)
    },
    ["Orange Sand"] = {
        MainBg          = Color3.fromRGB(22, 16, 13),
        PanelBg         = Color3.fromRGB(31, 23, 19),
        CardBg          = Color3.fromRGB(42, 32, 26),
        ControlBg       = Color3.fromRGB(58, 44, 36),
        Accent          = Color3.fromRGB(255, 156, 70),
        AccentSecondary = Color3.fromRGB(255, 214, 145),
        Stroke          = Color3.fromRGB(85, 66, 54),
        TextPrimary     = Color3.fromRGB(255, 246, 238),
        TextMuted       = Color3.fromRGB(196, 172, 154),
        DepthShadow     = Color3.fromRGB(10, 6, 4)
    },
    ["Midnight Monokai"] = {
        MainBg          = Color3.fromRGB(16, 17, 14),
        PanelBg         = Color3.fromRGB(24, 25, 21),
        CardBg          = Color3.fromRGB(33, 35, 29),
        ControlBg       = Color3.fromRGB(46, 48, 40),
        Accent          = Color3.fromRGB(174, 235, 54),
        AccentSecondary = Color3.fromRGB(112, 224, 245),
        Stroke          = Color3.fromRGB(68, 71, 60),
        TextPrimary     = Color3.fromRGB(250, 252, 244),
        TextMuted       = Color3.fromRGB(160, 164, 148),
        DepthShadow     = Color3.fromRGB(6, 7, 5)
    }
}

local function ApplySurfaceStyle(frame, radiusScale, strokeColor, themeBindings, radiusBindings, strokeType)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radiusScale)
    corner.Parent = frame
    table.insert(radiusBindings, {Instance = corner, BaseRadius = radiusScale})

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1.2
    stroke.Color = strokeColor
    stroke.Transparency = 0.20
    stroke.Parent = frame
    table.insert(themeBindings, {Instance = stroke, Prop = "Color", Key = strokeType or "Stroke"})
    return corner, stroke
end

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
    elseif key == "teleports" or key == "teleport" then
        Ring(sizePx * 0.58, sizePx * 0.58, 0.5, 0.42, sizePx, 1.8)
        Line(4, 4, 0.5, 0.42, 0, 2)
        Line(sizePx * 0.30, 2, 0.42, 0.76, 55, 1)
        Line(sizePx * 0.30, 2, 0.58, 0.76, -55, 1)
    elseif key == "player" or key == "user" then
        Ring(sizePx * 0.38, sizePx * 0.38, 0.5, 0.32, sizePx, 1.8)
        Ring(sizePx * 0.68, sizePx * 0.34, 0.5, 0.76, 6, 1.8)
    elseif key == "visuals" or key == "esp" then
        Ring(sizePx * 0.82, sizePx * 0.46, 0.5, 0.5, sizePx, 1.8)
        Line(sizePx * 0.24, sizePx * 0.24, 0.5, 0.5, 0, sizePx)
    elseif key == "misc" or key == "settings" then
        Ring(sizePx * 0.56, sizePx * 0.56, 0.5, 0.5, sizePx, 2)
        Line(sizePx * 0.82, 2, 0.5, 0.5, 0, 1)
        Line(sizePx * 0.82, 2, 0.5, 0.5, 90, 1)
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
    elseif key == "speed" then
        Ring(sizePx * 0.78, sizePx * 0.78, 0.5, 0.54, sizePx, 1.8)
        Line(sizePx * 0.34, 2, 0.58, 0.46, -35, 1)
    elseif key == "jump" then
        Line(2, sizePx * 0.64, 0.5, 0.54, 0, 1)
        Line(sizePx * 0.36, 2, 0.39, 0.32, -45, 1)
        Line(sizePx * 0.36, 2, 0.61, 0.32, 45, 1)
    elseif key == "collect" or key == "layers" then
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.38, 3, 1.6, 45)
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.60, 3, 1.6, 45)
    elseif key == "check" then
        Line(sizePx * 0.32, 2.2, 0.34, 0.58, 42, 1)
        Line(sizePx * 0.56, 2.2, 0.62, 0.46, -48, 1)
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

local function ImGui(config)
    config = config or {}
    local Self = {
        Title = config.Title or "DRY CURSED  -  IMGUI",
        Copyright = "R&8_DV",
        ThemeName = config.Theme or "Blue Night Sky",
        Rounded = (config.Rounded ~= false),
        SideCount = config.Sides or 3,
        UIScale = config.Scale or 1,
        LetterSpacing = config.LetterSpacing or 0,
        CheckboxStyle = config.CheckboxStyle or "Modern",
        Text3D = (config.Text3D ~= false),
        BgTransparency = 1, -- Jendela utama dibuat transparan penuh (tanpa background biru tua)[cite: 4]
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.84,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode ~= false),
        AutoLoading = (config.AutoLoading ~= false),
        IsMinimized = false,
        Flags = {},
        FlagListeners = {},
        Features = {},
        ActiveFeature = nil,
        ThemeBindings = {},
        GradientBindings = {},
        RadiusBindings = {},
        ToggleStyleUpdaters = {}
    }

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Blue Night Sky"]
    local CustomFontFace = GetFrameworkFont()
    local ResolvedMasterLogo = ResolveImage(MASTER_LOGO_URL)

    function Self:SetValue(flag, value)
        Self.Flags[flag] = value
        if Self.FlagListeners[flag] then
            for _, cb in ipairs(Self.FlagListeners[flag]) do task.spawn(cb, value) end
        end
    end

    function Self:GetValue(flag) return Self.Flags[flag] end

    function Self:OnValueChanged(flag, callback)
        Self.FlagListeners[flag] = Self.FlagListeners[flag] or {}
        table.insert(Self.FlagListeners[flag], callback)
    end

    local function BindTheme(instance, prop, themeKey, bgKeyForContrast)
        table.insert(Self.ThemeBindings, { Instance = instance, Prop = prop, Key = themeKey, BgKey = bgKeyForContrast })
        local col = CurrentTheme[themeKey]
        if bgKeyForContrast then col = GetReadableTextColor(CurrentTheme[bgKeyForContrast], col) end
        instance[prop] = col
    end

    local function CreateStylizedText(parent, text, sizePx, colorKey, is3DGradient, tracking)
        local Lbl = Instance.new("TextLabel")
        Lbl.BackgroundTransparency = 1
        Lbl.FontFace = CustomFontFace
        Lbl.Text = ApplyLetterSpacing(text, tracking or Self.LetterSpacing)
        Lbl.TextSize = sizePx or LayoutPreset.FontBody
        Lbl.Parent = parent
        BindTheme(Lbl, "TextColor3", colorKey or "TextPrimary", "PanelBg")

        local depthStroke = Instance.new("UIStroke")
        depthStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        depthStroke.Thickness = is3DGradient and 1.6 or 1.0
        depthStroke.Transparency = is3DGradient and 0.18 or 0.4
        depthStroke.Parent = Lbl
        BindTheme(depthStroke, "Color", "DepthShadow")

        if is3DGradient then
            local grad = Instance.new("UIGradient")
            grad.Rotation = 90
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, CurrentTheme.TextPrimary),
                ColorSequenceKeypoint.new(0.5, CurrentTheme.AccentSecondary),
                ColorSequenceKeypoint.new(1, CurrentTheme.Accent)
            })
            grad.Parent = Lbl
            table.insert(Self.GradientBindings, {Instance = grad, Mode = "Text3D"})
        end

        return Lbl
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "R8_DV_v6_" .. HttpService:GenerateGUID(false):sub(1, 6)
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = GetSafeGuiParent()

    local FocusBlocker = Instance.new("TextButton")
    FocusBlocker.Name = "FocusSink"
    FocusBlocker.Size = UDim2.fromScale(1, 1)
    FocusBlocker.BackgroundTransparency = 0.5
    FocusBlocker.BackgroundColor3 = Color3.fromRGB(3, 5, 8)
    FocusBlocker.Text = ""
    FocusBlocker.AutoButtonColor = false
    FocusBlocker.Active = true
    FocusBlocker.Modal = true
    FocusBlocker.Visible = Self.FocusMode
    FocusBlocker.Parent = ScreenGui

    -- FLOATING SHORTCUT MINIMIZE BUTTON
    local MinimizeIconBtn = Instance.new("ImageButton")
    MinimizeIconBtn.Name = "R8DV_FloatingShortcut"
    MinimizeIconBtn.Size = UDim2.fromOffset(64, 64)
    MinimizeIconBtn.Position = UDim2.new(0, 52, 0.5, 0)
    MinimizeIconBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIconBtn.BackgroundTransparency = 0
    MinimizeIconBtn.AutoButtonColor = false
    MinimizeIconBtn.Image = ""
    MinimizeIconBtn.Visible = false
    MinimizeIconBtn.ZIndex = 800
    MinimizeIconBtn.Parent = ScreenGui
    BindTheme(MinimizeIconBtn, "BackgroundColor3", "PanelBg")

    local MinOuterCorner = Instance.new("UICorner")
    MinOuterCorner.CornerRadius = UDim.new(0.28, 0)
    MinOuterCorner.Parent = MinimizeIconBtn

    local MinBgGrad = Instance.new("UIGradient")
    MinBgGrad.Rotation = 45
    MinBgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CurrentTheme.CardBg),
        ColorSequenceKeypoint.new(0.65, CurrentTheme.PanelBg),
        ColorSequenceKeypoint.new(1, CurrentTheme.MainBg)
    })
    MinBgGrad.Parent = MinimizeIconBtn
    table.insert(Self.GradientBindings, {Instance = MinBgGrad, Mode = "ShortcutOuter"})

    local MinOuterStroke = Instance.new("UIStroke")
    MinOuterStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MinOuterStroke.Thickness = 2.2
    MinOuterStroke.Parent = MinimizeIconBtn
    BindTheme(MinOuterStroke, "Color", "DepthShadow")

    local MinInnerBezel = Instance.new("Frame")
    MinInnerBezel.Size = UDim2.new(1, -6, 1, -6)
    MinInnerBezel.Position = UDim2.fromScale(0.5, 0.5)
    MinInnerBezel.AnchorPoint = Vector2.new(0.5, 0.5)
    MinInnerBezel.BackgroundTransparency = 0.05
    MinInnerBezel.ZIndex = 801
    MinInnerBezel.Parent = MinimizeIconBtn
    BindTheme(MinInnerBezel, "BackgroundColor3", "CardBg")

    local MinInnerCorner = Instance.new("UICorner")
    MinInnerCorner.CornerRadius = UDim.new(0.24, 0)
    MinInnerCorner.Parent = MinInnerBezel

    local InnerSurfaceGrad = Instance.new("UIGradient")
    InnerSurfaceGrad.Rotation = 135
    InnerSurfaceGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CurrentTheme.ControlBg),
        ColorSequenceKeypoint.new(0.7, CurrentTheme.CardBg),
        ColorSequenceKeypoint.new(1, CurrentTheme.Accent)
    })
    InnerSurfaceGrad.Parent = MinInnerBezel
    table.insert(Self.GradientBindings, {Instance = InnerSurfaceGrad, Mode = "ShortcutInner"})

    local MinEmblemImg = Instance.new("ImageLabel")
    MinEmblemImg.Size = UDim2.fromScale(0.82, 0.82)
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

    -- MAIN WINDOW CONTAINER (TRANSPARAN / TANPA BACKGROUND BIRU TUA)
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.fromOffset(LayoutPreset.WindowWidth, LayoutPreset.WindowHeight)
    MainWindow.Position = UDim2.fromScale(0.5, 0.5)
    MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    MainWindow.BackgroundTransparency = 1 -- Transparan total agar bersih tanpa latar belakang biru[cite: 4]
    MainWindow.Active = true
    MainWindow.Parent = ScreenGui

    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainWindow

    local function ComputeTargetScale()
        local cam = workspace.CurrentCamera
        if not cam then return 1 end
        local vp = cam.ViewportSize
        local autoFit = math.min(1, (vp.X * 0.94) / LayoutPreset.WindowWidth, (vp.Y * 0.92) / LayoutPreset.WindowHeight)
        return math.clamp(autoFit * Self.UIScale, 0.45, 1.45)
    end

    local function UpdateResponsiveScale()
        if not Self.IsMinimized then WindowScale.Scale = ComputeTargetScale() end
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(UpdateResponsiveScale)
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
    end
    UpdateResponsiveScale()

    local BannerLayer = Instance.new("ImageLabel")
    BannerLayer.Name = "CustomBanner"
    BannerLayer.Size = UDim2.fromScale(1, 1)
    BannerLayer.BackgroundTransparency = 1
    BannerLayer.ScaleType = Enum.ScaleType.Crop
    BannerLayer.Image = ResolveImage(Self.BannerImage)
    BannerLayer.ImageTransparency = Self.BannerImage ~= "" and Self.BannerTransparency or 1
    BannerLayer.Parent = MainWindow

    local Watermark = CreateStylizedText(MainWindow, "(C) " .. Self.Copyright .. " ENGINE", 12, "TextMuted", false, 0)
    Watermark.Size = UDim2.new(0, 160, 0, 16)
    Watermark.Position = UDim2.new(1, -168, 1, -17)
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    Watermark.TextTransparency = 0.4

    -- 1. LEFT SIDEBAR (DENGAN SPASI VERTIKAL AMAN)
    local m = LayoutPreset.OuterMargin
    local LeftSidebar = Instance.new("Frame")
    LeftSidebar.Name = "LeftSidebar"
    LeftSidebar.Position = UDim2.new(0, m, 0, m)
    LeftSidebar.Size = UDim2.new(0.24, -m, 1, -(m * 2))
    LeftSidebar.BackgroundTransparency = Self.BgTransparency
    LeftSidebar.Parent = MainWindow
    BindTheme(LeftSidebar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(LeftSidebar, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = UDim2.new(1, 0, 0, 118)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(82, 82)
    BrandLogo.Position = UDim2.fromScale(0.5, 0.52)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolvedMasterLogo
    BrandLogo.Parent = LogoHolder

    if ResolvedMasterLogo == "" then
        local fallbackCrest = DrawVectorIcon(LogoHolder, "AutoFarm", 44, "Accent", BindTheme)
        fallbackCrest.Position = UDim2.fromScale(0.5, 0.52)
        fallbackCrest.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Position = UDim2.new(0, 10, 0, 122)
    NavScroll.Size = UDim2.new(1, -20, 1, -132)
    NavScroll.BackgroundTransparency = 1
    NavScroll.ScrollBarThickness = 2
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.Parent = LeftSidebar
    BindTheme(NavScroll, "ScrollBarImageColor3", "Accent")

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 8) -- Spasi antar menu sidebar diperbesar agar tidak mepet[cite: 4]
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = NavScroll

    -- 2. TOP IMGUI HEADER BAR
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.24, 8, 0, m)
    TopBar.Size = UDim2.new(0.76, -(m + 8), 0, 40)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local TopLogoIcon = Instance.new("ImageLabel")
    TopLogoIcon.Position = UDim2.new(0, 12, 0.5, -10)
    TopLogoIcon.Size = UDim2.fromOffset(20, 20)
    TopLogoIcon.BackgroundTransparency = 1
    TopLogoIcon.ScaleType = Enum.ScaleType.Fit
    TopLogoIcon.Image = ResolvedMasterLogo
    TopLogoIcon.Parent = TopBar

    local TopTitle = CreateStylizedText(TopBar, Self.Title .. "   |   " .. Self.Copyright, LayoutPreset.FontBody, "TextPrimary", true, 1)
    TopTitle.Position = UDim2.new(0, 40, 0, 0)
    TopTitle.Size = UDim2.new(0.65, 0, 1, 0)
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left

    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Position = UDim2.new(1, -132, 0, 0)
    ControlsHolder.Size = UDim2.new(0, 124, 1, 0)
    ControlsHolder.BackgroundTransparency = 1
    ControlsHolder.Parent = TopBar

    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 5)
    ControlsLayout.Parent = ControlsHolder

    local function CreateVectorWindowBtn(vectorType, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(26, 26)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ControlsHolder
        local icon = DrawVectorIcon(btn, vectorType, 15, "TextMuted", BindTheme)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL & RIGHT PANEL (DENGAN SAFE PADDING KANAN)
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.24, 8, 0, m + 48)
    CenterPanel.Size = UDim2.new(0.50, -8, 1, -(m * 2 + 48))
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.74, 8, 0, m + 48)
    RightPanel.Size = UDim2.new(0.26, -(m + 8), 1, -(m * 2 + 48))
    RightPanel.BackgroundTransparency = Self.BgTransparency
    RightPanel.ClipsDescendants = true
    RightPanel.Parent = MainWindow
    BindTheme(RightPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(RightPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

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
        if input == iconDragInput and dragging then end
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    function Self:MinimizeToIcon()
        if Self.IsMinimized then return end
        Self.IsMinimized = true
        FocusBlocker.Visible = false
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)

        local shrink = TweenService:Create(WindowScale, TWEEN_FAST, {Scale = 0})
        shrink:Play()
        shrink.Completed:Connect(function()
            if Self.IsMinimized then
                MainWindow.Visible = false
                MinimizeIconBtn.Size = UDim2.fromOffset(12, 12)
                MinimizeIconBtn.Visible = true
                TweenService:Create(MinimizeIconBtn, TWEEN_POP, {Size = UDim2.fromOffset(64, 64)}):Play()
            end
        end)
    end

    function Self:RestoreFromIcon()
        if not Self.IsMinimized then return end
        Self.IsMinimized = false

        local hideIcon = TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(0, 0)})
        hideIcon:Play()
        hideIcon.Completed:Connect(function()
            if not Self.IsMinimized then
                MinimizeIconBtn.Visible = false
                MainWindow.Visible = true
                FocusBlocker.Visible = Self.FocusMode
                pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
                TweenService:Create(WindowScale, TWEEN_POP, {Scale = ComputeTargetScale()}):Play()
            end
        end)
    end

    function Self:ToggleMenu(forceState)
        local shouldOpen = (forceState ~= nil) and forceState or Self.IsMinimized
        if shouldOpen then Self:RestoreFromIcon() else Self:MinimizeToIcon() end
    end

    local iconDragging, iconDragInput, iconDragStart, iconStartPos
    local movedDist = 0

    MinimizeIconBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            iconDragging = true
            movedDist = 0
            iconDragStart = input.Position
            iconStartPos = MinimizeIconBtn.Position
            TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(58, 58)}):Play()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    iconDragging = false
                    TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(64, 64)}):Play()
                    if movedDist < 6 then Self:RestoreFromIcon() end
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

    function Self.Call(sideCount)
        Self.SideCount = (sideCount == 2) and 2 or 3
        if Self.SideCount == 3 then
            RightPanel.Visible = true
            TweenService:Create(CenterPanel, TWEEN_MEDIUM, { Size = UDim2.new(0.50, -8, 1, -(m * 2 + 48)) }):Play()
        else
            RightPanel.Visible = false
            TweenService:Create(CenterPanel, TWEEN_MEDIUM, { Size = UDim2.new(0.76, -(m + 8), 1, -(m * 2 + 48)) }):Play()
        end
        return Self
    end

    CreateVectorWindowBtn("Menu", function() Self.Call(Self.SideCount == 3 and 2 or 3) end)
    CreateVectorWindowBtn("Minimize", function() Self:MinimizeToIcon() end)
    local isMaximized = false
    CreateVectorWindowBtn("Maximize", function()
        isMaximized = not isMaximized
        TweenService:Create(MainWindow, TWEEN_MEDIUM, {
            Size = isMaximized and UDim2.fromOffset(1140, 650) or UDim2.fromOffset(LayoutPreset.WindowWidth, LayoutPreset.WindowHeight)
        }):Play()
    end)
    CreateVectorWindowBtn("Close", function() Self:MinimizeToIcon() end)

    function Self:SetTheme(themeName)
        if not Themes[themeName] then return end
        Self.ThemeName = themeName
        CurrentTheme = Themes[themeName]
        for _, b in ipairs(Self.ThemeBindings) do
            if b.Instance and b.Instance.Parent then
                local col = CurrentTheme[b.Key]
                if b.BgKey then col = GetReadableTextColor(CurrentTheme[b.BgKey], col) end
                b.Instance[b.Prop] = col
            end
        end
        for _, g in ipairs(Self.GradientBindings) do
            if g.Instance and g.Instance.Parent then
                if g.Mode == "Text3D" then
                    g.Instance.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, CurrentTheme.TextPrimary),
                        ColorSequenceKeypoint.new(0.5, CurrentTheme.AccentSecondary),
                        ColorSequenceKeypoint.new(1, CurrentTheme.Accent)
                    })
                elseif g.Mode == "ShortcutOuter" then
                    g.Instance.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, CurrentTheme.CardBg),
                        ColorSequenceKeypoint.new(0.65, CurrentTheme.PanelBg),
                        ColorSequenceKeypoint.new(1, CurrentTheme.MainBg)
                    })
                elseif g.Mode == "ShortcutInner" then
                    g.Instance.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, CurrentTheme.ControlBg),
                        ColorSequenceKeypoint.new(0.7, CurrentTheme.CardBg),
                        ColorSequenceKeypoint.new(1, CurrentTheme.Accent)
                    })
                end
            end
        end
        for _, fn in ipairs(Self.ToggleStyleUpdaters) do pcall(fn) end
    end

    function Self:SetCheckboxStyle(styleName)
        Self.CheckboxStyle = styleName or "Modern"
        for _, fn in ipairs(Self.ToggleStyleUpdaters) do pcall(fn, Self.CheckboxStyle) end
    end

    function Self:SetRounded(state)
        Self.Rounded = state
        for _, r in ipairs(Self.RadiusBindings) do
            if r.Instance and r.Instance.Parent then r.Instance.CornerRadius = UDim.new(0, state and r.BaseRadius or 0) end
        end
    end

    function Self:SetTransparency(alpha)
        Self.BgTransparency = math.clamp(alpha, 0, 0.65)
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
        if not gp and input.KeyCode == Self.ToggleKey then Self:ToggleMenu() end
    end)

    function Self:RunInternalLoader(duration)
        duration = duration or 0.8
        local Loader = Instance.new("Frame")
        Loader.Name = "FrameworkLoader"
        Loader.Size = UDim2.fromScale(1, 1)
        Loader.BackgroundColor3 = CurrentTheme.MainBg
        Loader.ZIndex = 500
        Loader.Parent = MainWindow
        ApplySurfaceStyle(Loader, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local LoaderIcon = Instance.new("ImageLabel")
        LoaderIcon.Size = UDim2.fromOffset(76, 76)
        LoaderIcon.Position = UDim2.new(0.5, -38, 0.25, 0)
        LoaderIcon.BackgroundTransparency = 1
        LoaderIcon.ScaleType = Enum.ScaleType.Fit
        LoaderIcon.Image = ResolvedMasterLogo
        LoaderIcon.ZIndex = 501
        LoaderIcon.Parent = Loader

        local LoadTitle = CreateStylizedText(Loader, Self.Title, 28, "TextPrimary", true, 1)
        LoadTitle.Size = UDim2.new(1, 0, 0, 34)
        LoadTitle.Position = UDim2.new(0, 0, 0.43, 0)
        LoadTitle.ZIndex = 501

        local LoadSub = CreateStylizedText(Loader, "Initializing Colourful Minimalist 2.5D Engine...", LayoutPreset.FontSmall, "TextMuted", false, 0)
        LoadSub.Size = UDim2.new(1, 0, 0, 20)
        LoadSub.Position = UDim2.new(0, 0, 0.50, 0)
        LoadSub.ZIndex = 501

        local BarBg = Instance.new("Frame")
        BarBg.Size = UDim2.fromOffset(260, 6)
        BarBg.Position = UDim2.new(0.5, -130, 0.58, 0)
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
            pcall(function() ContentProvider:PreloadAsync({BrandLogo, TopLogoIcon, MinEmblemImg, LoaderIcon}) end)
        end)

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()

        task.delay(duration, function()
            if Loader and Loader.Parent then
                TweenService:Create(Loader, TWEEN_MEDIUM, {BackgroundTransparency = 1}):Play()
                task.wait(0.15)
                Loader:Destroy()
            end
        end)
    end

    if Self.AutoLoading then Self:RunInternalLoader(0.8) end

    -- WIDGET FACTORY (DENGAN PADDING AMAN AGAR TIDAK MEPET KE UJUNG KANAN)
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

        function Builder:Header(title, subtitle, badgeText)
            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Size = UDim2.new(1, 0, 0, 56)
            HeaderFrame.BackgroundTransparency = 1
            HeaderFrame.Parent = scrollingPage

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(0, 4, 0, 46)
            AccentBar.Position = UDim2.new(0, 0, 0, 5)
            AccentBar.Parent = HeaderFrame
            BindTheme(AccentBar, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(AccentBar, 3, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

            local TitleLbl = CreateStylizedText(HeaderFrame, title, LayoutPreset.FontHeader, "TextPrimary", true, 1)
            TitleLbl.Position = UDim2.new(0, 14, 0, 2)
            TitleLbl.Size = UDim2.new(0.60, 0, 0, 28)
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local SubLbl = CreateStylizedText(HeaderFrame, subtitle or "", LayoutPreset.FontSmall, "TextMuted", false, 0)
            SubLbl.Position = UDim2.new(0, 14, 0, 31)
            SubLbl.Size = UDim2.new(0.60, 0, 0, 18)
            SubLbl.TextXAlignment = Enum.TextXAlignment.Left

            if badgeText then
                local Pill = Instance.new("Frame")
                Pill.Size = UDim2.fromOffset(118, 28)
                Pill.Position = UDim2.new(1, -122, 0, 10)
                Pill.Parent = HeaderFrame
                BindTheme(Pill, "BackgroundColor3", "CardBg")
                ApplySurfaceStyle(Pill, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(8, 8)
                Dot.Position = UDim2.new(0, 11, 0.5, -4)
                Dot.Parent = Pill
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplySurfaceStyle(Dot, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent")

                local PillTxt = CreateStylizedText(Pill, badgeText, LayoutPreset.FontSmall, "TextPrimary", true, 0)
                PillTxt.Position = UDim2.new(0, 24, 0, 0)
                PillTxt.Size = UDim2.new(1, -28, 1, 0)
                PillTxt.TextXAlignment = Enum.TextXAlignment.Left
            end
        end

        function Builder:StatRow(statsList)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 66)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / #statsList, -6, 1, 0)
            Grid.CellPadding = UDim2.new(0, 8, 0, 0)
            Grid.Parent = Row

            local ValueLabels = {}
            for i, item in ipairs(statsList) do
                local Card = Instance.new("Frame")
                Card.Parent = Row
                BindTheme(Card, "BackgroundColor3", "CardBg")
                ApplySurfaceStyle(Card, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

                local vecIcon = DrawVectorIcon(Card, item.Icon or "Bolt", 22, "Accent", BindTheme)
                vecIcon.Position = UDim2.new(0, 12, 0.5, -11)

                local Lbl = CreateStylizedText(Card, item.Label, LayoutPreset.FontSmall, "TextMuted", false, 0)
                Lbl.Position = UDim2.new(0, 44, 0, 12)
                Lbl.Size = UDim2.new(1, -48, 0, 16)
                Lbl.TextXAlignment = Enum.TextXAlignment.Left

                local Val = CreateStylizedText(Card, item.Value, LayoutPreset.FontCardTitle + 2, "TextPrimary", true, 0)
                Val.Position = UDim2.new(0, 44, 0, 30)
                Val.Size = UDim2.new(1, -48, 0, 22)
                Val.TextXAlignment = Enum.TextXAlignment.Left
                ValueLabels[i] = Val
            end
            return ValueLabels
        end

        function Builder:Card(title, rightActionText, iconName)
            local CardFrame = Instance.new("Frame")
            CardFrame.Size = UDim2.new(1, 0, 0, 36)
            CardFrame.AutomaticSize = Enum.AutomaticSize.Y
            CardFrame.Parent = scrollingPage
            BindTheme(CardFrame, "BackgroundColor3", "CardBg")
            ApplySurfaceStyle(CardFrame, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingTop = UDim.new(0, LayoutPreset.CardPadding)
            Pad.PaddingBottom = UDim.new(0, LayoutPreset.CardPadding)
            Pad.PaddingLeft = UDim.new(0, LayoutPreset.CardPadding)
            Pad.PaddingRight = UDim.new(0, LayoutPreset.CardPadding + 4) -- Extra margin kanan agar tidak mepet[cite: 4]
            Pad.Parent = CardFrame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, LayoutPreset.CardSpacing)
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
                    leftOffset = 22
                end

                local TitleTxt = CreateStylizedText(TopRow, title, LayoutPreset.FontCardTitle, "TextPrimary", true, 0)
                TitleTxt.Position = UDim2.new(0, leftOffset, 0, 0)
                TitleTxt.Size = UDim2.new(0.65, -leftOffset, 1, 0)
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left

                if rightActionText then
                    local ActionTxt = CreateStylizedText(TopRow, rightActionText, LayoutPreset.FontSmall, "TextMuted", false, 0)
                    ActionTxt.Size = UDim2.new(0.35, -16, 1, 0)
                    ActionTxt.Position = UDim2.new(0.65, 0, 0, 0)
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right

                    local arr = DrawVectorIcon(TopRow, "ArrowRight", 12, "TextMuted", BindTheme)
                    arr.Position = UDim2.new(1, -10, 0.5, -6)
                end
            end

            return CreateCanvasBuilder(CardFrame)
        end

        function Builder:ActionGrid(items)
            local GridHolder = Instance.new("Frame")
            GridHolder.Size = UDim2.new(1, 0, 0, 74)
            GridHolder.AutomaticSize = Enum.AutomaticSize.Y
            GridHolder.BackgroundTransparency = 1
            GridHolder.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / math.min(#items, 6), -6, 0, 72)
            Grid.CellPadding = UDim2.new(0, 6, 0, 6)
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

                local vec = DrawVectorIcon(Tile, action.Icon or "Bolt", 20, "Accent", BindTheme)
                vec.Position = UDim2.new(0.5, -10, 0, 13)

                local Lbl = CreateStylizedText(Tile, action.Name, LayoutPreset.FontSmall, "TextPrimary", true, 0)
                Lbl.Size = UDim2.new(1, -4, 0, 18)
                Lbl.Position = UDim2.new(0, 2, 1, -22)

                Tile.MouseButton1Click:Connect(function()
                    local nextVal = not Self.Flags[flag]
                    Self:SetValue(flag, nextVal)
                    tileStroke.Color = nextVal and CurrentTheme.Accent or CurrentTheme.Stroke
                    tileStroke.Transparency = nextVal and 0 or 0.20
                    if action.Callback then task.spawn(action.Callback, nextVal) end
                end)
            end
        end

        function Builder:Section(text, iconName)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 22)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local offset = 0
            if iconName then
                local ic = DrawVectorIcon(Row, iconName, 14, "Accent", BindTheme)
                ic.Position = UDim2.new(0, 0, 0.5, -7)
                offset = 20
            end

            local Lbl = CreateStylizedText(Row, text, LayoutPreset.FontSection, "TextPrimary", true, 0)
            Lbl.Position = UDim2.new(0, offset, 0, 0)
            Lbl.Size = UDim2.new(1, -offset, 1, 0)
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
        end

        function Builder:Toggle(label, flag, default, callback, customStyle)
            Self.Flags[flag] = (default == true)
            local currentStyle = customStyle or Self.CheckboxStyle

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight - 2)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextMuted", false, 0)
            Title.Size = UDim2.new(1, -54, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local HitBtn = Instance.new("TextButton")
            HitBtn.Position = UDim2.new(1, -48, 0.5, -11) -- Diatur lebih masuk ke dalam agar tidak mepet kanan[cite: 4]
            HitBtn.Size = UDim2.fromOffset(46, 22)
            HitBtn.Text = ""
            HitBtn.AutoButtonColor = false
            HitBtn.Parent = Row
            BindTheme(HitBtn, "BackgroundColor3", "ControlBg")
            local hitCorner, hitStroke = ApplySurfaceStyle(HitBtn, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.fromOffset(14, 14)
            Knob.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
            Knob.Parent = HitBtn
            ApplySurfaceStyle(Knob, 7, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local CheckVec = DrawVectorIcon(HitBtn, "Check", 14, "TextPrimary", BindTheme)
            CheckVec.Position = UDim2.fromScale(0.5, 0.5)
            CheckVec.AnchorPoint = Vector2.new(0.5, 0.5)

            local StateText = CreateStylizedText(HitBtn, "OFF", LayoutPreset.FontSmall, "TextPrimary", true, 0)
            StateText.Size = UDim2.fromScale(1, 1)

            local function RenderToggleVisual(newStyle)
                if newStyle and not customStyle then currentStyle = newStyle end
                local val = Self.Flags[flag]
                local styleKey = string.lower(tostring(currentStyle))

                if styleKey == "classic" then
                    HitBtn.Size = UDim2.fromOffset(22, 22)
                    HitBtn.Position = UDim2.new(1, -26, 0.5, -11)
                    hitCorner.CornerRadius = UDim.new(0, Self.Rounded and 6 or 0)
                    Knob.Visible = false
                    StateText.Visible = false
                    CheckVec.Visible = val
                    HitBtn.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                    hitStroke.Color = val and CurrentTheme.AccentSecondary or CurrentTheme.Stroke
                elseif styleKey == "biasa" or styleKey == "standard" then
                    HitBtn.Size = UDim2.fromOffset(48, 22)
                    HitBtn.Position = UDim2.new(1, -50, 0.5, -11)
                    hitCorner.CornerRadius = UDim.new(0, Self.Rounded and 5 or 0)
                    Knob.Visible = false
                    CheckVec.Visible = false
                    StateText.Visible = true
                    StateText.Text = val and "ON" or "OFF"
                    HitBtn.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                    hitStroke.Color = val and CurrentTheme.AccentSecondary or CurrentTheme.Stroke
                else
                    HitBtn.Size = UDim2.fromOffset(40, 20)
                    HitBtn.Position = UDim2.new(1, -46, 0.5, -10)
                    hitCorner.CornerRadius = UDim.new(0, Self.Rounded and 10 or 0)
                    Knob.Visible = true
                    CheckVec.Visible = false
                    StateText.Visible = false
                    HitBtn.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                    TweenService:Create(Knob, TWEEN_FAST, {
                        Position = val and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
                    }):Play()
                end
            end

            table.insert(Self.ToggleStyleUpdaters, RenderToggleVisual)
            RenderToggleVisual(currentStyle)

            HitBtn.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                RenderToggleVisual()
                if callback then task.spawn(callback, nextVal) end
            end)
        end

        function Builder:Slider(label, flag, min, max, default, suffix, callback)
            suffix = suffix or ""
            Self.Flags[flag] = default or min

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight - 2)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextMuted", false, 0)
            Title.Size = UDim2.new(0.38, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(0.34, 0, 0, 6)
            Track.Position = UDim2.new(0.39, 0, 0.5, -3)
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

            local ValTxt = CreateStylizedText(Row, tostring(Self.Flags[flag]) .. suffix, LayoutPreset.FontSmall, "TextPrimary", true, 0)
            ValTxt.Size = UDim2.new(0.24, 0, 1, 0)
            ValTxt.Position = UDim2.new(0.74, 0, 0, 0) -- Lebih masuk ke dalam agar tidak mepet ujung kanan[cite: 4]
            ValTxt.TextXAlignment = Enum.TextXAlignment.Right

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
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight - 2)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextMuted", false, 0)
            Title.Size = UDim2.new(0.50, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Controls = Instance.new("Frame")
            Controls.Size = UDim2.fromOffset(92, 24)
            Controls.Position = UDim2.new(1, -48, 0.5, -12) -- Lebih masuk ke dalam[cite: 4]
            Controls.AnchorPoint = Vector2.new(1, 0)
            Controls.Parent = Row
            BindTheme(Controls, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(Controls, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local Minus = Instance.new("TextButton")
            Minus.Size = UDim2.new(0, 26, 1, 0)
            Minus.BackgroundTransparency = 1
            Minus.FontFace = CustomFontFace
            Minus.Text = "-"
            Minus.TextSize = 16
            Minus.Parent = Controls
            BindTheme(Minus, "TextColor3", "TextPrimary", "ControlBg")

            local ValLbl = CreateStylizedText(Controls, tostring(Self.Flags[flag]), LayoutPreset.FontBody, "Accent", true, 0)
            ValLbl.Size = UDim2.new(1, -52, 1, 0)
            ValLbl.Position = UDim2.new(0, 26, 0, 0)

            local Plus = Instance.new("TextButton")
            Plus.Size = UDim2.new(0, 26, 1, 0)
            Plus.Position = UDim2.new(1, -26, 0, 0)
            Plus.BackgroundTransparency = 1
            Plus.FontFace = CustomFontFace
            Plus.Text = "+"
            Plus.TextSize = 16
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
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight - 2)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextMuted", false, 0)
            Title.Size = UDim2.new(0.40, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.56, 0, 0, 24)
            DropBtn.Position = UDim2.new(1, -48, 0.5, -12) -- Jarak aman dari ujung kanan[cite: 4]
            DropBtn.AnchorPoint = Vector2.new(1, 0)
            DropBtn.Text = ""
            DropBtn.AutoButtonColor = false
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(DropBtn, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local SelectedTxt = CreateStylizedText(DropBtn, tostring(Self.Flags[flag]), LayoutPreset.FontSmall, "TextPrimary", true, 0)
            SelectedTxt.Position = UDim2.new(0, 10, 0, 0)
            SelectedTxt.Size = UDim2.new(1, -28, 1, 0)
            SelectedTxt.TextXAlignment = Enum.TextXAlignment.Left

            local chev = DrawVectorIcon(DropBtn, "ChevronDown", 12, "TextMuted", BindTheme)
            chev.Position = UDim2.new(1, -16, 0.5, -6)

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
            BoxHolder.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            BoxHolder.BackgroundTransparency = 1
            BoxHolder.Parent = scrollingPage

            local Title = CreateStylizedText(BoxHolder, label, LayoutPreset.FontBody, "TextMuted", false, 0)
            Title.Size = UDim2.new(0.38, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0.58, 0, 0, 26)
            InputBox.Position = UDim2.new(1, -48, 0.5, -13) -- Diberi ruang aman di sisi kanan[cite: 4]
            InputBox.AnchorPoint = Vector2.new(1, 0)
            InputBox.FontFace = CustomFontFace
            InputBox.PlaceholderText = placeholder or "Enter value..."
            InputBox.Text = Self.Flags[flag]
            InputBox.TextSize = LayoutPreset.FontSmall
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

                local EventTxt = CreateStylizedText(Row, item.Text, LayoutPreset.FontBody, "TextPrimary", false, 0)
                EventTxt.Position = UDim2.new(0, 20, 0, 0)
                EventTxt.Size = UDim2.new(0.68, 0, 1, 0)
                EventTxt.TextXAlignment = Enum.TextXAlignment.Left

                local TimeTxt = CreateStylizedText(Row, item.Time, LayoutPreset.FontSmall, "TextMuted", false, 0)
                TimeTxt.Position = UDim2.new(0.70, 0, 0, 0)
                TimeTxt.Size = UDim2.new(0.30, -6, 1, 0)
                TimeTxt.TextXAlignment = Enum.TextXAlignment.Right
            end
        end

        return Builder
    end

    local function CreateScrollPage(parent)
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.fromScale(1, 1)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Visible = false
        Page.Parent = parent
        BindTheme(Page, "ScrollBarImageColor3", "Accent")

        local p = LayoutPreset.PanelPadding
        local Pad = Instance.new("UIPadding")
        Pad.PaddingTop = UDim.new(0, p)
        Pad.PaddingBottom = UDim.new(0, p)
        Pad.PaddingLeft = UDim.new(0, p)
        Pad.PaddingRight = UDim.new(0, p + 6) -- Margin kanan ekstra agar tidak ada teks yang mentok[cite: 4]
        Pad.Parent = Page

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, LayoutPreset.ItemSpacing)
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
            local vecTabIcon = DrawVectorIcon(NavBtn, logo or name, 17, "TextMuted", BindTheme)
            vecTabIcon.Position = UDim2.new(0, 12, 0.5, -8)
        end

        local NameLbl = CreateStylizedText(NavBtn, name, LayoutPreset.FontBody + 1, "TextPrimary", true, 0)
        NameLbl.Position = UDim2.new(0, 40, 0, 0)
        NameLbl.Size = UDim2.new(1, -46, 1, 0)
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left

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
            end
            CenterPage.Visible = true
            if FeatureObj.HasCustomRight then
                RightPage.Visible = true
            elseif Self.Features[1] then
                Self.Features[1].RightPage.Visible = true
            end
            ActiveLine.Visible = true
            NavBtn.BackgroundTransparency = 0.86
            Self.ActiveFeature = FeatureObj
        end

        NavBtn.MouseButton1Click:Connect(ActivateFeature)
        if #Self.Features == 1 then ActivateFeature() end

        return function(definition)
            if type(definition) == "table" then
                if type(definition.center) == "function" then definition.center(CreateCanvasBuilder(CenterPage)) end
                if type(definition.right) == "function" then
                    FeatureObj.HasCustomRight = true
                    definition.right(CreateCanvasBuilder(RightPage))
                    if Self.ActiveFeature == FeatureObj then RightPage.Visible = true end
                end
            end
            return FeatureObj
        end
    end

    Self.Call(Self.SideCount)
    return Self
end

return ImGui
