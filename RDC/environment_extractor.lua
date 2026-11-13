-- DEFIT BLOX — Module 03: Environment Extractor
-- Collects Lighting, Atmosphere, Sky, Clouds, Post-Processing Effects, SoundService, and Terrain settings.

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local EnvironmentExtractor = {}

local function color3ToTable(c: Color3): { number }
    return { math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255) }
end

function EnvironmentExtractor.run(_config: { [string]: any }, transport: any): boolean
    transport:sendProgress("ENVIRONMENT_EXTRACTOR", 0, 3, "Reading Lighting & Atmosphere")

    local lightingData = {
        ambient = color3ToTable(Lighting.Ambient),
        outdoor_ambient = color3ToTable(Lighting.OutdoorAmbient),
        brightness = Lighting.Brightness,
        clock_time = Lighting.ClockTime,
        geographic_latitude = Lighting.GeographicLatitude,
        fog_color = color3ToTable(Lighting.FogColor),
        fog_start = Lighting.FogStart,
        fog_end = Lighting.FogEnd,
        global_shadows = Lighting.GlobalShadows,
        technology = tostring(Lighting.Technology),
        environment_diffuse_scale = Lighting.EnvironmentDiffuseScale,
        environment_specular_scale = Lighting.EnvironmentSpecularScale,
    }

    local atmosphere = nil
    local sky = nil
    local clouds = nil
    local effects = {}

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Atmosphere") then
            atmosphere = {
                density = child.Density,
                offset = child.Offset,
                color = color3ToTable(child.Color),
                decay = color3ToTable(child.Decay),
                glare = child.Glare,
                haze = child.Haze,
            }
        elseif child:IsA("Sky") then
            sky = {
                celestial_bodies_shown = child.CelestialBodiesShown,
                moon_angular_size = child.MoonAngularSize,
                sun_angular_size = child.SunAngularSize,
                star_count = child.StarCount,
                skybox_bk = child.SkyboxBk,
                skybox_dn = child.SkyboxDn,
                skybox_ft = child.SkyboxFt,
                skybox_lf = child.SkyboxLf,
                skybox_rt = child.SkyboxRt,
                skybox_up = child.SkyboxUp,
            }
        elseif child:IsA("PostEffect") then
            table.insert(effects, {
                name = child.Name,
                class_name = child.ClassName,
                enabled = child.Enabled,
            })
        end
    end

    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    local terrainSettings = nil
    if terrain then
        local cloudObj = terrain:FindFirstChildOfClass("Clouds")
        if cloudObj then
            clouds = {
                cover = cloudObj.Cover,
                density = cloudObj.Density,
                color = color3ToTable(cloudObj.Color),
                enabled = cloudObj.Enabled,
            }
        end
        terrainSettings = {
            water_color = color3ToTable(terrain.WaterColor),
            water_transparency = terrain.WaterTransparency,
            water_wave_size = terrain.WaterWaveSize,
            water_wave_speed = terrain.WaterWaveSpeed,
            decoration = terrain.Decoration,
        }
    end

    transport:sendProgress("ENVIRONMENT_EXTRACTOR", 2, 3, "Reading SoundService settings")

    local soundData = {
        ambient_reverb = tostring(SoundService.AmbientReverb),
        distance_factor = SoundService.DistanceFactor,
        doppler_scale = SoundService.DopplerScale,
        rolloff_scale = SoundService.RolloffScale,
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
