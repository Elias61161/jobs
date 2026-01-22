-- Drag Action Module
-- Handles dragging cuffed players

local draggedPed = nil
local DRAG_ANIM_DICT = "amb@world_human_drinking@coffee@male@base"
local DRAG_ANIM_CLIP = "base"

-- Stop dragging
function StopDrag()
    if draggedPed then
        TriggerServerEvent("lunar_unijob:drag")
        Binds.interact.removeListener("stop_drag")
        ClearPedSecondaryTask(cache.ped)
        LR.hideUI()
        draggedPed = nil
    end
end

-- Drag animation interval
SetInterval(function()
    if not draggedPed then
        return
    end
    
    -- Check if dragged ped still exists and is alive
    if not DoesEntityExist(draggedPed) or IsEntityDead(draggedPed) then
        StopDrag()
        draggedPed = nil
        return
    end
    
    -- Keep playing drag animation
    if not IsEntityPlayingAnim(cache.ped, DRAG_ANIM_DICT, DRAG_ANIM_CLIP, 3) then
        lib.requestAnimDict(DRAG_ANIM_DICT)
        TaskPlayAnim(cache.ped, DRAG_ANIM_DICT, DRAG_ANIM_CLIP, 4.0, 4.0, -1, 49, 0.0, false, false, false)
        RemoveAnimDict(DRAG_ANIM_DICT)
    end
end, 200)

-- Disable sprinting while dragging (if not allowed)
if not Settings.sprintWhileDrag then
    CreateThread(function()
        while true do
            if draggedPed then
                DisableControlAction(0, 21)
                SetPlayerSprint(cache.playerId, false)
                Wait(0)
            else
                Wait(500)
            end
        end
    end)
end

-- Create drag action
Actions.createPlayer("drag", "hand", function(targetServerId, targetPed)
    TriggerServerEvent("lunar_unijob:drag", targetServerId)
    LR.showUI(locale("stop_drag", Binds.interact:getCurrentKey()))
    Binds.interact.addListener("stop_drag", StopDrag)
    Editable.actionPerformed("drag")
    draggedPed = targetPed
end, function(targetPed)
    -- Can only drag cuffed players who aren't being carried
    return IsPedCuffed(targetPed) and not IsCarryActive()
end)

-- Get the currently dragged ped
function GetDraggedPed()
    return draggedPed
end
