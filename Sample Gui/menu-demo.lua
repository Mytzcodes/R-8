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
-- LOGIKA SET VISUAL NAME (nama di dalam game, BUKAN nama Roblox)
-- Method 1 CLIENT : ubah attribute milik LocalPlayer (hanya terlihat di layar sendiri)
-- Method 2 SERVER : panggil Net.call milik game (RenameName/ChooseName/PickTitle),
--                   divalidasi server sehingga terlihat semua pemain
-- Sumber di game: Shared.Roles (nameOf -> Nick, titleOf -> WornTitle),
--                 Others/Game (warna nama -> DiscordColor), NameUI, WorldMenu
-- =========================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VN = {
    Orig = nil,      -- attribute asli (disimpan sekali sebelum apply pertama)
    Applied = false,
    Want = {},       -- attribute yang sedang kita paksa
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
-- title yang bisa dipilih lewat server (PickTitle) = hanya yang kamu miliki
local VN_SERVER_TITLE_LIST = {
    "Tanpa Title", "Content Creator", "Sponsor", "Supporter",
    "Patron", "Benefactor", "Royal", "Dr."
}

local function vnTrim(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

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

-- ----------------------------- METHOD 1: CLIENT -----------------------------
local function vnApplyClient()
    if not LocalPlayer then return end

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
    VN.Applied = true
    print("[R&8_DV] Visual name (client) diterapkan")
end

local function vnRestoreClient()
    if not LocalPlayer or not VN.Orig then return end
    for _, a in ipairs(VN_ATTRS) do
        local o = VN.Orig[a]
        if o then pcall(function() LocalPlayer:SetAttribute(a, o.v) end) end
    end
    VN.Want = {}
    VN.Applied = false
    print("[R&8_DV] Visual name dikembalikan ke asli")
end

-- Kunci: kalau server menimpa attribute (mis. ganti title), pasang ulang
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

-- ----------------------------- METHOD 2: SERVER -----------------------------
-- Memakai jalur resmi game (sama seperti NameUI / Birth Certificate / WorldMenu).
-- Server yang memvalidasi: nama 3-18 huruf+angka & unik, item Birth Certificate,
-- cooldown 60 hari, title harus yang kamu miliki.
local function vnGetNetCall()
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("Shared", 5):WaitForChild("Net", 5))
    end)
    if ok and type(mod) == "table" and type(mod.call) == "function" then
        return mod.call
    end
    return nil
end

local function vnServerCall(callName, ...)
    local call = vnGetNetCall()
    if not call then
        warn("[R&8_DV] Net.call tidak ditemukan (Shared.Net)")
        return false
    end
    local ok, success, msg = pcall(call, callName, ...)
    if not ok then
        warn("[R&8_DV] " .. callName .. " error: " .. tostring(success))
        return false
    end
    print("[R&8_DV] " .. callName .. " ->", tostring(success), tostring(msg or ""))
    return success == true or success == nil, msg
end

local function vnServerRename()
    local name = vnTrim(getValue("VN_ServerName", ""))
    if #name < 3 or #name > 18 or not name:match("^%w+$") then
        warn("[R&8_DV] Nama server harus 3-18 huruf/angka tanpa spasi atau simbol")
        return
    end
    if not getValue("VN_Confirm", false) then
        warn("[R&8_DV] Centang konfirmasi dulu (memakai 1 Birth Certificate, ganti nama lagi baru bisa setelah 60 hari)")
        return
    end
    -- belum pernah pilih nama -> ChooseName, selain itu RenameName
    local needs = LocalPlayer and LocalPlayer:GetAttribute("NeedsName") == true
    vnServerCall(needs and "ChooseName" or "RenameName", name)
end

local function vnServerPickTitle()
    local id = VN_TITLE_ID[getValue("VN_ServerTitle", "Tanpa Title")]
    if not id or id == "legend" then return end
    vnServerCall("PickTitle", id)
end

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
        c:Header("Set Visual Name", "Ubah nama, warna, dan title di dalam game (bukan nama Roblox)", "Visual")

        c:StatRow({
            { Icon = "Bolt",   Label = "Client", Value = "Lokal" },
            { Icon = "Shield", Label = "Server", Value = "Resmi" }
        })

        local ClientCard = c:Card("Method 1: Client", nil, "Palette", {
            Subtitle = "Ubah attribute pemain di sisi client. Hanya terlihat di layarmu sendiri"
        })
        ClientCard:Input("Nama Visual", "VN_Name", "Tulis nama...", "")
        ClientCard:Dropdown("Warna Nama", "VN_ColorPreset", VN_COLOR_LIST, "(tidak diubah)")
        ClientCard:Input("Warna Hex (opsional)", "VN_Hex", "contoh: FF8800", "")
        ClientCard:Dropdown("Title", "VN_Title", VN_TITLE_LIST, "(tidak diubah)")
        ClientCard:Toggle("Izinkan kode warna di nama (`4 `2 dst)", "VN_AllowCodes", false)
        ClientCard:Toggle("Kunci (pasang ulang jika ditimpa server)", "VN_Lock", false)
        ClientCard:Button("Terapkan Client", "APPLY", "Check", function()
            vnApplyClient()
        end)
        ClientCard:Button("Kembalikan Asli", "RESET", "Check", function()
            vnRestoreClient()
        end)
    end),

    -- ----------------------------- KANAN -----------------------------
    right = right(function(r)
        local ServerCard = r:Card("Method 2: Server", nil, "Bolt", {
            Subtitle = "Lewat jalur resmi game (Net.call). Terlihat semua pemain, divalidasi server"
        })
        ServerCard:Input("Nama Baru (3-18 huruf/angka)", "VN_ServerName", "NamaBaru", "")
        ServerCard:Toggle("Saya paham: pakai 1 Birth Certificate & tunggu 60 hari", "VN_Confirm", false)
        ServerCard:Button("Ganti Nama (Server)", "RENAME", "Check", function()
            vnServerRename()
        end)
        ServerCard:Dropdown("Title Dimiliki", "VN_ServerTitle", VN_SERVER_TITLE_LIST, "Tanpa Title")
        ServerCard:Button("Pilih Title (Server)", "PICK", "Check", function()
            vnServerPickTitle()
        end)

        local NoteCard = r:Card("Catatan", nil, "Shield", {
            Subtitle = "Warna & tulisan bebas hanya bisa di Method 1. Server menolak nama duplikat atau title yang tidak dimiliki"
        })
    end)
})

-- =========================================================================
-- KATEGORI 3: SETTINGS
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
