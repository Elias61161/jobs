-- Selling Module
-- Handles job selling interaction points

local isSelling = false
local sellingPoints = {}

-- Open selling menu
local function openSellingMenu(args)
    local sellData = args.data
    local sellIndex = args.index
    local locationIndex = args.locationIndex
    
    -- Sell item handler
    local function sellItem(itemIndex)
        local item = sellData.items[itemIndex]
        local itemLabel = Utils.getItemLabel(item.name)
        
        -- Show amount input dialog
        local result = lib.inputDialog(locale("selling_header", itemLabel, item.price), {
            {
                type = "number",
                label = locale("amount"),
                min = 1,
                required = true
            }
        })
        
        local amount = result and result[1]
        if not amount then
            lib.showContext("selling")
            return
        end
        
        -- Request selling from server
        local canSell, errorMsg = lib.callback.await("lunar_unijob:startSelling", false, sellIndex, locationIndex, itemIndex, amount)
        
        if not canSell then
            LR.notify(errorMsg or locale("cant_sell"), "error")
            return
        end
        
        CreateThread(function()
            local animation = sellData.animation
            local animationProp = sellData.animationProp
            
            -- Play animation if defined
            if animation then
                Utils.playAnim(animation, animationProp)
            end
            
            if sellData.sellAtOnce then
                -- Sell all at once
                LR.progressBar(sellData.progress, sellData.duration, false)
            else
                -- Sell one by one
                isSelling = true
                local remaining = amount
                
                while isSelling do
                    local success = LR.progressBar(sellData.progress, sellData.duration, true)
                    
                    if not success then
                        TriggerServerEvent("lunar_unijob:stopSelling")
                        isSelling = false
                    end
                    
                    remaining = remaining - 1
                    if remaining == 0 then
                        isSelling = false
                    end
                    
                    Wait(0)
                end
            end
            
            ClearPedTasks(cache.ped)
        end)
    end
    
    -- Build menu options
    local menuOptions = {}
    
    for itemIndex, item in ipairs(sellData.items) do
        local description
        
        if type(item.price) == "number" then
            description = locale("sell_price", item.price)
        else
            description = locale("sell_price2", item.price.min, item.price.max)
        end
        
        table.insert(menuOptions, {
            title = Utils.getItemLabel(item.name),
            description = description,
            icon = item.icon,
            image = item.image,
            onSelect = sellItem,
            args = itemIndex
        })
    end
    
    -- Show context menu
    lib.registerContext({
        id = "selling",
        title = locale("selling"),
        options = menuOptions
    })
    
    lib.showContext("selling")
end

-- Stop selling action
local function stopSelling()
    TriggerServerEvent("lunar_unijob:stopSelling")
    isSelling = false
    
    if LR.progressActive() then
        LR.cancelProgress()
    end
end

-- Event: Stop selling from server
RegisterNetEvent("lunar_unijob:stopSelling", function(errorMsg)
    isSelling = false
    
    if LR.progressActive() then
        LR.cancelProgress()
    end
    
    if errorMsg then
        LR.notify(errorMsg, "error")
    end
end)

-- Create selling points for a job
local function create(jobData)
    if not jobData.selling then
        return
    end
    
    for sellIndex, sellData in ipairs(jobData.selling) do
        for locationIndex, coords in ipairs(sellData.locations or {}) do
            if not coords then goto continue end
            
            local point = Utils.createInteractionPoint({
                coords = coords,
                radius = sellData.radius or Config.defaultRadius,
                options = {
                    {
                        label = sellData.label or locale("open_selling"),
                        icon = sellData.icon or "dollar-sign",
                        canInteract = function()
                            return not isSelling and HasGrade(sellData.grade)
                        end,
                        onSelect = openSellingMenu,
                        args = {
                            data = sellData,
                            index = sellIndex,
                            locationIndex = locationIndex
                        }
                    },
                    {
                        label = locale("cancel"),
                        icon = "xmark",
                        canInteract = function()
                            return isSelling and HasGrade(sellData.grade)
                        end,
                        onSelect = stopSelling
                    }
                }
            }, sellData.target)
            
            table.insert(sellingPoints, point)
            
            ::continue::
        end
    end
end

-- Clear all selling points
local function clear()
    for _, point in ipairs(sellingPoints) do
        point.remove()
    end
    table.wipe(sellingPoints)
end

-- Export module
Selling = {
    create = create,
    clear = clear
}
