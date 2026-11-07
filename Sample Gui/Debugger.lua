--[[ Sample Debugger Complete (Delta executor). Load:
loadstring(game:HttpGet("https://YOUR_URL/Debugger.lua"))()
Features: Remote/Packet spy + content search, Script/Asset explorer (Roblox vs Game vs Custom),
decompile, multi-format decode, safe threaded save. Compatible with Infinite Yield remotes. ]]

if getgenv().__SDBG then pcall(function() getgenv().__SDBG.Destroy() end) end
local S = {}
getgenv().__SDBG = S

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local function cap(n) return getgenv()[n] or (getfenv and getfenv()[n]) end
local F = {
    writefile = cap("writefile"), makefolder = cap("makefolder"), isfolder = cap("isfolder"),
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
        local bytes = {}
        for i = 0, math.min(len - 1, 31) do
            bytes[#bytes + 1] = string.format("%02X", buffer.readu8(v, i))
        end
        return string.format("<buffer len=%d hex=%s%s>", len, table.concat(bytes, " "), len > 32 and "..." or "")
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
    if fn:find("^CorePackages") or fn:find("^CoreGui") or fn:find("RobloxGui") or fn:find("^Chat") and inst:IsDescendantOf(game:GetService("Chat")) and false then return "Roblox" end
    local names = {PlayerScripts=1, RbxCharacterSounds=1, PlayerModule=1, ControlModule=1, CameraModule=1, Animate=1, Health=1, Sound=1}
    if names[inst.Name] and (fn:find("PlayerScripts") or fn:find("^Workspace%.[^%.]+%.")) then return "Roblox" end
    if not inst.Parent then return "Custom" end
    return "Game"
end

-- ============ PACKET SPY ============
S.Packets = {}
S.MaxPackets = 2000
S.Paused = false
S.IncludeExecutor = true   -- true = also log calls from executor scripts (Infinite Yield etc.)
S.Blocked = {}
S.OnPacket = nil
local counter = 0

local function record(dir, remote, method, args, caller)
    if S.Paused or S.Blocked[remote] then return end
    counter += 1
    local parts = {}
    for i = 1, args.n do
        local raw = args[i]
        local dec, how = nil, nil
        if type(raw) == "string" then dec, how = S.decode(raw) end
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
    table.insert(S.Packets, pk)
    if #S.Packets > S.MaxPackets then table.remove(S.Packets, 1) end
    if S.OnPacket then task.defer(S.OnPacket, pk) end
end

local remoteMethods = {FireServer = true, InvokeServer = true}
local oldNC
local hooked = false
if F.hookmm and F.getnc then
    local ok = pcall(function()
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
        local wrappers = setmetatable({}, {__mode = "k"})
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
    -- every service, no exceptions
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
    task.spawn(function()
        if pk.method == "FireServer" then pk.remote:FireServer(unpack(args, 1, n))
        elseif pk.method == "InvokeServer" then pk.remote:InvokeServer(unpack(args, 1, n)) end
    end)
end

function S.PacketText(pk)
    local L = {("[#%d %s] %s %s"):format(pk.id, pk.time, pk.dir, pk.method), "Remote: " .. pk.path, "Class: " .. pk.class, "Caller: " .. tostring(pk.caller)}
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
        if (not dirF or dirF == "ALL" or pk.dir == dirF) and (q == "" or pk.search:find(q, 1, true)) then out[#out + 1] = pk end
    end
    return out
end

-- Save packets: decoded successfully -> .txt ; failed decrypt -> .enc (raw kept)
function S.SavePackets(list, cb)
    list = list or S.Packets
    local snapshot = {table.unpack(list)}
    task.spawn(function()
        local ok, dec, enc = {}, {}, {}
        for i, pk in ipairs(snapshot) do
            local bad = false
            for _, p in ipairs(pk.args) do if p.how == "encrypted" then bad = true end end
            local t = S.PacketText(pk)
            if bad then enc[#enc + 1] = t else dec[#dec + 1] = t end
            if i % 100 == 0 then task.wait() end
        end
        local stamp = os.date("%Y%m%d_%H%M%S")
        local sep = "\n" .. ("-"):rep(40) .. "\n"
        local msg = {}
        if #dec > 0 then S.write("Packets/packets_" .. stamp .. ".txt", table.concat(dec, sep), function(_, p) msg[#msg + 1] = p end) end
        if #enc > 0 then S.write("Packets/packets_" .. stamp .. ".enc", table.concat(enc, sep), function(_, p) msg[#msg + 1] = p end) end
        task.wait(0.3)
        if cb then cb(("Saved %d ok, %d encrypted\n%s"):format(#dec, #enc, table.concat(msg, "\n"))) end
    end)
end

-- ============ SCRIPT / ASSET DEBUG ============
S.Scripts = {}
function S.ScanScripts()
    local seen, list = {}, {}
    local function add(i)
        if i and not seen[i] and typeof(i) == "Instance" and (i:IsA("LuaSourceContainer")) then
            seen[i] = true
            list[#list + 1] = {inst = i, name = i.Name, class = i.ClassName, path = fullName(i), cat = S.classify(i)}
        end
    end
    if F.getscripts then for _, i in ipairs(safe(F.getscripts) or {}) do add(i) end end
    if F.getmods then for _, i in ipairs(safe(F.getmods) or {}) do add(i) end end
    if F.getnil then for _, i in ipairs(safe(F.getnil) or {}) do add(i) end end
    for _, svc in ipairs(game:GetChildren()) do
        if svc ~= CoreGui or true then
            pcall(function() for _, d in ipairs(svc:GetDescendants()) do add(d) end end)
        end
    end
    table.sort(list, function(a, b) if a.cat ~= b.cat then return a.cat < b.cat end return a.path < b.path end)
    S.Scripts = list
    return list
end

function S.Source(inst)
    if F.decompile then
        local ok, r = pcall(F.decompile, inst)
        if ok and type(r) == "string" and #r > 0 then return r, "decompiled" end
    end
    local ok, r = pcall(function() return inst.Source end)
    if ok and r and #r > 0 then return r, "source" end
    if F.getbc then
        local ok2, bc = pcall(F.getbc, inst)
        if ok2 and bc then return bc, "bytecode" end
    end
    return nil, "failed"
end

-- Save scripts into 3 separate folders: Roblox / Game / Custom
function S.SaveScripts(list, cb)
    list = list or S.Scripts
    local snap = {table.unpack(list)}
    task.spawn(function()
        local okc, failc, folders = 0, 0, {}
        for i, s in ipairs(snap) do
            local src, how = S.Source(s.inst)
            local sub = ({Roblox = "Scripts_Roblox", Game = "Scripts_GameMap", Custom = "Scripts_Custom"})[s.cat]
            local base = clean(s.path):sub(1, 120) .. "_" .. i
            if src and how ~= "bytecode" then
                okc += 1
                S.write(sub .. "/" .. base .. ".lua", "-- " .. s.path .. " (" .. s.class .. ", " .. how .. ")\n" .. src)
            elseif src then
                okc += 1
                S.write(sub .. "/" .. base .. ".enc", src) -- bytecode only, could not decompile
            else
                failc += 1
                S.write(sub .. "/" .. base .. ".enc", "-- " .. s.path .. "\n-- decompile failed: kept as encrypted placeholder")
            end
            folders[sub] = true
            if i % 15 == 0 then task.wait() end
        end
        task.wait(0.3)
        local fl = {}
        for k in pairs(folders) do fl[#fl + 1] = ROOT .. "/" .. k end
        if cb then cb(("Scripts ok=%d failed(.enc)=%d\nLocation (workspace folder of executor):\n%s"):format(okc, failc, table.concat(fl, "\n"))) end
    end)
end

-- Asset / data debug: Value objects, attributes, sounds/meshes/decals ids
function S.ScanAssets()
    local out = {}
    for _, d in ipairs(game:GetDescendants()) do
        local ok = pcall(function()
            if d:IsA("ValueBase") then out[#out + 1] = {path = fullName(d), info = d.ClassName .. " = " .. tostring(d.Value)}
            elseif d:IsA("Sound") then out[#out + 1] = {path = fullName(d), info = "Sound " .. d.SoundId}
            elseif d:IsA("Decal") or d:IsA("Texture") then out[#out + 1] = {path = fullName(d), info = d.ClassName .. " " .. d.Texture}
            elseif d:IsA("MeshPart") then out[#out + 1] = {path = fullName(d), info = "Mesh " .. d.MeshId .. " tex " .. d.TextureID}
            elseif d:IsA("Animation") then out[#out + 1] = {path = fullName(d), info = "Anim " .. d.AnimationId} end
            local at = d:GetAttributes()
            for k, v in pairs(at) do out[#out + 1] = {path = fullName(d), info = "Attr " .. k .. " = " .. tostring(v)} end
        end)
    end
    return out
end
-- Non-default / third-party hint: remotes + scripts outside Roblox core
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
-- files: { {name="folder/a.txt", data="..."}, ... } -> zip binary string
function S.BuildZip(files)
    local out, central, offset = {}, {}, 0
    local dt = os.date("*t")
    local dosTime = bit32.bor(bit32.lshift(dt.hour, 11), bit32.lshift(dt.min, 5), math.floor(dt.sec / 2))
    local dosDate = bit32.bor(bit32.lshift(math.max(dt.year - 1980, 0), 9), bit32.lshift(dt.month, 5), dt.day)
    for i, f in ipairs(files) do
        local name, data = f.name, f.data
        local crc, size = crc32(data), #data
        local lh = string.pack("<I4I2I2I2I2I2I4I4I4I2I2", 0x04034b50, 20, 0x0800, 0, dosTime, dosDate, crc, size, size, #name, 0)
        out[#out + 1] = lh out[#out + 1] = name out[#out + 1] = data
        central[#central + 1] = string.pack("<I4I2I2I2I2I2I2I4I4I4I2I2I2I2I2I4I4", 0x02014b50, 20, 20, 0x0800, 0, dosTime, dosDate, crc, size, size, #name, 0, 0, 0, 0, 0, offset) .. name
        offset += #lh + #name + size
        if i % 20 == 0 then task.wait() end
    end
    local cd = table.concat(central)
    out[#out + 1] = cd
    out[#out + 1] = string.pack("<I4I2I2I2I2I4I4I2", 0x06054b50, 0, 0, #files, #files, #cd, offset, 0)
    return table.concat(out)
end

-- Export EVERYTHING (all packets + all scripts + all assets) into one folder structure, zipped.
function S.ExportAll(cb)
    task.spawn(function()
        local ok, err = pcall(function()
            local files, stamp = {}, os.date("%Y%m%d_%H%M%S")
            local function add(n, d) files[#files + 1] = {name = n, data = d} end
            local stats = {pk = 0, pkEnc = 0, sc = 0, scEnc = 0, scBad = 0, assets = 0}
            if cb then cb("1/4 packets...") end
            local dec, enc = {}, {}
            local sep = "\n" .. ("-"):rep(40) .. "\n"
            for i, pk in ipairs({table.unpack(S.Packets)}) do
                local bad = false
                for _, p in ipairs(pk.args) do if p.how == "encrypted" then bad = true end end
                if bad then enc[#enc + 1] = S.PacketText(pk) else dec[#dec + 1] = S.PacketText(pk) end
                if i % 100 == 0 then task.wait() end
            end
            stats.pk, stats.pkEnc = #dec, #enc
            if #dec > 0 then add("Packets/packets.txt", table.concat(dec, sep)) end
            if #enc > 0 then add("Packets/packets_failed_decrypt.enc", table.concat(enc, sep)) end
            local rl = {}
            for _, r in ipairs(S.ScanRemotes()) do rl[#rl + 1] = r.ClassName .. "  " .. fullName(r) end
            add("Packets/remote_list.txt", table.concat(rl, "\n"))

            if cb then cb("2/4 scripts...") end
            local list = S.ScanScripts()
            local dirs = {Roblox = "Scripts_Roblox", Game = "Scripts_GameMap", Custom = "Scripts_Custom"}
            for i, s in ipairs(list) do
                local src, how = S.Source(s.inst)
                local base = dirs[s.cat] .. "/" .. clean(s.path):sub(1, 120) .. "_" .. i
                if src and how ~= "bytecode" then
                    local c, e = S.CompileCheck(src)
                    local tag = c == nil and "n/a" or (c and "ok" or ("FAIL: " .. tostring(e)))
                    add(base .. ".lua", "-- " .. s.path .. " (" .. s.class .. ", " .. how .. ", compile:" .. tag .. ")\n" .. src)
                    stats.sc += 1 if c == false then stats.scBad += 1 end
                elseif src then
                    add(base .. ".enc", src) stats.scEnc += 1
                else
                    add(base .. ".enc", "-- " .. s.path .. "\n-- decompile failed") stats.scEnc += 1
                end
                if i % 15 == 0 then task.wait() end
            end

            if cb then cb("3/4 assets...") end
            local ao = {}
            for _, a in ipairs(S.ScanAssets()) do ao[#ao + 1] = a.info .. " @ " .. a.path end
            stats.assets = #ao
            add("Assets/assets.txt", table.concat(ao, "\n"))
            add("README.txt", ("Sample Debugger export %s\nPackets ok=%d encrypted=%d\nScripts ok=%d (compile-fail=%d) encrypted/failed=%d\nAssets=%d\nFolders: Scripts_Roblox (bawaan), Scripts_GameMap (map game), Scripts_Custom (nil/buatan)\n"):format(stamp, stats.pk, stats.pkEnc, stats.sc, stats.scBad, stats.scEnc, stats.assets))

            if cb then cb("4/4 zipping " .. #files .. " files...") end
            assert(F.writefile, "writefile unsupported")
            ensure(ROOT)
            local path = ROOT .. "/Export_" .. stamp .. ".zip"
            local zip = S.BuildZip(files)
            local wok, werr = pcall(F.writefile, path, zip)
            if not wok then
                -- fallback: plain files if zip write fails
                for _, f in ipairs(files) do
                    local p, parts = ROOT .. "/Export_" .. stamp, f.name:split("/")
                    ensure(p)
                    for j = 1, #parts - 1 do p = p .. "/" .. parts[j] ensure(p) end
                    pcall(F.writefile, p .. "/" .. parts[#parts], f.data)
                end
                path = ROOT .. "/Export_" .. stamp .. "/ (zip failed: " .. tostring(werr) .. ")"
            end
            S.Saved[#S.Saved + 1] = path
            if cb then cb(("DONE %s | %d files, %.1f KB | pk=%d/%d scripts=%d/%d"):format(path, #files, #zip / 1024, stats.pk, stats.pkEnc, stats.sc, stats.scEnc)) end
        end)
        if not ok and cb then cb("Export error: " .. tostring(err)) end
    end)
end

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "SampleDebugger" gui.ResetOnSpawn = false gui.DisplayOrder = 999
pcall(function() gui.Parent = (F.gethui and F.gethui()) or CoreGui end)
if not gui.Parent then gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local function new(c, p, par)
    local o = Instance.new(c)
    for k, v in pairs(p) do o[k] = v end
    o.Parent = par
    return o
end
local BG, PN, AC, TX = Color3.fromRGB(24, 24, 30), Color3.fromRGB(36, 36, 46), Color3.fromRGB(0, 140, 255), Color3.fromRGB(230, 230, 235)
local function btn(par, text, pos, size, cb)
    local b = new("TextButton", {Text = text, Position = pos, Size = size, BackgroundColor3 = PN, TextColor3 = TX, Font = Enum.Font.Code, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = true}, par)
    new("UICorner", {CornerRadius = UDim.new(0, 4)}, b)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local main = new("Frame", {Size = UDim2.fromOffset(640, 420), Position = UDim2.fromScale(0.5, 0.5) - UDim2.fromOffset(320, 210), BackgroundColor3 = BG, BorderSizePixel = 0, Active = true}, gui)
new("UICorner", {CornerRadius = UDim2 and UDim.new(0, 8)}, main)
local title = new("TextLabel", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = PN, Text = "  Sample Debugger Complete" .. (S.Hooked and "" or "  [hook unsupported]"), TextColor3 = TX, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}, main)
new("UICorner", {CornerRadius = UDim.new(0, 8)}, title)
-- drag
do
    local drag, start, orig
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag, start, orig = true, i.Position, main.Position end
    end)
    S.Conns[#S.Conns + 1] = UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            main.Position = UDim2.new(orig.X.Scale, orig.X.Offset + d.X, orig.Y.Scale, orig.Y.Offset + d.Y)
        end
    end)
    S.Conns[#S.Conns + 1] = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end
btn(main, "X", UDim2.new(1, -28, 0, 3), UDim2.fromOffset(24, 22), function() S.Destroy() end)
local minBtn = btn(main, "-", UDim2.new(1, -56, 0, 3), UDim2.fromOffset(24, 22))

local body = new("Frame", {Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1}, main)
minBtn.MouseButton1Click:Connect(function() body.Visible = not body.Visible main.Size = body.Visible and UDim2.fromOffset(640, 420) or UDim2.fromOffset(640, 28) end)

-- status bar + save bar
local status = new("TextLabel", {Position = UDim2.new(0, 6, 1, -22), Size = UDim2.new(1, -12, 0, 20), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 220, 150), Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Text = "Ready", TextTruncate = Enum.TextTruncate.AtEnd}, body)
local function say(t) status.Text = tostring(t):gsub("\n", " | ") end

local tabs, pages = {}, {}
local function page(name, idx)
    local f = new("Frame", {Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -54), BackgroundTransparency = 1, Visible = false}, body)
    pages[name] = f
    tabs[name] = btn(body, name, UDim2.fromOffset(6 + (idx - 1) * 104, 3), UDim2.fromOffset(100, 24), function()
        for n, p in pairs(pages) do p.Visible = (n == name) tabs[n].BackgroundColor3 = (n == name) and AC or PN end
    end)
    return f
end
local function box(par, ph, pos, size)
    return new("TextBox", {PlaceholderText = ph, Text = "", Position = pos, Size = size, BackgroundColor3 = PN, TextColor3 = TX, PlaceholderColor3 = Color3.fromRGB(130, 130, 140), Font = Enum.Font.Code, TextSize = 13, ClearTextOnFocus = false, BorderSizePixel = 0}, par)
end
local function list(par, pos, size)
    return new("ScrollingFrame", {Position = pos, Size = size, BackgroundColor3 = PN, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, par)
end
local function viewer(par, pos, size)
    local sf = new("ScrollingFrame", {Position = pos, Size = size, BackgroundColor3 = PN, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY}, par)
    local t = new("TextBox", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextColor3 = TX, Font = Enum.Font.Code, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ClearTextOnFocus = false, TextEditable = false, MultiLine = true, Text = "", TextWrapped = true}, sf)
    return t
end
local function fill(sf, items, labelf, onclick)
    for _, c in ipairs(sf:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    for i = 1, math.min(#items, 300) do
        local it = items[i]
        local b = new("TextButton", {Size = UDim2.new(1, -6, 0, 18), Position = UDim2.fromOffset(0, (i - 1) * 18), BackgroundTransparency = 1, Text = labelf(it), TextColor3 = TX, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0}, sf)
        b.MouseButton1Click:Connect(function() onclick(it) end)
    end
    sf.CanvasSize = UDim2.fromOffset(0, math.min(#items, 300) * 18)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.None
end

-- PACKETS PAGE
local P = page("Packets", 1)
local pSearch = box(P, "Search content / value (e.g. 100, kill, name)...", UDim2.fromOffset(6, 0), UDim2.fromOffset(300, 24))
local dirBtn = btn(P, "ALL", UDim2.fromOffset(310, 0), UDim2.fromOffset(50, 24))
local pPause = btn(P, "Pause", UDim2.fromOffset(364, 0), UDim2.fromOffset(52, 24))
btn(P, "Clear", UDim2.fromOffset(420, 0), UDim2.fromOffset(48, 24), function() S.Packets = {} S.refreshP() end)
local execBtn = btn(P, "Exec:ON", UDim2.fromOffset(472, 0), UDim2.fromOffset(60, 24))
btn(P, "Rescan", UDim2.fromOffset(536, 0), UDim2.fromOffset(60, 24), function() say("Remotes: " .. #S.ScanRemotes()) end)
local pList = list(P, UDim2.fromOffset(6, 28), UDim2.new(0.45, -6, 1, -62))
local pView = viewer(P, UDim2.new(0.45, 2, 0, 28), UDim2.new(0.55, -8, 1, -62))
local curPk
local dirs, di = {"ALL", "OUT", "IN"}, 1
function S.refreshP()
    local items = S.Filter(pSearch.Text, dirs[di])
    local rev = {}
    for i = #items, 1, -1 do rev[#rev + 1] = items[i] end
    fill(pList, rev, function(pk) return ("%s #%d %s %s"):format(pk.dir, pk.id, pk.method == "OnClientEvent" and "<-" or "->", pk.name) end, function(pk) curPk = pk pView.Text = S.PacketText(pk) end)
end
dirBtn.MouseButton1Click:Connect(function() di = di % 3 + 1 dirBtn.Text = dirs[di] S.refreshP() end)
pPause.MouseButton1Click:Connect(function() S.Paused = not S.Paused pPause.Text = S.Paused and "Resume" or "Pause" end)
execBtn.MouseButton1Click:Connect(function() S.IncludeExecutor = not S.IncludeExecutor execBtn.Text = S.IncludeExecutor and "Exec:ON" or "Exec:OFF" end)
pSearch:GetPropertyChangedSignal("Text"):Connect(S.refreshP)
btn(P, "Save Shown", UDim2.fromOffset(6, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(90, 24), function() say("Saving...") S.SavePackets(S.Filter(pSearch.Text, dirs[di]), say) end)
btn(P, "Save All", UDim2.fromOffset(100, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(70, 24), function() say("Saving...") S.SavePackets(nil, say) end)
btn(P, "Replay", UDim2.fromOffset(174, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(60, 24), function() if curPk then S.Replay(curPk) say("Replayed #" .. curPk.id) end end)
btn(P, "Copy", UDim2.fromOffset(238, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(50, 24), function() if curPk and F.setclip then F.setclip(S.PacketText(curPk)) say("Copied") end end)
btn(P, "Block", UDim2.fromOffset(292, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(50, 24), function() if curPk then S.Blocked[curPk.remote] = true say("Blocked " .. curPk.name) end end)
local lastR = 0
S.OnPacket = function() if tick() - lastR > 0.4 then lastR = tick() S.refreshP() end end

-- SCRIPTS PAGE
local SC = page("Scripts", 2)
local sSearch = box(SC, "Filter script name/path...", UDim2.fromOffset(6, 0), UDim2.fromOffset(250, 24))
local catBtn = btn(SC, "ALL", UDim2.fromOffset(260, 0), UDim2.fromOffset(60, 24))
btn(SC, "Scan", UDim2.fromOffset(324, 0), UDim2.fromOffset(50, 24), function() S.ScanScripts() S.refreshS() say(#S.Scripts .. " scripts") end)
local sList = list(SC, UDim2.fromOffset(6, 28), UDim2.new(0.45, -6, 1, -62))
local sView = viewer(SC, UDim2.new(0.45, 2, 0, 28), UDim2.new(0.55, -8, 1, -62))
local cats, ci = {"ALL", "Roblox", "Game", "Custom"}, 1
local curS
local function shownScripts()
    local q, out = sSearch.Text:lower(), {}
    for _, s in ipairs(S.Scripts) do
        if (cats[ci] == "ALL" or s.cat == cats[ci]) and (q == "" or s.path:lower():find(q, 1, true)) then out[#out + 1] = s end
    end
    return out
end
function S.refreshS()
    fill(sList, shownScripts(), function(s) return ("[%s] %s"):format(s.cat, s.path) end, function(s)
        curS = s sView.Text = "Decompiling..."
        task.spawn(function()
            local src, how = S.Source(s.inst)
            sView.Text = src and (how == "bytecode" and "-- bytecode only (encrypted)" or src) or "-- decompile failed"
        end)
    end)
end
catBtn.MouseButton1Click:Connect(function() ci = ci % 4 + 1 catBtn.Text = cats[ci] S.refreshS() end)
sSearch:GetPropertyChangedSignal("Text"):Connect(S.refreshS)
btn(SC, "Save Shown", UDim2.fromOffset(6, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(90, 24), function() say("Saving scripts...") S.SaveScripts(shownScripts(), say) end)
btn(SC, "Save Selected", UDim2.fromOffset(100, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(100, 24), function() if curS then S.SaveScripts({curS}, say) end end)
btn(SC, "Copy", UDim2.fromOffset(204, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(50, 24), function() if F.setclip and sView.Text ~= "" then F.setclip(sView.Text) say("Copied") end end)

-- ASSETS PAGE
local A = page("Assets/Data", 3)
local aSearch = box(A, "Filter asset/data/value...", UDim2.fromOffset(6, 0), UDim2.fromOffset(300, 24))
local aList = list(A, UDim2.fromOffset(6, 28), UDim2.new(1, -12, 1, -62))
local assets = {}
local function refreshA()
    local q, out = aSearch.Text:lower(), {}
    for _, a in ipairs(assets) do if q == "" or (a.path .. " " .. a.info):lower():find(q, 1, true) then out[#out + 1] = a end end
    fill(aList, out, function(a) return a.info .. "  @ " .. a.path end, function(a) if F.setclip then F.setclip(a.path .. " " .. a.info) say("Copied") end end)
    return out
end
btn(A, "Scan", UDim2.fromOffset(310, 0), UDim2.fromOffset(50, 24), function() assets = S.ScanAssets() refreshA() say(#assets .. " entries") end)
aSearch:GetPropertyChangedSignal("Text"):Connect(refreshA)
btn(A, "Save Shown", UDim2.fromOffset(6, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(90, 24), function()
    local o = {}
    for _, a in ipairs(refreshA()) do o[#o + 1] = a.info .. " @ " .. a.path end
    S.write("Assets/assets_" .. os.date("%H%M%S") .. ".txt", table.concat(o, "\n"), function(ok, p) say(ok and ("Saved: " .. ROOT .. "/" .. p:gsub("^" .. ROOT .. "/", "")) or p) end)
end)

-- DECODER PAGE
local D = page("Decoder", 4)
local dIn = box(D, "Paste packet string (base64 / hex / url / json / xor)...", UDim2.fromOffset(6, 0), UDim2.new(1, -90, 0, 24))
local dOut = viewer(D, UDim2.fromOffset(6, 28), UDim2.new(1, -12, 1, -62))
btn(D, "Decode", UDim2.new(1, -80, 0, 0), UDim2.fromOffset(74, 24), function()
    local r, m = S.decode(dIn.Text)
    dOut.Text = r and ("[" .. m .. "]\n" .. r) or "Failed to decrypt -> will be saved as .enc"
end)
btn(D, "Save", UDim2.fromOffset(6, 0) + UDim2.new(0, 0, 1, -30), UDim2.fromOffset(60, 24), function()
    local r, m = S.decode(dIn.Text)
    S.write("Decoded/dec_" .. os.date("%H%M%S") .. (r and ".txt" or ".enc"), r or dIn.Text, function(ok, p) say(ok and ("Saved: " .. p) or p) end)
end)

local exportBtn = btn(main, "Export ALL (zip)", UDim2.new(1, -176, 0, 3), UDim2.fromOffset(116, 22), function() say("Exporting...") S.ExportAll(say) end)
exportBtn.BackgroundColor3 = AC
pages["Packets"].Visible = true tabs["Packets"].BackgroundColor3 = AC
say(("Ready | hook=%s | save dir: <executor workspace>/%s/"):format(tostring(S.Hooked), ROOT))
task.spawn(function() S.ScanScripts() S.refreshS() end)

function S.Destroy()
    for _, c in ipairs(S.Conns) do pcall(function() c:Disconnect() end) end
    for _, c in pairs(watched) do pcall(function() c:Disconnect() end) end
    S.OnPacket = nil S.Paused = true
    gui:Destroy()
    getgenv().__SDBG = nil
end
return S
