-- DEFIT BLOX — Module 04: NPC Analyzer
-- Identifies non-player Humanoid models and records observable properties & animations.
-- Does NOT claim to know server-side AI source logic.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local NpcAnalyzer = {}

local function isPlayerCharacter(model: Model): boolean
    return Players:GetPlayerFromCharacter(model) ~= nil
end

local function vec3ToTable(v: Vector3): { number }
    return { math.round(v.X * 1000) / 1000, math.round(v.Y * 1000) / 1000, math.round(v.Z * 1000) / 1000 }
end

function NpcAnalyzer.run(_config: { [string]: any }, transport: any): ({ Model }, boolean)
    local npcModels = {}
    local npcRecords = {}

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("Model") and not isPlayerCharacter(inst) then
            local hum = inst:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(npcModels, inst)
            end
        end
    end

    local total = #npcModels
    if total == 0 then
        transport:sendProgress("NPC_ANALYZER", 1, 1, "No NPCs detected in Workspace")
        local ok = transport:sendEnvelope(
            "/api/extraction/chunk",
            "NPC_ANALYZER",
            { npcs = {}, note = "No client-visible NPCs found" },
            "npc_001",
            { total_chunks = 1 }
        )
        return npcModels, ok
    end

    for idx, model in ipairs(npcModels) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local hrp = model:FindFirstChild("HumanoidRootPart")
        local animator = hum and hum:FindFirstChildOfClass("Animator")

        local animations = {}
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("Animation") then
                table.insert(animations, {
                    name = desc.Name,
                    animation_id = desc.AnimationId,
                    full_name = desc:GetFullName(),
                })
            end
        end

        local hierarchy = {}
        for _, child in ipairs(model:GetChildren()) do
            table.insert(hierarchy, { name = child.Name, class_name = child.ClassName })
        end

        local pos = nil
        if hrp and hrp:IsA("BasePart") then
            pos = vec3ToTable(hrp.Position)
        end

        table.insert(npcRecords, {
            name = model.Name,
            full_name = model:GetFullName(),
            ai_source_known = false,
            observation_basis = "client_visible_state_only",
            hierarchy = hierarchy,
            humanoid = hum and {
                health = hum.Health,
                max_health = hum.MaxHealth,
                walk_speed = hum.WalkSpeed,
                jump_power = hum.JumpPower,
                jump_height = hum.JumpHeight,
                state = tostring(hum:GetState()),
                has_animator = animator ~= nil,
            } or nil,
            humanoid_root_part = hrp and hrp:GetFullName() or nil,
            current_position = pos,
            animation_references = animations,
        })

        transport:sendProgress(
            "NPC_ANALYZER",
            idx,
            total,
            string.format("Analyzing NPC %s (%d/%d)", model.Name, idx, total)
        )
        task.wait()
    end

    local ok = transport:sendChunkedList("NPC_ANALYZER", "npcs", npcRecords, "npc")
    return npcModels, ok
end

return NpcAnalyzer
