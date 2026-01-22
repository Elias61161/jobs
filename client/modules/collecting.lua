-- Collecting Module
-- Handles job collecting interaction points

local isCollecting = false
local collectingPoints = {}

-- Check if ped is in an invalid state for collecting
local function isPedBusy()
    return IsPedRagdoll(cache.ped) or
           IsPedFalling(cache.ped) or
           IsPedVaulting(cache.ped) or
           IsPedInMeleeCombat(cache.ped) or
           IsPedClimbing(cache.ped) or
           IsPedInCover(cache.ped) or
           IsPedReloading(cache.ped) or
           IsPedGettingIntoAVehicle(cache.ped) or
           IsPedDiving(cache.ped) or
           IsPedBeingStunned(cache.ped)
end

-- Start collecting action
local function startCollecting(args)
    -- Check if in vehicle
    if IsPedInAnyVehicle(cache.ped, false) then
        return
    end
    
    -- Remove weapons if armed
    if IsPedArmed(cache.ped, 6) then
        local weapon = GetSelectedPedWeapon(cache.ped)
        if weapon ~= -1569615261 then
            RemoveAllPedWeapons(cache.ped, false)
            Wait(1000)
        end
    end
    
    local collectData = args.data
    local collectIndex = args.index
    local locationIndex = args.locationIndex
    
    -- Request to start collecting from server
    local canCollect, errorMsg = lib.callback.await("lunar_unijob:startCollecting", false, collectIndex, locationIndex)
    
    if not canCollect then
        LR.notify(errorMsg or locale("cant_collect"), "error")
        return
    end
    
    isCollecting = true
    
    CreateThread(function()
        local animation = collectData.animation
        local animationProp = collectData.animationProp
        
        -- Play animation if defined
        if animation then
            Utils.playAnim(animation, animationProp)
        end
        
        -- Collecting loop
        while isCollecting do
            local success = LR.progressBar(collectData.progress, collectData.duration, true)
            
            if not success then
                TriggerServerEvent("lunar_unijob:stopCollecting")
                isCollecting = false
            end
            
            Wait(0)
        end
        
        -- Wait for ped to be in valid state
        while isPedBusy() do
            Wait(100)
        end
        
        ClearPedTasks(cache.ped)
        
        -- Clean up scenario objects if using scenario animation
        if animation and animation.scenario then
            while Utils.isPlayingAnim(animation) do
                Wait(100)
            end
            
            local coords = GetEntityCoords(cache.ped)
            ClearAreaOfObjects(coords.x, coords.y, coords.z, 2.0, 0)
        end
    end)
end

-- Stop collecting action
local function stopCollecting()
    TriggerServerEvent("lunar_unijob:stopCollecting")
    isCollecting = false
    
    if LR.progressActive() then
        LR.cancelProgress()
    end
end

-- Event: Stop collecting from server
RegisterNetEvent("lunar_unijob:stopCollecting", function(errorMsg)
    isCollecting = false
    
    if LR.progressActive() then
        LR.cancelProgress()
    end
    
    if errorMsg then
        LR.notify(errorMsg, "error")
    end
end)

-- Create collecting points for a job
local function create(jobData)
    if not jobData.collecting then
        return
    end
    
    for collectIndex, collectData in ipairs(jobData.collecting) do
        for locationIndex, coords in ipairs(collectData.locations or {}) do
            if not coords then goto continue end
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = collectData.radius or Config.defaultRadius,
                options = {
                    {
                        label = collectData.label or locale("start_collecting"),
                        icon = collectData.icon or "hand",
                        args = {
                            data = collectData,
                            index = collectIndex,
                            locationIndex = locationIndex
                        },
                        canInteract = function()
                            return not isCollecting and not IsPedInMeleeCombat(cache.ped)
                        end,
                        onSelect = startCollecting
                    },
                    {
                        label = locale("cancel"),
                        icon = "circle-xmark",
                        canInteract = function()
                            return isCollecting
                        end,
                        onSelect = stopCollecting
                    }
                }
            }, collectData.target)
            
            table.insert(collectingPoints, point)
            
            ::continue::
        end
    end
end

-- Clear all collecting points
local function clear()
    for _, point in ipairs(collectingPoints) do
        point.remove()
    end
    table.wipe(collectingPoints)
end

-- Export module
Collecting = {
    create = create,
    clear = clear
}
