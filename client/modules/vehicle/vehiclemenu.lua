if not KOJA.VehicleMenu or KOJA.VehicleMenu.Enabled == false then return end

local menuOpen = false
local indicator = { left = false, right = false, hazard = false }
local indicatorThreadRunning = false
local doorState = {}
local doorIndices = { 0, 1, 2, 3, 4, 5 }

local function getOwnedVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and DoesEntityExist(veh) and GetPedInVehicleSeat(veh, -1) == ped then
        return veh
    end
    return nil
end

local function isDoorOpen(veh, idx)
    return GetVehicleDoorAngleRatio(veh, idx) > 0.01
end

local function initDoorState(veh)
    doorState = {}
    for _, i in ipairs(doorIndices) do
        doorState[i] = isDoorOpen(veh, i)
    end
end

local function areLightsOn(veh)
    local _, lightsOn = GetVehicleLightsState(veh)
    return lightsOn == 1 or lightsOn == true
end

local function gatherState(veh)
    return {
        engine = GetIsVehicleEngineRunning(veh),
        seatbelt = KOJA.Client.IsSeatbeltOn(),
        lights = areLightsOn(veh),
        indicatorLeft = indicator.left,
        indicatorRight = indicator.right,
        hazard = indicator.hazard,
        doors = {
            frontLeft = doorState[0] or false,
            frontRight = doorState[1] or false,
            rearLeft = doorState[2] or false,
            rearRight = doorState[3] or false,
            hood = doorState[4] or false,
            trunk = doorState[5] or false,
        }
    }
end

local function applyIndicators(veh)
    if indicator.hazard then
        SetVehicleIndicatorLights(veh, 0, true)
        SetVehicleIndicatorLights(veh, 1, true)
    else
        SetVehicleIndicatorLights(veh, 1, indicator.left)
        SetVehicleIndicatorLights(veh, 0, indicator.right)
    end
end

local function ensureIndicatorThread()
    if indicatorThreadRunning then return end
    indicatorThreadRunning = true
    CreateThread(function()
        while indicator.left or indicator.right or indicator.hazard do
            local veh = getOwnedVehicle()
            if veh then applyIndicators(veh) end
            Wait(250)
        end
        local veh = getOwnedVehicle()
        if veh then
            SetVehicleIndicatorLights(veh, 0, false)
            SetVehicleIndicatorLights(veh, 1, false)
        end
        indicatorThreadRunning = false
    end)
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    KOJA.Client.SendReactMessage('koja_hud:closeVehicleMenu', true)
end

local function toggleMenu()
    if menuOpen then
        closeMenu()
        return
    end
    local veh = getOwnedVehicle()
    if not veh then return end
    initDoorState(veh)
    menuOpen = true
    SetNuiFocus(true, true)
    KOJA.Client.SendReactMessage('koja_hud:openVehicleMenu', gatherState(veh))
end

RegisterCommand('koja_vehiclemenu', toggleMenu, false)

RegisterKeyMapping('koja_vehiclemenu', KOJA.VehicleMenu.Desc or 'Open vehicle control menu', 'keyboard', KOJA.VehicleMenu.Key or 'U')

if KOJA.VehicleMenu.Command then
    RegisterCommand(KOJA.VehicleMenu.Command, toggleMenu, false)
    TriggerEvent('chat:addSuggestion', '/' .. KOJA.VehicleMenu.Command, 'Open the vehicle control menu (while driving)')
end

RegisterNUICallback('koja_hud:closeVehicleMenu', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('koja_hud:vehicleAction', function(data, cb)
    local veh = getOwnedVehicle()
    if not veh then
        cb({})
        return
    end
    local action = data and data.action

    if action == 'engine' then
        KOJA.Client.ToggleVehicleEngine(veh)
    elseif action == 'seatbelt' then
        KOJA.Client.ToggleSeatbelt()
    elseif action == 'lights' then
        SetVehicleLights(veh, areLightsOn(veh) and 1 or 2)
    elseif action == 'indicatorLeft' then
        indicator.left = not indicator.left
        if indicator.left then indicator.right = false; indicator.hazard = false end
        applyIndicators(veh)
        ensureIndicatorThread()
    elseif action == 'indicatorRight' then
        indicator.right = not indicator.right
        if indicator.right then indicator.left = false; indicator.hazard = false end
        applyIndicators(veh)
        ensureIndicatorThread()
    elseif action == 'hazard' then
        indicator.hazard = not indicator.hazard
        if indicator.hazard then indicator.left = false; indicator.right = false end
        applyIndicators(veh)
        ensureIndicatorThread()
    elseif action == 'door' then
        local idx = tonumber(data.index)
        if idx then
            local open = not (doorState[idx] or false)
            doorState[idx] = open
            if open then
                SetVehicleDoorOpen(veh, idx, false, false)
            else
                SetVehicleDoorShut(veh, idx, false)
            end
        end
    end

    cb(gatherState(veh))
end)

CreateThread(function()
    while true do
        if menuOpen and not getOwnedVehicle() then
            closeMenu()
        end
        Wait(500)
    end
end)
