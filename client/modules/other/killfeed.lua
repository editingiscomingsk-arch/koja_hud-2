KOJA.Client.Killfeed = {
    enabled = KOJA.Killfeed.Enabled,
    anyDistance = KOJA.Killfeed.AnyDistance,
    distance = KOJA.Killfeed.Distance,
}

local HEAD_BONE = 31086

RegisterNUICallback("koja_hud:updateKillfeed", function(data, cb)
    if type(data) == 'table' then
        if data.enabled ~= nil then KOJA.Client.Killfeed.enabled = data.enabled == true end
        if data.anyDistance ~= nil then KOJA.Client.Killfeed.anyDistance = data.anyDistance == true end
        if tonumber(data.distance) then KOJA.Client.Killfeed.distance = tonumber(data.distance) end
    end
    cb({})
end)

local function weaponIcon(hash)
    if not hash or hash == GetHashKey('WEAPON_UNARMED') then return 'fa-solid fa-hand-fist' end
    local group = GetWeapontypeGroup(hash)
    if group == GetHashKey('GROUP_MELEE') then return 'fa-solid fa-hand-fist' end
    if group == GetHashKey('GROUP_THROWN') then return 'fa-solid fa-bomb' end
    if group == GetHashKey('GROUP_HEAVY') then return 'fa-solid fa-explosion' end
    return 'fa-solid fa-gun'
end

local function pushKill(killer, victim, weapon, distance, opts)
    if not killer or not victim then return end
    local settings = KOJA.Client.Killfeed
    if not settings.anyDistance and distance and distance > (settings.distance or 100) then
        return
    end
    KOJA.Client.SendReactMessage('koja_hud:killfeed', {
        killer = tostring(killer),
        victim = tostring(victim),
        weapon = weapon or 'fa-solid fa-skull',
        distance = distance and math.floor(distance + 0.5) or -1,
        headshot = opts and opts.headshot == true or false,
        self = opts and opts.self == true or false,
    })
end

exports('AddKillfeed', pushKill)

RegisterNetEvent('koja_hud:killfeed', function(data)
    if type(data) ~= 'table' then return end
    pushKill(data.killer, data.victim, data.weapon, tonumber(data.distance), {
        headshot = data.headshot,
        self = data.self
    })
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local victim, attacker, isFatal = args[1], args[2], args[6]
    if isFatal ~= 1 or not victim or not attacker then return end

    local ped = PlayerPedId()
    if victim == ped then
        KOJA.Client.SendReactMessage('koja_hud:killstreakReset', {})
        return
    end

    if attacker ~= ped or not DoesEntityExist(victim) then return end

    local victimName = 'NPC'
    if IsPedAPlayer(victim) then
        local victimIndex = NetworkGetPlayerIndexFromPed(victim)
        if victimIndex ~= -1 then victimName = GetPlayerName(victimIndex) end
    end

    local distance = #(GetEntityCoords(ped) - GetEntityCoords(victim))
    pushKill(GetPlayerName(PlayerId()) or 'You', victimName, weaponIcon(GetPedCauseOfDeath(victim)), distance, {
        headshot = GetPedLastDamageBone(victim) == HEAD_BONE,
        self = true
    })
end)
