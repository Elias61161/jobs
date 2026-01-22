-- Jobs storage
local jobs = {}
local jobsLoaded = false

-- Get all jobs
function GetJobs()
    return jobs
end

-- Check if jobs are loaded
function AreJobsLoaded()
    return jobsLoaded
end

-- Feature modules
local featureModules = {
    Alarms,
    Collecting,
    Crafting,
    Garages,
    Selling,
    Shops,
    Stashes,
    Registers,
    AnimationZones,
    MusicPlayers,
    AdvancedCollecting
}

-- Track which players have requested jobs
local requestedJobsPlayers = {}

-- Request jobs event handler
RegisterNetEvent("lunar_unijob:requestJobs", function()
    local src = source

    if requestedJobsPlayers[src] then
        return
    end

    requestedJobsPlayers[src] = true

    while not jobsLoaded do
        Wait(0)
    end

    TriggerLatentClientEvent("lunar_unijob:syncJobs", src, 50000, jobs)
end)

-- Delete job from ESX database
local function deleteJobFromESX(jobName)
    MySQL.update.await("DELETE FROM jobs WHERE name = ?", { jobName })
    MySQL.update.await("DELETE FROM job_grades WHERE job_name = ?", { jobName })

    local result = MySQL.query.await([[
        SELECT COUNT(*) as count
        FROM information_schema.columns
        WHERE table_schema = DATABASE()
        AND table_name = 'job_grades'
        AND column_name = 'id'
        AND extra LIKE '%auto_increment%'
        AND column_key = 'PRI';
    ]])

    if result[1].count == 0 then
        MySQL.query.await("ALTER TABLE job_grades MODIFY COLUMN id INT AUTO_INCREMENT PRIMARY KEY;")
    end

    MySQL.query.await("ALTER TABLE job_grades AUTO_INCREMENT = 1;")
end

-- Register job in framework
local function registerJobInFramework(jobData, isExisting)
    if not Config.registerJobInFramework then
        return
    end

    if Framework.name == "es_extended" then
        local societyName = "society_" .. jobData.name

        -- Register addon account if esx_addonaccount is running
        if GetResourceState("esx_addonaccount") == "started" then
            MySQL.insert.await("INSERT IGNORE INTO addon_account (name, label, shared) VALUES (?, ?, 1)", {
                societyName, jobData.label
            })
            MySQL.update.await("UPDATE addon_account SET label = ? WHERE name = ?", {
                jobData.label, societyName
            })
        end

        -- Register datastore if esx_datastore is running
        if GetResourceState("esx_datastore") == "started" then
            MySQL.insert.await("INSERT IGNORE INTO datastore (name, label, shared) VALUES (?, ?, 1)", {
                societyName, jobData.label
            })
            MySQL.update.await("UPDATE datastore SET label = ? WHERE name = ?", {
                jobData.label, societyName
            })
        end

        -- Delete existing job if not updating
        if not isExisting then
            deleteJobFromESX(jobData.name)
        end

        -- Insert job
        MySQL.insert.await("INSERT INTO jobs (name, label, whitelisted) VALUES(?, ?, ?)", {
            jobData.name,
            jobData.label,
            jobData.whitelisted or false
        })

        -- Insert grades
        for gradeIndex, gradeData in pairs(jobData.grades) do
            MySQL.insert.await("INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES(?, ?, ?, ?, ?, ?, ?)", {
                jobData.name,
                gradeIndex - 1,
                gradeData.name,
                gradeData.label,
                gradeData.salary,
                "{}",
                "{}"
            })
        end

        -- Refresh ESX jobs
        Framework.object.RefreshJobs()

        -- Register society
        TriggerEvent("esx_society:registerSociety", jobData.name, jobData.label, societyName, societyName, societyName, { type = "public" })

    elseif Framework.name == "qb-core" then
        local isQBX = GetResourceState("qbx_core") == "started"

        local qbJobData = {
            label = jobData.label,
            type = jobData.type,
            defaultDuty = jobData.defaultDuty ~= nil and jobData.defaultDuty or true,
            offDutyPay = jobData.offDutyPay or false,
            grades = {}
        }

        for gradeIndex, gradeData in ipairs(jobData.grades) do
            local gradeKey = isQBX and (gradeIndex - 1) or tostring(gradeIndex - 1)
            qbJobData.grades[gradeKey] = {
                name = gradeData.label,
                payment = gradeData.salary,
                isboss = gradeData.bossActions
            }
        end

        exports["qb-core"]:RemoveJob(jobData.name)
        exports["qb-core"]:AddJob(jobData.name, qbJobData)
    end
end

-- Load job file from convert_jobs folder
local function loadJobFile(filePath)
    local fileContent = LoadResourceFile(cache.resource, filePath)

    if not fileContent or fileContent == "" then
        warn(("Couldn't load %s. (File doesn't exist or is empty)"):format(filePath))
        return false
    end

    -- Check file structure
    if fileContent:sub(1, 12) ~= "---@type Job" then
        warn(("Ignoring %s because of a invalid file structure. (Check the docs)"):format(filePath))
        return false
    end

    local success, result = Parser.parse(fileContent)

    if success then
        if jobs[result.name] then
            warn(("Ignoring %s job, a job with this name already exists."):format(result.name))
            return false
        end

        local registerSuccess, registerError = pcall(registerJobInFramework, result)
        if not registerSuccess then
            warn(("Couldn't register %s in your framework due to an error."):format(result.name))
            warn(registerError)
            return false
        end

        jobs[result.name] = result
        return true
    else
        warn(result:format(filePath))
        return false
    end
end

-- Get files in directory
local function getFilesInDirectory(dirPath)
    local files = {}
    local isUnix = dirPath:sub(1, 1) == "/"

    local handle
    if isUnix then
        handle = io.popen('ls "' .. dirPath .. '"')
    else
        handle = io.popen('dir "' .. dirPath .. '" /b')
    end

    if handle then
        if isUnix then
            local content = handle:read("*all")
            for fileName in content:gmatch("[^%s]+") do
                if fileName:find(".lua") then
                    table.insert(files, fileName)
                end
            end
        else
            for fileName in handle:lines() do
                if fileName:find(".lua") then
                    table.insert(files, fileName)
                end
            end
        end
        handle:close()
    end

    return files
end

-- Apply default values to job data
local function applyJobDefaults()
    local defaultLabels = {
        bossMenus = locale("open_boss_menu"),
        cloakrooms = locale("open_cloakroom"),
        collecting = locale("start_collecting"),
        advancedCollecting = locale("start_collecting"),
        crafting = locale("crafting"),
        garages = locale("open_garage"),
        selling = locale("selling"),
        shops = locale("shop"),
        stashes = locale("open_stash"),
        alarms = locale("trigger_alarm"),
        registers = locale("register_header"),
        musicPlayers = locale("music_player")
    }

    local defaultIcons = {
        bossMenus = "briefcase",
        cloakrooms = "shirt",
        collecting = "hand",
        advancedCollecting = "hand",
        crafting = "screwdriver-wrench",
        garages = "warehouse",
        selling = "dollar-sign",
        shops = "shopping-cart",
        stashes = "box",
        alarms = "bell",
        registers = "cash-register",
        animationZones = "running",
        musicPlayers = "music",
        teleports = "door-open"
    }

    for _, jobData in pairs(jobs) do
        -- Apply defaults to feature zones
        for featureName, defaultIcon in pairs(defaultIcons) do
            if jobData[featureName] then
                for _, zoneData in ipairs(jobData[featureName]) do
                    if not zoneData.label and defaultLabels[featureName] then
                        zoneData.label = defaultLabels[featureName]
                    end
                    if not zoneData.icon then
                        zoneData.icon = defaultIcon
                    end
                    if not zoneData.radius then
                        zoneData.radius = 1.25
                    end
                    if not zoneData.duration and featureName ~= "animationZones" then
                        zoneData.duration = 3000
                    end

                    -- Convert single prop/ped to array
                    if zoneData.prop and lib.table.type(zoneData.prop) == "hash" then
                        zoneData.prop = { zoneData.prop }
                    end
                    if zoneData.ped and lib.table.type(zoneData.ped) == "hash" then
                        zoneData.ped = { zoneData.ped }
                    end
                end
            end
        end

        -- Normalize collecting item counts
        if jobData.collecting then
            for _, collectData in pairs(jobData.collecting) do
                for _, itemData in pairs(collectData.items or {}) do
                    if type(itemData.count) == "number" then
                        itemData.count = { min = itemData.count, max = itemData.count }
                    end
                end
            end
        end

        -- Normalize advanced collecting item counts
        if jobData.advancedCollecting then
            for _, collectData in pairs(jobData.advancedCollecting) do
                for _, itemData in pairs(collectData.items or {}) do
                    if type(itemData.count) == "number" then
                        itemData.count = { min = itemData.count, max = itemData.count }
                    end
                end
            end
        end

        -- Set default currency and grade for shop items
        if jobData.shops then
            for _, shopData in pairs(jobData.shops) do
                for _, itemData in pairs(shopData.items or {}) do
                    if not itemData.currency then
                        itemData.currency = "money"
                    end
                    if not itemData.grade then
                        itemData.grade = 0
                    end
                end
            end
        end

        -- Copy animation from crafting entries to parent
        if jobData.crafting then
            for _, craftData in pairs(jobData.crafting) do
                for _, entryData in pairs(craftData.entries or {}) do
                    if entryData.animation then
                        craftData.animation = entryData.animation
                        craftData.animationProp = entryData.animationProp
                        break
                    end
                end
            end
        end

        -- Set default grade for various features
        local gradeFeatures = { "crafting", "garages", "selling", "shops", "stashes", "teleports" }
        for _, featureName in ipairs(gradeFeatures) do
            if jobData[featureName] then
                for _, featureData in ipairs(jobData[featureName]) do
                    if not featureData.grade then
                        featureData.grade = 0
                    end
                end
            end
        end
    end
end

-- Convert jobs command (for migrating from config files)
RegisterCommand("convertjobs", function(src)
    if src ~= 0 then
        return
    end

    local resourcePath = GetResourcePath(cache.resource) .. "/config/convert_jobs"
    local files = getFilesInDirectory(resourcePath)

    if #files == 0 then
        error(("Cannot load jobs from %s/config/convert_jobs"):format(cache.resource))
    end

    for _, fileName in ipairs(files) do
        local filePath = ("config/convert_jobs/%s"):format(fileName)
        loadJobFile(filePath)
    end

    applyJobDefaults()

    -- Save jobs to database
    for jobName, jobData in pairs(jobs) do
        local existing = MySQL.single.await("SELECT * FROM lunar_jobscreator WHERE name = ?", { jobName })
        if not existing then
            MySQL.insert.await("INSERT INTO lunar_jobscreator (name, data) VALUES (?, ?)", {
                jobName, json.encode(jobData)
            })
        end
    end

    TriggerLatentClientEvent("lunar_unijob:syncJobs", -1, 50000, jobs)
end)

-- Convert table values to vectors
local function convertToVectors(data)
    for key, value in pairs(data) do
        if type(value) == "table" then
            if value.x and value.y and value.z then
                if value.w then
                    data[key] = vector4(value.x, value.y, value.z, value.w)
                else
                    data[key] = vector3(value.x, value.y, value.z)
                end
            else
                convertToVectors(value)
            end
        elseif type(value) == "string" and value:len() == 0 then
            data[key] = nil
        end
    end
end

-- Load jobs from database on MySQL ready
MySQL.ready(function()
    Wait(1000)

    local dbJobs = MySQL.query.await("SELECT * FROM lunar_jobscreator")

    -- Delete existing ESX jobs first
    if Framework.name == "es_extended" then
        for i = 1, #dbJobs do
            deleteJobFromESX(dbJobs[i].name)
        end
    end

    -- Load and register jobs
    for i = 1, #dbJobs do
        local row = dbJobs[i]
        local jobData = json.decode(row.data)
        convertToVectors(jobData)

        jobs[row.name] = jobData
        registerJobInFramework(jobData, true)
    end

    jobsLoaded = true

    -- Initialize feature modules
    for _, module in ipairs(featureModules) do
        module.init(jobs)
    end
end)

-- Create job event handler
RegisterNetEvent("lunar_unijob:createJob", function(jobData)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    if jobs[jobData.name] then
        return
    end

    convertToVectors(jobData)
    jobs[jobData.name] = jobData
    registerJobInFramework(jobData)

    MySQL.query.await("INSERT INTO lunar_jobscreator (name, data) VALUES (?, ?)", {
        jobData.name, json.encode(jobData)
    })

    TriggerClientEvent("lunar_unijob:syncJob", -1, jobData)

    -- Update feature modules
    for _, module in ipairs(featureModules) do
        if module.update then
            module.update(jobData)
        end
    end

    AddHistoryLog(src, locale("history_create_job", jobData.label))
end)

-- Update job event handler
RegisterNetEvent("lunar_unijob:updateJob", function(jobData)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    convertToVectors(jobData)
    jobs[jobData.name] = jobData

    MySQL.query.await("UPDATE lunar_jobscreator SET data = ? WHERE name = ?", {
        json.encode(jobData), jobData.name
    })

    TriggerClientEvent("lunar_unijob:syncJob", -1, jobData)

    for _, module in ipairs(featureModules) do
        if module.update then
            module.update(jobData)
        end
    end

    AddHistoryLog(src, locale("history_update_job", jobData.label))
end)

-- Update job field event handler
RegisterNetEvent("lunar_unijob:updateJobField", function(jobName, fieldName, fieldValue)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    convertToVectors(fieldValue)

    local jobData = jobs[jobName]
    jobData[fieldName] = fieldValue

    MySQL.query.await("UPDATE lunar_jobscreator SET data = ? WHERE name = ?", {
        json.encode(jobData), jobName
    })

    TriggerClientEvent("lunar_unijob:syncJobField", -1, jobName, fieldName, fieldValue)

    for _, module in ipairs(featureModules) do
        if module.update then
            module.update(jobData)
        end
    end

    if fieldName == "grades" then
        registerJobInFramework(jobData)
    end

    AddHistoryLog(src, locale("history_update_job", jobData.label))
end)

-- Remove job event handler
RegisterNetEvent("lunar_unijob:removeJob", function(jobName)
    local src = source
    local player = Framework.getPlayerFromId(src)

    if not player or not IsPlayerAdmin(player.source) then
        return
    end

    jobs[jobName] = nil

    MySQL.query.await("DELETE FROM lunar_jobscreator WHERE name = ?", { jobName })

    TriggerClientEvent("lunar_unijob:syncRemoveJob", -1, jobName)
end)

-- Subcommands for unijob command
local subcommands = {}

function subcommands.helper(playerId)
    local player = Framework.getPlayerFromId(playerId)

    if player and IsPlayerAdmin(player.source) then
        TriggerClientEvent("lunar_unijob:openHelper", playerId)
    end
end

-- Register unijob command
RegisterCommand("unijob", function(src, args)
    local subcommand = args[1]
    local handler = subcommands[subcommand]

    if not handler then
        warn("Unsupported subcommand, view the documentation for help.")
        return
    end

    handler(src, args)
end)

-- Build accounts lookup table
Config.accountsByKey = {}
for _, account in ipairs(Config.accounts) do
    Config.accountsByKey[account] = true
end

-- Export to set job grade salary
exports("setJobGradeSalary", function(jobName, gradeIndex, salary)
    local jobData = jobs[jobName]
    if not jobData then
        return
    end

    local grade = jobData.grades[gradeIndex - 1]
    if grade then
        grade.salary = salary
        registerJobInFramework(jobData)
    end
end)

-- Check if player is admin
function IsPlayerAdmin(playerId)
    if Framework.name == "qb-core" then
        return IsPlayerAceAllowed(playerId, "jobscreator_admin")
    else
        local player = Framework.getPlayerFromId(playerId)
        if player then
            return player:hasOneOfGroups(Config.adminGroups)
        end
        return false
    end
end
