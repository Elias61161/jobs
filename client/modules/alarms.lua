-- Alarms Module
-- Handles job alarm interaction points

local jobAlarmPoints = {}
local globalAlarmPoints = {}

-- Trigger alarm action
local function triggerAlarm(args)
    local canTrigger = lib.callback.await("lunar_unijob:triggerAlarm", false, args)
    
    if canTrigger then
        LR.progressBar(locale("triggering_alarm"), 1000, false, {
            dict = "mini@repair",
            clip = "fixing_a_ped"
        })
        LR.notify(locale("alarm_triggered"), "success")
    else
        LR.notify(locale("cannot_alarm"), "error")
    end
end

-- Create alarm points for a job (non-global only)
local function create(jobData)
    if not jobData.alarms then
        return
    end
    
    for alarmIndex, alarm in ipairs(jobData.alarms) do
        if not alarm.global then
            for locationIndex, coords in ipairs(alarm.locations or {}) do
                if not coords then goto continue end
                
                local point = Utils.createInteractionPoint({
                    coords = coords,
                    radius = alarm.radius or Config.defaultRadius,
                    options = {
                        {
                            label = alarm.label or locale("trigger_alarm"),
                            icon = "bell",
                            onSelect = triggerAlarm,
                            args = {
                                job = jobData.name,
                                index = alarmIndex,
                                locationIndex = locationIndex
                            }
                        }
                    }
                }, alarm.target)
                
                table.insert(jobAlarmPoints, point)
                
                ::continue::
            end
        end
    end
end

-- Clear job-specific alarm points
local function clear()
    for _, point in ipairs(jobAlarmPoints) do
        point.remove()
    end
    table.wipe(jobAlarmPoints)
end

-- Update global alarm points (recreate all global alarms from all jobs)
local function update()
    -- Clear existing global alarm points
    for _, point in ipairs(globalAlarmPoints) do
        point.remove()
    end
    table.wipe(globalAlarmPoints)
    
    -- Recreate global alarms from all jobs
    local jobs = GetJobs()
    for _, jobData in pairs(jobs) do
        if jobData.alarms then
            for alarmIndex, alarm in ipairs(jobData.alarms) do
                if alarm.global then
                    for locationIndex, coords in ipairs(alarm.locations or {}) do
                        if not coords then goto continue2 end
                        
                        local point = Utils.createInteractionPoint({
                            coords = coords,
                            radius = alarm.radius or Config.defaultRadius,
                            options = {
                                {
                                    label = alarm.label or locale("trigger_alarm"),
                                    icon = "bell",
                                    onSelect = triggerAlarm,
                                    args = {
                                        job = jobData.name,
                                        index = alarmIndex,
                                        locationIndex = locationIndex
                                    }
                                }
                            }
                        })
                        
                        table.insert(globalAlarmPoints, point)
                        
                        ::continue2::
                    end
                end
            end
        end
    end
end

-- Export module
Alarms = {
    create = create,
    clear = clear,
    update = update
}
