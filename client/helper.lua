-- Helper Module
-- Provides coordinate selection tools for the job creator UI

-- Get bridge config for prompts
local bridgeConfig = exports.lunar_bridge:getConfig()
local promptsEnabled = bridgeConfig.Prompts.Enabled

-- Simple coordinate selection (player position)
local function getSimpleCoords()
    LR.showUI("[E] - Select point")
    
    while true do
        DisableControlAction(0, 38, true)  -- E key
        DisableControlAction(0, 105, true) -- Mouse scroll
        
        if IsDisabledControlJustReleased(0, 38) then
            local coords = GetEntityCoords(cache.ped)
            local heading = GetEntityHeading(cache.ped)
            LR.hideUI()
            return vector4(coords.x, coords.y, coords.z, heading)
        end
        
        Wait(0)
    end
end

-- Advanced coordinate selection with raycast and entity preview
local function getAdvancedCoords(peds, props)
    local hitCoords = nil
    local currentHeading = 0.0
    local hasPeds = #peds > 0
    local createdProps = {}
    local createdPeds = {}
    local playerCoords = GetEntityCoords(cache.ped)
    local hasLargeEntity = false
    local minZ = 0.0
    
    -- Create preview props
    for i = 1, #props do
        local minDim, maxDim = GetModelDimensions(props[1].model)
        local height = maxDim.z - minDim.z
        
        if height >= 1.0 then
            hasLargeEntity = true
        end
        
        if minZ > minDim.z then
            minZ = minDim.z
        end
        
        local spawnCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z - 10.0)
        createdProps[i] = Utils.createProp(spawnCoords, props[i])
    end
    
    -- Create preview peds
    for i = 1, #peds do
        local spawnCoords = vector3(playerCoords.x, playerCoords.y, playerCoords.z - 10.0)
        createdPeds[i] = Utils.createPed(spawnCoords, peds[i])
        hasLargeEntity = true
    end
    
    -- Raycast interval
    local raycastInterval = SetInterval(function()
        local hit, _, coords = lib.raycast.cam(-1, 4, 100.0)
        if hit then
            hitCoords = coords
        end
    end, 0)
    
    LR.showUI("[LMOUSE] - Select point")
    
    while true do
        DisableControlAction(0, 24, true)  -- Left mouse
        DisableControlAction(0, 105, true) -- Mouse scroll
        DisableControlAction(0, 73, true)  -- X key
        
        -- Confirm selection
        if IsDisabledControlJustReleased(0, 24) and hitCoords then
            ClearInterval(raycastInterval)
            LR.hideUI()
            
            -- Clean up preview entities
            for i = 1, #createdProps do
                createdProps[i].remove()
            end
            for i = 1, #createdPeds do
                createdPeds[i].remove()
            end
            
            -- Calculate final Z position
            local zOffset = (hasPeds and hasLargeEntity) and 1.0 or -minZ
            
            return vector4(hitCoords.x, hitCoords.y, hitCoords.z + zOffset, currentHeading)
        end
        
        -- Rotate heading
        if IsDisabledControlJustReleased(0, 14) then
            currentHeading = currentHeading + 5.0
        end
        if IsDisabledControlJustReleased(0, 15) then
            currentHeading = currentHeading - 5.0
        end
        
        -- Update preview entities
        if hitCoords then
            if not hasPeds then
                -- Draw simple marker
                DrawSphere(hitCoords.x, hitCoords.y, hitCoords.z, 0.1, 255, 0, 255, 0.5)
                
                local lineEnd = Utils.offsetCoords(
                    vector4(hitCoords.x, hitCoords.y, hitCoords.z, currentHeading),
                    0.0, 0.15, 0.0
                )
                DrawLine(hitCoords.x, hitCoords.y, hitCoords.z, lineEnd.x, lineEnd.y, lineEnd.z, 255, 100, 255, 0.5)
            else
                -- Update prop positions
                for i = 1, #createdProps do
                    local prop = createdProps[i].get()
                    local propData = props[i]
                    local offset = propData.offset
                    
                    if prop then
                        local zOffset = hasLargeEntity and 1.0 or -minZ
                        local baseCoords = vector3(hitCoords.x, hitCoords.y, hitCoords.z + zOffset)
                        
                        if offset then
                            local heading = GetEntityHeading(prop)
                            local rotZ = (propData.rotation and propData.rotation.z) or 0.0
                            baseCoords = Utils.offsetCoords(
                                vector4(baseCoords.x, baseCoords.y, baseCoords.z, heading + rotZ),
                                offset.x or 0, offset.y or 0, offset.z or 0
                            )
                        end
                        
                        SetEntityCoords(prop, baseCoords.x, baseCoords.y, baseCoords.z)
                        SetEntityAlpha(prop, 200, false)
                        SetEntityCollision(prop, false, false)
                        
                        local rotX = (propData.rotation and propData.rotation.x) or 0.0
                        local rotY = (propData.rotation and propData.rotation.y) or 0.0
                        local rotZ = (propData.rotation and propData.rotation.z) or 0.0
                        SetEntityRotation(prop, rotX, rotY, currentHeading + rotZ)
                    end
                end
                
                -- Update ped positions
                for i = 1, #createdPeds do
                    local ped = createdPeds[i].get()
                    local pedData = peds[i]
                    local offset = pedData.offset
                    
                    if ped then
                        local baseCoords = hitCoords
                        
                        if offset then
                            local heading = GetEntityHeading(ped)
                            baseCoords = Utils.offsetCoords(
                                vector4(baseCoords.x, baseCoords.y, baseCoords.z, heading),
                                -(offset.x or 0), -(offset.y or 0), offset.z or 0
                            )
                        end
                        
                        SetEntityCoords(ped, baseCoords.x, baseCoords.y, baseCoords.z)
                        SetEntityAlpha(ped, 200, false)
                        SetEntityCollision(ped, false, false)
                        SetEntityHeading(ped, currentHeading + (pedData.heading or 0.0))
                    end
                end
            end
        end
        
        Wait(0)
    end
end

-- Format number to 4 decimal places
local function formatCoord(value)
    return tonumber(string.format("%.4f", value))
end

-- NUI Callback: Get coordinates input
RegisterNUICallback("getCoordsInput", function(data, cb)
    SetNuiFocus(false, false)
    
    local useTarget = data.target
    local forceDisableTarget = data.forceDisableTarget
    local peds = data.ped or {}
    local props = data.prop or {}
    
    -- Determine selection method
    local useAdvanced = false
    if useTarget ~= false then
        if #peds > 0 or #props > 0 or promptsEnabled then
            useAdvanced = true
        end
    end
    
    -- Get coordinates
    local coords
    if useAdvanced and not forceDisableTarget then
        coords = getAdvancedCoords(peds, props)
    end
    
    if not coords then
        coords = getSimpleCoords()
    end
    
    -- Copy to clipboard
    lib.setClipboard(tostring(coords))
    
    -- Return formatted coordinates
    cb({
        x = formatCoord(coords.x),
        y = formatCoord(coords.y),
        z = formatCoord(coords.z),
        w = formatCoord(coords.w)
    })
    
    SetNuiFocus(true, true)
end)
