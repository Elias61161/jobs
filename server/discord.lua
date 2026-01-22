-- Cache for already fetched discord icons
local fetchedPlayers = {}

-- Get Discord ID from player
local function getDiscordId(playerId)
    local identifier = GetPlayerIdentifierByType(playerId, "discord")

    if not identifier then
        return nil
    end

    local colonPos = identifier:find(":")
    if colonPos then
        return identifier:sub(colonPos + 1)
    end

    return identifier
end

-- Get Discord avatar icon callback
lib.callback.register("lunar_unijob:getDiscordIcon", function(playerId)
    -- Check if bot token is configured
    if not SvConfig.discordBotToken or SvConfig.discordBotToken == "TOKEN_HERE" then
        warn("Discord bot token missing.")
        return nil
    end

    -- Check if already fetched
    if fetchedPlayers[playerId] then
        return nil
    end

    fetchedPlayers[playerId] = true

    local discordId = getDiscordId(playerId)
    if not discordId then
        return nil
    end

    local endpoint = "users/" .. discordId

    while true do
        local p = promise.new()

        PerformHttpRequest("https://discord.com/api/" .. endpoint, function(statusCode, responseData, headers)
            p:resolve({
                data = responseData,
                code = statusCode,
                headers = headers
            })
        end, "GET", "", {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bot " .. SvConfig.discordBotToken
        })

        local response = Citizen.Await(p)

        if response.code == 200 then
            local userData = json.decode(response.data)
            local avatarHash = userData.avatar
            return string.format("https://cdn.discordapp.com/avatars/%s/%s.png", discordId, avatarHash)
        elseif response.code == 429 then
            -- Rate limited
            local retryAfter = tonumber(response.headers["Retry-After"])
            if retryAfter then
                warn("Rate-limited. Waiting " .. retryAfter .. " seconds before retrying...")
                Wait(retryAfter * 1000)
            else
                warn("Rate limited but no Retry-After header provided.")
                Wait(5000)
            end
        else
            warn("Couldn't fetch discord user data: HTTP " .. tostring(response.code))
            return nil
        end
    end
end)
