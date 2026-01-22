-- Boss Actions Module
-- Handles boss menu interaction points

local bossMenuPoints = {}

-- Create boss menu interaction points for a job
local function create(jobData)
    -- Check if job has boss menus
    if not jobData.bossMenus then
        return
    end
    
    -- Check if current grade has boss actions permission
    local currentGrade = Framework.getJobGrade() + 1
    local gradeData = jobData.grades[currentGrade]
    
    if not gradeData or not gradeData.bossActions then
        return
    end
    
    -- Create interaction points for each boss menu location
    for _, bossMenu in ipairs(jobData.bossMenus) do
        for _, coords in ipairs(bossMenu.locations or {}) do
            if not coords then goto continue end
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = bossMenu.radius or Config.defaultRadius,
                options = {
                    {
                        label = locale("open_boss_menu"),
                        icon = bossMenu.icon or "briefcase",
                        onSelect = Editable.openBossMenu
                    }
                }
            }, bossMenu.target)
            
            table.insert(bossMenuPoints, point)
            
            ::continue::
        end
    end
end

-- Clear all boss menu interaction points
local function clear()
    for _, point in ipairs(bossMenuPoints) do
        point.remove()
    end
    table.wipe(bossMenuPoints)
end

-- Export module
BossActions = {
    create = create,
    clear = clear
}

-- Add boss action to menu (deferred to ensure Actions is loaded)
CreateThread(function()
    while not Actions do
        Wait(100)
    end
    
    Actions.createPlayer("boss", "briefcase", function()
        Editable.openBossMenu()
    end, function(entity)
        -- Only show if current job has boss actions permission
        local currentJob = GetCurrentJob()
        if not currentJob then return false end
        
        local currentGrade = Framework.getJobGrade() + 1
        local gradeData = currentJob.grades[currentGrade]
        
        return gradeData and gradeData.bossActions
    end)
end)
