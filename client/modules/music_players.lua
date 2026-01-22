-- Music Players Module
-- Handles job music player interaction points using xsound

local musicPlayerPoints = {}

-- Event: Set loop state from server
RegisterNetEvent("lunar_unijob:setLoop", function(playerId, loopState)
    if exports.xsound:soundExists(playerId) then
        exports.xsound:setSoundLoop(playerId, loopState)
    end
end)

-- Play music from URL
local function playMusicUrl(playerId)
    local result = lib.inputDialog(locale("play_music_url"), {
        {
            type = "input",
            label = locale("music_url"),
            icon = "link",
            required = true,
            min = 1
        }
    })
    
    local url = result and result[1]
    if not url then
        return
    end
    
    TriggerServerEvent("lunar_unijob:playMusic", playerId, url)
end

-- Change volume
local function changeVolume(playerId)
    local currentVolume = exports.xsound:getVolume(playerId) or 1.0
    
    local result = lib.inputDialog(locale("change_volume"), {
        {
            type = "slider",
            label = locale("volume"),
            icon = "link",
            required = true,
            min = 0.01,
            max = 1.0,
            step = 0.05,
            default = currentVolume
        }
    })
    
    local volume = result and result[1]
    if not volume then
        return
    end
    
    TriggerServerEvent("lunar_unijob:setDeskVolume", playerId, volume)
end

-- Pause music
local function pauseMusic(playerId)
    TriggerServerEvent("lunar_unijob:pauseMusic", playerId)
end

-- Resume music
local function resumeMusic(playerId)
    TriggerServerEvent("lunar_unijob:resumeMusic", playerId)
end

-- Stop music
local function stopMusic(playerId)
    TriggerServerEvent("lunar_unijob:stopMusic", playerId)
end

-- Toggle loop
local function toggleLoop(playerId)
    local isLooped = exports.xsound:isLooped(playerId)
    TriggerServerEvent("lunar_unijob:setLoop", playerId, not isLooped)
end

-- Open music player menu
local function openMusicPlayerMenu(playerId)
    local menuOptions = {
        {
            title = locale("play_music_url"),
            description = locale("play_music_url_desc"),
            icon = "music",
            onSelect = playMusicUrl,
            args = playerId
        },
        {
            title = locale("change_volume"),
            description = locale("change_volume_desc"),
            icon = "volume-high",
            onSelect = changeVolume,
            args = playerId
        }
    }
    
    -- Add options if sound exists
    if exports.xsound:soundExists(playerId) then
        -- Loop toggle
        local loopTitle = exports.xsound:isLooped(playerId) 
            and locale("loop_music_enabled") 
            or locale("loop_music_disabled")
        
        table.insert(menuOptions, {
            title = loopTitle,
            description = locale("loop_music_desc"),
            icon = "rotate",
            onSelect = toggleLoop,
            args = playerId
        })
        
        -- Pause/Resume
        if exports.xsound:isPaused(playerId) then
            table.insert(menuOptions, {
                title = locale("resume_music"),
                description = locale("resume_music_desc"),
                icon = "play",
                onSelect = resumeMusic,
                args = playerId
            })
        else
            table.insert(menuOptions, {
                title = locale("pause_music"),
                description = locale("pause_music_desc"),
                icon = "pause",
                onSelect = pauseMusic,
                args = playerId
            })
        end
        
        -- Stop option (only if playing)
        if exports.xsound:isPlaying(playerId) then
            table.insert(menuOptions, {
                title = locale("stop_music"),
                description = locale("stop_music_desc"),
                icon = "stop",
                onSelect = stopMusic,
                args = playerId
            })
        end
    end
    
    -- Show context menu
    lib.registerContext({
        id = "music_player",
        title = locale("music_player"),
        options = menuOptions
    })
    
    lib.showContext("music_player")
end

-- Create music player points for a job
local function create(jobData)
    if not jobData.musicPlayers then
        return
    end
    
    for playerIndex, musicPlayer in ipairs(jobData.musicPlayers) do
        for locationIndex, coords in ipairs(musicPlayer.locations) do
            local playerId = string.format("%s_%s_%s", jobData.name, playerIndex, locationIndex)
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = musicPlayer.radius or Config.defaultRadius,
                options = {
                    {
                        label = musicPlayer.label or locale("play_music"),
                        icon = musicPlayer.icon or "music",
                        onSelect = openMusicPlayerMenu,
                        args = playerId
                    }
                }
            }, musicPlayer.target)
            
            table.insert(musicPlayerPoints, point)
        end
    end
end

-- Clear all music player points
local function clear()
    for _, point in ipairs(musicPlayerPoints) do
        point.remove()
    end
    table.wipe(musicPlayerPoints)
end

-- Export module
MusicPlayers = {
    create = create,
    clear = clear
}
