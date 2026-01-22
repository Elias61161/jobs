-- Webhooks module
Webhooks = {}

-- Load global webhook from KVP
Webhooks.globalWebhook = GetResourceKvpString("webhook")

-- Load webhook settings from KVP or use defaults
local savedSettings = GetResourceKvpString("webhookSettings")
if savedSettings then
    Webhooks.settings = json.decode(savedSettings) or nil
end

if not Webhooks.settings then
    Webhooks.settings = {
        alarms = false,
        collecting = false,
        crafting = true,
        vehicleBought = true,
        registers = true,
        selling = true,
        shops = true,
        stashes = true
    }
end

-- Job-specific webhooks
Webhooks.jobs = {}

-- Load job webhooks from database on MySQL ready
MySQL.ready(function()
    Wait(1000)

    local dbWebhooks = MySQL.query.await("SELECT * FROM lunar_jobscreator_webhooks")

    for i = 1, #dbWebhooks do
        local row = dbWebhooks[i]
        Webhooks.jobs[row.name] = row.url
    end
end)

-- Get webhook data callback (admin only)
lib.callback.register("lunar_unijob:getWebhookData", function(playerId)
    local player = Framework.getPlayerFromId(playerId)

    if not player or not IsPlayerAdmin(player.source) then
        return nil
    end

    return Webhooks
end)

-- Update webhook data event handler (admin only)
RegisterNetEvent("lunar_unijob:updateWebhookData", function(newData)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    Webhooks.globalWebhook = newData.globalWebhook
    Webhooks.settings = newData.settings

    -- Save to KVP
    if newData.globalWebhook then
        SetResourceKvp("webhook", newData.globalWebhook)
    end

    if newData.settings then
        SetResourceKvp("webhookSettings", json.encode(newData.settings))
    end
end)

-- Update job-specific webhook event handler (admin only)
RegisterNetEvent("lunar_unijob:updateJobWebhook", function(jobName, webhookUrl)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    if webhookUrl:len() == 0 then
        return
    end

    Webhooks.jobs[jobName] = webhookUrl

    MySQL.update.await("INSERT INTO lunar_jobscreator_webhooks (name, url) VALUES(?, ?) ON DUPLICATE KEY UPDATE url = VALUES(url)", {
        jobName, webhookUrl
    })
end)
