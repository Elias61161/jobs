-- Settings Module
-- Handles job creator settings synchronization

Settings = {}
local settingsLoaded = false

-- Fetch settings from server on load
lib.callback("lunar_unijob:getSettings", false, function(data)
    Settings = data
    settingsLoaded = true
end)

-- Handle settings updates from server
RegisterNetEvent("lunar_unijob:updateSettings", function(data)
    Settings = data
    UI.sendMessage("updateSettings", data)
end)

-- NUI Callback: Get settings (wait until loaded)
RegisterNUICallback("getSettings", function(data, cb)
    while not settingsLoaded do
        Wait(100)
    end
    cb(Settings)
end)

-- NUI Callback: Update settings
RegisterNUICallback("updateSettings", function(data, cb)
    TriggerServerEvent("lunar_unijob:updateSettings", data)
    cb({})
end)
