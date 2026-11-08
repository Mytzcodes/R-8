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
    Title = "CHAT SPAMMER (SERVER)",
    BrandTitle = "R&8_DV",
    BrandSubtitle = "SPAM SUITE",
    Theme = "Minimalist Monochrome",
    CheckboxStyle = "Modern",
    LetterSpacing = 1,
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
-- LOGIKA SPAM
-- =========================================================================
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

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

-- MODE SERVER: kirim langsung ke TextChannel dunia lewat SendAsync,
-- sama seperti fungsi send milik ChatUI game (tidak bergantung pada UI chat).
-- Channel ada di TextChatService.WorldChannels.<nama dunia>.
local function findWorldChannel()
    local wc = TextChatService:FindFirstChild("WorldChannels")
    if not wc then return nil end

    -- prioritas: channel yang punya TextSource milik kita
    for _, ch in ipairs(wc:GetChildren()) do
        if ch:IsA("TextChannel") and ch:FindFirstChild(LocalPlayer.Name) then
            return ch
        end
    end
    -- cadangan: channel pertama yang ada
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

-- Susun pesan: Auto Prefix = ` + angka acak 1-9 (berganti tiap pesan)
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

-- Satu fungsi untuk tombol & hotkey: toggle start/stop
local function toggleSpam()
    if Spam.Running then stopSpam() else startSpam() end
end

-- =========================================================================
-- HELPER: TOMBOL TOGGLE (START / STOP dalam satu tombol)
-- Teks tombol berganti saat fitur nyala (START -> STOP) supaya user tahu
-- fitur itu sedang jalan dan bisa dimatikan dengan tombol yang sama.
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
end

-- startFn boleh return false kalau gagal (tombol tetap START)
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
-- LOGIKA SET VISUAL NAME (nama di dalam game, BUKAN nama Roblox) - 100% CLIENT
-- Mengubah attribute milik LocalPlayer, hanya terlihat di layar sendiri.
-- Sumber di game: Shared.Roles (nameOf -> Nick, titleOf -> WornTitle),
--                 Others/Game (warna nama -> DiscordColor)
-- =========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VN = {
    Orig = nil,      -- attribute asli (disimpan sekali sebelum apply pertama)
    Want = {},       -- attribute yang sedang kita paksa
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

-- label tampil -> id title di game (Roles.TITLES / TITLE_NAMES)
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
    return VN_COLORS[pick] -- nil kalau "(tidak diubah)"
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

    -- nama
    local name = vnTrim(getValue("VN_Name", ""))
    if not getValue("VN_AllowCodes", false) then
        name = name:gsub("`", "")
    end
    name = string.sub(name, 1, 30)
    if name ~= "" then want.Nick = name end

    -- warna
    local color = vnReadColor()
    if color then want.DiscordColor = color end

    -- title
    local titleId = VN_TITLE_ID[getValue("VN_Title", "(tidak diubah)")]
    if titleId == "none" then
        want.WornTitle = "none"
        want.HasLegend = false
    elseif titleId == "legend" then
        want.WornTitle = "none"      -- supaya titleOf jatuh ke jalur legend
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

    -- Nick dipasang terakhir: game hanya menggambar ulang nameplate saat Nick berubah
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

-- Kunci: kalau server menimpa attribute (mis. ganti title), pasang ulang
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
-- LOGIKA ITEM VISUAL (pakaian & aksesori saja, tanpa block dan seed) - 100% CLIENT
-- Cara kerja (dari ekspor game):
--  * Item diambil dari Shared.ItemDB: kind == "cloth" (seed "... Seed" dibuang)
--  * Yang sedang dipakai = tabel `worn` {slot = itemId} milik Game, dibaca rig tiap frame
--  * Game mengirim tabel itu ke server lewat Net.wear.send -> kita bungkus supaya
--    slot yang kita ubah SELALU dikirim sebagai nilai aslinya (server tidak pernah
--    tahu item visual). Kalau hook gagal, fitur dibatalkan (tidak dijalankan).
-- =========================================================================
local UserInputService = game:GetService("UserInputService")

local IV = {
    Active = false,
    Run = 0,
    DB = nil, Items = nil, Slots = nil, IconMod = nil,
    Worn = nil,          -- tabel worn milik game
    Ov = {},             -- slot -> { vis = itemId | false, real = itemId asli }
    WearTbl = nil, OrigSend = nil,
    Gui = nil, Main = nil, Mini = nil, Grid = nil, WornScroll = nil,
    CountLbl = nil, SlotBtn = nil, FxBtn = nil, Search = nil,
    Conns = {}, Cells = {}, WornSig = "",
    Query = "", SlotFilter = "Semua", HideFx = true,
    List = {}, Rendered = 0,
    Toggle = nil,
}
local IV_PAGE = 48
-- item dengan efek gameplay (kecepatan, gali, dll) disembunyikan default supaya
-- gerakanmu tidak berbeda dari yang diketahui server
local IV_FX_KEYS = { "speed", "dig", "slowFall", "fireproof", "rapier", "voidEye", "voidKatana" }

local IV_C = {
    bg    = Color3.fromRGB(18, 22, 30),
    cell  = Color3.fromRGB(32, 38, 50),
    line  = Color3.fromRGB(56, 66, 86),
    text  = Color3.fromRGB(232, 236, 244),
    sub   = Color3.fromRGB(150, 160, 178),
    worn  = Color3.fromRGB(73, 252, 0),
    vis   = Color3.fromRGB(25, 185, 255),
    btn   = Color3.fromRGB(44, 52, 68),
}

local function ivHasFx(it)
    for _, k in ipairs(IV_FX_KEYS) do
        if it[k] then return true end
    end
    return false
end

-- ---- cari tabel worn milik game lewat closure onWear ----
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

-- ---- hook Net.wear.send: item visual tidak pernah sampai ke server ----
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

-- ---- daftar item (tanpa block & seed) ----
local function ivBuildItems()
    if IV.Items then return true end
    local ok, DB = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("ItemDB", 5))
    end)
    if not ok or type(DB) ~= "table" then return false end

    local items, slotSet = {}, {}
    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" and it.kind == "cloth"
            and type(it.slot) == "string" and type(it.name) == "string"
            and not it.name:find(" Seed$") then
            slotSet[it.slot] = true
            items[#items + 1] = {
                id = id, name = it.name, lname = it.name:lower(),
                slot = it.slot, fx = ivHasFx(it),
            }
        end
    end
    table.sort(items, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)

    local tmp = {}
    for s in pairs(slotSet) do tmp[#tmp + 1] = s end
    table.sort(tmp)
    local slots = { "Semua" }
    for _, s in ipairs(tmp) do slots[#slots + 1] = s end

    IV.DB, IV.Items, IV.Slots = DB, items, slots
    local okI, icon = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("ItemIcon", 5))
    end)
    IV.IconMod = okI and icon or nil
    return #items > 0
end

-- ---- pakai / lepas secara visual ----
local function ivWear(id)
    local it = IV.DB and IV.DB[id]
    if not it or not it.slot then return end
    local slot = it.slot
    if IV.Ov[slot] == nil then IV.Ov[slot] = { real = IV.Worn[slot] } end
    IV.Ov[slot].vis = id
    IV.Worn[slot] = id
    if IV.Ov[slot].real == id then IV.Ov[slot] = nil end  -- sama dengan aslinya, tidak perlu override
end

local function ivUnwear(slot)
    if IV.Worn[slot] == nil and IV.Ov[slot] == nil then return end
    if IV.Ov[slot] == nil then IV.Ov[slot] = { real = IV.Worn[slot] } end
    IV.Ov[slot].vis = false
    IV.Worn[slot] = nil
end

local function ivReset(slot)
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
end

-- tap item: sedang dipakai -> lepas, belum -> pakai
local function ivToggleItem(id)
    local it = IV.DB and IV.DB[id]
    if not it or not it.slot then return end
    local slot = it.slot
    if IV.Worn[slot] == id then
        local o = IV.Ov[slot]
        if o and o.vis == id and o.real ~= id then
            ivReset(slot)      -- lepas item visual, balik ke pakaian asli
        else
            ivUnwear(slot)     -- lepas item asli (hanya visual)
        end
    else
        ivWear(id)
    end
end

-- game menghapus item yang tidak kita miliki tiap inventory berubah -> pasang ulang
local function ivKeepAlive()
    for slot, o in pairs(IV.Ov) do
        local want = o.vis or nil
        local cur = IV.Worn[slot]
        if cur ~= want then
            if cur == nil then
                IV.Worn[slot] = want
            else
                IV.Ov[slot] = nil   -- pemain mengganti sendiri lewat inventory: hormati
            end
        end
    end
end

-- ---- UI panel ----
local function ivNew(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function ivIcon(parent, id, size, pos)
    if not IV.IconMod then return end
    local okN, icon = pcall(IV.IconMod.new, parent, UDim2.fromOffset(size, size), 3)
    if not okN or not icon then return end
    icon.frame.Position = pos
    pcall(IV.IconMod.set, icon, id)
end

local function ivRefreshMarks()
    for id, c in pairs(IV.Cells) do
        c.stroke.Enabled = (IV.Worn[c.slot] == id)
    end
end

local function ivRebuildWorn()
    if not IV.WornScroll then return end
    local keys = {}
    for slot in pairs(IV.Worn) do keys[#keys + 1] = slot end
    table.sort(keys)
    local parts = {}
    for _, s in ipairs(keys) do
        parts[#parts + 1] = s .. "=" .. tostring(IV.Worn[s]) .. (IV.Ov[s] and "*" or "")
    end
    local sig = table.concat(parts, ",")
    if sig == IV.WornSig then return end
    IV.WornSig = sig

    for _, ch in ipairs(IV.WornScroll:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    for i, s in ipairs(keys) do
        local id = IV.Worn[s]
        local btn = ivNew("TextButton", {
            LayoutOrder = i, Size = UDim2.fromOffset(56, 56), Text = "",
            BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, AutoButtonColor = true,
        }, IV.WornScroll)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
        ivNew("UIStroke", {
            Color = IV.Ov[s] and IV_C.vis or IV_C.line, Thickness = IV.Ov[s] and 2 or 1,
        }, btn)
        ivIcon(btn, id, 34, UDim2.new(0.5, -17, 0, 3))
        ivNew("TextLabel", {
            Position = UDim2.new(0, 0, 1, -16), Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1, Text = s, TextSize = 10,
            Font = Enum.Font.Gotham, TextColor3 = IV_C.sub,
        }, btn)
        btn.Activated:Connect(function()
            ivToggleItem(id)
            ivRefreshMarks()
        end)
    end
end

local function ivRenderMore()
    if not IV.Grid then return end
    local last = math.min(IV.Rendered + IV_PAGE, #IV.List)
    for i = IV.Rendered + 1, last do
        local e = IV.List[i]
        local btn = ivNew("TextButton", {
            Name = "Item" .. e.id, LayoutOrder = i, Text = "",
            BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, AutoButtonColor = true,
        }, IV.Grid)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
        local stroke = ivNew("UIStroke", {
            Color = IV_C.worn, Thickness = 2, Enabled = (IV.Worn and IV.Worn[e.slot] == e.id) or false,
        }, btn)
        ivIcon(btn, e.id, 40, UDim2.new(0.5, -20, 0, 4))
        ivNew("TextLabel", {
            Position = UDim2.new(0, 2, 1, -34), Size = UDim2.new(1, -4, 0, 32),
            BackgroundTransparency = 1, Text = e.name, TextSize = 10, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.AtEnd, Font = Enum.Font.Gotham,
            TextColor3 = IV_C.text, TextYAlignment = Enum.TextYAlignment.Top,
        }, btn)
        btn.Activated:Connect(function()
            ivToggleItem(e.id)
            ivRefreshMarks()
        end)
        IV.Cells[e.id] = { btn = btn, stroke = stroke, slot = e.slot }
    end
    IV.Rendered = last
end

local function ivRefilter()
    if not IV.Grid then return end
    local q = IV.Query:lower()
    local list = {}
    for _, e in ipairs(IV.Items) do
        if (IV.SlotFilter == "Semua" or e.slot == IV.SlotFilter)
            and (not IV.HideFx or not e.fx)
            and (q == "" or e.lname:find(q, 1, true) or tostring(e.id):find(q, 1, true)) then
            list[#list + 1] = e
        end
    end
    IV.List = list
    for _, c in pairs(IV.Cells) do c.btn:Destroy() end
    IV.Cells, IV.Rendered = {}, 0
    ivRenderMore()
    IV.Grid.CanvasPosition = Vector2.zero
    if IV.CountLbl then
        IV.CountLbl.Text = #list .. " item  |  tap = pakai / lepas (visual saja)"
    end
end

local function ivBuildGui()
    local gui = ivNew("ScreenGui", {
        Name = "R8DV_ItemVisual", ResetOnSpawn = false, DisplayOrder = 950,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function()
        local h = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
        gui.Parent = h
    end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    IV.Gui = gui

    local main = ivNew("Frame", {
        Name = "Main", Size = UDim2.fromOffset(350, 500), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = IV_C.bg, BorderSizePixel = 0,
    }, gui)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 8) }, main)
    ivNew("UIStroke", { Color = IV_C.line, Thickness = 1 }, main)
    local scale = ivNew("UIScale", {}, main)
    local cam = workspace.CurrentCamera
    if cam then scale.Scale = math.clamp(cam.ViewportSize.Y / 760, 0.6, 1) end
    IV.Main = main

    -- mini button (saat panel diciutkan)
    local mini = ivNew("TextButton", {
        Name = "Mini", Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = IV_C.bg, Visible = false,
        Text = "IV", TextColor3 = IV_C.text, Font = Enum.Font.GothamBold, TextSize = 14,
        BorderSizePixel = 0,
    }, gui)
    ivNew("UICorner", { CornerRadius = UDim.new(1, 0) }, mini)
    ivNew("UIStroke", { Color = IV_C.vis, Thickness = 2 }, mini)
    IV.Mini = mini

    -- title bar (drag)
    local bar = ivNew("Frame", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Active = true,
    }, main)
    ivNew("TextLabel", {
        Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1, Text = "ITEM VISUAL  (client only)",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamBold, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, bar)
    local closeBtn = ivNew("TextButton", {
        Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -36, 0, 0),
        BackgroundTransparency = 1, Text = "-", TextColor3 = IV_C.sub,
        Font = Enum.Font.GothamBold, TextSize = 22,
    }, bar)
    closeBtn.Activated:Connect(function() main.Visible = false; mini.Visible = true end)
    mini.Activated:Connect(function() main.Visible = true; mini.Visible = false end)

    local dragging, dragStart, startPos = false, nil, nil
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    IV.Conns[#IV.Conns + 1] = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- strip "dipakai sekarang"
    ivNew("TextLabel", {
        Position = UDim2.fromOffset(10, 36), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = "Dipakai sekarang  (tap = lepas, garis biru = visual)",
        TextColor3 = IV_C.sub, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    local wornScroll = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 54), Size = UDim2.new(1, -20, 0, 62),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.X,
    }, main)
    ivNew("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, wornScroll)
    IV.WornScroll = wornScroll

    -- baris search + filter
    local search = ivNew("TextBox", {
        Position = UDim2.fromOffset(10, 122), Size = UDim2.fromOffset(160, 30),
        BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, Text = "",
        PlaceholderText = "Cari nama / ID...", PlaceholderColor3 = IV_C.sub,
        TextColor3 = IV_C.text, Font = Enum.Font.Gotham, TextSize = 12,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, search)
    ivNew("UIPadding", { PaddingLeft = UDim.new(0, 8) }, search)
    IV.Search = search

    local slotBtn = ivNew("TextButton", {
        Position = UDim2.fromOffset(176, 122), Size = UDim2.fromOffset(82, 30),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = "Slot: Semua",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 11,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, slotBtn)
    IV.SlotBtn = slotBtn

    local fxBtn = ivNew("TextButton", {
        Position = UDim2.fromOffset(264, 122), Size = UDim2.fromOffset(76, 30),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0,
        Text = IV.HideFx and "Efek: OFF" or "Efek: ON",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 11,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, fxBtn)
    IV.FxBtn = fxBtn

    local countLbl = ivNew("TextLabel", {
        Position = UDim2.fromOffset(10, 156), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = "", TextColor3 = IV_C.sub,
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    IV.CountLbl = countLbl

    -- grid item (scroll)
    local grid = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 176), Size = UDim2.new(1, -20, 1, -222),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, main)
    ivNew("UIGridLayout", {
        CellSize = UDim2.fromOffset(76, 84), CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    IV.Grid = grid

    -- tombol lepas semua
    local clearBtn = ivNew("TextButton", {
        Position = UDim2.new(0, 10, 1, -38), Size = UDim2.new(1, -20, 0, 30),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = "Lepas Semua Visual (balik ke pakaian asli)",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 12,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, clearBtn)

    -- event
    local token = 0
    search:GetPropertyChangedSignal("Text"):Connect(function()
        token += 1
        local my = token
        task.delay(0.25, function()
            if my == token and IV.Active then
                IV.Query = vnTrim(search.Text)
                ivRefilter()
            end
        end)
    end)
    slotBtn.Activated:Connect(function()
        local idx = table.find(IV.Slots, IV.SlotFilter) or 1
        idx = (idx % #IV.Slots) + 1
        IV.SlotFilter = IV.Slots[idx]
        slotBtn.Text = "Slot: " .. IV.SlotFilter
        ivRefilter()
    end)
    fxBtn.Activated:Connect(function()
        IV.HideFx = not IV.HideFx
        fxBtn.Text = IV.HideFx and "Efek: OFF" or "Efek: ON"
        ivRefilter()
    end)
    clearBtn.Activated:Connect(function()
        ivResetAll()
        ivRefreshMarks()
    end)
    grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if IV.Rendered < #IV.List
            and grid.CanvasPosition.Y + grid.AbsoluteWindowSize.Y >= grid.AbsoluteCanvasSize.Y - 240 then
            ivRenderMore()
        end
    end)

    ivRefilter()
    ivRebuildWorn()
end

local function ivStart()
    if IV.Active then return true end
    local worn, err = ivFindWorn()
    if not worn then
        warn("[R&8_DV] Item Visual dibatalkan: " .. tostring(err))
        return false
    end
    if not ivBuildItems() then
        warn("[R&8_DV] Item Visual dibatalkan: Shared.ItemDB tidak bisa dibaca")
        return false
    end
    if not ivHook() then
        warn("[R&8_DV] Item Visual dibatalkan: hook Net.wear.send gagal (supaya pakaian visual tidak terkirim ke server)")
        return false
    end
    IV.Worn = worn
    IV.Ov = {}
    IV.Active = true
    IV.Run += 1
    local run = IV.Run
    ivBuildGui()
    task.spawn(function()
        while IV.Active and IV.Run == run do
            ivKeepAlive()
            pcall(ivRebuildWorn)
            pcall(ivRefreshMarks)
            task.wait(0.25)
        end
    end)
    print("[R&8_DV] Item Visual START (client only), " .. #IV.Items .. " item pakaian")
    return true
end

local function ivStop()
    IV.Active = false
    IV.Run += 1
    if IV.Worn then ivResetAll() end
    ivUnhook()
    for _, c in ipairs(IV.Conns) do pcall(function() c:Disconnect() end) end
    IV.Conns = {}
    if IV.Gui then pcall(function() IV.Gui:Destroy() end) end
    IV.Gui, IV.Main, IV.Mini, IV.Grid, IV.WornScroll = nil, nil, nil, nil, nil
    IV.Cells, IV.WornSig, IV.Ov = {}, "", {}
    print("[R&8_DV] Item Visual STOP, pakaian dikembalikan")
end

IV.Toggle = newToggle(ivStart, ivStop)

-- =========================================================================
-- KATEGORI 1: SPAMMER
-- =========================================================================
if UI.Category then UI:Category("Spammer") end

feature("Chat", "Chat Spam")({
    -- ---------------------------- TENGAH ----------------------------
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

    -- ----------------------------- KANAN -----------------------------
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
-- KATEGORI 2: SET VISUAL NAME
-- =========================================================================
if UI.Category then UI:Category("Visual Name") end

feature("Name", "Set Visual Name")({
    -- ---------------------------- TENGAH ----------------------------
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

    -- ----------------------------- KANAN -----------------------------
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
-- KATEGORI 3: ITEM VISUAL
-- =========================================================================
if UI.Category then UI:Category("Item Visual") end

feature("Item", "Item Visual")({
    -- ---------------------------- TENGAH ----------------------------
    center = center(function(c)
        c:Header("Item Visual", "Pakai baju & aksesori hanya di layarmu (tanpa block dan seed)", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",         Value = "Client" },
            { Icon = "Shield", Label = "Kirim server", Value = "Diblokir" },
            { Icon = "Check",  Label = "Daftar",       Value = "Search" }
        })

        local PanelCard = c:Card("Panel Item Visual", nil, "Palette", {
            Subtitle = "START membuka panel (scroll, search, tap). STOP menutup dan mengembalikan pakaian asli"
        })
        IV.Toggle.Button = PanelCard:Button("Item Visual", "START", "Bolt", function()
            IV.Toggle.Toggle()
        end)
        PanelCard:Button("Lepas Semua Visual", "RESET", "Check", function()
            if IV.Active then ivResetAll() end
        end)
    end),

    -- ----------------------------- KANAN -----------------------------
    right = right(function(r)
        local HowCard = r:Card("Cara Pakai", nil, "Clock", {
            Subtitle = "Panel melayang, bisa digeser lewat judulnya, tombol - untuk meringkas"
        })
        HowCard:ActivityTimeline({
            { Text = "Cari nama atau ID item di kolom search", Time = "1" },
            { Text = "Tombol Slot = filter hat / shirt / feet dst (tap tap)", Time = "2" },
            { Text = "Tap item = pakai, tap lagi = lepas", Time = "3" },
            { Text = "Baris atas = pakaian yang sedang dipakai, tap = lepas", Time = "4" },
            { Text = "Efek: OFF menyembunyikan item ber-efek (kecepatan dll)", Time = "5" }
        })

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Pakaian visual tidak pernah dikirim ke server dan pemain lain tidak melihatnya"
        })
    end)
})

-- =========================================================================
-- KATEGORI 4: SETTINGS
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
