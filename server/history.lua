-- History storage
local historyLogs = {}
local historyLoaded = false

-- Fetched players cache (to prevent duplicate fetches)
local fetchedHistoryPlayers = {}

-- Get current timestamp
local function getCurrentTimestamp()
    return os.time()
end

-- Load history from database on MySQL ready
MySQL.ready(function()
    Wait(1000)

    local currentTime = getCurrentTimestamp()
    local twoDaysAgo = currentTime - 172800 -- 48 hours in seconds

    -- Load recent history
    historyLogs = MySQL.query.await("SELECT * FROM lunar_jobscreator_history WHERE timestamp >= ?", { twoDaysAgo })

    -- Clean up old history
    MySQL.query.await("DELETE FROM lunar_jobscreator_history WHERE timestamp < ?", { twoDaysAgo })

    historyLoaded = true
end)

-- Get history callback
lib.callback.register("lunar_unijob:getHistory", function(playerId)
    -- Prevent duplicate fetches
    if fetchedHistoryPlayers[playerId] then
        return nil
    end

    fetchedHistoryPlayers[playerId] = true

    -- Wait for history to load
    while not historyLoaded do
        Wait(0)
    end

    return historyLogs
end)

-- Add history log entry
function AddHistoryLog(playerId, action)
    local logEntry = {
        username = GetPlayerName(playerId),
        action = action,
        timestamp = getCurrentTimestamp()
    }

    -- Add to local cache
    historyLogs[#historyLogs + 1] = logEntry

    -- Insert into database
    MySQL.insert.await("INSERT INTO lunar_jobscreator_history (username, action, timestamp) VALUES (?, ?, ?)", {
        logEntry.username,
        logEntry.action,
        logEntry.timestamp
    })

    -- Sync to all clients
    TriggerClientEvent("lunar_unijob:updateHistory", -1, historyLogs)
end
