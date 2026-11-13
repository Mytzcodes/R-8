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

-- 2. Inisialisasi Jendela R&8_DV (Shell sama dengan SampleGui.lua)
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
local Players    = game:GetService("Players")
local CoreGui    = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LP         = Players.LocalPlayer

local H = {
    gt       = nil,
    Net      = nil,
    ItemDB   = nil,
    renderFn = nil,
    pxIdx    = nil,
    pyIdx    = nil,
    vxIdx    = nil,
    vyIdx    = nil,
    prevXIdx = nil,
    prevYIdx = nil,
}

local function uv(fn, idx)
    if type(debug) == "table" and type(debug.getupvalue) == "function" then
        local ok, _, val = pcall(debug.getupvalue, fn, idx)
        if ok then return val end
    end
    return nil
end

local function suv(fn, idx, val)
    if type(debug) == "table" and type(debug.setupvalue) == "function" then
        pcall(debug.setupvalue, fn, idx, val)
    end
end

local function isValidGT(t)
    return type(t) == "table"
        and type(t.fg) == "table"
        and type(t.w) == "number"
        and type(t.h) == "number"
        and type(t.goTo) == "function"
end

local function isValidNet(t)
    return type(t) == "table"
        and type(t.tile) == "table" and type(t.tile.send) == "function"
        and type(t.move) == "table" and type(t.move.send) == "function"
end

local function isValidItemDB(t)
    return type(t) == "table" and type(t[2]) == "table" and type(t[2].name) == "string"
end

local function inspectUpvalues(gt)
    if not gt or type(gt.goTo) ~= "function" then return end
    if type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then return end
    local ok, ups = pcall(debug.getupvalues, gt.goTo)
    if not ok or type(ups) ~= "table" then return end
    H.renderFn = gt.goTo
    H.pxIdx = 1
    H.pyIdx = 2
    -- lvzJPYBZmoBS.lua goTo upvalues: 1=px, 2=py, 5=prevX, 6=prevY, 7=vx, 8=vy
    if type(ups[5]) == "number" and type(ups[6]) == "number" then
        H.prevXIdx = 5
        H.prevYIdx = 6
    end
    if type(ups[7]) == "number" and type(ups[8]) == "number" then
        H.vxIdx = 7
        H.vyIdx = 8
    end
end

local function discoverGame()
    if type(getgc) == "function" then
        local ok, gc = pcall(getgc, true)
        if ok and type(gc) == "table" then
            for i = 1, #gc do
                local v = gc[i]
                if type(v) == "table" then
                    if not H.gt and isValidGT(v) then
                        H.gt = v
                    elseif not H.Net and isValidNet(v) then
                        H.Net = v
                    elseif not H.ItemDB and isValidItemDB(v) then
                        H.ItemDB = v
                    end
                    if H.gt and H.Net and H.ItemDB then break end
                end
            end
        end
    end
    if H.gt then inspectUpvalues(H.gt) end
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
    return info ~= nil and info.solid == true
end

local function validateTile(tx, ty)
    local gt = H.gt
    if not gt or gt.name == "" or not gt.w or not gt.h then
        return false, "Belum masuk world / gt tidak ditemukan"
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
    return true, string.format("VALID (%d, %d)", tx, ty), tx, ty
end

local function readCurrentPos()
    local x, y = 0, 1
    if H.renderFn and H.pxIdx and H.pyIdx then
        local vx = uv(H.renderFn, H.pxIdx)
        local vy = uv(H.renderFn, H.pyIdx)
        if type(vx) == "number" then x = vx end
        if type(vy) == "number" then y = vy end
    end
    return {
        x  = x,
        y  = y,
        tx = math.floor(x),
        ty = math.floor(y - 0.5),
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
    if H.renderFn and H.pxIdx then
        suv(H.renderFn, H.pxIdx, px)
        suv(H.renderFn, H.pyIdx, py)
        if H.prevXIdx then suv(H.renderFn, H.prevXIdx, px) end
        if H.prevYIdx then suv(H.renderFn, H.prevYIdx, py) end
        if H.vxIdx then suv(H.renderFn, H.vxIdx, 0) end
        if H.vyIdx then suv(H.renderFn, H.vyIdx, 0) end
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
    return true, string.format("Teleported -> (%d, %d)", cx, cy)
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

discoverGame()

-- State shared antar card
local state = {
    selectedX   = nil,
    selectedY   = nil,
    patrolOn    = false,
    patrolDelay = 1.2,
    lastStatus  = "Siap",
    renderMapFn = nil,
}

-- =========================================================================
-- KATEGORI 1: OVERVIEW (Sama dengan SampleGui, isi disesuaikan ke Status)
-- =========================================================================
if UI.Category then UI:Category("Overview") end

feature("Home", "Home")({
    center = center(function(c)
        c:Header("Teleport & Position", "Live coordinate inspector & validated tile teleportation", "Ready")

        c:StatRow({
            { Icon = "Teleports", Label = "Posisi Saat Ini", Value = "Scan..." },
            { Icon = "Shield",    Label = "Validasi Tile",   Value = "Strict" },
            { Icon = "Clock",     Label = "World",           Value = (H.gt and H.gt.name ~= "" and H.gt.name) or "-" },
        })

        local InfoCard = c:Card("Status Lokasi Live", "Live", "Player", {
            Subtitle = "Posisi karakter saat ini dan status validasi tile"
        })
        InfoCard:Button("Refresh / Scan Ulang Modul", "SCAN", "Bolt", function()
            local ok = discoverGame()
            state.lastStatus = ok and ("World terdeteksi: " .. tostring(H.gt.name)) or "Modul belum ditemukan"
            if state.renderMapFn then state.renderMapFn(true) end
        end)
        InfoCard:ActivityTimeline({
            { Text = "Lokasi & Validasi aktif di tab Teleport", Time = "Live" },
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
            Subtitle = "Koordinat real-time & status validasi tile tujuan"
        })
        PosCard:Input("Lokasi Saat Ini (Read-Only)", "LivePosDisplay", "Menunggu world...", "")
        PosCard:Input("Status Validasi", "ValidStatusDisplay", "Belum ada aksi", "")

        local ManualCard = c:Card("Manual Teleport (Harus Valid)", nil, "Teleports", {
            Subtitle = "Masukkan koordinat tile X & Y lalu cek atau teleport"
        })
        ManualCard:Input("Target Tile X", "TpManualX", "0 .. 99", "0")
        ManualCard:Input("Target Tile Y", "TpManualY", "0 .. 59", "0")
        ManualCard:Button("Cek Validasi Koordinat", "CEK", "Shield", function()
            local tx = tonumber(UI:GetValue("TpManualX"))
            local ty = tonumber(UI:GetValue("TpManualY"))
            local ok, msg, cx, cy = validateTile(tx, ty)
            state.lastStatus = msg
            UI:SetValue("ValidStatusDisplay", msg, true)
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
            state.lastStatus = msg
            UI:SetValue("ValidStatusDisplay", (ok and "[OK] " or "[INVALID] ") .. msg, true)
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
            if not H.gt then discoverGame() end
            state.patrolOn = true
            UI:SetValue("ValidStatusDisplay", "Patrol aktif (interval aman)", true)
            task.spawn(function()
                while state.patrolOn do
                    local pick = pickRandomValidTile()
                    if pick then
                        state.selectedX = pick.x
                        state.selectedY = pick.y
                        UI:SetValue("TpManualX", tostring(pick.x), true)
                        UI:SetValue("TpManualY", tostring(pick.y), true)
                        local ok, msg = teleportToValidTile(pick.x, pick.y)
                        UI:SetValue("ValidStatusDisplay", (ok and "[PATROL] " or "[ERR] ") .. msg, true)
                        if state.renderMapFn then state.renderMapFn(true) end
                    else
                        UI:SetValue("ValidStatusDisplay", "Tidak ada tile valid ditemukan", true)
                    end
                    task.wait(math.max(1.0, state.patrolDelay))
                end
            end)
        end)
        PatrolCard:Button("Stop Random Teleport", "STOP", "Shield", function()
            state.patrolOn = false
            UI:SetValue("ValidStatusDisplay", "Patrol dihentikan.", true)
        end)

        local MapCard = c:Card("Peta World Interaktif (Pilih Tile)", nil, "Visuals", {
            Subtitle = "Ketuk tile di peta untuk memilih X/Y, drag untuk geser, +/- untuk zoom"
        })
        MapCard:Input("Map Anchor (Embedded)", "__MAP_ANCHOR__", "__MAP_ANCHOR_KEY__", "__MAP_ANCHOR_KEY__")
        MapCard:Button("Render Ulang Peta", "REFRESH", "Visuals", function()
            discoverGame()
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

    -- Container baris milik Input anchor di dalam MapCard
    local rowContainer = anchorBox.Parent
    while rowContainer and rowContainer.Size.Y.Offset ~= 68 and rowContainer.Parent do
        rowContainer = rowContainer.Parent
    end
    if not rowContainer then rowContainer = anchorBox.Parent end

    for _, ch in ipairs(rowContainer:GetChildren()) do
        if not ch:IsA("UICorner") and not ch:IsA("UIStroke") then
            ch:Destroy()
        end
    end
    rowContainer.Size = UDim2.new(1, 0, 0, 260)
    rowContainer.BackgroundColor3 = Color3.fromRGB(11, 14, 20)
    rowContainer.ClipsDescendants = true

    local mapView = Instance.new("Frame")
    mapView.Size = UDim2.new(1, -12, 1, -38)
    mapView.Position = UDim2.fromOffset(6, 6)
    mapView.BackgroundColor3 = Color3.fromRGB(11, 14, 20)
    mapView.BorderSizePixel = 0
    mapView.ClipsDescendants = true
    mapView.Parent = rowContainer

    local mapCanvas = Instance.new("Frame")
    mapCanvas.BackgroundTransparency = 1
    mapCanvas.BorderSizePixel = 0
    mapCanvas.Parent = mapView

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -12, 0, 24)
    bar.Position = UDim2.new(0, 6, 1, -28)
    bar.BackgroundTransparency = 1
    bar.Parent = rowContainer

    local infoLbl = Instance.new("TextLabel")
    infoLbl.Size = UDim2.new(1, -124, 1, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Font = Enum.Font.Code
    infoLbl.TextSize = 11
    infoLbl.TextColor3 = Color3.fromRGB(203, 213, 225)
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left
    infoLbl.Text = "Klik tile di peta untuk memilih..."
    infoLbl.Parent = bar

    local function makeMiniBtn(txt, xOffset)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(26, 22)
        b.Position = UDim2.new(1, xOffset, 0, 1)
        b.BackgroundColor3 = Color3.fromRGB(31, 35, 44)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(240, 244, 250)
        b.Text = txt
        b.BorderSizePixel = 0
        b.Parent = bar
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = b
        return b
    end

    local zoomInBtn  = makeMiniBtn("+", -118)
    local zoomOutBtn = makeMiniBtn("-", -88)
    local tpBtn      = makeMiniBtn("TP", -58)
    tpBtn.Size = UDim2.fromOffset(54, 22)
    tpBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    tpBtn.TextColor3 = Color3.new(0, 0, 0)

    local mapTilePx = 5
    local mapPanX, mapPanY = 6, 6
    local mapPool = {}
    local lastDraw = 0

    local function updateTransform()
        local w = (H.gt and H.gt.w) or 100
        local h = (H.gt and H.gt.h) or 60
        mapCanvas.Size = UDim2.fromOffset(w * mapTilePx, h * mapTilePx)
        mapCanvas.Position = UDim2.fromOffset(mapPanX, mapPanY)
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
        f.ZIndex = z
        f.BackgroundColor3 = col
        f.BackgroundTransparency = trans or 0
        local uc = f:FindFirstChildOfClass("UICorner")
        if uc then uc.CornerRadius = UDim.new(round and 1 or 0, 0) end
        return f
    end

    local function renderMap(force)
        if not mapView.Visible then return end
        local now = os.clock()
        if not force and now - lastDraw < 0.25 then return end
        lastDraw = now

        updateTransform()
        local gt = H.gt
        if not gt or not gt.fg then return end
        local w, h, px = gt.w, gt.h, mapTilePx
        local used = 0

        -- 1. Terrain solid (run-length spans)
        for y = 0, h - 1 do
            local row = gt.fg[y]
            if row then
                local x = 0
                while x < w do
                    local id = row[x] or 0
                    local info = getItemInfo(id)
                    if info and (info.solid or info.platform) then
                        local sx = x
                        while x < w do
                            local ninfo = getItemInfo(row[x] or 0)
                            if not (ninfo and (ninfo.solid or ninfo.platform)) then break end
                            x += 1
                        end
                        used += 1
                        local f = getPoolBox(used, 1, Color3.fromRGB(58, 66, 80), 0, false)
                        f.Position = UDim2.fromOffset(sx * px, y * px)
                        f.Size = UDim2.fromOffset((x - sx) * px, math.max(1, px))
                    else
                        x += 1
                    end
                end
            end
        end

        -- 2. Trees (green)
        for y = 0, h - 1 do
            local row = gt.fg[y]
            if row then
                for x = 0, w - 1 do
                    local info = getItemInfo(row[x] or 0)
                    if info and info.kind == "seed" then
                        used += 1
                        local f = getPoolBox(used, 2, Color3.fromRGB(52, 168, 110), 0, false)
                        f.Position = UDim2.fromOffset(x * px, y * px)
                        f.Size = UDim2.fromOffset(math.max(2, px), math.max(2, px))
                    end
                end
            end
        end

        -- 3. Selected Target Tile (Cyan / Red if solid)
        if state.selectedX and state.selectedY then
            local ok = validateTile(state.selectedX, state.selectedY)
            used += 1
            local f = getPoolBox(used, 4, ok and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(239, 68, 68), 0.1, false)
            f.Position = UDim2.fromOffset(state.selectedX * px, state.selectedY * px)
            f.Size = UDim2.fromOffset(math.max(4, px), math.max(4, px))
        end

        -- 4. Live Player Dot (Yellow circle)
        local pos = readCurrentPos()
        used += 1
        local dot = getPoolBox(used, 5, Color3.fromRGB(250, 204, 21), 0, true)
        local dsz = math.max(5, px + 1)
        dot.Position = UDim2.fromOffset(pos.tx * px, pos.ty * px)
        dot.Size = UDim2.fromOffset(dsz, dsz)

        for i = used + 1, #mapPool do
            mapPool[i].Visible = false
        end
    end
    state.renderMapFn = renderMap

    -- Pan / Zoom / Click-to-select tile
    local isDown, moved, startScr, startPan = false, false, nil, nil
    mapView.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            isDown = true
            moved = false
            startScr = inp.Position
            startPan = Vector2.new(mapPanX, mapPanY)
        end
    end)
    mapView.InputChanged:Connect(function(inp)
        if isDown and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - startScr
            if d.Magnitude > 6 then
                moved = true
                mapPanX = startPan.X + d.X
                mapPanY = startPan.Y + d.Y
                updateTransform()
            end
        elseif inp.UserInputType == Enum.UserInputType.MouseWheel then
            local factor = inp.Position.Z > 0 and 1.15 or (1 / 1.15)
            mapTilePx = math.clamp(mapTilePx * factor, 3, 18)
            updateTransform()
            renderMap(true)
        end
    end)
    mapView.InputEnded:Connect(function(inp)
        if isDown and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then
            isDown = false
            if not moved then
                local abs = mapCanvas.AbsolutePosition
                local tx = math.floor((inp.Position.X - abs.X) / mapTilePx)
                local ty = math.floor((inp.Position.Y - abs.Y) / mapTilePx)
                local ok, msg = validateTile(tx, ty)
                state.selectedX = tx
                state.selectedY = ty
                UI:SetValue("TpManualX", tostring(tx), true)
                UI:SetValue("TpManualY", tostring(ty), true)
                UI:SetValue("ValidStatusDisplay", msg, true)
                infoLbl.Text = msg
                infoLbl.TextColor3 = ok and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(239, 68, 68)
                renderMap(true)
            end
        end
    end)

    zoomInBtn.MouseButton1Click:Connect(function()
        mapTilePx = math.clamp(mapTilePx + 1, 3, 18)
        renderMap(true)
    end)
    zoomOutBtn.MouseButton1Click:Connect(function()
        mapTilePx = math.clamp(mapTilePx - 1, 3, 18)
        renderMap(true)
    end)
    tpBtn.MouseButton1Click:Connect(function()
        if state.selectedX and state.selectedY then
            local ok, msg = teleportToValidTile(state.selectedX, state.selectedY)
            UI:SetValue("ValidStatusDisplay", (ok and "[OK] " or "[INVALID] ") .. msg, true)
            infoLbl.Text = msg
            infoLbl.TextColor3 = ok and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(239, 68, 68)
            renderMap(true)
        end
    end)

    -- Live coordinate + map refresh loop
    local lastPosTick = 0
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not rowContainer or not rowContainer.Parent then
            state.patrolOn = false
            conn:Disconnect()
            return
        end
        renderMap(false)
        local now = os.clock()
        if now - lastPosTick < 0.25 then return end
        lastPosTick = now

        if H.gt and H.gt.name ~= "" then
            local pos = readCurrentPos()
            local okHere = validateTile(pos.tx, pos.ty)
            UI:SetValue(
                "LivePosDisplay",
                string.format("Tile (%d, %d) | Pos (%.2f, %.2f) | %s [%s]",
                    pos.tx, pos.ty, pos.x, pos.y,
                    tostring(H.gt.name), okHere and "VALID" or "SOLID"),
                true
            )
        end
    end)

    renderMap(true)
end)
