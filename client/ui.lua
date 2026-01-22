-- UI Module
-- Handles NUI communication and job creator interface

UI = {}

-- Send message to NUI
function UI.sendMessage(action, data)
    SendNUIMessage({
        action = action,
        data = data
    })
end

-- Update a single job in the UI
function UI.updateJob(jobData)
    UI.sendMessage("updateJob", jobData)
end

-- Remove a job from the UI
function UI.removeJob(jobName)
    UI.sendMessage("removeJob", jobName)
end

-- Update all jobs in the UI
function UI.updateJobs(jobs)
    local jobList = {}
    for _, job in pairs(jobs) do
        jobList[#jobList + 1] = job
    end
    UI.sendMessage("updateJobs", jobList)
end

-- NUI Callback: Get all jobs
RegisterNUICallback("getJobs", function(data, cb)
    local jobs = GetJobs()
    local jobList = {}
    for _, job in pairs(jobs) do
        jobList[#jobList + 1] = job
    end
    cb(jobList)
end)

-- NUI Callback: Create a new job
RegisterNUICallback("createJob", function(data, cb)
    TriggerServerEvent("lunar_unijob:createJob", data)
    cb({})
end)

-- NUI Callback: Update a specific job field
RegisterNUICallback("updateJobField", function(data, cb)
    TriggerServerEvent("lunar_unijob:updateJobField", data.name, data.field, data.data)
    cb({})
end)

-- NUI Callback: Update entire job
RegisterNUICallback("updateJob", function(data, cb)
    TriggerServerEvent("lunar_unijob:updateJob", data)
    cb({})
end)

-- NUI Callback: Remove a job
RegisterNUICallback("removeJob", function(data, cb)
    TriggerServerEvent("lunar_unijob:removeJob", data)
    cb({})
end)

-- NUI Callback: Hide the UI frame
RegisterNUICallback("hideFrame", function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- NUI Callback: Update webhook data
RegisterNUICallback("updateWebhookData", function(data, cb)
    TriggerServerEvent("lunar_unijob:updateWebhookData", data)
    cb({})
end)

-- NUI Callback: Update job webhook
RegisterNUICallback("updateJobWebhook", function(data, cb)
    TriggerServerEvent("lunar_unijob:updateJobWebhook", data.name, data.url)
    cb({})
end)

-- History data
local historyData = nil

lib.callback("lunar_unijob:getHistory", false, function(data)
    historyData = data
end)

RegisterNetEvent("lunar_unijob:updateHistory", function(data)
    historyData = data
    UI.sendMessage("updateHistory", data)
end)

RegisterNUICallback("getHistory", function(data, cb)
    while not historyData do
        Wait(0)
    end
    cb(historyData)
end)

-- Stats data
local statsData = nil

lib.callback("lunar_unijob:getStats", false, function(data)
    statsData = data
end)

RegisterNUICallback("getStats", function(data, cb)
    while not statsData do
        Wait(0)
    end
    cb(statsData)
end)

RegisterNetEvent("lunar_unijob:updateStats", function(data)
    statsData = data
    UI.sendMessage("updateStats", data)
end)

-- NUI Callback: Get framework name
RegisterNUICallback("getFramework", function(data, cb)
    cb(Framework.name)
end)

-- NUI Callback: Get UI language
RegisterNUICallback("getLanguage", function(data, cb)
    cb(Config.uiLanguage)
end)

-- NUI Callback: Get player profile
RegisterNUICallback("getProfile", function(data, cb)
    cb({
        serverId = cache.serverId,
        username = GetPlayerName(cache.playerId),
        avatarUrl = nil
    })
end)

-- Discord icon fetched flag
local discordIconFetched = false

-- Command: Open job creator
RegisterCommand(Config.command or "jobscreator", function()
    local webhookData = lib.callback.await("lunar_unijob:getWebhookData", false)
    
    if not webhookData then
        return
    end
    
    -- Fetch Discord icon once
    if not discordIconFetched then
        lib.callback("lunar_unijob:getDiscordIcon", false, function(avatarUrl)
            UI.sendMessage("updateProfile", {
                serverId = cache.serverId,
                username = GetPlayerName(cache.playerId),
                avatarUrl = avatarUrl
            })
        end)
        discordIconFetched = true
    end
    
    UI.sendMessage("updateWebhookData", webhookData)
    UI.sendMessage("open")
    SetNuiFocus(true, true)
end)

-- Command: Edit specific job
RegisterCommand("edit", function(source, args, rawCommand)
    local webhookData = lib.callback.await("lunar_unijob:getWebhookData", false)
    
    if not webhookData then
        return
    end
    
    local jobName = args[1]
    local jobs = GetJobs()
    
    if not jobs[jobName] then
        LR.notify(locale("invalid_job_name"), "error")
        return
    end
    
    UI.sendMessage("updateWebhookData", webhookData)
    UI.sendMessage("openEditJob", jobName)
    UI.sendMessage("open")
    SetNuiFocus(true, true)
end)

-- NUI Callback: Teleport player
RegisterNUICallback("teleport", function(coords, cb)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    Wait(500)
    
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z + 1.0)
    
    if coords.w then
        SetEntityHeading(cache.ped, coords.w)
    end
    
    cb({})
end)
