-- Other Actions Module
-- Handles billing, reviving, healing, and vehicle player management

-- Player Actions
Actions.createPlayer("bill", "file-invoice", Editable.giveInvoice)
Actions.createPlayer("revive", "suitcase-medical", Editable.revivePlayer)
Actions.createPlayer("heal", "bandage", Editable.healPlayer)

-- Put player inside vehicle action
Actions.createVehicle("putInsideVehicle", "user-plus", function(vehicle)
    local draggedPed = GetDraggedPed()
    if not draggedPed then
        return
    end
    
    local playerIndex = NetworkGetPlayerIndexFromPed(draggedPed)
    local targetServerId = GetPlayerServerId(playerIndex)
    
    if targetServerId == 0 then
        return
    end
    
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    TriggerServerEvent("lunar_unijob:putInVehicle", targetServerId, vehicleNetId)
    StopDrag()
    Editable.actionPerformed("putInVehicle")
end, function()
    -- Can only put player in vehicle if dragging someone
    return GetDraggedPed() ~= nil
end)

-- Take player out of vehicle action
Actions.createVehicle("takeOutOfVehicle", "user-minus", function(vehicle)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    
    -- Check back seats first (from last seat to seat index maxPassengers - 3)
    for seatIndex = maxPassengers - 1, maxPassengers - 3, -1 do
        local ped = GetPedInVehicleSeat(vehicle, seatIndex)
        
        if ped ~= 0 and IsPedAPlayer(ped) then
            local playerIndex = NetworkGetPlayerIndexFromPed(ped)
            local targetServerId = GetPlayerServerId(playerIndex)
            
            if targetServerId == 0 then
                return
            end
            
            TriggerServerEvent("lunar_unijob:outTheVehicle", targetServerId)
            Editable.actionPerformed("takeOutOfVehicle")
            break
        end
    end
end, function(vehicle)
    -- Can only take out if there's a cuffed player in the vehicle
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    
    for seatIndex = maxPassengers - 1, maxPassengers - 3, -1 do
        local ped = GetPedInVehicleSeat(vehicle, seatIndex)
        
        if ped ~= 0 and IsPedCuffed(ped) then
            return true
        end
    end
    
    return false
end)
