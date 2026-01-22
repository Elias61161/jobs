-- Vehicle Actions Module
-- Handles vehicle-related actions (hijack, repair, clean, impound)

-- Send vehicle action to server
local function sendVehicleAction(vehicle, action)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent("lunar_unijob:performVehicleAction", netId, action)
end

-- Handle vehicle action on client
RegisterNetEvent("lunar_unijob:performVehicleAction", function(netId, action)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    
    if not DoesEntityExist(vehicle) then
        return
    end
    
    if action == "hijack" then
        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    elseif action == "repair" then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true)
    elseif action == "clean" then
        SetVehicleDirtLevel(vehicle, 0.0)
    elseif action == "impound" then
        SetEntityAsMissionEntity(vehicle)
        DeleteVehicle(vehicle)
    end
end)

-- Hijack vehicle action
Actions.createVehicle("hijack", "user-ninja", function(vehicle)
    local hasAccess = lib.callback.await("lunar_unijob:hijackVehicle", false)
    
    TaskStartScenarioInPlace(cache.ped, "PROP_HUMAN_BUM_BIN", 0, true)
    
    if hasAccess then
        local minigameSuccess = Editable.lockpickMinigame()
        
        if minigameSuccess then
            local progressSuccess = LR.progressBar(
                locale("progress_hijack"),
                Settings.durations.hijack,
                false
            )
            
            if progressSuccess then
                sendVehicleAction(vehicle, "hijack")
                LR.notify(locale("hijacked"), "success")
            end
        end
    end
    
    ClearPedTasks(cache.ped)
end)

-- Repair vehicle action
Actions.createVehicle("repair", "screwdriver-wrench", function(vehicle)
    local hasAccess = lib.callback.await("lunar_unijob:repairVehicle", false)
    
    if hasAccess then
        local success = LR.progressBar(
            locale("progress_repair"),
            Settings.durations.repair,
            false,
            { scenario = "PROP_HUMAN_BUM_BIN" }
        )
        
        if success then
            sendVehicleAction(vehicle, "repair")
            LR.notify(locale("repaired"), "success")
        end
    end
end)

-- Clean vehicle action
Actions.createVehicle("clean", "hand-sparkles", function(vehicle)
    local hasAccess = lib.callback.await("lunar_unijob:cleanVehicle", false)
    
    if hasAccess then
        local success = LR.progressBar(
            locale("progress_clean"),
            Settings.durations.clean,
            false,
            { scenario = "WORLD_HUMAN_MAID_CLEAN" }
        )
        
        if success then
            sendVehicleAction(vehicle, "clean")
            LR.notify(locale("cleaned"), "success")
        end
    end
end)

-- Impound vehicle action
Actions.createVehicle("impound", "truck", function(vehicle)
    local hasAccess = lib.callback.await("lunar_unijob:impoundVehicle", false)
    
    if hasAccess then
        local success = LR.progressBar(
            locale("progress_impound"),
            Settings.durations.impound,
            false,
            { scenario = "CODE_HUMAN_MEDIC_TEND_TO_DEAD" }
        )
        
        if success then
            sendVehicleAction(vehicle, "impound")
            LR.notify(locale("impounded"), "success")
        end
    end
end)
