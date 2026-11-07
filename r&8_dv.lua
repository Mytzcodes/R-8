--[[
    FRAMEWORK : R&8_DV ImGui Architecture (v5.4 - Large Effortless Typography, High-Contrast Solid UI & Spacious Cards)
    COPYRIGHT : R&8_DV
    ASSET     : Hardcoded GitHub Auto-Fetch + Clean Minimal UI Icons (Zero 2.5D/3D Text Bug / Locked 60 FPS)
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local HasMousePointer = UserInputService.MouseEnabled

-- // HARDCODED MASTER LOGO DARI GITHUB (JANGAN DIUBAH) //
local MASTER_LOGO_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Assets/icons.png"
local MASTER_CACHE_FILE = "R8DV_MasterLogo_v5.png"

local function GetSafeGuiParent()
    local ok, res = pcall(function()
        return (gethui and gethui()) or CoreGui
    end)
    if ok and res then return res end
    local lp = LocalPlayer or Players.LocalPlayer
    if lp then
        return lp:WaitForChild("PlayerGui")
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
                    if raw and #raw > 128 and not string.find(string.sub(raw, 1, 32), "404", 1, true) then
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

-- // LETTER SPACING FORMATTER (MURNI ASCII - BEBAS KOTAK [] DI MOBILE & PC) //
local function FormatSpacedText(str, spacingCount)
    str = tostring(str or "")
    spacingCount = tonumber(spacingCount) or 0
    if spacingCount <= 0 or #str <= 1 then
        return str
    end
    local pad = string.rep(" ", spacingCount)
    local out = {}
    for i = 1, #str do
        local ch = string.sub(str, i, i)
        if ch == " " then
            out[#out + 1] = "  "
        else
            out[#out + 1] = ch
            if i < #str and string.sub(str, i + 1, i + 1) ~= " " then
                out[#out + 1] = pad
            end
        end
    end
    return table.concat(out)
end

-- // PERCEPTUAL LUMINANCE & AUTOMATIC HIGH-CONTRAST GUARD //
local function GetLuminance(c)
    if not c then return 0 end
    return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function GetOnFillColor(fillColor)
    -- Jika background tombol/badge terang (putih, emas, lime, cyan terang), WAJIB pakai teks/ikon GELAP PEKAT!
    -- Jika background tombol/badge gelap/pekat (biru safir tua, ungu tua), WAJIB pakai teks/ikon PUTIH BERSIH!
    if GetLuminance(fillColor) > 0.52 then
        return Color3.fromRGB(12, 14, 20)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function GetReadableTextColor(bgColor, preferredTextColor)
    if not bgColor or not preferredTextColor then
        return preferredTextColor or Color3.fromRGB(248, 250, 255)
    end
    local bgLum = GetLuminance(bgColor)
    local fgLum = GetLuminance(preferredTextColor)
    if math.abs(bgLum - fgLum) < 0.42 then
        return bgLum > 0.50 and Color3.fromRGB(12, 14, 20) or Color3.fromRGB(248, 250, 255)
    end
    return preferredTextColor
end

-- =========================================================================
-- 5 TEMA WARNA SOLID KONTRAS TINGGI (TANPA BUG UIGRADIENT TEKS 2.5D / 3D!)
-- Semua teks dijamin terbaca 100% tajam di atas background gelap maupun terang
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
        MainBg      = Color3.fromRGB(10, 11, 15),
        PanelBg     = Color3.fromRGB(15, 17, 23),
        CardBg      = Color3.fromRGB(21, 24, 32),
        CardHoverBg = Color3.fromRGB(27, 31, 41),
        RowBg       = Color3.fromRGB(28, 32, 42),
        ControlBg   = Color3.fromRGB(36, 41, 54),
        Accent      = Color3.fromRGB(242, 246, 252), -- Platinum terang -> Teks di atasnya wajib gelap pekat!
        AccentSoft  = Color3.fromRGB(44, 50, 66),
        Stroke      = Color3.fromRGB(54, 62, 80),
        HoverStroke = Color3.fromRGB(176, 190, 216),
        TextPrimary = Color3.fromRGB(250, 252, 255),
        TextMuted   = Color3.fromRGB(204, 214, 232),
        TextAccent  = Color3.fromRGB(255, 255, 255),
        OnAccent    = Color3.fromRGB(12, 14, 20),
        KnobOn      = Color3.fromRGB(12, 14, 20)
    },
    ["Blue Night Sky"] = {
        MainBg      = Color3.fromRGB(8, 12, 20),
        PanelBg     = Color3.fromRGB(13, 19, 32),
        CardBg      = Color3.fromRGB(18, 26, 44),
        CardHoverBg = Color3.fromRGB(24, 35, 58),
        RowBg       = Color3.fromRGB(23, 33, 55),
        ControlBg   = Color3.fromRGB(31, 45, 74),
        Accent      = Color3.fromRGB(36, 128, 255), -- Biru Safir Elektrik pekat -> Teks putih sangat kontras!
        AccentSoft  = Color3.fromRGB(26, 54, 102),
        Stroke      = Color3.fromRGB(46, 70, 116),
        HoverStroke = Color3.fromRGB(96, 180, 255),
        TextPrimary = Color3.fromRGB(248, 252, 255),
        TextMuted   = Color3.fromRGB(196, 214, 242),
        TextAccent  = Color3.fromRGB(118, 204, 255),
        OnAccent    = Color3.fromRGB(255, 255, 255),
        KnobOn      = Color3.fromRGB(255, 255, 255)
    },
    ["Violet Amethyst"] = {
        MainBg      = Color3.fromRGB(11, 9, 19),
        PanelBg     = Color3.fromRGB(17, 14, 29),
        CardBg      = Color3.fromRGB(24, 20, 40),
        CardHoverBg = Color3.fromRGB(32, 27, 54),
        RowBg       = Color3.fromRGB(31, 25, 52),
        ControlBg   = Color3.fromRGB(41, 34, 68),
        Accent      = Color3.fromRGB(126, 74, 252), -- Ungu Amethyst pekat -> Teks putih sangat tajam!
        AccentSoft  = Color3.fromRGB(52, 34, 96),
        Stroke      = Color3.fromRGB(66, 52, 106),
        HoverStroke = Color3.fromRGB(186, 148, 255),
        TextPrimary = Color3.fromRGB(252, 250, 255),
        TextMuted   = Color3.fromRGB(208, 198, 238),
        TextAccent  = Color3.fromRGB(204, 168, 255),
        OnAccent    = Color3.fromRGB(255, 255, 255),
        KnobOn      = Color3.fromRGB(255, 255, 255)
    },
    ["Orange Sand"] = {
        MainBg      = Color3.fromRGB(14, 11, 9),
        PanelBg     = Color3.fromRGB(21, 17, 14),
        CardBg      = Color3.fromRGB(29, 23, 19),
        CardHoverBg = Color3.fromRGB(38, 31, 25),
        RowBg       = Color3.fromRGB(36, 29, 24),
        ControlBg   = Color3.fromRGB(49, 40, 33),
        Accent      = Color3.fromRGB(246, 156, 52), -- Amber Sand cerah -> Teks & centang hitam espresso pekat!
        AccentSoft  = Color3.fromRGB(78, 52, 28),
        Stroke      = Color3.fromRGB(82, 64, 48),
        HoverStroke = Color3.fromRGB(250, 182, 98),
        TextPrimary = Color3.fromRGB(255, 251, 246),
        TextMuted   = Color3.fromRGB(224, 208, 190),
        TextAccent  = Color3.fromRGB(255, 192, 104),
        OnAccent    = Color3.fromRGB(16, 12, 8),
        KnobOn      = Color3.fromRGB(16, 12, 8)
    },
    ["Midnight Monokai"] = {
        MainBg      = Color3.fromRGB(10, 13, 11),
        PanelBg     = Color3.fromRGB(15, 20, 17),
        CardBg      = Color3.fromRGB(21, 28, 24),
        CardHoverBg = Color3.fromRGB(28, 37, 32),
        RowBg       = Color3.fromRGB(27, 36, 31),
        ControlBg   = Color3.fromRGB(36, 48, 41),
        Accent      = Color3.fromRGB(162, 236, 54), -- Neon Lime cerah -> Teks & centang hitam pekat!
        AccentSoft  = Color3.fromRGB(40, 68, 36),
        Stroke      = Color3.fromRGB(52, 74, 58),
        HoverStroke = Color3.fromRGB(172, 244, 88),
        TextPrimary = Color3.fromRGB(248, 254, 250),
        TextMuted   = Color3.fromRGB(202, 220, 208),
        TextAccent  = Color3.fromRGB(184, 248, 96),
        OnAccent    = Color3.fromRGB(10, 15, 11),
        KnobOn      = Color3.fromRGB(10, 15, 11)
    }
}

-- =========================================================================
-- MINIMAL CLEAN GEOMETRIC UI ICONS (TANPA DESAIN ABSTRAK / GARIS PECAH)
-- =========================================================================
local function DrawVectorIcon(parent, iconName, sizePx, themeKey, bindThemeFn)
    local Holder = Instance.new("Frame")
    Holder.Name = "UIIcon_" .. tostring(iconName)
    Holder.Size = UDim2.fromOffset(sizePx, sizePx)
    Holder.BackgroundTransparency = 1
    Holder.Parent = parent

    local Parts = {}

    local function Bar(w, h, posX, posY, rot, radius, targetParent, anchorX, anchorY)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromScale(posX, posY)
        f.AnchorPoint = Vector2.new(anchorX or 0.5, anchorY or 0.5)
        f.Rotation = rot or 0
        f.BorderSizePixel = 0
        f.Parent = targetParent or Holder
        if bindThemeFn and themeKey then
            bindThemeFn(f, "BackgroundColor3", themeKey)
        end
        table.insert(Parts, {Inst = f, Prop = "BackgroundColor3"})
        if radius and radius > 0 then
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, radius)
            c.Parent = f
        end
        return f
    end

    local function Outline(w, h, posX, posY, radius, thickness, rot)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(w, h)
        f.Position = UDim2.fromScale(posX, posY)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundTransparency = 1
        f.Rotation = rot or 0
        f.Parent = Holder
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius or 3)
        c.Parent = f
        local s = Instance.new("UIStroke")
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Thickness = thickness or 1.8
        s.Parent = f
        if bindThemeFn and themeKey then
            bindThemeFn(s, "Color", themeKey)
        end
        table.insert(Parts, {Inst = s, Prop = "Color"})
        return f
    end

    local key = string.lower(tostring(iconName or "dot"))

    if key == "check" then
        -- True Connected L-Checkmark: kedua garis menyatu sempurna di sudut kiri-bawah pada skala berapapun!
        local cw = math.max(math.floor(sizePx * 0.64 + 0.5), 8)
        local ch = math.max(math.floor(sizePx * 0.38 + 0.5), 5)
        local th = math.max(sizePx * 0.17, 2.2)
        local LBox = Instance.new("Frame")
        LBox.Size = UDim2.fromOffset(cw, ch)
        LBox.Position = UDim2.fromScale(0.5, 0.46)
        LBox.AnchorPoint = Vector2.new(0.5, 0.5)
        LBox.BackgroundTransparency = 1
        LBox.Rotation = -45
        LBox.Parent = Holder
        Bar(th, ch, 0, 1, 0, 1, LBox, 0, 1)
        Bar(cw, th, 0, 1, 0, 1, LBox, 0, 1)
    elseif key == "menu" then
        Bar(15, 2, 0.5, 0.28, 0, 1)
        Bar(15, 2, 0.5, 0.50, 0, 1)
        Bar(15, 2, 0.5, 0.72, 0, 1)
    elseif key == "minimize" then
        Bar(13, 2.2, 0.5, 0.5, 0, 1)
    elseif key == "maximize" then
        Outline(12, 12, 0.5, 0.5, 2, 1.8)
    elseif key == "close" then
        Bar(14, 2.2, 0.5, 0.5, 45, 1)
        Bar(14, 2.2, 0.5, 0.5, -45, 1)
    elseif key == "chevrondown" then
        local VBox = Instance.new("Frame")
        VBox.Size = UDim2.fromOffset(7, 7)
        VBox.Position = UDim2.fromScale(0.5, 0.44)
        VBox.AnchorPoint = Vector2.new(0.5, 0.5)
        VBox.BackgroundTransparency = 1
        VBox.Rotation = -45
        VBox.Parent = Holder
        Bar(2, 7, 0, 1, 0, 1, VBox, 0, 1)
        Bar(7, 2, 0, 1, 0, 1, VBox, 0, 1)
    elseif key == "arrowright" then
        Bar(9, 2, 0.44, 0.5, 0, 1)
        local ABox = Instance.new("Frame")
        ABox.Size = UDim2.fromOffset(6, 6)
        ABox.Position = UDim2.fromScale(0.60, 0.5)
        ABox.AnchorPoint = Vector2.new(0.5, 0.5)
        ABox.BackgroundTransparency = 1
        ABox.Rotation = -45
        ABox.Parent = Holder
        Bar(6, 2, 1, 1, 0, 1, ABox, 1, 1)
        Bar(2, 6, 1, 1, 0, 1, ABox, 1, 1)
    elseif key == "home" then
        -- Clean Dashboard 2x2 Bento Squares
        local s = math.floor(sizePx * 0.30)
        Outline(s, s, 0.31, 0.31, 2, 1.7)
        Outline(s, s, 0.69, 0.31, 2, 1.7)
        Outline(s, s, 0.31, 0.69, 2, 1.7)
        Outline(s, s, 0.69, 0.69, 2, 1.7)
    elseif key == "combat" or key == "aimbot" or key == "target" or key == "crosshair" then
        Outline(sizePx * 0.72, sizePx * 0.72, 0.5, 0.5, sizePx, 1.8)
        Bar(sizePx * 0.22, sizePx * 0.22, 0.5, 0.5, 0, sizePx)
    elseif key == "autofarm" or key == "bot" or key == "robot" or key == "collect" or key == "grid" or key == "layers" then
        Outline(sizePx * 0.56, sizePx * 0.56, 0.5, 0.5, 3, 1.8, 45)
        Bar(sizePx * 0.18, sizePx * 0.18, 0.5, 0.5, 45, 1)
    elseif key == "visuals" or key == "esp" or key == "eye" then
        Outline(sizePx * 0.80, sizePx * 0.46, 0.5, 0.5, sizePx, 1.8)
        Bar(sizePx * 0.22, sizePx * 0.22, 0.5, 0.5, 0, sizePx)
    elseif key == "player" or key == "user" then
        Outline(sizePx * 0.36, sizePx * 0.36, 0.5, 0.31, sizePx, 1.8)
        Outline(sizePx * 0.66, sizePx * 0.32, 0.5, 0.75, 5, 1.8)
    elseif key == "sliders" or key == "misc" or key == "settings" or key == "gear" then
        Bar(sizePx * 0.76, 2, 0.5, 0.28, 0, 1)
        Bar(4, 6, 0.35, 0.28, 0, 2)
        Bar(sizePx * 0.76, 2, 0.5, 0.52, 0, 1)
        Bar(4, 6, 0.66, 0.52, 0, 2)
        Bar(sizePx * 0.76, 2, 0.5, 0.76, 0, 1)
        Bar(4, 6, 0.44, 0.76, 0, 2)
    elseif key == "palette" or key == "theme" or key == "sparkles" then
        Outline(sizePx * 0.72, sizePx * 0.72, 0.5, 0.5, sizePx, 1.8)
        Bar(sizePx * 0.28, sizePx * 0.28, 0.5, 0.5, 0, sizePx)
    elseif key == "clock" then
        Outline(sizePx * 0.74, sizePx * 0.74, 0.5, 0.5, sizePx, 1.8)
        Bar(2, sizePx * 0.24, 0.5, 0.39, 0, 1)
        Bar(sizePx * 0.22, 2, 0.59, 0.52, 0, 1)
    elseif key == "shield" then
        Outline(sizePx * 0.64, sizePx * 0.72, 0.5, 0.5, 5, 1.8)
        Bar(sizePx * 0.20, sizePx * 0.20, 0.5, 0.5, 0, sizePx)
    elseif key == "bolt" or key == "speed" or key == "jump" or key == "teleports" or key == "teleport" then
        Outline(sizePx * 0.68, sizePx * 0.68, 0.5, 0.5, 5, 1.8)
        Bar(sizePx * 0.26, 2.2, 0.5, 0.5, 0, 1)
        Bar(2.2, sizePx * 0.26, 0.5, 0.5, 0, 1)
    elseif key == "chat" or key == "spammer" or key == "message" then
        Outline(sizePx * 0.72, sizePx * 0.54, 0.5, 0.5, 5, 1.8)
        Bar(sizePx * 0.36, 2, 0.5, 0.44, 0, 1)
        Bar(sizePx * 0.24, 2, 0.44, 0.58, 0, 1)
    else
        Outline(sizePx * 0.56, sizePx * 0.56, 0.5, 0.5, 4, 1.8)
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

    local BASE_WIN_W = 1040
    local BASE_WIN_H = 520
    local MAX_WIN_W  = 1120
    local MAX_WIN_H  = 560

    local uiScaleValue = math.clamp(tonumber(config.Scale) or 1, 0.5, 1.5)
    local isMaximized = false

    local Self = {
        Title = config.Title or "DRY CURSED  -  IMGUI",
        BrandTitle = config.BrandTitle or "R&8_DV",
        BrandSubtitle = config.BrandSubtitle or "IMGUI SUITE",
        Copyright = "R&8_DV",
        ThemeName = Themes[config.Theme or ""] and config.Theme or "Minimalist Monochrome",
        Rounded = (config.Rounded ~= false),
        CheckboxStyle = config.CheckboxStyle or "Modern", -- "Modern" | "Checkbox"
        Text3D = false, -- Dihapus permanen agar teks 100% solid tajam & bebas bug di semua GPU
        LetterSpacing = tonumber(config.LetterSpacing) or 1,
        ReduceEffects = (config.ReduceEffects == true),
        SideCount = (config.Sides == 2) and 2 or 3,
        BgTransparency = math.clamp(tonumber(config.Transparency or config.BgTransparency) or 0.04, 0, 0.65),
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.85,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode ~= false),
        AutoLoading = (config.AutoLoading == true), -- Default false: langsung buka 0ms tanpa delay
        IsMinimized = false,
        Flags = {},
        FlagListeners = {},
        Features = {},
        ActiveFeature = nil,
        ThemeBindings = {},
        ThemeUpdaters = {},
        SpacingBindings = {},
        RadiusBindings = {},
        Connections = {}
    }

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Minimalist Monochrome"]
    local ResolvedMasterLogo = ResolveImage(MASTER_LOGO_URL)

    local function TrackConn(conn)
        if conn then
            table.insert(Self.Connections, conn)
        end
        return conn
    end

    -- Helper Animasi Smooth & Natural (Quad Out Halus - Tanpa Motion Aneh / Bouncing)
    local SMOOTH_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local SMOOTH_MED  = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local function SmoothTween(instance, duration, props)
        if not instance or not instance.Parent then return nil end
        if Self.ReduceEffects or Self.Flags["ReduceEffects"] or Self.Flags["FPSBoost"] then
            for k, v in pairs(props) do
                instance[k] = v
            end
            return nil
        end
        local info = (duration and duration > 0.15) and SMOOTH_MED or SMOOTH_FAST
        local tw = TweenService:Create(instance, info, props)
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
        stroke.Transparency = strokeTrans or 0.24
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

    local function BindSpacedText(label, rawText, minSpacing, forceUpper, maxSpacing)
        local base = forceUpper and string.upper(tostring(rawText or "")) or tostring(rawText or "")
        local function ApplySpacing()
            local amt = math.max(Self.LetterSpacing, minSpacing or 0)
            if maxSpacing then amt = math.min(amt, maxSpacing) end
            label.Text = FormatSpacedText(base, amt)
        end
        table.insert(Self.SpacingBindings, {Instance = label, Apply = ApplySpacing})
        ApplySpacing()
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

    -- Bersihkan instance lama jika script dijalankan ulang
    local globalEnv = (getgenv and getgenv()) or _G
    if type(globalEnv) == "table" and globalEnv.__R8_DV_ACTIVE_UI then
        pcall(function()
            globalEnv.__R8_DV_ACTIVE_UI:Destroy()
        end)
    end

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
    FocusBlocker.BackgroundTransparency = 0.55
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
    MinimizeIconBtn.Position = UDim2.new(0, 52, 0.5, 0)
    MinimizeIconBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIconBtn.BorderSizePixel = 0
    MinimizeIconBtn.AutoButtonColor = false
    MinimizeIconBtn.Image = ""
    MinimizeIconBtn.Visible = false
    MinimizeIconBtn.ZIndex = 800
    MinimizeIconBtn.Parent = ScreenGui
    BindTheme(MinimizeIconBtn, "BackgroundColor3", "CardBg")

    local _, MinSingleStroke = ApplySurfaceStyle(MinimizeIconBtn, 14, CurrentTheme.Stroke, false, 0.12)
    MinSingleStroke.Thickness = 1.2

    RegisterThemeUpdater(MinimizeIconBtn, function(theme)
        MinSingleStroke.Color = theme.Stroke
    end)

    local MinEmblemImg = Instance.new("ImageLabel")
    MinEmblemImg.Size = UDim2.fromScale(0.74, 0.74)
    MinEmblemImg.Position = UDim2.fromScale(0.5, 0.5)
    MinEmblemImg.AnchorPoint = Vector2.new(0.5, 0.5)
    MinEmblemImg.BackgroundTransparency = 1
    MinEmblemImg.ScaleType = Enum.ScaleType.Fit
    MinEmblemImg.Image = ResolvedMasterLogo
    MinEmblemImg.ZIndex = 802
    MinEmblemImg.Parent = MinimizeIconBtn

    if ResolvedMasterLogo == "" then
        local fbVec = DrawVectorIcon(MinimizeIconBtn, "AutoFarm", 26, "Accent", BindTheme)
        fbVec.Position = UDim2.fromScale(0.5, 0.5)
        fbVec.AnchorPoint = Vector2.new(0.5, 0.5)
        fbVec.ZIndex = 803
    end

    if HasMousePointer then
        MinimizeIconBtn.MouseEnter:Connect(function()
            if not Self.IsMinimized then return end
            SmoothTween(MinimizeIconBtn, 0.14, {BackgroundColor3 = CurrentTheme.CardHoverBg})
            SmoothTween(MinSingleStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0})
        end)
        MinimizeIconBtn.MouseLeave:Connect(function()
            if not Self.IsMinimized then return end
            SmoothTween(MinimizeIconBtn, 0.14, {BackgroundColor3 = CurrentTheme.CardBg})
            SmoothTween(MinSingleStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.12})
        end)
    end

    -- =========================================================================
    -- MAIN WINDOW CONTAINER (1040x520 LEGA, SKALA LAYAR OPTIMAL & TEKS BESAR!)
    -- =========================================================================
    local MainWindow = Instance.new("Frame")
    MainWindow.Name = "MainWindow"
    MainWindow.Size = UDim2.fromOffset(BASE_WIN_W, BASE_WIN_H)
    MainWindow.Position = UDim2.fromScale(0.5, 0.5)
    MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    MainWindow.BackgroundTransparency = Self.BgTransparency
    MainWindow.BorderSizePixel = 0
    MainWindow.Active = true
    MainWindow.Parent = ScreenGui
    BindTheme(MainWindow, "BackgroundColor3", "MainBg")
    ApplySurfaceStyle(MainWindow, 14, CurrentTheme.Stroke, "Stroke", 0.18)

    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainWindow

    local function ComputeTargetScale()
        local cam = workspace.CurrentCamera
        if not cam then return uiScaleValue end
        local vp = cam.ViewportSize
        if vp.X <= 1 or vp.Y <= 1 then return uiScaleValue end

        local targetW = isMaximized and MAX_WIN_W or BASE_WIN_W
        local targetH = isMaximized and MAX_WIN_H or BASE_WIN_H
        local maxScreenRatioX = isMaximized and 0.96 or 0.92
        local maxScreenRatioY = isMaximized and 0.94 or 0.90

        local fitScale = math.min(1, (vp.X * maxScreenRatioX) / targetW, (vp.Y * maxScreenRatioY) / targetH)
        local desired = fitScale * uiScaleValue
        local hardCap = math.min((vp.X * 0.96) / targetW, (vp.Y * 0.94) / targetH)
        return math.clamp(math.min(desired, hardCap), 0.42, 1.35)
    end

    local function UpdateResponsiveScale(animated)
        if not Self.IsMinimized then
            local s = ComputeTargetScale()
            if animated then
                SmoothTween(WindowScale, 0.16, {Scale = s})
            else
                WindowScale.Scale = s
            end
        end
    end

    local camConn
    local function BindCameraViewport()
        if camConn then camConn:Disconnect() end
        if workspace.CurrentCamera then
            camConn = TrackConn(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                UpdateResponsiveScale(false)
            end))
        end
        UpdateResponsiveScale(false)
    end
    TrackConn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCameraViewport))
    BindCameraViewport()

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

    -- 1. LEFT SIDEBAR (22% - BERSIH, HURUF NAVIGASI BESAR & JARAK LEGA)
    local LeftSidebar = Instance.new("Frame")
    LeftSidebar.Name = "LeftSidebar"
    LeftSidebar.Position = UDim2.new(0, 14, 0, 14)
    LeftSidebar.Size = UDim2.new(0.22, -18, 1, -28)
    LeftSidebar.BackgroundTransparency = Self.BgTransparency
    LeftSidebar.BorderSizePixel = 0
    LeftSidebar.Parent = MainWindow
    BindTheme(LeftSidebar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(LeftSidebar, 12, CurrentTheme.Stroke, "Stroke", 0.24)

    local LogoHolder = Instance.new("Frame")
    LogoHolder.Size = UDim2.new(1, 0, 0, 138)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(58, 58)
    BrandLogo.Position = UDim2.new(0.5, 0, 0, 36)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolvedMasterLogo
    BrandLogo.Parent = LogoHolder

    if ResolvedMasterLogo == "" then
        local fallbackCrest = DrawVectorIcon(LogoHolder, "AutoFarm", 36, "Accent", BindTheme)
        fallbackCrest.Position = UDim2.new(0.5, 0, 0, 36)
        fallbackCrest.AnchorPoint = Vector2.new(0.5, 0.5)
    end

    -- Judul Utama Solid & Besar di Bawah Logo (Tanpa 2.5D/3D Gradient!)
    local BrandMainTitle = Instance.new("TextLabel")
    BrandMainTitle.Size = UDim2.new(1, -20, 0, 28)
    BrandMainTitle.Position = UDim2.new(0, 10, 0, 72)
    BrandMainTitle.BackgroundTransparency = 1
    BrandMainTitle.Font = Enum.Font.GothamBlack
    BrandMainTitle.TextSize = 22
    BrandMainTitle.TextTruncate = Enum.TextTruncate.AtEnd
    BrandMainTitle.Parent = LogoHolder
    BindSpacedText(BrandMainTitle, Self.BrandTitle, 1, true, 2)
    BindTheme(BrandMainTitle, "TextColor3", "TextPrimary", "PanelBg")

    local BrandSubLbl = Instance.new("TextLabel")
    BrandSubLbl.Size = UDim2.new(1, -20, 0, 18)
    BrandSubLbl.Position = UDim2.new(0, 10, 0, 102)
    BrandSubLbl.BackgroundTransparency = 1
    BrandSubLbl.Font = Enum.Font.GothamBold
    BrandSubLbl.TextSize = 13
    BrandSubLbl.TextTruncate = Enum.TextTruncate.AtEnd
    BrandSubLbl.Parent = LogoHolder
    BindSpacedText(BrandSubLbl, Self.BrandSubtitle, 1, true, 2)
    BindTheme(BrandSubLbl, "TextColor3", "TextAccent", "PanelBg")

    local NavDivider = Instance.new("Frame")
    NavDivider.Size = UDim2.new(1, -24, 0, 1)
    NavDivider.Position = UDim2.new(0, 12, 0, 130)
    NavDivider.BorderSizePixel = 0
    NavDivider.BackgroundTransparency = 0.35
    NavDivider.Parent = LeftSidebar
    BindTheme(NavDivider, "BackgroundColor3", "Stroke")

    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Position = UDim2.new(0, 12, 0, 138)
    NavScroll.Size = UDim2.new(1, -24, 1, -216)
    NavScroll.BackgroundTransparency = 1
    NavScroll.BorderSizePixel = 0
    NavScroll.ScrollBarThickness = 2
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.Parent = LeftSidebar
    BindTheme(NavScroll, "ScrollBarImageColor3", "Accent")

    local NavPad = Instance.new("UIPadding")
    NavPad.PaddingTop = UDim.new(0, 4)
    NavPad.PaddingLeft = UDim.new(0, 2)
    NavPad.PaddingRight = UDim.new(0, 4)
    NavPad.PaddingBottom = UDim.new(0, 12)
    NavPad.Parent = NavScroll

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 8)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = NavScroll

    -- Sidebar Profile Card
    local ProfileCard = Instance.new("Frame")
    ProfileCard.Size = UDim2.new(1, -24, 0, 58)
    ProfileCard.Position = UDim2.new(0, 12, 1, -70)
    ProfileCard.BorderSizePixel = 0
    ProfileCard.Parent = LeftSidebar
    BindTheme(ProfileCard, "BackgroundColor3", "CardBg")
    ApplySurfaceStyle(ProfileCard, 10, CurrentTheme.Stroke, "Stroke", 0.24)

    local AvatarCircle = Instance.new("ImageLabel")
    AvatarCircle.Size = UDim2.fromOffset(38, 38)
    AvatarCircle.Position = UDim2.new(0, 10, 0.5, -19)
    AvatarCircle.BorderSizePixel = 0
    AvatarCircle.Parent = ProfileCard
    BindTheme(AvatarCircle, "BackgroundColor3", "ControlBg")
    ApplyCornerOnly(AvatarCircle, 19)
    pcall(function()
        local lp = LocalPlayer or Players.LocalPlayer
        if lp and lp.UserId and lp.UserId > 0 then
            AvatarCircle.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=48&h=48"
        end
    end)

    local PlayerNameLbl = Instance.new("TextLabel")
    PlayerNameLbl.Position = UDim2.new(0, 56, 0, 9)
    PlayerNameLbl.Size = UDim2.new(1, -78, 0, 20)
    PlayerNameLbl.BackgroundTransparency = 1
    PlayerNameLbl.Font = Enum.Font.GothamBold
    PlayerNameLbl.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Operator"
    PlayerNameLbl.TextSize = 16
    PlayerNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    PlayerNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    PlayerNameLbl.Parent = ProfileCard
    BindTheme(PlayerNameLbl, "TextColor3", "TextPrimary", "CardBg")

    local PlayerSubLbl = Instance.new("TextLabel")
    PlayerSubLbl.Position = UDim2.new(0, 56, 0, 30)
    PlayerSubLbl.Size = UDim2.new(1, -78, 0, 18)
    PlayerSubLbl.BackgroundTransparency = 1
    PlayerSubLbl.Font = Enum.Font.GothamMedium
    PlayerSubLbl.Text = "Active Session"
    PlayerSubLbl.TextSize = 13
    PlayerSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    PlayerSubLbl.Parent = ProfileCard
    BindTheme(PlayerSubLbl, "TextColor3", "TextMuted", "CardBg")

    local OnlineDot = Instance.new("Frame")
    OnlineDot.Size = UDim2.fromOffset(9, 9)
    OnlineDot.Position = UDim2.new(1, -18, 0.5, -4)
    OnlineDot.BorderSizePixel = 0
    OnlineDot.Parent = ProfileCard
    BindTheme(OnlineDot, "BackgroundColor3", "Accent")
    ApplyCornerOnly(OnlineDot, 5)

    -- 2. TOP IMGUI HEADER BAR (TINGGI 56px, JUDUL BESAR 18px, TOMBOL 36x36 JARAK 10px!)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.22, 6, 0, 14)
    TopBar.Size = UDim2.new(0.78, -20, 0, 56)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 12, CurrentTheme.Stroke, "Stroke", 0.24)

    local TopLogoIcon = Instance.new("ImageLabel")
    TopLogoIcon.Position = UDim2.new(0, 18, 0.5, -13)
    TopLogoIcon.Size = UDim2.fromOffset(26, 26)
    TopLogoIcon.BackgroundTransparency = 1
    TopLogoIcon.ScaleType = Enum.ScaleType.Fit
    TopLogoIcon.Image = ResolvedMasterLogo
    TopLogoIcon.Parent = TopBar

    if ResolvedMasterLogo == "" then
        local vecTop = DrawVectorIcon(TopBar, "AutoFarm", 20, "Accent", BindTheme)
        vecTop.Position = UDim2.new(0, 18, 0.5, -10)
    end

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Position = UDim2.new(0, 54, 0, 0)
    TopTitle.Size = UDim2.new(0.46, 0, 1, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Font = Enum.Font.GothamBlack
    TopTitle.TextSize = 18
    TopTitle.TextTruncate = Enum.TextTruncate.AtEnd
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    BindSpacedText(TopTitle, Self.Title, 0, false, 1)
    BindTheme(TopTitle, "TextColor3", "TextPrimary", "PanelBg")

    local TopThemeTag = Instance.new("Frame")
    TopThemeTag.AutomaticSize = Enum.AutomaticSize.X
    TopThemeTag.Size = UDim2.fromOffset(0, 34)
    TopThemeTag.Position = UDim2.new(1, -206, 0.5, 0)
    TopThemeTag.AnchorPoint = Vector2.new(1, 0.5)
    TopThemeTag.BorderSizePixel = 0
    TopThemeTag.Parent = TopBar
    BindTheme(TopThemeTag, "BackgroundColor3", "CardBg")
    ApplySurfaceStyle(TopThemeTag, 17, CurrentTheme.Stroke, "Stroke", 0.22)

    local TagPad = Instance.new("UIPadding")
    TagPad.PaddingLeft = UDim.new(0, 14)
    TagPad.PaddingRight = UDim.new(0, 14)
    TagPad.Parent = TopThemeTag

    local TopThemeTxt = Instance.new("TextLabel")
    TopThemeTxt.AutomaticSize = Enum.AutomaticSize.X
    TopThemeTxt.Size = UDim2.new(0, 0, 1, 0)
    TopThemeTxt.BackgroundTransparency = 1
    TopThemeTxt.Font = Enum.Font.GothamBold
    TopThemeTxt.Text = Self.ThemeName
    TopThemeTxt.TextSize = 14
    TopThemeTxt.Parent = TopThemeTag
    BindTheme(TopThemeTxt, "TextColor3", "TextAccent", "CardBg")

    -- 4 Tombol Kontrol Window: 36x36px dengan jarak antar tombol 10px & margin kanan 16px!
    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Position = UDim2.new(1, -190, 0, 0)
    ControlsHolder.Size = UDim2.new(0, 174, 1, 0)
    ControlsHolder.BackgroundTransparency = 1
    ControlsHolder.Parent = TopBar

    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 10)
    ControlsLayout.Parent = ControlsHolder

    local function CreateVectorWindowBtn(vectorType, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(36, 36)
        btn.BackgroundTransparency = 0.15
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ControlsHolder
        BindTheme(btn, "BackgroundColor3", "CardBg")
        local _, bStroke = ApplySurfaceStyle(btn, 9, CurrentTheme.Stroke, "Stroke", 0.24)

        local icon, recolorIcon = DrawVectorIcon(btn, vectorType, 16, "TextPrimary", BindTheme)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)

        if HasMousePointer then
            btn.MouseEnter:Connect(function()
                SmoothTween(btn, 0.12, {BackgroundColor3 = CurrentTheme.CardHoverBg, BackgroundTransparency = 0})
                SmoothTween(bStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.05})
                recolorIcon(CurrentTheme.TextAccent)
            end)
            btn.MouseLeave:Connect(function()
                SmoothTween(btn, 0.14, {BackgroundColor3 = CurrentTheme.CardBg, BackgroundTransparency = 0.15})
                SmoothTween(bStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.24})
                recolorIcon(CurrentTheme.TextPrimary)
            end)
        end
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL (45% di mode 3-sisi, 78% di mode 2-sisi - Margin Lega)
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.22, 6, 0, 80)
    CenterPanel.Size = (Self.SideCount == 3) and UDim2.new(0.45, -12, 1, -94) or UDim2.new(0.78, -20, 1, -94)
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.BorderSizePixel = 0
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, "Stroke", 0.24)

    -- 4. RIGHT PANEL (33% LEBAR AGAR CARD & TULISAN BESAR LEGA TIDAK PERNAH MEPET!)
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.67, 6, 0, 80)
    RightPanel.Size = UDim2.new(0.33, -20, 1, -94)
    RightPanel.BackgroundTransparency = Self.BgTransparency
    RightPanel.BorderSizePixel = 0
    RightPanel.ClipsDescendants = true
    RightPanel.Visible = (Self.SideCount == 3)
    RightPanel.Parent = MainWindow
    BindTheme(RightPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(RightPanel, 12, CurrentTheme.Stroke, "Stroke", 0.24)

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
    -- MINIMIZE & RESTORE HALUS NATURAL (TANPA MOTION ANEH / IMPLODE KE 0)
    -- =========================================================================
    function Self:MinimizeToIcon()
        if Self.IsMinimized then return end
        Self.IsMinimized = true
        FocusBlocker.Visible = false

        if Self.ReduceEffects then
            MainWindow.Visible = false
            MinimizeIconBtn.Visible = true
            return
        end

        MinimizeIconBtn.Visible = true
        local targetS = ComputeTargetScale()
        local shrink = TweenService:Create(WindowScale, SMOOTH_FAST, {Scale = targetS * 0.94})
        shrink:Play()
        shrink.Completed:Connect(function()
            if Self.IsMinimized then
                MainWindow.Visible = false
            end
        end)
    end

    function Self:RestoreFromIcon()
        if not Self.IsMinimized then return end
        Self.IsMinimized = false

        MinimizeIconBtn.Visible = false
        MainWindow.Visible = true
        FocusBlocker.Visible = Self.FocusMode

        local targetS = ComputeTargetScale()
        if Self.ReduceEffects then
            WindowScale.Scale = targetS
            return
        end

        WindowScale.Scale = targetS * 0.94
        SmoothTween(WindowScale, 0.15, {Scale = targetS})
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

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    iconDragging = false
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
            SmoothTween(CenterPanel, 0.16, {Size = UDim2.new(0.45, -12, 1, -94)})
        else
            RightPanel.Visible = false
            SmoothTween(CenterPanel, 0.16, {Size = UDim2.new(0.78, -20, 1, -94)})
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
    CreateVectorWindowBtn("Maximize", function()
        isMaximized = not isMaximized
        local w = isMaximized and MAX_WIN_W or BASE_WIN_W
        local h = isMaximized and MAX_WIN_H or BASE_WIN_H
        SmoothTween(MainWindow, 0.16, {Size = UDim2.fromOffset(w, h)})
        UpdateResponsiveScale(true)
    end)
    CreateVectorWindowBtn("Close", function()
        Self:MinimizeToIcon()
    end)

    -- =========================================================================
    -- LIVE UPDATERS
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

    -- Kompatibilitas aman jika script lama memanggil SetText3D (tidak memasang UIGradient teks)
    function Self:SetText3D(_)
        Self.Text3D = false
    end

    function Self:SetCheckboxStyle(styleName)
        Self.CheckboxStyle = styleName or "Modern"
        RefreshAllThemeElements()
    end

    function Self:SetLetterSpacing(amount)
        Self.LetterSpacing = math.clamp(tonumber(amount) or 0, 0, 3)
        for _, sb in ipairs(Self.SpacingBindings) do
            if sb.Instance and sb.Instance.Parent then
                sb.Apply()
            end
        end
    end

    function Self:SetScale(newScale)
        uiScaleValue = math.clamp(tonumber(newScale) or 1, 0.5, 1.5)
        UpdateResponsiveScale(false)
    end

    function Self:SetRounded(state)
        Self.Rounded = (state == true)
        for _, r in ipairs(Self.RadiusBindings) do
            if r.Instance and r.Instance.Parent then
                r.Instance.CornerRadius = UDim.new(0, Self.Rounded and r.BaseRadius or 0)
            end
        end
        RefreshAllThemeElements()
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

    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({BrandLogo, TopLogoIcon, MinEmblemImg})
        end)
    end)

    function Self:RunInternalLoader(duration)
        duration = duration or 0.40
        local Loader = Instance.new("Frame")
        Loader.Name = "FrameworkLoader"
        Loader.Size = UDim2.fromScale(1, 1)
        Loader.BackgroundColor3 = CurrentTheme.MainBg
        Loader.BorderSizePixel = 0
        Loader.ZIndex = 500
        Loader.Parent = MainWindow
        ApplyCornerOnly(Loader, 14)

        local LoadTitle = Instance.new("TextLabel")
        LoadTitle.Size = UDim2.new(1, 0, 0, 34)
        LoadTitle.Position = UDim2.new(0, 0, 0.44, 0)
        LoadTitle.BackgroundTransparency = 1
        LoadTitle.Font = Enum.Font.GothamBlack
        LoadTitle.Text = FormatSpacedText(Self.Title, 1)
        LoadTitle.TextSize = 22
        LoadTitle.ZIndex = 501
        LoadTitle.Parent = Loader
        BindTheme(LoadTitle, "TextColor3", "TextPrimary", "MainBg")

        local BarBg = Instance.new("Frame")
        BarBg.Size = UDim2.fromOffset(220, 4)
        BarBg.Position = UDim2.new(0.5, -110, 0.54, 0)
        BarBg.BorderSizePixel = 0
        BarBg.ZIndex = 501
        BarBg.Parent = Loader
        BindTheme(BarBg, "BackgroundColor3", "ControlBg")
        ApplyCornerOnly(BarBg, 2)

        local BarFill = Instance.new("Frame")
        BarFill.Size = UDim2.new(0, 0, 1, 0)
        BarFill.BorderSizePixel = 0
        BarFill.ZIndex = 502
        BarFill.Parent = BarBg
        BindTheme(BarFill, "BackgroundColor3", "Accent")
        ApplyCornerOnly(BarFill, 2)

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(1, 1)
        }):Play()

        task.delay(duration, function()
            if Loader and Loader.Parent then
                TweenService:Create(Loader, SMOOTH_FAST, {BackgroundTransparency = 1}):Play()
                TweenService:Create(LoadTitle, SMOOTH_FAST, {TextTransparency = 1}):Play()
                TweenService:Create(BarBg, SMOOTH_FAST, {BackgroundTransparency = 1}):Play()
                TweenService:Create(BarFill, SMOOTH_FAST, {BackgroundTransparency = 1}):Play()
                task.wait(0.15)
                if Loader and Loader.Parent then Loader:Destroy() end
            end
        end)
    end

    if Self.AutoLoading then
        Self:RunInternalLoader(0.40)
    end

    -- =========================================================================
    -- HELPER SWITCH / CHECKLIST UNIVERSAL (BESAR, BEBAS BUG, SMOOTH, KONTRAS TAJAM)
    -- Dipakai seragam oleh `Builder:Toggle` maupun Header `Builder:Card`!
    -- =========================================================================
    local function CreateInteractiveSwitch(parent, flag, onToggleCallback, styleOverride)
        local SwitchBg = Instance.new("Frame")
        SwitchBg.AnchorPoint = Vector2.new(1, 0.5)
        SwitchBg.Position = UDim2.new(1, 0, 0.5, 0)
        SwitchBg.BorderSizePixel = 0
        SwitchBg.Parent = parent
        local swCorner, swStroke = ApplySurfaceStyle(SwitchBg, 13, CurrentTheme.Stroke, false, 0.22)

        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.fromOffset(20, 20)
        Knob.AnchorPoint = Vector2.new(0, 0.5)
        Knob.BorderSizePixel = 0
        Knob.Parent = SwitchBg
        ApplyCornerOnly(Knob, 10)

        local CheckVec, recolorCheck = DrawVectorIcon(SwitchBg, "Check", 17, nil, nil)
        CheckVec.Position = UDim2.fromScale(0.5, 0.5)
        CheckVec.AnchorPoint = Vector2.new(0.5, 0.5)

        local lastModeIsBox = nil

        local function SyncVisual(animated, isHovered)
            local on = (Self.Flags[flag] == true)
            local mode = string.lower(tostring(styleOverride or Self.CheckboxStyle or "modern"))
            local isBox = (mode == "checkbox" or mode == "box" or mode == "classic" or mode == "checklist")

            local fillCol = on and CurrentTheme.Accent or CurrentTheme.ControlBg
            local strokeCol = on and CurrentTheme.Accent or (isHovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
            local strokeTr = on and 0.05 or (isHovered and 0.08 or 0.24)
            local contrastFg = on and GetOnFillColor(CurrentTheme.Accent) or Color3.fromRGB(242, 246, 255)

            -- Jika baru berganti mode antara Pill <-> Checkbox, langsung sesuaikan ukuran tanpa motion aneh
            local allowAnim = animated and (lastModeIsBox == isBox)
            lastModeIsBox = isBox

            if isBox then
                SwitchBg.Size = UDim2.fromOffset(28, 28)
                swCorner.CornerRadius = UDim.new(0, Self.Rounded and 8 or 0)
                Knob.Visible = false
                CheckVec.Visible = on
                recolorCheck(contrastFg)
            else
                SwitchBg.Size = UDim2.fromOffset(50, 26)
                swCorner.CornerRadius = UDim.new(0, Self.Rounded and 13 or 0)
                CheckVec.Visible = false
                Knob.Visible = true
                local targetPos = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                if allowAnim then
                    SmoothTween(Knob, 0.14, {Position = targetPos, BackgroundColor3 = contrastFg})
                else
                    Knob.Position = targetPos
                    Knob.BackgroundColor3 = contrastFg
                end
            end

            if allowAnim then
                SmoothTween(SwitchBg, 0.14, {BackgroundColor3 = fillCol})
                SmoothTween(swStroke, 0.14, {Color = strokeCol, Transparency = strokeTr})
            else
                SwitchBg.BackgroundColor3 = fillCol
                swStroke.Color = strokeCol
                swStroke.Transparency = strokeTr
            end

            if onToggleCallback then
                onToggleCallback(on)
            end
        end

        return SwitchBg, SyncVisual
    end

    -- =========================================================================
    -- WIDGET FACTORY (`center()` & `right()`) - LARGE EFFORTLESS CANVAS TEXT!
    -- =========================================================================
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

        -- Page Header Card Besar, Tegas & Terbaca Jelas Tanpa Mendekat ke Layar
        function Builder:Header(title, subtitle, badgeText)
            local hasSub = (subtitle and subtitle ~= "")
            local hasBadge = (badgeText and badgeText ~= "")
            local rightCut = hasBadge and -136 or -46

            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Size = UDim2.new(1, 0, 0, hasSub and 88 or 60)
            HeaderFrame.BorderSizePixel = 0
            HeaderFrame.Parent = scrollingPage
            BindTheme(HeaderFrame, "BackgroundColor3", "CardBg")
            ApplySurfaceStyle(HeaderFrame, 12, CurrentTheme.Stroke, "Stroke", 0.22)

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(0, 5, 0, hasSub and 54 or 30)
            AccentBar.Position = UDim2.new(0, 16, 0.5, 0)
            AccentBar.AnchorPoint = Vector2.new(0, 0.5)
            AccentBar.BorderSizePixel = 0
            AccentBar.Parent = HeaderFrame
            BindTheme(AccentBar, "BackgroundColor3", "Accent")
            ApplyCornerOnly(AccentBar, 3)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 32, 0, hasSub and 11 or 14)
            TitleLbl.Size = UDim2.new(1, rightCut, 0, 32)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBlack
            TitleLbl.TextSize = 26
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = HeaderFrame
            BindSpacedText(TitleLbl, title, 0, true, 1)
            BindTheme(TitleLbl, "TextColor3", "TextPrimary", "CardBg")

            if hasSub then
                local SubLbl = Instance.new("TextLabel")
                SubLbl.Position = UDim2.new(0, 32, 0, 44)
                SubLbl.Size = UDim2.new(1, rightCut, 0, 36)
                SubLbl.BackgroundTransparency = 1
                SubLbl.Font = Enum.Font.GothamMedium
                SubLbl.Text = subtitle
                SubLbl.TextSize = 15
                SubLbl.TextWrapped = true
                SubLbl.TextXAlignment = Enum.TextXAlignment.Left
                SubLbl.TextYAlignment = Enum.TextYAlignment.Top
                SubLbl.Parent = HeaderFrame
                BindTheme(SubLbl, "TextColor3", "TextMuted", "CardBg")
            end

            if hasBadge then
                local Pill = Instance.new("Frame")
                Pill.AutomaticSize = Enum.AutomaticSize.X
                Pill.Size = UDim2.fromOffset(0, 34)
                Pill.Position = UDim2.new(1, -16, 0.5, 0)
                Pill.AnchorPoint = Vector2.new(1, 0.5)
                Pill.BorderSizePixel = 0
                Pill.Parent = HeaderFrame
                ApplyCornerOnly(Pill, 17)

                local PillPad = Instance.new("UIPadding")
                PillPad.PaddingLeft = UDim.new(0, 14)
                PillPad.PaddingRight = UDim.new(0, 14)
                PillPad.Parent = Pill

                local PillTxt = Instance.new("TextLabel")
                PillTxt.AutomaticSize = Enum.AutomaticSize.X
                PillTxt.Size = UDim2.new(0, 0, 1, 0)
                PillTxt.BackgroundTransparency = 1
                PillTxt.Font = Enum.Font.GothamBlack
                PillTxt.Text = string.upper(tostring(badgeText))
                PillTxt.TextSize = 13
                PillTxt.Parent = Pill

                RegisterThemeUpdater(Pill, function(theme)
                    Pill.BackgroundColor3 = theme.Accent
                    PillTxt.TextColor3 = GetOnFillColor(theme.Accent)
                end)
            end
        end

        -- Fallback aman jika ada script memanggil HighlightBanner (dirancang sebagai Info Card standar bersih)
        function Builder:HighlightBanner(eyebrow, headline, subtext, badgeText)
            Builder:Header(headline or eyebrow or "Overview", subtext, badgeText)
        end

        -- Pemilih Palet 5 Tema (Teks 16px & Swatch 34px Pas di Dalam Card Panel Kanan)
        function Builder:ThemeSwatches(label)
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 84)
            Holder.BorderSizePixel = 0
            Holder.Parent = scrollingPage
            BindTheme(Holder, "BackgroundColor3", "RowBg")
            ApplySurfaceStyle(Holder, 10, CurrentTheme.Stroke, "Stroke", 0.30)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 12, 0, 9)
            TitleLbl.Size = UDim2.new(0.46, -12, 0, 22)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBold
            TitleLbl.Text = tostring(label or "Colour Palette")
            TitleLbl.TextSize = 16
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = Holder
            BindTheme(TitleLbl, "TextColor3", "TextPrimary", "RowBg")

            local ActiveThemeLbl = Instance.new("TextLabel")
            ActiveThemeLbl.Position = UDim2.new(0.46, 0, 0, 9)
            ActiveThemeLbl.Size = UDim2.new(0.54, -12, 0, 22)
            ActiveThemeLbl.BackgroundTransparency = 1
            ActiveThemeLbl.Font = Enum.Font.GothamBold
            ActiveThemeLbl.Text = Self.ThemeName
            ActiveThemeLbl.TextSize = 14
            ActiveThemeLbl.TextTruncate = Enum.TextTruncate.AtEnd
            ActiveThemeLbl.TextXAlignment = Enum.TextXAlignment.Right
            ActiveThemeLbl.Parent = Holder
            BindTheme(ActiveThemeLbl, "TextColor3", "TextAccent", "RowBg")

            local Row = Instance.new("Frame")
            Row.Position = UDim2.new(0, 12, 0, 38)
            Row.Size = UDim2.new(1, -24, 0, 36)
            Row.BackgroundTransparency = 1
            Row.Parent = Holder

            local RowLayout = Instance.new("UIListLayout")
            RowLayout.FillDirection = Enum.FillDirection.Horizontal
            RowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            RowLayout.SortOrder = Enum.SortOrder.LayoutOrder
            RowLayout.Padding = UDim.new(0, 10)
            RowLayout.Parent = Row

            local SwatchItems = {}
            for idx, tName in ipairs(ThemeOrder) do
                local tData = Themes[tName]
                local RingBtn = Instance.new("TextButton")
                RingBtn.LayoutOrder = idx
                RingBtn.Size = UDim2.fromOffset(34, 34)
                RingBtn.BackgroundTransparency = 1
                RingBtn.BorderSizePixel = 0
                RingBtn.Text = ""
                RingBtn.AutoButtonColor = false
                RingBtn.Parent = Row
                ApplyCornerOnly(RingBtn, 17)

                local RingStroke = Instance.new("UIStroke")
                RingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                RingStroke.Thickness = 2
                RingStroke.Parent = RingBtn

                local InnerCircle = Instance.new("Frame")
                InnerCircle.Size = UDim2.fromOffset(24, 24)
                InnerCircle.Position = UDim2.fromScale(0.5, 0.5)
                InnerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                InnerCircle.BackgroundColor3 = tData.Accent
                InnerCircle.BorderSizePixel = 0
                InnerCircle.Parent = RingBtn
                ApplyCornerOnly(InnerCircle, 12)

                local CheckIcon, recolorCheck = DrawVectorIcon(InnerCircle, "Check", 13, nil, nil)
                CheckIcon.Position = UDim2.fromScale(0.5, 0.5)
                CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                recolorCheck(GetOnFillColor(tData.Accent))

                RingBtn.MouseButton1Click:Connect(function()
                    Self:SetTheme(tName)
                    if Self.Flags["ThemeSelect"] ~= nil and Self.Flags["ThemeSelect"] ~= tName then
                        Self:SetValue("ThemeSelect", tName, true)
                        if Self.FlagListeners["ThemeSelect"] then
                            for _, cb in ipairs(Self.FlagListeners["ThemeSelect"]) do
                                task.spawn(cb, tName)
                            end
                        end
                    end
                end)

                table.insert(SwatchItems, {
                    Name = tName,
                    Stroke = RingStroke,
                    Check = CheckIcon
                })
            end

            RegisterThemeUpdater(Holder, function(theme)
                ActiveThemeLbl.Text = Self.ThemeName
                for _, item in ipairs(SwatchItems) do
                    local isSel = (Self.ThemeName == item.Name)
                    item.Check.Visible = isSel
                    item.Stroke.Color = isSel and theme.TextPrimary or theme.Stroke
                    item.Stroke.Transparency = isSel and 0.05 or 0.55
                end
            end)
        end

        -- StatRow 2-Tingkat: Label Atas 13px + Nilai Bawah Full-Width 20px Anti-Terpotong!
        function Builder:StatRow(statsList)
            local count = math.max(#statsList, 1)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 92)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / count, -8, 1, 0)
            Grid.CellPadding = UDim2.new(0, 12, 0, 0)
            Grid.Parent = Row

            local ValueLabels = {}
            for i, item in ipairs(statsList) do
                local Card = Instance.new("Frame")
                Card.BorderSizePixel = 0
                Card.Parent = Row
                BindTheme(Card, "BackgroundColor3", "CardBg")
                local _, statStroke = ApplySurfaceStyle(Card, 11, CurrentTheme.Stroke, "Stroke", 0.24)

                local IconBox = Instance.new("Frame")
                IconBox.Size = UDim2.fromOffset(28, 28)
                IconBox.Position = UDim2.new(0, 12, 0, 12)
                IconBox.BorderSizePixel = 0
                IconBox.Parent = Card
                BindTheme(IconBox, "BackgroundColor3", "AccentSoft")
                ApplyCornerOnly(IconBox, 8)

                local vecIcon = DrawVectorIcon(IconBox, item.Icon or "Bolt", 15, "TextAccent", BindTheme)
                vecIcon.Position = UDim2.fromScale(0.5, 0.5)
                vecIcon.AnchorPoint = Vector2.new(0.5, 0.5)

                local Lbl = Instance.new("TextLabel")
                Lbl.Position = UDim2.new(0, 48, 0, 16)
                Lbl.Size = UDim2.new(1, -58, 0, 20)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = string.upper(tostring(item.Label or ""))
                Lbl.TextSize = 13
                Lbl.TextTruncate = Enum.TextTruncate.AtEnd
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Card
                BindTheme(Lbl, "TextColor3", "TextMuted", "CardBg")

                local Val = Instance.new("TextLabel")
                Val.Position = UDim2.new(0, 12, 0, 48)
                Val.Size = UDim2.new(1, -24, 0, 30)
                Val.BackgroundTransparency = 1
                Val.Font = Enum.Font.GothamBlack
                Val.Text = tostring(item.Value or "")
                Val.TextSize = 20
                Val.TextTruncate = Enum.TextTruncate.AtEnd
                Val.TextXAlignment = Enum.TextXAlignment.Left
                Val.Parent = Card
                BindTheme(Val, "TextColor3", "TextPrimary", "CardBg")
                ValueLabels[i] = Val

                if HasMousePointer then
                    Card.MouseEnter:Connect(function()
                        SmoothTween(Card, 0.14, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                        SmoothTween(statStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
                    end)
                    Card.MouseLeave:Connect(function()
                        SmoothTween(Card, 0.14, {BackgroundColor3 = CurrentTheme.CardBg})
                        SmoothTween(statStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.24})
                    end)
                end
            end
            return ValueLabels
        end

        -- =====================================================================
        -- CARD CONTAINER (JUDUL BESAR 20px, SUBTITLE 15px, PADDING 18px LEGA!)
        -- =====================================================================
        function Builder:Card(title, rightActionText, iconName, cardOpts)
            if type(rightActionText) == "table" and cardOpts == nil then
                cardOpts = rightActionText
                rightActionText = cardOpts.ActionText
                iconName = iconName or cardOpts.Icon
            end
            cardOpts = cardOpts or {}

            local CardFrame = Instance.new("Frame")
            CardFrame.Size = UDim2.new(1, 0, 0, 52)
            CardFrame.AutomaticSize = Enum.AutomaticSize.Y
            CardFrame.BorderSizePixel = 0
            CardFrame.Parent = scrollingPage
            BindTheme(CardFrame, "BackgroundColor3", "CardBg")
            local _, cardStroke = ApplySurfaceStyle(CardFrame, 12, CurrentTheme.Stroke, "Stroke", 0.22)

            if HasMousePointer then
                CardFrame.MouseEnter:Connect(function()
                    SmoothTween(CardFrame, 0.14, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                    SmoothTween(cardStroke, 0.14, {Color = CurrentTheme.HoverStroke, Transparency = 0.10})
                end)
                CardFrame.MouseLeave:Connect(function()
                    SmoothTween(CardFrame, 0.16, {BackgroundColor3 = CurrentTheme.CardBg})
                    SmoothTween(cardStroke, 0.16, {Color = CurrentTheme.Stroke, Transparency = 0.22})
                end)
            end

            local Pad = Instance.new("UIPadding")
            Pad.PaddingTop = UDim.new(0, 18)
            Pad.PaddingBottom = UDim.new(0, 18)
            Pad.PaddingLeft = UDim.new(0, 18)
            Pad.PaddingRight = UDim.new(0, 18)
            Pad.Parent = CardFrame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 12)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = CardFrame

            if title and title ~= "" then
                local hasSub = (cardOpts.Subtitle and cardOpts.Subtitle ~= "")
                local rightReserve = cardOpts.ToggleFlag and 60 or (rightActionText and 118 or 4)

                local TopRow = Instance.new("Frame")
                TopRow.Size = UDim2.new(1, 0, 0, hasSub and 54 or 34)
                TopRow.AutomaticSize = Enum.AutomaticSize.Y
                TopRow.BackgroundTransparency = 1
                TopRow.Parent = CardFrame

                local leftOffset = 0
                if iconName then
                    local HdrIconBadge = Instance.new("Frame")
                    HdrIconBadge.Size = UDim2.fromOffset(34, 34)
                    HdrIconBadge.Position = UDim2.new(0, 0, 0, 0)
                    HdrIconBadge.BorderSizePixel = 0
                    HdrIconBadge.Parent = TopRow
                    BindTheme(HdrIconBadge, "BackgroundColor3", "AccentSoft")
                    ApplyCornerOnly(HdrIconBadge, 9)

                    local hdrIcon = DrawVectorIcon(HdrIconBadge, iconName, 18, "TextAccent", BindTheme)
                    hdrIcon.Position = UDim2.fromScale(0.5, 0.5)
                    hdrIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                    leftOffset = 44
                end

                local TitleTxt = Instance.new("TextLabel")
                TitleTxt.Position = UDim2.new(0, leftOffset, 0, 3)
                TitleTxt.Size = UDim2.new(1, -(leftOffset + rightReserve), 0, 26)
                TitleTxt.BackgroundTransparency = 1
                TitleTxt.Font = Enum.Font.GothamBlack
                TitleTxt.Text = title
                TitleTxt.TextSize = 20
                TitleTxt.TextTruncate = Enum.TextTruncate.AtEnd
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
                TitleTxt.Parent = TopRow
                BindTheme(TitleTxt, "TextColor3", "TextPrimary", "CardBg")

                if hasSub then
                    local subRightReserve = cardOpts.ToggleFlag and 56 or 4
                    local CardSub = Instance.new("TextLabel")
                    CardSub.Position = UDim2.new(0, leftOffset, 0, 32)
                    CardSub.Size = UDim2.new(1, -(leftOffset + subRightReserve), 0, 20)
                    CardSub.AutomaticSize = Enum.AutomaticSize.Y
                    CardSub.BackgroundTransparency = 1
                    CardSub.Font = Enum.Font.GothamMedium
                    CardSub.Text = cardOpts.Subtitle
                    CardSub.TextSize = 15
                    CardSub.TextWrapped = true
                    CardSub.TextXAlignment = Enum.TextXAlignment.Left
                    CardSub.TextYAlignment = Enum.TextYAlignment.Top
                    CardSub.Parent = TopRow
                    BindTheme(CardSub, "TextColor3", "TextMuted", "CardBg")
                end

                if cardOpts.ToggleFlag then
                    local tFlag = cardOpts.ToggleFlag
                    Self.Flags[tFlag] = (cardOpts.Default == true)

                    local HdrClick = Instance.new("TextButton")
                    HdrClick.Size = UDim2.fromOffset(56, 34)
                    HdrClick.Position = UDim2.new(1, -56, 0, 0)
                    HdrClick.BackgroundTransparency = 1
                    HdrClick.Text = ""
                    HdrClick.AutoButtonColor = false
                    HdrClick.Parent = TopRow

                    local _, syncHdrSw = CreateInteractiveSwitch(HdrClick, tFlag, nil, nil)
                    RegisterThemeUpdater(HdrClick, function() syncHdrSw(false, false) end)
                    Self:OnValueChanged(tFlag, function() syncHdrSw(true, false) end)

                    HdrClick.MouseButton1Click:Connect(function()
                        local nextVal = not Self.Flags[tFlag]
                        Self:SetValue(tFlag, nextVal)
                        if cardOpts.Callback then task.spawn(cardOpts.Callback, nextVal) end
                    end)
                elseif rightActionText then
                    local ActionTxt = Instance.new("TextLabel")
                    ActionTxt.Size = UDim2.new(0, 102, 0, 26)
                    ActionTxt.Position = UDim2.new(1, -118, 0, 4)
                    ActionTxt.BackgroundTransparency = 1
                    ActionTxt.Font = Enum.Font.GothamBold
                    ActionTxt.Text = rightActionText
                    ActionTxt.TextSize = 14
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right
                    ActionTxt.Parent = TopRow
                    BindTheme(ActionTxt, "TextColor3", "TextAccent", "CardBg")

                    local arr = DrawVectorIcon(TopRow, "ArrowRight", 13, "TextAccent", BindTheme)
                    arr.Position = UDim2.new(1, -13, 0, 10)
                end

                local Divider = Instance.new("Frame")
                Divider.Size = UDim2.new(1, 0, 0, 1)
                Divider.BorderSizePixel = 0
                Divider.BackgroundTransparency = 0.40
                Divider.Parent = CardFrame
                BindTheme(Divider, "BackgroundColor3", "Stroke")
            end

            return CreateCanvasBuilder(CardFrame)
        end

        -- =====================================================================
        -- INTERACTIVE FEATURE CARD (JUDUL 19px, DESKRIPSI 15px, KONTRAS TAJAM!)
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
            CardBtn.Size = UDim2.new(1, 0, 0, desc ~= "" and 90 or 62)
            CardBtn.BorderSizePixel = 0
            CardBtn.Text = ""
            CardBtn.AutoButtonColor = false
            CardBtn.Parent = scrollingPage
            local _, fcStroke = ApplySurfaceStyle(CardBtn, 12, CurrentTheme.Stroke, false, 0.22)

            local IconBadge = Instance.new("Frame")
            IconBadge.Size = UDim2.fromOffset(48, 48)
            IconBadge.Position = UDim2.new(0, 16, 0.5, -24)
            IconBadge.BorderSizePixel = 0
            IconBadge.Parent = CardBtn
            ApplyCornerOnly(IconBadge, 12)

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
                local vec, recolor = DrawVectorIcon(IconBadge, iconName, 23, nil, nil)
                vec.Position = UDim2.fromScale(0.5, 0.5)
                vec.AnchorPoint = Vector2.new(0.5, 0.5)
                recolorVec = recolor
            end

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 76, 0, desc ~= "" and 13 or 18)
            TitleLbl.Size = UDim2.new(1, -154, 0, 24)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBlack
            TitleLbl.Text = title
            TitleLbl.TextSize = 19
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = CardBtn
            BindTheme(TitleLbl, "TextColor3", "TextPrimary", "CardBg")

            if desc ~= "" then
                local DescLbl = Instance.new("TextLabel")
                DescLbl.Position = UDim2.new(0, 76, 0, 40)
                DescLbl.Size = UDim2.new(1, -150, 0, 40)
                DescLbl.BackgroundTransparency = 1
                DescLbl.Font = Enum.Font.GothamMedium
                DescLbl.Text = desc
                DescLbl.TextSize = 15
                DescLbl.TextWrapped = true
                DescLbl.TextXAlignment = Enum.TextXAlignment.Left
                DescLbl.TextYAlignment = Enum.TextYAlignment.Top
                DescLbl.Parent = CardBtn
                BindTheme(DescLbl, "TextColor3", "TextMuted", "CardBg")
            end

            local StatusPill = Instance.new("Frame")
            StatusPill.AutomaticSize = Enum.AutomaticSize.X
            StatusPill.Size = UDim2.fromOffset(0, 32)
            StatusPill.Position = UDim2.new(1, -16, 0.5, -16)
            StatusPill.AnchorPoint = Vector2.new(1, 0)
            StatusPill.BorderSizePixel = 0
            StatusPill.Parent = CardBtn
            ApplyCornerOnly(StatusPill, 9)

            local spPad = Instance.new("UIPadding")
            spPad.PaddingLeft = UDim.new(0, 13)
            spPad.PaddingRight = UDim.new(0, 13)
            spPad.Parent = StatusPill

            local StatusTxt = Instance.new("TextLabel")
            StatusTxt.AutomaticSize = Enum.AutomaticSize.X
            StatusTxt.Size = UDim2.new(0, 0, 1, 0)
            StatusTxt.BackgroundTransparency = 1
            StatusTxt.Font = Enum.Font.GothamBlack
            StatusTxt.TextSize = 13
            StatusTxt.Parent = StatusPill

            local hovered = false
            local function SyncCardState(animated)
                local active = isToggleable and (Self.Flags[flag] == true)
                local bgCol = active and CurrentTheme.AccentSoft or (hovered and CurrentTheme.CardHoverBg or CurrentTheme.CardBg)
                local stCol = active and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                local stTrans = active and 0.04 or (hovered and 0.08 or 0.24)
                local badgeBg = active and CurrentTheme.Accent or CurrentTheme.ControlBg
                local onAccFg = GetOnFillColor(CurrentTheme.Accent)

                StatusPill.BackgroundColor3 = active and CurrentTheme.Accent or CurrentTheme.ControlBg
                StatusTxt.Text = opts.Badge or (isToggleable and (active and "ON" or "OFF") or "OPEN")
                StatusTxt.TextColor3 = active and onAccFg or CurrentTheme.TextPrimary

                if recolorVec then
                    recolorVec(active and onAccFg or CurrentTheme.TextAccent)
                end

                if animated then
                    SmoothTween(CardBtn, 0.14, {BackgroundColor3 = bgCol})
                    SmoothTween(fcStroke, 0.14, {Color = stCol, Transparency = stTrans})
                    SmoothTween(IconBadge, 0.14, {BackgroundColor3 = badgeBg})
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

            if HasMousePointer then
                CardBtn.MouseEnter:Connect(function()
                    hovered = true
                    SyncCardState(true)
                end)
                CardBtn.MouseLeave:Connect(function()
                    hovered = false
                    SyncCardState(true)
                end)
            end
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
            GridHolder.Size = UDim2.new(1, 0, 0, 94)
            GridHolder.AutomaticSize = Enum.AutomaticSize.Y
            GridHolder.BackgroundTransparency = 1
            GridHolder.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / cols, -9, 0, 92)
            Grid.CellPadding = UDim2.new(0, 12, 0, 12)
            Grid.Parent = GridHolder

            for _, action in ipairs(items) do
                local flag = action.Flag or action.Name
                Self.Flags[flag] = (action.Default == true)

                local Tile = Instance.new("TextButton")
                Tile.BorderSizePixel = 0
                Tile.Text = ""
                Tile.AutoButtonColor = false
                Tile.Parent = GridHolder
                local _, tileStroke = ApplySurfaceStyle(Tile, 10, CurrentTheme.Stroke, false, 0.24)

                local vec, recolorVec = DrawVectorIcon(Tile, action.Icon or "Bolt", 24, nil, nil)
                vec.Position = UDim2.new(0.5, -12, 0, 16)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -12, 0, 24)
                Lbl.Position = UDim2.new(0, 6, 1, -32)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = action.Name
                Lbl.TextSize = 15
                Lbl.TextTruncate = Enum.TextTruncate.AtEnd
                Lbl.Parent = Tile

                local hovered = false
                local function SyncTile(animated)
                    local on = (Self.Flags[flag] == true)
                    local bg = on and CurrentTheme.AccentSoft or (hovered and CurrentTheme.CardHoverBg or CurrentTheme.RowBg)
                    local st = on and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                    local tr = on and 0.04 or (hovered and 0.08 or 0.24)
                    Lbl.TextColor3 = on and CurrentTheme.TextAccent or CurrentTheme.TextPrimary
                    recolorVec(on and CurrentTheme.TextAccent or CurrentTheme.TextMuted)
                    if animated then
                        SmoothTween(Tile, 0.14, {BackgroundColor3 = bg})
                        SmoothTween(tileStroke, 0.14, {Color = st, Transparency = tr})
                    else
                        Tile.BackgroundColor3 = bg
                        tileStroke.Color = st
                        tileStroke.Transparency = tr
                    end
                end

                RegisterThemeUpdater(Tile, function() SyncTile(false) end)
                Self:OnValueChanged(flag, function() SyncTile(true) end)

                if HasMousePointer then
                    Tile.MouseEnter:Connect(function()
                        hovered = true
                        SyncTile(true)
                    end)
                    Tile.MouseLeave:Connect(function()
                        hovered = false
                        SyncTile(true)
                    end)
                end
                Tile.MouseButton1Click:Connect(function()
                    local nextVal = not Self.Flags[flag]
                    Self:SetValue(flag, nextVal)
                    if action.Callback then task.spawn(action.Callback, nextVal) end
                end)
            end
        end

        function Builder:Section(text, iconName)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 36)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local offset = 0
            if iconName then
                local ic = DrawVectorIcon(Row, iconName, 18, "TextAccent", BindTheme)
                ic.Position = UDim2.new(0, 0, 0.5, -10)
                offset = 28
            end

            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, offset, 0, 0)
            Lbl.Size = UDim2.new(1, -offset, 1, -4)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBlack
            Lbl.TextSize = 16
            Lbl.TextTruncate = Enum.TextTruncate.AtEnd
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row
            BindSpacedText(Lbl, text, 1, true, 2)
            BindTheme(Lbl, "TextColor3", "TextPrimary", "PanelBg")

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 1)
            Line.Position = UDim2.new(0, 0, 1, -1)
            Line.BorderSizePixel = 0
            Line.BackgroundTransparency = 0.35
            Line.Parent = Row
            BindTheme(Line, "BackgroundColor3", "Stroke")
        end

        -- =====================================================================
        -- TOGGLE SWITCH / CHECKBOX (BARIS 50px LEGA, FONT 17px JELAS!)
        -- =====================================================================
        function Builder:Toggle(label, flag, default, callback, styleOverride)
            Self.Flags[flag] = (default == true)

            local Row = Instance.new("TextButton")
            Row.Size = UDim2.new(1, 0, 0, 50)
            Row.BorderSizePixel = 0
            Row.Text = ""
            Row.AutoButtonColor = false
            Row.Parent = scrollingPage
            BindTheme(Row, "BackgroundColor3", "RowBg")
            local _, rowStroke = ApplySurfaceStyle(Row, 10, CurrentTheme.Stroke, "Stroke", 0.36)

            local RowPad = Instance.new("UIPadding")
            RowPad.PaddingLeft = UDim.new(0, 14)
            RowPad.PaddingRight = UDim.new(0, 14)
            RowPad.Parent = Row

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -64, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 17
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row

            local hovered = false
            local _, syncSwitch = CreateInteractiveSwitch(Row, flag, function(isOn)
                Title.TextColor3 = isOn and CurrentTheme.TextPrimary or GetReadableTextColor(CurrentTheme.RowBg, CurrentTheme.TextMuted)
            end, styleOverride)

            RegisterThemeUpdater(Row, function()
                syncSwitch(false, hovered)
            end)
            Self:OnValueChanged(flag, function()
                syncSwitch(true, hovered)
            end)

            if HasMousePointer then
                Row.MouseEnter:Connect(function()
                    hovered = true
                    SmoothTween(rowStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.14})
                end)
                Row.MouseLeave:Connect(function()
                    hovered = false
                    SmoothTween(rowStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.36})
                end)
            end
            Row.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                if callback then task.spawn(callback, nextVal) end
            end)
        end

        -- =====================================================================
        -- SLIDER (BARIS 68px LEGA, LABEL 17px, VALUE BADGE 15px KONTRAS!)
        -- =====================================================================
        function Builder:Slider(label, flag, min, max, default, suffix, callback, step)
            suffix = suffix or ""
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if max <= min then max = min + 1 end
            step = tonumber(step) or 1
            Self.Flags[flag] = math.clamp(tonumber(default) or min, min, max)

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 0, 68)
            Container.BorderSizePixel = 0
            Container.Parent = scrollingPage
            BindTheme(Container, "BackgroundColor3", "RowBg")
            local _, boxStroke = ApplySurfaceStyle(Container, 10, CurrentTheme.Stroke, "Stroke", 0.36)

            local BoxPad = Instance.new("UIPadding")
            BoxPad.PaddingLeft = UDim.new(0, 14)
            BoxPad.PaddingRight = UDim.new(0, 14)
            BoxPad.PaddingTop = UDim.new(0, 10)
            BoxPad.PaddingBottom = UDim.new(0, 10)
            BoxPad.Parent = Container

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -80, 0, 24)
            Title.Position = UDim2.new(0, 0, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 17
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Container
            BindTheme(Title, "TextColor3", "TextPrimary", "RowBg")

            local ValPill = Instance.new("Frame")
            ValPill.AutomaticSize = Enum.AutomaticSize.X
            ValPill.Size = UDim2.fromOffset(0, 26)
            ValPill.Position = UDim2.new(1, 0, 0, -1)
            ValPill.AnchorPoint = Vector2.new(1, 0)
            ValPill.BorderSizePixel = 0
            ValPill.Parent = Container
            BindTheme(ValPill, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(ValPill, 7, CurrentTheme.Stroke, "Stroke", 0.30)

            local ValPad = Instance.new("UIPadding")
            ValPad.PaddingLeft = UDim.new(0, 10)
            ValPad.PaddingRight = UDim.new(0, 10)
            ValPad.Parent = ValPill

            local ValTxt = Instance.new("TextLabel")
            ValTxt.AutomaticSize = Enum.AutomaticSize.X
            ValTxt.Size = UDim2.new(0, 0, 1, 0)
            ValTxt.BackgroundTransparency = 1
            ValTxt.Font = Enum.Font.GothamBlack
            ValTxt.TextSize = 15
            ValTxt.Parent = ValPill
            BindTheme(ValTxt, "TextColor3", "TextAccent", "ControlBg")

            local HitArea = Instance.new("TextButton")
            HitArea.Size = UDim2.new(1, -18, 0, 24)
            HitArea.Position = UDim2.new(0, 9, 0, 28)
            HitArea.BackgroundTransparency = 1
            HitArea.Text = ""
            HitArea.AutoButtonColor = false
            HitArea.Parent = Container

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 9)
            Track.Position = UDim2.new(0, 0, 0.5, -4)
            Track.BorderSizePixel = 0
            Track.Parent = HitArea
            BindTheme(Track, "BackgroundColor3", "ControlBg")
            ApplyCornerOnly(Track, 5)

            local function CalcPct(v)
                return math.clamp((v - min) / (max - min), 0, 1)
            end

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(CalcPct(Self.Flags[flag]), 0, 1, 0)
            Fill.BorderSizePixel = 0
            Fill.Parent = Track
            BindTheme(Fill, "BackgroundColor3", "Accent")
            ApplyCornerOnly(Fill, 5)

            local Thumb = Instance.new("Frame")
            Thumb.Size = UDim2.fromOffset(18, 18)
            Thumb.Position = UDim2.new(CalcPct(Self.Flags[flag]), 0, 0.5, 0)
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.BackgroundColor3 = Color3.fromRGB(252, 254, 255)
            Thumb.BorderSizePixel = 0
            Thumb.ZIndex = 3
            Thumb.Parent = Track
            ApplyCornerOnly(Thumb, 9)
            local thumbStroke = Instance.new("UIStroke")
            thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            thumbStroke.Thickness = 2
            thumbStroke.Color = Color3.fromRGB(16, 20, 28)
            thumbStroke.Transparency = 0.25
            thumbStroke.Parent = Thumb

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
            local ancestorScroll = scrollingPage:IsA("ScrollingFrame") and scrollingPage or scrollingPage:FindFirstAncestorOfClass("ScrollingFrame")

            local function UpdateFromInput(input)
                local width = math.max(Track.AbsoluteSize.X, 1)
                local rawPct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / width, 0, 1)
                local rawVal = min + (max - min) * rawPct
                local snapped = math.clamp(math.floor((rawVal / step) + 0.5) * step, min, max)
                if Self.Flags[flag] ~= snapped then
                    SyncVisual(snapped)
                    Self:SetValue(flag, snapped, true)
                    if Self.FlagListeners[flag] then
                        for _, cb in ipairs(Self.FlagListeners[flag]) do
                            if cb ~= SyncVisual then
                                task.spawn(cb, snapped)
                            end
                        end
                    end
                    if callback then task.spawn(callback, snapped) end
                end
            end

            if HasMousePointer then
                Container.MouseEnter:Connect(function()
                    SmoothTween(boxStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.14})
                end)
                Container.MouseLeave:Connect(function()
                    if not sliding then
                        SmoothTween(boxStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.36})
                    end
                end)
            end

            HitArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    if ancestorScroll then ancestorScroll.ScrollingEnabled = false end
                    UpdateFromInput(input)
                end
            end)
            TrackConn(UserInputService.InputEnded:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    sliding = false
                    if ancestorScroll then ancestorScroll.ScrollingEnabled = true end
                    SmoothTween(boxStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.36})
                end
            end))
            TrackConn(UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateFromInput(input)
                end
            end))
        end

        -- Stepper dengan tombol - dan + besar (36x34) dan teks 17px jelas
        function Builder:Stepper(label, flag, default, step, callback)
            step = step or 1
            Self.Flags[flag] = default or 0

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 52)
            Row.BorderSizePixel = 0
            Row.Parent = scrollingPage
            BindTheme(Row, "BackgroundColor3", "RowBg")
            ApplySurfaceStyle(Row, 10, CurrentTheme.Stroke, "Stroke", 0.36)

            local RowPad = Instance.new("UIPadding")
            RowPad.PaddingLeft = UDim.new(0, 14)
            RowPad.PaddingRight = UDim.new(0, 10)
            RowPad.Parent = Row

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -142, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 17
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextPrimary", "RowBg")

            local Controls = Instance.new("Frame")
            Controls.Size = UDim2.fromOffset(132, 36)
            Controls.Position = UDim2.new(1, 0, 0.5, 0)
            Controls.AnchorPoint = Vector2.new(1, 0.5)
            Controls.BackgroundTransparency = 1
            Controls.Parent = Row

            local Minus = Instance.new("TextButton")
            Minus.Size = UDim2.fromOffset(36, 34)
            Minus.Position = UDim2.new(0, 0, 0.5, -17)
            Minus.BorderSizePixel = 0
            Minus.Font = Enum.Font.GothamBlack
            Minus.Text = "-"
            Minus.TextSize = 20
            Minus.AutoButtonColor = false
            Minus.Parent = Controls
            BindTheme(Minus, "BackgroundColor3", "ControlBg")
            BindTheme(Minus, "TextColor3", "TextPrimary", "ControlBg")
            ApplySurfaceStyle(Minus, 8, CurrentTheme.Stroke, "Stroke", 0.24)

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Size = UDim2.fromOffset(54, 34)
            ValLbl.Position = UDim2.new(0.5, -27, 0.5, -17)
            ValLbl.BackgroundTransparency = 1
            ValLbl.Font = Enum.Font.GothamBlack
            ValLbl.Text = tostring(Self.Flags[flag])
            ValLbl.TextSize = 17
            ValLbl.Parent = Controls
            BindTheme(ValLbl, "TextColor3", "TextAccent", "RowBg")

            local Plus = Instance.new("TextButton")
            Plus.Size = UDim2.fromOffset(36, 34)
            Plus.Position = UDim2.new(1, -36, 0.5, -17)
            Plus.BorderSizePixel = 0
            Plus.Font = Enum.Font.GothamBlack
            Plus.Text = "+"
            Plus.TextSize = 20
            Plus.AutoButtonColor = false
            Plus.Parent = Controls
            BindTheme(Plus, "BackgroundColor3", "ControlBg")
            BindTheme(Plus, "TextColor3", "TextPrimary", "ControlBg")
            ApplySurfaceStyle(Plus, 8, CurrentTheme.Stroke, "Stroke", 0.24)

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
        -- DROPDOWN 2-BARIS FULL-WIDTH (LABEL 17px + NILAI 15px ANTI-TERPOTONG!)
        -- =====================================================================
        function Builder:Dropdown(label, flag, options, default, callback)
            options = (type(options) == "table" and #options > 0) and options or {"Default"}
            Self.Flags[flag] = default or options[1]

            local Wrapper = Instance.new("Frame")
            Wrapper.Size = UDim2.new(1, 0, 0, 78)
            Wrapper.AutomaticSize = Enum.AutomaticSize.Y
            Wrapper.BackgroundTransparency = 1
            Wrapper.Parent = scrollingPage

            local WrapLayout = Instance.new("UIListLayout")
            WrapLayout.Padding = UDim.new(0, 8)
            WrapLayout.SortOrder = Enum.SortOrder.LayoutOrder
            WrapLayout.Parent = Wrapper

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 78)
            Row.BorderSizePixel = 0
            Row.LayoutOrder = 1
            Row.Parent = Wrapper
            BindTheme(Row, "BackgroundColor3", "RowBg")
            ApplySurfaceStyle(Row, 10, CurrentTheme.Stroke, "Stroke", 0.36)

            local RowPad = Instance.new("UIPadding")
            RowPad.PaddingLeft = UDim.new(0, 14)
            RowPad.PaddingRight = UDim.new(0, 14)
            RowPad.Parent = Row

            local Title = Instance.new("TextLabel")
            Title.Position = UDim2.new(0, 0, 0, 8)
            Title.Size = UDim2.new(1, 0, 0, 22)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 17
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextPrimary", "RowBg")

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(1, 0, 0, 35)
            DropBtn.Position = UDim2.new(0, 0, 0, 35)
            DropBtn.BorderSizePixel = 0
            DropBtn.Text = ""
            DropBtn.AutoButtonColor = false
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            local _, dropStroke = ApplySurfaceStyle(DropBtn, 8, CurrentTheme.Stroke, "Stroke", 0.22)

            local SelectedTxt = Instance.new("TextLabel")
            SelectedTxt.Position = UDim2.new(0, 12, 0, 0)
            SelectedTxt.Size = UDim2.new(1, -36, 1, 0)
            SelectedTxt.BackgroundTransparency = 1
            SelectedTxt.Font = Enum.Font.GothamBold
            SelectedTxt.Text = tostring(Self.Flags[flag])
            SelectedTxt.TextSize = 15
            SelectedTxt.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedTxt.TextXAlignment = Enum.TextXAlignment.Left
            SelectedTxt.Parent = DropBtn
            BindTheme(SelectedTxt, "TextColor3", "TextAccent", "ControlBg")

            local chev = DrawVectorIcon(DropBtn, "ChevronDown", 15, "TextPrimary", BindTheme)
            chev.Position = UDim2.new(1, -18, 0.5, 0)
            chev.AnchorPoint = Vector2.new(0.5, 0.5)

            local ListHolder = Instance.new("Frame")
            ListHolder.Size = UDim2.new(1, 0, 0, 0)
            ListHolder.BorderSizePixel = 0
            ListHolder.ClipsDescendants = true
            ListHolder.Visible = false
            ListHolder.LayoutOrder = 2
            ListHolder.Parent = Wrapper
            BindTheme(ListHolder, "BackgroundColor3", "PanelBg")
            local _, listStroke = ApplySurfaceStyle(ListHolder, 10, CurrentTheme.Stroke, "Stroke", 0.20)
            listStroke.Enabled = false

            local ListPad = Instance.new("UIPadding")
            ListPad.PaddingTop = UDim.new(0, 8)
            ListPad.PaddingBottom = UDim.new(0, 8)
            ListPad.PaddingLeft = UDim.new(0, 8)
            ListPad.PaddingRight = UDim.new(0, 8)
            ListPad.Parent = ListHolder

            local ListLayout = Instance.new("UIListLayout")
            ListLayout.Padding = UDim.new(0, 6)
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = ListHolder

            local isOpen = false
            local OptionRows = {}
            local targetHeight = (#options * 38) + (math.max(#options - 1, 0) * 6) + 16

            local function RefreshOptionsVisual()
                local onAccFg = GetOnFillColor(CurrentTheme.Accent)
                for _, entry in ipairs(OptionRows) do
                    local isSel = (entry.Value == Self.Flags[flag])
                    entry.Btn.BackgroundTransparency = isSel and 0 or 0.35
                    entry.Btn.BackgroundColor3 = isSel and CurrentTheme.Accent or CurrentTheme.RowBg
                    entry.Lbl.TextColor3 = isSel and onAccFg or CurrentTheme.TextPrimary
                    entry.Check.Visible = isSel
                    entry.RecolorCheck(onAccFg)
                end
                SelectedTxt.Text = tostring(Self.Flags[flag])
            end

            local function SetOpen(state)
                isOpen = state
                SmoothTween(dropStroke, 0.14, {
                    Color = isOpen and CurrentTheme.Accent or CurrentTheme.Stroke,
                    Transparency = isOpen and 0.04 or 0.22
                })
                if isOpen then
                    RefreshOptionsVisual()
                    ListHolder.Visible = true
                    listStroke.Enabled = true
                    SmoothTween(ListHolder, 0.16, {Size = UDim2.new(1, 0, 0, targetHeight)})
                else
                    local tw = SmoothTween(ListHolder, 0.14, {Size = UDim2.new(1, 0, 0, 0)})
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
                OptBtn.Size = UDim2.new(1, 0, 0, 38)
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = ""
                OptBtn.AutoButtonColor = false
                OptBtn.LayoutOrder = i
                OptBtn.Parent = ListHolder
                ApplyCornerOnly(OptBtn, 8)

                local OptLbl = Instance.new("TextLabel")
                OptLbl.Position = UDim2.new(0, 14, 0, 0)
                OptLbl.Size = UDim2.new(1, -44, 1, 0)
                OptLbl.BackgroundTransparency = 1
                OptLbl.Font = Enum.Font.GothamBold
                OptLbl.Text = tostring(opt)
                OptLbl.TextSize = 15
                OptLbl.TextTruncate = Enum.TextTruncate.AtEnd
                OptLbl.TextXAlignment = Enum.TextXAlignment.Left
                OptLbl.Parent = OptBtn

                local optCheck, recolorOptCheck = DrawVectorIcon(OptBtn, "Check", 15, nil, nil)
                optCheck.Position = UDim2.new(1, -20, 0.5, 0)
                optCheck.AnchorPoint = Vector2.new(0.5, 0.5)
                optCheck.Visible = false

                if HasMousePointer then
                    OptBtn.MouseEnter:Connect(function()
                        if Self.Flags[flag] ~= opt then
                            SmoothTween(OptBtn, 0.12, {BackgroundColor3 = CurrentTheme.ControlBg, BackgroundTransparency = 0})
                        end
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        if Self.Flags[flag] ~= opt then
                            SmoothTween(OptBtn, 0.12, {BackgroundColor3 = CurrentTheme.RowBg, BackgroundTransparency = 0.35})
                        end
                    end)
                end
                OptBtn.MouseButton1Click:Connect(function()
                    Self:SetValue(flag, opt)
                    RefreshOptionsVisual()
                    SetOpen(false)
                    if callback then task.spawn(callback, opt) end
                end)

                table.insert(OptionRows, {
                    Value = opt,
                    Btn = OptBtn,
                    Lbl = OptLbl,
                    Check = optCheck,
                    RecolorCheck = recolorOptCheck
                })
            end

            RegisterThemeUpdater(ListHolder, function() RefreshOptionsVisual() end)
            Self:OnValueChanged(flag, function() RefreshOptionsVisual() end)

            DropBtn.MouseButton1Click:Connect(function()
                SetOpen(not isOpen)
            end)
        end

        -- Input 2-Baris Full-Width (Label 17px + InputBox 15px Jelas & Tidak Sempit!)
        function Builder:Input(label, flag, placeholder, default, callback)
            Self.Flags[flag] = default or ""

            local BoxHolder = Instance.new("Frame")
            BoxHolder.Size = UDim2.new(1, 0, 0, 78)
            BoxHolder.BorderSizePixel = 0
            BoxHolder.Parent = scrollingPage
            BindTheme(BoxHolder, "BackgroundColor3", "RowBg")
            ApplySurfaceStyle(BoxHolder, 10, CurrentTheme.Stroke, "Stroke", 0.36)

            local RowPad = Instance.new("UIPadding")
            RowPad.PaddingLeft = UDim.new(0, 14)
            RowPad.PaddingRight = UDim.new(0, 14)
            RowPad.Parent = BoxHolder

            local Title = Instance.new("TextLabel")
            Title.Position = UDim2.new(0, 0, 0, 8)
            Title.Size = UDim2.new(1, 0, 0, 22)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 17
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = BoxHolder
            BindTheme(Title, "TextColor3", "TextPrimary", "RowBg")

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(1, 0, 0, 35)
            InputBox.Position = UDim2.new(0, 0, 0, 35)
            InputBox.BorderSizePixel = 0
            InputBox.Font = Enum.Font.GothamBold
            InputBox.PlaceholderText = placeholder or "Enter value..."
            InputBox.Text = tostring(Self.Flags[flag])
            InputBox.TextSize = 15
            InputBox.TextXAlignment = Enum.TextXAlignment.Left
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = BoxHolder
            BindTheme(InputBox, "BackgroundColor3", "ControlBg")
            BindTheme(InputBox, "TextColor3", "TextPrimary", "ControlBg")
            BindTheme(InputBox, "PlaceholderColor3", "TextMuted", "ControlBg")
            local _, inStroke = ApplySurfaceStyle(InputBox, 8, CurrentTheme.Stroke, "Stroke", 0.22)

            local InPad = Instance.new("UIPadding")
            InPad.PaddingLeft = UDim.new(0, 12)
            InPad.PaddingRight = UDim.new(0, 12)
            InPad.Parent = InputBox

            InputBox.Focused:Connect(function()
                SmoothTween(inStroke, 0.14, {Color = CurrentTheme.Accent, Transparency = 0})
            end)
            InputBox.FocusLost:Connect(function()
                SmoothTween(inStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.22})
                Self:SetValue(flag, InputBox.Text)
                if callback then task.spawn(callback, InputBox.Text) end
            end)
            Self:OnValueChanged(flag, function(v)
                if InputBox.Text ~= tostring(v) then
                    InputBox.Text = tostring(v)
                end
            end)
        end

        function Builder:Keybind(label, flag, defaultKey, callback)
            Self.Flags[flag] = defaultKey

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 52)
            Row.BorderSizePixel = 0
            Row.Parent = scrollingPage
            BindTheme(Row, "BackgroundColor3", "RowBg")
            ApplySurfaceStyle(Row, 10, CurrentTheme.Stroke, "Stroke", 0.36)

            local RowPad = Instance.new("UIPadding")
            RowPad.PaddingLeft = UDim.new(0, 14)
            RowPad.PaddingRight = UDim.new(0, 10)
            RowPad.Parent = Row

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -118, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 17
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindTheme(Title, "TextColor3", "TextPrimary", "RowBg")

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.AutomaticSize = Enum.AutomaticSize.X
            KeyBtn.Size = UDim2.fromOffset(92, 34)
            KeyBtn.Position = UDim2.new(1, 0, 0.5, -17)
            KeyBtn.AnchorPoint = Vector2.new(1, 0)
            KeyBtn.BorderSizePixel = 0
            KeyBtn.Text = ""
            KeyBtn.AutoButtonColor = false
            KeyBtn.Parent = Row
            BindTheme(KeyBtn, "BackgroundColor3", "ControlBg")
            local _, kbStroke = ApplySurfaceStyle(KeyBtn, 8, CurrentTheme.Stroke, "Stroke", 0.22)

            local KbPad = Instance.new("UIPadding")
            KbPad.PaddingLeft = UDim.new(0, 14)
            KbPad.PaddingRight = UDim.new(0, 14)
            KbPad.Parent = KeyBtn

            local function FormatKey(k)
                if typeof(k) == "EnumItem" then return k.Name end
                if type(k) == "string" and k ~= "" then return k end
                return "None"
            end

            local KeyLbl = Instance.new("TextLabel")
            KeyLbl.AutomaticSize = Enum.AutomaticSize.X
            KeyLbl.Size = UDim2.new(0, 0, 1, 0)
            KeyLbl.BackgroundTransparency = 1
            KeyLbl.Font = Enum.Font.GothamBlack
            KeyLbl.TextSize = 15
            KeyLbl.Text = FormatKey(Self.Flags[flag])
            KeyLbl.Parent = KeyBtn
            BindTheme(KeyLbl, "TextColor3", "TextAccent", "ControlBg")

            local listening = false
            local bindConn = nil

            local function StopListening(newKey, updateFlag)
                if bindConn then
                    bindConn:Disconnect()
                    bindConn = nil
                end
                listening = false
                task.defer(function() isBindingKey = false end)
                if updateFlag then
                    KeyLbl.Text = FormatKey(newKey)
                    Self:SetValue(flag, newKey)
                    if callback then task.spawn(callback, newKey) end
                else
                    KeyLbl.Text = FormatKey(Self.Flags[flag])
                end
                SmoothTween(kbStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.22})
            end

            Self:OnValueChanged(flag, function(v)
                if not listening then
                    KeyLbl.Text = FormatKey(v)
                end
            end)

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then
                    StopListening(nil, false)
                    return
                end
                listening = true
                isBindingKey = true
                KeyLbl.Text = "[ Press Key ]"
                SmoothTween(kbStroke, 0.12, {Color = CurrentTheme.Accent, Transparency = 0})

                bindConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local chosen = (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace) and nil or input.KeyCode
                        StopListening(chosen, true)
                    end
                end)
            end)
        end

        -- =====================================================================
        -- ACTION BUTTON (TINGGI 48px, TEKS 17px + KONTRAS GELAP/TERANG OTOMATIS!)
        -- =====================================================================
        function Builder:Button(label, actionBadge, iconName, callback)
            if type(actionBadge) == "function" then
                callback = actionBadge
                actionBadge = nil
            elseif type(iconName) == "function" then
                callback = iconName
                iconName = nil
            end

            local hasBadge = (actionBadge and actionBadge ~= "")
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 48)
            Btn.BorderSizePixel = 0
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.Parent = scrollingPage
            local _, btnStroke = ApplySurfaceStyle(Btn, 10, CurrentTheme.Stroke, false, 0.16)

            local leftOff = 18
            local recolorBtnIcon = nil
            if iconName then
                local ic, recolor = DrawVectorIcon(Btn, iconName, 20, nil, nil)
                ic.Position = UDim2.new(0, 16, 0.5, -10)
                recolorBtnIcon = recolor
                leftOff = 46
            end

            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, leftOff, 0, 0)
            Lbl.Size = UDim2.new(1, hasBadge and -(leftOff + 96) or -(leftOff + 16), 1, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBlack
            Lbl.Text = label
            Lbl.TextSize = 17
            Lbl.TextTruncate = Enum.TextTruncate.AtEnd
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Btn

            local BadgePill = nil
            local BadgeTxt = nil
            if hasBadge then
                BadgePill = Instance.new("Frame")
                BadgePill.AutomaticSize = Enum.AutomaticSize.X
                BadgePill.Size = UDim2.fromOffset(0, 28)
                BadgePill.Position = UDim2.new(1, -14, 0.5, 0)
                BadgePill.AnchorPoint = Vector2.new(1, 0.5)
                BadgePill.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
                BadgePill.BackgroundTransparency = 0.18
                BadgePill.BorderSizePixel = 0
                BadgePill.Parent = Btn
                ApplyCornerOnly(BadgePill, 8)

                local bPad = Instance.new("UIPadding")
                bPad.PaddingLeft = UDim.new(0, 11)
                bPad.PaddingRight = UDim.new(0, 11)
                bPad.Parent = BadgePill

                BadgeTxt = Instance.new("TextLabel")
                BadgeTxt.AutomaticSize = Enum.AutomaticSize.X
                BadgeTxt.Size = UDim2.new(0, 0, 1, 0)
                BadgeTxt.BackgroundTransparency = 1
                BadgeTxt.Font = Enum.Font.GothamBlack
                BadgeTxt.Text = string.upper(tostring(actionBadge))
                BadgeTxt.TextSize = 13
                BadgeTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
                BadgeTxt.Parent = BadgePill
            end

            RegisterThemeUpdater(Btn, function(theme)
                local fg = GetOnFillColor(theme.Accent)
                Btn.BackgroundColor3 = theme.Accent
                btnStroke.Color = theme.Accent
                Lbl.TextColor3 = fg
                if recolorBtnIcon then
                    recolorBtnIcon(fg)
                end
                if BadgePill and BadgeTxt then
                    BadgePill.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
                    BadgeTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)

            if HasMousePointer then
                Btn.MouseEnter:Connect(function()
                    SmoothTween(Btn, 0.12, {BackgroundTransparency = 0.10})
                end)
                Btn.MouseLeave:Connect(function()
                    SmoothTween(Btn, 0.14, {BackgroundTransparency = 0})
                end)
            end
            Btn.MouseButton1Click:Connect(function()
                if callback then task.spawn(callback) end
            end)
        end

        function Builder:TileGrid(label, flag, rows, cols, callback)
            rows = math.clamp(tonumber(rows) or 5, 2, 7)
            cols = math.clamp(tonumber(cols) or 5, 2, 7)
            local centerIdx = math.ceil((rows * cols) / 2)
            local activeTiles = {}
            Self.Flags[flag] = activeTiles

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 38)
            Holder.AutomaticSize = Enum.AutomaticSize.Y
            Holder.BackgroundTransparency = 1
            Holder.Parent = scrollingPage

            local HLayout = Instance.new("UIListLayout")
            HLayout.Padding = UDim.new(0, 10)
            HLayout.SortOrder = Enum.SortOrder.LayoutOrder
            HLayout.Parent = Holder

            if label and label ~= "" then
                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, 0, 0, 24)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = label
                Lbl.TextSize = 16
                Lbl.TextTruncate = Enum.TextTruncate.AtEnd
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Holder
                BindTheme(Lbl, "TextColor3", "TextPrimary", "CardBg")
            end

            local cellPx = 38
            local gapPx = 8
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
                Cell.Font = Enum.Font.GothamBlack
                Cell.TextSize = 16
                Cell.AutoButtonColor = false
                Cell.Parent = GridBox
                local _, cellStroke = ApplySurfaceStyle(Cell, 8, CurrentTheme.Stroke, false, 0.24)

                local function SyncCell(animated)
                    local sel = activeTiles[idx]
                    local bg = isCenter and CurrentTheme.AccentSoft or (sel and CurrentTheme.Accent or CurrentTheme.ControlBg)
                    local st = (isCenter or sel) and CurrentTheme.Accent or CurrentTheme.Stroke
                    Cell.TextColor3 = sel and GetOnFillColor(CurrentTheme.Accent) or CurrentTheme.TextPrimary
                    if animated then
                        SmoothTween(Cell, 0.12, {BackgroundColor3 = bg})
                        SmoothTween(cellStroke, 0.12, {Color = st, Transparency = (sel or isCenter) and 0.05 or 0.24})
                    else
                        Cell.BackgroundColor3 = bg
                        cellStroke.Color = st
                        cellStroke.Transparency = (sel or isCenter) and 0.05 or 0.24
                    end
                end

                RegisterThemeUpdater(Cell, function() SyncCell(false) end)

                if not isCenter then
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
                Row.Size = UDim2.new(1, 0, 0, 40)
                Row.BorderSizePixel = 0
                Row.Parent = scrollingPage
                BindTheme(Row, "BackgroundColor3", "RowBg")
                ApplyCornerOnly(Row, 8)

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(9, 9)
                Dot.Position = UDim2.new(0, 13, 0.5, -4)
                Dot.BorderSizePixel = 0
                Dot.Parent = Row
                BindTheme(Dot, "BackgroundColor3", "Accent")
                ApplyCornerOnly(Dot, 5)

                local EventTxt = Instance.new("TextLabel")
                EventTxt.Position = UDim2.new(0, 30, 0, 0)
                EventTxt.Size = UDim2.new(0.70, -30, 1, 0)
                EventTxt.BackgroundTransparency = 1
                EventTxt.Font = Enum.Font.GothamBold
                EventTxt.Text = item.Text
                EventTxt.TextSize = 15
                EventTxt.TextTruncate = Enum.TextTruncate.AtEnd
                EventTxt.TextXAlignment = Enum.TextXAlignment.Left
                EventTxt.Parent = Row
                BindTheme(EventTxt, "TextColor3", "TextPrimary", "RowBg")

                local TimeTxt = Instance.new("TextLabel")
                TimeTxt.Position = UDim2.new(0.70, 0, 0, 0)
                TimeTxt.Size = UDim2.new(0.30, -14, 1, 0)
                TimeTxt.BackgroundTransparency = 1
                TimeTxt.Font = Enum.Font.GothamBold
                TimeTxt.Text = item.Time
                TimeTxt.TextSize = 14
                TimeTxt.TextXAlignment = Enum.TextXAlignment.Right
                TimeTxt.Parent = Row
                BindTheme(TimeTxt, "TextColor3", "TextAccent", "RowBg")
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
        Pad.PaddingTop = UDim.new(0, 16)
        Pad.PaddingBottom = UDim.new(0, 26)
        Pad.PaddingLeft = UDim.new(0, 16)
        Pad.PaddingRight = UDim.new(0, 20)
        Pad.Parent = Page

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 14)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Page
        return Page
    end

    function Self:Category(catLabel)
        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, -12, 0, 28)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamBlack
        Lbl.TextSize = 13
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = NavScroll
        BindSpacedText(Lbl, " " .. tostring(catLabel or ""), 1, true, 2)
        BindTheme(Lbl, "TextColor3", "TextAccent", "PanelBg")
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
        NavBtn.Size = UDim2.new(1, 0, 0, 48)
        NavBtn.BackgroundTransparency = 1
        NavBtn.BorderSizePixel = 0
        NavBtn.Text = ""
        NavBtn.AutoButtonColor = false
        NavBtn.Parent = NavScroll
        local _, navStroke = ApplySurfaceStyle(NavBtn, 10, CurrentTheme.Stroke, false, 1)

        local recolorTabVec = nil
        local isAssetLogo = (type(logo) == "string" and (string.find(logo, "^https?://") or string.find(logo, "^rbxassetid://")))
        if isAssetLogo then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Position = UDim2.new(0, 14, 0.5, -10)
            IconImg.Size = UDim2.fromOffset(20, 20)
            IconImg.BackgroundTransparency = 1
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.Image = ResolveImage(logo)
            IconImg.Parent = NavBtn
        else
            local vecTabIcon, recolor = DrawVectorIcon(NavBtn, logo or name, 20, nil, nil)
            vecTabIcon.Position = UDim2.new(0, 14, 0.5, -10)
            recolorTabVec = recolor
        end

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Position = UDim2.new(0, 44, 0, 0)
        NameLbl.Size = UDim2.new(1, -52, 1, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = name
        NameLbl.TextSize = 17
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.Parent = NavBtn

        local FeatureObj = {
            Name = name,
            CenterPage = CenterPage,
            RightPage = RightPage,
            NavBtn = NavBtn,
            NameLbl = NameLbl,
            HasCustomRight = false,
            Hovered = false
        }

        local function RefreshTabVisual(animated)
            local isActive = (Self.ActiveFeature == FeatureObj)
            local hovered = FeatureObj.Hovered
            local onAccFg = GetOnFillColor(CurrentTheme.Accent)

            NameLbl.TextColor3 = isActive and onAccFg or (hovered and CurrentTheme.TextPrimary or CurrentTheme.TextMuted)
            if recolorTabVec then
                recolorTabVec(isActive and onAccFg or (hovered and CurrentTheme.TextAccent or CurrentTheme.TextMuted))
            end

            local targetBg = isActive and CurrentTheme.Accent or CurrentTheme.RowBg
            local targetBgTr = isActive and 0 or (hovered and 0.25 or 1)
            local targetStCol = isActive and CurrentTheme.Accent or CurrentTheme.Stroke
            local targetStTr = isActive and 0.05 or (hovered and 0.50 or 1)

            if animated then
                SmoothTween(NavBtn, 0.14, {BackgroundColor3 = targetBg, BackgroundTransparency = targetBgTr})
                SmoothTween(navStroke, 0.14, {Color = targetStCol, Transparency = targetStTr})
            else
                NavBtn.BackgroundColor3 = targetBg
                NavBtn.BackgroundTransparency = targetBgTr
                navStroke.Color = targetStCol
                navStroke.Transparency = targetStTr
            end
        end

        FeatureObj.RefreshVisual = RefreshTabVisual
        RegisterThemeUpdater(NavBtn, function() RefreshTabVisual(false) end)
        table.insert(Self.Features, FeatureObj)

        local function ActivateFeature()
            if Self.ActiveFeature == FeatureObj then return end
            local prev = Self.ActiveFeature
            Self.ActiveFeature = FeatureObj
            if prev then
                prev.CenterPage.Visible = false
                prev.RefreshVisual(true)
            end
            CenterPage.Visible = true
            FeatureObj.RefreshVisual(true)
            SyncRightPanelVisibility()
        end

        if HasMousePointer then
            NavBtn.MouseEnter:Connect(function()
                FeatureObj.Hovered = true
                RefreshTabVisual(true)
            end)
            NavBtn.MouseLeave:Connect(function()
                FeatureObj.Hovered = false
                RefreshTabVisual(true)
            end)
        end
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

    local InstanceProxy = setmetatable(Self, {
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

    if type(globalEnv) == "table" then
        globalEnv.__R8_DV_ACTIVE_UI = InstanceProxy
    end

    return InstanceProxy
end

return ImGui
