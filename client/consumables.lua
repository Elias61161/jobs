-- Consumables Module
-- Handles usable item consumption with progress bars and animations

RegisterNetEvent("lunar_unijob:useConsumable", function(itemName)
    local itemConfig = Config.usableItems[itemName]
    
    if not itemConfig then
        return
    end
    
    -- Convert prop data for progress bar
    local propData = Utils.convertAnimProp(itemConfig.prop)
    
    -- Show progress bar with animation
    local success = LR.progressBar(
        itemConfig.progress,
        itemConfig.duration,
        false,
        itemConfig.animation,
        propData
    )
    
    -- Update player status on success
    if success then
        Editable.updateStatus(itemConfig)
    end
end)
