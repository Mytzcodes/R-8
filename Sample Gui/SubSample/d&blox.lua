-- File: loader.lua
-- Usage: Ganti GITHUB_BASE_URL dengan URL Raw Repository GitHub milikmu tempat core_backend.lua dan ui_frontend.lua diupload.

local GITHUB_BASE_URL = "https://raw.githubusercontent.com/Mytzcodes/R-8/refs/heads/main/Sample%20Gui/SubSample/"
local BACKEND_URL     = GITHUB_BASE_URL .. "x%262918.lua"
local FRONTEND_URL    = GITHUB_BASE_URL .. "x%261823.lua"

local function FetchAndExecute(url, moduleLabel)
    local okHttp, source = pcall(function()
        return game:HttpGet(url)
    end)
    assert(okHttp and type(source) == "string" and #source > 64, string.format("[C8_LOADER] Gagal mengunduh %s dari: %s", moduleLabel, url))

    local chunk, syntaxErr = loadstring(source, "=" .. moduleLabel)
    assert(type(chunk) == "function", string.format("[C8_LOADER] Syntax error pada %s: %s", moduleLabel, tostring(syntaxErr)))

    local okRun, result = pcall(chunk)
    assert(okRun, string.format("[C8_LOADER] Runtime error pada %s: %s", moduleLabel, tostring(result)))

    return result
end

-- 1. Muat Core Backend terlebih dahulu & simpan ke Global Environment (getgenv().C8_FUNC)
local CoreBackend = FetchAndExecute(BACKEND_URL, "core_backend.lua")
if getgenv then
    getgenv().C8_FUNC = CoreBackend
end
_G.C8_FUNC = CoreBackend

-- 2. Muat UI Frontend (R&8_DV 3-Panel Canvas) yang otomatis terhubung ke getgenv().C8_FUNC
local UIFrontend = FetchAndExecute(FRONTEND_URL, "ui_frontend.lua")

return {
    Backend = CoreBackend,
    UI = UIFrontend
}
