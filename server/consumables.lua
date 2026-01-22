-- Register all usable items from config
for itemName, _ in pairs(Config.usableItems) do
    Framework.registerUsableItem(itemName, function(playerId)
        local player = Framework.getPlayerFromId(playerId)

        if player then
            player:removeItem(itemName, 1)
            TriggerClientEvent("lunar_unijob:useConsumable", playerId, itemName)
        end
    end)
end
