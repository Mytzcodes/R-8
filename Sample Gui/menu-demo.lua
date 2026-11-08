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
-- LOGIKA SPAM
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
-- TEKS RINGAN & ROOT FINDER
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
-- SET VISUAL NAME (CLIENT)
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
-- SET CLOTHES (CORE)
-- =========================================================================
local SC = {
    DB = nil,
    BlocksDB = nil,
    ItemIcon = nil,
    Assets = nil,
    Autotile = nil,
    Items = nil,
    BlockItems = nil,
    ItemMap = {},
    BlockMap = {},
    Slots = { "All" },
    Worn = nil,
    Game = nil,
    State = nil,
    PlayerSprite = nil,
    Ov = {},
    WearTbl = nil, OrigWear = nil,
    MoveTbl = nil, OrigMove = nil,
    JumpMode = "Tahan paket (disarankan)",
    ApplyMethod = "Dual Method (onWear + Direct GC)",
    Hold = nil,
    Loop = false,
    SearchQuery = "",
    SelectedSlot = "All",
    UpdateUIFn = nil,
    RefreshWornBarFn = nil,
    LastWornSignature = "",
    LastTapId = nil,
    LastTapTime = 0,
}

local SC_JUMP_MODES = { "Tahan paket (disarankan)", "Samarkan flag saja", "Mati" }
local SC_APPLY_METHODS = {
    "Dual Method (onWear + Direct GC)",
    "Method 1: Client onWear Callback",
    "Method 2: Direct Upvalue Mutation"
}

local KNOWN_SLOTS = {
    hair = true, head = true, mask = true, face = true, eyes = true,
    chest = true, shirt = true, pants = true, shoes = true, feet = true,
    back = true, wing = true, wings = true, neck = true, hand = true,
    aura = true, pet = true, hat = true, ride = true, artifact = true,
    waist = true, ancestral = true, legs = true, body = true, Beard = true, beard = true
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

-- IKON ITEM (modul asli game)
local function scAtlasUrl(atlasName)
    if type(atlasName) ~= "string" then return nil end
    local A = SC.Assets and SC.Assets.Atlas
    if type(A) == "table" then return A[atlasName] end
    return nil
end

local function scMakeIcon(holder, z)
    local II = SC.ItemIcon
    if type(II) == "table" and type(II.new) == "function" then
        local ok, res = pcall(II.new, holder, UDim2.new(1, -6, 1, -6), z or 3)
        if ok and type(res) == "table" and typeof(res.frame) == "Instance" and res.base and res.over then
            res.frame.Position = UDim2.fromOffset(3, 3)
            return res
        end
    end
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

local function scSetIcon(icon, id)
    if not icon then return end
    local II = SC.ItemIcon
    if type(II) == "table" and type(II.set) == "function" then
        if pcall(II.set, icon, id) then
            if icon.frame then icon.frame.Visible = true end
            return
        end
    end
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
    if SC.Items and #SC.Items > 0 and SC.BlockItems and #SC.BlockItems > 0 then return true end
    local sh = ReplicatedStorage:WaitForChild("Shared", 5)
    if not sh then return false end

    local ok, DB = pcall(function() return require(sh:WaitForChild("ItemDB", 5)) end)
    if not ok or type(DB) ~= "table" then return false end

    pcall(function() SC.BlocksDB = require(sh:FindFirstChild("BlocksDB")) end)
    pcall(function() SC.ItemIcon = require(sh:FindFirstChild("ItemIcon")) end)
    pcall(function() SC.Assets = require(sh:FindFirstChild("Assets")) end)
    pcall(function() SC.Autotile = require(sh:FindFirstChild("Autotile")) end)
    pcall(function() SC.PlayerSprite = require(sh:FindFirstChild("PlayerSprite")) end)

    local items, itemMap, slotMap = {}, {}, {}
    local blockItems, blockMap = {}, {}

    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" and type(it.name) == "string" then
            local url = scAtlasUrl(it.atlas)
            local num = url and tostring(url):match("(%d+)") or "-"
            local isSeed = it.name:find(" Seed$") ~= nil or it.kind == "seed"
            local isCloth = (it.kind == "cloth" or it.kind == "clothes" or it.kind == "wearable"
                or (type(it.slot) == "string" and it.slot ~= ""))

            if isCloth and type(it.slot) == "string" and not isSeed then
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
            elseif not isCloth and not isSeed then
                local isBlock = (it.kind == "block" or it.kind == "fg" or it.kind == "bg"
                    or (type(SC.BlocksDB) == "table" and SC.BlocksDB[id] ~= nil)
                    or it.hits ~= nil or it.breakHits ~= nil or it.hp ~= nil or it.hardness ~= nil
                    or it.collision ~= nil or it.autotile ~= nil or it.kind == nil or it.kind ~= "consumable")
                if isBlock and id > 0 then
                    local bEntry = {
                        id = id,
                        name = it.name,
                        lname = it.name:lower(),
                        kind = tostring(it.kind or "block"),
                        hits = tonumber(it.hits or it.breakHits or it.hp or 4) or 4,
                        icon = url,
                        assetNum = num,
                        raw = it,
                    }
                    blockItems[#blockItems + 1] = bEntry
                    blockMap[id] = bEntry
                end
            end
        end
    end

    table.sort(items, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)

    table.sort(blockItems, function(a, b)
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
    SC.BlockItems = blockItems
    SC.BlockMap = blockMap
    SC.Slots = slotList
    return #items > 0
end

-- =========================================================================
-- ANTI-DETECTION & PACKET TRAFFIC GUARD (tidak diubah)
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

local function scForceCharacterRedraw(prevFx)
    local W = SC.Worn
    if not W then return end

    local G = SC.State
    local method = SC.ApplyMethod or "Dual Method (onWear + Direct GC)"

    if (method == "Dual Method (onWear + Direct GC)" or method == "Method 1: Client onWear Callback") and SC.Game then
        if type(SC.Game.onWear) == "function" then
            local snapshot = {}
            for k, v in pairs(W) do snapshot[k] = v end
            pcall(SC.Game.onWear, snapshot)
            for k, v in pairs(snapshot) do W[k] = v end
        end
    end

    if G then
        if prevFx and type(G.effectsChanged) == "function" then
            pcall(G.effectsChanged, prevFx)
        elseif type(G.effects) == "function" and type(G.effectsChanged) == "function" then
            local okE, fx = pcall(G.effects)
            if okE then pcall(G.effectsChanged, fx) end
        end
        if type(G.call) == "function" then
            pcall(G.call, "wearChanged", W)
            pcall(G.call, "effectsChanged")
        end
        local hand = W.hand
        if hand == 138 or hand == 5480 then G.punchPick = hand end
    end

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

    if SC.PlayerSprite then
        for _, fnName in ipairs({ "apply", "update", "refresh", "setWorn" }) do
            local fn = SC.PlayerSprite[fnName]
            if type(fn) == "function" then
                pcall(fn, LocalPlayer.Character or LocalPlayer, W)
            end
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
    scHook()

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

    scForceCharacterRedraw(prevFx)
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
        W[slotName] = nil
    end)
end

local function scWearOrToggleItem(id)
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
-- HELPER UI
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
        if h <= 0 then h = 380 end
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

    function V:Refresh()
        for _, row in ipairs(self.Pool) do row.dirty = true end
        self:Layout()
    end

    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() V:Layout() end)
    scroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function() V:Layout() end)
    return V
end

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
        holder.Size = UDim2.new(1, 0, 0, 720)
        holder.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
        holder.BorderSizePixel = 0
        holder.LayoutOrder = 99
        holder.Parent = cardContainer
        uiCorner(holder, 10)
        uiStroke(holder, Color3.fromRGB(38, 40, 48), 1)

        -- Search bar
        local topSearchFrame = Instance.new("Frame")
        topSearchFrame.Size = UDim2.new(1, -20, 0, 40)
        topSearchFrame.Position = UDim2.new(0, 10, 0, 10)
        topSearchFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
        topSearchFrame.BorderSizePixel = 0
        topSearchFrame.Parent = holder
        uiCorner(topSearchFrame, 8)
        uiStroke(topSearchFrame, Color3.fromRGB(48, 52, 64), 1)

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -120, 1, -8)
        searchBox.Position = UDim2.new(0, 12, 0, 4)
        searchBox.BackgroundTransparency = 1
        searchBox.ClearTextOnFocus = false
        searchBox.PlaceholderText = "Cari nama, ID, slot, atau asset ID..."
        searchBox.PlaceholderColor3 = Color3.fromRGB(115, 120, 135)
        searchBox.Text = SC.SearchQuery or ""
        searchBox.TextSize = 12
        searchBox.TextColor3 = Color3.fromRGB(240, 242, 250)
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        lockFont(searchBox, UIFONT.med)
        searchBox.Parent = topSearchFrame

        local clearSearchBtn = Instance.new("TextButton")
        clearSearchBtn.Size = UDim2.new(0, 98, 0, 28)
        clearSearchBtn.Position = UDim2.new(1, -104, 0.5, -14)
        clearSearchBtn.BackgroundColor3 = Color3.fromRGB(34, 37, 48)
        clearSearchBtn.AutoButtonColor = false
        clearSearchBtn.TextSize = 10
        clearSearchBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
        clearSearchBtn.Text = "RESET CARI"
        lockFont(clearSearchBtn, UIFONT.bold)
        clearSearchBtn.Parent = topSearchFrame
        uiCorner(clearSearchBtn, 6)

        local countLabel = uiLabel(holder, "Memuat katalog...", 11, Color3.fromRGB(155, 160, 175), UIFONT.med)
        countLabel.Size = UDim2.new(1, -24, 0, 18)
        countLabel.Position = UDim2.new(0, 12, 0, 54)

        -- Katalog (lebar penuh, tinggi 330)
        local function makeClothRow(scroll)
            local row = {}
            local card = Instance.new("TextButton")
            card.Name = "ItemRow"
            card.BorderSizePixel = 0
            card.AutoButtonColor = false
            card.Text = ""
            card.Parent = scroll
            uiCorner(card, 8)
            row.frame = card
            row.card = card
            row.stroke = uiStroke(card, Color3.fromRGB(38, 42, 52), 1)

            local iconBg = Instance.new("Frame")
            iconBg.Size = UDim2.new(0, 52, 0, 52)
            iconBg.Position = UDim2.new(0, 8, 0.5, -26)
            iconBg.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
            iconBg.BorderSizePixel = 0
            iconBg.Parent = card
            uiCorner(iconBg, 7)
            row.icon = scMakeIcon(iconBg, 3)

            row.title = uiLabel(card, "", 13, Color3.fromRGB(244, 246, 252), UIFONT.bold)
            row.title.Size = UDim2.new(1, -170, 0, 22)
            row.title.Position = UDim2.new(0, 68, 0, 10)

            row.sub = uiLabel(card, "", 10, Color3.fromRGB(148, 155, 172), UIFONT.reg)
            row.sub.Size = UDim2.new(1, -170, 0, 18)
            row.sub.Position = UDim2.new(0, 68, 0, 34)

            local badge = uiLabel(card, "", 10, Color3.fromRGB(185, 190, 205), UIFONT.bold, Enum.TextXAlignment.Center)
            badge.Size = UDim2.new(0, 84, 0, 26)
            badge.Position = UDim2.new(1, -92, 0.5, -13)
            badge.BackgroundTransparency = 0
            uiCorner(badge, 6)
            row.badge = badge

            card.Activated:Connect(function()
                local item = row.item
                if not item then return end
                local now = os.clock()
                if SC.LastTapId == item.id and (now - SC.LastTapTime) <= 0.48 then
                    SC.LastTapId, SC.LastTapTime = nil, 0
                    scWearOrToggleItem(item.id)
                else
                    SC.LastTapId, SC.LastTapTime = item.id, now
                    badge.Text = "TAP LAGI!"
                    badge.BackgroundColor3 = Color3.fromRGB(55, 115, 215)
                    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
                    task.delay(0.5, function()
                        if row.item == item and SC.LastTapId == item.id then
                            local eq = ((SC.Worn or {})[item.slot] == item.id)
                            badge.Text = eq and "DIPAKAI ✓" or "2x TAP"
                            badge.BackgroundColor3 = eq and Color3.fromRGB(40, 145, 85) or Color3.fromRGB(30, 33, 42)
                            badge.TextColor3 = eq and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 190, 205)
                        end
                    end)
                end
            end)
            return row
        end

        local function bindClothRow(row, item)
            local eq = ((SC.Worn or {})[item.slot] == item.id)
            row.card.BackgroundColor3 = eq and Color3.fromRGB(20, 44, 34) or Color3.fromRGB(20, 22, 28)
            row.stroke.Color = eq and Color3.fromRGB(60, 185, 115) or Color3.fromRGB(38, 42, 52)
            if row.iconId ~= item.id then
                row.iconId = item.id
                scSetIcon(row.icon, item.id)
            end
            row.title.Text = string.format("%s   #%d", item.name, item.id)
            row.sub.Text = string.format("%s  •  rbxassetid://%s%s", item.slot:upper(), item.assetNum,
                item.doubleJump and "  •  2x JUMP" or "")
            row.badge.Text = eq and "DIPAKAI ✓" or "2x TAP"
            row.badge.BackgroundColor3 = eq and Color3.fromRGB(40, 145, 85) or Color3.fromRGB(30, 33, 42)
            row.badge.TextColor3 = eq and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 190, 205)
        end

        local vlist = newVList(holder, {
            name = "ClothesListScroll",
            rowH = 68, gap = 7, pad = 8,
            size = UDim2.new(1, -20, 0, 330),
            position = UDim2.new(0, 10, 0, 76),
            makeRow = makeClothRow,
            bind = bindClothRow,
        })

        -- Item dipakai: di BAWAH katalog, berupa grid kotak
        local wornPanel = Instance.new("Frame")
        wornPanel.Name = "WornBottomPanel"
        wornPanel.Size = UDim2.new(1, -20, 0, 290)
        wornPanel.Position = UDim2.new(0, 10, 0, 418)
        wornPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        wornPanel.BorderSizePixel = 0
        wornPanel.Parent = holder
        uiCorner(wornPanel, 8)
        uiStroke(wornPanel, Color3.fromRGB(44, 48, 58), 1)

        local statusDot = Instance.new("Frame")
        statusDot.Size = UDim2.new(0, 8, 0, 8)
        statusDot.Position = UDim2.new(0, 12, 0, 16)
        statusDot.BackgroundColor3 = Color3.fromRGB(72, 199, 142)
        statusDot.BorderSizePixel = 0
        statusDot.Parent = wornPanel
        uiCorner(statusDot, 99)

        local wornTitle = uiLabel(wornPanel, "ITEM DIPAKAI (0)", 12, Color3.fromRGB(230, 235, 245), UIFONT.bold)
        wornTitle.Size = UDim2.new(1, -180, 0, 18)
        wornTitle.Position = UDim2.new(0, 28, 0, 11)

        local wornSub = uiLabel(wornPanel, "1x tap pada kotak = copot", 10, Color3.fromRGB(145, 185, 255), UIFONT.reg)
        wornSub.Size = UDim2.new(1, -180, 0, 14)
        wornSub.Position = UDim2.new(0, 28, 0, 29)

        local unwearBtn = Instance.new("TextButton")
        unwearBtn.Size = UDim2.new(0, 124, 0, 28)
        unwearBtn.Position = UDim2.new(1, -132, 0, 10)
        unwearBtn.BackgroundColor3 = Color3.fromRGB(52, 22, 28)
        unwearBtn.AutoButtonColor = false
        unwearBtn.TextSize = 10
        unwearBtn.TextColor3 = Color3.fromRGB(255, 120, 130)
        unwearBtn.Text = "× UNWEAR ALL"
        lockFont(unwearBtn, UIFONT.bold)
        unwearBtn.Parent = wornPanel
        uiCorner(unwearBtn, 6)
        uiStroke(unwearBtn, Color3.fromRGB(165, 55, 65), 1)
        unwearBtn.Activated:Connect(function() scUnwearAll() end)

        local wornScroll = Instance.new("ScrollingFrame")
        wornScroll.Size = UDim2.new(1, -16, 1, -56)
        wornScroll.Position = UDim2.new(0, 8, 0, 48)
        wornScroll.BackgroundTransparency = 1
        wornScroll.BorderSizePixel = 0
        wornScroll.ScrollBarThickness = 4
        wornScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 95, 110)
        wornScroll.ScrollingDirection = Enum.ScrollingDirection.Y
        wornScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        wornScroll.CanvasSize = UDim2.new()
        wornScroll.Parent = wornPanel

        local wornGrid = Instance.new("UIGridLayout")
        wornGrid.CellSize = UDim2.fromOffset(92, 104)
        wornGrid.CellPadding = UDim2.fromOffset(8, 8)
        wornGrid.SortOrder = Enum.SortOrder.LayoutOrder
        wornGrid.Parent = wornScroll

        local function refreshWornColumn()
            for _, ch in ipairs(wornScroll:GetChildren()) do
                if ch:IsA("GuiObject") then ch:Destroy() end
            end
            local W = SC.Worn or scFindWorn()
            if not W or not SC.DB then
                statusDot.BackgroundColor3 = Color3.fromRGB(240, 170, 60)
                wornTitle.Text = "BELUM TERHUBUNG (masuk World dulu)"
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
            statusDot.BackgroundColor3 = #entries > 0 and Color3.fromRGB(72, 199, 142) or Color3.fromRGB(120, 125, 140)
            wornTitle.Text = string.format("ITEM DIPAKAI (%d)", #entries)

            for i, e in ipairs(entries) do
                local isVis = SC.Ov[e.slot] ~= nil
                local tile = Instance.new("TextButton")
                tile.LayoutOrder = i
                tile.BackgroundColor3 = isVis and Color3.fromRGB(24, 36, 52) or Color3.fromRGB(26, 28, 36)
                tile.AutoButtonColor = false
                tile.Text = ""
                tile.Parent = wornScroll
                uiCorner(tile, 8)
                local cs = uiStroke(tile, isVis and Color3.fromRGB(65, 140, 230) or Color3.fromRGB(48, 52, 64), 1)

                local iconHolder = Instance.new("Frame")
                iconHolder.Size = UDim2.new(0, 60, 0, 60)
                iconHolder.Position = UDim2.new(0.5, -30, 0, 8)
                iconHolder.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
                iconHolder.BorderSizePixel = 0
                iconHolder.Parent = tile
                uiCorner(iconHolder, 7)
                scSetIcon(scMakeIcon(iconHolder, 3), e.id)

                local nameLbl = uiLabel(tile, e.name, 10, Color3.fromRGB(242, 244, 250), UIFONT.bold, Enum.TextXAlignment.Center)
                nameLbl.Size = UDim2.new(1, -8, 0, 14)
                nameLbl.Position = UDim2.new(0, 4, 0, 72)

                local slotLbl = uiLabel(tile, tostring(e.slot):upper(), 9,
                    isVis and Color3.fromRGB(115, 185, 255) or Color3.fromRGB(150, 155, 170), UIFONT.reg, Enum.TextXAlignment.Center)
                slotLbl.Size = UDim2.new(1, -8, 0, 12)
                slotLbl.Position = UDim2.new(0, 4, 0, 87)

                tile.MouseEnter:Connect(function() cs.Color = Color3.fromRGB(235, 80, 90) end)
                tile.MouseLeave:Connect(function()
                    cs.Color = isVis and Color3.fromRGB(65, 140, 230) or Color3.fromRGB(48, 52, 64)
                end)
                tile.Activated:Connect(function() scRemoveSlot(e.slot) end)
            end
        end

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
            countLabel.Text = string.format("KATALOG %d ITEM  •  FILTER: %s  •  2x TAP = PAKAI",
                #out, (SC.SelectedSlot or "All"):upper())
            vlist:SetData(out, toTop)
        end

        local function refreshAll()
            refreshWornColumn()
            vlist:Refresh()
        end

        local filterToken = 0
        SC.FilterFn = function()
            filterToken += 1
            local my = filterToken
            task.delay(0.1, function()
                if my == filterToken then pcall(applyFilter, true) end
            end)
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            SC.SearchQuery = searchBox.Text
            SC.FilterFn()
        end)
        clearSearchBtn.Activated:Connect(function()
            searchBox.Text = ""
            SC.SearchQuery = ""
            SC.FilterFn()
        end)

        SC.RefreshWornBarFn = refreshAll
        SC.UpdateUIFn = refreshAll
        refreshWornColumn()
        applyFilter(true)
    end)
end


-- =========================================================================
-- CHECK MODERATOR
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
-- ESP JARING (SPIDERWEB) - garis langsung ke badan sprite player
-- =========================================================================
local ESP = {
    Targets = {},
    Objs = {},
    WebLines = {},
    CenterNode = nil,
    Overlay = nil,
    Others = nil,
    Entries = nil,
    Layer = nil,
    Probe = nil,
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
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local gg = pg and pg:FindFirstChild("GameGui")
    if gg then
        local t = gg:FindFirstChild("Tiles", true)
        if t and t:IsA("GuiObject") then
            ESP.Layer = t
            if ESP.Probe then pcall(function() ESP.Probe:Destroy() end) end
            local probe = Instance.new("Frame")
            probe.Name = "R8DV_ScaleProbe"
            probe.BackgroundTransparency = 1
            probe.BorderSizePixel = 0
            probe.Size = UDim2.fromOffset(100, 100)
            probe.Parent = t.Parent
            ESP.Probe = probe
            return t
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

-- Posisi badan sprite player langsung dari frame sprite game
local function espBodyScreenPos(entry)
    if not entry then return nil end
    local g = entry.group
    if typeof(g) == "Instance" and g:IsA("GuiObject") and g.Parent then
        local sz = g.AbsoluteSize
        if sz.X > 0 or sz.Y > 0 then
            return g.AbsolutePosition + sz * 0.5
        end
    end
    return nil
end

local function espHostGui()
    local E = espEntries()
    if E then
        for _, e in pairs(E) do
            local g = type(e) == "table" and e.group
            if typeof(g) == "Instance" and g.Parent then
                local h = g:FindFirstAncestorOfClass("ScreenGui")
                if h then return h end
            end
        end
    end
    return ESP.Layer and ESP.Layer:FindFirstAncestorOfClass("ScreenGui")
end

local function espStatusOf(plr, entry)
    local attrHidden = (plr:GetAttribute("Invisible") == true) or (plr:GetAttribute("Ghost") == true)
        or (plr:GetAttribute("Hidden") == true)
    if not entry then
        return attrHidden and "HIDDEN" or "OFF-GRID", false, attrHidden
    end
    if not entry.seen then
        return "HIDDEN", (type(entry.x) == "number" and type(entry.y) == "number"), true
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
            if hasPos and entry and type(entry.x) == "number" and mx then
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

local function espEnsureOverlay()
    if ESP.Overlay and ESP.Overlay.Parent then return ESP.Overlay end
    local parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
        or LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "R8DV_SpiderwebESP_Overlay"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 9999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local host = espHostGui()
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

local function espClearWebLines()
    for _, ln in ipairs(ESP.WebLines) do
        if ln and ln.Parent then ln.Visible = false end
    end
    if ESP.CenterNode and ESP.CenterNode.Parent then
        ESP.CenterNode.Visible = false
    end
end

local function espClearAll()
    for uid in pairs(ESP.Objs) do espDestroyObj(uid) end
    espClearWebLines()
end

local function espForget(plr)
    if plr then
        ESP.Targets[plr.UserId] = nil
        espDestroyObj(plr.UserId)
    end
end

local function espMakeObj(sg, uid)
    local line = Instance.new("Frame")
    line.Name = "WebRay_" .. uid
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.Visible = false
    line.Parent = sg

    local node = Instance.new("Frame")
    node.Name = "WebNode_" .. uid
    node.AnchorPoint = Vector2.new(0.5, 0.5)
    node.Size = UDim2.fromOffset(18, 18)
    node.BackgroundTransparency = 0.65
    node.BorderSizePixel = 0
    node.Visible = false
    node.Parent = sg
    uiCorner(node, 99)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.6
    stroke.Parent = node

    local innerDot = Instance.new("Frame")
    innerDot.Size = UDim2.fromOffset(5, 5)
    innerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    innerDot.Position = UDim2.fromScale(0.5, 0.5)
    innerDot.BorderSizePixel = 0
    innerDot.Parent = node
    uiCorner(innerDot, 99)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Tag_" .. uid
    lbl.AnchorPoint = Vector2.new(0.5, 1)
    lbl.Size = UDim2.fromOffset(145, 18)
    lbl.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
    lbl.BackgroundTransparency = 0.35
    lbl.BorderSizePixel = 0
    lbl.TextSize = 10
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Visible = false
    lbl.Parent = sg
    lbl:SetAttribute("R8DV_SkipLight", true)
    lbl.FontFace = UIFONT.bold
    uiCorner(lbl, 4)

    local o = { line = line, node = node, stroke = stroke, inner = innerDot, lbl = lbl }
    ESP.Objs[uid] = o
    return o
end

local function espDrawLine(lineFrame, p1, p2, color, thickness, trans)
    local delta = p2 - p1
    local len = delta.Magnitude
    if len < 3 then
        lineFrame.Visible = false
        return
    end
    lineFrame.BackgroundColor3 = color
    lineFrame.BackgroundTransparency = trans or 0.25
    lineFrame.Position = UDim2.fromOffset((p1.X + p2.X) * 0.5, (p1.Y + p2.Y) * 0.5)
    lineFrame.Size = UDim2.fromOffset(len, thickness or 1.5)
    lineFrame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    lineFrame.Visible = true
end

local function espWantedTargets()
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
    if next(want) == nil then
        espClearWebLines()
        return
    end

    espLayer()
    local sg = espEnsureOverlay()
    local hostGui = espHostGui()
    if hostGui and sg.IgnoreGuiInset ~= hostGui.IgnoreGuiInset then
        sg.IgnoreGuiInset = hostGui.IgnoreGuiInset
    end
    Camera = Workspace.CurrentCamera
    local vs = sg.AbsoluteSize
    if vs.X <= 0 then vs = (Camera and Camera.ViewportSize) or Vector2.new(800, 600) end
    local showHidden = getValue("ESP_Hidden", true)

    local mx, my = espMyPos()
    local myEntry = espEntryOf(LocalPlayer.UserId)
    local me2D = espBodyScreenPos(myEntry)
        or (mx and espToScreen(mx, my - 0.5))
        or Vector2.new(vs.X / 2, vs.Y / 2)

    if not ESP.CenterNode or not ESP.CenterNode.Parent then
        local cn = Instance.new("Frame")
        cn.Name = "SpiderWebHub"
        cn.AnchorPoint = Vector2.new(0.5, 0.5)
        cn.Size = UDim2.fromOffset(10, 10)
        cn.BackgroundColor3 = Color3.fromRGB(90, 225, 255)
        cn.BackgroundTransparency = 0.2
        cn.BorderSizePixel = 0
        cn.Parent = sg
        uiCorner(cn, 99)
        uiStroke(cn, Color3.fromRGB(255, 255, 255), 1)
        ESP.CenterNode = cn
    end

    local activeScreenPoints = {}

    for uid, plr in pairs(want) do
        local o = ESP.Objs[uid] or espMakeObj(sg, uid)
        local entry = espEntryOf(uid)
        local _, hasPos, hidden = espStatusOf(plr, entry)
        local modInfo = ModSys.ActiveMods[plr]

        local color
        if modInfo then color = Color3.fromRGB(255, 65, 75)
        elseif hidden then color = Color3.fromRGB(195, 115, 255)
        else color = Color3.fromRGB(75, 225, 255) end

        local pos2D
        if showHidden or not hidden then
            pos2D = espBodyScreenPos(entry)
            if not pos2D and hasPos and entry and type(entry.x) == "number" and type(entry.y) == "number" then
                pos2D = espToScreen(entry.x, entry.y - 0.5)
            end
        end

        if not pos2D then
            o.line.Visible = false
            o.node.Visible = false
            o.lbl.Visible = false
        else
            local margin = 28
            local clamped = Vector2.new(
                math.clamp(pos2D.X, margin, vs.X - margin),
                math.clamp(pos2D.Y, margin, vs.Y - margin)
            )

            espDrawLine(o.line, me2D, clamped, color, modInfo and 2.2 or 1.5, 0.2)

            o.node.BackgroundColor3 = color
            o.stroke.Color = color
            o.inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            o.node.Position = UDim2.fromOffset(clamped.X, clamped.Y)
            o.node.Visible = true

            local dist = 0
            if mx and entry and type(entry.x) == "number" then
                dist = math.sqrt((entry.x - mx) ^ 2 + (entry.y - my) ^ 2)
            end
            o.lbl.TextColor3 = color
            o.lbl.Position = UDim2.fromOffset(clamped.X, clamped.Y - 12)
            o.lbl.Text = string.format("%s%s [%.0ft]", modInfo and "⚠ " or "", plr.Name, dist)
            o.lbl.Visible = true

            activeScreenPoints[#activeScreenPoints + 1] = { pt = clamped, color = color }
        end
    end

    local webIdx = 0
    local nPts = #activeScreenPoints
    ESP.CenterNode.Position = UDim2.fromOffset(me2D.X, me2D.Y)
    ESP.CenterNode.Visible = (nPts > 0)

    if getValue("ESP_WebMesh", true) and nPts >= 2 then
        table.sort(activeScreenPoints, function(a, b)
            local angA = math.atan2(a.pt.Y - me2D.Y, a.pt.X - me2D.X)
            local angB = math.atan2(b.pt.Y - me2D.Y, b.pt.X - me2D.X)
            return angA < angB
        end)

        for i = 1, nPts do
            local pA = activeScreenPoints[i].pt
            local pB = activeScreenPoints[(i % nPts) + 1].pt

            webIdx += 1
            local outerLine = ESP.WebLines[webIdx]
            if not outerLine or not outerLine.Parent then
                outerLine = Instance.new("Frame")
                outerLine.Name = "SpiderWebOuter_" .. webIdx
                outerLine.BorderSizePixel = 0
                outerLine.AnchorPoint = Vector2.new(0.5, 0.5)
                outerLine.Parent = sg
                ESP.WebLines[webIdx] = outerLine
            end
            espDrawLine(outerLine, pA, pB, Color3.fromRGB(95, 210, 255), 1, 0.58)

            local midA = me2D:Lerp(pA, 0.45)
            local midB = me2D:Lerp(pB, 0.45)
            webIdx += 1
            local innerLine = ESP.WebLines[webIdx]
            if not innerLine or not innerLine.Parent then
                innerLine = Instance.new("Frame")
                innerLine.Name = "SpiderWebInner_" .. webIdx
                innerLine.BorderSizePixel = 0
                innerLine.AnchorPoint = Vector2.new(0.5, 0.5)
                innerLine.Parent = sg
                ESP.WebLines[webIdx] = innerLine
            end
            espDrawLine(innerLine, midA, midB, Color3.fromRGB(95, 210, 255), 1, 0.68)
        end
    end

    for i = webIdx + 1, #ESP.WebLines do
        if ESP.WebLines[i] then ESP.WebLines[i].Visible = false end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(espRender)
end)

-- Daftar player (embedded)
local function espMountPlayerList()
    task.spawn(function()
        task.wait(0.6)
        local cardContainer = findAnchorContainer("DAFTAR PLAYER", 40, 0.4)
        if not cardContainer then return end
        local old = cardContainer:FindFirstChild("R8DV_PlayerListBrowser")
        if old then old:Destroy() end

        local holder = Instance.new("Frame")
        holder.Name = "R8DV_PlayerListBrowser"
        holder.Size = UDim2.new(1, 0, 0, 380)
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

        local function makeRow(scroll)
            local row = {}
            local card = Instance.new("TextButton")
            card.Name = "PlayerRow"
            card.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
            card.BorderSizePixel = 0
            card.AutoButtonColor = false
            card.Text = ""
            card.Parent = scroll
            uiCorner(card, 7)
            row.frame = card
            row.stroke = uiStroke(card, Color3.fromRGB(38, 42, 52), 1)

            row.dot = Instance.new("Frame")
            row.dot.Size = UDim2.fromOffset(8, 8)
            row.dot.Position = UDim2.new(0, 10, 0.5, -4)
            row.dot.BorderSizePixel = 0
            row.dot.Parent = card
            uiCorner(row.dot, 99)

            row.title = uiLabel(card, "", 12, Color3.fromRGB(242, 244, 250), UIFONT.bold)
            row.title.Size = UDim2.new(1, -110, 0, 20)
            row.title.Position = UDim2.new(0, 26, 0, 7)

            row.sub = uiLabel(card, "", 10, Color3.fromRGB(145, 152, 168), UIFONT.reg)
            row.sub.Size = UDim2.new(1, -110, 0, 18)
            row.sub.Position = UDim2.new(0, 26, 0, 27)

            local espBtn = Instance.new("TextButton")
            espBtn.Size = UDim2.fromOffset(78, 28)
            espBtn.Position = UDim2.new(1, -86, 0.5, -14)
            espBtn.AutoButtonColor = false
            espBtn.TextSize = 10
            espBtn.Text = "JARING ESP"
            espBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            espBtn.BackgroundColor3 = COL_OFF
            lockFont(espBtn, UIFONT.bold)
            espBtn.Parent = card
            uiCorner(espBtn, 6)
            row.espBtn = espBtn

            local function toggleTarget()
                local it = row.item
                if not it then return end
                if ESP.Targets[it.userId] then
                    ESP.Targets[it.userId] = nil
                else
                    ESP.Targets[it.userId] = true
                end
                row.dirty = true
                if ESP.SoftRefresh then ESP.SoftRefresh() end
            end

            espBtn.Activated:Connect(toggleTarget)
            card.Activated:Connect(toggleTarget)
            return row
        end

        local function bindRow(row, it)
            local active = ESP.Targets[it.userId] == true
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

            row.espBtn.Text = active and "JARING ON" or "JARING OFF"
            row.espBtn.BackgroundColor3 = active and COL_ON or COL_OFF
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
            info.Text = string.format("%d player  •  %d staff  •  %d hidden  •  %d jaring aktif", shown, mods, hid, nTarget)
            vlist:SetData(rows, toTop)
        end

        quickBtn("JARING SEMUA PLAYER", 0, function()
            for _, r in ipairs(rows) do ESP.Targets[r.userId] = true end
            reload(false)
        end)
        quickBtn("BERSIHKAN JARING ESP", 0.5, function()
            ESP.Targets = {}
            espClearAll()
            reload(false)
        end)

        ESP.SoftRefresh = function() reload(false) end
        ESP.ListRefresh = function(toTop) reload(toTop) end

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
-- LOGIKA AUTO FARM (tanpa teleport; collect hanya kirim paket ambil)
-- =========================================================================
local AF = {
    Running = false,
    Button = nil,
    StatusLbl = nil,
    SelectedBlockId = nil,
    SelectedTiles = { ["1,0"] = { dx = 1, dy = 0 } },
    TileOrder = { { dx = 1, dy = 0 } },
    PlaceDelay = 0.18,
    BreakDelay = 0.16,
    CollectDelay = 0.12,
    BreakHits = 4,
    AutoCollect = false,
    CollectRadius = 4,
    OnlyShowOwnedBP = true,
    Method = "Dual Method (Client + Server Packet)",
    SearchQuery = "",
    InvModule = nil,
    DropModule = nil,
    BPCounts = {},
    RefreshBPUI = nil,
    UpdateTileGridUI = nil,
    PlacedCount = 0,
    BrokenCount = 0,
    CollectedCount = 0,
}

local AF_METHODS = {
    "Dual Method (Client + Server Packet)",
    "Method 1: Server Packet Direct (Net)",
    "Method 2: Client Game Handler + Packet"
}

local function afScanBackpackCounts()
    local counts = {}
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    if sh and not AF.InvModule then
        pcall(function() AF.InvModule = require(sh:FindFirstChild("Inventory")) end)
    end

    local function absorbTable(t)
        if type(t) ~= "table" then return end
        for k, v in pairs(t) do
            if type(k) == "number" and type(v) == "number" and k > 0 and v > 0 and SC.DB and SC.DB[k] then
                counts[k] = math.max(counts[k] or 0, v)
            elseif type(k) == "string" and tonumber(k) and type(v) == "number" and v > 0 then
                local id = tonumber(k)
                if SC.DB and SC.DB[id] then counts[id] = math.max(counts[id] or 0, v) end
            elseif type(v) == "table" then
                local id = tonumber(v.id or v.itemId or v.item or v[1])
                local cnt = tonumber(v.count or v.amount or v.qty or v.n or v[2])
                if id and cnt and cnt > 0 and SC.DB and SC.DB[id] then
                    counts[id] = math.max(counts[id] or 0, cnt)
                end
            end
        end
    end

    local Inv = AF.InvModule
    if type(Inv) == "table" then
        absorbTable(Inv.items or Inv.slots or Inv.bag or Inv.data or Inv.inventory or Inv)
        for _, fnName in ipairs({ "getItems", "GetItems", "all", "list", "getAll" }) do
            if type(Inv[fnName]) == "function" then
                local ok, res = pcall(Inv[fnName], Inv)
                if not ok or type(res) ~= "table" then ok, res = pcall(Inv[fnName]) end
                if ok and type(res) == "table" then absorbTable(res) end
            end
        end
        for _, v in pairs(Inv) do
            if type(v) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
                local okU, ups = pcall(debug.getupvalues, v)
                if okU and type(ups) == "table" then
                    for _, up in pairs(ups) do
                        if type(up) == "table" then absorbTable(up) end
                    end
                end
            end
        end
    end

    pcall(scFindWorn)
    for _, rootTbl in ipairs({ SC.State, SC.Game }) do
        if type(rootTbl) == "table" then
            absorbTable(rootTbl.inv or rootTbl.inventory or rootTbl.items or rootTbl.bag)
            for _, v in pairs(rootTbl) do
                if type(v) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
                    local okU, ups = pcall(debug.getupvalues, v)
                    if okU and type(ups) == "table" then
                        for _, up in pairs(ups) do
                            if type(up) == "table" and rawget(up, "onWear") == nil and up ~= SC.Worn then
                                absorbTable(up)
                            end
                        end
                    end
                end
            end
        end
    end

    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local gg = pg and pg:FindFirstChild("GameGui")
    if gg then
        for _, d in ipairs(gg:GetDescendants()) do
            if d:IsA("GuiObject") then
                local itemId = tonumber(d:GetAttribute("ItemId") or d:GetAttribute("Id") or d.Name:match("^Slot_(%d+)$") or d.Name:match("^Item_(%d+)$"))
                if itemId and SC.DB and SC.DB[itemId] then
                    local cnt = tonumber(d:GetAttribute("Count") or d:GetAttribute("Amount"))
                    if not cnt then
                        for _, sub in ipairs(d:GetDescendants()) do
                            if sub:IsA("TextLabel") then
                                local n = tonumber(sub.Text:match("(%d+)"))
                                if n and n > 0 then cnt = n; break end
                            end
                        end
                    end
                    if cnt and cnt > 0 then
                        counts[itemId] = math.max(counts[itemId] or 0, cnt)
                    end
                end
            end
        end
    end

    AF.BPCounts = counts
    return counts
end

-- Offset grid (dx,dy) -> tile dunia. Atas di grid = tile di atas karakter (y berkurang)
local function afGetWorldTileFromOffset(myX, myY, dx, dy)
    local baseTx = math.floor(myX + 0.5)
    local baseTy = math.floor(myY + 0.5)
    local yDir = getValue("AF_InvertY", true) and -1 or 1
    return baseTx + dx, baseTy + (dy * yDir)
end

local function afCheckTileHasBlock(tx, ty)
    pcall(scFindWorn)

    for _, obj in ipairs({ SC.State, SC.Game }) do
        if type(obj) == "table" then
            for _, fnName in ipairs({ "getTile", "tileAt", "getBlock", "blockAt", "fgAt", "getFg", "cellAt" }) do
                local fn = rawget(obj, fnName)
                if type(fn) == "function" then
                    local ok, res, res2 = pcall(fn, tx, ty)
                    if not ok then ok, res, res2 = pcall(fn, obj, tx, ty) end
                    if ok and res ~= nil then
                        if type(res) == "number" then return res > 0, res end
                        if type(res) == "table" then
                            local fg = tonumber(res.fg or res.id or res.block or res[1] or 0) or 0
                            if fg > 0 then return true, fg end
                            return false, 0
                        end
                    end
                end
            end

            for _, tblName in ipairs({ "tiles", "fg", "blocks", "map", "grid", "world" }) do
                local t = rawget(obj, tblName)
                if type(t) == "table" then
                    local row = t[ty] or t[tx]
                    if type(row) == "table" then
                        local cell = (t[ty] and t[ty][tx]) or (t[tx] and t[tx][ty])
                        if type(cell) == "number" then return cell > 0, cell end
                        if type(cell) == "table" then
                            local fg = tonumber(cell.fg or cell.id or cell.block or cell[1] or 0) or 0
                            return fg > 0, fg
                        end
                    end
                    local keyStr = tostring(tx) .. "," .. tostring(ty)
                    local keyColon = tostring(tx) .. ":" .. tostring(ty)
                    local cell = t[keyStr] or t[keyColon]
                    if type(cell) == "number" then return cell > 0, cell end
                    if type(cell) == "table" then
                        local fg = tonumber(cell.fg or cell.id or cell.block or cell[1] or 0) or 0
                        return fg > 0, fg
                    end
                end
            end
        end
    end

    local layer = espLayer()
    if layer then
        local tilePx = espPX()
        local targetX = tx * tilePx
        local targetY = ty * tilePx
        for _, ch in ipairs(layer:GetChildren()) do
            if ch:IsA("GuiObject") and ch.Visible then
                local nm = ch.Name:lower()
                if not nm:find("^bg") then
                    local cx = ch.Position.X.Offset
                    local cy = ch.Position.Y.Offset
                    if math.abs(cx - targetX) <= 6 and math.abs(cy - targetY) <= 6 then
                        if ch:IsA("ImageLabel") and (ch.Image == "" or ch.ImageTransparency >= 0.98) then
                            -- tile kosong
                        else
                            return true, 1
                        end
                    end
                end
            end
        end
    end

    return false, 0
end

local function afSendPlace(tx, ty, itemId)
    local Net = scGetNet()
    local method = AF.Method

    if Net and (method == "Dual Method (Client + Server Packet)" or method == "Method 1: Server Packet Direct (Net)") then
        for _, k in ipairs({ "place", "tile", "use", "build", "put", "action", "interact" }) do
            local pkt = Net[k]
            if type(pkt) == "table" and type(pkt.send) == "function" then
                pcall(pkt.send, { x = tx, y = ty, id = itemId, item = itemId, tileX = tx, tileY = ty, action = "place" })
                pcall(pkt.send, tx, ty, itemId)
            end
        end
    end

    if method == "Dual Method (Client + Server Packet)" or method == "Method 2: Client Game Handler + Packet" then
        for _, obj in ipairs({ SC.State, SC.Game }) do
            if type(obj) == "table" then
                for _, fnName in ipairs({ "place", "onPlace", "useItem", "tapTile", "actTile", "putTile" }) do
                    local fn = rawget(obj, fnName)
                    if type(fn) == "function" then
                        pcall(fn, tx, ty, itemId)
                        pcall(fn, obj, tx, ty, itemId)
                    end
                end
                if type(rawget(obj, "call")) == "function" then
                    pcall(obj.call, "place", tx, ty, itemId)
                end
            end
        end
    end
end

local function afSendBreak(tx, ty)
    local Net = scGetNet()
    local method = AF.Method
    local punchId = 18

    if Net and (method == "Dual Method (Client + Server Packet)" or method == "Method 1: Server Packet Direct (Net)") then
        for _, k in ipairs({ "punch", "hit", "break", "breakTile", "damage", "tile", "use", "action" }) do
            local pkt = Net[k]
            if type(pkt) == "table" and type(pkt.send) == "function" then
                pcall(pkt.send, { x = tx, y = ty, id = punchId, item = punchId, tileX = tx, tileY = ty, action = "punch" })
                pcall(pkt.send, tx, ty, punchId)
                pcall(pkt.send, { x = tx, y = ty })
            end
        end
    end

    if method == "Dual Method (Client + Server Packet)" or method == "Method 2: Client Game Handler + Packet" then
        for _, obj in ipairs({ SC.State, SC.Game }) do
            if type(obj) == "table" then
                for _, fnName in ipairs({ "punch", "hit", "breakTile", "onPunch", "tapTile", "swing" }) do
                    local fn = rawget(obj, fnName)
                    if type(fn) == "function" then
                        pcall(fn, tx, ty)
                        pcall(fn, obj, tx, ty)
                    end
                end
                if type(rawget(obj, "call")) == "function" then
                    pcall(obj.call, "punch", tx, ty)
                    pcall(obj.call, "hit", tx, ty)
                end
            end
        end
    end
end

-- Auto collect TANPA teleport: karakter tidak pernah dipindah, hanya kirim paket ambil
local function afRunAutoCollect(originX, originY)
    if not AF.AutoCollect or Spam.PausedByMod then return end
    local Net = scGetNet()
    if not Net then return end
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    if sh and not AF.DropModule then
        pcall(function() AF.DropModule = require(sh:FindFirstChild("DropBox")) end)
    end
    if type(AF.DropModule) ~= "table" then return end

    local drops = {}
    local function scan(t)
        for dk, dv in pairs(t) do
            if type(dv) == "table" and type(dv.x) == "number" and type(dv.y) == "number" then
                local d = math.sqrt((dv.x - originX) ^ 2 + (dv.y - originY) ^ 2)
                if d <= AF.CollectRadius then
                    drops[#drops + 1] = { x = dv.x, y = dv.y, uid = dv.id or dv.uid or dk }
                end
            end
        end
    end
    for _, v in pairs(AF.DropModule) do
        if type(v) == "table" then
            scan(v)
        elseif type(v) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
            local okU, ups = pcall(debug.getupvalues, v)
            if okU and type(ups) == "table" then
                for _, up in pairs(ups) do if type(up) == "table" then scan(up) end end
            end
        end
    end

    for _, d in ipairs(drops) do
        if not AF.Running or Spam.PausedByMod then break end
        for _, k in ipairs({ "collect", "pickup", "takeDrop", "dropCollect" }) do
            local pkt = Net[k]
            if type(pkt) == "table" and type(pkt.send) == "function" then
                pcall(pkt.send, d.uid)
                pcall(pkt.send, { id = d.uid, x = d.x, y = d.y })
            end
        end
        AF.CollectedCount += 1
        task.wait(math.max(AF.CollectDelay, 0.04))
    end
end

local function afUpdateButtonAndStatus(statusText)
    if AF.Button then
        local txt = AF.Running and "STOP FARM" or "START FARM"
        pcall(function()
            if AF.Button.SetText then AF.Button:SetText(txt)
            elseif AF.Button.SetLabel then AF.Button:SetLabel(txt) end
        end)
    end
    if AF.StatusLbl and statusText then
        pcall(function() AF.StatusLbl.Text = statusText end)
    end
end

local function afStop(reason)
    AF.Running = false
    afUpdateButtonAndStatus("⏹ Berhenti (" .. tostring(reason or "Manual") .. ")")
end

local function afStart()
    if AF.Running then return end
    scBuildItems()

    if not AF.SelectedBlockId or not SC.DB or not SC.DB[AF.SelectedBlockId] then
        notifyClient("Auto Farm", "Pilih Block terlebih dahulu dari daftar BP!", 4)
        return
    end
    if #AF.TileOrder == 0 then
        notifyClient("Auto Farm", "Pilih minimal 1 kotak target pada Grid 5x5!", 4)
        return
    end

    AF.Running = true
    local blockName = SC.DB[AF.SelectedBlockId].name
    afUpdateButtonAndStatus(string.format("▶ RUNNING: %s (#%d) pada %d tile", blockName, AF.SelectedBlockId, #AF.TileOrder))
    notifyClient("Auto Farm", "Auto Farm dimulai: " .. blockName, 3)

    task.spawn(function()
        while AF.Running do
            if Spam.PausedByMod then
                afUpdateButtonAndStatus("⏸ PAUSED: Menunggu Moderator keluar...")
                task.wait(0.5)
            else
                local mx, my = espMyPos()
                if not mx or not my then
                    afUpdateButtonAndStatus("⏳ Menunggu posisi karakter di dalam World...")
                    task.wait(0.5)
                else
                    local originX, originY = mx, my
                    local activeTargets = {}

                    for _, offset in ipairs(AF.TileOrder) do
                        if not AF.Running or Spam.PausedByMod then break end
                        local tx, ty = afGetWorldTileFromOffset(originX, originY, offset.dx, offset.dy)
                        activeTargets[#activeTargets + 1] = { tx = tx, ty = ty, dx = offset.dx, dy = offset.dy }

                        local alreadyHasBlock = afCheckTileHasBlock(tx, ty)
                        if alreadyHasBlock then
                            afUpdateButtonAndStatus(string.format("⏭ Tile (%+d,%+d) sudah ada block -> Skip Place", offset.dx, offset.dy))
                        else
                            afUpdateButtonAndStatus(string.format("🧱 Place %s di Tile (%+d,%+d)", blockName, offset.dx, offset.dy))
                            afSendPlace(tx, ty, AF.SelectedBlockId)
                            AF.PlacedCount += 1
                            task.wait(math.max(AF.PlaceDelay, 0.05))
                        end
                    end

                    for _, tgt in ipairs(activeTargets) do
                        if not AF.Running or Spam.PausedByMod then break end
                        local tx, ty = tgt.tx, tgt.ty
                        local maxHits = math.max(tonumber(AF.BreakHits) or 4, 1)
                        local extraVerifyRetries = 3

                        for hitIdx = 1, (maxHits + extraVerifyRetries) do
                            if not AF.Running or Spam.PausedByMod then break end

                            if hitIdx > 1 then
                                local stillThere = afCheckTileHasBlock(tx, ty)
                                if not stillThere and getValue("AF_SmartVerify", true) then
                                    afUpdateButtonAndStatus(string.format("✔ Tile (%+d,%+d) hancur pada hit ke-%d -> Skip", tgt.dx, tgt.dy, hitIdx - 1))
                                    break
                                end
                            end

                            if hitIdx > maxHits then
                                afUpdateButtonAndStatus(string.format("⏳ Tile (%+d,%+d) belum hancur, jeda verifikasi...", tgt.dx, tgt.dy))
                                task.wait(math.max(AF.BreakDelay * 0.75, 0.08))
                            end

                            afUpdateButtonAndStatus(string.format("⛏ Break Tile (%+d,%+d) [Hit %d/%d]", tgt.dx, tgt.dy, math.min(hitIdx, maxHits), maxHits))
                            afSendBreak(tx, ty)
                            task.wait(math.max(AF.BreakDelay, 0.05))
                        end
                        AF.BrokenCount += 1
                    end

                    if AF.Running and not Spam.PausedByMod and AF.AutoCollect then
                        afUpdateButtonAndStatus("🧲 Auto Collect: kirim paket ambil drop...")
                        afRunAutoCollect(originX, originY)
                    end

                    if AF.RefreshBPUI then pcall(AF.RefreshBPUI, false) end
                    task.wait(0.05)
                end
            end
        end
    end)
end

local function afToggle()
    if AF.Running then afStop("Manual Stop") else afStart() end
end


local function afMountEmbeddedUI()
    task.spawn(function()
        task.wait(0.9)
        scBuildItems()
        afScanBackpackCounts()

        local cardContainer = findAnchorContainer("MATRIX TILE 5X5 & KATALOG BP", 35, 0.3)
        if not cardContainer then return end
        local old = cardContainer:FindFirstChild("R8DV_AutoFarmSuite")
        if old then old:Destroy() end

        local holder = Instance.new("Frame")
        holder.Name = "R8DV_AutoFarmSuite"
        holder.Size = UDim2.new(1, 0, 0, 900)
        holder.BackgroundColor3 = Color3.fromRGB(15, 16, 20)
        holder.BorderSizePixel = 0
        holder.LayoutOrder = 99
        holder.Parent = cardContainer
        uiCorner(holder, 10)
        uiStroke(holder, Color3.fromRGB(38, 40, 48), 1)

        local statusBanner = uiLabel(holder, "⏹ Siap — pilih block dan tile target", 11, Color3.fromRGB(130, 210, 255), UIFONT.bold, Enum.TextXAlignment.Center)
        statusBanner.Size = UDim2.new(1, -20, 0, 26)
        statusBanner.Position = UDim2.new(0, 10, 0, 8)
        statusBanner.BackgroundTransparency = 0
        statusBanner.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
        uiCorner(statusBanner, 6)
        AF.StatusLbl = statusBanner

        -- Panel grid (atas, lebar penuh)
        local matrixPanel = Instance.new("Frame")
        matrixPanel.Size = UDim2.new(1, -20, 0, 420)
        matrixPanel.Position = UDim2.new(0, 10, 0, 40)
        matrixPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        matrixPanel.BorderSizePixel = 0
        matrixPanel.Parent = holder
        uiCorner(matrixPanel, 8)
        uiStroke(matrixPanel, Color3.fromRGB(44, 48, 58), 1)

        -- 5x5 persegi, ukuran tetap, di tengah panel
        local gridFrame = Instance.new("Frame")
        gridFrame.Size = UDim2.fromOffset(300, 300)
        gridFrame.AnchorPoint = Vector2.new(0.5, 0)
        gridFrame.Position = UDim2.new(0.5, 0, 0, 12)
        gridFrame.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
        gridFrame.BorderSizePixel = 0
        gridFrame.Parent = matrixPanel
        uiCorner(gridFrame, 8)
        uiStroke(gridFrame, Color3.fromRGB(34, 38, 48), 1)

        local gp = Instance.new("UIPadding")
        gp.PaddingTop, gp.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
        gp.PaddingLeft, gp.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
        gp.Parent = gridFrame

        local uiGrid = Instance.new("UIGridLayout")
        uiGrid.CellSize = UDim2.fromOffset(52, 52)
        uiGrid.CellPadding = UDim2.fromOffset(6, 6)
        uiGrid.SortOrder = Enum.SortOrder.LayoutOrder
        uiGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        uiGrid.VerticalAlignment = Enum.VerticalAlignment.Center
        uiGrid.Parent = gridFrame

        local function mkBtn(text, x, w, y, h, bg, fg, size)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(w[1], w[2], 0, h)
            b.Position = UDim2.new(x[1], x[2], 0, y)
            b.BackgroundColor3 = bg
            b.AutoButtonColor = false
            b.TextSize = size or 10
            b.TextColor3 = fg
            b.Text = text
            lockFont(b, UIFONT.bold)
            b.Parent = matrixPanel
            uiCorner(b, 7)
            return b
        end

        local clearTilesBtn = mkBtn("RESET TILE", { 0, 12 }, { 0.5, -18 }, 320, 30, Color3.fromRGB(45, 24, 28), Color3.fromRGB(255, 125, 135))
        local presetBtn = mkBtn("ATAS & KANAN", { 0.5, 6 }, { 0.5, -18 }, 320, 30, Color3.fromRGB(28, 42, 62), Color3.fromRGB(135, 195, 255))
        local quickStartBtn = mkBtn("▶  START / STOP AUTO FARM", { 0, 12 }, { 1, -24 }, 362, 44, Color3.fromRGB(36, 145, 82), Color3.fromRGB(255, 255, 255), 12)
        quickStartBtn.Activated:Connect(function()
            afToggle()
            quickStartBtn.BackgroundColor3 = AF.Running and Color3.fromRGB(175, 45, 55) or Color3.fromRGB(36, 145, 82)
            quickStartBtn.Text = AF.Running and "⏹  STOP AUTO FARM" or "▶  START / STOP AUTO FARM"
        end)

        local cellButtons = {}

        local function rebuildTileOrder()
            local list = {}
            for dy = 2, -2, -1 do
                for dx = -2, 2 do
                    if AF.SelectedTiles[dx .. "," .. dy] then
                        list[#list + 1] = { dx = dx, dy = dy }
                    end
                end
            end
            AF.TileOrder = list
        end

        local function refreshGridVisuals()
            rebuildTileOrder()
            for key, o in pairs(cellButtons) do
                local on = AF.SelectedTiles[key] ~= nil
                o.btn.BackgroundColor3 = on and Color3.fromRGB(38, 130, 82) or Color3.fromRGB(22, 25, 32)
                o.stroke.Color = on and Color3.fromRGB(95, 235, 150) or Color3.fromRGB(44, 48, 60)
                o.stroke.Thickness = on and 2 or 1
            end
        end

        -- Kotak tengah: ikon dari item game yang sedang dipakai (bukan foto Roblox)
        local centerCell = Instance.new("Frame")
        centerCell.Name = "YouCell"
        centerCell.LayoutOrder = 13
        centerCell.BackgroundColor3 = Color3.fromRGB(24, 38, 58)
        centerCell.BorderSizePixel = 0
        centerCell.Parent = gridFrame
        uiCorner(centerCell, 7)
        uiStroke(centerCell, Color3.fromRGB(80, 185, 255), 2)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(14, 14)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.fromScale(0.5, 0.5)
        dot.BackgroundColor3 = Color3.fromRGB(90, 225, 255)
        dot.BorderSizePixel = 0
        dot.Parent = centerCell
        uiCorner(dot, 99)

        local youIcon = scMakeIcon(centerCell, 4)
        youIcon.frame.Visible = false
        local PRIORITY = { "hair", "head", "face", "mask", "hat", "chest", "shirt", "body" }

        local function refreshAvatar()
            local W = SC.Worn
            local pick
            if W and SC.DB then
                for _, s in ipairs(PRIORITY) do
                    if W[s] then pick = W[s]; break end
                end
                if not pick then
                    for _, id in pairs(W) do pick = id; break end
                end
            end
            if pick then
                scSetIcon(youIcon, pick)
                dot.Visible = false
            else
                youIcon.frame.Visible = false
                dot.Visible = true
            end
        end

        local idx = 0
        for dy = 2, -2, -1 do
            for dx = -2, 2 do
                idx += 1
                if not (dx == 0 and dy == 0) then
                    local key = dx .. "," .. dy
                    local btn = Instance.new("TextButton")
                    btn.LayoutOrder = idx
                    btn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
                    btn.AutoButtonColor = false
                    btn.Text = ""
                    btn.Parent = gridFrame
                    uiCorner(btn, 7)
                    local st = uiStroke(btn, Color3.fromRGB(44, 48, 60), 1)
                    cellButtons[key] = { btn = btn, stroke = st }
                    btn.Activated:Connect(function()
                        if AF.SelectedTiles[key] then
                            AF.SelectedTiles[key] = nil
                        else
                            AF.SelectedTiles[key] = { dx = dx, dy = dy }
                        end
                        refreshGridVisuals()
                    end)
                end
            end
        end
        -- catatan: LayoutOrder 13 = sel ke-13 = baris 3 kolom 3 = tengah (kita)

        clearTilesBtn.Activated:Connect(function()
            AF.SelectedTiles = {}
            refreshGridVisuals()
        end)
        presetBtn.Activated:Connect(function()
            AF.SelectedTiles = { ["0,1"] = { dx = 0, dy = 1 }, ["1,0"] = { dx = 1, dy = 0 } }
            refreshGridVisuals()
        end)
        AF.UpdateTileGridUI = refreshGridVisuals
        refreshGridVisuals()
        refreshAvatar()
        task.spawn(function()
            while holder.Parent do
                pcall(refreshAvatar)
                task.wait(1)
            end
        end)

        -- Panel BP (di bawah grid, lebar penuh)
        local bpPanel = Instance.new("Frame")
        bpPanel.Size = UDim2.new(1, -20, 0, 420)
        bpPanel.Position = UDim2.new(0, 10, 0, 470)
        bpPanel.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        bpPanel.BorderSizePixel = 0
        bpPanel.Parent = holder
        uiCorner(bpPanel, 8)
        uiStroke(bpPanel, Color3.fromRGB(44, 48, 58), 1)

        local bpHeader = uiLabel(bpPanel, "PILIH BLOCK DARI BP", 12, Color3.fromRGB(235, 240, 250), UIFONT.bold)
        bpHeader.Size = UDim2.new(1, -130, 0, 20)
        bpHeader.Position = UDim2.new(0, 12, 0, 10)

        local scanBpBtn = Instance.new("TextButton")
        scanBpBtn.Size = UDim2.new(0, 108, 0, 26)
        scanBpBtn.Position = UDim2.new(1, -116, 0, 8)
        scanBpBtn.BackgroundColor3 = Color3.fromRGB(32, 65, 115)
        scanBpBtn.AutoButtonColor = false
        scanBpBtn.TextSize = 10
        scanBpBtn.TextColor3 = Color3.fromRGB(235, 242, 255)
        scanBpBtn.Text = "↻ REFRESH BP"
        lockFont(scanBpBtn, UIFONT.bold)
        scanBpBtn.Parent = bpPanel
        uiCorner(scanBpBtn, 6)

        local bpSearchFrame = Instance.new("Frame")
        bpSearchFrame.Size = UDim2.new(1, -20, 0, 34)
        bpSearchFrame.Position = UDim2.new(0, 10, 0, 40)
        bpSearchFrame.BackgroundColor3 = Color3.fromRGB(24, 27, 35)
        bpSearchFrame.BorderSizePixel = 0
        bpSearchFrame.Parent = bpPanel
        uiCorner(bpSearchFrame, 6)
        uiStroke(bpSearchFrame, Color3.fromRGB(45, 50, 62), 1)

        local bpSearchBox = Instance.new("TextBox")
        bpSearchBox.Size = UDim2.new(1, -16, 1, -4)
        bpSearchBox.Position = UDim2.new(0, 8, 0, 2)
        bpSearchBox.BackgroundTransparency = 1
        bpSearchBox.ClearTextOnFocus = false
        bpSearchBox.PlaceholderText = "Cari nama block atau ID..."
        bpSearchBox.PlaceholderColor3 = Color3.fromRGB(120, 126, 142)
        bpSearchBox.Text = ""
        bpSearchBox.TextSize = 11
        bpSearchBox.TextColor3 = Color3.fromRGB(240, 242, 250)
        bpSearchBox.TextXAlignment = Enum.TextXAlignment.Left
        lockFont(bpSearchBox, UIFONT.med)
        bpSearchBox.Parent = bpSearchFrame

        local selectedBlockBanner = uiLabel(bpPanel, "Block aktif: (belum dipilih)", 10, Color3.fromRGB(255, 210, 110), UIFONT.bold)
        selectedBlockBanner.Size = UDim2.new(1, -20, 0, 18)
        selectedBlockBanner.Position = UDim2.new(0, 12, 0, 78)

        local bpVList

        local function makeBpRow(scroll)
            local row = {}
            local card = Instance.new("TextButton")
            card.BorderSizePixel = 0
            card.AutoButtonColor = false
            card.Text = ""
            card.Parent = scroll
            uiCorner(card, 7)
            row.frame = card
            row.card = card
            row.stroke = uiStroke(card, Color3.fromRGB(38, 42, 52), 1)

            local iconBg = Instance.new("Frame")
            iconBg.Size = UDim2.new(0, 46, 0, 46)
            iconBg.Position = UDim2.new(0, 7, 0.5, -23)
            iconBg.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
            iconBg.BorderSizePixel = 0
            iconBg.Parent = card
            uiCorner(iconBg, 6)
            row.icon = scMakeIcon(iconBg, 3)

            row.title = uiLabel(card, "", 12, Color3.fromRGB(242, 244, 250), UIFONT.bold)
            row.title.Size = UDim2.new(1, -150, 0, 20)
            row.title.Position = UDim2.new(0, 60, 0, 8)

            row.sub = uiLabel(card, "", 10, Color3.fromRGB(145, 152, 168), UIFONT.reg)
            row.sub.Size = UDim2.new(1, -150, 0, 18)
            row.sub.Position = UDim2.new(0, 60, 0, 29)

            local badge = uiLabel(card, "", 10, Color3.fromRGB(255, 255, 255), UIFONT.bold, Enum.TextXAlignment.Center)
            badge.Size = UDim2.new(0, 78, 0, 24)
            badge.Position = UDim2.new(1, -86, 0.5, -12)
            badge.BackgroundTransparency = 0
            uiCorner(badge, 5)
            row.badge = badge

            card.Activated:Connect(function()
                if not row.item then return end
                AF.SelectedBlockId = row.item.id
                if row.item.hits and row.item.hits > 0 then AF.BreakHits = row.item.hits end
                selectedBlockBanner.Text = string.format("Block aktif: %s (#%d)  •  BP: x%d",
                    row.item.name, row.item.id, row.item.bpCount or 0)
                bpVList:Refresh()
            end)
            return row
        end

        local function bindBpRow(row, item)
            local sel = (AF.SelectedBlockId == item.id)
            local cnt = item.bpCount or 0
            row.card.BackgroundColor3 = sel and Color3.fromRGB(22, 46, 36) or Color3.fromRGB(20, 22, 28)
            row.stroke.Color = sel and Color3.fromRGB(65, 200, 120) or Color3.fromRGB(38, 42, 52)
            if row.iconId ~= item.id then
                row.iconId = item.id
                scSetIcon(row.icon, item.id)
            end
            row.title.Text = string.format("%s   #%d", item.name, item.id)
            row.sub.Text = string.format("HP/Hit: %d", item.hits or 4)
            row.badge.Text = sel and string.format("✓ x%d", cnt) or string.format("x%d", cnt)
            row.badge.BackgroundColor3 = sel and Color3.fromRGB(40, 150, 85)
                or (cnt > 0 and Color3.fromRGB(38, 75, 130) or Color3.fromRGB(30, 33, 42))
        end

        bpVList = newVList(bpPanel, {
            name = "BPBlocksScroll",
            rowH = 58, gap = 6, pad = 8,
            size = UDim2.new(1, -20, 1, -108),
            position = UDim2.new(0, 10, 0, 98),
            makeRow = makeBpRow,
            bind = bindBpRow,
        })

        local function reloadBPList(toTop)
            scBuildItems()
            local counts = afScanBackpackCounts()
            local hasAnyOwned = next(counts) ~= nil
            local q = vnTrim(AF.SearchQuery):lower()
            local onlyOwned = getValue("AF_OnlyBP", true)

            local out = {}
            for _, b in ipairs(SC.BlockItems or {}) do
                local c = counts[b.id] or 0
                b.bpCount = c
                local pass = (not onlyOwned) or (not hasAnyOwned) or (c > 0) or (AF.SelectedBlockId == b.id)
                if pass and (q == "" or b.lname:find(q, 1, true) or tostring(b.id):find(q, 1, true)) then
                    out[#out + 1] = b
                end
            end
            table.sort(out, function(a, b)
                local ca, cb = a.bpCount or 0, b.bpCount or 0
                if ca ~= cb then return ca > cb end
                return a.name < b.name
            end)

            if AF.SelectedBlockId and SC.BlockMap[AF.SelectedBlockId] then
                local sb = SC.BlockMap[AF.SelectedBlockId]
                selectedBlockBanner.Text = string.format("Block aktif: %s (#%d)  •  BP: x%d", sb.name, sb.id, counts[sb.id] or 0)
            end
            bpVList:SetData(out, toTop)
        end

        bpSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            AF.SearchQuery = bpSearchBox.Text
            reloadBPList(true)
        end)
        scanBpBtn.Activated:Connect(function() reloadBPList(false) end)

        AF.RefreshBPUI = reloadBPList
        reloadBPList(true)
    end)
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
-- KATEGORI 2: AUTO FARM
-- =========================================================================
if UI.Category then UI:Category("Auto Farm") end

feature("Bolt", "Auto Farm")({
    center = center(function(c)
        c:Header("Auto Farm 5×5 & BP Block Selector", "Pilih Block dari BP, pilih tile 5x5 (tengah = posisi kamu), Place -> Break -> Collect terverifikasi", "Farm")

        c:StatRow({
            { Icon = "Bolt",   Label = "Filter",  Value = "Block Only" },
            { Icon = "Check",  Label = "Verify",  Value = "Skip Place/Break" },
            { Icon = "Shield", Label = "Collect", Value = "Tanpa Teleport" }
        })

        c:Card("MATRIX TILE 5X5 & KATALOG BP", nil, "Palette", {
            Subtitle = "Atas = Grid 5x5 (tengah = kamu, atas = tile di atasmu). Bawah = pilih Block dari BP"
        })
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol Auto Farm", nil, "Bolt", {
            Subtitle = "Jalankan atau hentikan siklus Place -> Break -> Collect"
        })
        AF.Button = CtrlCard:Button("Auto Farm Toggle", "START FARM", "Bolt", function()
            afToggle()
        end)
        CtrlCard:Dropdown("Method Eksekusi Farm", "AF_MethodMode", AF_METHODS, AF.Method, function(m)
            AF.Method = m
        end)
        CtrlCard:Toggle("Tampilkan Hanya Block yang Ada di BP", "AF_OnlyBP", true, function(st)
            AF.OnlyShowOwnedBP = st
            if AF.RefreshBPUI then pcall(AF.RefreshBPUI, true) end
        end)
        CtrlCard:Toggle("Verifikasi Cerdas (Skip Place Jika Ada & Skip Break Jika Hancur)", "AF_SmartVerify", true)
        CtrlCard:Toggle("Konversi Sumbu Y (Atas = Atas Kepala Karakter)", "AF_InvertY", true)

        local DelayCard = r:Card("Pengaturan Delay & Break", nil, "Clock", {
            Subtitle = "Atur jeda Place, jeda pukulan Break, dan jumlah pukulan"
        })
        DelayCard:Slider("Delay Place", "AF_PlaceDelay", 0.05, 1.5, 0.18, " s", function(v)
            AF.PlaceDelay = tonumber(v) or 0.18
        end, 0.01)
        DelayCard:Slider("Delay Break (Per Hit)", "AF_BreakDelay", 0.05, 1.5, 0.16, " s", function(v)
            AF.BreakDelay = tonumber(v) or 0.16
        end, 0.01)
        DelayCard:Slider("Jumlah Pukulan Break", "AF_BreakHits", 1, 12, 4, " hit", function(v)
            AF.BreakHits = tonumber(v) or 4
        end, 1)

        local CollectCard = r:Card("Auto Collect (Tanpa Teleport)", nil, "Shield", {
            Subtitle = "Kirim paket ambil drop di sekitar tanpa memindahkan karakter"
        })
        CollectCard:Toggle("Aktifkan Auto Collect Drop", "AF_AutoCollect", false, function(st)
            AF.AutoCollect = st
        end)
        CollectCard:Slider("Radius Auto Collect", "AF_CollectRad", 1, 10, 4, " tile", function(v)
            AF.CollectRadius = tonumber(v) or 4
        end, 1)
        CollectCard:Slider("Delay Collect", "AF_CollectDelay", 0.04, 0.8, 0.12, " s", function(v)
            AF.CollectDelay = tonumber(v) or 0.12
        end, 0.01)
    end)
})

-- =========================================================================
-- KATEGORI 3: SET VISUAL NAME
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
-- KATEGORI 4: SET CLOTHES
-- =========================================================================
pcall(scBuildItems)
if UI.Category then UI:Category("Set Clothes") end

feature("Item", "Set Clothes")({
    center = center(function(c)
        c:Header("Set Clothes & Visual Catalog", "Search bar di atas, Katalog (2x Tap Pakai), lalu Item Dipakai di bawahnya (1x Tap Copot)", "Client")

        c:StatRow({
            { Icon = "Check",  Label = "Katalog", Value = "2x Tap Pakai" },
            { Icon = "Bolt",   Label = "Dipakai", Value = "1x Tap Copot" },
            { Icon = "Shield", Label = "Efek & Visual", Value = "Dual-Method" }
        })

        local CatalogCard = c:Card("KATALOG VISUAL CLOTHES", nil, "Palette", {
            Subtitle = "Filter kategori slot di bawah atau gunakan Search Bar di atas daftar pakaian"
        })
        CatalogCard:Dropdown("Filter Kategori Slot (Mask, Head, Wing, dll)", "SC_SlotFilter", SC.Slots, "All", function(slotVal)
            SC.SelectedSlot = tostring(slotVal or "All")
            if SC.FilterFn then pcall(SC.FilterFn) end
        end)

        local ManualCard = c:Card("Input Manual (Nama / ID)", nil, "Chat", {
            Subtitle = "Opsional: ketik beberapa nama atau ID dipisahkan koma lalu tekan SET"
        })
        ManualCard:Input("Nama / ID Item", "SC_Items", "contoh: Legendary Wings, 1784, Boots", "")
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Shortcut & Method Pakaian", nil, "Bolt", {
            Subtitle = "Dual-Method memastikan visual pakaian dan efek item langsung muncul di karakter"
        })
        CtrlCard:Dropdown("Method Pasang Visual & Efek", "SC_ApplyMethod", SC_APPLY_METHODS, SC.ApplyMethod, function(m)
            SC.ApplyMethod = m
        end)
        CtrlCard:Button("Pakai dari Kolom Input", "SET", "Bolt", function()
            scSet()
        end)
        CtrlCard:Button("Lepas Semua Item (Unwear All)", "LEPAS SEMUA", "Shield", function()
            scUnwearAll()
        end)
        CtrlCard:Button("Kembali ke Pakaian Asli", "RESET AWAL", "Check", function()
            scReset()
        end)
        CtrlCard:Button("Force Refresh Karakter & Efek", "REFRESH", "Bolt", function()
            scFindWorn()
            scForceCharacterRedraw()
            if SC.UpdateUIFn then pcall(SC.UpdateUIFn) end
            notifyClient("Set Clothes", "Visual karakter & efek item diperbarui", 2)
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
-- KATEGORI 5: ESP & CHECK
-- =========================================================================
if UI.Category then UI:Category("ESP & Check") end

feature("Shield", "ESP & Check")({
    center = center(function(c)
        c:Header("Spiderweb ESP & Moderator Check", "Garis visual client dari kita ke badan player target", "Client")

        c:StatRow({
            { Icon = "Shield", Label = "Check", Value = "Real-time" },
            { Icon = "Bolt",   Label = "ESP",   Value = "Jaring Visual" },
            { Icon = "Check",  Label = "Mode",  Value = "100% Client" }
        })

        local EspCard = c:Card("JARING ESP PLAYER (SPIDERWEB)", nil, "Bolt", {
            Subtitle = "Menggambar garis dari posisi kita ke badan target secara murni di layar client"
        })
        EspCard:Toggle("Aktifkan Jaring ESP", "ESP_Master", true, function(st)
            if not st then espClearAll() end
        end)
        EspCard:Toggle("Jaring ke Semua Player di World", "ESP_All", false)
        EspCard:Toggle("Hubungkan Benang Jaring Antar Target (Spiderweb Mesh)", "ESP_WebMesh", true)
        EspCard:Toggle("Tampilkan Player Hidden (Jika Koordinat Ada di Memori)", "ESP_Hidden", true)
        EspCard:Toggle("Auto-Jaring untuk Moderator / Staff", "Mod_ESP", true)

        local ListCard = c:Card("DAFTAR PLAYER (PILIH TARGET JARING)", nil, "Chat", {
            Subtitle = "Klik player di bawah untuk menyalakan/mematikan garis jaring ke player tersebut"
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
        local WebCtrlCard = r:Card("Kontrol Jaring ESP", nil, "Bolt", {
            Subtitle = "Bersihkan atau segarkan jaring visual di layar"
        })
        WebCtrlCard:Button("Matikan Semua Target Jaring", "ESP OFF", "Shield", function()
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
-- KATEGORI 6: SETTINGS
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

-- Inisialisasi awal semua modul UI embedded & hook
task.spawn(function()
    pcall(scHook)
    scMountEmbeddedBrowser()
    afMountEmbeddedUI()
    espMountPlayerList()
    task.wait(1.5)
    if getValue("LightText", true) then pcall(lightEnable) end
end)
