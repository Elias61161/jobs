-- Carry Action Module
-- Handles carrying other players

local carryTarget = nil

-- Get ped from server ID
local function getPedFromServerId(serverId)
    local player = GetPlayerFromServerId(serverId)
    if player == 0 then
        return nil
    end
    return GetPlayerPed(player)
end

-- Stop carrying
local function stopCarry()
    if carryTarget then
        TriggerServerEvent("lunar_unijob:stopCarry")
        Binds.interact.removeListener("stop_carry")
    end
end

-- Carrier animation loop (person doing the carrying)
local function carrierAnimLoop()
    Binds.interact.addListener("stop_carry", stopCarry)
    LR.showUI(locale("stop_carrying", Binds.interact:getCurrentKey()))
    
    while carryTarget do
        -- Keep playing carry animation
        if not IsEntityPlayingAnim(cache.ped, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 3) then
            lib.requestAnimDict("missfinale_c2mcs_1")
            TaskPlayAnim(cache.ped, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, -8.0, -1, 49, 0, false, false, false)
            RemoveAnimDict("missfinale_c2mcs_1")
        end
        Wait(200)
    end
    
    LR.hideUI()
end

-- Carried animation loop (person being carried)
local function carriedAnimLoop()
    Binds.interact.addListener("stop_carry", stopCarry)
    LR.showUI(locale("stop_carried", Binds.interact:getCurrentKey()))
    
    while carryTarget do
        -- Keep playing carried animation
        if not IsEntityPlayingAnim(cache.ped, "nm", "firemans_carry", 3) then
            lib.requestAnimDict("nm")
            TaskPlayAnim(cache.ped, "nm", "firemans_carry", 8.0, -8.0, -1, 33, 0, false, false, false)
            RemoveAnimDict("nm")
        end
        
        -- Stop if player dies
        if IsPlayerDead(cache.playerId) then
            stopCarry()
            break
        end
        
        Wait(200)
    end
    
    LR.hideUI()
end

-- Create carry action
Actions.createPlayer("carry", "hands", function(targetServerId)
    carryTarget = targetServerId
    TriggerServerEvent("lunar_unijob:carry", targetServerId)
    CreateThread(carrierAnimLoop)
    Editable.actionPerformed("carry")
end)

-- Sync carry event (when being carried)
RegisterNetEvent("lunar_unijob:syncCarry", function(carrierServerId)
    carryTarget = carrierServerId
    
    local carrierPed = getPedFromServerId(carrierServerId)
    if not carrierPed then
        return
    end
    
    -- Attach to carrier
    AttachEntityToEntity(
        cache.ped, carrierPed, 0,
        0.27, 0.15, 0.63,
        0.5, 0.5, 180,
        false, false, false, false, 2, false
    )
    
    CreateThread(carriedAnimLoop)
end)

-- Stop carry event
RegisterNetEvent("lunar_unijob:stopCarry", function(shouldDetach)
    carryTarget = nil
    
    if shouldDetach then
        DetachEntity(cache.ped)
    end
    
    ClearPedSecondaryTask(cache.ped)
end)

-- Check if carry is active
function IsCarryActive()
    return carryTarget ~= nil
end
