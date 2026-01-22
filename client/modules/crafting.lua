-- Crafting Module
-- Handles job crafting interaction points

local craftingPoints = {}

-- Format required items for display
local function formatRequiredItems(requiredItems)
    local itemStrings = {}
    
    for _, item in ipairs(requiredItems) do
        local itemLabel = Utils.getItemLabel(item.name)
        table.insert(itemStrings, string.format("%sx %s", item.count, itemLabel))
    end
    
    return locale("required_items", table.concat(itemStrings, ", "))
end

-- Open crafting menu
local function openCraftingMenu(args)
    local craftData = args.data
    local craftIndex = args.index
    local locationIndex = args.locationIndex
    
    -- Craft item handler
    local function craftItem(entryIndex)
        if LR.progressActive() then
            return
        end
        
        local entry = craftData.entries[entryIndex]
        
        -- Request crafting from server
        local canCraft, errorMsg = lib.callback.await("lunar_unijob:craft", false, craftIndex, locationIndex, entryIndex)
        
        if not canCraft then
            LR.notify(errorMsg or locale("missing_required_items"), "error")
            return
        end
        
        -- Convert animation prop for progress bar
        local animProp = Utils.convertAnimProp(craftData.animationProp)
        
        -- Show progress bar with animation
        local success = LR.progressBar(entry.progress, entry.duration, true, craftData.animation, animProp)
        
        if not success then
            TriggerServerEvent("lunar_unijob:stopCrafting")
        end
        
        -- Clean up scenario objects if using scenario animation
        if craftData.animation and craftData.animation.scenario then
            while Utils.isPlayingAnim(craftData.animation) do
                Wait(100)
            end
            
            local coords = GetEntityCoords(cache.ped)
            ClearAreaOfObjects(coords.x, coords.y, coords.z, 2.0, 0)
        end
    end
    
    -- Build menu options
    local menuOptions = {}
    
    for entryIndex, entry in ipairs(craftData.entries) do
        local title = entry.label or Utils.getItemLabel(entry.giveItems[1].name)
        
        -- Build description with blueprint info and required items
        local description = ""
        if entry.blueprint then
            description = locale("blueprint") or ""
        end
        description = description .. formatRequiredItems(entry.requiredItems)
        
        -- Get icon/image
        local icon = nil
        if entry.blueprint then
            icon = Editable.getInventoryIcon(entry.giveItems[1].name)
        end
        
        local image = Editable.getInventoryIcon(entry.blueprint or entry.giveItems[1].name)
        
        table.insert(menuOptions, {
            title = title,
            description = description,
            icon = icon,
            image = image,
            args = entryIndex,
            onSelect = craftItem
        })
    end
    
    -- Show context menu
    lib.registerContext({
        id = "crafting",
        title = locale("crafting"),
        options = menuOptions
    })
    
    lib.showContext("crafting")
end

-- Create crafting points for a job
local function create(jobData)
    if not jobData.crafting then
        return
    end
    
    for craftIndex, craftData in ipairs(jobData.crafting) do
        for locationIndex, coords in ipairs(craftData.locations or {}) do
            if not coords then goto continue end
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = craftData.radius or Config.defaultRadius,
                options = {
                    {
                        label = craftData.label or locale("open_crafting"),
                        icon = craftData.icon or "screwdriver-wrench",
                        onSelect = openCraftingMenu,
                        args = {
                            data = craftData,
                            index = craftIndex,
                            locationIndex = locationIndex
                        },
                        canInteract = function()
                            return not LR.progressActive() and HasGrade(craftData.grade)
                        end
                    },
                    {
                        label = locale("stop_anim"),
                        icon = "circle-xmark",
                        onSelect = function()
                            if LR.progressActive() then
                                LR.cancelProgress()
                            end
                        end,
                        canInteract = function()
                            return LR.progressActive()
                        end
                    }
                }
            }, craftData.target)
            
            table.insert(craftingPoints, point)
            
            ::continue::
        end
    end
end

-- Clear all crafting points
local function clear()
    for _, point in ipairs(craftingPoints) do
        point.remove()
    end
    table.wipe(craftingPoints)
end

-- Export module
Crafting = {
    create = create,
    clear = clear
}
