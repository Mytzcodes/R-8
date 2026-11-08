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

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

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

-- =========================================================================
-- TEKS RINGAN: kurangi ketebalan font bawaan library supaya mudah dibaca
-- Mode: "Medium" (default) / "Regular" / "Asli" (kembalikan)
-- =========================================================================
local FontLite = {
    Mode = "Medium",
    Orig = setmetatable({}, { __mode = "k" }),
    Guis = {},
    Conns = {},
}

local function flTarget()
    if FontLite.Mode == "Regular" then return Enum.FontWeight.Regular end
    if FontLite.Mode == "Medium" then return Enum.FontWeight.Medium end
    return nil
end

local function flApply(inst)
    if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then return end
    local okF, face = pcall(function() return inst.FontFace end)
    if not okF or not face then return end
    local target = flTarget()
    if target == nil then
        local o = FontLite.Orig[inst]
        if o then pcall(function() inst.FontFace = o end) end
        return
    end
    if FontLite.Orig[inst] == nil then FontLite.Orig[inst] = face end
    local cur = face.Weight.Value
    if cur > target.Value then
        pcall(function()
            inst.FontFace = Font.new(face.Family, target, face.Style)
        end)
    end
end

local function flRoots()
    local roots = {}
    pcall(function() if type(gethui) == "function" then roots[#roots + 1] = gethui() end end)
    pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
    local pg = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then roots[#roots + 1] = pg end
    return roots
end

local function flFindGuis()
    local found = {}
    for _, root in ipairs(flRoots()) do
        pcall(function()
            for _, g in ipairs(root:GetChildren()) do
                if g:IsA("ScreenGui") and not tostring(g.Name):find("^R8DV_") then
                    for _, d in ipairs(g:GetDescendants()) do
                        if d:IsA("TextLabel") then
                            local t = d.Text:lower():gsub("%s", "")
                            if t:find("r&8_dv", 1, true) or t:find("r&amp;8_dv", 1, true)
                                or t:find("chatspammer", 1, true) then
                                found[#found + 1] = g
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
    return found
end

local function flSweep()
    for _, g in ipairs(FontLite.Guis) do
        if g.Parent then
            for _, d in ipairs(g:GetDescendants()) do flApply(d) end
        end
    end
end

function FontLite.Set(mode)
    FontLite.Mode = mode or "Medium"
    if #FontLite.Guis == 0 then FontLite.Guis = flFindGuis() end
    for _, c in ipairs(FontLite.Conns) do pcall(function() c:Disconnect() end) end
    FontLite.Conns = {}
    for _, g in ipairs(FontLite.Guis) do
        FontLite.Conns[#FontLite.Conns + 1] = g.DescendantAdded:Connect(function(d)
            task.defer(flApply, d)
        end)
    end
    pcall(flSweep)
end

task.defer(function()
    task.wait(1)
    FontLite.Set("Medium")
end)
-- library kadang menggambar ulang saat ganti tema; sapu ulang berkala
task.spawn(function()
    while true do
        task.wait(5)
        if FontLite.Mode ~= "Asli" then pcall(flSweep) end
    end
end)

-- =========================================================================
-- LOGIKA SPAM
-- =========================================================================
local MAX_CHAT = 120

local Spam = {
    Running = false,
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

-- =========================================================================
-- SET VISUAL NAME + ROLE CHAT (100% CLIENT)
-- Nama   : attribute Nick
-- Warna  : attribute DiscordColor
-- Title  : WornTitle / HasLegend
-- Role   : attribute Tag ("moderator" / "developer"). Game menggambar tag
--          staff (@nama + warna khusus) di nameplate & chat dari attribute ini.
-- Semua hanya terlihat di layar sendiri. Server tidak pernah memberi hak
-- apa pun dari role visual ini.
-- =========================================================================
local NILV = {} -- penanda "attribute di-set nil"
local function vnRaw(v) if v == NILV then return nil end return v end

local VN = {
    Orig = nil,
    Want = {},
    Cmd = {},     -- override dari command chat (menang atas isi menu)
    Toggle = nil,
}
local VN_ATTRS = { "Nick", "WornTitle", "DiscordColor", "HasLegend", "HideLegendUntil", "Tag" }

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
-- alias untuk command chat (huruf kecil)
local VN_COLOR_ALIAS = {
    putih = "Putih", white = "Putih", merah = "Merah", red = "Merah",
    hijau = "Hijau", green = "Hijau", biru = "Biru", blue = "Biru",
    kuning = "Kuning", yellow = "Kuning", oranye = "Oranye", orange = "Oranye",
    pink = "Pink", ungu = "Ungu", purple = "Ungu", cyan = "Cyan",
    emas = "Emas", gold = "Emas", abu = "Abu-abu", gray = "Abu-abu", grey = "Abu-abu",
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
local VN_TITLE_BY_ID = {}
for label, id in pairs(VN_TITLE_ID) do VN_TITLE_BY_ID[id] = label end

local VN_ROLE_LIST = { "(tidak diubah)", "Player", "Moderator", "Developer" }

local function vnHexToColor(hex)
    hex = tostring(hex or ""):gsub("^#", "")
    if #hex == 6 and hex:match("^%x+$") then
        return Color3.fromRGB(
            tonumber(hex:sub(1, 2), 16),
            tonumber(hex:sub(3, 4), 16),
            tonumber(hex:sub(5, 6), 16)
        )
    end
    return nil
end

local function vnReadColor()
    local c = vnHexToColor(vnTrim(getValue("VN_Hex", "")))
    if c then return c end
    return VN_COLORS[getValue("VN_ColorPreset", "(tidak diubah)")]
end

-- command menang atas menu: nil = pakai menu, false = paksa "tidak diubah"
local function vnPick(key, uiVal)
    local v = VN.Cmd[key]
    if v == nil then return uiVal end
    if v == false then return nil end
    return v
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
    local name = vnTrim(vnPick("name", getValue("VN_Name", "")) or "")
    if not getValue("VN_AllowCodes", false) then
        name = name:gsub("`", "")
    end
    name = string.sub(name, 1, 30)
    if name ~= "" then want.Nick = name end

    -- warna
    local color = VN.Cmd.color
    if color == false then color = nil
    elseif color == nil then color = vnReadColor() end
    if color then want.DiscordColor = color end

    -- title
    local titleId = VN_TITLE_ID[vnPick("title", getValue("VN_Title", "(tidak diubah)")) or ""]
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

    -- role chat (tag staff, hanya tampilan)
    local role = vnPick("role", getValue("VN_Role", "(tidak diubah)"))
    if role == "Moderator" then want.Tag = "moderator"
    elseif role == "Developer" then want.Tag = "developer"
    elseif role == "Player" then want.Tag = NILV end

    for attr, val in pairs(want) do
        if attr ~= "Nick" then
            pcall(function() LocalPlayer:SetAttribute(attr, vnRaw(val)) end)
        end
    end

    -- Nick dipasang terakhir: game menggambar ulang nameplate saat Nick berubah
    local finalNick = want.Nick
    if finalNick == nil then finalNick = VN.Orig.Nick.v end
    pcall(function()
        LocalPlayer:SetAttribute("Nick", ".")
        LocalPlayer:SetAttribute("Nick", finalNick)
    end)

    VN.Want = want
    print("[R&8_DV] Visual name/role (client) aktif")
    return true
end

local function vnRestoreClient()
    VN.Want = {}
    if not LocalPlayer or not VN.Orig then return end
    for _, a in ipairs(VN_ATTRS) do
        local o = VN.Orig[a]
        if o then pcall(function() LocalPlayer:SetAttribute(a, o.v) end) end
    end
    print("[R&8_DV] Visual name/role dikembalikan ke asli")
end

VN.Toggle = newToggle(vnApplyClient, vnRestoreClient)

-- Kunci: kalau server menimpa attribute, pasang ulang
task.spawn(function()
    while true do
        task.wait(1)
        if VN.Toggle.Running and getValue("VN_Lock", false) and LocalPlayer then
            for attr, val in pairs(VN.Want) do
                local expected = vnRaw(val)
                local okGet, cur = pcall(function() return LocalPlayer:GetAttribute(attr) end)
                if okGet and cur ~= expected then
                    pcall(function() LocalPlayer:SetAttribute(attr, expected) end)
                end
            end
        end
    end
end)

-- ---- COMMAND CHAT LOKAL (/vhelp, /vrole, /vnick, /vcolor, /vtitle, /vreset) ----
-- Dicegat lewat Chat.onCommand milik game. Command ini TIDAK dikirim ke server
-- dan tidak muncul di chat pemain lain. Command staff asli (/ban, /kick, dll)
-- dicek server, jadi role visual tidak memberi akses ke sana.
local VC = { Chat = nil, Orig = nil, Tried = 0 }

local function vcSay(text)
    local chat = VC.Chat
    if not chat or type(chat.add) ~= "function" then return end
    text = tostring(text):gsub("`", "")
    pcall(chat.add, "`o" .. text .. "``")
end

local function vcErr(text)
    local chat = VC.Chat
    if chat and type(chat.add) == "function" then
        pcall(chat.add, "`4" .. tostring(text):gsub("`", "") .. "``")
    end
end

local function vcApply()
    if VN.Toggle.Running then
        vnApplyClient()
    else
        VN.Toggle.Set(true)
    end
end

local function vcRoleKey(s)
    s = s:lower()
    if s == "player" or s == "pemain" or s == "p" then return "Player" end
    if s == "mod" or s == "moderator" or s == "m" then return "Moderator" end
    if s == "dev" or s == "developer" or s == "d" then return "Developer" end
    return nil
end

local VC_HANDLERS = {}

VC_HANDLERS.vhelp = function()
    local role = vnPick("role", getValue("VN_Role", "(tidak diubah)"))
    vcSay("[Visual] Role aktif: " .. tostring(role) .. " (hanya tampilan di layarmu)")
    vcSay("/vrole player|mod|dev   - ganti role chat")
    vcSay("/vnick <nama>   - ganti nama visual")
    vcSay("/vcolor <hex|nama>   - warna nama, contoh /vcolor FF8800 atau /vcolor merah")
    vcSay("/vtitle <id>   - none cc sponsor supporter patron benefactor royal dr legend")
    vcSay("/vreset   - kembalikan semua ke asli")
end

VC_HANDLERS.vrole = function(arg)
    local r = vcRoleKey(arg)
    if not r then vcErr("Pakai: /vrole player | mod | dev") return end
    VN.Cmd.role = r
    vcApply()
    vcSay("Role visual: " .. r)
end

VC_HANDLERS.vnick = function(arg)
    if arg == "" then vcErr("Pakai: /vnick <nama>") return end
    VN.Cmd.name = arg
    vcApply()
    vcSay("Nama visual: " .. string.sub(arg:gsub("`", ""), 1, 30))
end

VC_HANDLERS.vcolor = function(arg)
    local a = arg:lower()
    if a == "" or a == "off" then
        VN.Cmd.color = false
    else
        local c = vnHexToColor(arg)
        if not c then
            local label = VN_COLOR_ALIAS[a]
            c = label and VN_COLORS[label] or nil
        end
        if not c then vcErr("Warna tidak dikenal. Pakai hex 6 digit atau nama (merah, biru, emas...)") return end
        VN.Cmd.color = c
    end
    vcApply()
    vcSay("Warna nama diperbarui")
end

VC_HANDLERS.vtitle = function(arg)
    local a = arg:lower()
    local label = VN_TITLE_BY_ID[a]
    if not label then
        for l in pairs(VN_TITLE_ID) do
            if l:lower() == a then label = l break end
        end
    end
    if a == "off" then label = "(tidak diubah)" end
    if not label then vcErr("Title tidak dikenal. Ketik /vhelp") return end
    VN.Cmd.title = (label == "(tidak diubah)") and false or label
    vcApply()
    vcSay("Title visual: " .. label)
end

VC_HANDLERS.vreset = function()
    VN.Cmd = {}
    VN.Toggle.Set(false)
    vcSay("Semua visual dikembalikan ke asli")
end

local function vcHandle(msg)
    if not getValue("VN_Cmds", true) then return false end
    local cmd, arg = string.match(msg, "^/(%a+)%s*(.-)%s*$")
    if not cmd then return false end
    local h = VC_HANDLERS[cmd:lower()]
    if not h then return false end
    local ok, err = pcall(h, arg or "")
    if not ok then warn("[R&8_DV] Command error: " .. tostring(err)) end
    return true
end

local function vcFindChat()
    if type(getgc) ~= "function" then return nil end
    local okGc, gc = pcall(getgc, true)
    if not okGc or type(gc) ~= "table" then return nil end
    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            local okA, add = pcall(rawget, obj, "add")
            local okC, oc = pcall(rawget, obj, "onCommand")
            if okA and okC and type(add) == "function" and type(oc) == "function" then
                return obj
            end
        end
    end
    return nil
end

local function vcInstall()
    if VC.Chat then return true end
    local chat = vcFindChat()
    if not chat then return false end
    local orig = chat.onCommand
    chat.onCommand = function(msg, ...)
        if type(msg) == "string" and string.sub(msg, 1, 2):lower() == "/v" and vcHandle(msg) then
            return true
        end
        return orig(msg, ...)
    end
    VC.Chat, VC.Orig = chat, orig
    print("[R&8_DV] Command chat lokal aktif (ketik /vhelp)")
    return true
end

task.spawn(function()
    while not VC.Chat and VC.Tried < 15 do
        VC.Tried += 1
        pcall(vcInstall)
        if VC.Chat then break end
        task.wait(4)
    end
    if not VC.Chat then
        warn("[R&8_DV] Command chat lokal tidak aktif: chat game belum ditemukan / executor tanpa getgc")
    end
end)

-- =========================================================================
-- ITEM VISUAL (pakaian & aksesori, tanpa block dan seed) - 100% CLIENT
--  * Item dari Shared.ItemDB: kind == "cloth"
--  * Yang dipakai = tabel `worn` milik Game. Game membaca tabel ini sendiri
--    untuk efek: speed, dig, slowFall, fireproof, doubleJump, voidEye, build,
--    dan efek pukul/hancur: rapier, voidKatana, devilBreak, fxStyle.
--    Karena kita mengubah tabel itu, efek berjalan di sisi client.
--  * Net.wear.send dibungkus: server selalu menerima pakaian ASLI.
--  * Panel masuk ke dalam card menu utama (fallback: panel melayang).
-- =========================================================================
local IV_CARD_TITLE = "Panel Item Visual"

local IV = {
    Active = false,
    Run = 0,
    DB = nil, Items = nil, Slots = nil, IconMod = nil,
    Worn = nil,
    Ov = {},
    WearTbl = nil, OrigSend = nil,
    Root = nil, Main = nil, Mini = nil, Grid = nil, WornScroll = nil,
    CountLbl = nil, SlotBtn = nil, FxBtn = nil, Search = nil,
    Conns = {}, Cells = {}, WornSig = "",
    Query = "", SlotFilter = "Semua", GameFx = true,
    List = {}, Rendered = 0,
    Docked = false,
    HostCard = nil,
    Toggle = nil,
}
local IV_PAGE = 48

-- efek pukul / hancur block (kosmetik + animasi)
local IV_HIT_KEYS = { "rapier", "voidKatana", "devilBreak" }
-- efek yang mengubah gerakan / kemampuan
local IV_GP_KEYS = { "speed", "dig", "slowFall", "fireproof", "doubleJump", "voidEye", "build" }

local IV_C = {
    bg    = Color3.fromRGB(18, 22, 30),
    cell  = Color3.fromRGB(32, 38, 50),
    line  = Color3.fromRGB(56, 66, 86),
    text  = Color3.fromRGB(226, 230, 238),
    sub   = Color3.fromRGB(150, 160, 178),
    worn  = Color3.fromRGB(73, 252, 0),
    vis   = Color3.fromRGB(25, 185, 255),
    btn   = Color3.fromRGB(44, 52, 68),
    hit   = Color3.fromRGB(255, 193, 94),
    gp    = Color3.fromRGB(255, 143, 243),
}

local function ivAnyKey(it, keys)
    for _, k in ipairs(keys) do
        if it[k] then return true end
    end
    return false
end

local function ivIsHit(it) return ivAnyKey(it, IV_HIT_KEYS) or it.fxStyle ~= nil end
local function ivIsGp(it) return ivAnyKey(it, IV_GP_KEYS) end

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
                slot = it.slot, hit = ivIsHit(it), gp = ivIsGp(it),
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

local function ivWear(id)
    local it = IV.DB and IV.DB[id]
    if not it or not it.slot then return end
    local slot = it.slot
    if IV.Ov[slot] == nil then IV.Ov[slot] = { real = IV.Worn[slot] } end
    IV.Ov[slot].vis = id
    IV.Worn[slot] = id
    if IV.Ov[slot].real == id then IV.Ov[slot] = nil end
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

-- saat "Efek GP" dimatikan: lepas item visual yang mengubah gerakan
local function ivDropGp()
    if not IV.Worn then return end
    local slots = {}
    for slot, o in pairs(IV.Ov) do
        local it = o.vis and IV.DB and IV.DB[o.vis]
        if it and ivIsGp(it) then slots[#slots + 1] = slot end
    end
    for _, slot in ipairs(slots) do ivReset(slot) end
end

local function ivToggleItem(id)
    local it = IV.DB and IV.DB[id]
    if not it or not it.slot then return end
    local slot = it.slot
    if IV.Worn[slot] == id then
        local o = IV.Ov[slot]
        if o and o.vis == id and o.real ~= id then
            ivReset(slot)
        else
            ivUnwear(slot)
        end
    else
        ivWear(id)
    end
end

local function ivKeepAlive()
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
        if e.hit or e.gp then
            ivNew("TextLabel", {
                Position = UDim2.fromOffset(3, 2), Size = UDim2.fromOffset(22, 12),
                BackgroundTransparency = 1, Text = e.hit and "FX" or "GP", TextSize = 9,
                Font = Enum.Font.GothamMedium, TextColor3 = e.hit and IV_C.hit or IV_C.gp,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, btn)
        end
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
            and (IV.GameFx or not e.gp)
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
        IV.CountLbl.Text = #list .. " item   FX = efek pukul   GP = efek gerak"
    end
end

-- cari card "Panel Item Visual" di menu utama untuk tempat panel
local function ivFindHost()
    local card = IV.HostCard
    if type(card) == "table" then
        for _, k in ipairs({ "Frame", "Content", "Body", "Container", "Instance", "Root", "Holder", "Gui", "Inner" }) do
            local okV, v = pcall(function() return card[k] end)
            if okV and typeof(v) == "Instance" and v:IsA("GuiObject") then
                return v, "inside"
            end
        end
    end

    for _, root in ipairs(flRoots()) do
        local result
        pcall(function()
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("TextLabel") and not d:IsDescendantOf(IV.Root or root)
                    and d.Text:lower():gsub("%s", ""):find("panelitemvisual", 1, true) then
                    local f = d.Parent
                    while f and not (f:IsA("Frame") and f.Parent and f.Parent:FindFirstChildOfClass("UIListLayout")) do
                        f = f.Parent
                    end
                    if f then result = f return end
                end
            end
        end)
        if result then
            if result:FindFirstChildOfClass("UIListLayout") then
                return result, "inside"
            end
            return result, "after"
        end
    end
    return nil
end

local function ivBuildGui()
    local host, how = ivFindHost()
    local docked = host ~= nil
    IV.Docked = docked

    local main, gui
    if docked then
        local parent, order = host, 9999
        if how == "after" then
            parent = host.Parent
            order = (host.LayoutOrder or 0) + 1
        elseif host.AutomaticSize == Enum.AutomaticSize.None then
            pcall(function() host.AutomaticSize = Enum.AutomaticSize.Y end)
        end
        main = ivNew("Frame", {
            Name = "R8DV_ItemPanel", Size = UDim2.new(1, -12, 0, 450),
            BackgroundColor3 = IV_C.bg, BorderSizePixel = 0, LayoutOrder = order,
        }, parent)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 8) }, main)
        ivNew("UIStroke", { Color = IV_C.line, Thickness = 1 }, main)
        IV.Root = main
    else
        warn("[R&8_DV] Card menu tidak ketemu, panel Item Visual dibuka melayang")
        gui = ivNew("ScreenGui", {
            Name = "R8DV_ItemVisual", ResetOnSpawn = false, DisplayOrder = 950,
            IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        pcall(function()
            local h = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
            gui.Parent = h
        end)
        if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        IV.Root = gui

        main = ivNew("Frame", {
            Name = "Main", Size = UDim2.fromOffset(350, 500), AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = IV_C.bg, BorderSizePixel = 0,
        }, gui)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 8) }, main)
        ivNew("UIStroke", { Color = IV_C.line, Thickness = 1 }, main)
        local scale = ivNew("UIScale", {}, main)
        local cam = workspace.CurrentCamera
        if cam then scale.Scale = math.clamp(cam.ViewportSize.Y / 760, 0.6, 1) end

        local mini = ivNew("TextButton", {
            Name = "Mini", Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = IV_C.bg, Visible = false,
            Text = "IV", TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 14,
            BorderSizePixel = 0,
        }, gui)
        ivNew("UICorner", { CornerRadius = UDim.new(1, 0) }, mini)
        ivNew("UIStroke", { Color = IV_C.vis, Thickness = 2 }, mini)
        IV.Mini = mini

        local bar = ivNew("Frame", {
            Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Active = true,
        }, main)
        ivNew("TextLabel", {
            Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1, Text = "ITEM VISUAL (client only)",
            TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, bar)
        local closeBtn = ivNew("TextButton", {
            Size = UDim2.fromOffset(34, 34), Position = UDim2.new(1, -36, 0, 0),
            BackgroundTransparency = 1, Text = "-", TextColor3 = IV_C.sub,
            Font = Enum.Font.GothamMedium, TextSize = 22,
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
    end
    IV.Main = main

    local T = docked and 6 or 38 -- offset atas

    ivNew("TextLabel", {
        Position = UDim2.fromOffset(10, T), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = "Dipakai sekarang (tap = lepas, garis biru = visual)",
        TextColor3 = IV_C.sub, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    local wornScroll = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, T + 18), Size = UDim2.new(1, -20, 0, 62),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.X,
    }, main)
    ivNew("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, wornScroll)
    IV.WornScroll = wornScroll

    local rowY = T + 86
    local search = ivNew("TextBox", {
        Position = UDim2.fromOffset(10, rowY), Size = UDim2.new(1, -196, 0, 30),
        BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, Text = "",
        PlaceholderText = "Cari nama / ID...", PlaceholderColor3 = IV_C.sub,
        TextColor3 = IV_C.text, Font = Enum.Font.Gotham, TextSize = 12,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, search)
    ivNew("UIPadding", { PaddingLeft = UDim.new(0, 8) }, search)
    IV.Search = search

    local slotBtn = ivNew("TextButton", {
        Position = UDim2.new(1, -180, 0, rowY), Size = UDim2.fromOffset(86, 30),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = "Slot: Semua",
        TextColor3 = IV_C.text, Font = Enum.Font.Gotham, TextSize = 11,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, slotBtn)
    IV.SlotBtn = slotBtn

    local fxBtn = ivNew("TextButton", {
        Position = UDim2.new(1, -88, 0, rowY), Size = UDim2.fromOffset(78, 30),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0,
        Text = IV.GameFx and "GP: ON" or "GP: OFF",
        TextColor3 = IV_C.text, Font = Enum.Font.Gotham, TextSize = 11,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, fxBtn)
    IV.FxBtn = fxBtn

    local countLbl = ivNew("TextLabel", {
        Position = UDim2.fromOffset(10, rowY + 34), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = "", TextColor3 = IV_C.sub,
        Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    }, main)
    IV.CountLbl = countLbl

    local gridY = rowY + 54
    local grid = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, gridY), Size = UDim2.new(1, -20, 1, -(gridY + 46)),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, main)
    ivNew("UIGridLayout", {
        CellSize = UDim2.fromOffset(76, 84), CellPadding = UDim2.fromOffset(6, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)
    IV.Grid = grid

    local clearBtn = ivNew("TextButton", {
        Position = UDim2.new(0, 10, 1, -38), Size = UDim2.new(1, -20, 0, 30),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = "Lepas semua visual (balik ke pakaian asli)",
        TextColor3 = IV_C.text, Font = Enum.Font.Gotham, TextSize = 12,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, clearBtn)

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
        IV.GameFx = not IV.GameFx
        fxBtn.Text = IV.GameFx and "GP: ON" or "GP: OFF"
        if not IV.GameFx then ivDropGp() end
        ivRefilter()
        ivRefreshMarks()
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
    if FontLite.Mode == "Asli" then return end
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
    local okGui, errGui = pcall(ivBuildGui)
    if not okGui then
        warn("[R&8_DV] Item Visual dibatalkan: panel gagal dibuat: " .. tostring(errGui))
        IV.Active = false
        ivUnhook()
        if IV.Root then pcall(function() IV.Root:Destroy() end) end
        IV.Root = nil
        return false
    end
    task.spawn(function()
        while IV.Active and IV.Run == run do
            ivKeepAlive()
            pcall(ivRebuildWorn)
            pcall(ivRefreshMarks)
            task.wait(0.25)
        end
    end)
    print("[R&8_DV] Item Visual START (client only), " .. #IV.Items .. " item pakaian, panel "
        .. (IV.Docked and "di dalam menu" or "melayang"))
    return true
end

local function ivStop()
    IV.Active = false
    IV.Run += 1
    if IV.Worn then ivResetAll() end
    ivUnhook()
    for _, c in ipairs(IV.Conns) do pcall(function() c:Disconnect() end) end
    IV.Conns = {}
    if IV.Root then pcall(function() IV.Root:Destroy() end) end
    IV.Root, IV.Main, IV.Mini, IV.Grid, IV.WornScroll = nil, nil, nil, nil, nil
    IV.Cells, IV.WornSig, IV.Ov = {}, "", {}
    print("[R&8_DV] Item Visual STOP, pakaian dikembalikan")
end

IV.Toggle = newToggle(ivStart, ivStop)

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
            task.delay(0.3, function() if FontLite.Mode ~= "Asli" then pcall(flSweep) end end)
        end)
        ThemeCard:Dropdown("Checkbox Style", "CheckboxStyleMode", { "Modern", "Checkbox" }, "Modern", function(mode)
            if UI.SetCheckboxStyle then UI:SetCheckboxStyle(mode) end
        end)
    end)
})

-- =========================================================================
-- KATEGORI 2: VISUAL NAME + ROLE
-- =========================================================================
if UI.Category then UI:Category("Visual Name") end

feature("Name", "Set Visual Name")({
    center = center(function(c)
        c:Header("Set Visual Name & Role", "Ubah nama, warna, title, dan role chat di dalam game (bukan nama Roblox)", "Client")

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

        local RoleCard = c:Card("Role Chat", nil, "Shield", {
            Subtitle = "Tag staff di nama & chat milikmu. Menyatu dengan Visual Name, tombol START sama"
        })
        RoleCard:Dropdown("Role", "VN_Role", VN_ROLE_LIST, "(tidak diubah)")
        RoleCard:Toggle("Aktifkan command chat lokal (/vhelp)", "VN_Cmds", true)
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol", nil, "Bolt", {
            Subtitle = "Satu tombol: START menerapkan, STOP mengembalikan nama & role asli"
        })
        VN.Toggle.Button = CtrlCard:Button("Visual Name", "START", "Bolt", function()
            VN.Toggle.Toggle()
        end)

        local CmdCard = r:Card("Command Chat", nil, "Chat", {
            Subtitle = "Ketik di chat game. Hanya lokal, tidak terkirim ke server"
        })
        CmdCard:ActivityTimeline({
            { Text = "/vhelp  daftar command", Time = "1" },
            { Text = "/vrole player | mod | dev", Time = "2" },
            { Text = "/vnick <nama>", Time = "3" },
            { Text = "/vcolor <hex atau nama>", Time = "4" },
            { Text = "/vtitle <id>  (legend, dr, royal, ...)", Time = "5" },
            { Text = "/vreset  kembalikan semua", Time = "6" }
        })

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Hanya terlihat di layarmu. Pemain lain tetap melihat nama & role aslimu. Role tidak memberi akses command staff asli (dicek server)"
        })
    end)
})

-- =========================================================================
-- KATEGORI 3: ITEM VISUAL
-- =========================================================================
if UI.Category then UI:Category("Item Visual") end

feature("Item", "Item Visual")({
    center = center(function(c)
        c:Header("Item Visual", "Pakai baju & aksesori di layarmu, lengkap dengan efek pukul (tanpa block dan seed)", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",         Value = "Client" },
            { Icon = "Shield", Label = "Kirim server", Value = "Diblokir" },
            { Icon = "Check",  Label = "Efek item",    Value = "Aktif" }
        })

        local PanelCard = c:Card(IV_CARD_TITLE, nil, "Palette", {
            Subtitle = "START membuka daftar item di card ini. STOP menutup dan mengembalikan pakaian asli"
        })
        IV.HostCard = PanelCard
        IV.Toggle.Button = PanelCard:Button("Item Visual", "START", "Bolt", function()
            IV.Toggle.Toggle()
        end)
        PanelCard:Button("Lepas Semua Visual", "RESET", "Check", function()
            if IV.Active then ivResetAll() end
        end)
    end),

    right = right(function(r)
        local HowCard = r:Card("Cara Pakai", nil, "Clock", {
            Subtitle = "Daftar item muncul di dalam card sebelah kiri setelah START"
        })
        HowCard:ActivityTimeline({
            { Text = "Cari nama atau ID item di kolom search", Time = "1" },
            { Text = "Tombol Slot = filter hat / shirt / feet dst (tap tap)", Time = "2" },
            { Text = "Tap item = pakai, tap lagi = lepas", Time = "3" },
            { Text = "Baris atas = pakaian yang sedang dipakai, tap = lepas", Time = "4" },
            { Text = "FX = efek pukul (rapier, katana, devil, blackhole)", Time = "5" },
            { Text = "GP = efek gerak (speed, dig, jump). Tombol GP: OFF menyembunyikannya", Time = "6" }
        })

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Pakaian visual tidak dikirim ke server dan tidak terlihat pemain lain. Efek GP (speed/dig) hanya di client, server bisa menarik posisimu kembali"
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

        local TextCard = c:Card("Teks", nil, "Palette", {
            Subtitle = "Kurangi ketebalan huruf supaya mudah dibaca"
        })
        TextCard:Dropdown("Ketebalan Teks", "FontWeightMode", { "Medium", "Regular", "Asli" }, "Medium", function(mode)
            FontLite.Set(mode)
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
