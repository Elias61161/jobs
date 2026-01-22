-- Registers Module
-- Handles job register interaction points

local registerPoints = {}
local registerStates = {}

-- Initialize register states from server
lib.callback("lunar_unijob:getRegisters", false, function(states)
    registerStates = states
end)

-- Sync all register states
RegisterNetEvent("lunar_unijob:syncRegisters", function(states)
    registerStates = states
end)

-- Sync single register state
RegisterNetEvent("lunar_unijob:syncRegister", function(registerId, state)
    registerStates[registerId] = state
end)

-- Pay register action
local function payRegister(registerId)
    local result = lib.inputDialog(locale("register_header"), {
        {
            type = "select",
            label = locale("payment_method"),
            options = Editable.getPaymentMethods(),
            required = true
        }
    })
    
    local paymentMethod = result and result[1]
    if not paymentMethod then
        return
    end
    
    local success, errorMsg = lib.callback.await("lunar_unijob:payRegister", false, registerId, paymentMethod)
    
    if success then
        LR.notify(locale("paid_register"), "success")
    elseif errorMsg then
        LR.notify(errorMsg, "error")
    end
end

-- Set register amount action
local function setRegister(registerId)
    local result = lib.inputDialog(locale("register_header"), {
        {
            type = "number",
            label = locale("register_amount"),
            icon = "dollar-sign",
            min = 1,
            required = true
        }
    })
    
    local amount = result and result[1]
    if not amount then
        return
    end
    
    TriggerServerEvent("lunar_unijob:setRegister", registerId, amount)
    LR.notify(locale("set_register_notify"), "success")
end

-- Clear register action
local function clearRegister(registerId)
    local confirm = lib.alertDialog({
        header = locale("register_header"),
        content = locale("register_clear_content"),
        centered = true,
        cancel = true
    })
    
    if confirm ~= "confirm" then
        return
    end
    
    TriggerServerEvent("lunar_unijob:clearRegister", registerId)
    LR.notify(locale("clear_register_notify"), "success")
end

-- Create a single register point
local function createRegisterPoint(jobData, registerIndex, locationIndex)
    local register = jobData.registers[registerIndex]
    local registerId = string.format("%s_%s_%s", jobData.name, registerIndex, locationIndex)
    
    local point = Utils.createInteractionPoint({
        coords = register.locations[locationIndex],
        radius = register.radius or Config.defaultRadius,
        options = {
            {
                label = locale("pay_register"),
                icon = "cash-register",
                canInteract = function()
                    return registerStates[registerId]
                end,
                onSelect = payRegister,
                args = registerId
            },
            {
                label = locale("set_register"),
                icon = "cash-register",
                canInteract = function()
                    return not registerStates[registerId]
                end,
                onSelect = setRegister,
                args = registerId
            },
            {
                label = locale("clear_register"),
                icon = "cash-register",
                canInteract = function()
                    return registerStates[registerId] and jobData.name == Framework.getJob()
                end,
                onSelect = clearRegister,
                args = registerId
            }
        }
    }, register.target)
    
    table.insert(registerPoints, point)
end

-- Update all register points (recreate from all jobs)
local function update()
    -- Clear existing points
    for _, point in ipairs(registerPoints) do
        point.remove()
    end
    table.wipe(registerPoints)
    
    -- Recreate from all jobs
    local jobs = GetJobs()
    for _, jobData in pairs(jobs) do
        if jobData.registers then
            for registerIndex, register in ipairs(jobData.registers) do
                for locationIndex in ipairs(register.locations) do
                    createRegisterPoint(jobData, registerIndex, locationIndex)
                end
            end
        end
    end
end

-- Export module
Registers = {
    update = update
}
