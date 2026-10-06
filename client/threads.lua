local refresh = KOJA.Refresh or {}

KOJA.Client.StartThread = function(session)
    CreateThread(function()
        local isTalking = false
        while KOJA.Client.IsSessionActive(session) do
            local playerId = PlayerId()
            local talking = NetworkIsPlayerTalking(playerId)
            if talking ~= isTalking then
                isTalking = talking
                KOJA.Client.SendReactMessage('koja_hud:setTalking', talking)
            end

            KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
                status = {
                    { id = "stamina", status = math.floor(GetPlayerStamina(playerId)) },
                    { id = "oxygen", status = GetPlayerUnderwaterTimeRemaining(playerId) * 10 },
                }
            })

            if KOJA.Client.StatusTick then
                KOJA.Client.StatusTick()
            end

            Wait(refresh.Hud or 1500)
        end
    end)
end

KOJA.Client.StartPauseMenuThread = function(session)
    if KOJA.HideHudOnPauseMenu == false then return end
    CreateThread(function()
        local hidden = false
        while KOJA.Client.IsSessionActive(session) do
            local paused = IsPauseMenuActive()
            if paused ~= hidden then
                hidden = paused
                KOJA.Client.SendReactMessage('koja_hud:pauseHud', paused)
            end
            Wait(refresh.PauseMenu or 200)
        end
    end)
end

KOJA.Client.StartCompassThread = function(session)
    if KOJA.Compass and KOJA.Compass.Enabled == false then return end
    CreateThread(function()
        local lastBearing = -1
        while KOJA.Client.IsSessionActive(session) do
            local camHeading = GetGameplayCamRot(2).z
            local bearing = math.floor((360.0 - (camHeading % 360.0)) % 360.0)
            if bearing ~= lastBearing then
                lastBearing = bearing
                KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
                    compass = { heading = bearing }
                })
            end
            Wait(refresh.Compass or 90)
        end
    end)
end

KOJA.Client.StartWeaponThread = function(session)
    CreateThread(function()
        local last = { hash = 0, clip = -1, reserve = -1, armed = nil }
        while KOJA.Client.IsSessionActive(session) do
            local ped = PlayerPedId()
            if IsPedArmed(ped, 7) then
                local weaponHash = GetSelectedPedWeapon(ped)
                local _, clip = GetAmmoInClip(ped, weaponHash)
                local total = GetAmmoInPedWeapon(ped, weaponHash)
                local reserve = math.max((total or 0) - (clip or 0), 0)
                if weaponHash ~= last.hash or clip ~= last.clip or reserve ~= last.reserve or last.armed ~= true then
                    last = { hash = weaponHash, clip = clip, reserve = reserve, armed = true }
                    KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
                        weapon = {
                            active = true,
                            name = WeaponNames[weaponHash] or 'Weapon',
                            ammo = clip or 0,
                            total = reserve
                        }
                    })
                end
            elseif last.armed ~= false then
                last = { hash = 0, clip = -1, reserve = -1, armed = false }
                KOJA.Client.SendReactMessage('koja_hud:refreshHud', { weapon = { active = false } })
            end
            Wait(refresh.Weapon or 250)
        end
    end)
end

local function getGearLabel(vehicle)
    if GetEntitySpeedVector(vehicle, true).y < -0.1 then return "R" end
    local gear = GetVehicleCurrentGear(vehicle)
    return gear == 0 and "N" or gear
end

KOJA.Client.StartVehicleThread = function(session)
    CreateThread(function()
        local carHudVisible = false
        while KOJA.Client.IsSessionActive(session) do
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

            if vehicle ~= 0 and DoesEntityExist(vehicle) and not KojaLib.Client.IsDead() then
                local _, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
                local engineHealth = math.max(0, math.min(100, GetVehicleEngineHealth(vehicle) / 10))
                local engineOn = KojaLib.Client.isVehicleEngineOn(vehicle)

                KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
                    car = {
                        speed = math.floor(GetEntitySpeed(vehicle)),
                        gear = getGearLabel(vehicle),
                        engine = engineOn,
                        keys = KojaLib.Client.isVehicleLocked(vehicle),
                        fuel = {
                            type = ElectricModels[GetEntityModel(vehicle)] and "electric" or "gas",
                            min = KojaLib.Client.GetFuel(vehicle),
                            max = 100
                        },
                        nitro = KOJA.Client.GetNitro(),
                        seatbelt = KOJA.Client.IsSeatbeltOn(),
                        rpm = GetVehicleCurrentRpm(vehicle),
                        engineHealth = math.floor(engineHealth),
                        lights = lightsOn == 1,
                        highbeam = highbeamsOn == 1,
                        indicators = GetVehicleIndicatorLights(vehicle),
                        cruise = KOJA.CruiseActive == true
                    }
                })

                if not carHudVisible then
                    carHudVisible = true
                    KOJA.Client.SendReactMessage('koja_hud:showCarHud', true)
                end
                Wait(refresh.Vehicle or 150)
            else
                if carHudVisible then
                    carHudVisible = false
                    KOJA.Client.SendReactMessage('koja_hud:showCarHud', false)
                end
                Wait(500)
            end
        end

        if carHudVisible then
            KOJA.Client.SendReactMessage('koja_hud:showCarHud', false)
        end
    end)
end

KOJA.Client.HideNativeHUDComponents = function(session)
    CreateThread(function()
        while KOJA.Client.IsSessionActive(session) do
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            Wait(0)
        end
    end)
end

CreateThread(function()
    local lastShown = nil
    while true do
        local mode = KOJA.MinimapVisibility or 'always'
        local inVehicle = IsPedInAnyVehicle(PlayerPedId(), false)
        local show = mode == 'always'
            or (mode == 'vehicle' and inVehicle)
            or (mode == 'foot' and not inVehicle)

        if show and KOJA.NeedItemForMinimap and KojaLib.Client.GetItemCount(KOJA.MinimapItem) <= 0 then
            show = false
        end

        if show ~= lastShown then
            lastShown = show
            DisplayRadar(show)
            KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
                misc = { minimap = show and 'on' or 'off' }
            })
        end
        Wait(300)
    end
end)

RegisterNUICallback("koja_hud:updateMinimapVisibility", function(data, cb)
    if type(data) == 'table' and type(data.mode) == 'string' then
        KOJA.MinimapVisibility = data.mode
    end
    cb({})
end)
