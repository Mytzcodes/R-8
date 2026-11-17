--!nocheck
local CANDIDATE_URLS = {
    "https://raw.githubusercontent.com/Mytzcodes/GUIX/refs/heads/main/SYT_CN.lua",
    "https://cdn.jsdelivr.net/gh/Mytzcodes/GUIX@main/SYT_CN.lua",
    "https://raw.githubusercontent.com/Mytzcodes/GUIX/main/SYT_CN.lua",
    "https://github.com/Mytzcodes/GUIX/raw/refs/heads/main/SYT_CN.lua",
    "https://raw.githubusercontent.com/Mytzcodes/GUIX/refs/heads/main/SYT.lua",
}

local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = 5,
        })
    end)
end

if not game:IsLoaded() then
    pcall(function()
        game.Loaded:Wait()
    end)
end

local Players = game:GetService("Players")
if not Players.LocalPlayer then
    local deadline = os.clock() + 10
    while not Players.LocalPlayer and os.clock() < deadline do
        task.wait(0.1)
    end
end

local function isValidSource(body)
    if type(body) ~= "string" or #body < 128 then
        return false
    end
    local head = string.lower((string.sub(body, 1, 64)):match("^%s*(.-)$") or "")
    if string.sub(head, 1, 4) == "404:" or string.sub(head, 1, 5) == "<html" or string.sub(head, 1, 9) == "<!doctype" then
        return false
    end
    return true
end

local reqFn = (type(syn) == "table" and type(syn.request) == "function" and syn.request)
    or (type(http_request) == "function" and http_request)
    or (type(request) == "function" and request)
    or nil

local function tryFetchOnce(url)
    local okGet, resGet = pcall(function()
        return game:HttpGet(url, true)
    end)
    if okGet and isValidSource(resGet) then
        return resGet
    end

    if reqFn then
        local okReq, resp = pcall(reqFn, {
            Url = url,
            Method = "GET",
            Headers = { ["Cache-Control"] = "no-cache" },
        })
        if okReq and type(resp) == "table" and isValidSource(resp.Body) then
            local sc = tonumber(resp.StatusCode)
            if not sc or (sc >= 200 and sc < 300) then
                return resp.Body
            end
        end
    end

    return nil, tostring(resGet or "empty/http error")
end

local function fetchBestSource()
    local lastErr = "unknown"
    for pass = 1, 2 do
        local bust = "?t=" .. tostring(math.floor(os.time())) .. "_" .. tostring(pass)
        for _, baseUrl in ipairs(CANDIDATE_URLS) do
            local target = (pass == 1) and baseUrl or (baseUrl .. bust)
            local body, err = tryFetchOnce(target)
            if body then
                return body
            end
            lastErr = tostring(err)
            task.wait()
        end
        if pass < 2 then
            task.wait(0.35)
        end
    end
    return nil, lastErr
end

local src, fetchErr = fetchBestSource()
if not src then
    warn("[SYT Loader] Download gagal: " .. tostring(fetchErr))
    notify("SYT Loader", "Gagal mengunduh SYT_CN. Cek koneksi/VPN/DNS.")
    return
end

local function elevateThread()
    local fn = (type(setthreadidentity) == "function" and setthreadidentity)
        or (type(setidentity) == "function" and setidentity)
        or (type(set_thread_identity) == "function" and set_thread_identity)
        or (type(syn) == "table" and type(syn.set_thread_identity) == "function" and syn.set_thread_identity)
        or nil
    if fn then pcall(fn, 8) end
end

elevateThread()
local chunk, compileErr = loadstring(src)
if type(chunk) ~= "function" then
    warn("[SYT Loader] Compile error: " .. tostring(compileErr))
    notify("SYT Loader", "Compile error! Cek F9 console.")
    return
end

elevateThread()
local okRun, resOrErr = xpcall(chunk, debug.traceback)
if not okRun then
    warn("[SYT Loader] Runtime error:\n" .. tostring(resOrErr))
    notify("SYT Loader", "Runtime error! Cek F9 console.")
    return
end

return resOrErr
