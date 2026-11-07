-- File: ui_frontend.lua
-- Architecture: R&8_DV ImGui v5.4 3-Panel Responsive Canvas (Identical Theme & Layout to r8g.lua)
-- Focus Lock: Modal Input Shield + Non-Menu Button Lock when menu is open or focused

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Retrieve Linked Core Backend
local Backend = (getgenv and getgenv().C8_FUNC) or _G.C8_FUNC
assert(type(Backend) == "table", "[SYPHUS_R8G_UI] Core Backend (C8_FUNC) belum dimuat! Jalankan melalui loader.lua.")

local State = Backend.State
local ItemDatabase = Backend.State.ItemDB.Registry

-- // =========================================================================
-- // 1. LOAD FRAMEWORK R&8_DV VIA GITHUB RAW (IDENTIK DENGAN R8G.LUA)
-- // =========================================================================
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r%268_dv.lua"
local okFetch, rawScript = pcall(function()
    return game:HttpGet(GITHUB_RAW_URL)
end)
if not okFetch or type(rawScript) ~= "string" or #rawScript < 128 or string.sub(rawScript, 1, 4) == "404:" then
    okFetch, rawScript = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/r8_dv.lua")
    end)
end
assert(okFetch and type(rawScript) == "string" and #rawScript > 128, "[R&8_DV] Pastikan koneksi ke r&8_dv.lua tersedia.")

-- Expose Frame/Container on CreateCanvasBuilder so dynamic mode cards & custom item rows work seamlessly
rawScript = string.gsub(
    rawScript,
    "local Builder = {}",
    "local Builder = { Frame = scrollingPage, Container = scrollingPage }",
    1
)

local ImGui = loadstring(rawScript)()

-- // =========================================================================
-- // 2. INISIALISASI JENDELA R&8_DV (3-PANEL CANVAS LAYOUT SAMA PERSIS R8G.LUA)
-- // =========================================================================
local UI = ImGui({
    Title = "SYPHUS_HUB // R&8_DV MASTER SUITE",
    BrandTitle = "R&8_DV",
    BrandSubtitle = "GAR x SKYP SUITE",
    Theme = "Minimalist Monochrome",
    CheckBoxStyle = "Modern",
    LetterSpacing = 1,
    AutoLoading = false
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

-- // =========================================================================
-- // 3. FOCUS SHIELD: TOMBOL SELAIN MENU TIDAK BISA DITEKAN SAAT MENU AKTIF
-- // =========================================================================
local function InstallModalFocusBlocker()
    pcall(function()
        Backend:SetMenuFocusLock(true)

        -- Attach a full-screen Modal TextButton behind the R&8_DV canvas inside its ScreenGui
        local roots = {
            (gethui and gethui()) or nil,
            CoreGui,
            LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        }
        for _, parentContainer in pairs(roots) do
            if typeof(parentContainer) == "Instance" then
                for _, gui in ipairs(parentContainer:GetChildren()) do
                    if gui:IsA("ScreenGui") and (string.find(gui.Name, "R8") or string.find(gui.Name, "R&8") or string.find(gui.Name, "ImGui")) then
                        gui.DisplayOrder = 2147483647
                        if not gui:FindFirstChild("C8_ModalInputBlocker") then
                            local blocker = Instance.new("TextButton")
                            blocker.Name = "C8_ModalInputBlocker"
                            blocker.Size = UDim2.fromScale(1, 1)
                            blocker.Position = UDim2.fromScale(0, 0)
                            blocker.BackgroundTransparency = 1
                            blocker.Text = ""
                            blocker.Modal = true
                            blocker.Active = true
                            blocker.Selectable = false
                            blocker.AutoButtonColor = false
                            blocker.ZIndex = -999
                            blocker.Parent = gui
                        end
                    end
                end
            end
        end
    end)
end
task.defer(InstallModalFocusBlocker)

-- // =========================================================================
-- // 4. HELPER UI: 1-BUTTON START/STOP & ITEM ICON RENDERER (SAMA PERSIS R8G.LUA)
-- // =========================================================================
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
            btnBadgeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        if btnBadgeFrame then
            btnBadgeFrame.BackgroundColor3 = isRunning and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
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

    local InnerBlock = Instance.new("Frame")
    InnerBlock.Size = UDim2.new(0.72, 0, 0.72, 0)
    InnerBlock.Position = UDim2.fromScale(0.5, 0.5)
    InnerBlock.AnchorPoint = Vector2.new(0.5, 0.5)
    InnerBlock.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InnerBlock.BackgroundTransparency = 0.82
    InnerBlock.BorderSizePixel = 0
    InnerBlock.Parent = IconContainer
    Instance.new("UICorner", InnerBlock).CornerRadius = UDim.new(0, 6)

    local AssetImg = Instance.new("ImageLabel")
    AssetImg.Size = UDim2.new(0.62, 0, 0.62, 0)
    AssetImg.Position = UDim2.fromScale(0.5, 0.45)
    AssetImg.AnchorPoint = Vector2.new(0.5, 0.5)
    AssetImg.BackgroundTransparency = 1
    AssetImg.Image = itemData.IconAsset or "rbxassetid://6031265976"
    AssetImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
    AssetImg.Parent = IconContainer

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
    Instance.new("UICorner", IdBadge).CornerRadius = UDim.new(0, 4)

    return IconContainer, AssetImg, IdBadge
end

-- // =========================================================================
-- // KATEGORI 1: FITUR MISC & LIVE POSITION INFO
-- // =========================================================================
if UI.Category then UI.Category("Main Modules") end

local MiscPosStatLabels = nil
local MiscWorldStatLabels = nil
local MiscActiveCountLabel = nil

feature("Misc", "Fitur Misc"){
    center = center(function(c)
        c:Header("Fitur Misc & Movement", "Toggle character modifiers (ON/OFF), Focus Lock & fast interaction utilities", "Misc [0/1]")

        local MoveModCard = c:Card("Movement & Physics (ON / OFF)", "6 MODS", "Speed", {
            Subtitle = "ModFly, NoClip, Speed, High Jump, AntiGravity & Non-Menu Button Lock"
        })

        MoveModCard:Toggle("Lock Non-Menu Buttons When Focused", "MiscFocusShield", true, function(on)
            State.FocusShieldActive = on
            Backend:SetMenuFocusLock(on)
        end)

        MoveModCard:Toggle("ModFly (Fly Anywhere)", "MiscModFly", false, function(on)
            Backend:SetModFly(on)
        end)

        MoveModCard:Toggle("NoClip (Walk Through Blocks)", "MiscNoClip", false, function(on)
            Backend:SetNoClip(on)
        end)

        MoveModCard:Toggle("Speed (Movement Boost ON/OFF)", "MiscSpeedOn", false, function(on)
            Backend:SetSpeed(on, State.Misc.SpeedVal)
        end)

        MoveModCard:Slider("Speed Value", "MiscSpeedVal", 16, 250, 60, " ws", function(val)
            Backend:SetSpeed(State.Misc.SpeedOn, val)
        end)

        MoveModCard:Toggle("High Jump (Jump Boost ON/OFF)", "MiscHighJumpOn", false, function(on)
            Backend:SetHighJump(on, State.Misc.JumpVal)
        end)

        MoveModCard:Slider("High Jump Power", "MiscJumpVal", 50, 350, 120, " jp", function(val)
            Backend:SetHighJump(State.Misc.HighJumpOn, val)
        end)

        MoveModCard:Toggle("AntiGravity (Zero / Low Gravity)", "MiscAntiGravity", false, function(on)
            Backend:SetAntiGravity(on)
        end)

        local ActionModCard = c:Card("Fast Utility & God Mode (ON / OFF)", "4 MODS", "Shield", {
            Subtitle = "Fast Roulette, Fast Wrench, Anti Take Item & God Mode hazard immunity"
        })

        ActionModCard:Toggle("Fast Roulette (Instant Wheel Result)", "MiscFastRoulette", false, function(on)
            Backend:SetFastRoulette(on)
        end)

        ActionModCard:Toggle("Fast Wrench (Instant Player Action)", "MiscFastWrench", false, function(on)
            Backend:SetFastWrench(on, State.Misc.WrenchMode)
        end)

        ActionModCard:Dropdown("Fast Wrench Action Mode", "MiscWrenchMode", {
            "Pull (/pull)",
            "Kick (/kick)",
            "Ban (/ban)",
            "Trade (/trade)",
            "View Inventory"
        }, "Pull (/pull)", function(mode)
            Backend:SetFastWrench(State.Misc.FastWrench, mode)
        end)

        ActionModCard:Toggle("God Mode (Anti-Hazard / Spike / Lava)", "MiscGodMode", false, function(on)
            Backend:SetGodMode(on)
        end)

        ActionModCard:Toggle("Anti Take Item (Ignore Loose Loot)", "MiscAntiTake", false, function(on)
            State.Misc.AntiTakeItem = on
        end)
    end),

    right = right(function(r)
        local tele = Backend:ReadLiveWorldAndPosition()

        local PosInfoCard = r:Card("Info Position Sekarang", "LIVE", "Player", {
            Subtitle = "Koordinat X : Y real-time, arah hadap, identitas player & world"
        })

        MiscPosStatLabels = PosInfoCard:StatRow({
            { Icon = "Teleports", Label = "X : Y POSITION", Value = string.format("X: %d | Y: %d", tele.X, tele.Y) },
            { Icon = "Player",    Label = "TOTAL PLAYER",   Value = tostring(tele.TotalPlayers) .. " Players" }
        })

        MiscWorldStatLabels = PosInfoCard:StatRow({
            { Icon = "User",      Label = "NAMA PLAYER",    Value = tele.PlayerName },
            { Icon = "Home",      Label = "NAMA WORLD",     Value = tele.WorldName }
        })

        PosInfoCard:Button("Copy Posisi Sekarang (X : Y)", "COPY POS", "Teleports", function()
            local info = Backend:ReadLiveWorldAndPosition()
            Backend:CopyToClipboard(string.format("X: %d, Y: %d (World: %s)", info.X, info.Y, info.WorldName))
        end)

        PosInfoCard:Button("Kirim X, Y ke Auto Farm (Basic & Pabrik)", "SET POS", "Bot", function()
            local info = Backend:ReadLiveWorldAndPosition()
            State.AutoFarm.Basic.SelectPos = { X = info.X, Y = info.Y }
            State.AutoFarm.Pabrik.BreakX = info.X
            State.AutoFarm.Pabrik.BreakY = info.Y
            if UI.SetValue then
                UI:SetValue("PabrikBreakX", tostring(info.X))
                UI:SetValue("PabrikBreakY", tostring(info.Y))
            end
        end)

        local QuickSummaryCard = r:Card("Status Fitur Misc", "MONITOR", "Bolt", {
            Subtitle = "Ringkasan modul Misc yang sedang aktif [1 = ON / 0 = OFF]"
        })

        MiscActiveCountLabel = QuickSummaryCard:StatRow({
            { Icon = "Bolt",   Label = "ACTIVE MODS", Value = "0 / 8 ON" },
            { Icon = "Shield", Label = "FOCUS LOCK",  Value = "LOCKED [1]" }
        })

        QuickSummaryCard:Button("Matikan Semua Fitur Misc (Reset 0)", "RESET ALL", "Close", function()
            for _, f in ipairs({
                "MiscModFly", "MiscNoClip", "MiscFastRoulette", "MiscFastWrench",
                "MiscGodMode", "MiscSpeedOn", "MiscHighJumpOn", "MiscAntiGravity"
            }) do
                if UI.SetValue then UI:SetValue(f, false) end
            end
            Backend:SetModFly(false)
            Backend:SetNoClip(false)
            Backend:SetFastRoulette(false)
            Backend:SetFastWrench(false)
            Backend:SetGodMode(false)
            Backend:SetSpeed(false, State.Misc.SpeedVal)
            Backend:SetHighJump(false, State.Misc.JumpVal)
            Backend:SetAntiGravity(false)
        end)
    end)
}

-- // =========================================================================
-- // KATEGORI 2: FITUR ITEM INFO (SEARCH BAR, ASSET CARDS, INSPECTOR)
-- // =========================================================================
local SelectedItem = State.ItemDB.SelectedItem or ItemDatabase[1]
local ItemDetailRefs = {}
local ItemEntryCards = {}
local CurrentItemSearch = ""
local CurrentItemCategory = "All Categories"

local function RefreshSelectedItemInspector(item)
    if not item then return end
    SelectedItem = item
    State.ItemDB.SelectedItem = item

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
        if entry.Frame then entry.Frame.Visible = show end
        if show then visibleCount += 1 end
    end

    if ItemDetailRefs.CountStat and ItemDetailRefs.CountStat[1] then
        ItemDetailRefs.CountStat[1].Text = string.format("%d / %d Items", visibleCount, #ItemDatabase)
    end
end

feature("Visuals", "Item Info"){
    center = center(function(c)
        c:Header("Fitur Item Info & Database", "Real Shared.ItemDB explorer, Asset Icon renderer & Copy ID / Name", "Item DB")

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

        local ListCard = c:Card("Card All Item List", tostring(#ItemDatabase) .. " ITEMS", "Grid", {
            Subtitle = "Klik DETAIL untuk inspeksi penuh di panel kanan atau langsung COPY ID / NAME"
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
            Instance.new("UICorner", ItemRow).CornerRadius = UDim.new(0, 10)

            local RowStroke = Instance.new("UIStroke", ItemRow)
            RowStroke.Color = Color3.fromRGB(60, 68, 88)
            RowStroke.Transparency = 0.35
            RowStroke.Thickness = 1

            local iconBox = BuildVisualItemIcon(ItemRow, item, 58)
            iconBox.Position = UDim2.new(0, 14, 0.5, 0)
            iconBox.AnchorPoint = Vector2.new(0, 0.5)

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
            Instance.new("UICorner", BtnInspect).CornerRadius = UDim.new(0, 6)

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
            Instance.new("UICorner", BtnCopyID).CornerRadius = UDim.new(0, 6)

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
            Instance.new("UICorner", BtnCopyName).CornerRadius = UDim.new(0, 6)

            local function SelectThisItem()
                RefreshSelectedItemInspector(item)
                if ItemDetailRefs.CountStat and ItemDetailRefs.CountStat[2] then
                    ItemDetailRefs.CountStat[2].Text = "#" .. tostring(item.ID) .. " " .. item.Name
                end
            end

            BtnInspect.MouseButton1Click:Connect(SelectThisItem)
            BtnCopyID.MouseButton1Click:Connect(function()
                SelectThisItem()
                Backend:CopyToClipboard(tostring(item.ID))
                BtnCopyID.Text = "COPIED!"
                task.delay(0.8, function()
                    if BtnCopyID and BtnCopyID.Parent then BtnCopyID.Text = "COPY ID" end
                end)
            end)
            BtnCopyName.MouseButton1Click:Connect(function()
                SelectThisItem()
                Backend:CopyToClipboard(item.Name)
                BtnCopyName.Text = "COPIED NAME!"
                task.delay(0.8, function()
                    if BtnCopyName and BtnCopyName.Parent then BtnCopyName.Text = "COPY NAME" end
                end)
            end)

            table.insert(ItemEntryCards, { Data = item, Frame = ItemRow })
        end
    end),

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
            Instance.new("UICorner", HeroBanner).CornerRadius = UDim.new(0, 10)

            local HeroStroke = Instance.new("UIStroke", HeroBanner)
            HeroStroke.Color = Color3.fromRGB(70, 80, 105)
            HeroStroke.Transparency = 0.3

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
            Backend:CopyToClipboard(tostring(SelectedItem.ID))
        end)

        CopyCard:Button("Copy Item Name", "COPY NAME", "Chat", function()
            Backend:CopyToClipboard(tostring(SelectedItem.Name))
        end)

        CopyCard:Button("Copy Seed ID (ID + 1)", "SEED ID", "Bot", function()
            Backend:CopyToClipboard(tostring(SelectedItem.SeedID or (SelectedItem.ID + 1)))
        end)

        CopyCard:Button("Gunakan Item Ini di Semua Mode Auto Farm", "SEND TO FARM", "Bolt", function()
            local blkId = tonumber(SelectedItem.ID) or 4584
            local seedId = tonumber(SelectedItem.SeedID) or (blkId + 1)
            State.AutoFarm.Basic.ItemID = blkId
            State.AutoFarm.Pabrik.SeedID = seedId
            State.AutoFarm.TeinPNB.BlockID = blkId
            State.AutoFarm.LavaFarm.BlockID = blkId
            State.AutoFarm.LavaFarm.SeedID = seedId
            if UI.SetValue then
                UI:SetValue("BasicItemID", tostring(blkId))
                UI:SetValue("PabrikSeedID", tostring(seedId))
                UI:SetValue("TeinBlockID", tostring(blkId))
            end
        end)
    end)
}

-- // =========================================================================
-- // KATEGORI 3: FITUR AUTO FARM (6 MODE DINAMIS GAR + R8G + COLLECT RAD 4)
-- // =========================================================================
local FarmCenterCards = {}
local FarmRightCards = {}
local FarmStatusLabels = nil
local BasicRightStatLabels = nil
local PabrikRightStatLabels = nil
local ClearRightStatLabels = nil
local TeinRightStatLabels = nil
local LavaRightStatLabels = nil
local AutoDFRightStatLabels = nil

local ModeControllers = {}

local function StopOtherFarmControllers(exceptKey)
    for k, ctrl in pairs(ModeControllers) do
        if k ~= exceptKey and ctrl then
            ctrl.SetState(false, true)
        end
    end
end

local function SyncAutoCollectStatus()
    local isRunning = State.AutoFarm.Active
    State.AutoFarm.AutoCollectAlwaysOn = isRunning
    State.AutoFarm.AutoCollectRadius = 4

    if FarmStatusLabels then
        if FarmStatusLabels[1] then
            FarmStatusLabels[1].Text = isRunning and State.AutoFarm.StatusText or "IDLE [0]"
        end
        if FarmStatusLabels[2] then
            FarmStatusLabels[2].Text = isRunning and "ON (RADIUS 4)" or "STANDBY (RAD 4)"
        end
    end
end

local function SwitchAutoFarmMode(modeName)
    State.AutoFarm.Mode = modeName
    local map = {
        ["1. BASIC"]    = "Basic",
        ["2. PABRIK"]   = "Pabrik",
        ["3. CLEAR"]    = "Clear",
        ["4. TEIN PNB"] = "TeinPNB",
        ["5. RYO LAVA"] = "LavaFarm",
        ["6. AUTO-DF"]  = "AutoDF"
    }
    local activeKey = map[modeName] or "Basic"

    for k, card in pairs(FarmCenterCards) do
        if card and card.Frame then
            card.Frame.Visible = (k == activeKey)
        end
    end
    for k, card in pairs(FarmRightCards) do
        if card and card.Frame then
            card.Frame.Visible = (k == activeKey)
        end
    end
end

feature("Bot", "Auto Farm"){
    center = center(function(c)
        c:Header(
            "Fitur Auto Farm (6 Mode GAR + R8G)",
            "Auto Collect ON Always (Radius 4) saat Auto Farm menyala • Pilih Mode untuk input berbeda",
            "Radius 4"
        )

        local ModeSelectorCard = c:Card("Auto Farm Mode & Auto Collect Guard", "6 MODES", "Bot", {
            Subtitle = "Auto Collect otomatis terkunci pada Radius 4 ketika mode Auto Farm dijalankan"
        })

        FarmStatusLabels = ModeSelectorCard:StatRow({
            { Icon = "Bot",     Label = "FARM STATUS",          Value = "IDLE [0]" },
            { Icon = "Collect", Label = "AUTO COLLECT (RAD 4)", Value = "STANDBY (RAD 4)" }
        })

        ModeSelectorCard:Dropdown("Pilih Mode Auto Farm (Beda Pilih Beda Input)", "AutoFarmModeSelect", {
            "1. BASIC",
            "2. PABRIK",
            "3. CLEAR",
            "4. TEIN PNB",
            "5. RYO LAVA",
            "6. AUTO-DF"
        }, "1. BASIC", function(selectedMode)
            SwitchAutoFarmMode(selectedMode)
        end)

        -- MODE 1: BASIC
        local BasicCard = c:Card("Mode 1: BASIC Auto Farm", "MODE 1", "Bolt", {
            Subtitle = "ID Item Input, Hide/No Hand Break Place, Speed Setting & 6x6 Grid Place"
        })
        FarmCenterCards.Basic = BasicCard

        BasicCard:Input("ID Item Input (Block ID)", "BasicItemID", "Masukkan ID Item (contoh: 4584)...", tostring(State.AutoFarm.Basic.ItemID), function(val)
            State.AutoFarm.Basic.ItemID = tonumber(val) or 4584
            if BasicRightStatLabels and BasicRightStatLabels[1] then
                BasicRightStatLabels[1].Text = "ID: " .. tostring(State.AutoFarm.Basic.ItemID)
            end
        end)

        BasicCard:Toggle("Hide / No Hand Animation (Break & Place)", "BasicHideHand", true, function(on)
            State.AutoFarm.Basic.HideHand = on
        end)

        BasicCard:Slider("Speed Setting (Break / Place Delay)", "BasicSpeedMs", 50, 500, 160, " ms", function(val)
            State.AutoFarm.Basic.SpeedMs = val
        end)

        BasicCard:Slider("Hits Per Block", "BasicBlockHits", 1, 12, 4, " hits", function(val)
            State.AutoFarm.Basic.Hits = val
        end)

        ModeControllers.Basic = CreateUnifiedStartStopButton(
            BasicCard,
            "START BASIC AUTO FARM",
            "STOP BASIC AUTO FARM (RUNNING)",
            "Bolt",
            function(running)
                if running then StopOtherFarmControllers("Basic") end
                State.AutoFarm.Mode = "1. BASIC"
                State.AutoFarm.Active = running
                State.AutoFarm.StatusText = running and "BASIC [1]" or "IDLE [0]"
                SyncAutoCollectStatus()
            end
        )

        -- MODE 2: PABRIK
        local PabrikCard = c:Card("Mode 2: PABRIK Auto Farm", "MODE 2", "Grid", {
            Subtitle = "Input Koordinat X, Y Posisi Break, ID Seed, Radius / Total Seed Place"
        })
        FarmCenterCards.Pabrik = PabrikCard

        PabrikCard:Input("Posisi Break X (Tile X)", "PabrikBreakX", "Contoh: 50", tostring(State.AutoFarm.Pabrik.BreakX), function(val)
            State.AutoFarm.Pabrik.BreakX = tonumber(val) or 50
            if PabrikRightStatLabels and PabrikRightStatLabels[1] then
                PabrikRightStatLabels[1].Text = string.format("X: %d | Y: %d", State.AutoFarm.Pabrik.BreakX, State.AutoFarm.Pabrik.BreakY)
            end
        end)

        PabrikCard:Input("Posisi Break Y (Tile Y)", "PabrikBreakY", "Contoh: 23", tostring(State.AutoFarm.Pabrik.BreakY), function(val)
            State.AutoFarm.Pabrik.BreakY = tonumber(val) or 23
            if PabrikRightStatLabels and PabrikRightStatLabels[1] then
                PabrikRightStatLabels[1].Text = string.format("X: %d | Y: %d", State.AutoFarm.Pabrik.BreakX, State.AutoFarm.Pabrik.BreakY)
            end
        end)

        PabrikCard:Button("Ambil X, Y Posisi Player Sekarang", "GET X, Y", "Teleports", function()
            local info = Backend:ReadLiveWorldAndPosition()
            State.AutoFarm.Pabrik.BreakX = info.X
            State.AutoFarm.Pabrik.BreakY = info.Y
            if UI.SetValue then
                UI:SetValue("PabrikBreakX", tostring(info.X))
                UI:SetValue("PabrikBreakY", tostring(info.Y))
            end
            if PabrikRightStatLabels and PabrikRightStatLabels[1] then
                PabrikRightStatLabels[1].Text = string.format("X: %d | Y: %d", info.X, info.Y)
            end
        end)

        PabrikCard:Input("ID Seed Input", "PabrikSeedID", "Contoh: 4585", tostring(State.AutoFarm.Pabrik.SeedID), function(val)
            State.AutoFarm.Pabrik.SeedID = tonumber(val) or 4585
            if PabrikRightStatLabels and PabrikRightStatLabels[2] then
                PabrikRightStatLabels[2].Text = "Seed #" .. tostring(State.AutoFarm.Pabrik.SeedID)
            end
        end)

        PabrikCard:Slider("Radius or Total Seed Place", "PabrikRadiusOrTotal", 1, 100, 4, " tiles", function(val)
            State.AutoFarm.Pabrik.RadiusOrTotal = val
        end)

        ModeControllers.Pabrik = CreateUnifiedStartStopButton(
            PabrikCard,
            "START PABRIK AUTO FARM",
            "STOP PABRIK AUTO FARM (RUNNING)",
            "Bot",
            function(running)
                if running then StopOtherFarmControllers("Pabrik") end
                State.AutoFarm.Mode = "2. PABRIK"
                State.AutoFarm.Active = running
                State.AutoFarm.StatusText = running and "PABRIK [1]" or "IDLE [0]"
                SyncAutoCollectStatus()
            end
        )

        -- MODE 3: CLEAR + AUTO STORAGE DROP
        local ClearCard = c:Card("Mode 3: CLEAR World + Auto Drop", "MODE 3", "Target", {
            Subtitle = "Automatic Break All blocks di world + Multi-World Storage Drop"
        })
        FarmCenterCards.Clear = ClearCard

        ClearCard:Dropdown("Target Layer Clear", "ClearLayerMode", {
            "All Blocks (FG + BG)",
            "Foreground Blocks Only",
            "Background Tiles Only"
        }, "All Blocks (FG + BG)", function(mode)
            State.AutoFarm.Clear.LayerMode = mode
        end)

        ClearCard:Input("Worlds List (Comma Separated)", "ClearWorldsList", "world1,world2", State.AutoFarm.Clear.WorldsList, function(txt)
            State.AutoFarm.Clear.WorldsList = txt
        end)

        ClearCard:Input("Drop Storage World", "ClearDropWorld", "storageworld", State.AutoFarm.Clear.DropWorld, function(txt)
            State.AutoFarm.Clear.DropWorld = txt
        end)

        ClearCard:Toggle("Skip Bedrock (ID 8) & Main Door (ID 6)", "ClearSkipBedrock", true, function(on)
            State.AutoFarm.Clear.SkipBedrock = on
        end)

        ClearCard:Slider("Clear Break Delay", "ClearDelayMs", 50, 400, 140, " ms", function(val)
            State.AutoFarm.Clear.DelayMs = val
        end)

        ModeControllers.Clear = CreateUnifiedStartStopButton(
            ClearCard,
            "START AUTO BREAK ALL (CLEAR)",
            "STOP AUTO BREAK ALL (RUNNING)",
            "Target",
            function(running)
                if running then StopOtherFarmControllers("Clear") end
                State.AutoFarm.Mode = "3. CLEAR"
                State.AutoFarm.Active = running
                State.AutoFarm.StatusText = running and "CLEAR [1]" or "IDLE [0]"
                SyncAutoCollectStatus()
            end
        )

        -- MODE 4: TEIN PNB
        local TeinCard = c:Card("Mode 4: TEIN Facing-Direction PNB", "MODE 4", "Bolt", {
            Subtitle = "Place & Break sejumlah Range Tile di depan arah hadap karakter"
        })
        FarmCenterCards.TeinPNB = TeinCard

        TeinCard:Input("Block ID (Contoh: 340 Chandelier)", "TeinBlockID", "340", tostring(State.AutoFarm.TeinPNB.BlockID), function(txt)
            State.AutoFarm.TeinPNB.BlockID = tonumber(txt) or 340
            if TeinRightStatLabels and TeinRightStatLabels[1] then
                TeinRightStatLabels[1].Text = "Block #" .. tostring(State.AutoFarm.TeinPNB.BlockID)
            end
        end)

        TeinCard:Slider("Range Block Ahead (Tiles)", "TeinRangeTiles", 1, 10, 5, " tiles", function(val)
            State.AutoFarm.TeinPNB.RangeBlock = val
            if TeinRightStatLabels and TeinRightStatLabels[2] then
                TeinRightStatLabels[2].Text = tostring(val) .. " Tiles"
            end
        end)

        TeinCard:Slider("Punch Hit Count", "TeinHitCount", 1, 10, 4, " hits", function(val)
            State.AutoFarm.TeinPNB.HitCount = val
        end)

        TeinCard:Slider("Place / Break Delay", "TeinDelayMs", 50, 350, 110, " ms", function(val)
            State.AutoFarm.TeinPNB.PlaceDelay = val
            State.AutoFarm.TeinPNB.BreakDelay = val
        end)

        ModeControllers.TeinPNB = CreateUnifiedStartStopButton(
            TeinCard,
            "START TEIN PNB AUTO FARM",
            "STOP TEIN PNB (RUNNING)",
            "Bolt",
            function(running)
                if running then StopOtherFarmControllers("TeinPNB") end
                State.AutoFarm.Mode = "4. TEIN PNB"
                State.AutoFarm.Active = running
                State.AutoFarm.StatusText = running and "TEIN PNB [1]" or "IDLE [0]"
                SyncAutoCollectStatus()
            end
        )

        -- MODE 5: RYO LAVA FARM
        local LavaCard = c:Card("Mode 5: RYO Lava Farm (PNB + Plant + Harvest)", "MODE 5", "Bot", {
            Subtitle = "Spread 1/3/5 PNB, Auto Plant 20, Harvest Ready Trees & Drop Extra Seeds"
        })
        FarmCenterCards.LavaFarm = LavaCard

        LavaCard:Input("Farm World (World|DoorID)", "LavaFarmWorld", "LAVAFARM|A1", State.AutoFarm.LavaFarm.FarmWorld, function(txt)
            State.AutoFarm.LavaFarm.FarmWorld = txt
        end)

        LavaCard:Input("Drop Seed World (World|DoorID)", "LavaDropWorld", "LAVADROP|B2", State.AutoFarm.LavaFarm.DropWorld, function(txt)
            State.AutoFarm.LavaFarm.DropWorld = txt
        end)

        LavaCard:Dropdown("Spread Tiles (1 / 3 / 5)", "LavaSpreadSelect", { "1", "3", "5" }, "5", function(opt)
            State.AutoFarm.LavaFarm.SpreadCount = tonumber(opt) or 5
            if LavaRightStatLabels and LavaRightStatLabels[1] then
                LavaRightStatLabels[1].Text = tostring(State.AutoFarm.LavaFarm.SpreadCount) .. " Tiles Spread"
            end
        end)

        LavaCard:Dropdown("Punch Direction", "LavaDirSelect", { "up", "down" }, "up", function(opt)
            State.AutoFarm.LavaFarm.Direction = opt
        end)

        LavaCard:Slider("PNB Delay (ms)", "LavaPnbDelay", 80, 400, 190, " ms", function(val)
            State.AutoFarm.LavaFarm.PnbDelay = val
        end)

        ModeControllers.LavaFarm = CreateUnifiedStartStopButton(
            LavaCard,
            "START RYO LAVA FARM",
            "STOP RYO LAVA FARM (RUNNING)",
            "Bot",
            function(running)
                if running then StopOtherFarmControllers("LavaFarm") end
                State.AutoFarm.Mode = "5. RYO LAVA"
                State.AutoFarm.Active = running
                State.AutoFarm.StatusText = running and "RYO LAVA [1]" or "IDLE [0]"
                SyncAutoCollectStatus()
            end
        )

        -- MODE 6: AUTO-DF BUILDER
        local AutoDFCard = c:Card("Mode 6: Auto-DF Builder & Sustainer", "MODE 6", "Grid", {
            Subtitle = "Full Dirt Farm Builder: Side Tunnels, Platform Ladders, Ground Sweep & Skybuild"
        })
        FarmCenterCards.AutoDF = AutoDFCard

        AutoDFCard:Input("Target DF World", "AutoDFTargetWorld", "NTUUM", State.AutoFarm.AutoDF.TargetWorld, function(txt)
            State.AutoFarm.AutoDF.TargetWorld = txt
            if AutoDFRightStatLabels and AutoDFRightStatLabels[1] then
                AutoDFRightStatLabels[1].Text = txt
            end
        end)

        AutoDFCard:Input("Storage Drop World", "AutoDFDropWorld", "KUALISTORAGE", State.AutoFarm.AutoDF.DropWorld, function(txt)
            State.AutoFarm.AutoDF.DropWorld = txt
            if AutoDFRightStatLabels and AutoDFRightStatLabels[2] then
                AutoDFRightStatLabels[2].Text = txt
            end
        end)

        AutoDFCard:Toggle("Use Signal Jammer (ID 226)", "AutoDFJammer", false, function(on)
            State.AutoFarm.AutoDF.UseJammer = on
        end)

        AutoDFCard:Toggle("Use Wooden Platform Ladders (ID 102)", "AutoDFPlatform", true, function(on)
            State.AutoFarm.AutoDF.UsePlatform = on
        end)

        ModeControllers.AutoDF = CreateUnifiedStartStopButton(
            AutoDFCard,
            "START AUTO-DF BUILDER",
            "STOP AUTO-DF BUILDER (RUNNING)",
            "Grid",
            function(running)
                if running then StopOtherFarmControllers("AutoDF") end
                State.AutoFarm.Mode = "6. AUTO-DF"
                State.AutoFarm.Active = running
                State.AutoFarm.StatusText = running and "AUTO-DF [1]" or "IDLE [0]"
                SyncAutoCollectStatus()
            end
        )

        task.defer(function()
            SwitchAutoFarmMode(State.AutoFarm.Mode)
        end)
    end),

    right = right(function(r)
        local CollectGuardCard = r:Card("Auto Collect Guard (Radius 4)", "ALWAYS ON", "Collect", {
            Subtitle = "Otomatis aktif pada Radius 4 tile setiap kali Auto Farm menyala"
        })

        CollectGuardCard:StatRow({
            { Icon = "Collect", Label = "COLLECT RADIUS",   Value = "4 Tiles (Locked)" },
            { Icon = "Shield",  Label = "SHARED.DROPBOX",   Value = "Auto Loot ON" }
        })

        -- Right Card Mode 1: Basic 6x6 Matrix
        local BasicGridCard = r:Card("Grid Place 6x6 & Select Pos", "6X6 MATRIX", "Grid", {
            Subtitle = "Pilih posisi tile Place & Break pada matriks 6x6"
        })
        FarmRightCards.Basic = BasicGridCard

        BasicRightStatLabels = BasicGridCard:StatRow({
            { Icon = "Key",  Label = "TARGET ITEM ID", Value = "ID: " .. tostring(State.AutoFarm.Basic.ItemID) },
            { Icon = "Grid", Label = "SELECTED POS",   Value = "1 Tile Active" }
        })

        if BasicGridCard.TileGrid then
            BasicGridCard:TileGrid("Grid Place 6x6 (Klik Tile untuk Select Pos)", "BasicGridMatrix6x6", 6, 6, function(idx, isSel, allTiles)
                State.AutoFarm.Basic.SelectedTiles = allTiles or {}
                local count = 0
                if type(allTiles) == "table" then
                    for _, v in pairs(allTiles) do
                        if v then count += 1 end
                    end
                end
                if BasicRightStatLabels and BasicRightStatLabels[2] then
                    BasicRightStatLabels[2].Text = tostring(count) .. " Tiles Active"
                end
            end)
        end

        -- Right Card Mode 2: Pabrik
        local PabrikMonitorCard = r:Card("Pabrik Position & Seed Monitor", "PABRIK LIVE", "Bot", {
            Subtitle = "Ringkasan koordinat X, Y Break, ID Seed & siklus tanam Pabrik"
        })
        FarmRightCards.Pabrik = PabrikMonitorCard

        PabrikRightStatLabels = PabrikMonitorCard:StatRow({
            { Icon = "Teleports", Label = "BREAK POS (X, Y)", Value = string.format("X: %d | Y: %d", State.AutoFarm.Pabrik.BreakX, State.AutoFarm.Pabrik.BreakY) },
            { Icon = "Bot",       Label = "SEED ID TARGET",   Value = "Seed #" .. tostring(State.AutoFarm.Pabrik.SeedID) }
        })

        -- Right Card Mode 3: Clear
        local ClearMonitorCard = r:Card("Clear World Telemetry", "CLEAR LIVE", "Target", {
            Subtitle = "Status pembersihan blok world secara otomatis & Auto Collect Radius 4"
        })
        FarmRightCards.Clear = ClearMonitorCard

        ClearRightStatLabels = ClearMonitorCard:StatRow({
            { Icon = "Target",  Label = "CLEARED BLOCKS", Value = "0 Blocks" },
            { Icon = "Collect", Label = "AUTO COLLECT",   Value = "ON (Radius 4)" }
        })

        -- Right Card Mode 4: Tein PNB
        local TeinMonitorCard = r:Card("Tein PNB Telemetry", "TEIN LIVE", "Bolt", {
            Subtitle = "Monitor arah hadap karakter & jangkauan tile Tein PNB"
        })
        FarmRightCards.TeinPNB = TeinMonitorCard

        TeinRightStatLabels = TeinMonitorCard:StatRow({
            { Icon = "Key",  Label = "TARGET BLOCK", Value = "Block #" .. tostring(State.AutoFarm.TeinPNB.BlockID) },
            { Icon = "Bolt", Label = "RANGE AHEAD",  Value = tostring(State.AutoFarm.TeinPNB.RangeBlock) .. " Tiles" }
        })

        -- Right Card Mode 5: Ryo Lava
        local LavaMonitorCard = r:Card("Ryo Lava Farm Telemetry", "LAVA LIVE", "Bot", {
            Subtitle = "Monitor Spread PNB, Plant Max 20 & Seed Drop"
        })
        FarmRightCards.LavaFarm = LavaMonitorCard

        LavaRightStatLabels = LavaMonitorCard:StatRow({
            { Icon = "Grid",    Label = "SPREAD MODE",  Value = tostring(State.AutoFarm.LavaFarm.SpreadCount) .. " Tiles Spread" },
            { Icon = "Collect", Label = "AUTO COLLECT", Value = "ON (Radius 4)" }
        })

        -- Right Card Mode 6: Auto-DF
        local AutoDFMonitorCard = r:Card("Auto-DF Sustainer Telemetry", "AUTO-DF LIVE", "Grid", {
            Subtitle = "Monitor world target, storage drop & ladder builder"
        })
        FarmRightCards.AutoDF = AutoDFMonitorCard

        AutoDFRightStatLabels = AutoDFMonitorCard:StatRow({
            { Icon = "Home",      Label = "TARGET WORLD", Value = State.AutoFarm.AutoDF.TargetWorld },
            { Icon = "Teleports", Label = "STORAGE DROP", Value = State.AutoFarm.AutoDF.DropWorld }
        })

        task.defer(function()
            SwitchAutoFarmMode(State.AutoFarm.Mode)
        end)
    end)
}

-- // =========================================================================
-- // KATEGORI 4: FITUR SPAM CHAT & CLIENT VISUAL SPOOFER
-- // =========================================================================
local SpamPreviewStatLabels = nil
local SpamCounterStatLabels = nil

feature("Chat", "Spam Chat & Visual"){
    center = center(function(c)
        c:Header("Fitur Spam Chat & Visual Spoofer", "Auto prefix/color chat broadcaster & Client Visual Identity Spoofer", "Chat & Spoof")

        local MsgCard = c:Card("Message & Color / Prefix Selector", "CONFIG", "Chat", {
            Subtitle = "Atur pesan teks, prioritas prefix otomatis, serta kode warna chat"
        })

        MsgCard:Input("Input Text Message", "SpamMessageInput", "Ketik pesan spam chat di sini...", State.SpamChat.Message, function(txt)
            State.SpamChat.Message = txt
            local prev = Backend:BuildFormattedSpamText()
            if SpamPreviewStatLabels and SpamPreviewStatLabels[1] then
                SpamPreviewStatLabels[1].Text = prev
            end
        end)

        MsgCard:Toggle("Auto Prefix Priority (Aktifkan Warna / Prefix)", "SpamAutoPrefixToggle", true, function(on)
            State.SpamChat.AutoPrefix = on
            local prev = Backend:BuildFormattedSpamText()
            if SpamPreviewStatLabels and SpamPreviewStatLabels[1] then
                SpamPreviewStatLabels[1].Text = prev
            end
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
            State.SpamChat.ColorChoice = choice
            local prev = Backend:BuildFormattedSpamText()
            if SpamPreviewStatLabels and SpamPreviewStatLabels[1] then
                SpamPreviewStatLabels[1].Text = prev
            end
        end)

        MsgCard:Dropdown("Channel / Command Prefix", "SpamChannelSelect", {
            "Normal Chat",
            "/sb (Super Broadcast)",
            "/b (Broadcast)",
            "/me (Action)"
        }, "Normal Chat", function(chan)
            State.SpamChat.ChannelPrefix = chan
            local prev = Backend:BuildFormattedSpamText()
            if SpamPreviewStatLabels and SpamPreviewStatLabels[1] then
                SpamPreviewStatLabels[1].Text = prev
            end
        end)

        local DelayCard = c:Card("Delay Setup & Start/Stop Control", "TIMING", "Clock", {
            Subtitle = "Atur jeda pengiriman pesan (ms / detik) dan jalankan dengan 1 tombol Start/Stop"
        })

        DelayCard:Slider("Delay Setup (Milliseconds)", "SpamDelayMsSlider", 1000, 30000, 4500, " ms", function(val)
            State.SpamChat.DelayMs = val
            if SpamCounterStatLabels and SpamCounterStatLabels[2] then
                SpamCounterStatLabels[2].Text = string.format("%.1f Detik (%d ms)", val / 1000, val)
            end
        end)

        CreateUnifiedStartStopButton(
            DelayCard,
            "START SPAM CHAT",
            "STOP SPAM CHAT (RUNNING)",
            "Chat",
            function(running)
                State.SpamChat.Active = running
                if SpamPreviewStatLabels and SpamPreviewStatLabels[2] then
                    SpamPreviewStatLabels[2].Text = running and "RUNNING [1]" or "STOPPED [0]"
                end
            end
        )

        local SpoofCard = c:Card("Client Visual Identity Spoofer", "VISUAL", "User", {
            Subtitle = "Set Custom Name, Moderator Gold Title & Role Presets (NameUI / Roles)"
        })

        SpoofCard:Input("Set Custom Name", "VisualCustomName", "Ketik nama display baru...", "", function(txt)
            State.Visual.CustomName = txt
            Backend:ApplyVisualSpoof()
        end)

        SpoofCard:Toggle("Set Moderator Title (`4[MOD] @)", "VisualModTitle", false, function(on)
            State.Visual.ModTitle = on
            Backend:ApplyVisualSpoof()
        end)

        SpoofCard:Dropdown("Role Visual Preset", "VisualRolePreset", {
            "Default",
            "Developer [`6@Dev]",
            "VIP [`9@VIP]",
            "Guardian [`b@Guard]"
        }, "Default", function(preset)
            State.Visual.RolePreset = preset
            local base = LocalPlayer and LocalPlayer.Name or "Operator"
            if preset:find("@Dev") then
                State.Visual.CustomName = "@Dev_" .. base
            elseif preset:find("@VIP") then
                State.Visual.CustomName = "[VIP] " .. base
            elseif preset:find("@Guard") then
                State.Visual.CustomName = "[GUARD] " .. base
            end
            Backend:ApplyVisualSpoof()
        end)
    end),

    right = right(function(r)
        local PreviewCard = r:Card("Live Spam Chat Preview", "PREVIEW", "Chat", {
            Subtitle = "Pratinjau teks beserta kode prefix/warna yang akan dikirim"
        })

        SpamPreviewStatLabels = PreviewCard:StatRow({
            { Icon = "Chat", Label = "OUTPUT MESSAGE", Value = State.SpamChat.LastPreview },
            { Icon = "Bolt", Label = "SPAM STATUS",    Value = "STOPPED [0]" }
        })

        SpamCounterStatLabels = PreviewCard:StatRow({
            { Icon = "Check", Label = "TOTAL SENT",  Value = "0 Messages" },
            { Icon = "Clock", Label = "DELAY SETUP", Value = "4.5 Detik (4500 ms)" }
        })

        PreviewCard:Button("Test Kirim 1 Pesan Sekarang", "SEND 1X", "Chat", function()
            local msg = Backend:BuildFormattedSpamText()
            Backend:SendChatMessage(msg)
            if SpamCounterStatLabels and SpamCounterStatLabels[1] then
                SpamCounterStatLabels[1].Text = tostring(State.SpamChat.SentCount) .. " Messages"
            end
        end)

        PreviewCard:Button("Copy Formatted Text", "COPY TEXT", "Check", function()
            Backend:CopyToClipboard(Backend:BuildFormattedSpamText())
        end)
    end)
}

-- // =========================================================================
-- // KATEGORI 5: UI SETTINGS & THEME (IDENTIK DENGAN R8G.LUA)
-- // =========================================================================
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
                if newKey then UI.ToggleKey = newKey end
            end)
        end
        LayoutCard:Button("Minimize to Popup Icon (Unlock Non-Menu Buttons)", "HIDE", "Minimize", function()
            Backend:SetMenuFocusLock(false)
            UI:MinimizeToIcon()
        end)
    end)
}

-- // =========================================================================
-- // BACKGROUND TELEMETRY, AUTO FARM & SPAM CHAT DISPATCH LOOP
-- // =========================================================================
task.spawn(function()
    local lastSpamTick = 0
    while task.wait(0.2) do
        local info = Backend:ReadLiveWorldAndPosition()

        if MiscPosStatLabels then
            if MiscPosStatLabels[1] then
                MiscPosStatLabels[1].Text = string.format("X: %d | Y: %d", info.X, info.Y)
            end
            if MiscPosStatLabels[2] then
                MiscPosStatLabels[2].Text = tostring(info.TotalPlayers) .. " Players"
            end
        end
        if MiscWorldStatLabels then
            if MiscWorldStatLabels[1] then MiscWorldStatLabels[1].Text = info.PlayerName end
            if MiscWorldStatLabels[2] then MiscWorldStatLabels[2].Text = info.WorldName end
        end

        if MiscActiveCountLabel then
            local activeCount = 0
            for _, v in ipairs({
                State.Misc.ModFly, State.Misc.NoClip, State.Misc.FastRoulette, State.Misc.FastWrench,
                State.Misc.GodMode, State.Misc.SpeedOn, State.Misc.HighJumpOn, State.Misc.AntiGravity
            }) do
                if v then activeCount += 1 end
            end
            if MiscActiveCountLabel[1] then
                MiscActiveCountLabel[1].Text = string.format("%d / 8 ON", activeCount)
            end
            if MiscActiveCountLabel[2] then
                MiscActiveCountLabel[2].Text = State.MenuFocused and "LOCKED [1]" or "UNLOCKED [0]"
            end
        end

        if State.AutoFarm.Active then
            Backend:StepAutoFarm()
            SyncAutoCollectStatus()
            if ClearRightStatLabels and ClearRightStatLabels[1] then
                ClearRightStatLabels[1].Text = tostring(State.AutoFarm.Clear.ClearedCount) .. " Blocks"
            end
        end

        local now = os.clock()
        if State.SpamChat.Active and (now - lastSpamTick) * 1000 >= State.SpamChat.DelayMs then
            lastSpamTick = now
            local msg = Backend:BuildFormattedSpamText()
            Backend:SendChatMessage(msg)
            if SpamCounterStatLabels and SpamCounterStatLabels[1] then
                SpamCounterStatLabels[1].Text = tostring(State.SpamChat.SentCount) .. " Messages"
            end
        end
    end
end)

return UI