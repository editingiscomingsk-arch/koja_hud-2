local seatbeltOn = false

KOJA.Client.IsSeatbeltOn = function()
    return seatbeltOn
end

KOJA.Client.ToggleSeatbelt = function()
    return seatbeltOn
end

if not KOJA.Seatbelt.Enabled then return end

local EXIT_VEHICLE_CONTROL = 75
local monitorRunning = false

exports("SeatbeltState", function(state)
    seatbeltOn = state == true
end)

KOJA.Client.ToggleSeatbelt = function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return seatbeltOn
    end

    seatbeltOn = not seatbeltOn
    SetPedRagdollOnCollision(ped, not seatbeltOn)
    KOJA.Client.SendNotifyHud({
        title = 'game.seatbelt.notify.title',
        desc = seatbeltOn and 'game.seatbelt.texts.seatbelt_on' or 'game.seatbelt.texts.seatbelt_off',
    })
    return seatbeltOn
end

local function monitorSeatbelt()
    if monitorRunning then return end
    monitorRunning = true

    CreateThread(function()
        local lastSpeed = 0.0
        local lastVelocity = vector3(0, 0, 0)
        local ragdollSpeed = KOJA.Seatbelt.MaxVehicleSpeedToRagdoll / 3.6

        while true do
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle == 0 then break end

            local speed = GetEntitySpeed(vehicle)
            if not seatbeltOn and lastSpeed > ragdollSpeed and (lastSpeed - speed) > (lastSpeed * 0.2) then
                local coords = GetEntityCoords(ped)
                local forward = GetEntityForwardVector(ped)
                SetEntityCoords(ped, coords.x + forward.x, coords.y + forward.y, coords.z - 0.47, true, true, true, false)
                SetEntityVelocity(ped, lastVelocity.x, lastVelocity.y, lastVelocity.z)
                SetPedToRagdoll(ped, 1000, 1000, 0, false, false, false)
                break
            end

            lastSpeed = speed
            lastVelocity = GetEntityVelocity(vehicle)

            if seatbeltOn then
                for _ = 1, 10 do
                    DisableControlAction(0, EXIT_VEHICLE_CONTROL, true)
                    DisableControlAction(27, EXIT_VEHICLE_CONTROL, true)
                    Wait(0)
                end
            else
                Wait(100)
            end
        end

        seatbeltOn = false
        monitorRunning = false
    end)
end

KojaLib.registerKeyBind({
    name = "toggle_seatbelt",
    description = KOJA.Seatbelt.Desc,
    key = KOJA.Seatbelt.Key,
    onPress = KOJA.Client.ToggleSeatbelt
})

AddEventHandler("koja-lib:callback_triggered", function(key, value)
    if key ~= "vehicle" then return end
    if value and value > 0 then
        SetPedRagdollOnCollision(PlayerPedId(), true)
        monitorSeatbelt()
    else
        seatbeltOn = false
    end
end)
