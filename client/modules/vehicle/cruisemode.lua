KOJA.CruiseActive = false

if not KOJA.CruiseMode.Enabled then return end

local BRAKE_CONTROL = 72
local cruiseId = 0

local function notifyCruise(text)
    KOJA.Client.SendNotifyHud({
        title = 'game.cruisemode.notify.title',
        desc = 'game.cruisemode.texts.' .. text,
    })
end

local function stopCruise(reason)
    KOJA.CruiseActive = false
    if reason then notifyCruise(reason) end
end

local function startCruise(vehicle, ped)
    local cruiseSpeed = GetEntitySpeed(vehicle)
    cruiseId = cruiseId + 1
    local id = cruiseId
    KOJA.CruiseActive = true
    notifyCruise('cruisemode_on')

    CreateThread(function()
        while KOJA.CruiseActive and id == cruiseId do
            if GetVehiclePedIsIn(ped, false) ~= vehicle or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                stopCruise('cruisemode_off')
                break
            end

            if not IsVehicleOnAllWheels(vehicle) then
                stopCruise('cruisemode_off_airborne')
                break
            end

            if IsControlJustPressed(0, BRAKE_CONTROL) then
                stopCruise('cruisemode_off_braking')
                break
            end

            if GetEntitySpeed(vehicle) < cruiseSpeed then
                SetVehicleForwardSpeed(vehicle, cruiseSpeed)
            end
            Wait(0)
        end
    end)
end

KOJA.Client.ToggleCruiseControl = function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return
    end

    if KOJA.CruiseActive then
        stopCruise('cruisemode_off')
        return
    end

    if GetEntitySpeed(vehicle) * 3.6 < (KOJA.CruiseMode.MinSpeed or 20.0) then
        notifyCruise('cruisemode_too_slow')
        return
    end

    startCruise(vehicle, ped)
end

KojaLib.registerKeyBind({
    name = "toggle_cruisemode",
    description = KOJA.CruiseMode.Desc,
    key = KOJA.CruiseMode.Key,
    onPress = KOJA.Client.ToggleCruiseControl
})
