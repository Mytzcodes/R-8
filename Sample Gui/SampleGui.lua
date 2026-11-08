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
    LetterSpacing = 0, -- 0 = huruf tidak renggang, lebih mudah dibaca
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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
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

-- MODE SERVER: kirim langsung ke TextChannel dunia lewat SendAsync
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
-- TEKS RINGAN: kurangi tebal huruf (bold) di jendela R&8_DV supaya enak dibaca
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
                                if up:find("SPAM SUITE", 1, true) or up:find("R&8_DV", 1, true) then
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
-- LOGIKA SET VISUAL NAME (100% CLIENT)
-- Mengubah attribute milik LocalPlayer, hanya terlihat di layar sendiri.
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

-- =========================================================================
-- SET VISUAL NAME: tombol SET (terapkan) dan tombol KEMBALI KE NAMA AWAL.
-- Bukan on/off.
-- =========================================================================
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
    print("[R&8_DV] Visual name di-SET (client)")
    return true
end

local function vnReset()
    VN.Want = {}
    VN.Applied = false
    if not LocalPlayer or not VN.Orig then
        print("[R&8_DV] Visual name: belum pernah di-set, tidak ada yang dikembalikan")
        return
    end
    for _, a in ipairs(VN_ATTRS) do
        local o = VN.Orig[a]
        if o then pcall(function() LocalPlayer:SetAttribute(a, o.v) end) end
    end
    pcall(function()
        local nick = VN.Orig.Nick and VN.Orig.Nick.v
        LocalPlayer:SetAttribute("Nick", ".")
        LocalPlayer:SetAttribute("Nick", nick)
    end)
    print("[R&8_DV] Visual name dikembalikan ke nama awal")
end

-- Kunci: kalau server menimpa attribute, pasang ulang (hanya setelah SET)
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
-- SET CLOTHES (pakaian & aksesori, tanpa block dan seed) - 100% CLIENT
--  * Tombol SET: pakai item dari kolom nama / ID. Tombol KEMBALI KE AWAL:
--    semua item visual dibuang dan status dipakai dikembalikan ke asli.
--    Bukan on/off, tidak ada panel.
--  * Setiap perubahan diikuti Game.refresh() (menggambar ulang karakter) dan
--    Game.effects/effectsChanged (efek item ikut jalan).
--  * Net.wear.send dibungkus: server tetap menerima pakaian asli.
--  * Anti teleport double jump: Net.move.send dibungkus. Sayap visual yang
--    punya double jump membuat bit airJump (128) di flags paket gerak, padahal
--    server hanya tahu pakaian asli, sehingga posisi ditarik balik. Hook ini
--    menahan / menyamarkan paket itu hanya saat sayap-nya visual.
-- =========================================================================
local SC = {
    DB = nil, Items = nil,
    Worn = nil, Game = nil, State = nil,
    Ov = {},
    WearTbl = nil, OrigWear = nil,
    MoveTbl = nil, OrigMove = nil,
    JumpMode = "Tahan paket (disarankan)",
    Hold = nil,
    Loop = false,
}

local SC_JUMP_MODES = { "Tahan paket (disarankan)", "Samarkan flag saja", "Mati" }

local function scLooksLikeWorn(t)
    if type(t) ~= "table" then return false end
    for k, v in pairs(t) do
        if type(k) ~= "string" or type(v) ~= "number" then return false end
    end
    return true
end

-- Cari: tabel worn, objek karakter game (punya refresh), tabel state game (punya call/effects)
local function scFindWorn()
    if SC.Worn then return SC.Worn end
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
                    local worn, state
                    for _, up in pairs(ups) do
                        if type(up) == "table" then
                            if not worn and scLooksLikeWorn(up) then worn = up end
                            if not state and type(rawget(up, "call")) == "function" then state = up end
                        end
                    end
                    if worn then
                        SC.Game, SC.State, SC.Worn = obj, state, worn
                        return worn
                    end
                end
            end
        end
    end
    return nil, "tabel pakaian tidak ditemukan, masuk ke world dulu lalu coba lagi"
end

local function scBuildItems()
    if SC.Items then return true end
    local sh = ReplicatedStorage:WaitForChild("Shared", 5)
    local ok, DB = pcall(function() return require(sh:WaitForChild("ItemDB", 5)) end)
    if not ok or type(DB) ~= "table" then return false end
    local items = {}
    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" and it.kind == "cloth"
            and type(it.slot) == "string" and type(it.name) == "string"
            and not it.name:find(" Seed$") then
            items[#items + 1] = { id = id, name = it.name, lname = it.name:lower(), slot = it.slot }
        end
    end
    table.sort(items, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)
    SC.DB, SC.Items = DB, items
    return #items > 0
end

-- ---------------------------------------------------------------------
-- Hook paket keluar
-- ---------------------------------------------------------------------
local function scGetNet()
    local okN, Net = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Net", 5))
    end)
    if okN and type(Net) == "table" then return Net end
    return nil
end

-- Sayap visual dengan double jump, sementara pakaian asli tidak punya?
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
                if type(tbl) == "table" and next(SC.Ov) ~= nil then
                    local copy = {}
                    for k, v in pairs(tbl) do copy[k] = v end
                    for slot, o in pairs(SC.Ov) do copy[slot] = o.real end
                    return orig(copy, ...)
                end
                return orig(tbl, ...)
            end
        end)
        if not okSet or wear.send == orig then return false end
        SC.WearTbl, SC.OrigWear = wear, orig
    end

    -- anti teleport double jump (kalau gagal, pakaian tetap jalan)
    if type(move) == "table" and type(move.send) == "function"
        and not (SC.MoveTbl == move and SC.OrigMove) then
        local origMove = move.send
        if type(setreadonly) == "function" then pcall(setreadonly, move, false) end
        local okM = pcall(function()
            move.send = function(tbl, ...)
                local mode = SC.JumpMode
                if mode ~= "Mati" and type(tbl) == "table" and scVisualOnlyDoubleJump() then
                    local flags = tonumber(tbl.flags) or 0
                    local air = bit32.band(flags, 128) ~= 0
                    local function stripped()
                        local copy = {}
                        for k, v in pairs(tbl) do copy[k] = v end
                        copy.flags = bit32.band(flags, 127)
                        return copy
                    end
                    if mode == "Samarkan flag saja" then
                        if air then return origMove(stripped(), ...) end
                    else
                        local now = os.clock()
                        if air and not SC.Hold then SC.Hold = now end
                        if SC.Hold then
                            local grounded = bit32.band(flags, 2) ~= 0
                            if (grounded and now - SC.Hold > 0.3) or now - SC.Hold > 4 then
                                SC.Hold = nil
                                return origMove(stripped(), ...)
                            end
                            return -- tahan: server tidak melihat lompatan udara visual
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
        else
            warn("[R&8_DV] Hook Net.move.send gagal, anti teleport double jump tidak aktif")
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

-- ---------------------------------------------------------------------
-- Terapkan perubahan ke tabel worn + catat override + gambar ulang karakter
-- ---------------------------------------------------------------------
local function scMutate(fn)
    local W = SC.Worn
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
    if SC.Game and type(SC.Game.refresh) == "function" then
        pcall(SC.Game.refresh)
    end
end

-- pakai item (bukan toggle); aturan "suit" game: slot yang tidak cocok dilepas
local function scWearInto(W, id)
    local it = SC.DB[id]
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

-- jaga-jaga kalau game menghapus item visual (mis. event inventory berubah)
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
                SC.Ov[slot] = nil -- pemain ganti sendiri lewat inventory asli
            end
        end
    end
    if changed and SC.Game and type(SC.Game.refresh) == "function" then
        pcall(SC.Game.refresh)
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
        if it and it.kind == "cloth" and type(it.slot) == "string" then return n end
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

-- Tombol SET
local function scSet()
    local raw = tostring(getValue("SC_Items", ""))
    local tokens = {}
    for t in string.gmatch(raw, "[^,\n]+") do
        t = vnTrim(t)
        if t ~= "" then tokens[#tokens + 1] = t end
    end
    if #tokens == 0 then
        warn("[R&8_DV] Set Clothes: isi dulu kolom item (nama atau ID, pisahkan koma)")
        return
    end

    local worn, err = scFindWorn()
    if not worn then warn("[R&8_DV] Set Clothes dibatalkan: " .. tostring(err)); return end
    if not scBuildItems() then warn("[R&8_DV] Set Clothes dibatalkan: Shared.ItemDB tidak bisa dibaca"); return end
    if not scHook() then
        warn("[R&8_DV] Set Clothes dibatalkan: hook Net.wear.send gagal (supaya pakaian visual tidak terkirim ke server)")
        return
    end
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
        print("[R&8_DV] Set Clothes: dipakai -> " .. table.concat(applied, ", "))
    end
    if #missing > 0 then
        warn("[R&8_DV] Set Clothes: tidak ketemu -> " .. table.concat(missing, ", "))
    end
end

-- Tombol KEMBALI KE AWAL: semua item visual dibuang, status dipakai direset ke asli
local function scReset()
    if SC.Worn and next(SC.Ov) ~= nil then
        scMutate(function(W)
            for slot, o in pairs(SC.Ov) do W[slot] = o.real end
        end)
    end
    SC.Ov = {}
    scUnhook()
    print("[R&8_DV] Set Clothes: semua item dikembalikan ke status awal")
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
-- KATEGORI 2: SET VISUAL NAME (tombol SET + KEMBALI KE NAMA AWAL)
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
-- KATEGORI 3: SET CLOTHES (tombol SET + KEMBALI KE AWAL)
-- =========================================================================
if UI.Category then UI:Category("Set Clothes") end

feature("Item", "Set Clothes")({
    center = center(function(c)
        c:Header("Set Clothes", "Pakai baju & aksesori di layarmu, lengkap dengan efeknya (tanpa block dan seed)", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",         Value = "Client" },
            { Icon = "Shield", Label = "Kirim server", Value = "Diblokir" },
            { Icon = "Check",  Label = "Efek",         Value = "Aktif" }
        })

        local ItemCard = c:Card("Item", nil, "Palette", {
            Subtitle = "Tulis nama atau ID item, pisahkan dengan koma (contoh: Legendary Wings, 1784, Boots)"
        })
        ItemCard:Input("Nama / ID Item", "SC_Items", "contoh: Legendary Wings, Boots", "")

        local JumpCard = c:Card("Anti Teleport Double Jump", nil, "Shield", {
            Subtitle = "Dipakai hanya saat sayap double jump-nya visual. Tahan paket = server tidak melihat lompatan udara"
        })
        JumpCard:Dropdown("Mode", "SC_JumpMode", SC_JUMP_MODES, SC.JumpMode, function(mode)
            SC.JumpMode = mode
        end)
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol", nil, "Bolt", {
            Subtitle = "SET memakai item. KEMBALI KE AWAL membuang semua item visual dan mereset status dipakai"
        })
        CtrlCard:Button("Set Clothes", "SET", "Bolt", function()
            scSet()
        end)
        CtrlCard:Button("Kembali ke awal", "KEMBALI", "Check", function()
            scReset()
        end)

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Efek jalan di karakter client lewat game sendiri. Server tidak menerima pakaian visual, pemain lain tidak melihatnya. Hasil SET tercatat di console"
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

-- Teks ringan aktif otomatis setelah jendela selesai dibangun
task.delay(1.5, function()
    if getValue("LightText", true) then pcall(lightEnable) end
end)
