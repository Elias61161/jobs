-- Animation Zones Module
-- Handles job animation zone interaction points

local jobAnimZones = {}
local globalAnimZones = {}
local currentAnimation = nil

-- Get current player position and heading as vector4
local function getCurrentPosition()
    local coords = GetEntityCoords(cache.ped)
    local heading = GetEntityHeading(cache.ped)
    return vector4(coords.x, coords.y, coords.z, heading)
end

-- Stop current animation
local function stopAnimation()
    if not currentAnimation then
        return
    end
    
    LR.hideUI()
    Binds.interact.removeListener("stop_anim")
    TriggerServerEvent("lunar_unijob:stopAnimation", currentAnimation.name)
    ClearPedTasks(cache.ped)
    
    -- Return to original position if configured
    if currentAnimation.lastCoords then
        SetEntityCoords(cache.ped, currentAnimation.lastCoords.x, currentAnimation.lastCoords.y, currentAnimation.lastCoords.z - 1.0)
        SetEntityHeading(cache.ped, currentAnimation.lastCoords.w)
    end
    
    FreezeEntityPosition(cache.ped, false)
    currentAnimation = nil
end

-- Start animation at zone
local function startAnimation(args)
    if currentAnimation then
        return
    end
    
    local zoneName = args.name
    local animZone = args.animationZone
    local coords = args.coords
    
    -- Check if zone is occupied (if required)
    if animZone.checkOccupied then
        local canStart = lib.callback.await("lunar_unijob:startAnimation", false, zoneName)
        if not canStart then
            return
        end
    end
    
    -- Store animation state
    currentAnimation = {
        name = zoneName,
        lastCoords = animZone.back and getCurrentPosition() or nil
    }
    
    -- Freeze player if not disabled
    if not animZone.disableFreeze then
        FreezeEntityPosition(cache.ped, true)
    end
    
    -- Move player to position if configured
    if animZone.move then
        SetEntityCoords(cache.ped, coords.x, coords.y, coords.z - 1.0)
        if coords.w then
            SetEntityHeading(cache.ped, coords.w)
        end
    end
    
    -- Handle timed or continuous animation
    if animZone.duration then
        if animZone.progress then
            -- Show progress bar with animation
            local animProp = Utils.convertAnimProp(animZone.animationProp)
            LR.progressBar(animZone.progress, animZone.duration, false, animZone.animation, animProp)
        else
            -- Just play animation for duration
            Utils.playAnim(animZone.animation, animZone.animationProp)
            Wait(animZone.duration)
        end
        
        -- Show notification if configured
        if animZone.notify then
            LR.notify(animZone.notify, "success")
        end
        
        stopAnimation()
    else
        -- Continuous animation with manual stop
        Utils.playAnim(animZone.animation, animZone.animationProp)
        
        local stopLabel = animZone.stop or locale("stop_anim")
        LR.showUI(string.format("[%s] - %s", Binds.interact:getCurrentKey(), stopLabel))
        Binds.interact.addListener("stop_anim", stopAnimation)
    end
end

-- Create animation zone points for a specific zone
local function createAnimZonePoints(jobData, zoneIndex)
    local animZone = jobData.animationZones[zoneIndex]
    
    for locationIndex, coords in ipairs(animZone.locations or {}) do
        if not coords then goto continue end
        -- Apply offset if configured
        if animZone.offset then
            if coords.w then
                coords = vector4(
                    coords.x + animZone.offset.x,
                    coords.y + animZone.offset.y,
                    coords.z + animZone.offset.z,
                    coords.w
                )
            else
                coords = vector3(
                    coords.x + animZone.offset.x,
                    coords.y + animZone.offset.y,
                    coords.z + animZone.offset.z
                )
            end
        end
        
        local zoneName = string.format("%s_%s_%s", jobData.name, zoneIndex, locationIndex)
        
        local point = Utils.createInteractionPoint({
            coords = coords,
            radius = animZone.radius or Config.defaultRadius,
            options = {
                {
                    label = animZone.label,
                    icon = animZone.icon,
                    onSelect = startAnimation,
                    args = {
                        name = zoneName,
                        animationZone = animZone,
                        coords = coords
                    },
                    canInteract = function()
                        return currentAnimation == nil
                    end
                }
            }
        }, animZone.target)
        
        -- Store in appropriate table
        if animZone.global then
            table.insert(globalAnimZones, point)
        else
            table.insert(jobAnimZones, point)
        end
        
        ::continue::
    end
end

-- Create animation zones for a job (non-global only)
local function create(jobData)
    if not jobData.animationZones then
        return
    end
    
    for zoneIndex, animZone in ipairs(jobData.animationZones) do
        if not animZone.global then
            createAnimZonePoints(jobData, zoneIndex)
        end
    end
end

-- Clear job-specific animation zones
local function clear()
    for _, point in ipairs(jobAnimZones) do
        point.remove()
    end
    table.wipe(jobAnimZones)
end

-- Update global animation zones (recreate from all jobs)
local function update()
    -- Clear existing global zones
    for _, point in ipairs(globalAnimZones) do
        point.remove()
    end
    table.wipe(globalAnimZones)
    
    -- Recreate global zones from all jobs
    local jobs = GetJobs()
    for _, jobData in pairs(jobs) do
        if jobData.animationZones then
            for zoneIndex, animZone in ipairs(jobData.animationZones) do
                if animZone.global then
                    createAnimZonePoints(jobData, zoneIndex)
                end
            end
        end
    end
end

-- Export module
AnimationZones = {
    create = create,
    clear = clear,
    update = update
}
