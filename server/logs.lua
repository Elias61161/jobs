-- Logs module
Logs = {}

-- Send log to Discord webhooks
function Logs.send(playerId, jobName, message)
    -- Send to job-specific webhook if configured
    local jobWebhook = Webhooks.jobs[jobName]
    if jobWebhook and jobWebhook ~= "" then
        Utils.logToDiscord(playerId, jobWebhook, message)
    end

    -- Send to global webhook if configured
    local globalWebhook = Webhooks.globalWebhook
    if globalWebhook and globalWebhook ~= "" then
        Utils.logToDiscord(playerId, globalWebhook, message)
    end
end
