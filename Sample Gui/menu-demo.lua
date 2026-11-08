-- 1. Panggil Framework R&8_DV via GitHub RAW
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

-- Patch langsung sumber script agar font tidak ketebalan (GothamBlack/Bold -> GothamMedium/Gotham)
rawScript = rawScript
    :gsub("Enum%.Font%.GothamBlack", "Enum.Font.GothamMedium")
    :gsub("Enum%.Font%.GothamBold", "Enum.Font.Gotham")
    :gsub("Enum%.Font%.SourceSansBold", "Enum.Font.Gotham")
    :gsub("Enum%.Font%.ArialBold", "Enum.Font.Gotham")
    :gsub("Enum%.FontWeight%.Black", "Enum.FontWeight.Medium")
    :gsub("Enum%.FontWeight%.Heavy", "Enum.FontWeight.Medium")
    :gsub("Enum%.FontWeight%.Bold", "Enum.FontWeight.Regular")

local ImGui = loadstring(rawScript)()

-- =========================================================================
-- DAFTAR TEMA & PALET KONTRAS TINGGI (ENAK DI MATA DENGAN TEKS PUTIH)
-- =========================================================================
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Snapshot GUI sebelum inisialisasi untuk mendeteksi ScreenGui milik R&8_DV
local function getGuiContainers()
    local list = {}
    pcall(function()
        if type(gethui) == "function" then
            local h = gethui()
            if h then table.insert(list, h) end
        end
    end)
    pcall(function() table.insert(list, CoreGui) end)
    pcall(function()
        if LocalPlayer then
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then table.insert(list, pg) end
        end
    end)
    return list
end

local existingGuis = {}
for _, parent in ipairs(getGuiContainers()) do
    for _, ch in ipairs(parent:GetChildren()) do
        existingGuis[ch] = true
    end
end

-- 2. Inisialisasi Jendela (LetterSpacing = 0 agar teks tidak renggang/tebal)
local UI = ImGui({
    Title = "CHAT SPAMMER (SERVER)",
    BrandTitle = "R&8_DV",
    BrandSubtitle = "SPAM SUITE",
    Theme = "Minimalist Monochrome",
    CheckboxStyle = "Modern",
    LetterSpacing = 0,
    AutoLoading = false
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

-- Palet warna kustom dengan kontras gelap pekat + aksen tajam + teks 100% putih
local CustomPalettes = {
    ["Cyberpunk Neon"] = {
        Bg     = Color3.fromRGB(10, 13, 22),
        Panel  = Color3.fromRGB(15, 20, 34),
        Card   = Color3.fromRGB(21, 28, 46),
        Elem   = Color3.fromRGB(30, 40, 64),
        Stroke = Color3.fromRGB(0, 210, 255),
        Accent = Color3.fromRGB(0, 230, 255),
    },
    ["Crimson Obsidian"] = {
        Bg     = Color3.fromRGB(12, 9, 12),
        Panel  = Color3.fromRGB(20, 13, 18),
        Card   = Color3.fromRGB(28, 18, 25),
        Elem   = Color3.fromRGB(42, 26, 36),
        Stroke = Color3.fromRGB(220, 38, 78),
        Accent = Color3.fromRGB(255, 46, 99),
    },
    ["Emerald Matrix"] = {
        Bg     = Color3.fromRGB(8, 15, 12),
        Panel  = Color3.fromRGB(13, 24, 19),
        Card   = Color3.fromRGB(18, 34, 27),
        Elem   = Color3.fromRGB(26, 48, 38),
        Stroke = Color3.fromRGB(16, 185, 129),
        Accent = Color3.fromRGB(52, 211, 153),
    },
    ["Tokyo Night"] = {
        Bg     = Color3.fromRGB(15, 17, 29),
        Panel  = Color3.fromRGB(22, 25, 43),
        Card   = Color3.fromRGB(30, 35, 58),
        Elem   = Color3.fromRGB(41, 48, 79),
        Stroke = Color3.fromRGB(122, 162, 247),
        Accent = Color3.fromRGB(137, 180, 250),
    },
    ["Dracula Pro"] = {
        Bg     = Color3.fromRGB(16, 14, 24),
        Panel  = Color3.fromRGB(24, 21, 36),
        Card   = Color3.fromRGB(34, 30, 50),
        Elem   = Color3.fromRGB(48, 42, 70),
        Stroke = Color3.fromRGB(255, 121, 198),
        Accent = Color3.fromRGB(189, 147, 249),
    },
    ["Nordic Frost"] = {
        Bg     = Color3.fromRGB(16, 21, 30),
        Panel  = Color3.fromRGB(23, 30, 43),
        Card   = Color3.fromRGB(32, 41, 58),
        Elem   = Color3.fromRGB(45, 57, 79),
        Stroke = Color3.fromRGB(56, 189, 248),
        Accent = Color3.fromRGB(125, 211, 252),
    },
    ["Royal Gold Dark"] = {
        Bg     = Color3.fromRGB(13, 12, 10),
        Panel  = Color3.fromRGB(22, 20, 16),
        Card   = Color3.fromRGB(32, 28, 22),
        Elem   = Color3.fromRGB(46, 40, 31),
        Stroke = Color3.fromRGB(245, 158, 11),
        Accent = Color3.fromRGB(251, 191, 36),
    },
    ["Catppuccin Mocha"] = {
        Bg     = Color3.fromRGB(17, 17, 27),
        Panel  = Color3.fromRGB(24, 24, 37),
        Card   = Color3.fromRGB(30, 30, 46),
        Elem   = Color3.fromRGB(49, 50, 68),
        Stroke = Color3.fromRGB(203, 166, 247),
        Accent = Color3.fromRGB(180, 190, 254),
    },
}

local BaseThemes = UI.GetThemes and UI:GetThemes() or {
    "Minimalist Monochrome",
    "Blue Night Sky",
    "Violet Amethyst",
    "Orange Sand",
    "Midnight Monokai"
}

local ThemeChoices = {}
local seenTheme = {}
for _, t in ipairs(BaseThemes) do
    seenTheme[t] = true
    table.insert(ThemeChoices, t)
end
for _, customName in ipairs({
    "Cyberpunk Neon",
    "Crimson Obsidian",
    "Emerald Matrix",
    "Tokyo Night",
    "Dracula Pro",
    "Nordic Frost",
    "Royal Gold Dark",
    "Catppuccin Mocha"
}) do
    if not seenTheme[customName] then
        table.insert(ThemeChoices, customName)
    end
end

-- =========================================================================
-- STYLER OTOMATIS: TEKS PUTIH BERSIH, FONT TIDAK TEBAL & TEMA KONTRAS
-- =========================================================================
local WHITE_TEXT = Color3.fromRGB(255, 255, 255)
local PLACEHOLDER_WHITE = Color3.fromRGB(205, 212, 225)
local TargetScreenGui = nil
local ActiveCustomPalette = nil
local StyledInstances = setmetatable({}, { __mode = "k" })

local function findImGuiScreenGui()
    if TargetScreenGui and TargetScreenGui.Parent then return TargetScreenGui end
    for _, parent in ipairs(getGuiContainers()) do
        for _, ch in ipairs(parent:GetChildren()) do
            if ch:IsA("ScreenGui") and not existingGuis[ch] then
                TargetScreenGui = ch
                return ch
            end
        end
    end
    for _, parent in ipairs(getGuiContainers()) do
        for _, ch in ipairs(parent:GetChildren()) do
            if ch:IsA("ScreenGui") then
                for _, d in ipairs(ch:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton")) and
                       (tostring(d.Text):find("R&8_DV", 1, true) or tostring(d.Text):find("SPAM", 1, true)) then
                        TargetScreenGui = ch
                        return ch
                    end
                end
            end
        end
    end
    return nil
end

local function styleTextAndFont(inst)
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        pcall(function()
            -- Paksa warna tulisan jadi putih bersih
            if inst.TextColor3 ~= WHITE_TEXT then
                inst.TextColor3 = WHITE_TEXT
            end
            -- Hilangkan outline/stroke pada huruf agar tidak terlihat ketebalan
            inst.TextStrokeTransparency = 1
            if inst:IsA("TextBox") then
                inst.PlaceholderColor3 = PLACEHOLDER_WHITE
            end
            -- Tipiskan font yang terlalu tebal
            local f = inst.Font
            if f == Enum.Font.GothamBlack or f == Enum.Font.SourceSansBold or f == Enum.Font.ArialBold then
                inst.Font = Enum.Font.GothamMedium
            elseif f == Enum.Font.GothamBold then
                inst.Font = (inst.TextSize <= 13) and Enum.Font.Gotham or Enum.Font.GothamMedium
            end
        end)

        if not StyledInstances[inst] then
            StyledInstances[inst] = true
            inst:GetPropertyChangedSignal("TextColor3"):Connect(function()
                if inst.TextColor3 ~= WHITE_TEXT then
                    pcall(function() inst.TextColor3 = WHITE_TEXT end)
                end
            end)
            inst:GetPropertyChangedSignal("Font"):Connect(function()
                local f = inst.Font
                if f == Enum.Font.GothamBlack or f == Enum.Font.GothamBold then
                    pcall(function()
                        inst.Font = (inst.TextSize <= 13) and Enum.Font.Gotham or Enum.Font.GothamMedium
                    end)
                end
            end)
        end
    elseif inst:IsA("UIStroke") and inst.Parent and
           (inst.Parent:IsA("TextLabel") or inst.Parent:IsA("TextButton") or inst.Parent:IsA("TextBox")) then
        -- Jika UIStroke menempel pada teks (Contextual), matikan agar huruf tidak tebal
        pcall(function()
            if inst.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual then
                inst.Thickness = 0
                inst.Transparency = 1
            end
        end)
    end
end

local function applyPaletteToGui(pal)
    local gui = findImGuiScreenGui()
    if not gui or not pal then return end
    for _, d in ipairs(gui:GetDescendants()) do
        styleTextAndFont(d)
        if d:IsA("Frame") or d:IsA("ScrollingFrame") or d:IsA("CanvasGroup") then
            if d.BackgroundTransparency < 0.95 then
                local sz = d.AbsoluteSize
                if sz.X >= 420 and sz.Y >= 280 then
                    d.BackgroundColor3 = pal.Bg
                elseif sz.X >= 140 and sz.Y >= 240 then
                    d.BackgroundColor3 = pal.Panel
                elseif sz.Y >= 45 then
                    d.BackgroundColor3 = pal.Card
                else
                    d.BackgroundColor3 = pal.Elem
                end
            end
            if d:IsA("ScrollingFrame") then
                pcall(function() d.ScrollBarImageColor3 = pal.Accent end)
            end
        elseif d:IsA("TextButton") or d:IsA("TextBox") then
            if d.BackgroundTransparency < 0.95 then
                local c = d.BackgroundColor3
                -- Jika tombol memiliki warna aksen terang, gunakan warna Accent palet
                if math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B) > 0.25 then
                    d.BackgroundColor3 = pal.Accent
                else
                    d.BackgroundColor3 = pal.Elem
                end
            end
        elseif d:IsA("UIStroke") and d.Parent and not (d.Parent:IsA("TextLabel") or d.Parent:IsA("TextBox")) then
            if d.Transparency < 0.95 and d.Thickness > 0 then
                d.Color = pal.Stroke
            end
        elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
            if d.Image ~= "" and d.ImageColor3 ~= Color3.fromRGB(255, 255, 255) then
                d.ImageColor3 = pal.Accent
            end
        end
    end
end

local function refreshAllGuiStyling()
    local gui = findImGuiScreenGui()
    if not gui then return end
    for _, d in ipairs(gui:GetDescendants()) do
        styleTextAndFont(d)
    end
    if ActiveCustomPalette then
        applyPaletteToGui(ActiveCustomPalette)
    end
end

local function applyThemeSelection(selectedTheme)
    local customPal = CustomPalettes[selectedTheme]
    if customPal then
        ActiveCustomPalette = customPal
        pcall(function() UI:SetTheme("Minimalist Monochrome") end)
        task.defer(function()
            applyPaletteToGui(customPal)
        end)
    else
        ActiveCustomPalette = nil
        pcall(function() UI:SetTheme(selectedTheme) end)
        task.defer(refreshAllGuiStyling)
    end
end

-- =========================================================================
-- LOGIKA SPAM
-- =========================================================================
local MAX_CHAT = 120 -- batas karakter chat game

local Spam = {
    Running = false,
    Sent = 0,
    Index = 0,
    Thread = nil,
    Button = nil,
}

local function getValue(flag, fallback)
    local ok, v = pcall(function() return UI:GetValue(flag) end)
    if ok and v ~= nil then return v end
    return fallback
end

local function findWorldChannel()
    local wc = TextChatService:FindFirstChild("WorldChannels")
    if not wc then return nil end

    for _, ch in ipairs(wc:GetChildren()) do
        if ch:IsA("TextChannel") and ch:FindFirstChild(LocalPlayer.Name) then
            return ch
        end
    end
    for _, ch in ipairs(wc:GetChildren()) do
        if ch:IsA("TextChannel") then return ch end
    end
    return nil
end

local function sendChat(msg)
    msg = string.sub(msg, 1, MAX_CHAT)
    local ch = findWorldChannel()
    if not ch then return false end
    local ok, err = pcall(function() ch:SendAsync(msg) end)
    if not ok then warn("[R&8_DV] SendAsync error: " .. tostring(err)) end
    return ok
end

local function buildMessage()
    local raw = tostring(getValue("SpamMessage", "Hello!"))
    local lines = {}
    for line in string.gmatch(raw, "[^|]+") do
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed ~= "" then table.insert(lines, trimmed) end
    end
    if #lines == 0 then lines = { "Hello!" } end

    local mode = getValue("SpamMode", "Sequential")
    local msg
    if mode == "Random" then
        msg = lines[math.random(1, #lines)]
    else
        Spam.Index = (Spam.Index % #lines) + 1
        msg = lines[Spam.Index]
    end

    if getValue("AutoPrefix", false) then
        msg = "`" .. tostring(math.random(1, 9)) .. msg
    end

    return string.sub(msg, 1, MAX_CHAT)
end

local function setButtonText(running)
    if not Spam.Button then return end
    local text = running and "STOP" or "START"
    pcall(function()
        if Spam.Button.SetText then
            Spam.Button:SetText(text)
        elseif Spam.Button.SetLabel then
            Spam.Button:SetLabel(text)
        end
    end)
    task.defer(refreshAllGuiStyling)
end

local function stopSpam()
    Spam.Running = false
    setButtonText(false)
    print("[R&8_DV] Spam STOP | Total terkirim:", Spam.Sent)
end

local function startSpam()
    if Spam.Running then return end
    Spam.Running = true
    setButtonText(true)
    print("[R&8_DV] Spam START (server)")

    Spam.Thread = task.spawn(function()
        while Spam.Running do
            if sendChat(buildMessage()) then
                Spam.Sent += 1
            else
                warn("[R&8_DV] Gagal kirim: WorldChannel tidak ditemukan, pastikan sudah masuk world")
            end
            local delay = tonumber(getValue("SpamDelay", 3)) or 3
            task.wait(math.max(delay, 0.1))
        end
    end)
end

local function toggleSpam()
    if Spam.Running then stopSpam() else startSpam() end
end

-- =========================================================================
-- HELPER: TOMBOL TOGGLE (START / STOP dalam satu tombol)
-- =========================================================================
local function setToggleText(btn, running)
    if not btn then return end
    local text = running and "STOP" or "START"
    pcall(function()
        if btn.SetText then
            btn:SetText(text)
        elseif btn.SetLabel then
            btn:SetLabel(text)
        end
    end)
    task.defer(refreshAllGuiStyling)
end

local function newToggle(startFn, stopFn)
    local T = { Running = false, Button = nil }
    function T.Set(on)
        if on == T.Running then return end
        if on then
            local ok, res = pcall(startFn)
            if not ok then
                warn("[R&8_DV] Gagal START: " .. tostring(res))
                return
            end
            if res == false then return end
            T.Running = true
        else
            local ok, res = pcall(stopFn)
            if not ok then warn("[R&8_DV] Error saat STOP: " .. tostring(res)) end
            T.Running = false
        end
        setToggleText(T.Button, T.Running)
    end
    function T.Toggle() T.Set(not T.Running) end
    return T
end

local function vnTrim(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

-- =========================================================================
-- LOGIKA SET VISUAL NAME - 100% CLIENT
-- =========================================================================
local VN = {
    Orig = nil,
    Want = {},
    Toggle = nil,
}
local VN_ATTRS = { "Nick", "WornTitle", "DiscordColor", "HasLegend", "HideLegendUntil" }

local VN_COLOR_LIST = {
    "(tidak diubah)", "Putih", "Merah", "Hijau", "Biru", "Kuning",
    "Oranye", "Pink", "Ungu", "Cyan", "Emas", "Abu-abu"
}
local VN_COLORS = {
    ["Putih"]   = Color3.fromRGB(255, 255, 255),
    ["Merah"]   = Color3.fromRGB(255, 39, 29),
    ["Hijau"]   = Color3.fromRGB(73, 252, 0),
    ["Biru"]    = Color3.fromRGB(25, 185, 255),
    ["Kuning"]  = Color3.fromRGB(255, 238, 125),
    ["Oranye"]  = Color3.fromRGB(255, 148, 69),
    ["Pink"]    = Color3.fromRGB(255, 143, 243),
    ["Ungu"]    = Color3.fromRGB(187, 0, 255),
    ["Cyan"]    = Color3.fromRGB(80, 255, 255),
    ["Emas"]    = Color3.fromRGB(255, 193, 94),
    ["Abu-abu"] = Color3.fromRGB(158, 158, 158),
}

local VN_TITLE_LIST = {
    "(tidak diubah)", "Tanpa Title", "Content Creator", "Sponsor", "Supporter",
    "Patron", "Benefactor", "Royal", "Dr.", "Legendary"
}
local VN_TITLE_ID = {
    ["Tanpa Title"]     = "none",
    ["Content Creator"] = "cc",
    ["Sponsor"]         = "sponsor",
    ["Supporter"]       = "supporter",
    ["Patron"]          = "patron",
    ["Benefactor"]      = "benefactor",
    ["Royal"]           = "royal",
    ["Dr."]             = "dr",
    ["Legendary"]       = "legend",
}

local function vnReadColor()
    local hex = vnTrim(getValue("VN_Hex", ""))
    hex = hex:gsub("^#", "")
    if #hex == 6 and hex:match("^%x+$") then
        return Color3.fromRGB(
            tonumber(hex:sub(1, 2), 16),
            tonumber(hex:sub(3, 4), 16),
            tonumber(hex:sub(5, 6), 16)
        )
    end
    local pick = getValue("VN_ColorPreset", "(tidak diubah)")
    return VN_COLORS[pick]
end

local function vnApplyClient()
    if not LocalPlayer then return false end

    if not VN.Orig then
        VN.Orig = {}
        for _, a in ipairs(VN_ATTRS) do
            VN.Orig[a] = { v = LocalPlayer:GetAttribute(a) }
        end
    end

    local want = {}

    local name = vnTrim(getValue("VN_Name", ""))
    if not getValue("VN_AllowCodes", false) then
        name = name:gsub("`", "")
    end
    name = string.sub(name, 1, 30)
    if name ~= "" then want.Nick = name end

    local color = vnReadColor()
    if color then want.DiscordColor = color end

    local titleId = VN_TITLE_ID[getValue("VN_Title", "(tidak diubah)")]
    if titleId == "none" then
        want.WornTitle = "none"
        want.HasLegend = false
    elseif titleId == "legend" then
        want.WornTitle = "none"
        want.HasLegend = true
        want.HideLegendUntil = 0
    elseif titleId then
        want.WornTitle = titleId
        want.HasLegend = false
    end

    for attr, val in pairs(want) do
        if attr ~= "Nick" then
            pcall(function() LocalPlayer:SetAttribute(attr, val) end)
        end
    end

    local finalNick = want.Nick
    if finalNick == nil then finalNick = VN.Orig.Nick.v end
    pcall(function()
        LocalPlayer:SetAttribute("Nick", ".")
        LocalPlayer:SetAttribute("Nick", finalNick)
    end)

    VN.Want = want
    print("[R&8_DV] Visual name (client) aktif")
    return true
end

local function vnRestoreClient()
    VN.Want = {}
    if not LocalPlayer or not VN.Orig then return end
    for _, a in ipairs(VN_ATTRS) do
        local o = VN.Orig[a]
        if o then pcall(function() LocalPlayer:SetAttribute(a, o.v) end) end
    end
    print("[R&8_DV] Visual name dikembalikan ke asli")
end

VN.Toggle = newToggle(vnApplyClient, vnRestoreClient)

task.spawn(function()
    while true do
        task.wait(1)
        if VN.Toggle.Running and getValue("VN_Lock", false) and LocalPlayer then
            for attr, val in pairs(VN.Want) do
                local okGet, cur = pcall(function() return LocalPlayer:GetAttribute(attr) end)
                if okGet and cur ~= val then
                    pcall(function() LocalPlayer:SetAttribute(attr, val) end)
                end
            end
        end
    end
end)

-- =========================================================================
-- LOGIKA ITEM VISUAL (100% DI DALAM 1 IMGUI UTAMA, TANPA BUKA GUI BARU)
-- =========================================================================
local IV = {
    Active = false,
    Run = 0,
    DB = nil,
    Items = nil,
    Slots = nil,
    SlotItems = {},      -- slot -> daftar pilihan string dropdown
    OptionToId = {},     -- string pilihan -> itemId
    Worn = nil,
    Ov = {},
    WearTbl = nil,
    OrigSend = nil,
    Toggle = nil,
}

local IV_FX_KEYS = { "speed", "dig", "slowFall", "fireproof", "rapier", "voidEye", "voidKatana" }

local function ivHasFx(it)
    for _, k in ipairs(IV_FX_KEYS) do
        if it[k] then return true end
    end
    return false
end

local function ivLooksLikeWorn(t)
    if type(t) ~= "table" then return false end
    for k, v in pairs(t) do
        if type(k) ~= "string" or type(v) ~= "number" then return false end
    end
    return true
end

local function ivFindWorn()
    if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
        return nil, "executor tidak mendukung getgc / debug.getupvalues"
    end
    local okGc, gc = pcall(getgc, true)
    if not okGc or type(gc) ~= "table" then return nil, "getgc gagal" end
    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            local okF, fn = pcall(rawget, obj, "onWear")
            if okF and type(fn) == "function" then
                local okU, ups = pcall(debug.getupvalues, fn)
                if okU and type(ups) == "table" then
                    for _, up in pairs(ups) do
                        if ivLooksLikeWorn(up) then return up end
                    end
                end
            end
        end
    end
    return nil, "tabel pakaian tidak ditemukan, masuk ke world dulu lalu coba lagi"
end

local function ivHook()
    local okN, Net = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Net", 5))
    end)
    if not okN or type(Net) ~= "table" then return false end
    local wear = Net.wear
    if type(wear) ~= "table" or type(wear.send) ~= "function" then return false end
    if IV.WearTbl == wear and IV.OrigSend then return true end

    local orig = wear.send
    if type(setreadonly) == "function" then pcall(setreadonly, wear, false) end
    local okSet = pcall(function()
        wear.send = function(tbl, ...)
            if type(tbl) == "table" and next(IV.Ov) ~= nil then
                local copy = {}
                for k, v in pairs(tbl) do copy[k] = v end
                for slot, o in pairs(IV.Ov) do copy[slot] = o.real end
                return orig(copy, ...)
            end
            return orig(tbl, ...)
        end
    end)
    if not okSet or wear.send == orig then return false end
    IV.WearTbl, IV.OrigSend = wear, orig
    return true
end

local function ivUnhook()
    if IV.WearTbl and IV.OrigSend then
        pcall(function() IV.WearTbl.send = IV.OrigSend end)
    end
    IV.WearTbl, IV.OrigSend = nil, nil
end

local function ivBuildItems()
    if IV.Items and #IV.Items > 0 then return true end
    local ok, DB = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("ItemDB", 5))
    end)
    if not ok or type(DB) ~= "table" then return false end

    local items, slotSet = {}, {}
    local slotItems, optToId = {}, {}

    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" and it.kind == "cloth"
            and type(it.slot) == "string" and type(it.name) == "string"
            and not it.name:find(" Seed$") then
            local hasFx = ivHasFx(it)
            local label = string.format("%s [#%d]%s", it.name, id, hasFx and " [FX]" or "")
            slotSet[it.slot] = true
            items[#items + 1] = {
                id = id,
                name = it.name,
                lname = it.name:lower(),
                slot = it.slot,
                fx = hasFx,
                label = label,
            }
            optToId[label] = id
        end
    end

    table.sort(items, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)

    local tmp = {}
    for s in pairs(slotSet) do
        tmp[#tmp + 1] = s
        slotItems[s] = { "(Asli / Tidak Diubah)", "(Kosongkan Slot Ini)" }
    end
    table.sort(tmp)

    for _, e in ipairs(items) do
        table.insert(slotItems[e.slot], e.label)
    end

    local slots = { "Semua" }
    for _, s in ipairs(tmp) do slots[#slots + 1] = s end

    IV.DB = DB
    IV.Items = items
    IV.Slots = slots
    IV.SlotItems = slotItems
    IV.OptionToId = optToId
    return #items > 0
end

-- Muat database item di awal agar dropdown per-slot langsung terisi di dalam ImGui
pcall(ivBuildItems)
if not IV.Slots then
    IV.Slots = { "Semua", "hat", "hair", "face", "neck", "shirt", "pants", "feet", "back", "hand" }
    IV.Items = {}
end

local function ivKeepAlive()
    if not IV.Worn then return end
    for slot, o in pairs(IV.Ov) do
        local want = o.vis or nil
        local cur = IV.Worn[slot]
        if cur ~= want then
            if cur == nil then
                IV.Worn[slot] = want
            else
                IV.Ov[slot] = nil
            end
        end
    end
end

local function ivReset(slot)
    if not IV.Worn then return end
    local o = IV.Ov[slot]
    if o then
        IV.Worn[slot] = o.real
        IV.Ov[slot] = nil
    end
end

local function ivResetAll()
    if not IV.Worn then return end
    local slots = {}
    for slot in pairs(IV.Ov) do slots[#slots + 1] = slot end
    for _, slot in ipairs(slots) do ivReset(slot) end
    print("[R&8_DV] Semua pakaian visual dikembalikan ke pakaian asli")
end

local function ivStart()
    if IV.Active then return true end
    local worn, err = ivFindWorn()
    if not worn then
        warn("[R&8_DV] Item Visual gagal aktif: " .. tostring(err))
        return false
    end
    if not ivBuildItems() then
        warn("[R&8_DV] Item Visual gagal aktif: Shared.ItemDB belum siap")
        return false
    end
    if not ivHook() then
        warn("[R&8_DV] Item Visual gagal aktif: hook Net.wear.send gagal")
        return false
    end
    IV.Worn = worn
    IV.Ov = {}
    IV.Active = true
    IV.Run += 1
    local run = IV.Run
    task.spawn(function()
        while IV.Active and IV.Run == run do
            ivKeepAlive()
            task.wait(0.25)
        end
    end)
    print("[R&8_DV] Item Visual AKTIF (Pure 1 ImGui, Client Only)")
    return true
end

local function ivStop()
    IV.Active = false
    IV.Run += 1
    if IV.Worn then ivResetAll() end
    ivUnhook()
    IV.Ov = {}
    print("[R&8_DV] Item Visual NONAKTIF, pakaian dikembalikan")
end

IV.Toggle = newToggle(ivStart, ivStop)

local function ivEnsureActive()
    if not IV.Active then
        IV.Toggle.Set(true)
    end
    return IV.Active
end

local function ivWear(id)
    if not ivEnsureActive() then return false end
    local it = IV.DB and IV.DB[id]
    if not it or not it.slot then return false end
    if getValue("IV_HideFx", true) and ivHasFx(it) then
        warn("[R&8_DV] Item '" .. tostring(it.name) .. "' memiliki efek gameplay. Matikan filter 'Sembunyikan Item Berefek' jika tetap ingin memakainya.")
        return false
    end
    local slot = it.slot
    if IV.Ov[slot] == nil then IV.Ov[slot] = { real = IV.Worn[slot] } end
    IV.Ov[slot].vis = id
    IV.Worn[slot] = id
    if IV.Ov[slot].real == id then IV.Ov[slot] = nil end
    print(string.format("[R&8_DV] Memakai visual: %s (ID: %d | Slot: %s)", it.name, id, slot))
    return true
end

local function ivUnwear(slot)
    if not ivEnsureActive() then return false end
    if IV.Worn[slot] == nil and IV.Ov[slot] == nil then return false end
    if IV.Ov[slot] == nil then IV.Ov[slot] = { real = IV.Worn[slot] } end
    IV.Ov[slot].vis = false
    IV.Worn[slot] = nil
    print("[R&8_DV] Slot visual dikosongkan: " .. tostring(slot))
    return true
end

local function ivFindItemByQuery(rawQuery, slotFilter, hideFx)
    if not ivBuildItems() then return nil end
    local q = vnTrim(rawQuery):lower()
    if q == "" then return nil end

    -- 1. Cek jika input berupa angka ID langsung (atau #ID)
    local numId = tonumber(q:match("^#?(%d+)$"))
    if numId then
        for _, e in ipairs(IV.Items) do
            if e.id == numId and (slotFilter == "Semua" or e.slot == slotFilter) and (not hideFx or not e.fx) then
                return e
            end
        end
    end

    -- 2. Cek kecocokan nama persis
    for _, e in ipairs(IV.Items) do
        if e.lname == q and (slotFilter == "Semua" or e.slot == slotFilter) and (not hideFx or not e.fx) then
            return e
        end
    end

    -- 3. Cek kecocokan sebagian nama / substring
    for _, e in ipairs(IV.Items) do
        if (e.lname:find(q, 1, true) or tostring(e.id) == q)
            and (slotFilter == "Semua" or e.slot == slotFilter)
            and (not hideFx or not e.fx) then
            return e
        end
    end
    return nil
end

-- =========================================================================
-- KATEGORI 1: SPAMMER
-- =========================================================================
if UI.Category then UI:Category("Spammer") end

feature("Chat", "Chat Spam")({
    center = center(function(c)
        c:Header("Chat Spammer", "Mode Server: kirim langsung ke channel dunia via SendAsync", "Server")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",   Value = "Server" },
            { Icon = "Clock",  Label = "Delay",  Value = "Custom" },
            { Icon = "Shield", Label = "Limit",  Value = "120 char" }
        })

        local MsgCard = c:Card("Pesan Spam", nil, "Chat", {
            Subtitle = "Pisahkan beberapa pesan dengan tanda |  (contoh: halo | apa kabar)"
        })
        MsgCard:Input("Isi Pesan", "SpamMessage", "Tulis pesan...", "Hello!")
        MsgCard:Dropdown("Mode Pesan", "SpamMode", { "Sequential", "Random" }, "Sequential")

        local PrefixCard = c:Card("Auto Prefix", nil, "Sliders", {
            Subtitle = "Tambah ` + angka acak 1-9 di depan pesan (contoh: `4halo), berganti tiap kirim",
            ToggleFlag = "MasterPrefix",
            Default = false
        })
        PrefixCard:Toggle("Aktifkan Auto Prefix", "AutoPrefix", false)

        local DelayCard = c:Card("Delay Spam", nil, "Clock", {
            Subtitle = "Jeda antar pesan (detik). Terlalu cepat bisa kena flood-check"
        })
        DelayCard:Slider("Delay", "SpamDelay", 0.5, 15, 3, " s", nil, 0.1)
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol Spam", nil, "Bolt", {
            Subtitle = "Satu tombol untuk Start / Stop"
        })
        if CtrlCard.Button then
            Spam.Button = CtrlCard:Button("Spam Toggle", "START", "Bolt", function()
                toggleSpam()
            end)
        end
        if CtrlCard.Keybind then
            CtrlCard:Keybind("Hotkey Start/Stop", "SpamHotkey", Enum.KeyCode.F, function() end)
        end

        local InfoCard = r:Card("Info Sesi", nil, "Clock", {
            Subtitle = "Ringkasan aktivitas spam"
        })
        InfoCard:ActivityTimeline({
            { Text = "Mode server: WorldChannels:SendAsync", Time = "Now" },
            { Text = "Channel dunia dideteksi otomatis", Time = "Now" }
        })
        if InfoCard.Button then
            InfoCard:Button("Reset Counter", "RESET", "Check", function()
                Spam.Sent = 0
                Spam.Index = 0
                print("[R&8_DV] Counter di-reset")
            end)
        end

        local ThemeCard = r:Card("Theme & Contrast Palette", nil, "Palette", {
            Subtitle = "Palet kontras tinggi dengan tulisan putih bersih"
        })
        if ThemeCard.ThemeSwatches then
            ThemeCard:ThemeSwatches("Colour Palette")
        end
        ThemeCard:Dropdown("Color Style", "ThemeSelect", ThemeChoices, "Cyberpunk Neon", function(selectedTheme)
            applyThemeSelection(selectedTheme)
        end)
        ThemeCard:Dropdown("Checkbox Style", "CheckboxStyleMode", { "Modern", "Checkbox" }, "Modern", function(mode)
            if UI.SetCheckboxStyle then UI:SetCheckboxStyle(mode) end
            task.defer(refreshAllGuiStyling)
        end)
    end)
})

-- =========================================================================
-- KATEGORI 2: SET VISUAL NAME
-- =========================================================================
if UI.Category then UI:Category("Visual Name") end

feature("Name", "Set Visual Name")({
    center = center(function(c)
        c:Header("Set Visual Name", "Ubah nama, warna, dan title di dalam game (bukan nama Roblox)", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",     Value = "Client" },
            { Icon = "Shield", Label = "Terlihat", Value = "Hanya kamu" }
        })

        local ClientCard = c:Card("Nama, Warna & Title", nil, "Palette", {
            Subtitle = "Isi yang mau diubah, kolom kosong / (tidak diubah) dibiarkan asli"
        })
        ClientCard:Input("Nama Visual", "VN_Name", "Tulis nama...", "")
        ClientCard:Dropdown("Warna Nama", "VN_ColorPreset", VN_COLOR_LIST, "(tidak diubah)")
        ClientCard:Input("Warna Hex (opsional)", "VN_Hex", "contoh: FF8800", "")
        ClientCard:Dropdown("Title", "VN_Title", VN_TITLE_LIST, "(tidak diubah)")
        ClientCard:Toggle("Izinkan kode warna di nama (`4 `2 dst)", "VN_AllowCodes", false)
        ClientCard:Toggle("Kunci (pasang ulang jika ditimpa server)", "VN_Lock", false)
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol", nil, "Bolt", {
            Subtitle = "Satu tombol: START menerapkan, STOP mengembalikan nama asli"
        })
        VN.Toggle.Button = CtrlCard:Button("Visual Name", "START", "Bolt", function()
            VN.Toggle.Toggle()
        end)

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Hanya terlihat di layarmu. Pemain lain tetap melihat nama aslimu"
        })
    end)
})

-- =========================================================================
-- KATEGORI 3: ITEM VISUAL (100% PURE 1 IMGUI - TANPA BUKA GUI BARU)
-- =========================================================================
if UI.Category then UI:Category("Item Visual") end

feature("Item", "Item Visual")({
    center = center(function(c)
        c:Header("Item Visual (Pure 1 ImGui)", "Pakai baju & aksesori langsung dari menu ini tanpa buka GUI baru", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "UI Mode",      Value = "1 ImGui" },
            { Icon = "Shield", Label = "Kirim Server", Value = "Diblokir" },
            { Icon = "Check",  Label = "Total Cloth",  Value = tostring(#(IV.Items or {})) .. " Item" }
        })

        -- Card 1: Pencarian Cepat via Nama / ID langsung di ImGui
        local SearchCard = c:Card("Cari & Pakai Cepat (Nama / ID)", nil, "Chat", {
            Subtitle = "Ketik nama atau ID pakaian lalu tekan PAKAI (otomatis menyalakan bypass client)"
        })
        SearchCard:Input("Cari Nama / ID Item", "IV_SearchInput", "Contoh: Angel Wings / Fedora / 245...", "")
        SearchCard:Dropdown("Filter Slot Cari", "IV_SlotFilter", IV.Slots, "Semua")
        SearchCard:Toggle("Sembunyikan Item Berefek (Speed/Dig/dll)", "IV_HideFx", true)

        SearchCard:Button("Pakai Item Hasil Cari", "PAKAI", "Check", function()
            local q = getValue("IV_SearchInput", "")
            local slotFilter = getValue("IV_SlotFilter", "Semua")
            local hideFx = getValue("IV_HideFx", true)
            local found = ivFindItemByQuery(q, slotFilter, hideFx)
            if not found then
                warn("[R&8_DV] Item tidak ditemukan untuk kata kunci: '" .. tostring(q) .. "' (Slot: " .. tostring(slotFilter) .. ")")
                return
            end
            ivWear(found.id)
        end)

        SearchCard:Button("Kosongkan Slot Filter Saat Ini", "LEPAS SLOT", "Minimize", function()
            local slotFilter = getValue("IV_SlotFilter", "Semua")
            if slotFilter ~= "Semua" then
                ivUnwear(slotFilter)
            else
                local q = getValue("IV_SearchInput", "")
                local found = ivFindItemByQuery(q, "Semua", false)
                if found then ivUnwear(found.slot) end
            end
        end)

        -- Card 2: Katalog Dropdown Per-Slot langsung di dalam ImGui
        local CatalogCard = c:Card("Katalog Pakaian Per Slot", nil, "Palette", {
            Subtitle = "Pilih pakaian dari slot mana saja untuk langsung dipakai secara visual"
        })

        for _, slotName in ipairs(IV.Slots) do
            if slotName ~= "Semua" then
                local options = IV.SlotItems[slotName] or { "(Asli / Tidak Diubah)", "(Kosongkan Slot Ini)" }
                CatalogCard:Dropdown("Slot: " .. slotName:upper(), "IV_SlotPick_" .. slotName, options, "(Asli / Tidak Diubah)", function(picked)
                    if picked == "(Asli / Tidak Diubah)" then
                        if IV.Active then ivReset(slotName) end
                    elseif picked == "(Kosongkan Slot Ini)" then
                        ivUnwear(slotName)
                    else
                        local id = IV.OptionToId[picked] or tonumber(tostring(picked):match("%[#(%d+)%]"))
                        if id then
                            ivWear(id)
                        end
                    end
                end)
            end
        end
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol Item Visual", nil, "Bolt", {
            Subtitle = "Semua terintegrasi di dalam 1 ImGui tanpa jendela tambahan"
        })
        IV.Toggle.Button = CtrlCard:Button("Status Bypass Visual", "START", "Bolt", function()
            IV.Toggle.Toggle()
        end)
        CtrlCard:Button("Reset ke Pakaian Asli", "RESET ALL", "Check", function()
            if IV.Active then ivResetAll() end
        end)
        CtrlCard:Button("Lepas Semua Pakaian (Kosongkan)", "UNWEAR ALL", "Minimize", function()
            if not ivEnsureActive() then return end
            for _, slotName in ipairs(IV.Slots) do
                if slotName ~= "Semua" then
                    ivUnwear(slotName)
                end
            end
        end)

        local HowCard = r:Card("Panduan Singkat", nil, "Clock", {
            Subtitle = "Cara pakai langsung dari dalam tab ini"
        })
        HowCard:ActivityTimeline({
            { Text = "Pilih pakaian langsung di Katalog Per Slot", Time = "1" },
            { Text = "Atau ketik nama/ID di kolom Cari lalu klik PAKAI", Time = "2" },
            { Text = "Hook Net.wear.send otomatis memblokir info ke server", Time = "3" },
            { Text = "Klik RESET ALL untuk kembali ke pakaian asli", Time = "4" }
        })
    end)
})

-- =========================================================================
-- KATEGORI 4: SETTINGS
-- =========================================================================
if UI.Category then UI:Category("Settings") end

feature("Misc", "Misc")({
    center = center(function(c)
        c:Header("Misc & Appearance", "Pengaturan jendela, tema kontras, & utilitas", "Utility")

        local WinCard = c:Card("Window Controls", nil, "Menu", {
            Subtitle = "Kecilkan menu menjadi ikon mengambang"
        })
        WinCard:Button("Minimize to Popup Icon", "HIDE", "Minimize", function()
            UI:MinimizeToIcon()
        end)
        WinCard:Slider("UI Scale", "UIScalePct", 60, 130, 100, "%", function(val)
            if UI.SetScale then UI:SetScale(val / 100) else UI.UIScale = val / 100 end
        end)
        WinCard:Slider("Transparency", "BgTransPct", 0, 55, 4, "%", function(val)
            UI:SetTransparency(val / 100)
        end)
        WinCard:Toggle("Rounded Borders", "RoundedState", true, function(state)
            UI:SetRounded(state)
        end)
    end),

    right = right(function(r)
        local ThemeSetCard = r:Card("Colour Palette (High Contrast)", nil, "Palette", {
            Subtitle = "Ganti tema warna gelap kontras tinggi (Teks Putih)"
        })
        ThemeSetCard:Dropdown("Pilih Tema Kontras", "ThemeSelectSettings", ThemeChoices, "Cyberpunk Neon", function(selectedTheme)
            applyThemeSelection(selectedTheme)
        end)

        local PerfCard = r:Card("Performance", nil, "Bolt", {
            Subtitle = "Mode ringan untuk perangkat low-end"
        })
        PerfCard:Toggle("FPS Boost", "FPSBoost", false)
        PerfCard:Toggle("Reduce Effects", "ReduceEffects", false)
        if PerfCard.Keybind then
            PerfCard:Keybind("Toggle Menu Key", "MenuHotkey", Enum.KeyCode.RightShift, function(newKey)
                if newKey then UI.ToggleKey = newKey end
            end)
        end
    end)
})

-- Terapkan tema kontras default ("Cyberpunk Neon") + paksa seluruh teks menjadi putih & tidak ketebalan
task.spawn(function()
    task.wait(0.15)
    local gui = findImGuiScreenGui()
    if gui then
        gui.DescendantAdded:Connect(function(desc)
            task.defer(function()
                styleTextAndFont(desc)
                if ActiveCustomPalette then
                    applyPaletteToGui(ActiveCustomPalette)
                end
            end)
        end)
    end
    applyThemeSelection("Cyberpunk Neon")
end)
