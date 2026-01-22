-- Shops Module
-- Handles job shop interaction points

local shopPoints = {}

-- Create shop points for a job
local function create(jobData)
    if not jobData.shops then
        return
    end
    
    for shopIndex, shop in ipairs(jobData.shops) do
        for locationIndex, coords in ipairs(shop.locations or {}) do
            if not coords then goto continue end
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = shop.radius or Config.defaultRadius,
                options = {
                    {
                        label = shop.label or locale("open_shop"),
                        icon = shop.icon or "shopping-basket",
                        onSelect = Editable.openShop,
                        args = {
                            job = jobData,
                            index = shopIndex,
                            locationIndex = locationIndex
                        },
                        canInteract = function()
                            return HasGrade(shop.grade)
                        end
                    }
                }
            }, shop.target)
            
            table.insert(shopPoints, point)
            
            ::continue::
        end
    end
end

-- Clear all shop points
local function clear()
    for _, point in ipairs(shopPoints) do
        point.remove()
    end
    table.wipe(shopPoints)
end

-- Export module
Shops = {
    create = create,
    clear = clear
}
