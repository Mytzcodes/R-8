-- DEFIT BLOX — Luau Agent Configuration

local Config = {
    DEFAULT_PORT = 8765,
    PAIRING_TOKEN = "", -- Optional pre-shared token, or set _G.DEFIT_BLOX_TOKEN
    CHUNK_ITEM_LIMIT = 150, -- Max items per chunk to keep payloads fast and reliable
    MAX_RETRIES = 3,
    RETRY_DELAY_SEC = 1.0,
    REQUEST_TIMEOUT_SEC = 10,

    -- Runtime Observer (Module 08) safety limits
    RUNTIME_OBSERVER_DURATION_SEC = 10,
    RUNTIME_OBSERVER_MAX_EVENTS = 250,
    RUNTIME_OBSERVER_MAX_BYTES = 262144, -- 256 KB
    RUNTIME_OBSERVER_FLUSH_INTERVAL_SEC = 2,

    -- Services safe to inspect from client (never touch ServerStorage / ServerScriptService)
    CLIENT_SCAN_SERVICES = {
        "Workspace",
        "Lighting",
        "ReplicatedStorage",
        "ReplicatedFirst",
        "Players",
        "StarterGui",
        "StarterPack",
        "StarterPlayer",
        "SoundService",
        "Teams",
    },
}

return Config
