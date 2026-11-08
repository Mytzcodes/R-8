--[[ R&8_DV Debugger Suite (v5.4 Canvas Edition — Delta & PC/Mobile Executor Compatible)
Load:
loadstring(game:HttpGet("https://YOUR_URL/Debugger.lua"))()
Built on R&8_DV ImGui Framework (r&8_dv.lua) 3-Panel Canvas Layout (same UI architecture as SampleGui.lua).
Features: Remote/Packet Spy + live content search, Script/Asset Explorer (Roblox vs Game vs Custom),
Luau decompiler, multi-format codec (Base64/Hex/URL/JSON/XOR), & threaded pure-Luau ZIP archive export. ]]

if getgenv().__SDBG then pcall(function() getgenv().__SDBG.Destroy() end) end
local S = {}
getgenv().__SDBG = S

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function cap(n) return getgenv()[n] or (getfenv and getfenv()[n]) end
local F = {
    writefile = cap("writefile"), readfile = cap("readfile"),
    makefolder = cap("makefolder"), isfolder = cap("isfolder"),
    isfile = cap("isfile"), decompile = cap("decompile"), getscripts = cap("getscripts"),
    getnil = cap("getnilinstances"), getmods = cap("getloadedmodules"),
    hookmm = cap("hookmetamethod"), getnc = cap("getnamecallmethod"),
    checkcaller = cap("checkcaller"), setclip = cap("setclipboard") or cap("toclipboard"),
    getbc = cap("getscriptbytecode"), newcc = cap("newcclosure"), gethui = cap("gethui"),
    getinst = cap("getinstances"), crypt = cap("crypt"), getsenv = cap("getsenv"),
}

-- ============ UTIL ============
local function safe(f, ...) local ok, r = pcall(f, ...) if ok then return r end return nil, r end
local function fullName(i)
    local ok, n = pcall(function() return i:GetFullName() end)
    return ok and n or tostring(i)
end
local function clean(s) return (tostring(s):gsub("[^%w_%-%.]", "_")) end

local function ser(v, d, seen)
    d = d or 0; seen = seen or {}
    local t = typeof(v)
    if t == "string" then return string.format("%q", v)
    elseif t == "number" or t == "boolean" or t == "nil" then return tostring(v)
    elseif t == "buffer" then
        local len = buffer.len(v)
        local lim = math.min(len, 256)
        local bytes, ascii = {}, {}
        for i = 0, lim - 1 do
            local b = buffer.readu8(v, i)
            bytes[#bytes + 1] = string.format("%02X", b)
            ascii[#ascii + 1] = (b >= 32 and b <= 126) and string.char(b) or "."
        end
        return string.format("<buffer len=%d hex=%s%s | ascii=%s>", len, table.concat(bytes, " "), len > lim and " ..." or "", table.concat(ascii))
    elseif t == "Instance" then return "<" .. v.ClassName .. "> " .. fullName(v)
    elseif t == "table" then
        if seen[v] or d > 4 then return "{...}" end
        seen[v] = true
        local out, n = {}, 0
        for k, x in pairs(v) do
            n += 1 if n > 60 then out[#out + 1] = "..." break end
            out[#out + 1] = "[" .. ser(k, d + 1, seen) .. "]=" .. ser(x, d + 1, seen)
        end
        seen[v] = nil
        return "{" .. table.concat(out, ", ") .. "}"
    else return t .. ":" .. tostring(v) end
end
S.ser = ser

-- ============ CODEC (decode/decrypt) ============
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64dec(s)
    s = s:gsub("[^" .. b64chars .. "=]", "")
    return (s:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (b64chars:find(x, 1, true) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end
local function printable(s)
    if #s == 0 then return false end
    local bad = 0
    for i = 1, math.min(#s, 200) do
        local b = s:byte(i)
        if b < 9 or (b > 13 and b < 32) or b > 126 then bad += 1 end
    end
    return bad / math.min(#s, 200) < 0.1
end
local function hexdec(s)
    local h = s:gsub("%s", "")
    if #h % 2 ~= 0 or h:find("[^%x]") then return nil end
    return (h:gsub("%x%x", function(x) return string.char(tonumber(x, 16)) end))
end

-- returns decoded string, method | nil, "encrypted"
function S.decode(s)
    if type(s) ~= "string" then return ser(s), "plain" end
    if printable(s) and not (s:match("^[%w+/=]+$") and #s >= 8) and not (s:match("^[%x]+$") and #s >= 8) then
        return s, "plain"
    end
    local tries = {}
    if s:match("^[%w+/=%s]+$") and #s >= 8 then
        tries[#tries + 1] = {"base64", function() return b64dec(s) end}
        if F.crypt and F.crypt.base64decode then tries[#tries + 1] = {"base64(crypt)", function() return F.crypt.base64decode(s) end} end
    end
    if s:match("^[%x%s]+$") and #s >= 8 then tries[#tries + 1] = {"hex", function() return hexdec(s) end} end
    if s:find("%%%x%x") then tries[#tries + 1] = {"url", function() return HttpService:UrlDecode(s) end} end
    if s:sub(1, 1) == "{" or s:sub(1, 1) == "[" then tries[#tries + 1] = {"json", function() return ser(HttpService:JSONDecode(s)) end} end
    -- single-byte XOR brute force (keys 1..255) accepting printable results
    tries[#tries + 1] = {"xor", function()
        for k = 1, 255 do
            local o = {}
            for i = 1, math.min(#s, 64) do o[i] = string.char(bit32.bxor(s:byte(i), k)) end
            if printable(table.concat(o)) then
                local full = {}
                for i = 1, #s do full[i] = string.char(bit32.bxor(s:byte(i), k)) end
                return table.concat(full), k
            end
        end
    end}
    for _, t in ipairs(tries) do
        local ok, r, extra = pcall(t[2])
        if ok and type(r) == "string" and printable(r) then
            local name = t[1] .. (extra and (" key=" .. tostring(extra)) or "")
            -- nested one more level
            if t[1] ~= "plain" and (r:match("^[%w+/=]+$") and #r >= 8) then
                local r2, m2 = S.decode(r)
                if m2 ~= "encrypted" then return r2, name .. ">" .. m2 end
            end
            return r, name
        end
    end
    return nil, "encrypted"
end

-- ============ SAVE (threaded, no crash) ============
local ROOT = "SampleDebugger"
S.Saved = {}
local function ensure(p)
    if F.makefolder and F.isfolder and not F.isfolder(p) then pcall(F.makefolder, p) end
end
function S.write(rel, data, cb)
    task.spawn(function()
        local ok, err = pcall(function()
            assert(F.writefile, "writefile unsupported")
            ensure(ROOT)
            local parts, path = rel:split("/"), ROOT
            for i = 1, #parts - 1 do path = path .. "/" .. parts[i] ensure(path) end
            path = path .. "/" .. parts[#parts]
            F.writefile(path, data)
            S.Saved[#S.Saved + 1] = path
            if cb then cb(true, path) end
        end)
        if not ok and cb then cb(false, tostring(err)) end
    end)
end

-- Classify script source: "Roblox" (core), "Game" (map/in-game), "Custom" (nil/unparented/executor-made)
function S.classify(inst)
    local fn = fullName(inst)
    local ok, inCore = pcall(function() return inst:IsDescendantOf(CoreGui) end)
    if ok and inCore then return "Roblox" end
    if fn:find("^CorePackages") or fn:find("^CoreGui") or fn:find("RobloxGui") then return "Roblox" end
    local names = {PlayerScripts=1, RbxCharacterSounds=1, PlayerModule=1, ControlModule=1, CameraModule=1, Animate=1, Health=1, Sound=1}
    if names[inst.Name] and (fn:find("PlayerScripts") or fn:find("^Workspace%.[^%.]+%.")) then return "Roblox" end
    if not inst.Parent then return "Custom" end
    return "Game"
end

-- ============ PACKET SPY ============
-- Buffer -> readable info: u8 list, embedded ASCII strings (len>=3), try string decode
-- Parser heuristik untuk buffer custom (Blink/Zap/ByteNet/serializer sendiri):
-- u16 LE length + string ASCII -> str, 8 byte yang valid sbg double -> f64, sisanya u8 mentah.
local function parseBufferLayout(buf, maxItems)
    local len = buffer.len(buf)
    local items, raw, rawStart = {}, {}, 0
    local i = 0
    local function flush()
        if #raw > 0 then
            items[#items + 1] = ("+0x%02X raw[%d]: %s"):format(rawStart, #raw, table.concat(raw, " "))
            raw = {}
        end
    end
    while i < len and #items < (maxItems or 80) do
        local matched = false
        -- length-prefixed string (u16 LE)
        if i + 2 <= len then
            local n = buffer.readu16(buf, i)
            if n >= 2 and n <= 512 and i + 2 + n <= len then
                local ok = true
                local chars = table.create(n)
                for k = 0, n - 1 do
                    local c = buffer.readu8(buf, i + 2 + k)
                    if c < 32 or c > 126 then ok = false break end
                    chars[k + 1] = string.char(c)
                end
                if ok then
                    flush()
                    items[#items + 1] = ("+0x%02X str(%d) \"%s\""):format(i, n, table.concat(chars))
                    i += 2 + n
                    matched = true
                end
            end
        end
        -- f64 (byte tertinggi harus eksponen wajar, nilai bukan nol)
        if not matched and i + 8 <= len then
            local top = buffer.readu8(buf, i + 7)
            if top == 0x3F or top == 0x40 or top == 0x41 or top == 0x42 or top == 0xBF or top == 0xC0 or top == 0xC1 or top == 0xC2 then
                local okF, v = pcall(buffer.readf64, buf, i)
                if okF and v == v and math.abs(v) >= 0.001 and math.abs(v) < 1e15 then
                    flush()
                    items[#items + 1] = ("+0x%02X f64 %s"):format(i, (v == math.floor(v)) and string.format("%d", v) or tostring(v))
                    i += 8
                    matched = true
                end
            end
        end
        if not matched then
            if #raw == 0 then rawStart = i end
            raw[#raw + 1] = string.format("%02X", buffer.readu8(buf, i))
            i += 1
            if #raw >= 16 then flush() end
        end
    end
    flush()
    if i < len then items[#items + 1] = ("... (%d byte lagi tidak diparse)"):format(len - i) end
    return items
end
S.parseBufferLayout = parseBufferLayout

function S.bufferInfo(buf)
    local len = buffer.len(buf)
    local okS, str = pcall(buffer.tostring, buf)
    if not okS then return nil, "buffer" end
    local runs, cur = {}, {}
    local function flush()
        if #cur >= 3 then runs[#runs + 1] = table.concat(cur) end
        cur = {}
    end
    for i = 1, #str do
        local b = str:byte(i)
        if b >= 32 and b <= 126 then cur[#cur + 1] = string.char(b) else flush() end
    end
    flush()
    local out = {("buffer len=%d"):format(len)}
    if #runs > 0 then out[#out + 1] = "strings: " .. table.concat(runs, " | ") end
    local ok1, u8 = pcall(function()
        local t = {}
        for i = 0, math.min(len, 128) - 1 do t[#t + 1] = buffer.readu8(buf, i) end
        return table.concat(t, ",")
    end)
    local okL, layout = pcall(parseBufferLayout, buf, 80)
    if okL and #layout > 0 then out[#out + 1] = "layout (heuristik):\n  " .. table.concat(layout, "\n  ") end
    if ok1 then out[#out + 1] = "u8: " .. u8 .. (len > 128 and ",..." or "") end
    return table.concat(out, "\n"), "buffer"
end

S.Packets = {}
S.MaxPackets = 2000
S.Paused = false
S.IncludeExecutor = true   -- true = also log calls from executor scripts (Infinite Yield etc.)
S.Blocked = {}
S.OnPacket = nil
local counter = 0

-- Auto spam/ping filter: packet identik (remote + method + argumen sama persis) yang berulang
-- (mis. heartbeat "hb" saat player diam) hanya dicatat beberapa kali, sisanya dihitung saja.
S.HideSpam = true
S.SpamThreshold = 3      -- berapa kali boleh tercatat sebelum dianggap spam
S.SpamWindow = 20        -- detik: kalau jeda > window, hitungan di-reset (packet dianggap baru lagi)
S.IgnoreNames = {}       -- [remote.Name] = true, diabaikan manual (tombol Ignore)
S.SpamSeen = {}          -- signature -> {n, last, first}
S.SpamDropped = 0
local function spamSig(dir, remote, method, args)
    local t = {dir, fullName(remote), method}
    for i = 1, args.n do t[#t + 1] = ser(args[i]) end
    return table.concat(t, "\1")
end

S.ShapeSeen = {}
-- "bentuk" packet: angka diabaikan (timestamp/counter berubah-ubah), string pendek & tipe dipakai
local function shapeSig(dir, remote, method, args)
    local t = {dir, fullName(remote), method}
    for i = 1, args.n do
        local v = args[i]
        local ty = typeof(v)
        if ty == "number" then t[#t + 1] = "#"
        elseif ty == "string" then t[#t + 1] = (#v <= 32) and v or "str"
        elseif ty == "buffer" then t[#t + 1] = "buf" .. buffer.len(v)
        else t[#t + 1] = ty end
    end
    return table.concat(t, "\1")
end
-- true jika packet ini bagian dari ping periodik (interval teratur) -> di-skip
local function periodicSpam(sig)
    local now = tick()
    local e = S.ShapeSeen[sig]
    if not e or now - e.last > 30 then
        e = {last = now, iv = {}, pk = nil, spam = false}
        S.ShapeSeen[sig] = e
        S._curShape = e
        return false
    end
    local gap = now - e.last
    e.last = now
    table.insert(e.iv, gap)
    if #e.iv > 5 then table.remove(e.iv, 1) end
    local sum = 0
    for _, g in ipairs(e.iv) do sum += g end
    local mean = sum / #e.iv
    if e.spam then
        -- masih ping selama jedanya mirip rata-rata; kalau tidak, bukan ping lagi
        if math.abs(gap - mean) <= mean * 0.5 then
            if e.pk then e.pk.repeats = (e.pk.repeats or 0) + 1 end
            return true
        end
        e.spam, e.iv = false, {gap}
        S._curShape = e
        return false
    end
    if #e.iv >= 4 and mean >= 0.4 then
        local regular = true
        for _, g in ipairs(e.iv) do if math.abs(g - mean) > mean * 0.25 then regular = false break end end
        if regular then
            e.spam = true
            if e.pk then e.pk.repeats = (e.pk.repeats or 0) + 1 end
            return true
        end
    end
    S._curShape = e
    return false
end

local function record(dir, remote, method, args, caller)
    if S.Paused or S.Blocked[remote] or S.IgnoreNames[remote.Name] then return end
    S._curShape = nil
    if S.HideSpam then
        local okS, shape = pcall(shapeSig, dir, remote, method, args)
        if okS and periodicSpam(shape) then S.SpamDropped += 1 return end
        local ok, sig = pcall(spamSig, dir, remote, method, args)
        if ok then
            local now = tick()
            local e = S.SpamSeen[sig]
            if e and now - e.last > S.SpamWindow then e = nil end
            if not e then
                e = {n = 0, last = now, pk = nil}
                S.SpamSeen[sig] = e
            end
            e.n += 1
            e.last = now
            if e.n > S.SpamThreshold then
                S.SpamDropped += 1
                if e.pk then e.pk.repeats = (e.pk.repeats or 0) + 1 end
                return
            end
            S._curSpam = e
        end
    end
    counter += 1
    local parts = {}
    for i = 1, args.n do
        local raw = args[i]
        local dec, how = nil, nil
        if type(raw) == "string" then dec, how = S.decode(raw)
        elseif typeof(raw) == "buffer" then dec, how = S.bufferInfo(raw) end
        parts[#parts + 1] = {raw = raw, text = ser(raw), decoded = dec, how = how}
    end
    local pk = {
        id = counter, time = os.date("%H:%M:%S"), dir = dir, remote = remote,
        name = remote.Name, path = fullName(remote), class = remote.ClassName,
        method = method, args = parts, caller = caller,
    }
    local blob = {pk.dir, pk.name, pk.path, pk.method}
    for _, p in ipairs(parts) do blob[#blob + 1] = p.text if p.decoded then blob[#blob + 1] = p.decoded end end
    pk.search = table.concat(blob, " "):lower()
    if S._curSpam then S._curSpam.pk = pk S._curSpam = nil end
    if S._curShape then S._curShape.pk = pk S._curShape = nil end
    table.insert(S.Packets, pk)
    if #S.Packets > S.MaxPackets then table.remove(S.Packets, 1) end
    if S.OnPacket then task.defer(S.OnPacket, pk) end
end

local remoteMethods = {FireServer = true, InvokeServer = true}
local oldNC
local hooked = false
if F.hookmm and F.getnc then
    pcall(function()
        local handler = function(self, ...)
            local m = F.getnc()
            if remoteMethods[m] and typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
                local mine = F.checkcaller and F.checkcaller()
                if S.IncludeExecutor or not mine then
                    local args = table.pack(...)
                    task.defer(record, "OUT", self, m, args, mine and "executor" or "game")
                end
            end
            return oldNC(self, ...)
        end
        oldNC = F.hookmm(game, "__namecall", F.newcc and F.newcc(handler) or handler)
        hooked = true
    end)
    -- dot-call: Remote.FireServer(Remote, ...) goes through __index
    pcall(function()
        local oldIdx
        local idxHandler = function(self, key)
            local v = oldIdx(self, key)
            if remoteMethods[key] and typeof(self) == "Instance" and type(v) == "function" and (self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction") then
                local mine = F.checkcaller and F.checkcaller()
                if S.IncludeExecutor or not mine then
                    local w = function(s, ...)
                        task.defer(record, "OUT", s, key, table.pack(...), (mine and "executor" or "game") .. " (dot-call)")
                        return v(s, ...)
                    end
                    return F.newcc and F.newcc(w) or w
                end
            end
            return v
        end
        oldIdx = F.hookmm(game, "__index", F.newcc and F.newcc(idxHandler) or idxHandler)
        S.HookedIndex = true
    end)
    -- RemoteFunction.OnClientInvoke (server -> client): wrap callback when game assigns it
    pcall(function()
        local oldNew
        local nh = function(self, key, value)
            if key == "OnClientInvoke" and type(value) == "function" and typeof(self) == "Instance" and self.ClassName == "RemoteFunction" then
                local orig = value
                value = function(...)
                    task.defer(record, "IN", self, "OnClientInvoke", table.pack(...), "server")
                    return orig(...)
                end
            end
            return oldNew(self, key, value)
        end
        oldNew = F.hookmm(game, "__newindex", F.newcc and F.newcc(nh) or nh)
        S.HookedNewIndex = true
    end)
end
S.Hooked = hooked

-- incoming packets (server -> client)
local watched = {}
local function watch(r)
    if watched[r] or not (r:IsA("RemoteEvent") or r.ClassName == "UnreliableRemoteEvent") then return end
    watched[r] = r.OnClientEvent:Connect(function(...)
        record("IN", r, "OnClientEvent", table.pack(...), "server")
    end)
end
local wrappedRF = {}
local function wrapRF(r)
    if wrappedRF[r] or not r:IsA("RemoteFunction") then return end
    wrappedRF[r] = true
    local gcv = getgenv().getcallbackvalue
    if gcv then
        pcall(function()
            local cur = gcv(r, "OnClientInvoke")
            if type(cur) == "function" then
                r.OnClientInvoke = cur -- goes through hooked __newindex -> wrapped
            end
        end)
    end
end
function S.ScanRemotes()
    local list, seen = {}, {}
    local function consider(d)
        if not seen[d] and typeof(d) == "Instance" and (d.ClassName == "RemoteEvent" or d.ClassName == "RemoteFunction" or d.ClassName == "UnreliableRemoteEvent") then
            seen[d] = true list[#list + 1] = d watch(d) wrapRF(d)
        end
    end
    for _, svc in ipairs(game:GetChildren()) do
        pcall(function() consider(svc) for _, d in ipairs(svc:GetDescendants()) do consider(d) end end)
    end
    if F.getnil then for _, d in ipairs(safe(F.getnil) or {}) do pcall(consider, d) end end
    if F.getinst then for _, d in ipairs(safe(F.getinst) or {}) do pcall(consider, d) end end
    return list
end
S.Conns = {}
S.Conns[#S.Conns + 1] = game.DescendantAdded:Connect(function(d)
    pcall(function() watch(d) wrapRF(d) end)
end)
S.ScanRemotes()

-- Replay a packet
function S.Replay(pk)
    local args = {}
    for i, p in ipairs(pk.args) do args[i] = p.raw end
    local n = #pk.args
    local unpackFn = table.unpack or unpack
    task.spawn(function()
        if pk.method == "FireServer" then pk.remote:FireServer(unpackFn(args, 1, n))
        elseif pk.method == "InvokeServer" then pk.remote:InvokeServer(unpackFn(args, 1, n)) end
    end)
end

function S.PacketText(pk)
    local L = {
        ("[#%d %s] %s %s"):format(pk.id, pk.time, pk.dir, pk.method),
        "Remote: " .. pk.path,
        "Class:  " .. pk.class,
        "Caller: " .. tostring(pk.caller)
    }
    if pk.repeats then L[#L + 1] = ("Repeats (spam disembunyikan): +%d"):format(pk.repeats) end
    for i, p in ipairs(pk.args) do
        L[#L + 1] = ("Arg%d (%s): %s"):format(i, typeof(p.raw), p.text)
        if p.decoded and p.how ~= "plain" then L[#L + 1] = ("   decoded[%s]: %s"):format(p.how, p.decoded)
        elseif p.how == "encrypted" then L[#L + 1] = "   <encrypted/unreadable>" end
    end
    return table.concat(L, "\n")
end

-- Search/filter packets by content (value) e.g. "100", "kill"
function S.Filter(q, dirF)
    q = (q or ""):lower()
    local out = {}
    for _, pk in ipairs(S.Packets) do
        if (not dirF or dirF == "ALL" or pk.dir == dirF) and (q == "" or pk.search:find(q, 1, true)) then
            out[#out + 1] = pk
        end
    end
    return out
end

-- Save packets: decoded successfully -> .txt ; failed decrypt -> .enc (raw kept)
function S.SavePackets(list, cb, progCb)
    list = list or S.Packets
    local snapshot = {table.unpack(list)}
    local notifyProg = progCb or S.OnProgress
    task.spawn(function()
        local total = math.max(#snapshot, 1)
        if notifyProg then notifyProg(5, ("Formatting %d packets..."):format(#snapshot)) end
        local dec, enc = {}, {}
        for i, pk in ipairs(snapshot) do
            local bad = false
            for _, p in ipairs(pk.args) do if p.how == "encrypted" then bad = true end end
            local t = S.PacketText(pk)
            if bad then enc[#enc + 1] = t else dec[#dec + 1] = t end
            if i % 50 == 0 or i == #snapshot then
                local pct = math.floor(10 + (i / total) * 70)
                if notifyProg then notifyProg(pct, ("Formatting packets (%d/%d)..."):format(i, #snapshot)) end
                task.wait()
            end
        end
        local stamp = os.date("%Y%m%d_%H%M%S")
        local sep = "\n" .. ("-"):rep(40) .. "\n"
        local msg = {}
        if notifyProg then notifyProg(88, "Writing packet files to workspace...") end
        if #dec > 0 then S.write("Packets/packets_" .. stamp .. ".txt", table.concat(dec, sep), function(_, p) msg[#msg + 1] = p end) end
        if #enc > 0 then S.write("Packets/packets_" .. stamp .. ".enc", table.concat(enc, sep), function(_, p) msg[#msg + 1] = p end) end
        task.wait(0.3)
        local doneTxt = ("Saved %d ok, %d encrypted | %s"):format(#dec, #enc, table.concat(msg, ", "))
        if notifyProg then notifyProg(100, doneTxt) end
        if cb then cb(doneTxt) end
    end)
end

-- ============ SCRIPT / ASSET DEBUG ============
S.Scripts = {}
S.ScanServices = {
    "ReplicatedStorage", "ReplicatedFirst", "Players", "StarterGui", "StarterPack", "StarterPlayer",
    "Workspace", "Lighting", "SoundService", "Teams", "Chat", "TextChatService", "CollectionService",
    "ContextActionService", "MarketplaceService", "PathfindingService", "PhysicsService",
}
function S.ScanScripts()
    local seen, list = {}, {}
    local function add(i)
        if i and not seen[i] and typeof(i) == "Instance" and i:IsA("LuaSourceContainer") then
            seen[i] = true
            local cat = S.classify(i)
            if cat == "Roblox" then return end -- skip Roblox package scripts entirely
            list[#list + 1] = {inst = i, name = i.Name, class = i.ClassName, path = fullName(i), cat = cat}
        end
    end
    -- only game-side containers (client-visible game scripts), not CoreGui / CorePackages
    for _, name in ipairs(S.ScanServices) do
        local okS, svc = pcall(function() return game:GetService(name) end)
        if okS and svc then
            pcall(function() for _, d in ipairs(svc:GetDescendants()) do add(d) end end)
        end
    end
    -- executor APIs, filtered by classify() (Roblox package dropped)
    if F.getscripts then for _, i in ipairs(safe(F.getscripts) or {}) do pcall(add, i) end end
    if F.getmods then for _, i in ipairs(safe(F.getmods) or {}) do pcall(add, i) end end
    if F.getnil then for _, i in ipairs(safe(F.getnil) or {}) do pcall(add, i) end end
    table.sort(list, function(a, b) if a.cat ~= b.cat then return a.cat < b.cat end return a.path < b.path end)
    S.Scripts = list
    return list
end

local function dumpClosure(fn, depth, out, seen)
    depth = depth or 0 out = out or {} seen = seen or {}
    if seen[fn] or depth > 4 then return out end
    seen[fn] = true
    local pad = ("  "):rep(depth)
    local dbg = debug or {}
    local gc = getgenv().getconstants or dbg.getconstants
    local gp = getgenv().getprotos or dbg.getprotos
    local gi = dbg.getinfo
    local name = "?"
    if gi then local ok, info = pcall(gi, fn) if ok and info then name = tostring(info.name or "anonymous") .. ":" .. tostring(info.linedefined or "?") end end
    out[#out + 1] = pad .. "-- function " .. name
    if gc then
        local ok, cs = pcall(gc, fn)
        if ok and type(cs) == "table" then
            for i, c in pairs(cs) do
                if c ~= nil then out[#out + 1] = pad .. ("  const[%s] = %s"):format(tostring(i), ser(c)) end
            end
        end
    end
    if gp then
        local ok, ps = pcall(gp, fn)
        if ok and type(ps) == "table" then for _, pf in ipairs(ps) do if type(pf) == "function" then dumpClosure(pf, depth + 1, out, seen) end end end
    end
    return out
end

-- Returns: text, how ("decompiled"|"source"|"constants"|"bytecode") or nil, reason
function S.Source(inst)
    local reason = {}
    if F.decompile then
        for attempt = 1, 2 do
            local ok, r = pcall(F.decompile, inst)
            if ok and type(r) == "string" and #r > 0 and not r:find("^%-%-.-[Ff]ailed to decompile") then return r, "decompiled" end
            reason[#reason + 1] = "decompile: " .. tostring(ok and (r == "" and "empty" or r) or r)
            if attempt == 1 then task.wait(0.05) end
        end
    else reason[#reason + 1] = "decompile unsupported" end
    local ok, r = pcall(function() return inst.Source end)
    if ok and r and #r > 0 then return r, "source" end
    -- fallback: dump constants/protos from script closure (readable strings, remotes, names)
    local gsc = getgenv().getscriptclosure
    if gsc then
        local okc, fn = pcall(gsc, inst)
        if okc and type(fn) == "function" then
            local lines = dumpClosure(fn)
            if #lines > 1 then
                return "-- [CONSTANT DUMP] decompile gagal, ini constants & nested function dari bytecode\n" .. table.concat(lines, "\n"), "constants"
            end
        end
    end
    if F.getbc then
        local ok2, bc = pcall(F.getbc, inst)
        if ok2 and bc then return bc, "bytecode" end
        reason[#reason + 1] = "bytecode: " .. tostring(bc)
    end
    return nil, table.concat(reason, " ; ")
end

-- FIX: SaveScripts sekarang SKIP kategori "Roblox" (package dasar Roblox).
-- Hanya simpan "Game" (script map/game) dan "Custom" (nil/executor-made).
-- Bytecode binary (&/00/00...) di-encode ke hex string agar bisa dibaca, bukan raw binary.
local function bytesToHex(s)
    -- Convert binary string ke hex dump yang readable
    local out, lineLen = {}, 0
    out[#out + 1] = "-- [BYTECODE HEX DUMP]\n"
    for i = 1, #s do
        out[#out + 1] = string.format("%02X ", s:byte(i))
        lineLen += 1
        if lineLen >= 16 then
            out[#out + 1] = "\n"
            lineLen = 0
        end
    end
    return table.concat(out)
end

function S.SaveScripts(list, cb, progCb)
    list = list or S.Scripts
    -- FIX: Filter keluar script Roblox sebelum proses
    local snap = {}
    for _, s in ipairs(list) do
        if s.cat ~= "Roblox" then
            snap[#snap + 1] = s
        end
    end
    local notifyProg = progCb or S.OnProgress
    task.spawn(function()
        local total = math.max(#snap, 1)
        if notifyProg then notifyProg(2, ("Saving scripts (0/%d) — Roblox package skipped..."):format(#snap)) end
        local okc, failc, folders = 0, 0, {}
        for i, s in ipairs(snap) do
            local src, how = S.Source(s.inst)
            local sub = ({Game = "Scripts_GameMap", Custom = "Scripts_Custom"})[s.cat] or "Scripts_Other"
            local base = clean(s.path):sub(1, 120) .. "_" .. i
            if src and how ~= "bytecode" then
                -- Source terbaca normal
                okc += 1
                S.write(sub .. "/" .. base .. ".lua", "-- " .. s.path .. " (" .. s.class .. ", " .. how .. ")\n" .. src)
            elseif src then
                -- FIX: Bytecode binary -> simpan sebagai hex dump readable, bukan raw binary
                okc += 1
                local hexDump = bytesToHex(src)
                S.write(sub .. "/" .. base .. "_bytecode.txt", "-- " .. s.path .. " (" .. s.class .. ", bytecode/encrypted)\n" .. hexDump)
            else
                failc += 1
                S.write(sub .. "/" .. base .. ".txt", "-- " .. s.path .. "\n-- decompile failed: " .. tostring(how))
            end
            folders[sub] = true
            local pct = math.floor(5 + (i / total) * 90)
            if i % 5 == 0 or i == #snap then
                if notifyProg then notifyProg(pct, ("Saving scripts (%d/%d) — %s"):format(i, #snap, s.name)) end
            end
            if i % 12 == 0 then task.wait() end
        end
        task.wait(0.3)
        local fl = {}
        for k in pairs(folders) do fl[#fl + 1] = ROOT .. "/" .. k end
        local doneTxt = ("Scripts ok=%d failed=%d | Roblox package excluded | %s"):format(okc, failc, table.concat(fl, ", "))
        if notifyProg then notifyProg(100, doneTxt) end
        if cb then cb(doneTxt) end
    end)
end

-- Asset / data debug: Value objects, attributes, sounds/meshes/decals/animations
function S.ScanAssets()
    local out = {}
    for _, svc in ipairs(game:GetChildren()) do
        pcall(function()
            for _, d in ipairs(svc:GetDescendants()) do
                pcall(function()
                    local sg = d:FindFirstAncestorOfClass("ScreenGui")
                    if sg and sg.Name:find("^R8_DV_Engine_") then return end
                    if d:IsA("ValueBase") then out[#out + 1] = {tag = "VALUE", path = fullName(d), info = d.ClassName .. " = " .. tostring(d.Value)}
                    elseif d:IsA("Sound") then out[#out + 1] = {tag = "SOUND", path = fullName(d), info = "Sound " .. d.SoundId}
                    elseif d:IsA("Decal") then out[#out + 1] = {tag = "DECAL", path = fullName(d), info = "Decal " .. d.Texture}
                    elseif d:IsA("Texture") then out[#out + 1] = {tag = "TEX", path = fullName(d), info = "Texture " .. d.Texture}
                    elseif d:IsA("MeshPart") then out[#out + 1] = {tag = "MESH", path = fullName(d), info = "Mesh " .. d.MeshId .. " tex " .. d.TextureID}
                    elseif d:IsA("Animation") then out[#out + 1] = {tag = "ANIM", path = fullName(d), info = "Anim " .. d.AnimationId} end
                    local at = d:GetAttributes()
                    for k, v in pairs(at) do out[#out + 1] = {tag = "ATTR", path = fullName(d), info = "Attr " .. k .. " = " .. tostring(v)} end
                end)
            end
        end)
    end
    return out
end
function S.Cleanup() end

-- ============ COMPILE CHECK ============
function S.CompileCheck(src)
    local ls = getgenv().loadstring or loadstring
    if not ls then return nil end
    local f, err = ls(src)
    return f ~= nil, err
end

-- ============ ZIP (store method, pure Luau) ============
local crcT
local function crcTable()
    if crcT then return crcT end
    crcT = {}
    for i = 0, 255 do
        local c = i
        for _ = 1, 8 do
            if bit32.band(c, 1) == 1 then c = bit32.bxor(bit32.rshift(c, 1), 0xEDB88320) else c = bit32.rshift(c, 1) end
        end
        crcT[i] = c
    end
    return crcT
end
local function crc32(s)
    local t, c = crcTable(), 0xFFFFFFFF
    for i = 1, #s do
        c = bit32.bxor(t[bit32.band(bit32.bxor(c, s:byte(i)), 0xFF)], bit32.rshift(c, 8))
        if i % 200000 == 0 then task.wait() end
    end
    return bit32.bxor(c, 0xFFFFFFFF)
end
function S.BuildZip(files, onZipProg)
    local out, central, offset = {}, {}, 0
    local dt = os.date("*t")
    local dosTime = bit32.bor(bit32.lshift(dt.hour, 11), bit32.lshift(dt.min, 5), math.floor(dt.sec / 2))
    local dosDate = bit32.bor(bit32.lshift(math.max(dt.year - 1980, 0), 9), bit32.lshift(dt.month, 5), dt.day)
    local total = math.max(#files, 1)
    for i, f in ipairs(files) do
        local name, data = f.name, f.data
        local crc, size = crc32(data), #data
        local lh = string.pack("<I4I2I2I2I2I2I4I4I4I2I2", 0x04034b50, 20, 0x0800, 0, dosTime, dosDate, crc, size, size, #name, 0)
        out[#out + 1] = lh out[#out + 1] = name out[#out + 1] = data
        central[#central + 1] = string.pack("<I4I2I2I2I2I2I2I4I4I4I2I2I2I2I2I4I4", 0x02014b50, 20, 20, 0x0800, 0, dosTime, dosDate, crc, size, size, #name, 0, 0, 0, 0, 0, offset) .. name
        offset += #lh + #name + size
        if i % 15 == 0 or i == #files then
            if onZipProg then onZipProg(i, total) end
            task.wait()
        end
    end
    local cd = table.concat(central)
    out[#out + 1] = cd
    out[#out + 1] = string.pack("<I4I2I2I2I2I4I4I2", 0x06054b50, 0, 0, #files, #files, #cd, offset, 0)
    return table.concat(out)
end

-- Export EVERYTHING (all packets + all scripts + all assets) into one folder structure, zipped.
function S.ExportAll(cb, progCb)
    local notifyProg = progCb or S.OnProgress
    task.spawn(function()
        local ok, err = pcall(function()
            local function step(pct, msg)
                if notifyProg then notifyProg(pct, msg) end
                if cb then cb(msg) end
            end

            local files, stamp = {}, os.date("%Y%m%d_%H%M%S")
            local function add(n, d) files[#files + 1] = {name = n, data = d} end
            local stats = {pk = 0, pkEnc = 0, sc = 0, scEnc = 0, scBad = 0, assets = 0}
            step(2, "1/4 Exporting packets...")
            local dec, enc = {}, {}
            local sep = "\n" .. ("-"):rep(40) .. "\n"
            local pkSnap = {table.unpack(S.Packets)}
            local pkTotal = math.max(#pkSnap, 1)
            for i, pk in ipairs(pkSnap) do
                local bad = false
                for _, p in ipairs(pk.args) do if p.how == "encrypted" then bad = true end end
                if bad then enc[#enc + 1] = S.PacketText(pk) else dec[#dec + 1] = S.PacketText(pk) end
                if i % 100 == 0 then
                    step(math.floor(2 + (i / pkTotal) * 10), ("1/4 Exporting packets (%d/%d)..."):format(i, #pkSnap))
                    task.wait()
                end
            end
            stats.pk, stats.pkEnc = #dec, #enc
            if #dec > 0 then add("Packets/packets.txt", table.concat(dec, sep)) end
            if #enc > 0 then add("Packets/packets_failed_decrypt.enc", table.concat(enc, sep)) end
            local rl = {}
            for _, r in ipairs(S.ScanRemotes()) do rl[#rl + 1] = r.ClassName .. "  " .. fullName(r) end
            add("Packets/remote_list.txt", table.concat(rl, "\n"))
            step(15, ("1/4 Packets & %d remotes indexed"):format(#rl))

            -- FIX: Filter keluar Roblox package dari export
            local rawList = S.ScanScripts()
            local list = {}
            local skippedRoblox = 0
            for _, s in ipairs(rawList) do
                if s.cat ~= "Roblox" then
                    list[#list + 1] = s
                else
                    skippedRoblox += 1
                end
            end
            local totalSc = #list
            step(16, ("2/4 Decompiling & exporting scripts (0/%d) — %d Roblox package skipped..."):format(totalSc, skippedRoblox))
            local dirs = {Game = "Scripts_GameMap", Custom = "Scripts_Custom"}
            for i, s in ipairs(list) do
                local src, how = S.Source(s.inst)
                local dirKey = dirs[s.cat] or "Scripts_Other"
                local base = dirKey .. "/" .. clean(s.path):sub(1, 120) .. "_" .. i
                if src and how ~= "bytecode" then
                    local c, e = S.CompileCheck(src)
                    local tag = c == nil and "n/a" or (c and "ok" or ("FAIL: " .. tostring(e)))
                    add(base .. ".lua", "-- " .. s.path .. " (" .. s.class .. ", " .. how .. ", compile:" .. tag .. ")\n" .. src)
                    stats.sc += 1 if c == false then stats.scBad += 1 end
                elseif src then
                    -- FIX: Bytecode binary -> hex dump readable, bukan raw .enc binary
                    local hexDump = bytesToHex(src)
                    add(base .. "_bytecode.txt", "-- " .. s.path .. " (" .. s.class .. ", bytecode/encrypted)\n" .. hexDump)
                    stats.scEnc += 1
                else
                    add(base .. ".txt", "-- " .. s.path .. "\n-- decompile failed: " .. tostring(how)) stats.scEnc += 1
                end
                local pct = math.floor(16 + (i / math.max(totalSc, 1)) * 58)
                if i % 5 == 0 or i == totalSc then
                    step(pct, ("2/4 Decompiling & exporting scripts (%d/%d)..."):format(i, totalSc))
                end
                if i % 15 == 0 or i == totalSc then
                    task.wait()
                end
            end

            step(76, "3/4 Scanning & exporting assets...")
            local ao = {}
            for _, a in ipairs(S.ScanAssets()) do ao[#ao + 1] = a.info .. " @ " .. a.path end
            stats.assets = #ao
            add("Assets/assets.txt", table.concat(ao, "\n"))
            add("README.txt", ("R&8_DV Debugger export %s\nPackets ok=%d encrypted=%d\nScripts ok=%d (compile-fail=%d) bytecode/failed=%d\nAssets=%d\nFolders: Scripts_GameMap (script game/map), Scripts_Custom (nil/executor-made)\nNote: Scripts_Roblox (package dasar) TIDAK diexport — hanya game & custom scripts.\nBytecode script disimpan sebagai hex dump (_bytecode.txt), bukan raw binary.\n"):format(stamp, stats.pk, stats.pkEnc, stats.sc, stats.scBad, stats.scEnc, stats.assets))
            step(85, ("3/4 Assets exported (%d entries)"):format(#ao))

            step(86, "4/4 Zipping " .. #files .. " files...")
            assert(F.writefile, "writefile unsupported")
            ensure(ROOT)
            local path = ROOT .. "/Export_" .. stamp .. ".zip"
            local zip = S.BuildZip(files, function(doneFiles, totalFiles)
                local zPct = math.floor(86 + (doneFiles / totalFiles) * 12)
                step(zPct, ("4/4 Zipping archive (%d/%d files)..."):format(doneFiles, totalFiles))
            end)
            local wok, werr = pcall(F.writefile, path, zip)
            if not wok then
                for _, f in ipairs(files) do
                    local p, parts = ROOT .. "/Export_" .. stamp, f.name:split("/")
                    ensure(p)
                    for j = 1, #parts - 1 do p = p .. "/" .. parts[j] ensure(p) end
                    pcall(F.writefile, p .. "/" .. parts[#parts], f.data)
                end
                path = ROOT .. "/Export_" .. stamp .. "/ (zip fallback: " .. tostring(werr) .. ")"
            end
            S.Saved[#S.Saved + 1] = path
            local finalMsg = ("DONE %s | %d files (%.1f KB) | pk=%d/%d sc=%d/%d"):format(path, #files, #zip / 1024, stats.pk, stats.pkEnc, stats.sc, stats.scEnc)
            step(100, finalMsg)
        end)
        if not ok then
            local errMsg = "Export error: " .. tostring(err)
            if notifyProg then notifyProg(0, errMsg) end
            if cb then cb(errMsg) end
        end
    end)
end

-- =========================================================================
-- 1. PANGGIL FRAMEWORK R&8_DV VIA GITHUB RAW (SAMA PERSIS DENGAN SAMPLE GUI)
-- =========================================================================
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"
local okFetch, rawScript = pcall(function()
    return game:HttpGet(GITHUB_RAW_URL)
end)
if not okFetch or type(rawScript) ~= "string" or #rawScript < 128 or string.sub(rawScript, 1, 4) == "404:" then
    okFetch, rawScript = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r&8_dv.lua")
    end)
end
if (not okFetch or type(rawScript) ~= "string" or #rawScript < 128) and F.isfile and F.readfile then
    okFetch, rawScript = pcall(function()
        if F.isfile("r&8_dv.lua") then return F.readfile("r&8_dv.lua") end
    end)
end
assert(okFetch and type(rawScript) == "string" and #rawScript > 128, "[R&8_DV] HTTP 404: Pastikan file r&8_dv.lua sudah di-upload ke GitHub Mytzcodes/R-8 (branch main).")

local ImGui = loadstring(rawScript)()

-- 2. Inisialisasi Jendela R&8_DV (Layout Canvas 3-Panel Sama Persis Dengan SampleGui.lua)
local UI = ImGui({
    Title = "DRY CURSED - DEBUGGER",
    BrandTitle = "R&8_DV",
    BrandSubtitle = "DEBUGGER SUITE",
    Theme = "Minimalist Monochrome",
    CheckboxStyle = "Modern",
    LetterSpacing = 1,
    AutoLoading = false
}).Call(3)

S.UI = UI

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
-- HELPER KOMPONEN CANVAS NATIVE (MENGIKUTI TEMA & RADIUS FRAMEWORK R&8_DV)
-- =========================================================================
local ActiveTheme = {
    PanelBg     = Color3.fromRGB(15, 17, 23),
    CardBg      = Color3.fromRGB(21, 24, 32),
    CardHoverBg = Color3.fromRGB(27, 31, 41),
    RowBg       = Color3.fromRGB(28, 32, 42),
    ControlBg   = Color3.fromRGB(36, 41, 54),
    Accent      = Color3.fromRGB(242, 246, 252),
    AccentSoft  = Color3.fromRGB(44, 50, 66),
    Stroke      = Color3.fromRGB(54, 62, 80),
    HoverStroke = Color3.fromRGB(176, 190, 216),
    TextPrimary = Color3.fromRGB(250, 252, 255),
    TextMuted   = Color3.fromRGB(204, 214, 232),
    TextAccent  = Color3.fromRGB(255, 255, 255),
}

local function GetOnFillColor(c)
    if not c then return Color3.fromRGB(255, 255, 255) end
    local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    return lum > 0.52 and Color3.fromRGB(12, 14, 20) or Color3.fromRGB(255, 255, 255)
end

local function CurrentCenterPage()
    local f = UI.Features and UI.Features[#UI.Features]
    return f and f.CenterPage
end

local function CurrentRightPage()
    local f = UI.Features and UI.Features[#UI.Features]
    return f and f.RightPage
end

local function GetLastFrame(parent)
    if not parent then return nil end
    local ch = parent:GetChildren()
    for i = #ch, 1, -1 do
        if ch[i]:IsA("Frame") then
            return ch[i]
        end
    end
    return nil
end

local function FindCardActionLabel(cardFrame, initialText)
    if not cardFrame then return nil end
    for _, d in ipairs(cardFrame:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text == initialText then
            return d
        end
    end
    return nil
end

local function BindLiveInput(cardFrame, flag, onTextChanged)
    local row = GetLastFrame(cardFrame)
    if not row then return nil end
    local tb = row:FindFirstChildOfClass("TextBox")
    if tb then
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            UI:SetValue(flag, tb.Text, true)
            if onTextChanged then onTextChanged(tb.Text) end
        end)
    end
    return tb
end

local function RegisterCanvasRadius(corner, baseRadius)
    if UI.RadiusBindings then
        table.insert(UI.RadiusBindings, {Instance = corner, BaseRadius = baseRadius})
    end
end

local function RegisterCanvasTheme(inst, fn)
    if UI.ThemeUpdaters then
        table.insert(UI.ThemeUpdaters, {Instance = inst, Update = function(theme)
            ActiveTheme = theme
            fn(theme)
        end})
    end
    fn(ActiveTheme)
end

-- Live Status & Event Log Sync
local StatusLabels = {}
local ActivityRows = {}
local ActivityHistory = {
    {Text = ("Save Workspace: <executor>/%s/"):format(ROOT), Time = "Ready"},
    {Text = S.Hooked and "Metamethod Remote Spy Active" or "Passive Remote Listener Ready", Time = "Init"},
    {Text = "Multi-Codec (Base64/Hex/URL/JSON/XOR) Ready", Time = "Init"},
    {Text = "R&8_DV v5.4 Canvas Debugger Initialized", Time = "Init"},
}

local StatValueLabels = nil
local RemoteCountCache = 0

local function RefreshDashboardStats()
    if not StatValueLabels then return end
    if StatValueLabels[1] then
        StatValueLabels[1].Text = tostring(#S.Packets) .. " Logs"
    end
    if StatValueLabels[2] then
        StatValueLabels[2].Text = tostring(#S.Scripts) .. " Found"
    end
    if StatValueLabels[3] then
        StatValueLabels[3].Text = S.Hooked and ("Hooked (" .. RemoteCountCache .. ")") or ("No Hook (" .. RemoteCountCache .. ")")
    end
end

local function say(msg)
    local cleanMsg = tostring(msg or ""):gsub("\n", " | ")
    for _, lbl in ipairs(StatusLabels) do
        if lbl and lbl.Parent then
            lbl.Text = cleanMsg
        end
    end
    table.insert(ActivityHistory, 1, {
        Text = cleanMsg,
        Time = os.date("%H:%M:%S")
    })
    while #ActivityHistory > 4 do
        table.remove(ActivityHistory)
    end
    for idx, row in ipairs(ActivityRows) do
        local entry = ActivityHistory[idx]
        if entry and row.EventTxt and row.TimeTxt then
            row.EventTxt.Text = entry.Text
            row.TimeTxt.Text = entry.Time
        end
    end
    RefreshDashboardStats()
end

-- FIX: Tiap progress bar punya state sendiri (tag-based), tidak lagi shared global.
-- Ini mencegah bug progress muncul di semua tab sekaligus.
local ProgressBars = {}
local CurrentExportPct = 0
local CurrentExportStage = "Idle — Ready to Export"

-- ActiveBarTag menentukan bar mana yang sedang di-update.
-- Di-set sebelum memanggil SetExportProgress dari tiap operasi.
local ActiveBarTag = nil

local SMOOTH_BAR_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH_BTN_TWEEN = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function SetExportProgress(pct, stageText, barTag)
    -- Gunakan barTag argumen jika ada, lalu fallback ke ActiveBarTag, lalu update semua
    local targetTag = barTag or ActiveBarTag
    CurrentExportPct = math.clamp(math.floor((tonumber(pct) or 0) + 0.5), 0, 100)
    if stageText and stageText ~= "" then
        CurrentExportStage = tostring(stageText):gsub("\n", " | ")
    end
    local onAcc = GetOnFillColor(ActiveTheme.Accent)
    local isBusyOrDone = (CurrentExportPct > 0)
    for _, bar in ipairs(ProgressBars) do
        -- FIX: Hanya update bar yang tag-nya cocok, atau semua jika tidak ada tag aktif
        if bar.Holder and bar.Holder.Parent and (not targetTag or bar.Tag == targetTag) then
            bar.StageLbl.Text = CurrentExportStage
            bar.PctTxt.Text = tostring(CurrentExportPct) .. "%"
            bar.PctPill.BackgroundColor3 = isBusyOrDone and ActiveTheme.Accent or ActiveTheme.ControlBg
            bar.PctTxt.TextColor3 = isBusyOrDone and onAcc or ActiveTheme.TextAccent
            bar.Stroke.Color = (CurrentExportPct > 0 and CurrentExportPct < 100) and ActiveTheme.Accent or (bar.Hovered and ActiveTheme.HoverStroke or ActiveTheme.Stroke)
            bar.Stroke.Transparency = (CurrentExportPct > 0 and CurrentExportPct < 100) and 0.05 or (bar.Hovered and 0.08 or 0.28)
            if UI.ReduceEffects then
                bar.Fill.Size = UDim2.new(CurrentExportPct / 100, 0, 1, 0)
            else
                TweenService:Create(bar.Fill, SMOOTH_BAR_TWEEN, {
                    Size = UDim2.new(CurrentExportPct / 100, 0, 1, 0)
                }):Play()
            end
        end
    end
end
S.OnProgress = SetExportProgress

-- Helper: buat progress callback yang terikat ke satu bar tag tertentu
local function MakeProgressCb(tag)
    return function(pct, msg) SetExportProgress(pct, msg, tag) end
end

local function AttachExportProgressBar(cardFrame, initialStageText, barTag)
    local Holder = Instance.new("TextButton")
    Holder.Size = UDim2.new(1, 0, 0, 68)
    Holder.BorderSizePixel = 0
    Holder.Text = ""
    Holder.AutoButtonColor = false
    Holder.Parent = cardFrame

    local HScale = Instance.new("UIScale")
    HScale.Scale = 1
    HScale.Parent = Holder

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, UI.Rounded and 10 or 0)
    Corner.Parent = Holder
    RegisterCanvasRadius(Corner, 10)

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Transparency = 0.28
    Stroke.Parent = Holder

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 10)
    Pad.PaddingBottom = UDim.new(0, 10)
    Pad.PaddingLeft = UDim.new(0, 14)
    Pad.PaddingRight = UDim.new(0, 14)
    Pad.Parent = Holder

    local StageLbl = Instance.new("TextLabel")
    StageLbl.Position = UDim2.new(0, 0, 0, 0)
    StageLbl.Size = UDim2.new(1, -78, 0, 24)
    StageLbl.BackgroundTransparency = 1
    StageLbl.Font = Enum.Font.GothamBold
    StageLbl.TextSize = 14
    StageLbl.TextTruncate = Enum.TextTruncate.AtEnd
    StageLbl.TextXAlignment = Enum.TextXAlignment.Left
    StageLbl.Text = initialStageText or CurrentExportStage
    StageLbl.Parent = Holder

    local PctPill = Instance.new("Frame")
    PctPill.AutomaticSize = Enum.AutomaticSize.X
    PctPill.Size = UDim2.fromOffset(0, 24)
    PctPill.Position = UDim2.new(1, 0, 0, 0)
    PctPill.AnchorPoint = Vector2.new(1, 0)
    PctPill.BorderSizePixel = 0
    PctPill.Parent = Holder

    local PillCorner = Instance.new("UICorner")
    PillCorner.CornerRadius = UDim.new(0, UI.Rounded and 7 or 0)
    PillCorner.Parent = PctPill
    RegisterCanvasRadius(PillCorner, 7)

    local PillPad = Instance.new("UIPadding")
    PillPad.PaddingLeft = UDim.new(0, 10)
    PillPad.PaddingRight = UDim.new(0, 10)
    PillPad.Parent = PctPill

    local PctTxt = Instance.new("TextLabel")
    PctTxt.AutomaticSize = Enum.AutomaticSize.X
    PctTxt.Size = UDim2.new(0, 0, 1, 0)
    PctTxt.BackgroundTransparency = 1
    PctTxt.Font = Enum.Font.GothamBlack
    PctTxt.TextSize = 13
    PctTxt.Text = tostring(CurrentExportPct) .. "%"
    PctTxt.Parent = PctPill

    local Track = Instance.new("Frame")
    Track.Position = UDim2.new(0, 0, 0, 34)
    Track.Size = UDim2.new(1, 0, 0, 11)
    Track.BorderSizePixel = 0
    Track.ClipsDescendants = true
    Track.Parent = Holder

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(0, UI.Rounded and 6 or 0)
    TrackCorner.Parent = Track
    RegisterCanvasRadius(TrackCorner, 6)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(CurrentExportPct / 100, 0, 1, 0)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, UI.Rounded and 6 or 0)
    FillCorner.Parent = Fill
    RegisterCanvasRadius(FillCorner, 6)

    local barEntry = {
        Holder = Holder,
        Stroke = Stroke,
        StageLbl = StageLbl,
        PctPill = PctPill,
        PctTxt = PctTxt,
        Track = Track,
        Fill = Fill,
        Hovered = false,
        Tag = barTag or false,  -- FIX: simpan tag biar bisa difilter per-tab
    }
    table.insert(ProgressBars, barEntry)

    local function SyncBarTheme(theme)
        local onAcc = GetOnFillColor(theme.Accent)
        local isBusyOrDone = (CurrentExportPct > 0)
        Holder.BackgroundColor3 = barEntry.Hovered and theme.CardHoverBg or theme.RowBg
        Stroke.Color = (CurrentExportPct > 0 and CurrentExportPct < 100) and theme.Accent or (barEntry.Hovered and theme.HoverStroke or theme.Stroke)
        Stroke.Transparency = (CurrentExportPct > 0 and CurrentExportPct < 100) and 0.05 or (barEntry.Hovered and 0.08 or 0.28)
        StageLbl.TextColor3 = theme.TextPrimary
        Track.BackgroundColor3 = theme.ControlBg
        Fill.BackgroundColor3 = theme.Accent
        PctPill.BackgroundColor3 = isBusyOrDone and theme.Accent or theme.ControlBg
        PctTxt.TextColor3 = isBusyOrDone and onAcc or theme.TextAccent
    end

    RegisterCanvasTheme(Holder, SyncBarTheme)

    if UIS.MouseEnabled then
        Holder.MouseEnter:Connect(function()
            barEntry.Hovered = true
            SyncBarTheme(ActiveTheme)
        end)
        Holder.MouseLeave:Connect(function()
            barEntry.Hovered = false
            HScale.Scale = 1
            SyncBarTheme(ActiveTheme)
        end)
    end

    Holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(HScale, SMOOTH_BTN_TWEEN, {Scale = 0.98}):Play()
        end
    end)
    Holder.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(HScale, SMOOTH_BTN_TWEEN, {Scale = 1}):Play()
        end
    end)
    Holder.MouseButton1Click:Connect(function()
        local lastSaved = S.Saved[#S.Saved]
        if lastSaved and F.setclip then
            F.setclip(lastSaved)
            say(("Progress %d%% — Copied latest export path: %s"):format(CurrentExportPct, lastSaved))
        else
            say(("Export progress: %d%% (%s)"):format(CurrentExportPct, CurrentExportStage))
        end
    end)

    return barEntry
end

-- Hover + Click Press Visual Feedback untuk semua Action Button di dalam Card
local EnhancedButtons = setmetatable({}, {__mode = "k"})
local function EnhanceCardButtons(cardFrame)
    if not cardFrame then return end
    for _, child in ipairs(cardFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Size.Y.Offset == 48 and not EnhancedButtons[child] then
            EnhancedButtons[child] = true
            local btnScale = child:FindFirstChildOfClass("UIScale")
            if not btnScale then
                btnScale = Instance.new("UIScale")
                btnScale.Scale = 1
                btnScale.Parent = child
            end
            local btnStroke = child:FindFirstChildOfClass("UIStroke")
            local mainLbl = child:FindFirstChildOfClass("TextLabel")
            local badgePill = child:FindFirstChildOfClass("Frame")
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("Frame") and sub.AnchorPoint.X == 1 then
                    badgePill = sub
                    break
                end
            end
            local badgeTxt = badgePill and badgePill:FindFirstChildOfClass("TextLabel")
            local origBadge = badgeTxt and badgeTxt.Text or ""
            local hovered, pressed = false, false
            local clickSeq = 0

            local function ApplyState()
                local onAcc = GetOnFillColor(ActiveTheme.Accent)
                local bg = pressed and ActiveTheme.ControlBg or (hovered and ActiveTheme.CardHoverBg or ActiveTheme.Accent)
                local fg = (pressed or hovered) and ActiveTheme.TextPrimary or onAcc
                TweenService:Create(child, SMOOTH_BTN_TWEEN, {BackgroundColor3 = bg, BackgroundTransparency = 0}):Play()
                TweenService:Create(btnScale, SMOOTH_BTN_TWEEN, {Scale = pressed and 0.97 or (hovered and 1.01 or 1)}):Play()
                if mainLbl then mainLbl.TextColor3 = fg end
                if btnStroke then
                    btnStroke.Thickness = (pressed or hovered) and 1.8 or 1
                    btnStroke.Color = pressed and ActiveTheme.TextPrimary or ActiveTheme.Accent
                    btnStroke.Transparency = (pressed or hovered) and 0 or 0.16
                end
                if badgePill and badgeTxt then
                    if pressed or hovered then
                        badgePill.BackgroundColor3 = ActiveTheme.Accent
                        badgePill.BackgroundTransparency = 0
                        badgeTxt.TextColor3 = onAcc
                    else
                        badgePill.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
                        badgePill.BackgroundTransparency = 0.18
                        badgeTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end
            end

            if UIS.MouseEnabled then
                child.MouseEnter:Connect(function()
                    hovered = true
                    ApplyState()
                end)
                child.MouseLeave:Connect(function()
                    hovered = false
                    pressed = false
                    ApplyState()
                end)
            end

            child.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    pressed = true
                    ApplyState()
                end
            end)
            child.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if pressed then
                        pressed = false
                        ApplyState()
                    end
                end
            end)
            child.MouseButton1Click:Connect(function()
                clickSeq += 1
                local mySeq = clickSeq
                pressed = true
                ApplyState()
                if badgeTxt and origBadge ~= "" then
                    badgeTxt.Text = "OK ✓"
                end
                task.delay(0.13, function()
                    if child and child.Parent then
                        pressed = false
                        ApplyState()
                    end
                end)
                task.delay(0.60, function()
                    if badgeTxt and badgeTxt.Parent and clickSeq == mySeq and origBadge ~= "" then
                        badgeTxt.Text = origBadge
                    end
                end)
            end)
        end
    end
end

local function AttachStatusBanner(cardFrame, defaultText)
    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, 0, 0, 42)
    Box.AutomaticSize = Enum.AutomaticSize.Y
    Box.BorderSizePixel = 0
    Box.Parent = cardFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, UI.Rounded and 10 or 0)
    Corner.Parent = Box
    RegisterCanvasRadius(Corner, 10)

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Transparency = 0.28
    Stroke.Parent = Box

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 10)
    Pad.PaddingBottom = UDim.new(0, 10)
    Pad.PaddingLeft = UDim.new(0, 14)
    Pad.PaddingRight = UDim.new(0, 14)
    Pad.Parent = Box

    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1, 0, 0, 20)
    Lbl.AutomaticSize = Enum.AutomaticSize.Y
    Lbl.BackgroundTransparency = 1
    Lbl.Font = Enum.Font.GothamBold
    Lbl.TextSize = 14
    Lbl.TextWrapped = true
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.TextYAlignment = Enum.TextYAlignment.Center
    Lbl.Text = defaultText or "Ready"
    Lbl.Parent = Box

    RegisterCanvasTheme(Box, function(theme)
        Box.BackgroundColor3 = theme.RowBg
        Stroke.Color = theme.Stroke
        Lbl.TextColor3 = theme.TextAccent
    end)

    table.insert(StatusLabels, Lbl)
    return Lbl
end

local function AttachSelectList(cardFrame, heightPx, emptyText)
    local ListScroll = Instance.new("ScrollingFrame")
    ListScroll.Size = UDim2.new(1, 0, 0, heightPx or 225)
    ListScroll.BorderSizePixel = 0
    ListScroll.ScrollBarThickness = 3
    ListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ListScroll.Parent = cardFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, UI.Rounded and 10 or 0)
    Corner.Parent = ListScroll
    RegisterCanvasRadius(Corner, 10)

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Transparency = 0.24
    Stroke.Parent = ListScroll

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 8)
    Pad.PaddingBottom = UDim.new(0, 8)
    Pad.PaddingLeft = UDim.new(0, 8)
    Pad.PaddingRight = UDim.new(0, 10)
    Pad.Parent = ListScroll

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 6)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = ListScroll

    local EmptyLbl = Instance.new("TextLabel")
    EmptyLbl.Size = UDim2.new(1, 0, 0, 48)
    EmptyLbl.BackgroundTransparency = 1
    EmptyLbl.Font = Enum.Font.GothamMedium
    EmptyLbl.TextSize = 15
    EmptyLbl.TextWrapped = true
    EmptyLbl.Text = emptyText or "No entries available"
    EmptyLbl.Parent = ListScroll

    local RowEntries = {}

    local function ApplyRowTheme(entry, theme)
        local sel = entry.IsSelected()
        local onAcc = GetOnFillColor(theme.Accent)
        entry.Corner.CornerRadius = UDim.new(0, UI.Rounded and 8 or 0)
        entry.TagCorner.CornerRadius = UDim.new(0, UI.Rounded and 6 or 0)
        if sel then
            entry.Btn.BackgroundColor3 = theme.Accent
            entry.Btn.BackgroundTransparency = 0
            entry.Stroke.Color = theme.Accent
            entry.Stroke.Transparency = 0.05
            entry.Title.TextColor3 = onAcc
            entry.Tag.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
            entry.Tag.BackgroundTransparency = 0.20
            entry.TagTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            entry.Btn.BackgroundColor3 = entry.Hovered and theme.CardHoverBg or theme.RowBg
            entry.Btn.BackgroundTransparency = 0
            entry.Stroke.Color = entry.Hovered and theme.HoverStroke or theme.Stroke
            entry.Stroke.Transparency = entry.Hovered and 0.10 or 0.34
            entry.Title.TextColor3 = theme.TextPrimary
            entry.Tag.BackgroundColor3 = theme.ControlBg
            entry.Tag.BackgroundTransparency = 0
            entry.TagTxt.TextColor3 = theme.TextAccent
        end
    end

    RegisterCanvasTheme(ListScroll, function(theme)
        ListScroll.BackgroundColor3 = theme.PanelBg
        ListScroll.ScrollBarImageColor3 = theme.Accent
        Stroke.Color = theme.Stroke
        EmptyLbl.TextColor3 = theme.TextMuted
        for _, entry in ipairs(RowEntries) do
            if entry.Btn and entry.Btn.Parent then
                ApplyRowTheme(entry, theme)
            end
        end
    end)

    local Api = {}
    function Api:RefreshStyles()
        for _, entry in ipairs(RowEntries) do
            if entry.Btn and entry.Btn.Parent then
                ApplyRowTheme(entry, ActiveTheme)
            end
        end
    end

    function Api:Render(items, getTag, getLabel, isSelectedFn, onSelect)
        for _, entry in ipairs(RowEntries) do
            if entry.Btn and entry.Btn.Parent then
                entry.Btn:Destroy()
            end
        end
        table.clear(RowEntries)

        local count = math.min(#items, 300)
        EmptyLbl.Visible = (count == 0)

        for i = 1, count do
            local item = items[i]
            local Btn = Instance.new("TextButton")
            Btn.LayoutOrder = i
            Btn.Size = UDim2.new(1, 0, 0, 38)
            Btn.BorderSizePixel = 0
            Btn.Text = ""
            Btn.AutoButtonColor = false
            Btn.Parent = ListScroll

            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(0, UI.Rounded and 8 or 0)
            rCorner.Parent = Btn

            local rStroke = Instance.new("UIStroke")
            rStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            rStroke.Thickness = 1
            rStroke.Parent = Btn

            local TagPill = Instance.new("Frame")
            TagPill.Size = UDim2.fromOffset(66, 24)
            TagPill.Position = UDim2.new(0, 8, 0.5, 0)
            TagPill.AnchorPoint = Vector2.new(0, 0.5)
            TagPill.BorderSizePixel = 0
            TagPill.Parent = Btn

            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = UDim.new(0, UI.Rounded and 6 or 0)
            tCorner.Parent = TagPill

            local TagTxt = Instance.new("TextLabel")
            TagTxt.Size = UDim2.fromScale(1, 1)
            TagTxt.BackgroundTransparency = 1
            TagTxt.Font = Enum.Font.GothamBlack
            TagTxt.TextSize = 11
            TagTxt.TextTruncate = Enum.TextTruncate.AtEnd
            TagTxt.Text = string.upper(tostring(getTag(item) or "LOG"))
            TagTxt.Parent = TagPill

            local Title = Instance.new("TextLabel")
            Title.Position = UDim2.new(0, 82, 0, 0)
            Title.Size = UDim2.new(1, -92, 1, 0)
            Title.BackgroundTransparency = 1
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 14
            Title.TextTruncate = Enum.TextTruncate.AtEnd
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Text = tostring(getLabel(item) or "")
            Title.Parent = Btn

            local rScale = Instance.new("UIScale")
            rScale.Scale = 1
            rScale.Parent = Btn

            local entry = {
                Btn = Btn,
                Corner = rCorner,
                Stroke = rStroke,
                Tag = TagPill,
                TagCorner = tCorner,
                TagTxt = TagTxt,
                Title = Title,
                Hovered = false,
                IsSelected = function()
                    return isSelectedFn and isSelectedFn(item) or false
                end
            }
            table.insert(RowEntries, entry)
            ApplyRowTheme(entry, ActiveTheme)

            if UIS.MouseEnabled then
                Btn.MouseEnter:Connect(function()
                    entry.Hovered = true
                    ApplyRowTheme(entry, ActiveTheme)
                end)
                Btn.MouseLeave:Connect(function()
                    entry.Hovered = false
                    rScale.Scale = 1
                    ApplyRowTheme(entry, ActiveTheme)
                end)
            end

            Btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    TweenService:Create(rScale, SMOOTH_BTN_TWEEN, {Scale = 0.985}):Play()
                end
            end)
            Btn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    TweenService:Create(rScale, SMOOTH_BTN_TWEEN, {Scale = 1}):Play()
                end
            end)

            Btn.MouseButton1Click:Connect(function()
                if onSelect then onSelect(item) end
                Api:RefreshStyles()
            end)
        end
    end

    return Api
end

local function AttachCodeViewer(cardFrame, heightPx, placeholderText)
    local ViewScroll = Instance.new("ScrollingFrame")
    ViewScroll.Size = UDim2.new(1, 0, 0, heightPx or 210)
    ViewScroll.BorderSizePixel = 0
    ViewScroll.ScrollBarThickness = 4
    ViewScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ViewScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    ViewScroll.Parent = cardFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, UI.Rounded and 10 or 0)
    Corner.Parent = ViewScroll
    RegisterCanvasRadius(Corner, 10)

    local Stroke = Instance.new("UIStroke")
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Transparency = 0.22
    Stroke.Parent = ViewScroll

    local Pad = Instance.new("UIPadding")
    Pad.PaddingTop = UDim.new(0, 12)
    Pad.PaddingBottom = UDim.new(0, 12)
    Pad.PaddingLeft = UDim.new(0, 12)
    Pad.PaddingRight = UDim.new(0, 14)
    Pad.Parent = ViewScroll

    local CodeBox = Instance.new("TextBox")
    CodeBox.Size = UDim2.new(1, 0, 0, 0)
    CodeBox.AutomaticSize = Enum.AutomaticSize.Y
    CodeBox.BackgroundTransparency = 1
    CodeBox.Font = Enum.Font.Code
    CodeBox.TextSize = 14
    CodeBox.LineHeight = 1.15
    CodeBox.TextXAlignment = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment = Enum.TextYAlignment.Top
    CodeBox.ClearTextOnFocus = false
    CodeBox.TextEditable = false
    CodeBox.MultiLine = true
    CodeBox.TextWrapped = true
    CodeBox.PlaceholderText = placeholderText or "Select an item to inspect..."
    CodeBox.Text = ""
    CodeBox.Parent = ViewScroll

    RegisterCanvasTheme(ViewScroll, function(theme)
        ViewScroll.BackgroundColor3 = theme.PanelBg
        ViewScroll.ScrollBarImageColor3 = theme.Accent
        Stroke.Color = theme.Stroke
        CodeBox.TextColor3 = theme.TextPrimary
        CodeBox.PlaceholderColor3 = theme.TextMuted
    end)

    local fullContent = ""
    local MAX_PREVIEW = 24000
    return {
        SetText = function(_, raw)
            fullContent = tostring(raw or "")
            ViewScroll.CanvasPosition = Vector2.zero
            if #fullContent > MAX_PREVIEW then
                CodeBox.Text = fullContent:sub(1, MAX_PREVIEW) .. ("\n\n-- [Preview truncated at %d KB; Copy / Save exports complete %d KB output]"):format(math.floor(MAX_PREVIEW / 1024), math.floor(#fullContent / 1024))
            else
                CodeBox.Text = fullContent
            end
        end,
        GetText = function()
            return fullContent
        end
    }
end

-- Two-way Spy State Sync
local syncingSpyFlags = false
local function SetSpyPaused(state)
    S.Paused = (state == true)
    if syncingSpyFlags then return end
    syncingSpyFlags = true
    UI:SetValue("HomePauseSpy", S.Paused)
    UI:SetValue("PkPauseSpy", S.Paused)
    syncingSpyFlags = false
    say(S.Paused and "Packet capture paused" or "Packet capture active")
end

local function SetIncludeExec(state)
    S.IncludeExecutor = (state == true)
    if syncingSpyFlags then return end
    syncingSpyFlags = true
    UI:SetValue("HomeIncludeExec", S.IncludeExecutor)
    UI:SetValue("PkIncludeExec", S.IncludeExecutor)
    syncingSpyFlags = false
    say("Executor remote logging: " .. (S.IncludeExecutor and "ON" or "OFF"))
end

-- Global Right Panel Builder (Sama Persis Dengan SampleGui.lua)
local function BuildGlobalSettingsRight(r)
    local ThemeCard = r:Card("Theme & Checklist", nil, "Palette", {
        Subtitle = "Choose colour palette and switch/checkbox style"
    })
    if ThemeCard.ThemeSwatches then
        ThemeCard:ThemeSwatches("Colour Palette")
    end
    ThemeCard:Dropdown("Color Style", "ThemeSelect", ThemeChoices, "Minimalist Monochrome", function(selectedTheme)
        UI:SetTheme(selectedTheme)
    end)
    ThemeCard:Dropdown("Checkbox Style", "CheckboxStyleMode", {
        "Modern",
        "Checkbox"
    }, "Modern", function(mode)
        if UI.SetCheckboxStyle then UI:SetCheckboxStyle(mode) end
    end)
    ThemeCard:Slider("Letter Spacing", "LetterSpacingVal", 0, 3, 1, "x", function(val)
        if UI.SetLetterSpacing then UI:SetLetterSpacing(val) end
    end)

    local LayoutCard = r:Card("Window & Layout", nil, "Sliders", {
        Subtitle = "Scale, surface opacity, corners and menu hotkey"
    })
    LayoutCard:Slider("UI Scale", "UIScalePct", 60, 130, 100, "%", function(val)
        if UI.SetScale then
            UI:SetScale(val / 100)
        else
            UI.UIScale = val / 100
        end
    end)
    LayoutCard:Slider("Transparency", "BgTransPct", 0, 55, 4, "%", function(val)
        UI:SetTransparency(val / 100)
    end)
    LayoutCard:Toggle("Rounded Borders", "RoundedState", true, function(state)
        UI:SetRounded(state)
    end)
    LayoutCard:Toggle("Lock Position", "LockPosition", false)
    if LayoutCard.Keybind then
        LayoutCard:Keybind("Toggle Menu Key", "MenuHotkey", Enum.KeyCode.RightShift, function(newKey)
            if newKey then
                UI.ToggleKey = newKey
            end
        end)
    end

    local PerfCard = r:Card("Performance", nil, "Bolt", {
        Subtitle = "Instant zero-tween mode for low-end devices"
    })
    PerfCard:Toggle("FPS Boost", "FPSBoost", false)
    PerfCard:Toggle("Reduce Effects", "ReduceEffects", false)
end

-- =========================================================================
-- KATEGORI 1: OVERVIEW (SAMA SEPERTI SAMPLE GUI)
-- =========================================================================
if UI.Category then UI:Category("Overview") end

feature("Home", "Home")({
    center = center(function(c)
        c:Header(
            "Debugger Overview",
            S.Hooked and "Remote spy hooked, Luau decompiler & multi-codec archive ready" or "Hook metamethod unsupported — passive listener, decompiler & codec ready",
            S.Hooked and "Hooked" or "Passive"
        )

        StatValueLabels = c:StatRow({
            { Icon = "Target", Label = "Packets", Value = "0 Logs" },
            { Icon = "Layers", Label = "Scripts", Value = "0 Found" },
            { Icon = "Shield", Label = "Spy Hook", Value = S.Hooked and "Active" or "No Hook" }
        })

        local QuickCard = c:Card("Quick Debugger Controls", "Archive", "Bolt", {
            Subtitle = "Export complete game dump (.zip) or toggle packet capture"
        })
        local quickFrame = GetLastFrame(CurrentCenterPage())
        AttachExportProgressBar(quickFrame, "Idle — Click Export ALL to build .zip")

        QuickCard:Toggle("Pause Packet Capture", "HomePauseSpy", S.Paused, function(val)
            SetSpyPaused(val)
        end)
        QuickCard:Toggle("Log Executor Remotes", "HomeIncludeExec", S.IncludeExecutor, function(val)
            SetIncludeExec(val)
        end)
        QuickCard:Button("Export ALL to ZIP Archive", "ZIP ALL", "Collect", function()
            SetExportProgress(1, "Starting full ZIP export...")
            say("Starting full ZIP export...")
            S.ExportAll(say, SetExportProgress)
        end)
        QuickCard:Button("Rescan All Game Remotes", "RESCAN", "Target", function()
            local rList = S.ScanRemotes()
            RemoteCountCache = #rList
            say("Scanned & watching " .. tostring(#rList) .. " remotes")
        end)
        EnhanceCardButtons(quickFrame)

        local ActivityCard = c:Card("Recent Debugger Events", "Live Logs", "Clock", {
            Subtitle = "Live status stream & workspace export notifications"
        })
        ActivityCard:ActivityTimeline(ActivityHistory)

        -- Tangkap label timeline agar update secara real-time saat say() dipanggil
        local actFrame = GetLastFrame(CurrentCenterPage())
        if actFrame then
            for _, child in ipairs(actFrame:GetChildren()) do
                if child:IsA("Frame") and child.Size.Y.Offset == 40 then
                    local labels = {}
                    for _, sub in ipairs(child:GetChildren()) do
                        if sub:IsA("TextLabel") then
                            table.insert(labels, sub)
                        end
                    end
                    if #labels >= 2 then
                        table.insert(ActivityRows, {EventTxt = labels[1], TimeTxt = labels[2]})
                    end
                end
            end
        end
    end),

    right = right(function(r)
        BuildGlobalSettingsRight(r)
    end)
})

-- =========================================================================
-- KATEGORI 2: DEBUGGER MODULES
-- =========================================================================
if UI.Category then UI:Category("Debugger") end

-- TAB 1: PACKET SPY
local curPk = nil
local PacketListUI = nil
local PacketViewerUI = nil
local PacketCountBadge = nil

function S.refreshP()
    if not PacketListUI then return end
    local query = UI:GetValue("PkSearch") or ""
    local dirFilter = UI:GetValue("PkDir") or "ALL"
    local items = S.Filter(query, dirFilter)
    local rev = {}
    for i = #items, 1, -1 do
        rev[#rev + 1] = items[i]
    end
    if PacketCountBadge then
        PacketCountBadge.Text = tostring(#rev) .. " Shown"
    end
    PacketListUI:Render(
        rev,
        function(pk) return pk.dir end,
        function(pk)
            local arrow = (pk.method == "OnClientEvent" or pk.method == "OnClientInvoke") and "<-" or "->"
            local argHint = (pk.args[1] and pk.args[1].text) and ("  " .. pk.args[1].text) or ""
            return ("#%d %s %s%s"):format(pk.id, arrow, pk.name, argHint)
        end,
        function(pk) return curPk == pk end,
        function(pk)
            curPk = pk
            if PacketViewerUI then
                PacketViewerUI:SetText(S.PacketText(pk))
            end
        end
    )
    RefreshDashboardStats()
end

feature("Target", "Packets")({
    center = center(function(c)
        c:Header("Packet Spy", "Intercept, search & decode RemoteEvent / RemoteFunction traffic", S.Hooked and "Live Spy" or "IN Only")

        c:Card("Captured Packets", "0 Shown", "Target", {
            Subtitle = "Newest packets on top — click any packet to inspect arguments"
        })
        local streamFrame = GetLastFrame(CurrentCenterPage())
        PacketCountBadge = FindCardActionLabel(streamFrame, "0 Shown")
        PacketListUI = AttachSelectList(streamFrame, 225, "No matching packets yet — perform an action in-game")

        local FilterCard = c:Card("Filter & Capture Policy", nil, "Sliders", {
            Subtitle = "Live content search (values, strings, names) & direction filter"
        })
        FilterCard:Input("Search Content / Value", "PkSearch", "Search e.g. 100, kill, coin, remote...", "", function()
            S.refreshP()
        end)
        local filterFrame = GetLastFrame(CurrentCenterPage())
        BindLiveInput(filterFrame, "PkSearch", function()
            S.refreshP()
        end)
        FilterCard:Dropdown("Traffic Direction", "PkDir", {"ALL", "OUT", "IN"}, "ALL", function()
            S.refreshP()
        end)
        FilterCard:Toggle("Pause Packet Capture", "PkPauseSpy", S.Paused, function(val)
            SetSpyPaused(val)
        end)
        FilterCard:Toggle("Include Executor Calls", "PkIncludeExec", S.IncludeExecutor, function(val)
            SetIncludeExec(val)
        end)
        FilterCard:Toggle("Hide Ping/Spam (auto)", "PkHideSpam", S.HideSpam, function(val)
            S.HideSpam = (val == true)
            if not S.HideSpam then table.clear(S.SpamSeen) table.clear(S.ShapeSeen) end
            say("Hide ping/spam: " .. (S.HideSpam and "ON" or "OFF"))
        end)
    end),

    right = right(function(r)
        local InspectCard = r:Card("Packet Inspector", nil, "Chat", {
            Subtitle = "Arguments, caller origin & automatic decoded strings"
        })
        local inspectFrame = GetLastFrame(CurrentRightPage())
        AttachStatusBanner(inspectFrame, "Select a packet on the left to inspect")
        PacketViewerUI = AttachCodeViewer(inspectFrame, 195, "Click a captured packet to view full arguments & decoded payload...")

        InspectCard:Button("Replay Selected Packet", "REPLAY", "Bolt", function()
            if not curPk then say("Select a packet first") return end
            S.Replay(curPk)
            say("Replayed packet #" .. tostring(curPk.id) .. " (" .. curPk.name .. ")")
        end)
        InspectCard:Button("Copy Packet Details", "COPY", "Check", function()
            if not curPk then say("Select a packet first") return end
            if F.setclip then
                F.setclip(S.PacketText(curPk))
                say("Copied packet #" .. tostring(curPk.id) .. " to clipboard")
            else
                say("Clipboard unsupported in this executor")
            end
        end)
        InspectCard:Button("Ignore Remote Name (ping)", "IGNORE", "Shield", function()
            if not curPk then say("Select a packet first") return end
            S.IgnoreNames[curPk.name] = true
            say("Ignoring all packets from: " .. tostring(curPk.name))
        end)
        InspectCard:Button("Block Selected Remote", "BLOCK", "Shield", function()
            if not curPk then say("Select a packet first") return end
            S.Blocked[curPk.remote] = true
            say("Blocked remote: " .. tostring(curPk.name))
        end)
        EnhanceCardButtons(inspectFrame)

        local ManageCard = r:Card("Save & Maintenance", nil, "Collect", {
            Subtitle = "Export decoded (.txt) & encrypted (.enc) packet logs"
        })
        local manageFrame = GetLastFrame(CurrentRightPage())
        -- FIX: Tag "packets" agar progress hanya update bar di tab ini
        AttachExportProgressBar(manageFrame, "Ready to save packet logs", "packets")
        local packetProgCb = MakeProgressCb("packets")

        ManageCard:Button("Save Filtered Packets", "SHOWN", "Check", function()
            say("Saving filtered packets...")
            local filtered = S.Filter(UI:GetValue("PkSearch") or "", UI:GetValue("PkDir") or "ALL")
            S.SavePackets(filtered, say, packetProgCb)
        end)
        ManageCard:Button("Save All Packets", "SAVE ALL", "Collect", function()
            say("Saving all packets...")
            S.SavePackets(nil, say, packetProgCb)
        end)
        ManageCard:Button("Clear Captured Packets", "CLEAR", "Minimize", function()
            S.Packets = {}
            curPk = nil
            if PacketViewerUI then PacketViewerUI:SetText("") end
            S.refreshP()
            say("Cleared packet log")
        end)
        ManageCard:Button("Unblock All Remotes & Rescan", "RESET", "Target", function()
            table.clear(S.Blocked)
            table.clear(S.IgnoreNames)
            table.clear(S.SpamSeen)
            table.clear(S.ShapeSeen)
            local list = S.ScanRemotes()
            RemoteCountCache = #list
            say("Unblocked all & watching " .. tostring(#list) .. " remotes")
        end)
        EnhanceCardButtons(manageFrame)
    end)
})

-- TAB 2: SCRIPT EXPLORER & DECOMPILER
local curS = nil
local ScriptListUI = nil
local ScriptViewerUI = nil
local ScriptCountBadge = nil

local function GetShownScripts()
    local q = (UI:GetValue("ScSearch") or ""):lower()
    local cat = UI:GetValue("ScCat") or "ALL"
    local out = {}
    for _, s in ipairs(S.Scripts) do
        if (cat == "ALL" or s.cat == cat) and (q == "" or s.path:lower():find(q, 1, true)) then
            out[#out + 1] = s
        end
    end
    return out
end

function S.refreshS()
    if not ScriptListUI then return end
    local shown = GetShownScripts()
    if ScriptCountBadge then
        ScriptCountBadge.Text = tostring(#shown) .. " Scripts"
    end
    ScriptListUI:Render(
        shown,
        function(s) return s.cat end,
        function(s) return s.path end,
        function(s) return curS == s end,
        function(s)
            curS = s
            if ScriptViewerUI then
                ScriptViewerUI:SetText("-- Decompiling " .. s.path .. " (" .. s.class .. ") ...")
            end
            task.spawn(function()
                local src, how = S.Source(s.inst)
                if curS ~= s or not ScriptViewerUI then return end
                if src and how ~= "bytecode" then
                    ScriptViewerUI:SetText("-- " .. s.path .. " [" .. s.class .. " | " .. how .. "]\n\n" .. src)
                    say("Decompiled: " .. s.name .. " (" .. how .. ")")
                elseif src then
                    ScriptViewerUI:SetText("-- " .. s.path .. "\n-- Bytecode only (decompile gagal) — hex dump, disimpan sebagai _bytecode.txt\n" .. bytesToHex(src:sub(1, 4096)))
                    say("Bytecode only: " .. s.name)
                else
                    ScriptViewerUI:SetText("-- " .. s.path .. "\n-- Decompile failed / script source inaccessible\n-- Reason: " .. tostring(how))
                    say("Decompile failed: " .. s.name)
                end
            end)
        end
    )
    RefreshDashboardStats()
end

feature("Layers", "Scripts")({
    center = center(function(c)
        c:Header("Script Explorer", "Browse Roblox, Game Map & Custom/Nil scripts with Luau decompiler", "Decompiler")

        c:Card("Discovered Scripts", "0 Scripts", "Layers", {
            Subtitle = "Classified by origin — click any script to decompile"
        })
        local scListFrame = GetLastFrame(CurrentCenterPage())
        ScriptCountBadge = FindCardActionLabel(scListFrame, "0 Scripts")
        ScriptListUI = AttachSelectList(scListFrame, 230, "Scanning scripts... or click Scan All Scripts below")

        local ScFilterCard = c:Card("Script Filter & Scanner", nil, "Sliders", {
            Subtitle = "Filter by script name/path or source category"
        })
        ScFilterCard:Input("Filter Script Path", "ScSearch", "Search script name, service or folder...", "", function()
            S.refreshS()
        end)
        local scFilterFrame = GetLastFrame(CurrentCenterPage())
        BindLiveInput(scFilterFrame, "ScSearch", function()
            S.refreshS()
        end)
        ScFilterCard:Dropdown("Origin Category", "ScCat", {"ALL", "Game", "Custom"}, "ALL", function()
            S.refreshS()
        end)
        ScFilterCard:Button("Scan All Scripts", "SCAN", "Layers", function()
            say("Scanning game & nil scripts...")
            S.ScanScripts()
            S.refreshS()
            say("Found " .. tostring(#S.Scripts) .. " scripts")
        end)
        EnhanceCardButtons(scFilterFrame)
    end),

    right = right(function(r)
        local DecompCard = r:Card("Decompiled Source", nil, "Chat", {
            Subtitle = "Read-only Luau viewer & 3-folder categorized exporter"
        })
        local decompFrame = GetLastFrame(CurrentRightPage())
        AttachStatusBanner(decompFrame, "Select a script to decompile")
        -- FIX: Tag "scripts" agar progress hanya update bar di tab ini
        AttachExportProgressBar(decompFrame, "Ready to decompile & save scripts (Roblox package excluded)", "scripts")
        local scriptProgCb = MakeProgressCb("scripts")
        ScriptViewerUI = AttachCodeViewer(decompFrame, 195, "Click any LocalScript or ModuleScript on the left to decompile...")

        DecompCard:Button("Copy Source to Clipboard", "COPY", "Check", function()
            local txt = ScriptViewerUI and ScriptViewerUI:GetText() or ""
            if txt == "" then say("No source loaded to copy") return end
            if F.setclip then
                F.setclip(txt)
                say("Copied script source (" .. tostring(#txt) .. " chars)")
            else
                say("Clipboard unsupported in this executor")
            end
        end)
        DecompCard:Button("Save Selected Script", "SAVE 1", "Layers", function()
            if not curS then say("Select a script first") return end
            if curS.cat == "Roblox" then say("Skip: ini Roblox package — hanya Game & Custom yang disimpan") return end
            say("Saving " .. curS.name .. "...")
            S.SaveScripts({curS}, say, scriptProgCb)
        end)
        DecompCard:Button("Save All Shown Scripts", "SAVE ALL", "Collect", function()
            local list = GetShownScripts()
            if #list == 0 then say("No scripts match current filter") return end
            say("Saving " .. tostring(#list) .. " scripts — Roblox package will be excluded...")
            S.SaveScripts(list, say, scriptProgCb)
        end)
        EnhanceCardButtons(decompFrame)
    end)
})

-- TAB 3: ASSETS & DATA SCANNER
local ScannedAssets = {}
local curAsset = nil
local AssetListUI = nil
local AssetViewerUI = nil
local AssetCountBadge = nil

local function GetShownAssets()
    local q = (UI:GetValue("AsSearch") or ""):lower()
    local out = {}
    for _, a in ipairs(ScannedAssets) do
        if q == "" or (a.path .. " " .. a.info):lower():find(q, 1, true) then
            out[#out + 1] = a
        end
    end
    return out
end

local function RefreshAssetsUI()
    if not AssetListUI then return {} end
    local shown = GetShownAssets()
    if AssetCountBadge then
        AssetCountBadge.Text = tostring(#shown) .. " Entries"
    end
    AssetListUI:Render(
        shown,
        function(a) return a.tag or "DATA" end,
        function(a) return a.info .. "  @ " .. a.path end,
        function(a) return curAsset == a end,
        function(a)
            curAsset = a
            local detail = "Entry: " .. a.info .. "\nPath:  " .. a.path
            if AssetViewerUI then
                AssetViewerUI:SetText(detail)
            end
            if F.setclip then
                F.setclip(a.path .. " | " .. a.info)
                say("Selected & copied: " .. a.info)
            else
                say("Selected: " .. a.info)
            end
        end
    )
    return shown
end

feature("Visuals", "Assets")({
    center = center(function(c)
        c:Header("Assets & Data", "Inspect ValueObjects, Attributes, Sounds, Meshes, Decals & Animations", "Scanner")

        c:Card("Scanned Assets & Values", "0 Entries", "Visuals", {
            Subtitle = "Click Scan Game Assets below to index live values & asset IDs"
        })
        local asListFrame = GetLastFrame(CurrentCenterPage())
        AssetCountBadge = FindCardActionLabel(asListFrame, "0 Entries")
        AssetListUI = AttachSelectList(asListFrame, 230, "Click 'Scan Game Assets' below to populate values, attributes & IDs")

        local AsFilterCard = c:Card("Asset Search & Scanner", nil, "Sliders", {
            Subtitle = "Search by ValueBase value, Attribute key, SoundId or MeshId"
        })
        AsFilterCard:Input("Filter Asset / Data", "AsSearch", "Search rbxassetid, Value, Attr, Sound...", "", function()
            RefreshAssetsUI()
        end)
        local asFilterFrame = GetLastFrame(CurrentCenterPage())
        BindLiveInput(asFilterFrame, "AsSearch", function()
            RefreshAssetsUI()
        end)
        AsFilterCard:Button("Scan Game Assets & Values", "SCAN", "Visuals", function()
            say("Scanning game instances & attributes...")
            SetExportProgress(35, "Scanning game assets & attributes...")
            task.spawn(function()
                ScannedAssets = S.ScanAssets()
                RefreshAssetsUI()
                local msg = "Indexed " .. tostring(#ScannedAssets) .. " asset/data entries"
                SetExportProgress(100, msg)
                say(msg)
            end)
        end)
        EnhanceCardButtons(asFilterFrame)
    end),

    right = right(function(r)
        local AsDetailCard = r:Card("Entry Inspector & Export", nil, "Collect", {
            Subtitle = "Inspect full instance path & save filtered entries to .txt"
        })
        local asDetailFrame = GetLastFrame(CurrentRightPage())
        AttachStatusBanner(asDetailFrame, "Ready to scan assets & data")
        -- FIX: Tag "assets" agar progress hanya update bar di tab ini
        AttachExportProgressBar(asDetailFrame, "Ready to scan & export assets", "assets")
        AssetViewerUI = AttachCodeViewer(asDetailFrame, 185, "Click any scanned entry on the left to inspect & auto-copy...")

        AsDetailCard:Button("Copy Selected Entry", "COPY", "Check", function()
            if not curAsset then say("Select an entry first") return end
            if F.setclip then
                F.setclip(curAsset.path .. " | " .. curAsset.info)
                say("Copied asset entry to clipboard")
            else
                say("Clipboard unsupported in this executor")
            end
        end)
        -- FIX: Gunakan assetProgCb agar progress hanya tampil di bar tab Assets
        local assetProgCb = MakeProgressCb("assets")
        AsDetailCard:Button("Save Shown Entries (.txt)", "SAVE", "Collect", function()
            local shown = GetShownAssets()
            if #shown == 0 then say("No asset entries to save — run Scan first") return end
            assetProgCb(25, "Formatting " .. tostring(#shown) .. " asset entries...")
            local lines = {}
            for _, a in ipairs(shown) do
                lines[#lines + 1] = a.info .. " @ " .. a.path
            end
            assetProgCb(75, "Writing asset entries to workspace...")
            S.write("Assets/assets_" .. os.date("%H%M%S") .. ".txt", table.concat(lines, "\n"), function(ok, p)
                local doneMsg = ok and ("Saved " .. tostring(#lines) .. " entries -> " .. p) or ("Save failed: " .. tostring(p))
                assetProgCb(ok and 100 or 0, doneMsg)
                say(doneMsg)
            end)
        end)
        EnhanceCardButtons(asDetailFrame)
    end)
})

-- TAB 4: MULTI-CODEC DECODER
local DecoderViewerUI = nil

feature("Shield", "Decoder")({
    center = center(function(c)
        c:Header("Multi-Codec Decoder", "Decode Base64, Hex, URL, JSON & Single-Byte XOR (with nested detection)", "Codec")

        local DecInCard = c:Card("Encoded Payload Input", nil, "Shield", {
            Subtitle = "Paste packet string or obfuscated value to decode automatically"
        })
        DecInCard:Input("Payload String", "DecInput", "Paste base64 / hex / url / json / xor string...", "")
        local decInFrame = GetLastFrame(CurrentCenterPage())
        BindLiveInput(decInFrame, "DecInput")

        DecInCard:Button("Decode Payload", "DECODE", "Bolt", function()
            local raw = UI:GetValue("DecInput") or ""
            if raw == "" then
                say("Paste an encoded string first")
                return
            end
            local res, method = S.decode(raw)
            if res then
                if DecoderViewerUI then
                    DecoderViewerUI:SetText("[" .. tostring(method) .. "]\n\n" .. res)
                end
                say("Decoded via " .. tostring(method))
            else
                if DecoderViewerUI then
                    DecoderViewerUI:SetText("Failed to decrypt / non-printable binary.\nWill be saved as .enc if exported.\n\nRaw (" .. tostring(#raw) .. " bytes):\n" .. ser(raw))
                end
                say("Failed to decrypt -> marked as .enc")
            end
        end)
        EnhanceCardButtons(decInFrame)

        local DecOutCard = c:Card("Decoded Output", "Result", "Chat", {
            Subtitle = "Detected encoding chain & plaintext result"
        })
        local decOutFrame = GetLastFrame(CurrentCenterPage())
        AttachStatusBanner(decOutFrame, "Paste payload above and click Decode")
        DecoderViewerUI = AttachCodeViewer(decOutFrame, 195, "Decoded output will appear here...")

        DecOutCard:Button("Copy Decoded Output", "COPY", "Check", function()
            local txt = DecoderViewerUI and DecoderViewerUI:GetText() or ""
            if txt == "" then say("Nothing decoded yet") return end
            if F.setclip then
                F.setclip(txt)
                say("Copied decoded output")
            end
        end)
        DecOutCard:Button("Save Decoded Result", "SAVE", "Collect", function()
            local raw = UI:GetValue("DecInput") or ""
            if raw == "" then say("Paste an input string first") return end
            local r, m = S.decode(raw)
            local ext = r and ".txt" or ".enc"
            local body = r and ("-- Method: " .. tostring(m) .. "\n" .. r) or raw
            S.write("Decoded/dec_" .. os.date("%H%M%S") .. ext, body, function(ok, p)
                say(ok and ("Saved: " .. p) or ("Save error: " .. tostring(p)))
            end)
        end)
        EnhanceCardButtons(decOutFrame)
    end)
    -- Panel kanan otomatis menampilkan Global Theme & Window Settings (sama seperti SampleGui.lua)
})

-- =========================================================================
-- KATEGORI 3: UTILITY & EXPORT
-- =========================================================================
if UI.Category then UI:Category("Utility") end

feature("Misc", "Export & Misc")({
    center = center(function(c)
        c:Header("Export & Session", "One-click ZIP archive bundler, workspace info & window controls", "Utility")

        local ExportCard = c:Card("Complete Archive Bundler", "Pure Luau ZIP", "Collect", {
            Subtitle = "Exports all Packets, Remote List, Decompiled Scripts & Assets into one .zip"
        })
        local expFrame = GetLastFrame(CurrentCenterPage())
        AttachStatusBanner(expFrame, ("Workspace folder: <executor>/%s/"):format(ROOT))
        -- FIX: Tag "exportall" agar progress hanya update bar di tab Export & Misc
        AttachExportProgressBar(expFrame, "Idle — Click Export ALL to build .zip (Roblox package excluded)", "exportall")
        local exportAllProgCb = MakeProgressCb("exportall")

        ExportCard:Button("Export ALL (ZIP Archive)", "EXPORT", "Collect", function()
            exportAllProgCb(1, "Starting full ZIP export — Roblox package excluded...")
            say("Starting full ZIP export...")
            S.ExportAll(say, exportAllProgCb)
        end)
        ExportCard:Button("Copy Save Directory Name", "COPY", "Check", function()
            if F.setclip then
                F.setclip(ROOT)
                say("Copied folder name: " .. ROOT)
            end
        end)
        EnhanceCardButtons(expFrame)

        local WinCard = c:Card("Window & Debugger Controls", nil, "Menu", {
            Subtitle = "Dock into R&8_DV floating squircle icon or unload debugger cleanly"
        })
        local winFrame = GetLastFrame(CurrentCenterPage())
        WinCard:Button("Minimize to Popup Icon", "HIDE", "Minimize", function()
            UI:MinimizeToIcon()
        end)
        WinCard:Button("Unload & Destroy Debugger", "EXIT", "Shield", function()
            S.Destroy()
        end)
        EnhanceCardButtons(winFrame)
    end)
})

-- =========================================================================
-- STARTUP SYNC & BACKGROUND AUTO-SCAN
-- =========================================================================
UI:SetTheme(UI.ThemeName)
RemoteCountCache = #S.ScanRemotes()
S.refreshP()

local lastRefreshAt = 0
local pendingRefresh = false
S.OnPacket = function()
    local now = tick()
    if now - lastRefreshAt >= 0.35 then
        lastRefreshAt = now
        S.refreshP()
    elseif not pendingRefresh then
        pendingRefresh = true
        task.delay(0.35, function()
            pendingRefresh = false
            lastRefreshAt = tick()
            if getgenv().__SDBG == S then
                S.refreshP()
            end
        end)
    end
end

say(("Ready | hook=%s | remotes=%d | dir: %s/"):format(tostring(S.Hooked), RemoteCountCache, ROOT))

task.spawn(function()
    S.ScanScripts()
    if getgenv().__SDBG == S then
        S.refreshS()
        RefreshDashboardStats()
    end
end)

function S.Destroy()
    for _, c in ipairs(S.Conns) do pcall(function() c:Disconnect() end) end
    for _, c in pairs(watched) do pcall(function() c:Disconnect() end) end
    S.OnPacket = nil
    S.Paused = true
    pcall(function() UI:Destroy() end)
    getgenv().__SDBG = nil
end

return S
