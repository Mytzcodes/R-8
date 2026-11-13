--[[
    DEFIT BLOX + R&8_DV Debugger — Single-Loadstring Unified Loader
    GitHub Basepath: https://github.com/Mytzcodes/R-8/tree/main/Sample%20Gui

    Run in 1 line:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Mytzcodes/R-8/main/Sample%20Gui/Loader.lua"))()
]]

local BASE_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/main/RDC/"
_G.DEFIT_BLOX_BASE_URL = BASE_URL
_G.DEFIT_BLOX_MODULES = _G.DEFIT_BLOX_MODULES or {}

local ls = (getgenv and getgenv().loadstring) or loadstring
local isfileFn = (getgenv and getgenv().isfile) or isfile
local readfileFn = (getgenv and getgenv().readfile) or readfile

local function fetchScript(filename: string): (boolean, string?)
    -- 1. Try GitHub Raw
    local okHttp, body = pcall(function()
        return game:HttpGet(BASE_URL .. filename)
    end)
    if okHttp and type(body) == "string" and #body > 16 and string.sub(body, 1, 4) ~= "404:" then
        return true, body
    end

    -- 2. Fallback to local executor workspace files
    if type(isfileFn) == "function" and type(readfileFn) == "function" then
        for _, prefix in ipairs({ "Sample Gui/", "DEFIT_BLOX/Sample Gui/", "luau/", "" }) do
            local localPath = prefix .. filename
            local okLocal, exists = pcall(isfileFn, localPath)
            if okLocal and exists then
                local okRead, content = pcall(readfileFn, localPath)
                if okRead and type(content) == "string" and #content > 16 then
                    return true, content
                end
            end
        end
    end

    return false, nil
end

local function loadRemoteModule(modName: string, filename: string): boolean
    local okFetch, src = fetchScript(filename)
    if not okFetch or not src then
        warn("[DEFIT_BLOX Loader] Failed to fetch " .. filename)
        return false
    end

    local fn, compileErr = ls(src, "@" .. filename)
    if type(fn) ~= "function" then
        warn("[DEFIT_BLOX Loader] Compile error in " .. filename .. ": " .. tostring(compileErr))
        return false
    end

    local okRun, result = pcall(fn)
    if not okRun then
        warn("[DEFIT_BLOX Loader] Runtime error in " .. filename .. ": " .. tostring(result))
        return false
    end

    _G.DEFIT_BLOX_MODULES[modName] = result
    return true
end

local MODULE_MANIFEST = {
    { "config", "config.lua" },
    { "transport", "transport.lua" },
    { "scanner", "scanner.lua" },
    { "map_extractor", "map_extractor.lua" },
    { "environment_extractor", "environment_extractor.lua" },
    { "npc_analyzer", "npc_analyzer.lua" },
    { "interaction_observer", "interaction_observer.lua" },
    { "asset_analyzer", "asset_analyzer.lua" },
    { "dependency_analyzer", "dependency_analyzer.lua" },
    { "runtime_observer", "runtime_observer.lua" },
}

local loadedCount = 0
for _, entry in ipairs(MODULE_MANIFEST) do
    if loadRemoteModule(entry[1], entry[2]) then
        loadedCount += 1
    end
    task.wait()
end

print(string.format("[DEFIT_BLOX Loader] Loaded %d/%d DEFIT BLOX modules.", loadedCount, #MODULE_MANIFEST))

-- Load and launch unified Debugger GUI
local okDbg, dbgSrc = fetchScript("Debugger.lua")
if not okDbg or not dbgSrc then
    warn("[DEFIT_BLOX Loader] Failed to fetch Debugger.lua from " .. BASE_URL)
    return nil
end

local dbgFn, dbgCompileErr = ls(dbgSrc, "@Debugger.lua")
if type(dbgFn) ~= "function" then
    warn("[DEFIT_BLOX Loader] Compile error in Debugger.lua: " .. tostring(dbgCompileErr))
    return nil
end

local okExec, dbgResult = pcall(dbgFn)
if not okExec then
    warn("[DEFIT_BLOX Loader] Runtime error in Debugger.lua: " .. tostring(dbgResult))
    return nil
end

return dbgResult
