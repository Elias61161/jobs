-- Actions Module
-- Handles player and vehicle action interactions

Actions = {}

local playerActionsList = {}
local vehicleActionsList = {}
local actionCategories = {}

-- Check if player can perform actions (not dead and not in vehicle)
local function canPerformAction()
    local isDead = Editable.isDead(cache.ped)
    local inVehicle = IsPedInAnyVehicle(cache.ped)
    return not inVehicle and not isDead
end

-- Get action category type based on action name
local function getActionCategory(actionName)
    local playerActions = {
        handcuff = true, ziptie = true, steal = true, drag = true,
        carry = true, bill = true, revive = true, tackle = true, heal = true
    }
    return playerActions[actionName] and "playerActions" or "vehicleActions"
end

-- Check if player has access to perform an action
function HasAccess(actionName)
    local currentJob = GetCurrentJob()

    -- Special handling for handcuffs/zipties
    if actionName == "handcuffs" or actionName == "zipties" then
        local playerActions = currentJob and currentJob.playerActions
        if playerActions and playerActions.handcuff then
            return playerActions.handcuff == "both"
        end
        return Settings.playerActions.handcuff == "both"
    end

    -- Standard action access check
    local category = getActionCategory(actionName)
    local jobActions = currentJob and currentJob[category]
    local hasJobAccess = jobActions and jobActions[actionName] ~= nil and jobActions[actionName]

    local settingsActions = Settings[category]
    local hasSettingsAccess = settingsActions and settingsActions[actionName] ~= nil and settingsActions[actionName]

    return hasSettingsAccess or hasJobAccess
end

-- Check item requirements and handle item removal
local function checkItemRequirements(actionName)
    local currentJob = GetCurrentJob()
    local category = getActionCategory(actionName)

    -- Get action config from job or settings
    local actionConfig = nil
    if currentJob then
        local jobActions = currentJob[category]
        if jobActions then
            actionConfig = jobActions[actionName]
        end
    end

    if actionConfig == nil then
        local settingsActions = Settings[category]
        if settingsActions then
            actionConfig = settingsActions[actionName]
        end
    end

    -- Check if action requires an item
    if type(actionConfig) == "table" then
        if actionConfig.item then
            local hasItem = Framework.hasItem(actionConfig.item)
            if not hasItem then
                local itemLabel = (Utils.getItemLabel and Utils.getItemLabel(actionConfig.item)) or actionConfig.item
                LR.notify(locale("missing_item", itemLabel), "error")
                return false
            end
        end

        -- Remove item after use if configured
        if actionConfig.removeAfterUse then
            TriggerServerEvent("lunar_unijob:removeItem", actionConfig.item)
        end
    end

    return true
end

-- Create a player action
function Actions.createPlayer(actionName, icon, callback, canInteractFilter)
    local function actionHandler(data)
        -- ox_target passes data table with entity field
        local targetPed = type(data) == "table" and data.entity or data
        
        if not canPerformAction() then
            LR.notify(locale("in_car"), "error")
            return
        end

        if not targetPed or targetPed == 0 or not DoesEntityExist(targetPed) then
            return
        end

        local playerIndex = NetworkGetPlayerIndexFromPed(targetPed)
        if playerIndex == 0 then
            return
        end

        if not checkItemRequirements(actionName) then
            return
        end

        local targetServerId = GetPlayerServerId(playerIndex)

        -- Check for action override
        local override = PlayerActionOverrides[actionName]
        if override then
            override(targetServerId, targetPed)
            return
        end

        callback(targetServerId, targetPed)
    end

    -- Register ox_target interaction if enabled
    if not Config.disableTargetInteractions then
        local success, error = pcall(function()
            exports.ox_target:addGlobalPlayer({
                {
                    label = locale(actionName),
                    icon = "fas fa-" .. icon,
                    canInteract = function(entity)
                        if actionName == "steal" then
                            print("^3[DEBUG] Checking canInteract for steal action^7")
                        end
                        
                        if not canPerformAction() then
                            if actionName == "steal" then
                                print("^3[DEBUG] Cannot perform action (in vehicle/etc)^7")
                            end
                            return false
                        end

                        if canInteractFilter and not canInteractFilter(entity) then
                            if actionName == "steal" then
                                print("^3[DEBUG] Custom canInteractFilter returned false^7")
                            end
                            return false
                        end

                        local editableFilter = Editable.canInteractFilter[actionName]
                        if editableFilter then
                            local result = editableFilter(entity)
                            if actionName == "steal" then
                                print(string.format("^3[DEBUG] Editable.canInteractFilter.steal returned: %s^7", tostring(result)))
                            end
                            if not result then
                                return false
                            end
                        end

                        local hasAccess = HasAccess(actionName)
                        if actionName == "steal" then
                            print(string.format("^3[DEBUG] HasAccess returned: %s^7", tostring(hasAccess)))
                        end
                        
                        return hasAccess
                    end,
                    onSelect = actionHandler,
                    distance = Settings.interactDistance or 3.0
                }
            })
        end)
        
        if not success then
            print("^3Warning: ox_target exports not available. Player actions will only work via F6 menu.^7")
        end
    end

    -- Add to player actions list
    playerActionsList[#playerActionsList + 1] = {
        name = actionName,
        icon = icon,
        onSelect = actionHandler
    }

    -- Register export
    exports(actionName, actionHandler)
end

-- Create a vehicle action
function Actions.createVehicle(actionName, icon, callback, canInteractFilter)
    local function actionHandler(data)
        -- ox_target passes data table with entity field
        local vehicle = type(data) == "table" and data.entity or data
        
        if not canPerformAction() then
            LR.notify(locale("in_car"), "error")
            return
        end

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
            return
        end

        if not checkItemRequirements(actionName) then
            return
        end

        -- Check for action override
        local override = VehicleActionOverrides[actionName]
        if override then
            override(vehicle)
            return
        end

        callback(vehicle)
    end

    -- Register ox_target interaction if enabled
    if not Config.disableTargetInteractions then
        local success, error = pcall(function()
            exports.ox_target:addGlobalVehicle({
                {
                    label = locale(actionName),
                    icon = "fas fa-" .. icon,
                    canInteract = function(entity)
                        if not canPerformAction() then
                            return false
                        end

                        local currentJob = GetCurrentJob()
                        if not currentJob or not currentJob.vehicleActions then
                            return Settings.vehicleActions[actionName] ~= nil and Settings.vehicleActions[actionName]
                        end

                        if canInteractFilter and not canInteractFilter(entity) then
                            return false
                        end

                        local editableFilter = Editable.canInteractFilter[actionName]
                        if editableFilter and not editableFilter(entity) then
                            return false
                        end

                        local jobAction = currentJob.vehicleActions[actionName]
                        if jobAction ~= nil then
                            return jobAction
                        end

                        return Settings.vehicleActions[actionName] ~= nil and Settings.vehicleActions[actionName]
                    end,
                    onSelect = actionHandler,
                    distance = Settings.interactDistance or 3.0
                }
            })
        end)
        
        if not success then
            print("^3Warning: ox_target exports not available. Vehicle actions will only work via F6 menu.^7")
        end
    end

    -- Add to vehicle actions list
    vehicleActionsList[#vehicleActionsList + 1] = {
        name = actionName,
        icon = icon,
        onSelect = actionHandler
    }

    -- Register export
    exports(actionName, actionHandler)
end

-- Find closest player and execute callback
local function findClosestPlayerAndExecute(callback)
    local coords = GetEntityCoords(cache.ped)
    local closestPlayer, closestPed = lib.getClosestPlayer(coords, Settings.interactDistance, false)

    if not closestPlayer or not closestPed then
        LR.notify(locale("no_player_near"), "error")
        return
    end

    callback(closestPed)
end

-- Find closest vehicle and execute callback
local function findClosestVehicleAndExecute(callback)
    local coords = GetEntityCoords(cache.ped)
    local closestVehicle = lib.getClosestVehicle(coords, Settings.interactDistance, false)

    if not closestVehicle then
        LR.notify(locale("no_vehicle_near"), "error")
        return
    end

    callback(closestVehicle)
end

-- Show player actions menu
local function showPlayerActionsMenu()
    local options = {}

    for _, action in ipairs(playerActionsList) do
        if HasAccess(action.name) then
            table.insert(options, {
                label = locale(action.name),
                icon = action.icon,
                onSelect = action.onSelect
            })
        end
    end

    lib.registerMenu({
        id = "player_actions",
        title = locale("player_actions"),
        position = Config.actionsMenuPosition or "top-right",
        options = options
    }, function(selected)
        findClosestPlayerAndExecute(options[selected].onSelect)
    end)

    lib.showMenu("player_actions")
end

-- Show vehicle actions menu
local function showVehicleActionsMenu()
    local options = {}

    for _, action in ipairs(vehicleActionsList) do
        if HasAccess(action.name) then
            table.insert(options, {
                label = locale(action.name),
                icon = action.icon,
                onSelect = action.onSelect
            })
        end
    end

    lib.registerMenu({
        id = "vehicle_actions",
        title = locale("vehicle_actions"),
        position = Config.actionsMenuPosition or "top-right",
        options = options
    }, function(selected)
        findClosestVehicleAndExecute(options[selected].onSelect)
    end)

    lib.showMenu("vehicle_actions")
end

-- Check if any player actions are available
local function hasAnyPlayerActions()
    for _, action in ipairs(playerActionsList) do
        if HasAccess(action.name) then
            return true
        end
    end
    return false
end

-- Check if any vehicle actions are available
local function hasAnyVehicleActions()
    for _, action in ipairs(vehicleActionsList) do
        if HasAccess(action.name) then
            return true
        end
    end
    return false
end

-- Initialize action categories
actionCategories = {
    {
        name = "player_actions",
        label = locale("player_actions"),
        icon = "user",
        onSelect = showPlayerActionsMenu,
        canInteract = hasAnyPlayerActions
    },
    {
        name = "vehicle_actions",
        label = locale("vehicle_actions"),
        icon = "car",
        onSelect = showVehicleActionsMenu,
        canInteract = hasAnyVehicleActions
    }
}

-- Export: Add custom action category
exports("addActionsCategory", function(category)
    table.insert(actionCategories, category)
end)

-- Export: Remove action category
exports("removeActionsCategory", function(categoryName)
    for i, category in ipairs(actionCategories) do
        if category.name == categoryName then
            table.remove(actionCategories, i)
            break
        end
    end
end)

-- Actions menu keybind listener
Binds.actionsMenu.addListener("main", function()
    local currentJob = GetCurrentJob()
    local availableCategories = {}

    for _, category in ipairs(actionCategories) do
        if not category.canInteract or category.canInteract() then
            table.insert(availableCategories, category)
        end
    end

    if not Config.actionsMenu or not canPerformAction() or #availableCategories == 0 then
        return
    end

    local menuTitle = (currentJob and currentJob.label) or locale("actions")

    lib.registerMenu({
        id = "actions_menu",
        position = Config.actionsMenuPosition or "top-right",
        title = menuTitle,
        options = availableCategories
    }, function(selected)
        availableCategories[selected].onSelect()
    end)

    lib.showMenu("actions_menu")
end)

-- Update radial menu with available actions
function Actions.updateRadial()
    lib.removeRadialItem("player_actions")
    lib.removeRadialItem("vehicle_actions")

    if not Config.radialMenu then
        return
    end

    -- Build player actions radial items
    local playerRadialItems = {}
    for _, action in ipairs(playerActionsList) do
        if HasAccess(action.name) then
            table.insert(playerRadialItems, {
                id = action.name,
                label = locale(action.name .. "_radial"),
                icon = action.icon,
                onSelect = function()
                    findClosestPlayerAndExecute(action.onSelect)
                end
            })
        end
    end

    -- Build vehicle actions radial items
    local vehicleRadialItems = {}
    for _, action in ipairs(vehicleActionsList) do
        if HasAccess(action.name) then
            table.insert(vehicleRadialItems, {
                id = action.name,
                label = locale(action.name .. "_radial"),
                icon = action.icon,
                onSelect = function()
                    findClosestVehicleAndExecute(action.onSelect)
                end
            })
        end
    end

    -- Register player actions radial menu
    if #playerRadialItems > 0 then
        lib.addRadialItem({
            id = "player_actions",
            label = locale("player_actions_radial"),
            icon = "user",
            menu = "player_actions"
        })
        lib.registerRadial({
            id = "player_actions",
            items = playerRadialItems
        })
    end

    -- Register vehicle actions radial menu
    if #vehicleRadialItems > 0 then
        lib.addRadialItem({
            id = "vehicle_actions",
            label = locale("vehicle_actions_radial"),
            icon = "car",
            menu = "vehicle_actions"
        })
        lib.registerRadial({
            id = "vehicle_actions",
            items = vehicleRadialItems
        })
    end
end
