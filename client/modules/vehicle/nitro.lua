local vehicleNitro = 0

KOJA.Client.GetNitro = function()
    return vehicleNitro
end

KOJA.Client.SetNitro = function() end

if not KOJA.Nitro.Enabled then return end

local EXHAUST_BONES = {
    "exhaust", "exhaust_2", "exhaust_3", "exhaust_4", "exhaust_5", "exhaust_6", "exhaust_7", "exhaust_8",
    "exhaust_9", "exhaust_10", "exhaust_11", "exhaust_12", "exhaust_13", "exhaust_14", "exhaust_15", "exhaust_16"
}
local INSTALL_TIME = 5000

local currentVehicle = nil
local savedNitro = 0
local boosting = false
local lightTrails = {}

local function notifyNitro(text)
    KOJA.Client.SendNotifyHud({
        title = 'game.nitro.notify.title',
        desc = text:find('%.') and text or 'game.nitro.texts.' .. text,
    })
end

local function saveNitro(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) or vehicleNitro == savedNitro then return end
    savedNitro = vehicleNitro
    TriggerServerEvent("koja_hud:setVehicleNitro", GetVehicleNumberPlateText(vehicle), vehicleNitro)
end

local function createExhaustBackfire(vehicle, scale)
    for _, boneName in ipairs(EXHAUST_BONES) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
        if boneIndex ~= -1 then
            local position = GetWorldPositionOfEntityBone(vehicle, boneIndex)
            local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, position.x, position.y, position.z)
            UseParticleFxAssetNextCall('core')
            StartNetworkedParticleFxNonLoopedOnEntity('veh_backfire', vehicle, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, scale, false, false, false)
        end
    end
end

local function startLightTrail(vehicle, bone)
    UseParticleFxAssetNextCall('core')
    local particle = StartNetworkedParticleFxLoopedOnEntityBone('veh_light_red_trail', vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        GetEntityBoneIndexByName(vehicle, bone), 1.0, false, false, false)
    SetParticleFxLoopedEvolution(particle, "speed", 1.0, false)
    return particle
end

local function fadeOutLightTrail(particle, duration)
    CreateThread(function()
        local endTime = GetGameTimer() + duration
        while GetGameTimer() < endTime do
            local scale = (endTime - GetGameTimer()) / duration
            SetParticleFxLoopedScale(particle, scale)
            SetParticleFxLoopedAlpha(particle, scale)
            Wait(0)
        end
        StopParticleFxLooped(particle, false)
    end)
end

local function setBoostEffects(vehicle, enabled)
    if DoesEntityExist(vehicle) then
        SetVehicleBoostActive(vehicle, enabled)
        SetVehicleEnginePowerMultiplier(vehicle, enabled and KOJA.Nitro.NitroForce or 1.0)
    end

    if enabled then
        StartScreenEffect('RaceTurbo', 0, false)
        SetTimecycleModifier('rply_motionblur')
        ShakeGameplayCam('SKY_DIVING_SHAKE', 0.30)
        lightTrails = { startLightTrail(vehicle, "taillight_l"), startLightTrail(vehicle, "taillight_r") }
    else
        StopScreenEffect('RaceTurbo')
        StopGameplayCamShaking(true)
        SetTransitionTimecycleModifier('default', 0.35)
        for _, particle in ipairs(lightTrails) do
            fadeOutLightTrail(particle, 500)
        end
        lightTrails = {}
    end
end

local function isDriverOf(vehicle)
    local ped = PlayerPedId()
    return vehicle and DoesEntityExist(vehicle) and GetVehiclePedIsIn(ped, false) == vehicle and GetPedInVehicleSeat(vehicle, -1) == ped
end

local function startBoost()
    local vehicle = currentVehicle
    boosting = true
    setBoostEffects(vehicle, true)

    CreateThread(function()
        while boosting and vehicleNitro > 0 and isDriverOf(vehicle) do
            createExhaustBackfire(vehicle, 1.25)
            vehicleNitro = math.max(0, vehicleNitro - KOJA.Nitro.RemoveNitroOnMilliseconds)
            Wait(100)
        end

        boosting = false
        setBoostEffects(vehicle, false)

        if vehicleNitro <= 0 then
            notifyNitro('run_out_of_nitro')
        end
        saveNitro(vehicle)
    end)
end

KojaLib.registerKeyBind({
    name = "toggle_nitro",
    description = KOJA.Nitro.Desc,
    key = KOJA.Nitro.Key,
    onPress = function()
        if not isDriverOf(currentVehicle) then return end

        if boosting then
            boosting = false
        elseif vehicleNitro > 0 then
            startBoost()
        else
            notifyNitro('no_nitro')
        end
    end
})

AddEventHandler("koja-lib:callback_triggered", function(key, value, oldValue)
    if key ~= "vehicle" then return end

    if oldValue and oldValue > 0 then
        boosting = false
        saveNitro(oldValue)
    end

    currentVehicle = nil
    vehicleNitro = 0
    savedNitro = 0

    if not value or value <= 0 or GetPedInVehicleSeat(value, -1) ~= PlayerPedId() then return end

    currentVehicle = value
    KojaLib.Client.TriggerServerCallback("koja_hud:getVehicleNitro", GetVehicleNumberPlateText(value), function(result)
        if currentVehicle == value and result and result.success then
            vehicleNitro = tonumber(result.nitro) or 0
            savedNitro = vehicleNitro
        end
    end)
end)

local function getVehicleInFront(ped)
    local from = GetEntityCoords(ped)
    local to = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 10, ped, 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    if hit == 1 and GetEntityType(entity) == 2 and DoesEntityExist(entity) then
        return entity
    end
end

KOJA.Client.SetNitro = function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then
        notifyNitro('cant_install_in_car')
        return
    end

    local vehicle = getVehicleInFront(ped)
    if not vehicle or not IsPedOnFoot(ped) then
        notifyNitro('no_car')
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    KojaLib.Client.TriggerServerCallback("koja_hud:getVehicleNitro", plate, function(result)
        if not result or not result.success then
            notifyNitro(result and result.msg or 'you_are_not_owner')
            return
        end
        if (tonumber(result.nitro) or 0) > 0 then
            notifyNitro('vehicle_have_nitro')
            return
        end

        TaskStartScenarioInPlace(ped, 'PROP_HUMAN_BUM_BIN', 0, true)
        Wait(INSTALL_TIME)
        ClearPedTasks(ped)

        KojaLib.Client.TriggerServerCallback("koja_hud:installNitro", plate, function(installed)
            notifyNitro(installed and installed.success and 'filled_up_nitro' or (installed and installed.msg or 'no_nitro'))
        end)
    end)
end
