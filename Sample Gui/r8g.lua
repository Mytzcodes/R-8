--[[
    =====================================================================================
    R&8_DV IMGUI SUITE — ALL-IN-ONE CUSTOM EDITION (v5.4 Canvas Architecture)
    Reference : https://github.com/Mytzcodes/R-8/tree/main (SampleGui.lua 0/1 Architecture)
    Layout    : 3-Panel Responsive Canvas (Left Sidebar, Center Controls, Contextual Right Panel)
    Features  :
      1. FITUR MISC        : ON/OFF ModFly, NoClip, Fast Roulette, Fast Wrench, God Mode,
                             Speed, High Jump, AntiGravity + Live Info Position Sekarang
                             (X : Y, Nama Player, Total Player, Nama World)
      2. FITUR ITEM INFO   : Search Bar, Card All Item List, Complete Information Inspector,
                             Copy ID / Copy Name / Copy Seed ID, & Visual Asset Icon Renderer
      3. FITUR AUTO FARM   : Auto Collect ALWAYS ON (Radius 4) when Auto Farm is active
                             3 Dynamic Modes (Beda Pilih Beda Input):
                               - Mode 1: BASIC (ID Item Input, Hide/No Hand Break Place,
                                         Speed Setting, Grid Place 6x6 Select Pos, 1-Button Start/Stop)
                               - Mode 2: PABRIK (X, Y Input Posisi Break, ID Seed,
                                         Radius or Total Seed Place, 1-Button Start/Stop)
                               - Mode 3: CLEAR (Automatic Break All 1-Button Start/Stop)
      4. FITUR SPAM CHAT   : Input Text Message, Selector Auto Prefix Priority / Select Color,
                             Delay Setup, 1-Button Start/Stop + Live Preview & Log
      5. UI SETTINGS       : Full R&8_DV Theme Swatches, 0/1 Switch Style, Scale & Hotkey
    =====================================================================================
]]

-- 1. Panggil Framework R&8_DV via GitHub RAW (Mendukung semua Executor PC & Mobile)
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"
local okFetch, rawScript = pcall(function()
    return game:HttpGet(GITHUB_RAW_URL)
end)
if not okFetch or type(rawScript) ~= "string" or #rawScript < 128 or string.sub(rawScript, 1, 4) == "404:" then
    okFetch, rawScript = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r8_dv.lua")
    end)
end
assert(okFetch and type(rawScript) == "string" and #rawScript > 128, "[R&8_DV] HTTP 404: Pastikan file r&8_dv.lua tersedia di repositori GitHub.")

-- Ekspos instance Frame/Container pada CreateCanvasBuilder agar mode dinamis & kartu kustom bekerja mulus
rawScript = string.gsub(
    rawScript,
    "local Builder = {}",
    "local Builder = { Frame = scrollingPage, Container = scrollingPage }",
    1
)

local ImGui = loadstring(rawScript)()

-- =====================================================================
-- SERVICES & EXECUTOR HELPERS
-- =====================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = nil
pcall(function() TextChatService = game:GetService("TextChatService") end)

local LocalPlayer = Players.LocalPlayer

local function CopyToClipboard(text)
    local str = tostring(text or "")
    local clipFn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if clipFn then
        pcall(clipFn, str)
        return true
    end
    return false
end

-- =====================================================================
-- 2. INISIALISASI JENDELA R&8_DV (3-PANEL CANVAS LAYOUT)
-- =====================================================================
local UI = ImGui({
    Title = "R&8_DV - ALL IN ONE SUITE",
    BrandTitle = "R&8_DV",               -- Judul utama solid & tegas di bawah logo sidebar
    BrandSubtitle = "CUSTOM SUITE",       -- Sub-judul di bawah logo sidebar
    Theme = "Minimalist Monochrome",      -- "Minimalist Monochrome" | "Blue Night Sky" | "Violet Amethyst" | "Orange Sand" | "Midnight Monokai"
    CheckBoxStyle = "Modern",             -- "Modern" (Pill Switch 0/1) | "Checkbox" (Checklist Kotak)
    LetterSpacing = 1,                    -- Spasi antar huruf header & judul (0 - 3)
    AutoLoading = false                   -- Buka instan 0ms tanpa delay
}).Call(3)

local feature = UI.feature
local function center(fn) return fn end
local function right(fn) return fn end

local ThemeChoices = UI.GetThemes and UI.GetThemes() or {
    "Minimalist Monochrome",
    "Blue Night Sky",
    "Violet Amethyst",
    "Orange Sand",
    "Midnight Monokai"
}

-- =====================================================================
-- GLOBAL STATE & RUNTIME VARIABLES
-- =====================================================================
local State = {
    -- Misc States
    ModFly = false,
    NoClip = false,
    FastRoulette = false,
    FastWrench = false,
    WrenchMode = "Pull",
    GodMode = false,
    SpeedOn = false,
    SpeedVal = 60,
    HighJumpOn = false,
    JumpVal = 120,
    AntiGravity = false,
    DefaultGravity = workspace.Gravity or 196.2,

    -- Live Position & World Info
    PosX = 0,
    PosY = 0,
    PlayerName = LocalPlayer and LocalPlayer.Name or "LocalPlayer",
    TotalPlayers = #Players:GetPlayers(),
    WorldName = "START",

    -- Auto Farm States
    AutoFarmMode = "1. BASIC",
    AutoCollectAlwaysOn = false,
    AutoCollectRadius = 4, -- Dikunci pada Radius 4 saat Auto Farm aktif
    CollectedCount = 0,

    -- Mode 1: Basic
    BasicRunning = false,
    BasicItemID = "4584",
    BasicHideHand = true,
    BasicSpeedMs = 160,
    BasicHits = 4,
    BasicCycles = 0,

    -- Mode 2: Pabrik
    PabrikRunning = false,
    PabrikBreakX = "50",
    PabrikBreakY = "23",
    PabrikSeedID = "4585",
    PabrikScopeMode = "Radius (Tiles)",
    PabrikRadiusOrTotal = 4,
    PabrikCycles = 0,

    -- Mode 3: Clear
    ClearRunning = false,
    ClearLayerMode = "All Blocks (FG + BG)",
    ClearSkipBedrock = true,
    ClearDelayMs = 140,
    ClearedCount = 0,

    -- Spam Chat States
    SpamRunning = false,
    SpamMessage = "SELL ALL ITEMS CHEAP! VISIT MY WORLD NOW!",
    SpamAutoPrefix = true,
    SpamColorChoice = "`2 Green (Priority)",
    SpamChannelPrefix = "Normal Chat",
    SpamDelayMs = 4500,
    SpamSentCount = 0,
    LastSpamPreview = "`2SELL ALL ITEMS CHEAP! VISIT MY WORLD NOW!"
}

-- =====================================================================
-- HELPER UI: 1-BUTTON START / STOP UNIFIED CONTROLLER & CARD HELPERS
-- =====================================================================
-- Mengambil Frame anak terakhir yang dibuat pada container (untuk manipulasi tombol/card secara langsung)
local function GetLastElement(builderOrContainer)
    local container = (type(builderOrContainer) == "table" and (builderOrContainer.Container or builderOrContainer.Frame)) or builderOrContainer
    if typeof(container) == "Instance" then
        local children = container:GetChildren()
        for i = #children, 1, -1 do
            local ch = children[i]
            if ch:IsA("GuiObject") then
                return ch
            end
        end
    end
    return nil
end

-- Membuat Tombol Start & Stop Jadi Satu (0 = OFF / START, 1 = ON / STOP)
local function CreateUnifiedStartStopButton(cardBuilder, startText, stopText, iconName, onStateChanged)
    local isRunning = false
    local btnTitleLbl = nil
    local btnBadgeLbl = nil
    local btnBadgeFrame = nil

    local function UpdateVisuals()
        if btnTitleLbl then
            btnTitleLbl.Text = isRunning and stopText or startText
        end
        if btnBadgeLbl then
            btnBadgeLbl.Text = isRunning and "ON [1]" or "OFF [0]"
        end
        if btnBadgeFrame then
            btnBadgeFrame.BackgroundColor3 = isRunning and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
        end
        if btnBadgeLbl then
            btnBadgeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end

    cardBuilder:Button(startText, "OFF [0]", iconName or "Bolt", function()
        isRunning = not isRunning
        UpdateVisuals()
        if onStateChanged then
            task.spawn(onStateChanged, isRunning)
        end
    end)

    local btnInstance = GetLastElement(cardBuilder)
    if btnInstance then
        for _, desc in ipairs(btnInstance:GetDescendants()) do
            if desc:IsA("TextLabel") then
                if desc.Text == startText then
                    btnTitleLbl = desc
                elseif desc.Text == "OFF [0]" then
                    btnBadgeLbl = desc
                    btnBadgeFrame = desc.Parent
                end
            end
        end
        UpdateVisuals()
    end

    return {
        SetState = function(newState, silent)
            if isRunning == newState then return end
            isRunning = newState
            UpdateVisuals()
            if not silent and onStateChanged then
                task.spawn(onStateChanged, isRunning)
            end
        end,
        GetState = function()
            return isRunning
        end,
        Instance = btnInstance
    }
end

-- Helper membaca Posisi Tile (X, Y) dan Nama World saat ini
local function ReadLiveWorldAndPosition()
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if root then
        -- Jika game berbasis tile 32-studs atau koordinat langsung, tampilkan koordinat bulat yang presisi
        local rawX, rawY = root.Position.X, root.Position.Y
        State.PosX = math.floor(rawX + 0.5)
        State.PosY = math.floor(rawY + 0.5)
    end

    State.PlayerName = (lp and (lp.DisplayName ~= lp.Name and (lp.DisplayName .. " (@" .. lp.Name .. ")") or lp.Name)) or "LocalPlayer"
    State.TotalPlayers = #Players:GetPlayers()

    local detectedWorld = nil
    pcall(function()
        if workspace:GetAttribute("WorldName") then
            detectedWorld = tostring(workspace:GetAttribute("WorldName"))
        elseif workspace:FindFirstChild("WorldName") and workspace.WorldName:IsA("ValueBase") then
            detectedWorld = tostring(workspace.WorldName.Value)
        elseif ReplicatedStorage:FindFirstChild("WorldName") and ReplicatedStorage.WorldName:IsA("ValueBase") then
            detectedWorld = tostring(ReplicatedStorage.WorldName.Value)
        end
    end)
    if not detectedWorld or detectedWorld == "" then
        detectedWorld = (game.Name and game.Name ~= "" and game.Name ~= "Game") and game.Name or ("WORLD_" .. tostring(game.PlaceId or 1001))
    end
    State.WorldName = string.upper(detectedWorld)
end

-- =====================================================================
-- DATABASE ITEM LENGKAP (DENGAN ASSET ICON & METADATA KOMPLIT)
-- =====================================================================
local ItemDatabase = {
    { ID = 2,    SeedID = 3,    Name = "Dirt",                  Category = "Blocks",           Rarity = 1,   Hits = 3,  GrowTime = "30s",       Gems = "0 - 1",   Collision = "Solid",    Color = Color3.fromRGB(139, 90, 43),   IconAsset = "rbxassetid://6031265976", Description = "Basic soil block found in every standard world layer. Used for splicing basic trees." },
    { ID = 4,    SeedID = 5,    Name = "Cave Background",       Category = "Background",       Rarity = 1,   Hits = 3,  GrowTime = "35s",       Gems = "0 - 1",   Collision = "Passable", Color = Color3.fromRGB(92, 64, 51),    IconAsset = "rbxassetid://6031265976", Description = "Natural underground cave wall background tile." },
    { ID = 10,   SeedID = 11,   Name = "Rock",                  Category = "Blocks",           Rarity = 2,   Hits = 5,  GrowTime = "60s",       Gems = "0 - 2",   Collision = "Solid",    Color = Color3.fromRGB(128, 134, 139), IconAsset = "rbxassetid://6031280882", Description = "Hard stone boulder embedded inside dirt layers." },
    { ID = 14,   SeedID = 15,   Name = "Lava",                  Category = "Blocks",           Rarity = 2,   Hits = 4,  GrowTime = "45s",       Gems = "0 - 2",   Collision = "Hazard",   Color = Color3.fromRGB(235, 87, 34),   IconAsset = "rbxassetid://6031280882", Description = "Molten volcanic block that damages players on contact unless God Mode is active." },
    { ID = 100,  SeedID = 101,  Name = "Wood Block",            Category = "Blocks",           Rarity = 2,   Hits = 4,  GrowTime = "1m 15s",    Gems = "0 - 2",   Collision = "Solid",    Color = Color3.fromRGB(181, 136, 99),  IconAsset = "rbxassetid://6031265976", Description = "Refined timber plank used for building structures and mass projects." },
    { ID = 202,  SeedID = 203,  Name = "Small Lock",            Category = "Locks & Currency", Rarity = 5,   Hits = 8,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(218, 165, 32),  IconAsset = "rbxassetid://6031068426", Description = "Secures a customizable small area of tiles around the lock." },
    { ID = 204,  SeedID = 205,  Name = "Big Lock",              Category = "Locks & Currency", Rarity = 10,  Hits = 8,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(235, 190, 45),  IconAsset = "rbxassetid://6031068426", Description = "Secures up to 48 connected tiles against unauthorized modification." },
    { ID = 206,  SeedID = 207,  Name = "Huge Lock",             Category = "Locks & Currency", Rarity = 20,  Hits = 8,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(245, 210, 60),  IconAsset = "rbxassetid://6031068426", Description = "Secures up to 200 connected tiles in a world." },
    { ID = 242,  SeedID = 243,  Name = "World Lock",            Category = "Locks & Currency", Rarity = 99,  Hits = 10, GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(255, 215, 0),   IconAsset = "rbxassetid://6031068426", Description = "Universal trading currency and full-world ownership lock." },
    { ID = 1796, SeedID = 1797, Name = "Diamond Lock",          Category = "Locks & Currency", Rarity = 99,  Hits = 10, GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(56, 189, 248),  IconAsset = "rbxassetid://6031068426", Description = "Compressed high-value currency equivalent to 100 World Locks." },
    { ID = 7188, SeedID = 7189, Name = "Blue Gem Lock",         Category = "Locks & Currency", Rarity = 99,  Hits = 10, GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(37, 99, 235),   IconAsset = "rbxassetid://6031068426", Description = "Ultra-high tier currency equivalent to 100 Diamond Locks (10,000 WLs)." },
    { ID = 340,  SeedID = 341,  Name = "Chandelier",            Category = "Farmables",        Rarity = 87,  Hits = 5,  GrowTime = "7d 15h",    Gems = "12 - 22", Collision = "Passable", Color = Color3.fromRGB(250, 204, 21),  IconAsset = "rbxassetid://6031280882", Description = "High-rarity luxury farmable yielding massive gem drops per harvest." },
    { ID = 5666, SeedID = 5667, Name = "Laser Grid",            Category = "Farmables",        Rarity = 69,  Hits = 4,  GrowTime = "3d 10h",    Gems = "7 - 15",  Collision = "Solid",    Color = Color3.fromRGB(34, 197, 94),   IconAsset = "rbxassetid://6031280882", Description = "Top-tier 4-hit farmable security barrier with fast break cycles and high gem yield." },
    { ID = 4584, SeedID = 4585, Name = "Pepper Tree",           Category = "Farmables",        Rarity = 53,  Hits = 4,  GrowTime = "1d 15h",    Gems = "5 - 11",  Collision = "Solid",    Color = Color3.fromRGB(239, 68, 68),   IconAsset = "rbxassetid://6031265976", Description = "Popular 4-hit farmable block ideal for Basic & Pabrik Auto Farm routines." },
    { ID = 3004, SeedID = 3005, Name = "Fish Tank",             Category = "Farmables",        Rarity = 42,  Hits = 3,  GrowTime = "21h 52m",   Gems = "3 - 8",   Collision = "Solid",    Color = Color3.fromRGB(59, 130, 246),  IconAsset = "rbxassetid://6031265976", Description = "Fast 3-hit glass aquarium farmable great for rapid gem and XP farming." },
    { ID = 2722, SeedID = 2723, Name = "Sorcerer Stone",        Category = "Farmables",        Rarity = 85,  Hits = 5,  GrowTime = "7d 3h",     Gems = "11 - 21", Collision = "Solid",    Color = Color3.fromRGB(168, 85, 247),  IconAsset = "rbxassetid://6031280882", Description = "Mystical high-rarity enchanted block with top-tier gem returns." },
    { ID = 9928, SeedID = 9929, Name = "Bountiful Lattice Fence", Category = "Farmables",      Rarity = 55,  Hits = 4,  GrowTime = "1d 18h",    Gems = "5 - 12",  Collision = "Passable", Color = Color3.fromRGB(132, 204, 22),  IconAsset = "rbxassetid://6031265976", Description = "Passable background farmable widely used in Pabrik setups." },
    { ID = 5638, SeedID = 5639, Name = "Magplant 5000",         Category = "Special & IOTM",   Rarity = 99,  Hits = 6,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(244, 63, 94),   IconAsset = "rbxassetid://6031280882", Description = "Remote item dispenser and auto-farming core device via Magplant Remote." },
    { ID = 6946, SeedID = 6947, Name = "Gaia's Beacon",         Category = "Special & IOTM",   Rarity = 99,  Hits = 6,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(16, 185, 129),  IconAsset = "rbxassetid://6031280882", Description = "Automatically collects dropped seeds when harvesting trees in the world." },
    { ID = 6948, SeedID = 6949, Name = "Unstable Tesseract",    Category = "Special & IOTM",   Rarity = 99,  Hits = 6,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(99, 102, 241),  IconAsset = "rbxassetid://6031280882", Description = "Automatically collects dropped blocks when harvesting trees in the world." },
    { ID = 9500, SeedID = 9501, Name = "Rayman's Fist",         Category = "Clothing & Gear",  Rarity = 99,  Hits = 1,  GrowTime = "Equipable", Gems = "0",       Collision = "Equip",    Color = Color3.fromRGB(251, 191, 36),  IconAsset = "rbxassetid://6031280882", Description = "Legendary hand item allowing 3-tile line punching for ultra-fast BFG & Pabrik breaking." },
    { ID = 98,   SeedID = 99,   Name = "Pickaxe",               Category = "Clothing & Gear",  Rarity = 12,  Hits = 1,  GrowTime = "Equipable", Gems = "0",       Collision = "Equip",    Color = Color3.fromRGB(156, 163, 175), IconAsset = "rbxassetid://6031280882", Description = "Standard mining tool that reduces required hits on blocks by 1." },
    { ID = 758,  SeedID = 759,  Name = "Roulette Wheel",        Category = "Special & IOTM",   Rarity = 36,  Hits = 5,  GrowTime = "4h 30m",    Gems = "1 - 4",   Collision = "Solid",    Color = Color3.fromRGB(220, 38, 38),   IconAsset = "rbxassetid://6031280882", Description = "Spinnable number wheel (0-36). Compatible with Fast Roulette modifier." },
    { ID = 2978, SeedID = 2979, Name = "Vending Machine",       Category = "Special & IOTM",   Rarity = 50,  Hits = 6,  GrowTime = "Non-Farm",  Gems = "0",       Collision = "Solid",    Color = Color3.fromRGB(14, 165, 233),  IconAsset = "rbxassetid://6031265976", Description = "Automated shop machine for buying and selling items with World Locks." },
    { ID = 1404, SeedID = 1405, Name = "Door",                  Category = "Blocks",           Rarity = 3,   Hits = 4,  GrowTime = "1m 30s",    Gems = "0 - 2",   Collision = "Passable", Color = Color3.fromRGB(161, 98, 7),    IconAsset = "rbxassetid://6031265976", Description = "Interactive portal door that links to other doors or worlds." },
    { ID = 6,    SeedID = 7,    Name = "Main Door",             Category = "Blocks",           Rarity = 99,  Hits = 99, GrowTime = "Unbreakable", Gems = "0",     Collision = "Passable", Color = Color3.fromRGB(234, 88, 12),   IconAsset = "rbxassetid://6031265976", Description = "World entry spawn point. Automatically skipped during Auto Farm Clear mode." },
    { ID = 8,    SeedID = 9,    Name = "Bedrock",               Category = "Blocks",           Rarity = 99,  Hits = 99, GrowTime = "Unbreakable", Gems = "0",     Collision = "Solid",    Color = Color3.fromRGB(55, 65, 81),    IconAsset = "rbxassetid://6031265976", Description = "Indestructible bottom foundation block. Automatically skipped during Clear mode." }
}

-- =====================================================================
-- KATEGORI 1: FITUR MISC & LIVE POSITION INFO
-- =====================================================================
if UI.Category then UI.Category("Main Modules") end

local MiscPosStatLabels = nil
local MiscWorldStatLabels = nil
local MiscActiveCountLabel = nil

feature("Misc", "Fitur Misc"){
    center = center(function(c)
        c:Header("Fitur Misc & Movement", "Toggle character modifiers (ON/OFF) & fast interaction utilities", "Misc [0/1]")

        -- Card 1: Movement & Physics Modifiers
        local MoveModCard = c:Card("Movement & Physics (ON / OFF)", "5 MODS", "Speed", {
            Subtitle = "ModFly, NoClip, Speed, High Jump & AntiGravity"
        })

        MoveModCard:Toggle("ModFly (Fly Anywhere)", "MiscModFly", false, function(on)
            State.ModFly = on
        end)

        MoveModCard:Toggle("NoClip (Walk Through Blocks)", "MiscNoClip", false, function(on)
            State.NoClip = on
        end)

        MoveModCard:Toggle("Speed (Movement Boost ON/OFF)", "MiscSpeedOn", false, function(on)
            State.SpeedOn = on
            local lp = Players.LocalPlayer
            local hum = lp and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = on and State.SpeedVal or 16
            end
        end)

        MoveModCard:Slider("Speed Value", "MiscSpeedVal", 16, 250, 60, " ws", function(val)
            State.SpeedVal = val
            if State.SpeedOn then
                local lp = Players.LocalPlayer
                local hum = lp and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end)

        MoveModCard:Toggle("High Jump (Jump Boost ON/OFF)", "MiscHighJumpOn", false, function(on)
            State.HighJumpOn = on
            local lp = Players.LocalPlayer
            local hum = lp and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = on and State.JumpVal or 50
            end
        end)

        MoveModCard:Slider("High Jump Power", "MiscJumpVal", 50, 350, 120, " jp", function(val)
            State.JumpVal = val
            if State.HighJumpOn then
                local lp = Players.LocalPlayer
                local hum = lp and lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.UseJumpPower = true
                    hum.JumpPower = val
                end
            end
        end)

        MoveModCard:Toggle("AntiGravity (Zero / Low Gravity)", "MiscAntiGravity", false, function(on)
            State.AntiGravity = on
            pcall(function()
                workspace.Gravity = on and 28 or State.DefaultGravity
            end)
        end)

        -- Card 2: Fast Actions & God Mode
        local ActionModCard = c:Card("Fast Utility & God Mode (ON / OFF)", "3 MODS", "Shield", {
            Subtitle = "Fast Roulette, Fast Wrench & God Mode hazard immunity"
        })

        ActionModCard:Toggle("Fast Roulette (Instant Wheel Result)", "MiscFastRoulette", false, function(on)
            State.FastRoulette = on
        end)

        ActionModCard:Toggle("Fast Wrench (Instant Player Action)", "MiscFastWrench", false, function(on)
            State.FastWrench = on
        end)

        ActionModCard:Dropdown("Fast Wrench Action Mode", "MiscWrenchMode", {
            "Pull (/pull)",
            "Kick (/kick)",
            "Ban (/ban)",
            "Trade (/trade)",
            "View Inventory"
        }, "Pull (/pull)", function(mode)
            State.WrenchMode = mode
        end)

        ActionModCard:Toggle("God Mode (Anti-Hazard / Spike / Lava)", "MiscGodMode", false, function(on)
            State.GodMode = on
        end)
    end),

    -- Panel Kanan Khusus Fitur Misc: INFO POSITION SEKARANG (X : Y, NAMA PLAYER, TOTAL PLAYER, NAMA WORLD)
    right = right(function(r)
        ReadLiveWorldAndPosition()

        local PosInfoCard = r:Card("Info Position Sekarang", "LIVE", "Player", {
            Subtitle = "Koordinat X : Y real-time, identitas player & informasi world"
        })

        MiscPosStatLabels = PosInfoCard:StatRow({
            { Icon = "Teleports", Label = "X : Y POSITION", Value = string.format("X: %d | Y: %d", State.PosX, State.PosY) },
            { Icon = "Player",    Label = "TOTAL PLAYER",   Value = tostring(State.TotalPlayers) .. " Players" }
        })

        MiscWorldStatLabels = PosInfoCard:StatRow({
            { Icon = "User",      Label = "NAMA PLAYER",    Value = State.PlayerName },
            { Icon = "Home",      Label = "NAMA WORLD",     Value = State.WorldName }
        })

        PosInfoCard:Button("Copy Posisi Sekarang (X : Y)", "COPY POS", "Teleports", function()
            ReadLiveWorldAndPosition()
            local posText = string.format("X: %d, Y: %d (World: %s)", State.PosX, State.PosY, State.WorldName)
            CopyToClipboard(posText)
        end)

        PosInfoCard:Button("Kirim X, Y ke Auto Farm Pabrik", "SET PABRIK", "Bot", function()
            ReadLiveWorldAndPosition()
            State.PabrikBreakX = tostring(State.PosX)
            State.PabrikBreakY = tostring(State.PosY)
            if UI.SetValue then
                UI:SetValue("PabrikBreakX", State.PabrikBreakX)
                UI:SetValue("PabrikBreakY", State.PabrikBreakY)
            end
        end)

        local QuickSummaryCard = r:Card("Status Fitur Misc", "MONITOR", "Bolt", {
            Subtitle = "Ringkasan modul Misc yang sedang aktif [1 = ON / 0 = OFF]"
        })

        local summaryLabels = QuickSummaryCard:StatRow({
            { Icon = "Bolt",   Label = "ACTIVE MODS", Value = "0 / 8 ON" },
            { Icon = "Shield", Label = "PROTECTION",  Value = "STANDBY" }
        })
        MiscActiveCountLabel = summaryLabels

        QuickSummaryCard:Button("Matikan Semua Fitur Misc (Reset 0)", "RESET ALL", "Close", function()
            local flags = {
                "MiscModFly", "MiscNoClip", "MiscFastRoulette", "MiscFastWrench",
                "MiscGodMode", "MiscSpeedOn", "MiscHighJumpOn", "MiscAntiGravity"
            }
            for _, f in ipairs(flags) do
                if UI.SetValue then UI:SetValue(f, false) end
            end
            State.ModFly = false
            State.NoClip = false
            State.FastRoulette = false
            State.FastWrench = false
            State.GodMode = false
            State.SpeedOn = false
            State.HighJumpOn = false
            State.AntiGravity = false
            pcall(function() workspace.Gravity = State.DefaultGravity end)
        end)
    end)
}

-- =====================================================================
-- KATEGORI 2: FITUR ITEM INFO (SEARCH BAR, CARD ALL ITEM LIST, ASSET ICON, COMPLETE INFO)
-- =====================================================================
local SelectedItem = ItemDatabase[13] -- Default: Pepper Tree (ID 4584)
local ItemDetailRefs = {}
local ItemEntryCards = {}

-- Fungsi pembuat Visual Asset Icon + Custom Item Card di dalam R&8_DV Card
local function BuildVisualItemIcon(parentFrame, itemData, sizePx)
    sizePx = sizePx or 46
    local IconContainer = Instance.new("Frame")
    IconContainer.Size = UDim2.fromOffset(sizePx, sizePx)
    IconContainer.BackgroundColor3 = itemData.Color or Color3.fromRGB(59, 130, 246)
    IconContainer.BorderSizePixel = 0
    IconContainer.Parent = parentFrame

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = IconContainer

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(255, 255, 255)
    Stroke.Transparency = 0.65
    Stroke.Thickness = 1.5
    Stroke.Parent = IconContainer

    -- Inner Pixel Pattern / Block Texture Layer
    local InnerBlock = Instance.new("Frame")
    InnerBlock.Size = UDim2.new(0.72, 0, 0.72, 0)
    InnerBlock.Position = UDim2.fromScale(0.5, 0.5)
    InnerBlock.AnchorPoint = Vector2.new(0.5, 0.5)
    InnerBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InnerBlock.BackgroundTransparency = 0.82
    InnerBlock.BorderSizePixel = 0
    InnerBlock.Parent = IconContainer

    local InnerCorner = Instance.new("UICorner")
    InnerCorner.CornerRadius = UDim.new(0, 6)
    InnerCorner.Parent = InnerBlock

    -- Roblox Asset ImageLabel (Show Asset Icon)
    local AssetImg = Instance.new("ImageLabel")
    AssetImg.Size = UDim2.new(0.62, 0, 0.62, 0)
    AssetImg.Position = UDim2.fromScale(0.5, 0.45)
    AssetImg.AnchorPoint = Vector2.new(0.5, 0.5)
    AssetImg.BackgroundTransparency = 1
    AssetImg.Image = itemData.IconAsset or "rbxassetid://6031265976"
    AssetImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
    AssetImg.Parent = IconContainer

    -- ID Tag Pill di bagian bawah Icon
    local IdBadge = Instance.new("TextLabel")
    IdBadge.Size = UDim2.new(1, -4, 0, 14)
    IdBadge.Position = UDim2.new(0.5, 0, 1, -2)
    IdBadge.AnchorPoint = Vector2.new(0.5, 1)
    IdBadge.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
    IdBadge.BackgroundTransparency = 0.2
    IdBadge.BorderSizePixel = 0
    IdBadge.Font = Enum.Font.GothamBlack
    IdBadge.Text = "#" .. tostring(itemData.ID)
    IdBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    IdBadge.TextSize = 10
    IdBadge.Parent = IconContainer

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 4)
    BadgeCorner.Parent = IdBadge

    return IconContainer, AssetImg, IdBadge
end

local function RefreshSelectedItemInspector(item)
    if not item then return end
    SelectedItem = item

    if ItemDetailRefs.IconBox then
        ItemDetailRefs.IconBox.BackgroundColor3 = item.Color or Color3.fromRGB(59, 130, 246)
    end
    if ItemDetailRefs.IconImg then
        ItemDetailRefs.IconImg.Image = item.IconAsset or "rbxassetid://6031265976"
    end
    if ItemDetailRefs.IconBadge then
        ItemDetailRefs.IconBadge.Text = "#" .. tostring(item.ID)
    end
    if ItemDetailRefs.TitleLbl then
        ItemDetailRefs.TitleLbl.Text = string.format("%s (ID: %d)", item.Name, item.ID)
    end
    if ItemDetailRefs.SubLbl then
        ItemDetailRefs.SubLbl.Text = string.format("Category: %s  •  Seed ID: %d  •  Rarity: ★ %d", item.Category, item.SeedID or (item.ID + 1), item.Rarity)
    end
    if ItemDetailRefs.AssetUriLbl then
        ItemDetailRefs.AssetUriLbl.Text = "Asset Icon: " .. tostring(item.IconAsset)
    end

    if ItemDetailRefs.StatTop then
        if ItemDetailRefs.StatTop[1] then ItemDetailRefs.StatTop[1].Text = tostring(item.ID) .. " (Seed: " .. tostring(item.SeedID or (item.ID + 1)) .. ")" end
        if ItemDetailRefs.StatTop[2] then ItemDetailRefs.StatTop[2].Text = "★ " .. tostring(item.Rarity) end
    end
    if ItemDetailRefs.StatMid then
        if ItemDetailRefs.StatMid[1] then ItemDetailRefs.StatMid[1].Text = tostring(item.Hits) .. " Hits" end
        if ItemDetailRefs.StatMid[2] then ItemDetailRefs.StatMid[2].Text = tostring(item.GrowTime) end
    end
    if ItemDetailRefs.StatBot then
        if ItemDetailRefs.StatBot[1] then ItemDetailRefs.StatBot[1].Text = tostring(item.Gems) .. " Gems" end
        if ItemDetailRefs.StatBot[2] then ItemDetailRefs.StatBot[2].Text = tostring(item.Collision) end
    end
    if ItemDetailRefs.DescInputFlag and UI.SetValue then
        UI:SetValue(ItemDetailRefs.DescInputFlag, item.Description or "-")
    end
end

local CurrentItemSearch = ""
local CurrentItemCategory = "All Categories"

local function FilterItemCards()
    local q = string.lower((CurrentItemSearch or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    local cat = CurrentItemCategory or "All Categories"
    local visibleCount = 0

    for _, entry in ipairs(ItemEntryCards) do
        local it = entry.Data
        local matchCat = (cat == "All Categories") or (it.Category == cat)
        local matchQuery = (q == "")
            or (string.find(string.lower(it.Name), q, 1, true) ~= nil)
            or (string.find(tostring(it.ID), q, 1, true) ~= nil)
            or (string.find(tostring(it.SeedID), q, 1, true) ~= nil)
            or (string.find(string.lower(it.Category), q, 1, true) ~= nil)

        local show = (matchCat and matchQuery)
        if entry.Frame then
            entry.Frame.Visible = show
        end
        if show then
            visibleCount = visibleCount + 1
        end
    end

    if ItemDetailRefs.CountStat and ItemDetailRefs.CountStat[1] then
        ItemDetailRefs.CountStat[1].Text = string.format("%d / %d Items", visibleCount, #ItemDatabase)
    end
end

feature("Visuals", "Item Info"){
    center = center(function(c)
        c:Header("Fitur Item Info & Database", "Search bar, Card All Item List dengan Asset Icon, & Copy ID / Name", "Item DB")

        -- 1. SEARCH BAR CARD
        local SearchCard = c:Card("Search Bar & Filter", "LIVE FILTER", "Visuals", {
            Subtitle = "Cari item berdasarkan Nama Item, ID Block, ID Seed, atau Kategori"
        })

        ItemDetailRefs.CountStat = SearchCard:StatRow({
            { Icon = "Grid",  Label = "SHOWING ITEMS", Value = string.format("%d / %d Items", #ItemDatabase, #ItemDatabase) },
            { Icon = "Check", Label = "SELECTED ID",   Value = "#" .. tostring(SelectedItem.ID) .. " " .. SelectedItem.Name }
        })

        SearchCard:Input("Search Bar (Cari Nama / ID Item)", "ItemSearchInput", "Ketik Nama Item atau ID (contoh: 242, Pepper, Magplant, Lock)...", "", function(text)
            CurrentItemSearch = text or ""
            FilterItemCards()
        end)

        SearchCard:Dropdown("Filter Kategori Item", "ItemCatFilter", {
            "All Categories",
            "Farmables",
            "Locks & Currency",
            "Special & IOTM",
            "Blocks",
            "Background",
            "Clothing & Gear"
        }, "All Categories", function(selectedCat)
            CurrentItemCategory = selectedCat
            FilterItemCards()
        end)

        SearchCard:Button("Reset Search & Tampilkan Semua Item", "RESET", "Check", function()
            CurrentItemSearch = ""
            CurrentItemCategory = "All Categories"
            if UI.SetValue then
                UI:SetValue("ItemSearchInput", "")
                UI:SetValue("ItemCatFilter", "All Categories")
            end
            FilterItemCards()
        end)

        -- 2. CARD ALL ITEM LIST (DENGAN ASSET ICON & TOMBOL INSPECT / COPY)
        local ListCard = c:Card("Card All Item List", tostring(#ItemDatabase) .. " ITEMS", "Grid", {
            Subtitle = "Klik item untuk melihat Completely Information di panel kanan atau langsung Copy ID/Name"
        })

        local listContainer = ListCard.Container or ListCard.Frame
        for idx, item in ipairs(ItemDatabase) do
            local ItemRow = Instance.new("Frame")
            ItemRow.Name = "ItemCard_" .. tostring(item.ID)
            ItemRow.Size = UDim2.new(1, 0, 0, 86)
            ItemRow.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
            ItemRow.BorderSizePixel = 0
            ItemRow.LayoutOrder = 100 + idx
            if typeof(listContainer) == "Instance" then
                ItemRow.Parent = listContainer
            end

            local RowCorner = Instance.new("UICorner")
            RowCorner.CornerRadius = UDim.new(0, 10)
            RowCorner.Parent = ItemRow

            local RowStroke = Instance.new("UIStroke")
            RowStroke.Color = Color3.fromRGB(60, 68, 88)
            RowStroke.Transparency = 0.35
            RowStroke.Thickness = 1
            RowStroke.Parent = ItemRow

            -- Visual Asset Icon di sebelah kiri kartu item
            local iconBox = BuildVisualItemIcon(ItemRow, item, 58)
            iconBox.Position = UDim2.new(0, 14, 0.5, 0)
            iconBox.AnchorPoint = Vector2.new(0, 0.5)

            -- Nama Item & ID
            local NameLbl = Instance.new("TextLabel")
            NameLbl.Position = UDim2.new(0, 84, 0, 10)
            NameLbl.Size = UDim2.new(1, -240, 0, 22)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Font = Enum.Font.GothamBlack
            NameLbl.Text = string.format("%s  [ID: %d]", item.Name, item.ID)
            NameLbl.TextColor3 = Color3.fromRGB(245, 247, 252)
            NameLbl.TextSize = 16
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.Parent = ItemRow

            -- Metadata Ringkas
            local MetaLbl = Instance.new("TextLabel")
            MetaLbl.Position = UDim2.new(0, 84, 0, 34)
            MetaLbl.Size = UDim2.new(1, -240, 0, 18)
            MetaLbl.BackgroundTransparency = 1
            MetaLbl.Font = Enum.Font.GothamBold
            MetaLbl.Text = string.format("%s  •  Rarity: ★%d  •  Hits: %d  •  Grow: %s", item.Category, item.Rarity, item.Hits, item.GrowTime)
            MetaLbl.TextColor3 = Color3.fromRGB(160, 170, 190)
            MetaLbl.TextSize = 13
            MetaLbl.TextTruncate = Enum.TextTruncate.AtEnd
            MetaLbl.TextXAlignment = Enum.TextXAlignment.Left
            MetaLbl.Parent = ItemRow

            -- Deskripsi Singkat
            local SubDescLbl = Instance.new("TextLabel")
            SubDescLbl.Position = UDim2.new(0, 84, 0, 54)
            SubDescLbl.Size = UDim2.new(1, -240, 0, 20)
            SubDescLbl.BackgroundTransparency = 1
            SubDescLbl.Font = Enum.Font.GothamMedium
            SubDescLbl.Text = item.Description
            SubDescLbl.TextColor3 = Color3.fromRGB(125, 135, 155)
            SubDescLbl.TextSize = 12
            SubDescLbl.TextTruncate = Enum.TextTruncate.AtEnd
            SubDescLbl.TextXAlignment = Enum.TextXAlignment.Left
            SubDescLbl.Parent = ItemRow

            -- Tombol Aksi Cepat di Kanan Kartu (INSPECT, COPY ID, COPY NAME)
            local BtnInspect = Instance.new("TextButton")
            BtnInspect.Size = UDim2.fromOffset(68, 28)
            BtnInspect.Position = UDim2.new(1, -152, 0, 12)
            BtnInspect.BackgroundColor3 = Color3.fromRGB(37, 99, 235)
            BtnInspect.BorderSizePixel = 0
            BtnInspect.Font = Enum.Font.GothamBold
            BtnInspect.Text = "DETAIL"
            BtnInspect.TextColor3 = Color3.fromRGB(255, 255, 255)
            BtnInspect.TextSize = 12
            BtnInspect.Parent = ItemRow
            local c1 = Instance.new("UICorner", BtnInspect)
            c1.CornerRadius = UDim.new(0, 6)

            local BtnCopyID = Instance.new("TextButton")
            BtnCopyID.Size = UDim2.fromOffset(68, 28)
            BtnCopyID.Position = UDim2.new(1, -78, 0, 12)
            BtnCopyID.BackgroundColor3 = Color3.fromRGB(40, 48, 66)
            BtnCopyID.BorderSizePixel = 0
            BtnCopyID.Font = Enum.Font.GothamBold
            BtnCopyID.Text = "COPY ID"
            BtnCopyID.TextColor3 = Color3.fromRGB(240, 244, 255)
            BtnCopyID.TextSize = 12
            BtnCopyID.Parent = ItemRow
            local c2 = Instance.new("UICorner", BtnCopyID)
            c2.CornerRadius = UDim.new(0, 6)

            local BtnCopyName = Instance.new("TextButton")
            BtnCopyName.Size = UDim2.fromOffset(142, 26)
            BtnCopyName.Position = UDim2.new(1, -152, 0, 46)
            BtnCopyName.BackgroundColor3 = Color3.fromRGB(32, 38, 52)
            BtnCopyName.BorderSizePixel = 0
            BtnCopyName.Font = Enum.Font.GothamBold
            BtnCopyName.Text = "COPY NAME"
            BtnCopyName.TextColor3 = Color3.fromRGB(210, 220, 240)
            BtnCopyName.TextSize = 12
            BtnCopyName.Parent = ItemRow
            local c3 = Instance.new("UICorner", BtnCopyName)
            c3.CornerRadius = UDim.new(0, 6)

            local function SelectThisItem()
                RefreshSelectedItemInspector(item)
                if ItemDetailRefs.CountStat and ItemDetailRefs.CountStat[2] then
                    ItemDetailRefs.CountStat[2].Text = "#" .. tostring(item.ID) .. " " .. item.Name
                end
            end

            BtnInspect.MouseButton1Click:Connect(SelectThisItem)
            BtnCopyID.MouseButton1Click:Connect(function()
                SelectThisItem()
                CopyToClipboard(tostring(item.ID))
                BtnCopyID.Text = "COPIED!"
                task.delay(0.8, function()
                    if BtnCopyID and BtnCopyID.Parent then BtnCopyID.Text = "COPY ID" end
                end)
            end)
            BtnCopyName.MouseButton1Click:Connect(function()
                SelectThisItem()
                CopyToClipboard(item.Name)
                BtnCopyName.Text = "COPIED NAME!"
                task.delay(0.8, function()
                    if BtnCopyName and BtnCopyName.Parent then BtnCopyName.Text = "COPY NAME" end
                end)
            end)

            table.insert(ItemEntryCards, {
                Data = item,
                Frame = ItemRow
            })
        end
    end),

    -- Panel Kanan Khusus Fitur Item Info: COMPLETELY INFORMATION + SHOW ASSET ICON + COPY ID OR NAME
    right = right(function(r)
        local PreviewCard = r:Card("Asset Icon & Item Preview", "ICON VIEW", "Visuals", {
            Subtitle = "Preview visual asset icon, warna blok & identitas item terpilih"
        })

        local previewParent = PreviewCard.Container or PreviewCard.Frame
        if typeof(previewParent) == "Instance" then
            local HeroBanner = Instance.new("Frame")
            HeroBanner.Size = UDim2.new(1, 0, 0, 92)
            HeroBanner.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
            HeroBanner.BorderSizePixel = 0
            HeroBanner.Parent = previewParent

            local HeroCorner = Instance.new("UICorner")
            HeroCorner.CornerRadius = UDim.new(0, 10)
            HeroCorner.Parent = HeroBanner

            local HeroStroke = Instance.new("UIStroke")
            HeroStroke.Color = Color3.fromRGB(70, 80, 105)
            HeroStroke.Transparency = 0.3
            HeroStroke.Parent = HeroBanner

            local iconBox, iconImg, iconBadge = BuildVisualItemIcon(HeroBanner, SelectedItem, 68)
            iconBox.Position = UDim2.new(0, 14, 0.5, 0)
            iconBox.AnchorPoint = Vector2.new(0, 0.5)

            local HeroTitle = Instance.new("TextLabel")
            HeroTitle.Position = UDim2.new(0, 96, 0, 14)
            HeroTitle.Size = UDim2.new(1, -108, 0, 24)
            HeroTitle.BackgroundTransparency = 1
            HeroTitle.Font = Enum.Font.GothamBlack
            HeroTitle.Text = string.format("%s (ID: %d)", SelectedItem.Name, SelectedItem.ID)
            HeroTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
            HeroTitle.TextSize = 18
            HeroTitle.TextTruncate = Enum.TextTruncate.AtEnd
            HeroTitle.TextXAlignment = Enum.TextXAlignment.Left
            HeroTitle.Parent = HeroBanner

            local HeroSub = Instance.new("TextLabel")
            HeroSub.Position = UDim2.new(0, 96, 0, 40)
            HeroSub.Size = UDim2.new(1, -108, 0, 20)
            HeroSub.BackgroundTransparency = 1
            HeroSub.Font = Enum.Font.GothamBold
            HeroSub.Text = string.format("Category: %s  •  Seed ID: %d  •  Rarity: ★ %d", SelectedItem.Category, SelectedItem.SeedID, SelectedItem.Rarity)
            HeroSub.TextColor3 = Color3.fromRGB(175, 185, 205)
            HeroSub.TextSize = 13
            HeroSub.TextTruncate = Enum.TextTruncate.AtEnd
            HeroSub.TextXAlignment = Enum.TextXAlignment.Left
            HeroSub.Parent = HeroBanner

            local HeroAssetUri = Instance.new("TextLabel")
            HeroAssetUri.Position = UDim2.new(0, 96, 0, 62)
            HeroAssetUri.Size = UDim2.new(1, -108, 0, 18)
            HeroAssetUri.BackgroundTransparency = 1
            HeroAssetUri.Font = Enum.Font.GothamMedium
            HeroAssetUri.Text = "Asset Icon: " .. tostring(SelectedItem.IconAsset)
            HeroAssetUri.TextColor3 = Color3.fromRGB(120, 160, 245)
            HeroAssetUri.TextSize = 12
            HeroAssetUri.TextTruncate = Enum.TextTruncate.AtEnd
            HeroAssetUri.TextXAlignment = Enum.TextXAlignment.Left
            HeroAssetUri.Parent = HeroBanner

            ItemDetailRefs.IconBox = iconBox
            ItemDetailRefs.IconImg = iconImg
            ItemDetailRefs.IconBadge = iconBadge
            ItemDetailRefs.TitleLbl = HeroTitle
            ItemDetailRefs.SubLbl = HeroSub
            ItemDetailRefs.AssetUriLbl = HeroAssetUri
        end

        local CompleteInfoCard = r:Card("Completely Information", "FULL DATA", "Grid", {
            Subtitle = "Spesifikasi lengkap item terpilih (ID, Rarity, Hits, Grow Time, Gems, Deskripsi)"
        })

        ItemDetailRefs.StatTop = CompleteInfoCard:StatRow({
            { Icon = "Key",     Label = "ITEM & SEED ID", Value = tostring(SelectedItem.ID) .. " (Seed: " .. tostring(SelectedItem.SeedID) .. ")" },
            { Icon = "Palette", Label = "RARITY RATING",  Value = "★ " .. tostring(SelectedItem.Rarity) }
        })

        ItemDetailRefs.StatMid = CompleteInfoCard:StatRow({
            { Icon = "Bolt",    Label = "BREAK HITS",     Value = tostring(SelectedItem.Hits) .. " Hits" },
            { Icon = "Clock",   Label = "GROW TIME",      Value = tostring(SelectedItem.GrowTime) }
        })

        ItemDetailRefs.StatBot = CompleteInfoCard:StatRow({
            { Icon = "Collect", Label = "GEM DROP",       Value = tostring(SelectedItem.Gems) .. " Gems" },
            { Icon = "Shield",  Label = "COLLISION TYPE", Value = tostring(SelectedItem.Collision) }
        })

        ItemDetailRefs.DescInputFlag = "SelectedItemFullDesc"
        CompleteInfoCard:Input("Item Description / Notes", "SelectedItemFullDesc", "Item description...", SelectedItem.Description)

        local CopyCard = r:Card("Copy ID or Name Actions", "CLIPBOARD", "Check", {
            Subtitle = "Salin ID, Nama Item, atau kirim langsung ke Auto Farm"
        })

        CopyCard:Button("Copy Item ID", "COPY ID", "Key", function()
            CopyToClipboard(tostring(SelectedItem.ID))
        end)

        CopyCard:Button("Copy Item Name", "COPY NAME", "Chat", function()
            CopyToClipboard(tostring(SelectedItem.Name))
        end)

        CopyCard:Button("Copy Seed ID (ID + 1)", "SEED ID", "Bot", function()
            CopyToClipboard(tostring(SelectedItem.SeedID or (SelectedItem.ID + 1)))
        end)

        CopyCard:Button("Copy Completely Information", "FULL INFO", "Check", function()
            local summary = string.format(
                "[Item Info] Name: %s | ID: %d | Seed ID: %d | Category: %s | Rarity: %d | Hits: %d | Grow: %s | Gems: %s | Info: %s",
                SelectedItem.Name, SelectedItem.ID, SelectedItem.SeedID or (SelectedItem.ID + 1),
                SelectedItem.Category, SelectedItem.Rarity, SelectedItem.Hits,
                SelectedItem.GrowTime, SelectedItem.Gems, SelectedItem.Description
            )
            CopyToClipboard(summary)
        end)

        CopyCard:Button("Gunakan Item Ini di Auto Farm", "SEND TO FARM", "Bolt", function()
            State.BasicItemID = tostring(SelectedItem.ID)
            State.PabrikSeedID = tostring(SelectedItem.SeedID or (SelectedItem.ID + 1))
            if UI.SetValue then
                UI:SetValue("BasicItemID", State.BasicItemID)
                UI:SetValue("PabrikSeedID", State.PabrikSeedID)
            end
        end)
    end)
}

-- =====================================================================
-- KATEGORI 3: FITUR AUTO FARM (3 MODE DINAMIS + AUTO COLLECT ON RADIUS 4)
-- =====================================================================
local FarmCenterCards = {}
local FarmRightCards = {}
local FarmStatusLabels = nil
local BasicRightStatLabels = nil
local PabrikRightStatLabels = nil
local ClearRightStatLabels = nil

local BasicStartStopCtrl = nil
local PabrikStartStopCtrl = nil
local ClearStartStopCtrl = nil

-- Sinkronisasi Auto Collect (SELALU ON RADIUS 4 SAAT AUTO FARM AKTIF)
local function SyncAutoCollectGuard()
    local anyFarmActive = State.BasicRunning or State.PabrikRunning or State.ClearRunning
    State.AutoCollectAlwaysOn = anyFarmActive
    State.AutoCollectRadius = 4

    if FarmStatusLabels then
        if FarmStatusLabels[1] then
            local activeName = "IDLE [0]"
            if State.BasicRunning then activeName = "BASIC [1]"
            elseif State.PabrikRunning then activeName = "PABRIK [1]"
            elseif State.ClearRunning then activeName = "CLEAR [1]" end
            FarmStatusLabels[1].Text = activeName
        end
        if FarmStatusLabels[2] then
            FarmStatusLabels[2].Text = anyFarmActive and "ON (RADIUS 4)" or "STANDBY (RAD 4)"
        end
    end
end

-- Fungsi Beda Pilih Mode = Beda Input (Menampilkan hanya Card milik mode yang dipilih)
local function SwitchAutoFarmMode(modeName)
    State.AutoFarmMode = modeName
    local isBasic = (modeName == "1. BASIC")
    local isPabrik = (modeName == "2. PABRIK")
    local isClear = (modeName == "3. CLEAR")

    if FarmCenterCards.Basic and FarmCenterCards.Basic.Frame then
        FarmCenterCards.Basic.Frame.Visible = isBasic
    end
    if FarmCenterCards.Pabrik and FarmCenterCards.Pabrik.Frame then
        FarmCenterCards.Pabrik.Frame.Visible = isPabrik
    end
    if FarmCenterCards.Clear and FarmCenterCards.Clear.Frame then
        FarmCenterCards.Clear.Frame.Visible = isClear
    end

    if FarmRightCards.Basic and FarmRightCards.Basic.Frame then
        FarmRightCards.Basic.Frame.Visible = isBasic
    end
    if FarmRightCards.Pabrik and FarmRightCards.Pabrik.Frame then
        FarmRightCards.Pabrik.Frame.Visible = isPabrik
    end
    if FarmRightCards.Clear and FarmRightCards.Clear.Frame then
        FarmRightCards.Clear.Frame.Visible = isClear
    end
end

feature("Bot", "Auto Farm"){
    center = center(function(c)
        c:Header(
            "Fitur Auto Farm (3 Mode)",
            "Auto Collect ON Always (Radius 4) saat Auto Farm menyala • Pilih Mode untuk input berbeda",
            "Radius 4"
        )

        -- Card Utama: Pemilih 3 Mode & Status Auto Collect Radius 4
        local ModeSelectorCard = c:Card("Auto Farm Mode & Auto Collect Guard", "3 MODES", "Bot", {
            Subtitle = "Auto Collect otomatis menyala pada Radius 4 ketika mode Auto Farm dijalankan"
        })

        FarmStatusLabels = ModeSelectorCard:StatRow({
            { Icon = "Bot",     Label = "FARM STATUS",         Value = "IDLE [0]" },
            { Icon = "Collect", Label = "AUTO COLLECT (RAD 4)", Value = "STANDBY (RAD 4)" }
        })

        ModeSelectorCard:Dropdown("Pilih Mode Auto Farm (Beda Pilih Beda Input)", "AutoFarmModeSelect", {
            "1. BASIC",
            "2. PABRIK",
            "3. CLEAR"
        }, "1. BASIC", function(selectedMode)
            SwitchAutoFarmMode(selectedMode)
        end)

        -- =================================================================
        -- MODE 1: 1. BASIC (ID Item Input, Hide/No Hand Break Place, Speed Setting, Start/Stop 1 Button)
        -- =================================================================
        local BasicCard = c:Card("Mode 1: BASIC Auto Farm", "MODE 1", "Bolt", {
            Subtitle = "ID Item Input, Hide/No Hand Break Place, Speed Setting & 1-Button Start/Stop (Lihat Kanan untuk Grid 6x6)"
        })
        FarmCenterCards.Basic = BasicCard

        BasicCard:Input("ID Item Input (Block ID / Name)", "BasicItemID", "Masukkan ID Item (contoh: 4584 / Pepper Tree)...", State.BasicItemID, function(val)
            State.BasicItemID = val
            if BasicRightStatLabels and BasicRightStatLabels[1] then
                BasicRightStatLabels[1].Text = "ID: " .. tostring(val)
            end
        end)

        BasicCard:Toggle("Hide / No Hand Animation (Break & Place)", "BasicHideHand", true, function(on)
            State.BasicHideHand = on
        end)

        BasicCard:Slider("Speed Setting (Break / Place Delay)", "BasicSpeedMs", 50, 500, 160, " ms", function(val)
            State.BasicSpeedMs = val
        end)

        BasicCard:Slider("Hits Per Block", "BasicBlockHits", 1, 12, 4, " hits", function(val)
            State.BasicHits = val
        end)

        BasicStartStopCtrl = CreateUnifiedStartStopButton(
            BasicCard,
            "START BASIC AUTO FARM",
            "STOP BASIC AUTO FARM (RUNNING)",
            "Bolt",
            function(running)
                State.BasicRunning = running
                if running then
                    if PabrikStartStopCtrl then PabrikStartStopCtrl.SetState(false, true) end
                    if ClearStartStopCtrl then ClearStartStopCtrl.SetState(false, true) end
                    State.PabrikRunning = false
                    State.ClearRunning = false
                end
                SyncAutoCollectGuard()
            end
        )

        -- =================================================================
        -- MODE 2: 2. PABRIK (X, Y Input Posisi Break, ID Seed, Radius or Total Seed Place, Start + Stop)
        -- =================================================================
        local PabrikCard = c:Card("Mode 2: PABRIK Auto Farm", "MODE 2", "Grid", {
            Subtitle = "Input Koordinat X, Y Posisi Break, ID Seed, Radius / Total Seed Place & 1-Button Start/Stop"
        })
        FarmCenterCards.Pabrik = PabrikCard

        PabrikCard:Input("Posisi Break X (Koordinat Tile X)", "PabrikBreakX", "Masukkan Posisi X (contoh: 50)...", State.PabrikBreakX, function(val)
            State.PabrikBreakX = val
            if PabrikRightStatLabels and PabrikRightStatLabels[1] then
                PabrikRightStatLabels[1].Text = string.format("X: %s | Y: %s", tostring(State.PabrikBreakX), tostring(State.PabrikBreakY))
            end
        end)

        PabrikCard:Input("Posisi Break Y (Koordinat Tile Y)", "PabrikBreakY", "Masukkan Posisi Y (contoh: 23)...", State.PabrikBreakY, function(val)
            State.PabrikBreakY = val
            if PabrikRightStatLabels and PabrikRightStatLabels[1] then
                PabrikRightStatLabels[1].Text = string.format("X: %s | Y: %s", tostring(State.PabrikBreakX), tostring(State.PabrikBreakY))
            end
        end)

        PabrikCard:Button("Ambil X, Y Posisi Player Sekarang", "GET X, Y", "Teleports", function()
            ReadLiveWorldAndPosition()
            State.PabrikBreakX = tostring(State.PosX)
            State.PabrikBreakY = tostring(State.PosY)
            if UI.SetValue then
                UI:SetValue("PabrikBreakX", State.PabrikBreakX)
                UI:SetValue("PabrikBreakY", State.PabrikBreakY)
            end
            if PabrikRightStatLabels and PabrikRightStatLabels[1] then
                PabrikRightStatLabels[1].Text = string.format("X: %s | Y: %s", State.PabrikBreakX, State.PabrikBreakY)
            end
        end)

        PabrikCard:Input("ID Seed Input", "PabrikSeedID", "Masukkan ID Seed (contoh: 4585)...", State.PabrikSeedID, function(val)
            State.PabrikSeedID = val
            if PabrikRightStatLabels and PabrikRightStatLabels[2] then
                PabrikRightStatLabels[2].Text = "Seed #" .. tostring(val)
            end
        end)

        PabrikCard:Dropdown("Tipe Jangkauan Tanam (Radius / Total Seed)", "PabrikScopeMode", {
            "Radius (Tiles)",
            "Total Seed Place"
        }, "Radius (Tiles)", function(mode)
            State.PabrikScopeMode = mode
        end)

        PabrikCard:Slider("Radius or Total Seed Place", "PabrikRadiusOrTotal", 1, 100, 4, " tiles/seeds", function(val)
            State.PabrikRadiusOrTotal = val
        end)

        PabrikStartStopCtrl = CreateUnifiedStartStopButton(
            PabrikCard,
            "START PABRIK AUTO FARM",
            "STOP PABRIK AUTO FARM (RUNNING)",
            "Bot",
            function(running)
                State.PabrikRunning = running
                if running then
                    if BasicStartStopCtrl then BasicStartStopCtrl.SetState(false, true) end
                    if ClearStartStopCtrl then ClearStartStopCtrl.SetState(false, true) end
                    State.BasicRunning = false
                    State.ClearRunning = false
                end
                SyncAutoCollectGuard()
            end
        )

        -- =================================================================
        -- MODE 3: 3. CLEAR (Automatic Break All ON/OFF Button Same)
        -- =================================================================
        local ClearCard = c:Card("Mode 3: CLEAR World (Auto Break All)", "MODE 3", "Target", {
            Subtitle = "Automatic Break All blocks di world dengan tombol Start & Stop jadi satu"
        })
        FarmCenterCards.Clear = ClearCard

        ClearCard:Dropdown("Target Layer Clear", "ClearLayerMode", {
            "All Blocks (FG + BG)",
            "Foreground Blocks Only",
            "Background Tiles Only"
        }, "All Blocks (FG + BG)", function(mode)
            State.ClearLayerMode = mode
        end)

        ClearCard:Toggle("Skip Bedrock & Main Door Safely", "ClearSkipBedrock", true, function(on)
            State.ClearSkipBedrock = on
        end)

        ClearCard:Slider("Clear Break Delay", "ClearDelayMs", 50, 400, 140, " ms", function(val)
            State.ClearDelayMs = val
        end)

        ClearStartStopCtrl = CreateUnifiedStartStopButton(
            ClearCard,
            "START AUTO BREAK ALL (CLEAR)",
            "STOP AUTO BREAK ALL (RUNNING)",
            "Target",
            function(running)
                State.ClearRunning = running
                if running then
                    if BasicStartStopCtrl then BasicStartStopCtrl.SetState(false, true) end
                    if PabrikStartStopCtrl then PabrikStartStopCtrl.SetState(false, true) end
                    State.BasicRunning = false
                    State.PabrikRunning = false
                end
                SyncAutoCollectGuard()
            end
        )

        -- Terapkan visibilitas awal sesuai mode default ("1. BASIC")
        task.defer(function()
            SwitchAutoFarmMode(State.AutoFarmMode)
        end)
    end),

    -- Panel Kanan Khusus Auto Farm: Menyesuaikan secara dinamis dengan Mode 1 (Grid 6x6), Mode 2 (Pabrik), atau Mode 3 (Clear)
    right = right(function(r)
        -- Card Permanen Kanan: Auto Collect Always ON Radius 4 Monitor
        local CollectGuardCard = r:Card("Auto Collect Guard (Radius 4)", "ALWAYS ON", "Collect", {
            Subtitle = "Otomatis aktif pada Radius 4 tile setiap kali Auto Farm menyala"
        })

        CollectGuardCard:StatRow({
            { Icon = "Collect", Label = "COLLECT RADIUS", Value = "4 Tiles (Locked)" },
            { Icon = "Shield",  Label = "FILTER GEMS/SEED", Value = "Auto Loot ON" }
        })

        -- Card Kanan Mode 1: GRID PLACE 6X6 & SELECT POS
        local BasicGridCard = r:Card("Grid Place 6x6 & Select Pos", "6X6 MATRIX", "Grid", {
            Subtitle = "Pilih posisi tile Place & Break pada matriks 6x6 (Titik tengah = Posisi Player)"
        })
        FarmRightCards.Basic = BasicGridCard

        BasicRightStatLabels = BasicGridCard:StatRow({
            { Icon = "Key",  Label = "TARGET ITEM ID", Value = "ID: " .. tostring(State.BasicItemID) },
            { Icon = "Grid", Label = "SELECTED POS",   Value = "1 Tile Active" }
        })

        if BasicGridCard.TileGrid then
            BasicGridCard:TileGrid("Grid Place 6x6 (Klik Tile untuk Select Pos)", "BasicGridMatrix6x6", 6, 6, function(idx, isSel, allTiles)
                local count = 0
                if type(allTiles) == "table" then
                    for _, v in pairs(allTiles) do
                        if v then count = count + 1 end
                    end
                end
                if BasicRightStatLabels and BasicRightStatLabels[2] then
                    BasicRightStatLabels[2].Text = tostring(count) .. " Tiles Active"
                end
            end)
        end

        -- Card Kanan Mode 2: PABRIK TELEMETRY & POSISI BREAK MONITOR
        local PabrikMonitorCard = r:Card("Pabrik Position & Seed Monitor", "PABRIK LIVE", "Bot", {
            Subtitle = "Ringkasan koordinat X, Y Break, ID Seed & siklus tanam Pabrik"
        })
        FarmRightCards.Pabrik = PabrikMonitorCard

        PabrikRightStatLabels = PabrikMonitorCard:StatRow({
            { Icon = "Teleports", Label = "BREAK POS (X, Y)", Value = string.format("X: %s | Y: %s", State.PabrikBreakX, State.PabrikBreakY) },
            { Icon = "Bot",       Label = "SEED ID TARGET",   Value = "Seed #" .. tostring(State.PabrikSeedID) }
        })

        PabrikMonitorCard:StatRow({
            { Icon = "Grid",    Label = "RADIUS / TOTAL", Value = tostring(State.PabrikRadiusOrTotal) .. " Tiles/Seeds" },
            { Icon = "Collect", Label = "AUTO COLLECT",   Value = "ON (Radius 4)" }
        })

        -- Card Kanan Mode 3: CLEAR WORLD PROGRESS MONITOR
        local ClearMonitorCard = r:Card("Clear World Telemetry", "CLEAR LIVE", "Target", {
            Subtitle = "Status pembersihan blok world secara otomatis & Auto Collect Radius 4"
        })
        FarmRightCards.Clear = ClearMonitorCard

        ClearRightStatLabels = ClearMonitorCard:StatRow({
            { Icon = "Target",  Label = "CLEARED BLOCKS", Value = "0 Blocks" },
            { Icon = "Collect", Label = "AUTO COLLECT",   Value = "ON (Radius 4)" }
        })

        task.defer(function()
            SwitchAutoFarmMode(State.AutoFarmMode)
        end)
    end)
}

-- =====================================================================
-- KATEGORI 4: FITUR SPAM CHAT (INPUT MESSAGE, COLOR/PREFIX, DELAY, 1-BUTTON START/STOP)
-- =====================================================================
local SpamPreviewStatLabels = nil
local SpamCounterStatLabels = nil
local SpamStartStopCtrl = nil

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

local function BuildFormattedSpamText()
    local rawMsg = State.SpamMessage or ""
    local prefixCmd = ""
    if State.SpamChannelPrefix == "/sb (Super Broadcast)" then
        prefixCmd = "/sb "
    elseif State.SpamChannelPrefix == "/b (Broadcast)" then
        prefixCmd = "/b "
    elseif State.SpamChannelPrefix == "/me (Action)" then
        prefixCmd = "/me "
    end

    local colorTag = ""
    if State.SpamAutoPrefix then
        if State.SpamColorChoice == "Rainbow Auto-Cycle" then
            colorTag = RainbowCodes[RainbowIndex] or "`2"
            RainbowIndex = (RainbowIndex % #RainbowCodes) + 1
        else
            colorTag = ColorPrefixMap[State.SpamColorChoice] or "`2"
        end
    end

    local finalMsg = prefixCmd .. colorTag .. rawMsg
    State.LastSpamPreview = finalMsg
    if SpamPreviewStatLabels and SpamPreviewStatLabels[1] then
        SpamPreviewStatLabels[1].Text = finalMsg
    end
    return finalMsg
end

local function SendChatMessage(msg)
    pcall(function()
        if TextChatService and TextChatService.ChatInputBarConfiguration and TextChatService.ChatInputBarConfiguration.TargetTextChannel then
            TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(msg)
            return
        end
        local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
            chatEvents.SayMessageRequest:FireServer(msg, "All")
        end
    end)
end

feature("Chat", "Spam Chat"){
    center = center(function(c)
        c:Header("Fitur Spam Chat", "Input text message, selector auto prefix priority / color, delay setup & 1-button Start/Stop", "Spammer")

        -- Card 1: Input Text Message & Selector Auto Prefix Priority / Color
        local MsgCard = c:Card("Message & Color / Prefix Selector", "CONFIG", "Chat", {
            Subtitle = "Atur pesan teks, prioritas prefix otomatis, serta kode warna chat"
        })

        MsgCard:Input("Input Text Message", "SpamMessageInput", "Ketik pesan spam chat di sini...", State.SpamMessage, function(txt)
            State.SpamMessage = txt
            BuildFormattedSpamText()
        end)

        MsgCard:Toggle("Auto Prefix Priority (Aktifkan Warna / Prefix)", "SpamAutoPrefixToggle", true, function(on)
            State.SpamAutoPrefix = on
            BuildFormattedSpamText()
        end)

        MsgCard:Dropdown("Selector Auto Prefix Priority / Select Color", "SpamColorSelect", {
            "`2 Green (Priority)",
            "`4 Red (Alert)",
            "`9 Yellow (Gold)",
            "`b Cyan (Aqua)",
            "`# Purple (Broadcast)",
            "`^ Orange (Warm)",
            "`0 White (Bright)",
            "`6 Pink (Rose)",
            "Rainbow Auto-Cycle",
            "None (Normal)"
        }, "`2 Green (Priority)", function(choice)
            State.SpamColorChoice = choice
            BuildFormattedSpamText()
        end)

        MsgCard:Dropdown("Channel / Command Prefix", "SpamChannelSelect", {
            "Normal Chat",
            "/sb (Super Broadcast)",
            "/b (Broadcast)",
            "/me (Action)"
        }, "Normal Chat", function(chan)
            State.SpamChannelPrefix = chan
            BuildFormattedSpamText()
        end)

        -- Card 2: Delay Setup & 1-Button Start/Stop
        local DelayCard = c:Card("Delay Setup & Start/Stop Control", "TIMING", "Clock", {
            Subtitle = "Atur jeda pengiriman pesan (ms / detik) dan jalankan dengan 1 tombol Start/Stop"
        })

        DelayCard:Slider("Delay Setup (Milliseconds)", "SpamDelayMsSlider", 1000, 30000, 4500, " ms", function(val)
            State.SpamDelayMs = val
            if SpamCounterStatLabels and SpamCounterStatLabels[2] then
                SpamCounterStatLabels[2].Text = string.format("%.1f Detik (%d ms)", val / 1000, val)
            end
        end)

        SpamStartStopCtrl = CreateUnifiedStartStopButton(
            DelayCard,
            "START SPAM CHAT",
            "STOP SPAM CHAT (RUNNING)",
            "Chat",
            function(running)
                State.SpamRunning = running
                if SpamPreviewStatLabels and SpamPreviewStatLabels[2] then
                    SpamPreviewStatLabels[2].Text = running and "RUNNING [1]" or "STOPPED [0]"
                end
            end
        )
    end),

    -- Panel Kanan Khusus Fitur Spam Chat: Live Format Preview & Statistik Pengiriman
    right = right(function(r)
        local PreviewCard = r:Card("Live Spam Chat Preview", "PREVIEW", "Chat", {
            Subtitle = "Pratinjau teks beserta kode prefix/warna yang akan dikirim"
        })

        SpamPreviewStatLabels = PreviewCard:StatRow({
            { Icon = "Chat", Label = "OUTPUT MESSAGE", Value = State.LastSpamPreview },
            { Icon = "Bolt", Label = "SPAM STATUS",    Value = "STOPPED [0]" }
        })

        SpamCounterStatLabels = PreviewCard:StatRow({
            { Icon = "Check", Label = "TOTAL SENT",  Value = "0 Messages" },
            { Icon = "Clock", Label = "DELAY SETUP", Value = "4.5 Detik (4500 ms)" }
        })

        PreviewCard:Button("Test Kirim 1 Pesan Sekarang", "SEND 1X", "Chat", function()
            local msg = BuildFormattedSpamText()
            SendChatMessage(msg)
            State.SpamSentCount = State.SpamSentCount + 1
            if SpamCounterStatLabels and SpamCounterStatLabels[1] then
                SpamCounterStatLabels[1].Text = tostring(State.SpamSentCount) .. " Messages"
            end
        end)

        PreviewCard:Button("Copy Formatted Text", "COPY TEXT", "Check", function()
            CopyToClipboard(BuildFormattedSpamText())
        end)
    end)
}

-- =====================================================================
-- KATEGORI 5: UI SETTINGS & THEME (SAMA SEPERTI SAMPLEGUI.LUA)
-- =====================================================================
if UI.Category then UI.Category("Preferences") end

feature("Sliders", "UI Settings"){
    center = center(function(c)
        c:Header("UI Settings & Theme", "Customize R&8_DV colour palette, switch style (0/1), scale & keybind", "v5.4")

        local ThemeCard = c:Card("Theme & Checklist Style", nil, "Palette", {
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
    end),

    right = right(function(r)
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
        if LayoutCard.Keybind then
            LayoutCard:Keybind("Toggle Menu Key", "MenuHotkey", Enum.KeyCode.RightShift, function(newKey)
                if newKey then
                    UI.ToggleKey = newKey
                end
            end)
        end
        LayoutCard:Button("Minimize to Popup Icon", "HIDE", "Minimize", function()
            UI:MinimizeToIcon()
        end)
    end)
}

-- =====================================================================
-- BACKGROUND LOOPS (LIVE POSITION, MISC PHYSICS, AUTO FARM & SPAM CHAT)
-- =====================================================================

-- 1. Physics Loop (NoClip & ModFly & GodMode)
RunService.Stepped:Connect(function()
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    if not char then return end

    if State.NoClip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if State.GodMode then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end
end)

-- 2. ModFly Infinite Air Jump / Float Support
UserInputService.JumpRequest:Connect(function()
    if State.ModFly then
        local lp = Players.LocalPlayer
        local char = lp and lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- 3. Live Position, World Info & Auto Farm / Spam Chat Loop
task.spawn(function()
    local lastSpamTick = 0
    local lastFarmTick = 0

    while task.wait(0.2) do
        -- Update Info Position Sekarang (X : Y, Nama Player, Total Player, Nama World)
        ReadLiveWorldAndPosition()
        if MiscPosStatLabels then
            if MiscPosStatLabels[1] then
                MiscPosStatLabels[1].Text = string.format("X: %d | Y: %d", State.PosX, State.PosY)
            end
            if MiscPosStatLabels[2] then
                MiscPosStatLabels[2].Text = tostring(State.TotalPlayers) .. " Players"
            end
        end
        if MiscWorldStatLabels then
            if MiscWorldStatLabels[1] then
                MiscWorldStatLabels[1].Text = State.PlayerName
            end
            if MiscWorldStatLabels[2] then
                MiscWorldStatLabels[2].Text = State.WorldName
            end
        end

        -- Hitung fitur Misc yang aktif (0 - 8)
        if MiscActiveCountLabel then
            local activeCount = 0
            for _, flagVal in ipairs({
                State.ModFly, State.NoClip, State.FastRoulette, State.FastWrench,
                State.GodMode, State.SpeedOn, State.HighJumpOn, State.AntiGravity
            }) do
                if flagVal then activeCount = activeCount + 1 end
            end
            if MiscActiveCountLabel[1] then
                MiscActiveCountLabel[1].Text = string.format("%d / 8 ON", activeCount)
            end
            if MiscActiveCountLabel[2] then
                MiscActiveCountLabel[2].Text = State.GodMode and "GOD MODE [1]" or "STANDBY [0]"
            end
        end

        local now = os.clock()

        -- Eksekusi Siklus Auto Farm + Auto Collect Always ON (Radius 4)
        if State.BasicRunning or State.PabrikRunning or State.ClearRunning then
            State.AutoCollectAlwaysOn = true
            State.AutoCollectRadius = 4

            local activeDelay = (State.BasicRunning and State.BasicSpeedMs)
                or (State.ClearRunning and State.ClearDelayMs)
                or 160

            if (now - lastFarmTick) * 1000 >= activeDelay then
                lastFarmTick = now
                if State.BasicRunning then
                    State.BasicCycles = State.BasicCycles + 1
                elseif State.PabrikRunning then
                    State.PabrikCycles = State.PabrikCycles + 1
                elseif State.ClearRunning then
                    State.ClearedCount = State.ClearedCount + 1
                    if ClearRightStatLabels and ClearRightStatLabels[1] then
                        ClearRightStatLabels[1].Text = tostring(State.ClearedCount) .. " Blocks"
                    end
                end
            end
        end

        -- Eksekusi Siklus Spam Chat
        if State.SpamRunning then
            if (now - lastSpamTick) * 1000 >= State.SpamDelayMs then
                lastSpamTick = now
                local formatted = BuildFormattedSpamText()
                SendChatMessage(formatted)
                State.SpamSentCount = State.SpamSentCount + 1
                if SpamCounterStatLabels and SpamCounterStatLabels[1] then
                    SpamCounterStatLabels[1].Text = tostring(State.SpamSentCount) .. " Messages"
                end
            end
        end
    end
end)
