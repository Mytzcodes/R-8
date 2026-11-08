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
-- LOGIKA SET VISUAL NAME + ROLE (100% CLIENT)
-- Mengubah attribute milik LocalPlayer, hanya terlihat di layar sendiri.
-- Role = attribute "Tag" (moderator / developer), dibaca Shared.Roles
-- =========================================================================
local NIL = {} -- penanda: attribute diisi nil

local VN = {
    Orig = nil,
    Want = {},
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

local VN_ROLE_LIST = { "(tidak diubah)", "Player", "World Owner", "Moderator", "Developer" }
local VN_ROLE_TAG = {
    ["Player"]      = NIL,
    ["World Owner"] = NIL,
    ["Moderator"]   = "moderator",
    ["Developer"]   = "developer",
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
-- ROLE COMMANDS (client)
-- /help TIDAK membuat panel baru: pakai panel Help bawaan game (border, judul,
-- tombol X, scroll, chip command) lalu isinya ditimpa sesuai role yang dipilih:
--   Player      -> Everyone
--   World Owner -> Everyone + World owner
--   Moderator   -> Everyone + World owner + Staff Moderator (+ legend)
--   Developer   -> Everyone + World owner + Staff Moderator + Staff Developer
-- Daftar command Moderator/Developer tidak ada di ekspor (StaffCommands hanya
-- dikirim ke akun staff), jadi bisa kamu isi sendiri di kartu Role.
-- =========================================================================
local RC = { Role = nil, Installed = false, Game = nil, Chat = nil, OrigOpen = nil, OrigCmd = nil, Parts = nil }

local function rcWords(s)
    local t = {}
    for w in string.gmatch(tostring(s or ""), "%a+") do t[#t + 1] = w:lower() end
    return t
end

local function rcRealCommands()
    local real = { player = {}, world = {}, all = {} }
    local ok, list = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("CommandList", 5))
    end)
    if ok and type(list) == "table" then
        for _, c in ipairs(list) do
            if c.rank == "player" then real.player[#real.player + 1] = c.name
            elseif c.rank == "world" then real.world[#real.world + 1] = c.name end
            real.all[c.name] = true
        end
    end
    return real
end

local function rcGroups(role)
    local real = rcRealCommands()
    local groups = {
        { title = "Everyone", kind = "player", names = real.player },
    }
    if role ~= "Player" then
        groups[#groups + 1] = { title = "World owner", kind = "world", names = real.world }
    end
    if role == "Moderator" or role == "Developer" then
        groups[#groups + 1] = { title = "Staff - Moderator", kind = "mod", names = rcWords(getValue("RC_ModCmds", "")) }
    end
    if role == "Developer" then
        groups[#groups + 1] = { title = "Staff - Developer", kind = "dev", names = rcWords(getValue("RC_DevCmds", "")) }
    end
    return groups
end

local function rcFind()
    if type(getgc) ~= "function" then return end
    local ok, gc = pcall(getgc, true)
    if not ok or type(gc) ~= "table" then return end
    for _, obj in ipairs(gc) do
        if type(obj) == "table" then
            local h = rawget(obj, "help")
            if not RC.Game and type(h) == "table" and type(rawget(h, "open")) == "function"
                and type(rawget(obj, "modCommand")) == "function" then
                RC.Game = obj
            end
            if not RC.Chat and type(rawget(obj, "onCommand")) == "function"
                and type(rawget(obj, "add")) == "function" then
                RC.Chat = obj
            end
            if RC.Game and RC.Chat then return end
        end
    end
end

-- Ambil bagian-bagian panel Help ASLI milik game lewat upvalue fungsi open():
--   build (fungsi pembuat isi), panel (objek Panel), lalu dari build:
--   Flow / Legend / Commands (scroll), BitmapText, ui (corner/stroke), Sfx, chat
local function rcFindParts()
    if RC.Parts then return RC.Parts end
    if not (RC.Game and type(RC.Game.help) == "table" and type(RC.OrigOpen) == "function") then return nil end
    if type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then return nil end

    local p = {}
    local okU, ups = pcall(debug.getupvalues, RC.OrigOpen)
    if not okU or type(ups) ~= "table" then return nil end
    for _, up in pairs(ups) do
        if type(up) == "function" and not p.build then
            p.build = up
        elseif type(up) == "table" and type(rawget(up, "setHeight")) == "function" then
            p.panel = up
        end
    end
    if not (p.build and p.panel) then return nil end

    local okB, bups = pcall(debug.getupvalues, p.build)
    if not okB or type(bups) ~= "table" then return nil end
    for _, up in pairs(bups) do
        if typeof(up) == "Instance" then
            if up.Name == "Flow" then p.flow = up
            elseif up.Name == "Legend" then p.legend = up
            elseif up.Name == "Commands" and up:IsA("ScrollingFrame") then p.scroll = up end
        elseif type(up) == "table" then
            if type(rawget(up, "new")) == "function" and type(rawget(up, "COLORS")) == "table" then
                p.bt = up
            elseif type(rawget(up, "corner")) == "function" and type(rawget(up, "stroke")) == "function" then
                p.ui = up
            elseif rawget(up, "MODERATOR_COLOR") ~= nil then
                p.roles = up
            elseif type(rawget(up, "prefill")) == "function" then
                p.chat = up
            elseif type(rawget(up, "play")) == "function" then
                p.sfx = up
            end
        end
    end
    if not (p.flow and p.legend and p.scroll and p.bt and p.ui) then return nil end
    RC.Parts = p
    return p
end

-- Timpa isi panel Help bawaan (Flow + Legend) memakai gaya chip yang sama
-- persis dengan HelpUI game, jadi tidak ada border / GUI baru.
local function rcRebuild(role)
    local P = rcFindParts()
    if not P then error("bagian panel Help tidak ditemukan") end
    local groups = rcGroups(role)
    local showLegend = (role == "Moderator" or role == "Developer")

    local function colorOf(kind)
        if kind == "mod" then return (P.roles and P.roles.MODERATOR_COLOR) or Color3.fromRGB(255, 193, 94) end
        if kind == "dev" then return (P.roles and P.roles.DEVELOPER_COLOR) or Color3.fromRGB(255, 39, 29) end
        return Color3.new(1, 1, 1)
    end

    for _, c in ipairs(P.flow:GetChildren()) do c:Destroy() end
    for _, c in ipairs(P.legend:GetChildren()) do c:Destroy() end

    local x, y = 0, 0

    local function heading(text)
        if x > 0 or y > 0 then y = y + 68 end
        x = 0
        local bt = P.bt.new(P.flow, { size = 26, color = P.bt.COLORS.s })
        bt:set(text)
        bt.frame.Position = UDim2.fromOffset(0, y)
        y = y + 34
        x = -1
    end

    local function chip(name, kind)
        local color = colorOf(kind)
        local b = Instance.new("TextButton")
        b.Name = name
        b.Text = ""
        b.AutoButtonColor = true
        b.BackgroundColor3 = Color3.new(0, 0, 0)
        b.BackgroundTransparency = 0.5
        local bt = P.bt.new(b, { size = 30, color = color })
        bt:set("/" .. name)
        bt.frame.AnchorPoint = Vector2.new(0.5, 0.5)
        bt.frame.Position = UDim2.fromScale(0.5, 0.5)
        local w = math.ceil(bt.contentWidth) + 36
        if x < 0 then
            x = 0
        elseif x > 0 and x + w > 1000 then
            x = 0
            y = y + 62
        end
        b.Position = UDim2.fromOffset(x, y)
        b.Size = UDim2.fromOffset(w, 52)
        b.Parent = P.flow
        P.ui.corner(b, 10)
        P.ui.stroke(b, color, 2).Transparency = 0.45
        x = x + w + 10
        b.Activated:Connect(function()
            if P.sfx then pcall(P.sfx.play, "click") end
            pcall(function() P.panel:close() end)
            if P.chat and P.chat.prefill then pcall(P.chat.prefill, "/" .. name .. " ") end
        end)
    end

    for _, g in ipairs(groups) do
        if #g.names > 0 then
            heading(g.title)
            for _, n in ipairs(g.names) do chip(n, g.kind) end
        end
    end

    -- legend (Everyone | Moderator | Developer) seperti tampilan staff asli
    local legendTop = 100
    if showLegend then
        local lx = 0
        local items = { { "Everyone", "player" }, { "Moderator", "mod" } }
        if role == "Developer" then items[#items + 1] = { "Developer", "dev" } end
        for _, it in ipairs(items) do
            local bt = P.bt.new(P.legend, { size = 26, color = colorOf(it[2]) })
            bt:set(it[1])
            bt.frame.Position = UDim2.fromOffset(lx, 0)
            lx = lx + math.ceil(bt.contentWidth) + 40
        end
        legendTop = 140
    end
    P.legend.Visible = showLegend

    local contentH = y + 52
    local viewH = math.min(contentH + 32, 720)
    P.flow.Size = UDim2.new(1, -44, 0, contentH)
    P.scroll.Position = UDim2.fromOffset(28, legendTop)
    P.scroll.Size = UDim2.fromOffset(1044, viewH)
    P.scroll.CanvasSize = UDim2.fromOffset(0, contentH + 32)
    P.scroll.CanvasPosition = Vector2.zero
    P.panel:setHeight(legendTop + viewH + 28)
end

-- true kalau command staff ini harus dijalankan secara visual saja
local function rcFakeCommand(text)
    if not RC.Role or type(text) ~= "string" then return false end
    local cmd, args = string.match(text, "^/(%a+)%s*(.-)%s*$")
    if not cmd then return false end
    cmd = cmd:lower()
    local real = rcRealCommands()
    if real.all[cmd] then return false end -- command asli game tetap diproses game

    local allowed = false
    if RC.Role == "Moderator" or RC.Role == "Developer" then
        if table.find(rcWords(getValue("RC_ModCmds", "")), cmd) then allowed = true end
    end
    if RC.Role == "Developer" and table.find(rcWords(getValue("RC_DevCmds", "")), cmd) then allowed = true end
    if not allowed then return false end

    pcall(function()
        if RC.Chat and type(RC.Chat.add) == "function" then
            RC.Chat.add("`2[Visual] /" .. cmd .. (args ~= "" and (" " .. args) or "") .. "`` `8(client only, tidak dikirim ke server)``")
        end
    end)
    return true
end

local function rcInstall()
    if RC.Installed then return end
    rcFind()
    if RC.Game and type(RC.Game.help) == "table" then
        local orig = RC.Game.help.open
        RC.OrigOpen = orig
        pcall(function()
            RC.Game.help.open = function(...)
                if RC.Role then
                    local P = rcFindParts()
                    if P then
                        local okAll = pcall(function()
                            P.build()               -- builder asli game (reset isi panel)
                            rcRebuild(RC.Role)      -- timpa isi sesuai role
                            P.panel:open()          -- buka panel asli
                        end)
                        if okAll then return end
                    else
                        warn("[R&8_DV] Role: bagian panel Help tidak terbaca, memakai /help asli")
                    end
                end
                return orig(...)
            end
        end)
    else
        warn("[R&8_DV] Role: menu /help game tidak ditemukan (executor perlu getgc)")
    end
    if RC.Chat then
        local origCmd = RC.Chat.onCommand
        RC.OrigCmd = origCmd
        pcall(function()
            RC.Chat.onCommand = function(text, ...)
                if RC.Role and rcFakeCommand(text) then return true end
                return origCmd(text, ...)
            end
        end)
    end
    RC.Installed = true
end

local function rcUninstall()
    if RC.Game and RC.OrigOpen and type(RC.Game.help) == "table" then
        pcall(function() RC.Game.help.open = RC.OrigOpen end)
    end
    if RC.Chat and RC.OrigCmd then
        pcall(function() RC.Chat.onCommand = RC.OrigCmd end)
    end
    RC.OrigOpen, RC.OrigCmd, RC.Parts = nil, nil, nil
    RC.Role, RC.Installed = nil, false
end

-- ---------------------------------------------------------------------

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

    -- role (visual): Tag -> warna nama staff, tanda @, dan menu /help
    local role = getValue("VN_Role", "(tidak diubah)")
    local roleTag = VN_ROLE_TAG[role]
    if roleTag ~= nil then
        want.Tag = roleTag
        RC.Role = role
        rcInstall()
        RC.Role = role -- rcInstall tidak menimpa, tapi pastikan terisi
    else
        RC.Role = nil
    end

    for attr, val in pairs(want) do
        if attr ~= "Nick" then
            local v = val
            if v == NIL then v = nil end
            pcall(function() LocalPlayer:SetAttribute(attr, v) end)
        end
    end

    local finalNick = want.Nick
    if finalNick == nil then finalNick = VN.Orig.Nick.v end
    pcall(function()
        LocalPlayer:SetAttribute("Nick", ".")
        LocalPlayer:SetAttribute("Nick", finalNick)
    end)

    VN.Want = want
    print("[R&8_DV] Visual name (client) aktif" .. (RC.Role and (", role: " .. RC.Role) or ""))
    return true
end

local function vnRestoreClient()
    VN.Want = {}
    rcUninstall()
    if not LocalPlayer or not VN.Orig then return end
    for _, a in ipairs(VN_ATTRS) do
        local o = VN.Orig[a]
        if o then pcall(function() LocalPlayer:SetAttribute(a, o.v) end) end
    end
    print("[R&8_DV] Visual name & role dikembalikan ke asli")
end

VN.Toggle = newToggle(vnApplyClient, vnRestoreClient)

-- Kunci: kalau server menimpa attribute, pasang ulang
task.spawn(function()
    while true do
        task.wait(1)
        if VN.Toggle.Running and getValue("VN_Lock", false) and LocalPlayer then
            for attr, val in pairs(VN.Want) do
                local target = val
                if target == NIL then target = nil end
                local okGet, cur = pcall(function() return LocalPlayer:GetAttribute(attr) end)
                if okGet and cur ~= target then
                    pcall(function() LocalPlayer:SetAttribute(attr, target) end)
                end
            end
        end
    end
end)

-- =========================================================================
-- LOGIKA ITEM VISUAL (pakaian & aksesori saja, tanpa block dan seed) - 100% CLIENT
--  * Yang dipakai = tabel `worn` milik Game. Setiap perubahan diikuti
--    Game.refresh() (INI yang membuat baju benar-benar tergambar di karakter)
--    dan Game.effects/effectsChanged (supaya efek slash/rapier/speed ikut jalan).
--  * Net.wear.send dibungkus supaya server tetap menerima pakaian asli.
--  * Panel TIDAK membuat ScreenGui baru: selalu ditempel di dalam menu utama
--    (di bawah kartu Item Visual).
--  * Daftar = kartu list (gambar atlas asset ID Roblox + nama + ID + slot),
--    bisa dicari, difilter per slot (Head/Mask/Hair/...), scroll.
--  * Tap 1x = pilih, tap 2x = pakai / lepas. Ada UNWEAR ALL dan RESET.
-- =========================================================================
local IV = {
    Active = false,
    Run = 0,
    DB = nil, Items = nil, Slots = nil, Assets = nil, Autotile = nil, IconMod = nil,
    Worn = nil, Game = nil, State = nil,
    Ov = {},
    WearTbl = nil, OrigSend = nil,
    Main = nil, Grid = nil, WornScroll = nil, ChipRow = nil,
    CountLbl = nil, Search = nil, InfoLbl = nil, InfoBtn = nil,
    Conns = {}, Cells = {}, WornSig = "", ChipBtns = {},
    Query = "", Filter = "Semua", -- Semua | Dipakai | Efek | <slot>
    List = {}, Rendered = 0,
    Selected = nil, TapId = nil, TapAt = 0,
    Toggle = nil, HostLabel = nil, Z = 1,
}
local IV_PAGE = 40
local IV_HOST_TAG = "R8DV_ITEMHOST"
local IV_HOST_DONE = "Panel muncul di bawah kartu ini. Tap 1x pilih, tap 2x pakai / lepas"
local IV_FX_KEYS = { "speed", "dig", "slowFall", "fireproof", "rapier", "voidEye", "voidKatana", "slashFx", "doubleJump" }
local IV_SLOT_LABEL = {
    hat = "Head", face = "Mask", hair = "Hair", shirt = "Shirt", chest = "Chest",
    pants = "Pants", feet = "Feet", hand = "Hand", back = "Back",
}
local IV_SLOT_ORDER = { "hat", "face", "hair", "shirt", "chest", "pants", "feet", "hand", "back" }

local function ivSlotLabel(slot)
    return IV_SLOT_LABEL[slot] or (slot:sub(1, 1):upper() .. slot:sub(2))
end

local IV_C = {
    bg    = Color3.fromRGB(18, 22, 30),
    cell  = Color3.fromRGB(32, 38, 50),
    line  = Color3.fromRGB(56, 66, 86),
    text  = Color3.fromRGB(235, 238, 245),
    sub   = Color3.fromRGB(170, 180, 196),
    worn  = Color3.fromRGB(73, 252, 0),
    vis   = Color3.fromRGB(25, 185, 255),
    pick  = Color3.fromRGB(255, 193, 94),
    btn   = Color3.fromRGB(44, 52, 68),
    btnOn = Color3.fromRGB(80, 96, 128),
}

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

-- Cari: tabel worn, objek karakter game (punya refresh), tabel state game (punya call/effects)
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
                    local worn, state
                    for _, up in pairs(ups) do
                        if type(up) == "table" then
                            if not worn and ivLooksLikeWorn(up) then worn = up end
                            if not state and type(rawget(up, "call")) == "function" then state = up end
                        end
                    end
                    if worn then
                        IV.Game = obj
                        IV.State = state or RC.Game
                        return worn
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
    local sh = ReplicatedStorage:WaitForChild("Shared", 5)
    local ok, DB = pcall(function() return require(sh:WaitForChild("ItemDB", 5)) end)
    if not ok or type(DB) ~= "table" then return false end

    local items, slotSet = {}, {}
    for id, it in pairs(DB) do
        if type(id) == "number" and type(it) == "table" and it.kind == "cloth"
            and type(it.slot) == "string" and type(it.name) == "string"
            and not it.name:find(" Seed$") then
            slotSet[it.slot] = true
            items[#items + 1] = {
                id = id, name = it.name, lname = it.name:lower(),
                slot = it.slot, lslot = (it.slot .. " " .. ivSlotLabel(it.slot)):lower(),
                fx = ivHasFx(it),
            }
        end
    end
    table.sort(items, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name < b.name
    end)

    -- urutan slot: Head, Mask, Hair, ... lalu sisanya alfabet
    local slots, seen = {}, {}
    for _, s in ipairs(IV_SLOT_ORDER) do
        if slotSet[s] then slots[#slots + 1] = s; seen[s] = true end
    end
    local rest = {}
    for s in pairs(slotSet) do if not seen[s] then rest[#rest + 1] = s end end
    table.sort(rest)
    for _, s in ipairs(rest) do slots[#slots + 1] = s end

    IV.DB, IV.Items, IV.Slots = DB, items, slots
    local okA, assets = pcall(function() return require(sh:WaitForChild("Assets", 5)) end)
    IV.Assets = okA and assets or nil
    local okT, tile = pcall(function() return require(sh:WaitForChild("Autotile", 5)) end)
    IV.Autotile = okT and tile or nil
    local okI, icon = pcall(function() return require(sh:WaitForChild("ItemIcon", 5)) end)
    IV.IconMod = okI and icon or nil
    return #items > 0
end

-- ---------------------------------------------------------------------
-- Terapkan perubahan ke tabel worn + catat override + gambar ulang karakter
-- ---------------------------------------------------------------------
local function ivMutate(fn)
    local W = IV.Worn
    if not W then return end
    local before = {}
    for k, v in pairs(W) do before[k] = v end

    local G = IV.State
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
            local o = IV.Ov[slot]
            if not o then
                o = { real = before[slot] }
                IV.Ov[slot] = o
            end
            o.vis = W[slot] or false
            if o.real == W[slot] then IV.Ov[slot] = nil end
        end
    end

    if prevFx and G and type(G.effectsChanged) == "function" then
        pcall(G.effectsChanged, prevFx)
    end
    if G then
        local hand = W.hand
        if hand == 138 or hand == 5480 then G.punchPick = hand end
    end
    if IV.Game and type(IV.Game.refresh) == "function" then
        pcall(IV.Game.refresh)
    end
end

local function ivToggleItem(id)
    local it = IV.DB and IV.DB[id]
    if not it or not it.slot then return end
    ivMutate(function(W)
        local slot = it.slot
        if W[slot] == id then
            W[slot] = nil
        else
            -- aturan "suit" game: slot yang tidak cocok dilepas otomatis
            local s = it.suit
            for k, other in pairs(W) do
                local o = IV.DB[other]
                local os = o and o.suit
                if not (k == slot or ((not s or s[k]) and (not os or os[slot]))) then
                    W[k] = nil
                end
            end
            W[slot] = id
        end
    end)
end

local function ivUnwearAll()
    ivMutate(function(W)
        for k in pairs(W) do W[k] = nil end
    end)
end

local function ivResetAll()
    ivMutate(function(W)
        for slot, o in pairs(IV.Ov) do W[slot] = o.real end
    end)
    IV.Ov = {}
end

-- jaga-jaga kalau game menghapus item visual (mis. event inventory berubah)
local function ivKeepAlive()
    local W = IV.Worn
    if not W then return end
    local changed = false
    for slot, o in pairs(IV.Ov) do
        local want = o.vis or nil
        local cur = W[slot]
        if cur ~= want then
            if cur == nil then
                W[slot] = want
                changed = true
            else
                IV.Ov[slot] = nil -- pemain ganti sendiri lewat inventory asli
            end
        end
    end
    if changed and IV.Game and type(IV.Game.refresh) == "function" then
        pcall(IV.Game.refresh)
    end
end

-- ---------------------------------------------------------------------
-- UI (di dalam menu utama, tanpa ScreenGui baru)
-- ---------------------------------------------------------------------
local function ivNew(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if o:IsA("GuiObject") then o.ZIndex = IV.Z + (props.ZIndex or 0) end
    if parent then o.Parent = parent end
    return o
end

-- Gambar item = potongan 32x32 dari atlas rbxassetid milik game (Assets.Atlas)
local function ivIcon(parent, id, size, pos)
    local it = IV.DB and IV.DB[id]
    if not it then return end
    local sheet = IV.Assets and IV.Assets.Atlas and it.atlas and IV.Assets.Atlas[it.atlas]
    if sheet then
        local cx, cy = it.tx or 0, it.ty or 0
        if IV.Autotile then
            local ok, a, b = pcall(IV.Autotile.aloneCell, it)
            if ok and a then cx, cy = a, b end
        end
        if it.slot == "feet" then cy = cy * 2 end
        local frame = ivNew("Frame", {
            BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos, ZIndex = 2,
        }, parent)
        ivNew("ImageLabel", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2,
            Image = sheet, ImageRectSize = Vector2.new(32, 32),
            ImageRectOffset = Vector2.new(cx * 32, cy * 32),
            ImageColor3 = it.tint or Color3.new(1, 1, 1),
            ResampleMode = Enum.ResamplerMode.Pixelated,
        }, frame)
        local oc = it.overCell
        if oc then
            ivNew("ImageLabel", {
                BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3,
                Image = sheet, ImageRectSize = Vector2.new(32, 32),
                ImageRectOffset = Vector2.new(oc[1] * 32, oc[2] * 32),
                ResampleMode = Enum.ResamplerMode.Pixelated,
            }, frame)
        end
        return
    end
    -- cadangan: ItemIcon bawaan game
    if IV.IconMod then
        local okN, icon = pcall(IV.IconMod.new, parent, UDim2.fromOffset(size, size), IV.Z + 2)
        if okN and icon then
            icon.frame.Position = pos
            pcall(IV.IconMod.set, icon, id)
        end
    end
end

local function ivInfoUpdate()
    if not IV.InfoLbl then return end
    local id = IV.Selected
    local it = id and IV.DB and IV.DB[id]
    if not it then
        IV.InfoLbl.Text = "Belum ada item dipilih. Tap 1x pilih, tap 2x pakai / lepas"
        if IV.InfoBtn then IV.InfoBtn.Text = "-" end
        return
    end
    local worn = IV.Worn and IV.Worn[it.slot] == id
    IV.InfoLbl.Text = it.name .. "   |   ID " .. id .. "   |   " .. ivSlotLabel(it.slot)
    if IV.InfoBtn then IV.InfoBtn.Text = worn and "LEPAS" or "PAKAI" end
end

local function ivRefreshMarks()
    local W = IV.Worn or {}
    for id, c in pairs(IV.Cells) do
        local worn = (W[c.slot] == id)
        local isVis = worn and IV.Ov[c.slot] ~= nil
        if worn then
            c.stroke.Color = isVis and IV_C.vis or IV_C.worn
            c.stroke.Thickness = 2
            c.stroke.Enabled = true
        elseif IV.Selected == id then
            c.stroke.Color = IV_C.pick
            c.stroke.Thickness = 2
            c.stroke.Enabled = true
        else
            c.stroke.Enabled = false
        end
        c.mark.Text = worn and (isVis and "VISUAL" or "DIPAKAI") or ""
        c.mark.TextColor3 = isVis and IV_C.vis or IV_C.worn
    end
    ivInfoUpdate()
end

local function ivTap(id)
    local now = os.clock()
    IV.Selected = id
    if IV.TapId == id and now - IV.TapAt < 0.45 then
        IV.TapId = nil
        ivToggleItem(id) -- tap 2x = pakai / lepas
    else
        IV.TapId, IV.TapAt = id, now
    end
    ivRefreshMarks()
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
            LayoutOrder = i, Size = UDim2.fromOffset(60, 62), Text = "",
            BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, AutoButtonColor = true,
        }, IV.WornScroll)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
        ivNew("UIStroke", {
            Color = IV.Ov[s] and IV_C.vis or IV_C.line, Thickness = IV.Ov[s] and 2 or 1,
        }, btn)
        ivIcon(btn, id, 36, UDim2.new(0.5, -18, 0, 3))
        ivNew("TextLabel", {
            Position = UDim2.new(0, 0, 1, -18), Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1, Text = ivSlotLabel(s), TextSize = 11, ZIndex = 3,
            Font = Enum.Font.Gotham, TextColor3 = IV_C.sub,
        }, btn)
        btn.Activated:Connect(function() ivTap(id) end)
    end
end

local function ivRenderMore()
    if not IV.Grid then return end
    local W = IV.Worn or {}
    local last = math.min(IV.Rendered + IV_PAGE, #IV.List)
    for i = IV.Rendered + 1, last do
        local e = IV.List[i]
        local btn = ivNew("TextButton", {
            Name = "Item" .. e.id, LayoutOrder = i, Text = "", Size = UDim2.new(1, -6, 0, 56),
            BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, AutoButtonColor = true,
        }, IV.Grid)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
        local stroke = ivNew("UIStroke", {
            Color = IV_C.worn, Thickness = 2, Enabled = (W[e.slot] == e.id),
        }, btn)
        ivIcon(btn, e.id, 44, UDim2.fromOffset(6, 6))
        ivNew("TextLabel", {
            Position = UDim2.fromOffset(58, 6), Size = UDim2.new(1, -136, 0, 22),
            BackgroundTransparency = 1, Text = e.name, TextSize = 14, ZIndex = 3,
            TextTruncate = Enum.TextTruncate.AtEnd, Font = Enum.Font.GothamMedium,
            TextColor3 = IV_C.text, TextXAlignment = Enum.TextXAlignment.Left,
        }, btn)
        ivNew("TextLabel", {
            Position = UDim2.fromOffset(58, 29), Size = UDim2.new(1, -136, 0, 18),
            BackgroundTransparency = 1, TextSize = 12, ZIndex = 3,
            Text = "ID " .. e.id .. "  |  " .. ivSlotLabel(e.slot) .. (e.fx and "  |  efek" or ""),
            TextTruncate = Enum.TextTruncate.AtEnd, Font = Enum.Font.Gotham,
            TextColor3 = IV_C.sub, TextXAlignment = Enum.TextXAlignment.Left,
        }, btn)
        local mark = ivNew("TextLabel", {
            Position = UDim2.new(1, -74, 0, 0), Size = UDim2.new(0, 68, 1, 0),
            BackgroundTransparency = 1, Text = "", TextSize = 11, ZIndex = 3,
            Font = Enum.Font.GothamMedium, TextColor3 = IV_C.worn,
            TextXAlignment = Enum.TextXAlignment.Right,
        }, btn)
        btn.Activated:Connect(function() ivTap(e.id) end)
        IV.Cells[e.id] = { btn = btn, stroke = stroke, mark = mark, slot = e.slot }
    end
    IV.Rendered = last
    ivRefreshMarks()
end

local function ivRefilter()
    if not IV.Grid then return end
    local q = IV.Query:lower()
    local f = IV.Filter
    local W = IV.Worn or {}
    local list = {}
    for _, e in ipairs(IV.Items) do
        local pass
        if f == "Semua" then pass = true
        elseif f == "Dipakai" then pass = (W[e.slot] == e.id)
        elseif f == "Efek" then pass = e.fx
        else pass = (e.slot == f) end
        if pass and (q == "" or e.lname:find(q, 1, true) or e.lslot:find(q, 1, true)
            or tostring(e.id):find(q, 1, true)) then
            list[#list + 1] = e
        end
    end
    IV.List = list
    for _, c in pairs(IV.Cells) do c.btn:Destroy() end
    IV.Cells, IV.Rendered = {}, 0
    ivRenderMore()
    IV.Grid.CanvasPosition = Vector2.zero
    if IV.CountLbl then
        IV.CountLbl.Text = #list .. " item  |  tap 1x pilih, tap 2x pakai / lepas"
    end
end

local function ivStyleChips()
    for key, b in pairs(IV.ChipBtns) do
        local on = (key == IV.Filter)
        b.BackgroundColor3 = on and IV_C.btnOn or IV_C.btn
        b.TextColor3 = on and Color3.new(1, 1, 1) or IV_C.sub
    end
end

-- Cari tempat di dalam menu utama untuk menaruh panel. Kartu dibuat dengan
-- subtitle penanda; setelah ditemukan teksnya diganti dan label disimpan
-- supaya START berikutnya tetap menemukan tempat yang sama.
local function ivFindHost()
    local function hostFrom(label)
        -- 1) kolom berisi kartu-kartu: ScrollingFrame / frame ber-UIListLayout terdekat
        local s = label:FindFirstAncestorWhichIsA("ScrollingFrame")
        if s then
            if s:FindFirstChildOfClass("UIListLayout") then return s end
            for _, ch in ipairs(s:GetChildren()) do
                if ch:IsA("GuiObject") and ch:FindFirstChildOfClass("UIListLayout") then return ch end
            end
        end
        -- 2) naik sampai ketemu daftar lebar
        local p = label.Parent
        while p and not p:IsA("LayerCollector") do
            if p:FindFirstChildOfClass("UIListLayout") and #p:GetChildren() >= 3
                and p.AbsoluteSize.X > 300 then
                return p
            end
            p = p.Parent
        end
        return nil
    end

    if IV.HostLabel and IV.HostLabel.Parent then
        local h = hostFrom(IV.HostLabel)
        if h then return h end
    end

    local containers = {}
    pcall(function() if type(gethui) == "function" then containers[#containers + 1] = gethui() end end)
    pcall(function() containers[#containers + 1] = game:GetService("CoreGui") end)
    pcall(function() containers[#containers + 1] = LocalPlayer:FindFirstChild("PlayerGui") end)
    for _, c in ipairs(containers) do
        if c then
            for _, d in ipairs(c:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton"))
                    and (d.Text:find(IV_HOST_TAG, 1, true) or d.Text == IV_HOST_DONE) then
                    pcall(function() d.Text = IV_HOST_DONE end)
                    IV.HostLabel = d
                    local h = hostFrom(d)
                    if h then return h end
                end
            end
        end
    end
    return nil
end

local function ivZBase(host)
    local layer = host:FindFirstAncestorWhichIsA("LayerCollector")
    if layer and layer:IsA("ScreenGui") and layer.ZIndexBehavior == Enum.ZIndexBehavior.Global then
        local m = 1
        for _, d in ipairs(layer:GetDescendants()) do
            if d:IsA("GuiObject") and d.ZIndex > m then m = d.ZIndex end
        end
        return m + 1
    end
    return 1
end

local function ivBuildGui(host)
    IV.Z = ivZBase(host)

    local main = ivNew("Frame", {
        Name = "R8DV_ItemVisualPanel", Size = UDim2.new(1, 0, 0, 600),
        LayoutOrder = 100000, BackgroundColor3 = IV_C.bg, BorderSizePixel = 0,
    }, host)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 8) }, main)
    ivNew("UIStroke", { Color = IV_C.line, Thickness = 1 }, main)
    IV.Main = main

    ivNew("TextLabel", {
        Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 4),
        BackgroundTransparency = 1, Text = "ITEM VISUAL  (client only)",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, main)

    -- baris: item yang dipakai sekarang (scroll horizontal)
    ivNew("TextLabel", {
        Position = UDim2.fromOffset(10, 34), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = "Dipakai sekarang  (garis biru = visual, tap 2x = lepas)",
        TextColor3 = IV_C.sub, Font = Enum.Font.Gotham, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, main)
    local wornScroll = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 52), Size = UDim2.new(1, -20, 0, 70),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.X, ZIndex = 2,
    }, main)
    ivNew("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, wornScroll)
    IV.WornScroll = wornScroll

    -- pencarian
    local search = ivNew("TextBox", {
        Position = UDim2.fromOffset(10, 128), Size = UDim2.new(1, -20, 0, 30),
        BackgroundColor3 = IV_C.cell, BorderSizePixel = 0, Text = "",
        PlaceholderText = "Cari nama / ID / slot (head, mask, hair...)", PlaceholderColor3 = IV_C.sub,
        TextColor3 = IV_C.text, Font = Enum.Font.Gotham, TextSize = 13,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, search)
    ivNew("UIPadding", { PaddingLeft = UDim.new(0, 8) }, search)
    IV.Search = search

    -- filter slot (scroll horizontal): Semua | Dipakai | Efek | Head | Mask | ...
    local chipRow = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 164), Size = UDim2.new(1, -20, 0, 32),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
        AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.X, ZIndex = 2,
    }, main)
    ivNew("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center,
    }, chipRow)
    IV.ChipRow, IV.ChipBtns = chipRow, {}

    local function addChip(key, label, order)
        local b = ivNew("TextButton", {
            LayoutOrder = order, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = label,
            TextColor3 = IV_C.sub, Font = Enum.Font.GothamMedium, TextSize = 12, ZIndex = 2,
        }, chipRow)
        ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        ivNew("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, b)
        b.Activated:Connect(function()
            IV.Filter = key
            ivStyleChips()
            ivRefilter()
        end)
        IV.ChipBtns[key] = b
    end
    addChip("Semua", "Semua", 1)
    addChip("Dipakai", "Dipakai", 2)
    addChip("Efek", "Efek", 3)
    for i, s in ipairs(IV.Slots) do addChip(s, ivSlotLabel(s), 3 + i) end
    ivStyleChips()

    local countLbl = ivNew("TextLabel", {
        Position = UDim2.fromOffset(10, 200), Size = UDim2.new(1, -20, 0, 16),
        BackgroundTransparency = 1, Text = "", TextColor3 = IV_C.sub,
        Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, main)
    IV.CountLbl = countLbl

    -- daftar kartu item (scroll vertikal)
    local grid = ivNew("ScrollingFrame", {
        Position = UDim2.fromOffset(10, 220), Size = UDim2.new(1, -20, 1, -330),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
        ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2,
    }, main)
    ivNew("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
    IV.Grid = grid

    -- info item terpilih + tombol pakai / lepas
    local infoLbl = ivNew("TextLabel", {
        Position = UDim2.new(0, 10, 1, -104), Size = UDim2.new(1, -110, 0, 30),
        BackgroundTransparency = 1, Text = "", TextColor3 = IV_C.text,
        Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, main)
    IV.InfoLbl = infoLbl
    local infoBtn = ivNew("TextButton", {
        Position = UDim2.new(1, -94, 1, -104), Size = UDim2.fromOffset(84, 30),
        BackgroundColor3 = IV_C.btnOn, BorderSizePixel = 0, Text = "-",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 13, ZIndex = 2,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, infoBtn)
    IV.InfoBtn = infoBtn
    infoBtn.Activated:Connect(function()
        if IV.Selected then
            ivToggleItem(IV.Selected)
            ivRefreshMarks()
        end
    end)

    -- shortcut: UNWEAR ALL dan RESET
    local unwearBtn = ivNew("TextButton", {
        Position = UDim2.new(0, 10, 1, -66), Size = UDim2.new(0.5, -14, 0, 32),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = "UNWEAR ALL (lepas semua)",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 12, ZIndex = 2,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, unwearBtn)
    unwearBtn.Activated:Connect(function()
        ivUnwearAll()
        ivRefreshMarks()
    end)
    local resetBtn = ivNew("TextButton", {
        Position = UDim2.new(0.5, 4, 1, -66), Size = UDim2.new(0.5, -14, 0, 32),
        BackgroundColor3 = IV_C.btn, BorderSizePixel = 0, Text = "RESET (balik ke pakaian asli)",
        TextColor3 = IV_C.text, Font = Enum.Font.GothamMedium, TextSize = 12, ZIndex = 2,
    }, main)
    ivNew("UICorner", { CornerRadius = UDim.new(0, 6) }, resetBtn)
    resetBtn.Activated:Connect(function()
        ivResetAll()
        ivRefreshMarks()
    end)
    ivNew("TextLabel", {
        Position = UDim2.new(0, 10, 1, -30), Size = UDim2.new(1, -20, 0, 24),
        BackgroundTransparency = 1, TextColor3 = IV_C.sub, Font = Enum.Font.Gotham, TextSize = 11,
        Text = "Hanya terlihat di layarmu. Pakaian visual tidak dikirim ke server.",
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
    }, main)

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
    local host = ivFindHost()
    if not host then
        ivUnhook()
        warn("[R&8_DV] Item Visual dibatalkan: tempat panel di menu utama tidak ditemukan (tidak membuat GUI baru)")
        return false
    end
    if not (IV.Game and type(IV.Game.refresh) == "function") then
        warn("[R&8_DV] Peringatan: Game.refresh tidak ditemukan, karakter mungkin tidak tergambar ulang")
    end
    IV.Worn = worn
    IV.Ov = {}
    IV.Selected, IV.TapId, IV.Filter, IV.Query = nil, nil, "Semua", ""
    IV.Active = true
    IV.Run += 1
    local run = IV.Run
    ivBuildGui(host)
    if Light.On then task.defer(lightEnable) end
    task.spawn(function()
        while IV.Active and IV.Run == run do
            ivKeepAlive()
            pcall(ivRebuildWorn)
            pcall(ivRefreshMarks)
            task.wait(0.25)
        end
    end)
    print("[R&8_DV] Item Visual START (client only), " .. #IV.Items .. " item pakaian, panel di menu utama")
    return true
end

local function ivStop()
    IV.Active = false
    IV.Run += 1
    if IV.Worn then pcall(ivResetAll) end
    ivUnhook()
    for _, c in ipairs(IV.Conns) do pcall(function() c:Disconnect() end) end
    IV.Conns = {}
    if IV.Main then pcall(function() IV.Main:Destroy() end) end
    IV.Main, IV.Grid, IV.WornScroll, IV.ChipRow = nil, nil, nil, nil
    IV.Cells, IV.WornSig, IV.Ov, IV.ChipBtns = {}, "", {}, {}
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
        end)
        ThemeCard:Dropdown("Checkbox Style", "CheckboxStyleMode", { "Modern", "Checkbox" }, "Modern", function(mode)
            if UI.SetCheckboxStyle then UI:SetCheckboxStyle(mode) end
        end)
    end)
})

-- =========================================================================
-- KATEGORI 2: SET VISUAL NAME + ROLE
-- =========================================================================
if UI.Category then UI:Category("Visual Name") end

feature("Name", "Set Visual Name")({
    center = center(function(c)
        c:Header("Set Visual Name", "Ubah nama, warna, title, dan role di dalam game (bukan nama Roblox)", "Client")

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

        local RoleCard = c:Card("Role (visual)", nil, "Shield", {
            Subtitle = "Ikut tombol START yang sama. /help memakai panel asli game, isinya diganti sesuai role"
        })
        RoleCard:Dropdown("Role", "VN_Role", VN_ROLE_LIST, "(tidak diubah)")
        RoleCard:Input("Command Moderator", "RC_ModCmds", "pisahkan dengan spasi", "mute unmute tape untape warn tp bring")
        RoleCard:Input("Command Developer", "RC_DevCmds", "pisahkan dengan spasi", "give spawn clear setrank")
    end),

    right = right(function(r)
        local CtrlCard = r:Card("Kontrol", nil, "Bolt", {
            Subtitle = "Satu tombol: START menerapkan, STOP mengembalikan nama & role asli"
        })
        VN.Toggle.Button = CtrlCard:Button("Visual Name", "START", "Bolt", function()
            VN.Toggle.Toggle()
        end)

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Hanya terlihat di layarmu. Command staff yang diketik hanya tampil visual, tidak dikirim ke server"
        })
    end)
})

-- =========================================================================
-- KATEGORI 3: ITEM VISUAL
-- =========================================================================
if UI.Category then UI:Category("Item Visual") end

feature("Item", "Item Visual")({
    center = center(function(c)
        c:Header("Item Visual", "Pakai baju & aksesori di layarmu, lengkap dengan efeknya (tanpa block dan seed)", "Client")

        c:StatRow({
            { Icon = "Bolt",   Label = "Mode",         Value = "Client" },
            { Icon = "Shield", Label = "Kirim server", Value = "Diblokir" },
            { Icon = "Check",  Label = "Efek",         Value = "Aktif" }
        })

        -- subtitle berisi penanda; setelah START teksnya diganti otomatis
        local PanelCard = c:Card("Panel Item Visual", nil, "Palette", {
            Subtitle = IV_HOST_TAG
        })
        IV.Toggle.Button = PanelCard:Button("Item Visual", "START", "Bolt", function()
            IV.Toggle.Toggle()
        end)
        -- shortcut langsung dari kartu (tanpa harus scroll ke panel)
        PanelCard:Button("Unwear All (lepas semua item)", "UNWEAR", "Check", function()
            if IV.Active then ivUnwearAll(); ivRefreshMarks() end
        end)
        PanelCard:Button("Reset ke pakaian asli", "RESET", "Check", function()
            if IV.Active then ivResetAll(); ivRefreshMarks() end
        end)
    end),

    right = right(function(r)
        local HowCard = r:Card("Cara Pakai", nil, "Clock", {
            Subtitle = "Panel muncul di bawah kartu Item Visual (di dalam menu ini, tanpa GUI baru)"
        })
        HowCard:ActivityTimeline({
            { Text = "Cari nama, ID, atau slot (head / mask / hair) di kolom search", Time = "1" },
            { Text = "Chip filter: Semua, Dipakai, Efek, Head, Mask, Hair, Shirt, Pants, Feet, Hand, Back", Time = "2" },
            { Text = "Tap item 1x = pilih, tap 2x = pakai / lepas (atau tombol PAKAI / LEPAS)", Time = "3" },
            { Text = "Baris atas = item yang sedang dipakai (garis biru = visual), tap 2x = lepas", Time = "4" },
            { Text = "UNWEAR ALL = lepas semua, RESET = balik ke pakaian asli", Time = "5" }
        })

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Efek jalan di karakter client lewat game sendiri. Server tidak menerima pakaian visual, pemain lain tidak melihatnya"
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
