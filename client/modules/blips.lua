-- Blips Module
-- Handles job blip creation and management

local jobBlips = {}
local globalBlips = {}

-- Create blips for a specific job (non-global only)
local function create(jobData)
    if not jobData.blips then
        return
    end
    
    for _, blipData in ipairs(jobData.blips) do
        if not blipData.global then
            -- Ensure size is a number
            blipData.size = blipData.size + 0.0
            
            -- Clone the blip data
            local blipConfig = table.clone(blipData)
            
            -- Apply custom font if configured
            if Config.blipsFont and #Config.blipsFont > 0 then
                blipConfig.name = string.format("<font face=\"%s\">%s</font>", Config.blipsFont, blipConfig.name)
            end
            
            -- Create the blip
            local blip = Utils.createBlip(blipConfig.coords, blipConfig)
            table.insert(jobBlips, blip)
        end
    end
end

-- Clear all job-specific blips
local function clear()
    for _, blip in ipairs(jobBlips) do
        if blip and blip.remove then
            blip.remove()
        end
    end
    table.wipe(jobBlips)
end

-- Update global blips (recreate all global blips from all jobs)
local function update()
    -- Clear existing global blips
    for _, blip in ipairs(globalBlips) do
        if blip and blip.remove then
            blip.remove()
        end
    end
    table.wipe(globalBlips)
    
    -- Recreate global blips from all jobs
    local jobs = GetJobs()
    for _, jobData in pairs(jobs) do
        if jobData.blips then
            for _, blipData in ipairs(jobData.blips) do
                if blipData.global and blipData.coords then
                    -- Ensure size is a number
                    blipData.size = blipData.size + 0.0
                    
                    -- Clone the blip data
                    local blipConfig = table.clone(blipData)
                    
                    -- Apply custom font if configured
                    if Config.blipsFont and #Config.blipsFont > 0 then
                        blipConfig.name = string.format("<font face=\"%s\">%s</font>", Config.blipsFont, blipConfig.name)
                    end
                    
                    -- Create the blip
                    local blip = Utils.createBlip(blipConfig.coords, blipConfig)
                    table.insert(globalBlips, blip)
                end
            end
        end
    end
end

-- Export module
Blips = {
    create = create,
    clear = clear,
    update = update
}
