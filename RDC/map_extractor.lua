-- DEFIT BLOX — Module 02: Map Extractor
-- Collects Workspace, Model, Folder, Part, MeshPart, UnionOperation, Terrain, and spatial/collision properties.

local Workspace = game:GetService("Workspace")

local MapExtractor = {}

local function vec3ToTable(v: Vector3): { number }
    return { math.round(v.X * 1000) / 1000, math.round(v.Y * 1000) / 1000, math.round(v.Z * 1000) / 1000 }
end

local function color3ToTable(c: Color3): { number }
    return { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) }
end

local function serializeBasePart(part: BasePart): { [string]: any }
    local data: { [string]: any } = {
        name = part.Name,
        class_name = part.ClassName,
        full_name = part:GetFullName(),
        parent = part.Parent and part.Parent:GetFullName() or "Workspace",
        position = vec3ToTable(part.Position),
        orientation = vec3ToTable(part.Orientation),
        size = vec3ToTable(part.Size),
        material = tostring(part.Material),
        color_rgb = color3ToTable(part.Color),
        transparency = part.Transparency,
        can_collide = part.CanCollide,
        anchored = part.Anchored,
        can_touch = part.CanTouch,
        can_query = part.CanQuery,
        collision_group = part.CollisionGroup,
    }
    if part:IsA("MeshPart") then
        data.mesh_id = part.MeshId
        data.texture_id = part.TextureID
    end
    return data
end

function MapExtractor.run(config: { [string]: any }, transport: any): boolean
    local models = {}
    local parts = {}
    local folders = {}

    local descendants = Workspace:GetDescendants()
    local total = #descendants

    for idx, inst in ipairs(descendants) do
        if transport.disconnected then
            return false
        end

        if inst:IsA("Model") and inst.Parent == Workspace then
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

        if idx % 200 == 0 or idx == total then
            transport:sendProgress(
                "MAP_EXTRACTOR",
                idx,
                math.max(1, total),
                string.format("Extracting map geometry %d/%d", idx, total),
                nil,
                idx
            )
            task.wait()
        end
    end

    -- Terrain metadata
    local terrainData = nil
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrainData = {
            name = terrain.Name,
            water_color = color3ToTable(terrain.WaterColor),
            water_transparency = terrain.WaterTransparency,
            water_wave_size = terrain.WaterWaveSize,
            water_wave_speed = terrain.WaterWaveSpeed,
            water_reflectance = terrain.WaterReflectance,
            decoration = terrain.Decoration,
        }
    end

    -- Send models & terrain first
    local okMeta = transport:sendEnvelope(
        "/api/extraction/chunk",
        "MAP_EXTRACTOR",
        {
            models = models,
            folders = folders,
            terrain = terrainData,
        },
        "map_models_001",
        { total_chunks = 1 }
    )
    if not okMeta then
        return false
    end

    -- Send parts in chunks
    return transport:sendChunkedList("MAP_EXTRACTOR", "parts", parts, "map_parts")
end

return MapExtractor
