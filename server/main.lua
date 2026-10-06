if not KOJA.Nitro.Enabled then return end

local MAX_NITRO = 100
local garagesTable = KOJA.Nitro.Tables.GaragesTable
local ownerColumn = KOJA.Nitro.Tables.OwnerColumn

local function trimPlate(plate)
    return type(plate) == 'string' and plate:match('^%s*(.-)%s*$') or nil
end

local function getOwnedVehicleNitro(source, plate)
    local trimmed = trimPlate(plate)
    if not trimmed or trimmed == '' then return nil end

    local identifier = KojaLib.Server.GetPlayerIdentifier(source)
    if not identifier then return nil end

    local row = MySQL.single.await(
        ('SELECT plate, nitro FROM `%s` WHERE `%s` = ? AND (plate = ? OR plate = ?) LIMIT 1'):format(garagesTable, ownerColumn),
        { identifier, plate, trimmed }
    )
    if not row then return nil end
    return row.plate, tonumber(row.nitro) or 0
end

local function updateNitro(plate, value)
    MySQL.update.await(('UPDATE `%s` SET nitro = ? WHERE plate = ?'):format(garagesTable), { value, plate })
end

MySQL.ready(function()
    MySQL.query(('ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS nitro INT DEFAULT 0'):format(garagesTable))
end)

KojaLib.Server.RegisterServerCallback('koja_hud:getVehicleNitro', function(source, plate, cb)
    local storedPlate, nitro = getOwnedVehicleNitro(source, plate)
    if storedPlate then
        cb({ success = true, nitro = nitro })
    else
        cb({ success = false, msg = 'game.nitro.texts.you_are_not_owner' })
    end
end)

KojaLib.Server.RegisterServerCallback('koja_hud:installNitro', function(source, plate, cb)
    local storedPlate, nitro = getOwnedVehicleNitro(source, plate)
    if not storedPlate then
        cb({ success = false, msg = 'game.nitro.texts.you_are_not_owner' })
        return
    end
    if nitro > 0 then
        cb({ success = false, msg = 'game.nitro.texts.vehicle_have_nitro' })
        return
    end

    if KOJA.Nitro.Item then
        if not KojaLib.Server.HasItem(source, KOJA.Nitro.Item, 1) then
            cb({ success = false, msg = 'game.nitro.texts.no_nitro' })
            return
        end
        KojaLib.Server.removeInventoryItem(source, KOJA.Nitro.Item, 1)
    end

    updateNitro(storedPlate, MAX_NITRO)
    cb({ success = true })
end)

RegisterNetEvent('koja_hud:setVehicleNitro', function(plate, value)
    local source = source
    value = tonumber(value)
    if not value then return end

    local storedPlate, nitro = getOwnedVehicleNitro(source, plate)
    if not storedPlate then return end

    local newValue = math.floor(math.max(0, math.min(value, nitro)))
    if newValue ~= nitro then
        updateNitro(storedPlate, newValue)
    end
end)
