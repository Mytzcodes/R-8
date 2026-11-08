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
            Duration = duration or 4
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
    if d:GetAttribute("R8DV_SkipLight") then return end
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
-- LOGIKA SET CLOTHES (IKON ASLI GAME + LIST SMOOTH + 1x TAP)
--  * Gambar item memakai ReplicatedStorage.Shared.ItemIcon (modul asli game).
--  * Katalog ter-virtualisasi, bisa dicari, scroll mulus.
--  * 1x tap = pakai / lepas. Lepas = slot kembali ke set awal, langsung
--    hilang dari bar "Sedang Dipakai".
-- =========================================================================
local SC = {
    DB = nil,
    ItemIcon = nil,
    Assets = nil,
    Items = nil,
    ItemMap = {},
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
    RefreshWornBarFn = nil,
    LastWornSignature = "",
}

local SC_JUMP_MODES = { "Tahan paket (disarankan)", "Samarkan flag saja", "Mati" }

local KNOWN_SLOTS = {
    hair = true, head = true, mask = true, face = true, eyes = true,
    chest = true, shirt = true, pants = true, shoes = true, feet = true,
    back = true, wing = true, wings = true, neck = true, hand = true,
    aura = true, pet = true, hat = true, ride = true, artifact = true,
    waist = true, ancestral = true,legs = true, body = true, Beard = true, beard = true
}

local function scLooksLikeWorn(t)
    if type(t) ~= "table" then return false end
    if rawget(t, "onWear") ~= nil or rawget(t, "refresh") ~= nil or rawget(t, "call") ~= nil then
        return false
    end
    local hasSlotKey = false
    for k, v in pairs(t) do
        if type(k) ~= "string" or type(v) ~= "number" then return false end
        if KNOWN_SLOTS[k] or KNOWN_SLOTS[k:lower()] then
            hasSlotKey = true
        end
    end
    return hasSlotKey or next(t) == nil
end

local function scFindWorn()
    if SC.Worn and SC.Game then return SC.Worn end
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    if sh and not SC.PlayerSprite then
        pcall(function() SC.PlayerSprite = require(sh:FindFirstChild("PlayerSprite")) end)
    end

    if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
        return nil, "Executor tidak mendukung getgc / debug.getupvalues"
    end

    local okGc, gc = pcall(getgc, true)
    if not okGc or type(gc) ~= "table" then return nil, "getgc gagal" end

    local fallbackGame, fallbackState, fallbackWorn

    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            local okF, fn = pcall(rawget, obj, "onWear")
            local okR, fnR = pcall(rawget, obj, "refresh")
            if okF and type(fn) == "function" then
                local okU, ups = pcall(debug.getupvalues, fn)
                if okU and type(ups) == "table" then
                    local worn, state
                    for _, up in pairs(ups) do
                        if type(up) == "table" then
                            if scLooksLikeWorn(up) then
                                if next(up) ~= nil then
                                    worn = up
                                elseif not worn then
                                    worn = up
                                end
                            end
                            if not state and (type(rawget(up, "call")) == "function" or type(rawget(up, "effects")) == "function") then
                                state = up
                            end
                        end
                    end
                    if not worn and type(fnR) == "function" then
                        local okUR, upsR = pcall(debug.getupvalues, fnR)
                        if okUR and type(upsR) == "table" then
                            for _, up in pairs(upsR) do
                                if type(up) == "table" and scLooksLikeWorn(up) then
                                    worn = up
                                    break
                                end
                            end
                        end
                    end
                    if worn then
                        if next(worn) ~= nil then
                            SC.Game, SC.State, SC.Worn = obj, state, worn
                            return worn
                        elseif not fallbackWorn then
                            fallbackGame, fallbackState, fallbackWorn = obj, state, worn
                        end
                    end
                end
            end
        end
    end

    if fallbackWorn then
        SC.Game, SC.State, SC.Worn = fallbackGame, fallbackState, fallbackWorn
        return fallbackWorn
    end

    return nil, "Tabel pakaian belum ditemukan (pastikan sudah masuk ke dalam world)"
end

-- =========================================================================
-- IKON ITEM: MEMAKAI MODUL ASLI GAME (ItemIcon.new / ItemIcon.set)
--  ItemIcon.set membaca atlas + tx/ty + tint dari ItemDB dengan benar
--  (termasuk aloneCell & aturan sepatu), jadi gambar selalu cocok dengan
--  tampilan di inventori game. Ada fallback manual bila modul gagal.
-- =========================================================================
local function scAtlasUrl(atlasName)
    if type(atlasName) ~= "string" then return nil end
    local A = SC.Assets and SC.Assets.Atlas
    if type(A) == "table" then return A[atlasName] end
    return nil
end

-- Buat 1 ikon (Frame + layer Base/Over) di dalam holder. Dibuat sekali, dipakai ulang.
local function scMakeIcon(holder, z)
    local II = SC.ItemIcon
    if type(II) == "table" and type(II.new) == "function" then
        local ok, res = pcall(II.new, holder, UDim2.new(1, -6, 1, -6), z or 3)
        if ok and type(res) == "table" and typeof(res.frame) == "Instance" and res.base and res.over then
            res.frame.Position = UDim2.fromOffset(3, 3)
            return res
        end
    end
    -- fallback: struktur sama dengan ItemIcon.new
    local f = Instance.new("Frame")
    f.Name = "Icon"
    f.BackgroundTransparency = 1
    f.Size = UDim2.new(1, -6, 1, -6)
    f.Position = UDim2.fromOffset(3, 3)
    f.ZIndex = z or 3
    f.Parent = holder
    local function layer(n)
        local l = Instance.new("ImageLabel")
        l.Name = n
        l.BackgroundTransparency = 1
        l.Size = UDim2.fromScale(1, 1)
        l.AnchorPoint = Vector2.new(0.5, 0.5)
        l.Position = UDim2.fromScale(0.5, 0.5)
        l.ResampleMode = Enum.ResamplerMode.Pixelated
        l.ZIndex = z or 3
        l.Parent = f
        return l
    end
    return { frame = f, base = layer("Base"), over = layer("Over") }
end

-- Isi ikon dengan gambar item `id`
local function scSetIcon(icon, id)
    if not icon then return end
    local II = SC.ItemIcon
    if type(II) == "table" and type(II.set) == "function" then
        if pcall(II.set, icon, id) then return end
    end
    -- fallback manual (meniru ItemIcon.set untuk item atlas)
    local it = SC.DB and SC.DB[id]
    local url = it and scAtlasUrl(it.atlas)
    if not url then
        icon.frame.Visible = false
        return
    end
    local cx, cy = it.tx or 0, it.ty or 0
    if SC.Autotile and type(SC.Autotile.aloneCell) == "function" then
        local ok, a, b = pcall(SC.Autotile.aloneCell, it)
        if ok and type(a) == "number" and type(b) == "number" then cx, cy = a, b end
    end
    if it.kind == "cloth" and it.slot == "feet" then cy = cy * 2 end
    icon.base.Image = url
    icon.base.ImageRectSize = Vector2.new(32, 32)
    icon.base.ImageRectOffset = Vector2.new(cx * 32, cy * 32)
    icon.base.ImageColor3 = it.tint or Color3.new(1, 1, 1)
    icon.base.Size = UDim2.fromScale(1, 1)
    local oc = it.overCell
    icon.over.Visible = oc ~= nil
    if oc then
        icon.over.Image = url
        icon.over.ImageRectSize = Vector2.new(32, 32)
        icon.over.ImageRectOffset = Vector2.new(oc[1] * 32, oc[2] * 32)
        icon.over.ImageColor3 = Color3.new(1, 1, 1)
        icon.over.Size = UDim2.fromScale(1, 1)
    end
    icon.frame.Visible = true
end

local function scBuildItems()
    if SC.Items and #SC.Items > 0 then return true end
    local sh = ReplicatedStorage:WaitForChild("Shared", 5)
    if not sh then return false end

    local ok, DB = pcall(function() return require(sh:WaitForChild("ItemDB", 5)) end)
    if not ok or type(DB) ~= "table" then return false end

    pcall(function() SC.ItemIcon = require(sh:FindFirstChild("ItemIcon")) end)
    pcall(function() SC.Assets = require(sh:FindFirstChild("Assets")) end)
    pcall(function() SC.Autotile = require(sh:FindFirstChild("Autotile")) end)
    pcall(function() SC.PlayerSprite = require(sh:FindFirstChild("PlayerSprite")) end)

    local items, itemMap, slotMap = {}, {}, {}

    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" then
            local isCloth = (it.kind == "cloth" or it.kind == "clothes" or it.kind == "wearable"
                or (type(it.slot) == "string" and it.slot ~= ""))
            if isCloth and type(it.slot) == "string" and type(it.name) == "string" and not it.name:find(" Seed$") then
                local url = scAtlasUrl(it.atlas)
                local num = url and tostring(url):match("(%d+)") or "-"
                local slotClean = it.slot:lower()
                slotMap[slotClean] = true
                local entry = {
                    id = id,
                    name = it.name,
                    lname = it.name:lower(),
                    slot = slotClean,
                    icon = url,
                    assetNum = num,
                    doubleJump = it.doubleJump and true or false,
                    raw = it,
                }
                items[#items + 1] = entry
                itemMap[id] = entry
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
    SC.ItemMap = itemMap
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
end

local function scGetWornSignature()
    local W = SC.Worn
    if not W then return "nil" end
    local parts = {}
    for k, v in pairs(W) do
        parts[#parts + 1] = tostring(k) .. ":" .. tostring(v)
    end
    table.sort(parts)
    return table.concat(parts, "|")
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
    SC.LastWornSignature = scGetWornSignature()
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
    local W = SC.Worn or scFindWorn()
    if not W then return end

    if next(SC.Ov) ~= nil then
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
        end
    end

    local sig = scGetWornSignature()
    if sig ~= SC.LastWornSignature then
        SC.LastWornSignature = sig
        if SC.RefreshWornBarFn then pcall(SC.RefreshWornBarFn) end
    end
end

local function scEnsureLoop()
    if SC.Loop then return end
    SC.Loop = true
    task.spawn(function()
        while true do
            task.wait(0.3)
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

-- Lepas 1 slot = kembalikan slot itu ke SET AWAL (pakaian asli dari server).
-- Kalau slot itu memang item asli (bukan hasil pasang visual), item dilepas.
-- Tanpa notifikasi supaya tap terasa langsung.
local function scRemoveSlot(slotName)
    local worn, err = scFindWorn()
    if not worn then
        notifyClient("Set Clothes", tostring(err), 3)
        return
    end
    scBuildItems()
    scHook()
    scEnsureLoop()

    scMutate(function(W)
        local o = SC.Ov[slotName]
        if o then
            W[slotName] = o.real
        else
            W[slotName] = nil
        end
    end)
end

-- 1x tap pada item di katalog: pakai kalau belum dipakai, kembali ke awal kalau sudah dipakai
local function scTapItem(id)
    local worn, err = scFindWorn()
    if not worn then
        notifyClient("Set Clothes", tostring(err), 4)
        return
    end
    if not scBuildItems() then return end
    scHook()
    scEnsureLoop()

    local it = SC.DB[id]
    if not it or type(it.slot) ~= "string" then return end

    if worn[it.slot] == id then
        scRemoveSlot(it.slot)
    else
        scMutate(function(W)
            scWearInto(W, id)
        end)
    end
end

-- Unwear All (lepas semua pakaian secara visual di client)
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
end

local function scSet()
    local raw = tostring(getValue("SC_Items", ""))
    local tokens = {}
    for t in string.gmatch(raw, "[^,\n]+") do
        t = vnTrim(t)
        if t ~= "" then tokens[#tokens + 1] = t end
    end
    if #tokens == 0 then
        notifyClient("Set Clothes", "Isi kolom item atau tap 2x pada kartu di katalog!", 3)
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
-- HELPER UI: FONT, LIST TER-VIRTUALISASI (SMOOTH), PENCARI ANCHOR
-- =========================================================================
local UIFONT = {
    bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
    med  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
    reg  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
}

local function lockFont(guiObj, fontFace)
    guiObj:SetAttribute("R8DV_SkipLight", true)
    guiObj.FontFace = fontFace
    guiObj:GetPropertyChangedSignal("FontFace"):Connect(function()
        if guiObj.FontFace ~= fontFace then
            guiObj.FontFace = fontFace
        end
    end)
end

local function uiCorner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function uiStroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color
    s.Thickness = thick or 1
    s.Parent = parent
    return s
end

local function uiLabel(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextSize = size
    l.TextColor3 = color
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = text
    lockFont(l, font or UIFONT.med)
    l.Parent = parent
    return l
end

-- List virtual: hanya ~12 baris yang benar-benar dibuat (di-pool), isinya di-bind ulang
-- saat scroll. Jumlah item ribuan pun tetap ringan dan scroll mulus.
--   opts.rowH, opts.gap, opts.pad, opts.size, opts.position, opts.bg
--   opts.makeRow(scroll) -> { frame = GuiObject, ... }
--   opts.bind(row, item, idx)
local function newVList(parent, opts)
    local rowH = opts.rowH
    local gap = opts.gap or 6
    local pad = opts.pad or 8
    local step = rowH + gap

    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = opts.name or "VList"
    scroll.Size = opts.size
    scroll.Position = opts.position
    scroll.BackgroundColor3 = opts.bg or Color3.fromRGB(12, 13, 17)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 100)
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.CanvasSize = UDim2.new()
    scroll.Parent = parent
    uiCorner(scroll, 8)
    uiStroke(scroll, Color3.fromRGB(32, 34, 42), 1)

    local V = { Scroll = scroll, Data = {}, Pool = {} }

    local function ensurePool()
        local h = scroll.AbsoluteWindowSize.Y
        if h <= 0 then h = 360 end
        local need = math.ceil(h / step) + 3
        while #V.Pool < need do
            local row = opts.makeRow(scroll)
            row.frame.Size = UDim2.new(1, -(pad * 2 + 6), 0, rowH)
            row.frame.Visible = false
            V.Pool[#V.Pool + 1] = row
        end
        return #V.Pool
    end

    function V:Layout()
        local n = ensurePool()
        local data = self.Data
        local total = #data
        local top = scroll.CanvasPosition.Y
        local first = math.max(1, math.floor((top - pad) / step) + 1)
        local last = math.min(total, first + n - 1)
        local used = {}
        for idx = first, last do
            local row = self.Pool[(idx - 1) % n + 1]
            used[row] = true
            local item = data[idx]
            if row.idx ~= idx or row.item ~= item or row.dirty then
                row.idx = idx
                row.item = item
                row.dirty = false
                row.frame.Position = UDim2.new(0, pad, 0, pad + (idx - 1) * step)
                opts.bind(row, item, idx)
            end
            row.frame.Visible = true
        end
        for _, row in ipairs(self.Pool) do
            if not used[row] then
                row.frame.Visible = false
                row.idx = nil
                row.item = nil
            end
        end
    end

    function V:SetData(data, toTop)
        self.Data = data or {}
        local total = #self.Data
        local h = total > 0 and (pad * 2 + total * step - gap) or 0
        scroll.CanvasSize = UDim2.fromOffset(0, h)
        if toTop then scroll.CanvasPosition = Vector2.new(0, 0) end
        for _, row in ipairs(self.Pool) do row.dirty = true end
        self:Layout()
    end

    -- bind ulang baris yang sedang tampil (mis. setelah status pakai berubah)
    function V:Refresh()
        for _, row in ipairs(self.Pool) do row.dirty = true end
        self:Layout()
    end

    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() V:Layout() end)
    scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function() V:Layout() end)
    return V
end

-- Cari card (berdasarkan teks judul) lalu kembalikan container Frame-nya
local function findAnchorContainer(text, tries, waitT)
    for _ = 1, tries or 20 do
        for _, root in ipairs(lightFindRoots()) do
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:find(text, 1, true) then
                    local c = d.Parent
                    while c and not (c:IsA("Frame") or c:IsA("ScrollingFrame")) do
                        c = c.Parent
                    end
                    if c then return c, d end
                end
            end
        end
        task.wait(waitT or 0.3)
    end
    return nil
end

-- =========================================================================
-- BROWSER CLOTHES (EMBEDDED, TANPA WINDOW BARU)
--  * Atas  : "Sedang Dipakai" (kartu mini + ikon asli). 1x tap = lepas /
--            kembali ke set awal untuk slot itu, langsung hilang dari bar.
--  * Bawah : Katalog semua item, list ter-virtualisasi (smooth), bisa
--            dicari (nama / ID / slot / asset). 1x tap = pakai / lepas.
-- =========================================================================
local function scMountEmbeddedBrowser()
    task.spawn(function()
        task.wait(0.8)
        scBuildItems()
        pcall(scFindWorn)
        scEnsureLoop()

        local cardContainer = findAnchorContainer("KATALOG VISUAL CLOTHES", 30, 0.3)
        if not cardContainer then return end
        local oldBrowser = cardContainer:FindFirstChild("R8DV_EmbeddedClothesBrowser")
        if oldBrowser then oldBrowser:Destroy() end

        local holder = Instance.new("Frame")
        holder.Name = "R8DV_EmbeddedClothesBrowser"
        holder.Size = UDim2.new(1, 0, 0, 480)
        holder.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
        holder.BorderSizePixel = 0
        holder.LayoutOrder = 99
        holder.Parent = cardContainer
        uiCorner(holder, 10)
        uiStroke(holder, Color3.fromRGB(38, 40, 48), 1)

        -- ---------------- PANEL ATAS: SEDANG DIPAKAI ----------------
        local wornPanel = Instance.new("Frame")
        wornPanel.Name = "WornStatusPanel"
        wornPanel.Size = UDim2.new(1, -20, 0, 96)
        wornPanel.Position = UDim2.new(0, 10, 0, 10)
        wornPanel.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
        wornPanel.BorderSizePixel = 0
        wornPanel.Parent = holder
        uiCorner(wornPanel, 8)
        uiStroke(wornPanel, Color3.fromRGB(44, 48, 58), 1)

        local headerBar = Instance.new("Frame")
        headerBar.Size = UDim2.new(1, -20, 0, 26)
        headerBar.Position = UDim2.new(0, 10, 0, 6)
        headerBar.BackgroundTransparency = 1
        headerBar.Parent = wornPanel

        local statusDot = Instance.new("Frame")
        statusDot.Size = UDim2.new(0, 7, 0, 7)
        statusDot.Position = UDim2.new(0, 0, 0.5, -3)
        statusDot.BackgroundColor3 = Color3.fromRGB(72, 199, 142)
        statusDot.BorderSizePixel = 0
        statusDot.Parent = headerBar
        uiCorner(statusDot, 99)

        local wornTitle = uiLabel(headerBar, "SEDANG DIPAKAI", 11, Color3.fromRGB(220, 225, 235), UIFONT.bold)
        wornTitle.Size = UDim2.new(1, -135, 1, 0)
        wornTitle.Position = UDim2.new(0, 13, 0, 0)

        local unwearBtn = Instance.new("TextButton")
        unwearBtn.Name = "UnwearAllBtn"
        unwearBtn.Size = UDim2.new(0, 108, 0, 24)
        unwearBtn.Position = UDim2.new(1, -108, 0.5, -12)
        unwearBtn.BackgroundColor3 = Color3.fromRGB(45, 22, 26)
        unwearBtn.AutoButtonColor = false
        unwearBtn.TextSize = 10
        unwearBtn.TextColor3 = Color3.fromRGB(255, 115, 125)
        unwearBtn.Text = "×  LEPAS SEMUA"
        lockFont(unwearBtn, UIFONT.bold)
        unwearBtn.Parent = headerBar
        uiCorner(unwearBtn, 6)
        uiStroke(unwearBtn, Color3.fromRGB(165, 55, 65), 1)
        unwearBtn.Activated:Connect(function() scUnwearAll() end)

        local wornScroll = Instance.new("ScrollingFrame")
        wornScroll.Name = "WornItemsScroll"
        wornScroll.Size = UDim2.new(1, -20, 0, 54)
        wornScroll.Position = UDim2.new(0, 10, 0, 36)
        wornScroll.BackgroundTransparency = 1
        wornScroll.BorderSizePixel = 0
        wornScroll.ScrollBarThickness = 3
        wornScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 95, 110)
        wornScroll.ScrollingDirection = Enum.ScrollingDirection.X
        wornScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
        wornScroll.CanvasSize = UDim2.new()
        wornScroll.Parent = wornPanel

        local wornLayout = Instance.new("UIListLayout")
        wornLayout.FillDirection = Enum.FillDirection.Horizontal
        wornLayout.Padding = UDim.new(0, 8)
        wornLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        wornLayout.Parent = wornScroll

        local countLabel = uiLabel(holder, "Memuat katalog pakaian...", 11, Color3.fromRGB(155, 160, 175), UIFONT.med)
        countLabel.Size = UDim2.new(1, -20, 0, 20)
        countLabel.Position = UDim2.new(0, 12, 0, 112)

        -- ---------------- STATE ----------------
        local vlist
        local matched = {}

        -- ---------------- BAR "SEDANG DIPAKAI" ----------------
        local function infoPill(text, w)
            local pill = Instance.new("Frame")
            pill.Size = UDim2.new(0, w, 0, 42)
            pill.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
            pill.BorderSizePixel = 0
            pill.Parent = wornScroll
            uiCorner(pill, 6)
            local l = uiLabel(pill, text, 11, Color3.fromRGB(145, 150, 165), UIFONT.reg)
            l.Size = UDim2.new(1, -16, 1, 0)
            l.Position = UDim2.new(0, 10, 0, 0)
        end

        local function refreshWornChips()
            for _, ch in ipairs(wornScroll:GetChildren()) do
                if ch:IsA("GuiObject") then ch:Destroy() end
            end

            local W = SC.Worn or scFindWorn()
            if not W or not SC.DB then
                statusDot.BackgroundColor3 = Color3.fromRGB(240, 170, 60)
                wornTitle.Text = "SEDANG DIPAKAI"
                infoPill("Masuk ke dalam World terlebih dahulu untuk memuat pakaian.", 310)
                return
            end

            local entries = {}
            for slot, id in pairs(W) do
                local dbIt = SC.DB[id]
                if dbIt then
                    entries[#entries + 1] = { slot = slot, id = id, name = dbIt.name or ("Item #" .. tostring(id)) }
                end
            end
            table.sort(entries, function(a, b) return tostring(a.slot) < tostring(b.slot) end)

            if #entries == 0 then
                statusDot.BackgroundColor3 = Color3.fromRGB(120, 125, 140)
                wornTitle.Text = "SEDANG DIPAKAI (0)  •  BELUM ADA ITEM AKTIF"
                infoPill("Tidak ada pakaian dipakai. Tap item di katalog di bawah.", 300)
                return
            end

            statusDot.BackgroundColor3 = Color3.fromRGB(72, 199, 142)
            wornTitle.Text = string.format("SEDANG DIPAKAI (%d)  •  TAP 1x = LEPAS / KEMBALI KE AWAL", #entries)

            for _, e in ipairs(entries) do
                local isVis = SC.Ov[e.slot] ~= nil

                local chip = Instance.new("TextButton")
                chip.Name = "WornCard_" .. tostring(e.slot)
                chip.Size = UDim2.new(0, 175, 0, 46)
                chip.BackgroundColor3 = isVis and Color3.fromRGB(24, 34, 48) or Color3.fromRGB(28, 30, 38)
                chip.AutoButtonColor = false
                chip.Text = ""
                chip.Parent = wornScroll
                uiCorner(chip, 7)
                local cs = uiStroke(chip, isVis and Color3.fromRGB(65, 135, 220) or Color3.fromRGB(52, 56, 68), 1)

                local iconHolder = Instance.new("Frame")
                iconHolder.Size = UDim2.new(0, 34, 0, 34)
                iconHolder.Position = UDim2.new(0, 6, 0.5, -17)
                iconHolder.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
                iconHolder.BorderSizePixel = 0
                iconHolder.Parent = chip
                uiCorner(iconHolder, 5)
                scSetIcon(scMakeIcon(iconHolder, 3), e.id)

                local nameLbl = uiLabel(chip, e.name, 11, Color3.fromRGB(240, 242, 248), UIFONT.bold)
                nameLbl.Size = UDim2.new(1, -68, 0, 18)
                nameLbl.Position = UDim2.new(0, 46, 0, 6)

                local slotLbl = uiLabel(chip, string.format("[%s] #%d", tostring(e.slot):upper(), e.id), 10,
                    isVis and Color3.fromRGB(115, 180, 255) or Color3.fromRGB(150, 155, 170), UIFONT.reg)
                slotLbl.Size = UDim2.new(1, -68, 0, 15)
                slotLbl.Position = UDim2.new(0, 46, 0, 24)

                local closeBadge = uiLabel(chip, "×", 11, Color3.fromRGB(255, 110, 120), UIFONT.bold, Enum.TextXAlignment.Center)
                closeBadge.Size = UDim2.new(0, 18, 0, 18)
                closeBadge.Position = UDim2.new(1, -23, 0.5, -9)
                closeBadge.BackgroundTransparency = 0
                closeBadge.BackgroundColor3 = Color3.fromRGB(48, 30, 34)
                uiCorner(closeBadge, 4)

                chip.MouseEnter:Connect(function() cs.Color = Color3.fromRGB(235, 80, 90) end)
                chip.MouseLeave:Connect(function()
                    cs.Color = isVis and Color3.fromRGB(65, 135, 220) or Color3.fromRGB(52, 56, 68)
                end)

                -- 1x tap: langsung hilang dari bar & kembali ke set awal untuk slot ini
                chip.Activated:Connect(function()
                    scRemoveSlot(e.slot)
                end)
            end
        end

        -- ---------------- KATALOG (VIRTUAL LIST) ----------------
        local function makeClothRow(scroll)
            local row = {}
            local card = Instance.new("TextButton")
            card.Name = "ItemRow"
            card.BorderSizePixel = 0
            card.AutoButtonColor = false
            card.Text = ""
            card.Parent = scroll
            uiCorner(card, 7)
            row.frame = card
            row.card = card
            row.stroke = uiStroke(card, Color3.fromRGB(38, 42, 52), 1)

            local iconBg = Instance.new("Frame")
            iconBg.Size = UDim2.new(0, 42, 0, 42)
            iconBg.Position = UDim2.new(0, 7, 0.5, -21)
            iconBg.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
            iconBg.BorderSizePixel = 0
            iconBg.Parent = card
            uiCorner(iconBg, 6)
            uiStroke(iconBg, Color3.fromRGB(34, 36, 45), 1)
            row.icon = scMakeIcon(iconBg, 3)

            row.title = uiLabel(card, "", 12, Color3.fromRGB(242, 244, 250), UIFONT.bold)
            row.title.Size = UDim2.new(1, -150, 0, 20)
            row.title.Position = UDim2.new(0, 58, 0, 8)

            row.sub = uiLabel(card, "", 10, Color3.fromRGB(145, 152, 168), UIFONT.reg)
            row.sub.Size = UDim2.new(1, -150, 0, 18)
            row.sub.Position = UDim2.new(0, 58, 0, 29)

            local badge = uiLabel(card, "", 10, Color3.fromRGB(185, 190, 205), UIFONT.bold, Enum.TextXAlignment.Center)
            badge.Size = UDim2.new(0, 76, 0, 24)
            badge.Position = UDim2.new(1, -84, 0.5, -12)
            badge.BackgroundTransparency = 0
            uiCorner(badge, 5)
            row.badge = badge

            card.Activated:Connect(function()
                if row.item then scTapItem(row.item.id) end
            end)
            return row
        end

        local function bindClothRow(row, item)
            local W = SC.Worn or {}
            local eq = (W[item.slot] == item.id)
            local ov = SC.Ov[item.slot] ~= nil and eq
            row.card.BackgroundColor3 = eq and Color3.fromRGB(20, 42, 32) or Color3.fromRGB(20, 22, 28)
            row.stroke.Color = eq and Color3.fromRGB(60, 185, 115) or Color3.fromRGB(38, 42, 52)
            if row.iconId ~= item.id then
                row.iconId = item.id
                scSetIcon(row.icon, item.id)
            end
            row.title.Text = string.format("%s   #%d", item.name, item.id)
            row.sub.Text = string.format("%s  •  rbxassetid://%s%s", item.slot:upper(), item.assetNum,
                item.doubleJump and "  •  2x JUMP" or "")
            row.badge.Text = eq and (ov and "VISUAL ✓" or "DIPAKAI") or "PAKAI"
            row.badge.BackgroundColor3 = eq and Color3.fromRGB(40, 145, 85) or Color3.fromRGB(30, 33, 42)
            row.badge.TextColor3 = eq and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 190, 205)
        end

        vlist = newVList(holder, {
            name = "ClothesListScroll",
            rowH = 56,
            gap = 6,
            pad = 8,
            size = UDim2.new(1, -20, 1, -146),
            position = UDim2.new(0, 10, 0, 136),
            makeRow = makeClothRow,
            bind = bindClothRow,
        })

        local function applyFilter(toTop)
            if not scBuildItems() then
                countLabel.Text = "ItemDB kosong / belum ter-load."
                return
            end
            local words = {}
            for w in string.gmatch(vnTrim(SC.SearchQuery):lower(), "%S+") do words[#words + 1] = w end
            local slotFilter = (SC.SelectedSlot or "All"):lower()

            local out = {}
            for _, item in ipairs(SC.Items) do
                if slotFilter == "all" or item.slot == slotFilter then
                    local ok = true
                    if #words > 0 then
                        local hay = item.hay
                        if not hay then
                            hay = item.lname .. " " .. item.slot .. " " .. tostring(item.id) .. " " .. tostring(item.assetNum)
                            item.hay = hay
                        end
                        for _, w in ipairs(words) do
                            if not hay:find(w, 1, true) then ok = false; break end
                        end
                    end
                    if ok then out[#out + 1] = item end
                end
            end
            matched = out
            countLabel.Text = string.format("%d pakaian  •  Filter: %s  •  Tap 1x = pakai / kembali ke awal",
                #out, (SC.SelectedSlot or "All"):upper())
            vlist:SetData(out, toTop)
        end

        local function refreshAll()
            refreshWornChips()
            vlist:Refresh()
        end

        -- pencarian dengan debounce supaya mengetik tidak membuat lag
        local filterToken = 0
        SC.FilterFn = function()
            filterToken += 1
            local my = filterToken
            task.delay(0.12, function()
                if my == filterToken then pcall(applyFilter, true) end
            end)
        end

        SC.RefreshWornBarFn = refreshAll
        SC.UpdateUIFn = refreshAll

        refreshWornChips()
        applyFilter(true)
    end)
end


-- =========================================================================
-- LOGIKA CHECK MODERATOR + ANTI-SPAM NOTIF + AUTO ACTION (EXIT/DIEM)
-- =========================================================================
local ModSys = {
    RolesModule = nil,
    ActiveMods = {},
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

    for _, desc in ipairs(plr:GetDescendants()) do
        if desc:IsA("ValueBase") then
            local ln = desc.Name:lower()
            if ln:find("role") or ln:find("rank") or ln:find("mod") or ln:find("admin") or ln:find("staff") then
                local isM, roleTitle = isModRoleValue(desc.Value)
                if isM then return true, roleTitle end
            end
        end
    end

    local nick = tostring(plr:GetAttribute("Nick") or plr.DisplayName or plr.Name)
    if nick:find("^`@") or nick:find("^`#") or nick:lower():find("^%[mod%]") or nick:lower():find("^%[admin%]") or nick:lower():find("^mod ") then
        return true, "Prefix:" .. nick
    end

    return false, nil
end

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

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name == plr.Name or obj:GetAttribute("UserId") == plr.UserId or obj:GetAttribute("Owner") == plr.Name) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                return part.Position, true
            end
        end
    end

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

-- =========================================================================
-- ESP & CHECK: DAFTAR PLAYER, ESP VISUAL (100% CLIENT), JALAN OTOMATIS
--  * Posisi diambil dari modul "Others" milik game (koordinat tile), jadi
--    ESP bekerja untuk game 2D ini, bukan lewat Character 3D Roblox.
--  * ESP hanya menggambar di layarmu (overlay GUI), tidak mengirim apa pun.
--  * GO = jalan kaki otomatis lewat input game (bukan teleport).
-- =========================================================================
local ESP = {
    Targets = {},     -- [userId] = true  (ESP per player dari tombol di list)
    Objs = {},        -- [userId] = { line, box, lbl }
    Overlay = nil,
    Others = nil,     -- instance modul Others milik game
    Entries = nil,    -- tabel internal pemain milik Others (id -> data)
    Layer = nil,      -- frame "Tiles" (layer dunia)
    Probe = nil,      -- frame 100px untuk membaca skala UI
    LastScan = 0,
    Filter = "Semua",
    Search = "",
    ListRefresh = nil,
    SoftRefresh = nil,
}

local ESP_FILTERS = { "Semua", "Staff / Mod", "Hidden", "Terlihat" }

local function espPX()
    local ts = SC.Assets and SC.Assets.TileSize
    if type(ts) ~= "number" then
        local ok, A = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Assets", 5))
        end)
        ts = (ok and type(A) == "table" and type(A.TileSize) == "number") and A.TileSize or 32
        if ok and type(A) == "table" and not SC.Assets then SC.Assets = A end
    end
    return ts * 2
end

local function espFindOthers()
    if ESP.Others then return ESP.Others end
    if type(getgc) ~= "function" then return nil end
    if os.clock() - ESP.LastScan < 3 then return nil end
    ESP.LastScan = os.clock()
    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return nil end
    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            if type(rawget(obj, "where")) == "function"
                and type(rawget(obj, "list")) == "function"
                and type(rawget(obj, "tagOf")) == "function"
                and type(rawget(obj, "playerAt")) == "function" then
                ESP.Others = obj
                return obj
            end
        end
    end
    return nil
end

-- Tabel internal pemain milik Others (upvalue fungsi `where`)
local function espEntries()
    if ESP.Entries then return ESP.Entries end
    local O = espFindOthers()
    if not O then return nil end
    if type(debug) == "table" and type(debug.getupvalues) == "function" then
        local ok, ups = pcall(debug.getupvalues, O.where)
        if ok and type(ups) == "table" then
            for _, v in pairs(ups) do
                if type(v) == "table" then
                    ESP.Entries = v
                    return v
                end
            end
        end
    end
    return nil
end

local function espEntryOf(userId)
    local E = espEntries()
    if E then
        for _, e in pairs(E) do
            if type(e) == "table" and e.userId == userId then return e end
        end
    end
    return nil
end

-- Posisi (tile) milik kita sendiri: upvalue 1 & 2 dari G.goTo adalah x,y pemain
local function espMyPos()
    local G = SC.State
    if not G then pcall(scFindWorn); G = SC.State end
    if G and type(G.goTo) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
        local ok, ups = pcall(debug.getupvalues, G.goTo)
        if ok and type(ups) == "table" then
            local x, y = ups[1], ups[2]
            if type(x) == "number" and type(y) == "number" then return x, y end
        end
    end
    return nil, nil
end

-- Konversi koordinat tile -> posisi layar (dalam ruang ScreenGui overlay)
local function espLayer()
    if ESP.Layer and ESP.Layer.Parent then return ESP.Layer end
    local E = espEntries()
    if E then
        for _, e in pairs(E) do
            local g = type(e) == "table" and e.group
            if typeof(g) == "Instance" and g.Parent then
                local layer = g.Parent:FindFirstChild("Tiles")
                if layer then
                    ESP.Layer = layer
                    if ESP.Probe then pcall(function() ESP.Probe:Destroy() end) end
                    local probe = Instance.new("Frame")
                    probe.Name = "R8DV_ScaleProbe"
                    probe.BackgroundTransparency = 1
                    probe.BorderSizePixel = 0
                    probe.Size = UDim2.fromOffset(100, 100)
                    probe.Parent = layer.Parent
                    ESP.Probe = probe
                    return layer
                end
            end
        end
    end
    return nil
end

local function espToScreen(x, y)
    local layer = espLayer()
    if not layer then return nil end
    local s = 1
    if ESP.Probe and ESP.Probe.Parent then
        s = ESP.Probe.AbsoluteSize.X / 100
        if s <= 0 then s = 1 end
    end
    local ap = layer.AbsolutePosition
    local px = espPX() * s
    return Vector2.new(ap.X + x * px, ap.Y + y * px)
end

-- ---------------------------------------------------------------------
-- DATA PLAYER (dipakai list & ESP)
-- ---------------------------------------------------------------------
local function espStatusOf(plr, entry)
    local attrHidden = (plr:GetAttribute("Invisible") == true) or (plr:GetAttribute("Ghost") == true)
        or (plr:GetAttribute("Hidden") == true)
    if not entry then
        return attrHidden and "HIDDEN" or "TAK DI WORLD", false, attrHidden
    end
    if not entry.seen then
        return "HIDDEN", false, true
    end
    if attrHidden then
        return "HIDDEN", true, true
    end
    return "TERLIHAT", true, false
end

local function espCollect()
    local rows = {}
    local mx, my = espMyPos()
    local q = vnTrim(ESP.Search):lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local entry = espEntryOf(plr.UserId)
            local status, hasPos, hidden = espStatusOf(plr, entry)
            local modInfo = ModSys.ActiveMods[plr]
            local role = modInfo and tostring(modInfo.role) or nil
            local nick = tostring(plr:GetAttribute("Nick") or "")
            local show = tostring(plr.DisplayName ~= "" and plr.DisplayName or plr.Name)
            local dist
            if hasPos and entry and mx then
                dist = math.sqrt((entry.x - mx) ^ 2 + (entry.y - my) ^ 2)
            end
            local ok = true
            if ESP.Filter == "Staff / Mod" then ok = modInfo ~= nil
            elseif ESP.Filter == "Hidden" then ok = hidden or status == "HIDDEN"
            elseif ESP.Filter == "Terlihat" then ok = (status == "TERLIHAT") end
            if ok and q ~= "" then
                local hay = (plr.Name .. " " .. show .. " " .. nick .. " " .. tostring(plr.UserId)):lower()
                ok = hay:find(q, 1, true) ~= nil
            end
            if ok then
                rows[#rows + 1] = {
                    plr = plr,
                    userId = plr.UserId,
                    name = plr.Name,
                    display = show,
                    role = role,
                    isMod = modInfo ~= nil,
                    status = status,
                    hasPos = hasPos,
                    hidden = hidden,
                    dist = dist,
                }
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.isMod ~= b.isMod then return a.isMod end
        local ra = a.hasPos and 0 or 1
        local rb = b.hasPos and 0 or 1
        if ra ~= rb then return ra < rb end
        return a.name:lower() < b.name:lower()
    end)
    return rows
end

-- ---------------------------------------------------------------------
-- OVERLAY ESP
-- ---------------------------------------------------------------------
local function espEnsureOverlay()
    if ESP.Overlay and ESP.Overlay.Parent then return ESP.Overlay end
    local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
        or LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "R8DV_ESP_Overlay"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local layer = ESP.Layer
    local host = layer and layer:FindFirstAncestorOfClass("ScreenGui")
    sg.IgnoreGuiInset = host and host.IgnoreGuiInset or true
    sg.Parent = parent
    ESP.Overlay = sg
    return sg
end

local function espDestroyObj(uid)
    local o = ESP.Objs[uid]
    if o then
        for _, v in pairs(o) do
            pcall(function() v:Destroy() end)
        end
        ESP.Objs[uid] = nil
    end
end

local function espClearAll()
    for uid in pairs(ESP.Objs) do espDestroyObj(uid) end
end

local function espForget(plr)
    if plr then
        ESP.Targets[plr.UserId] = nil
        espDestroyObj(plr.UserId)
    end
end

local function espMakeObj(sg, uid)
    local line = Instance.new("Frame")
    line.Name = "Tracer_" .. uid
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.Parent = sg

    local box = Instance.new("Frame")
    box.Name = "Box_" .. uid
    box.AnchorPoint = Vector2.new(0.5, 1)
    box.BackgroundTransparency = 0.85
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Parent = box

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label_" .. uid
    lbl.AnchorPoint = Vector2.new(0.5, 1)
    lbl.Size = UDim2.fromOffset(190, 32)
    lbl.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    lbl.BackgroundTransparency = 0.25
    lbl.BorderSizePixel = 0
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.Visible = false
    lbl.Parent = sg
    lbl:SetAttribute("R8DV_SkipLight", true)
    lbl.FontFace = UIFONT.bold
    uiCorner(lbl, 4)

    local o = { line = line, box = box, stroke = stroke, lbl = lbl }
    ESP.Objs[uid] = o
    return o
end

local function espWantedTargets()
    -- siapa saja yang digambar: target manual, semua player, dan staff otomatis
    local want = {}
    local all = getValue("ESP_All", false)
    local autoMod = getValue("Mod_ESP", true) and getValue("Mod_Enable", true)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if all or ESP.Targets[plr.UserId] or (autoMod and ModSys.ActiveMods[plr]) then
                want[plr.UserId] = plr
            end
        end
    end
    return want
end

local function espRender()
    if not getValue("ESP_Master", true) then
        if next(ESP.Objs) ~= nil then espClearAll() end
        return
    end

    local want = espWantedTargets()
    for uid in pairs(ESP.Objs) do
        if not want[uid] then espDestroyObj(uid) end
    end
    if next(want) == nil then return end

    espLayer()
    local sg = espEnsureOverlay()
    local hostGui = ESP.Layer and ESP.Layer:FindFirstAncestorOfClass("ScreenGui")
    if hostGui and sg.IgnoreGuiInset ~= hostGui.IgnoreGuiInset then
        sg.IgnoreGuiInset = hostGui.IgnoreGuiInset
    end
    Camera = Workspace.CurrentCamera
    local vs = sg.AbsoluteSize
    if vs.X <= 0 then vs = (Camera and Camera.ViewportSize) or Vector2.new(800, 600) end
    local showHidden = getValue("ESP_Hidden", true)

    local mx, my = espMyPos()
    local me2D = (mx and espToScreen(mx, my - 0.5)) or Vector2.new(vs.X / 2, vs.Y * 0.8)

    for uid, plr in pairs(want) do
        local o = ESP.Objs[uid] or espMakeObj(sg, uid)
        local entry = espEntryOf(uid)
        local status, hasPos, hidden = espStatusOf(plr, entry)
        local modInfo = ModSys.ActiveMods[plr]

        local color
        if modInfo then color = Color3.fromRGB(255, 70, 70)
        elseif hidden then color = Color3.fromRGB(190, 120, 255)
        else color = Color3.fromRGB(80, 220, 255) end

        local pos2D
        if hasPos and entry and (showHidden or not hidden) then
            pos2D = espToScreen(entry.x, entry.y - 0.5)
        end

        if not pos2D then
            o.line.Visible = false
            o.box.Visible = false
            if modInfo or ESP.Targets[uid] then
                -- tetap beri info di atas layar kalau tak ada posisi (mis. hidden penuh)
                o.lbl.Visible = true
                o.lbl.TextColor3 = color
                o.lbl.Position = UDim2.fromOffset(vs.X / 2, 70 + (uid % 5) * 36)
                o.lbl.Text = string.format("%s%s\n%s (posisi tidak dikirim server)",
                    modInfo and "[MOD] " or "", plr.Name, status)
            else
                o.lbl.Visible = false
            end
        else
            local margin = 36
            local clamped = Vector2.new(
                math.clamp(pos2D.X, margin, vs.X - margin),
                math.clamp(pos2D.Y, margin + 30, vs.Y - margin)
            )
            local offscreen = (clamped - pos2D).Magnitude > 1

            local delta = clamped - me2D
            local len = delta.Magnitude
            o.line.BackgroundColor3 = color
            o.line.BackgroundTransparency = 0.25
            o.line.Position = UDim2.fromOffset((me2D.X + clamped.X) / 2, (me2D.Y + clamped.Y) / 2)
            o.line.Size = UDim2.fromOffset(len, 2)
            o.line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
            o.line.Visible = len > 4

            local sizePx = offscreen and 22 or 56
            o.box.BackgroundColor3 = color
            o.stroke.Color = color
            o.box.Size = UDim2.fromOffset(sizePx, sizePx)
            o.box.Position = UDim2.fromOffset(clamped.X, clamped.Y + sizePx / 2)
            o.box.Visible = true

            local dist = 0
            if mx and entry then
                dist = math.sqrt((entry.x - mx) ^ 2 + (entry.y - my) ^ 2)
            end
            o.lbl.TextColor3 = color
            o.lbl.Position = UDim2.fromOffset(clamped.X, clamped.Y - (offscreen and 6 or 30))
            o.lbl.Text = string.format("%s%s\n%s  •  %.0f tile%s",
                modInfo and "[MOD] " or "", plr.Name, status, dist, offscreen and "  ➤" or "")
            o.lbl.Visible = true
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(espRender)
end)

-- ---------------------------------------------------------------------
-- JALAN OTOMATIS KE PLAYER (BUKAN TELEPORT)
--  Menimpa input arah/lompat milik game (modul kontrol dengan dir()/jumping()),
--  fallback VirtualInputManager (tombol panah) bila modul tidak ketemu.
-- ---------------------------------------------------------------------
local Walk = {
    Active = false,
    UserId = nil,
    Name = "",
    dir = 0,
    jump = false,
    Tbl = nil,
    OrigDir = nil,
    OrigJump = nil,
    UseVIM = false,
    KeyState = {},
    StartedAt = 0,
    LastX = nil,
    LastCheck = 0,
    JumpUntil = 0,
    NextJump = 0,
    Refresh = nil,   -- callback untuk menyegarkan tombol GO di list
}

local function walkFindInputTable()
    if Walk.Tbl then return Walk.Tbl end
    if type(getgc) ~= "function" then return nil end
    if os.clock() - (Walk.LastScan or -99) < 10 then return nil end
    Walk.LastScan = os.clock()
    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return nil end
    for _, obj in ipairs(gc) do
        if type(obj) == "table"
            and type(rawget(obj, "dir")) == "function"
            and type(rawget(obj, "jumping")) == "function" then
            Walk.Tbl = obj
            return obj
        end
    end
    return nil
end

local function walkVIMKey(code, down)
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if not ok or not vim then return false end
    if Walk.KeyState[code] == down then return true end
    Walk.KeyState[code] = down
    return pcall(function() vim:SendKeyEvent(down, code, false, game) end)
end

local function walkInstallHook()
    if Walk.OrigDir then return true end
    local t = walkFindInputTable()
    if not t then
        Walk.UseVIM = true
        return true
    end
    if type(setreadonly) == "function" then pcall(setreadonly, t, false) end
    local od, oj = rawget(t, "dir"), rawget(t, "jumping")
    local okSet = pcall(function()
        t.dir = function(...)
            if Walk.Active then return Walk.dir end
            return od(...)
        end
        t.jumping = function(...)
            if Walk.Active and Walk.jump then return true end
            return oj(...)
        end
    end)
    if okSet and t.dir ~= od then
        Walk.OrigDir, Walk.OrigJump = od, oj
        Walk.UseVIM = false
        return true
    end
    Walk.UseVIM = true
    return true
end

local function walkStop(reason, silent)
    local wasActive = Walk.Active
    Walk.Active = false
    Walk.dir = 0
    Walk.jump = false
    Walk.UserId = nil
    if Walk.UseVIM then
        walkVIMKey(Enum.KeyCode.Left, false)
        walkVIMKey(Enum.KeyCode.Right, false)
        walkVIMKey(Enum.KeyCode.Up, false)
    end
    if wasActive and reason and not silent then
        notifyClient("ESP & Check", reason, 3)
    end
    if Walk.Refresh then pcall(Walk.Refresh) end
end

local function walkStart(userId, name)
    if Walk.Active and Walk.UserId == userId then
        walkStop("Jalan otomatis dihentikan")
        return
    end
    local mx = espMyPos()
    if not mx then
        notifyClient("ESP & Check", "Posisimu belum terbaca. Masuk ke world dulu.", 4)
        return
    end
    local entry = espEntryOf(userId)
    if not (entry and entry.seen) then
        notifyClient("ESP & Check", tostring(name) .. ": posisi tidak tersedia (hidden / tidak di world ini)", 4)
        return
    end
    walkInstallHook()
    Walk.Active = true
    Walk.UserId = userId
    Walk.Name = tostring(name)
    Walk.StartedAt = os.clock()
    Walk.LastX = nil
    Walk.LastCheck = os.clock()
    Walk.JumpUntil = 0
    Walk.NextJump = 0
    notifyClient("ESP & Check", "Berjalan ke " .. Walk.Name .. " ...", 2)
    if Walk.Refresh then pcall(Walk.Refresh) end
end

RunService.Heartbeat:Connect(function()
    if not Walk.Active then return end
    local now = os.clock()

    if now - Walk.StartedAt > 150 then
        walkStop("Jalan otomatis berhenti (timeout)")
        return
    end

    local mx, my = espMyPos()
    local entry = espEntryOf(Walk.UserId)
    if not mx then
        walkStop("Posisimu tidak terbaca")
        return
    end
    if not (entry and entry.seen) then
        walkStop("Target hilang dari world / hidden")
        return
    end

    local dx, dy = entry.x - mx, entry.y - my
    if math.abs(dx) < 0.9 and math.abs(dy) < 1.6 then
        walkStop("Sudah sampai di " .. Walk.Name)
        return
    end

    local d = 0
    if math.abs(dx) > 0.35 then d = dx > 0 and 1 or -1 end
    Walk.dir = d

    -- lompat: target lebih tinggi, atau tersangkut (posisi x tidak berubah)
    if now - Walk.LastCheck >= 0.3 then
        local stuck = Walk.LastX ~= nil and d ~= 0 and math.abs(mx - Walk.LastX) < 0.05
        Walk.LastX = mx
        Walk.LastCheck = now
        if (stuck or dy < -1.2) and now >= Walk.NextJump then
            Walk.JumpUntil = now + 0.28
            Walk.NextJump = now + 0.7
        end
    end
    Walk.jump = now < Walk.JumpUntil

    if Walk.UseVIM then
        walkVIMKey(Enum.KeyCode.Left, d < 0)
        walkVIMKey(Enum.KeyCode.Right, d > 0)
        walkVIMKey(Enum.KeyCode.Up, Walk.jump)
    end
end)

-- ---------------------------------------------------------------------
-- UI LIST PLAYER (EMBEDDED, SCROLLABLE, VIRTUAL)
-- ---------------------------------------------------------------------
local function espMountPlayerList()
    task.spawn(function()
        task.wait(0.6)
        local cardContainer = findAnchorContainer("DAFTAR PLAYER", 40, 0.4)
        if not cardContainer then return end
        local old = cardContainer:FindFirstChild("R8DV_PlayerListBrowser")
        if old then old:Destroy() end

        local holder = Instance.new("Frame")
        holder.Name = "R8DV_PlayerListBrowser"
        holder.Size = UDim2.new(1, 0, 0, 400)
        holder.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
        holder.BorderSizePixel = 0
        holder.LayoutOrder = 99
        holder.Parent = cardContainer
        uiCorner(holder, 10)
        uiStroke(holder, Color3.fromRGB(38, 40, 48), 1)

        local info = uiLabel(holder, "Memuat daftar player...", 11, Color3.fromRGB(155, 160, 175), UIFONT.med)
        info.Size = UDim2.new(1, -20, 0, 22)
        info.Position = UDim2.new(0, 12, 0, 6)

        local COL_ON = Color3.fromRGB(40, 145, 85)
        local COL_OFF = Color3.fromRGB(30, 33, 42)
        local COL_GO = Color3.fromRGB(55, 105, 205)

        local function makeRow(scroll)
            local row = {}
            local card = Instance.new("Frame")
            card.Name = "PlayerRow"
            card.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
            card.BorderSizePixel = 0
            card.Parent = scroll
            uiCorner(card, 7)
            row.frame = card
            row.stroke = uiStroke(card, Color3.fromRGB(38, 42, 52), 1)

            row.dot = Instance.new("Frame")
            row.dot.Size = UDim2.fromOffset(8, 8)
            row.dot.Position = UDim2.new(0, 9, 0.5, -4)
            row.dot.BorderSizePixel = 0
            row.dot.Parent = card
            uiCorner(row.dot, 99)

            row.title = uiLabel(card, "", 12, Color3.fromRGB(242, 244, 250), UIFONT.bold)
            row.title.Size = UDim2.new(1, -146, 0, 20)
            row.title.Position = UDim2.new(0, 24, 0, 7)

            row.sub = uiLabel(card, "", 10, Color3.fromRGB(145, 152, 168), UIFONT.reg)
            row.sub.Size = UDim2.new(1, -146, 0, 18)
            row.sub.Position = UDim2.new(0, 24, 0, 27)

            local function btn(text, xOff)
                local b = Instance.new("TextButton")
                b.Size = UDim2.fromOffset(58, 28)
                b.Position = UDim2.new(1, xOff, 0.5, -14)
                b.AutoButtonColor = false
                b.TextSize = 10
                b.Text = text
                b.TextColor3 = Color3.fromRGB(255, 255, 255)
                b.BackgroundColor3 = COL_OFF
                lockFont(b, UIFONT.bold)
                b.Parent = card
                uiCorner(b, 6)
                return b
            end
            row.espBtn = btn("ESP", -126)
            row.goBtn = btn("GO", -64)

            row.espBtn.Activated:Connect(function()
                local it = row.item
                if not it then return end
                if ESP.Targets[it.userId] then
                    ESP.Targets[it.userId] = nil
                else
                    ESP.Targets[it.userId] = true
                end
                row.dirty = true
                if ESP.SoftRefresh then ESP.SoftRefresh() end
            end)
            row.goBtn.Activated:Connect(function()
                local it = row.item
                if not it then return end
                walkStart(it.userId, it.name)
            end)
            return row
        end

        local function bindRow(row, it)
            local active = ESP.Targets[it.userId] == true
            local walking = Walk.Active and Walk.UserId == it.userId
            local col
            if it.isMod then col = Color3.fromRGB(255, 70, 70)
            elseif it.hidden or it.status == "HIDDEN" then col = Color3.fromRGB(190, 120, 255)
            elseif it.status == "TERLIHAT" then col = Color3.fromRGB(72, 199, 142)
            else col = Color3.fromRGB(120, 125, 140) end
            row.dot.BackgroundColor3 = col
            row.stroke.Color = active and Color3.fromRGB(60, 185, 115) or Color3.fromRGB(38, 42, 52)

            local nm = it.display
            if it.display:lower() ~= it.name:lower() then nm = it.display .. "  (@" .. it.name .. ")" end
            row.title.Text = (it.isMod and "[MOD] " or "") .. nm
            row.sub.Text = string.format("%s%s%s", it.status,
                it.dist and string.format("  •  %.0f tile", it.dist) or "",
                it.role and ("  •  " .. it.role) or "")

            row.espBtn.Text = active and "ESP ON" or "ESP"
            row.espBtn.BackgroundColor3 = active and COL_ON or COL_OFF
            row.goBtn.Text = walking and "STOP" or "GO"
            row.goBtn.BackgroundColor3 = walking and Color3.fromRGB(165, 45, 55) or (it.hasPos and COL_GO or COL_OFF)
            row.goBtn.TextTransparency = it.hasPos and 0 or 0.5
        end

        local vlist = newVList(holder, {
            name = "PlayerListScroll",
            rowH = 50,
            gap = 6,
            pad = 8,
            size = UDim2.new(1, -20, 1, -64),
            position = UDim2.new(0, 10, 0, 54),
            makeRow = makeRow,
            bind = bindRow,
        })

        -- tombol cepat: ESP semua / matikan semua
        local function quickBtn(text, xScale, onClick)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0.5, -15, 0, 22)
            b.Position = UDim2.new(xScale, xScale == 0 and 10 or 5, 0, 30)
            b.AutoButtonColor = false
            b.TextSize = 10
            b.Text = text
            b.TextColor3 = Color3.fromRGB(215, 220, 232)
            b.BackgroundColor3 = Color3.fromRGB(26, 29, 37)
            lockFont(b, UIFONT.bold)
            b.Parent = holder
            uiCorner(b, 6)
            b.Activated:Connect(onClick)
            return b
        end

        local rows = {}
        local function reload(toTop)
            rows = espCollect()
            local shown, mods, hid = #rows, 0, 0
            for _, r in ipairs(rows) do
                if r.isMod then mods += 1 end
                if r.status == "HIDDEN" then hid += 1 end
            end
            local nTarget = 0
            for _ in pairs(ESP.Targets) do nTarget += 1 end
            info.Text = string.format("%d player  •  %d staff  •  %d hidden  •  %d ESP aktif", shown, mods, hid, nTarget)
            vlist:SetData(rows, toTop)
        end

        quickBtn("ESP SEMUA YANG TAMPIL", 0, function()
            for _, r in ipairs(rows) do ESP.Targets[r.userId] = true end
            reload(false)
        end)
        quickBtn("MATIKAN SEMUA ESP", 0.5, function()
            ESP.Targets = {}
            espClearAll()
            reload(false)
        end)

        ESP.SoftRefresh = function() reload(false) end
        ESP.ListRefresh = function(toTop) reload(toTop) end
        Walk.Refresh = function() vlist:Refresh() end

        -- segarkan data tiap 1 detik (tidak mengulang scroll)
        task.spawn(function()
            while holder.Parent do
                pcall(reload, false)
                task.wait(1)
            end
        end)

        reload(true)
    end)
end


local function scanModerators()
    if not getValue("Mod_Enable", true) then
        if Spam.PausedByMod then setFreezeState(false) end
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

    for plr in pairs(ModSys.ActiveMods) do
        if not currentMods[plr] then
            notifyClient("Mod Left", string.format("Moderator %s telah keluar dari World.", plr.Name), 4)
            ModSys.ActiveMods[plr] = nil
        end
    end

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
    end
    espForget(plr)
    task.defer(scanModerators)
end)

task.spawn(function()
    while true do
        task.wait(0.8)
        pcall(scanModerators)
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
-- KATEGORI 3: SET CLOTHES (DIPERBAIKI & DIPERBAGUS)
-- =========================================================================
pcall(scBuildItems)
if UI.Category then UI:Category("Set Clothes") end

feature("Item", "Set Clothes")({
    center = center(function(c)
        c:Header("Set Clothes & Visual Catalog", "Katalog pakaian dengan ikon asli game, bisa dicari. 1x tap = pakai / lepas (kembali ke set awal)", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Bar Atas",     Value = "1x Tap Lepas" },
            { Icon = "Check",  Label = "Katalog",      Value = "1x Tap Pakai" },
            { Icon = "Shield", Label = "Kirim Server", Value = "Diblokir" }
        })

        local CatalogCard = c:Card("KATALOG VISUAL CLOTHES", nil, "Palette", {
            Subtitle = "Bar atas = item yang sedang dipakai (tap 1x untuk lepas). Daftar bawah = katalog (tap 1x untuk pakai, tap lagi untuk kembali ke awal)"
        })
        CatalogCard:Input("Cari Nama / ID / Asset ID", "SC_Search", "Ketik nama item, ID, slot, atau asset id...", "", function(val)
            SC.SearchQuery = tostring(val or "")
            if SC.FilterFn then pcall(SC.FilterFn) end
        end)
        CatalogCard:Dropdown("Filter Kategori Slot", "SC_SlotFilter", SC.Slots, "All", function(slotVal)
            SC.SelectedSlot = tostring(slotVal or "All")
            if SC.FilterFn then pcall(SC.FilterFn) end
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
        CtrlCard:Button("Lepas Semua Item (Unwear All)", "LEPAS SEMUA", "Shield", function()
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
-- KATEGORI 4: ESP & CHECK
-- =========================================================================
if UI.Category then UI:Category("ESP & Check") end

feature("Shield", "ESP & Check")({
    center = center(function(c)
        c:Header("ESP & Check", "ESP player (termasuk hidden), jalan otomatis ke player, dan cek moderator di world", "Client")

        c:StatRow({
            { Icon = "Shield", Label = "Check",  Value = "Real-time" },
            { Icon = "Bolt",   Label = "ESP",    Value = "Visual client" },
            { Icon = "Check",  Label = "Go To",  Value = "Jalan kaki" }
        })

        local EspCard = c:Card("ESP PLAYER", nil, "Bolt", {
            Subtitle = "Garis, kotak, nama & jarak ke player. Hanya tampil di layarmu (client)"
        })
        EspCard:Toggle("ESP ON / OFF", "ESP_Master", true, function(st)
            if not st then espClearAll() end
        end)
        EspCard:Toggle("ESP semua player di world", "ESP_All", false)
        EspCard:Toggle("Tampilkan player hidden / vanish", "ESP_Hidden", true)
        EspCard:Toggle("Auto-ESP untuk Moderator / Staff", "Mod_ESP", true)

        local ListCard = c:Card("DAFTAR PLAYER (ESP & GO TO)", nil, "Chat", {
            Subtitle = "Tombol ESP = tampilkan ESP ke player itu. Tombol GO = jalan otomatis ke lokasinya (bukan teleport)"
        })
        ListCard:Input("Cari Player", "ESP_Search", "Ketik nama / display name / ID...", "", function(val)
            ESP.Search = tostring(val or "")
            if ESP.ListRefresh then pcall(ESP.ListRefresh, true) end
        end)
        ListCard:Dropdown("Filter Daftar", "ESP_Filter", ESP_FILTERS, "Semua", function(v)
            ESP.Filter = tostring(v or "Semua")
            if ESP.ListRefresh then pcall(ESP.ListRefresh, true) end
        end)

        local ModCard = c:Card("CHECK MODERATOR WORLD", nil, "Shield", {
            Subtitle = "Notifikasi siapa Mod yang masuk/ada di world tanpa spam berulang untuk Mod yang sama"
        })
        ModCard:Toggle("Aktifkan Check Moderator", "Mod_Enable", true, function()
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
        local WalkCard = r:Card("Jalan Otomatis", nil, "Bolt", {
            Subtitle = "Karakter berjalan sendiri ke player lewat input game, tanpa teleport"
        })
        WalkCard:Button("Hentikan Jalan Otomatis", "STOP", "Check", function()
            walkStop("Jalan otomatis dihentikan")
        end)
        WalkCard:Button("Matikan Semua ESP Player", "ESP OFF", "Shield", function()
            ESP.Targets = {}
            espClearAll()
            if ESP.ListRefresh then pcall(ESP.ListRefresh, false) end
        end)

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
            notifyClient("ESP & Check", "Karakter di-unfreeze secara manual", 3)
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

task.spawn(function()
    task.wait(1.0)
    for _, root in ipairs(lightFindRoots()) do
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("TextLabel") and d.Text:find("CHECK MODERATOR WORLD", 1, true) then
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

-- Inisialisasi awal
task.spawn(function()
    pcall(scHook)
    scMountEmbeddedBrowser()
    espMountPlayerList()
    task.wait(1.5)
    if getValue("LightText", true) then pcall(lightEnable) end
end)
