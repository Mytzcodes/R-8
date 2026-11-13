-- DEFIT BLOX — Module 08: Runtime Observer
-- Observes runtime changes (NPCs, doors, new objects, health/state) with strict time, count, and size caps.

local Workspace = game:GetService("Workspace")

local RuntimeObserver = {}

local function formatElapsed(sec: number): string
    local total = math.max(0, math.floor(sec))
    local h = math.floor(total / 3600)
    local m = math.floor((total % 3600) / 60)
    local s = total % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

function RuntimeObserver.run(
    config: { [string]: any },
    transport: any,
    npcModels: { Model }
): boolean
    local maxDuration = config.RUNTIME_OBSERVER_DURATION_SEC or 10
    local maxEvents = config.RUNTIME_OBSERVER_MAX_EVENTS or 250
    local maxBytes = config.RUNTIME_OBSERVER_MAX_BYTES or 262144
    local flushInterval = config.RUNTIME_OBSERVER_FLUSH_INTERVAL_SEC or 2

    local startTime = os.clock()
    local events = {}
    local totalEvents = 0
    local estimatedBytes = 0
    local connections: { RBXScriptConnection } = {}
    local stopped = false

    local function stop()
        if stopped then
            return
        end
        stopped = true
        for _, conn in ipairs(connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        table.clear(connections)
    end

    local function recordEvent(eventName: string, target: string, detail: any?)
        if stopped or totalEvents >= maxEvents or estimatedBytes >= maxBytes then
            stop()
            return
        end
        local elapsed = formatElapsed(os.clock() - startTime)
        local entry = {
            timestamp = elapsed,
            event = eventName,
            target = target,
            detail = detail,
        }
        table.insert(events, entry)
        totalEvents += 1
        estimatedBytes += #target + #eventName + 64
    end

    -- Record initial NPCs
    for _, npc in ipairs(npcModels) do
        recordEvent("NPC detected", npc:GetFullName())
        local hum = npc:FindFirstChildOfClass("Humanoid")
        if hum then
            table.insert(
                connections,
                hum.HealthChanged:Connect(function(newHealth)
                    recordEvent("NPC health changed", npc:GetFullName(), { health = newHealth })
                end)
            )
            table.insert(
                connections,
                hum.StateChanged:Connect(function(_old, newState)
                    recordEvent("NPC state changed", npc:GetFullName(), { state = tostring(newState) })
                end)
            )
        end
    end

    -- Watch for newly added objects in Workspace
    table.insert(
        connections,
        Workspace.DescendantAdded:Connect(function(inst)
            recordEvent("New object detected", inst:GetFullName(), { class_name = inst.ClassName })
        end)
    )

    local lastFlush = os.clock()
    while not stopped do
        local elapsed = os.clock() - startTime
        if elapsed >= maxDuration or totalEvents >= maxEvents or estimatedBytes >= maxBytes or transport.disconnected then
            break
        end

        transport:sendProgress(
            "RUNTIME_OBSERVER",
            math.floor(elapsed),
            maxDuration,
            string.format("Observing runtime events (%d/%d)", totalEvents, maxEvents)
        )

        if #events > 0 and (os.clock() - lastFlush) >= flushInterval then
            local batch = events
            events = {}
            lastFlush = os.clock()
            local ok = transport:sendEnvelope("/api/observations", "RUNTIME_OBSERVER", { events = batch })
            if not ok then
                stop()
                return false
            end
        end

        task.wait(0.5)
    end

    stop()

    if #events > 0 and not transport.disconnected then
        local ok = transport:sendEnvelope("/api/observations", "RUNTIME_OBSERVER", { events = events })
        if not ok then
            return false
        end
    end

    transport:sendProgress("RUNTIME_OBSERVER", maxDuration, maxDuration, "Runtime observation complete")
    return true
end

return RuntimeObserver
