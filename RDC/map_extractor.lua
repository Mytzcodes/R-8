-- DEFIT BLOX — Module 02: Map Extractor
-- Collects Workspace, Model, Folder, Part, MeshPart, UnionOperation, Terrain, and spatial/collision properties.

local Workspace = game:GetService("Workspace")

local MapExtractor = {}

local function safeProp(inst: any, prop: string, fallback: any): any
    local ok, val = pcall(function()
        return inst[prop]
    end)
    if ok and val ~= nil then
        return val
    end
    return fallback
end

local function vec3ToTable(v: any): { number }
    if typeof(v) ~= "Vector3" then
        return { 0, 0, 0 }
    end
    return { math.round(v.X * 1000) / 1000, math.round(v.Y * 1000) / 1000, math.round(v.Z * 1000) / 1000 }
end

local function color3ToTable(c: any): { number }
    if typeof(c) ~= "Color3" then
        return { 0, 0, 0 }
    end
    return { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) }
end

local function serializeBasePart(part: BasePart): { [string]: any }
    local okFull, fullP = pcall(function()
        return part:GetFullName()
    end)
    local okParent, parentFull = pcall(function()
        return part.Parent and part.Parent:GetFullName() or "Workspace"
    end)
    local data: { [string]: any } = {
        name = part.Name,
        class_name = part.ClassName,
        full_name = okFull and fullP or part.Name,
        parent = okParent and parentFull or "Workspace",
        position = vec3ToTable(safeProp(part, "Position", Vector3.new())),
        orientation = vec3ToTable(safeProp(part, "Orientation", Vector3.new())),
        size = vec3ToTable(safeProp(part, "Size", Vector3.new())),
        material = tostring(safeProp(part, "Material", "Plastic")),
        color_rgb = color3ToTable(safeProp(part, "Color", Color3.new())),
        transparency = safeProp(part, "Transparency", 0),
        can_collide = safeProp(part, "CanCollide", true),
        anchored = safeProp(part, "Anchored", false),
        can_touch = safeProp(part, "CanTouch", true),
        can_query = safeProp(part, "CanQuery", true),
        collision_group = safeProp(part, "CollisionGroup", "Default"),
    }
    if part:IsA("MeshPart") then
        data.mesh_id = safeProp(part, "MeshId", "")
        data.texture_id = safeProp(part, "TextureID", "")
    end
    return data
end

function MapExtractor.run(_config: { [string]: any }, transport: any): boolean
    local models = {}
    local parts = {}
    local folders = {}

    local okDesc, descendants = pcall(function()
        return Workspace:GetDescendants()
    end)
    if not okDesc or type(descendants) ~= "table" then
        descendants = {}
    end
    local total = math.max(1, #descendants)

    for idx, inst in ipairs(descendants) do
        if transport.disconnected then
            return false
        end

        pcall(function()
            if inst:IsA("Model") then
                local childNames = {}
                for _, c in ipairs(inst:GetChildren()) do
                    table.insert(childNames, { name = c.Name, class_name = c.ClassName })
                end
                local okPivot, pivot = pcall(function()
                    return inst:GetPivot().Position
                end)
                table.insert(models, {
                    name = inst.Name,
                    full_name = inst:GetFullName(),
                    parent = inst.Parent and inst.Parent:GetFullName() or "Workspace",
                    pivot_position = okPivot and vec3ToTable(pivot) or nil,
                    children = childNames,
                })
            elseif inst:IsA("Folder") then
                table.insert(folders, {
                    name = inst.Name,
                    full_name = inst:GetFullName(),
                    child_count = #inst:GetChildren(),
                })
            elseif inst:IsA("BasePart") and not inst:IsA("Terrain") then
                table.insert(parts, serializeBasePart(inst))
            end
        end)

        if idx % 200 == 0 then
            transport:sendProgress(
                "MAP_EXTRACTOR",
                math.min(idx, total - 1),
                total,
                string.format("Scanning map geometry %d/%d", idx, total),
                nil,
                idx
            )
            task.wait()
        end
    end

    -- Terrain metadata (safe pcall)
    local terrainData = nil
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrainData = {
                name = terrain.Name,
                water_color = color3ToTable(safeProp(terrain, "WaterColor", Color3.new())),
                water_transparency = safeProp(terrain, "WaterTransparency", 0),
                water_wave_size = safeProp(terrain, "WaterWaveSize", 0),
                water_wave_speed = safeProp(terrain, "WaterWaveSpeed", 0),
                water_reflectance = safeProp(terrain, "WaterReflectance", 0),
                decoration = safeProp(terrain, "Decoration", false),
            }
        end
    end)

    local okTerrain = transport:sendEnvelope(
        "/api/extraction/chunk",
        "MAP_EXTRACTOR",
        { terrain = terrainData },
        "map_terrain_001",
        { total_chunks = 1 }
    )
    local okModels = transport:sendChunkedList("MAP_EXTRACTOR", "models", models, "map_models")
    local okFolders = transport:sendChunkedList("MAP_EXTRACTOR", "folders", folders, "map_folders")
    local okParts = transport:sendChunkedList("MAP_EXTRACTOR", "parts", parts, "map_parts")

    if okTerrain and okModels and okFolders and okParts then
        transport:sendProgress("MAP_EXTRACTOR", total, total, "Map extraction complete")
        return true
    end
    return false
end

return MapExtractor
