--[[
    FRAMEWORK : R&8_DV ImGui Architecture (v5.2 - Full Colourful Gradient & Heavy Display Typography Edition)
    COPYRIGHT : R&8_DV
    ASSET     : Hardcoded GitHub Auto-Fetch + Procedural Lucide Vector Icons (Zero Emoji / Zero [] Bug / Locked 60 FPS)
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

-- // CONTRAST GUARD (PASTIKAN SEMUA TEKS TERANG DI ATAS SURFACE GELAP) //
local function GetReadableTextColor(bgColor, preferredTextColor)
    if not bgColor or not preferredTextColor then
        return preferredTextColor or Color3.fromRGB(246, 249, 255)
    end
    local function lum(c)
        return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    end
    if math.abs(lum(bgColor) - lum(preferredTextColor)) < 0.38 then
        return lum(bgColor) > 0.5 and Color3.fromRGB(16, 18, 24) or Color3.fromRGB(246, 249, 255)
    end
    return preferredTextColor
end

-- =========================================================================
-- 5 TEMA COLOURFUL DUAL-HUE GRADIENT (100% 2-POINT MOBILE OPENGL-ES SAFE)
-- Setiap tema memiliki pasangan warna gradasi hidup (Accent -> AccentEnd,
-- HeroBgStart -> HeroBgEnd, GradTop -> GradBot, ActiveTop -> ActiveBot)
-- =========================================================================
local ThemeOrder = {
    "Blue Night Sky",
    "Violet Amethyst",
    "Orange Sand",
    "Midnight Monokai",
    "Minimalist Monochrome"
}

local Themes = {
    ["Blue Night Sky"] = {
        MainBg      = Color3.fromRGB(8, 12, 22),
        PanelBg     = Color3.fromRGB(12, 18, 32),
        CardBg      = Color3.fromRGB(17, 25, 44),
        CardHoverBg = Color3.fromRGB(24, 36, 62),
        HeroBgStart = Color3.fromRGB(20, 56, 112),
        HeroBgEnd   = Color3.fromRGB(16, 28, 58),
        ControlBg   = Color3.fromRGB(26, 38, 66),
        Accent      = Color3.fromRGB(18, 168, 255),
        AccentEnd   = Color3.fromRGB(78, 104, 255),
        AccentSoft  = Color3.fromRGB(26, 62, 118),
        Stroke      = Color3.fromRGB(42, 64, 104),
        HoverStroke = Color3.fromRGB(96, 198, 255),
        TextPrimary = Color3.fromRGB(248, 252, 255),
        TextMuted   = Color3.fromRGB(176, 198, 232),
        TextAccent  = Color3.fromRGB(112, 216, 255),
        GradTop     = Color3.fromRGB(255, 255, 255),
        GradBot     = Color3.fromRGB(74, 208, 255),
        ActiveTop   = Color3.fromRGB(152, 242, 255),
        ActiveBot   = Color3.fromRGB(68, 168, 255),
        LabelTop    = Color3.fromRGB(252, 254, 255),
        LabelBot    = Color3.fromRGB(194, 222, 255),
        OnAccent    = Color3.fromRGB(255, 255, 255),
        KnobOn      = Color3.fromRGB(255, 255, 255)
    },
    ["Violet Amethyst"] = {
        MainBg      = Color3.fromRGB(11, 9, 20),
        PanelBg     = Color3.fromRGB(17, 14, 30),
        CardBg      = Color3.fromRGB(24, 19, 42),
        CardHoverBg = Color3.fromRGB(34, 27, 58),
        HeroBgStart = Color3.fromRGB(68, 32, 116),
        HeroBgEnd   = Color3.fromRGB(32, 20, 58),
        ControlBg   = Color3.fromRGB(38, 31, 64),
        Accent      = Color3.fromRGB(152, 82, 255),
        AccentEnd   = Color3.fromRGB(244, 78, 166),
        AccentSoft  = Color3.fromRGB(60, 38, 108),
        Stroke      = Color3.fromRGB(62, 48, 98),
        HoverStroke = Color3.fromRGB(214, 136, 255),
        TextPrimary = Color3.fromRGB(252, 248, 255),
        TextMuted   = Color3.fromRGB(194, 180, 228),
        TextAccent  = Color3.fromRGB(228, 158, 255),
        GradTop     = Color3.fromRGB(255, 248, 255),
        GradBot     = Color3.fromRGB(242, 128, 255),
        ActiveTop   = Color3.fromRGB(255, 178, 230),
        ActiveBot   = Color3.fromRGB(182, 124, 255),
        LabelTop    = Color3.fromRGB(254, 250, 255),
        LabelBot    = Color3.fromRGB(218, 196, 255),
        OnAccent    = Color3.fromRGB(255, 255, 255),
        KnobOn      = Color3.fromRGB(255, 255, 255)
    },
    ["Orange Sand"] = {
        MainBg      = Color3.fromRGB(15, 11, 12),
        PanelBg     = Color3.fromRGB(22, 17, 18),
        CardBg      = Color3.fromRGB(30, 23, 24),
        CardHoverBg = Color3.fromRGB(42, 32, 33),
        HeroBgStart = Color3.fromRGB(98, 42, 48),
        HeroBgEnd   = Color3.fromRGB(44, 28, 24),
        ControlBg   = Color3.fromRGB(48, 37, 36),
        Accent      = Color3.fromRGB(255, 94, 122),
        AccentEnd   = Color3.fromRGB(255, 182, 68),
        AccentSoft  = Color3.fromRGB(86, 46, 44),
        Stroke      = Color3.fromRGB(76, 56, 54),
        HoverStroke = Color3.fromRGB(255, 174, 112),
        TextPrimary = Color3.fromRGB(255, 250, 246),
        TextMuted   = Color3.fromRGB(212, 188, 178),
        TextAccent  = Color3.fromRGB(255, 188, 112),
        GradTop     = Color3.fromRGB(255, 252, 242),
        GradBot     = Color3.fromRGB(255, 146, 102),
        ActiveTop   = Color3.fromRGB(255, 218, 118),
        ActiveBot   = Color3.fromRGB(255, 116, 114),
        LabelTop    = Color3.fromRGB(255, 252, 248),
        LabelBot    = Color3.fromRGB(255, 212, 188),
        OnAccent    = Color3.fromRGB(18, 13, 16),
        KnobOn      = Color3.fromRGB(255, 255, 255)
    },
    ["Midnight Monokai"] = {
        MainBg      = Color3.fromRGB(10, 13, 12),
        PanelBg     = Color3.fromRGB(15, 20, 18),
        CardBg      = Color3.fromRGB(21, 28, 25),
        CardHoverBg = Color3.fromRGB(29, 39, 35),
        HeroBgStart = Color3.fromRGB(34, 76, 52),
        HeroBgEnd   = Color3.fromRGB(18, 34, 30),
        ControlBg   = Color3.fromRGB(34, 45, 40),
        Accent      = Color3.fromRGB(164, 242, 60),
        AccentEnd   = Color3.fromRGB(34, 226, 168),
        AccentSoft  = Color3.fromRGB(40, 74, 46),
        Stroke      = Color3.fromRGB(48, 68, 56),
        HoverStroke = Color3.fromRGB(152, 248, 112),
        TextPrimary = Color3.fromRGB(248, 254, 246),
        TextMuted   = Color3.fromRGB(180, 202, 184),
        TextAccent  = Color3.fromRGB(168, 248, 102),
        GradTop     = Color3.fromRGB(250, 255, 242),
        GradBot     = Color3.fromRGB(98, 246, 142),
        ActiveTop   = Color3.fromRGB(198, 255, 96),
        ActiveBot   = Color3.fromRGB(54, 236, 180),
        LabelTop    = Color3.fromRGB(250, 255, 248),
        LabelBot    = Color3.fromRGB(198, 238, 210),
        OnAccent    = Color3.fromRGB(12, 18, 14),
        KnobOn      = Color3.fromRGB(255, 255, 255)
    },
    ["Minimalist Monochrome"] = {
        MainBg      = Color3.fromRGB(10, 11, 14),
        PanelBg     = Color3.fromRGB(15, 17, 22),
        CardBg      = Color3.fromRGB(21, 24, 32),
        CardHoverBg = Color3.fromRGB(29, 33, 44),
        HeroBgStart = Color3.fromRGB(42, 50, 68),
        HeroBgEnd   = Color3.fromRGB(22, 26, 36),
        ControlBg   = Color3.fromRGB(33, 38, 50),
        Accent      = Color3.fromRGB(252, 254, 255),
        AccentEnd   = Color3.fromRGB(178, 206, 246),
        AccentSoft  = Color3.fromRGB(48, 56, 74),
        Stroke      = Color3.fromRGB(48, 55, 70),
        HoverStroke = Color3.fromRGB(176, 194, 226),
        TextPrimary = Color3.fromRGB(250, 252, 255),
        TextMuted   = Color3.fromRGB(184, 196, 218),
        TextAccent  = Color3.fromRGB(230, 240, 255),
        GradTop     = Color3.fromRGB(255, 255, 255),
        GradBot     = Color3.fromRGB(174, 204, 246),
        ActiveTop   = Color3.fromRGB(255, 255, 255),
        ActiveBot   = Color3.fromRGB(190, 216, 252),
        LabelTop    = Color3.fromRGB(252, 254, 255),
        LabelBot    = Color3.fromRGB(204, 218, 240),
        OnAccent    = Color3.fromRGB(14, 16, 22),
        KnobOn      = Color3.fromRGB(14, 16, 22)
    }
}

-- =========================================================================
-- PROCEDURAL LUCIDE VECTOR ICON ENGINE (RINGAN & ANTI-KOTAK [])
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
        if bindThemeFn and themeKey then
            bindThemeFn(f, "BackgroundColor3", themeKey)
        end
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
        if bindThemeFn and themeKey then
            bindThemeFn(s, "Color", themeKey)
        end
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
        Line(sizePx * 0.28, 2, 0.5, 0.5, 0, 1)
        Line(2, sizePx * 0.28, 0.5, 0.5, 0, 1)
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

    local BASE_WIN_W = 1080
    local BASE_WIN_H = 560
    local MAX_WIN_W  = 1160
    local MAX_WIN_H  = 600

    local uiScaleValue = math.clamp(tonumber(config.Scale) or 1, 0.5, 1.5)
    local isMaximized = false

    local Self = {
        Title = config.Title or "DRY CURSED  -  IMGUI",
        BrandTitle = config.BrandTitle or "R&8_DV",
        BrandSubtitle = config.BrandSubtitle or "IMGUI SUITE",
        Copyright = "R&8_DV",
        ThemeName = Themes[config.Theme or ""] and config.Theme or "Blue Night Sky",
        Rounded = (config.Rounded ~= false),
        CheckboxStyle = config.CheckboxStyle or "Modern", -- "Modern" | "Checkbox"
        Text3D = (config.Text3D ~= false),
        LetterSpacing = tonumber(config.LetterSpacing) or 1,
        ReduceEffects = (config.ReduceEffects == true),
        SideCount = (config.Sides == 2) and 2 or 3,
        BgTransparency = math.clamp(tonumber(config.Transparency or config.BgTransparency) or 0.04, 0, 0.65),
        BannerImage = config.BannerImage or "",
        BannerTransparency = config.BannerTransparency or 0.85,
        ToggleKey = config.ToggleKey or Enum.KeyCode.RightShift,
        FocusMode = (config.FocusMode ~= false),
        AutoLoading = (config.AutoLoading == true), -- Default false agar menu langsung terbuka 0ms tanpa delay!
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

    local CurrentTheme = Themes[Self.ThemeName] or Themes["Blue Night Sky"]
    local ResolvedMasterLogo = ResolveImage(MASTER_LOGO_URL)

    local function TrackConn(conn)
        if conn then
            table.insert(Self.Connections, conn)
        end
        return conn
    end

    -- Helper Transisi Smooth & Seragam (Snappy 0.12s Quart Out - Tanpa Jeda / Lag)
    local FAST_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local MED_INFO  = TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    local function FastTween(instance, duration, props)
        if not instance or not instance.Parent then return nil end
        if Self.ReduceEffects or Self.Flags["ReduceEffects"] or Self.Flags["FPSBoost"] then
            for k, v in pairs(props) do
                instance[k] = v
            end
            return nil
        end
        local info = (duration and duration > 0.14) and MED_INFO or FAST_INFO
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

    -- =========================================================================
    -- COLOURFUL 2-POINT VERTEX GRADIENT ENGINE (TEKS + SURFACE + CTA = 60 FPS!)
    -- - Murni 2-keypoint ColorSequence.new(A, B): 100% aman di shader OpenGL ES Mobile & PC!
    -- - Font tebal (GothamBlack / GothamBold) + gradasi warna untuk menekankan hierarki!
    -- =========================================================================
    local function ApplyGradientTitle(label)
        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = label

        RegisterThemeUpdater(label, function(theme)
            theme = theme or CurrentTheme
            if Self.Text3D then
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                grad.Enabled = true
                grad.Color = ColorSequence.new(theme.GradTop, theme.GradBot)
            else
                grad.Enabled = false
                label.TextColor3 = theme.TextPrimary
            end
        end)
    end

    local function ApplyAccentTextGrad(label)
        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = label

        RegisterThemeUpdater(label, function(theme)
            theme = theme or CurrentTheme
            if Self.Text3D then
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                grad.Enabled = true
                grad.Color = ColorSequence.new(theme.ActiveTop, theme.ActiveBot)
            else
                grad.Enabled = false
                label.TextColor3 = theme.TextAccent
            end
        end)
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

    local function BindControlLabel(label)
        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = label

        local active = false
        local function Refresh(theme)
            theme = theme or CurrentTheme
            -- Saat aktif, tebalkan ke GothamBlack & beri gradasi aksen penuh agar maksud fitur langsung menonjol!
            label.Font = active and Enum.Font.GothamBlack or Enum.Font.GothamBold
            if Self.Text3D then
                label.TextColor3 = Color3.fromRGB(255, 255, 255)
                grad.Enabled = true
                if active then
                    grad.Color = ColorSequence.new(theme.ActiveTop, theme.ActiveBot)
                else
                    grad.Color = ColorSequence.new(theme.LabelTop, theme.LabelBot)
                end
            else
                grad.Enabled = false
                label.TextColor3 = active and theme.TextAccent or theme.TextPrimary
            end
        end
        RegisterThemeUpdater(label, Refresh)
        return function(isOn)
            active = (isOn == true)
            Refresh(CurrentTheme)
        end
    end

    local function AttachAccentFillGrad(guiObj, rotation)
        local grad = Instance.new("UIGradient")
        grad.Rotation = rotation or 18
        grad.Enabled = false
        grad.Parent = guiObj

        local enabledState = false
        local function SyncGrad(theme)
            theme = theme or CurrentTheme
            grad.Color = ColorSequence.new(theme.Accent, theme.AccentEnd)
            grad.Enabled = enabledState
            if enabledState then
                guiObj.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        RegisterThemeUpdater(guiObj, SyncGrad)

        return function(on, fallbackColor)
            enabledState = (on == true)
            grad.Color = ColorSequence.new(CurrentTheme.Accent, CurrentTheme.AccentEnd)
            grad.Enabled = enabledState
            if enabledState then
                guiObj.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            elseif fallbackColor then
                guiObj.BackgroundColor3 = fallbackColor
            end
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

    -- Bersihkan instance lama jika script di-eksekusi ulang di executor (PC maupun Mobile)
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
    MinimizeIconBtn.Size = UDim2.fromOffset(56, 56)
    MinimizeIconBtn.Position = UDim2.new(0, 48, 0.5, 0)
    MinimizeIconBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    MinimizeIconBtn.BorderSizePixel = 0
    MinimizeIconBtn.AutoButtonColor = false
    MinimizeIconBtn.Image = ""
    MinimizeIconBtn.Visible = false
    MinimizeIconBtn.ZIndex = 800
    MinimizeIconBtn.Parent = ScreenGui
    BindTheme(MinimizeIconBtn, "BackgroundColor3", "CardBg")

    local _, MinSingleStroke = ApplySurfaceStyle(MinimizeIconBtn, 14, CurrentTheme.Stroke, false, 0.10)
    MinSingleStroke.Thickness = 1.2

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
        local fbVec = DrawVectorIcon(MinimizeIconBtn, "AutoFarm", 26, "Accent", BindTheme)
        fbVec.Position = UDim2.fromScale(0.5, 0.5)
        fbVec.AnchorPoint = Vector2.new(0.5, 0.5)
        fbVec.ZIndex = 803
    end

    if HasMousePointer then
        MinimizeIconBtn.MouseEnter:Connect(function()
            if not Self.IsMinimized then return end
            FastTween(MinimizeIconBtn, 0.12, {BackgroundColor3 = CurrentTheme.CardHoverBg, Size = UDim2.fromOffset(60, 60)})
            FastTween(MinSingleStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0})
        end)
        MinimizeIconBtn.MouseLeave:Connect(function()
            if not Self.IsMinimized then return end
            FastTween(MinimizeIconBtn, 0.12, {BackgroundColor3 = CurrentTheme.CardBg, Size = UDim2.fromOffset(56, 56)})
            FastTween(MinSingleStroke, 0.12, {Color = CurrentTheme.Stroke, Transparency = 0.10})
        end)
    end

    -- =========================================================================
    -- MAIN WINDOW CONTAINER (LEBIH LEBAR 1100x560 & PROPORSIONAL SAAT MAXIMIZE)
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
        local maxScreenRatioX = isMaximized and 0.93 or 0.86
        local maxScreenRatioY = isMaximized and 0.90 or 0.84

        local fitScale = math.min(1, (vp.X * maxScreenRatioX) / targetW, (vp.Y * maxScreenRatioY) / targetH)
        local desired = fitScale * uiScaleValue
        -- Pastikan jendela TIDAK PERNAH meluber keluar layar walau di-Maximize atau UI Scale besar
        local hardCap = math.min((vp.X * 0.94) / targetW, (vp.Y * 0.91) / targetH)
        return math.clamp(math.min(desired, hardCap), 0.34, 1.35)
    end

    local function UpdateResponsiveScale(animated)
        if not Self.IsMinimized then
            local s = ComputeTargetScale()
            if animated then
                FastTween(WindowScale, 0.16, {Scale = s})
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

    -- Custom Banner Layer (Hanya UICorner, Tanpa UIStroke Ganda)
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

    -- 1. LEFT SIDEBAR (22% - LOGO + JUDUL HURUF BESAR SPACED + NAV + PROFILE CARD)
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
    LogoHolder.Size = UDim2.new(1, 0, 0, 144)
    LogoHolder.BackgroundTransparency = 1
    LogoHolder.Parent = LeftSidebar

    -- Aura Gradasi Warna di belakang Logo & Judul Utama
    local CrestGlow = Instance.new("Frame")
    CrestGlow.Size = UDim2.new(1, -20, 0, 126)
    CrestGlow.Position = UDim2.new(0, 10, 0, 8)
    CrestGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CrestGlow.BackgroundTransparency = 0.28
    CrestGlow.BorderSizePixel = 0
    CrestGlow.ZIndex = 0
    CrestGlow.Parent = LogoHolder
    ApplyCornerOnly(CrestGlow, 11)
    local CrestGrad = Instance.new("UIGradient")
    CrestGrad.Rotation = 90
    CrestGrad.Parent = CrestGlow
    RegisterThemeUpdater(CrestGlow, function(theme)
        CrestGrad.Color = ColorSequence.new(theme.HeroBgStart, theme.PanelBg)
    end)

    local BrandLogo = Instance.new("ImageLabel")
    BrandLogo.Size = UDim2.fromOffset(62, 62)
    BrandLogo.Position = UDim2.new(0.5, 0, 0, 41)
    BrandLogo.AnchorPoint = Vector2.new(0.5, 0.5)
    BrandLogo.BackgroundTransparency = 1
    BrandLogo.ScaleType = Enum.ScaleType.Fit
    BrandLogo.Image = ResolvedMasterLogo
    BrandLogo.ZIndex = 2
    BrandLogo.Parent = LogoHolder

    if ResolvedMasterLogo == "" then
        local fallbackCrest = DrawVectorIcon(LogoHolder, "AutoFarm", 40, "Accent", BindTheme)
        fallbackCrest.Position = UDim2.new(0.5, 0, 0, 41)
        fallbackCrest.AnchorPoint = Vector2.new(0.5, 0.5)
        fallbackCrest.ZIndex = 2
    end

    -- Judul Huruf Besar & Tebal di Bawah Logo dengan Colourful Gradient + Letter Spacing!
    local BrandMainTitle = Instance.new("TextLabel")
    BrandMainTitle.Size = UDim2.new(1, -16, 0, 28)
    BrandMainTitle.Position = UDim2.new(0, 8, 0, 77)
    BrandMainTitle.BackgroundTransparency = 1
    BrandMainTitle.Font = Enum.Font.GothamBlack
    BrandMainTitle.TextSize = 22
    BrandMainTitle.TextTruncate = Enum.TextTruncate.AtEnd
    BrandMainTitle.ZIndex = 2
    BrandMainTitle.Parent = LogoHolder
    BindSpacedText(BrandMainTitle, Self.BrandTitle, 1, true, 3)
    ApplyGradientTitle(BrandMainTitle)

    local BrandSubLbl = Instance.new("TextLabel")
    BrandSubLbl.Size = UDim2.new(1, -16, 0, 16)
    BrandSubLbl.Position = UDim2.new(0, 8, 0, 108)
    BrandSubLbl.BackgroundTransparency = 1
    BrandSubLbl.Font = Enum.Font.GothamBlack
    BrandSubLbl.TextSize = 11
    BrandSubLbl.TextTruncate = Enum.TextTruncate.AtEnd
    BrandSubLbl.ZIndex = 2
    BrandSubLbl.Parent = LogoHolder
    BindSpacedText(BrandSubLbl, Self.BrandSubtitle, 1, true, 2)
    ApplyAccentTextGrad(BrandSubLbl)

    local NavDivider = Instance.new("Frame")
    NavDivider.Size = UDim2.new(1, -28, 0, 2)
    NavDivider.Position = UDim2.new(0, 14, 0, 136)
    NavDivider.BorderSizePixel = 0
    NavDivider.BackgroundTransparency = 0.25
    NavDivider.Parent = LeftSidebar
    local setNavDivGrad = AttachAccentFillGrad(NavDivider, 0)
    setNavDivGrad(true)

    local NavScroll = Instance.new("ScrollingFrame")
    NavScroll.Position = UDim2.new(0, 12, 0, 144)
    NavScroll.Size = UDim2.new(1, -24, 1, -218)
    NavScroll.BackgroundTransparency = 1
    NavScroll.BorderSizePixel = 0
    NavScroll.ScrollBarThickness = 2
    NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    NavScroll.Parent = LeftSidebar
    BindTheme(NavScroll, "ScrollBarImageColor3", "Accent")

    local NavPad = Instance.new("UIPadding")
    NavPad.PaddingTop = UDim.new(0, 3)
    NavPad.PaddingLeft = UDim.new(0, 3)
    NavPad.PaddingRight = UDim.new(0, 5)
    NavPad.PaddingBottom = UDim.new(0, 10)
    NavPad.Parent = NavScroll

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Padding = UDim.new(0, 6)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NavLayout.Parent = NavScroll

    -- Sidebar Profile Card (Tidak Mepet Sisi & Teks Jelas)
    local ProfileCard = Instance.new("Frame")
    ProfileCard.Size = UDim2.new(1, -24, 0, 52)
    ProfileCard.Position = UDim2.new(0, 12, 1, -64)
    ProfileCard.BorderSizePixel = 0
    ProfileCard.Parent = LeftSidebar
    BindTheme(ProfileCard, "BackgroundColor3", "CardBg")
    local _, profileStroke = ApplySurfaceStyle(ProfileCard, 10, CurrentTheme.Stroke, "Stroke", 0.25)

    local AvatarCircle = Instance.new("ImageLabel")
    AvatarCircle.Size = UDim2.fromOffset(34, 34)
    AvatarCircle.Position = UDim2.new(0, 10, 0.5, -17)
    AvatarCircle.BorderSizePixel = 0
    AvatarCircle.Parent = ProfileCard
    BindTheme(AvatarCircle, "BackgroundColor3", "ControlBg")
    ApplyCornerOnly(AvatarCircle, 17)
    pcall(function()
        local lp = LocalPlayer or Players.LocalPlayer
        if lp and lp.UserId and lp.UserId > 0 then
            AvatarCircle.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=48&h=48"
        end
    end)

    local PlayerNameLbl = Instance.new("TextLabel")
    PlayerNameLbl.Position = UDim2.new(0, 52, 0, 8)
    PlayerNameLbl.Size = UDim2.new(1, -76, 0, 18)
    PlayerNameLbl.BackgroundTransparency = 1
    PlayerNameLbl.Font = Enum.Font.GothamBlack
    PlayerNameLbl.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Operator"
    PlayerNameLbl.TextSize = 14
    PlayerNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    PlayerNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    PlayerNameLbl.Parent = ProfileCard
    ApplyGradientTitle(PlayerNameLbl)

    local PlayerSubLbl = Instance.new("TextLabel")
    PlayerSubLbl.Position = UDim2.new(0, 52, 0, 27)
    PlayerSubLbl.Size = UDim2.new(1, -76, 0, 16)
    PlayerSubLbl.BackgroundTransparency = 1
    PlayerSubLbl.Font = Enum.Font.GothamBold
    PlayerSubLbl.Text = "Active Session"
    PlayerSubLbl.TextSize = 11
    PlayerSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    PlayerSubLbl.Parent = ProfileCard
    ApplyAccentTextGrad(PlayerSubLbl)

    local OnlineDot = Instance.new("Frame")
    OnlineDot.Size = UDim2.fromOffset(9, 9)
    OnlineDot.Position = UDim2.new(1, -18, 0.5, -4)
    OnlineDot.BorderSizePixel = 0
    OnlineDot.Parent = ProfileCard
    ApplyCornerOnly(OnlineDot, 5)
    local setDotGrad = AttachAccentFillGrad(OnlineDot, 45)
    setDotGrad(true)

    -- 2. TOP IMGUI HEADER BAR (LEGA & JUDUL JELAS DENGAN LETTER SPACING)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Position = UDim2.new(0.22, 6, 0, 14)
    TopBar.Size = UDim2.new(0.78, -20, 0, 48)
    TopBar.BackgroundTransparency = Self.BgTransparency
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainWindow
    BindTheme(TopBar, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(TopBar, 10, CurrentTheme.Stroke, "Stroke", 0.24)

    local TopLogoIcon = Instance.new("ImageLabel")
    TopLogoIcon.Position = UDim2.new(0, 16, 0.5, -12)
    TopLogoIcon.Size = UDim2.fromOffset(24, 24)
    TopLogoIcon.BackgroundTransparency = 1
    TopLogoIcon.ScaleType = Enum.ScaleType.Fit
    TopLogoIcon.Image = ResolvedMasterLogo
    TopLogoIcon.Parent = TopBar

    if ResolvedMasterLogo == "" then
        local vecTop = DrawVectorIcon(TopBar, "Layers", 18, "Accent", BindTheme)
        vecTop.Position = UDim2.new(0, 16, 0.5, -9)
    end

    local TopTitle = Instance.new("TextLabel")
    TopTitle.Position = UDim2.new(0, 48, 0, 0)
    TopTitle.Size = UDim2.new(0.52, 0, 1, 0)
    TopTitle.BackgroundTransparency = 1
    TopTitle.Font = Enum.Font.GothamBlack
    TopTitle.TextSize = 16
    TopTitle.TextTruncate = Enum.TextTruncate.AtEnd
    TopTitle.TextXAlignment = Enum.TextXAlignment.Left
    TopTitle.Parent = TopBar
    BindSpacedText(TopTitle, Self.Title, 0, false, 3)
    ApplyGradientTitle(TopTitle)

    local TopThemeTag = Instance.new("Frame")
    TopThemeTag.AutomaticSize = Enum.AutomaticSize.X
    TopThemeTag.Size = UDim2.fromOffset(0, 28)
    TopThemeTag.Position = UDim2.new(1, -168, 0.5, -14)
    TopThemeTag.AnchorPoint = Vector2.new(1, 0)
    TopThemeTag.BorderSizePixel = 0
    TopThemeTag.Parent = TopBar
    ApplyCornerOnly(TopThemeTag, 14)
    local setTopTagGrad = AttachAccentFillGrad(TopThemeTag, 18)
    setTopTagGrad(true)

    local TagPad = Instance.new("UIPadding")
    TagPad.PaddingLeft = UDim.new(0, 13)
    TagPad.PaddingRight = UDim.new(0, 13)
    TagPad.Parent = TopThemeTag

    local TopThemeTxt = Instance.new("TextLabel")
    TopThemeTxt.AutomaticSize = Enum.AutomaticSize.X
    TopThemeTxt.Size = UDim2.new(0, 0, 1, 0)
    TopThemeTxt.BackgroundTransparency = 1
    TopThemeTxt.Font = Enum.Font.GothamBlack
    TopThemeTxt.Text = FormatSpacedText(string.upper(Self.ThemeName), 1)
    TopThemeTxt.TextSize = 11
    TopThemeTxt.Parent = TopThemeTag
    BindTheme(TopThemeTxt, "TextColor3", "OnAccent")

    local ControlsHolder = Instance.new("Frame")
    ControlsHolder.Position = UDim2.new(1, -156, 0, 0)
    ControlsHolder.Size = UDim2.new(0, 142, 1, 0)
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
        btn.Size = UDim2.fromOffset(30, 30)
        btn.BackgroundTransparency = 0.35
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = ControlsHolder
        BindTheme(btn, "BackgroundColor3", "ControlBg")
        ApplySurfaceStyle(btn, 8, CurrentTheme.Stroke, "Stroke", 0.35)

        local icon, recolorIcon = DrawVectorIcon(btn, vectorType, 15, "TextPrimary", BindTheme)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)

        if HasMousePointer then
            btn.MouseEnter:Connect(function()
                FastTween(btn, 0.10, {BackgroundTransparency = 0.06})
                recolorIcon(CurrentTheme.Accent)
            end)
            btn.MouseLeave:Connect(function()
                FastTween(btn, 0.12, {BackgroundTransparency = 0.35})
                recolorIcon(CurrentTheme.TextPrimary)
            end)
        end
        btn.MouseButton1Click:Connect(onClick)
        return btn
    end

    -- 3. CENTER PANEL (46% di mode 3-sisi, 78% di mode 2-sisi)
    local CenterPanel = Instance.new("Frame")
    CenterPanel.Name = "CenterPanel"
    CenterPanel.Position = UDim2.new(0.22, 6, 0, 72)
    CenterPanel.Size = (Self.SideCount == 3) and UDim2.new(0.46, -10, 1, -86) or UDim2.new(0.78, -20, 1, -86)
    CenterPanel.BackgroundTransparency = Self.BgTransparency
    CenterPanel.BorderSizePixel = 0
    CenterPanel.ClipsDescendants = true
    CenterPanel.Parent = MainWindow
    BindTheme(CenterPanel, "BackgroundColor3", "PanelBg")
    ApplySurfaceStyle(CenterPanel, 12, CurrentTheme.Stroke, "Stroke", 0.24)

    -- 4. RIGHT PANEL (32% LEBIH LEBAR AGAR KONTROL TIDAK MEPET / KEPOTONG!)
    local RightPanel = Instance.new("Frame")
    RightPanel.Name = "RightPanel"
    RightPanel.Position = UDim2.new(0.68, 6, 0, 72)
    RightPanel.Size = UDim2.new(0.32, -20, 1, -86)
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
    -- MINIMIZE & RESTORE INSTAN SMOOTH (TANPA JEDA DELAY 2 TAHAP)
    -- =========================================================================
    function Self:MinimizeToIcon()
        if Self.IsMinimized then return end
        Self.IsMinimized = true
        FocusBlocker.Visible = false

        if Self.ReduceEffects then
            WindowScale.Scale = 0
            MainWindow.Visible = false
            MinimizeIconBtn.Size = UDim2.fromOffset(56, 56)
            MinimizeIconBtn.Visible = true
            return
        end

        MinimizeIconBtn.Size = UDim2.fromOffset(36, 36)
        MinimizeIconBtn.Visible = true
        FastTween(MinimizeIconBtn, 0.15, {Size = UDim2.fromOffset(56, 56)})

        local shrink = TweenService:Create(WindowScale, FAST_INFO, {Scale = 0})
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

        if Self.ReduceEffects then
            WindowScale.Scale = ComputeTargetScale()
            return
        end

        WindowScale.Scale = ComputeTargetScale() * 0.88
        FastTween(WindowScale, 0.15, {Scale = ComputeTargetScale()})
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
            FastTween(MinimizeIconBtn, 0.08, {Size = UDim2.fromOffset(50, 50)})

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    iconDragging = false
                    if movedDist < 6 then
                        Self:RestoreFromIcon()
                    else
                        FastTween(MinimizeIconBtn, 0.12, {Size = UDim2.fromOffset(56, 56)})
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
            FastTween(CenterPanel, 0.15, {Size = UDim2.new(0.46, -10, 1, -86)})
        else
            RightPanel.Visible = false
            FastTween(CenterPanel, 0.15, {Size = UDim2.new(0.78, -20, 1, -86)})
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
        FastTween(MainWindow, 0.16, {Size = UDim2.fromOffset(w, h)})
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
        TopThemeTxt.Text = FormatSpacedText(string.upper(themeName), 1)
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

    -- Preload logo di background tanpa menahan tampilan UI!
    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({BrandLogo, TopLogoIcon, MinEmblemImg})
        end)
    end)

    -- Opsional Loader super cepat (0.45s) jika diminta eksplisit
    function Self:RunInternalLoader(duration)
        duration = duration or 0.45
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
        ApplyGradientTitle(LoadTitle)

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

        TweenService:Create(BarFill, TweenInfo.new(duration * 0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(1, 1)
        }):Play()

        task.delay(duration, function()
            if Loader and Loader.Parent then
                TweenService:Create(Loader, FAST_INFO, {BackgroundTransparency = 1}):Play()
                TweenService:Create(LoadTitle, FAST_INFO, {TextTransparency = 1}):Play()
                TweenService:Create(BarBg, FAST_INFO, {BackgroundTransparency = 1}):Play()
                TweenService:Create(BarFill, FAST_INFO, {BackgroundTransparency = 1}):Play()
                task.wait(0.13)
                if Loader and Loader.Parent then Loader:Destroy() end
            end
        end)
    end

    if Self.AutoLoading then
        Self:RunInternalLoader(0.45)
    end

    -- =========================================================================
    -- WIDGET FACTORY (`center()` & `right()`) - COLOURFUL GRADIENT & HEAVY DISPLAY FONT
    -- =========================================================================
    local function CreateCanvasBuilder(scrollingPage)
        local Builder = {}

        -- Hero Page Header (Gradasi Permukaan + Font Display Extra-Bold 26px + Gradient Pill)
        function Builder:Header(title, subtitle, badgeText)
            local hasSub = (subtitle and subtitle ~= "")
            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Size = UDim2.new(1, 0, 0, hasSub and 74 or 52)
            HeaderFrame.BorderSizePixel = 0
            HeaderFrame.ClipsDescendants = true
            HeaderFrame.Parent = scrollingPage
            BindTheme(HeaderFrame, "BackgroundColor3", "CardBg")
            ApplySurfaceStyle(HeaderFrame, 12, CurrentTheme.Stroke, "Stroke", 0.20)

            local HeroGlow = Instance.new("Frame")
            HeroGlow.Size = UDim2.fromScale(1, 1)
            HeroGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            HeroGlow.BackgroundTransparency = 0.22
            HeroGlow.BorderSizePixel = 0
            HeroGlow.ZIndex = 0
            HeroGlow.Parent = HeaderFrame
            ApplyCornerOnly(HeroGlow, 12)

            local HeroGrad = Instance.new("UIGradient")
            HeroGrad.Rotation = 18
            HeroGrad.Parent = HeroGlow
            RegisterThemeUpdater(HeroGlow, function(theme)
                HeroGrad.Color = ColorSequence.new(theme.HeroBgStart, theme.HeroBgEnd)
            end)

            local AccentBar = Instance.new("Frame")
            AccentBar.Size = UDim2.new(0, 5, 0, hasSub and 48 or 30)
            AccentBar.Position = UDim2.new(0, 12, 0.5, 0)
            AccentBar.AnchorPoint = Vector2.new(0, 0.5)
            AccentBar.BorderSizePixel = 0
            AccentBar.ZIndex = 2
            AccentBar.Parent = HeaderFrame
            ApplyCornerOnly(AccentBar, 3)
            local setBarGrad = AttachAccentFillGrad(AccentBar, 90)
            setBarGrad(true)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 27, 0, hasSub and 10 or 10)
            TitleLbl.Size = UDim2.new(0.68, -27, 0, 32)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBlack
            TitleLbl.TextSize = 26
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.ZIndex = 2
            TitleLbl.Parent = HeaderFrame
            BindSpacedText(TitleLbl, title, 1, true, 2)
            ApplyGradientTitle(TitleLbl)

            if hasSub then
                local SubLbl = Instance.new("TextLabel")
                SubLbl.Position = UDim2.new(0, 27, 0, 44)
                SubLbl.Size = UDim2.new(0.74, -27, 0, 20)
                SubLbl.BackgroundTransparency = 1
                SubLbl.Font = Enum.Font.GothamBold
                SubLbl.Text = subtitle
                SubLbl.TextSize = 13
                SubLbl.TextTruncate = Enum.TextTruncate.AtEnd
                SubLbl.TextXAlignment = Enum.TextXAlignment.Left
                SubLbl.ZIndex = 2
                SubLbl.Parent = HeaderFrame
                BindTheme(SubLbl, "TextColor3", "LabelBot", "CardBg")
            end

            if badgeText and badgeText ~= "" then
                local Pill = Instance.new("Frame")
                Pill.AutomaticSize = Enum.AutomaticSize.X
                Pill.Size = UDim2.fromOffset(0, 28)
                Pill.Position = UDim2.new(1, -14, 0.5, 0)
                Pill.AnchorPoint = Vector2.new(1, 0.5)
                Pill.BorderSizePixel = 0
                Pill.ZIndex = 2
                Pill.Parent = HeaderFrame
                ApplyCornerOnly(Pill, 14)
                local setPillGrad = AttachAccentFillGrad(Pill, 18)
                setPillGrad(true)

                local PillPad = Instance.new("UIPadding")
                PillPad.PaddingLeft = UDim.new(0, 13)
                PillPad.PaddingRight = UDim.new(0, 13)
                PillPad.Parent = Pill

                local PillTxt = Instance.new("TextLabel")
                PillTxt.AutomaticSize = Enum.AutomaticSize.X
                PillTxt.Size = UDim2.new(0, 0, 1, 0)
                PillTxt.BackgroundTransparency = 1
                PillTxt.Font = Enum.Font.GothamBlack
                PillTxt.Text = FormatSpacedText(string.upper(badgeText), 1)
                PillTxt.TextSize = 11
                PillTxt.ZIndex = 3
                PillTxt.Parent = Pill
                BindTheme(PillTxt, "TextColor3", "OnAccent")
            end
        end

        -- Full Colour-Gradient Highlight Banner (Gaya Poster "BIG IDEAS. EVEN BIGGER ENERGY.")
        function Builder:HighlightBanner(eyebrow, headline, subtext, badgeText)
            local Banner = Instance.new("Frame")
            Banner.Size = UDim2.new(1, 0, 0, 84)
            Banner.AutomaticSize = Enum.AutomaticSize.Y
            Banner.BorderSizePixel = 0
            Banner.Parent = scrollingPage
            ApplySurfaceStyle(Banner, 13, Color3.fromRGB(255, 255, 255), false, 0.16)
            local setBanGrad = AttachAccentFillGrad(Banner, 16)
            setBanGrad(true)

            local BanPad = Instance.new("UIPadding")
            BanPad.PaddingTop = UDim.new(0, 15)
            BanPad.PaddingBottom = UDim.new(0, 15)
            BanPad.PaddingLeft = UDim.new(0, 18)
            BanPad.PaddingRight = UDim.new(0, 18)
            BanPad.Parent = Banner

            local BanLayout = Instance.new("UIListLayout")
            BanLayout.Padding = UDim.new(0, 5)
            BanLayout.SortOrder = Enum.SortOrder.LayoutOrder
            BanLayout.Parent = Banner

            local TopMeta = Instance.new("Frame")
            TopMeta.Size = UDim2.new(1, 0, 0, 20)
            TopMeta.BackgroundTransparency = 1
            TopMeta.LayoutOrder = 1
            TopMeta.Parent = Banner

            local EyeLbl = Instance.new("TextLabel")
            EyeLbl.Size = UDim2.new(0.72, 0, 1, 0)
            EyeLbl.BackgroundTransparency = 1
            EyeLbl.Font = Enum.Font.GothamBlack
            EyeLbl.TextSize = 11
            EyeLbl.TextTransparency = 0.12
            EyeLbl.TextTruncate = Enum.TextTruncate.AtEnd
            EyeLbl.TextXAlignment = Enum.TextXAlignment.Left
            EyeLbl.Parent = TopMeta
            BindSpacedText(EyeLbl, eyebrow or "FEATURED", 1, true, 2)
            BindTheme(EyeLbl, "TextColor3", "OnAccent")

            if badgeText and badgeText ~= "" then
                local BadgeFrame = Instance.new("Frame")
                BadgeFrame.AutomaticSize = Enum.AutomaticSize.X
                BadgeFrame.Size = UDim2.fromOffset(0, 20)
                BadgeFrame.Position = UDim2.new(1, 0, 0.5, 0)
                BadgeFrame.AnchorPoint = Vector2.new(1, 0.5)
                BadgeFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
                BadgeFrame.BackgroundTransparency = 0.24
                BadgeFrame.BorderSizePixel = 0
                BadgeFrame.Parent = TopMeta
                ApplyCornerOnly(BadgeFrame, 10)

                local bPad = Instance.new("UIPadding")
                bPad.PaddingLeft = UDim.new(0, 9)
                bPad.PaddingRight = UDim.new(0, 9)
                bPad.Parent = BadgeFrame

                local bTxt = Instance.new("TextLabel")
                bTxt.AutomaticSize = Enum.AutomaticSize.X
                bTxt.Size = UDim2.new(0, 0, 1, 0)
                bTxt.BackgroundTransparency = 1
                bTxt.Font = Enum.Font.GothamBlack
                bTxt.Text = FormatSpacedText(string.upper(badgeText), 1)
                bTxt.TextSize = 10
                bTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
                bTxt.Parent = BadgeFrame
            end

            local HeadLbl = Instance.new("TextLabel")
            HeadLbl.Size = UDim2.new(1, 0, 0, 26)
            HeadLbl.AutomaticSize = Enum.AutomaticSize.Y
            HeadLbl.BackgroundTransparency = 1
            HeadLbl.Font = Enum.Font.GothamBlack
            HeadLbl.Text = string.upper(tostring(headline or ""))
            HeadLbl.TextSize = 22
            HeadLbl.TextWrapped = true
            HeadLbl.TextXAlignment = Enum.TextXAlignment.Left
            HeadLbl.LayoutOrder = 2
            HeadLbl.Parent = Banner
            BindTheme(HeadLbl, "TextColor3", "OnAccent")

            if subtext and subtext ~= "" then
                local SubTxt = Instance.new("TextLabel")
                SubTxt.Size = UDim2.new(1, 0, 0, 18)
                SubTxt.AutomaticSize = Enum.AutomaticSize.Y
                SubTxt.BackgroundTransparency = 1
                SubTxt.Font = Enum.Font.GothamBold
                SubTxt.Text = tostring(subtext)
                SubTxt.TextSize = 13
                SubTxt.TextTransparency = 0.14
                SubTxt.TextWrapped = true
                SubTxt.TextXAlignment = Enum.TextXAlignment.Left
                SubTxt.LayoutOrder = 3
                SubTxt.Parent = Banner
                BindTheme(SubTxt, "TextColor3", "OnAccent")
            end
        end

        -- Circular Palette Swatches (5 Tema Bulat Bergradasi + Selection Ring & Checkmark)
        function Builder:ThemeSwatches(label)
            local SwatchCard = Instance.new("Frame")
            SwatchCard.Size = UDim2.new(1, 0, 0, 78)
            SwatchCard.BorderSizePixel = 0
            SwatchCard.Parent = scrollingPage
            BindTheme(SwatchCard, "BackgroundColor3", "CardBg")
            ApplySurfaceStyle(SwatchCard, 10, CurrentTheme.Stroke, "Stroke", 0.24)

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 14, 0, 9)
            TitleLbl.Size = UDim2.new(0.46, -14, 0, 18)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBlack
            TitleLbl.TextSize = 11
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = SwatchCard
            BindSpacedText(TitleLbl, label or "COLOUR", 1, true, 2)
            ApplyGradientTitle(TitleLbl)

            local ActiveThemeLbl = Instance.new("TextLabel")
            ActiveThemeLbl.Position = UDim2.new(0.46, 0, 0, 9)
            ActiveThemeLbl.Size = UDim2.new(0.54, -14, 0, 18)
            ActiveThemeLbl.BackgroundTransparency = 1
            ActiveThemeLbl.Font = Enum.Font.GothamBlack
            ActiveThemeLbl.Text = Self.ThemeName
            ActiveThemeLbl.TextSize = 12
            ActiveThemeLbl.TextTruncate = Enum.TextTruncate.AtEnd
            ActiveThemeLbl.TextXAlignment = Enum.TextXAlignment.Right
            ActiveThemeLbl.Parent = SwatchCard
            ApplyAccentTextGrad(ActiveThemeLbl)

            local Row = Instance.new("Frame")
            Row.Position = UDim2.new(0, 14, 0, 33)
            Row.Size = UDim2.new(1, -28, 0, 36)
            Row.BackgroundTransparency = 1
            Row.Parent = SwatchCard

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
                InnerCircle.Size = UDim2.fromOffset(26, 26)
                InnerCircle.Position = UDim2.fromScale(0.5, 0.5)
                InnerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
                InnerCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                InnerCircle.BorderSizePixel = 0
                InnerCircle.Parent = RingBtn
                ApplyCornerOnly(InnerCircle, 13)

                local SwGrad = Instance.new("UIGradient")
                SwGrad.Rotation = 35
                SwGrad.Color = ColorSequence.new(tData.Accent, tData.AccentEnd)
                SwGrad.Parent = InnerCircle

                local CheckIcon, recolorCheck = DrawVectorIcon(InnerCircle, "Check", 13, nil, nil)
                CheckIcon.Position = UDim2.fromScale(0.5, 0.5)
                CheckIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                recolorCheck(tData.OnAccent)

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

            RegisterThemeUpdater(SwatchCard, function(theme)
                ActiveThemeLbl.Text = Self.ThemeName
                for _, item in ipairs(SwatchItems) do
                    local isSel = (Self.ThemeName == item.Name)
                    item.Check.Visible = isSel
                    item.Stroke.Color = isSel and theme.TextPrimary or theme.Stroke
                    item.Stroke.Transparency = isSel and 0.04 or 0.55
                end
            end)
        end

        function Builder:StatRow(statsList)
            local count = math.max(#statsList, 1)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 82)
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
                Card.ClipsDescendants = true
                Card.Parent = Row
                BindTheme(Card, "BackgroundColor3", "CardBg")
                local _, statStroke = ApplySurfaceStyle(Card, 11, CurrentTheme.Stroke, "Stroke", 0.24)

                local TopStrip = Instance.new("Frame")
                TopStrip.Size = UDim2.new(1, 0, 0, 2)
                TopStrip.BorderSizePixel = 0
                TopStrip.BackgroundTransparency = 0.12
                TopStrip.Parent = Card
                local setStripGrad = AttachAccentFillGrad(TopStrip, 0)
                setStripGrad(true)

                local IconBox = Instance.new("Frame")
                IconBox.Size = UDim2.fromOffset(40, 40)
                IconBox.Position = UDim2.new(0, 12, 0.5, -19)
                IconBox.BorderSizePixel = 0
                IconBox.Parent = Card
                ApplyCornerOnly(IconBox, 10)
                local setStatIconGrad = AttachAccentFillGrad(IconBox, 35)
                setStatIconGrad(true)

                local vecIcon = DrawVectorIcon(IconBox, item.Icon or "Bolt", 20, "OnAccent", BindTheme)
                vecIcon.Position = UDim2.fromScale(0.5, 0.5)
                vecIcon.AnchorPoint = Vector2.new(0.5, 0.5)

                local Lbl = Instance.new("TextLabel")
                Lbl.Position = UDim2.new(0, 60, 0, 15)
                Lbl.Size = UDim2.new(1, -66, 0, 16)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBlack
                Lbl.Text = FormatSpacedText(string.upper(tostring(item.Label or "")), 1)
                Lbl.TextSize = 10
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Card
                ApplyAccentTextGrad(Lbl)

                local Val = Instance.new("TextLabel")
                Val.Position = UDim2.new(0, 60, 0, 34)
                Val.Size = UDim2.new(1, -66, 0, 26)
                Val.BackgroundTransparency = 1
                Val.Font = Enum.Font.GothamBlack
                Val.Text = tostring(item.Value or "")
                Val.TextSize = 18
                Val.TextTruncate = Enum.TextTruncate.AtEnd
                Val.TextXAlignment = Enum.TextXAlignment.Left
                Val.Parent = Card
                ApplyGradientTitle(Val)
                ValueLabels[i] = Val

                if HasMousePointer then
                    Card.MouseEnter:Connect(function()
                        FastTween(Card, 0.12, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                        FastTween(statStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.06})
                    end)
                    Card.MouseLeave:Connect(function()
                        FastTween(Card, 0.12, {BackgroundColor3 = CurrentTheme.CardBg})
                        FastTween(statStroke, 0.12, {Color = CurrentTheme.Stroke, Transparency = 0.24})
                    end)
                end
            end
            return ValueLabels
        end

        -- =====================================================================
        -- CARD CONTAINER (JUDUL GOTHAMBLACK 18px + BADGE GRADIENT + SWITCH GRADIENT)
        -- =====================================================================
        function Builder:Card(title, rightActionText, iconName, cardOpts)
            if type(rightActionText) == "table" and cardOpts == nil then
                cardOpts = rightActionText
                rightActionText = cardOpts.ActionText
                iconName = iconName or cardOpts.Icon
            end
            cardOpts = cardOpts or {}

            local CardFrame = Instance.new("Frame")
            CardFrame.Size = UDim2.new(1, 0, 0, 44)
            CardFrame.AutomaticSize = Enum.AutomaticSize.Y
            CardFrame.BorderSizePixel = 0
            CardFrame.Parent = scrollingPage
            BindTheme(CardFrame, "BackgroundColor3", "CardBg")
            local _, cardStroke = ApplySurfaceStyle(CardFrame, 11, CurrentTheme.Stroke, "Stroke", 0.24)

            if HasMousePointer then
                CardFrame.MouseEnter:Connect(function()
                    FastTween(CardFrame, 0.12, {BackgroundColor3 = CurrentTheme.CardHoverBg})
                    FastTween(cardStroke, 0.12, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
                end)
                CardFrame.MouseLeave:Connect(function()
                    FastTween(CardFrame, 0.14, {BackgroundColor3 = CurrentTheme.CardBg})
                    FastTween(cardStroke, 0.14, {Color = CurrentTheme.Stroke, Transparency = 0.24})
                end)
            end

            local Pad = Instance.new("UIPadding")
            Pad.PaddingTop = UDim.new(0, 16)
            Pad.PaddingBottom = UDim.new(0, 16)
            Pad.PaddingLeft = UDim.new(0, 18)
            Pad.PaddingRight = UDim.new(0, 18)
            Pad.Parent = CardFrame

            local Layout = Instance.new("UIListLayout")
            Layout.Padding = UDim.new(0, 11)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = CardFrame

            if title and title ~= "" then
                local hasSub = (cardOpts.Subtitle and cardOpts.Subtitle ~= "")
                local TopRow = Instance.new("Frame")
                TopRow.Size = UDim2.new(1, 0, 0, hasSub and 46 or 28)
                TopRow.BackgroundTransparency = 1
                TopRow.Parent = CardFrame

                local leftOffset = 0
                if iconName then
                    local HdrIconBadge = Instance.new("Frame")
                    HdrIconBadge.Size = UDim2.fromOffset(28, 28)
                    HdrIconBadge.Position = UDim2.new(0, 0, 0, 0)
                    HdrIconBadge.BorderSizePixel = 0
                    HdrIconBadge.Parent = TopRow
                    ApplyCornerOnly(HdrIconBadge, 8)
                    local setHdrIconGrad = AttachAccentFillGrad(HdrIconBadge, 35)
                    setHdrIconGrad(true)

                    local hdrIcon = DrawVectorIcon(HdrIconBadge, iconName, 16, "OnAccent", BindTheme)
                    hdrIcon.Position = UDim2.fromScale(0.5, 0.5)
                    hdrIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                    leftOffset = 36
                end

                local TitleTxt = Instance.new("TextLabel")
                TitleTxt.Position = UDim2.new(0, leftOffset, 0, 1)
                TitleTxt.Size = UDim2.new(1, -(leftOffset + 56), 0, 24)
                TitleTxt.BackgroundTransparency = 1
                TitleTxt.Font = Enum.Font.GothamBlack
                TitleTxt.Text = title
                TitleTxt.TextSize = 18
                TitleTxt.TextTruncate = Enum.TextTruncate.AtEnd
                TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
                TitleTxt.Parent = TopRow
                ApplyGradientTitle(TitleTxt)

                if hasSub then
                    local CardSub = Instance.new("TextLabel")
                    CardSub.Position = UDim2.new(0, leftOffset, 0, 26)
                    CardSub.Size = UDim2.new(1, -(leftOffset + 48), 0, 18)
                    CardSub.BackgroundTransparency = 1
                    CardSub.Font = Enum.Font.GothamBold
                    CardSub.Text = cardOpts.Subtitle
                    CardSub.TextSize = 12
                    CardSub.TextTruncate = Enum.TextTruncate.AtEnd
                    CardSub.TextXAlignment = Enum.TextXAlignment.Left
                    CardSub.Parent = TopRow
                    BindTheme(CardSub, "TextColor3", "LabelBot", "CardBg")
                end

                if cardOpts.ToggleFlag then
                    local tFlag = cardOpts.ToggleFlag
                    Self.Flags[tFlag] = (cardOpts.Default == true)

                    local HdrSwitch = Instance.new("TextButton")
                    HdrSwitch.Size = UDim2.fromOffset(42, 22)
                    HdrSwitch.Position = UDim2.new(1, -42, 0, 3)
                    HdrSwitch.BorderSizePixel = 0
                    HdrSwitch.Text = ""
                    HdrSwitch.AutoButtonColor = false
                    HdrSwitch.Parent = TopRow
                    local _, hdrSwStroke = ApplySurfaceStyle(HdrSwitch, 11, CurrentTheme.Stroke, false, 0.24)
                    local setHdrSwGrad = AttachAccentFillGrad(HdrSwitch, 16)

                    local HdrKnob = Instance.new("Frame")
                    HdrKnob.Size = UDim2.fromOffset(16, 16)
                    HdrKnob.AnchorPoint = Vector2.new(0, 0.5)
                    HdrKnob.BorderSizePixel = 0
                    HdrKnob.Parent = HdrSwitch
                    ApplyCornerOnly(HdrKnob, 8)

                    local function SyncHdrSwitch(animated)
                        local on = (Self.Flags[tFlag] == true)
                        setHdrSwGrad(on, CurrentTheme.ControlBg)
                        local knobCol = on and CurrentTheme.KnobOn or Color3.fromRGB(242, 246, 255)
                        local targetPos = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                        hdrSwStroke.Color = on and Color3.fromRGB(255, 255, 255) or CurrentTheme.Stroke
                        hdrSwStroke.Transparency = on and 0.08 or 0.24
                        if animated then
                            FastTween(HdrKnob, 0.12, {Position = targetPos, BackgroundColor3 = knobCol})
                        else
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
                    ActionTxt.Size = UDim2.new(0, 96, 0, 24)
                    ActionTxt.Position = UDim2.new(1, -112, 0, 2)
                    ActionTxt.BackgroundTransparency = 1
                    ActionTxt.Font = Enum.Font.GothamBlack
                    ActionTxt.Text = rightActionText
                    ActionTxt.TextSize = 12
                    ActionTxt.TextXAlignment = Enum.TextXAlignment.Right
                    ActionTxt.Parent = TopRow
                    ApplyAccentTextGrad(ActionTxt)

                    local arr = DrawVectorIcon(TopRow, "ArrowRight", 12, "Accent", BindTheme)
                    arr.Position = UDim2.new(1, -12, 0, 8)
                end

                local Divider = Instance.new("Frame")
                Divider.Size = UDim2.new(1, 0, 0, 2)
                Divider.BorderSizePixel = 0
                Divider.BackgroundTransparency = 0.30
                Divider.Parent = CardFrame
                ApplyCornerOnly(Divider, 1)
                local setDivGrad = AttachAccentFillGrad(Divider, 0)
                setDivGrad(true)
            end

            return CreateCanvasBuilder(CardFrame)
        end

        -- =====================================================================
        -- INTERACTIVE FEATURE HOVER CARD (GRADIENT BADGE & PILL SAAT AKTIF)
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
            CardBtn.Size = UDim2.new(1, 0, 0, desc ~= "" and 74 or 52)
            CardBtn.BorderSizePixel = 0
            CardBtn.Text = ""
            CardBtn.AutoButtonColor = false
            CardBtn.Parent = scrollingPage
            local _, fcStroke = ApplySurfaceStyle(CardBtn, 11, CurrentTheme.Stroke, false, 0.22)

            local IconBadge = Instance.new("Frame")
            IconBadge.Size = UDim2.fromOffset(44, 44)
            IconBadge.Position = UDim2.new(0, 14, 0.5, -22)
            IconBadge.BorderSizePixel = 0
            IconBadge.Parent = CardBtn
            ApplyCornerOnly(IconBadge, 11)
            local setBadgeGrad = AttachAccentFillGrad(IconBadge, 35)

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
                local vec, recolor = DrawVectorIcon(IconBadge, iconName, 21, nil, nil)
                vec.Position = UDim2.fromScale(0.5, 0.5)
                vec.AnchorPoint = Vector2.new(0.5, 0.5)
                recolorVec = recolor
            end

            local TitleLbl = Instance.new("TextLabel")
            TitleLbl.Position = UDim2.new(0, 70, 0, desc ~= "" and 11 or 15)
            TitleLbl.Size = UDim2.new(1, -138, 0, 22)
            TitleLbl.BackgroundTransparency = 1
            TitleLbl.Font = Enum.Font.GothamBlack
            TitleLbl.Text = title
            TitleLbl.TextSize = 16
            TitleLbl.TextTruncate = Enum.TextTruncate.AtEnd
            TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
            TitleLbl.Parent = CardBtn
            ApplyGradientTitle(TitleLbl)

            if desc ~= "" then
                local DescLbl = Instance.new("TextLabel")
                DescLbl.Position = UDim2.new(0, 70, 0, 35)
                DescLbl.Size = UDim2.new(1, -132, 0, 30)
                DescLbl.BackgroundTransparency = 1
                DescLbl.Font = Enum.Font.GothamBold
                DescLbl.Text = desc
                DescLbl.TextSize = 12
                DescLbl.TextWrapped = true
                DescLbl.TextXAlignment = Enum.TextXAlignment.Left
                DescLbl.TextYAlignment = Enum.TextYAlignment.Top
                DescLbl.Parent = CardBtn
                BindTheme(DescLbl, "TextColor3", "LabelBot", "CardBg")
            end

            local StatusPill = Instance.new("Frame")
            StatusPill.AutomaticSize = Enum.AutomaticSize.X
            StatusPill.Size = UDim2.fromOffset(0, 26)
            StatusPill.Position = UDim2.new(1, -14, 0.5, -13)
            StatusPill.AnchorPoint = Vector2.new(1, 0)
            StatusPill.BorderSizePixel = 0
            StatusPill.Parent = CardBtn
            ApplyCornerOnly(StatusPill, 8)
            local setStatusGrad = AttachAccentFillGrad(StatusPill, 18)

            local spPad = Instance.new("UIPadding")
            spPad.PaddingLeft = UDim.new(0, 10)
            spPad.PaddingRight = UDim.new(0, 10)
            spPad.Parent = StatusPill

            local StatusTxt = Instance.new("TextLabel")
            StatusTxt.AutomaticSize = Enum.AutomaticSize.X
            StatusTxt.Size = UDim2.new(0, 0, 1, 0)
            StatusTxt.BackgroundTransparency = 1
            StatusTxt.Font = Enum.Font.GothamBlack
            StatusTxt.TextSize = 11
            StatusTxt.Parent = StatusPill

            local hovered = false
            local function SyncCardState(animated)
                local active = isToggleable and (Self.Flags[flag] == true)
                local bgCol = active and CurrentTheme.HeroBgStart or (hovered and CurrentTheme.CardHoverBg or CurrentTheme.CardBg)
                local stCol = active and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                local stTrans = active and 0.02 or (hovered and 0.08 or 0.24)

                setBadgeGrad(active, CurrentTheme.ControlBg)
                setStatusGrad(active, CurrentTheme.ControlBg)
                StatusTxt.Text = opts.Badge or (isToggleable and (active and "ON" or "OFF") or "OPEN")
                StatusTxt.TextColor3 = active and CurrentTheme.OnAccent or CurrentTheme.TextPrimary

                if recolorVec then
                    recolorVec(active and CurrentTheme.OnAccent or CurrentTheme.Accent)
                end

                if animated then
                    FastTween(CardBtn, 0.12, {BackgroundColor3 = bgCol})
                    FastTween(fcStroke, 0.12, {Color = stCol, Transparency = stTrans})
                else
                    CardBtn.BackgroundColor3 = bgCol
                    fcStroke.Color = stCol
                    fcStroke.Transparency = stTrans
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
            GridHolder.Size = UDim2.new(1, 0, 0, 82)
            GridHolder.AutomaticSize = Enum.AutomaticSize.Y
            GridHolder.BackgroundTransparency = 1
            GridHolder.Parent = scrollingPage

            local Grid = Instance.new("UIGridLayout")
            Grid.CellSize = UDim2.new(1 / cols, -7, 0, 78)
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
                local _, tileStroke = ApplySurfaceStyle(Tile, 10, CurrentTheme.Stroke, false, 0.24)

                local vec, recolorVec = DrawVectorIcon(Tile, action.Icon or "Bolt", 22, nil, nil)
                vec.Position = UDim2.new(0.5, -11, 0, 14)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -10, 0, 20)
                Lbl.Position = UDim2.new(0, 5, 1, -26)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = action.Name
                Lbl.TextSize = 12
                Lbl.TextTruncate = Enum.TextTruncate.AtEnd
                Lbl.Parent = Tile
                local setLblActive = BindControlLabel(Lbl)

                local hovered = false
                local function SyncTile(animated)
                    local on = (Self.Flags[flag] == true)
                    local bg = on and CurrentTheme.HeroBgStart or (hovered and CurrentTheme.CardHoverBg or CurrentTheme.ControlBg)
                    local st = on and CurrentTheme.Accent or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                    local tr = on and 0 or (hovered and 0.08 or 0.24)
                    setLblActive(on)
                    recolorVec(on and CurrentTheme.ActiveTop or CurrentTheme.Accent)
                    if animated then
                        FastTween(Tile, 0.12, {BackgroundColor3 = bg})
                        FastTween(tileStroke, 0.12, {Color = st, Transparency = tr})
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

        -- Section Header Berwarna (Icon + Judul Tebal Gradasi Aksen + Garis Gradasi 2px)
        function Builder:Section(text, iconName)
            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 32)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local offset = 0
            if iconName then
                local ic = DrawVectorIcon(Row, iconName, 18, "Accent", BindTheme)
                ic.Position = UDim2.new(0, 0, 0.5, -10)
                offset = 26
            end

            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, offset, 0, 0)
            Lbl.Size = UDim2.new(1, -offset, 1, -4)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBlack
            Lbl.TextSize = 15
            Lbl.TextTruncate = Enum.TextTruncate.AtEnd
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Row
            BindSpacedText(Lbl, text, 1, true, 2)
            ApplyAccentTextGrad(Lbl)

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, 0, 0, 2)
            Line.Position = UDim2.new(0, 0, 1, -2)
            Line.BorderSizePixel = 0
            Line.BackgroundTransparency = 0.25
            Line.Parent = Row
            ApplyCornerOnly(Line, 1)
            local setLineGrad = AttachAccentFillGrad(Line, 0)
            setLineGrad(true)
        end

        -- =====================================================================
        -- TOGGLE SWITCH / CHECKBOX (GRADASI PENUH SAAT ON + TEKS TEBAL BERWARNA)
        -- =====================================================================
        function Builder:Toggle(label, flag, default, callback, styleOverride)
            Self.Flags[flag] = (default == true)

            local Row = Instance.new("TextButton")
            Row.Size = UDim2.new(1, 0, 0, 34)
            Row.BackgroundTransparency = 1
            Row.BorderSizePixel = 0
            Row.Text = ""
            Row.AutoButtonColor = false
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -56, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            local setTitleActive = BindControlLabel(Title)

            local SwitchBg = Instance.new("Frame")
            SwitchBg.AnchorPoint = Vector2.new(1, 0.5)
            SwitchBg.Position = UDim2.new(1, -2, 0.5, 0)
            SwitchBg.BorderSizePixel = 0
            SwitchBg.Parent = Row
            local swCorner, swStroke = ApplySurfaceStyle(SwitchBg, 11, CurrentTheme.Stroke, false, 0.24)
            local setSwGrad = AttachAccentFillGrad(SwitchBg, 16)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.fromOffset(16, 16)
            Knob.AnchorPoint = Vector2.new(0, 0.5)
            Knob.BorderSizePixel = 0
            Knob.Parent = SwitchBg
            ApplyCornerOnly(Knob, 8)

            local CheckVec, recolorCheck = DrawVectorIcon(SwitchBg, "Check", 14, nil, nil)
            CheckVec.Position = UDim2.fromScale(0.5, 0.5)
            CheckVec.AnchorPoint = Vector2.new(0.5, 0.5)

            local hovered = false
            local function SyncToggle(animated)
                local on = (Self.Flags[flag] == true)
                local mode = string.lower(tostring(styleOverride or Self.CheckboxStyle or "modern"))
                local isBox = (mode == "checkbox" or mode == "box" or mode == "classic")

                setTitleActive(on)
                setSwGrad(on, CurrentTheme.ControlBg)
                local stCol = on and Color3.fromRGB(255, 255, 255) or (hovered and CurrentTheme.HoverStroke or CurrentTheme.Stroke)
                local stTr = on and 0.06 or (hovered and 0.08 or 0.24)

                if isBox then
                    SwitchBg.Size = UDim2.fromOffset(22, 22)
                    swCorner.CornerRadius = UDim.new(0, Self.Rounded and 6 or 0)
                    Knob.Visible = false
                    CheckVec.Visible = on
                    recolorCheck(CurrentTheme.OnAccent)
                else
                    SwitchBg.Size = UDim2.fromOffset(42, 22)
                    swCorner.CornerRadius = UDim.new(0, Self.Rounded and 11 or 0)
                    CheckVec.Visible = false
                    Knob.Visible = true
                    local knobCol = on and CurrentTheme.KnobOn or Color3.fromRGB(242, 246, 255)
                    local targetPos = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
                    if animated then
                        FastTween(Knob, 0.12, {Position = targetPos, BackgroundColor3 = knobCol})
                    else
                        Knob.Position = targetPos
                        Knob.BackgroundColor3 = knobCol
                    end
                end

                if animated then
                    FastTween(swStroke, 0.12, {Color = stCol, Transparency = stTr})
                else
                    swStroke.Color = stCol
                    swStroke.Transparency = stTr
                end
            end

            RegisterThemeUpdater(Row, function() SyncToggle(false) end)
            Self:OnValueChanged(flag, function() SyncToggle(true) end)

            if HasMousePointer then
                Row.MouseEnter:Connect(function()
                    hovered = true
                    SyncToggle(true)
                end)
                Row.MouseLeave:Connect(function()
                    hovered = false
                    SyncToggle(true)
                end)
            end
            Row.MouseButton1Click:Connect(function()
                local nextVal = not Self.Flags[flag]
                Self:SetValue(flag, nextVal)
                if callback then task.spawn(callback, nextVal) end
            end)
        end

        -- =====================================================================
        -- SLIDER (GRADIENT FILL BAR + VALUE BADGE PILL + TEKS TEBAL BERWARNA)
        -- =====================================================================
        function Builder:Slider(label, flag, min, max, default, suffix, callback, step)
            suffix = suffix or ""
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if max <= min then max = min + 1 end
            step = tonumber(step) or 1
            Self.Flags[flag] = math.clamp(tonumber(default) or min, min, max)

            local Container = Instance.new("Frame")
            Container.Size = UDim2.new(1, 0, 0, 46)
            Container.BackgroundTransparency = 1
            Container.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.66, 0, 0, 22)
            Title.Position = UDim2.new(0, 0, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Container
            local setSliderLbl = BindControlLabel(Title)

            local ValPill = Instance.new("Frame")
            ValPill.AutomaticSize = Enum.AutomaticSize.X
            ValPill.Size = UDim2.fromOffset(0, 22)
            ValPill.Position = UDim2.new(1, -2, 0, 0)
            ValPill.AnchorPoint = Vector2.new(1, 0)
            ValPill.BorderSizePixel = 0
            ValPill.Parent = Container
            BindTheme(ValPill, "BackgroundColor3", "AccentSoft")
            ApplySurfaceStyle(ValPill, 6, CurrentTheme.Stroke, "Stroke", 0.32)

            local ValPad = Instance.new("UIPadding")
            ValPad.PaddingLeft = UDim.new(0, 8)
            ValPad.PaddingRight = UDim.new(0, 8)
            ValPad.Parent = ValPill

            local ValTxt = Instance.new("TextLabel")
            ValTxt.AutomaticSize = Enum.AutomaticSize.X
            ValTxt.Size = UDim2.new(0, 0, 1, 0)
            ValTxt.BackgroundTransparency = 1
            ValTxt.Font = Enum.Font.GothamBlack
            ValTxt.TextSize = 12
            ValTxt.Parent = ValPill
            ApplyAccentTextGrad(ValTxt)

            local HitArea = Instance.new("TextButton")
            HitArea.Size = UDim2.new(1, -14, 0, 22)
            HitArea.Position = UDim2.new(0, 7, 0, 24)
            HitArea.BackgroundTransparency = 1
            HitArea.Text = ""
            HitArea.AutoButtonColor = false
            HitArea.Parent = Container

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, 0, 0, 7)
            Track.Position = UDim2.new(0, 0, 0.5, -3)
            Track.BorderSizePixel = 0
            Track.Parent = HitArea
            BindTheme(Track, "BackgroundColor3", "ControlBg")
            local _, trackStroke = ApplySurfaceStyle(Track, 4, CurrentTheme.Stroke, "Stroke", 0.28)

            local function CalcPct(v)
                return math.clamp((v - min) / (max - min), 0, 1)
            end

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(CalcPct(Self.Flags[flag]), 0, 1, 0)
            Fill.BorderSizePixel = 0
            Fill.Parent = Track
            ApplyCornerOnly(Fill, 4)
            local setFillGrad = AttachAccentFillGrad(Fill, 0)
            setFillGrad(true)

            local Thumb = Instance.new("Frame")
            Thumb.Size = UDim2.fromOffset(14, 14)
            Thumb.Position = UDim2.new(CalcPct(Self.Flags[flag]), 0, 0.5, 0)
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.BackgroundColor3 = Color3.fromRGB(252, 254, 255)
            Thumb.BorderSizePixel = 0
            Thumb.ZIndex = 3
            Thumb.Parent = Track
            ApplyCornerOnly(Thumb, 8)
            local thumbStroke = Instance.new("UIStroke")
            thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            thumbStroke.Thickness = 2
            thumbStroke.Parent = Thumb
            BindTheme(thumbStroke, "Color", "Accent")

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
                HitArea.MouseEnter:Connect(function()
                    hovered = true
                    FastTween(Thumb, 0.10, {Size = UDim2.fromOffset(17, 17)})
                    FastTween(trackStroke, 0.10, {Color = CurrentTheme.HoverStroke, Transparency = 0.08})
                end)
                HitArea.MouseLeave:Connect(function()
                    hovered = false
                    if not sliding then
                        FastTween(Thumb, 0.12, {Size = UDim2.fromOffset(14, 14)})
                        FastTween(trackStroke, 0.12, {Color = CurrentTheme.Stroke, Transparency = 0.28})
                    end
                end)
            end

            HitArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    setSliderLbl(true)
                    if ancestorScroll then ancestorScroll.ScrollingEnabled = false end
                    FastTween(Thumb, 0.08, {Size = UDim2.fromOffset(17, 17)})
                    UpdateFromInput(input)
                end
            end)
            TrackConn(UserInputService.InputEnded:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    sliding = false
                    setSliderLbl(false)
                    if ancestorScroll then ancestorScroll.ScrollingEnabled = true end
                    if not hovered then
                        FastTween(Thumb, 0.12, {Size = UDim2.fromOffset(14, 14)})
                        FastTween(trackStroke, 0.12, {Color = CurrentTheme.Stroke, Transparency = 0.28})
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
            Row.Size = UDim2.new(1, 0, 0, 34)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -112, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindControlLabel(Title)

            local Controls = Instance.new("Frame")
            Controls.Size = UDim2.fromOffset(104, 28)
            Controls.Position = UDim2.new(1, -4, 0.5, 0)
            Controls.AnchorPoint = Vector2.new(1, 0.5)
            Controls.BorderSizePixel = 0
            Controls.Parent = Row
            BindTheme(Controls, "BackgroundColor3", "ControlBg")
            ApplySurfaceStyle(Controls, 8, CurrentTheme.Stroke, "Stroke", 0.24)

            local Minus = Instance.new("TextButton")
            Minus.Size = UDim2.new(0, 28, 1, 0)
            Minus.BackgroundTransparency = 1
            Minus.Font = Enum.Font.GothamBlack
            Minus.Text = "-"
            Minus.TextSize = 17
            Minus.AutoButtonColor = false
            Minus.Parent = Controls
            BindTheme(Minus, "TextColor3", "TextPrimary", "ControlBg")

            local ValLbl = Instance.new("TextLabel")
            ValLbl.Size = UDim2.new(1, -56, 1, 0)
            ValLbl.Position = UDim2.new(0, 28, 0, 0)
            ValLbl.BackgroundTransparency = 1
            ValLbl.Font = Enum.Font.GothamBlack
            ValLbl.Text = tostring(Self.Flags[flag])
            ValLbl.TextSize = 14
            ValLbl.Parent = Controls
            ApplyAccentTextGrad(ValLbl)

            local Plus = Instance.new("TextButton")
            Plus.Size = UDim2.new(0, 28, 1, 0)
            Plus.Position = UDim2.new(1, -28, 0, 0)
            Plus.BackgroundTransparency = 1
            Plus.Font = Enum.Font.GothamBlack
            Plus.Text = "+"
            Plus.TextSize = 17
            Plus.AutoButtonColor = false
            Plus.Parent = Controls
            BindTheme(Plus, "TextColor3", "TextPrimary", "ControlBg")

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
        -- INTERACTIVE EXPANDABLE DROPDOWN (TEKS TEBAL BERWARNA & OPSI GRADIENT)
        -- =====================================================================
        function Builder:Dropdown(label, flag, options, default, callback)
            options = (type(options) == "table" and #options > 0) and options or {"Default"}
            Self.Flags[flag] = default or options[1]

            local Wrapper = Instance.new("Frame")
            Wrapper.Size = UDim2.new(1, 0, 0, 34)
            Wrapper.AutomaticSize = Enum.AutomaticSize.Y
            Wrapper.BackgroundTransparency = 1
            Wrapper.Parent = scrollingPage

            local WrapLayout = Instance.new("UIListLayout")
            WrapLayout.Padding = UDim.new(0, 6)
            WrapLayout.SortOrder = Enum.SortOrder.LayoutOrder
            WrapLayout.Parent = Wrapper

            local Row = Instance.new("Frame")
            Row.Size = UDim2.new(1, 0, 0, 34)
            Row.BackgroundTransparency = 1
            Row.LayoutOrder = 1
            Row.Parent = Wrapper

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.42, -6, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindControlLabel(Title)

            local DropBtn = Instance.new("TextButton")
            DropBtn.Size = UDim2.new(0.58, -2, 0, 30)
            DropBtn.Position = UDim2.new(0.42, 0, 0.5, -15)
            DropBtn.BorderSizePixel = 0
            DropBtn.Text = ""
            DropBtn.AutoButtonColor = false
            DropBtn.Parent = Row
            BindTheme(DropBtn, "BackgroundColor3", "ControlBg")
            local _, dropStroke = ApplySurfaceStyle(DropBtn, 8, CurrentTheme.Stroke, "Stroke", 0.24)

            local SelectedTxt = Instance.new("TextLabel")
            SelectedTxt.Position = UDim2.new(0, 11, 0, 0)
            SelectedTxt.Size = UDim2.new(1, -30, 1, 0)
            SelectedTxt.BackgroundTransparency = 1
            SelectedTxt.Font = Enum.Font.GothamBlack
            SelectedTxt.Text = tostring(Self.Flags[flag])
            SelectedTxt.TextSize = 12
            SelectedTxt.TextTruncate = Enum.TextTruncate.AtEnd
            SelectedTxt.TextXAlignment = Enum.TextXAlignment.Left
            SelectedTxt.Parent = DropBtn
            ApplyAccentTextGrad(SelectedTxt)

            local chev = DrawVectorIcon(DropBtn, "ChevronDown", 12, "Accent", BindTheme)
            chev.Position = UDim2.new(1, -15, 0.5, 0)
            chev.AnchorPoint = Vector2.new(0.5, 0.5)

            local ListHolder = Instance.new("Frame")
            ListHolder.Size = UDim2.new(1, -2, 0, 0)
            ListHolder.BorderSizePixel = 0
            ListHolder.ClipsDescendants = true
            ListHolder.Visible = false
            ListHolder.LayoutOrder = 2
            ListHolder.Parent = Wrapper
            BindTheme(ListHolder, "BackgroundColor3", "PanelBg")
            local _, listStroke = ApplySurfaceStyle(ListHolder, 8, CurrentTheme.Stroke, "Stroke", 0.20)
            listStroke.Enabled = false

            local ListPad = Instance.new("UIPadding")
            ListPad.PaddingTop = UDim.new(0, 5)
            ListPad.PaddingBottom = UDim.new(0, 5)
            ListPad.PaddingLeft = UDim.new(0, 5)
            ListPad.PaddingRight = UDim.new(0, 5)
            ListPad.Parent = ListHolder

            local ListLayout = Instance.new("UIListLayout")
            ListLayout.Padding = UDim.new(0, 3)
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = ListHolder

            local isOpen = false
            local OptionRows = {}
            local targetHeight = (#options * 29) + 10

            local function RefreshOptionsVisual()
                for _, entry in ipairs(OptionRows) do
                    local isSel = (entry.Value == Self.Flags[flag])
                    entry.Dot.Visible = isSel
                    entry.SetActive(isSel)
                    entry.Btn.BackgroundTransparency = isSel and 0.08 or 1
                    entry.Btn.BackgroundColor3 = isSel and CurrentTheme.HeroBgStart or CurrentTheme.ControlBg
                end
                SelectedTxt.Text = tostring(Self.Flags[flag])
            end

            local function SetOpen(state)
                isOpen = state
                FastTween(chev, 0.12, {Rotation = isOpen and 180 or 0})
                FastTween(dropStroke, 0.12, {
                    Color = isOpen and CurrentTheme.Accent or CurrentTheme.Stroke,
                    Transparency = isOpen and 0.04 or 0.24
                })
                if isOpen then
                    RefreshOptionsVisual()
                    ListHolder.Visible = true
                    listStroke.Enabled = true
                    FastTween(ListHolder, 0.14, {Size = UDim2.new(1, -2, 0, targetHeight)})
                else
                    local tw = FastTween(ListHolder, 0.12, {Size = UDim2.new(1, -2, 0, 0)})
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
                OptBtn.Size = UDim2.new(1, 0, 0, 26)
                OptBtn.BackgroundTransparency = 1
                OptBtn.BorderSizePixel = 0
                OptBtn.Text = ""
                OptBtn.AutoButtonColor = false
                OptBtn.LayoutOrder = i
                OptBtn.Parent = ListHolder
                ApplyCornerOnly(OptBtn, 6)

                local OptDot = Instance.new("Frame")
                OptDot.Size = UDim2.fromOffset(7, 7)
                OptDot.Position = UDim2.new(0, 9, 0.5, -3)
                OptDot.BorderSizePixel = 0
                OptDot.Visible = false
                OptDot.Parent = OptBtn
                ApplyCornerOnly(OptDot, 4)
                local setOptDotGrad = AttachAccentFillGrad(OptDot, 45)
                setOptDotGrad(true)

                local OptLbl = Instance.new("TextLabel")
                OptLbl.Position = UDim2.new(0, 22, 0, 0)
                OptLbl.Size = UDim2.new(1, -28, 1, 0)
                OptLbl.BackgroundTransparency = 1
                OptLbl.Font = Enum.Font.GothamBold
                OptLbl.Text = tostring(opt)
                OptLbl.TextSize = 13
                OptLbl.TextTruncate = Enum.TextTruncate.AtEnd
                OptLbl.TextXAlignment = Enum.TextXAlignment.Left
                OptLbl.Parent = OptBtn
                local setOptAct = BindControlLabel(OptLbl)

                if HasMousePointer then
                    OptBtn.MouseEnter:Connect(function()
                        if Self.Flags[flag] ~= opt then
                            OptBtn.BackgroundColor3 = CurrentTheme.ControlBg
                            FastTween(OptBtn, 0.10, {BackgroundTransparency = 0.30})
                        end
                    end)
                    OptBtn.MouseLeave:Connect(function()
                        if Self.Flags[flag] ~= opt then
                            FastTween(OptBtn, 0.10, {BackgroundTransparency = 1})
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
                    Dot = OptDot,
                    SetActive = setOptAct
                })
            end

            RegisterThemeUpdater(ListHolder, function() RefreshOptionsVisual() end)
            Self:OnValueChanged(flag, function() RefreshOptionsVisual() end)

            DropBtn.MouseButton1Click:Connect(function()
                SetOpen(not isOpen)
            end)
        end

        function Builder:Input(label, flag, placeholder, default, callback)
            Self.Flags[flag] = default or ""

            local BoxHolder = Instance.new("Frame")
            BoxHolder.Size = UDim2.new(1, 0, 0, 34)
            BoxHolder.BackgroundTransparency = 1
            BoxHolder.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.42, -6, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = BoxHolder
            BindControlLabel(Title)

            local InputBox = Instance.new("TextBox")
            InputBox.Size = UDim2.new(0.58, -2, 0, 30)
            InputBox.Position = UDim2.new(0.42, 0, 0.5, -15)
            InputBox.BorderSizePixel = 0
            InputBox.Font = Enum.Font.GothamBold
            InputBox.PlaceholderText = placeholder or "Enter value..."
            InputBox.Text = tostring(Self.Flags[flag])
            InputBox.TextSize = 13
            InputBox.TextXAlignment = Enum.TextXAlignment.Left
            InputBox.ClearTextOnFocus = false
            InputBox.Parent = BoxHolder
            BindTheme(InputBox, "BackgroundColor3", "ControlBg")
            BindTheme(InputBox, "TextColor3", "TextPrimary", "ControlBg")
            BindTheme(InputBox, "PlaceholderColor3", "TextMuted", "ControlBg")
            local _, inStroke = ApplySurfaceStyle(InputBox, 8, CurrentTheme.Stroke, "Stroke", 0.24)

            local InPad = Instance.new("UIPadding")
            InPad.PaddingLeft = UDim.new(0, 10)
            InPad.PaddingRight = UDim.new(0, 10)
            InPad.Parent = InputBox

            InputBox.Focused:Connect(function()
                FastTween(inStroke, 0.12, {Color = CurrentTheme.Accent, Transparency = 0})
            end)
            InputBox.FocusLost:Connect(function()
                FastTween(inStroke, 0.12, {Color = CurrentTheme.Stroke, Transparency = 0.24})
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
            Row.Size = UDim2.new(1, 0, 0, 34)
            Row.BackgroundTransparency = 1
            Row.Parent = scrollingPage

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(0.58, -6, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.Text = label
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Row
            BindControlLabel(Title)

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.AutomaticSize = Enum.AutomaticSize.X
            KeyBtn.Size = UDim2.fromOffset(68, 28)
            KeyBtn.Position = UDim2.new(1, -2, 0.5, -14)
            KeyBtn.AnchorPoint = Vector2.new(1, 0)
            KeyBtn.BorderSizePixel = 0
            KeyBtn.Text = ""
            KeyBtn.AutoButtonColor = false
            KeyBtn.Parent = Row
            BindTheme(KeyBtn, "BackgroundColor3", "AccentSoft")
            local _, kbStroke = ApplySurfaceStyle(KeyBtn, 8, CurrentTheme.Stroke, "Stroke", 0.24)

            local KbPad = Instance.new("UIPadding")
            KbPad.PaddingLeft = UDim.new(0, 12)
            KbPad.PaddingRight = UDim.new(0, 12)
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
            KeyLbl.TextSize = 12
            KeyLbl.Text = FormatKey(Self.Flags[flag])
            KeyLbl.Parent = KeyBtn
            ApplyAccentTextGrad(KeyLbl)

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
                FastTween(kbStroke, 0.12, {Color = CurrentTheme.Stroke, Transparency = 0.24})
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
                KeyLbl.Text = "[ ... ]"
                FastTween(kbStroke, 0.10, {Color = CurrentTheme.Accent, Transparency = 0})

                bindConn = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local chosen = (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace) and nil or input.KeyCode
                        StopListening(chosen, true)
                    end
                end)
            end)
        end

        -- =====================================================================
        -- FULL COLOUR-GRADIENT CTA BUTTON (GAYA CORAL POP / ELECTRIC LAGOON CTA)
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
            Btn.Size = UDim2.new(1, 0, 0, 40)
            Btn.BorderSizePixel = 0
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.Parent = scrollingPage
            local _, btnStroke = ApplySurfaceStyle(Btn, 10, Color3.fromRGB(255, 255, 255), false, 0.18)
            local setBtnGrad = AttachAccentFillGrad(Btn, 16)
            setBtnGrad(true)

            local leftOff = 16
            if iconName then
                local ic = DrawVectorIcon(Btn, iconName, 18, "OnAccent", BindTheme)
                ic.Position = UDim2.new(0, 14, 0.5, -9)
                leftOff = 40
            end

            local Lbl = Instance.new("TextLabel")
            Lbl.Position = UDim2.new(0, leftOff, 0, 0)
            Lbl.Size = UDim2.new(0.70, -leftOff, 1, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamBlack
            Lbl.Text = label
            Lbl.TextSize = 15
            Lbl.TextTruncate = Enum.TextTruncate.AtEnd
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Btn
            BindTheme(Lbl, "TextColor3", "OnAccent")

            if actionBadge and actionBadge ~= "" then
                local BadgePill = Instance.new("Frame")
                BadgePill.AutomaticSize = Enum.AutomaticSize.X
                BadgePill.Size = UDim2.fromOffset(0, 24)
                BadgePill.Position = UDim2.new(1, -12, 0.5, 0)
                BadgePill.AnchorPoint = Vector2.new(1, 0.5)
                BadgePill.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
                BadgePill.BackgroundTransparency = 0.26
                BadgePill.BorderSizePixel = 0
                BadgePill.Parent = Btn
                ApplyCornerOnly(BadgePill, 7)

                local bPad = Instance.new("UIPadding")
                bPad.PaddingLeft = UDim.new(0, 9)
                bPad.PaddingRight = UDim.new(0, 9)
                bPad.Parent = BadgePill

                local Badge = Instance.new("TextLabel")
                Badge.AutomaticSize = Enum.AutomaticSize.X
                Badge.Size = UDim2.new(0, 0, 1, 0)
                Badge.BackgroundTransparency = 1
                Badge.Font = Enum.Font.GothamBlack
                Badge.Text = FormatSpacedText(string.upper(actionBadge), 1)
                Badge.TextSize = 11
                Badge.TextColor3 = Color3.fromRGB(255, 255, 255)
                Badge.Parent = BadgePill
            end

            if HasMousePointer then
                Btn.MouseEnter:Connect(function()
                    FastTween(Btn, 0.10, {BackgroundTransparency = 0.10})
                    FastTween(btnStroke, 0.10, {Transparency = 0})
                end)
                Btn.MouseLeave:Connect(function()
                    FastTween(Btn, 0.12, {BackgroundTransparency = 0})
                    FastTween(btnStroke, 0.12, {Transparency = 0.18})
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
                Lbl.Size = UDim2.new(1, 0, 0, 20)
                Lbl.BackgroundTransparency = 1
                Lbl.Font = Enum.Font.GothamBold
                Lbl.Text = label
                Lbl.TextSize = 13
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.Parent = Holder
                BindControlLabel(Lbl)
            end

            local cellPx = 32
            local gapPx = 6
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
                Cell.TextSize = 12
                Cell.AutoButtonColor = false
                Cell.Parent = GridBox
                local _, cellStroke = ApplySurfaceStyle(Cell, 7, CurrentTheme.Stroke, false, 0.24)
                local setCellGrad = AttachAccentFillGrad(Cell, 35)

                local function SyncCell(animated)
                    local sel = activeTiles[idx]
                    setCellGrad(sel, isCenter and CurrentTheme.HeroBgStart or CurrentTheme.ControlBg)
                    local st = sel and Color3.fromRGB(255, 255, 255) or (isCenter and CurrentTheme.Accent or CurrentTheme.Stroke)
                    Cell.TextColor3 = sel and CurrentTheme.OnAccent or CurrentTheme.TextPrimary
                    if animated then
                        FastTween(cellStroke, 0.10, {Color = st, Transparency = (sel or isCenter) and 0.04 or 0.24})
                    else
                        cellStroke.Color = st
                        cellStroke.Transparency = (sel or isCenter) and 0.04 or 0.24
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
                Row.Size = UDim2.new(1, 0, 0, 28)
                Row.BackgroundTransparency = 1
                Row.BorderSizePixel = 0
                Row.Parent = scrollingPage

                local Dot = Instance.new("Frame")
                Dot.Size = UDim2.fromOffset(8, 8)
                Dot.Position = UDim2.new(0, 4, 0.5, -4)
                Dot.BorderSizePixel = 0
                Dot.Parent = Row
                ApplyCornerOnly(Dot, 4)
                local setActDotGrad = AttachAccentFillGrad(Dot, 45)
                setActDotGrad(true)

                local EventTxt = Instance.new("TextLabel")
                EventTxt.Position = UDim2.new(0, 20, 0, 0)
                EventTxt.Size = UDim2.new(0.70, -20, 1, 0)
                EventTxt.BackgroundTransparency = 1
                EventTxt.Font = Enum.Font.GothamBold
                EventTxt.Text = item.Text
                EventTxt.TextSize = 13
                EventTxt.TextTruncate = Enum.TextTruncate.AtEnd
                EventTxt.TextXAlignment = Enum.TextXAlignment.Left
                EventTxt.Parent = Row
                BindControlLabel(EventTxt)

                local TimeTxt = Instance.new("TextLabel")
                TimeTxt.Position = UDim2.new(0.70, 0, 0, 0)
                TimeTxt.Size = UDim2.new(0.30, -4, 1, 0)
                TimeTxt.BackgroundTransparency = 1
                TimeTxt.Font = Enum.Font.GothamBlack
                TimeTxt.Text = item.Time
                TimeTxt.TextSize = 12
                TimeTxt.TextXAlignment = Enum.TextXAlignment.Right
                TimeTxt.Parent = Row
                ApplyAccentTextGrad(TimeTxt)
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
        Page.ScrollBarThickness = 2
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Visible = false
        Page.Parent = parent
        BindTheme(Page, "ScrollBarImageColor3", "Accent")

        local Pad = Instance.new("UIPadding")
        Pad.PaddingTop = UDim.new(0, 18)
        Pad.PaddingBottom = UDim.new(0, 24)
        Pad.PaddingLeft = UDim.new(0, 18)
        Pad.PaddingRight = UDim.new(0, 22)
        Pad.Parent = Page

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0, 12)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = Page
        return Page
    end

    function Self:Category(catLabel)
        local Lbl = Instance.new("TextLabel")
        Lbl.Size = UDim2.new(1, -12, 0, 24)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamBlack
        Lbl.TextSize = 11
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.Parent = NavScroll
        BindSpacedText(Lbl, " " .. tostring(catLabel or ""), 1, true, 2)
        ApplyAccentTextGrad(Lbl)
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
        NavBtn.Size = UDim2.new(1, 0, 0, 42)
        NavBtn.BackgroundTransparency = 1
        NavBtn.BorderSizePixel = 0
        NavBtn.Text = ""
        NavBtn.AutoButtonColor = false
        NavBtn.Parent = NavScroll
        local _, navStroke = ApplySurfaceStyle(NavBtn, 10, CurrentTheme.Stroke, false, 1)
        local setNavGrad = AttachAccentFillGrad(NavBtn, 16)

        local recolorTabVec = nil
        local isAssetLogo = (type(logo) == "string" and (string.find(logo, "^https?://") or string.find(logo, "^rbxassetid://")))
        if isAssetLogo then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Position = UDim2.new(0, 14, 0.5, -9)
            IconImg.Size = UDim2.fromOffset(18, 18)
            IconImg.BackgroundTransparency = 1
            IconImg.ScaleType = Enum.ScaleType.Fit
            IconImg.Image = ResolveImage(logo)
            IconImg.Parent = NavBtn
        else
            local vecTabIcon, recolor = DrawVectorIcon(NavBtn, logo or name, 18, nil, nil)
            vecTabIcon.Position = UDim2.new(0, 14, 0.5, -9)
            recolorTabVec = recolor
        end

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Position = UDim2.new(0, 42, 0, 0)
        NameLbl.Size = UDim2.new(1, -50, 1, 0)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.Text = name
        NameLbl.TextSize = 15
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.Parent = NavBtn

        local TabGrad = Instance.new("UIGradient")
        TabGrad.Rotation = 90
        TabGrad.Enabled = false
        TabGrad.Parent = NameLbl

        local ActivePill = Instance.new("Frame")
        ActivePill.Size = UDim2.fromOffset(4, 20)
        ActivePill.Position = UDim2.new(0, 4, 0.5, 0)
        ActivePill.AnchorPoint = Vector2.new(0, 0.5)
        ActivePill.BorderSizePixel = 0
        ActivePill.Visible = false
        ActivePill.Parent = NavBtn
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

            setNavGrad(isActive, CurrentTheme.ControlBg)
            NameLbl.Font = isActive and Enum.Font.GothamBlack or Enum.Font.GothamBold

            if isActive then
                TabGrad.Enabled = false
                NameLbl.TextColor3 = CurrentTheme.OnAccent
                ActivePill.BackgroundColor3 = CurrentTheme.OnAccent
            elseif Self.Text3D then
                NameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                TabGrad.Color = ColorSequence.new(CurrentTheme.LabelTop, CurrentTheme.LabelBot)
                TabGrad.Enabled = true
            else
                TabGrad.Enabled = false
                NameLbl.TextColor3 = hovered and CurrentTheme.TextPrimary or CurrentTheme.TextMuted
            end

            if recolorTabVec then
                recolorTabVec(isActive and CurrentTheme.OnAccent or (hovered and CurrentTheme.ActiveTop or CurrentTheme.Accent))
            end

            local targetBgTr = isActive and 0.04 or (hovered and 0.48 or 1)
            local targetStCol = isActive and Color3.fromRGB(255, 255, 255) or CurrentTheme.Stroke
            local targetStTr = isActive and 0.16 or (hovered and 0.58 or 1)
            ActivePill.Visible = isActive

            if animated then
                FastTween(NavBtn, 0.12, {BackgroundTransparency = targetBgTr})
                FastTween(navStroke, 0.12, {Color = targetStCol, Transparency = targetStTr})
            else
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
