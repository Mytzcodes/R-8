-- DEFIT BLOX — Module 07: Dependency Analyzer
-- Builds object relationships and distinguishes direct vs inferred dependencies.

local DependencyAnalyzer = {}

function DependencyAnalyzer.run(
    _config: { [string]: any },
    transport: any,
    context: {
        instances: { any }?,
        npcModels: { Model }?,
        interactions: { [string]: any }?,
        assetRefs: { any }?,
    }
): boolean
    local edges = {}

    -- 1. Direct Parent -> Child / Model -> Component relationships from scanned instances
    if context.instances then
        for _, inst in ipairs(context.instances) do
            if inst.parent and inst.parent ~= "DataModel" and inst.full_name then
                local rel = (inst.class_name == "Model") and "contains_model" or "parent_child"
                table.insert(edges, {
                    source = inst.parent,
                    target = inst.full_name,
                    relation = rel,
                    confidence = "direct",
                })
            end
        end
    end

    -- 2. Direct NPC -> Humanoid relationships
    if context.npcModels then
        for _, npc in ipairs(context.npcModels) do
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum then
                table.insert(edges, {
                    source = npc:GetFullName(),
                    target = hum:GetFullName(),
                    relation = "npc_humanoid",
                    confidence = "direct",
                })
            end
        end
    end

    -- 3. Direct Object -> Interaction & GUI -> Control relationships
    if context.interactions then
        for _, p in ipairs(context.interactions.proximity_prompts or {}) do
            if p.parent ~= "" then
                table.insert(edges, {
                    source = p.parent,
                    target = p.full_name,
                    relation = "has_proximity_prompt",
                    confidence = "direct",
                })
            end
        end
        for _, c in ipairs(context.interactions.click_detectors or {}) do
            if c.parent ~= "" then
                table.insert(edges, {
                    source = c.parent,
                    target = c.full_name,
                    relation = "has_click_detector",
                    confidence = "direct",
                })
            end
        end
        for _, g in ipairs(context.interactions.gui_controls or {}) do
            table.insert(edges, {
                source = "PlayerGui",
                target = g.full_name,
                relation = "observable_gui_control",
                confidence = "inferred",
            })
        end
    end

    -- 4. Direct Asset -> Referencing Object relationships
    if context.assetRefs then
        for _, ref in ipairs(context.assetRefs) do
            table.insert(edges, {
                source = ref.full_name,
                target = ref.asset_id,
                relation = "references_" .. string.lower(ref.asset_type),
                confidence = "direct",
            })
        end
    end

    transport:sendProgress("DEPENDENCY_ANALYZER", 1, 2, string.format("Built %d dependency edges", #edges))

    local ok = transport:sendChunkedList(
        "DEPENDENCY_ANALYZER",
        "edges",
        edges,
        "dep",
        function(doneCount, totalCount)
            transport:sendProgress(
                "DEPENDENCY_ANALYZER",
                doneCount,
                totalCount,
                string.format("Uploading dependency graph %d/%d", doneCount, totalCount)
            )
        end
    )
    return ok
end

return DependencyAnalyzer
