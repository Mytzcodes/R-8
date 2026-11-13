-- DEFIT BLOX — Module 01: Instance Scanner
-- Scans client-accessible services only. Never attempts to access ServerStorage or ServerScriptService.

local CollectionService = game:GetService("CollectionService")

local Scanner = {}

local function serializeAttributes(inst: Instance): { [string]: any }
    local ok, attrs = pcall(function()
        return inst:GetAttributes()
    end)
    if not ok or type(attrs) ~= "table" then
        return {}
    end
    local out = {}
    for k, v in pairs(attrs) do
        local t = typeof(v)
        if t == "string" or t == "number" or t == "boolean" then
            out[k] = v
        else
            out[k] = tostring(v)
        end
    end
    return out
end

local function serializeTags(inst: Instance): { string }
    local ok, tags = pcall(function()
        return CollectionService:GetTags(inst)
    end)
    if not ok or type(tags) ~= "table" then
        return {}
    end
    return tags
end

function Scanner.run(config: { [string]: any }, transport: any): ({ any }, boolean)
    local services = config.CLIENT_SCAN_SERVICES or { "Workspace", "Lighting", "ReplicatedStorage" }
    local discovered = {}
    local totalServices = #services

    for sIdx, serviceName in ipairs(services) do
        if transport.disconnected then
            return discovered, false
        end

        local ok, service = pcall(function()
            return game:GetService(serviceName)
        end)

        if ok and service then
            local descOk, descendants = pcall(function()
                return service:GetDescendants()
            end)
            local list = { service }
            if descOk and type(descendants) == "table" then
                for _, d in ipairs(descendants) do
                    table.insert(list, d)
                end
            end

            for i, inst in ipairs(list) do
                pcall(function()
                    local okFull, fullName = pcall(function()
                        return inst:GetFullName()
                    end)
                    local okChildren, children = pcall(function()
                        return inst:GetChildren()
                    end)
                    table.insert(discovered, {
                        name = inst.Name,
                        class_name = inst.ClassName,
                        parent = inst.Parent and inst.Parent.Name or "DataModel",
                        full_name = okFull and fullName or inst.Name,
                        attributes = serializeAttributes(inst),
                        tags = serializeTags(inst),
                        archivable = inst.Archivable,
                        child_count = (okChildren and type(children) == "table") and #children or 0,
                    })
                end)
                if i % 200 == 0 then
                    task.wait()
                end
            end
        end

        transport:sendProgress(
            "INSTANCE_SCANNER",
            sIdx,
            totalServices,
            string.format("Scanning %s (%d instances)", serviceName, #discovered),
            #discovered,
            #discovered
        )
        task.wait()
    end

    local sent = transport:sendChunkedList(
        "INSTANCE_SCANNER",
        "instances",
        discovered,
        "scan",
        function(doneCount, totalCount)
            transport:sendProgress(
                "INSTANCE_SCANNER",
                doneCount,
                totalCount,
                string.format("Uploading instances %d/%d", doneCount, totalCount),
                totalCount,
                doneCount
            )
        end
    )

    return discovered, sent
end

return Scanner
