-- Stats storage
local stats = {
    onDutyCount = 0,
    lastOnDutyCount = 0,
    wealthiestJob = nil,
    jobCounts = {}
}

-- Stats loaded flag
local statsLoaded = false

-- Player job tracking
local playerJobs = {}
local playerOnDuty = {}

-- Update wealthiest job
local function updateWealthiestJob()
    local allJobs = GetJobs()
    local wealthiest = { job = nil, balance = 0 }

    for _, jobData in pairs(allJobs) do
        local balance = Editable.getSocietyMoney(jobData.name) or 0

        -- Ensure balance is a number
        if type(balance) ~= "number" then
            balance = tonumber(balance) or 0
        end

        if balance >= wealthiest.balance then
            wealthiest = { job = jobData, balance = balance }
        end
    end

    if wealthiest.job then
        stats.wealthiestJob = {
            label = wealthiest.job.label,
            balance = wealthiest.balance
        }
    end
end

-- Get stats callback
lib.callback.register("lunar_unijob:getStats", function()
    while not statsLoaded do
        Wait(100)
    end

    return stats
end)

-- Update wealthiest job hourly
lib.cron.new("0 * * * *", function()
    updateWealthiestJob()
end)

-- Initialize stats on startup
CreateThread(function()
    while not AreJobsLoaded() do
        Wait(100)
    end

    local allJobs = GetJobs()

    for _, jobData in pairs(allJobs) do
        stats.jobCounts[jobData.name] = 0
    end

    updateWealthiestJob()
    statsLoaded = true
end)

-- Broadcast stats periodically (every 10 minutes)
SetInterval(function()
    TriggerClientEvent("lunar_unijob:updateStats", -1, stats)
end, 600000)

-- Update player job stats
local function updatePlayerJobStats(playerId, jobName, isOnDuty)
    local allJobs = GetJobs()
    local previousJob = playerJobs[playerId]

    if previousJob == jobName then
        return
    end

    -- Decrement previous job count
    if previousJob and stats.jobCounts[previousJob] then
        stats.jobCounts[previousJob] = stats.jobCounts[previousJob] - 1
    end

    -- Check if new job is tracked
    if allJobs[jobName] then
        if not stats.jobCounts[jobName] then
            stats.jobCounts[jobName] = 0
        end

        stats.jobCounts[jobName] = stats.jobCounts[jobName] + 1
        playerJobs[playerId] = jobName
    else
        playerJobs[playerId] = nil
    end

    -- Update on-duty count
    if isOnDuty then
        if not playerOnDuty[playerId] then
            playerOnDuty[playerId] = true
            stats.onDutyCount = stats.onDutyCount + 1
        end
    else
        if playerOnDuty[playerId] then
            playerOnDuty[playerId] = nil
            stats.onDutyCount = stats.onDutyCount - 1
        end
    end
end

-- ESX job change handler
AddEventHandler("esx:setJob", function(playerId, jobData)
    if jobData.name ~= Config.UnemployedJob then
        local isOnDuty = Editable.getPlayerDuty(playerId, jobData)
        updatePlayerJobStats(playerId, jobData.name, isOnDuty)
    end
end)

-- QB-Core job change handler
AddEventHandler("QBCore:Server:OnJobUpdate", function(playerId, jobData)
    if jobData.name ~= Config.UnemployedJob then
        local isOnDuty = Editable.getPlayerDuty(playerId, jobData)
        updatePlayerJobStats(playerId, jobData.name, isOnDuty)
    end
end)

-- ESX player loaded handler
AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    local isOnDuty = Editable.getPlayerDuty(playerId, xPlayer.job)
    updatePlayerJobStats(playerId, xPlayer.job.name, isOnDuty)
end)

-- QB-Core player loaded handler
AddEventHandler("QBCore:Server:PlayerLoaded", function(player)
    local isOnDuty = Editable.getPlayerDuty(player.PlayerData.source, player.PlayerData.job)
    updatePlayerJobStats(player.PlayerData.source, player.PlayerData.job.name, isOnDuty)
end)

-- Save last on-duty count hourly
lib.cron.new("0 * * * *", function()
    stats.lastOnDutyCount = stats.onDutyCount
end)

-- Sync existing players on startup
CreateThread(function()
    while not statsLoaded do
        Wait(100)
    end

    local players = Framework.getPlayers()

    for _, playerData in pairs(players) do
        local playerId = playerData.source or playerData.PlayerData.source
        local jobData = playerData.job or playerData.PlayerData.job
        local isOnDuty = Editable.getPlayerDuty(playerId, jobData)

        if Framework.name == "es_extended" then
            updatePlayerJobStats(playerData.source, playerData.job.name, isOnDuty)
        else
            updatePlayerJobStats(playerData.PlayerData.source, playerData.PlayerData.job.name, isOnDuty)
        end
    end

    TriggerClientEvent("lunar_unijob:updateStats", -1, stats)
end)
