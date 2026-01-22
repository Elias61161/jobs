-- Advanced Collecting Module
-- Handles collectable item spawning and interaction

local collectablePoints = {}

-- Handle collecting an item
local function collectItem(data)
    -- Check if player is in a vehicle
    if IsPedInAnyVehicle(cache.ped, true) then
        return
    end
    
    -- Check for required item
    local requiredItem = data.collecting.requiredItem
    if requiredItem and requiredItem ~= "" then
        if not Framework.hasItem(requiredItem) then
            LR.notify(
                locale("missing_item", Utils.getItemLabel(requiredItem)),
                "error"
            )
            return
        end
    end
    
    -- Harvest the collectable
    local success = lib.callback.await("lunar_unijob:harvestCollectable", false, data.name, data.index)
    
    if not success then
        LR.notify(msg, "error")
        return
    end
    
    -- Face the collectable
    Utils.makeEntityFaceCoords(cache.ped, data.coords)
    
    -- Show progress bar
    LR.progressBar(
        data.collecting.progress,
        data.collecting.duration,
        false,
        data.collecting.animation,
        Utils.convertAnimProp(data.collecting.animationProp)
    )
end

-- Spawn a collectable at a location
local function spawnCollectable(jobData, collectingIndex, locationIndex, coords, pointId)
    local collectingData = jobData.advancedCollecting[collectingIndex]
    local pointKey = string.format("%s_%s_%s", jobData.name, collectingIndex, locationIndex)
    
    -- Initialize point tracking
    if not collectablePoints[pointKey] then
        collectablePoints[pointKey] = {}
    end
    
    -- Check if already spawned
    if collectablePoints[pointKey][pointId] then
        return
    end
    
    -- Create point for spawning area
    local point = lib.points.new({
        coords = coords,
        distance = 100.0
    })
    
    local spawnedEntity = nil
    local interactionPoint = nil
    
    point.onEnter = function()
        -- Request prop model
        lib.requestModel(collectingData.propModel)
        
        -- Get ground Z coordinate
        local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
        local searchHeight = 50.0
        
        -- Search for ground if not found
        while groundZ == 0.0 and searchHeight < 500.0 do
            searchHeight = searchHeight + 50.0
            _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + searchHeight, false)
            Wait(0)
        end
        
        -- Create the collectable object
        spawnedEntity = CreateObjectNoOffset(
            collectingData.propModel,
            coords.x,
            coords.y,
            groundZ + 1.0,
            false,
            false
        )
        
        -- Place on ground properly
        PlaceObjectOnGroundProperly(spawnedEntity)
        Wait(0)
        
        -- Freeze and random rotation
        FreezeEntityPosition(spawnedEntity, true)
        SetEntityHeading(spawnedEntity, math.random(0, 360) + 0.0)
        
        -- Slightly lower to ground
        local offsetCoords = GetOffsetFromEntityInWorldCoords(spawnedEntity, 0.0, 0.0, -0.1)
        SetEntityCoords(spawnedEntity, offsetCoords.x, offsetCoords.y, offsetCoords.z)
        
        -- Get entity coordinates for interaction
        local entityCoords = GetEntityCoords(spawnedEntity)
        local interactionOffset = collectingData.interactionOffset or vector3(0.0, 0.0, 0.0)
        
        -- Create interaction point
        local interactionCoords = vector3(
            entityCoords.x + interactionOffset.x,
            entityCoords.y + interactionOffset.y,
            entityCoords.z + interactionOffset.z
        )
        
        interactionPoint = Utils.createInteractionPoint({
            coords = interactionCoords,
            radius = 0.75,
            options = {
                {
                    label = collectingData.label or locale("start_collecting"),
                    icon = collectingData.icon or "hand",
                    onSelect = collectItem,
                    args = {
                        collecting = collectingData,
                        name = jobData.name,
                        index = collectingIndex,
                        coords = entityCoords
                    },
                    canInteract = function()
                        return not LR.progressActive()
                    end
                }
            }
        })
    end
    
    point.onExit = function()
        -- Clean up spawned entity
        if spawnedEntity then
            DeleteEntity(spawnedEntity)
        end
        
        -- Clean up interaction point
        if interactionPoint and interactionPoint.remove then
            interactionPoint.remove()
        end
    end
    
    collectablePoints[pointKey][pointId] = point
end

-- Event: Spawn collectable
RegisterNetEvent("lunar_unijob:spawnCollectable", function(jobName, collectingIndex, locationIndex, coords, pointId)
    -- Wait for job data to be available
    while not GetJobs()[jobName] do
        Wait(100)
    end
    
    local jobData = GetJobs()[jobName]
    spawnCollectable(jobData, collectingIndex, locationIndex, coords, pointId)
end)

-- Get all collectables from server
lib.callback("lunar_unijob:getCollectables", false, function(collectables)
    for _, collectableGroup in ipairs(collectables) do
        for pointId, coords in pairs(collectableGroup.spawned) do
            -- Wait for job data to be available
            while not GetJobs()[collectableGroup.jobName] do
                Wait(100)
            end

            local jobData = GetJobs()[collectableGroup.jobName]
            spawnCollectable(
                jobData,
                collectableGroup.index,
                collectableGroup.locationIndex,
                coords,
                pointId
            )
        end
    end
end)

-- Event: Remove collectable
RegisterNetEvent("lunar_unijob:removeCollectable", function(pointKey, pointId)
    local point = collectablePoints[pointKey][pointId]
    if point then
        point.onExit(point)
        point.remove(point)
    end
end)

-- Event: Clear all advanced collecting
RegisterNetEvent("lunar_unijob:clearAdvancedCollecting", function(pointKeys)
    for _, pointKey in ipairs(pointKeys) do
        if collectablePoints[pointKey] then
            for _, point in pairs(collectablePoints[pointKey]) do
                point.onExit(point)
                point.remove(point)
            end
            collectablePoints[pointKey] = nil
        end
    end
end)
