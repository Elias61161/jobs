-- Stashes Module
-- Handles job stash interaction points

local jobStashes = {}
local globalStashes = {}

-- Create a single stash interaction point
local function createStashPoint(jobData, stashIndex)
    local stash = jobData.stashes[stashIndex]
    
    for locationIndex, coords in ipairs(stash.locations or {}) do
        if not coords then goto continue end
        -- Generate stash name
        local stashName = stash.name or string.format("%s_stash_%s_%s", jobData.name, stash.name or stashIndex, locationIndex)
        
        -- Create interaction point
        local point = Utils.createInteractionPoint({
            coords = coords,
            radius = stash.radius or Config.defaultRadius,
            options = {
                {
                    label = stash.label or locale("open_stash"),
                    icon = stash.icon or "box-archive",
                    onSelect = Editable.openStash,
                    args = {
                        name = stashName,
                        data = stash
                    },
                    canInteract = function()
                        if stash.global then
                            return true
                        end
                        return HasGrade(stash.grade)
                    end
                }
            }
        }, stash.target)
        
        -- Store in appropriate table
        if stash.global then
            table.insert(globalStashes, point)
        else
            table.insert(jobStashes, point)
        end
        
        ::continue::
    end
end

-- Create stashes for a job (non-global only)
local function create(jobData)
    if not jobData.stashes then
        return
    end
    
    for stashIndex, stash in ipairs(jobData.stashes) do
        if not stash.global then
            createStashPoint(jobData, stashIndex)
        end
    end
end

-- Clear job-specific stashes
local function clear()
    for _, point in ipairs(jobStashes) do
        point.remove()
    end
    table.wipe(jobStashes)
end

-- Update global stashes (recreate all global stashes from all jobs)
local function update()
    -- Clear existing global stashes
    for _, point in ipairs(globalStashes) do
        point.remove()
    end
    table.wipe(globalStashes)
    
    -- Recreate global stashes from all jobs
    local jobs = GetJobs()
    for _, jobData in pairs(jobs) do
        if jobData.stashes then
            for stashIndex, stash in ipairs(jobData.stashes) do
                if stash.global then
                    createStashPoint(jobData, stashIndex)
                end
            end
        end
    end
end

-- Export module
Stashes = {
    create = create,
    clear = clear,
    update = update
}
