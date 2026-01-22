-- Client Utils Module
-- Provides utility functions for client-side operations

local createdEntities = {}

-- Check if player has permission to use job creator
function Utils.hasPermission()
    return lib.callback.await("lunar_unijob:hasPermission", false)
end

-- Create and attach a prop to the player
local function createAttachedProp(propData)
    lib.requestModel(propData.model)
    
    local playerCoords = GetEntityCoords(cache.ped)
    local prop = CreateObject(propData.model, playerCoords.x, playerCoords.y, playerCoords.z, true, true, true)
    
    local boneIndex = GetPedBoneIndex(cache.ped, propData.bone or 60309)
    
    AttachEntityToEntity(
        prop,
        cache.ped,
        boneIndex,
        propData.position.x,
        propData.position.y,
        propData.position.z,
        propData.rotation.x,
        propData.rotation.y,
        propData.rotation.z,
        true, true, false, true, 0, true
    )
    
    SetModelAsNoLongerNeeded(propData.model)
    return prop
end

-- Check if player is currently playing an animation
function Utils.isPlayingAnim(animData)
    if animData.dict and animData.clip then
        return IsEntityPlayingAnim(cache.ped, animData.dict, animData.clip, 3)
    elseif animData.scenario then
        return IsPedUsingScenario(cache.ped, animData.scenario)
    end
    return false
end

-- Play an animation with optional props
function Utils.playAnim(animData, propData)
    if animData.dict and animData.clip then
        -- Play animation
        lib.requestAnimDict(animData.dict)
        TaskPlayAnim(
            cache.ped,
            animData.dict,
            animData.clip,
            animData.blendIn or 3.0,
            animData.blendOut or 1.0,
            animData.duration or -1,
            animData.flag or 49,
            animData.playbackRate or 0,
            animData.lockX or false,
            animData.lockY or false,
            animData.lockZ or false
        )
    elseif animData.scenario then
        -- Play scenario
        local playEnter = animData.playEnter
        if playEnter == nil then
            playEnter = true
        end
        
        TaskStartScenarioInPlace(cache.ped, animData.scenario, 0, playEnter)
        
        -- Clean up scenario objects when done
        CreateThread(function()
            while Utils.isPlayingAnim(animData) do
                Wait(100)
            end
            local coords = GetEntityCoords(cache.ped)
            ClearAreaOfObjects(coords.x, coords.y, coords.z, 2.0, 0)
        end)
    end
    
    -- Handle props if provided
    if not propData then
        return
    end
    
    local props = {}
    local propList = propData
    
    -- Normalize to array
    if table.type(propData) == "hash" then
        propList = { propData }
    end
    
    -- Create props
    for _, prop in ipairs(propList) do
        table.insert(props, createAttachedProp(prop))
    end
    
    -- Clean up props when animation ends
    CreateThread(function()
        while true do
            Wait(100)
            if not Utils.isPlayingAnim(animData) then
                for _, prop in ipairs(props) do
                    DeleteEntity(prop)
                end
                
                if animData.scenario then
                    local coords = GetEntityCoords(cache.ped)
                    ClearAreaOfObjects(coords.x, coords.y, coords.z, 2.0, 0)
                end
                break
            end
        end
    end)
end

-- Convert table to vector4
local function tableToVector4(tbl)
    if not tbl.x or not tbl.y or not tbl.z then
        return nil
    end
    return vector4(tbl.x, tbl.y, tbl.z, tbl.w or 0.0)
end

-- Create props at a location
function Utils.createProps(coords, data)
    local vec = tableToVector4(coords)
    if not vec then
        return
    end
    
    local propList = data.prop
    if table.type(data.prop) == "hash" then
        propList = { data.prop }
    end
    
    for _, propData in ipairs(propList) do
        if IsModelValid(propData.model) then
            table.insert(createdEntities, Utils.createProp(vec, propData))
        end
    end
end

-- Create peds at a location
function Utils.createPeds(coords, data)
    local vec = tableToVector4(coords)
    if not vec then
        return
    end
    
    local pedList = data.ped
    if table.type(data.ped) == "hash" then
        pedList = { data.ped }
    end
    
    for _, pedData in ipairs(pedList) do
        if IsModelValid(pedData.model) then
            table.insert(createdEntities, Utils.createPed(vec, pedData))
        end
    end
end

-- Remove all created entities
function Utils.removeEntities()
    for _, entity in ipairs(createdEntities) do
        entity.remove()
    end
    table.wipe(createdEntities)
end

-- Convert animation prop data to progress bar format
function Utils.convertAnimProp(propData)
    if not propData then
        return nil
    end
    
    local result = {}
    local propList = propData
    
    if table.type(propData) == "hash" then
        propList = { propData }
    end
    
    for _, prop in ipairs(propList) do
        table.insert(result, {
            model = prop.model,
            bone = prop.bone,
            pos = prop.position,
            rot = prop.rotation
        })
    end
    
    return result
end
