--[[
    SkyP_R8_Teleport.lua — Teleport & Interactive Map Inspector
    Menggunakan shell GUI R&8_DV (SampleGui.lua) tanpa memisahkan jendela.
    Catatan: Hanya mendukung teleport ke koordinat/tile valid (non-solid, dalam batas world)
    dengan interval aman (tidak menyertakan spam/bypass anti-cheat).
]]

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
assert(okFetch and type(rawScript) == "string" and #rawScript > 128, "[R&8_DV] HTTP 404: Pastikan file r&8_dv.lua tersedia di Mytzcodes/R-8 (branch main).")

local ImGui = loadstring(rawScript)()

-- 2. Inisialisasi Jendela R&8_DV (Shell sama persis dengan SampleGui.lua)
local UI = ImGui({
    Title = "DRY CURSED - IMGUI",
    BrandTitle = "R&8_DV",
    BrandSubtitle = "IMGUI SUITE",
    Theme = "Minimalist Monochrome",
    CheckboxStyle = "Modern",
    LetterSpacing = 1,
    AutoLoading = false,
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

local ThemeChoices = UI.GetThemes and UI:GetThemes() or {
    "Minimalist Monochrome",
    "Blue Night Sky",
    "Violet Amethyst",
    "Orange Sand",
    "Midnight Monokai",
}

-- ═══════════════════════════════════════════════════════════════════════════
--  DISCOVERY & POSITION / TILE VALIDATION HELPERS (READ + SAFE MOVE)
-- ═══════════════════════════════════════════════════════════════════════════
local Players           = game:GetService("Players")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local LP                = Players.LocalPlayer

local H = {
    gt         = nil,
    Net        = nil,
    ItemDB     = nil,
    stateObj   = nil,
    renderFn   = nil,
    pxIdx      = nil,
    pyIdx      = nil,
    vxIdx      = nil,
    vyIdx      = nil,
    prevXIdx   = nil,
    prevYIdx   = nil,
    goPxIdx    = nil,
    goPyIdx    = nil,
    goPrevXIdx = nil,
    goPrevYIdx = nil,
    goVxIdx    = nil,
    goVyIdx    = nil,
}

local function uv(fn, idx)
    if type(fn) ~= "function" then return nil end
    local getter = (type(debug) == "table" and debug.getupvalue) or getupvalue
    if type(getter) == "function" then
        local ok, _, val = pcall(getter, fn, idx)
        if ok then return val end
    end
    local getterAll = (type(debug) == "table" and debug.getupvalues) or getupvalues
    if type(getterAll) == "function" then
        local ok, ups = pcall(getterAll, fn)
        if ok and type(ups) == "table" then
            return ups[idx]
        end
    end
    return nil
end

local function suv(fn, idx, val)
    if type(fn) ~= "function" or not idx then return false end
    local setter = (type(debug) == "table" and debug.setupvalue) or setupvalue
    if type(setter) == "function" then
        return (pcall(setter, fn, idx, val))
    end
    return false
end

local function isValidGT(t)
    if type(t) ~= "table" then return false end
    return type(rawget(t, "fg")) == "table"
        and type(rawget(t, "bg")) == "table"
        and type(rawget(t, "w")) == "number"
        and type(rawget(t, "h")) == "number"
        and type(rawget(t, "name")) == "string"
        and type(rawget(t, "goTo")) == "function"
        and type(rawget(t, "touchBlocks")) == "function"
end

local function isValidNet(t)
    if type(t) ~= "table" then return false end
    local tile = rawget(t, "tile")
    local move = rawget(t, "move")
    return type(tile) == "table" and type(rawget(tile, "send")) == "function"
        and type(move) == "table" and type(rawget(move, "send")) == "function"
        and type(rawget(t, "worldTag")) == "function"
end

local function isValidItemDB(t)
    if type(t) ~= "table" then return false end
    local d2 = rawget(t, 2)
    local d3 = rawget(t, 3)
    return type(d2) == "table" and rawget(d2, "name") == "Dirt"
        and type(d3) == "table" and rawget(d3, "kind") == "seed"
end

local function isValidStateObj(t)
    if type(t) ~= "table" then return false end
    return type(rawget(t, "state")) == "function"
        and type(rawget(t, "RAY")) == "table"
        and type(rawget(t, "onDie")) == "function"
        and type(rawget(t, "onHurt")) == "function"
end

local function inspectUpvalues(gt)
    if not gt then return end

    -- 1. Cari posisi live dari H.stateObj jika tersedia (untuk verifikasi akurat)
    local refX, refY = nil, nil
    if H.stateObj and type(H.stateObj.state) == "function" then
        local okSt, st = pcall(H.stateObj.state)
        if okSt and type(st) == "table" and type(st.x) == "number" and type(st.y) == "number" then
            refX, refY = st.x, st.y
        end
    end

    -- 2. Inspect upvalues milik gt.goTo (Game.lua L10758: px, py, gt, dead, prevX, prevY, vx, vy, ...)
    local goTo = rawget(gt, "goTo")
    if type(goTo) == "function" then
        for idx = 1, 14 do
            local v1 = uv(goTo, idx)
            local v2 = uv(goTo, idx + 1)
            local v3 = uv(goTo, idx + 2)
            if type(v1) == "number" and type(v2) == "number" and v3 == gt then
                H.goPxIdx = idx
                H.goPyIdx = idx + 1
                if type(uv(goTo, idx + 4)) == "number" and type(uv(goTo, idx + 5)) == "number" then
                    H.goPrevXIdx = idx + 4
                    H.goPrevYIdx = idx + 5
                end
                if type(uv(goTo, idx + 6)) == "number" and type(uv(goTo, idx + 7)) == "number" then
                    H.goVxIdx = idx + 6
                    H.goVyIdx = idx + 7
                end
                break
            end
        end
        if not H.goPxIdx then
            local v1, v2 = uv(goTo, 1), uv(goTo, 2)
            if type(v1) == "number" and type(v2) == "number" then
                H.goPxIdx, H.goPyIdx = 1, 2
            end
        end
    end

    if (not refX or not refY) and type(goTo) == "function" and H.goPxIdx and H.goPyIdx then
        local gx, gy = uv(goTo, H.goPxIdx), uv(goTo, H.goPyIdx)
        if type(gx) == "number" and type(gy) == "number" then
            refX, refY = gx, gy
        end
    end

    -- 3. Cari RenderStepped connection milik Game.lua (uv(fn, 1) == gt + UIScale + 64)
    local getconns = getconnections
    if type(getconns) == "function" and not H.renderFn then
        local okConns, conns = pcall(getconns, RunService.RenderStepped)
        if okConns and type(conns) == "table" then
            for _, c in ipairs(conns) do
                local fn = type(c) == "table" and (c.Function or c["function"]) or nil
                if type(fn) == "function" and uv(fn, 1) == gt then
                    local hasScale, has64 = false, false
                    for idx = 1, 80 do
                        local val = uv(fn, idx)
                        if val == nil and idx > 65 then break end
                        if typeof(val) == "Instance" and val:IsA("UIScale") then
                            hasScale = true
                        elseif val == 64 then
                            has64 = true
                        end
                    end
                    if hasScale and has64 then
                        H.renderFn = fn
                        break
                    end
                end
            end
        end
    end

    -- 4. Cocokkan indeks px/py/prev/vel di RenderStepped (Game.lua L114: vx, vy, facing, px, py, grounded, prevX, prevY)
    if H.renderFn and refX and refY then
        local fallbackIdx = nil
        for idx = 10, 45 do
            local vx = uv(H.renderFn, idx)
            local vy = uv(H.renderFn, idx + 1)
            if type(vx) == "number" and type(vy) == "number"
                and math.abs(vx - refX) < 0.05 and math.abs(vy - refY) < 0.05 then
                if not fallbackIdx then fallbackIdx = idx end
                local isGroundedBool = type(uv(H.renderFn, idx + 2)) == "boolean"
                local hasFacingNum = type(uv(H.renderFn, idx - 1)) == "number"
                if isGroundedBool and hasFacingNum then
                    H.pxIdx = idx
                    H.pyIdx = idx + 1
                    break
                end
            end
        end
        if not H.pxIdx and fallbackIdx then
            H.pxIdx = fallbackIdx
            H.pyIdx = fallbackIdx + 1
        end
        if H.pxIdx then
            local idx = H.pxIdx
            if type(uv(H.renderFn, idx - 3)) == "number" and type(uv(H.renderFn, idx - 2)) == "number" then
                H.vxIdx = idx - 3
                H.vyIdx = idx - 2
            end
            if type(uv(H.renderFn, idx + 3)) == "number" and type(uv(H.renderFn, idx + 4)) == "number" then
                H.prevXIdx = idx + 3
                H.prevYIdx = idx + 4
            end
        end
    end
end

local function discoverGame()
    -- 1. Prioritaskan require langsung dari ReplicatedStorage.Shared agar akurat
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    if sh then
        if not H.ItemDB then
            local m = sh:FindFirstChild("ItemDB")
            if m then
                local okReq, res = pcall(require, m)
                if okReq and isValidItemDB(res) then
                    H.ItemDB = res
                end
            end
        end
        if not H.Net then
            local m = sh:FindFirstChild("Net")
            if m then
                local okReq, res = pcall(require, m)
                if okReq and isValidNet(res) then
                    H.Net = res
                end
            end
        end
    end

    -- 2. Scan getgc(true) untuk modul internal client (gt, stateObj, fallback Net/ItemDB)
    if type(getgc) == "function" then
        local okGc, gc = pcall(getgc, true)
        if okGc and type(gc) == "table" then
            for i = 1, #gc do
                local v = gc[i]
                if type(v) == "table" then
                    if not H.gt and isValidGT(v) then
                        H.gt = v
                    elseif not H.Net and isValidNet(v) then
                        H.Net = v
                    elseif not H.ItemDB and isValidItemDB(v) then
                        H.ItemDB = v
                    elseif not H.stateObj and isValidStateObj(v) then
                        H.stateObj = v
                    end
                    if H.gt and H.Net and H.ItemDB and H.stateObj then break end
                end
            end
        end
    end

    if H.gt then
        pcall(inspectUpvalues, H.gt)
    end
    return H.gt ~= nil
end

local function getItemInfo(id)
    return (H.ItemDB and id and id ~= 0) and H.ItemDB[id] or nil
end

local function isTileSolid(tx, ty)
    local gt = H.gt
    if not gt or not gt.fg or not gt.fg[ty] then return false end
    local id = gt.fg[ty][tx] or 0
    if id == 0 then return false end
    local info = getItemInfo(id)
    if not info then return false end
    if info.door or info.entrance then return false end
    return info.solid == true
end

local function validateTile(tx, ty)
    local gt = H.gt
    if not gt or (gt.name or "") == "" or not gt.w or not gt.h then
        return false, "Belum masuk world / modul gt belum ditemukan"
    end
    if type(tx) ~= "number" or type(ty) ~= "number" then
        return false, "Koordinat harus berupa angka"
    end
    tx = math.floor(tx)
    ty = math.floor(ty)
    if tx < 0 or tx >= gt.w or ty < 0 or ty >= gt.h then
        return false, string.format("Di luar batas world (X: 0..%d, Y: 0..%d)", gt.w - 1, gt.h - 1)
    end
    if isTileSolid(tx, ty) then
        return false, string.format("Tile (%d, %d) SOLID / terhalang block", tx, ty)
    end
    return true, string.format("VALID Tile (%d, %d) | Stats (%d, %d)", tx, ty, tx + 1, ty + 1), tx, ty
end

local function readCurrentPos()
    local x, y = nil, nil
    if H.stateObj and type(H.stateObj.state) == "function" then
        local okSt, st = pcall(H.stateObj.state)
        if okSt and type(st) == "table" and type(st.x) == "number" and type(st.y) == "number" then
            x, y = st.x, st.y
        end
    end
    if (not x or not y) and H.renderFn and H.pxIdx and H.pyIdx then
        local vx = uv(H.renderFn, H.pxIdx)
        local vy = uv(H.renderFn, H.pyIdx)
        if type(vx) == "number" and type(vy) == "number" then
            x, y = vx, vy
        end
    end
    if (not x or not y) and H.gt and type(H.gt.goTo) == "function" then
        if not H.goPxIdx then pcall(inspectUpvalues, H.gt) end
        if H.goPxIdx and H.goPyIdx then
            local vx = uv(H.gt.goTo, H.goPxIdx)
            local vy = uv(H.gt.goTo, H.goPyIdx)
            if type(vx) == "number" and type(vy) == "number" then
                x, y = vx, vy
            end
        end
    end
    x = x or 0
    y = y or 1
    -- Sesuai Game.lua L10643-10646: My Stats menampilkan floor(x)+1, floor(y-0.01)+1
    local tx = math.floor(x)
    local ty = math.floor(y - 0.01)
    if H.gt and H.gt.w and H.gt.h then
        tx = math.clamp(tx, 0, H.gt.w - 1)
        ty = math.clamp(ty, 0, H.gt.h - 1)
    end
    return {
        x  = x,
        y  = y,
        tx = tx,
        ty = ty,
        sx = tx + 1,
        sy = ty + 1,
    }
end

local function teleportToValidTile(tx, ty)
    local okValid, msg, cx, cy = validateTile(tx, ty)
    if not okValid then
        return false, msg
    end
    local gt = H.gt
    local px = cx + 0.5
    local py = cy + 1
    if not H.pxIdx and H.gt then
        pcall(inspectUpvalues, H.gt)
    end
    if H.renderFn and H.pxIdx and H.pyIdx then
        suv(H.renderFn, H.pxIdx, px)
        suv(H.renderFn, H.pyIdx, py)
        if H.prevXIdx then suv(H.renderFn, H.prevXIdx, px) end
        if H.prevYIdx then suv(H.renderFn, H.prevYIdx, py) end
        if H.vxIdx then suv(H.renderFn, H.vxIdx, 0) end
        if H.vyIdx then suv(H.renderFn, H.vyIdx, 0) end
        gt.stuckAt = nil
        gt.portalGo = nil
    end
    if type(gt.goTo) == "function" then
        pcall(gt.goTo, cx, cy)
    end
    if H.Net and H.Net.move and type(H.Net.move.send) == "function" then
        pcall(function()
            H.Net.move.send({
                x     = px,
                y     = py,
                vx    = 0,
                vy    = 0,
                flags = 2,
                t     = math.floor((os.clock() * 1000) % 65535),
            })
        end)
    end
    return true, string.format("Teleported -> Tile (%d, %d) | Stats (%d, %d)", cx, cy, cx + 1, cy + 1)
end

local function pickRandomValidTile()
    local gt = H.gt
    if not gt or not gt.w or not gt.h then return nil end
    local candidates = {}
    for y = 1, gt.h - 2 do
        for x = 1, gt.w - 2 do
            if not isTileSolid(x, y) then
                candidates[#candidates + 1] = { x = x, y = y }
            end
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

local state = {
    selectedX   = nil,
    selectedY   = nil,
    patrolOn    = false,
    patrolDelay = 1.2,
    renderMapFn = nil,
}

local initialWorldName = "-"

-- =========================================================================
-- KATEGORI 1: OVERVIEW (Shell & Panel Kanan sama dengan SampleGui.lua)
-- =========================================================================
if UI.Category then UI:Category("Overview") end

feature("Home", "Home")({
    center = center(function(c)
        c:Header("Teleport & Position", "Live coordinate inspector & validated tile teleportation", "Ready")

        c:StatRow({
            { Icon = "Teleports", Label = "Teleport Mode", Value = "Valid Only" },
            { Icon = "Shield",    Label = "Validasi Tile", Value = "Strict" },
            { Icon = "Clock",     Label = "World",         Value = initialWorldName },
        })

        local InfoCard = c:Card("Status Lokasi Live", "Live", "Player", {
            Subtitle = "Posisi karakter saat ini dan status validasi tile"
        })
        InfoCard:Button("Refresh / Scan Ulang Modul", "SCAN", "Bolt", function()
            local ok = pcall(discoverGame)
            if ok and H.gt then
                local statusStr = string.format("World: %s | ItemDB: %s | State: %s",
                    tostring(H.gt.name ~= "" and H.gt.name or "-"),
                    H.ItemDB and "OK" or "NIL",
                    (H.stateObj or H.renderFn or H.goPxIdx) and "OK" or "NIL")
                UI:SetValue("ValidStatusDisplay", statusStr)
            else
                UI:SetValue("ValidStatusDisplay", "Modul belum ditemukan")
            end
            if state.renderMapFn then state.renderMapFn(true) end
        end)
        InfoCard:ActivityTimeline({
            { Text = "Koordinat Stats (1-based) & Tile (0-based) tampil di tab Teleport", Time = "Live" },
            { Text = "Hanya teleport ke tile non-solid yang valid", Time = "Safe" },
        })
    end),

    -- Panel Kanan Global: Dipertahankan sama persis dengan SampleGui.lua
    right = right(function(r)
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
        LayoutCard:Toggle("Rounded Borders", "RoundedState", true, function(stateVal)
            UI:SetRounded(stateVal)
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
    end)
})

-- =========================================================================
-- KATEGORI 2: MODULES (Teleport Manual + Validasi + Map Picker + Start/Stop)
-- =========================================================================
if UI.Category then UI:Category("Modules") end

feature("Teleports", "Teleport")({
    center = center(function(c)
        c:Header("Teleport & Map", "Input manual tervalidasi, lokasi live, & pilih tile di peta", "Active")

        local PosCard = c:Card("Lokasi Saat Ini & Validasi", "Live", "Player", {
            Subtitle = "Stats cocok dengan My Stats (1-based) | Tile (0-based)"
        })
        PosCard:Input("Lokasi Saat Ini (Live)", "LivePosDisplay", "Menunggu world...", "")
        PosCard:Input("Status Validasi", "ValidStatusDisplay", "Belum ada aksi", "")

        local ManualCard = c:Card("Manual Teleport (Harus Valid)", nil, "Teleports", {
            Subtitle = "Masukkan koordinat Tile X (0..99) & Y (0..59) lalu cek atau teleport"
        })
        ManualCard:Input("Target Tile X (0..99)", "TpManualX", "0 .. 99", "0")
        ManualCard:Input("Target Tile Y (0..59)", "TpManualY", "0 .. 59", "0")
        ManualCard:Button("Cek Validasi Koordinat", "CEK", "Shield", function()
            local tx = tonumber(UI:GetValue("TpManualX"))
            local ty = tonumber(UI:GetValue("TpManualY"))
            local ok, msg, cx, cy = validateTile(tx, ty)
            UI:SetValue("ValidStatusDisplay", msg)
            if ok then
                state.selectedX = cx
                state.selectedY = cy
                if state.renderMapFn then state.renderMapFn(true) end
            end
        end)
        ManualCard:Button("Teleport ke Koordinat Valid", "TELEPORT", "Teleports", function()
            local tx = tonumber(UI:GetValue("TpManualX"))
            local ty = tonumber(UI:GetValue("TpManualY"))
            local ok, msg = teleportToValidTile(tx, ty)
            UI:SetValue("ValidStatusDisplay", (ok and "[OK] " or "[INVALID] ") .. msg)
            if state.renderMapFn then state.renderMapFn(true) end
        end)

        local PatrolCard = c:Card("Random Valid Tile Patrol (Safe Interval)", nil, "Bolt", {
            Subtitle = "Pindah ke tile valid acak dengan jeda aman (Start / Stop)"
        })
        PatrolCard:Slider("Interval Jeda Aman (detik)", "PatrolDelaySec", 1.0, 5.0, 1.5, " s", function(val)
            state.patrolDelay = math.max(1.0, tonumber(val) or 1.5)
        end, 0.2)
        PatrolCard:Button("Start Random Valid Teleport", "START", "Bolt", function()
            if state.patrolOn then return end
            if not H.gt then pcall(discoverGame) end
            state.patrolOn = true
            UI:SetValue("ValidStatusDisplay", "Patrol aktif (interval aman)")
            task.spawn(function()
                while state.patrolOn do
                    local pick = pickRandomValidTile()
                    if pick then
                        state.selectedX = pick.x
                        state.selectedY = pick.y
                        UI:SetValue("TpManualX", tostring(pick.x))
                        UI:SetValue("TpManualY", tostring(pick.y))
                        local ok, msg = teleportToValidTile(pick.x, pick.y)
                        UI:SetValue("ValidStatusDisplay", (ok and "[PATROL] " or "[ERR] ") .. msg)
                        if state.renderMapFn then state.renderMapFn(true) end
                    else
                        UI:SetValue("ValidStatusDisplay", "Tidak ada tile valid ditemukan")
                    end
                    task.wait(math.max(1.0, state.patrolDelay))
                end
            end)
        end)
        PatrolCard:Button("Stop Random Teleport", "STOP", "Shield", function()
            state.patrolOn = false
            UI:SetValue("ValidStatusDisplay", "Patrol dihentikan.")
        end)

        local MapCard = c:Card("Peta World Interaktif (Pilih Tile)", nil, "Visuals", {
            Subtitle = "Ketuk tile di peta untuk memilih X/Y, drag untuk geser, +/- atau FIT untuk zoom"
        })
        MapCard:Input("Map Anchor (Embedded)", "__MAP_ANCHOR__", "__MAP_ANCHOR_KEY__", "__MAP_ANCHOR_KEY__")
        MapCard:Button("Render Ulang Peta", "REFRESH", "Visuals", function()
            pcall(discoverGame)
            if state.renderMapFn then state.renderMapFn(true) end
        end)
    end)
})

-- ═══════════════════════════════════════════════════════════════════════════
--  EMBEDDED MINIMAP INSIDE R&8_DV MapCard (BUKAN GUI TERPISAH)
-- ═══════════════════════════════════════════════════════════════════════════
task.spawn(function()
    local anchorBox = nil
    for _ = 1, 60 do
        for _, rootParent in ipairs({ CoreGui, LP and LP:FindFirstChildOfClass("PlayerGui") }) do
            if rootParent then
                for _, desc in ipairs(rootParent:GetDescendants()) do
                    if desc:IsA("TextBox") and desc.Text == "__MAP_ANCHOR_KEY__" then
                        anchorBox = desc
                        break
                    end
                end
            end
            if anchorBox then break end
        end
        if anchorBox then break end
        task.wait(0.1)
    end
    if not anchorBox or not anchorBox.Parent then return end

    -- anchorBox parent adalah BoxHolder (height 78) di dalam MapCard
    local rowContainer = anchorBox.Parent
    for _, ch in ipairs(rowContainer:GetChildren()) do
        if not ch:IsA("UICorner") and not ch:IsA("UIStroke") then
            ch:Destroy()
        end
    end
    rowContainer.Size = UDim2.new(1, 0, 0, 260)
    rowContainer.BackgroundColor3 = Color3.fromRGB(11, 14, 20)
    rowContainer.ClipsDescendants = true

    local parentScroller = rowContainer:FindFirstAncestorOfClass("ScrollingFrame")

    local mapView = Instance.new("Frame")
    mapView.Size = UDim2.new(1, -12, 1, -38)
    mapView.Position = UDim2.fromOffset(6, 6)
    mapView.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    mapView.BorderSizePixel = 0
    mapView.ClipsDescendants = true
    mapView.Active = true
    mapView.Parent = rowContainer

    local mapCanvas = Instance.new("Frame")
    mapCanvas.BackgroundTransparency = 0
    mapCanvas.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    mapCanvas.BorderSizePixel = 0
    mapCanvas.Parent = mapView

    local canvasStroke = Instance.new("UIStroke")
    canvasStroke.Color = Color3.fromRGB(70, 86, 114)
    canvasStroke.Thickness = 1
    canvasStroke.Parent = mapCanvas

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -12, 0, 24)
    bar.Position = UDim2.new(0, 6, 1, -28)
    bar.BackgroundTransparency = 1
    bar.Parent = rowContainer

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, -160, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextColor3 = Color3.fromRGB(203, 213, 225)
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
    infoLbl.Text = "Ketuk tile di dalam kotak peta..."
    infoLbl.Parent = bar

    local function makeMiniBtn(txt, xOffset, width)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(width or 26, 22)
        b.Position = UDim2.new(1, xOffset, 0, 1)
        b.BackgroundColor3 = Color3.fromRGB(31, 35, 44)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = Color3.fromRGB(240, 244, 250)
        b.Text = txt
        b.BorderSizePixel = 0
        b.Parent = bar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = b
        return b
    end

    local fitBtn     = makeMiniBtn("FIT", -154, 32)
    local zoomInBtn  = makeMiniBtn("+",   -118, 26)
    local zoomOutBtn = makeMiniBtn("-",    -88, 26)
    local tpBtn      = makeMiniBtn("TP",   -58, 54)
    tpBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    tpBtn.TextColor3 = Color3.new(0, 0, 0)

    local mapTilePx = 3.2
    local mapPanX, mapPanY = 6, 6
    local didInitialFit = false
    local fittedW, fittedH = nil, nil
    local mapPool = {}
    local lastDraw = 0

    local function isMapVisible()
        if not rowContainer or not rowContainer.Parent or not mapView.Visible then return false end
        return mapView.AbsoluteSize.X > 10 and mapView.AbsoluteSize.Y > 10
    end

    local function clampPan()
        local w = (H.gt and H.gt.w) or 100
        local h = (H.gt and H.gt.h) or 60
        local vw = math.max(100, mapView.AbsoluteSize.X)
        local vh = math.max(80, mapView.AbsoluteSize.Y)
        local cw = w * mapTilePx
        local ch = h * mapTilePx
        if cw <= vw then
            mapPanX = math.clamp(mapPanX, 4, math.max(4, vw - cw - 4))
        else
            mapPanX = math.clamp(mapPanX, vw - cw - 12, 12)
        end
        if ch <= vh then
            mapPanY = math.clamp(mapPanY, 4, math.max(4, vh - ch - 4))
        else
            mapPanY = math.clamp(mapPanY, vh - ch - 12, 12)
        end
    end

    local function updateTransform()
        local w = (H.gt and H.gt.w) or 100
        local h = (H.gt and H.gt.h) or 60
        clampPan()
        mapCanvas.Size = UDim2.fromOffset(w * mapTilePx, h * mapTilePx)
        mapCanvas.Position = UDim2.fromOffset(mapPanX, mapPanY)
    end

    local function fitMapToView()
        local w = (H.gt and H.gt.w) or 100
        local h = (H.gt and H.gt.h) or 60
        local vw = math.max(120, mapView.AbsoluteSize.X)
        local vh = math.max(80, mapView.AbsoluteSize.Y)
        local fit = math.clamp(math.min((vw - 10) / w, (vh - 10) / h), 2, 18)
        mapTilePx = fit
        mapPanX = math.floor((vw - w * fit) * 0.5)
        mapPanY = math.floor((vh - h * fit) * 0.5)
        didInitialFit = true
        fittedW, fittedH = w, h
        updateTransform()
    end

    local function applyZoom(newPx)
        local vw = math.max(100, mapView.AbsoluteSize.X)
        local vh = math.max(80, mapView.AbsoluteSize.Y)
        local oldPx = mapTilePx
        local clamped = math.clamp(newPx, 2, 18)
        if math.abs(clamped - oldPx) < 0.01 then return end
        local centerTileX = (vw * 0.5 - mapPanX) / oldPx
        local centerTileY = (vh * 0.5 - mapPanY) / oldPx
        mapTilePx = clamped
        mapPanX = vw * 0.5 - centerTileX * clamped
        mapPanY = vh * 0.5 - centerTileY * clamped
        updateTransform()
    end

    local function getPoolBox(idx, z, col, trans, round)
        local f = mapPool[idx]
        if not f then
            f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.Parent = mapCanvas
            local uc = Instance.new("UICorner")
            uc.Parent = f
            mapPool[idx] = f
        end
        f.Visible = true
        f.ZIndex = (mapCanvas.ZIndex or 1) + z
        f.BackgroundColor3 = col
        f.BackgroundTransparency = trans or 0
        local uc = f:FindFirstChildOfClass("UICorner")
        if uc then uc.CornerRadius = UDim.new(round and 1 or 0, 0) end
        return f
    end

    local function renderMap(force)
        if not isMapVisible() then return end
        local now = os.clock()
        if not force and now - lastDraw < 0.25 then return end
        lastDraw = now

        local curW = H.gt and H.gt.w or 100
        local curH = H.gt and H.gt.h or 60
        if not didInitialFit or fittedW ~= curW or fittedH ~= curH then
            fitMapToView()
        else
            updateTransform()
        end

        local gt = H.gt
        if not gt or not gt.fg or not gt.w or not gt.h then return end
        local w, h, px = gt.w, gt.h, mapTilePx
        local used = 0
        local hasDB = H.ItemDB ~= nil

        -- 0. Background walls (cave/interior saat fg == 0) agar kedalaman dunia terlihat
        if type(gt.bg) == "table" then
            for y = 0, h - 1 do
                local fgRow = gt.fg[y]
                local bgRow = gt.bg[y]
                if bgRow then
                    local x = 0
                    while x < w do
                        local bgId = bgRow[x] or 0
                        local fgId = fgRow and fgRow[x] or 0
                        if bgId ~= 0 and fgId == 0 then
                            local sx = x
                            while x < w do
                                local nBg = bgRow[x] or 0
                                local nFg = fgRow and fgRow[x] or 0
                                if not (nBg ~= 0 and nFg == 0) then break end
                                x += 1
                            end
                            used += 1
                            local f = getPoolBox(used, 1, Color3.fromRGB(24, 30, 42), 0, false)
                            f.Position = UDim2.fromOffset(sx * px, y * px)
                            f.Size = UDim2.fromOffset(math.max(1, (x - sx) * px), math.max(1, px))
                        else
                            x += 1
                        end
                    end
                end
            end
        end

        -- 1. Terrain solid / platform (run-length spans) + failsafe bila ItemDB belum termuat
        for y = 0, h - 1 do
            local row = gt.fg[y]
            if row then
                local x = 0
                while x < w do
                    local id = row[x] or 0
                    local info = hasDB and getItemInfo(id) or nil
                    local isTerrain = (id ~= 0) and (
                        (info and (info.solid or info.platform))
                        or (not info and id ~= 0)
                    )
                    if isTerrain then
                        local isBedrock = (id == 8)
                        local sx = x
                        while x < w do
                            local nid = row[x] or 0
                            local ninfo = hasDB and getItemInfo(nid) or nil
                            local nTerrain = (nid ~= 0) and (
                                (ninfo and (ninfo.solid or ninfo.platform))
                                or (not ninfo and nid ~= 0)
                            )
                            if not nTerrain or ((nid == 8) ~= isBedrock) then break end
                            x += 1
                        end
                        used += 1
                        local col = isBedrock and Color3.fromRGB(54, 61, 76) or Color3.fromRGB(84, 93, 112)
                        local f = getPoolBox(used, 2, col, 0, false)
                        f.Position = UDim2.fromOffset(sx * px, y * px)
                        f.Size = UDim2.fromOffset(math.max(1, (x - sx) * px), math.max(1, px))
                    else
                        x += 1
                    end
                end
            end
        end

        -- 2. Trees / seeds (hijau) & pintu / non-solid fg penting
        if hasDB then
            for y = 0, h - 1 do
                local row = gt.fg[y]
                if row then
                    for x = 0, w - 1 do
                        local id = row[x] or 0
                        if id ~= 0 then
                            local info = getItemInfo(id)
                            if info and info.kind == "seed" then
                                used += 1
                                local f = getPoolBox(used, 3, Color3.fromRGB(52, 185, 110), 0, false)
                                f.Position = UDim2.fromOffset(x * px, y * px)
                                f.Size = UDim2.fromOffset(math.max(2, px), math.max(2, px))
                            elseif info and (info.door or id == 6) then
                                used += 1
                                local f = getPoolBox(used, 3, Color3.fromRGB(96, 165, 250), 0, false)
                                f.Position = UDim2.fromOffset(x * px, y * px)
                                f.Size = UDim2.fromOffset(math.max(2, px), math.max(2, px))
                            end
                        end
                    end
                end
            end
        end

        -- 3. Selected Target Tile (Cyan jika valid, Merah jika solid/invalid)
        if state.selectedX and state.selectedY then
            local ok = validateTile(state.selectedX, state.selectedY)
            used += 1
            local f = getPoolBox(used, 4, ok and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(239, 68, 68), 0.1, false)
            f.Position = UDim2.fromOffset(state.selectedX * px, state.selectedY * px)
            f.Size = UDim2.fromOffset(math.max(4, px), math.max(4, px))
        end

        -- 4. Live Player Dot (Kuning bulat)
        local pos = readCurrentPos()
        used += 1
        local dot = getPoolBox(used, 5, Color3.fromRGB(250, 204, 21), 0, true)
        local dsz = math.max(5, px + 1.5)
        dot.Position = UDim2.fromOffset(pos.tx * px, pos.ty * px)
        dot.Size = UDim2.fromOffset(dsz, dsz)

        for i = used + 1, #mapPool do
            mapPool[i].Visible = false
        end
    end
    state.renderMapFn = renderMap

    -- Pan / Zoom / Click-to-select tile (aman di ScrollingFrame & Android/Delta)
    local activeInput, moved, startScr, startPan, savedScroll = nil, false, nil, nil, nil
    local function restoreScroller()
        if parentScroller and savedScroll ~= nil then
            parentScroller.ScrollingEnabled = savedScroll
            savedScroll = nil
        end
    end

    mapView.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            activeInput = inp
            moved = false
            startScr = inp.Position
            startPan = Vector2.new(mapPanX, mapPanY)
            if not parentScroller then
                parentScroller = rowContainer:FindFirstAncestorOfClass("ScrollingFrame")
            end
            if parentScroller and savedScroll == nil then
                savedScroll = parentScroller.ScrollingEnabled
                parentScroller.ScrollingEnabled = false
            end
        end
    end)

    mapView.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            local factor = inp.Position.Z > 0 and 1.18 or (1 / 1.18)
            applyZoom(mapTilePx * factor)
            renderMap(true)
        end
    end)

    local uisChgConn = UserInputService.InputChanged:Connect(function(inp)
        if not activeInput then return end
        local sameTouch = (activeInput.UserInputType == Enum.UserInputType.Touch and inp == activeInput)
        local mouseMove = (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseMovement)
        if (sameTouch or mouseMove) and startScr and startPan then
            local d = inp.Position - startScr
            if d.Magnitude > 6 then
                moved = true
                mapPanX = startPan.X + d.X
                mapPanY = startPan.Y + d.Y
                updateTransform()
            end
        end
    end)

    local uisEndConn = UserInputService.InputEnded:Connect(function(inp)
        if not activeInput then return end
        local ended = (inp == activeInput)
            or (activeInput.UserInputType == Enum.UserInputType.MouseButton1 and inp.UserInputType == Enum.UserInputType.MouseButton1)
        if not ended then return end
        local wasMoved = moved
        activeInput = nil
        restoreScroller()
        if not wasMoved and isMapVisible() then
            local abs = mapCanvas.AbsolutePosition
            local tx = math.floor((inp.Position.X - abs.X) / mapTilePx)
            local ty = math.floor((inp.Position.Y - abs.Y) / mapTilePx)
            local gt = H.gt
            local maxW = (gt and gt.w) or 100
            local maxH = (gt and gt.h) or 60
            if tx < 0 or tx >= maxW or ty < 0 or ty >= maxH then
                infoLbl.Text = string.format("Ketuk di dalam kotak peta (X: 0..%d, Y: 0..%d)", maxW - 1, maxH - 1)
                infoLbl.TextColor3 = Color3.fromRGB(245, 158, 11)
                return
            end
            local ok, msg = validateTile(tx, ty)
            state.selectedX = tx
            state.selectedY = ty
            UI:SetValue("TpManualX", tostring(tx))
            UI:SetValue("TpManualY", tostring(ty))
            UI:SetValue("ValidStatusDisplay", msg)
            infoLbl.Text = msg
            infoLbl.TextColor3 = ok and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(239, 68, 68)
            renderMap(true)
        end
    end)

    fitBtn.MouseButton1Click:Connect(function()
        fitMapToView()
        renderMap(true)
    end)
    zoomInBtn.MouseButton1Click:Connect(function()
        applyZoom(mapTilePx + 1)
        renderMap(true)
    end)
    zoomOutBtn.MouseButton1Click:Connect(function()
        applyZoom(mapTilePx - 1)
        renderMap(true)
    end)
    tpBtn.MouseButton1Click:Connect(function()
        if state.selectedX and state.selectedY then
            local ok, msg = teleportToValidTile(state.selectedX, state.selectedY)
            UI:SetValue("ValidStatusDisplay", (ok and "[OK] " or "[INVALID] ") .. msg)
            infoLbl.Text = msg
            infoLbl.TextColor3 = ok and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
            renderMap(true)
        end
    end)

    -- Jalankan discovery setelah semua tab UI selesai dibuat
    task.spawn(function()
        pcall(discoverGame)
        if isMapVisible() then
            fitMapToView()
            renderMap(true)
        end
    end)

    -- Live coordinate + map refresh loop
    local lastPosTick = 0
    local lastDiscTick = 0
    local lastLivePosStr = ""
    local wasMapVisible = false
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not rowContainer or not rowContainer.Parent then
            state.patrolOn = false
            restoreScroller()
            if uisChgConn then uisChgConn:Disconnect() end
            if uisEndConn then uisEndConn:Disconnect() end
            conn:Disconnect()
            return
        end

        local now = os.clock()
        if (not H.gt or not H.ItemDB or not H.Net or (not H.stateObj and not H.pxIdx and not H.goPxIdx))
            and (now - lastDiscTick >= 2.0) then
            lastDiscTick = now
            pcall(discoverGame)
        end

        local vis = isMapVisible()
        if vis and not wasMapVisible then
            if not didInitialFit then fitMapToView() end
            renderMap(true)
        else
            renderMap(false)
        end
        wasMapVisible = vis

        if now - lastPosTick < 0.25 then return end
        lastPosTick = now

        if H.gt and (H.gt.name or "") ~= "" then
            local pos = readCurrentPos()
            local okHere = validateTile(pos.tx, pos.ty)
            local str = string.format("Stats (%d, %d) | Tile (%d, %d) | %s [%s]",
                pos.sx, pos.sy, pos.tx, pos.ty,
                tostring(H.gt.name), okHere and "VALID" or "SOLID")
            if str ~= lastLivePosStr then
                lastLivePosStr = str
                UI:SetValue("LivePosDisplay", str)
            end
        end
    end)

    if isMapVisible() then
        fitMapToView()
        renderMap(true)
    end
end)
