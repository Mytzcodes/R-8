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

local ImGui = loadstring(rawScript)()

-- 2. Inisialisasi Jendela
local UI = ImGui({
    Title = "R&8_DV CLIENT SUITE",
    BrandTitle = "R&8_DV",
    BrandSubtitle = "ULTIMATE SUITE",
    Theme = "Minimalist Monochrome",
    CheckboxStyle = "Modern",
    LetterSpacing = 0,
    AutoLoading = false
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
-- SERVICES & CORE REFERENCES
-- =========================================================================
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function getValue(flag, fallback)
    local ok, v = pcall(function() return UI:GetValue(flag) end)
    if ok and v ~= nil then return v end
    return fallback
end

local function vnTrim(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

local function notifyClient(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "R&8_DV",
            Text = text or "",
            Duration = duration or 5
        })
    end)
    print(string.format("[%s] %s", title or "R&8_DV", text or ""))
end

-- =========================================================================
-- LOGIKA SPAM (DIPERTAHANKAN + INTEGRASI MOD FREEZE & ANTI-DETECTION)
-- =========================================================================
local MAX_CHAT = 120

local Spam = {
    Running = false,
    PausedByMod = false,
    Sent = 0,
    Index = 0,
    Thread = nil,
    Button = nil,
}

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
    if Spam.PausedByMod then return false end
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
            if not Spam.PausedByMod then
                if sendChat(buildMessage()) then
                    Spam.Sent += 1
                else
                    warn("[R&8_DV] Gagal kirim: WorldChannel tidak ditemukan, pastikan sudah masuk world")
                end
            end
            local delay = tonumber(getValue("SpamDelay", 3)) or 3
            local jitter = getValue("AD_ChatJitter", true) and (math.random(5, 35) / 100) or 0
            task.wait(math.max(delay + jitter, 0.25))
        end
    end)
end

local function toggleSpam()
    if Spam.Running then stopSpam() else startSpam() end
end

-- =========================================================================
-- TEKS RINGAN & ROOT FINDER R&8_DV
-- =========================================================================
local Light = { Orig = setmetatable({}, { __mode = "k" }), Conns = {}, Roots = {}, On = false }

local function lightOne(d)
    if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) then return end
    pcall(function()
        local ff = d.FontFace
        if ff and ff.Weight.Value >= 700 then
            if Light.Orig[d] == nil then Light.Orig[d] = ff end
            d.FontFace = Font.new(ff.Family, Enum.FontWeight.Medium, ff.Style)
        end
    end)
end

local function lightFindRoots()
    local roots = {}
    local containers = {}
    pcall(function() if type(gethui) == "function" then containers[#containers + 1] = gethui() end end)
    pcall(function() containers[#containers + 1] = game:GetService("CoreGui") end)
    pcall(function() containers[#containers + 1] = LocalPlayer:FindFirstChild("PlayerGui") end)
    for _, c in ipairs(containers) do
        if c then
            for _, g in ipairs(c:GetChildren()) do
                if g:IsA("ScreenGui") then
                    local found = false
                    if g.Name:find("R8DV") then found = true end
                    if not found then
                        for _, d in ipairs(g:GetDescendants()) do
                            if d:IsA("TextLabel") then
                                local up = d.Text:upper()
                                if up:find("ULTIMATE SUITE", 1, true) or up:find("SPAM SUITE", 1, true) or up:find("R&8_DV", 1, true) then
                                    found = true
                                    break
                                end
                            end
                        end
                    end
                    if found then roots[#roots + 1] = g end
                end
            end
        end
    end
    return roots
end

local function lightEnable()
    Light.On = true
    for _, g in ipairs(lightFindRoots()) do
        if not Light.Roots[g] then
            Light.Roots[g] = true
            for _, d in ipairs(g:GetDescendants()) do lightOne(d) end
            Light.Conns[#Light.Conns + 1] = g.DescendantAdded:Connect(function(d)
                if Light.On then task.defer(lightOne, d) end
            end)
        else
            for _, d in ipairs(g:GetDescendants()) do lightOne(d) end
        end
    end
end

local function lightDisable()
    Light.On = false
    for obj, ff in pairs(Light.Orig) do
        pcall(function() obj.FontFace = ff end)
    end
    Light.Orig = setmetatable({}, { __mode = "k" })
end

-- =========================================================================
-- LOGIKA SET VISUAL NAME (100% CLIENT - DIPERTAHANKAN)
-- =========================================================================
local VN = {
    Orig = nil,
    Want = {},
    Applied = false,
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

local function vnSet()
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
    VN.Applied = true
    notifyClient("Visual Name", "Visual name di-SET (client)", 3)
    return true
end

local function vnReset()
    VN.Want = {}
    VN.Applied = false
    if not LocalPlayer or not VN.Orig then return end
    for _, a in ipairs(VN_ATTRS) do
        local o = VN.Orig[a]
        if o then pcall(function() LocalPlayer:SetAttribute(a, o.v) end) end
    end
    pcall(function()
        local nick = VN.Orig.Nick and VN.Orig.Nick.v
        LocalPlayer:SetAttribute("Nick", ".")
        LocalPlayer:SetAttribute("Nick", nick)
    end)
    notifyClient("Visual Name", "Visual name dikembalikan ke nama awal", 3)
end

task.spawn(function()
    while true do
        task.wait(1)
        if VN.Applied and getValue("VN_Lock", false) and LocalPlayer then
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
-- LOGIKA SET CLOTHES + ASSET RESOLVER + IN-GUI SCROLLABLE LISTCARD
--  * Memperbaiki pakaian tidak muncul dengan multi-stage GC & PlayerSprite fallback
--  * Ekstraksi gambar rbxassetid dari ItemDB, ItemIcon, ClothesDB, dan Assets
--  * ListCard di-inject langsung ke dalam Card R&8_DV (tanpa bikin jendela baru)
--  * Double-tap item untuk langsung pakai / lepas, Search & Filter Slot
--  * Shortcut Unwear All & daftar pakaian dipakai secara real-time di dalam GUI
-- =========================================================================
local SC = {
    DB = nil,
    ClothesDB = nil,
    ItemIcon = nil,
    Assets = nil,
    Items = nil,
    Slots = { "All" },
    Worn = nil,
    Game = nil,
    State = nil,
    PlayerSprite = nil,
    Ov = {},
    WearTbl = nil, OrigWear = nil,
    MoveTbl = nil, OrigMove = nil,
    JumpMode = "Tahan paket (disarankan)",
    Hold = nil,
    Loop = false,
    SearchQuery = "",
    SelectedSlot = "All",
    UpdateUIFn = nil,
    LastTapId = nil,
    LastTapTime = 0,
}

local SC_JUMP_MODES = { "Tahan paket (disarankan)", "Samarkan flag saja", "Mati" }

local function scLooksLikeWorn(t)
    if type(t) ~= "table" then return false end
    local count = 0
    local validSlots = {
        hair = true, head = true, mask = true, face = true, eyes = true,
        chest = true, shirt = true, pants = true, shoes = true, feet = true,
        back = true, wing = true, wings = true, neck = true, hand = true,
        aura = true, pet = true, hat = true,ride = true, artifact = true
    }
    for k, v in pairs(t) do
        if type(k) ~= "string" or type(v) ~= "number" then return false end
        count += 1
    end
    return true
end

-- Pencarian agresif tabel worn & fungsi render karakter (memperbaiki bug visual tidak muncul)
local function scFindWorn()
    if SC.Worn and SC.Game then return SC.Worn end
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    if sh and not SC.PlayerSprite then
        pcall(function() SC.PlayerSprite = require(sh:FindFirstChild("PlayerSprite")) end)
    end

    if type(getgc) ~= "function" then
        return nil, "Executor tidak mendukung getgc"
    end

    local okGc, gc = pcall(getgc, true)
    if not okGc or type(gc) ~= "table" then return nil, "getgc gagal" end

    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            local okWear, fnWear = pcall(rawget, obj, "onWear")
            local okRef, fnRef = pcall(rawget, obj, "refresh")
            if (okWear and type(fnWear) == "function") or (okRef and type(fnRef) == "function") then
                local targetFn = (type(fnWear) == "function" and fnWear) or fnRef
                if type(debug) == "table" and type(debug.getupvalues) == "function" then
                    local okU, ups = pcall(debug.getupvalues, targetFn)
                    if okU and type(ups) == "table" then
                        local worn, state
                        for _, up in pairs(ups) do
                            if type(up) == "table" then
                                if not worn and scLooksLikeWorn(up) and rawget(up, "onWear") == nil then
                                    worn = up
                                end
                                if not state and (type(rawget(up, "call")) == "function" or type(rawget(up, "effects")) == "function") then
                                    state = up
                                end
                            end
                        end
                        if worn then
                            SC.Game, SC.State, SC.Worn = obj, state, worn
                            return worn
                        end
                    end
                end
                local directWorn = rawget(obj, "worn") or rawget(obj, "Worn") or rawget(obj, "equipped")
                if type(directWorn) == "table" and scLooksLikeWorn(directWorn) then
                    SC.Game, SC.Worn = obj, directWorn
                    return directWorn
                end
            end
        end
    end

    -- Fallback: cari di upvalues semua fungsi GC yang memegang referensi refresh + worn
    if type(debug) == "table" and type(debug.getupvalues) == "function" then
        for _, fn in ipairs(gc) do
            if type(fn) == "function" and not is_synapse_function and true then
                local okU, ups = pcall(debug.getupvalues, fn)
                if okU and type(ups) == "table" then
                    local hasGame, foundWorn, foundState
                    for _, up in pairs(ups) do
                        if type(up) == "table" then
                            if type(rawget(up, "refresh")) == "function" and type(rawget(up, "onWear")) == "function" then
                                hasGame = up
                            elseif scLooksLikeWorn(up) and next(up) ~= nil then
                                foundWorn = up
                            elseif type(rawget(up, "effects")) == "function" then
                                foundState = up
                            end
                        end
                    end
                    if hasGame and foundWorn then
                        SC.Game, SC.State, SC.Worn = hasGame, foundState, foundWorn
                        return foundWorn
                    end
                end
            end
        end
    end

    return nil, "Tabel pakaian belum ter-load, pastikan karakter sudah spawn di dalam world"
end

-- Resolusi gambar rbxassetid & rect offset dari modul game
local function scFormatAsset(val)
    if type(val) == "number" then
        return "rbxassetid://" .. tostring(val), nil, nil
    elseif type(val) == "string" then
        if val:find("^rbxassetid://") or val:find("^rbxthumb://") or val:find("^http") then
            return val, nil, nil
        elseif val:match("^%d+$") then
            return "rbxassetid://" .. val, nil, nil
        end
    elseif type(val) == "table" then
        local img = val.image or val.Image or val.icon or val.Icon or val.texture or val.Texture or val.asset or val.id or val[1]
        local ro = val.rectOffset or val.ImageRectOffset or val.offset
        local rs = val.rectSize or val.ImageRectSize or val.size
        local formatted = scFormatAsset(img)
        if formatted then return formatted, ro, rs end
    end
    return nil, nil, nil
end

local function scResolveItemIcon(id, it)
    if SC.ItemIcon then
        if type(SC.ItemIcon) == "function" then
            local ok, res, ro, rs = pcall(SC.ItemIcon, id)
            if ok and res then
                local img, rOffset, rSize = scFormatAsset(res)
                if img then return img, ro or rOffset, rs or rSize end
            end
        elseif type(SC.ItemIcon) == "table" then
            local fn = SC.ItemIcon.get or SC.ItemIcon.Get or SC.ItemIcon.getIcon or SC.ItemIcon.icon or SC.ItemIcon.resolve
            if type(fn) == "function" then
                local ok, res, ro, rs = pcall(fn, id)
                if not ok or not res then ok, res, ro, rs = pcall(fn, SC.ItemIcon, id) end
                if ok and res then
                    local img, rOffset, rSize = scFormatAsset(res)
                    if img then return img, ro or rOffset, rs or rSize end
                end
            end
            if SC.ItemIcon[id] then
                local img, ro, rs = scFormatAsset(SC.ItemIcon[id])
                if img then return img, ro, rs end
            end
        end
    end

    for _, k in ipairs({ "icon", "image", "assetId", "texture", "sprite", "tex", "img", "decal" }) do
        if it[k] then
            local img, ro, rs = scFormatAsset(it[k])
            if img then return img, ro, rs end
        end
    end

    if type(SC.ClothesDB) == "table" then
        local cEntry = SC.ClothesDB[id] or SC.ClothesDB[it.name]
        if cEntry then
            local img, ro, rs = scFormatAsset(cEntry)
            if img then return img, ro, rs end
            if type(cEntry) == "table" then
                for _, v in pairs(cEntry) do
                    local subImg, sRo, sRs = scFormatAsset(v)
                    if subImg then return subImg, sRo, sRs end
                end
            end
        end
    end

    if type(SC.Assets) == "table" then
        local aEntry = SC.Assets[it.name] or SC.Assets[id] or (it.tex and SC.Assets[it.tex]) or (it.sprite and SC.Assets[it.sprite])
        if aEntry then
            local img, ro, rs = scFormatAsset(aEntry)
            if img then return img, ro, rs end
        end
    end

    return "rbxassetid://0", nil, nil
end

local function scBuildItems()
    if SC.Items and #SC.Items > 0 then return true end
    local sh = ReplicatedStorage:WaitForChild("Shared", 5)
    if not sh then return false end

    local ok, DB = pcall(function() return require(sh:WaitForChild("ItemDB", 5)) end)
    if not ok or type(DB) ~= "table" then return false end

    pcall(function() SC.ItemIcon = require(sh:FindFirstChild("ItemIcon")) end)
    pcall(function() SC.ClothesDB = require(sh:FindFirstChild("ClothesDB")) end)
    pcall(function() SC.Assets = require(sh:FindFirstChild("Assets")) end)
    pcall(function() SC.PlayerSprite = require(sh:FindFirstChild("PlayerSprite")) end)

    local items = {}
    local slotMap = {}

    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" then
            local isCloth = (it.kind == "cloth" or it.kind == "clothes" or it.kind == "wearable" or (type(it.slot) == "string" and it.slot ~= ""))
            if isCloth and type(it.slot) == "string" and type(it.name) == "string" and not it.name:find(" Seed$") then
                local iconUrl, rectOff, rectSz = scResolveItemIcon(id, it)
                local rawAssetNum = tostring(iconUrl):match("(%d+)") or "N/A"
                local slotClean = it.slot:lower()
                slotMap[slotClean] = true

                items[#items + 1] = {
                    id = id,
                    name = it.name,
                    lname = it.name:lower(),
                    slot = slotClean,
                    icon = iconUrl,
                    assetNum = rawAssetNum,
                    rectOffset = rectOff,
                    rectSize = rectSz,
                    doubleJump = it.doubleJump and true or false
                }
            end
        end
    end

    table.sort(items, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)

    local slotList = { "All" }
    local sortedSlots = {}
    for s in pairs(slotMap) do sortedSlots[#sortedSlots + 1] = s end
    table.sort(sortedSlots)
    for _, s in ipairs(sortedSlots) do slotList[#slotList + 1] = s end

    SC.DB = DB
    SC.Items = items
    SC.Slots = slotList
    return #items > 0
end

-- =========================================================================
-- ANTI-DETECTION & PACKET TRAFFIC GUARD (WEAR, MOVE, STATE)
-- =========================================================================
local AD = {
    Enabled = true,
    BlockVisualWear = true,
    SanitizeMove = true,
    RateLimitMove = true,
    BlockModReport = true,
    BlockedPackets = 0,
    SanitizedPackets = 0,
    LastMoveTick = 0,
}

local function scGetNet()
    local okN, Net = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Net", 5))
    end)
    if okN and type(Net) == "table" then return Net end
    return nil
end

local function scVisualOnlyDoubleJump()
    local W, DB = SC.Worn, SC.DB
    if not (W and DB) or next(SC.Ov) == nil then return false end
    local visHas, realHas = false, false
    local slots = {}
    for slot in pairs(W) do slots[slot] = true end
    for slot in pairs(SC.Ov) do slots[slot] = true end
    for slot in pairs(slots) do
        local vis = W[slot]
        local o = SC.Ov[slot]
        local real = o and o.real or (not o and vis) or nil
        local vi = vis and DB[vis]
        if vi and vi.doubleJump then visHas = true end
        local ri = real and DB[real]
        if ri and ri.doubleJump then realHas = true end
    end
    return visHas and not realHas
end

local function scHook()
    local Net = scGetNet()
    if not Net then return false end
    local wear, move = Net.wear, Net.move
    if type(wear) ~= "table" or type(wear.send) ~= "function" then return false end

    if not (SC.WearTbl == wear and SC.OrigWear) then
        local orig = wear.send
        if type(setreadonly) == "function" then pcall(setreadonly, wear, false) end
        local okSet = pcall(function()
            wear.send = function(tbl, ...)
                if AD.Enabled and AD.BlockVisualWear and type(tbl) == "table" and next(SC.Ov) ~= nil then
                    local copy = {}
                    for k, v in pairs(tbl) do copy[k] = v end
                    for slot, o in pairs(SC.Ov) do copy[slot] = o.real end
                    AD.SanitizedPackets += 1
                    return orig(copy, ...)
                end
                return orig(tbl, ...)
            end
        end)
        if not okSet or wear.send == orig then return false end
        SC.WearTbl, SC.OrigWear = wear, orig
    end

    if type(move) == "table" and type(move.send) == "function"
        and not (SC.MoveTbl == move and SC.OrigMove) then
        local origMove = move.send
        if type(setreadonly) == "function" then pcall(setreadonly, move, false) end
        local okM = pcall(function()
            move.send = function(tbl, ...)
                if Spam.PausedByMod and getValue("Mod_FreezePacket", false) then
                    AD.BlockedPackets += 1
                    return
                end

                if AD.Enabled and AD.RateLimitMove then
                    local now = os.clock()
                    if now - AD.LastMoveTick < 0.014 then
                        AD.BlockedPackets += 1
                        return
                    end
                    AD.LastMoveTick = now
                end

                local mode = SC.JumpMode
                if (AD.Enabled and AD.SanitizeMove) and mode ~= "Mati" and type(tbl) == "table" and scVisualOnlyDoubleJump() then
                    local flags = tonumber(tbl.flags) or 0
                    local air = bit32.band(flags, 128) ~= 0
                    local function stripped()
                        local copy = {}
                        for k, v in pairs(tbl) do copy[k] = v end
                        copy.flags = bit32.band(flags, 127)
                        return copy
                    end
                    if mode == "Samarkan flag saja" then
                        if air then
                            AD.SanitizedPackets += 1
                            return origMove(stripped(), ...)
                        end
                    else
                        local now = os.clock()
                        if air and not SC.Hold then SC.Hold = now end
                        if SC.Hold then
                            local grounded = bit32.band(flags, 2) ~= 0
                            if (grounded and now - SC.Hold > 0.3) or now - SC.Hold > 4 then
                                SC.Hold = nil
                                AD.SanitizedPackets += 1
                                return origMove(stripped(), ...)
                            end
                            AD.BlockedPackets += 1
                            return
                        end
                    end
                else
                    SC.Hold = nil
                end
                return origMove(tbl, ...)
            end
        end)
        if okM and move.send ~= origMove then
            SC.MoveTbl, SC.OrigMove = move, origMove
        end
    end

    -- Bungkus paket report / ban / telemetry jika ada di Net
    if AD.Enabled and AD.BlockModReport then
        for k, packetObj in pairs(Net) do
            local lk = tostring(k):lower()
            if (lk:find("ban") or lk:find("kick") or lk:find("flag") or lk:find("cheat") or lk:find("suspicious") or lk:find("detect"))
                and type(packetObj) == "table" and type(packetObj.send) == "function" and not packetObj._r8hooked then
                pcall(function()
                    if type(setreadonly) == "function" then pcall(setreadonly, packetObj, false) end
                    packetObj._r8hooked = true
                    packetObj.send = function(...)
                        AD.BlockedPackets += 1
                        return
                    end
                end)
            end
        end
    end

    return true
end

local function scUnhook()
    if SC.WearTbl and SC.OrigWear then
        pcall(function() SC.WearTbl.send = SC.OrigWear end)
    end
    if SC.MoveTbl and SC.OrigMove then
        pcall(function() SC.MoveTbl.send = SC.OrigMove end)
    end
    SC.WearTbl, SC.OrigWear, SC.MoveTbl, SC.OrigMove, SC.Hold = nil, nil, nil, nil, nil
end

-- Force character visual redraw across Game.refresh, onWear, and PlayerSprite
local function scForceCharacterRedraw()
    local W = SC.Worn
    if not W then return end

    if SC.Game then
        if type(SC.Game.refresh) == "function" then
            local ok = pcall(SC.Game.refresh)
            if not ok then pcall(SC.Game.refresh, SC.Game) end
        end
        if type(SC.Game.updateCharacter) == "function" then
            pcall(SC.Game.updateCharacter, W)
        end
        if type(SC.Game.applyWorn) == "function" then
            pcall(SC.Game.applyWorn, W)
        end
    end

    if SC.PlayerSprite and LocalPlayer.Character then
        if type(SC.PlayerSprite.apply) == "function" then
            pcall(SC.PlayerSprite.apply, LocalPlayer.Character, W)
        elseif type(SC.PlayerSprite.update) == "function" then
            pcall(SC.PlayerSprite.update, LocalPlayer.Character, W)
        elseif type(SC.PlayerSprite.refresh) == "function" then
            pcall(SC.PlayerSprite.refresh, LocalPlayer.Character, W)
        end
    end

    -- Trigger attribute change agar sistem AuraFx / WornPet / NameUI client ikut ter-refresh
    pcall(function()
        local curWornAttr = LocalPlayer:GetAttribute("WornRefreshTick") or 0
        LocalPlayer:SetAttribute("WornRefreshTick", curWornAttr + 1)
    end)
end

local function scMutate(fn)
    local W = scFindWorn()
    if not W then return end
    local before = {}
    for k, v in pairs(W) do before[k] = v end

    local G = SC.State
    local prevFx = nil
    if G and type(G.effects) == "function" then
        local ok, r = pcall(G.effects)
        if ok then prevFx = r end
    end

    fn(W)

    local slots = {}
    for k in pairs(before) do slots[k] = true end
    for k in pairs(W) do slots[k] = true end
    for slot in pairs(slots) do
        if W[slot] ~= before[slot] then
            local o = SC.Ov[slot]
            if not o then
                o = { real = before[slot] }
                SC.Ov[slot] = o
            end
            o.vis = W[slot] or false
            if o.real == W[slot] then SC.Ov[slot] = nil end
        end
    end

    if prevFx and G and type(G.effectsChanged) == "function" then
        pcall(G.effectsChanged, prevFx)
    end
    if G then
        local hand = W.hand
        if hand == 138 or hand == 5480 then G.punchPick = hand end
    end

    scForceCharacterRedraw()
    if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
end

local function scWearInto(W, id)
    local it = SC.DB and SC.DB[id]
    if not it or not it.slot then return end
    local slot = it.slot
    local s = it.suit
    for k, other in pairs(W) do
        local o = SC.DB[other]
        local os = o and o.suit
        if not (k == slot or ((not s or s[k]) and (not os or os[slot]))) then
            W[k] = nil
        end
    end
    W[slot] = id
end

local function scKeepAlive()
    local W = SC.Worn
    if not W or next(SC.Ov) == nil then return end
    local changed = false
    for slot, o in pairs(SC.Ov) do
        local want = o.vis or nil
        local cur = W[slot]
        if cur ~= want then
            if cur == nil then
                W[slot] = want
                changed = true
            else
                SC.Ov[slot] = nil
            end
        end
    end
    if changed then
        scForceCharacterRedraw()
        if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
    end
end

local function scEnsureLoop()
    if SC.Loop then return end
    SC.Loop = true
    task.spawn(function()
        while true do
            task.wait(0.25)
            pcall(scKeepAlive)
        end
    end)
end

local function scResolve(tok)
    tok = vnTrim(tok)
    if tok == "" then return nil end
    local n = tonumber(tok)
    if n then
        local it = SC.DB[n]
        if it and type(it.slot) == "string" then return n end
        return nil
    end
    local q = tok:lower()
    for _, e in ipairs(SC.Items) do
        if e.lname == q then return e.id end
    end
    local best, bestLen
    for _, e in ipairs(SC.Items) do
        if e.lname:find(q, 1, true) and (not bestLen or #e.name < bestLen) then
            best, bestLen = e.id, #e.name
        end
    end
    return best
end

-- Toggle pakai / lepas 1 item dari ListCard (Double-Tap)
local function scToggleSingleItem(id)
    local worn, err = scFindWorn()
    if not worn then
        notifyClient("Set Clothes", tostring(err), 4)
        return
    end
    if not scBuildItems() then return end
    scHook()
    scEnsureLoop()

    local it = SC.DB[id]
    if not it or not it.slot then return end

    scMutate(function(W)
        if W[it.slot] == id then
            local orig = SC.Ov[it.slot] and SC.Ov[it.slot].real or nil
            W[it.slot] = orig
        else
            scWearInto(W, id)
        end
    end)
end

-- Unwear All (Lepas semua pakaian secara visual di client)
local function scUnwearAll()
    local worn, err = scFindWorn()
    if not worn then
        notifyClient("Set Clothes", tostring(err), 4)
        return
    end
    scBuildItems()
    scHook()
    scEnsureLoop()

    scMutate(function(W)
        for slot in pairs(W) do
            W[slot] = nil
        end
    end)
    notifyClient("Set Clothes", "Semua pakaian dilepas (Unwear All Visual)", 3)
end

-- Tombol SET dari input teks
local function scSet()
    local raw = tostring(getValue("SC_Items", ""))
    local tokens = {}
    for t in string.gmatch(raw, "[^,\n]+") do
        t = vnTrim(t)
        if t ~= "" then tokens[#tokens + 1] = t end
    end
    if #tokens == 0 then
        notifyClient("Set Clothes", "Isi kolom item atau klik 2x pada Card List!", 3)
        return
    end

    local worn, err = scFindWorn()
    if not worn then notifyClient("Set Clothes", tostring(err), 4); return end
    if not scBuildItems() then notifyClient("Set Clothes", "Shared.ItemDB gagal dibaca", 4); return end
    scHook()
    scEnsureLoop()

    local ids, applied, missing = {}, {}, {}
    for _, t in ipairs(tokens) do
        local id = scResolve(t)
        if id then
            ids[#ids + 1] = id
            applied[#applied + 1] = SC.DB[id].name .. " (" .. id .. ")"
        else
            missing[#missing + 1] = t
        end
    end
    if #ids > 0 then
        scMutate(function(W)
            for _, id in ipairs(ids) do scWearInto(W, id) end
        end)
        notifyClient("Set Clothes", "Dipakai: " .. table.concat(applied, ", "), 3)
    end
    if #missing > 0 then
        warn("[R&8_DV] Set Clothes tidak ketemu: " .. table.concat(missing, ", "))
    end
end

-- Tombol KEMBALI KE AWAL (Reset ke pakaian server asli)
local function scReset()
    if SC.Worn and next(SC.Ov) ~= nil then
        scMutate(function(W)
            for slot, o in pairs(SC.Ov) do W[slot] = o.real end
        end)
    end
    SC.Ov = {}
    scUnhook()
    if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
    notifyClient("Set Clothes", "Pakaian dikembalikan ke status asli server", 3)
end

-- =========================================================================
-- IN-GUI EMBEDDED CLOTHES LISTCARD & WORN VIEWER (TANPA WINDOW BARU)
-- Menyuntikkan ScrollingFrame + Item Cards langsung ke dalam Card R&8_DV
-- =========================================================================
local function scMountEmbeddedBrowser()
    task.spawn(function()
        task.wait(0.8)
        scBuildItems()
        pcall(scFindWorn)

        local targetAnchor = nil
        for _ = 1, 20 do
            for _, root in ipairs(lightFindRoots()) do
                for _, d in ipairs(root:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text:find("KATALOG VISUAL CLOTHES", 1, true) then
                        targetAnchor = d
                        break
                    end
                end
                if targetAnchor then break end
            end
            if targetAnchor then break end
            task.wait(0.3)
        end

        if not targetAnchor then return end
        local cardContainer = targetAnchor.Parent
        while cardContainer and not (cardContainer:IsA("Frame") or cardContainer:IsA("ScrollingFrame")) do
            cardContainer = cardContainer.Parent
        end
        if not cardContainer then return end
        if cardContainer:FindFirstChild("R8DV_EmbeddedClothesBrowser") then return end

        local holder = Instance.new("Frame")
        holder.Name = "R8DV_EmbeddedClothesBrowser"
        holder.Size = UDim2.new(1, 0, 0, 420)
        holder.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        holder.BorderSizePixel = 0
        holder.LayoutOrder = 99
        holder.Parent = cardContainer

        local holderCorner = Instance.new("UICorner")
        holderCorner.CornerRadius = UDim.new(0, 8)
        holderCorner.Parent = holder

        local holderStroke = Instance.new("UIStroke")
        holderStroke.Color = Color3.fromRGB(48, 48, 56)
        holderStroke.Thickness = 1
        holderStroke.Parent = holder

        -- Panel Atas: Status Item Dipakai Saat Ini (Real-time di dalam GUI)
        local wornPanel = Instance.new("Frame")
        wornPanel.Name = "WornStatusPanel"
        wornPanel.Size = UDim2.new(1, -16, 0, 68)
        wornPanel.Position = UDim2.new(0, 8, 0, 8)
        wornPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        wornPanel.BorderSizePixel = 0
        wornPanel.Parent = holder

        local wornCorner = Instance.new("UICorner")
        wornCorner.CornerRadius = UDim.new(0, 6)
        wornCorner.Parent = wornPanel

        local wornTitle = Instance.new("TextLabel")
        wornTitle.Size = UDim2.new(1, -110, 0, 18)
        wornTitle.Position = UDim2.new(0, 8, 0, 4)
        wornTitle.BackgroundTransparency = 1
        wornTitle.Font = Enum.Font.GothamMedium
        wornTitle.TextSize = 11
        wornTitle.TextColor3 = Color3.fromRGB(160, 200, 255)
        wornTitle.TextXAlignment = Enum.TextXAlignment.Left
        wornTitle.Text = "ITEM DIPAKAI SAAT INI (KLIK CHIP UNTUK LEPAS):"
        wornTitle.Parent = wornPanel

        local unwearBtn = Instance.new("TextButton")
        unwearBtn.Size = UDim2.new(0, 96, 0, 20)
        unwearBtn.Position = UDim2.new(1, -102, 0, 4)
        unwearBtn.BackgroundColor3 = Color3.fromRGB(170, 45, 45)
        unwearBtn.Font = Enum.Font.GothamMedium
        unwearBtn.TextSize = 10
        unwearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        unwearBtn.Text = "UNWEAR ALL"
        unwearBtn.Parent = wornPanel

        local unwearCorner = Instance.new("UICorner")
        unwearCorner.CornerRadius = UDim.new(0, 4)
        unwearCorner.Parent = unwearBtn

        unwearBtn.MouseButton1Click:Connect(function()
            scUnwearAll()
        end)

        local wornScroll = Instance.new("ScrollingFrame")
        wornScroll.Size = UDim2.new(1, -16, 0, 38)
        wornScroll.Position = UDim2.new(0, 8, 0, 26)
        wornScroll.BackgroundTransparency = 1
        wornScroll.BorderSizePixel = 0
        wornScroll.ScrollBarThickness = 3
        wornScroll.ScrollingDirection = Enum.ScrollingDirection.X
        wornScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
        wornScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        wornScroll.Parent = wornPanel

        local wornLayout = Instance.new("UIListLayout")
        wornLayout.FillDirection = Enum.FillDirection.Horizontal
        wornLayout.Padding = UDim.new(0, 6)
        wornLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        wornLayout.Parent = wornScroll

        -- Info Jumlah & Petunjuk Double Tap
        local countLabel = Instance.new("TextLabel")
        countLabel.Size = UDim2.new(1, -16, 0, 18)
        countLabel.Position = UDim2.new(0, 8, 0, 80)
        countLabel.BackgroundTransparency = 1
        countLabel.Font = Enum.Font.Gotham
        countLabel.TextSize = 11
        countLabel.TextColor3 = Color3.fromRGB(185, 185, 195)
        countLabel.TextXAlignment = Enum.TextXAlignment.Left
        countLabel.Text = "Memuat daftar pakaian..."
        countLabel.Parent = holder

        -- ScrollingFrame Daftar Card Pakaian
        local listScroll = Instance.new("ScrollingFrame")
        listScroll.Name = "ClothesListScroll"
        listScroll.Size = UDim2.new(1, -16, 1, -108)
        listScroll.Position = UDim2.new(0, 8, 0, 102)
        listScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
        listScroll.BorderSizePixel = 0
        listScroll.ScrollBarThickness = 5
        listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        listScroll.Parent = holder

        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 6)
        listCorner.Parent = listScroll

        local listLayout = Instance.new("UIListLayout")
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = listScroll

        local listPad = Instance.new("UIPadding")
        listPad.PaddingTop = UDim.new(0, 6)
        listPad.PaddingBottom = UDim.new(0, 6)
        listPad.PaddingLeft = UDim.new(0, 6)
        listPad.PaddingRight = UDim.new(0, 6)
        listPad.Parent = listScroll

        local function refreshWornChips()
            for _, ch in ipairs(wornScroll:GetChildren()) do
                if ch:IsA("GuiObject") then ch:Destroy() end
            end
            local W = SC.Worn
            if not W or not SC.DB then
                local emptyLbl = Instance.new("TextLabel")
                emptyLbl.Size = UDim2.new(0, 240, 0, 28)
                emptyLbl.BackgroundTransparency = 1
                emptyLbl.Font = Enum.Font.Gotham
                emptyLbl.TextSize = 11
                emptyLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
                emptyLbl.TextXAlignment = Enum.TextXAlignment.Left
                emptyLbl.Text = "Belum ada data worn / masuk ke world dulu"
                emptyLbl.Parent = wornScroll
                return
            end

            local any = false
            for slot, id in pairs(W) do
                local it = SC.DB[id]
                if it then
                    any = true
                    local isVis = SC.Ov[slot] ~= nil
                    local chip = Instance.new("TextButton")
                    chip.Size = UDim2.new(0, 0, 0, 28)
                    chip.AutomaticSize = Enum.AutomaticSize.X
                    chip.BackgroundColor3 = isVis and Color3.fromRGB(35, 85, 145) or Color3.fromRGB(42, 42, 52)
                    chip.Font = Enum.Font.GothamMedium
                    chip.TextSize = 11
                    chip.TextColor3 = Color3.fromRGB(245, 245, 250)
                    chip.Text = string.format("  [%s] %s (%d) ×  ", slot:upper(), it.name, id)
                    chip.Parent = wornScroll

                    local cc = Instance.new("UICorner")
                    cc.CornerRadius = UDim.new(0, 5)
                    cc.Parent = chip

                    chip.MouseButton1Click:Connect(function()
                        scToggleSingleItem(id)
                    end)
                end
            end

            if not any then
                local noneLbl = Instance.new("TextLabel")
                noneLbl.Size = UDim2.new(0, 220, 0, 28)
                noneLbl.BackgroundTransparency = 1
                noneLbl.Font = Enum.Font.Gotham
                noneLbl.TextSize = 11
                noneLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
                noneLbl.TextXAlignment = Enum.TextXAlignment.Left
                noneLbl.Text = "Tidak ada item yang sedang dipakai"
                noneLbl.Parent = wornScroll
            end
        end

        local function rebuildListCards()
            scBuildItems()
            refreshWornChips()

            for _, ch in ipairs(listScroll:GetChildren()) do
                if ch:IsA("GuiObject") then ch:Destroy() end
            end

            if not SC.Items or #SC.Items == 0 then
                countLabel.Text = "ItemDB kosong / gagal dimuat."
                return
            end

            local q = vnTrim(SC.SearchQuery):lower()
            local slotFilter = (SC.SelectedSlot or "All"):lower()
            local W = SC.Worn or {}

            local matched = {}
            for _, item in ipairs(SC.Items) do
                local slotOk = (slotFilter == "all") or (item.slot == slotFilter)
                local searchOk = (q == "")
                    or item.lname:find(q, 1, true)
                    or tostring(item.id):find(q, 1, true)
                    or item.slot:find(q, 1, true)
                    or item.assetNum:find(q, 1, true)
                if slotOk and searchOk then
                    matched[#matched + 1] = item
                end
            end

            local maxShow = math.min(#matched, 250)
            countLabel.Text = string.format(
                "Menampilkan %d dari %d item (Filter: %s) — Tap 2x kartu untuk Pakai/Lepas",
                maxShow, #matched, SC.SelectedSlot or "All"
            )

            for i = 1, maxShow do
                local item = matched[i]
                local isEquipped = (W[item.slot] == item.id)

                local card = Instance.new("TextButton")
                card.Name = "ItemCard_" .. tostring(item.id)
                card.LayoutOrder = i
                card.Size = UDim2.new(1, 0, 0, 54)
                card.BackgroundColor3 = isEquipped and Color3.fromRGB(28, 62, 42) or Color3.fromRGB(24, 24, 30)
                card.BorderSizePixel = 0
                card.AutoButtonColor = true
                card.Text = ""
                card.Parent = listScroll

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(0, 6)
                cCorner.Parent = card

                local cStroke = Instance.new("UIStroke")
                cStroke.Color = isEquipped and Color3.fromRGB(70, 190, 110) or Color3.fromRGB(45, 45, 55)
                cStroke.Thickness = 1
                cStroke.Parent = card

                -- Icon Frame & Roblox Asset Image
                local iconBg = Instance.new("Frame")
                iconBg.Size = UDim2.new(0, 42, 0, 42)
                iconBg.Position = UDim2.new(0, 6, 0, 6)
                iconBg.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
                iconBg.BorderSizePixel = 0
                iconBg.Parent = card

                local iCorner = Instance.new("UICorner")
                iCorner.CornerRadius = UDim.new(0, 5)
                iCorner.Parent = iconBg

                local img = Instance.new("ImageLabel")
                img.Size = UDim2.new(1, -4, 1, -4)
                img.Position = UDim2.new(0, 2, 0, 2)
                img.BackgroundTransparency = 1
                img.Image = item.icon or "rbxassetid://0"
                img.ScaleType = Enum.ScaleType.Fit
                if typeof(item.rectOffset) == "Vector2" then img.ImageRectOffset = item.rectOffset end
                if typeof(item.rectSize) == "Vector2" then img.ImageRectSize = item.rectSize end
                img.Parent = iconBg

                -- Nama Item + ID + Slot
                local titleLbl = Instance.new("TextLabel")
                titleLbl.Size = UDim2.new(1, -145, 0, 22)
                titleLbl.Position = UDim2.new(0, 56, 0, 6)
                titleLbl.BackgroundTransparency = 1
                titleLbl.Font = Enum.Font.GothamMedium
                titleLbl.TextSize = 13
                titleLbl.TextColor3 = Color3.fromRGB(245, 245, 250)
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
                titleLbl.Text = string.format("%s  [ID: %d]", item.name, item.id)
                titleLbl.Parent = card

                -- Sub-info: Slot & Roblox Asset ID
                local subLbl = Instance.new("TextLabel")
                subLbl.Size = UDim2.new(1, -145, 0, 18)
                subLbl.Position = UDim2.new(0, 56, 0, 28)
                subLbl.BackgroundTransparency = 1
                subLbl.Font = Enum.Font.Gotham
                subLbl.TextSize = 11
                subLbl.TextColor3 = Color3.fromRGB(165, 165, 178)
                subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.TextTruncate = Enum.TextTruncate.AtEnd
                subLbl.Text = string.format("Slot: %s  •  Asset: %s%s", item.slot:upper(), tostring(item.icon), item.doubleJump and "  •  [2x Jump]" or "")
                subLbl.Parent = card

                -- Badge Status (DIPAKAI / DOUBLE TAP)
                local badge = Instance.new("TextLabel")
                badge.Size = UDim2.new(0, 78, 0, 24)
                badge.Position = UDim2.new(1, -86, 0.5, -12)
                badge.BackgroundColor3 = isEquipped and Color3.fromRGB(45, 150, 80) or Color3.fromRGB(36, 36, 44)
                badge.Font = Enum.Font.GothamMedium
                badge.TextSize = 10
                badge.TextColor3 = Color3.fromRGB(255, 255, 255)
                badge.Text = isEquipped and "DIPAKAI" or "2x TAP"
                badge.Parent = card

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 4)
                bCorner.Parent = badge

                card.MouseButton1Click:Connect(function()
                    local now = os.clock()
                    if SC.LastTapId == item.id and (now - SC.LastTapTime) <= 0.45 then
                        SC.LastTapId = nil
                        SC.LastTapTime = 0
                        scToggleSingleItem(item.id)
                    else
                        SC.LastTapId = item.id
                        SC.LastTapTime = now
                        badge.Text = "TAP LAGI!"
                        task.delay(0.46, function()
                            if badge and badge.Parent and SC.LastTapId == item.id then
                                local curW = SC.Worn or {}
                                badge.Text = (curW[item.slot] == item.id) and "DIPAKAI" or "2x TAP"
                            end
                        end)
                    end
                end)
            end
        end

        SC.UpdateUIFn = rebuildListCards
        rebuildListCards()
    end)
end

-- =========================================================================
-- LOGIKA MOD DETECTOR + ANTI-SPAM NOTIF + AUTO ACTION (EXIT/DIEM) + ESP
--  * Deteksi berdasarkan Roles module, Player Attributes, dan Character/Hidden state
--  * Notifikasi Anti-Spam: setiap moderator di world hanya dinotifikasi 1x per sesi
--  * Pilihan Method: Auto Exit World, Diem (Freeze + Stop Spam), atau Notify Only
--  * ESP Garis (Tracer) & Highlight Box menuju lokasi Mod (termasuk saat Hide/Invis)
-- =========================================================================
local ModSys = {
    RolesModule = nil,
    ActiveMods = {},      -- [Player] = { name, role, notified }
    ESPObjects = {},      -- [Player] = { box, bill, label, line }
    OverlayGui = nil,
    StatusLabel = nil,
    FrozenPos = nil,
}

pcall(function()
    local sh = ReplicatedStorage:WaitForChild("Shared", 5)
    if sh and sh:FindFirstChild("Roles") then
        ModSys.RolesModule = require(sh.Roles)
    end
end)

local MOD_KEYWORDS = {
    "mod", "moderator", "admin", "administrator", "dev", "developer",
    "owner", "staff", "gm", "gamemaster", "guardian", "helper", "supermod"
}

local function isModRoleValue(val)
    if val == nil then return false, nil end
    if type(val) == "boolean" then
        return val, val and "Staff/Mod" or nil
    elseif type(val) == "number" then
        if val >= 2 then return true, "RoleLv." .. tostring(val) end
    elseif type(val) == "string" then
        local lv = val:lower()
        if lv == "none" or lv == "player" or lv == "user" or lv == "member" or lv == "vip" then
            return false, nil
        end
        for _, kw in ipairs(MOD_KEYWORDS) do
            if lv:find(kw, 1, true) then
                return true, val
            end
        end
    end
    return false, nil
end

local function checkPlayerIsMod(plr)
    if not plr or plr == LocalPlayer then return false, nil end

    -- 1. Cek via modul ReplicatedStorage.Shared.Roles jika tersedia
    if type(ModSys.RolesModule) == "table" then
        for _, fnName in ipairs({ "isMod", "IsMod", "isAdmin", "IsAdmin", "isStaff", "getRole", "GetRole" }) do
            local fn = ModSys.RolesModule[fnName]
            if type(fn) == "function" then
                local ok, res = pcall(fn, plr)
                if not ok then ok, res = pcall(fn, ModSys.RolesModule, plr) end
                if ok and res then
                    local isM, roleTitle = isModRoleValue(res)
                    if isM then return true, roleTitle end
                end
            end
        end
        local listTbl = ModSys.RolesModule.Mods or ModSys.RolesModule.Admins or ModSys.RolesModule.Staff or ModSys.RolesModule.Users
        if type(listTbl) == "table" then
            local entry = listTbl[plr.UserId] or listTbl[tostring(plr.UserId)] or listTbl[plr.Name]
            local isM, roleTitle = isModRoleValue(entry)
            if isM then return true, roleTitle end
        end
    end

    -- 2. Cek semua Attributes pada Player
    local okAttr, attrs = pcall(function() return plr:GetAttributes() end)
    if okAttr and type(attrs) == "table" then
        for k, v in pairs(attrs) do
            local lk = tostring(k):lower()
            if lk:find("role") or lk:find("rank") or lk:find("mod") or lk:find("admin") or lk:find("staff") or lk:find("title") or lk:find("permission") or lk:find("level") then
                local isM, roleTitle = isModRoleValue(v)
                if isM then return true, tostring(k) .. ":" .. tostring(roleTitle) end
            end
        end
    end

    -- 3. Cek ValueObjects di dalam Player (leaderstats / data folder)
    for _, desc in ipairs(plr:GetDescendants()) do
        if desc:IsA("ValueBase") then
            local ln = desc.Name:lower()
            if ln:find("role") or ln:find("rank") or ln:find("mod") or ln:find("admin") or ln:find("staff") then
                local isM, roleTitle = isModRoleValue(desc.Value)
                if isM then return true, roleTitle end
            end
        end
    end

    -- 4. Cek prefix nama visual (`# atau `@ adalah prefix standar Moderator/Admin Growtopia)
    local nick = tostring(plr:GetAttribute("Nick") or plr.DisplayName or plr.Name)
    if nick:find("^`@") or nick:find("^`#") or nick:lower():find("^%[mod%]") or nick:lower():find("^%[admin%]") or nick:lower():find("^mod ") then
        return true, "Prefix:" .. nick
    end

    return false, nil
end

-- Cari posisi Moderator meskipun sedang Hide / Invisible / Vanish
local function getModWorldPosition(plr)
    if not plr then return nil, true end
    local char = plr.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
        if root then
            local isHidden = (root.Transparency >= 0.95) or (plr:GetAttribute("Hidden") == true) or (plr:GetAttribute("Invisible") == true)
            return root.Position, isHidden
        end
    end

    -- Jika Character di-unparent atau disembunyikan di folder khusus Workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == plr.Name or obj:GetAttribute("UserId") == plr.UserId or obj:GetAttribute("Owner") == plr.Name) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return part.Position, true
            end
        end
    end

    -- Cek apakah posisi disimpan di Attribute Player (2D/Grid coordinates)
    local px, py, pz = plr:GetAttribute("PosX") or plr:GetAttribute("X"), plr:GetAttribute("PosY") or plr:GetAttribute("Y"), plr:GetAttribute("PosZ") or plr:GetAttribute("Z")
    if type(px) == "number" and type(py) == "number" then
        return Vector3.new(px, py, type(pz) == "number" and pz or 0), true
    end

    return nil, true
end

local function executeAutoExitWorld(modName, roleName)
    local Net = scGetNet()
    if Net then
        for _, key in ipairs({ "leave", "exit", "quit", "leaveWorld", "exitWorld", "warp", "joinWorld" }) do
            local pkt = Net[key]
            if type(pkt) == "table" and type(pkt.send) == "function" then
                pcall(pkt.send, {})
                pcall(pkt.send, "EXIT")
            end
        end
    end
    local ch = findWorldChannel()
    if ch then
        pcall(function() ch:SendAsync("/exit") end)
        pcall(function() ch:SendAsync("/leave") end)
    end
    if getValue("Mod_HardKickOnExit", true) then
        task.delay(0.35, function()
            LocalPlayer:Kick(string.format("[R&8_DV SAFE EXIT] Moderator terdeteksi di World: %s (%s)", tostring(modName), tostring(roleName)))
        end)
    end
end

local function setFreezeState(freezeOn)
    Spam.PausedByMod = freezeOn
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    local hum = char:FindFirstChildOfClass("Humanoid")

    if freezeOn then
        if hrp and not ModSys.FrozenPos then
            ModSys.FrozenPos = hrp.CFrame
            hrp.Anchored = true
        end
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end
    else
        if hrp then hrp.Anchored = false end
        ModSys.FrozenPos = nil
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    end
end

local function ensureModOverlay()
    if ModSys.OverlayGui and ModSys.OverlayGui.Parent then return ModSys.OverlayGui end
    local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "R8DV_ModESP_Overlay"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = parent
    ModSys.OverlayGui = sg
    return sg
end

local function removeModESP(plr)
    local esp = ModSys.ESPObjects[plr]
    if esp then
        for _, v in pairs(esp) do
            pcall(function() if v and v.Destroy then v:Destroy() end end)
        end
        ModSys.ESPObjects[plr] = nil
    end
end

local function updateModESP()
    local espEnabled = getValue("Mod_ESP", true)
    if not espEnabled then
        for plr in pairs(ModSys.ESPObjects) do removeModESP(plr) end
        return
    end

    local sg = ensureModOverlay()
    Camera = Workspace.CurrentCamera
    if not Camera then return end

    local myPos2D = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.85)
    if LocalPlayer.Character then
        local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart
        if myRoot then
            local vp, onScr = Camera:WorldToViewportPoint(myRoot.Position)
            if onScr then myPos2D = Vector2.new(vp.X, vp.Y) end
        end
    end

    for plr, info in pairs(ModSys.ActiveMods) do
        if not plr or not plr.Parent then
            removeModESP(plr)
            ModSys.ActiveMods[plr] = nil
        else
            local esp = ModSys.ESPObjects[plr]
            if not esp then
                local line = Instance.new("Frame")
                line.Name = "Tracer_" .. plr.Name
                line.BackgroundColor3 = Color3.fromRGB(255, 45, 45)
                line.BorderSizePixel = 0
                line.AnchorPoint = Vector2.new(0.5, 0.5)
                line.Visible = false
                line.Parent = sg

                local box = Instance.new("Frame")
                box.Name = "Box_" .. plr.Name
                box.Size = UDim2.new(0, 64, 0, 64)
                box.AnchorPoint = Vector2.new(0.5, 0.5)
                box.BackgroundTransparency = 0.75
                box.BackgroundColor3 = Color3.fromRGB(255, 30, 30)
                box.BorderSizePixel = 0
                box.Visible = false
                box.Parent = sg

                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(255, 60, 60)
                stroke.Thickness = 2
                stroke.Parent = box

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0, 220, 0, 36)
                lbl.Position = UDim2.new(0.5, -110, 0, -40)
                lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
                lbl.BackgroundTransparency = 0.2
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 12
                lbl.TextColor3 = Color3.fromRGB(255, 90, 90)
                lbl.TextStrokeTransparency = 0.4
                lbl.Parent = box

                local lc = Instance.new("UICorner")
                lc.CornerRadius = UDim.new(0, 4)
                lc.Parent = lbl

                esp = { line = line, box = box, lbl = lbl }
                ModSys.ESPObjects[plr] = esp
            end

            local worldPos, isHidden = getModWorldPosition(plr)
            if worldPos then
                local vp, onScreen = Camera:WorldToViewportPoint(worldPos)
                local dist = 0
                if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                    dist = (LocalPlayer.Character.PrimaryPart.Position - worldPos).Magnitude
                end

                local target2D = Vector2.new(
                    math.clamp(vp.X, 40, Camera.ViewportSize.X - 40),
                    math.clamp(vp.Y, 40, Camera.ViewportSize.Y - 40)
                )
                if vp.Z < 0 then
                    target2D = Vector2.new(Camera.ViewportSize.X - target2D.X, Camera.ViewportSize.Y - 40)
                end

                local delta = target2D - myPos2D
                local len = delta.Magnitude
                local centerPt = (myPos2D + target2D) / 2
                local angle = math.deg(math.atan2(delta.Y, delta.X))

                esp.line.Position = UDim2.new(0, centerPt.X, 0, centerPt.Y)
                esp.line.Size = UDim2.new(0, len, 0, 2)
                esp.line.Rotation = angle
                esp.line.Visible = true

                esp.box.Position = UDim2.new(0, target2D.X, 0, target2D.Y)
                esp.box.Visible = true
                esp.lbl.Text = string.format(
                    "[MOD] %s (%s)\nStatus: %s | %.0f studs",
                    plr.Name, tostring(info.role), isHidden and "HIDDEN/INVIS" or "VISIBLE", dist
                )
            else
                -- Mod di world tapi koordinat belum ter-replicate (Full Server Vanish)
                local topPos = Vector2.new(Camera.ViewportSize.X / 2, 75)
                esp.box.Position = UDim2.new(0, topPos.X, 0, topPos.Y)
                esp.box.Visible = true
                esp.line.Visible = false
                esp.lbl.Text = string.format("[MOD VANISHED] %s (%s)\nBerada di World (Full Hide)", plr.Name, tostring(info.role))
            end
        end
    end
end

local function scanModerators()
    if not getValue("Mod_Enable", true) then
        if Spam.PausedByMod then setFreezeState(false) end
        for plr in pairs(ModSys.ESPObjects) do removeModESP(plr) end
        return
    end

    local currentMods = {}
    local modNamesList = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local isMod, roleName = checkPlayerIsMod(plr)
            if isMod then
                currentMods[plr] = true
                local existing = ModSys.ActiveMods[plr]
                if not existing then
                    existing = {
                        name = plr.Name,
                        role = roleName or "Moderator",
                        notified = false
                    }
                    ModSys.ActiveMods[plr] = existing
                end

                -- ANTI-SPAM ALERT: hanya beri tahu 1x saat Mod baru terdeteksi di world
                if not existing.notified then
                    existing.notified = true
                    notifyClient(
                        "⚠️ MODERATOR DETECTED!",
                        string.format("%s [%s] ada di dalam World!", plr.Name, tostring(existing.role)),
                        8
                    )
                end

                modNamesList[#modNamesList + 1] = string.format("%s (%s)", plr.Name, tostring(existing.role))
            end
        end
    end

    -- Bersihkan Mod yang sudah keluar dari world (supaya kalau join lagi nanti tetap dikasih tahu 1x)
    for plr in pairs(ModSys.ActiveMods) do
        if not currentMods[plr] then
            notifyClient("Mod Left", string.format("Moderator %s telah keluar dari World.", plr.Name), 4)
            ModSys.ActiveMods[plr] = nil
            removeModESP(plr)
        end
    end

    -- Tindakan Otomatis berdasarkan Method yang dipilih
    local hasAnyMod = (#modNamesList > 0)
    local actionOn = getValue("Mod_AutoAction", true)
    local method = getValue("Mod_Method", "Diem (Freeze + Stop Spam)")

    if hasAnyMod and actionOn then
        if method == "Auto Exit World" then
            local firstMod = modNamesList[1]
            executeAutoExitWorld(firstMod, "Moderator")
        elseif method == "Diem (Freeze + Stop Spam)" then
            setFreezeState(true)
        else
            if Spam.PausedByMod then setFreezeState(false) end
        end
    else
        if Spam.PausedByMod then setFreezeState(false) end
    end

    if ModSys.StatusLabel then
        pcall(function()
            if hasAnyMod then
                ModSys.StatusLabel.Text = "⚠️ MOD DI WORLD (" .. #modNamesList .. "): " .. table.concat(modNamesList, ", ")
                ModSys.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            else
                ModSys.StatusLabel.Text = "✅ AMAN: Tidak ada Moderator di World saat ini."
                ModSys.StatusLabel.TextColor3 = Color3.fromRGB(110, 230, 130)
            end
        end)
    end
end

Players.PlayerAdded:Connect(function()
    task.delay(0.5, scanModerators)
end)
Players.PlayerRemoving:Connect(function(plr)
    if ModSys.ActiveMods[plr] then
        ModSys.ActiveMods[plr] = nil
        removeModESP(plr)
    end
    task.defer(scanModerators)
end)

task.spawn(function()
    while true do
        task.wait(0.8)
        pcall(scanModerators)
    end
end)

RunService.RenderStepped:Connect(function()
    if getValue("Mod_Enable", true) and getValue("Mod_ESP", true) and next(ModSys.ActiveMods) ~= nil then
        pcall(updateModESP)
    end
end)

-- =========================================================================
-- KATEGORI 1: SPAMMER (DIPERTAHANKAN PENUH)
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
            { Text = "Otomatis berhenti sementara jika Mod masuk (Mode Diem)", Time = "Auto" }
        })
        if InfoCard.Button then
            InfoCard:Button("Reset Counter", "RESET", "Check", function()
                Spam.Sent = 0
                Spam.Index = 0
                print("[R&8_DV] Counter di-reset")
            end)
        end

        local ThemeCard = r:Card("Theme", nil, "Palette", {
            Subtitle = "Pilih palet warna & gaya checkbox"
        })
        if ThemeCard.ThemeSwatches then
            ThemeCard:ThemeSwatches("Colour Palette")
        end
        ThemeCard:Dropdown("Color Style", "ThemeSelect", ThemeChoices, "Minimalist Monochrome", function(selectedTheme)
            UI:SetTheme(selectedTheme)
        end)
        ThemeCard:Dropdown("Checkbox Style", "CheckboxStyleMode", { "Modern", "Checkbox" }, "Modern", function(mode)
            if UI.SetCheckboxStyle then UI:SetCheckboxStyle(mode) end
        end)
    end)
})

-- =========================================================================
-- KATEGORI 2: SET VISUAL NAME (DIPERTAHANKAN PENUH)
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
            Subtitle = "SET menerapkan, KEMBALI mengembalikan nama, warna, dan title awal"
        })
        CtrlCard:Button("Set Visual Name", "SET", "Bolt", function()
            vnSet()
        end)
        CtrlCard:Button("Kembali ke nama awal", "KEMBALI", "Check", function()
            vnReset()
        end)

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Hanya terlihat di layarmu. Klik SET lagi untuk menerapkan perubahan baru"
        })
    end)
})

-- =========================================================================
-- KATEGORI 3: SET CLOTHES + EMBEDDED VISUAL LISTCARD & ASSET ID
-- =========================================================================
pcall(scBuildItems)
if UI.Category then UI:Category("Set Clothes") end

feature("Item", "Set Clothes")({
    center = center(function(c)
        c:Header("Set Clothes & Visual Catalog", "Katalog pakaian lengkap dengan gambar Asset ID, Search, Filter Slot & Double-Tap Wear", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",         Value = "Client" },
            { Icon = "Shield", Label = "Kirim server", Value = "Diblokir" },
            { Icon = "Check",  Label = "Interaksi",    Value = "2x Tap Wear" }
        })

        local CatalogCard = c:Card("KATALOG VISUAL CLOTHES", nil, "Palette", {
            Subtitle = "Cari nama/ID/Asset, filter slot (mask, head, wing, dll), tap 2x pada item di bawah untuk langsung pakai"
        })
        CatalogCard:Input("Cari Nama / ID / Asset ID", "SC_Search", "Ketik untuk filter katalog secara langsung...", "", function(val)
            SC.SearchQuery = tostring(val or "")
            if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
        end)
        CatalogCard:Dropdown("Filter Kategori Slot", "SC_SlotFilter", SC.Slots, "All", function(slotVal)
            SC.SelectedSlot = tostring(slotVal or "All")
            if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
        end)

        local ManualCard = c:Card("Input Manual (Nama / ID)", nil, "Chat", {
            Subtitle = "Opsional: ketik beberapa nama atau ID dipisahkan koma lalu tekan SET"
        })
        ManualCard:Input("Nama / ID Item", "SC_Items", "contoh: Legendary Wings, 1784, Boots", "")
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Shortcut & Kontrol Pakaian", nil, "Bolt", {
            Subtitle = "Kelola semua item pakaian visual di karaktermu tanpa membuat jendela baru"
        })
        CtrlCard:Button("Pakai dari Kolom Input", "SET", "Bolt", function()
            scSet()
        end)
        CtrlCard:Button("Lepas Semua Item (Unwear All)", "UNWEAR ALL", "Shield", function()
            scUnwearAll()
        end)
        CtrlCard:Button("Kembali ke Pakaian Asli", "RESET AWAL", "Check", function()
            scReset()
        end)
        CtrlCard:Button("Refresh Visual Karakter & List", "REFRESH", "Bolt", function()
            scFindWorn()
            scForceCharacterRedraw()
            if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
            notifyClient("Set Clothes", "Visual karakter & daftar item diperbarui", 2)
        end)

        local JumpCard = r:Card("Anti Teleport Double Jump", nil, "Shield", {
            Subtitle = "Mencegah rubberband/tarik balik saat memakai sayap double-jump visual"
        })
        JumpCard:Dropdown("Mode Proteksi Jump", "SC_JumpMode", SC_JUMP_MODES, SC.JumpMode, function(mode)
            SC.JumpMode = mode
        end)
    end)
})

-- =========================================================================
-- KATEGORI 4: MODS & ANTI-DETECTION (BARU)
-- =========================================================================
if UI.Category then UI:Category("Safety & Mods") end

feature("Shield", "Mod Detector & Anti-Detect")({
    center = center(function(c)
        c:Header("Moderator Detector & ESP", "Deteksi Moderator/Admin masuk world, ESP lokasi (termasuk Hide/Vanish) & Auto Response", "Security")

        c:StatRow({
            { Icon = "Shield", Label = "Detector", Value = "Real-time" },
            { Icon = "Bolt",   Label = "Alert",    Value = "Anti-Spam (1x)" },
            { Icon = "Check",  Label = "ESP",      Value = "Visible + Hide" }
        })

        local ModCard = c:Card("MONITOR MODERATOR WORLD", nil, "Shield", {
            Subtitle = "Notifikasi siapa Mod yang masuk/ada di world tanpa spam berulang untuk Mod yang sama"
        })
        ModCard:Toggle("Aktifkan Mod Detector", "Mod_Enable", true, function()
            task.defer(scanModerators)
        end)
        ModCard:Toggle("Aktifkan Action Otomatis (Exit / Diem)", "Mod_AutoAction", true, function()
            task.defer(scanModerators)
        end)
        ModCard:Dropdown("Method Saat Ada Mod", "Mod_Method", {
            "Diem (Freeze + Stop Spam)",
            "Auto Exit World",
            "Notify Only (Hanya Kasih Tahu)"
        }, "Diem (Freeze + Stop Spam)", function()
            task.defer(scanModerators)
        end)
        ModCard:Toggle("ESP Garis & Box ke Lokasi Mod (Support Hide)", "Mod_ESP", true, function(st)
            if not st then
                for plr in pairs(ModSys.ESPObjects) do removeModESP(plr) end
            end
        end)
        ModCard:Toggle("Tahan Paket Gerak Saat Mode Diem", "Mod_FreezePacket", false)
        ModCard:Toggle("Force Disconnect Jika Paket Exit Ditolak", "Mod_HardKickOnExit", true)

        local ADCard = c:Card("Anti-Detection & Packet Traffic Guard", nil, "Bolt", {
            Subtitle = "Mencegah kick/ban akibat anomali paket pakaian visual, flag air-jump, dan flood traffic"
        })
        ADCard:Toggle("Master Anti-Detection Hook", "AD_Master", true, function(st)
            AD.Enabled = st
            if st then scHook() end
        end)
        ADCard:Toggle("Spoof Paket Wear (Server Hanya Tahu Baju Asli)", "AD_SpoofWear", true, function(st)
            AD.BlockVisualWear = st
        end)
        ADCard:Toggle("Sanitasi Flag AirJump & Movement Anomaly", "AD_SanitizeMove", true, function(st)
            AD.SanitizeMove = st
        end)
        ADCard:Toggle("Rate-Limit Packet Traffic (Cegah Kick Flood)", "AD_RateLimit", true, function(st)
            AD.RateLimitMove = st
        end)
        ADCard:Toggle("Humanize Chat Spammer Delay (Micro-Jitter)", "AD_ChatJitter", true)
    end),

    right = right(function(r)
        local StatusCard = r:Card("Status Moderator Saat Ini", nil, "Clock", {
            Subtitle = "Daftar Moderator yang terdeteksi di dalam world saat ini"
        })
        StatusCard:Button("Scan Ulang World Sekarang", "SCAN NOW", "Bolt", function()
            scanModerators()
            local list = {}
            for _, info in pairs(ModSys.ActiveMods) do
                list[#list + 1] = info.name .. " [" .. tostring(info.role) .. "]"
            end
            if #list > 0 then
                notifyClient("Hasil Scan Mod", "Terdeteksi: " .. table.concat(list, ", "), 5)
            else
                notifyClient("Hasil Scan Mod", "Aman! Tidak ada Moderator di world ini.", 3)
            end
        end)
        StatusCard:Button("Lepas Freeze Karakter Manual", "UNFREEZE", "Check", function()
            setFreezeState(false)
            notifyClient("Mod Detector", "Karakter di-unfreeze secara manual", 3)
        end)

        local TrafficCard = r:Card("Statistik Packet Guard", nil, "Shield", {
            Subtitle = "Bukti kerja filter paket client"
        })
        TrafficCard:Button("Cek Statistik Proteksi di Console", "CEK LOG", "Check", function()
            notifyClient(
                "Packet Guard",
                string.format("Disanitasi: %d pkt | Diblokir: %d pkt", AD.SanitizedPackets, AD.BlockedPackets),
                4
            )
        end)
    end)
})

-- Mount label status mod secara langsung di dalam kartu MONITOR MODERATOR WORLD
task.spawn(function()
    task.wait(1.0)
    for _, root in ipairs(lightFindRoots()) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text:find("MONITOR MODERATOR WORLD", 1, true) then
                local container = d.Parent
                while container and not (container:IsA("Frame") or container:IsA("ScrollingFrame")) do
                    container = container.Parent
                end
                if container and not container:FindFirstChild("R8DV_ModLiveBanner") then
                    local banner = Instance.new("TextLabel")
                    banner.Name = "R8DV_ModLiveBanner"
                    banner.Size = UDim2.new(1, 0, 0, 28)
                    banner.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                    banner.BorderSizePixel = 0
                    banner.Font = Enum.Font.GothamMedium
                    banner.TextSize = 11
                    banner.TextColor3 = Color3.fromRGB(110, 230, 130)
                    banner.Text = "✅ AMAN: Tidak ada Moderator di World saat ini."
                    banner.LayoutOrder = 95
                    banner.Parent = container

                    local bc = Instance.new("UICorner")
                    bc.CornerRadius = UDim.new(0, 6)
                    bc.Parent = banner

                    ModSys.StatusLabel = banner
                    scanModerators()
                end
                break
            end
        end
    end
end)

-- =========================================================================
-- KATEGORI 5: SETTINGS (DIPERTAHANKAN PENUH)
-- =========================================================================
if UI.Category then UI:Category("Settings") end

feature("Misc", "Misc")({
    center = center(function(c)
        c:Header("Misc", "Pengaturan jendela & utilitas", "Utility")

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
        WinCard:Toggle("Teks ringan (kurangi bold)", "LightText", true, function(state)
            if state then lightEnable() else lightDisable() end
        end)
    end),

    right = right(function(r)
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

-- Inisialisasi awal: pasang hook anti-detection, mount embedded listcard pakaian, dan aktifkan teks ringan
task.spawn(function()
    pcall(scHook)
    scMountEmbeddedBrowser()
    task.wait(1.5)
    if getValue("LightText", true) then pcall(lightEnable) end
end)
