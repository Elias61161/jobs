-- Settings module
Settings = {}

-- Settings loaded flag
local settingsLoaded = false

-- Default settings
local defaultSettings = {
    interactDistance = 3.0,
    impoundPrice = 500,
    handcuffItems = true,
    handcuffsItemName = "handcuffs",
    ziptiesItemName = "zipties",
    handcuffsSkillCheck = true,
    sprintWhileDrag = false,
    disableTargetInteractions = false,
    tackleCooldown = 10000,
    tackleRadius = 2.0,
    playerActions = {
        steal = true,
        handcuff = true,
        drag = true,
        carry = true,
        bill = true,
        revive = true,
        heal = true
    },
    vehicleActions = {
        putInsideVehicle = false,
        takeOutOfVehicle = false,
        hijack = false,
        repair = false,
        clean = false,
        impound = false
    },
    durations = {
        steal = 3000,
        revive = 10000,
        heal = 5000,
        hijack = 1000,
        repair = 10000,
        clean = 10000,
        impound = 10000
    }
}

-- Save settings to database
local function saveSettings()
    local updates = {}

    for key, value in pairs(Settings) do
        updates[#updates + 1] = { json.encode(value), key }
    end

    MySQL.prepare.await("UPDATE lunar_jobscreator_settings SET `value` = ? WHERE `key` = ?", updates)
end

-- Load settings from database on MySQL ready
MySQL.ready(function()
    Wait(1000)

    -- Initialize with defaults and insert/update database
    for key, value in pairs(defaultSettings) do
        Settings[key] = value
        MySQL.query.await("INSERT INTO lunar_jobscreator_settings (`key`, `value`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)", {
            key, json.encode(value)
        })
    end

    -- Load settings from database
    local dbSettings = MySQL.query.await("SELECT * FROM lunar_jobscreator_settings")

    for i = 1, #dbSettings do
        local row = dbSettings[i]
        Settings[row.key] = json.decode(row.value)
    end

    settingsLoaded = true
end)

-- Update settings event handler
RegisterNetEvent("lunar_unijob:updateSettings", function(newSettings)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    Settings = newSettings

    TriggerClientEvent("lunar_unijob:updateSettings", -1, newSettings)
    saveSettings()
end)

-- Get settings callback
lib.callback.register("lunar_unijob:getSettings", function()
    while not settingsLoaded do
        Wait(100)
    end

    return Settings
end)
