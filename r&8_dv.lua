--[[
    FRAMEWORK : R&8_DV ImGui Architecture (v5.0 - Minimalist Monochrome & 2.5D/3D Colourful Typography Edition)
    COPYRIGHT : R&8_DV
    ASSET     : Hardcoded GitHub Auto-Fetch + Procedural Lucide Vector Icons (Zero Emoji / Zero [] Bug / Zero FPS Drop)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // HARDCODED MASTER LOGO DARI GITHUB (JANGAN DIUBAH) //
local MASTER_LOGO_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Assets/icons.png"
local MASTER_CACHE_FILE = "R8DV_MasterLogo_v4.png"

local function GetSafeGuiParent()
    local ok, res = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if ok and res then return res end
    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end
    return CoreGui
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
    if not bgColor or not preferredTextColor then
        return preferredTextColor or Color3.fromRGB(244, 247, 255)
    end
    local function lum(c)
        return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    end
    if math.abs(lum(bgColor) - lum(preferredTextColor)) < 0.35 then
        return lum(bgColor) > 0.5 and Color3.fromRGB(16, 18, 24) or Color3.fromRGB(244, 247, 255)
    end
    return preferredTextColor
end

-- =========================================================================
-- 5 TEMA WARNA COLOURFUL BERBASIS MINIMALIST MONOCHROME SURFACE
-- Ringan (0% Loop Animasi), Kontras Tinggi, & Gradasi Teks 2.5D / 3D Sesuai Nama Tema
-- =========================================================================
local ThemeOrder = {
    "Minimalist Monochrome",
    "Blue Night Sky",
    "Violet Amethyst",
    "Orange Sand",
    "Midnight Monokai"
}

local Themes = {
    ["Minimalist Monochrome"] = {
        MainBg      = Color3.fromRGB(10, 11, 14),
        PanelBg     = Color3.fromRGB(14, 16, 20),
        CardBg      = Color3.fromRGB(19, 21, 27),
        CardHoverBg = Color3.fromRGB(25, 28, 36),
        ControlBg   = Color3.fromRGB(28, 31, 40),
        Accent      = Color3.fromRGB(236, 242, 252),
        AccentSoft  = Color3.fromRGB(40, 45, 58),
        Stroke      = Color3.fromRGB(36, 40, 52),
        HoverStroke = Color3.fromRGB(138, 150, 178),
        TextPrimary = Color3.fromRGB(248, 250, 255),
        TextMuted   = Color3.fromRGB(136, 145, 164),
        Grad3DTop   = Color3.fromRGB(255, 255, 255),
        Grad3DMid   = Color3.fromRGB(210, 224, 246),
        Grad3DBot   = Color3.fromRGB(128, 148, 184),
        LabelTop    = Color3.fromRGB(250, 252, 255),
        LabelBot    = Color3.fromRGB(184, 198, 222),
        TextShadow  = Color3.fromRGB(4, 5, 8),
        KnobOn      = Color3.fromRGB(14, 16, 22)
    },
    ["Blue Night Sky"] = {
        MainBg      = Color3.fromRGB(9, 12, 20),
        PanelBg     = Color3.fromRGB(13, 17, 28),
        CardBg      = Color3.fromRGB(18, 24, 38),
        CardHoverBg = Color3.fromRGB(24, 32, 50),
        ControlBg   = Color3.fromRGB(27, 36, 56),
        Accent      = Color3.fromRGB(68, 148, 255),
        AccentSoft  = Color3.fromRGB(26, 52, 96),
        Stroke      = Color3.fromRGB(36, 48, 74),
        HoverStroke = Color3.fromRGB(92, 172, 255),
        TextPrimary = Color3.fromRGB(242, 247, 255),
        TextMuted   = Color3.fromRGB(134, 150, 182),
        Grad3DTop   = Color3.fromRGB(255, 255, 255),
        Grad3DMid   = Color3.fromRGB(112, 202, 255),
        Grad3DBot   = Color3.fromRGB(52, 118, 255),
        LabelTop    = Color3.fromRGB(245, 250, 255),
        LabelBot    = Color3.fromRGB(162, 208, 255),
        TextShadow  = Color3.fromRGB(4, 8, 18),
        KnobOn      = Color3.fromRGB(252, 254, 255)
    },
    ["Violet Amethyst"] = {
        MainBg      = Color3.fromRGB(11, 10, 18),
        PanelBg     = Color3.fromRGB(16, 14, 26),
        CardBg      = Color3.fromRGB(22, 19, 35),
        CardHoverBg = Color3.fromRGB(29, 25, 46),
        ControlBg   = Color3.fromRGB(34, 29, 54),
        Accent      = Color3.fromRGB(134, 98, 255),
        AccentSoft  = Color3.fromRGB(48, 36, 92),
        Stroke      = Color3.fromRGB(46, 39, 72),
        HoverStroke = Color3.fromRGB(164, 132, 255),
        TextPrimary = Color3.fromRGB(248, 244, 255),
        TextMuted   = Color3.fromRGB(150, 140, 178),
        Grad3DTop   = Color3.fromRGB(255, 250, 255),
        Grad3DMid   = Color3.fromRGB(196, 148, 255),
        Grad3DBot   = Color3.fromRGB(124, 82, 255),
        LabelTop    = Color3.fromRGB(250, 246, 255),
        LabelBot    = Color3.fromRGB(204, 176, 255),
        TextShadow  = Color3.fromRGB(7, 5, 16),
        KnobOn      = Color3.fromRGB(252, 250, 255)
    },
    ["Orange Sand"] = {
        MainBg      = Color3.fromRGB(14, 12, 10),
        PanelBg     = Color3.fromRGB(20, 17, 14),
        CardBg      = Color3.fromRGB(27, 23, 19),
        CardHoverBg = Color3.fromRGB(35, 30, 25),
        ControlBg   = Color3.fromRGB(42, 35, 29),
        Accent      = Color3.fromRGB(245, 164, 68),
        AccentSoft  = Color3.fromRGB(72, 48, 24),
        Stroke      = Color3.fromRGB(56, 46, 37),
        HoverStroke = Color3.fromRGB(248, 184, 98),
        TextPrimary = Color3.fromRGB(254, 248, 240),
        TextMuted   = Color3.fromRGB(168, 150, 134),
        Grad3DTop   = Color3.fromRGB(255, 252, 242),
        Grad3DMid   = Color3.fromRGB(255, 198, 102),
        Grad3DBot   = Color3.fromRGB(238, 124, 42),
        LabelTop    = Color3.fromRGB(255, 250, 242),
        LabelBot    = Color3.fromRGB(250, 204, 152),
        TextShadow  = Color3.fromRGB(12, 8, 5),
        KnobOn      = Color3.fromRGB(20, 15, 10)
    },
    ["Midnight Monokai"] = {
        MainBg      = Color3.fromRGB(12, 13, 11),
        PanelBg     = Color3.fromRGB(17, 19, 16),
        CardBg      = Color3.fromRGB(23, 26, 22),
        CardHoverBg = Color3.fromRGB(30, 34, 28),
        ControlBg   = Color3.fromRGB(36, 40, 34),
        Accent      = Color3.fromRGB(166, 226, 46),
        AccentSoft  = Color3.fromRGB(42, 60, 24),
        Stroke      = Color3.fromRGB(46, 52, 43),
        HoverStroke = Color3.fromRGB(174, 234, 62),
        TextPrimary = Color3.fromRGB(248, 250, 244),
        TextMuted   = Color3.fromRGB(142, 150, 136),
        Grad3DTop   = Color3.fromRGB(252, 255, 245),
        Grad3DMid   = Color3.fromRGB(182, 242, 68),
        Grad3DBot   = Color3.fromRGB(46, 214, 136),
        LabelTop    = Color3.fromRGB(248, 252, 244),
        LabelBot    = Color3.fromRGB(192, 238, 152),
        TextShadow  = Color3.fromRGB(6, 9, 6),
        KnobOn      = Color3.fromRGB(14, 18, 12)
    }
}

-- =========================================================================
-- PROCEDURAL LUCIDE VECTOR ICON ENGINE (ZERO EMOJI & ANTI-BUG KOTAK [])
-- =========================================================================
local function DrawVectorIcon(parent, iconName, sizePx, themeKey, bindThemeFn)
    local Holder = Instance.new("Frame")
    Holder.Name = "VectorIcon_" .. tostring(iconName)
    Holder.Size = UDim2.fromOffset(sizePx, sizePx)
    Holder.BackgroundTransparency = 1
    Holder.Parent = parent

    local Parts = {}

    local function Line(w, h, posX, posY, rot, radius)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromScale(posX, posY)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Rotation = rot or 0
        f.BorderSizePixel = 0
        f.Parent = Holder
        bindThemeFn(f, "BackgroundColor3", themeKey)
        table.insert(Parts, {Inst = f, Prop = "BackgroundColor3"})
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
        table.insert(Parts, {Inst = s, Prop = "Color"})
        return f
    end

    local key = string.lower(tostring(iconName or "dot"))

    if key == "home" then
        Line(sizePx * 0.55, 2, 0.32, 0.30, -40, 1)
        Line(sizePx * 0.55, 2, 0.68, 0.30, 40, 1)
        Ring(sizePx * 0.62, sizePx * 0.48, 0.5, 0.64, 3, 1.8)
    elseif key == "autofarm" or key == "rocket" then
        Ring(sizePx * 0.48, sizePx * 0.48, 0.5, 0.5, 4, 1.8, 45)
        Line(sizePx * 0.20, sizePx * 0.20, 0.5, 0.5, 45, 2)
        Line(sizePx * 0.30, 2, 0.26, 0.74, -45, 1)
    elseif key == "bot" or key == "robot" then
        Ring(sizePx * 0.68, sizePx * 0.54, 0.5, 0.56, 5, 1.8)
        Line(2, sizePx * 0.18, 0.5, 0.20, 0, 1)
        Line(sizePx * 0.14, sizePx * 0.14, 0.36, 0.54, 0, sizePx)
        Line(sizePx * 0.14, sizePx * 0.14, 0.64, 0.54, 0, sizePx)
    elseif key == "combat" or key == "aimbot" or key == "target" or key == "crosshair" then
        Ring(sizePx * 0.74, sizePx * 0.74, 0.5, 0.5, sizePx, 1.8)
        Line(sizePx * 0.26, 1.8, 0.5, 0.5, 0, 1)
        Line(1.8, sizePx * 0.26, 0.5, 0.5, 0, 1)
    elseif key == "teleports" or key == "teleport" or key == "pin" or key == "world" then
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
        Line(sizePx * 0.22, sizePx * 0.22, 0.5, 0.5, 0, sizePx)
    elseif key == "sliders" then
        Line(sizePx * 0.76, 2, 0.5, 0.28, 0, 1)
        Line(4, 6, 0.35, 0.28, 0, 2)
        Line(sizePx * 0.76, 2, 0.5, 0.52, 0, 1)
        Line(4, 6, 0.68, 0.52, 0, 2)
        Line(sizePx * 0.76, 2, 0.5, 0.76, 0, 1)
        Line(4, 6, 0.45, 0.76, 0, 2)
    elseif key == "bolt" or key == "exploits" then
        Line(sizePx * 0.48, 2.2, 0.46, 0.34, -55, 1)
        Line(sizePx * 0.36, 2.2, 0.50, 0.50, 0, 1)
        Line(sizePx * 0.48, 2.2, 0.54, 0.66, -55, 1)
    elseif key == "clock" then
        Ring(sizePx * 0.76, sizePx * 0.76, 0.5, 0.5, sizePx, 1.8)
        Line(2, sizePx * 0.26, 0.5, 0.40, 0, 1)
        Line(sizePx * 0.22, 2, 0.58, 0.54, 25, 1)
    elseif key == "shield" then
        Ring(sizePx * 0.66, sizePx * 0.74, 0.5, 0.5, 5, 1.8)
        Line(2, sizePx * 0.36, 0.5, 0.5, 0, 1)
    elseif key == "speed" or key == "gauge" then
        Ring(sizePx * 0.78, sizePx * 0.78, 0.5, 0.54, sizePx, 1.8)
        Line(sizePx * 0.34, 2, 0.58, 0.46, -35, 1)
    elseif key == "jump" or key == "arrowup" then
        Line(2, sizePx * 0.64, 0.5, 0.54, 0, 1)
        Line(sizePx * 0.36, 2, 0.39, 0.32, -45, 1)
        Line(sizePx * 0.36, 2, 0.61, 0.32, 45, 1)
    elseif key == "collect" or key == "layers" or key == "grid" then
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.38, 3, 1.6, 45)
        Ring(sizePx * 0.54, sizePx * 0.54, 0.5, 0.60, 3, 1.6, 45)
    elseif key == "chat" or key == "spammer" or key == "message" then
        Ring(sizePx * 0.74, sizePx * 0.56, 0.5, 0.46, 5, 1.8)
        Line(sizePx * 0.36, 1.8, 0.5, 0.42, 0, 1)
        Line(sizePx * 0.24, 1.8, 0.44, 0.54, 0, 1)
    elseif key == "fish" or key == "fishing" then
        Ring(sizePx * 0.56, sizePx * 0.38, 0.44, 0.5, sizePx, 1.8)
        Line(sizePx * 0.26, 1.8, 0.78, 0.42, -35, 1)
        Line(sizePx * 0.26, 1.8, 0.78, 0.58, 35, 1)
    elseif key == "key" or key == "keybind" then
        Ring(sizePx * 0.40, sizePx * 0.40, 0.34, 0.5, sizePx, 1.8)
        Line(sizePx * 0.42, 2, 0.66, 0.5, 0, 1)
        Line(2, sizePx * 0.18, 0.78, 0.60, 0, 1)
    elseif key == "palette" or key == "sparkles" or key == "theme" then
        Ring(sizePx * 0.72, sizePx * 0.72, 0.5, 0.5, sizePx, 1.8)
        Line(3, 3, 0.38, 0.38, 0, 2)
        Line(3, 3, 0.62, 0.40, 0, 2)
        Line(3, 3, 0.44, 0.62, 0, 2)
    elseif key == "check" then
        Line(sizePx * 0.28, 2.2, 0.34, 0.56, 42, 1)
        Line(sizePx * 0.52, 2.2, 0.62, 0.48, -46, 1)
    elseif key == "menu" then
        Line(14, 2, 0.5, 0.30, 0, 1)
        Line(14, 2, 0.5, 0.50, 0, 1)
        Line(10, 2, 0.4, 0.70, 0, 1)
    elseif key == "minimize" then
        Line(12, 2, 0.5, 0.5, 0, 1)
    elseif key == "maximize" then
        Ring(11, 11, 0.5, 0.5, 2, 1.6)
    elseif key == "close" then
        Line(13, 2, 0.5, 0.5, 45, 1)
        Line(13, 2, 0.5, 0.5, -45, 1)
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

    return Holder, function(overrideColor)
        for _, p in ipairs(Parts) do
            if p.Inst and p.Inst.Parent then
                p.Inst[p.Prop] = overrideColor
            end
        end
    end
end

-- // KONSTRUKTOR UTAMA IMGUI //
local function ImGui(config)
    config = config or {}

    local uiScaleValue = math.clamp(tonumber(config.Scale) or 1, 0.5, 1.5)

    local Self = {
        Title = config.Title or "DRY CURSED  -  IMGUI",
        Copyright = "R&8_DV",
        ThemeName = Themes[config.Theme or ""] and config.Theme or "Blue Night Sky",
        Rounded = (config.Rounded ~= false),
        CheckboxStyle = config.CheckboxStyle or "Modern", -- "Modern" | "Checkbox"
        Text3D = (config.Text3D ~= false),
        ReduceEffects = (config.ReduceEffects == true),
        SideCount = (config.Sides == 2) and 2 or 3,
        BgTransparency = math.clamp(tonumber(config.Transparency or config.BgTransparency) or 0.04, 0, 0.65),
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.85,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode ~= false),
        AutoLoading = (config.AutoLoading ~= false),
        IsMinimized = false,
        Flags = {},
        FlagListeners = {},
        Features = {},
        ActiveFeature = nil,
        ThemeBindings = {},
        ThemeUpdaters = {},
        RadiusBindings = {},
        Connections = {}
    }

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Blue Night Sky"]
    local ResolvedMasterLogo = ResolveImage(MASTER_LOGO_URL)

    local function TrackConn(conn)
        if conn then
            table.insert(Self.Connections, conn)
        end
        return conn
    end

    -- Helper Micro-Interaction Ringan (Event-Driven Saja, 0% Idle CPU / FPS Drop)
    local function FastTween(instance, duration, props, style, dir)
        if not instance or not instance.Parent then return nil end
        if Self.ReduceEffects or Self.Flags["ReduceEffects"] or Self.Flags["FPSBoost"] then
            for k, v in pairs(props) do
                instance[k] = v
            end
            return nil
        end
        local tw = TweenService:Create(
            instance,
            TweenInfo.new(duration or 0.14, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
            props
        )
        tw:Play()
        return tw
    end

    local function ApplyCornerOnly(frame, radiusScale)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, Self.Rounded and radiusScale or 0)
        corner.Parent = frame
        table.insert(Self.RadiusBindings, {Instance = corner, BaseRadius = radiusScale})
        return corner
    end

    local function ApplySurfaceStyle(frame, radiusScale, strokeColor, strokeType, strokeTrans)
        local corner = ApplyCornerOnly(frame, radiusScale)
        local stroke = Instance.new("UIStroke")
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Thickness = 1
        stroke.Color = strokeColor or CurrentTheme.Stroke
        stroke.Transparency = strokeTrans or 0.28
        stroke.Parent = frame
        if strokeType ~= false then
            table.insert(Self.ThemeBindings, {Instance = stroke, Prop = "Color", Key = strokeType or "Stroke"})
        end
        return corner, stroke
    end

    local function BindTheme(instance, prop, themeKey, bgKeyForContrast)
        table.insert(Self.ThemeBindings, {
            Instance = instance,
            Prop = prop,
            Key = themeKey,
            BgKey = bgKeyForContrast
        })
        local col = CurrentTheme[themeKey] or CurrentTheme.TextPrimary
        if bgKeyForContrast and CurrentTheme[bgKeyForContrast] then
            col = GetReadableTextColor(CurrentTheme[bgKeyForContrast], col)
        end
        instance[prop] = col
    end

    local function RegisterThemeUpdater(instance, fn)
        table.insert(Self.ThemeUpdaters, {Instance = instance, Update = fn})
        fn(CurrentTheme)
    end

    -- =========================================================================
    -- 2.5D & 3D COLOURFUL GRADIENT TYPOGRAPHY ENGINE (ULTRA RINGAN - ZERO FPS DROP)
    -- Satu TextLabel + Satu UIGradient Statis + Satu UIStroke Kontur Kedalaman
    -- =========================================================================
    local function ApplyRichText(label, mode, bgKeyForFallback)
        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = label

        local depthStroke = Instance.new("UIStroke")
        depthStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
        depthStroke.LineJoinMode = Enum.LineJoinMode.Round
        depthStroke.Parent = label

        local isHighlighted = false

        local function Refresh(theme)
            theme = theme or CurrentTheme
            if Self.Text3D then
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                grad.Enabled = true
                depthStroke.Enabled = true
                depthStroke.Color = theme.TextShadow

                if mode == "Display3D" then
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, theme.Grad3DTop),
                        ColorSequenceKeypoint.new(0.46, theme.Grad3DMid),
                        ColorSequenceKeypoint.new(1, theme.Grad3DBot)
                    })
                    depthStroke.Thickness = 1.2
                    depthStroke.Transparency = 0.24
                elseif mode == "Title25D" or isHighlighted then
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, theme.Grad3DTop),
                        ColorSequenceKeypoint.new(0.52, theme.Grad3DMid),
                        ColorSequenceKeypoint.new(1, theme.Grad3DBot)
                    })
                    depthStroke.Thickness = 1
                    depthStroke.Transparency = 0.34
                else -- "Label25D" (Menu Control Labels: Bold, Readable & Colour-Tinted)
                    grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, theme.LabelTop),
                        ColorSequenceKeypoint.new(1, theme.LabelBot)
                    })
                    depthStroke.Thickness = 0.85
                    depthStroke.Transparency = 0.50
                end
            else
                grad.Enabled = false
                depthStroke.Enabled = false
                local fallbackKey = (mode == "Label25D" and not isHighlighted) and "TextPrimary" or "Accent"
                if mode == "Display3D" or mode == "Title25D" then
                    fallbackKey = "TextPrimary"
                end
                local col = theme[fallbackKey]
                if bgKeyForFallback and theme[bgKeyForFallback] then
                    col = GetReadableTextColor(theme[bgKeyForFallback], col)
                end
                label.TextColor3 = col
            end
        end

        RegisterThemeUpdater(label, Refresh)

        return function(activeState)
            isHighlighted = (activeState == true)
            Refresh(CurrentTheme)
        end
    end

    -- State Flag System
    function Self:SetValue(flag, value, silent)
        Self.Flags[flag] = value
        if flag == "ReduceEffects" or flag == "FPSBoost" then
            Self.ReduceEffects = (Self.Flags["ReduceEffects"] == true or Self.Flags["FPSBoost"] == true)
        end
        if not silent and Self.FlagListeners[flag] then
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

    function Self:GetThemes()
        local copy = {}
        for i, name in ipairs(ThemeOrder) do
            copy[i] = name
        end
        return copy
    end

    -- Bersihkan instance lama jika script di-eksekusi ulang di executor
    local SafeParent = GetSafeGuiParent()
    pcall(function()
        for _, child in ipairs(SafeParent:GetChildren()) do
            if child:IsA("ScreenGui") and string.find(child.Name, "^R8_DV_Engine_") then
                child:Destroy()
            end
        end
    end)

    -- Root ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "R8_DV_Engine_" .. HttpService:GenerateGUID(false):sub(1, 6)
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999999
    ScreenGui.Parent = SafeParent

    -- Focus Mode Blocker
    local FocusBlocker = Instance.new("TextButton")
    FocusBlocker.Name = "FocusSink"
    FocusBlocker.Size = UDim2.fromScale(1, 1)
    FocusBlocker.BackgroundTransparency = 0.52
    FocusBlocker.BackgroundColor3 = Color3.fromRGB(4, 6, 10)
    FocusBlocker.BorderSizePixel = 0
    FocusBlocker.Text = ""
    FocusBlocker.AutoButtonColor = false
    FocusBlocker.Active = true
    FocusBlocker.Modal = true
    FocusBlocker.Visible = Self.FocusMode
    FocusBlocker.Parent = ScreenGui

    -- =========================================================================
    -- FLOATING POPUP ICON MENU (SINGLE CLEAN BORDER - ZERO DUPLICATE STROKE!)
    -- =========================================================================
    local MinimizeIconBtn = Instance.new("ImageButton")
    MinimizeIconBtn.Name = "R8DV_FloatingSquircle"
    MinimizeIconBtn.Size = UDim2.fromOffset(58, 58)
    MinimizeIconBtn.Position = UDim2.new(0, 46, 0.5, 0)
    MinimizeIconBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIconBtn.BorderSizePixel = 0
    MinimizeIconBtn.AutoButtonColor = false
    MinimizeIconBtn.Image = ""
    MinimizeIconBtn.Visible = false
    MinimizeIconBtn.ZIndex = 800
    MinimizeIconBtn.Parent = ScreenGui
    BindTheme(MinimizeIconBtn, "BackgroundColor3", "CardBg")

    -- Hanya 1 UICorner & 1 UIStroke (Tanpa Inner Bezel Ganda!)
    local _, MinSingleStroke = ApplySurfaceStyle(MinimizeIconBtn, 15, CurrentTheme.Stroke, false, 0.12)
    MinSingleStroke.Thickness = 1.2

    local MinSurfaceGrad = Instance.new("UIGradient")
    MinSurfaceGrad.Rotation = 45
    MinSurfaceGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(215, 220, 232))
    })
    MinSurfaceGrad.Parent = MinimizeIconBtn

    RegisterThemeUpdater(MinimizeIconBtn, function(theme)
        MinSingleStroke.Color = theme.Stroke
    end)

    local MinEmblemImg = Instance.new("ImageLabel")
    MinEmblemImg.Size = UDim2.fromScale(0.76, 0.76)
    MinEmblemImg.Position = UDim2.fromScale(0.5, 0.5)
    MinEmblemImg.AnchorPoint = Vector2.new(0.5, 0.5)
    MinEmblemImg.BackgroundTransparency = 1
    MinEmblemImg.ScaleType = Enum.ScaleType.Fit
    MinEmblemImg.Image = ResolvedMasterLogo
    MinEmblemImg.ZIndex = 802
    MinEmblemImg.Parent = MinimizeIconBtn

    if ResolvedMasterLogo == "" then
        local fbVec = DrawVectorIcon(MinimizeIconBtn, "AutoFarm", 28, "Accent", BindTheme)
        fbVec.Position = UDim2.fromScale(0.5, 0.5)
        fbVec.AnchorPoint = Vector2.new(0.5, 0.5)
        fbVec.ZIndex = 803
    end

    MinimizeIconBtn.MouseEnter:Connect(function()
        if not Self.IsMinimized then return end
        FastTween(MinimizeIconBtn, 0.14, {
            BackgroundColor3 = CurrentTheme.CardHoverBg,
            Size = UDim2.fromOffset(62, 62)
        })
        FastTween(MinSingleStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0})
    end)
    MinimizeIconBtn.MouseLeave:Connect(function()
        if not Self.IsMinimized then return end
        FastTween(MinimizeIconBtn, 0.16, {
            BackgroundColor3 = CurrentTheme.CardBg,
            Size = UDim2.fromOffset(58, 58)
        })
        FastTween(MinSingleStroke, 0.16, {Color = CurrentTheme.Stroke, Transparency = 0.12})
    end)

    -- =========================================================================
    -- MAIN WINDOW CONTAINER (SINGLE CLEAN BORDER)
    -- =========================================================================
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.fromOffset(1020, 600)
    MainWindow.Position = UDim2.fromScale(0.5, 0.5)
    MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    MainWindow.BackgroundTransparency = Self.BgTransparency
    MainWindow.BorderSizePixel = 0
    MainWindow.Active = true
    MainWindow.Parent = ScreenGui
    BindTheme(MainWindow, "BackgroundColor3", "MainBg")
    ApplySurfaceStyle(MainWindow, 14, CurrentTheme.Stroke, "Stroke", 0.20)

    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainWindow

    local function ComputeTargetScale()
        local cam = workspace.CurrentCamera
        if not cam then return uiScaleValue end
        local vp = cam.ViewportSize
        local autoFit = math.min(1, (vp.X * 0.94) / 1020, (vp.Y * 0.92) / 600)
        return math.clamp(autoFit * uiScaleValue, 0.42, 1.5)
    end

    local function UpdateResponsiveScale()
        if not Self.IsMinimized then
            WindowScale.Scale = ComputeTargetScale()
        end
    end

    local camConn
    local function BindCameraViewport()
        if camConn then camConn:Disconnect() end
        if workspace.CurrentCamera then
            camConn = TrackConn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale))
        end
        UpdateResponsiveScale()
    end
    TrackConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCameraViewport))
    BindCameraViewport()

    -- Custom Banner Layer (Hanya UICorner, Tanpa UIStroke Duplikat!)
    local resolvedBanner = ResolveImage(Self.BannerImage)
    local BannerLayer = Instance.new("ImageLabel")
    BannerLayer.Name = "CustomBanner"
    BannerLayer.Size = UDim2.fromScale(1, 1)
    BannerLayer.BackgroundTransparency = 1
    BannerLayer.ScaleType = Enum.ScaleType.Crop
    BannerLayer.Image = resolvedBanner
    BannerLayer.ImageTransparency = resolvedBanner ~= "" and Self.BannerTransparency or 1
    BannerLayer.Visible = (resolvedBanner ~= "")
    BannerLayer.Parent = MainWindow
    ApplyCornerOnly(BannerLayer, 14)

    -- Watermark Copyright R&8_DV
    local Watermark = Instance.new("TextLabel")
    Watermark.Size = UDim2.new(0, 170, 0, 16)
    Watermark.Position = UDim2.new(1, -178, 1, -16)
    Watermark.BackgroundTransparency = 1
    Watermark.Font = Enum.Font.GothamBold
    Watermark.Text = "(C) " .. Self.Copyright .. " ENGINE"
    Watermark.TextSize = 10
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    Watermark.TextTransparency = 0.55
    Watermark.Parent = MainWindow
    BindTheme(Watermark, "TextColor3", "TextMuted", "MainBg")

    -- 1. LEFT SIDEBAR (24%)
    local LeftSidebar = Instance.new("Frame")
    LeftSidebar.Name = "LeftSidebar"
    LeftSidebar.Position = UDim2.new(0, 12, 0, 12)
    LeftSidebar.Size = UDim2.new(0.24, -16, 1, -24)
    LeftSidebar.BackgroundTransparency = Self.BgTransparency
    LeftSidebar.BorderSizePixel = 0
    LeftSidebar.Parent = MainWindow
    BindTheme(LeftSidebar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(LeftSidebar, 12, CurrentTheme.Stroke, "Stroke", 0.28)

    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = UDim2.new(1, 0, 0, 114)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(72, 72)
    BrandLogo.Position = UDim2.new(0.5, 0, 0, 44)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolvedMasterLogo
    BrandLogo.Parent = LogoHolder

    if ResolvedMasterLogo == "" then
        local fallbackCrest = DrawVectorIcon(LogoHolder, "AutoFarm", 44, "Accent", BindTheme)
        fallbackCrest.Position = UDim2.new(0.5, 0, 0, 44)
        fallbackCrest.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    local BrandSubLbl = Instance.new("TextLabel")
    BrandSubLbl.Size = UDim2.new(1, -20, 0, 20)
    BrandSubLbl.Position = UDim2.new(0, 10, 0, 84)
    BrandSubLbl.BackgroundTransparency = 1
    BrandSubLbl.Font = Enum.Font.GothamBlack
    BrandSubLbl.Text = Self.Copyright .. "  //  MINIMAL"
    BrandSubLbl.TextSize = 11
    BrandSubLbl.Parent = LogoHolder
    ApplyRichText(BrandSubLbl, "Title25D", "PanelBg")

    local NavDivider = Instance.new("Frame")
    NavDivider.Size = UDim2.new(1, -28, 0, 1)
    NavDivider.Position = UDim2.new(0, 14, 0, 112)
    NavDivider.BorderSizePixel = 0
    NavDivider.BackgroundTransparency = 0.45
    NavDivider.Parent = LeftSidebar
    BindTheme(NavDivider, "BackgroundColor3", "Stroke")

    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Position = UDim2.new(0, 10, 0, 120)
    NavScroll.Size = UDim2.new(1, -20, 1, -184)
    NavScroll.BackgroundTransparency = 1
    NavScroll.BorderSizePixel = 0
    NavScroll.ScrollBarThickness = 2
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.Parent = LeftSidebar
    BindTheme(NavScroll, "ScrollBarImageColor3", "Accent")

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 5)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = NavScroll

    -- Sidebar Profile Card (Terinspirasi Referensi UI Modern Minimalis)
    local ProfileCard = Instance.new("Frame")
    ProfileCard.Size = UDim2.new(1, -20, 0, 48)
    ProfileCard.Position = UDim2.new(0, 10, 1, -58)
    ProfileCard.BorderSizePixel = 0
    ProfileCard.Parent = LeftSidebar
    BindTheme(ProfileCard, "BackgroundColor3", "CardBg")
    local _, profileStroke = ApplySurfaceStyle(ProfileCard, 10, CurrentTheme.Stroke, "Stroke", 0.30)

    local AvatarCircle = Instance.new("ImageLabel")
    AvatarCircle.Size = UDim2.fromOffset(32, 32)
    AvatarCircle.Position = UDim2.new(0, 9, 0.5, -16)
    AvatarCircle.BorderSizePixel = 0
    AvatarCircle.Parent = ProfileCard
    BindTheme(AvatarCircle, "BackgroundColor3", "ControlBg")
    ApplyCornerOnly(AvatarCircle, 16)
    pcall(function()
        if LocalPlayer and LocalPlayer.UserId and LocalPlayer.UserId > 0 then
            AvatarCircle.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=48&h=48"
        end
    end)

    local PlayerNameLbl = Instance.new("TextLabel")
    PlayerNameLbl.Position = UDim2.new(0, 48, 0, 7)
    PlayerNameLbl.Size = UDim2.new(1, -68, 0, 18)
    PlayerNameLbl.BackgroundTransparency = 1
    PlayerNameLbl.Font = Enum.Font.GothamBold
    PlayerNameLbl.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Operator"
    PlayerNameLbl.TextSize = 12
    PlayerNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    PlayerNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    PlayerNameLbl.Parent = ProfileCard
    ApplyRichText(PlayerNameLbl, "Title25D", "CardBg")

    local PlayerSubLbl = Instance.new("TextLabel")
    PlayerSubLbl.Position = UDim2.new(0, 48, 0, 25)
    PlayerSubLbl.Size = UDim2.new(1, -68, 0, 14)
    PlayerSubLbl.BackgroundTransparency = 1
    PlayerSubLbl.Font = Enum.Font.GothamMedium
    PlayerSubLbl.Text = "Active Session"
    PlayerSubLbl.TextSize = 10
    PlayerSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    PlayerSubLbl.Parent = ProfileCard
    BindTheme(PlayerSubLbl, "TextColor3", "TextMuted", "CardBg")

    local OnlineDot = Instance.new("Frame")
    OnlineDot.Size = UDim2.fromOffset(7, 7)
    OnlineDot.Position = UDim2.new(1, -16, 0.5, -3)
    OnlineDot.BorderSizePixel = 0
    OnlineDot.Parent = ProfileCard
    BindTheme(OnlineDot, "BackgroundColor3", "Accent")
    ApplyCornerOnly(OnlineDot, 4)

    ProfileCard.MouseEnter:Connect(function()
        FastTween(ProfileCard, 0.14, {BackgroundColor3 = CurrentTheme.CardHoverBg})
        FastTween(profileStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
    end)
    ProfileCard.MouseLeave:Connect(function()
        FastTween(ProfileCard, 0.16, {BackgroundColor3 = CurrentTheme.CardBg})
        FastTween(profileStroke, 0.16, {Color = CurrentTheme.Stroke, Transparency = 0.30})
    end)

    -- 2. TOP IMGUI HEADER BAR
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.24, 4, 0, 12)
    TopBar.Size = UDim2.new(0.76, -16, 0, 44)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 10, CurrentTheme.Stroke, "Stroke", 0.28)

    local TopLogoIcon = Instance.new("ImageLabel")
    TopLogoIcon.Position = UDim2.new(0, 14, 0.5, -11)
    TopLogoIcon.Size = UDim2.fromOffset(22, 22)
    TopLogoIcon.BackgroundTransparency = 1
    TopLogoIcon.ScaleType = Enum.ScaleType.Fit
    TopLogoIcon.Image = ResolvedMasterLogo
    TopLogoIcon.Parent = TopBar

    if ResolvedMasterLogo == "" then
        local vecTop = DrawVectorIcon(TopBar, "Layers", 18, "Accent", BindTheme)
        vecTop.Position = UDim2.new(0, 14, 0.5, -9)
    end

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Position = UDim2.new(0, 44, 0, 0)
    TopTitle.Size = UDim2.new(0.55, 0, 1, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Font = Enum.Font.GothamBlack
    TopTitle.Text = Self.Title
    TopTitle.TextSize = 14
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    ApplyRichText(TopTitle, "Display3D", "PanelBg")

    local TopThemeTag = Instance.new("Frame")
    TopThemeTag.AutomaticSize = Enum.AutomaticSize.X
    TopThemeTag.Size = UDim2.fromOffset(0, 24)
    TopThemeTag.Position = UDim2.new(1, -148, 0.5, -12)
    TopThemeTag.AnchorPoint = Vector2.new(1, 0)
    TopThemeTag.BorderSizePixel = 0
    TopThemeTag.Parent = TopBar
    BindTheme(TopThemeTag, "BackgroundColor3", "CardBg")
    ApplySurfaceStyle(TopThemeTag, 12, CurrentTheme.Stroke, "Stroke", 0.32)

    local TagPad = Instance.new("UIPadding")
    TagPad.PaddingLeft = UDim.new(0, 10)
    TagPad.PaddingRight = UDim.new(0, 10)
    TagPad.Parent = TopThemeTag

    local TopThemeTxt = Instance.new("TextLabel")
    TopThemeTxt.AutomaticSize = Enum.AutomaticSize.X
    TopThemeTxt.Size = UDim2.new(0, 0, 1, 0)
    TopThemeTxt.BackgroundTransparency = 1
    TopThemeTxt.Font = Enum.Font.GothamBold
    TopThemeTxt.Text = Self.ThemeName
    TopThemeTxt.TextSize = 11
    TopThemeTxt.Parent = TopThemeTag
    ApplyRichText(TopThemeTxt, "Title25D", "CardBg")

    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Position = UDim2.new(1, -138, 0, 0)
    ControlsHolder.Size = UDim2.new(0, 128, 1, 0)
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
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ControlsHolder
        BindTheme(btn, "BackgroundColor3", "ControlBg")
        ApplyCornerOnly(btn, 7)

        local icon, recolorIcon = DrawVectorIcon(btn, vectorType, 15, "TextMuted", BindTheme)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)

        btn.MouseEnter:Connect(function()
            FastTween(btn, 0.12, {BackgroundTransparency = 0.15})
            recolorIcon(CurrentTheme.Accent)
        end)
        btn.MouseLeave:Connect(function()
            FastTween(btn, 0.14, {BackgroundTransparency = 1})
            recolorIcon(CurrentTheme.TextMuted)
        end)
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.24, 4, 0, 66)
    CenterPanel.Size = (Self.SideCount == 3) and UDim2.new(0.50, -8, 1, -78) or UDim2.new(0.76, -16, 1, -78)
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.BorderSizePixel = 0
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, "Stroke", 0.28)

    -- 4. RIGHT PANEL
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.74, 4, 0, 66)
    RightPanel.Size = UDim2.new(0.26, -16, 1, -78)
    RightPanel.BackgroundTransparency = Self.BgTransparency
    RightPanel.BorderSizePixel = 0
    RightPanel.ClipsDescendants = true
    RightPanel.Visible = (Self.SideCount == 3)
    RightPanel.Parent = MainWindow
    BindTheme(RightPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(RightPanel, 12, CurrentTheme.Stroke, "Stroke", 0.28)

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
    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    -- =========================================================================
    -- LOGIKA MINIMIZE (-) & CLOSE (X) KE SINGLE-BORDER POPUP ICON
    -- =========================================================================
    function Self:MinimizeToIcon()
        if Self.IsMinimized then return end
        Self.IsMinimized = true
        FocusBlocker.Visible = false

        if Self.ReduceEffects then
            WindowScale.Scale = 0
            MainWindow.Visible = false
            MinimizeIconBtn.Size = UDim2.fromOffset(58, 58)
            MinimizeIconBtn.Visible = true
            return
        end

        local shrink = TweenService:Create(WindowScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Scale = 0
        })
        shrink:Play()
        shrink.Completed:Connect(function()
            if Self.IsMinimized then
                MainWindow.Visible = false
                MinimizeIconBtn.Size = UDim2.fromOffset(0, 0)
                MinimizeIconBtn.Visible = true
                TweenService:Create(MinimizeIconBtn, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(58, 58)
                }):Play()
            end
        end)
    end

    function Self:RestoreFromIcon()
        if not Self.IsMinimized then return end
        Self.IsMinimized = false

        if Self.ReduceEffects then
            MinimizeIconBtn.Visible = false
            MainWindow.Visible = true
            FocusBlocker.Visible = Self.FocusMode
            WindowScale.Scale = ComputeTargetScale()
            return
        end

        local hideIcon = TweenService:Create(MinimizeIconBtn, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(0, 0)
        })
        hideIcon:Play()
        hideIcon.Completed:Connect(function()
            if not Self.IsMinimized then
                MinimizeIconBtn.Visible = false
                MainWindow.Visible = true
                FocusBlocker.Visible = Self.FocusMode
                TweenService:Create(WindowScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
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
            FastTween(MinimizeIconBtn, 0.10, {Size = UDim2.fromOffset(52, 52)})

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    iconDragging = false
                    if movedDist < 6 then
                        Self:RestoreFromIcon()
                    else
                        FastTween(MinimizeIconBtn, 0.14, {Size = UDim2.fromOffset(58, 58)})
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
    TrackConn(UserInputService.InputChanged:Connect(function(input)
        if input == iconDragInput and iconDragging then
            local delta = input.Position - iconDragStart
            movedDist = delta.Magnitude
            MinimizeIconBtn.Position = UDim2.new(
                iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X,
                iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y
            )
        end
    end))

    -- Division Switcher (.Call(2) atau .Call(3))
    function Self.Call(sideCount)
        Self.SideCount = (sideCount == 2) and 2 or 3
        if Self.SideCount == 3 then
            RightPanel.Visible = true
            FastTween(CenterPanel, 0.20, {Size = UDim2.new(0.50, -8, 1, -78)})
        else
            RightPanel.Visible = false
            FastTween(CenterPanel, 0.20, {Size = UDim2.new(0.76, -16, 1, -78)})
        end
        return Self
    end

    -- 4 Tombol Kontrol Window di TopBar
    CreateVectorWindowBtn("Menu", function()
        Self.Call(Self.SideCount == 3 and 2 or 3)
    end)
    CreateVectorWindowBtn("Minimize", function()
        Self:MinimizeToIcon()
    end)
    local isMaximized = false
    CreateVectorWindowBtn("Maximize", function()
        isMaximized = not isMaximized
        FastTween(MainWindow, 0.22, {
            Size = isMaximized and UDim2.fromOffset(1160, 670) or UDim2.fromOffset(1020, 600)
        })
    end)
    CreateVectorWindowBtn("Close", function()
        Self:MinimizeToIcon()
    end)

    -- =========================================================================
    -- LIVE UPDATERS (TEMA, SCALE, TEXT 3D, CHECKBOX STYLE, TRANSPARENCY)
    -- =========================================================================
    local function RefreshAllThemeElements()
        for _, b in ipairs(Self.ThemeBindings) do
            if b.Instance and b.Instance.Parent then
                local col = CurrentTheme[b.Key]
                if col then
                    if b.BgKey and CurrentTheme[b.BgKey] then
                        col = GetReadableTextColor(CurrentTheme[b.BgKey], col)
                    end
                    b.Instance[b.Prop] = col
                end
            end
        end
        for _, u in ipairs(Self.ThemeUpdaters) do
            if u.Instance and u.Instance.Parent then
                u.Update(CurrentTheme)
            end
        end
    end

    function Self:SetTheme(themeName)
        if not Themes[themeName] then return end
        Self.ThemeName = themeName
        CurrentTheme = Themes[themeName]
        TopThemeTxt.Text = themeName
        RefreshAllThemeElements()
    end

    function Self:SetText3D(state)
        Self.Text3D = (state == true)
        RefreshAllThemeElements()
    end

    function Self:SetCheckboxStyle(styleName)
        Self.CheckboxStyle = styleName or "Modern"
        RefreshAllThemeElements()
    end

    function Self:SetScale(newScale)
        uiScaleValue = math.clamp(tonumber(newScale) or 1, 0.5, 1.5)
        UpdateResponsiveScale()
    end

    function Self:SetRounded(state)
        Self.Rounded = (state == true)
        for _, r in ipairs(Self.RadiusBindings) do
            if r.Instance and r.Instance.Parent then
                r.Instance.CornerRadius = UDim.new(0, Self.Rounded and r.BaseRadius or 0)
            end
        end
    end

    function Self:SetTransparency(alpha)
        Self.BgTransparency = math.clamp(tonumber(alpha) or 0, 0, 0.65)
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
        BannerLayer.Visible = (asset ~= "")
        BannerLayer.ImageTransparency = (asset ~= "") and Self.BannerTransparency or 1
    end

    function Self:Destroy()
        for _, c in ipairs(Self.Connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(Self.Connections)
        if ScreenGui and ScreenGui.Parent then
            ScreenGui:Destroy()
        end
    end

    TrackConn(ScreenGui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            for _, c in ipairs(Self.Connections) do
                pcall(function() c:Disconnect() end)
            end
        end
    end))

    local isBindingKey = false
    TrackConn(UserInputService.InputBegan:Connect(function(input, gp)
        if isBindingKey then return end
        if not gp and input.KeyCode == Self.ToggleKey then
            Self:ToggleMenu()
        end
    end))

    -- =========================================================================
    -- SMOOTH MINIMALIST LOADER (TANPA ANIMASI BERLEBIHAN / ZERO FPS DROP)
    -- =========================================================================
    function Self:RunInternalLoader(duration)
        duration = duration or 1.15
        local Loader = Instance.new("Frame")
        Loader.Name = "FrameworkLoader"
        Loader.Size = UDim2.fromScale(1, 1)
        Loader.BackgroundColor3 = CurrentTheme.MainBg
        Loader.BorderSizePixel = 0
        Loader.ZIndex = 500
        Loader.Parent = MainWindow
        ApplyCornerOnly(Loader, 14)

        local LoaderIcon = Instance.new("ImageLabel")
        LoaderIcon.Size = UDim2.fromOffset(72, 72)
        LoaderIcon.Position = UDim2.new(0.5, -36, 0.27, 0)
        LoaderIcon.BackgroundTransparency = 1
        LoaderIcon.ScaleType = Enum.ScaleType.Fit
        LoaderIcon.Image = ResolvedMasterLogo
        LoaderIcon.ZIndex = 501
        LoaderIcon.Parent = Loader

        local LoadTitle = Instance.new("TextLabel")
        LoadTitle.Size = UDim2.new(1, 0, 0, 32)
        LoadTitle.Position = UDim2.new(0, 0, 0.44, 0)
        LoadTitle.BackgroundTransparency = 1
        LoadTitle.Font = Enum.Font.GothamBlack
        LoadTitle.Text = Self.Title
        LoadTitle.TextSize = 23
        LoadTitle.ZIndex = 501
        LoadTitle.Parent = Loader
        ApplyRichText(LoadTitle, "Display3D", "MainBg")

        local LoadSub = Instance.new("TextLabel")
        LoadSub.Size = UDim2.new(1, 0, 0, 20)
        LoadSub.Position = UDim2.new(0, 0, 0.50, 0)
        LoadSub.BackgroundTransparency = 1
        LoadSub.Font = Enum.Font.GothamMedium
        LoadSub.Text = "Loading R&8_DV Minimalist Interface..."
        LoadSub.TextSize = 12
        LoadSub.ZIndex = 501
        LoadSub.Parent = Loader
        BindTheme(LoadSub, "TextColor3", "TextMuted", "MainBg")

        local BarBg = Instance.new("Frame")
        BarBg.Size = UDim2.fromOffset(260, 5)
        BarBg.Position = UDim2.new(0.5, -130, 0.58, 0)
        BarBg.BorderSizePixel = 0
        BarBg.ZIndex = 501
        BarBg.Parent = Loader
        BindTheme(BarBg, "BackgroundColor3", "ControlBg")
        ApplySurfaceStyle(BarBg, 3, CurrentTheme.Stroke, "Stroke", 0.35)

        -- Tanpa UIStroke ganda pada BarFill
        local BarFill = Instance.new("Frame")
        BarFill.Size = UDim2.new(0, 0, 1, 0)
        BarFill.BorderSizePixel = 0
        BarFill.ZIndex = 502
        BarFill.Parent = BarBg
        BindTheme(BarFill, "BackgroundColor3", "Accent")
        ApplyCornerOnly(BarFill, 3)

        task.spawn(function()
            pcall(function()
                ContentProvider:PreloadAsync({BrandLogo, TopLogoIcon, MinEmblemImg, LoaderIcon})
            end)
        end)

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.82, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(1, 1)
        }):Play()

        task.delay(duration, function()
            if Loader and Loader.Parent then
                TweenService:Create(Loader, TweenInfo.new(0.22), {BackgroundTransparency = 1}):Play()
                TweenService:Create(LoaderIcon, TweenInfo.new(0.18), {ImageTransparency = 1}):Play()
                TweenService:Create(LoadTitle, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
                TweenService:Create(LoadSub, TweenInfo.new(0.18), {TextTransparency = 1}):Play()
                TweenService:Create(BarBg, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
                TweenService:Create(BarFill, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
                for _, desc in ipairs(Loader:GetDescendants()) do
                    if desc:IsA("UIStroke") then
                        TweenService:Create(desc, TweenInfo.new(0.18), {Transparency = 1}):Play()
                    end
                end
                task.wait(0.23)
                if Loader and Loader.Parent then
                    Loader:Destroy()
                end
            end
        end)
    end

    if Self.AutoLoading then
        Self:RunInternalLoader(1.15)
    end

    -- =========================================================================
    -- WIDGET FACTORY (`center()` & `right()`) - BOLD MENU TYPOGRAPHY & CARD HOVER
    -- =========================================================================
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

        function Builder:Header(title, subtitle, badgeText)
            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Size = UDim2.new(1, 0, 0, subtitle and 56 or 38)
            HeaderFrame.BackgroundTransparency = 1
            HeaderFrame.Parent = scrollingPage

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(0, 4, 0, subtitle and 44 or 28)
            AccentBar.Position = UDim2.new(0, 0, 0, 6)
            AccentBar.BorderSizePixel = 0
            AccentBar.Parent = HeaderFrame
            BindTheme(AccentBar, "BackgroundColor3", "Accent")
            ApplyCornerOnly(AccentBar, 3)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 14, 0, 3)
            TitleLbl.Size = UDim2.new(0.68, 0, 0, 28)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBlack
            TitleLbl.Text = title
            TitleLbl.TextSize = 22
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = HeaderFrame
            ApplyRichText(TitleLbl, "Display3D", "PanelBg")

            if subtitle and subtitle ~= "" then
                local SubLbl = Instance.new("TextLabel")
                SubLbl.Position = UDim2.new(0, 14, 0, 32)
                SubLbl.Size = UDim2.new(0.72, 0, 0, 18)
                SubLbl.BackgroundTransparency = 1
                SubLbl.Font = Enum.Font.GothamMedium
                SubLbl.Text = subtitle
                SubLbl.TextSize = 12
                SubLbl.TextXAlignment = Enum.TextXAlignment.Left
                SubLbl.Parent = HeaderFrame
                BindTheme(SubLbl, "TextColor3", "TextMuted", "PanelBg")
            end

            if badgeText and badgeText ~= "" then
                local Pill = Instance.new("Frame")
                Pill.AutomaticSize = Enum.AutomaticSize.X
                Pill.Size = UDim2.fromOffset(0, 28)
                Pill.Position = UDim2.new(1, 0, 0, 10)
                Pill.AnchorPoint = Vector2.new(1, 0)
                Pill.BorderSizePixel = 0
                Pill.Parent = HeaderFrame
                BindTheme(Pill, "BackgroundColor3", "CardBg")
                local _, pillStroke = ApplySurfaceStyle(Pill, 14, CurrentTheme.Stroke, "Stroke", 0.28)

                local PillPad = Instance.new("UIPadding")
                PillPad.PaddingLeft = UDim.new(0, 12)
                PillPad.PaddingRight = UDim.new(0, 12)
                PillPad.Parent = Pill

                local PillLayout = Instance.new("UIListLayout")
                PillLayout.FillDirection = Enum.FillDirection.Horizontal
                PillLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                PillLayout.Padding = UDim.new(0, 7)
                PillLayout.Parent = Pill

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(7, 7)
                Dot.BorderSizePixel = 0
                Dot.Parent = Pill
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplyCornerOnly(Dot, 4)

                local PillTxt = Instance.new("TextLabel")
                PillTxt.AutomaticSize = Enum.AutomaticSize.X
                PillTxt.Size = UDim2.new(0, 0, 1, 0)
                PillTxt.BackgroundTransparency = 1
                PillTxt.Font = Enum.Font.GothamBold
                PillTxt.Text = badgeText
                PillTxt.TextSize = 11
                PillTxt.Parent = Pill
                ApplyRichText(PillTxt, "Title25D", "CardBg")

                Pill.MouseEnter:Connect(function()
                    FastTween(Pill, 0.14, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                    FastTween(pillStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0.05})
                end)
                Pill.MouseLeave:Connect(function()
                    FastTween(Pill, 0.16, {BackgroundColor3 = CurrentTheme.CardBg})
                    FastTween(pillStroke, 0.16, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                end)
            end
        end

        function Builder:StatRow(statsList)
            local count = math.max(#statsList, 1)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 74)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / count, -8, 1, 0)
            Grid.CellPadding = UDim2.new(0, 10, 0, 0)
            Grid.Parent = Row

            local ValueLabels = {}
            for i, item in ipairs(statsList) do
                local Card = Instance.new("Frame")
                Card.BorderSizePixel = 0
                Card.Parent = Row
                BindTheme(Card, "BackgroundColor3", "CardBg")
                local _, statStroke = ApplySurfaceStyle(Card, 10, CurrentTheme.Stroke, "Stroke", 0.28)

                local IconBox = Instance.new("Frame")
                IconBox.Size = UDim2.fromOffset(36, 36)
                IconBox.Position = UDim2.new(0, 12, 0.5, -18)
                IconBox.BorderSizePixel = 0
                IconBox.Parent = Card
                BindTheme(IconBox, "BackgroundColor3", "ControlBg")
                ApplyCornerOnly(IconBox, 9)

                local vecIcon = DrawVectorIcon(IconBox, item.Icon or "Bolt", 20, "Accent", BindTheme)
                vecIcon.Position = UDim2.fromScale(0.5, 0.5)
                vecIcon.AnchorPoint = Vector2.new(0.5, 0.5)

                local Lbl = Instance.new("TextLabel")
                Lbl.Position = UDim2.new(0, 56, 0, 15)
                Lbl.Size = UDim2.new(1, -62, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = string.upper(tostring(item.Label or ""))
                Lbl.TextSize = 10
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Card
                BindTheme(Lbl, "TextColor3", "TextMuted", "CardBg")

                local Val = Instance.new("TextLabel")
                Val.Position = UDim2.new(0, 56, 0, 33)
                Val.Size = UDim2.new(1, -62, 0, 22)
                Val.BackgroundTransparency = 1
                Val.Font = Enum.Font.GothamBlack
                Val.Text = tostring(item.Value or "")
                Val.TextSize = 16
                Val.TextXAlignment = Enum.TextXAlignment.Left
                Val.Parent = Card
                ApplyRichText(Val, "Display3D", "CardBg")
                ValueLabels[i] = Val

                Card.MouseEnter:Connect(function()
                    FastTween(Card, 0.14, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                    FastTween(statStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0.06})
                end)
                Card.MouseLeave:Connect(function()
                    FastTween(Card, 0.16, {BackgroundColor3 = CurrentTheme.CardBg})
                    FastTween(statStroke, 0.16, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                end)
            end
            return ValueLabels
        end

        -- =====================================================================
        -- CARD CONTAINER + CARD HOVER + OPSIONAL SUBTITLE & MASTER HEADER TOGGLE
        -- (Sesuai Referensi Opium / RT Store / Warm Gold Menu)
        -- =====================================================================
        function Builder:Card(title, rightActionText, iconName, cardOpts)
            if type(rightActionText) == "table" and cardOpts == nil then
                cardOpts = rightActionText
                rightActionText = cardOpts.ActionText
                iconName = iconName or cardOpts.Icon
            end
            cardOpts = cardOpts or {}

            local CardFrame = Instance.new("Frame")
            CardFrame.Size = UDim2.new(1, 0, 0, 42)
            CardFrame.AutomaticSize = Enum.AutomaticSize.Y
            CardFrame.BorderSizePixel = 0
            CardFrame.Parent = scrollingPage
            BindTheme(CardFrame, "BackgroundColor3", "CardBg")
            local _, cardStroke = ApplySurfaceStyle(CardFrame, 10, CurrentTheme.Stroke, "Stroke", 0.28)

            -- Card Hover Micro-Interaction (Event-Driven, 0% Idle Overhead)
            CardFrame.MouseEnter:Connect(function()
                FastTween(CardFrame, 0.15, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                FastTween(cardStroke, 0.15, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
            end)
            CardFrame.MouseLeave:Connect(function()
                FastTween(CardFrame, 0.18, {BackgroundColor3 = CurrentTheme.CardBg})
                FastTween(cardStroke, 0.18, {Color = CurrentTheme.Stroke, Transparency = 0.28})
            end)

            local Pad = Instance.new("UIPadding")
            Pad.PaddingTop = UDim.new(0, 13)
            Pad.PaddingBottom = UDim.new(0, 13)
            Pad.PaddingLeft = UDim.new(0, 14)
            Pad.PaddingRight = UDim.new(0, 14)
            Pad.Parent = CardFrame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 9)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = CardFrame

            if title then
                local hasSub = (cardOpts.Subtitle and cardOpts.Subtitle ~= "")
                local TopRow = Instance.new("Frame")
                TopRow.Size = UDim2.new(1, 0, 0, hasSub and 38 or 22)
                TopRow.BackgroundTransparency = 1
                TopRow.Parent = CardFrame

                local leftOffset = 0
                if iconName then
                    local hdrIcon = DrawVectorIcon(TopRow, iconName, 17, "Accent", BindTheme)
                    hdrIcon.Position = UDim2.new(0, 0, 0, hasSub and 3 or 2)
                    leftOffset = 25
                end

                local TitleTxt = Instance.new("TextLabel")
                TitleTxt.Position = UDim2.new(0, leftOffset, 0, 0)
                TitleTxt.Size = UDim2.new(0.74, -leftOffset, 0, 20)
                TitleTxt.BackgroundTransparency = 1
                TitleTxt.Font = Enum.Font.GothamBold
                TitleTxt.Text = title
                TitleTxt.TextSize = 14
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
                TitleTxt.Parent = TopRow
                ApplyRichText(TitleTxt, "Title25D", "CardBg")

                if hasSub then
                    local CardSub = Instance.new("TextLabel")
                    CardSub.Position = UDim2.new(0, leftOffset, 0, 21)
                    CardSub.Size = UDim2.new(0.82, -leftOffset, 0, 15)
                    CardSub.BackgroundTransparency = 1
                    CardSub.Font = Enum.Font.GothamMedium
                    CardSub.Text = cardOpts.Subtitle
                    CardSub.TextSize = 11
                    CardSub.TextXAlignment = Enum.TextXAlignment.Left
                    CardSub.Parent = TopRow
                    BindTheme(CardSub, "TextColor3", "TextMuted", "CardBg")
                end

                if cardOpts.ToggleFlag then
                    local tFlag = cardOpts.ToggleFlag
                    Self.Flags[tFlag] = (cardOpts.Default == true)

                    local HdrSwitch = Instance.new("TextButton")
                    HdrSwitch.Size = UDim2.fromOffset(36, 19)
                    HdrSwitch.Position = UDim2.new(1, -36, 0, 1)
                    HdrSwitch.BorderSizePixel = 0
                    HdrSwitch.Text = ""
                    HdrSwitch.AutoButtonColor = false
                    HdrSwitch.Parent = TopRow
                    local _, hdrSwStroke = ApplySurfaceStyle(HdrSwitch, 10, CurrentTheme.Stroke, false, 0.30)

                    local HdrKnob = Instance.new("Frame")
                    HdrKnob.Size = UDim2.fromOffset(13, 13)
                    HdrKnob.AnchorPoint = Vector2.new(0, 0.5)
                    HdrKnob.BorderSizePixel = 0
                    HdrKnob.Parent = HdrSwitch
                    ApplyCornerOnly(HdrKnob, 7)

                    local function SyncHdrSwitch(animated)
                        local on = (Self.Flags[tFlag] == true)
                        local bgCol = on and CurrentTheme.Accent or CurrentTheme.ControlBg
                        local knobCol = on and CurrentTheme.KnobOn or Color3.fromRGB(238, 242, 250)
                        local targetPos = on and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                        hdrSwStroke.Color = on and CurrentTheme.Accent or CurrentTheme.Stroke
                        if animated then
                            FastTween(HdrSwitch, 0.15, {BackgroundColor3 = bgCol})
                            FastTween(HdrKnob, 0.15, {Position = targetPos, BackgroundColor3 = knobCol})
                        else
                            HdrSwitch.BackgroundColor3 = bgCol
                            HdrKnob.Position = targetPos
                            HdrKnob.BackgroundColor3 = knobCol
                        end
                    end

                    RegisterThemeUpdater(HdrSwitch, function() SyncHdrSwitch(false) end)
                    Self:OnValueChanged(tFlag, function() SyncHdrSwitch(true) end)

                    HdrSwitch.MouseButton1Click:Connect(function()
                        local nextVal = not Self.Flags[tFlag]
                        Self:SetValue(tFlag, nextVal)
                        if cardOpts.Callback then task.spawn(cardOpts.Callback, nextVal) end
                    end)
                elseif rightActionText then
                    local ActionTxt = Instance.new("TextLabel")
                    ActionTxt.Size = UDim2.new(0.28, -16, 0, 20)
                    ActionTxt.Position = UDim2.new(0.72, 0, 0, 0)
                    ActionTxt.BackgroundTransparency = 1
                    ActionTxt.Font = Enum.Font.GothamBold
                    ActionTxt.Text = rightActionText
                    ActionTxt.TextSize = 11
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right
                    ActionTxt.Parent = TopRow
                    BindTheme(ActionTxt, "TextColor3", "TextMuted", "CardBg")

                    local arr = DrawVectorIcon(TopRow, "ArrowRight", 12, "TextMuted", BindTheme)
                    arr.Position = UDim2.new(1, -12, 0, 4)
                end

                local Divider = Instance.new("Frame")
                Divider.Size = UDim2.new(1, 0, 0, 1)
                Divider.BorderSizePixel = 0
                Divider.BackgroundTransparency = 0.50
                Divider.Parent = CardFrame
                BindTheme(Divider, "BackgroundColor3", "Stroke")
            end

            return CreateCanvasBuilder(CardFrame)
        end

        -- =====================================================================
        -- INTERACTIVE FEATURE HOVER CARD (Sesuai Referensi Automation / Autofarm Card)
        -- =====================================================================
        function Builder:FeatureCard(opts)
            opts = opts or {}
            local title = opts.Title or opts.Name or "Feature"
            local desc = opts.Description or opts.Subtitle or ""
            local iconName = opts.Icon or "Bot"
            local flag = opts.Flag or ("FeatureCard_" .. title)
            local isToggleable = (opts.Toggle ~= false)

            if isToggleable then
                Self.Flags[flag] = (opts.Default == true)
            end

            local CardBtn = Instance.new("TextButton")
            CardBtn.Size = UDim2.new(1, 0, 0, desc ~= "" and 66 or 48)
            CardBtn.BorderSizePixel = 0
            CardBtn.Text = ""
            CardBtn.AutoButtonColor = false
            CardBtn.Parent = scrollingPage
            local _, fcStroke = ApplySurfaceStyle(CardBtn, 11, CurrentTheme.Stroke, false, 0.25)

            local BtnScale = Instance.new("UIScale")
            BtnScale.Parent = CardBtn

            local IconBadge = Instance.new("Frame")
            IconBadge.Size = UDim2.fromOffset(40, 40)
            IconBadge.Position = UDim2.new(0, 13, 0.5, -20)
            IconBadge.BorderSizePixel = 0
            IconBadge.Parent = CardBtn
            ApplyCornerOnly(IconBadge, 10)

            local recolorVec = nil
            if opts.Image and opts.Image ~= "" then
                local Img = Instance.new("ImageLabel")
                Img.Size = UDim2.fromScale(0.72, 0.72)
                Img.Position = UDim2.fromScale(0.5, 0.5)
                Img.AnchorPoint = Vector2.new(0.5, 0.5)
                Img.BackgroundTransparency = 1
                Img.ScaleType = Enum.ScaleType.Fit
                Img.Image = ResolveImage(opts.Image)
                Img.Parent = IconBadge
            else
                local vec, recolor = DrawVectorIcon(IconBadge, iconName, 20, "Accent", BindTheme)
                vec.Position = UDim2.fromScale(0.5, 0.5)
                vec.AnchorPoint = Vector2.new(0.5, 0.5)
                recolorVec = recolor
            end

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 64, 0, desc ~= "" and 11 or 14)
            TitleLbl.Size = UDim2.new(1, -124, 0, 20)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBold
            TitleLbl.Text = title
            TitleLbl.TextSize = 14
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = CardBtn
            local setHighlightText = ApplyRichText(TitleLbl, "Label25D", "CardBg")

            if desc ~= "" then
                local DescLbl = Instance.new("TextLabel")
                DescLbl.Position = UDim2.new(0, 64, 0, 31)
                DescLbl.Size = UDim2.new(1, -118, 0, 26)
                DescLbl.BackgroundTransparency = 1
                DescLbl.Font = Enum.Font.GothamMedium
                DescLbl.Text = desc
                DescLbl.TextSize = 11
                DescLbl.TextWrapped = true
                DescLbl.TextXAlignment = Enum.TextXAlignment.Left
                DescLbl.TextYAlignment = Enum.TextYAlignment.Top
                DescLbl.Parent = CardBtn
                BindTheme(DescLbl, "TextColor3", "TextMuted", "CardBg")
            end

            local StatusPill = Instance.new("Frame")
            StatusPill.AutomaticSize = Enum.AutomaticSize.X
            StatusPill.Size = UDim2.fromOffset(0, 22)
            StatusPill.Position = UDim2.new(1, -13, 0.5, -11)
            StatusPill.AnchorPoint = Vector2.new(1, 0)
            StatusPill.BorderSizePixel = 0
            StatusPill.Parent = CardBtn
            ApplyCornerOnly(StatusPill, 7)

            local spPad = Instance.new("UIPadding")
            spPad.PaddingLeft = UDim.new(0, 8)
            spPad.PaddingRight = UDim.new(0, 8)
            spPad.Parent = StatusPill

            local StatusTxt = Instance.new("TextLabel")
            StatusTxt.AutomaticSize = Enum.AutomaticSize.X
            StatusTxt.Size = UDim2.new(0, 0, 1, 0)
            StatusTxt.BackgroundTransparency = 1
            StatusTxt.Font = Enum.Font.GothamBold
            StatusTxt.TextSize = 10
            StatusTxt.Parent = StatusPill

            local hovered = false
            local function SyncCardState(animated)
                local active = isToggleable and (Self.Flags[flag] == true)
                local bgCol = active and CurrentTheme.AccentSoft or (hovered and CurrentTheme.CardHoverBg or CurrentTheme.CardBg)
                local stCol = active and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                local stTrans = active and 0.05 or (hovered and 0.08 or 0.28)
                local badgeBg = active and CurrentTheme.Accent or CurrentTheme.ControlBg

                StatusPill.BackgroundColor3 = active and CurrentTheme.Accent or CurrentTheme.ControlBg
                StatusTxt.Text = opts.Badge or (isToggleable and (active and "ON" or "OFF") or "OPEN")
                StatusTxt.TextColor3 = active and CurrentTheme.KnobOn or CurrentTheme.TextMuted
                setHighlightText(active or hovered)

                if recolorVec then
                    recolorVec(active and CurrentTheme.KnobOn or CurrentTheme.Accent)
                end

                if animated then
                    FastTween(CardBtn, 0.14, {BackgroundColor3 = bgCol})
                    FastTween(fcStroke, 0.14, {Color = stCol, Transparency = stTrans})
                    FastTween(IconBadge, 0.14, {BackgroundColor3 = badgeBg})
                else
                    CardBtn.BackgroundColor3 = bgCol
                    fcStroke.Color = stCol
                    fcStroke.Transparency = stTrans
                    IconBadge.BackgroundColor3 = badgeBg
                end
            end

            RegisterThemeUpdater(CardBtn, function() SyncCardState(false) end)
            if isToggleable then
                Self:OnValueChanged(flag, function() SyncCardState(true) end)
            end

            CardBtn.MouseEnter:Connect(function()
                hovered = true
                FastTween(BtnScale, 0.14, {Scale = 1.01})
                SyncCardState(true)
            end)
            CardBtn.MouseLeave:Connect(function()
                hovered = false
                FastTween(BtnScale, 0.16, {Scale = 1})
                SyncCardState(true)
            end)
            CardBtn.MouseButton1Down:Connect(function()
                FastTween(BtnScale, 0.09, {Scale = 0.985})
            end)
            CardBtn.MouseButton1Up:Connect(function()
                FastTween(BtnScale, 0.12, {Scale = hovered and 1.01 or 1})
            end)
            CardBtn.MouseButton1Click:Connect(function()
                if isToggleable then
                    local nextVal = not Self.Flags[flag]
                    Self:SetValue(flag, nextVal)
                    if opts.Callback then task.spawn(opts.Callback, nextVal) end
                else
                    if opts.Callback then task.spawn(opts.Callback) end
                end
            end)
        end

        function Builder:ActionGrid(items)
            local cols = math.clamp(#items, 1, 3)
            if #items >= 6 then cols = 3 end
            local GridHolder = Instance.new("Frame")
            GridHolder.Size = UDim2.new(1, 0, 0, 82)
            GridHolder.AutomaticSize = Enum.AutomaticSize.Y
            GridHolder.BackgroundTransparency = 1
            GridHolder.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / cols, -7, 0, 74)
            Grid.CellPadding = UDim2.new(0, 8, 0, 8)
            Grid.Parent = GridHolder

            for _, action in ipairs(items) do
                local flag = action.Flag or action.Name
                Self.Flags[flag] = (action.Default == true)

                local Tile = Instance.new("TextButton")
                Tile.BorderSizePixel = 0
                Tile.Text = ""
                Tile.AutoButtonColor = false
                Tile.Parent = GridHolder
                local _, tileStroke = ApplySurfaceStyle(Tile, 9, CurrentTheme.Stroke, false, 0.28)

                local TileScale = Instance.new("UIScale")
                TileScale.Parent = Tile

                local vec, recolorVec = DrawVectorIcon(Tile, action.Icon or "Bolt", 21, "Accent", BindTheme)
                vec.Position = UDim2.new(0.5, -10, 0, 14)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -8, 0, 18)
                Lbl.Position = UDim2.new(0, 4, 1, -24)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = action.Name
                Lbl.TextSize = 11
                Lbl.TextTruncate = Enum.TextTruncate.AtEnd
                Lbl.Parent = Tile
                local setLblActive = ApplyRichText(Lbl, "Label25D", "ControlBg")

                local hovered = false
                local function SyncTile(animated)
                    local on = (Self.Flags[flag] == true)
                    local bg = on and CurrentTheme.AccentSoft or (hovered and CurrentTheme.CardHoverBg or CurrentTheme.ControlBg)
                    local st = on and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                    local tr = on and 0 or (hovered and 0.08 or 0.28)
                    setLblActive(on)
                    recolorVec(CurrentTheme.Accent)
                    if animated then
                        FastTween(Tile, 0.14, {BackgroundColor3 = bg})
                        FastTween(tileStroke, 0.14, {Color = st, Transparency = tr})
                    else
                        Tile.BackgroundColor3 = bg
                        tileStroke.Color = st
                        tileStroke.Transparency = tr
                    end
                end

                RegisterThemeUpdater(Tile, function() SyncTile(false) end)
                Self:OnValueChanged(flag, function() SyncTile(true) end)

                Tile.MouseEnter:Connect(function()
                    hovered = true
                    SyncTile(true)
                end)
                Tile.MouseLeave:Connect(function()
                    hovered = false
                    FastTween(TileScale, 0.12, {Scale = 1})
                    SyncTile(true)
                end)
                Tile.MouseButton1Down:Connect(function()
                    FastTween(TileScale, 0.08, {Scale = 0.96})
                end)
                Tile.MouseButton1Up:Connect(function()
                    FastTween(TileScale, 0.12, {Scale = 1})
                end)
                Tile.MouseButton1Click:Connect(function()
                    local nextVal = not Self.Flags[flag]
                    Self:SetValue(flag, nextVal)
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
            Lbl.TextSize = 13
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row
            ApplyRichText(Lbl, "Title25D", "PanelBg")
        end

        -- =====================================================================
        -- TOGGLE SWITCH / CHECKBOX (MENDUKUNG GAYA "Modern" PILL & "Checkbox" BOX)
        -- =====================================================================
        function Builder:Toggle(label, flag, default, callback, styleOverride)
            Self.Flags[flag] = (default == true)

            local Row = Instance.new("TextButton")
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.Text = ""
            Row.AutoButtonColor = false
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -52, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            local setTitleHighlight = ApplyRichText(Title, "Label25D", "CardBg")

            local SwitchBg = Instance.new("Frame")
            SwitchBg.AnchorPoint = Vector2.new(1, 0.5)
            SwitchBg.Position = UDim2.new(1, 0, 0.5, 0)
            SwitchBg.BorderSizePixel = 0
            SwitchBg.Parent = Row
            local swCorner, swStroke = ApplySurfaceStyle(SwitchBg, 10, CurrentTheme.Stroke, false, 0.28)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.fromOffset(14, 14)
            Knob.AnchorPoint = Vector2.new(0, 0.5)
            Knob.BorderSizePixel = 0
            Knob.Parent = SwitchBg
            ApplyCornerOnly(Knob, 7)

            local CheckVec, recolorCheck = DrawVectorIcon(SwitchBg, "Check", 13, "Accent", BindTheme)
            CheckVec.Position = UDim2.fromScale(0.5, 0.5)
            CheckVec.AnchorPoint = Vector2.new(0.5, 0.5)

            local hovered = false
            local function SyncToggle(animated)
                local on = (Self.Flags[flag] == true)
                local mode = string.lower(tostring(styleOverride or Self.CheckboxStyle or "modern"))
                local isBox = (mode == "checkbox" or mode == "box" or mode == "classic")

                setTitleHighlight(on)
                local bgCol = on and CurrentTheme.Accent or CurrentTheme.ControlBg
                local stCol = on and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                local stTr = on and 0.05 or (hovered and 0.08 or 0.28)

                if isBox then
                    SwitchBg.Size = UDim2.fromOffset(20, 20)
                    swCorner.CornerRadius = UDim.new(0, Self.Rounded and 5 or 0)
                    Knob.Visible = false
                    CheckVec.Visible = on
                    recolorCheck(CurrentTheme.KnobOn)
                else
                    SwitchBg.Size = UDim2.fromOffset(38, 20)
                    swCorner.CornerRadius = UDim.new(0, Self.Rounded and 10 or 0)
                    CheckVec.Visible = false
                    Knob.Visible = true
                    local knobCol = on and CurrentTheme.KnobOn or Color3.fromRGB(240, 244, 252)
                    local targetPos = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                    if animated then
                        FastTween(Knob, 0.15, {Position = targetPos, BackgroundColor3 = knobCol})
                    else
                        Knob.Position = targetPos
                        Knob.BackgroundColor3 = knobCol
                    end
                end

                if animated then
                    FastTween(SwitchBg, 0.15, {BackgroundColor3 = bgCol})
                    FastTween(swStroke, 0.15, {Color = stCol, Transparency = stTr})
                else
                    SwitchBg.BackgroundColor3 = bgCol
                    swStroke.Color = stCol
                    swStroke.Transparency = stTr
                end
            end

            RegisterThemeUpdater(Row, function() SyncToggle(false) end)
            Self:OnValueChanged(flag, function() SyncToggle(true) end)

            Row.MouseEnter:Connect(function()
                hovered = true
                SyncToggle(true)
            end)
            Row.MouseLeave:Connect(function()
                hovered = false
                SyncToggle(true)
            end)
            Row.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                if callback then task.spawn(callback, nextVal) end
            end)
        end

        -- =====================================================================
        -- SLIDER DENGAN CIRCULAR THUMB KNOB & MICRO-INTERACTION HOVER/DRAG
        -- =====================================================================
        function Builder:Slider(label, flag, min, max, default, suffix, callback, step)
            suffix = suffix or ""
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if max <= min then max = min + 1 end
            step = tonumber(step) or 1
            Self.Flags[flag] = math.clamp(tonumber(default) or min, min, max)

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 32)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.42, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            ApplyRichText(Title, "Label25D", "CardBg")

            local HitArea = Instance.new("TextButton")
            HitArea.Size = UDim2.new(0.38, 0, 0, 22)
            HitArea.Position = UDim2.new(0.43, 0, 0.5, -11)
            HitArea.BackgroundTransparency = 1
            HitArea.Text = ""
            HitArea.AutoButtonColor = false
            HitArea.Parent = Row

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 5)
            Track.Position = UDim2.new(0, 0, 0.5, -2)
            Track.BorderSizePixel = 0
            Track.Parent = HitArea
            BindTheme(Track, "BackgroundColor3", "ControlBg")
            local _, trackStroke = ApplySurfaceStyle(Track, 3, CurrentTheme.Stroke, "Stroke", 0.30)

            local function CalcPct(v)
                return math.clamp((v - min) / (max - min), 0, 1)
            end

            -- Fill tanpa UIStroke ganda!
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(CalcPct(Self.Flags[flag]), 0, 1, 0)
            Fill.BorderSizePixel = 0
            Fill.Parent = Track
            BindTheme(Fill, "BackgroundColor3", "Accent")
            ApplyCornerOnly(Fill, 3)

            local Thumb = Instance.new("Frame")
            Thumb.Size = UDim2.fromOffset(11, 11)
            Thumb.Position = UDim2.new(CalcPct(Self.Flags[flag]), 0, 0.5, 0)
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.BackgroundColor3 = Color3.fromRGB(252, 254, 255)
            Thumb.BorderSizePixel = 0
            Thumb.ZIndex = 3
            Thumb.Parent = Track
            ApplyCornerOnly(Thumb, 8)

            local ValTxt = Instance.new("TextLabel")
            ValTxt.Size = UDim2.new(0.18, 0, 1, 0)
            ValTxt.Position = UDim2.new(0.82, 0, 0, 0)
            ValTxt.BackgroundTransparency = 1
            ValTxt.Font = Enum.Font.GothamBold
            ValTxt.TextSize = 12
            ValTxt.TextXAlignment = Enum.TextXAlignment.Right
            ValTxt.Parent = Row
            ApplyRichText(ValTxt, "Title25D", "CardBg")

            local function FormatVal(v)
                if step < 1 then
                    return string.format("%.2f", v):gsub("%.?0+$", "") .. suffix
                end
                return tostring(math.floor(v + 0.5)) .. suffix
            end
            ValTxt.Text = FormatVal(Self.Flags[flag])

            local function SyncVisual(v)
                local clamped = math.clamp(tonumber(v) or min, min, max)
                local pct = CalcPct(clamped)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                ValTxt.Text = FormatVal(clamped)
            end

            Self:OnValueChanged(flag, SyncVisual)

            local sliding = false
            local hovered = false

            local function UpdateFromInput(input)
                local width = math.max(Track.AbsoluteSize.X, 1)
                local rawPct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / width, 0, 1)
                local rawVal = min + (max - min) * rawPct
                local snapped = math.clamp(math.floor((rawVal / step) + 0.5) * step, min, max)
                SyncVisual(snapped)
                if Self.Flags[flag] ~= snapped then
                    Self:SetValue(flag, snapped)
                    if callback then task.spawn(callback, snapped) end
                end
            end

            HitArea.MouseEnter:Connect(function()
                hovered = true
                FastTween(Thumb, 0.12, {Size = UDim2.fromOffset(14, 14)})
                FastTween(trackStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
            end)
            HitArea.MouseLeave:Connect(function()
                hovered = false
                if not sliding then
                    FastTween(Thumb, 0.14, {Size = UDim2.fromOffset(11, 11)})
                    FastTween(trackStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.30})
                end
            end)
            HitArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    FastTween(Thumb, 0.10, {Size = UDim2.fromOffset(15, 15)})
                    UpdateFromInput(input)
                end
            end)
            TrackConn(UserInputService.InputEnded:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    sliding = false
                    if not hovered then
                        FastTween(Thumb, 0.14, {Size = UDim2.fromOffset(11, 11)})
                        FastTween(trackStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.30})
                    end
                end
            end))
            TrackConn(UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end))
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
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            ApplyRichText(Title, "Label25D", "CardBg")

            local Controls = Instance.new("Frame")
            Controls.Size = UDim2.fromOffset(98, 25)
            Controls.Position = UDim2.new(1, -98, 0.5, -12)
            Controls.BorderSizePixel = 0
            Controls.Parent = Row
            BindTheme(Controls, "BackgroundColor3", "ControlBg")
            local _, ctrlStroke = ApplySurfaceStyle(Controls, 6, CurrentTheme.Stroke, "Stroke", 0.28)

            local Minus = Instance.new("TextButton")
            Minus.Size = UDim2.new(0, 26, 1, 0)
            Minus.BackgroundTransparency = 1
            Minus.Font = Enum.Font.GothamBold
            Minus.Text = "-"
            Minus.TextSize = 15
            Minus.AutoButtonColor = false
            Minus.Parent = Controls
            BindTheme(Minus, "TextColor3", "TextPrimary", "ControlBg")

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Size = UDim2.new(1, -52, 1, 0)
            ValLbl.Position = UDim2.new(0, 26, 0, 0)
            ValLbl.BackgroundTransparency = 1
            ValLbl.Font = Enum.Font.GothamBold
            ValLbl.Text = tostring(Self.Flags[flag])
            ValLbl.TextSize = 12
            ValLbl.Parent = Controls
            ApplyRichText(ValLbl, "Title25D", "ControlBg")

            local Plus = Instance.new("TextButton")
            Plus.Size = UDim2.new(0, 26, 1, 0)
            Plus.Position = UDim2.new(1, -26, 0, 0)
            Plus.BackgroundTransparency = 1
            Plus.Font = Enum.Font.GothamBold
            Plus.Text = "+"
            Plus.TextSize = 15
            Plus.AutoButtonColor = false
            Plus.Parent = Controls
            BindTheme(Plus, "TextColor3", "TextPrimary", "ControlBg")

            Controls.MouseEnter:Connect(function()
                FastTween(ctrlStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
            end)
            Controls.MouseLeave:Connect(function()
                FastTween(ctrlStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.28})
            end)

            Self:OnValueChanged(flag, function(v)
                ValLbl.Text = tostring(v)
            end)

            Minus.MouseButton1Click:Connect(function()
                local v = Self.Flags[flag] - step
                Self:SetValue(flag, v)
                if callback then task.spawn(callback, v) end
            end)
            Plus.MouseButton1Click:Connect(function()
                local v = Self.Flags[flag] + step
                Self:SetValue(flag, v)
                if callback then task.spawn(callback, v) end
            end)
        end

        -- =====================================================================
        -- INTERACTIVE EXPANDABLE DROPDOWN (SINGLE CLEAN BORDER & CHEVRON TWEEN)
        -- =====================================================================
        function Builder:Dropdown(label, flag, options, default, callback)
            options = (type(options) == "table" and #options > 0) and options or {"Default"}
            Self.Flags[flag] = default or options[1]

            local Wrapper = Instance.new("Frame")
            Wrapper.Size = UDim2.new(1, 0, 0, 30)
            Wrapper.AutomaticSize = Enum.AutomaticSize.Y
            Wrapper.BackgroundTransparency = 1
            Wrapper.Parent = scrollingPage

            local WrapLayout = Instance.new("UIListLayout")
            WrapLayout.Padding = UDim.new(0, 5)
            WrapLayout.SortOrder = Enum.SortOrder.LayoutOrder
            WrapLayout.Parent = Wrapper

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = 1
            Row.Parent = Wrapper

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.45, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            ApplyRichText(Title, "Label25D", "CardBg")

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.53, 0, 0, 26)
            DropBtn.Position = UDim2.new(0.47, 0, 0.5, -13)
            DropBtn.BorderSizePixel = 0
            DropBtn.Text = ""
            DropBtn.AutoButtonColor = false
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            local _, dropStroke = ApplySurfaceStyle(DropBtn, 6, CurrentTheme.Stroke, "Stroke", 0.28)

            local SelectedTxt = Instance.new("TextLabel")
            SelectedTxt.Position = UDim2.new(0, 10, 0, 0)
            SelectedTxt.Size = UDim2.new(1, -28, 1, 0)
            SelectedTxt.BackgroundTransparency = 1
            SelectedTxt.Font = Enum.Font.GothamBold
            SelectedTxt.Text = tostring(Self.Flags[flag])
            SelectedTxt.TextSize = 11
            SelectedTxt.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedTxt.TextXAlignment = Enum.TextXAlignment.Left
            SelectedTxt.Parent = DropBtn
            ApplyRichText(SelectedTxt, "Title25D", "ControlBg")

            local chev = DrawVectorIcon(DropBtn, "ChevronDown", 12, "TextMuted", BindTheme)
            chev.Position = UDim2.new(1, -14, 0.5, 0)
            chev.AnchorPoint = Vector2.new(0.5, 0.5)

            -- Expandable Menu Container (Hanya 1 Border Bersih, Aktif Saat Terbuka)
            local ListHolder = Instance.new("Frame")
            ListHolder.Size = UDim2.new(1, 0, 0, 0)
            ListHolder.BorderSizePixel = 0
            ListHolder.ClipsDescendants = true
            ListHolder.Visible = false
            ListHolder.LayoutOrder = 2
            ListHolder.Parent = Wrapper
            BindTheme(ListHolder, "BackgroundColor3", "PanelBg")
            local _, listStroke = ApplySurfaceStyle(ListHolder, 8, CurrentTheme.Stroke, "Stroke", 0.22)
            listStroke.Enabled = false

            local ListPad = Instance.new("UIPadding")
            ListPad.PaddingTop = UDim.new(0, 4)
            ListPad.PaddingBottom = UDim.new(0, 4)
            ListPad.PaddingLeft = UDim.new(0, 4)
            ListPad.PaddingRight = UDim.new(0, 4)
            ListPad.Parent = ListHolder

            local ListLayout = Instance.new("UIListLayout")
            ListLayout.Padding = UDim.new(0, 3)
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = ListHolder

            local isOpen = false
            local OptionRows = {}
            local targetHeight = (#options * 27) + 8

            local function RefreshOptionsVisual()
                for _, entry in ipairs(OptionRows) do
                    local isSel = (entry.Value == Self.Flags[flag])
                    entry.Dot.Visible = isSel
                    entry.SetHighlight(isSel)
                    entry.Btn.BackgroundTransparency = isSel and 0.15 or 1
                    entry.Btn.BackgroundColor3 = isSel and CurrentTheme.AccentSoft or CurrentTheme.ControlBg
                end
                SelectedTxt.Text = tostring(Self.Flags[flag])
            end

            local function SetOpen(state)
                isOpen = state
                FastTween(chev, 0.16, {Rotation = isOpen and 180 or 0})
                FastTween(dropStroke, 0.14, {
                    Color = isOpen and CurrentTheme.Accent or CurrentTheme.Stroke,
                    Transparency = isOpen and 0.05 or 0.28
                })
                if isOpen then
                    RefreshOptionsVisual()
                    ListHolder.Visible = true
                    listStroke.Enabled = true
                    FastTween(ListHolder, 0.16, {Size = UDim2.new(1, 0, 0, targetHeight)})
                else
                    local tw = FastTween(ListHolder, 0.14, {Size = UDim2.new(1, 0, 0, 0)})
                    if tw then
                        tw.Completed:Connect(function()
                            if not isOpen then
                                listStroke.Enabled = false
                                ListHolder.Visible = false
                            end
                        end)
                    else
                        listStroke.Enabled = false
                        ListHolder.Visible = false
                    end
                end
            end

            for i, opt in ipairs(options) do
                local OptBtn = Instance.new("TextButton")
                OptBtn.Size = UDim2.new(1, 0, 0, 24)
                OptBtn.BackgroundTransparency = 1
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = ""
                OptBtn.AutoButtonColor = false
                OptBtn.LayoutOrder = i
                OptBtn.Parent = ListHolder
                ApplyCornerOnly(OptBtn, 6)

                local OptDot = Instance.new("Frame")
                OptDot.Size = UDim2.fromOffset(5, 5)
                OptDot.Position = UDim2.new(0, 8, 0.5, -2)
                OptDot.BorderSizePixel = 0
                OptDot.Visible = false
                OptDot.Parent = OptBtn
                BindTheme(OptDot, "BackgroundColor3", "Accent")
                ApplyCornerOnly(OptDot, 3)

                local OptLbl = Instance.new("TextLabel")
                OptLbl.Position = UDim2.new(0, 20, 0, 0)
                OptLbl.Size = UDim2.new(1, -26, 1, 0)
                OptLbl.BackgroundTransparency = 1
                OptLbl.Font = Enum.Font.GothamBold
                OptLbl.Text = tostring(opt)
                OptLbl.TextSize = 11
                OptLbl.TextXAlignment = Enum.TextXAlignment.Left
                OptLbl.Parent = OptBtn
                local setOptHi = ApplyRichText(OptLbl, "Label25D", "PanelBg")

                OptBtn.MouseEnter:Connect(function()
                    if Self.Flags[flag] ~= opt then
                        OptBtn.BackgroundColor3 = CurrentTheme.ControlBg
                        FastTween(OptBtn, 0.10, {BackgroundTransparency = 0.35})
                    end
                end)
                OptBtn.MouseLeave:Connect(function()
                    if Self.Flags[flag] ~= opt then
                        FastTween(OptBtn, 0.12, {BackgroundTransparency = 1})
                    end
                end)
                OptBtn.MouseButton1Click:Connect(function()
                    Self:SetValue(flag, opt)
                    RefreshOptionsVisual()
                    SetOpen(false)
                    if callback then task.spawn(callback, opt) end
                end)

                table.insert(OptionRows, {
                    Value = opt,
                    Btn = OptBtn,
                    Dot = OptDot,
                    SetHighlight = setOptHi
                })
            end

            RegisterThemeUpdater(ListHolder, function() RefreshOptionsVisual() end)
            Self:OnValueChanged(flag, function() RefreshOptionsVisual() end)

            DropBtn.MouseEnter:Connect(function()
                if not isOpen then
                    FastTween(dropStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
                end
            end)
            DropBtn.MouseLeave:Connect(function()
                if not isOpen then
                    FastTween(dropStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                end
            end)
            DropBtn.MouseButton1Click:Connect(function()
                SetOpen(not isOpen)
            end)
        end

        function Builder:Input(label, flag, placeholder, default, callback)
            Self.Flags[flag] = default or ""

            local BoxHolder = Instance.new("Frame")
            BoxHolder.Size = UDim2.new(1, 0, 0, 32)
            BoxHolder.BackgroundTransparency = 1
            BoxHolder.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.42, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = BoxHolder
            ApplyRichText(Title, "Label25D", "CardBg")

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0.56, 0, 0, 28)
            InputBox.Position = UDim2.new(0.44, 0, 0.5, -14)
            InputBox.BorderSizePixel = 0
            InputBox.Font = Enum.Font.GothamBold
            InputBox.PlaceholderText = placeholder or "Enter value..."
            InputBox.Text = tostring(Self.Flags[flag])
            InputBox.TextSize = 12
            InputBox.TextXAlignment = Enum.TextXAlignment.Left
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = BoxHolder
            BindTheme(InputBox, "BackgroundColor3", "ControlBg")
            BindTheme(InputBox, "TextColor3", "TextPrimary", "ControlBg")
            BindTheme(InputBox, "PlaceholderColor3", "TextMuted", "ControlBg")
            local _, inStroke = ApplySurfaceStyle(InputBox, 6, CurrentTheme.Stroke, "Stroke", 0.28)

            local InPad = Instance.new("UIPadding")
            InPad.PaddingLeft = UDim.new(0, 10)
            InPad.PaddingRight = UDim.new(0, 10)
            InPad.Parent = InputBox

            InputBox.Focused:Connect(function()
                FastTween(inStroke, 0.14, {Color = CurrentTheme.Accent, Transparency = 0})
            end)
            InputBox.FocusLost:Connect(function()
                FastTween(inStroke, 0.16, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                Self:SetValue(flag, InputBox.Text)
                if callback then task.spawn(callback, InputBox.Text) end
            end)
            Self:OnValueChanged(flag, function(v)
                if InputBox.Text ~= tostring(v) then
                    InputBox.Text = tostring(v)
                end
            end)
        end

        -- =====================================================================
        -- KEYBIND ROW (Sesuai Referensi Opium & Keybind List)
        -- =====================================================================
        function Builder:Keybind(label, flag, defaultKey, callback)
            Self.Flags[flag] = defaultKey

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 30)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.58, 0, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            ApplyRichText(Title, "Label25D", "CardBg")

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.AutomaticSize = Enum.AutomaticSize.X
            KeyBtn.Size = UDim2.fromOffset(64, 24)
            KeyBtn.Position = UDim2.new(1, 0, 0.5, -12)
            KeyBtn.AnchorPoint = Vector2.new(1, 0)
            KeyBtn.BorderSizePixel = 0
            KeyBtn.Font = Enum.Font.GothamBold
            KeyBtn.TextSize = 11
            KeyBtn.AutoButtonColor = false
            KeyBtn.Parent = Row
            BindTheme(KeyBtn, "BackgroundColor3", "ControlBg")
            local _, kbStroke = ApplySurfaceStyle(KeyBtn, 6, CurrentTheme.Stroke, "Stroke", 0.28)

            local KbPad = Instance.new("UIPadding")
            KbPad.PaddingLeft = UDim.new(0, 10)
            KbPad.PaddingRight = UDim.new(0, 10)
            KbPad.Parent = KeyBtn

            local function FormatKey(k)
                if typeof(k) == "EnumItem" then return k.Name end
                if type(k) == "string" and k ~= "" then return k end
                return "None"
            end
            KeyBtn.Text = FormatKey(Self.Flags[flag])
            ApplyRichText(KeyBtn, "Title25D", "ControlBg")

            local listening = false
            KeyBtn.MouseEnter:Connect(function()
                if not listening then
                    FastTween(kbStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
                end
            end)
            KeyBtn.MouseLeave:Connect(function()
                if not listening then
                    FastTween(kbStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                end
            end)

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                isBindingKey = true
                KeyBtn.Text = "[ ... ]"
                FastTween(kbStroke, 0.12, {Color = CurrentTheme.Accent, Transparency = 0})

                local bindConn
                bindConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        bindConn:Disconnect()
                        listening = false
                        task.defer(function() isBindingKey = false end)
                        local chosen = (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace) and nil or input.KeyCode
                        KeyBtn.Text = FormatKey(chosen)
                        FastTween(kbStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                        Self:SetValue(flag, chosen)
                        if callback then task.spawn(callback, chosen) end
                    end
                end)
            end)
        end

        -- =====================================================================
        -- ACTION BUTTON ROW (TACTILE HOVER & PRESS MICRO-INTERACTION)
        -- =====================================================================
        function Builder:Button(label, actionBadge, iconName, callback)
            if type(actionBadge) == "function" then
                callback = actionBadge
                actionBadge = nil
            elseif type(iconName) == "function" then
                callback = iconName
                iconName = nil
            end

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 34)
            Btn.BorderSizePixel = 0
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.Parent = scrollingPage
            BindTheme(Btn, "BackgroundColor3", "ControlBg")
            local _, btnStroke = ApplySurfaceStyle(Btn, 8, CurrentTheme.Stroke, "Stroke", 0.25)

            local BtnScale = Instance.new("UIScale")
            BtnScale.Parent = Btn

            local leftOff = 12
            if iconName then
                local ic = DrawVectorIcon(Btn, iconName, 16, "Accent", BindTheme)
                ic.Position = UDim2.new(0, 12, 0.5, -8)
                leftOff = 34
            end

            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, leftOff, 0, 0)
            Lbl.Size = UDim2.new(0.72, -leftOff, 1, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBold
            Lbl.Text = label
            Lbl.TextSize = 13
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Btn
            ApplyRichText(Lbl, "Title25D", "ControlBg")

            if actionBadge and actionBadge ~= "" then
                local Badge = Instance.new("TextLabel")
                Badge.Size = UDim2.new(0.28, -12, 1, 0)
                Badge.Position = UDim2.new(0.72, 0, 0, 0)
                Badge.BackgroundTransparency = 1
                Badge.Font = Enum.Font.GothamBold
                Badge.Text = actionBadge
                Badge.TextSize = 11
                Badge.TextXAlignment = Enum.TextXAlignment.Right
                Badge.Parent = Btn
                BindTheme(Badge, "TextColor3", "TextMuted", "ControlBg")
            end

            Btn.MouseEnter:Connect(function()
                FastTween(Btn, 0.12, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                FastTween(btnStroke, 0.12, {Color = CurrentTheme.Accent, Transparency = 0.05})
            end)
            Btn.MouseLeave:Connect(function()
                FastTween(Btn, 0.14, {BackgroundColor3 = CurrentTheme.ControlBg})
                FastTween(btnStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.25})
                FastTween(BtnScale, 0.12, {Scale = 1})
            end)
            Btn.MouseButton1Down:Connect(function()
                FastTween(BtnScale, 0.08, {Scale = 0.975})
            end)
            Btn.MouseButton1Up:Connect(function()
                FastTween(BtnScale, 0.12, {Scale = 1})
            end)
            Btn.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
        end

        -- =====================================================================
        -- INTERACTIVE TILE SELECTOR GRID (Sesuai Referensi "Select tile to break")
        -- =====================================================================
        function Builder:TileGrid(label, flag, rows, cols, callback)
            rows = math.clamp(tonumber(rows) or 5, 2, 7)
            cols = math.clamp(tonumber(cols) or 5, 2, 7)
            local centerIdx = math.ceil((rows * cols) / 2)
            local activeTiles = {}
            Self.Flags[flag] = activeTiles

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 30)
            Holder.AutomaticSize = Enum.AutomaticSize.Y
            Holder.BackgroundTransparency = 1
            Holder.Parent = scrollingPage

            local HLayout = Instance.new("UIListLayout")
            HLayout.Padding = UDim.new(0, 8)
            HLayout.SortOrder = Enum.SortOrder.LayoutOrder
            HLayout.Parent = Holder

            if label and label ~= "" then
                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, 0, 0, 18)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = label
                Lbl.TextSize = 12
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Holder
                ApplyRichText(Lbl, "Label25D", "CardBg")
            end

            local cellPx = 30
            local gapPx = 5
            local totalW = cols * cellPx + (cols - 1) * gapPx
            local totalH = rows * cellPx + (rows - 1) * gapPx

            local GridBox = Instance.new("Frame")
            GridBox.Size = UDim2.fromOffset(totalW, totalH)
            GridBox.BackgroundTransparency = 1
            GridBox.Parent = Holder

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.fromOffset(cellPx, cellPx)
            Grid.CellPadding = UDim2.fromOffset(gapPx, gapPx)
            Grid.SortOrder = Enum.SortOrder.LayoutOrder
            Grid.Parent = GridBox

            for idx = 1, (rows * cols) do
                local isCenter = (idx == centerIdx)
                activeTiles[idx] = false

                local Cell = Instance.new("TextButton")
                Cell.LayoutOrder = idx
                Cell.BorderSizePixel = 0
                Cell.Text = isCenter and "P" or ""
                Cell.Font = Enum.Font.GothamBold
                Cell.TextSize = 10
                Cell.AutoButtonColor = false
                Cell.Parent = GridBox
                local _, cellStroke = ApplySurfaceStyle(Cell, 6, CurrentTheme.Stroke, false, 0.28)

                local function SyncCell(animated)
                    local sel = activeTiles[idx]
                    local bg = isCenter and CurrentTheme.AccentSoft or (sel and CurrentTheme.Accent or CurrentTheme.ControlBg)
                    local st = (isCenter or sel) and CurrentTheme.Accent or CurrentTheme.Stroke
                    Cell.TextColor3 = CurrentTheme.TextPrimary
                    if animated then
                        FastTween(Cell, 0.12, {BackgroundColor3 = bg})
                        FastTween(cellStroke, 0.12, {Color = st, Transparency = (sel or isCenter) and 0.05 or 0.28})
                    else
                        Cell.BackgroundColor3 = bg
                        cellStroke.Color = st
                        cellStroke.Transparency = (sel or isCenter) and 0.05 or 0.28
                    end
                end

                RegisterThemeUpdater(Cell, function() SyncCell(false) end)

                if not isCenter then
                    Cell.MouseEnter:Connect(function()
                        if not activeTiles[idx] then
                            FastTween(cellStroke, 0.10, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
                        end
                    end)
                    Cell.MouseLeave:Connect(function()
                        SyncCell(true)
                    end)
                    Cell.MouseButton1Click:Connect(function()
                        activeTiles[idx] = not activeTiles[idx]
                        SyncCell(true)
                        Self:SetValue(flag, activeTiles)
                        if callback then task.spawn(callback, idx, activeTiles[idx], activeTiles) end
                    end)
                end
            end
        end

        function Builder:ActivityTimeline(entries)
            for _, item in ipairs(entries) do
                local Row = Instance.new("Frame")
                Row.Size = UDim2.new(1, 0, 0, 24)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Parent = scrollingPage
                ApplyCornerOnly(Row, 6)

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(7, 7)
                Dot.Position = UDim2.new(0, 6, 0.5, -3)
                Dot.BorderSizePixel = 0
                Dot.Parent = Row
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplyCornerOnly(Dot, 4)

                local EventTxt = Instance.new("TextLabel")
                EventTxt.Position = UDim2.new(0, 22, 0, 0)
                EventTxt.Size = UDim2.new(0.70, -22, 1, 0)
                EventTxt.BackgroundTransparency = 1
                EventTxt.Font = Enum.Font.GothamBold
                EventTxt.Text = item.Text
                EventTxt.TextSize = 12
                EventTxt.TextXAlignment = Enum.TextXAlignment.Left
                EventTxt.Parent = Row
                ApplyRichText(EventTxt, "Label25D", "CardBg")

                local TimeTxt = Instance.new("TextLabel")
                TimeTxt.Position = UDim2.new(0.70, 0, 0, 0)
                TimeTxt.Size = UDim2.new(0.30, -6, 1, 0)
                TimeTxt.BackgroundTransparency = 1
                TimeTxt.Font = Enum.Font.GothamMedium
                TimeTxt.Text = item.Time
                TimeTxt.TextSize = 11
                TimeTxt.TextXAlignment = Enum.TextXAlignment.Right
                TimeTxt.Parent = Row
                BindTheme(TimeTxt, "TextColor3", "TextMuted", "CardBg")

                Row.MouseEnter:Connect(function()
                    Row.BackgroundColor3 = CurrentTheme.ControlBg
                    FastTween(Row, 0.12, {BackgroundTransparency = 0.55})
                end)
                Row.MouseLeave:Connect(function()
                    FastTween(Row, 0.14, {BackgroundTransparency = 1})
                end)
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
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Visible = false
        Page.Parent = parent
        BindTheme(Page, "ScrollBarImageColor3", "Accent")

        local Pad = Instance.new("UIPadding")
        Pad.PaddingTop = UDim.new(0, 15)
        Pad.PaddingBottom = UDim.new(0, 15)
        Pad.PaddingLeft = UDim.new(0, 15)
        Pad.PaddingRight = UDim.new(0, 15)
        Pad.Parent = Page

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 11)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Page
        return Page
    end

    function Self:Category(catLabel)
        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, -12, 0, 20)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamBold
        Lbl.Text = "  " .. string.upper(tostring(catLabel or ""))
        Lbl.TextSize = 10
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = NavScroll
        BindTheme(Lbl, "TextColor3", "TextMuted", "PanelBg")
    end

    local function SyncRightPanelVisibility()
        for _, f in ipairs(Self.Features) do
            f.RightPage.Visible = false
        end
        local active = Self.ActiveFeature
        if not active then return end
        if active.HasCustomRight then
            active.RightPage.Visible = true
        elseif Self.Features[1] and Self.Features[1].HasCustomRight then
            Self.Features[1].RightPage.Visible = true
        end
    end

    function Self.feature(logo, name)
        local CenterPage = CreateScrollPage(CenterPanel)
        local RightPage = CreateScrollPage(RightPanel)

        local NavBtn = Instance.new("TextButton")
        NavBtn.Size = UDim2.new(1, 0, 0, 38)
        NavBtn.BackgroundTransparency = 1
        NavBtn.BorderSizePixel = 0
        NavBtn.Text = ""
        NavBtn.AutoButtonColor = false
        NavBtn.Parent = NavScroll
        local _, navStroke = ApplySurfaceStyle(NavBtn, 9, CurrentTheme.Stroke, false, 1)

        local recolorTabVec = nil
        local isAssetLogo = (type(logo) == "string" and (string.find(logo, "^https?://") or string.find(logo, "^rbxassetid://")))
        if isAssetLogo then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Position = UDim2.new(0, 13, 0.5, -9)
            IconImg.Size = UDim2.fromOffset(18, 18)
            IconImg.BackgroundTransparency = 1
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.Image = ResolveImage(logo)
            IconImg.Parent = NavBtn
        else
            local vecTabIcon, recolor = DrawVectorIcon(NavBtn, logo or name, 17, "TextMuted", BindTheme)
            vecTabIcon.Position = UDim2.new(0, 13, 0.5, -8)
            recolorTabVec = recolor
        end

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Position = UDim2.new(0, 40, 0, 0)
        NameLbl.Size = UDim2.new(1, -48, 1, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = name
        NameLbl.TextSize = 13
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.Parent = NavBtn
        local setTabHighlight = ApplyRichText(NameLbl, "Label25D", "PanelBg")

        -- Vertical Pill Indicator di Sisi Kiri (Minimalist & Tanpa Tabrakan Border)
        local ActivePill = Instance.new("Frame")
        ActivePill.Size = UDim2.fromOffset(3, 0)
        ActivePill.Position = UDim2.new(0, 3, 0.5, 0)
        ActivePill.AnchorPoint = Vector2.new(0, 0.5)
        ActivePill.BorderSizePixel = 0
        ActivePill.Visible = false
        ActivePill.Parent = NavBtn
        BindTheme(ActivePill, "BackgroundColor3", "Accent")
        ApplyCornerOnly(ActivePill, 2)

        local FeatureObj = {
            Name = name,
            CenterPage = CenterPage,
            RightPage = RightPage,
            NavBtn = NavBtn,
            ActivePill = ActivePill,
            NameLbl = NameLbl,
            HasCustomRight = false,
            Hovered = false
        }

        local function RefreshTabVisual(animated)
            local isActive = (Self.ActiveFeature == FeatureObj)
            local hovered = FeatureObj.Hovered
            setTabHighlight(isActive)

            if recolorTabVec then
                recolorTabVec((isActive or hovered) and CurrentTheme.Accent or CurrentTheme.TextMuted)
            end

            local targetBg = isActive and CurrentTheme.AccentSoft or CurrentTheme.ControlBg
            local targetBgTr = isActive and 0.15 or (hovered and 0.55 or 1)
            local targetStCol = isActive and CurrentTheme.Accent or CurrentTheme.Stroke
            local targetStTr = isActive and 0.35 or (hovered and 0.65 or 1)
            local targetX = (isActive or hovered) and 43 or 40

            ActivePill.Visible = isActive or (ActivePill.Size.Y.Offset > 0)
            if animated then
                FastTween(NavBtn, 0.14, {BackgroundColor3 = targetBg, BackgroundTransparency = targetBgTr})
                FastTween(navStroke, 0.14, {Color = targetStCol, Transparency = targetStTr})
                FastTween(NameLbl, 0.14, {Position = UDim2.new(0, targetX, 0, 0)})
                local tw = FastTween(ActivePill, 0.16, {Size = UDim2.fromOffset(3, isActive and 18 or 0)})
                if tw and not isActive then
                    tw.Completed:Connect(function()
                        if Self.ActiveFeature ~= FeatureObj then ActivePill.Visible = false end
                    end)
                elseif not isActive then
                    ActivePill.Visible = false
                end
            else
                NavBtn.BackgroundColor3 = targetBg
                NavBtn.BackgroundTransparency = targetBgTr
                navStroke.Color = targetStCol
                navStroke.Transparency = targetStTr
                NameLbl.Position = UDim2.new(0, targetX, 0, 0)
                ActivePill.Size = UDim2.fromOffset(3, isActive and 18 or 0)
                ActivePill.Visible = isActive
            end
        end

        FeatureObj.RefreshVisual = RefreshTabVisual
        RegisterThemeUpdater(NavBtn, function() RefreshTabVisual(false) end)
        table.insert(Self.Features, FeatureObj)

        local function ActivateFeature()
            Self.ActiveFeature = FeatureObj
            for _, f in ipairs(Self.Features) do
                f.CenterPage.Visible = (f == FeatureObj)
                f.RefreshVisual(true)
            end
            SyncRightPanelVisibility()
        end

        NavBtn.MouseEnter:Connect(function()
            FeatureObj.Hovered = true
            RefreshTabVisual(true)
        end)
        NavBtn.MouseLeave:Connect(function()
            FeatureObj.Hovered = false
            RefreshTabVisual(true)
        end)
        NavBtn.MouseButton1Click:Connect(ActivateFeature)

        if #Self.Features == 1 then
            Self.ActiveFeature = FeatureObj
            CenterPage.Visible = true
            RefreshTabVisual(false)
        end

        return function(definition)
            if type(definition) == "table" then
                if type(definition.center) == "function" then
                    definition.center(CreateCanvasBuilder(CenterPage))
                end
                if type(definition.right) == "function" then
                    FeatureObj.HasCustomRight = true
                    definition.right(CreateCanvasBuilder(RightPage))
                end
                SyncRightPanelVisibility()
            end
            return FeatureObj
        end
    end

    -- Metatable agar penulisan lama `UI.UIScale = val / 100` langsung meng-update ukuran UI secara live!
    return setmetatable(Self, {
        __index = function(_, key)
            if key == "UIScale" then
                return uiScaleValue
            end
            return nil
        end,
        __newindex = function(tbl, key, value)
            if key == "UIScale" then
                Self:SetScale(value)
            else
                rawset(tbl, key, value)
            end
        end
    })
end

return ImGui
