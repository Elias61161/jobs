-- Main Client Module
-- Core job management and synchronization

local jobs = {}
local jobsSynced = false
local lastJob = nil
local lastGrade = nil
local jobCheckInterval = nil

-- Get all jobs
function GetJobs()
    return jobs
end

-- Get current player's job data
function GetCurrentJob()
    local jobName = Framework.getJob()
    return jobs[jobName]
end

-- Check if player has required grade
function HasGrade(gradeRequired)
    if not gradeRequired then
        return true
    end
    
    local currentGrade = Framework.getJobGrade()
    if type(currentGrade) == "number" and type(gradeRequired) == "number" then
        return currentGrade >= gradeRequired
    end
    
    return true
end

-- All job modules (populated lazily to ensure modules are loaded)
local modules = nil

local function getModules()
    if not modules then
        modules = {
            Alarms,
            BossActions,
            Blips,
            Cloakrooms,
            Collecting,
            Crafting,
            Garages,
            Selling,
            Shops,
            Stashes,
            Registers,
            AnimationZones,
            MusicPlayers,
            Teleports
        }
    end
    return modules
end

-- Update job modules and entities
local function updateJobModules(fullUpdate)
    local jobName = Framework.getJob()
    local currentJob = jobs[jobName]
    
    -- Full update: refresh global modules and entities
    if fullUpdate then
        -- Update global modules
        for _, module in ipairs(getModules()) do
            if module.update then
                module.update()
            end
        end
        
        -- Remove old entities
        Utils.removeEntities()
        
        -- Create props and peds for all jobs
        for _, jobData in pairs(jobs) do
            for _, fieldData in pairs(jobData) do
                if type(fieldData) == "table" and table.type(fieldData) == "array" then
                    for _, entry in ipairs(fieldData) do
                        if entry.locations then
                            for _, location in ipairs(entry.locations) do
                                -- Create props
                                if entry.prop then
                                    local coords = (type(location) == "table" and location.coords) or location
                                    Utils.createProps(coords, entry)
                                end
                                
                                -- Create peds
                                if entry.ped then
                                    local coords = (type(location) == "table" and location.coords) or location
                                    Utils.createPeds(coords, entry)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Update radial menu
    Actions.updateRadial()
    
    -- Update job-specific modules
    if currentJob then
        for _, module in ipairs(getModules()) do
            if module.clear then
                module.clear()
                module.create(currentJob)
            end
        end
    else
        -- Clear all modules when no job
        for _, module in ipairs(getModules()) do
            if module.clear then
                module.clear()
            end
        end
    end
end

-- Sync all jobs from server
RegisterNetEvent("lunar_unijob:syncJobs", function(data)
    jobsSynced = true
    jobs = data
    UI.updateJobs(jobs)
    updateJobModules(true)
end)

-- Sync single job update
RegisterNetEvent("lunar_unijob:syncJob", function(jobData)
    if not jobData then
        return
    end
    
    jobs[jobData.name] = jobData
    UI.updateJob(jobData)
    updateJobModules(true)
end)

-- Sync job removal
RegisterNetEvent("lunar_unijob:syncRemoveJob", function(jobName)
    jobs[jobName] = nil
    UI.removeJob(jobName)
    updateJobModules(true)
end)

-- Sync job field update
RegisterNetEvent("lunar_unijob:syncJobField", function(jobName, field, data)
    if not data then
        return
    end
    
    local job = jobs[jobName]
    job[field] = data
    UI.updateJob(job)
    updateJobModules(true)
end)

-- Player loaded handler
Framework.onPlayerLoaded(function()
    -- Request jobs if not synced
    if not jobsSynced then
        TriggerServerEvent("lunar_unijob:requestJobs")
    end
    
    -- Check for job/grade changes
    jobCheckInterval = SetInterval(function()
        local currentJob = Framework.getJob()
        local currentGrade = Framework.getJobGrade()
        
        if currentJob ~= lastJob or currentGrade ~= lastGrade then
            updateJobModules(false)
        end
        
        lastJob = currentJob
        lastGrade = currentGrade
    end, 500)
    
    -- Wait for UI and update jobs
    CreateThread(function()
        while not UI do
            Wait(100)
        end
        UI.updateJobs(jobs)
    end)
end)

-- Player logout handler
Framework.onPlayerLogout(function()
    if jobCheckInterval then
        ClearInterval(jobCheckInterval)
        jobCheckInterval = nil
    end
end)

-- Resource start handler
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        TriggerServerEvent("lunar_unijob:requestJobs")
    end
end)
