-- Cuff Action Module
-- Handles handcuffing, dragging, and vehicle interactions for cuffed players

local isCuffed = false
local draggerServerId = nil
local cuffPropObject = nil

-- Cuff prop models
local CUFF_PROPS = {
    handcuffs = -1281059971,
    zipties = 623548567
}

-- Cuff prop attachment offsets
local CUFF_OFFSETS = {
    handcuffs = {
        pos = vec3(0.0, 0.07, 0.03),
        rot = vec3(10.0, 115.0, -65.0)
    },
    zipties = {
        pos = vec3(0.05, 0.04, 0.055),
        rot = vec3(-90.0, 110.0, -65.0)
    }
}

-- Animation dictionaries
local ARREST_ANIM_DICT = "mp_arrest_paired"
local ARRESTING_ANIM_DICT = "mp_arresting"
local CUFF_ANIM_COP = "cop_p2_back_left"
local CUFF_ANIM_CROOK = "crook_p2_back_left"
local UNCUFF_ANIM = "a_uncuff"
local WALK_ANIM_DICT = "anim@move_m@prisoner_cuffed"
local RUN_ANIM_DICT = "anim@move_m@trash"

local wasPlayingCuffAnim = false
local needsAnimReplay = false

-- Get ped from server ID
local function getPedFromServerId(serverId)
    local player = GetPlayerFromServerId(serverId)
    if player == 0 then
        return nil
    end
    return GetPlayerPed(player)
end

-- Create steal action
Actions.createPlayer("steal", "eye", Editable.searchPlayer)

-- Create handcuff action
Actions.createPlayer("handcuff", "handcuffs", function(targetServerId)
    TriggerServerEvent("lunar_unijob:cuffToggle", targetServerId, "handcuffs")
end)

-- Create ziptie action
Actions.createPlayer("ziptie", "link", function(targetServerId)
    TriggerServerEvent("lunar_unijob:cuffToggle", targetServerId, "zipties")
end)

-- Event: Cuff receiver (person being cuffed)
RegisterNetEvent("lunar_unijob:cuffReceiver", function(cufferServerId)
    local cuffType = lib.callback.await("lunar_unijob:getPlayerCuffState", false, cache.serverId)
    local cufferPed = getPedFromServerId(cufferServerId)
    
    if not cufferPed then
        return
    end
    
    if cuffType then
        -- Being cuffed
        SetEnableHandcuffs(cache.ped, true)
        DisablePlayerFiring(cache.ped, true)
        SetCurrentPedWeapon(cache.ped, -1569615261, true)
        SetPedCanPlayGestureAnims(cache.ped, false)
        
        lib.requestAnimDict(ARREST_ANIM_DICT)
        
        -- Attach to cuffer for animation
        AttachEntityToEntity(
            cache.ped, cufferPed, 11816,
            -0.1, 0.45, 0.0,
            0.0, 0.0, 20.0,
            false, false, false, false, 20, false
        )
        
        TaskPlayAnim(cache.ped, ARREST_ANIM_DICT, CUFF_ANIM_CROOK, 8.0, -8.0, 5500, 33, 0, false, false, false)
        
        Wait(3500)
        
        DetachEntity(cache.ped, true, false)
        RemoveAnimDict(ARREST_ANIM_DICT)
        
        -- Create and attach cuff prop
        local propModel = CUFF_PROPS[cuffType]
        local propOffset = CUFF_OFFSETS[cuffType]
        
        lib.requestModel(propModel)
        cuffPropObject = CreateObject(propModel, 0, 0, 0, true, true, true)
        
        local boneIndex = GetPedBoneIndex(cache.ped, 18905)
        AttachEntityToEntity(
            cuffPropObject, cache.ped, boneIndex,
            propOffset.pos.x, propOffset.pos.y, propOffset.pos.z,
            propOffset.rot.x, propOffset.rot.y, propOffset.rot.z,
            true, true, false, true, 1, true
        )
    else
        -- Being uncuffed
        if draggerServerId then
            DetachEntity(cache.ped)
            draggerServerId = nil
        end
        
        AttachEntityToEntity(
            cache.ped, cufferPed, 11816,
            -0.1, 0.65, 0.0,
            0.0, 0.0, 20.0,
            false, false, false, false, 20, false
        )
        
        Wait(2000)
        
        DetachEntity(cache.ped, true, false)
        SetEnableHandcuffs(cache.ped, false)
        DisablePlayerFiring(cache.ped, false)
        SetCurrentPedWeapon(cache.ped, -1569615261, true)
        SetPedCanPlayGestureAnims(cache.ped, true)
        
        if cuffPropObject then
            DeleteEntity(cuffPropObject)
        end
    end
    
    isCuffed = cuffType
end)

-- Event: Cuff sender (person doing the cuffing)
RegisterNetEvent("lunar_unijob:cuffSender", function(targetServerId)
    local targetCuffed = lib.callback.await("lunar_unijob:getPlayerCuffState", false, targetServerId)
    
    if targetCuffed then
        -- Cuffing animation
        lib.requestAnimDict(ARREST_ANIM_DICT)
        TaskPlayAnim(cache.ped, ARREST_ANIM_DICT, CUFF_ANIM_COP, 8.0, -8.0, 5500, 33, 0, false, false, false)
        Wait(3500)
        ClearPedTasks(cache.ped)
        RemoveAnimDict(ARREST_ANIM_DICT)
        Editable.actionPerformed("handcuff")
    else
        -- Uncuffing animation
        lib.requestAnimDict(ARRESTING_ANIM_DICT)
        TaskPlayAnim(cache.ped, ARRESTING_ANIM_DICT, UNCUFF_ANIM, 8.0, -8.0, -1, 2, 0, false, false, false)
        Wait(2000)
        ClearPedTasks(cache.ped)
        RemoveAnimDict(ARRESTING_ANIM_DICT)
        Editable.actionPerformed("unhandcuff")
    end
end)

-- Event: Sync cuff state
RegisterNetEvent("lunar_unijob:syncCuff", function()
    local cuffState = lib.callback.await("lunar_unijob:getPlayerCuffState", false, cache.serverId)
    
    if not cuffState then
        SetEnableHandcuffs(cache.ped, false)
        DisablePlayerFiring(cache.ped, false)
        SetCurrentPedWeapon(cache.ped, -1569615261, true)
        SetPedCanPlayGestureAnims(cache.ped, true)
        
        if draggerServerId then
            TriggerEvent("lunar_unijob:drag")
        end
    end
    
    isCuffed = cuffState
end)

-- Event: Drag (when being dragged by another player)
RegisterNetEvent("lunar_unijob:drag", function(draggerId)
    if not isCuffed then
        return
    end
    
    if not draggerServerId and draggerId then
        -- Start being dragged
        local draggerPed = getPedFromServerId(draggerId)
        if not draggerPed then
            return
        end
        
        AttachEntityToEntity(
            cache.ped, draggerPed, 11816,
            0.2, 0.45, 0.0,
            0.0, 0.0, 0.0,
            false, false, false, true, 2, true
        )
    else
        -- Stop being dragged
        DetachEntity(cache.ped)
        StopAnimTask(cache.ped, WALK_ANIM_DICT, "walk", 3.0)
        StopAnimTask(cache.ped, RUN_ANIM_DICT, "run", 3.0)
    end
    
    draggerServerId = draggerId
end)

-- Event: Put in vehicle
RegisterNetEvent("lunar_unijob:putInVehicle", function(vehicleNetId)
    if not isCuffed or not draggerServerId then
        return
    end
    
    if not NetworkDoesEntityExistWithNetworkId(vehicleNetId) then
        return
    end
    
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    
    -- Find first free seat
    for seatIndex = maxPassengers - 1, 0, -1 do
        if IsVehicleSeatFree(vehicle, seatIndex) then
            TaskWarpPedIntoVehicle(cache.ped, vehicle, seatIndex)
            break
        end
    end
end)

-- Event: Get out of vehicle
RegisterNetEvent("lunar_unijob:outTheVehicle", function()
    if not isCuffed or not IsPedSittingInAnyVehicle(cache.ped) then
        return
    end
    
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    TaskLeaveVehicle(cache.ped, vehicle, 64)
end)

-- Update movement animations while being dragged
local function updateDraggedMovementAnim(draggerPed)
    if IsPedWalking(draggerPed) then
        if not IsEntityPlayingAnim(cache.ped, WALK_ANIM_DICT, "walk", 3) then
            lib.requestAnimDict(WALK_ANIM_DICT)
            TaskPlayAnim(cache.ped, WALK_ANIM_DICT, "walk", 3.0, 3.0, -1, 1, 0.0, false, false, false)
            RemoveAnimDict(WALK_ANIM_DICT)
        end
    elseif IsPedRunning(draggerPed) or IsPedSprinting(draggerPed) then
        if Settings.sprintWhileDrag then
            if not IsEntityPlayingAnim(cache.ped, RUN_ANIM_DICT, "run", 3) then
                lib.requestAnimDict(RUN_ANIM_DICT)
                TaskPlayAnim(cache.ped, RUN_ANIM_DICT, "run", 3.0, 3.0, -1, 1, 0.0, false, false, false)
                RemoveAnimDict(RUN_ANIM_DICT)
            end
        else
            StopAnimTask(cache.ped, WALK_ANIM_DICT, "walk", 3.0)
            StopAnimTask(cache.ped, RUN_ANIM_DICT, "run", 3.0)
        end
    end
end

-- Cuff animation interval
SetInterval(function()
    if isCuffed then
        -- Update dragged movement if being dragged
        if draggerServerId then
            local draggerPed = getPedFromServerId(draggerServerId)
            if draggerPed then
                updateDraggedMovementAnim(draggerPed)
            end
        end
        
        -- Play idle cuff animation
        local isPlayingIdle = IsEntityPlayingAnim(cache.ped, ARRESTING_ANIM_DICT, "idle", 3)
        
        if not isPlayingIdle or Config.forceCuffAnim or needsAnimReplay then
            lib.requestAnimDict(ARRESTING_ANIM_DICT)
            TaskPlayAnim(cache.ped, ARRESTING_ANIM_DICT, "idle", 8.0, -8, -1, 49, 0.0, false, false, false)
            RemoveAnimDict(ARRESTING_ANIM_DICT)
            wasPlayingCuffAnim = true
            needsAnimReplay = false
        end
        
        -- Check for ragdoll to replay animation
        if IsPedRagdoll(cache.ped) then
            needsAnimReplay = true
        end
    else
        -- Clear animation when uncuffed
        if wasPlayingCuffAnim then
            if IsEntityPlayingAnim(cache.ped, ARRESTING_ANIM_DICT, "idle", 3) then
                ClearPedTasks(cache.ped)
                wasPlayingCuffAnim = false
            end
        end
    end
end, 100)

-- Handcuff controls thread
CreateThread(function()
    while true do
        if isCuffed then
            Editable.handcuffControls()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Check if player is handcuffed
function IsHandcuffed()
    return isCuffed
end

-- Check if player is being dragged
function IsDragged()
    return draggerServerId ~= nil
end

-- Export functions
exports("isCuffed", IsHandcuffed)
exports("isDragged", IsDragged)
