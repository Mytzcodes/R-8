-- DEFIT BLOX — Module 05: Interaction Observer
-- Collects observable interaction points (ProximityPrompt, ClickDetector, TouchTransmitter, GUI controls).
-- NEVER fires RemoteEvents or RemoteFunctions.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local InteractionObserver = {}

function InteractionObserver.run(_config: { [string]: any }, transport: any): ({ [string]: any }, boolean)
    local prompts = {}
    local clickDetectors = {}
    local touchObjects = {}
    local guiControls = {}

    local wsDesc = Workspace:GetDescendants()
    local total = #wsDesc

    for idx, inst in ipairs(wsDesc) do
        if inst:IsA("ProximityPrompt") then
            table.insert(prompts, {
                name = inst.Name,
                full_name = inst:GetFullName(),
                parent = inst.Parent and inst.Parent:GetFullName() or "",
                action_text = inst.ActionText,
                object_text = inst.ObjectText,
                hold_duration = inst.HoldDuration,
                max_activation_distance = inst.MaxActivationDistance,
                enabled = inst.Enabled,
            })
        elseif inst:IsA("ClickDetector") then
            table.insert(clickDetectors, {
                name = inst.Name,
                full_name = inst:GetFullName(),
                parent = inst.Parent and inst.Parent:GetFullName() or "",
                max_activation_distance = inst.MaxActivationDistance,
            })
        elseif inst:IsA("TouchTransmitter") and inst.Parent then
            table.insert(touchObjects, {
                name = inst.Parent.Name,
                full_name = inst.Parent:GetFullName(),
                class_name = inst.Parent.ClassName,
            })
        end

        if idx % 300 == 0 or idx == total then
            transport:sendProgress(
                "INTERACTION_OBSERVER",
                idx,
                math.max(1, total),
                string.format("Scanning Workspace interactions %d/%d", idx, total)
            )
            task.wait()
        end
    end

    -- Observable GUI controls (PlayerGui if available, plus StarterGui)
    local guiRoots = { StarterGui }
    local localPlayer = Players.LocalPlayer
    if localPlayer then
        local pg = localPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            table.insert(guiRoots, pg)
        end
    end

    for _, root in ipairs(guiRoots) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("TextButton") or inst:IsA("ImageButton") or inst:IsA("TextBox") then
                table.insert(guiControls, {
                    name = inst.Name,
                    class_name = inst.ClassName,
                    full_name = inst:GetFullName(),
                    visible = inst.Visible,
                    active = inst.Active,
                    text = (inst:IsA("TextButton") or inst:IsA("TextBox")) and inst.Text or nil,
                })
            end
        end
    end

    local result = {
        proximity_prompts = prompts,
        click_detectors = clickDetectors,
        touch_objects = touchObjects,
        gui_controls = guiControls,
    }

    local ok = transport:sendEnvelope(
        "/api/extraction/chunk",
        "INTERACTION_OBSERVER",
        result,
        "interactions_001",
        { total_chunks = 1 }
    )
    return result, ok
end

return InteractionObserver
