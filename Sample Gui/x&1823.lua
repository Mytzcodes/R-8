-- File: core_backend.lua
-- Architecture: Luau / Roblox Client & Packet Sandbox Hybrid Engine
-- Dependencies: ReplicatedStorage.Shared (Net, ByteNet, ItemDB, BlocksDB, ClothesDB, Inventory, DropBox, ItemIcon, Assets, Roles, WorldCodec)

local C8_FUNC = {}
C8_FUNC.__index = C8_FUNC

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")
local TextChatService = nil
pcall(function() TextChatService = game:GetService("TextChatService") end)

local LocalPlayer = Players.LocalPlayer

-- // =========================================================================
-- // SECTION 1: SHARED MODULES & BYTENET DYNAMIC DISCOVERY (DOCUMENTRY.ZIP)
-- // =========================================================================

C8_FUNC.Modules = {
    SharedFolder = nil,
    ByteNet = nil,
    Net = nil,
    ItemDB = nil,
    BlocksDB = nil,
    ClothesDB = nil,
    MiscDB = nil,
    ProviderDB = nil,
    ItemIcon = nil,
    Assets = nil,
    Inventory = nil,
    DropBox = nil,
    WorldCodec = nil,
    Roles = nil,
    CommandList = nil,
    Store = nil,
    ShopPrices = nil,
    Splice = nil,
    Combine = nil,
    GameScriptEnv = nil,
    NetPackets = {}
}

local function safeRequire(inst)
    if not inst or not inst:IsA("ModuleScript") then return nil end
    local ok, mod = pcall(require, inst)
    if ok and mod ~= nil then return mod end
    return nil
end

function C8_FUNC:DiscoverGameModules()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local byteNetMod = ReplicatedStorage:FindFirstChild("ByteNet")

    self.Modules.SharedFolder = shared
    self.Modules.ByteNet = safeRequire(byteNetMod)

    if shared then
        self.Modules.Net        = safeRequire(shared:FindFirstChild("Net"))
        self.Modules.ItemDB     = safeRequire(shared:FindFirstChild("ItemDB"))
        self.Modules.BlocksDB   = safeRequire(shared:FindFirstChild("BlocksDB"))
        self.Modules.ClothesDB  = safeRequire(shared:FindFirstChild("ClothesDB"))
        self.Modules.MiscDB     = safeRequire(shared:FindFirstChild("MiscDB"))
        self.Modules.ProviderDB = safeRequire(shared:FindFirstChild("ProviderDB"))
        self.Modules.ItemIcon   = safeRequire(shared:FindFirstChild("ItemIcon"))
        self.Modules.Assets     = safeRequire(shared:FindFirstChild("Assets"))
        self.Modules.Inventory  = safeRequire(shared:FindFirstChild("Inventory"))
        self.Modules.DropBox    = safeRequire(shared:FindFirstChild("DropBox"))
        self.Modules.WorldCodec = safeRequire(shared:FindFirstChild("WorldCodec"))
        self.Modules.Roles      = safeRequire(shared:FindFirstChild("Roles"))
        self.Modules.CommandList= safeRequire(shared:FindFirstChild("CommandList"))
        self.Modules.Store      = safeRequire(shared:FindFirstChild("Store"))
        self.Modules.ShopPrices = safeRequire(shared:FindFirstChild("ShopPrices"))
        self.Modules.Splice     = safeRequire(shared:FindFirstChild("Splice"))
        self.Modules.Combine    = safeRequire(shared:FindFirstChild("Combine"))
    end

    -- Index all ByteNet packet objects inside Shared.Net (recursive scan for .send / .listen)
    local function indexPackets(tbl, prefix)
        if type(tbl) ~= "table" then return end
        for k, v in pairs(tbl) do
            local keyName = tostring(k):lower()
            local fullKey = prefix ~= "" and (prefix .. "." .. keyName) or keyName
            if type(v) == "table" then
                if type(v.send) == "function" or type(v.wait) == "function" or type(v.listen) == "function" then
                    self.Modules.NetPackets[keyName] = v
                    self.Modules.NetPackets[fullKey] = v
                else
                    indexPackets(v, fullKey)
                end
            elseif type(v) == "function" then
                self.Modules.NetPackets[keyName] = v
            end
        end
    end

    if self.Modules.Net then
        indexPackets(self.Modules.Net, "")
    end

    -- Discover PlayerGui.GameGui.Game environment if available
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local gameGui = pGui and pGui:FindFirstChild("GameGui")
        local gameScript = gameGui and gameGui:FindFirstChild("Game")
        if gameScript and type(getsenv) == "function" then
            local okEnv, env = pcall(getsenv, gameScript)
            if okEnv and type(env) == "table" then
                self.Modules.GameScriptEnv = env
            end
        end
    end)
end

-- // =========================================================================
-- // SECTION 2: LOW-LEVEL PACKET & SANDBOX BRIDGES (SKYP-FREE + BYTENET)
-- // =========================================================================

local function _sleep(ms)
    local sec = (tonumber(ms) or 100) / 1000
    if type(sleep) == "function" then
        return pcall(sleep, ms)
    elseif task and task.wait then
        return task.wait(sec)
    else
        local t0 = os.clock()
        while os.clock() - t0 < sec do end
    end
end

local function _isValid(v)
    return v ~= nil and type(v) ~= "boolean"
end

function C8_FUNC:CopyToClipboard(text)
    local str = tostring(text or "")
    local clipFn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if clipFn then
        pcall(clipFn, str)
        return true
    end
    return false
end

-- Dispatch ByteNet packet by matching semantic packet names in Shared.Net
function C8_FUNC:SendByteNetPacket(candidateNames, payload)
    local pkts = self.Modules.NetPackets
    if not pkts then return false end
    for _, name in ipairs(candidateNames) do
        local target = pkts[string.lower(name)]
        if target then
            if type(target) == "table" and type(target.send) == "function" then
                local ok = pcall(target.send, payload)
                if ok then return true end
            elseif type(target) == "function" then
                local ok = pcall(target, payload)
                if ok then return true end
            end
        end
    end
    return false
end

function C8_FUNC:SendPacket(pktType, strPayload)
    if type(sendPacket) == "function" then
        local ok = pcall(sendPacket, pktType, strPayload)
        if ok then return true end
    elseif type(SendPacket) == "function" then
        local ok = pcall(SendPacket, pktType, strPayload)
        if ok then return true end
    end

    -- Check Shared.Net for raw/action packet sender
    if self:SendByteNetPacket({ "sendpacket", "action", "packet", "input", "command" }, { type = pktType, data = strPayload, text = strPayload }) then
        return true
    end

    -- Check ReplicatedStorage RemoteEvents
    local rem = ReplicatedStorage:FindFirstChild("SendPacket", true)
        or ReplicatedStorage:FindFirstChild("RemoteEvent", true)
    if rem and rem:IsA("RemoteEvent") then
        pcall(function() rem:FireServer(pktType, strPayload) end)
        return true
    end
    return false
end

function C8_FUNC:SendPacketRaw(flag, tblPayload)
    if type(sendPacketRaw) == "function" then
        local ok = pcall(sendPacketRaw, flag, tblPayload)
        if ok then return true end
    elseif type(SendPacketRaw) == "function" then
        local ok = pcall(SendPacketRaw, flag, tblPayload)
        if ok then return true end
    end

    if type(tblPayload) == "table" then
        if tblPayload.type == 3 then
            return self:SendByteNetPacket(
                { "tilechange", "place", "hit", "punch", "breakblock", "interact", "tile" },
                { x = tblPayload.px or tblPayload.punchx, y = tblPayload.py or tblPayload.punchy, id = tblPayload.value, item = tblPayload.value }
            )
        elseif tblPayload.type == 11 then
            return self:SendByteNetPacket(
                { "collect", "pickup", "dropbox", "loot", "collectitem" },
                { id = tblPayload.value, oid = tblPayload.value, x = tblPayload.x, y = tblPayload.y }
            )
        end
    end
    return false
end

function C8_FUNC:RequestTileChange(x, y, itemID)
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)
    itemID = math.floor(tonumber(itemID) or 18)

    if type(requestTileChange) == "function" then
        local ok = pcall(requestTileChange, x, y, itemID)
        if ok then return true end
    end

    -- 1. Try GameGui.Game internal tile action function if exposed in senv
    local env = self.Modules.GameScriptEnv
    if type(env) == "table" then
        for _, fnName in ipairs({ "requestTileChange", "punchTile", "placeTile", "interactTile", "hitTile" }) do
            if type(env[fnName]) == "function" then
                local ok = pcall(env[fnName], x, y, itemID)
                if ok then return true end
            end
        end
    end

    -- 2. Try Shared.Net ByteNet Packets (Punch / Place / TileInteract)
    if itemID == 18 then
        if self:SendByteNetPacket({ "punch", "hit", "break", "tilehit", "tilechange", "interact" }, { x = x, y = y, id = 18 }) then
            return true
        end
    elseif itemID == 32 then
        if self:SendByteNetPacket({ "wrench", "tilewrench", "interact" }, { x = x, y = y, id = 32 }) then
            return true
        end
    else
        if self:SendByteNetPacket({ "place", "build", "plant", "tileplace", "tilechange", "interact" }, { x = x, y = y, id = itemID, item = itemID }) then
            return true
        end
    end

    -- 3. Fallback to Raw Packet Type 3
    local px, py = self:GetPlayerGridPos()
    return self:SendPacketRaw(false, {
        type = 3,
        value = itemID,
        punchx = x,
        punchy = y,
        px = x,
        py = y,
        x = px * 32,
        y = py * 32
    })
end

-- // =========================================================================
-- // SECTION 3: CENTRALIZED STATE & CONFIGURATION REGISTRY
-- // =========================================================================

C8_FUNC.State = {
    MenuFocused = false,
    FocusShieldActive = true,

    -- 1. Misc States
    Misc = {
        ModFly = false,
        FlySpeed = 60,
        NoClip = false,
        FastRoulette = false,
        FastWrench = false,
        WrenchMode = "Pull (/pull)",
        GodMode = false,
        AntiTakeItem = false,
        SpeedOn = false,
        SpeedVal = 60,
        HighJumpOn = false,
        JumpVal = 120,
        AntiGravity = false,
        GravityVal = 28,
        DefaultGravity = Workspace.Gravity or 196.2
    },

    -- 2. Live Position & World Info
    Telemetry = {
        X = 0,
        Y = 0,
        FacingLeft = false,
        PlayerName = LocalPlayer and LocalPlayer.Name or "Operator",
        TotalPlayers = #Players:GetPlayers(),
        WorldName = "START"
    },

    -- 3. Item Database
    ItemDB = {
        Registry = {},
        Filtered = {},
        SelectedItem = nil,
        CurrentSearch = "",
        CurrentCategory = "All Categories"
    },

    -- 4. Multi-Mode Auto Farm (6 Modes + Always-On Radius 4 Collect)
    AutoFarm = {
        Active = false,
        Mode = "1. BASIC", -- "1. BASIC" | "2. PABRIK" | "3. CLEAR" | "4. TEIN PNB" | "5. RYO LAVA" | "6. AUTO-DF"
        StatusText = "IDLE [0]",
        AutoCollectAlwaysOn = false,
        AutoCollectRadius = 4,
        CollectedCount = 0,

        Basic = {
            ItemID = 4584,
            HideHand = true,
            SpeedMs = 160,
            Hits = 4,
            Grid6x6 = false,
            SelectedTiles = {},
            SelectPos = { X = 0, Y = 0 },
            Cycles = 0
        },
        Pabrik = {
            BreakX = 50,
            BreakY = 23,
            SeedID = 4585,
            ScopeMode = "Radius (Tiles)",
            RadiusOrTotal = 4,
            DelayMs = 160,
            Cycles = 0
        },
        Clear = {
            LayerMode = "All Blocks (FG + BG)",
            SkipBedrock = true,
            DelayMs = 140,
            WorldsList = "world1,world2",
            DropWorld = "storageworld",
            DropX = 9,
            DropY = 18,
            DropAmount = 100,
            TargetBG = 14,
            ClearedCount = 0
        },
        TeinPNB = {
            BlockID = 340,
            RangeBlock = 5,
            HitCount = 4,
            PlaceDelay = 110,
            BreakDelay = 110,
            Cycles = 0
        },
        LavaFarm = {
            FarmWorld = "LAVAFARM|A1",
            DropWorld = "LAVADROP|B2",
            BlockID = 4,
            SeedID = 5,
            SpreadCount = 5,
            Direction = "up",
            DropLimit = 200,
            KeepSeed = 100,
            DropX = 6,
            DropY = 10,
            PnbDelay = 190,
            PlantDelay = 350,
            HarvestDelay = 350,
            PlantMax = 20
        },
        AutoDF = {
            TargetWorld = "NTUUM",
            DropWorld = "KUALISTORAGE",
            DropX = 83,
            DropY = 23,
            UseJammer = false,
            UsePlatform = true,
            PlatformID = 102,
            BlockID = 2,
            SeedID = 3,
            MainDoorID = 6,
            MaxBlockPNB = 150,
            PlantLimit = 50,
            TargetRows = { 25, 27, 29 },
            PunchDelay = 220,
            MoveDelay = 200,
            PlaceDelay = 320,
            DropThreshold = 150,
            DropFixedCount = 100
        }
    },

    -- 5. Spam Chat Engine
    SpamChat = {
        Active = false,
        Message = "SELL ALL ITEMS CHEAP! VISIT MY WORLD NOW!",
        AutoPrefix = true,
        ColorChoice = "`2 Green (Priority)",
        ChannelPrefix = "Normal Chat",
        DelayMs = 4500,
        SentCount = 0,
        LastPreview = "`2SELL ALL ITEMS CHEAP! VISIT MY WORLD NOW!"
    },

    -- 6. Visual Spoofer
    Visual = {
        CustomName = "",
        ModTitle = false,
        RolePreset = "Default"
    }
}

-- // =========================================================================
-- // SECTION 4: MENU FOCUS LOCK & NON-MENU BUTTON BLOCKER
-- // =========================================================================

local _DisabledGameGuiButtons = {}
local _SinkActionName = "C8_MenuFocusSinkAction"

function C8_FUNC:SetMenuFocusLock(isMenuOpenAndFocused)
    self.State.MenuFocused = (isMenuOpenAndFocused == true)

    -- 1. Sink world inputs via ContextActionService when menu is focused
    pcall(function()
        if self.State.MenuFocused and self.State.FocusShieldActive then
            ContextActionService:BindActionAtPriority(
                _SinkActionName,
                function() return Enum.ContextActionResult.Sink end,
                false,
                Enum.ContextActionPriority.High.Value + 500,
                Enum.UserInputType.MouseButton1,
                Enum.UserInputType.MouseButton2,
                Enum.UserInputType.Touch
            )
        else
            ContextActionService:UnbindAction(_SinkActionName)
        end
    end)

    -- 2. Disable Active/Selectable state on non-menu buttons in PlayerGui.GameGui
    pcall(function()
        local pGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        if not pGui then return end

        if self.State.MenuFocused and self.State.FocusShieldActive then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and not string.find(gui.Name, "R8") and not string.find(gui.Name, "ImGui") and not string.find(gui.Name, "SYPHUS") then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("GuiButton") and desc.Active then
                            _DisabledGameGuiButtons[desc] = {
                                Active = desc.Active,
                                Selectable = desc.Selectable,
                                AutoButtonColor = desc.AutoButtonColor
                            }
                            desc.Active = false
                            desc.Selectable = false
                            desc.AutoButtonColor = false
                        end
                    end
                end
            end
        else
            for btn, props in pairs(_DisabledGameGuiButtons) do
                if btn and btn.Parent then
                    btn.Active = props.Active
                    btn.Selectable = props.Selectable
                    btn.AutoButtonColor = props.AutoButtonColor
                end
            end
            table.clear(_DisabledGameGuiButtons)
        end
    end)
end

-- // =========================================================================
-- // SECTION 5: LIVE TELEMETRY, INVENTORY & WORLD TILE READER
-- // =========================================================================

function C8_FUNC:GetPlayerGridPos()
    -- 1. Check Genta/Bothax getLocal()
    if type(getLocal) == "function" then
        local ok, loc = pcall(getLocal)
        if ok and _isValid(loc) and _isValid(loc.pos) then
            return math.floor(loc.pos.x / 32), math.floor(loc.pos.y / 32), (loc.pos.facingLeft == true)
        end
    end

    -- 2. Check GameGui.Game environment
    local env = self.Modules.GameScriptEnv
    if type(env) == "table" then
        local px = env.playerX or env.posX or (type(env.player) == "table" and env.player.x)
        local py = env.playerY or env.posY or (type(env.player) == "table" and env.player.y)
        local facing = env.facingLeft or (type(env.player) == "table" and env.player.facingLeft) or false
        if type(px) == "number" and type(py) == "number" then
            if px > 100 or py > 100 then
                return math.floor(px / 32), math.floor(py / 32), (facing == true)
            end
            return math.floor(px + 0.5), math.floor(py + 0.5), (facing == true)
        end
    end

    -- 3. Check Roblox Character HumanoidRootPart
    local char = LocalPlayer and LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if root then
        local gx = math.floor(root.Position.X + 0.5)
        local gy = math.floor(root.Position.Y + 0.5)
        local facingLeft = (root.CFrame.LookVector.X < 0)
        return gx, gy, facingLeft
    end

    return 0, 0, false
end

function C8_FUNC:ReadLiveWorldAndPosition()
    local gx, gy, facingLeft = self:GetPlayerGridPos()
    self.State.Telemetry.X = gx
    self.State.Telemetry.Y = gy
    self.State.Telemetry.FacingLeft = facingLeft

    local lp = Players.LocalPlayer
    self.State.Telemetry.PlayerName = (lp and (lp.DisplayName ~= lp.Name and (lp.DisplayName .. " (@" .. lp.Name .. ")") or lp.Name)) or "Operator"
    self.State.Telemetry.TotalPlayers = #Players:GetPlayers()

    local detectedWorld = nil
    pcall(function()
        if type(getWorld) == "function" then
            local ok, w = pcall(getWorld)
            if ok and _isValid(w) and w.name then detectedWorld = tostring(w.name) end
        end
        if not detectedWorld and self.Modules.GameScriptEnv then
            local env = self.Modules.GameScriptEnv
            detectedWorld = env.worldName or env.currentWorld or (type(env.world) == "table" and env.world.name)
        end
        if not detectedWorld then
            if Workspace:GetAttribute("WorldName") then
                detectedWorld = tostring(Workspace:GetAttribute("WorldName"))
            elseif Workspace:FindFirstChild("WorldName") and Workspace.WorldName:IsA("ValueBase") then
                detectedWorld = tostring(Workspace.WorldName.Value)
            elseif ReplicatedStorage:FindFirstChild("WorldName") and ReplicatedStorage.WorldName:IsA("ValueBase") then
                detectedWorld = tostring(ReplicatedStorage.WorldName.Value)
            end
        end
    end)

    if not detectedWorld or detectedWorld == "" then
        detectedWorld = (game.Name and game.Name ~= "" and game.Name ~= "Game") and game.Name or ("WORLD_" .. tostring(game.PlaceId or 1001))
    end
    self.State.Telemetry.WorldName = string.upper(detectedWorld)
    return self.State.Telemetry
end

function C8_FUNC:GetItemCount(itemID)
    itemID = tonumber(itemID) or 0
    -- 1. Check Shared.Inventory module from DOCUMENTRY.zip
    local invMod = self.Modules.Inventory
    if type(invMod) == "table" then
        if type(invMod.GetCount) == "function" then
            local ok, cnt = pcall(invMod.GetCount, invMod, itemID)
            if ok and type(cnt) == "number" then return cnt end
        elseif type(invMod.getItemCount) == "function" then
            local ok, cnt = pcall(invMod.getItemCount, itemID)
            if ok and type(cnt) == "number" then return cnt end
        elseif type(invMod.Items) == "table" then
            local slot = invMod.Items[itemID] or invMod.Items[tostring(itemID)]
            if type(slot) == "number" then return slot end
            if type(slot) == "table" then return tonumber(slot.amount or slot.count or slot.qty) or 0 end
        end
    end

    -- 2. Check Genta/Bothax getInventory()
    if type(getInventory) == "function" then
        local ok, inv = pcall(getInventory)
        if ok and type(inv) == "table" then
            for _, item in pairs(inv) do
                if _isValid(item) and tonumber(item.id) == itemID then
                    return tonumber(item.amount or item.count) or 0
                end
            end
        end
    end

    return 200 -- Safe fallback so local testing cycles execute cleanly
end

function C8_FUNC:CheckTile(x, y)
    if type(checkTile) == "function" then
        local ok, t = pcall(checkTile, x, y)
        if ok and _isValid(t) then return t end
    elseif type(GetTile) == "function" then
        local ok, t = pcall(GetTile, x, y)
        if ok and _isValid(t) then return t end
    end

    local env = self.Modules.GameScriptEnv
    if type(env) == "table" and type(env.getTile) == "function" then
        local ok, t = pcall(env.getTile, x, y)
        if ok and type(t) == "table" then
            return {
                fg = tonumber(t.fg or t.id or 0) or 0,
                bg = tonumber(t.bg or 0) or 0,
                ready = (t.ready == true),
                pos = { x = x, y = y }
            }
        end
    end

    return { fg = 0, bg = 0, ready = true, pos = { x = x, y = y } }
end

function C8_FUNC:MoveToGrid(x, y, delayMs)
    x = math.floor(tonumber(x) or 0)
    y = math.floor(tonumber(y) or 0)

    if type(findPath) == "function" then
        pcall(findPath, x, y, delayMs)
        _sleep(delayMs or 150)
        return true
    end

    local env = self.Modules.GameScriptEnv
    if type(env) == "table" then
        if type(env.player) == "table" then
            env.player.x = x * 32
            env.player.y = y * 32
        end
        if type(env.posX) == "number" then
            env.posX = x * 32
            env.posY = y * 32
        end
    end

    self:SendByteNetPacket({ "move", "state", "playerstate", "position" }, { x = x * 32, y = y * 32, gx = x, gy = y })

    local char = LocalPlayer and LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if root then
        root.CFrame = CFrame.new(x, y, root.Position.Z)
    end

    _sleep(delayMs or 150)
    return true
end

function C8_FUNC:WarpWorld(worldName)
    local target = string.upper(tostring(worldName or "START"))
    self.State.AutoFarm.StatusText = "WARP -> " .. target
    self:SendByteNetPacket({ "warp", "joinworld", "join", "worldjoin" }, { name = target, world = target })
    self:SendPacket(3, "action|join_request\nname|" .. target .. "\ninvitedWorld|0")
    _sleep(2000)
    return true
end

-- // =========================================================================
-- // SECTION 6: AUTO COLLECT ALWAYS ON (LOCKED AT RADIUS 4)
-- // =========================================================================

function C8_FUNC:RunAutoCollectRadius4(centerX, centerY)
    local radius = 4
    self.State.AutoFarm.AutoCollectRadius = radius

    if type(requestCollectByRange) == "function" then
        pcall(requestCollectByRange, radius)
    end

    local px, py = self:GetPlayerGridPos()
    local cx = centerX or px
    local cy = centerY or py

    -- 1. Collect from Shared.DropBox module if present
    local dropBox = self.Modules.DropBox
    if type(dropBox) == "table" then
        local list = dropBox.Drops or dropBox.Objects or dropBox.items or dropBox
        if type(list) == "table" then
            for id, obj in pairs(list) do
                if type(obj) == "table" then
                    local ox = tonumber(obj.x or obj.gx or (obj.pos and obj.pos.x)) or cx
                    local oy = tonumber(obj.y or obj.gy or (obj.pos and obj.pos.y)) or cy
                    if ox > 100 or oy > 100 then
                        ox = math.floor(ox / 32)
                        oy = math.floor(oy / 32)
                    end
                    if math.abs(ox - cx) <= radius and math.abs(oy - cy) <= radius then
                        local oid = obj.oid or obj.id or id
                        self:SendByteNetPacket({ "collect", "pickup", "dropbox" }, { id = oid, x = ox, y = oy })
                        self:SendPacketRaw(false, { type = 11, value = oid, x = ox * 32, y = oy * 32 })
                        self.State.AutoFarm.CollectedCount += 1
                    end
                end
            end
        end
    end

    -- 2. Collect from getWorldObject() if present
    if type(getWorldObject) == "function" then
        local ok, objs = pcall(getWorldObject)
        if ok and type(objs) == "table" then
            for _, obj in pairs(objs) do
                if _isValid(obj) and _isValid(obj.pos) then
                    local ox = math.floor(obj.pos.x / 32)
                    local oy = math.floor(obj.pos.y / 32)
                    if math.abs(ox - cx) <= radius and math.abs(oy - cy) <= radius then
                        self:SendPacketRaw(false, {
                            type = 11,
                            value = obj.oid or obj.id,
                            x = obj.pos.x,
                            y = obj.pos.y
                        })
                        self.State.AutoFarm.CollectedCount += 1
                    end
                end
            end
        end
    end
end

-- // =========================================================================
-- // SECTION 7: ITEM DATABASE BUILDER (REAL ITEMDB + BLOCKSDB + CLOTHESDB)
-- // =========================================================================

local FallbackItems = {
    { ID = 2,    SeedID = 3,    Name = "Dirt",                    Category = "Blocks",           Rarity = 1,  Hits = 3,  GrowTime = "30s",         Gems = "0 - 1",   Collision = "Solid",    Color = Color3.fromRGB(139, 90, 43),   IconAsset = "rbxassetid://6031265976", Description = "Basic soil block found in every standard world layer. Used for splicing basic trees." },
    { ID = 4,    SeedID = 5,    Name = "Cave Background",         Category = "Background",       Rarity = 1,  Hits = 3,  GrowTime = "35s",         Gems = "0 - 1",   Collision = "Passable", Color = Color3.fromRGB(92, 64, 51),    IconAsset = "rbxassetid://6031265976", Description = "Natural underground cave wall background tile." },
    { ID = 6,    SeedID = 7,    Name = "Main Door",               Category = "Blocks",           Rarity = 99, Hits = 99, GrowTime = "Unbreakable", Gems = "0",       Collision = "Passable", Color = Color3.fromRGB(234, 88, 12),   IconAsset = "rbxassetid://6031094678", Description = "World entry spawn point. Automatically skipped during Auto Farm Clear mode." },
    { ID = 8,    SeedID = 9,    Name = "Bedrock",                 Category = "Blocks",           Rarity = 99, Hits = 99, GrowTime = "Unbreakable", Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(55, 65, 81),    IconAsset = "rbxassetid://6031094678", Description = "Indestructible bottom foundation block. Automatically skipped during Clear mode." },
    { ID = 10,   SeedID = 11,   Name = "Rock",                    Category = "Blocks",           Rarity = 2,  Hits = 5,  GrowTime = "60s",         Gems = "0 - 2",   Collision = "Solid",    Color = Color3.fromRGB(128, 134, 139), IconAsset = "rbxassetid://6031280882", Description = "Hard stone boulder embedded inside dirt layers." },
    { ID = 14,   SeedID = 15,   Name = "Lava",                    Category = "Blocks",           Rarity = 2,  Hits = 4,  GrowTime = "45s",         Gems = "0 - 2",   Collision = "Hazard",   Color = Color3.fromRGB(235, 87, 34),   IconAsset = "rbxassetid://6031280882", Description = "Molten volcanic block that damages players on contact unless God Mode is active." },
    { ID = 98,   SeedID = 99,   Name = "Pickaxe",                 Category = "Clothing & Gear",  Rarity = 12, Hits = 1,  GrowTime = "Equipable",   Gems = "0",       Collision = "Equip",    Color = Color3.fromRGB(156, 163, 175), IconAsset = "rbxassetid://6031280882", Description = "Standard mining tool that reduces required hits on blocks by 1." },
    { ID = 100,  SeedID = 101,  Name = "Wood Block",              Category = "Blocks",           Rarity = 2,  Hits = 4,  GrowTime = "1m 15s",      Gems = "0 - 2",   Collision = "Solid",    Color = Color3.fromRGB(181, 136, 99),  IconAsset = "rbxassetid://6031265976", Description = "Refined timber plank used for building structures and mass projects." },
    { ID = 102,  SeedID = 103,  Name = "Wooden Platform",         Category = "Blocks",           Rarity = 4,  Hits = 3,  GrowTime = "2m 00s",      Gems = "0 - 2",   Collision = "Platform", Color = Color3.fromRGB(161, 98, 7),    IconAsset = "rbxassetid://6031265976", Description = "One-way wooden platform used for Auto-DF side ladders (Cols 1 & 98)." },
    { ID = 202,  SeedID = 203,  Name = "Small Lock",              Category = "Locks & Currency", Rarity = 5,  Hits = 8,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(218, 165, 32),  IconAsset = "rbxassetid://6031068426", Description = "Secures a customizable small area of tiles around the lock." },
    { ID = 204,  SeedID = 205,  Name = "Big Lock",                Category = "Locks & Currency", Rarity = 10, Hits = 8,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(235, 190, 45),  IconAsset = "rbxassetid://6031068426", Description = "Secures up to 48 connected tiles against unauthorized modification." },
    { ID = 206,  SeedID = 207,  Name = "Huge Lock",               Category = "Locks & Currency", Rarity = 20, Hits = 8,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(245, 210, 60),  IconAsset = "rbxassetid://6031068426", Description = "Secures up to 200 connected tiles in a world." },
    { ID = 226,  SeedID = 227,  Name = "Signal Jammer",           Category = "Special & IOTM",   Rarity = 15, Hits = 5,  GrowTime = "15m 00s",     Gems = "0 - 4",   Collision = "Solid",    Color = Color3.fromRGB(220, 38, 38),   IconAsset = "rbxassetid://6031280882", Description = "Hides world from public broadcast and blocks radar detection." },
    { ID = 242,  SeedID = 243,  Name = "World Lock",              Category = "Locks & Currency", Rarity = 99, Hits = 10, GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(255, 215, 0),   IconAsset = "rbxassetid://6031068426", Description = "Universal trading currency and full-world ownership lock." },
    { ID = 340,  SeedID = 341,  Name = "Chandelier",              Category = "Farmables",        Rarity = 87, Hits = 5,  GrowTime = "7d 15h",      Gems = "12 - 22", Collision = "Passable", Color = Color3.fromRGB(250, 204, 21),  IconAsset = "rbxassetid://6031280882", Description = "High-rarity luxury farmable yielding massive gem drops per harvest." },
    { ID = 758,  SeedID = 759,  Name = "Roulette Wheel",          Category = "Special & IOTM",   Rarity = 36, Hits = 5,  GrowTime = "4h 30m",      Gems = "1 - 4",   Collision = "Solid",    Color = Color3.fromRGB(220, 38, 38),   IconAsset = "rbxassetid://6031280882", Description = "Spinnable number wheel (0-36). Compatible with Fast Roulette modifier." },
    { ID = 1404, SeedID = 1405, Name = "Door",                    Category = "Blocks",           Rarity = 3,  Hits = 4,  GrowTime = "1m 30s",      Gems = "0 - 2",   Collision = "Passable", Color = Color3.fromRGB(161, 98, 7),    IconAsset = "rbxassetid://6031265976", Description = "Interactive portal door that links to other doors or worlds." },
    { ID = 1796, SeedID = 1797, Name = "Diamond Lock",            Category = "Locks & Currency", Rarity = 99, Hits = 10, GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(56, 189, 248),  IconAsset = "rbxassetid://6031068426", Description = "Compressed high-value currency equivalent to 100 World Locks." },
    { ID = 2722, SeedID = 2723, Name = "Sorcerer Stone",          Category = "Farmables",        Rarity = 85, Hits = 5,  GrowTime = "7d 3h",       Gems = "11 - 21", Collision = "Solid",    Color = Color3.fromRGB(168, 85, 247),  IconAsset = "rbxassetid://6031280882", Description = "Mystical high-rarity enchanted block with top-tier gem returns." },
    { ID = 2978, SeedID = 2979, Name = "Vending Machine",         Category = "Special & IOTM",   Rarity = 50, Hits = 6,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(14, 165, 233),  IconAsset = "rbxassetid://6031265976", Description = "Automated shop machine for buying and selling items with World Locks." },
    { ID = 3004, SeedID = 3005, Name = "Fish Tank",               Category = "Farmables",        Rarity = 42, Hits = 3,  GrowTime = "21h 52m",     Gems = "3 - 8",   Collision = "Solid",    Color = Color3.fromRGB(59, 130, 246),  IconAsset = "rbxassetid://6031265976", Description = "Fast 3-hit glass aquarium farmable great for rapid gem and XP farming." },
    { ID = 4584, SeedID = 4585, Name = "Pepper Tree",             Category = "Farmables",        Rarity = 53, Hits = 4,  GrowTime = "1d 15h",      Gems = "5 - 11",  Collision = "Solid",    Color = Color3.fromRGB(239, 68, 68),   IconAsset = "rbxassetid://6031265976", Description = "Popular 4-hit farmable block ideal for Basic & Pabrik Auto Farm routines." },
    { ID = 5638, SeedID = 5639, Name = "Magplant 5000",           Category = "Special & IOTM",   Rarity = 99, Hits = 6,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(244, 63, 94),   IconAsset = "rbxassetid://6031280882", Description = "Remote item dispenser and auto-farming core device via Magplant Remote." },
    { ID = 5666, SeedID = 5667, Name = "Laser Grid",              Category = "Farmables",        Rarity = 69, Hits = 4,  GrowTime = "3d 10h",      Gems = "7 - 15",  Collision = "Solid",    Color = Color3.fromRGB(34, 197, 94),   IconAsset = "rbxassetid://6031280882", Description = "Top-tier 4-hit farmable security barrier with fast break cycles and high gem yield." },
    { ID = 6946, SeedID = 6947, Name = "Gaia's Beacon",           Category = "Special & IOTM",   Rarity = 99, Hits = 6,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(16, 185, 129),  IconAsset = "rbxassetid://6031280882", Description = "Automatically collects dropped seeds when harvesting trees in the world." },
    { ID = 6948, SeedID = 6949, Name = "Unstable Tesseract",      Category = "Special & IOTM",   Rarity = 99, Hits = 6,  GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(99, 102, 241),  IconAsset = "rbxassetid://6031280882", Description = "Automatically collects dropped blocks when harvesting trees in the world." },
    { ID = 7188, SeedID = 7189, Name = "Blue Gem Lock",           Category = "Locks & Currency", Rarity = 99, Hits = 10, GrowTime = "Non-Farm",    Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(37, 99, 235),   IconAsset = "rbxassetid://6031068426", Description = "Ultra-high tier currency equivalent to 100 Diamond Locks (10,000 WLs)." },
    { ID = 9500, SeedID = 9501, Name = "Rayman's Fist",           Category = "Clothing & Gear",  Rarity = 99, Hits = 1,  GrowTime = "Equipable",   Gems = "0",       Collision = "Equip",    Color = Color3.fromRGB(251, 191, 36),  IconAsset = "rbxassetid://6031280882", Description = "Legendary hand item allowing 3-tile line punching for ultra-fast BFG & Pabrik breaking." },
    { ID = 9928, SeedID = 9929, Name = "Bountiful Lattice Fence", Category = "Farmables",        Rarity = 55, Hits = 4,  GrowTime = "1d 18h",      Gems = "5 - 12",  Collision = "Passable", Color = Color3.fromRGB(132, 204, 22),  IconAsset = "rbxassetid://6031265976", Description = "Passable background farmable widely used in Pabrik setups." }
}

function C8_FUNC:BuildItemDatabase()
    local list = {}
    local seenIDs = {}

    local function addEntry(entry)
        if not entry or not entry.ID or seenIDs[entry.ID] then return end
        seenIDs[entry.ID] = true
        table.insert(list, entry)
    end

    -- 1. Pull live items from ReplicatedStorage.Shared.ItemDB if present
    local liveDB = self.Modules.ItemDB
    local iconMod = self.Modules.ItemIcon
    if type(liveDB) == "table" then
        local sourceTable = liveDB.Items or liveDB.ById or liveDB
        for k, raw in pairs(sourceTable) do
            if type(raw) == "table" and (raw.id or raw.ID or type(k) == "number") then
                local id = tonumber(raw.id or raw.ID or k)
                local name = tostring(raw.name or raw.Name or ("Item #" .. tostring(id)))
                if id and name ~= "" then
                    local rarity = tonumber(raw.rarity or raw.Rarity or 1) or 1
                    local hits = tonumber(raw.hits or raw.hp or raw.Hits or 4) or 4
                    local growSec = tonumber(raw.growTime or raw.grow or 0) or 0
                    local growStr = growSec > 0 and (tostring(growSec) .. "s") or tostring(raw.GrowTime or "Non-Farm")
                    local cat = tostring(raw.category or raw.type or raw.Category or (rarity >= 40 and "Farmables" or "Blocks"))
                    local iconAsset = tostring(raw.icon or raw.image or raw.IconAsset or "rbxassetid://6031265976")

                    if type(iconMod) == "table" and type(iconMod.GetIcon) == "function" then
                        local okIc, icRes = pcall(iconMod.GetIcon, id)
                        if okIc and type(icRes) == "string" and icRes ~= "" then
                            iconAsset = icRes
                        elseif okIc and type(icRes) == "table" and icRes.Image then
                            iconAsset = tostring(icRes.Image)
                        end
                    end

                    addEntry({
                        ID = id,
                        SeedID = tonumber(raw.seedId or raw.SeedID) or (id + 1),
                        Name = name,
                        Category = cat,
                        Rarity = rarity,
                        Hits = hits,
                        GrowTime = growStr,
                        Gems = tostring(raw.gems or raw.Gems or (rarity > 20 and "4 - 12" or "0 - 2")),
                        Collision = tostring(raw.collision or raw.Collision or "Solid"),
                        Color = typeof(raw.color) == "Color3" and raw.color or Color3.fromRGB(56, 189, 248),
                        IconAsset = iconAsset,
                        Description = tostring(raw.desc or raw.description or raw.Description or ("In-game item from ReplicatedStorage.Shared.ItemDB (ID " .. tostring(id) .. ")."))
                    })
                end
            end
        end
    end

    -- 2. Merge curated FallbackItems so all standard Farmables, Locks & Tools are always available
    for _, item in ipairs(FallbackItems) do
        addEntry(item)
    end

    table.sort(list, function(a, b) return a.ID < b.ID end)
    self.State.ItemDB.Registry = list
    self.State.ItemDB.Filtered = list
    self.State.ItemDB.SelectedItem = list[1] or FallbackItems[1]
    return list
end

-- // =========================================================================
-- // SECTION 8: MISC MODIFIERS & PHYSICS HOOKS
-- // =========================================================================

function C8_FUNC:SetModFly(on)
    self.State.Misc.ModFly = (on == true)
    if type(toggleCheat) == "function" then pcall(toggleCheat, 26, self.State.Misc.ModFly) end
    if self.State.Misc.ModFly and type(patchMemoryByName) == "function" then
        pcall(patchMemoryByName, "Mod fly")
    end
    local env = self.Modules.GameScriptEnv
    if type(env) == "table" then
        env.modFly = self.State.Misc.ModFly
        env.canFly = self.State.Misc.ModFly
    end
end

function C8_FUNC:SetNoClip(on)
    self.State.Misc.NoClip = (on == true)
    local env = self.Modules.GameScriptEnv
    if type(env) == "table" then
        env.noclip = self.State.Misc.NoClip
    end
end

function C8_FUNC:SetFastRoulette(on)
    self.State.Misc.FastRoulette = (on == true)
    pcall(function() Workspace:SetAttribute("FastRoulette", self.State.Misc.FastRoulette) end)
    local panelRoll = self.Modules.SharedFolder and safeRequire(self.Modules.SharedFolder:FindFirstChild("PanelRoll"))
    if type(panelRoll) == "table" then
        panelRoll.FastSpin = self.State.Misc.FastRoulette
        panelRoll.Duration = self.State.Misc.FastRoulette and 0.05 or 3.0
    end
end

function C8_FUNC:SetFastWrench(on, mode)
    self.State.Misc.FastWrench = (on == true)
    if mode then self.State.Misc.WrenchMode = tostring(mode) end
end

function C8_FUNC:SetGodMode(on)
    self.State.Misc.GodMode = (on == true)
    local env = self.Modules.GameScriptEnv
    if type(env) == "table" then
        env.godMode = self.State.Misc.GodMode
    end
end

function C8_FUNC:SetSpeed(on, val)
    if on ~= nil then self.State.Misc.SpeedOn = (on == true) end
    if val ~= nil then self.State.Misc.SpeedVal = tonumber(val) or 60 end
    local char = LocalPlayer and LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = self.State.Misc.SpeedOn and self.State.Misc.SpeedVal or 16
    end
end

function C8_FUNC:SetHighJump(on, val)
    if on ~= nil then self.State.Misc.HighJumpOn = (on == true) end
    if val ~= nil then self.State.Misc.JumpVal = tonumber(val) or 120 end
    local char = LocalPlayer and LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = self.State.Misc.HighJumpOn and self.State.Misc.JumpVal or 50
    end
end

function C8_FUNC:SetAntiGravity(on)
    self.State.Misc.AntiGravity = (on == true)
    pcall(function()
        Workspace.Gravity = self.State.Misc.AntiGravity and self.State.Misc.GravityVal or self.State.Misc.DefaultGravity
    end)
end

-- // =========================================================================
-- // SECTION 9: MULTI-MODE AUTO FARM EXECUTION STEPPER (ALL 6 MODES)
-- // =========================================================================

function C8_FUNC:StepAutoFarm()
    local af = self.State.AutoFarm
    if not af.Active then return end

    -- Always enforce Auto Collect at Radius 4
    af.AutoCollectAlwaysOn = true
    af.AutoCollectRadius = 4
    self:RunAutoCollectRadius4()

    local px, py, facingLeft = self:GetPlayerGridPos()
    local mode = af.Mode

    if mode == "1. BASIC" then
        local cfg = af.Basic
        local bx = (cfg.SelectPos.X ~= 0) and cfg.SelectPos.X or px
        local by = (cfg.SelectPos.Y ~= 0) and cfg.SelectPos.Y or py
        local targets = {}

        if type(cfg.SelectedTiles) == "table" and next(cfg.SelectedTiles) ~= nil then
            for idx, isSel in pairs(cfg.SelectedTiles) do
                if isSel then
                    local n = tonumber(idx) or 1
                    local row = math.floor((n - 1) / 6) - 2
                    local col = ((n - 1) % 6) - 2
                    table.insert(targets, { X = bx + col, Y = by + row })
                end
            end
        end
        if #targets == 0 then
            table.insert(targets, { X = bx, Y = by - 1 })
        end

        af.StatusText = string.format("BASIC [1] (%d TILES)", #targets)
        for _, t in ipairs(targets) do
            if not af.Active or af.Mode ~= "1. BASIC" then break end
            self:RequestTileChange(t.X, t.Y, tonumber(cfg.ItemID) or 4584)
            _sleep(cfg.SpeedMs)
            for _ = 1, (tonumber(cfg.Hits) or 4) do
                if not af.Active or af.Mode ~= "1. BASIC" then break end
                self:RequestTileChange(t.X, t.Y, 18)
                _sleep(cfg.SpeedMs)
            end
            self:RunAutoCollectRadius4(t.X, t.Y)
        end
        cfg.Cycles += 1

    elseif mode == "2. PABRIK" then
        local cfg = af.Pabrik
        local bx = tonumber(cfg.BreakX) or px
        local by = tonumber(cfg.BreakY) or py
        local seedID = tonumber(cfg.SeedID) or 4585
        local blockID = math.max(2, seedID - 1)
        local span = math.max(1, tonumber(cfg.RadiusOrTotal) or 4)

        af.StatusText = string.format("PABRIK [1] (%d,%d)", bx, by)
        self:MoveToGrid(bx, by + 1, cfg.DelayMs)
        self:RequestTileChange(bx, by, blockID)
        _sleep(cfg.DelayMs)
        for _ = 1, 4 do
            if not af.Active or af.Mode ~= "2. PABRIK" then break end
            self:RequestTileChange(bx, by, 18)
            _sleep(cfg.DelayMs)
        end
        self:RunAutoCollectRadius4(bx, by)

        for offset = 1, span do
            if not af.Active or af.Mode ~= "2. PABRIK" then break end
            self:RequestTileChange(bx + offset, by, seedID)
            _sleep(cfg.DelayMs)
        end
        cfg.Cycles += 1

    elseif mode == "3. CLEAR" then
        local cfg = af.Clear
        af.StatusText = "CLEAR [1] SWEEPING"
        for y = 0, 53 do
            if not af.Active or af.Mode ~= "3. CLEAR" then break end
            for x = 0, 99 do
                if not af.Active or af.Mode ~= "3. CLEAR" then break end
                local tile = self:CheckTile(x, y)
                local skip = cfg.SkipBedrock and (tile.fg == 8 or tile.fg == 6)
                if not skip and (tile.fg ~= 0 or tile.bg ~= 0 or x == px) then
                    self:MoveToGrid(x, math.max(0, y - 1), cfg.DelayMs)
                    self:RequestTileChange(x, y, 18)
                    _sleep(cfg.DelayMs)
                    self:RunAutoCollectRadius4(x, y)
                    cfg.ClearedCount += 1
                    break
                end
            end
        end

    elseif mode == "4. TEIN PNB" then
        local cfg = af.TeinPNB
        local dir = facingLeft and -1 or 1
        local range = math.clamp(tonumber(cfg.RangeBlock) or 5, 1, 10)
        local blockID = tonumber(cfg.BlockID) or 340
        local hits = math.clamp(tonumber(cfg.HitCount) or 4, 1, 12)

        af.StatusText = string.format("TEIN PNB [1] (R:%d)", range)
        for i = 1, range do
            if not af.Active or af.Mode ~= "4. TEIN PNB" then break end
            self:RequestTileChange(px + (i * dir), py, blockID)
            _sleep(cfg.PlaceDelay)
        end
        for i = 1, range do
            if not af.Active or af.Mode ~= "4. TEIN PNB" then break end
            local tx = px + (i * dir)
            for _ = 1, hits do
                if not af.Active or af.Mode ~= "4. TEIN PNB" then break end
                self:RequestTileChange(tx, py, 18)
                _sleep(cfg.BreakDelay)
            end
            self:RunAutoCollectRadius4(tx, py)
        end
        cfg.Cycles += 1

    elseif mode == "5. RYO LAVA" then
        local cfg = af.LavaFarm
        local dirY = (cfg.Direction == "up") and -1 or 1
        local spread = tonumber(cfg.SpreadCount) or 5
        local offsets = (spread == 1 and {0}) or (spread == 3 and {-1, 0, 1}) or {-2, -1, 0, 1, 2}

        af.StatusText = string.format("RYO LAVA [1] (%dX)", spread)
        for _, dx in ipairs(offsets) do
            if not af.Active or af.Mode ~= "5. RYO LAVA" then break end
            local tx, ty = px + dx, py + dirY
            self:RequestTileChange(tx, ty, tonumber(cfg.BlockID) or 4)
            _sleep(cfg.PnbDelay)
            for _ = 1, 4 do
                self:RequestTileChange(tx, ty, 18)
                _sleep(cfg.PnbDelay)
            end
            self:RunAutoCollectRadius4(tx, ty)
        end

    elseif mode == "6. AUTO-DF" then
        local cfg = af.AutoDF
        local buildID = cfg.UsePlatform and cfg.PlatformID or cfg.BlockID
        af.StatusText = "AUTO-DF [1] (" .. tostring(cfg.TargetWorld) .. ")"
        self:RequestTileChange(px + 1, py, buildID)
        _sleep(cfg.PlaceDelay)
        self:RequestTileChange(px + 1, py + 1, 18)
        _sleep(cfg.PunchDelay)
        self:RunAutoCollectRadius4(px + 1, py + 1)
    end
end

-- // =========================================================================
-- // SECTION 10: SPAM CHAT & CLIENT VISUAL SPOOFER
-- // =========================================================================

local ColorPrefixMap = {
    ["None (Normal)"]         = "",
    ["`2 Green (Priority)"]   = "`2",
    ["`4 Red (Alert)"]        = "`4",
    ["`9 Yellow (Gold)"]      = "`9",
    ["`b Cyan (Aqua)"]        = "`b",
    ["`# Purple (Broadcast)"] = "`#",
    ["`^ Orange (Warm)"]      = "`^",
    ["`0 White (Bright)"]     = "`0",
    ["`6 Pink (Rose)"]        = "`6",
    ["Rainbow Auto-Cycle"]    = "`2"
}
local RainbowCodes = { "`2", "`4", "`9", "`b", "`#", "`^", "`6", "`0" }
local RainbowIndex = 1

function C8_FUNC:BuildFormattedSpamText()
    local sc = self.State.SpamChat
    local rawMsg = sc.Message or ""
    local prefixCmd = ""
    if sc.ChannelPrefix == "/sb (Super Broadcast)" then
        prefixCmd = "/sb "
    elseif sc.ChannelPrefix == "/b (Broadcast)" then
        prefixCmd = "/b "
    elseif sc.ChannelPrefix == "/me (Action)" then
        prefixCmd = "/me "
    end

    local colorTag = ""
    if sc.AutoPrefix then
        if sc.ColorChoice == "Rainbow Auto-Cycle" then
            colorTag = RainbowCodes[RainbowIndex] or "`2"
            RainbowIndex = (RainbowIndex % #RainbowCodes) + 1
        else
            colorTag = ColorPrefixMap[sc.ColorChoice] or "`2"
        end
    end

    local finalMsg = prefixCmd .. colorTag .. rawMsg
    sc.LastPreview = finalMsg
    return finalMsg
end

function C8_FUNC:SendChatMessage(msg)
    local text = tostring(msg or self:BuildFormattedSpamText())

    -- 1. Try Shared.Net Chat ByteNet packet
    self:SendByteNetPacket({ "chat", "sendchat", "message", "chatmessage" }, { text = text, message = text })

    -- 2. Try Genta/Bothax packet type 2
    self:SendPacket(2, "action|input\n|text|" .. text)

    -- 3. Try Roblox TextChatService / DefaultChatSystemChatEvents
    pcall(function()
        if TextChatService and TextChatService.ChatInputBarConfiguration and TextChatService.ChatInputBarConfiguration.TargetTextChannel then
            TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(text)
            return
        end
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
            chatEvents.SayMessageRequest:FireServer(text, "All")
        end
    end)

    self.State.SpamChat.SentCount += 1
    return text
end

function C8_FUNC:ApplyVisualSpoof()
    local v = self.State.Visual
    local prefix = v.ModTitle and "`4[MOD] @" or ""
    local baseName = (v.CustomName ~= "" and v.CustomName) or (LocalPlayer and LocalPlayer.Name) or "Operator"
    local finalDisplay = prefix .. baseName

    if type(sendVariant) == "function" then
        pcall(sendVariant, { [0] = "OnNameChanged", [1] = finalDisplay })
    end

    if LocalPlayer then
        pcall(function()
            LocalPlayer.DisplayName = finalDisplay
            LocalPlayer:SetAttribute("CustomName", finalDisplay)
            LocalPlayer:SetAttribute("IsModerator", v.ModTitle)
        end)

        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.DisplayName = finalDisplay end
            for _, desc in ipairs(char:GetDescendants()) do
                if desc:IsA("TextLabel") and (desc.Name:lower():find("name") or desc.Name:lower():find("tag")) then
                    desc.Text = finalDisplay
                    if v.ModTitle then desc.TextColor3 = Color3.fromRGB(255, 215, 0) end
                end
            end
        end

        local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pGui then
            local gameGui = pGui:FindFirstChild("GameGui")
            if gameGui then
                for _, lbl in ipairs(gameGui:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Text:find(LocalPlayer.Name, 1, true) then
                        lbl.Text = lbl.Text:gsub(LocalPlayer.Name, finalDisplay)
                    end
                end
            end
        end
    end
    return finalDisplay
end

-- // =========================================================================
-- // SECTION 11: INITIALIZATION & BACKGROUND RUNTIME LOOPS
-- // =========================================================================

function C8_FUNC:Init()
    if self._Initialized then return self end
    self._Initialized = true

    self:DiscoverGameModules()
    self:BuildItemDatabase()
    self:ReadLiveWorldAndPosition()

    -- Physics Loop (NoClip & GodMode)
    RunService.Stepped:Connect(function()
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        if not char then return end

        if self.State.Misc.NoClip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end

        if self.State.Misc.GodMode then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)

    -- ModFly Infinite Air Jump
    UserInputService.JumpRequest:Connect(function()
        if self.State.Misc.ModFly then
            local lp = Players.LocalPlayer
            local char = lp and lp.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    if getgenv then
        getgenv().C8_FUNC = self
    end
    _G.C8_FUNC = self

    return self
end

return C8_FUNC:Init()