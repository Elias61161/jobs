-- Cloakrooms Module
-- Handles job cloakroom interaction points

local cloakroomPoints = {}

-- Create cloakroom points for a job
local function create(jobData)
    if not jobData.cloakrooms then
        return
    end
    
    for _, cloakroom in ipairs(jobData.cloakrooms) do
        for _, coords in ipairs(cloakroom.locations or {}) do
            if not coords then goto continue end
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = cloakroom.radius or Config.defaultRadius,
                options = {
                    {
                        label = locale("open_cloakroom"),
                        icon = "shirt",
                        onSelect = Editable.openCloakroom
                    }
                }
            }, cloakroom.target)
            
            table.insert(cloakroomPoints, point)
            
            ::continue::
        end
    end
end

-- Clear all cloakroom points
local function clear()
    for _, point in ipairs(cloakroomPoints) do
        point.remove()
    end
    table.wipe(cloakroomPoints)
end

-- Export module
Cloakrooms = {
    create = create,
    clear = clear
}
