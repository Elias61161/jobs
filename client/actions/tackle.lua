-- Tackle Action Module
-- Handles player tackling mechanics

local TACKLE_ANIM_DICT = "missmic2ig_11"
local TACKLE_ANIM_TACKLER = "mic_2_ig_11_intro_goon"
local TACKLE_ANIM_VICTIM = "mic_2_ig_11_intro_p_one"

local tackleCooldown = false

-- Perform tackle
local function performTackle()
    -- Check if player has access and can tackle
    if not HasAccess("tackle") then
        return
    end
    
    if tackleCooldown then
        return
    end
    
    if IsPedInAnyVehicle(cache.ped, true) then
        return
    end
    
    if not IsPedSprinting(cache.ped) then
        return
    end
    
    -- Get position in front of player
    local forwardVector = GetEntityForwardVector(cache.ped)
    local playerCoords = GetEntityCoords(cache.ped)
    local targetCoords = playerCoords + (forwardVector * 2)
    
    -- Find closest player in front
    local closestPlayer = lib.getClosestPlayer(targetCoords, Settings.tackleRadius)
    if not closestPlayer then
        return
    end
    
    -- Set cooldown
    tackleCooldown = true
    SetTimeout(Settings.tackleCooldown, function()
        tackleCooldown = false
    end)
    
    -- Trigger tackle on server
    local targetServerId = GetPlayerServerId(closestPlayer)
    TriggerServerEvent("lunar_unijob:tacklePlayer", targetServerId)
    
    -- Play tackler animation
    lib.requestAnimDict(TACKLE_ANIM_DICT)
    TaskPlayAnim(cache.ped, TACKLE_ANIM_DICT, TACKLE_ANIM_TACKLER, 8.0, -8.0, 3000, 0, 0, false, false, false)
    RemoveAnimDict(TACKLE_ANIM_DICT)
end

-- Event: Play tackled animation (victim)
RegisterNetEvent("lunar_unijob:playTackledAnim", function(tacklerServerId)
    lib.requestAnimDict(TACKLE_ANIM_DICT)
    
    -- Get tackler ped
    local tacklerPlayer = GetPlayerFromServerId(tacklerServerId)
    local tacklerPed = GetPlayerPed(tacklerPlayer)
    
    -- Attach to tackler
    AttachEntityToEntity(
        cache.ped, tacklerPed, 11816,
        0.25, 0.5, 0.0,
        0.5, 0.5, 180.0,
        false, false, false, false, 2, false
    )
    
    -- Play victim animation
    TaskPlayAnim(cache.ped, TACKLE_ANIM_DICT, TACKLE_ANIM_VICTIM, 8.0, -8.0, 3000, 0, 0, false, false, false)
    
    Wait(3000)
    
    -- Detach and ragdoll
    DetachEntity(cache.ped)
    
    CreateThread(function()
        for _ = 1, 30 do
            SetPedToRagdoll(cache.ped, 1000, 1000, 0, false, false, false)
            Wait(100)
        end
    end)
    
    RemoveAnimDict(TACKLE_ANIM_DICT)
end)

-- Register tackle keybind
lib.addKeybind({
    defaultMapper = "keyboard",
    defaultKey = Config.tackleKeybind,
    name = "tackle",
    description = "Player tackling",
    onReleased = performTackle
})
