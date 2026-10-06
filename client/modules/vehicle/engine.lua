KOJA.Client.ToggleVehicleEngine = function(vehicle)
    vehicle = vehicle or GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local enabled = not GetIsVehicleEngineRunning(vehicle)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, enabled, true, true)
    return enabled
end

if not KOJA.Engine.Enabled then return end

local ACCELERATE_CONTROL, BRAKE_CONTROL = 71, 72
local engineBlocked = false
local blockedVehicle = nil
local blockRunning = false

local function startEngineBlock(vehicle)
    engineBlocked = true
    blockedVehicle = vehicle
    if blockRunning then return end
    blockRunning = true

    CreateThread(function()
        while engineBlocked and blockedVehicle and DoesEntityExist(blockedVehicle) do
            DisableControlAction(0, ACCELERATE_CONTROL, true)
            DisableControlAction(0, BRAKE_CONTROL, true)
            Wait(0)
        end
        blockRunning = false
    end)
end

local function stopEngineBlock()
    engineBlocked = false
    blockedVehicle = nil
end

local function isDriver(vehicle, ped)
    return vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped
end

KOJA.Client.ToggleVehicleEngine = function(vehicle)
    local ped = PlayerPedId()
    vehicle = vehicle or GetVehiclePedIsIn(ped, false)
    if not isDriver(vehicle, ped) then return end

    local enabled = not GetIsVehicleEngineRunning(vehicle)
    if enabled then
        stopEngineBlock()
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineOn(vehicle, true, true, true)
    else
        SetVehicleEngineOn(vehicle, false, true, true)
        SetVehicleUndriveable(vehicle, true)
        startEngineBlock(vehicle)
    end

    KOJA.Client.SendNotifyHud({
        title = 'game.engine.notify.title',
        desc = enabled and 'game.engine.texts.engine_on' or 'game.engine.texts.engine_off',
    })
    return enabled
end

KojaLib.registerKeyBind({
    name = "toggle_engine",
    description = KOJA.Engine.Desc,
    key = KOJA.Engine.Key,
    onPress = function()
        KOJA.Client.ToggleVehicleEngine()
    end
})

AddEventHandler("koja-lib:callback_triggered", function(key, value)
    if key ~= "vehicle" then return end

    if not value or value <= 0 then
        stopEngineBlock()
        return
    end

    local ped = PlayerPedId()
    if not isDriver(value, ped) or GetIsVehicleEngineRunning(value) then return end

    if KOJA.Engine.StartEngineOnEntering then
        SetVehicleUndriveable(value, false)
        SetVehicleEngineOn(value, true, true, true)
    else
        startEngineBlock(value)
    end
end)
