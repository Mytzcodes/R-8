--[[
    FRAMEWORK : R&8_DV ImGui Architecture (v6.3 - Clean Flat Colourful, Large Readable Font & Borderless Active Buttons)
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

local TWEEN_FAST   = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MEDIUM = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_POP    = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- UKURAN FONT DIPERBESAR AGAR JELAS & MUDAH DIBACA USER
local LayoutPreset = {
    WindowWidth   = 1060,
    WindowHeight  = 620,
    OuterMargin   = 12,
    PanelPadding  = 16,
    ItemSpacing   = 12,
    CardPadding   = 16,
    CardSpacing   = 10,
    RowHeight     = 38,
    FontHeader    = 34,
    FontCardTitle = 22,
    FontSection   = 20,
    FontBody      = 20,
    FontSmall     = 18
}

local function GetSafeGuiParent()
    local ok, res = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if ok and res then return res end
    return LocalPlayer and LocalPlayer:WaitForChild("PlayerGui") or CoreGui
end

local function GetLuminance(col)
    if not col then return 0 end
    return 0.2126 * col.R + 0.7152 * col.G + 0.0722 * col.B
end

local function GetReadableTextColor(bgColor, preferredColor)
    if not bgColor or not preferredColor then
        return preferredColor or Color3.fromRGB(248, 250, 255)
    end
    local bgLum = GetLuminance(bgColor)
    local txtLum = GetLuminance(preferredColor)
    if math.abs(bgLum - txtLum) < 0.22 then
        if bgLum > 0.52 then
            return Color3.fromRGB(16, 20, 28)
        else
            return Color3.fromRGB(248, 250, 255)
        end
    end
    return preferredColor
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

-- =========================================================================
-- 5 PALET TEMA WARNA COLOURFUL (KONTRAS TINGGI & SANGAT MUDAH DIBACA)
-- =========================================================================
local Themes = {
    ["Blue Night Sky"] = {
        MainBg          = Color3.fromRGB(11, 15, 25),
        PanelBg         = Color3.fromRGB(16, 22, 36),
        CardBg          = Color3.fromRGB(23, 32, 52),
        ControlBg       = Color3.fromRGB(34, 46, 74),
        ControlActiveBg = Color3.fromRGB(44, 62, 102),
        Accent          = Color3.fromRGB(78, 168, 255),
        AccentSecondary = Color3.fromRGB(145, 228, 255),
        Stroke          = Color3.fromRGB(48, 66, 102),
        TextPrimary     = Color3.fromRGB(248, 252, 255),
        TextMuted       = Color3.fromRGB(192, 212, 242),
        OnAccentText    = Color3.fromRGB(10, 16, 28)
    },
    ["Orange Sand"] = {
        MainBg          = Color3.fromRGB(22, 16, 13),
        PanelBg         = Color3.fromRGB(31, 22, 18),
        CardBg          = Color3.fromRGB(44, 32, 26),
        ControlBg       = Color3.fromRGB(62, 45, 36),
        ControlActiveBg = Color3.fromRGB(84, 58, 44),
        Accent          = Color3.fromRGB(255, 152, 60),
        AccentSecondary = Color3.fromRGB(255, 218, 130),
        Stroke          = Color3.fromRGB(86, 62, 48),
        TextPrimary     = Color3.fromRGB(255, 249, 242),
        TextMuted       = Color3.fromRGB(226, 198, 176),
        OnAccentText    = Color3.fromRGB(24, 14, 8)
    },
    ["Midnight Monokai"] = {
        MainBg          = Color3.fromRGB(17, 18, 15),
        PanelBg         = Color3.fromRGB(25, 27, 22),
        CardBg          = Color3.fromRGB(35, 38, 31),
        ControlBg       = Color3.fromRGB(50, 54, 44),
        ControlActiveBg = Color3.fromRGB(66, 72, 56),
        Accent          = Color3.fromRGB(166, 226, 46),
        AccentSecondary = Color3.fromRGB(102, 217, 239),
        Stroke          = Color3.fromRGB(70, 75, 60),
        TextPrimary     = Color3.fromRGB(250, 252, 245),
        TextMuted       = Color3.fromRGB(202, 210, 188),
        OnAccentText    = Color3.fromRGB(16, 20, 10)
    },
    ["Sakura Cyber Neon"] = {
        MainBg          = Color3.fromRGB(21, 13, 25),
        PanelBg         = Color3.fromRGB(31, 19, 38),
        CardBg          = Color3.fromRGB(44, 27, 55),
        ControlBg       = Color3.fromRGB(62, 38, 78),
        ControlActiveBg = Color3.fromRGB(84, 48, 106),
        Accent          = Color3.fromRGB(255, 96, 180),
        AccentSecondary = Color3.fromRGB(255, 186, 230),
        Stroke          = Color3.fromRGB(88, 52, 110),
        TextPrimary     = Color3.fromRGB(255, 246, 253),
        TextMuted       = Color3.fromRGB(228, 194, 222),
        OnAccentText    = Color3.fromRGB(24, 10, 22)
    },
    ["Emerald Aurora"] = {
        MainBg          = Color3.fromRGB(10, 20, 18),
        PanelBg         = Color3.fromRGB(15, 30, 27),
        CardBg          = Color3.fromRGB(22, 43, 39),
        ControlBg       = Color3.fromRGB(32, 60, 54),
        ControlActiveBg = Color3.fromRGB(42, 82, 72),
        Accent          = Color3.fromRGB(46, 230, 166),
        AccentSecondary = Color3.fromRGB(142, 255, 214),
        Stroke          = Color3.fromRGB(46, 86, 76),
        TextPrimary     = Color3.fromRGB(244, 255, 251),
        TextMuted       = Color3.fromRGB(186, 228, 214),
        OnAccentText    = Color3.fromRGB(8, 22, 18)
    }
}

local ThemeOrder = {
    "Blue Night Sky",
    "Orange Sand",
    "Midnight Monokai",
    "Sakura Cyber Neon",
    "Emerald Aurora"
}

local function ApplySurfaceStyle(frame, radiusScale, strokeColor, themeBindings, radiusBindings, strokeType, skipStroke)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radiusScale)
    corner.Parent = frame
    table.insert(radiusBindings, {Instance = corner, BaseRadius = radiusScale})

    if skipStroke then
        return corner, nil
    end

    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Thickness = 1
    stroke.Color = strokeColor
    stroke.Transparency = 0.35
    stroke.Parent = frame
    table.insert(themeBindings, {Instance = stroke, Prop = "Color", Key = strokeType or "Stroke"})
    return corner, stroke
end

local function DrawVectorIcon(parent, iconName, sizePx, themeKey, bindThemeFn)
    local Holder = Instance.new("Frame")
    Holder.Name = "VectorIcon_" .. tostring(iconName)
    Holder.Size = UDim2.fromOffset(sizePx, sizePx)
    Holder.BackgroundTransparency = 1
    Holder.Active = false
    Holder.Parent = parent

    local function Line(w, h, posX, posY, rot, radius)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromScale(posX, posY)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Rotation = rot or 0
        f.BorderSizePixel = 0
        f.Active = false
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
        f.Active = false
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
    elseif key == "collect" or key == "layers" or key == "palette" or key == "sparkles" then
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.38, 3, 1.6, 45)
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.60, 3, 1.6, 45)
    elseif key == "check" then
        -- Ikon centang yang presisi, tebal, dan menyambung sempurna
        Line(sizePx * 0.36, 2.6, 0.30, 0.56, 45, 1)
        Line(sizePx * 0.64, 2.6, 0.60, 0.48, -45, 1)
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
        Line(6, 2, 0.38, 0.5, 40, 1)
        Line(6, 2, 0.62, 0.5, -40, 1)
    elseif key == "arrowright" then
        Line(8, 2, 0.45, 0.5, 0, 1)
        Line(5, 2, 0.68, 0.38, 40, 1)
        Line(5, 2, 0.68, 0.62, -40, 1)
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
        BgTransparency = math.clamp(tonumber(config.BgTransparency) or 0.04, 0, 0.65),
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.84,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode == true),
        AutoLoading = (config.AutoLoading ~= false),
        IsMinimized = false,
        IsAlive = true,
        Flags = {},
        FlagListeners = {},
        Features = {},
        ActiveFeature = nil,
        ThemeBindings = {},
        GradientBindings = {},
        RadiusBindings = {},
        ToggleStyleUpdaters = {},
        Connections = {}
    }

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Blue Night Sky"]
    local CustomFontFace = GetFrameworkFont()
    local ResolvedMasterLogo = ResolveImage(MASTER_LOGO_URL)

    local function TrackConnection(conn)
        if conn then table.insert(Self.Connections, conn) end
        return conn
    end

    function Self:GetThemes()
        return ThemeOrder
    end

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
        local col = CurrentTheme[themeKey] or CurrentTheme.TextPrimary
        if bgKeyForContrast then col = GetReadableTextColor(CurrentTheme[bgKeyForContrast], col) end
        instance[prop] = col
    end

    local function BuildGradientSequence(mode, theme)
        if mode == "ShortcutSurface" then
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.CardBg),
                ColorSequenceKeypoint.new(0.65, theme.PanelBg),
                ColorSequenceKeypoint.new(1, theme.MainBg)
            })
        elseif mode == "CanvasBg" then
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.CardBg),
                ColorSequenceKeypoint.new(0.55, theme.PanelBg),
                ColorSequenceKeypoint.new(1, theme.ControlBg)
            })
        elseif mode == "LoaderBar" then
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, theme.Accent),
                ColorSequenceKeypoint.new(1, theme.AccentSecondary)
            })
        end
        return ColorSequence.new(theme.TextPrimary)
    end

    local function BindGradient(gradInstance, mode)
        gradInstance.Color = BuildGradientSequence(mode, CurrentTheme)
        table.insert(Self.GradientBindings, {Instance = gradInstance, Mode = mode})
    end

    -- TEXT FACTORY: BERSIH, TAJAM, TANPA EFEK 2.5D/3D YANG MERUSAK PIXEL FONT
    local function CreateStylizedText(parent, text, sizePx, colorKey, _, tracking)
        local Lbl = Instance.new("TextLabel")
        Lbl.BackgroundTransparency = 1
        Lbl.FontFace = CustomFontFace
        Lbl.Text = ApplyLetterSpacing(text, tracking or Self.LetterSpacing)
        Lbl.TextSize = sizePx or LayoutPreset.FontBody
        Lbl.Active = false
        Lbl.Parent = parent
        BindTheme(Lbl, "TextColor3", colorKey or "TextPrimary", "PanelBg")
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
    FocusBlocker.BackgroundTransparency = 0.55
    FocusBlocker.BackgroundColor3 = Color3.fromRGB(3, 5, 8)
    FocusBlocker.Text = ""
    FocusBlocker.AutoButtonColor = false
    FocusBlocker.Active = true
    FocusBlocker.Modal = true
    FocusBlocker.Visible = Self.FocusMode
    FocusBlocker.Parent = ScreenGui

    -- =========================================================================
    -- FLOATING SHORTCUT POPUP ICON MENU (TANPA DUPLIKAT BORDER)
    -- =========================================================================
    local MinimizeIconBtn = Instance.new("ImageButton")
    MinimizeIconBtn.Name = "R8DV_FloatingShortcut"
    MinimizeIconBtn.Size = UDim2.fromOffset(60, 60)
    MinimizeIconBtn.Position = UDim2.new(0, 52, 0.5, 0)
    MinimizeIconBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIconBtn.BackgroundTransparency = 0.04
    MinimizeIconBtn.AutoButtonColor = false
    MinimizeIconBtn.Image = ""
    MinimizeIconBtn.Visible = false
    MinimizeIconBtn.ZIndex = 800
    MinimizeIconBtn.Parent = ScreenGui
    BindTheme(MinimizeIconBtn, "BackgroundColor3", "CardBg")

    local MinOuterCorner = Instance.new("UICorner")
    MinOuterCorner.CornerRadius = UDim.new(0.26, 0)
    MinOuterCorner.Parent = MinimizeIconBtn

    local MinBgGrad = Instance.new("UIGradient")
    MinBgGrad.Rotation = 45
    BindGradient(MinBgGrad, "ShortcutSurface")
    MinBgGrad.Parent = MinimizeIconBtn

    local MinEmblemImg = Instance.new("ImageLabel")
    MinEmblemImg.Size = UDim2.fromScale(0.76, 0.76)
    MinEmblemImg.Position = UDim2.fromScale(0.5, 0.5)
    MinEmblemImg.AnchorPoint = Vector2.new(0.5, 0.5)
    MinEmblemImg.BackgroundTransparency = 1
    MinEmblemImg.ScaleType = Enum.ScaleType.Fit
    MinEmblemImg.Image = ResolvedMasterLogo
    MinEmblemImg.Active = false
    MinEmblemImg.ZIndex = 802
    MinEmblemImg.Parent = MinimizeIconBtn

    if ResolvedMasterLogo == "" then
        local fbVec = DrawVectorIcon(MinimizeIconBtn, "AutoFarm", 28, "Accent", BindTheme)
        fbVec.Position = UDim2.fromScale(0.5, 0.5)
        fbVec.AnchorPoint = Vector2.new(0.5, 0.5)
        fbVec.ZIndex = 803
    end

    -- =========================================================================
    -- MAIN WINDOW CONTAINER
    -- =========================================================================
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.fromOffset(LayoutPreset.WindowWidth, LayoutPreset.WindowHeight)
    MainWindow.Position = UDim2.fromScale(0.5, 0.5)
    MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    MainWindow.BackgroundTransparency = 1
    MainWindow.Active = true
    MainWindow.Parent = ScreenGui

    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainWindow

    local function ComputeTargetScale()
        local cam = workspace.CurrentCamera
        if not cam then return Self.UIScale end
        local vp = cam.ViewportSize
        local autoFit = math.min(1, (vp.X * 0.94) / LayoutPreset.WindowWidth, (vp.Y * 0.92) / LayoutPreset.WindowHeight)
        return math.clamp(autoFit * Self.UIScale, 0.45, 1.45)
    end

    local function UpdateResponsiveScale()
        if not Self.IsMinimized then WindowScale.Scale = ComputeTargetScale() end
    end

    function Self:SetScale(scaleVal)
        Self.UIScale = math.clamp(tonumber(scaleVal) or 1, 0.5, 1.5)
        UpdateResponsiveScale()
    end

    TrackConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(UpdateResponsiveScale))
    if workspace.CurrentCamera then
        TrackConnection(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale))
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

    local Watermark = CreateStylizedText(MainWindow, "(C) " .. Self.Copyright .. " ENGINE", 15, "TextMuted", false, 0)
    Watermark.Size = UDim2.new(0, 180, 0, 18)
    Watermark.Position = UDim2.new(1, -188, 1, -19)
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    Watermark.TextTransparency = 0.35

    -- 1. LEFT SIDEBAR
    local m = LayoutPreset.OuterMargin
    local LeftSidebar = Instance.new("Frame")
    LeftSidebar.Name = "LeftSidebar"
    LeftSidebar.Position = UDim2.new(0, m, 0, m)
    LeftSidebar.Size = UDim2.new(0.23, -m, 1, -(m * 2))
    LeftSidebar.BackgroundTransparency = Self.BgTransparency
    LeftSidebar.ClipsDescendants = true
    LeftSidebar.Parent = MainWindow
    BindTheme(LeftSidebar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(LeftSidebar, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local SidebarGlow = Instance.new("Frame")
    SidebarGlow.Size = UDim2.fromOffset(150, 150)
    SidebarGlow.Position = UDim2.new(0.5, 0, 0, 52)
    SidebarGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    SidebarGlow.BackgroundTransparency = 0.90
    SidebarGlow.BorderSizePixel = 0
    SidebarGlow.Parent = LeftSidebar
    BindTheme(SidebarGlow, "BackgroundColor3", "Accent")
    local sgCorner = Instance.new("UICorner")
    sgCorner.CornerRadius = UDim.new(1, 0)
    sgCorner.Parent = SidebarGlow

    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = UDim2.new(1, 0, 0, 124)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(78, 78)
    BrandLogo.Position = UDim2.fromScale(0.5, 0.45)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolvedMasterLogo
    BrandLogo.Parent = LogoHolder

    if ResolvedMasterLogo == "" then
        local fallbackCrest = DrawVectorIcon(LogoHolder, "AutoFarm", 42, "Accent", BindTheme)
        fallbackCrest.Position = UDim2.fromScale(0.5, 0.45)
        fallbackCrest.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local ThemeTagLbl = CreateStylizedText(LogoHolder, Self.ThemeName, 16, "AccentSecondary", false, 0)
    ThemeTagLbl.Size = UDim2.new(1, -16, 0, 20)
    ThemeTagLbl.Position = UDim2.new(0, 8, 1, -24)

    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Position = UDim2.new(0, 10, 0, 128)
    NavScroll.Size = UDim2.new(1, -20, 1, -138)
    NavScroll.BackgroundTransparency = 1
    NavScroll.ScrollBarThickness = 2
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.Parent = LeftSidebar
    BindTheme(NavScroll, "ScrollBarImageColor3", "Accent")

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 8)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = NavScroll

    -- 2. TOP IMGUI HEADER BAR
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.23, 8, 0, m)
    TopBar.Size = UDim2.new(0.77, -(m + 8), 0, 44)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 10, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local TopLogoIcon = Instance.new("ImageLabel")
    TopLogoIcon.Position = UDim2.new(0, 14, 0.5, -11)
    TopLogoIcon.Size = UDim2.fromOffset(22, 22)
    TopLogoIcon.BackgroundTransparency = 1
    TopLogoIcon.ScaleType = Enum.ScaleType.Fit
    TopLogoIcon.Image = ResolvedMasterLogo
    TopLogoIcon.Parent = TopBar

    local TopTitle = CreateStylizedText(TopBar, Self.Title .. "   |   " .. Self.Copyright, 21, "TextPrimary", false, 0)
    TopTitle.Position = UDim2.new(0, 44, 0, 0)
    TopTitle.Size = UDim2.new(0.65, 0, 1, 0)
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left

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

    local function CreateVectorWindowBtn(vectorType, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(28, 28)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ControlsHolder
        BindTheme(btn, "BackgroundColor3", "ControlBg")
        ApplySurfaceStyle(btn, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)
        local icon = DrawVectorIcon(btn, vectorType, 15, "TextPrimary", BindTheme)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TWEEN_FAST, {BackgroundTransparency = 0.2}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TWEEN_FAST, {BackgroundTransparency = 1}):Play()
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL & RIGHT PANEL
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.23, 8, 0, m + 52)
    CenterPanel.Size = UDim2.new(0.50, -8, 1, -(m * 2 + 52))
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.73, 8, 0, m + 52)
    RightPanel.Size = UDim2.new(0.27, -(m + 8), 1, -(m * 2 + 52))
    RightPanel.BackgroundTransparency = Self.BgTransparency
    RightPanel.ClipsDescendants = true
    RightPanel.Parent = MainWindow
    BindTheme(RightPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(RightPanel, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

    -- DRAG LOGIC (WINDOW & FLOATING SHORTCUT ICON)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    local iconDragging, iconDragInput, iconDragStart, iconStartPos = false, nil, nil, nil
    local movedDist = 0

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

    MinimizeIconBtn.MouseEnter:Connect(function()
        if not iconDragging then
            TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(64, 64)}):Play()
        end
    end)
    MinimizeIconBtn.MouseLeave:Connect(function()
        if not iconDragging then
            TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(60, 60)}):Play()
        end
    end)

    MinimizeIconBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            iconDragging = true
            movedDist = 0
            iconDragStart = input.Position
            iconStartPos = MinimizeIconBtn.Position
            TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(54, 54)}):Play()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    iconDragging = false
                    TweenService:Create(MinimizeIconBtn, TWEEN_FAST, {Size = UDim2.fromOffset(60, 60)}):Play()
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

    TrackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif input == iconDragInput and iconDragging then
            local delta = input.Position - iconDragStart
            movedDist = delta.Magnitude
            MinimizeIconBtn.Position = UDim2.new(
                iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
                iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
            )
        end
    end))

    function Self:MinimizeToIcon()
        if Self.IsMinimized then return end
        Self.IsMinimized = true
        FocusBlocker.Visible = false
        if Self.FocusMode then
            pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
        end

        local shrink = TweenService:Create(WindowScale, TWEEN_FAST, {Scale = 0})
        shrink:Play()
        shrink.Completed:Connect(function()
            if Self.IsMinimized then
                MainWindow.Visible = false
                MinimizeIconBtn.Size = UDim2.fromOffset(12, 12)
                MinimizeIconBtn.Visible = true
                TweenService:Create(MinimizeIconBtn, TWEEN_POP, {Size = UDim2.fromOffset(60, 60)}):Play()
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
                if Self.FocusMode then
                    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
                end
                TweenService:Create(WindowScale, TWEEN_POP, {Scale = ComputeTargetScale()}):Play()
            end
        end)
    end

    function Self:ToggleMenu(forceState)
        local shouldOpen = (forceState ~= nil) and forceState or Self.IsMinimized
        if shouldOpen then Self:RestoreFromIcon() else Self:MinimizeToIcon() end
    end

    function Self:Destroy()
        Self.IsAlive = false
        for _, c in ipairs(Self.Connections) do
            pcall(function() c:Disconnect() end)
        end
        Self.Connections = {}
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end

    function Self.Call(sideCount)
        Self.SideCount = (sideCount == 2) and 2 or 3
        if Self.SideCount == 3 then
            RightPanel.Visible = true
            TweenService:Create(CenterPanel, TWEEN_MEDIUM, { Size = UDim2.new(0.50, -8, 1, -(m * 2 + 52)) }):Play()
        else
            RightPanel.Visible = false
            TweenService:Create(CenterPanel, TWEEN_MEDIUM, { Size = UDim2.new(0.77, -(m + 8), 1, -(m * 2 + 52)) }):Play()
        end
        return Self
    end

    CreateVectorWindowBtn("Menu", function() Self.Call(Self.SideCount == 3 and 2 or 3) end)
    CreateVectorWindowBtn("Minimize", function() Self:MinimizeToIcon() end)
    local isMaximized = false
    CreateVectorWindowBtn("Maximize", function()
        isMaximized = not isMaximized
        TweenService:Create(MainWindow, TWEEN_MEDIUM, {
            Size = isMaximized and UDim2.fromOffset(1180, 680) or UDim2.fromOffset(LayoutPreset.WindowWidth, LayoutPreset.WindowHeight)
        }):Play()
    end)
    CreateVectorWindowBtn("Close", function() Self:MinimizeToIcon() end)

    function Self:SetTheme(themeName)
        if not Themes[themeName] then return end
        Self.ThemeName = themeName
        CurrentTheme = Themes[themeName]
        if ThemeTagLbl and ThemeTagLbl.Parent then
            ThemeTagLbl.Text = ApplyLetterSpacing(themeName, Self.LetterSpacing)
        end
        for _, b in ipairs(Self.ThemeBindings) do
            if b.Instance and b.Instance.Parent then
                local col = CurrentTheme[b.Key] or CurrentTheme.TextPrimary
                if b.BgKey then col = GetReadableTextColor(CurrentTheme[b.BgKey], col) end
                b.Instance[b.Prop] = col
            end
        end
        for _, g in ipairs(Self.GradientBindings) do
            if g.Instance and g.Instance.Parent then
                g.Instance.Color = BuildGradientSequence(g.Mode, CurrentTheme)
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
        for _, fn in ipairs(Self.ToggleStyleUpdaters) do pcall(fn) end
    end

    function Self:SetTransparency(alpha)
        Self.BgTransparency = math.clamp(tonumber(alpha) or 0.04, 0, 0.65)
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

    TrackConnection(UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Self.ToggleKey then Self:ToggleMenu() end
    end))

    -- =========================================================================
    -- ILLUSTRATED ANIMATED LOADER (NYAMAN, JELAS & RINGAN)
    -- =========================================================================
    function Self:RunInternalLoader(duration)
        duration = duration or 1.05
        local Loader = Instance.new("Frame")
        Loader.Name = "FrameworkLoader"
        Loader.Size = UDim2.fromScale(1, 1)
        Loader.BackgroundColor3 = CurrentTheme.MainBg
        Loader.ClipsDescendants = true
        Loader.ZIndex = 500
        Loader.Parent = MainWindow
        ApplySurfaceStyle(Loader, 14, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

        local LoaderGrad = Instance.new("UIGradient")
        LoaderGrad.Rotation = 135
        BindGradient(LoaderGrad, "CanvasBg")
        LoaderGrad.Parent = Loader

        local ArtCanvas = Instance.new("Frame")
        ArtCanvas.Size = UDim2.fromOffset(160, 160)
        ArtCanvas.Position = UDim2.new(0.5, 0, 0.30, 0)
        ArtCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
        ArtCanvas.BackgroundTransparency = 1
        ArtCanvas.ZIndex = 501
        ArtCanvas.Parent = Loader

        local OuterOrbit = Instance.new("Frame")
        OuterOrbit.Size = UDim2.fromOffset(126, 126)
        OuterOrbit.Position = UDim2.fromScale(0.5, 0.5)
        OuterOrbit.AnchorPoint = Vector2.new(0.5, 0.5)
        OuterOrbit.BackgroundTransparency = 0.88
        OuterOrbit.BackgroundColor3 = CurrentTheme.ControlBg
        OuterOrbit.Rotation = 15
        OuterOrbit.ZIndex = 501
        OuterOrbit.Parent = ArtCanvas
        local ooCorner = Instance.new("UICorner")
        ooCorner.CornerRadius = UDim.new(0.32, 0)
        ooCorner.Parent = OuterOrbit

        local InnerOrbit = Instance.new("Frame")
        InnerOrbit.Size = UDim2.fromOffset(98, 98)
        InnerOrbit.Position = UDim2.fromScale(0.5, 0.5)
        InnerOrbit.AnchorPoint = Vector2.new(0.5, 0.5)
        InnerOrbit.BackgroundTransparency = 0.78
        InnerOrbit.BackgroundColor3 = CurrentTheme.CardBg
        InnerOrbit.Rotation = -20
        InnerOrbit.ZIndex = 501
        InnerOrbit.Parent = ArtCanvas
        local ioCorner = Instance.new("UICorner")
        ioCorner.CornerRadius = UDim.new(0.36, 0)
        ioCorner.Parent = InnerOrbit

        local LoaderIcon = Instance.new("ImageLabel")
        LoaderIcon.Size = UDim2.fromOffset(76, 76)
        LoaderIcon.Position = UDim2.fromScale(0.5, 0.5)
        LoaderIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        LoaderIcon.BackgroundTransparency = 1
        LoaderIcon.ScaleType = Enum.ScaleType.Fit
        LoaderIcon.Image = ResolvedMasterLogo
        LoaderIcon.ZIndex = 503
        LoaderIcon.Parent = ArtCanvas

        if ResolvedMasterLogo == "" then
            local fallbackVec = DrawVectorIcon(ArtCanvas, "AutoFarm", 42, "Accent", BindTheme)
            fallbackVec.Position = UDim2.fromScale(0.5, 0.5)
            fallbackVec.AnchorPoint = Vector2.new(0.5, 0.5)
            fallbackVec.ZIndex = 503
        end

        TweenService:Create(OuterOrbit, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = 105, Size = UDim2.fromOffset(136, 136)}):Play()
        TweenService:Create(InnerOrbit, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Rotation = -110}):Play()

        local LoadTitle = CreateStylizedText(Loader, Self.Title, 34, "TextPrimary", false, 1)
        LoadTitle.Size = UDim2.new(1, 0, 0, 38)
        LoadTitle.Position = UDim2.new(0, 0, 0.49, 0)
        LoadTitle.ZIndex = 502

        local LoadSub = CreateStylizedText(Loader, "Loading Colourful Theme & Illustrated Interface...", LayoutPreset.FontBody, "TextMuted", false, 0)
        LoadSub.Size = UDim2.new(1, 0, 0, 24)
        LoadSub.Position = UDim2.new(0, 0, 0.56, 0)
        LoadSub.ZIndex = 502

        local BarBg = Instance.new("Frame")
        BarBg.Size = UDim2.fromOffset(300, 8)
        BarBg.Position = UDim2.new(0.5, -150, 0.65, 0)
        BarBg.ZIndex = 502
        BarBg.BorderSizePixel = 0
        BarBg.Parent = Loader
        BindTheme(BarBg, "BackgroundColor3", "ControlBg")
        ApplySurfaceStyle(BarBg, 4, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

        local BarFill = Instance.new("Frame")
        BarFill.Size = UDim2.new(0, 0, 1, 0)
        BarFill.ZIndex = 503
        BarFill.BorderSizePixel = 0
        BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        BarFill.Parent = BarBg
        ApplySurfaceStyle(BarFill, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

        local BarFillGrad = Instance.new("UIGradient")
        BindGradient(BarFillGrad, "LoaderBar")
        BarFillGrad.Parent = BarFill

        local PctTxt = CreateStylizedText(Loader, "0%  •  " .. Self.ThemeName, 18, "Accent", false, 0)
        PctTxt.Size = UDim2.new(1, 0, 0, 22)
        PctTxt.Position = UDim2.new(0, 0, 0.68, 0)
        PctTxt.ZIndex = 502

        task.spawn(function()
            pcall(function() ContentProvider:PreloadAsync({BrandLogo, TopLogoIcon, MinEmblemImg, LoaderIcon}) end)
        end)

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.82, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()

        task.spawn(function()
            local steps = 10
            local stepWait = (duration * 0.78) / steps
            for i = 1, steps do
                if not Loader or not Loader.Parent then break end
                local pct = math.min(100, math.floor((i / steps) * 100))
                PctTxt.Text = tostring(pct) .. "%  •  " .. Self.ThemeName
                task.wait(stepWait)
            end
        end)

        task.delay(duration, function()
            if Loader and Loader.Parent then
                TweenService:Create(Loader, TWEEN_MEDIUM, {BackgroundTransparency = 1}):Play()
                for _, desc in ipairs(Loader:GetDescendants()) do
                    if desc:IsA("TextLabel") then
                        TweenService:Create(desc, TWEEN_FAST, {TextTransparency = 1}):Play()
                    elseif desc:IsA("ImageLabel") then
                        TweenService:Create(desc, TWEEN_FAST, {ImageTransparency = 1}):Play()
                    elseif desc:IsA("Frame") then
                        TweenService:Create(desc, TWEEN_FAST, {BackgroundTransparency = 1}):Play()
                    elseif desc:IsA("UIStroke") then
                        TweenService:Create(desc, TWEEN_FAST, {Transparency = 1}):Play()
                    end
                end
                task.wait(0.2)
                if Loader and Loader.Parent then Loader:Destroy() end
            end
        end)
    end

    if Self.AutoLoading then Self:RunInternalLoader(1.0) end

    -- =========================================================================
    -- WIDGET FACTORY (CANVAS BUILDER)
    -- =========================================================================
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

        function Builder:Header(title, subtitle, badgeText)
            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Size = UDim2.new(1, 0, 0, 62)
            HeaderFrame.BackgroundTransparency = 1
            HeaderFrame.Parent = scrollingPage

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(0, 4, 0, 50)
            AccentBar.Position = UDim2.new(0, 0, 0, 6)
            AccentBar.BorderSizePixel = 0
            AccentBar.Parent = HeaderFrame
            BindTheme(AccentBar, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(AccentBar, 3, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

            local TitleLbl = CreateStylizedText(HeaderFrame, title, LayoutPreset.FontHeader, "TextPrimary", false, 0)
            TitleLbl.Position = UDim2.new(0, 14, 0, 2)
            TitleLbl.Size = UDim2.new(0.62, 0, 0, 34)
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

            local SubLbl = CreateStylizedText(HeaderFrame, subtitle or "", LayoutPreset.FontSmall, "TextMuted", false, 0)
            SubLbl.Position = UDim2.new(0, 14, 0, 36)
            SubLbl.Size = UDim2.new(0.62, 0, 0, 22)
            SubLbl.TextXAlignment = Enum.TextXAlignment.Left

            if badgeText then
                local Pill = Instance.new("Frame")
                Pill.Size = UDim2.fromOffset(132, 32)
                Pill.Position = UDim2.new(1, -136, 0, 12)
                Pill.BorderSizePixel = 0
                Pill.Parent = HeaderFrame
                BindTheme(Pill, "BackgroundColor3", "CardBg")
                ApplySurfaceStyle(Pill, 16, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(8, 8)
                Dot.Position = UDim2.new(0, 12, 0.5, -4)
                Dot.BorderSizePixel = 0
                Dot.Parent = Pill
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplySurfaceStyle(Dot, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

                local PillTxt = CreateStylizedText(Pill, badgeText, LayoutPreset.FontSmall, "Accent", false, 0)
                PillTxt.Position = UDim2.new(0, 26, 0, 0)
                PillTxt.Size = UDim2.new(1, -30, 1, 0)
                PillTxt.TextXAlignment = Enum.TextXAlignment.Left
            end
        end

        -- ILLUSTRATED ANIMATED DESIGN CANVAS WIDGET
        function Builder:IllustratedCanvas(info)
            info = info or {}
            local CanvasCard = Instance.new("Frame")
            CanvasCard.Name = "IllustratedCanvas"
            CanvasCard.Size = UDim2.new(1, 0, 0, info.Height or 114)
            CanvasCard.ClipsDescendants = true
            CanvasCard.Parent = scrollingPage
            CanvasCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ApplySurfaceStyle(CanvasCard, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings)

            local BgGrad = Instance.new("UIGradient")
            BgGrad.Rotation = 25
            BindGradient(BgGrad, "CanvasBg")
            BgGrad.Parent = CanvasCard

            local SunOrb = Instance.new("Frame")
            SunOrb.Size = UDim2.fromOffset(78, 78)
            SunOrb.Position = UDim2.new(0.85, 0, 0.52, 0)
            SunOrb.AnchorPoint = Vector2.new(0.5, 0.5)
            SunOrb.BackgroundTransparency = 0.76
            SunOrb.BorderSizePixel = 0
            SunOrb.Parent = CanvasCard
            BindTheme(SunOrb, "BackgroundColor3", "Accent")
            local sunCorner = Instance.new("UICorner")
            sunCorner.CornerRadius = UDim.new(1, 0)
            sunCorner.Parent = SunOrb

            local OrbitRing = Instance.new("Frame")
            OrbitRing.Size = UDim2.fromOffset(92, 92)
            OrbitRing.Position = UDim2.new(0.85, 0, 0.52, 0)
            OrbitRing.AnchorPoint = Vector2.new(0.5, 0.5)
            OrbitRing.BackgroundTransparency = 0.85
            OrbitRing.Rotation = 25
            OrbitRing.BorderSizePixel = 0
            OrbitRing.Parent = CanvasCard
            BindTheme(OrbitRing, "BackgroundColor3", "AccentSecondary")
            local orCorner = Instance.new("UICorner")
            orCorner.CornerRadius = UDim.new(0.32, 0)
            orCorner.Parent = OrbitRing

            local CoreDiamond = Instance.new("Frame")
            CoreDiamond.Size = UDim2.fromOffset(26, 26)
            CoreDiamond.Position = UDim2.new(0.85, 0, 0.52, 0)
            CoreDiamond.AnchorPoint = Vector2.new(0.5, 0.5)
            CoreDiamond.Rotation = 45
            CoreDiamond.BackgroundTransparency = 0.15
            CoreDiamond.BorderSizePixel = 0
            CoreDiamond.Parent = CanvasCard
            BindTheme(CoreDiamond, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(CoreDiamond, 6, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

            local Hill1 = Instance.new("Frame")
            Hill1.Size = UDim2.new(0.55, 0, 0, 36)
            Hill1.Position = UDim2.new(0.52, 0, 1, -14)
            Hill1.Rotation = -6
            Hill1.BackgroundTransparency = 0.80
            Hill1.BorderSizePixel = 0
            Hill1.Parent = CanvasCard
            BindTheme(Hill1, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(Hill1, 16, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

            local Hill2 = Instance.new("Frame")
            Hill2.Size = UDim2.new(0.45, 0, 0, 30)
            Hill2.Position = UDim2.new(0.70, 0, 1, -10)
            Hill2.Rotation = 5
            Hill2.BackgroundTransparency = 0.75
            Hill2.BorderSizePixel = 0
            Hill2.Parent = CanvasCard
            BindTheme(Hill2, "BackgroundColor3", "AccentSecondary")
            ApplySurfaceStyle(Hill2, 16, CurrentTheme.AccentSecondary, Self.ThemeBindings, Self.RadiusBindings, "AccentSecondary", true)

            local TagPill = Instance.new("Frame")
            TagPill.Size = UDim2.fromOffset(146, 24)
            TagPill.Position = UDim2.new(0, 16, 0, 14)
            TagPill.BackgroundTransparency = 0.15
            TagPill.BorderSizePixel = 0
            TagPill.Parent = CanvasCard
            BindTheme(TagPill, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(TagPill, 8, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

            local TagLbl = CreateStylizedText(TagPill, info.Tag or "ILLUSTRATED UI", 15, "Accent", false, 0)
            TagLbl.Size = UDim2.fromScale(1, 1)

            local MainHeading = CreateStylizedText(CanvasCard, info.Title or "Colourful Minimalist Engine", 24, "TextPrimary", false, 0)
            MainHeading.Position = UDim2.new(0, 16, 0, 44)
            MainHeading.Size = UDim2.new(0.68, 0, 0, 28)
            MainHeading.TextXAlignment = Enum.TextXAlignment.Left

            local SubDesc = CreateStylizedText(CanvasCard, info.Subtitle or "5 Dynamic Themes • Crisp Readable Font • Smooth Animation", LayoutPreset.FontSmall, "TextMuted", false, 0)
            SubDesc.Position = UDim2.new(0, 16, 0, 74)
            SubDesc.Size = UDim2.new(0.68, 0, 0, 22)
            SubDesc.TextXAlignment = Enum.TextXAlignment.Left

            task.spawn(function()
                local step = 0
                while Self.IsAlive and CanvasCard.Parent do
                    step = step + 1
                    local targetRot = (step % 2 == 0) and 65 or 15
                    local diamondScale = (step % 2 == 0) and 30 or 24
                    TweenService:Create(OrbitRing, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Rotation = targetRot
                    }):Play()
                    TweenService:Create(CoreDiamond, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Rotation = (step % 2 == 0) and 135 or 45,
                        Size = UDim2.fromOffset(diamondScale, diamondScale)
                    }):Play()
                    TweenService:Create(SunOrb, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        Size = (step % 2 == 0) and UDim2.fromOffset(86, 86) or UDim2.fromOffset(72, 72)
                    }):Play()
                    task.wait(2.45)
                end
            end)

            return CanvasCard
        end

        function Builder:StatRow(statsList)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 72)
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

                local vecIcon = DrawVectorIcon(Card, item.Icon or "Bolt", 24, "Accent", BindTheme)
                vecIcon.Position = UDim2.new(0, 14, 0.5, -12)

                local Lbl = CreateStylizedText(Card, item.Label, LayoutPreset.FontSmall, "TextMuted", false, 0)
                Lbl.Position = UDim2.new(0, 46, 0, 12)
                Lbl.Size = UDim2.new(1, -50, 0, 20)
                Lbl.TextXAlignment = Enum.TextXAlignment.Left

                local Val = CreateStylizedText(Card, item.Value, LayoutPreset.FontCardTitle + 2, "Accent", false, 0)
                Val.Position = UDim2.new(0, 46, 0, 34)
                Val.Size = UDim2.new(1, -50, 0, 26)
                Val.TextXAlignment = Enum.TextXAlignment.Left
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
            Pad.PaddingTop = UDim.new(0, LayoutPreset.CardPadding)
            Pad.PaddingBottom = UDim.new(0, LayoutPreset.CardPadding)
            Pad.PaddingLeft = UDim.new(0, LayoutPreset.CardPadding)
            Pad.PaddingRight = UDim.new(0, LayoutPreset.CardPadding + 4)
            Pad.Parent = CardFrame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, LayoutPreset.CardSpacing)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = CardFrame

            if title then
                local TopRow = Instance.new("Frame")
                TopRow.Size = UDim2.new(1, 0, 0, 26)
                TopRow.BackgroundTransparency = 1
                TopRow.Parent = CardFrame

                local leftOffset = 0
                if iconName then
                    local hdrIcon = DrawVectorIcon(TopRow, iconName, 18, "Accent", BindTheme)
                    hdrIcon.Position = UDim2.new(0, 0, 0.5, -9)
                    leftOffset = 26
                end

                local TitleTxt = CreateStylizedText(TopRow, title, LayoutPreset.FontCardTitle, "TextPrimary", false, 0)
                TitleTxt.Position = UDim2.new(0, leftOffset, 0, 0)
                TitleTxt.Size = UDim2.new(0.65, -leftOffset, 1, 0)
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left

                if rightActionText then
                    local ActionTxt = CreateStylizedText(TopRow, rightActionText, LayoutPreset.FontSmall, "Accent", false, 0)
                    ActionTxt.Size = UDim2.new(0.35, -18, 1, 0)
                    ActionTxt.Position = UDim2.new(0.65, 0, 0, 0)
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right

                    local arr = DrawVectorIcon(TopRow, "ArrowRight", 13, "Accent", BindTheme)
                    arr.Position = UDim2.new(1, -12, 0.5, -6)
                end
            end

            return CreateCanvasBuilder(CardFrame)
        end

        -- QUICK ACTION GRID (TANPA BORDER ANEH SAAT AKTIF)
        function Builder:ActionGrid(items)
            local GridHolder = Instance.new("Frame")
            GridHolder.Size = UDim2.new(1, 0, 0, 78)
            GridHolder.AutomaticSize = Enum.AutomaticSize.Y
            GridHolder.BackgroundTransparency = 1
            GridHolder.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / math.min(#items, 6), -6, 0, 76)
            Grid.CellPadding = UDim2.new(0, 6, 0, 6)
            Grid.Parent = GridHolder

            for _, action in ipairs(items) do
                local flag = action.Flag or action.Name
                Self.Flags[flag] = action.Default or false

                local Tile = Instance.new("TextButton")
                Tile.Text = ""
                Tile.AutoButtonColor = false
                Tile.BorderSizePixel = 0
                Tile.Parent = GridHolder
                ApplySurfaceStyle(Tile, 9, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

                local ActiveDot = Instance.new("Frame")
                ActiveDot.Size = UDim2.fromOffset(6, 6)
                ActiveDot.Position = UDim2.new(1, -12, 0, 6)
                ActiveDot.BorderSizePixel = 0
                ActiveDot.Active = false
                ActiveDot.Parent = Tile
                ApplySurfaceStyle(ActiveDot, 3, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

                local vec = DrawVectorIcon(Tile, action.Icon or "Bolt", 22, "Accent", BindTheme)
                vec.Position = UDim2.new(0.5, -11, 0, 13)

                local Lbl = CreateStylizedText(Tile, action.Name, 17, "TextPrimary", false, 0)
                Lbl.Size = UDim2.new(1, -4, 0, 22)
                Lbl.Position = UDim2.new(0, 2, 1, -25)

                local function SyncTileVisual()
                    local active = Self.Flags[flag]
                    Tile.BackgroundColor3 = active and CurrentTheme.ControlActiveBg or CurrentTheme.ControlBg
                    ActiveDot.BackgroundColor3 = active and CurrentTheme.Accent or CurrentTheme.Stroke
                    ActiveDot.BackgroundTransparency = active and 0 or 0.55
                    Lbl.TextColor3 = active and CurrentTheme.AccentSecondary or CurrentTheme.TextPrimary
                end
                table.insert(Self.ToggleStyleUpdaters, SyncTileVisual)
                SyncTileVisual()

                Tile.MouseButton1Click:Connect(function()
                    local nextVal = not Self.Flags[flag]
                    Self:SetValue(flag, nextVal)
                    SyncTileVisual()
                    if action.Callback then task.spawn(action.Callback, nextVal) end
                end)
            end
        end

        function Builder:Section(text, iconName)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 28)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local offset = 0
            if iconName then
                local ic = DrawVectorIcon(Row, iconName, 16, "Accent", BindTheme)
                ic.Position = UDim2.new(0, 0, 0.5, -8)
                offset = 24
            end

            local Lbl = CreateStylizedText(Row, text, LayoutPreset.FontSection, "AccentSecondary", false, 0)
            Lbl.Position = UDim2.new(0, offset, 0, 0)
            Lbl.Size = UDim2.new(1, -offset, 1, 0)
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
        end

        -- CHECKLIST / TOGGLE (DIPERBAIKI TOTAL: TANPA BORDER ANEH & KLIK SUPER RESPONSIF)
        function Builder:Toggle(label, flag, default, callback, customStyle)
            Self.Flags[flag] = (default == true)
            local currentStyle = customStyle or Self.CheckboxStyle

            local Row = Instance.new("TextButton")
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            Row.BackgroundTransparency = 1
            Row.Text = ""
            Row.AutoButtonColor = false
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextPrimary", false, 0)
            Title.Size = UDim2.new(1, -68, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local HitBtn = Instance.new("Frame")
            HitBtn.Position = UDim2.new(1, -54, 0.5, -12)
            HitBtn.Size = UDim2.fromOffset(46, 24)
            HitBtn.BorderSizePixel = 0
            HitBtn.Active = false
            HitBtn.Parent = Row
            local hitCorner = ApplySurfaceStyle(HitBtn, 12, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.fromOffset(18, 18)
            Knob.Position = Self.Flags[flag] and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            Knob.BackgroundColor3 = Color3.fromRGB(250, 252, 255)
            Knob.BorderSizePixel = 0
            Knob.Active = false
            Knob.Parent = HitBtn
            ApplySurfaceStyle(Knob, 9, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            local CheckVec = DrawVectorIcon(HitBtn, "Check", 16, "OnAccentText", BindTheme)
            CheckVec.Position = UDim2.fromScale(0.5, 0.5)
            CheckVec.AnchorPoint = Vector2.new(0.5, 0.5)

            local StateText = CreateStylizedText(HitBtn, "OFF", LayoutPreset.FontSmall, "TextPrimary", false, 0)
            StateText.Size = UDim2.fromScale(1, 1)

            local function RenderToggleVisual(newStyle, animate)
                if newStyle and not customStyle then currentStyle = newStyle end
                local val = (Self.Flags[flag] == true)
                local styleKey = string.lower(tostring(currentStyle))

                Title.TextColor3 = val and CurrentTheme.TextPrimary or CurrentTheme.TextMuted

                if styleKey == "classic" then
                    HitBtn.Size = UDim2.fromOffset(24, 24)
                    HitBtn.Position = UDim2.new(1, -32, 0.5, -12)
                    hitCorner.CornerRadius = UDim.new(0, Self.Rounded and 6 or 0)
                    Knob.Visible = false
                    StateText.Visible = false
                    CheckVec.Visible = val
                    HitBtn.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                elseif styleKey == "biasa" or styleKey == "standard" then
                    HitBtn.Size = UDim2.fromOffset(54, 26)
                    HitBtn.Position = UDim2.new(1, -56, 0.5, -13)
                    hitCorner.CornerRadius = UDim.new(0, Self.Rounded and 6 or 0)
                    Knob.Visible = false
                    CheckVec.Visible = false
                    StateText.Visible = true
                    StateText.Text = val and "ON" or "OFF"
                    StateText.TextColor3 = val and CurrentTheme.OnAccentText or CurrentTheme.TextMuted
                    HitBtn.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                else
                    HitBtn.Size = UDim2.fromOffset(46, 24)
                    HitBtn.Position = UDim2.new(1, -54, 0.5, -12)
                    hitCorner.CornerRadius = UDim.new(0, Self.Rounded and 12 or 0)
                    Knob.Visible = true
                    CheckVec.Visible = false
                    StateText.Visible = false
                    HitBtn.BackgroundColor3 = val and CurrentTheme.Accent or CurrentTheme.ControlBg
                    Knob.BackgroundColor3 = val and CurrentTheme.OnAccentText or Color3.fromRGB(240, 244, 252)
                    local targetPos = val and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                    if animate then
                        TweenService:Create(Knob, TWEEN_FAST, {Position = targetPos}):Play()
                    else
                        Knob.Position = targetPos
                    end
                end
            end

            table.insert(Self.ToggleStyleUpdaters, function(newStyle)
                RenderToggleVisual(newStyle, false)
            end)
            RenderToggleVisual(currentStyle, false)

            Row.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                RenderToggleVisual(nil, true)
                if callback then task.spawn(callback, nextVal) end
            end)
        end

        function Builder:Slider(label, flag, min, max, default, suffix, callback)
            suffix = suffix or ""
            Self.Flags[flag] = default or min

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextPrimary", false, 0)
            Title.Size = UDim2.new(0.40, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(0.34, 0, 0, 8)
            Track.Position = UDim2.new(0.41, 0, 0.5, -4)
            Track.Text = ""
            Track.AutoButtonColor = false
            Track.BorderSizePixel = 0
            Track.Parent = Row
            BindTheme(Track, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(Track, 4, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            local initPct = math.clamp((Self.Flags[flag] - min) / math.max(1, (max - min)), 0, 1)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(initPct, 0, 1, 0)
            Fill.BorderSizePixel = 0
            Fill.Active = false
            Fill.Parent = Track
            BindTheme(Fill, "BackgroundColor3", "Accent")
            ApplySurfaceStyle(Fill, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

            local ValTxt = CreateStylizedText(Row, tostring(Self.Flags[flag]) .. suffix, LayoutPreset.FontSmall, "Accent", false, 0)
            ValTxt.Size = UDim2.new(0.22, 0, 1, 0)
            ValTxt.Position = UDim2.new(0.76, 0, 0, 0)
            ValTxt.TextXAlignment = Enum.TextXAlignment.Right

            local sliding = false
            local function UpdateFromInput(input)
                local width = math.max(1, Track.AbsoluteSize.X)
                local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / width, 0, 1)
                local value = math.floor(min + (max - min) * pct + 0.5)
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
            TrackConnection(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end))
            TrackConnection(UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end))
        end

        function Builder:Stepper(label, flag, default, step, callback)
            step = step or 1
            Self.Flags[flag] = default or 0

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextPrimary", false, 0)
            Title.Size = UDim2.new(0.52, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local Controls = Instance.new("Frame")
            Controls.Size = UDim2.fromOffset(102, 28)
            Controls.Position = UDim2.new(1, -8, 0.5, -14)
            Controls.AnchorPoint = Vector2.new(1, 0)
            Controls.BorderSizePixel = 0
            Controls.Parent = Row
            BindTheme(Controls, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(Controls, 7, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            local Minus = Instance.new("TextButton")
            Minus.Size = UDim2.new(0, 30, 1, 0)
            Minus.BackgroundTransparency = 1
            Minus.FontFace = CustomFontFace
            Minus.Text = "-"
            Minus.TextSize = 20
            Minus.Parent = Controls
            BindTheme(Minus, "TextColor3", "TextPrimary", "ControlBg")

            local ValLbl = CreateStylizedText(Controls, tostring(Self.Flags[flag]), LayoutPreset.FontBody, "Accent", false, 0)
            ValLbl.Size = UDim2.new(1, -60, 1, 0)
            ValLbl.Position = UDim2.new(0, 30, 0, 0)

            local Plus = Instance.new("TextButton")
            Plus.Size = UDim2.new(0, 30, 1, 0)
            Plus.Position = UDim2.new(1, -30, 0, 0)
            Plus.BackgroundTransparency = 1
            Plus.FontFace = CustomFontFace
            Plus.Text = "+"
            Plus.TextSize = 20
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
            options = (type(options) == "table" and #options > 0) and options or {"Default"}
            Self.Flags[flag] = default or options[1]

            local Wrapper = Instance.new("Frame")
            Wrapper.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            Wrapper.AutomaticSize = Enum.AutomaticSize.Y
            Wrapper.BackgroundTransparency = 1
            Wrapper.Parent = scrollingPage

            local WrapperLayout = Instance.new("UIListLayout")
            WrapperLayout.Padding = UDim.new(0, 4)
            WrapperLayout.SortOrder = Enum.SortOrder.LayoutOrder
            WrapperLayout.Parent = Wrapper

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = 1
            Row.Parent = Wrapper

            local Title = CreateStylizedText(Row, label, LayoutPreset.FontBody, "TextPrimary", false, 0)
            Title.Size = UDim2.new(0.42, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.56, 0, 0, 28)
            DropBtn.Position = UDim2.new(1, -8, 0.5, -14)
            DropBtn.AnchorPoint = Vector2.new(1, 0)
            DropBtn.Text = ""
            DropBtn.AutoButtonColor = false
            DropBtn.BorderSizePixel = 0
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(DropBtn, 7, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            local SelectedTxt = CreateStylizedText(DropBtn, tostring(Self.Flags[flag]), LayoutPreset.FontSmall, "AccentSecondary", false, 0)
            SelectedTxt.Position = UDim2.new(0, 10, 0, 0)
            SelectedTxt.Size = UDim2.new(1, -28, 1, 0)
            SelectedTxt.TextXAlignment = Enum.TextXAlignment.Left

            local chev = DrawVectorIcon(DropBtn, "ChevronDown", 13, "Accent", BindTheme)
            chev.Position = UDim2.new(1, -18, 0.5, -6)

            local MenuHolder = Instance.new("Frame")
            MenuHolder.Size = UDim2.new(1, -8, 0, 0)
            MenuHolder.AutomaticSize = Enum.AutomaticSize.Y
            MenuHolder.Visible = false
            MenuHolder.LayoutOrder = 2
            MenuHolder.BorderSizePixel = 0
            MenuHolder.Parent = Wrapper
            BindTheme(MenuHolder, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(MenuHolder, 8, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            local MenuPad = Instance.new("UIPadding")
            MenuPad.PaddingTop = UDim.new(0, 4)
            MenuPad.PaddingBottom = UDim.new(0, 4)
            MenuPad.PaddingLeft = UDim.new(0, 4)
            MenuPad.PaddingRight = UDim.new(0, 4)
            MenuPad.Parent = MenuHolder

            local MenuLayout = Instance.new("UIListLayout")
            MenuLayout.Padding = UDim.new(0, 2)
            MenuLayout.SortOrder = Enum.SortOrder.LayoutOrder
            MenuLayout.Parent = MenuHolder

            local isOpen = false
            local OptionBtns = {}

            local function RefreshOptionVisuals()
                for _, item in ipairs(OptionBtns) do
                    local isSelected = (Self.Flags[flag] == item.Value)
                    item.Button.BackgroundTransparency = isSelected and 0 or 1
                    item.Button.BackgroundColor3 = CurrentTheme.ControlActiveBg
                    item.Label.TextColor3 = isSelected and CurrentTheme.AccentSecondary or CurrentTheme.TextPrimary
                end
            end
            table.insert(Self.ToggleStyleUpdaters, RefreshOptionVisuals)

            for i, opt in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 28)
                OptBtn.BackgroundTransparency = 1
                OptBtn.Text = ""
                OptBtn.AutoButtonColor = false
                OptBtn.BorderSizePixel = 0
                OptBtn.LayoutOrder = i
                OptBtn.Parent = MenuHolder
                ApplySurfaceStyle(OptBtn, 6, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

                local OptLbl = CreateStylizedText(OptBtn, tostring(opt), LayoutPreset.FontSmall, "TextPrimary", false, 0)
                OptLbl.Position = UDim2.new(0, 10, 0, 0)
                OptLbl.Size = UDim2.new(1, -20, 1, 0)
                OptLbl.TextXAlignment = Enum.TextXAlignment.Left

                table.insert(OptionBtns, {Button = OptBtn, Label = OptLbl, Value = opt})

                OptBtn.MouseButton1Click:Connect(function()
                    SelectedTxt.Text = ApplyLetterSpacing(tostring(opt), Self.LetterSpacing)
                    Self:SetValue(flag, opt)
                    RefreshOptionVisuals()
                    isOpen = false
                    MenuHolder.Visible = false
                    TweenService:Create(chev, TWEEN_FAST, {Rotation = 0}):Play()
                    if callback then task.spawn(callback, opt) end
                end)
            end

            RefreshOptionVisuals()

            DropBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                MenuHolder.Visible = isOpen
                TweenService:Create(chev, TWEEN_FAST, {Rotation = isOpen and 180 or 0}):Play()
            end)
        end

        function Builder:Input(label, flag, placeholder, default, callback)
            Self.Flags[flag] = default or ""

            local BoxHolder = Instance.new("Frame")
            BoxHolder.Size = UDim2.new(1, 0, 0, LayoutPreset.RowHeight)
            BoxHolder.BackgroundTransparency = 1
            BoxHolder.Parent = scrollingPage

            local Title = CreateStylizedText(BoxHolder, label, LayoutPreset.FontBody, "TextPrimary", false, 0)
            Title.Size = UDim2.new(0.40, 0, 1, 0)
            Title.TextXAlignment = Enum.TextXAlignment.Left

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0.58, 0, 0, 28)
            InputBox.Position = UDim2.new(1, -8, 0.5, -14)
            InputBox.AnchorPoint = Vector2.new(1, 0)
            InputBox.FontFace = CustomFontFace
            InputBox.PlaceholderText = placeholder or "Enter value..."
            InputBox.Text = Self.Flags[flag]
            InputBox.TextSize = LayoutPreset.FontSmall
            InputBox.ClearTextOnFocus = false
            InputBox.BorderSizePixel = 0
            InputBox.Parent = BoxHolder
            BindTheme(InputBox, "BackgroundColor3", "ControlBg")
            BindTheme(InputBox, "TextColor3", "TextPrimary", "ControlBg")
            BindTheme(InputBox, "PlaceholderColor3", "TextMuted", "ControlBg")
            ApplySurfaceStyle(InputBox, 7, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

            InputBox.FocusLost:Connect(function()
                Self:SetValue(flag, InputBox.Text)
                if callback then task.spawn(callback, InputBox.Text) end
            end)
        end

        function Builder:ActivityTimeline(entries)
            for _, item in ipairs(entries) do
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 28)
                Row.BackgroundTransparency = 1
                Row.Parent = scrollingPage

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(8, 8)
                Dot.Position = UDim2.new(0, 4, 0.5, -4)
                Dot.BorderSizePixel = 0
                Dot.Parent = Row
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplySurfaceStyle(Dot, 4, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

                local EventTxt = CreateStylizedText(Row, item.Text, LayoutPreset.FontBody, "TextPrimary", false, 0)
                EventTxt.Position = UDim2.new(0, 22, 0, 0)
                EventTxt.Size = UDim2.new(0.68, 0, 1, 0)
                EventTxt.TextXAlignment = Enum.TextXAlignment.Left

                local TimeTxt = CreateStylizedText(Row, item.Time, LayoutPreset.FontSmall, "Accent", false, 0)
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
        Pad.PaddingRight = UDim.new(0, p + 6)
        Pad.Parent = Page

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, LayoutPreset.ItemSpacing)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Page
        return Page
    end

    -- TAB SIDEBAR BUTTON (TANPA BORDER KOTAK SAAT AKTIF)
    function Self.feature(logo, name)
        local CenterPage = CreateScrollPage(CenterPanel)
        local RightPage = CreateScrollPage(RightPanel)

        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(1, 0, 0, 42)
        NavBtn.BackgroundTransparency = 1
        NavBtn.Text = ""
        NavBtn.AutoButtonColor = false
        NavBtn.BorderSizePixel = 0
        NavBtn.Parent = NavScroll
        BindTheme(NavBtn, "BackgroundColor3", "ControlBg")
        ApplySurfaceStyle(NavBtn, 9, CurrentTheme.Stroke, Self.ThemeBindings, Self.RadiusBindings, "Stroke", true)

        local isAssetLogo = (type(logo) == "string" and (string.find(logo, "^https?://") or string.find(logo, "^rbxassetid://")))
        if isAssetLogo then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Position = UDim2.new(0, 14, 0.5, -10)
            IconImg.Size = UDim2.fromOffset(20, 20)
            IconImg.BackgroundTransparency = 1
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.Image = ResolveImage(logo)
            IconImg.Active = false
            IconImg.Parent = NavBtn
        else
            local vecTabIcon = DrawVectorIcon(NavBtn, logo or name, 18, "Accent", BindTheme)
            vecTabIcon.Position = UDim2.new(0, 14, 0.5, -9)
        end

        local NameLbl = CreateStylizedText(NavBtn, name, 21, "TextPrimary", false, 0)
        NameLbl.Position = UDim2.new(0, 42, 0, 0)
        NameLbl.Size = UDim2.new(1, -48, 1, 0)
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left

        local ActiveLine = Instance.new("Frame")
        ActiveLine.Size = UDim2.new(0, 4, 0.54, 0)
        ActiveLine.Position = UDim2.new(0, 0, 0.23, 0)
        ActiveLine.BorderSizePixel = 0
        ActiveLine.Visible = false
        ActiveLine.Active = false
        ActiveLine.Parent = NavBtn
        BindTheme(ActiveLine, "BackgroundColor3", "Accent")
        ApplySurfaceStyle(ActiveLine, 2, CurrentTheme.Accent, Self.ThemeBindings, Self.RadiusBindings, "Accent", true)

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
                f.NameLbl.TextColor3 = CurrentTheme.TextMuted
            end
            CenterPage.Visible = true
            if FeatureObj.HasCustomRight then
                RightPage.Visible = true
            elseif Self.Features[1] then
                Self.Features[1].RightPage.Visible = true
            end
            ActiveLine.Visible = true
            NavBtn.BackgroundTransparency = 0.15
            NameLbl.TextColor3 = CurrentTheme.TextPrimary
            Self.ActiveFeature = FeatureObj
        end

        table.insert(Self.ToggleStyleUpdaters, function()
            if Self.ActiveFeature == FeatureObj then
                NameLbl.TextColor3 = CurrentTheme.TextPrimary
            else
                NameLbl.TextColor3 = CurrentTheme.TextMuted
            end
        end)

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
