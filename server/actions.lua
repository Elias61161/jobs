-- Cuff state storage
local cuffedPlayers = {}

-- Drag state storage
local draggedPlayers = {}

-- Carry state storage
local carryingPlayers = {}
local beingCarriedBy = {}

-- Actions module
Actions = {}

-- Item names configuration
local function getItemNames()
    return {
        handcuffs = Settings.handcuffsItemName,
        zipties = Settings.ziptiesItemName
    }
end

-- Cuff toggle with items (handcuffs/zipties)
local function cuffToggleWithItems(targetId)
    local src = source
    local itemNames = getItemNames()

    if not Utils.distanceCheck(src, targetId, Settings.interactDistance) then
        return
    end

    local player = Framework.getPlayerFromId(src)
    if not player then
        return
    end

    local currentCuffState = cuffedPlayers[targetId]

    if not currentCuffState then
        -- Player is not cuffed, try to cuff them
        local cuffType = nil

        if player:hasItem(itemNames.handcuffs) then
            if Actions.hasAccess(player, "handcuffs") then
                cuffType = "handcuffs"
            end
        elseif player:hasItem(itemNames.zipties) then
            if Actions.hasAccess(player, "zipties") then
                cuffType = "zipties"
            end
        else
            LR.notify(src, locale("missing_cuff"), "error")
            return
        end

        if not cuffType then
            return
        end

        cuffedPlayers[targetId] = cuffType
        player:removeItem(itemNames[cuffType], 1)

        TriggerClientEvent("lunar_unijob:cuffReceiver", targetId, src)
        TriggerClientEvent("lunar_unijob:cuffSender", src, targetId)
        Editable.onCuffStateChanged(src, targetId, true, cuffType)
    else
        -- Player is cuffed, try to uncuff them
        if not Actions.hasAccess(player, currentCuffState) then
            LR.notify(src, locale("cant_un" .. cuffedPlayers[targetId]), "error")
            return
        end

        if currentCuffState == "handcuffs" then
            player:addItem("handcuffs", 1)
        end

        cuffedPlayers[targetId] = nil

        TriggerClientEvent("lunar_unijob:cuffReceiver", targetId, src)
        TriggerClientEvent("lunar_unijob:cuffSender", src, targetId)
        Editable.onCuffStateChanged(src, targetId, false, currentCuffState)
    end
end

-- Cuff toggle without items
local function cuffToggleNoItems(targetId)
    local src = source

    if not Utils.distanceCheck(src, targetId, Settings.interactDistance) then
        return
    end

    local player = Framework.getPlayerFromId(src)
    if not player then
        return
    end

    local currentCuffState = cuffedPlayers[targetId]

    if not currentCuffState then
        -- Player is not cuffed
        if not Actions.hasAccess(player, "handcuffs") then
            LR.notify(src, locale("cant_handcuff"), "error")
            return
        end

        cuffedPlayers[targetId] = "handcuffs"

        TriggerClientEvent("lunar_unijob:cuffReceiver", targetId, src)
        TriggerClientEvent("lunar_unijob:cuffSender", src, targetId)
        Editable.onCuffStateChanged(src, targetId, true, "handcuffs")
    else
        -- Player is cuffed
        if not Actions.hasAccess(player, "handcuffs") then
            LR.notify(src, locale("cant_unhandcuff"), "error")
            return
        end

        cuffedPlayers[targetId] = nil

        TriggerClientEvent("lunar_unijob:cuffReceiver", targetId, src)
        TriggerClientEvent("lunar_unijob:cuffSender", src, targetId)
        Editable.onCuffStateChanged(src, targetId, false, "handcuffs")
    end
end

-- Register cuff toggle event
RegisterNetEvent("lunar_unijob:cuffToggle", function(targetId)
    if Settings.handcuffItems then
        cuffToggleWithItems(targetId)
    else
        cuffToggleNoItems(targetId)
    end
end)

-- Get player cuff state callback
lib.callback.register("lunar_unijob:getPlayerCuffState", function(source, targetId)
    return cuffedPlayers[targetId]
end)

-- Admin uncuff command
RegisterCommand("uncuff", function(src, args, rawCommand)
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    local targetId = tonumber(args[1])
    if targetId then
        cuffedPlayers[targetId] = nil
        TriggerClientEvent("lunar_unijob:syncCuff", targetId)
    end
end, true)

-- Export uncuff function
exports("uncuff", function(playerId)
    cuffedPlayers[playerId] = nil
    TriggerClientEvent("lunar_unijob:syncCuff", playerId)
end)

-- Drag event handler
RegisterNetEvent("lunar_unijob:drag", function(targetId)
    local src = source
    local player = Framework.getPlayerFromId(src)
    local target = draggedPlayers[src] or targetId

    if not player or not target then
        return
    end

    if not Actions.hasAccess(player, "drag") then
        return
    end

    if not Utils.distanceCheck(src, target, Settings.interactDistance) then
        return
    end

    if not cuffedPlayers[target] then
        return
    end

    if draggedPlayers[src] then
        draggedPlayers[src] = nil
    else
        draggedPlayers[src] = target
    end

    local draggerId = draggedPlayers[src] and src or nil
    TriggerClientEvent("lunar_unijob:drag", target, draggerId)
end)

-- Put in vehicle event handler
RegisterNetEvent("lunar_unijob:putInVehicle", function(targetId, seat)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player then
        return
    end

    if not Actions.hasAccess(player, "putInsideVehicle") then
        return
    end

    if not Utils.distanceCheck(src, targetId, Settings.interactDistance) then
        return
    end

    TriggerClientEvent("lunar_unijob:putInVehicle", targetId, seat)
end)

-- Take out of vehicle event handler
RegisterNetEvent("lunar_unijob:outTheVehicle", function(targetId, coords)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player then
        return
    end

    if not Actions.hasAccess(player, "takeOutOfVehicle") then
        return
    end

    if not Utils.distanceCheck(src, targetId, 10.0) then
        return
    end

    TriggerClientEvent("lunar_unijob:outTheVehicle", targetId, coords)
end)

-- Carry event handler
RegisterNetEvent("lunar_unijob:carry", function(targetId)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player then
        return
    end

    if not Actions.hasAccess(player, "carry") then
        return
    end

    if not Utils.distanceCheck(src, targetId, Settings.interactDistance) then
        return
    end

    -- Check if either player is already in a carry state
    if carryingPlayers[src] or carryingPlayers[targetId] or beingCarriedBy[src] or beingCarriedBy[targetId] then
        return
    end

    carryingPlayers[src] = targetId
    beingCarriedBy[targetId] = src

    TriggerClientEvent("lunar_unijob:syncCarry", targetId, src)
end)

-- Stop carry event handler
RegisterNetEvent("lunar_unijob:stopCarry", function()
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not Actions.hasAccess(player, "carry") then
        return
    end

    if carryingPlayers[src] then
        local carriedPlayer = carryingPlayers[src]

        if not Utils.distanceCheck(src, carriedPlayer, Settings.interactDistance) then
            return
        end

        TriggerClientEvent("lunar_unijob:stopCarry", src, false)
        TriggerClientEvent("lunar_unijob:stopCarry", carriedPlayer, true)

        beingCarriedBy[carriedPlayer] = nil
        carryingPlayers[src] = nil
    elseif beingCarriedBy[src] then
        local carrier = beingCarriedBy[src]

        if not Utils.distanceCheck(src, carrier, Settings.interactDistance) then
            return
        end

        TriggerClientEvent("lunar_unijob:stopCarry", src, true)
        TriggerClientEvent("lunar_unijob:stopCarry", carrier, false)

        beingCarriedBy[carrier] = nil
        carryingPlayers[src] = nil
    end
end)

-- Get action category (player or vehicle)
local function getActionCategory(actionName)
    local playerActions = {
        handcuff = true,
        ziptie = true,
        steal = true,
        drag = true,
        carry = true,
        bill = true,
        revive = true,
        tackle = true,
        heal = true
    }

    if playerActions[actionName] then
        return "playerActions"
    else
        return "vehicleActions"
    end
end

-- Check if player has access to an action
function Actions.hasAccess(player, actionName)
    local jobs = GetJobs()
    local playerJob = player:getJob()
    local jobData = jobs[playerJob]

    if actionName == "handcuffs" or actionName == "zipties" then
        local actions = jobData and jobData.playerActions
        if actions and actions.handcuff then
            return actions.handcuff == "both"
        else
            return Settings.playerActions.handcuff == "both"
        end
    else
        local category = getActionCategory(actionName)
        local jobActions = jobData and jobData[category]
        local hasJobAccess = jobActions and jobActions[actionName] or false

        local settingsActions = Settings[category]
        local hasSettingsAccess = settingsActions and settingsActions[actionName] or false

        return hasSettingsAccess or hasJobAccess
    end
end

-- Vehicle action callbacks
lib.callback.register("lunar_unijob:hijackVehicle", function(source)
    return Editable.onVehicleAction(source, "hijack")
end)

lib.callback.register("lunar_unijob:repairVehicle", function(source)
    return Editable.onVehicleAction(source, "repair")
end)

lib.callback.register("lunar_unijob:cleanVehicle", function(source)
    return Editable.onVehicleAction(source, "clean")
end)

lib.callback.register("lunar_unijob:impoundVehicle", function(source)
    return Editable.onVehicleAction(source, "impound")
end)

-- Pending vehicle actions storage
PendingVehicleActions = {}

-- Perform vehicle action event handler
RegisterNetEvent("lunar_unijob:performVehicleAction", function(netId, actionType)
    local src = source

    if not PendingVehicleActions[src] then
        return
    end

    PendingVehicleActions[src] = nil

    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then
        return
    end

    local owner = NetworkGetEntityOwner(entity)
    TriggerClientEvent("lunar_unijob:performVehicleAction", owner, netId, actionType)
end)

-- Remove item event handler
RegisterNetEvent("lunar_unijob:removeItem", function(itemName)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or type(itemName) ~= "string" then
        return
    end

    if player:hasItem(itemName) then
        player:removeItem(itemName, 1)
    end
end)

-- Tackle player event handler
RegisterNetEvent("lunar_unijob:tacklePlayer", function(targetId)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player then
        return
    end

    if not Actions.hasAccess(player, "tackle") then
        return
    end

    if not Utils.distanceCheck(src, targetId, 5.0) then
        return
    end

    TriggerClientEvent("lunar_unijob:playTackledAnim", targetId, src)
end)