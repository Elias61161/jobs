-- Teleports Module
-- Handles job teleport interaction points

local teleportPoints = {}

-- Perform teleport with animation and screen fade
local function performTeleport(targetCoords, disableAnim)
    -- Play door animation if not disabled
    if not disableAnim then
        lib.requestAnimDict("anim@heists@keycard@")
        TaskPlayAnim(cache.ped, "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, false, false, false)
    end
    
    -- Fade out screen
    DoScreenFadeOut(750)
    
    -- Request collision at destination
    RequestCollisionAtCoord(targetCoords.x, targetCoords.y, targetCoords.z)
    
    Wait(1000)
    
    -- Reset artificial lights
    SetArtificialLightsState(false)
    
    -- Teleport player
    SetEntityCoords(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z)
    SetEntityHeading(cache.ped, targetCoords.w)
    SetGameplayCamRelativeHeading(0.0)
    PlaceObjectOnGroundProperly(cache.ped)
    
    Wait(1750)
    
    -- Fade in screen
    DoScreenFadeIn(500)
end

-- Handle teleport entry (going inside)
local function onTeleportEnter(args)
    local jobData = args.job
    local teleportIndex = args.index
    local teleport = jobData.teleports[teleportIndex]
    
    local exitPoint = nil
    
    -- Teleport to destination
    performTeleport(teleport.to.coords, teleport.disableAnim)
    TriggerServerEvent("lunar_unijob:teleport", teleportIndex)
    
    -- Create exit point at destination
    exitPoint = Utils.createInteractionPoint({
        coords = teleport.to.target,
        radius = teleport.radius or Config.defaultRadius,
        options = {
            {
                label = teleport.to.label or locale("go_outside"),
                icon = teleport.to.icon or "door-open",
                onSelect = function()
                    performTeleport(teleport.from.coords, teleport.disableAnim)
                    TriggerServerEvent("lunar_unijob:exitTeleport")
                    
                    if exitPoint then
                        exitPoint.remove()
                    end
                end
            }
        }
    })
end

-- Create teleport points for a job
local function create(jobData)
    if not jobData.teleports then
        return
    end
    
    for teleportIndex, teleport in ipairs(jobData.teleports) do
        local point = Utils.createInteractionPoint({
            coords = teleport.from.target,
            radius = teleport.radius or Config.defaultRadius,
            options = {
                {
                    label = teleport.from.label or locale("go_inside"),
                    icon = teleport.from.icon or "door-open",
                    onSelect = onTeleportEnter,
                    args = {
                        job = jobData,
                        index = teleportIndex
                    },
                    canInteract = function()
                        return HasGrade(teleport.grade)
                    end
                }
            }
        }, teleport.target)
        
        table.insert(teleportPoints, point)
    end
end

-- Clear all teleport points
local function clear()
    for _, point in ipairs(teleportPoints) do
        point.remove()
    end
    table.wipe(teleportPoints)
end

-- Export module
Teleports = {
    create = create,
    clear = clear
}
