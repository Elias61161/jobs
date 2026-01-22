Editable = {}

local function isStarted(resourceName)
    return GetResourceState(resourceName) == 'started'
end

function Editable.openCloakroom()
    if isStarted('fivem-appearance') then
        TriggerEvent('fivem-appearance:clothingShop')
    elseif isStarted('illenium-appearance') then
        TriggerEvent('illenium-appearance:client:openClothingShopMenu', false)
    elseif isStarted('qb-clothing') then
        TriggerEvent('qb-clothing:client:openOutfitMenu')
    else
        error('No script for clothing found! Supported: fivem-appearance/illenium-appearance/qb-clothing')
    end
end

---@param vehicle number
function Editable.onVehicleSpawned(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local plate = GetVehicleNumberPlateText(vehicle):strtrim(' ')

    if isStarted('qs-vehiclekeys') then
        exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
    else
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
    end
end

function Editable.onVehicleSaved(vehicle)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local plate = GetVehicleNumberPlateText(vehicle):strtrim(' ')

    if isStarted('qs-vehiclekeys') then
        exports['qs-vehiclekeys']:RemoveKeys(plate, model)
    else
        TriggerEvent("qb-vehiclekeys:client:RemoveKeys", plate)
    end
end

---@param args { name: string, data: StashData }
function Editable.openStash(args)
    local name, data in args

    if isStarted('ox_inventory') then
        exports.ox_inventory:openInventory('stash', name)
    elseif isStarted('qb-inventory')
        or isStarted('qs-inventory')
        or isStarted('ps-inventory')
        or isStarted('lj-inventory') then
        local name = data.shared and name or (name .. '_' .. Framework.getIdentifier())

        TriggerServerEvent('inventory:server:OpenInventory', 'stash', name, {
            label = data.label,
            maxweight = data.maxWeight,
            slots = data.slots
        })
        TriggerEvent("inventory:client:SetCurrentStash", name)
    else
        warn('Your inventory script doesn\t support stashes. ')
    end
end

---@param data { index: integer, locationIndex: integer, itemIndex: integer }
local function buyItem(data)
    local index, locationIndex, itemIndex in data
    local shop = GetCurrentJob().shops[index]
    local amount = lib.inputDialog(locale('shop_header'), {
        {
            type = 'number',
            label = locale('amount'),
            min = 1,
            required = true
        }
    })?[1]

    if not amount then
        lib.showContext('shop')
        return
    end

    local success, msg = lib.callback.await('lunar_unijob:buyItem', false, index, locationIndex, itemIndex, amount)

    if success then
        if shop.ped then
            LR.progressBar(locale('buying'), 3000, false, {
                dict = 'misscarsteal4@actor',
                clip = 'actor_berating_loop'
            })
        end
        
        LR.notify(locale('bought_item'), 'success')
    elseif msg then
        LR.notify(msg, 'error')
    end
end

---@param job Job
---@param index integer
---@param locationIndex integer
local function openBuiltinShop(job, index, locationIndex)
    local shop = job.shops[index]
    local options = {}

    for itemIndex, item in ipairs(shop.items) do
        if HasGrade(item.grade) then
            table.insert(options, {
                title = Utils.getItemLabel(item.name),
                description = locale('shop_price', item.price),
                icon = item.icon,
                image = item.image or Editable.getInventoryIcon(item.name),
                onSelect = buyItem,
                args = { index = index, locationIndex = locationIndex, itemIndex = itemIndex }
            })
        end
    end

    lib.registerContext({
        id = 'shop',
        title = locale('shop'),
        options = options
    })

    lib.showContext('shop')
end

---@param data { job: Job, index: integer, locationIndex: integer }
function Editable.openShop(data)
    local job, index, locationIndex in data
    local name = ('%s_shop_%s'):format(job.name, index)


    if isStarted('ox_inventory') then
        exports.ox_inventory:openInventory('shop', { type = name, id = locationIndex })
    elseif isStarted('qb-inventory') or isStarted('ps-inventory')
    or isStarted('lj-inventory') or isStarted('qs-inventory') then
        openBuiltinShop(job, index, locationIndex)
    else
        warn('Configure cl_edit.lua shops for your inventory.')
    end
end

---Used for cash registers and buy garages
---@return { label: string, value: string }[]
function Editable.getPaymentMethods()
    local options = {}

    for _, account in ipairs(Config.accounts) do
        table.insert(options, {
            label = locale(account),
            value = account
        })
    end

    return options
end

---Used to check if player is dead
---@param ped number
function Editable.isDead(ped)
    return IsEntityDead(ped)
        or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
end

---You can add override player actions here
---@type table<string, fun(targetId: number, entity: number)>
PlayerActionOverrides = {}

---You can add override vehicle actions here
---@type table<string, fun(entity: number)>
VehicleActionOverrides = {
    -- impound = function(entity)
    --
    -- end
}

---You can add your own canInteract functions for player/vehicle actions here
---@type table<string, fun(entity: number): boolean?>
-- Helper to get cuff state of a target ped
local function isTargetCuffed(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    local playerIndex = NetworkGetPlayerIndexFromPed(entity)
    if playerIndex == 0 then return false end
    local targetServerId = GetPlayerServerId(playerIndex)
    local cuffState = lib.callback.await("lunar_unijob:getPlayerCuffState", false, targetServerId)
    return cuffState ~= nil
end

Editable.canInteractFilter = {
    -- Revive: only dead players
    revive = function(entity)
        return Editable.isDead(entity)
    end,
    -- Heal: only alive players
    heal = function(entity)
        return not Editable.isDead(entity)
    end,
    -- Handcuff: only alive players (can cuff or uncuff)
    handcuff = function(entity)
        if Editable.isDead(entity) then 
            print("^3[DEBUG] Target is dead, denying handcuff^7")
            return false 
        end
        print("^3[DEBUG] Target is alive, allowing handcuff action^7")
        return true
    end,
    -- Ziptie: only alive, non-cuffed players
    ziptie = function(entity)
        if Editable.isDead(entity) then return false end
        return not isTargetCuffed(entity)
    end,
    -- Drag: only cuffed players
    drag = function(entity)
        if Editable.isDead(entity) then return false end
        return isTargetCuffed(entity)
    end,
    -- Carry: only alive players (can carry cuffed or uncuffed)
    carry = function(entity)
        return not Editable.isDead(entity)
    end,
    -- Steal/Search: only cuffed players
    steal = function(entity)
        if Editable.isDead(entity) then 
            print("^3[DEBUG] Target is dead, denying steal^7")
            return false 
        end
        local cuffed = isTargetCuffed(entity)
        print(string.format("^3[DEBUG] Target cuffed: %s^7", tostring(cuffed)))
        return cuffed
    end,
    -- Bill: only alive players
    bill = function(entity)
        return not Editable.isDead(entity)
    end
}

---@param action string
function Editable.actionPerformed(action)
    -- Add your own logic here
end

function Editable.searchPlayer(targetId)
    if not LR.progressBar(locale('searching'), Settings.durations.steal, false, {
        dict = 'missbigscore2aig_7@driver',
        clip = 'boot_r_loop',
        flag = 1
    }) then return end
    
    if isStarted('ox_inventory') then
        exports.ox_inventory:openInventory('player', targetId)
    else
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", targetId)
    end
end

function Editable.giveInvoice(targetId)
    local job = GetCurrentJob()

    if not job then return end

    local amount = lib.inputDialog(locale('invoice_heading'), {
        {
            type = 'number',
            label = locale('invoice_amount'),
            icon = 'dollar-sign',
            min = 1,
            required = true
        }
    })?[1]

    if not amount then return end

    if Framework.name == 'es_extended' then
        TriggerServerEvent('esx_billing:sendBill', targetId, 'society_' .. job.name, job.label, amount)
    else
        -- Adds bill to qb-phone
        -- Available in sv_edit.lua
        TriggerServerEvent('lunar_unijob:giveInvoice', targetId, amount) 
    end

    LR.notify(locale('sent_bill'), 'success')
end

function Editable.revivePlayer(targetId)
    if not LR.progressBar(locale('reviving'), Settings.durations.revive, false, {
        dict = 'mini@cpr@char_a@cpr_str',
        clip = 'cpr_pumpchest',
        flag = 1
    }) then return end

    TriggerServerEvent('lunar_unijob:revivePlayer', targetId)
end

function Editable.healPlayer(targetId)
    if not LR.progressBar(locale('healing'), Settings.durations.heal, false, {
        dict = 'missheistdockssetup1clipboard@idle_a',
        clip = 'idle_a',
        flag = 1
    }) then return end

    TriggerServerEvent('lunar_unijob:healPlayer', targetId)
end

-- No need to secure this event, cheaters can abuse natives anyways
RegisterNetEvent('lunar_unijob:healed', function()
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    LR.notify(locale('healed'), 'success')
end)

-- Fallback revive when no ambulance script is detected
RegisterNetEvent('lunar_unijob:forceRevive', function()
    local ped = cache.ped
    
    -- Respawn if dead
    if IsEntityDead(ped) then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
    end
    
    -- Clear tasks and set health
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    SetPlayerInvincible(cache.playerId, false)
    
    -- Try to stop common death animations
    if IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3) then
        StopAnimTask(ped, 'dead', 'dead_a', 1.0)
    end
    
    LR.notify(locale('revived') or 'You have been revived', 'success')
end)

function Editable.openBossMenu()
    local job = GetCurrentJob()

    if not job then 
        print("^3[DEBUG] Boss menu: No current job^7")
        return 
    end
    
    print(string.format("^3[DEBUG] Opening boss menu for job: %s^7", job.name))
    
    if isStarted('wasabi_multijob') then
        print("^3[DEBUG] Using wasabi_multijob^7")
        exports['wasabi_multijob']:openBossMenu(job.name)
    elseif isStarted('lunar_multijob') then
        print("^3[DEBUG] Using lunar_multijob^7")
        exports['lunar_multijob']:openBossMenu()
    elseif isStarted('qbx_management') then
        print("^3[DEBUG] Using qbx_management^7")
        exports.qbx_management:OpenBossMenu('job')
    elseif isStarted('esx_society') then
        print("^3[DEBUG] Using esx_society^7")
        Framework.object.UI.Menu.CloseAll()
        TriggerEvent('esx_society:openBossMenu', job.name, function(data, menu)
            if menu then
                menu.close()
            end
        end, {
            wash = job.canWash,
            grades = false,
            salary = false
        })
    elseif isStarted('qb-management') then
        print("^3[DEBUG] Using qb-management^7")
        TriggerEvent('qb-bossmenu:client:OpenMenu')
    else
        print("^3[DEBUG] No boss menu resource found!^7")
    end
end

---@return boolean
function Editable.lockpickMinigame()
    if Config.lockpickMinigame == 'normal' then
        return exports['lockpick']:startLockpick()
    elseif Config.lockpickMinigame == 'quasar' then
        local p = promise.new()
        TriggerEvent('lockpick:client:openLockpick', function(success)
            p:resolve(success)
        end)
        return Citizen.Await(p)
    end

    return true
end

---@type string
local path

if isStarted('ox_inventory') then
    path = 'nui://ox_inventory/web/images/%s.png'
elseif isStarted('qb-inventory') then
    path = 'nui://qb-inventory/html/images/%s.png'
elseif isStarted('ps-inventory') then
    path = 'nui://ps-inventory/html/images/%s.png'
elseif isStarted('lj-inventory') then
    path = 'nui://lj-inventory/html/images/%s.png'
elseif isStarted('qs-inventory') then
    path = 'nui://qs-inventory/html/images/%s.png' -- Not really sure
end

---Returns the NUI path of an icon.
---@param itemName string
---@return string?
---@diagnostic disable-next-line: duplicate-set-field
function Editable.getInventoryIcon(itemName)
    if not path then
        warn('Inventory images path not set in cl_edit.lua!')
        return
    end

    return path:format(itemName) .. '?height=128'
end

Binds = {}

Binds.interact = Utils.addKeybind({
    name = 'unijob_interaction',
    description = 'Used for certain interactions such as cancelling animations etc.',
    defaultMapper = 'keyboard',
    defaultKey = 'G'
})

Binds.actionsMenu = Utils.addKeybind({
    name = 'unijob_actions',
    description = 'Opens the job menu.',
    defaultMapper = 'keyboard',
    defaultKey = 'F6',
})

lib.callback.register('lunar_unijob:skillCheck', function()
    return lib.skillCheck({ 'easy', 'easy', 'medium', 'medium', 'hard' }, { 'e' })
end)

---@param item UsableItem
function Editable.updateStatus(item)
    if item.hunger then Editable.addHunger(item.hunger) end
    if item.thirst then Editable.addThirst(item.thirst) end
end

function Editable.addHunger(amount)
    if Framework.name == 'es_extended' then
        TriggerEvent('esx_status:add', 'hunger', amount)
    else
        local value = Framework.object.Functions.GetPlayerData().metadata.hunger + amount
        TriggerServerEvent('consumables:server:addHunger', value)
    end
end

function Editable.addThirst(amount)
    if Framework.name == 'es_extended' then
        TriggerEvent('esx_status:add', 'thirst', amount)
    else
        local value = Framework.object.Functions.GetPlayerData().metadata.thirst + amount
        TriggerServerEvent('consumables:server:addThirst', value)
    end
end

function Editable.handcuffControls()
    DisableControlAction(0, 24, true) --Attack
    DisableControlAction(0, 49, true) --Go inside vehicles
    DisableControlAction(0, 257, true) --Attack 2
    DisableControlAction(0, 25, true) --Aim
    DisableControlAction(0, 263, true) --Melee Attack 1
    DisableControlAction(0, 45, true) --Reload
    DisableControlAction(0, 44, true) --Cover
    DisableControlAction(0, 37, true) --Select Weapon
    DisableControlAction(0, 23, true) --Also 'enter' ?
    DisableControlAction(0, 288, true) --Disable phone
    DisableControlAction(0, 289, true) --Inventory
    DisableControlAction(0, 170, true) --Animations
    DisableControlAction(0, 167, true) --Job
    DisableControlAction(0, 0, true) --Disable changing view
    DisableControlAction(0, 26, true) --Disable looking behind
    DisableControlAction(0, 73, true) --Disable clearing animation
    DisableControlAction(2, 199, true) --Disable pause screen
    DisableControlAction(0, 59, true) --Disable steering in vehicle
    DisableControlAction(0, 71, true) --Disable driving forward in vehicle
    DisableControlAction(0, 72, true) --Disable reversing in vehicle
    DisableControlAction(2, 36, true) --Disable going stealth
    DisableControlAction(0, 47, true) --Disable weapon
    DisableControlAction(0, 264, true) --Disable melee
    DisableControlAction(0, 257, true) --Disable melee
    DisableControlAction(0, 140, true) --Disable melee
    DisableControlAction(0, 141, true) --Disable melee
    DisableControlAction(0, 142, true) --Disable melee
    DisableControlAction(0, 143, true) --Disable melee
    DisableControlAction(0, 75, true) --Disable exit vehicle
    DisableControlAction(27, 75, true) --Disable exit vehicle
end