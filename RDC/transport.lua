-- DEFIT BLOX — HTTP Transport Adapter & Pure-Luau SHA-256

local HttpService = game:GetService("HttpService")

local Transport = {}
Transport.__index = Transport

-- ============================================================================
-- Pure-Luau SHA-256 (bit32) for deterministic checksums matching Python hashlib
-- ============================================================================
local K = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local function sha256(msg: string): string
    local band, bxor, bnot = bit32.band, bit32.bxor, bit32.bnot
    local rrotate, rshift = bit32.rrotate, bit32.rshift

    local len = #msg
    local bitLen = len * 8
    local padLen = (56 - (len + 1) % 64) % 64
    local padded = msg .. "\128" .. string.rep("\0", padLen)
    local hi = math.floor(bitLen / 4294967296)
    local lo = bitLen % 4294967296
    padded = padded .. string.char(
        band(rshift(hi, 24), 0xff), band(rshift(hi, 16), 0xff), band(rshift(hi, 8), 0xff), band(hi, 0xff),
        band(rshift(lo, 24), 0xff), band(rshift(lo, 16), 0xff), band(rshift(lo, 8), 0xff), band(lo, 0xff)
    )

    local H = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    }

    local w = table.create(64, 0)
    for offset = 1, #padded, 64 do
        for i = 0, 15 do
            local idx = offset + i * 4
            local b1, b2, b3, b4 = string.byte(padded, idx, idx + 3)
            w[i + 1] = ((b1 * 256 + b2) * 256 + b3) * 256 + b4
        end
        for i = 17, 64 do
            local v15 = w[i - 15]
            local v2 = w[i - 2]
            local s0 = bxor(rrotate(v15, 7), rrotate(v15, 18), rshift(v15, 3))
            local s1 = bxor(rrotate(v2, 17), rrotate(v2, 19), rshift(v2, 10))
            w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % 4294967296
        end

        local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
        for i = 1, 64 do
            local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local temp1 = (h + S1 + ch + K[i] + w[i]) % 4294967296
            local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
            local maj = bxor(band(a, b), band(a, c), band(b, c))
            local temp2 = (S0 + maj) % 4294967296

            h = g
            g = f
            f = e
            e = (d + temp1) % 4294967296
            d = c
            c = b
            b = a
            a = (temp1 + temp2) % 4294967296
        end

        H[1] = (H[1] + a) % 4294967296
        H[2] = (H[2] + b) % 4294967296
        H[3] = (H[3] + c) % 4294967296
        H[4] = (H[4] + d) % 4294967296
        H[5] = (H[5] + e) % 4294967296
        H[6] = (H[6] + f) % 4294967296
        H[7] = (H[7] + g) % 4294967296
        H[8] = (H[8] + h) % 4294967296
    end

    return string.format(
        "%08x%08x%08x%08x%08x%08x%08x%08x",
        H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
    )
end

-- ============================================================================
-- Multi-environment HTTP Request Adapter
-- ============================================================================
function Transport.detectHttpAdapter()
    local env = (getfenv and getfenv(0)) or _G
    if type(env.request) == "function" then
        return "request", env.request
    end
    if type(env.http_request) == "function" then
        return "http_request", env.http_request
    end
    if type(env.syn) == "table" and type(env.syn.request) == "function" then
        return "syn.request", env.syn.request
    end
    if type(env.fluxus) == "table" and type(env.fluxus.request) == "function" then
        return "fluxus.request", env.fluxus.request
    end
    if type(env.http) == "table" and type(env.http.request) == "function" then
        return "http.request", env.http.request
    end
    -- Fallback to Roblox Studio HttpService:RequestAsync
    return "HttpService:RequestAsync", function(reqOpts)
        return HttpService:RequestAsync(reqOpts)
    end
end

function Transport.isValidIPv4(ip: string): boolean
    if type(ip) ~= "string" then
        return false
    end
    local a, b, c, d = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then
        return false
    end
    for _, oct in ipairs({ tonumber(a), tonumber(b), tonumber(c), tonumber(d) }) do
        if not oct or oct < 0 or oct > 255 then
            return false
        end
    end
    return true
end

function Transport.isValidEndpoint(endpoint: string): boolean
    if type(endpoint) ~= "string" then
        return false
    end
    local trimmed = endpoint:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed:match("^https?://[%w%.%-_]+") then
        return true
    end
    return Transport.isValidIPv4(trimmed)
end

function Transport.normalizeBaseUrl(endpoint: string, serverPort: number): string
    local trimmed = endpoint:gsub("^%s+", ""):gsub("%s+$", ""):gsub("/+$", "")
    if trimmed:match("^https?://") then
        return trimmed
    end
    return string.format("http://%s:%d", trimmed, serverPort)
end

function Transport.new(serverEndpoint: string, serverPort: number, config: { [string]: any })
    local adapterName, adapterFn = Transport.detectHttpAdapter()
    return setmetatable({
        baseUrl = Transport.normalizeBaseUrl(serverEndpoint, serverPort),
        adapterName = adapterName,
        adapterFn = adapterFn,
        config = config,
        authToken = "",
        sessionId = "pending",
        disconnected = false,
    }, Transport)
end

function Transport:_rawRequest(method: string, path: string, bodyStr: string?, timeoutOverride: number?): (boolean, number, any)
    local url = self.baseUrl .. path
    local headers = {
        ["Content-Type"] = "application/json",
        ["ngrok-skip-browser-warning"] = "true",
    }
    if self.authToken ~= "" then
        headers["X-Defit-Token"] = self.authToken
    end

    local timeoutSec = timeoutOverride or (self.config and self.config.REQUEST_TIMEOUT_SEC) or 6
    local done = false
    local ok = false
    local resp: any = nil

    task.spawn(function()
        local callOk, callRes = pcall(function()
            local opts: { [string]: any } = {
                Url = url,
                Method = method,
                Headers = headers,
            }
            if bodyStr ~= nil then
                opts.Body = bodyStr
            end
            return self.adapterFn(opts)
        end)
        ok = callOk
        resp = callRes
        done = true
    end)

    local deadline = os.clock() + timeoutSec
    while not done and os.clock() < deadline do
        task.wait(0.05)
    end

    if not done then
        return false, 0, { error = string.format("Timeout after %ds (check IP / Windows Firewall / same Wi-Fi)", timeoutSec) }
    end

    if not ok or type(resp) ~= "table" then
        return false, 0, { error = tostring(resp or "No response table from HTTP adapter") }
    end

    local statusCode = tonumber(resp.StatusCode or resp.status or resp.code) or 0
    local respBody = resp.Body or resp.body or "{}"
    local decodedOk, decoded = pcall(function()
        return HttpService:JSONDecode(respBody)
    end)

    if not decodedOk then
        decoded = { raw = respBody }
    end

    return (statusCode >= 200 and statusCode < 300), statusCode, decoded
end

function Transport:ping(): (boolean, any)
    local ok, statusCode, data = self:_rawRequest("GET", "/api/ping", nil, 4)
    if not ok then
        return false, data or { error = "HTTP " .. tostring(statusCode) }
    end
    return true, data
end

function Transport:sendEnvelope(
    path: string,
    moduleName: string,
    payloadTable: any,
    chunkId: string?,
    extraFields: { [string]: any }?
): (boolean, any)
    if self.disconnected then
        return false, { error = "Transport disconnected" }
    end

    local payloadJson = HttpService:JSONEncode(payloadTable)
    local checksum = sha256(payloadJson)

    local envelope: { [string]: any } = {
        session_id = self.sessionId,
        auth_token = self.authToken,
        module_name = moduleName,
        timestamp = os.time(),
        payload = payloadJson,
        payload_encoding = "json_string",
        checksum = checksum,
    }
    if chunkId then
        envelope.chunk_id = chunkId
    end
    if extraFields then
        for k, v in pairs(extraFields) do
            envelope[k] = v
        end
    end

    local encodedEnvelope = HttpService:JSONEncode(envelope)
    local maxRetries = self.config.MAX_RETRIES or 3
    local retryDelay = self.config.RETRY_DELAY_SEC or 1.0

    for attempt = 1, maxRetries do
        local ok, statusCode, data = self:_rawRequest("POST", path, encodedEnvelope)
        if ok then
            return true, data
        end
        -- Do not retry 401 Unauthorized
        if statusCode == 401 then
            return false, data
        end
        if attempt < maxRetries then
            task.wait(retryDelay * attempt)
        else
            if statusCode == 0 then
                self.disconnected = true
            end
            return false, data
        end
    end

    return false, { error = "Exhausted retries" }
end

function Transport:getAckState(): (boolean, any)
    local path = string.format(
        "/api/session/ack?session_id=%s&auth_token=%s",
        HttpService:UrlEncode(self.sessionId),
        HttpService:UrlEncode(self.authToken)
    )
    local ok, _status, data = self:_rawRequest("GET", path, nil)
    return ok, data
end

function Transport:sendProgress(
    moduleName: string,
    completedUnits: number,
    totalUnits: number,
    operation: string,
    objectsDiscovered: number?,
    objectsProcessed: number?
): boolean
    local ok = self:sendEnvelope("/api/extraction/progress", moduleName, {
        completed_units = completedUnits,
        total_units = totalUnits,
        operation = operation,
        objects_discovered = objectsDiscovered,
        objects_processed = objectsProcessed,
    })
    return ok
end

function Transport:sendChunkedList(
    moduleName: string,
    listKey: string,
    items: { any },
    chunkPrefix: string,
    onProgress: ((number, number) -> ())?
): boolean
    local limit = self.config.CHUNK_ITEM_LIMIT or 150
    local totalItems = #items
    local totalChunks = math.max(1, math.ceil(totalItems / limit))

    if totalItems == 0 then
        local ok = self:sendEnvelope(
            "/api/extraction/chunk",
            moduleName,
            { [listKey] = {} },
            string.format("%s_001", chunkPrefix),
            { total_chunks = 1 }
        )
        if onProgress then
            onProgress(1, 1)
        end
        return ok
    end

    for chunkIdx = 1, totalChunks do
        if self.disconnected then
            return false
        end
        local startIdx = (chunkIdx - 1) * limit + 1
        local endIdx = math.min(totalItems, chunkIdx * limit)
        local slice = table.create(endIdx - startIdx + 1)
        for i = startIdx, endIdx do
            table.insert(slice, items[i])
        end

        local chunkId = string.format("%s_%03d", chunkPrefix, chunkIdx)
        local ok = self:sendEnvelope(
            "/api/extraction/chunk",
            moduleName,
            { [listKey] = slice },
            chunkId,
            { total_chunks = totalChunks }
        )
        if not ok then
            return false
        end
        if onProgress then
            onProgress(endIdx, totalItems)
        end
        task.wait()
    end

    return true
end

return Transport
