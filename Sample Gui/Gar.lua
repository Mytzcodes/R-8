--[[
    ============================================================================
    PRODUCT: SYPHUS_HUB // C&8_FUNC v2.0 MASTER SUITE (R8G EDITION)
    COPYRIGHT: R&8_DV (Mytzcodes/R-8 Architecture)
    GUI BASE: https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Sample%20Gui/r8g.lua
    INTEGRATED LOGIC:
      - Misc Engine (ModFly, Noclip, Fast Roulette, Fast Wrench, God, Speed, Jump, Gravity)
      - Live Telemetry HUD (X, Y, Facing Direction, Player Name, Total Players, World Name)
      - Interactive Item Info Explorer (Search Bar, Scrollable Asset Cards, Complete Info, Copy ID/Name)
      - Multi-Mode Auto Farm (Always-On Radius 4 Collect + Dynamic Sub-Mode Input Panels):
          [1] BASIC (Item ID, NoHand, Speed, 6x6 Grid, Select Pos)
          [2] PABRIK (Break X/Y, Seed ID, Radius/Total Seed)
          [3] CLEAR + AUTO DROP (Kurotsume Multi-World BG Clear & Storage Drop)
          [4] TEIN PNB (Facing Direction Range Block Place & Multi-Hit Punch)
          [5] RYO LAVA FARM (Spread 1/3/5 PNB, Plant 20, Harvest Ready, Drop Extra Seed)
          [6] AUTO-DF BUILDER (Full World Sustainer, Tunnels, Ladders, Lava Holes, Skybuild)
      - Spam Chat Engine (Message Input, Auto Prefix/Color Selector, Delay Slider, 1-Button Toggle)
      - Client Visual Spoofer (Set Name, Set Moderator Title, Custom Map GUI Visuals)
    ============================================================================
]]

-- // =========================================================================
-- // PART 1: DUAL-ENVIRONMENT API BRIDGE & C&8_FUNC CORE LOGIC ENGINE
-- // =========================================================================

local C8_FUNC = {}
C8_FUNC.__index = C8_FUNC

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TextChatService = game:GetService("TextChatService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local setclipboard_fn = setclipboard or toclipboard or (Clipboard and Clipboard.set) or function() end

-- Native Genta / Packet Sandbox Bridges with Safe Luau Fallbacks
local function _sleep(ms)
    if type(sleep) == "function" then
        return sleep(ms)
    elseif task and task.wait then
        return task.wait((ms or 100) / 1000)
    else
        local t = os.clock()
        while os.clock() - t <= (ms or 100) / 1000 do end
    end
end

local function _isValid(obj)
    return obj ~= nil and type(obj) ~= "boolean"
end

local function _log(msg)
    if type(logToConsole) == "function" then
        pcall(logToConsole, "[C&8_FUNC] " .. tostring(msg))
    else
        print("[C&8_FUNC] " .. tostring(msg))
    end
end

local function _showOverlay(txt)
    if type(sendVariant) == "function" then
        local var = {}
        var[0] = "OnTextOverlay"
        var[1] = "`2[C&8_FUNC] `0" .. tostring(txt)
        pcall(sendVariant, var)
    end
end

local function _getLocal()
    if type(getLocal) == "function" then
        local ok, res = pcall(getLocal)
        if ok and _isValid(res) then return res end
    end
    if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        return {
            name = LocalPlayer.DisplayName or LocalPlayer.Name,
            pos = {
                x = hrp.Position.X * 8,
                y = hrp.Position.Y * 8,
                facingLeft = (hrp.CFrame.LookVector.X < 0)
            }
        }
    end
    return { name = LocalPlayer and LocalPlayer.Name or "Operator", pos = { x = 0, y = 0, facingLeft = false } }
end

local function _getWorld()
    if type(getWorld) == "function" then
        local ok, w = pcall(getWorld)
        if ok and _isValid(w) then return w end
    end
    local wName = (Workspace and Workspace:GetAttribute("WorldName"))
        or (Workspace and Workspace:FindFirstChild("WorldName") and Workspace.WorldName.Value)
        or (game and game.Name) or "SECTOR_01"
    return { name = tostring(wName) }
end

local function _getInventory()
    if type(getInventory) == "function" then
        local ok, inv = pcall(getInventory)
        if ok and (type(inv) == "table" or type(inv) == "userdata") then return inv end
    end
    return {}
end

local function _getWorldObject()
    if type(getWorldObject) == "function" then
        local ok, objs = pcall(getWorldObject)
        if ok and (type(objs) == "table" or type(objs) == "userdata") then return objs end
    end
    return {}
end

local function _checkTile(x, y)
    if type(checkTile) == "function" then
        local ok, t = pcall(checkTile, x, y)
        if ok and _isValid(t) then return t end
    elseif type(GetTile) == "function" then
        local ok, t = pcall(GetTile, x, y)
        if ok and _isValid(t) then return t end
    end
    return { fg = 0, bg = 0, pos = { x = x, y = y } }
end

local function _getExtraTile(x, y)
    if type(getExtraTile) == "function" then
        local ok, ext = pcall(getExtraTile, x, y)
        if ok and _isValid(ext) then return ext end
    end
    return { ready = true }
end

local function _getAllTiles()
    if type(getTile) == "function" then
        local ok, tiles = pcall(getTile)
        if ok and _isValid(tiles) then return tiles end
    elseif type(GetTiles) == "function" then
        local ok, tiles = pcall(GetTiles)
        if ok and _isValid(tiles) then return tiles end
    end
    return {}
end

local function _sendPacket(pktType, strPayload)
    if type(sendPacket) == "function" then
        return pcall(sendPacket, pktType, strPayload)
    elseif type(SendPacket) == "function" then
        return pcall(SendPacket, pktType, strPayload)
    elseif ReplicatedStorage then
        local rem = ReplicatedStorage:FindFirstChild("SendPacket", true)
        if rem and rem:IsA("RemoteEvent") then
            rem:FireServer(pktType, strPayload)
            return true
        end
    end
    return false
end

local function _sendPacketRaw(flag, tblPayload)
    if type(sendPacketRaw) == "function" then
        return pcall(sendPacketRaw, flag, tblPayload)
    elseif type(SendPacketRaw) == "function" then
        return pcall(SendPacketRaw, flag, tblPayload)
    end
    return false
end

local function _requestTileChange(x, y, itemID)
    if type(requestTileChange) == "function" then
        return pcall(requestTileChange, x, y, itemID)
    end
    local loc = _getLocal()
    return _sendPacketRaw(false, {
        type = 3,
        value = itemID,
        punchx = x,
        punchy = y,
        px = x,
        py = y,
        x = loc.pos.x,
        y = loc.pos.y
    })
end

local function _findPath(x, y, delayOpt)
    if type(findPath) == "function" then
        if delayOpt then
            return pcall(findPath, x, y, delayOpt)
        else
            return pcall(findPath, x, y)
        end
    elseif LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x * 4, y * 4, LocalPlayer.Character.HumanoidRootPart.Position.Z)
        return true, true
    end
    return false
end

local function _toggleCheat(cheatID, state)
    if type(toggleCheat) == "function" then
        pcall(toggleCheat, cheatID, state)
    end
end

local function _patchMemoryByName(patchName)
    if type(patchMemoryByName) == "function" then
        pcall(patchMemoryByName, patchName)
    end
end

-- // CENTRALIZED STATE REGISTRY
C8_FUNC.State = {
    Misc = {
        ModFly = false,
        FlySpeed = 48,
        Noclip = false,
        FastRoulette = false,
        FastWrench = false,
        WrenchMode = "Pull", -- "Pull" | "Kick" | "Ban"
        GodMode = false,
        Speed = false,
        SpeedValue = 36,
        HighJump = false,
        JumpValue = 85,
        AntiGravity = false,
        GravityValue = 35,
        AntiTakeItem = false
    },
    Telemetry = {
        X = 0,
        Y = 0,
        FacingLeft = false,
        PlayerName = LocalPlayer and LocalPlayer.Name or "Operator",
        TotalPlayers = 1,
        WorldName = "SECTOR_01"
    },
    ItemDB = {
        Registry = {},
        Filtered = {},
        SelectedItem = nil,
        LastSearch = ""
    },
    AutoFarm = {
        Active = false,
        StatusText = "IDLE // STANDBY",
        Mode = "BASIC", -- "BASIC" | "PABRIK" | "CLEAR" | "TEIN_PNB" | "LAVA_FARM" | "AUTO_DF"
        AutoCollect = true,
        CollectRadius = 4,

        Basic = {
            ItemID = 2,
            NoHand = false,
            SpeedDelay = 160,
            Grid6x6 = false,
            SelectPos = { X = 0, Y = 0 }
        },
        Pabrik = {
            BreakX = 0,
            BreakY = 0,
            SeedID = 3,
            RadiusOrTotal = 6,
            Delay = 160
        },
        Clear = {
            WorldsListString = "world1,world2",
            Worlds = { "world1", "world2" },
            DropWorld = "dropworld/storageworld",
            DropX = 9,
            DropY = 18,
            DropAmount = 100,
            TargetBG = 14,
            PunchDelay = 250,
            PathDelay = 250,
            DropItems = {
                { name = "Dirt Seed",        id = 3 },
                { name = "Dirt Block",       id = 2 },
                { name = "Background Seed",  id = 15 },
                { name = "Background Block", id = 14 },
                { name = "Stone Seed",       id = 11 },
                { name = "Stone Block",      id = 10 }
            }
        },
        TeinPNB = {
            BlockID = 340,
            HitCount = 1,
            PlaceDelay = 100,
            BreakDelay = 100,
            RangeBlock = 5
        },
        LavaFarm = {
            FarmWorld = "LAVAFARM|A1",
            DropWorld = "LAVADROP|B2",
            BlockID = 4,
            SeedID = 5,
            DropLimit = 200,
            KeepSeed = 100,
            DropX = 6,
            DropY = 10,
            PnbDelay = 210,
            PlantDelay = 500,
            HarvestDelay = 500,
            SpreadCount = 5,
            Direction = "up",
            PlantMax = 20
        },
        AutoDF = {
            TargetWorld = "NTUUM",
            DropWorld = "KUALISTORAGE",
            DropX = 83,
            DropY = 23,
            UseJammer = false,
            UsePlatform = true,
            DoorID = 2810,
            JammerID = 226,
            PlatformID = 102,
            BlockID = 2,
            SeedID = 3,
            LavaID = 4,
            MainDoorID = 6,
            WlID = 242,
            MaxBlockPNB = 150,
            PlantLimit = 50,
            TargetRows = { 25, 27, 29 },
            PunchDelay = 230,
            MoveDelay = 200,
            PlaceDelay = 350,
            PlaceMoveDelay = 400,
            SafeNavDelay = 400,
            LavaMoveDelay = 400,
            LavaPunchDelay = 350,
            LavaPlaceDelay = 500,
            DropThreshold = 150,
            DropFixedCount = 100
        }
    },
    SpamChat = {
        Active = false,
        Message = "SYPHUS_HUB // R&8_DV ON TOP",
        AutoPrefix = true,
        ColorPrefix = "`2",
        Delay = 4000
    },
    Visual = {
        CustomName = "",
        ModTitle = false,
        RolePreset = "Default",
        MapGuiScale = 1.0,
        CustomAccentOverride = false
    }
}

local _Connections = {}
local _LavaHoles = {}
local _DropHookState = {
    IsDropping = false,
    DroppingAmount = 0,
    TargetDropID = 0,
    HookRegistered = false
}

-- // CORE LOGIC METHODS
function C8_FUNC:InitDropDialogHook()
    if _DropHookState.HookRegistered then return end
    if type(AddHook) == "function" then
        local function onVarlistHook(vlist)
            if _isValid(vlist) and _isValid(vlist[0]) then
                if type(vlist[0]) == "string" and vlist[0]:find("OnDialogRequest") then
                    if type(vlist[1]) == "string" and vlist[1]:find("end_dialog|drop_item") and _DropHookState.IsDropping then
                        local itemID = vlist[1]:match("itemID|(%d+)")
                        if itemID then
                            local pkt = string.format("action|dialog_return\ndialog_name|drop_item\nitemID|%s|\ncount|%d\n", itemID, _DropHookState.DroppingAmount)
                            _sendPacket(2, pkt)
                            _DropHookState.IsDropping = false
                            return true
                        end
                    end
                end
            end
            return false
        end
        pcall(AddHook, "onvarlist", "C8_BuilderHook", onVarlistHook)
        _DropHookState.HookRegistered = true
    end
end

function C8_FUNC:RemoveDropDialogHook()
    if type(RemoveHook) == "function" and _DropHookState.HookRegistered then
        pcall(RemoveHook, "C8_BuilderHook")
        _DropHookState.HookRegistered = false
    end
end

function C8_FUNC:GetItemCount(itemID)
    for _, item in pairs(_getInventory()) do
        if _isValid(item) and item.id == itemID then
            return item.amount
        end
    end
    return 0
end

function C8_FUNC:GetPlayerGridPos()
    local p = _getLocal()
    if _isValid(p) and _isValid(p.pos) then
        return math.floor(p.pos.x / 32), math.floor(p.pos.y / 32), (p.pos.facingLeft == true)
    end
    return 0, 0, false
end

function C8_FUNC:GetPositionInfo()
    local px, py, facingLeft = self:GetPlayerGridPos()
    local loc = _getLocal()
    local w = _getWorld()

    self.State.Telemetry.X = px
    self.State.Telemetry.Y = py
    self.State.Telemetry.FacingLeft = facingLeft
    self.State.Telemetry.PlayerName = loc.name or (LocalPlayer and LocalPlayer.Name) or "Operator"
    self.State.Telemetry.TotalPlayers = (Players and #Players:GetPlayers()) or 1
    self.State.Telemetry.WorldName = (w and w.name) or "SECTOR_01"

    return self.State.Telemetry
end

function C8_FUNC:IsPlayerReady()
    local px, py = self:GetPlayerGridPos()
    return px ~= -1 and py ~= -1
end

function C8_FUNC:WaitForReconnect()
    if self:IsPlayerReady() then return true end
    _showOverlay("`4Waiting for Reconnect...")
    while self.State.AutoFarm.Active and not self:IsPlayerReady() do
        _sleep(5000)
    end
    _sleep(3000)
    return self:IsPlayerReady()
end

function C8_FUNC:WaitToArrive(tx, ty)
    for _ = 1, 25 do
        if not self.State.AutoFarm.Active then return false end
        local px, py = self:GetPlayerGridPos()
        if px ~= -1 and math.abs(px - tx) <= 1 and math.abs(py - ty) <= 1 then
            return true
        end
        _sleep(200)
    end
    return false
end

function C8_FUNC:SafeMove(x, y, customDelay)
    local delayToUse = customDelay or self.State.AutoFarm.AutoDF.MoveDelay
    if not self:WaitForReconnect() then return false end
    local px, py = self:GetPlayerGridPos()

    if px ~= -1 and math.abs(px - x) <= 1 and math.abs(py - y) <= 1 then
        _sleep(math.floor(delayToUse / 2))
        return true
    end

    local ok, res = _findPath(x, y)
    if ok and res ~= false then
        if self:WaitToArrive(x, y) then
            _sleep(delayToUse)
            return true
        end
    end
    _sleep(300)
    return false
end

function C8_FUNC:WarpWorld(worldName, useInvitedZero)
    local targetClean = string.upper(tostring(worldName))
    local baseTarget = string.match(targetClean, "^([^|]+)") or targetClean

    local w = _getWorld()
    if _isValid(w) and type(w.name) == "string" and string.find(string.upper(w.name), baseTarget, 1, true) then
        return true
    end

    self.State.AutoFarm.StatusText = "WARPING -> " .. baseTarget
    _showOverlay("`9Warping to: `w" .. targetClean)
    _log("Warping to world: " .. targetClean)

    local payload = "action|join_request\nname|" .. targetClean
    if useInvitedZero ~= false then
        payload = payload .. "\ninvitedWorld|0"
    end
    _sendPacket(3, payload)

    for _ = 1, 30 do
        if not self.State.AutoFarm.Active then return false end
        _sleep(500)
        w = _getWorld()
        if _isValid(w) and type(w.name) == "string" and string.find(string.upper(w.name), baseTarget, 1, true) then
            _showOverlay("`2Arrived at: `w" .. baseTarget)
            _sleep(3000)
            return true
        end
    end
    return false
end

-- AUTO COLLECT ON ALWAYS WHEN FARMING (RADIUS 4 LOCK)
function C8_FUNC:RunAutoCollectRadius4(centerTileX, centerTileY, customTileRadius)
    if not self.State.AutoFarm.AutoCollect then return end
    local radiusTiles = customTileRadius or self.State.AutoFarm.CollectRadius or 4

    if type(requestCollectByRange) == "function" then
        pcall(requestCollectByRange, radiusTiles)
    end

    local px, py = self:GetPlayerGridPos()
    local cx = centerTileX or px
    local cy = centerTileY or py
    local localRaw = _getLocal()

    for _, obj in pairs(_getWorldObject()) do
        if _isValid(obj) and _isValid(obj.pos) then
            local ox = math.floor(obj.pos.x / 32)
            local oy = math.floor(obj.pos.y / 32)
            local withinTileRadius = (math.abs(ox - cx) <= radiusTiles and math.abs(oy - cy) <= radiusTiles)
            local withinPixelRadius = (_isValid(localRaw.pos) and math.abs(localRaw.pos.x - obj.pos.x) < (radiusTiles * 32) and math.abs(localRaw.pos.y - obj.pos.y) < (radiusTiles * 32))

            if withinTileRadius or withinPixelRadius then
                _sendPacketRaw(false, {
                    type = 11,
                    value = obj.oid or obj.id,
                    x = obj.pos.x,
                    y = obj.pos.y
                })
                _sleep(5)
            end
        end
    end
end

-- // MISC METHODS
function C8_FUNC:SetModFly(status, flySpeed)
    self.State.Misc.ModFly = (status == true)
    if flySpeed then self.State.Misc.FlySpeed = tonumber(flySpeed) or 48 end

    _toggleCheat(26, self.State.Misc.ModFly)
    if self.State.Misc.ModFly then _patchMemoryByName("Mod fly") end

    if _Connections.ModFly then _Connections.ModFly:Disconnect() _Connections.ModFly = nil end
    if self.State.Misc.ModFly and LocalPlayer then
        _Connections.ModFly = RunService.RenderStepped:Connect(function()
            local c = LocalPlayer.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local bv = root:FindFirstChild("C8_FlyBV") or Instance.new("BodyVelocity", root)
            bv.Name = "C8_FlyBV"
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1, 0, 0) end
            bv.Velocity = (move.Magnitude > 0) and (move.Unit * self.State.Misc.FlySpeed) or Vector3.zero
        end)
    elseif LocalPlayer and LocalPlayer.Character then
        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and root:FindFirstChild("C8_FlyBV") then root.C8_FlyBV:Destroy() end
    end
    return self.State.Misc.ModFly
end

function C8_FUNC:SetAntiTakeItem(status)
    self.State.Misc.AntiTakeItem = (status == true)
    _toggleCheat(22, self.State.Misc.AntiTakeItem)
    return self.State.Misc.AntiTakeItem
end

function C8_FUNC:SetNoclip(status)
    self.State.Misc.Noclip = (status == true)
    if _Connections.Noclip then _Connections.Noclip:Disconnect() _Connections.Noclip = nil end
    if self.State.Misc.Noclip and LocalPlayer then
        _Connections.Noclip = RunService.Stepped:Connect(function()
            if not LocalPlayer.Character then return end
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    return self.State.Misc.Noclip
end

function C8_FUNC:SetFastRoulette(status)
    self.State.Misc.FastRoulette = (status == true)
    if Workspace then Workspace:SetAttribute("FastRoulette", self.State.Misc.FastRoulette) end
    return self.State.Misc.FastRoulette
end

function C8_FUNC:SetFastWrench(status, mode)
    self.State.Misc.FastWrench = (status == true)
    if mode then self.State.Misc.WrenchMode = tostring(mode) end
    return self.State.Misc.FastWrench
end

function C8_FUNC:SetGodMode(status)
    self.State.Misc.GodMode = (status == true)
    if _Connections.GodMode then _Connections.GodMode:Disconnect() _Connections.GodMode = nil end
    if self.State.Misc.GodMode and LocalPlayer then
        _Connections.GodMode = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = hum.MaxHealth end
        end)
    end
    return self.State.Misc.GodMode
end

function C8_FUNC:SetSpeed(status, val)
    self.State.Misc.Speed = (status == true)
    if val then self.State.Misc.SpeedValue = tonumber(val) or 36 end
    if _Connections.Speed then _Connections.Speed:Disconnect() _Connections.Speed = nil end
    if self.State.Misc.Speed and LocalPlayer then
        _Connections.Speed = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = self.State.Misc.SpeedValue end
        end)
    elseif LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
    return self.State.Misc.Speed
end

function C8_FUNC:SetHighJump(status, val)
    self.State.Misc.HighJump = (status == true)
    if val then self.State.Misc.JumpValue = tonumber(val) or 85 end
    if _Connections.HighJump then _Connections.HighJump:Disconnect() _Connections.HighJump = nil end
    if self.State.Misc.HighJump and LocalPlayer then
        _Connections.HighJump = RunService.Heartbeat:Connect(function()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = self.State.Misc.JumpValue
            end
        end)
    elseif LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = 50
    end
    return self.State.Misc.HighJump
end

function C8_FUNC:SetAntiGravity(status, val)
    self.State.Misc.AntiGravity = (status == true)
    if val then self.State.Misc.GravityValue = tonumber(val) or 35 end
    if Workspace then
        Workspace.Gravity = self.State.Misc.AntiGravity and self.State.Misc.GravityValue or 196.2
    end
    return self.State.Misc.AntiGravity
end

-- // ITEM DATABASE
function C8_FUNC:InitItemDatabase()
    self.State.ItemDB.Registry = {
        { ID = 2,    Name = "Dirt Block",            Rarity = 1,  GrowTime = 30,     Hits = 3, Category = "Block",      Description = "Standard soil block used for base foundation and Dirt Farms.", IconAsset = "rbxassetid://6031075938" },
        { ID = 3,    Name = "Dirt Seed",             Rarity = 1,  GrowTime = 30,     Hits = 1, Category = "Seed",       Description = "Plant on any solid block to grow a Dirt Tree in 30s.",       IconAsset = "rbxassetid://6031075938" },
        { ID = 4,    Name = "Lava Block",            Rarity = 2,  GrowTime = 60,     Hits = 4, Category = "Block",      Description = "Molten volcanic hazard block. High drop rate in Ryo PNB.",   IconAsset = "rbxassetid://6031280882" },
        { ID = 5,    Name = "Lava Seed",             Rarity = 2,  GrowTime = 60,     Hits = 1, Category = "Seed",       Description = "Grows a Lava Tree. Spliced with Dirt for mass production.", IconAsset = "rbxassetid://6031280882" },
        { ID = 6,    Name = "Main Door",             Rarity = 1,  GrowTime = 0,      Hits = 0, Category = "Door",       Description = "Unbreakable world entry spawn point.",                      IconAsset = "rbxassetid://6031094678" },
        { ID = 8,    Name = "Bedrock",               Rarity = 99, GrowTime = 0,      Hits = 0, Category = "Bedrock",    Description = "Indestructible bottom layer boundary block.",               IconAsset = "rbxassetid://6031094678" },
        { ID = 10,   Name = "Rock Block",            Rarity = 2,  GrowTime = 60,     Hits = 5, Category = "Block",      Description = "Dense subterranean stone block found in world generation.",  IconAsset = "rbxassetid://6031075938" },
        { ID = 11,   Name = "Rock Seed",             Rarity = 2,  GrowTime = 60,     Hits = 1, Category = "Seed",       Description = "Grows a Rock Tree.",                                        IconAsset = "rbxassetid://6031075938" },
        { ID = 14,   Name = "Cave Background",       Rarity = 1,  GrowTime = 45,     Hits = 3, Category = "Background", Description = "Standard underground cave wall cleared by Kurotsume Clear.", IconAsset = "rbxassetid://6031075938" },
        { ID = 15,   Name = "Cave Background Seed",  Rarity = 1,  GrowTime = 45,     Hits = 1, Category = "Seed",       Description = "Grows Cave Background blocks.",                             IconAsset = "rbxassetid://6031075938" },
        { ID = 18,   Name = "Fist",                  Rarity = 0,  GrowTime = 0,      Hits = 1, Category = "Tool",       Description = "Primary tile break action ID (18).",                        IconAsset = "rbxassetid://6031265976" },
        { ID = 32,   Name = "Wrench",                Rarity = 0,  GrowTime = 0,      Hits = 1, Category = "Tool",       Description = "Configures doors, locks, and Fast Wrench Pull/Kick/Ban.",    IconAsset = "rbxassetid://6031265976" },
        { ID = 102,  Name = "Wooden Platform",       Rarity = 4,  GrowTime = 120,    Hits = 3, Category = "Platform",   Description = "Used by Auto-DF Builder for edge ladders (Cols 1 & 98).",   IconAsset = "rbxassetid://6031075938" },
        { ID = 226,  Name = "Signal Jammer",         Rarity = 15, GrowTime = 900,    Hits = 5, Category = "Toggle",     Description = "Blocks world broadcast & hides radar presence.",             IconAsset = "rbxassetid://6031280882" },
        { ID = 242,  Name = "World Lock",            Rarity = 99, GrowTime = 0,      Hits = 6, Category = "Lock",       Description = "Secures entire world ownership & permissions.",             IconAsset = "rbxassetid://6031094678" },
        { ID = 340,  Name = "Chandelier",            Rarity = 87, GrowTime = 129060, Hits = 5, Category = "Farmable",   Description = "High-gem farmable block default in Tein PNB.",              IconAsset = "rbxassetid://6031280882" },
        { ID = 2810, Name = "Air Vent / Door",       Rarity = 12, GrowTime = 400,    Hits = 4, Category = "Door",       Description = "Placed flanking Main Door during Auto-DF Defense Setup.",   IconAsset = "rbxassetid://6031094678" },
        { ID = 4584, Name = "Pepper Tree Block",     Rarity = 67, GrowTime = 80107,  Hits = 4, Category = "Farmable",   Description = "Fast-cycle farmable block for Basic & Pabrik modes.",       IconAsset = "rbxassetid://6031075938" },
        { ID = 5666, Name = "Laser Grid",            Rarity = 74, GrowTime = 97542,  Hits = 3, Category = "Farmable",   Description = "3-hit high-yield farmable security laser block.",           IconAsset = "rbxassetid://6031280882" }
    }
    self.State.ItemDB.Filtered = self.State.ItemDB.Registry
    self.State.ItemDB.SelectedItem = self.State.ItemDB.Registry[1]
    return self.State.ItemDB.Registry
end

function C8_FUNC:SearchItems(query)
    if #self.State.ItemDB.Registry == 0 then self:InitItemDatabase() end
    local q = tostring(query or ""):lower():gsub("^%s*(.-)%s*$", "%1")
    self.State.ItemDB.LastSearch = q
    if q == "" then
        self.State.ItemDB.Filtered = self.State.ItemDB.Registry
        return self.State.ItemDB.Filtered
    end
    local out = {}
    for _, it in ipairs(self.State.ItemDB.Registry) do
        if tostring(it.Name):lower():find(q, 1, true)
            or tostring(it.ID):find(q, 1, true)
            or tostring(it.Category):lower():find(q, 1, true) then
            table.insert(out, it)
        end
    end
    self.State.ItemDB.Filtered = out
    return out
end

function C8_FUNC:CopyItemData(itemObj, copyMode)
    if not itemObj then return "" end
    local m = tostring(copyMode or "ID"):upper()
    local payload = (m == "NAME" and tostring(itemObj.Name))
        or (m == "BOTH" and (itemObj.Name .. " [" .. itemObj.ID .. "]"))
        or tostring(itemObj.ID)
    setclipboard_fn(payload)
    return payload
end

-- // AUTO FARM SUB-ENGINES
local function getRyoSpreadOffsets(n)
    if n == 1 then return { 0 }
    elseif n == 3 then return { -1, 0, 1 }
    elseif n == 5 then return { -2, -1, 0, 1, 2 }
    else return { 0 } end
end

function C8_FUNC:ExecuteLavaFarmCycle()
    local cfg = self.State.AutoFarm.LavaFarm
    self.State.AutoFarm.StatusText = "LAVA_FARM // WARPING TO " .. cfg.FarmWorld
    self:WarpWorld(cfg.FarmWorld, false)
    _findPath(1, 1)
    _sleep(500)

    while self.State.AutoFarm.Active and self.State.AutoFarm.Mode == "LAVA_FARM" do
        local seedCount = self:GetItemCount(cfg.SeedID)
        if seedCount >= cfg.DropLimit then
            local dropCount = seedCount - cfg.KeepSeed
            if dropCount > 0 then
                self.State.AutoFarm.StatusText = "LAVA_FARM // DROPPING " .. dropCount .. " SEEDS"
                self:WarpWorld(cfg.DropWorld, false)
                _findPath(cfg.DropX, cfg.DropY)
                _sleep(1000)
                _sendPacket(2, "action|drop\n|itemID|" .. cfg.SeedID)
                _sleep(500)
                _sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. cfg.SeedID .. "|\ncount|" .. dropCount)
                _sendPacket(2, "action|dialog_return\ndialog_name|ok")
                _sendPacket(2, "action|dialog_return\ndialog_name|close")
                _sleep(1500)
                self:WarpWorld(cfg.FarmWorld, false)
            end
        end

        self.State.AutoFarm.StatusText = "LAVA_FARM // PNB + COLLECT (RAD 4)"
        local dir = (cfg.Direction == "up") and -1 or 1
        while self.State.AutoFarm.Active and self.State.AutoFarm.Mode == "LAVA_FARM" and self:GetItemCount(cfg.BlockID) > 0 do
            local px, py = self:GetPlayerGridPos()
            for _, dx in ipairs(getRyoSpreadOffsets(cfg.SpreadCount)) do
                if not self.State.AutoFarm.Active then break end
                local tx, ty = px + dx, py + dir
                _requestTileChange(tx, ty, cfg.BlockID)
                _sleep(cfg.PnbDelay)
                _requestTileChange(tx, ty, 18)
                _sleep(cfg.PnbDelay)
                self:RunAutoCollectRadius4(tx, ty, 4)
            end
        end

        self.State.AutoFarm.StatusText = "LAVA_FARM // PLANTING (MAX " .. cfg.PlantMax .. ")"
        local planted = 0
        for y = 0, 53 do
            if not self.State.AutoFarm.Active or self:GetItemCount(cfg.SeedID) <= 0 or planted >= cfg.PlantMax then break end
            for x = 0, 99 do
                if not self.State.AutoFarm.Active or self:GetItemCount(cfg.SeedID) <= 0 or planted >= cfg.PlantMax then break end
                local t = _checkTile(x, y)
                local b = _checkTile(x, y + 1)
                if t.fg == 0 and b.fg ~= 0 then
                    _findPath(x, y)
                    _sleep(100)
                    _requestTileChange(x, y, cfg.SeedID)
                    _sleep(cfg.PlantDelay)
                    planted = planted + 1
                end
            end
        end

        self.State.AutoFarm.StatusText = "LAVA_FARM // HARVESTING READY TREES"
        for y = 0, 53 do
            if not self.State.AutoFarm.Active then break end
            for x = 0, 99 do
                if not self.State.AutoFarm.Active then break end
                local t = _checkTile(x, y)
                local ext = _getExtraTile(x, y)
                if t.fg == cfg.SeedID and ext.ready then
                    _findPath(x, y)
                    _sleep(100)
                    _requestTileChange(x, y, 18)
                    _sleep(cfg.HarvestDelay)
                    self:RunAutoCollectRadius4(x, y, 4)
                end
            end
        end
        _sleep(500)
    end
end

function C8_FUNC:ExecuteTeinPNBCycle()
    local cfg = self.State.AutoFarm.TeinPNB
    local px, py, facingLeft = self:GetPlayerGridPos()
    local dir = facingLeft and -1 or 1
    self.State.AutoFarm.StatusText = string.format("TEIN_PNB // DIR:%s RANGE:%d", facingLeft and "LEFT" or "RIGHT", cfg.RangeBlock)

    for offsetX = 1, cfg.RangeBlock do
        if not self.State.AutoFarm.Active then return end
        _requestTileChange(px + (offsetX * dir), py, cfg.BlockID)
        _sleep(cfg.PlaceDelay)
    end

    for offsetX = 1, cfg.RangeBlock do
        if not self.State.AutoFarm.Active then return end
        local tx = px + (offsetX * dir)
        for _ = 1, cfg.HitCount do
            if not self.State.AutoFarm.Active then return end
            _requestTileChange(tx, py, 18)
            _sleep(cfg.BreakDelay)
        end
        self:RunAutoCollectRadius4(tx, py, 4)
    end
end

function C8_FUNC:GetReadyDropItem(dropItemsList, threshold)
    for _, itemData in ipairs(dropItemsList) do
        local amt = self:GetItemCount(itemData.id)
        if amt >= threshold then return itemData, amt end
    end
    return nil, 0
end

function C8_FUNC:ExecuteClearAndDropCycle()
    local cfg = self.State.AutoFarm.Clear
    self:SetAntiTakeItem(true)
    self:SetModFly(true)

    -- Parse comma-separated world list
    cfg.Worlds = {}
    for w in string.gmatch(cfg.WorldsListString or "world1", "([^,]+)") do
        local trimmed = w:gsub("^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then table.insert(cfg.Worlds, trimmed) end
    end
    if #cfg.Worlds == 0 then cfg.Worlds = { "world1" } end

    local function clearSinglePass()
        for y = 0, 54 do
            for x = 99, 0, -1 do
                if not self.State.AutoFarm.Active or self.State.AutoFarm.Mode ~= "CLEAR" then return false end
                local readyItem = self:GetReadyDropItem(cfg.DropItems, cfg.DropAmount)
                if readyItem ~= nil then return true end

                local tile = _checkTile(x, y)
                local matchTarget = (cfg.TargetBG == 0 and (tile.fg ~= 0 or tile.bg ~= 0)) or (tile.bg == cfg.TargetBG)

                if matchTarget and tile.fg ~= 8 and tile.fg ~= 6 then
                    self.State.AutoFarm.StatusText = string.format("CLEAR // BREAKING (%d, %d)", x, y)
                    _findPath(x, y - 1, 200)
                    _sleep(cfg.PathDelay)

                    while self.State.AutoFarm.Active and ((cfg.TargetBG == 0 and (_checkTile(x, y).fg ~= 0 or _checkTile(x, y).bg ~= 0)) or (_checkTile(x, y).bg == cfg.TargetBG)) do
                        _requestTileChange(x, y, 18)
                        _sleep(cfg.PunchDelay)
                        if self:GetReadyDropItem(cfg.DropItems, cfg.DropAmount) ~= nil then return true end
                    end
                    self:RunAutoCollectRadius4(x, y, 4)
                end
            end
        end
        return false
    end

    local function processStorageDrop()
        self.State.AutoFarm.StatusText = "CLEAR // DROPPING AT " .. cfg.DropWorld
        self:WarpWorld(cfg.DropWorld, true)
        _sleep(1500)
        _findPath(cfg.DropX, cfg.DropY, 200)
        _sleep(1500)

        for _, itemData in ipairs(cfg.DropItems) do
            if not self.State.AutoFarm.Active then break end
            if self:GetItemCount(itemData.id) >= cfg.DropAmount then
                _sendPacket(2, "action|drop\n|itemID|" .. itemData.id)
                _sleep(300)
                _sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. itemData.id .. "|\ncount|" .. cfg.DropAmount)
                _sleep(1000)
            end
        end
    end

    for i = 1, #cfg.Worlds do
        if not self.State.AutoFarm.Active or self.State.AutoFarm.Mode ~= "CLEAR" then break end
        local currentWorld = cfg.Worlds[i]
        self:WarpWorld(currentWorld, true)

        while self.State.AutoFarm.Active and self.State.AutoFarm.Mode == "CLEAR" do
            if clearSinglePass() then
                processStorageDrop()
                self:WarpWorld(currentWorld, true)
            else
                break
            end
        end
    end
    self.State.AutoFarm.Active = false
    self.State.AutoFarm.StatusText = "CLEAR // COMPLETED"
end

function C8_FUNC:ExecuteAutoDFBuilder()
    local cfg = self.State.AutoFarm.AutoDF
    self:SetAntiTakeItem(true)
    self:SetModFly(true)
    self:InitDropDialogHook()

    local function dropItemWithHook(id, threshold, dropCount)
        if self:GetItemCount(id) < threshold then return end
        self.State.AutoFarm.StatusText = "AUTO_DF // DROPPING ID " .. id
        _sleep(2000)
        if not self:WarpWorld(cfg.DropWorld, true) then return end
        if self:SafeMove(cfg.DropX, cfg.DropY) then
            _DropHookState.IsDropping = true
            _DropHookState.DroppingAmount = dropCount
            _DropHookState.TargetDropID = id
            _sendPacket(2, "action|drop\n|itemID|" .. id)
            local timeout = 0
            while _DropHookState.IsDropping and timeout < 30 do
                _sleep(100)
                timeout = timeout + 1
            end
            if _DropHookState.IsDropping then
                _sendPacket(2, string.format("action|dialog_return\ndialog_name|drop_item\nitemID|%d|\ncount|%d\n", id, dropCount))
                _DropHookState.IsDropping = false
            end
            _sleep(3000)
        end
        self:WarpWorld(cfg.TargetWorld, true)
        _sleep(3000)
    end

    local function checkAndDropAllItems()
        for _, id in ipairs({ 2, 3, 14, 15, 10, 11, 4, 5 }) do
            if not self.State.AutoFarm.Active then return end
            dropItemWithHook(id, cfg.DropThreshold, cfg.DropFixedCount)
        end
    end

    local function getSweepCenters(direction)
        local t = {}
        if direction == 1 then
            for c = 4, 94, 5 do table.insert(t, c) end
            table.insert(t, 97)
        else
            for c = 95, 5, -5 do table.insert(t, c) end
            table.insert(t, 2)
        end
        return t
    end

    local function runHarvest()
        self.State.AutoFarm.StatusText = "AUTO_DF // HARVESTING ROWS 25,27,29"
        if not self:SafeMove(1, 25, cfg.SafeNavDelay) then return 0 end
        local tilesToHarvest = {}
        for _, y in ipairs(cfg.TargetRows) do
            for x = 0, 99 do
                if _checkTile(x, y).fg == cfg.SeedID then
                    table.insert(tilesToHarvest, { x = x, y = y })
                end
            end
        end
        local harvestedCount = 0
        for i = 1, #tilesToHarvest do
            if not self.State.AutoFarm.Active or self:GetItemCount(cfg.BlockID) >= cfg.MaxBlockPNB then break end
            local target = tilesToHarvest[i]
            if self:SafeMove(target.x, target.y, cfg.SafeNavDelay) then
                local hitCount = 0
                while self.State.AutoFarm.Active and hitCount < 10 do
                    if _checkTile(target.x, target.y).fg == 0 then break end
                    _requestTileChange(target.x, target.y, 18)
                    _sleep(cfg.PunchDelay)
                    hitCount = hitCount + 1
                end
                self:RunAutoCollectRadius4(target.x, target.y, 8)
                harvestedCount = harvestedCount + 1
            end
        end
        return harvestedCount
    end

    local function runPlant()
        self.State.AutoFarm.StatusText = "AUTO_DF // PLANTING SEEDS (MAX 50)"
        if self:GetItemCount(cfg.SeedID) <= 0 then return 0 end
        if not self:SafeMove(1, 25, cfg.SafeNavDelay) then return 0 end
        local plantedCount = 0
        for _, y in ipairs(cfg.TargetRows) do
            for x = 0, 99 do
                if not self.State.AutoFarm.Active or plantedCount >= cfg.PlantLimit or self:GetItemCount(cfg.SeedID) <= 0 then break end
                if _checkTile(x, y).fg == 0 and self:SafeMove(x, y, cfg.SafeNavDelay) then
                    _sleep(100)
                    _requestTileChange(x, y, cfg.SeedID)
                    _sleep(cfg.PlaceDelay)
                    plantedCount = plantedCount + 1
                end
            end
        end
        return plantedCount
    end

    if not self:WarpWorld(cfg.TargetWorld, true) then
        self.State.AutoFarm.Active = false
        return
    end

    -- Phase 1: Defense & Tunnels & Ladders & Ground Rows & Lava & Sustainer Skybuild
    self.State.AutoFarm.StatusText = "AUTO_DF // CLEARING SIDE TUNNELS"
    local buildItemID = cfg.UsePlatform and cfg.PlatformID or cfg.BlockID
    for _, side in ipairs({ {0, 1}, {99, 98} }) do
        for y = 2, 53 do
            for _, x in ipairs(side) do
                if not self.State.AutoFarm.Active then return end
                checkAndDropAllItems()
                local t = _checkTile(x, y)
                local isLadder = ((x == 1 or x == 98) and (y % 2 == 0) and t.fg == buildItemID)
                if t and (t.fg ~= 0 or t.bg ~= 0) and t.fg ~= 8 and t.fg ~= cfg.MainDoorID and not isLadder then
                    if self:SafeMove(x, y - 1, cfg.MoveDelay) then
                        local tries = 0
                        while self.State.AutoFarm.Active and (_checkTile(x, y).fg ~= 0 or _checkTile(x, y).bg ~= 0) and tries < 15 do
                            _requestTileChange(x, y, 18)
                            _sleep(cfg.PunchDelay)
                            tries = tries + 1
                        end
                        self:RunAutoCollectRadius4(x, y, 4)
                    end
                end
            end
        end
    end

    self.State.AutoFarm.StatusText = "AUTO_DF // BUILDING LADDERS"
    for _, data in ipairs({ {targetX = 1, standX = 0}, {targetX = 98, standX = 99} }) do
        for targetY = 52, 2, -2 do
            if not self.State.AutoFarm.Active then return end
            checkAndDropAllItems()
            if self:GetItemCount(buildItemID) <= 0 then runHarvest() runPlant() end
            if _checkTile(data.targetX, targetY).fg == 0 and self:SafeMove(data.standX, targetY + 1, cfg.PlaceMoveDelay) then
                _requestTileChange(data.targetX, targetY, buildItemID)
                _sleep(cfg.PlaceDelay)
            end
        end
    end

    self.State.AutoFarm.StatusText = "AUTO_DF // CLEARING GROUND ROWS"
    local direction = 1
    for standY = 23, 51, 2 do
        local targetY = standY + 2
        for _, centerX in ipairs(getSweepCenters(direction)) do
            if not self.State.AutoFarm.Active then return end
            checkAndDropAllItems()
            if self:SafeMove(centerX, standY, cfg.MoveDelay) then
                for dx = -2, 2 do
                    local tx = centerX + dx
                    if tx >= 2 and tx <= 97 then
                        local tries = 0
                        while self.State.AutoFarm.Active and (_checkTile(tx, targetY).fg ~= 0 or _checkTile(tx, targetY).bg ~= 0) and _checkTile(tx, targetY).fg ~= 8 and tries < 10 do
                            _requestTileChange(tx, targetY, 18)
                            _sleep(cfg.PunchDelay)
                            tries = tries + 1
                        end
                    end
                end
                self:RunAutoCollectRadius4(centerX, targetY, 4)
            end
        end
        direction = direction * -1
    end

    self.State.AutoFarm.StatusText = "AUTO_DF // SUSTAINER SKYBUILD"
    while self.State.AutoFarm.Active and self.State.AutoFarm.Mode == "AUTO_DF" do
        if self:GetItemCount(cfg.BlockID) < cfg.MaxBlockPNB then
            local h = runHarvest()
            if self:GetItemCount(cfg.BlockID) < cfg.MaxBlockPNB and h == 0 then
                if runPlant() == 0 then _sleep(5000) end
            end
        end
        if self:GetItemCount(cfg.BlockID) > 0 then
            local dirSky = 1
            local stopBuild = false
            for targetY = 22, 2, -2 do
                if not self.State.AutoFarm.Active or self:GetItemCount(cfg.BlockID) <= 0 then stopBuild = true break end
                for _, centerX in ipairs(getSweepCenters(dirSky)) do
                    if not self.State.AutoFarm.Active or self:GetItemCount(cfg.BlockID) <= 0 then stopBuild = true break end
                    if self:SafeMove(centerX, targetY + 1, cfg.PlaceMoveDelay) then
                        for dx = -2, 2 do
                            local tx = centerX + dx
                            if tx >= 2 and tx <= 97 and _checkTile(tx, targetY).fg == 0 then
                                _requestTileChange(tx, targetY, cfg.BlockID)
                                _sleep(cfg.PlaceDelay)
                            end
                        end
                    end
                end
                dirSky = dirSky * -1
            end
            if not stopBuild then break end
        end
    end

    self:RemoveDropDialogHook()
    self.State.AutoFarm.Active = false
    self.State.AutoFarm.StatusText = "AUTO_DF // FINISHED"
end

-- UNIFIED 1-BUTTON START/STOP CONTROLLER
function C8_FUNC:ToggleAutoFarm(modeOverride, forceState, onStatusChangeCallback)
    if modeOverride then
        self.State.AutoFarm.Mode = tostring(modeOverride):upper()
    end
    if forceState ~= nil then
        self.State.AutoFarm.Active = (forceState == true)
    else
        self.State.AutoFarm.Active = not self.State.AutoFarm.Active
    end

    if not self.State.AutoFarm.Active then
        self:RemoveDropDialogHook()
        self.State.AutoFarm.StatusText = "STOPPED // IDLE"
        if onStatusChangeCallback then onStatusChangeCallback(false, self.State.AutoFarm.StatusText) end
        return false, self.State.AutoFarm.StatusText
    end

    self.State.AutoFarm.StatusText = "ACTIVE // " .. self.State.AutoFarm.Mode .. " (COLLECT RAD:4 ON)"
    if onStatusChangeCallback then onStatusChangeCallback(true, self.State.AutoFarm.StatusText) end

    task.spawn(function()
        while self.State.AutoFarm.Active do
            local mode = self.State.AutoFarm.Mode
            self:RunAutoCollectRadius4()

            if mode == "BASIC" then
                local cfg = self.State.AutoFarm.Basic
                local px, py = self:GetPlayerGridPos()
                local bx = (cfg.SelectPos.X ~= 0) and cfg.SelectPos.X or px
                local by = (cfg.SelectPos.Y ~= 0) and cfg.SelectPos.Y or py
                local coords = {}

                if cfg.Grid6x6 then
                    for dx = -2, 3 do
                        for dy = -2, 3 do
                            if not (dx == 0 and dy == 0) then
                                table.insert(coords, { X = bx + dx, Y = by + dy })
                            end
                        end
                    end
                else
                    table.insert(coords, { X = bx, Y = by - 1 })
                end

                self.State.AutoFarm.StatusText = string.format("BASIC // PLACING (%d TILES)", #coords)
                for _, c in ipairs(coords) do
                    if not self.State.AutoFarm.Active then break end
                    _requestTileChange(c.X, c.Y, cfg.ItemID)
                    self:RunAutoCollectRadius4(c.X, c.Y, 4)
                    _sleep(cfg.SpeedDelay)
                end

                self.State.AutoFarm.StatusText = string.format("BASIC // BREAKING (%d TILES)", #coords)
                for _, c in ipairs(coords) do
                    if not self.State.AutoFarm.Active then break end
                    for _ = 1, 4 do
                        if not self.State.AutoFarm.Active then break end
                        _requestTileChange(c.X, c.Y, 18)
                        self:RunAutoCollectRadius4(c.X, c.Y, 4)
                        _sleep(cfg.SpeedDelay)
                    end
                end

            elseif mode == "PABRIK" then
                local cfg = self.State.AutoFarm.Pabrik
                local px, py = self:GetPlayerGridPos()
                local bx = (cfg.BreakX ~= 0) and cfg.BreakX or px
                local by = (cfg.BreakY ~= 0) and cfg.BreakY or (py - 1)

                self.State.AutoFarm.StatusText = string.format("PABRIK // STATION (%d, %d)", bx, by)
                _findPath(bx, by + 1)
                _requestTileChange(bx, by, math.max(2, cfg.SeedID - 1))
                _sleep(cfg.Delay)
                for _ = 1, 4 do
                    if not self.State.AutoFarm.Active then break end
                    _requestTileChange(bx, by, 18)
                    self:RunAutoCollectRadius4(bx, by, 4)
                    _sleep(cfg.Delay)
                end

                self.State.AutoFarm.StatusText = string.format("PABRIK // SEEDING (%d TILES)", cfg.RadiusOrTotal)
                for offset = 1, math.max(1, cfg.RadiusOrTotal) do
                    if not self.State.AutoFarm.Active then break end
                    _requestTileChange(bx + offset, by, cfg.SeedID)
                    self:RunAutoCollectRadius4(bx + offset, by, 4)
                    _sleep(cfg.Delay)
                end

            elseif mode == "TEIN_PNB" then
                self:ExecuteTeinPNBCycle()

            elseif mode == "LAVA_FARM" then
                self:ExecuteLavaFarmCycle()

            elseif mode == "CLEAR" then
                self:ExecuteClearAndDropCycle()

            elseif mode == "AUTO_DF" then
                self:ExecuteAutoDFBuilder()
            end

            _sleep(50)
        end
        if onStatusChangeCallback then
            onStatusChangeCallback(false, self.State.AutoFarm.StatusText)
        end
    end)

    return true, self.State.AutoFarm.StatusText
end

-- // SPAM CHAT CONTROLLER
function C8_FUNC:ToggleSpamChat(forceState, onStatusChangeCallback)
    if forceState ~= nil then
        self.State.SpamChat.Active = (forceState == true)
    else
        self.State.SpamChat.Active = not self.State.SpamChat.Active
    end

    if not self.State.SpamChat.Active then
        if onStatusChangeCallback then onStatusChangeCallback(false) end
        return false, "STOPPED"
    end

    if onStatusChangeCallback then onStatusChangeCallback(true) end

    task.spawn(function()
        while self.State.SpamChat.Active do
            local cfg = self.State.SpamChat
            local textOut = (cfg.AutoPrefix and cfg.ColorPrefix ~= "") and (cfg.ColorPrefix .. cfg.Message) or cfg.Message

            local sent = _sendPacket(2, "action|input\n|text|" .. textOut)
            if not sent and TextChatService then
                pcall(function()
                    local ch = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if ch then ch:SendAsync(textOut) end
                end)
            end
            _sleep(cfg.Delay)
        end
    end)
    return true, "STARTED"
end

-- // VISUAL SPOOFER CONTROLLER
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
                    if v.ModTitle then
                        desc.TextColor3 = Color3.fromRGB(255, 215, 0)
                    end
                end
            end
        end

        -- Client-side Custom Map GUI Visual Multiplier
        local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui:IsA("ScreenGui") and gui.Name ~= "SYPHUS_R8G_SUITE" then
                    for _, lbl in ipairs(gui:GetDescendants()) do
                        if lbl:IsA("TextLabel") and lbl.Text:find(LocalPlayer.Name, 1, true) then
                            lbl.Text = lbl.Text:gsub(LocalPlayer.Name, finalDisplay)
                        end
                    end
                end
            end
        end
    end
    return finalDisplay
end

-- Initialize Item DB upfront
C8_FUNC:InitItemDatabase()

-- // =========================================================================
-- // PART 2: R-8 (`r8g.lua`) 3-PANE RESPONSIVE INTERACTIVE UI ENGINE
-- // =========================================================================

-- Custom Font Loader (Jersey25-Regular.ttf from GitHub with Enum.Font Fallback)
local CustomFontFace = Font.fromEnum(Enum.Font.RobotoMono)
pcall(function()
    if writefile and getcustomasset and game.HttpGet then
        local fontUrl = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Jersey25-Regular.ttf"
        if not isfile("Jersey25-Regular.ttf") then
            writefile("Jersey25-Regular.ttf", game:HttpGet(fontUrl))
        end
        local fontJson = '{"name":"Jersey25","faces":[{"name":"Regular","weight":400,"style":"normal","assetId":"' .. getcustomasset("Jersey25-Regular.ttf") .. '"}]}'
        writefile("Jersey25.json", fontJson)
        CustomFontFace = Font.new(getcustomasset("Jersey25.json"))
    end
end)

-- R-8 Signature Color Themes
local Themes = {
    ["Blue Night Sky"] = {
        BgPrimary   = Color3.fromRGB(11, 15, 25),
        BgSecondary = Color3.fromRGB(17, 23, 38),
        BgCard      = Color3.fromRGB(23, 31, 50),
        Accent      = Color3.fromRGB(56, 189, 248),
        AccentDim   = Color3.fromRGB(14, 116, 144),
        TextMain    = Color3.fromRGB(241, 245, 249),
        TextMuted   = Color3.fromRGB(148, 163, 184),
        Border      = Color3.fromRGB(38, 52, 79),
        Success     = Color3.fromRGB(34, 197, 94),
        Danger      = Color3.fromRGB(239, 68, 68)
    },
    ["Orange Sand"] = {
        BgPrimary   = Color3.fromRGB(20, 16, 14),
        BgSecondary = Color3.fromRGB(31, 24, 20),
        BgCard      = Color3.fromRGB(43, 33, 27),
        Accent      = Color3.fromRGB(249, 115, 22),
        AccentDim   = Color3.fromRGB(154, 52, 18),
        TextMain    = Color3.fromRGB(255, 247, 237),
        TextMuted   = Color3.fromRGB(180, 154, 135),
        Border      = Color3.fromRGB(68, 50, 39),
        Success     = Color3.fromRGB(34, 197, 94),
        Danger      = Color3.fromRGB(239, 68, 68)
    },
    ["Midnight Monokai"] = {
        BgPrimary   = Color3.fromRGB(18, 18, 22),
        BgSecondary = Color3.fromRGB(27, 27, 34),
        BgCard      = Color3.fromRGB(38, 38, 48),
        Accent      = Color3.fromRGB(168, 85, 247),
        AccentDim   = Color3.fromRGB(107, 33, 168),
        TextMain    = Color3.fromRGB(248, 250, 252),
        TextMuted   = Color3.fromRGB(161, 161, 170),
        Border      = Color3.fromRGB(63, 63, 78),
        Success     = Color3.fromRGB(16, 185, 129),
        Danger      = Color3.fromRGB(244, 63, 94)
    }
}

local CurrentThemeName = "Blue Night Sky"
local ActiveTheme = Themes[CurrentThemeName]
local ThemeListeners = {}

local function BindTheme(instance, prop, themeKey)
    instance[prop] = ActiveTheme[themeKey]
    table.insert(ThemeListeners, { Instance = instance, Prop = prop, Key = themeKey })
end

local function ApplyTheme(themeName)
    if not Themes[themeName] then return end
    CurrentThemeName = themeName
    ActiveTheme = Themes[themeName]
    for _, item in ipairs(ThemeListeners) do
        if item.Instance and item.Instance.Parent then
            TweenService:Create(item.Instance, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                [item.Prop] = ActiveTheme[item.Key]
            }):Play()
        end
    end
end

-- Cleanup Old Instance
local ParentGui = (gethui and gethui()) or (pcall(function() return CoreGui.Name end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
if ParentGui:FindFirstChild("SYPHUS_R8G_SUITE") then
    ParentGui.SYPHUS_R8G_SUITE:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SYPHUS_R8G_SUITE"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

-- Main 2.5D Window Container
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.fromOffset(820, 490)
MainWindow.Position = UDim2.fromScale(0.5, 0.5)
MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
MainWindow.BackgroundTransparency = 0.04
MainWindow.BorderSizePixel = 0
MainWindow.Parent = ScreenGui
BindTheme(MainWindow, "BackgroundColor3", "BgPrimary")

local WinCorner = Instance.new("UICorner", MainWindow)
WinCorner.CornerRadius = UDim.new(0, 10)

local WinStroke = Instance.new("UIStroke", MainWindow)
WinStroke.Thickness = 1.5
BindTheme(WinStroke, "Color", "Border")

-- Responsive Auto-Scaler
local UIScale = Instance.new("UIScale", MainWindow)
local function UpdateResponsiveScale()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local scaleX = (vp.X * 0.92) / 820
    local scaleY = (vp.Y * 0.88) / 490
    UIScale.Scale = math.clamp(math.min(scaleX, scaleY, 1.05), 0.55, 1.05)
end
if Workspace.CurrentCamera then
    Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
    UpdateResponsiveScale()
end

-- Top Header Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainWindow
BindTheme(TopBar, "BackgroundColor3", "BgSecondary")

local TopCorner = Instance.new("UICorner", TopBar)
TopCorner.CornerRadius = UDim.new(0, 10)

local BrandTitle = Instance.new("TextLabel")
BrandTitle.Size = UDim2.new(0.55, 0, 1, 0)
BrandTitle.Position = UDim2.fromOffset(14, 0)
BrandTitle.BackgroundTransparency = 1
BrandTitle.FontFace = CustomFontFace
BrandTitle.Text = "SYPHUS_HUB // R&8_DV  [C&8_FUNC v2.0]"
BrandTitle.TextSize = 18
BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
BrandTitle.Parent = TopBar
BindTheme(BrandTitle, "TextColor3", "Accent")

-- Theme Cycle Button in Header
local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.fromOffset(140, 26)
ThemeBtn.Position = UDim2.new(1, -195, 0.5, -13)
ThemeBtn.FontFace = CustomFontFace
ThemeBtn.Text = "THEME: BLUE NIGHT"
ThemeBtn.TextSize = 13
ThemeBtn.AutoButtonColor = false
ThemeBtn.Parent = TopBar
BindTheme(ThemeBtn, "BackgroundColor3", "BgCard")
BindTheme(ThemeBtn, "TextColor3", "TextMain")
Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 6)
local ThemeBtnStroke = Instance.new("UIStroke", ThemeBtn)
ThemeBtnStroke.Thickness = 1
BindTheme(ThemeBtnStroke, "Color", "Accent")

local themeOrder = { "Blue Night Sky", "Orange Sand", "Midnight Monokai" }
local themeIdx = 1
ThemeBtn.MouseButton1Click:Connect(function()
    themeIdx = (themeIdx % #themeOrder) + 1
    local nextTheme = themeOrder[themeIdx]
    ApplyTheme(nextTheme)
    ThemeBtn.Text = "THEME: " .. nextTheme:upper():sub(1, 12)
end)

-- Minimize / Fold Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(32, 26)
MinBtn.Position = UDim2.new(1, -44, 0.5, -13)
MinBtn.FontFace = CustomFontFace
MinBtn.Text = "—"
MinBtn.TextSize = 15
MinBtn.AutoButtonColor = false
MinBtn.Parent = TopBar
BindTheme(MinBtn, "BackgroundColor3", "BgCard")
BindTheme(MinBtn, "TextColor3", "TextMain")
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Smooth Dragging on TopBar
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- // 3-PANE BODY CONTAINER (25% LEFT | 50% CENTER | 25% RIGHT)
local BodyContainer = Instance.new("Frame")
BodyContainer.Name = "BodyContainer"
BodyContainer.Size = UDim2.new(1, -20, 1, -54)
BodyContainer.Position = UDim2.fromOffset(10, 46)
BodyContainer.BackgroundTransparency = 1
BodyContainer.Parent = MainWindow

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    BodyContainer.Visible = not isMinimized
    TweenService:Create(MainWindow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = isMinimized and UDim2.fromOffset(820, 44) or UDim2.fromOffset(820, 490)
    }):Play()
    MinBtn.Text = isMinimized and "+" or "—"
end)

-- LEFT PANE (25% Width): Navigation Tabs + Quick Status
local LeftPane = Instance.new("Frame")
LeftPane.Name = "LeftPane"
LeftPane.Size = UDim2.new(0.24, -6, 1, 0)
LeftPane.Position = UDim2.fromScale(0, 0)
LeftPane.BorderSizePixel = 0
LeftPane.Parent = BodyContainer
BindTheme(LeftPane, "BackgroundColor3", "BgSecondary")
Instance.new("UICorner", LeftPane).CornerRadius = UDim.new(0, 8)
local LeftStroke = Instance.new("UIStroke", LeftPane)
LeftStroke.Thickness = 1
BindTheme(LeftStroke, "Color", "Border")

-- CENTER PANE (50% Width): Active Interactive Workspace
local CenterPane = Instance.new("Frame")
CenterPane.Name = "CenterPane"
CenterPane.Size = UDim2.new(0.51, -6, 1, 0)
CenterPane.Position = UDim2.new(0.24, 3, 0, 0)
CenterPane.BorderSizePixel = 0
CenterPane.Parent = BodyContainer
BindTheme(CenterPane, "BackgroundColor3", "BgSecondary")
Instance.new("UICorner", CenterPane).CornerRadius = UDim.new(0, 8)
local CenterStroke = Instance.new("UIStroke", CenterPane)
CenterStroke.Thickness = 1
BindTheme(CenterStroke, "Color", "Border")

-- RIGHT PANE (25% Width): Live Telemetry HUD & Item Inspector
local RightPane = Instance.new("Frame")
RightPane.Name = "RightPane"
RightPane.Size = UDim2.new(0.25, -3, 1, 0)
RightPane.Position = UDim2.new(0.75, 3, 0, 0)
RightPane.BorderSizePixel = 0
RightPane.Parent = BodyContainer
BindTheme(RightPane, "BackgroundColor3", "BgSecondary")
Instance.new("UICorner", RightPane).CornerRadius = UDim.new(0, 8)
local RightStroke = Instance.new("UIStroke", RightPane)
RightStroke.Thickness = 1
BindTheme(RightStroke, "Color", "Border")

-- // =========================================================================
-- // PART 3: REUSABLE R-8 INTERACTIVE COMPONENT BUILDERS
-- // =========================================================================

local function CreateSectionHeader(parent, titleText)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.FontFace = CustomFontFace
    lbl.Text = "// " .. tostring(titleText):upper()
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    BindTheme(lbl, "TextColor3", "Accent")
    return lbl
end

local function CreateToggleRow(parent, labelText, defaultState, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 36)
    card.BorderSizePixel = 0
    card.Parent = parent
    BindTheme(card, "BackgroundColor3", "BgCard")
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.68, 0, 1, 0)
    title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1
    title.FontFace = CustomFontFace
    title.Text = labelText
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    BindTheme(title, "TextColor3", "TextMain")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(64, 24)
    btn.Position = UDim2.new(1, -72, 0.5, -12)
    btn.FontFace = CustomFontFace
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = card
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local state = (defaultState == true)
    local function syncVisual()
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and ActiveTheme.Success or ActiveTheme.BgPrimary
        btn.TextColor3 = ActiveTheme.TextMain
    end
    syncVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        syncVisual()
        if callback then callback(state) end
    end)

    return card, function(newState)
        state = (newState == true)
        syncVisual()
    end
end

local function CreateInputRow(parent, labelText, defaultVal, placeholder, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 36)
    card.BorderSizePixel = 0
    card.Parent = parent
    BindTheme(card, "BackgroundColor3", "BgCard")
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.52, 0, 1, 0)
    title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1
    title.FontFace = CustomFontFace
    title.Text = labelText
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    BindTheme(title, "TextColor3", "TextMain")

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.42, 0, 0, 24)
    box.Position = UDim2.new(0.56, 0, 0.5, -12)
    box.FontFace = CustomFontFace
    box.Text = tostring(defaultVal or "")
    box.PlaceholderText = tostring(placeholder or "Input...")
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Parent = card
    BindTheme(box, "BackgroundColor3", "BgPrimary")
    BindTheme(box, "TextColor3", "Accent")
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)

    box.FocusLost:Connect(function()
        if callback then callback(box.Text, box) end
    end)

    return card, box
end

local function CreateSelectorRow(parent, labelText, optionsList, defaultOpt, callback)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 36)
    card.BorderSizePixel = 0
    card.Parent = parent
    BindTheme(card, "BackgroundColor3", "BgCard")
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.48, 0, 1, 0)
    title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1
    title.FontFace = CustomFontFace
    title.Text = labelText
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card
    BindTheme(title, "TextColor3", "TextMain")

    local idx = 1
    for i, v in ipairs(optionsList) do
        if tostring(v):upper() == tostring(defaultOpt):upper() then idx = i break end
    end

    local cycleBtn = Instance.new("TextButton")
    cycleBtn.Size = UDim2.new(0.46, 0, 0, 24)
    cycleBtn.Position = UDim2.new(0.52, 0, 0.5, -12)
    cycleBtn.FontFace = CustomFontFace
    cycleBtn.Text = "< " .. tostring(optionsList[idx]) .. " >"
    cycleBtn.TextSize = 13
    cycleBtn.AutoButtonColor = false
    cycleBtn.Parent = card
    BindTheme(cycleBtn, "BackgroundColor3", "BgPrimary")
    BindTheme(cycleBtn, "TextColor3", "Accent")
    Instance.new("UICorner", cycleBtn).CornerRadius = UDim.new(0, 5)

    cycleBtn.MouseButton1Click:Connect(function()
        idx = (idx % #optionsList) + 1
        local picked = optionsList[idx]
        cycleBtn.Text = "< " .. tostring(picked) .. " >"
        if callback then callback(picked) end
    end)

    return card, cycleBtn
end

local function CreateActionButton(parent, btnText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 36)
    btn.FontFace = CustomFontFace
    btn.Text = btnText
    btn.TextSize = 15
    btn.AutoButtonColor = false
    btn.Parent = parent
    BindTheme(btn, "BackgroundColor3", "AccentDim")
    BindTheme(btn, "TextColor3", "TextMain")
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local st = Instance.new("UIStroke", btn)
    st.Thickness = 1
    BindTheme(st, "Color", "Accent")

    btn.MouseButton1Click:Connect(function()
        if callback then callback(btn) end
    end)
    return btn
end

-- // =========================================================================
-- // PART 4: POPULATING THE 3 PANES (NAVIGATION, PAGES, TELEMETRY HUD)
-- // =========================================================================

-- 1. RIGHT PANE: LIVE TELEMETRY (INFO POSITION SEKARANG) + SELECTED ITEM CARD
local RightLayout = Instance.new("UIListLayout", RightPane)
RightLayout.Padding = UDim.new(0, 6)
RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local RightPad = Instance.new("UIPadding", RightPane)
RightPad.PaddingTop = UDim.new(0, 8)
RightPad.PaddingLeft = UDim.new(0, 6)
RightPad.PaddingRight = UDim.new(0, 6)

CreateSectionHeader(RightPane, "INFO POSITION SEKARANG")

local TelemetryCard = Instance.new("Frame")
TelemetryCard.Size = UDim2.new(1, -4, 0, 142)
TelemetryCard.BorderSizePixel = 0
TelemetryCard.Parent = RightPane
BindTheme(TelemetryCard, "BackgroundColor3", "BgCard")
Instance.new("UICorner", TelemetryCard).CornerRadius = UDim.new(0, 6)

local TeleText = Instance.new("TextLabel")
TeleText.Size = UDim2.new(1, -14, 1, -10)
TeleText.Position = UDim2.fromOffset(8, 5)
TeleText.BackgroundTransparency = 1
TeleText.FontFace = CustomFontFace
TeleText.TextSize = 14
TeleText.TextXAlignment = Enum.TextXAlignment.Left
TeleText.TextYAlignment = Enum.TextYAlignment.Top
TeleText.RichText = true
TeleText.Parent = TelemetryCard
BindTheme(TeleText, "TextColor3", "TextMain")

CreateSectionHeader(RightPane, "ITEM INSPECTOR")

local InspectorCard = Instance.new("Frame")
InspectorCard.Size = UDim2.new(1, -4, 0, 215)
InspectorCard.BorderSizePixel = 0
InspectorCard.Parent = RightPane
BindTheme(InspectorCard, "BackgroundColor3", "BgCard")
Instance.new("UICorner", InspectorCard).CornerRadius = UDim.new(0, 6)

local InspIcon = Instance.new("ImageLabel")
InspIcon.Size = UDim2.fromOffset(42, 42)
InspIcon.Position = UDim2.fromOffset(8, 8)
InspIcon.BackgroundTransparency = 0.2
InspIcon.Image = "rbxassetid://6031075938"
InspIcon.Parent = InspectorCard
BindTheme(InspIcon, "BackgroundColor3", "BgPrimary")
Instance.new("UICorner", InspIcon).CornerRadius = UDim.new(0, 6)

local InspTitle = Instance.new("TextLabel")
InspTitle.Size = UDim2.new(1, -60, 0, 42)
InspTitle.Position = UDim2.fromOffset(56, 8)
InspTitle.BackgroundTransparency = 1
InspTitle.FontFace = CustomFontFace
InspTitle.Text = "Dirt Block [ID: 2]"
InspTitle.TextSize = 15
InspTitle.TextWrapped = true
InspTitle.TextXAlignment = Enum.TextXAlignment.Left
InspTitle.Parent = InspectorCard
BindTheme(InspTitle, "TextColor3", "Accent")

local InspDetails = Instance.new("TextLabel")
InspDetails.Size = UDim2.new(1, -16, 0, 108)
InspDetails.Position = UDim2.fromOffset(8, 54)
InspDetails.BackgroundTransparency = 1
InspDetails.FontFace = CustomFontFace
InspDetails.TextSize = 13
InspDetails.TextWrapped = true
InspDetails.TextXAlignment = Enum.TextXAlignment.Left
InspDetails.TextYAlignment = Enum.TextYAlignment.Top
InspDetails.Parent = InspectorCard
BindTheme(InspDetails, "TextColor3", "TextMuted")

local CopyIDBtn = Instance.new("TextButton")
CopyIDBtn.Size = UDim2.new(0.46, 0, 0, 28)
CopyIDBtn.Position = UDim2.new(0.03, 0, 1, -34)
CopyIDBtn.FontFace = CustomFontFace
CopyIDBtn.Text = "COPY ID"
CopyIDBtn.TextSize = 13
CopyIDBtn.AutoButtonColor = false
CopyIDBtn.Parent = InspectorCard
BindTheme(CopyIDBtn, "BackgroundColor3", "BgPrimary")
BindTheme(CopyIDBtn, "TextColor3", "Accent")
Instance.new("UICorner", CopyIDBtn).CornerRadius = UDim.new(0, 5)

local CopyNameBtn = Instance.new("TextButton")
CopyNameBtn.Size = UDim2.new(0.46, 0, 0, 28)
CopyNameBtn.Position = UDim2.new(0.51, 0, 1, -34)
CopyNameBtn.FontFace = CustomFontFace
CopyNameBtn.Text = "COPY NAME"
CopyNameBtn.TextSize = 13
CopyNameBtn.AutoButtonColor = false
CopyNameBtn.Parent = InspectorCard
BindTheme(CopyNameBtn, "BackgroundColor3", "BgPrimary")
BindTheme(CopyNameBtn, "TextColor3", "TextMain")
Instance.new("UICorner", CopyNameBtn).CornerRadius = UDim.new(0, 5)

local function RefreshInspector(itemObj)
    if not itemObj then return end
    C8_FUNC.State.ItemDB.SelectedItem = itemObj
    InspIcon.Image = itemObj.IconAsset or "rbxassetid://6031075938"
    InspTitle.Text = string.format("%s\n[ID: %d]", itemObj.Name, itemObj.ID)
    InspDetails.Text = string.format(
        "Category: %s\nRarity: %d  |  Hits: %d\nGrowTime: %ds\nInv Count: %d\nDesc: %s",
        tostring(itemObj.Category),
        tonumber(itemObj.Rarity) or 0,
        tonumber(itemObj.Hits) or 0,
        tonumber(itemObj.GrowTime) or 0,
        C8_FUNC:GetItemCount(itemObj.ID),
        tostring(itemObj.Description)
    )
end
RefreshInspector(C8_FUNC.State.ItemDB.Registry[1])

CopyIDBtn.MouseButton1Click:Connect(function()
    local copied = C8_FUNC:CopyItemData(C8_FUNC.State.ItemDB.SelectedItem, "ID")
    CopyIDBtn.Text = "COPIED: " .. tostring(copied)
    task.delay(1, function() CopyIDBtn.Text = "COPY ID" end)
end)

CopyNameBtn.MouseButton1Click:Connect(function()
    local copied = C8_FUNC:CopyItemData(C8_FUNC.State.ItemDB.SelectedItem, "NAME")
    CopyNameBtn.Text = "COPIED!"
    task.delay(1, function() CopyNameBtn.Text = "COPY NAME" end)
end)

-- 2. CENTER PANE TAB PAGES
local TabPages = {}
local function CreateTabPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "_Page"
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.fromOffset(6, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.fromScale(0, 0)
    page.Visible = false
    page.Parent = CenterPane
    BindTheme(page, "ScrollBarImageColor3", "Accent")

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    TabPages[name] = page
    return page
end

local PageMisc     = CreateTabPage("MISC")
local PageItemInfo = CreateTabPage("ITEM INFO")
local PageAutoFarm = CreateTabPage("AUTO FARM")
local PageSpamChat = CreateTabPage("SPAM CHAT")
local PageVisual   = CreateTabPage("VISUAL")

-- 3. LEFT PANE NAVIGATION BUTTONS
local LeftLayout = Instance.new("UIListLayout", LeftPane)
LeftLayout.Padding = UDim.new(0, 6)
LeftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local LeftPad = Instance.new("UIPadding", LeftPane)
LeftPad.PaddingTop = UDim.new(0, 8)
LeftPad.PaddingLeft = UDim.new(0, 6)
LeftPad.PaddingRight = UDim.new(0, 6)

CreateSectionHeader(LeftPane, "R-8 NAVIGATION")

local NavButtons = {}
local function SwitchTab(tabName)
    for name, page in pairs(TabPages) do
        page.Visible = (name == tabName)
    end
    for name, btn in pairs(NavButtons) do
        local isCurrent = (name == tabName)
        btn.BackgroundColor3 = isCurrent and ActiveTheme.AccentDim or ActiveTheme.BgCard
        btn.TextColor3 = isCurrent and ActiveTheme.Accent or ActiveTheme.TextMain
    end
end

local tabOrder = { "AUTO FARM", "MISC", "ITEM INFO", "SPAM CHAT", "VISUAL" }
for _, tName in ipairs(tabOrder) do
    local nBtn = Instance.new("TextButton")
    nBtn.Size = UDim2.new(1, -4, 0, 38)
    nBtn.FontFace = CustomFontFace
    nBtn.Text = "  >  " .. tName
    nBtn.TextSize = 15
    nBtn.TextXAlignment = Enum.TextXAlignment.Left
    nBtn.AutoButtonColor = false
    nBtn.Parent = LeftPane
    BindTheme(nBtn, "BackgroundColor3", "BgCard")
    BindTheme(nBtn, "TextColor3", "TextMain")
    Instance.new("UICorner", nBtn).CornerRadius = UDim.new(0, 6)

    NavButtons[tName] = nBtn
    nBtn.MouseButton1Click:Connect(function()
        SwitchTab(tName)
    end)
end

-- Quick Engine Status Card on Bottom of Left Pane
CreateSectionHeader(LeftPane, "ENGINE STATUS")
local EngineStatusBox = Instance.new("Frame")
EngineStatusBox.Size = UDim2.new(1, -4, 0, 128)
EngineStatusBox.BorderSizePixel = 0
EngineStatusBox.Parent = LeftPane
BindTheme(EngineStatusBox, "BackgroundColor3", "BgCard")
Instance.new("UICorner", EngineStatusBox).CornerRadius = UDim.new(0, 6)

local EngineStatusText = Instance.new("TextLabel")
EngineStatusText.Size = UDim2.new(1, -12, 1, -10)
EngineStatusText.Position = UDim2.fromOffset(6, 5)
EngineStatusText.BackgroundTransparency = 1
EngineStatusText.FontFace = CustomFontFace
EngineStatusText.TextSize = 13
EngineStatusText.TextWrapped = true
EngineStatusText.TextXAlignment = Enum.TextXAlignment.Left
EngineStatusText.TextYAlignment = Enum.TextYAlignment.Top
EngineStatusText.Parent = EngineStatusBox
BindTheme(EngineStatusText, "TextColor3", "TextMuted")

-- // =========================================================================
-- // PART 5: BUILDING EACH FEATURE TAB PAGE IN THE CENTER PANE
-- // =========================================================================

-- ---------------------------------------------------------------------------
-- TAB 1: MISC FEATURES (MODFLY, NOCLIP, FAST ROULETTE, FAST WRENCH, GOD, ETC.)
-- ---------------------------------------------------------------------------
CreateSectionHeader(PageMisc, "MISC CONTROLLER (ON / OFF)")

CreateToggleRow(PageMisc, "MODFLY (GENTA ID 26 / BV)", false, function(st)
    C8_FUNC:SetModFly(st)
end)

CreateToggleRow(PageMisc, "NOCLIP (COLLISION BYPASS)", false, function(st)
    C8_FUNC:SetNoclip(st)
end)

CreateToggleRow(PageMisc, "FAST ROULETTE (INSTANT WHEEL)", false, function(st)
    C8_FUNC:SetFastRoulette(st)
end)

CreateToggleRow(PageMisc, "FAST WRENCH (AUTO POPUP)", false, function(st)
    C8_FUNC:SetFastWrench(st)
end)

CreateSelectorRow(PageMisc, "FAST WRENCH ACTION", { "Pull", "Kick", "Ban" }, "Pull", function(opt)
    C8_FUNC.State.Misc.WrenchMode = opt
end)

CreateToggleRow(PageMisc, "GOD MODE (ANTI-SPIKE / LAVA)", false, function(st)
    C8_FUNC:SetGodMode(st)
end)

CreateToggleRow(PageMisc, "ANTI TAKE ITEM (CHEAT ID 22)", false, function(st)
    C8_FUNC:SetAntiTakeItem(st)
end)

CreateSectionHeader(PageMisc, "PHYSICS & MOVEMENT OVERRIDES")

CreateToggleRow(PageMisc, "SPEED OVERRIDE", false, function(st)
    C8_FUNC:SetSpeed(st)
end)

CreateInputRow(PageMisc, "SPEED VALUE", "36", "36", function(txt)
    local v = tonumber(txt) or 36
    C8_FUNC.State.Misc.SpeedValue = v
    if C8_FUNC.State.Misc.Speed then C8_FUNC:SetSpeed(true, v) end
end)

CreateToggleRow(PageMisc, "HIGH JUMP OVERRIDE", false, function(st)
    C8_FUNC:SetHighJump(st)
end)

CreateInputRow(PageMisc, "JUMP POWER VALUE", "85", "85", function(txt)
    local v = tonumber(txt) or 85
    C8_FUNC.State.Misc.JumpValue = v
    if C8_FUNC.State.Misc.HighJump then C8_FUNC:SetHighJump(true, v) end
end)

CreateToggleRow(PageMisc, "ANTIGRAVITY (LOW GRAV)", false, function(st)
    C8_FUNC:SetAntiGravity(st)
end)

-- ---------------------------------------------------------------------------
-- TAB 2: ITEM INFO (SEARCH BAR, ALL ITEM CARDS, COMPLETE INFO, COPY ID/NAME)
-- ---------------------------------------------------------------------------
CreateSectionHeader(PageItemInfo, "ITEM DATABASE & ASSET EXPLORER")

local SearchBarFrame, SearchBox = CreateInputRow(PageItemInfo, "SEARCH ITEM (NAME / ID)", "", "Type name or ID...")

local CardsContainer = Instance.new("Frame")
CardsContainer.Size = UDim2.new(1, -8, 0, 340)
CardsContainer.BackgroundTransparency = 1
CardsContainer.Parent = PageItemInfo

local CardsGrid = Instance.new("UIGridLayout", CardsContainer)
CardsGrid.CellSize = UDim2.new(0.48, 0, 0, 64)
CardsGrid.CellPadding = UDim2.fromOffset(6, 6)

local function RebuildItemCards(itemsList)
    for _, child in ipairs(CardsContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    for _, item in ipairs(itemsList) do
        local cardBtn = Instance.new("TextButton")
        cardBtn.Text = ""
        cardBtn.AutoButtonColor = false
        cardBtn.Parent = CardsContainer
        BindTheme(cardBtn, "BackgroundColor3", "BgCard")
        Instance.new("UICorner", cardBtn).CornerRadius = UDim.new(0, 6)

        local cStroke = Instance.new("UIStroke", cardBtn)
        cStroke.Thickness = 1
        BindTheme(cStroke, "Color", "Border")

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.fromOffset(36, 36)
        icon.Position = UDim2.fromOffset(6, 6)
        icon.BackgroundTransparency = 0.2
        icon.Image = item.IconAsset or "rbxassetid://6031075938"
        icon.Parent = cardBtn
        BindTheme(icon, "BackgroundColor3", "BgPrimary")
        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 5)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -50, 0, 22)
        nameLbl.Position = UDim2.fromOffset(46, 4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.FontFace = CustomFontFace
        nameLbl.Text = item.Name
        nameLbl.TextSize = 14
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Parent = cardBtn
        BindTheme(nameLbl, "TextColor3", "TextMain")

        local metaLbl = Instance.new("TextLabel")
        metaLbl.Size = UDim2.new(1, -50, 0, 18)
        metaLbl.Position = UDim2.fromOffset(46, 24)
        metaLbl.BackgroundTransparency = 1
        metaLbl.FontFace = CustomFontFace
        metaLbl.Text = string.format("ID: %d | Hits: %d | R:%d", item.ID, item.Hits, item.Rarity)
        metaLbl.TextSize = 12
        metaLbl.TextXAlignment = Enum.TextXAlignment.Left
        metaLbl.Parent = cardBtn
        BindTheme(metaLbl, "TextColor3", "Accent")

        local quickCopy = Instance.new("TextLabel")
        quickCopy.Size = UDim2.new(1, -12, 0, 16)
        quickCopy.Position = UDim2.fromOffset(6, 44)
        quickCopy.BackgroundTransparency = 1
        quickCopy.FontFace = CustomFontFace
        quickCopy.Text = "CLICK TO INSPECT & COPY ID/NAME"
        quickCopy.TextSize = 11
        quickCopy.TextXAlignment = Enum.TextXAlignment.Left
        quickCopy.Parent = cardBtn
        BindTheme(quickCopy, "TextColor3", "TextMuted")

        cardBtn.MouseButton1Click:Connect(function()
            RefreshInspector(item)
            C8_FUNC:CopyItemData(item, "ID")
            quickCopy.Text = "COPIED ID: " .. tostring(item.ID) .. " (SEE RIGHT PANE)"
            task.delay(1.2, function()
                if quickCopy and quickCopy.Parent then
                    quickCopy.Text = "CLICK TO INSPECT & COPY ID/NAME"
                end
            end)
        end)
    end

    local rows = math.ceil(#itemsList / 2)
    CardsContainer.Size = UDim2.new(1, -8, 0, math.max(70, rows * 72))
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local filtered = C8_FUNC:SearchItems(SearchBox.Text)
    RebuildItemCards(filtered)
end)
RebuildItemCards(C8_FUNC.State.ItemDB.Registry)

-- ---------------------------------------------------------------------------
-- TAB 3: AUTO FARM (RADIUS 4 ALWAYS ON + DYNAMIC MODE INPUT PANELS + 1-BUTTON)
-- ---------------------------------------------------------------------------
CreateSectionHeader(PageAutoFarm, "AUTO FARM ENGINE (COLLECT RAD 4 ALWAYS ON)")

-- Single Unified Start/Stop Button (Top of Auto Farm so user never gets confused)
local UnifiedFarmBtn = Instance.new("TextButton")
UnifiedFarmBtn.Size = UDim2.new(1, -8, 0, 42)
UnifiedFarmBtn.FontFace = CustomFontFace
UnifiedFarmBtn.Text = "START AUTO FARM [MODE: BASIC]"
UnifiedFarmBtn.TextSize = 16
UnifiedFarmBtn.AutoButtonColor = false
UnifiedFarmBtn.Parent = PageAutoFarm
UnifiedFarmBtn.BackgroundColor3 = ActiveTheme.Success
UnifiedFarmBtn.TextColor3 = ActiveTheme.TextMain
Instance.new("UICorner", UnifiedFarmBtn).CornerRadius = UDim.new(0, 6)

local function SyncUnifiedFarmButton(isActive)
    local mode = C8_FUNC.State.AutoFarm.Mode
    if isActive then
        UnifiedFarmBtn.Text = "STOP AUTO FARM [RUNNING: " .. mode .. "]"
        UnifiedFarmBtn.BackgroundColor3 = ActiveTheme.Danger
    else
        UnifiedFarmBtn.Text = "START AUTO FARM [MODE: " .. mode .. "]"
        UnifiedFarmBtn.BackgroundColor3 = ActiveTheme.Success
    end
end

-- Sub-mode Containers (Different Mode = Different Input Panel)
local ModePanels = {}
local function CreateModeSubPanel(modeKey)
    local container = Instance.new("Frame")
    container.Name = modeKey .. "_SubPanel"
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.Visible = false
    container.Parent = PageAutoFarm

    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    ModePanels[modeKey] = container
    return container
end

local PanelBasic    = CreateModeSubPanel("BASIC")
local PanelPabrik   = CreateModeSubPanel("PABRIK")
local PanelClear    = CreateModeSubPanel("CLEAR")
local PanelTeinPNB  = CreateModeSubPanel("TEIN_PNB")
local PanelLavaFarm = CreateModeSubPanel("LAVA_FARM")
local PanelAutoDF   = CreateModeSubPanel("AUTO_DF")

local function SwitchFarmModePanel(selectedMode)
    C8_FUNC.State.AutoFarm.Mode = selectedMode
    for k, panel in pairs(ModePanels) do
        panel.Visible = (k == selectedMode)
    end
    SyncUnifiedFarmButton(C8_FUNC.State.AutoFarm.Active)
end

CreateSelectorRow(
    PageAutoFarm,
    "SELECT FARM MODE",
    { "BASIC", "PABRIK", "CLEAR", "TEIN_PNB", "LAVA_FARM", "AUTO_DF" },
    "BASIC",
    function(pickedMode)
        SwitchFarmModePanel(pickedMode)
    end
)

UnifiedFarmBtn.MouseButton1Click:Connect(function()
    C8_FUNC:ToggleAutoFarm(C8_FUNC.State.AutoFarm.Mode, nil, function(activeState)
        SyncUnifiedFarmButton(activeState)
    end)
end)

-- [MODE 1: BASIC INPUTS]
CreateSectionHeader(PanelBasic, "MODE 1: BASIC PNB & 6X6 GRID CONFIG")
CreateInputRow(PanelBasic, "ID ITEM INPUT", "2", "Block/Seed ID", function(txt)
    C8_FUNC.State.AutoFarm.Basic.ItemID = tonumber(txt) or 2
end)
CreateToggleRow(PanelBasic, "HIDE / NO HAND BREAK PLACE", false, function(st)
    C8_FUNC.State.AutoFarm.Basic.NoHand = st
end)
CreateInputRow(PanelBasic, "SPEED SETTING (MS DELAY)", "160", "160", function(txt)
    C8_FUNC.State.AutoFarm.Basic.SpeedDelay = tonumber(txt) or 160
end)
CreateToggleRow(PanelBasic, "GRID PLACE 6X6 AROUND POS", false, function(st)
    C8_FUNC.State.AutoFarm.Basic.Grid6x6 = st
end)
local BasicPosBtn = CreateActionButton(PanelBasic, "SELECT POS (CAPTURE CURRENT X, Y)", function(btn)
    local px, py = C8_FUNC:GetPlayerGridPos()
    C8_FUNC.State.AutoFarm.Basic.SelectPos = { X = px, Y = py }
    btn.Text = string.format("SELECTED POS LOCKED: (%d, %d)", px, py)
end)

-- [MODE 2: PABRIK INPUTS]
CreateSectionHeader(PanelPabrik, "MODE 2: PABRIK STATION CONFIG")
local _, PabXBox = CreateInputRow(PanelPabrik, "X INPUT POSISI BREAK", "0", "0 = Current X", function(txt)
    C8_FUNC.State.AutoFarm.Pabrik.BreakX = tonumber(txt) or 0
end)
local _, PabYBox = CreateInputRow(PanelPabrik, "Y INPUT POSISI BREAK", "0", "0 = Current Y", function(txt)
    C8_FUNC.State.AutoFarm.Pabrik.BreakY = tonumber(txt) or 0
end)
CreateActionButton(PanelPabrik, "CAPTURE CURRENT X, Y FOR PABRIK", function()
    local px, py = C8_FUNC:GetPlayerGridPos()
    C8_FUNC.State.AutoFarm.Pabrik.BreakX = px
    C8_FUNC.State.AutoFarm.Pabrik.BreakY = py
    PabXBox.Text = tostring(px)
    PabYBox.Text = tostring(py)
end)
CreateInputRow(PanelPabrik, "ID SEED", "3", "Seed ID (e.g. 3)", function(txt)
    C8_FUNC.State.AutoFarm.Pabrik.SeedID = tonumber(txt) or 3
end)
CreateInputRow(PanelPabrik, "RADIUS OR TOTAL SEED PLACE", "6", "Total tiles", function(txt)
    C8_FUNC.State.AutoFarm.Pabrik.RadiusOrTotal = tonumber(txt) or 6
end)

-- [MODE 3: CLEAR + AUTO DROP (KUROTSUME) INPUTS]
CreateSectionHeader(PanelClear, "MODE 3: AUTOMATIC CLEAR + STORAGE DROP")
CreateInputRow(PanelClear, "WORLDS LIST (COMMA SEP)", "world1,world2", "world1,world2", function(txt)
    C8_FUNC.State.AutoFarm.Clear.WorldsListString = txt
end)
CreateInputRow(PanelClear, "DROP STORAGE WORLD", "dropworld/storageworld", "World|DoorID", function(txt)
    C8_FUNC.State.AutoFarm.Clear.DropWorld = txt
end)
CreateInputRow(PanelClear, "DROP X COORDINATE", "9", "9", function(txt)
    C8_FUNC.State.AutoFarm.Clear.DropX = tonumber(txt) or 9
end)
CreateInputRow(PanelClear, "DROP Y COORDINATE", "18", "18", function(txt)
    C8_FUNC.State.AutoFarm.Clear.DropY = tonumber(txt) or 18
end)
CreateInputRow(PanelClear, "TRIGGER DROP AMOUNT", "100", "100", function(txt)
    C8_FUNC.State.AutoFarm.Clear.DropAmount = tonumber(txt) or 100
end)
CreateInputRow(PanelClear, "TARGET BG ID (14=CAVE, 0=ALL)", "14", "14", function(txt)
    C8_FUNC.State.AutoFarm.Clear.TargetBG = tonumber(txt) or 14
end)

-- [MODE 4: TEIN PNB INPUTS]
CreateSectionHeader(PanelTeinPNB, "MODE 4: TEIN FACING-DIRECTION PNB")
CreateInputRow(PanelTeinPNB, "BLOCK ID (DEFAULT 340)", "340", "340", function(txt)
    C8_FUNC.State.AutoFarm.TeinPNB.BlockID = tonumber(txt) or 340
end)
CreateInputRow(PanelTeinPNB, "RANGE BLOCK (TILES AHEAD)", "5", "5", function(txt)
    C8_FUNC.State.AutoFarm.TeinPNB.RangeBlock = tonumber(txt) or 5
end)
CreateInputRow(PanelTeinPNB, "PUNCH HIT COUNT", "1", "1", function(txt)
    C8_FUNC.State.AutoFarm.TeinPNB.HitCount = tonumber(txt) or 1
end)
CreateInputRow(PanelTeinPNB, "PLACE DELAY (MS)", "100", "100", function(txt)
    C8_FUNC.State.AutoFarm.TeinPNB.PlaceDelay = tonumber(txt) or 100
end)
CreateInputRow(PanelTeinPNB, "BREAK DELAY (MS)", "100", "100", function(txt)
    C8_FUNC.State.AutoFarm.TeinPNB.BreakDelay = tonumber(txt) or 100
end)

-- [MODE 5: RYO LAVA FARM INPUTS]
CreateSectionHeader(PanelLavaFarm, "MODE 5: RYO LAVA FARM (PNB+PLANT+HARVEST)")
CreateInputRow(PanelLavaFarm, "FARM WORLD (WORLD|ID)", "LAVAFARM|A1", "LAVAFARM|A1", function(txt)
    C8_FUNC.State.AutoFarm.LavaFarm.FarmWorld = txt
end)
CreateInputRow(PanelLavaFarm, "DROP SEED WORLD (WORLD|ID)", "LAVADROP|B2", "LAVADROP|B2", function(txt)
    C8_FUNC.State.AutoFarm.LavaFarm.DropWorld = txt
end)
CreateInputRow(PanelLavaFarm, "BLOCK ID (LAVA=4)", "4", "4", function(txt)
    C8_FUNC.State.AutoFarm.LavaFarm.BlockID = tonumber(txt) or 4
end)
CreateInputRow(PanelLavaFarm, "SEED ID (LAVA SEED=5)", "5", "5", function(txt)
    C8_FUNC.State.AutoFarm.LavaFarm.SeedID = tonumber(txt) or 5
end)
CreateSelectorRow(PanelLavaFarm, "SPREAD TILES (1 / 3 / 5)", { "1", "3", "5" }, "5", function(opt)
    C8_FUNC.State.AutoFarm.LavaFarm.SpreadCount = tonumber(opt) or 5
end)
CreateSelectorRow(PanelLavaFarm, "PUNCH DIRECTION", { "up", "down" }, "up", function(opt)
    C8_FUNC.State.AutoFarm.LavaFarm.Direction = opt
end)
CreateInputRow(PanelLavaFarm, "SEED DROP LIMIT", "200", "200", function(txt)
    C8_FUNC.State.AutoFarm.LavaFarm.DropLimit = tonumber(txt) or 200
end)
CreateInputRow(PanelLavaFarm, "KEEP SEED AMOUNT", "100", "100", function(txt)
    C8_FUNC.State.AutoFarm.LavaFarm.KeepSeed = tonumber(txt) or 100
end)

-- [MODE 6: OPTIMIZED AUTO-DF BUILDER & SUSTAINER INPUTS]
CreateSectionHeader(PanelAutoDF, "MODE 6: OPTIMIZED AUTO-DF BUILDER & SUSTAINER")
CreateInputRow(PanelAutoDF, "TARGET DF WORLD", "NTUUM", "NTUUM", function(txt)
    C8_FUNC.State.AutoFarm.AutoDF.TargetWorld = txt
end)
CreateInputRow(PanelAutoDF, "STORAGE DROP WORLD", "KUALISTORAGE", "KUALISTORAGE", function(txt)
    C8_FUNC.State.AutoFarm.AutoDF.DropWorld = txt
end)
CreateInputRow(PanelAutoDF, "STORAGE DROP X", "83", "83", function(txt)
    C8_FUNC.State.AutoFarm.AutoDF.DropX = tonumber(txt) or 83
end)
CreateInputRow(PanelAutoDF, "STORAGE DROP Y", "23", "23", function(txt)
    C8_FUNC.State.AutoFarm.AutoDF.DropY = tonumber(txt) or 23
end)
CreateToggleRow(PanelAutoDF, "USE SIGNAL JAMMER (ID 226)", false, function(st)
    C8_FUNC.State.AutoFarm.AutoDF.UseJammer = st
end)
CreateToggleRow(PanelAutoDF, "USE WOODEN PLATFORM (ID 102)", true, function(st)
    C8_FUNC.State.AutoFarm.AutoDF.UsePlatform = st
end)

SwitchFarmModePanel("BASIC")

-- ---------------------------------------------------------------------------
-- TAB 4: SPAM CHAT (MESSAGE, AUTO PREFIX/COLOR SELECTOR, DELAY, 1-BUTTON)
-- ---------------------------------------------------------------------------
CreateSectionHeader(PageSpamChat, "SPAM CHAT BROADCASTER")

local UnifiedSpamBtn = Instance.new("TextButton")
UnifiedSpamBtn.Size = UDim2.new(1, -8, 0, 42)
UnifiedSpamBtn.FontFace = CustomFontFace
UnifiedSpamBtn.Text = "START SPAM CHAT"
UnifiedSpamBtn.TextSize = 16
UnifiedSpamBtn.AutoButtonColor = false
UnifiedSpamBtn.Parent = PageSpamChat
UnifiedSpamBtn.BackgroundColor3 = ActiveTheme.Success
UnifiedSpamBtn.TextColor3 = ActiveTheme.TextMain
Instance.new("UICorner", UnifiedSpamBtn).CornerRadius = UDim.new(0, 6)

UnifiedSpamBtn.MouseButton1Click:Connect(function()
    C8_FUNC:ToggleSpamChat(nil, function(isRunning)
        UnifiedSpamBtn.Text = isRunning and "STOP SPAM CHAT [BROADCASTING]" or "START SPAM CHAT"
        UnifiedSpamBtn.BackgroundColor3 = isRunning and ActiveTheme.Danger or ActiveTheme.Success
    end)
end)

CreateInputRow(PageSpamChat, "INPUT TEXT MESSAGE", C8_FUNC.State.SpamChat.Message, "Enter spam text...", function(txt)
    C8_FUNC.State.SpamChat.Message = txt
end)

CreateToggleRow(PageSpamChat, "AUTO PREFIX / COLOR PRIORITY", true, function(st)
    C8_FUNC.State.SpamChat.AutoPrefix = st
end)

CreateSelectorRow(
    PageSpamChat,
    "SELECT COLOR / PREFIX TAG",
    { "`2 (Green)", "`4 (Red)", "`9 (Yellow)", "`b (Cyan)", "`# (Pink)", "[SYPHUS] " },
    "`2 (Green)",
    function(picked)
        local code = picked:match("^([^%s]+)") or "`2"
        C8_FUNC.State.SpamChat.ColorPrefix = (code == "[SYPHUS]") and "[SYPHUS] " or code
    end
)

CreateInputRow(PageSpamChat, "DELAY SETUP (MS)", "4000", "4000 (4 Seconds)", function(txt)
    C8_FUNC.State.SpamChat.Delay = math.clamp(tonumber(txt) or 4000, 500, 60000)
end)

-- ---------------------------------------------------------------------------
-- TAB 5: VISUAL SPOOFER (SET NAME, SET MOD, CLIENT MAP GUI VISUALS)
-- ---------------------------------------------------------------------------
CreateSectionHeader(PageVisual, "CLIENT-SIDE VISUAL IDENTITY SPOOFER")

CreateInputRow(PageVisual, "SET CUSTOM NAME", "", "Enter spoofed name...", function(txt)
    C8_FUNC.State.Visual.CustomName = txt
    C8_FUNC:ApplyVisualSpoof()
end)

CreateToggleRow(PageVisual, "SET MODERATOR (@Moderator Gold)", false, function(st)
    C8_FUNC.State.Visual.ModTitle = st
    C8_FUNC:ApplyVisualSpoof()
end)

CreateSelectorRow(
    PageVisual,
    "MAP CUSTOM GUI VISUAL PRESET",
    { "Default", "Developer [`6@Dev]", "VIP [`9@VIP]", "Guardian [`b@Guard]" },
    "Default",
    function(preset)
        C8_FUNC.State.Visual.RolePreset = preset
        if preset:find("@Dev") then
            C8_FUNC.State.Visual.CustomName = "`6@Dev_" .. (LocalPlayer and LocalPlayer.Name or "R8")
        elseif preset:find("@VIP") then
            C8_FUNC.State.Visual.CustomName = "`9[VIP] " .. (LocalPlayer and LocalPlayer.Name or "R8")
        elseif preset:find("@Guard") then
            C8_FUNC.State.Visual.CustomName = "`b[GUARD] " .. (LocalPlayer and LocalPlayer.Name or "R8")
        end
        C8_FUNC:ApplyVisualSpoof()
    end
)

CreateActionButton(PageVisual, "FORCE REFRESH LOCAL MAP GUI VISUALS", function(btn)
    local res = C8_FUNC:ApplyVisualSpoof()
    btn.Text = "APPLIED: " .. tostring(res)
    task.delay(1.2, function()
        btn.Text = "FORCE REFRESH LOCAL MAP GUI VISUALS"
    end)
end)

-- Default Open Tab
SwitchTab("AUTO FARM")

-- // =========================================================================
-- // PART 6: REAL-TIME TELEMETRY HEARTBEAT LOOP & KEYBIND (RIGHT-SHIFT)
-- // =========================================================================

RunService.Heartbeat:Connect(function()
    local info = C8_FUNC:GetPositionInfo()
    TeleText.Text = string.format(
        "<b>X :</b> %d    |    <b>Y :</b> %d\n<b>FACING :</b> %s\n<b>NAMA PLAYER :</b> %s\n<b>TOTAL PLAYER :</b> %d\n<b>NAMA WORLD :</b> %s",
        info.X,
        info.Y,
        info.FacingLeft and "LEFT (-1)" or "RIGHT (+1)",
        tostring(info.PlayerName),
        info.TotalPlayers,
        tostring(info.WorldName)
    )

    EngineStatusText.Text = string.format(
        "FARM: %s\nMODE: %s\nCOLLECT: RAD %d (LOCKED)\nSPAM: %s\nMODFLY: %s\nSTATUS: %s",
        C8_FUNC.State.AutoFarm.Active and "RUNNING" or "STOPPED",
        C8_FUNC.State.AutoFarm.Mode,
        C8_FUNC.State.AutoFarm.CollectRadius,
        C8_FUNC.State.SpamChat.Active and "ON" or "OFF",
        C8_FUNC.State.Misc.ModFly and "ON" or "OFF",
        C8_FUNC.State.AutoFarm.StatusText
    )
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        MainWindow.Visible = not MainWindow.Visible
    end
end)

if getgenv then getgenv().C8_FUNC = C8_FUNC end
_G.C8_FUNC = C8_FUNC

return C8_FUNC