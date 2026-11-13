-- DEFIT BLOX — Module 06: Asset Reference Analyzer
-- Collects MeshId, TextureID, Decal, AnimationId, SoundId, and Material references from accessible instances.

local AssetAnalyzer = {}

local function addRef(refs: { any }, inst: Instance, assetType: string, assetId: string?)
    if type(assetId) == "string" and assetId ~= "" then
        table.insert(refs, {
            asset_type = assetType,
            asset_id = assetId,
            instance_name = inst.Name,
            instance_class = inst.ClassName,
            full_name = inst:GetFullName(),
        })
    end
end

function AssetAnalyzer.run(config: { [string]: any }, transport: any): ({ any }, boolean)
    local services = config.CLIENT_SCAN_SERVICES or { "Workspace", "ReplicatedStorage", "StarterGui" }
    local refs = {}
    local totalServices = #services

    for sIdx, serviceName in ipairs(services) do
        local ok, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if ok and service then
            for i, inst in ipairs(service:GetDescendants()) do
                if inst:IsA("MeshPart") then
                    addRef(refs, inst, "MeshId", inst.MeshId)
                    addRef(refs, inst, "TextureID", inst.TextureID)
                elseif inst:IsA("SpecialMesh") then
                    addRef(refs, inst, "MeshId", inst.MeshId)
                    addRef(refs, inst, "TextureId", inst.TextureId)
                elseif inst:IsA("Decal") or inst:IsA("Texture") then
                    addRef(refs, inst, "DecalOrTexture", inst.Texture)
                elseif inst:IsA("Animation") then
                    addRef(refs, inst, "AnimationId", inst.AnimationId)
                elseif inst:IsA("Sound") then
                    addRef(refs, inst, "SoundId", inst.SoundId)
                elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
                    addRef(refs, inst, "Image", inst.Image)
                elseif inst:IsA("BasePart") and inst.MaterialVariant ~= "" then
                    addRef(refs, inst, "MaterialVariant", inst.MaterialVariant)
                end

                if i % 300 == 0 then
                    task.wait()
                end
            end
        end

        transport:sendProgress(
            "ASSET_REFERENCE_ANALYZER",
            sIdx,
            totalServices,
            string.format("Collected %d asset references (%s)", #refs, serviceName)
        )
        task.wait()
    end

    local ok = transport:sendChunkedList(
        "ASSET_REFERENCE_ANALYZER",
        "asset_references",
        refs,
        "assets",
        function(doneCount, totalCount)
            transport:sendProgress(
                "ASSET_REFERENCE_ANALYZER",
                doneCount,
                totalCount,
                string.format("Uploading asset references %d/%d", doneCount, totalCount)
            )
        end
    )
    return refs, ok
end

return AssetAnalyzer
