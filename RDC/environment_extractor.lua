-- DEFIT BLOX — Module 03: Environment Extractor
-- Collects Lighting, Atmosphere, Sky, Clouds, Post-Processing Effects, SoundService, and Terrain settings.

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local EnvironmentExtractor = {}

local function safeProp(inst: any, prop: string, fallback: any): any
    local ok, val = pcall(function()
        return inst[prop]
    end)
    if ok and val ~= nil then
        return val
    end
    return fallback
end

local function color3ToTable(c: any): { number }
    if typeof(c) ~= "Color3" then
        return { 0, 0, 0 }
    end
    return { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) }
end

function EnvironmentExtractor.run(_config: { [string]: any }, transport: any): boolean
    transport:sendProgress("ENVIRONMENT_EXTRACTOR", 0, 3, "Reading Lighting & Atmosphere")

    local lightingData = {
        ambient = color3ToTable(safeProp(Lighting, "Ambient", Color3.new())),
        outdoor_ambient = color3ToTable(safeProp(Lighting, "OutdoorAmbient", Color3.new())),
        brightness = safeProp(Lighting, "Brightness", 0),
        clock_time = safeProp(Lighting, "ClockTime", 14),
        geographic_latitude = safeProp(Lighting, "GeographicLatitude", 0),
        fog_color = color3ToTable(safeProp(Lighting, "FogColor", Color3.new())),
        fog_start = safeProp(Lighting, "FogStart", 0),
        fog_end = safeProp(Lighting, "FogEnd", 100000),
        global_shadows = safeProp(Lighting, "GlobalShadows", true),
        technology = tostring(safeProp(Lighting, "Technology", "Unknown")),
        environment_diffuse_scale = safeProp(Lighting, "EnvironmentDiffuseScale", 0),
        environment_specular_scale = safeProp(Lighting, "EnvironmentSpecularScale", 0),
    }

    local atmosphere = nil
    local sky = nil
    local clouds = nil
    local effects = {}

    local okChildren, children = pcall(function()
        return Lighting:GetChildren()
    end)
    if okChildren and type(children) == "table" then
        for _, child in ipairs(children) do
            pcall(function()
                if child:IsA("Atmosphere") then
                    atmosphere = {
                        density = safeProp(child, "Density", 0),
                        offset = safeProp(child, "Offset", 0),
                        color = color3ToTable(safeProp(child, "Color", Color3.new())),
                        decay = color3ToTable(safeProp(child, "Decay", Color3.new())),
                        glare = safeProp(child, "Glare", 0),
                        haze = safeProp(child, "Haze", 0),
                    }
                elseif child:IsA("Sky") then
                    sky = {
                        celestial_bodies_shown = safeProp(child, "CelestialBodiesShown", true),
                        moon_angular_size = safeProp(child, "MoonAngularSize", 11),
                        sun_angular_size = safeProp(child, "SunAngularSize", 21),
                        star_count = safeProp(child, "StarCount", 3000),
                        skybox_bk = safeProp(child, "SkyboxBk", ""),
                        skybox_dn = safeProp(child, "SkyboxDn", ""),
                        skybox_ft = safeProp(child, "SkyboxFt", ""),
                        skybox_lf = safeProp(child, "SkyboxLf", ""),
                        skybox_rt = safeProp(child, "SkyboxRt", ""),
                        skybox_up = safeProp(child, "SkyboxUp", ""),
                    }
                elseif child:IsA("PostEffect") then
                    table.insert(effects, {
                        name = child.Name,
                        class_name = child.ClassName,
                        enabled = safeProp(child, "Enabled", false),
                    })
                end
            end)
        end
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    local terrainSettings = nil
    if terrain then
        pcall(function()
            local cloudObj = terrain:FindFirstChildOfClass("Clouds")
            if cloudObj then
                clouds = {
                    cover = safeProp(cloudObj, "Cover", 0),
                    density = safeProp(cloudObj, "Density", 0),
                    color = color3ToTable(safeProp(cloudObj, "Color", Color3.new())),
                    enabled = safeProp(cloudObj, "Enabled", false),
                }
            end
            terrainSettings = {
                water_color = color3ToTable(safeProp(terrain, "WaterColor", Color3.new())),
                water_transparency = safeProp(terrain, "WaterTransparency", 0),
                water_wave_size = safeProp(terrain, "WaterWaveSize", 0),
                water_wave_speed = safeProp(terrain, "WaterWaveSpeed", 0),
                decoration = safeProp(terrain, "Decoration", false),
            }
        end)
    end

    transport:sendProgress("ENVIRONMENT_EXTRACTOR", 2, 3, "Reading SoundService settings")

    local soundData = {
        ambient_reverb = tostring(safeProp(SoundService, "AmbientReverb", "NoReverb")),
        distance_factor = safeProp(SoundService, "DistanceFactor", 3.33),
        doppler_scale = safeProp(SoundService, "DopplerScale", 1),
        rolloff_scale = safeProp(SoundService, "RolloffScale", 1),
    }

    local payload = {
        lighting = lightingData,
        atmosphere = atmosphere,
        sky = sky,
        clouds = clouds,
        effects = effects,
        sound_service = soundData,
        terrain_settings = terrainSettings,
    }

    local ok = transport:sendEnvelope(
        "/api/extraction/chunk",
        "ENVIRONMENT_EXTRACTOR",
        payload,
        "env_001",
        { total_chunks = 1, artifact_name = "environment.json" }
    )
    if ok then
        transport:sendProgress("ENVIRONMENT_EXTRACTOR", 3, 3, "Environment extraction complete")
    end
    return ok
end

return EnvironmentExtractor
