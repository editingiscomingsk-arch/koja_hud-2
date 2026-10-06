KOJA.Client = {}
KOJA.Client.PlayerLoaded = false

KOJA.Client.GetHealthPercent = function(ped)
    if KojaLib.Client.IsDead() then
        return 0.0
    end
    return KojaLib.Client.percent(GetEntityHealth(ped) - 100, GetEntityMaxHealth(ped) - 100)
end

KOJA.Client.RefreshStatus = function(food, water)
    local ped = PlayerPedId()
    local health = KOJA.Client.GetHealthPercent(ped)
    local armour = KojaLib.Client.percent(GetPedArmour(ped), 100)

    KojaLib.Client.TriggerServerCallback("koja-lib:GetMoney", nil, function(result)
        KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
            status = {
                { id = "health", status = health },
                { id = "shield", status = armour },
                { id = "food", status = KojaLib.Client.percent(food or 0, 100) },
                { id = "water", status = KojaLib.Client.percent(water or 0, 100) },
                { id = "stress", status = KojaLib.Client.percent(KOJA.Client.GetPlayerStress(), 100) }
            },
            informations = {
                cash = result and result.money or 0,
                bank = result and result.bank or 0,
                job = KojaLib.Client.GetPlayerJobLabel(),
                id = GetPlayerServerId(PlayerId())
            }
        })
    end)
end

KOJA.Client.IsPlayerLoaded = function()
    local data = KojaLib.Client.GetPlayerData()
    if KojaLib.Framework == "esx" then
        return type(data) == 'table' and data.job ~= nil
    elseif KojaLib.Framework == "qb" then
        return type(data) == 'table' and data.citizenid ~= nil
    end
    return true
end

KOJA.Client.OnPlayerLoaded = function()
    Wait(500)
    KOJA.Client.PlayerLoaded = true
    KOJA.Client.Start()
end

if KojaLib.Framework == "esx" then
    RegisterNetEvent("esx:playerLoaded", KOJA.Client.OnPlayerLoaded)

    RegisterNetEvent("esx:onPlayerLogout", function()
        KOJA.Client.PlayerLoaded = false
    end)

    KOJA.Client.StatusTick = function()
        local hunger, thirst = 0, 0
        TriggerEvent('esx_status:getStatus', 'hunger', function(status)
            hunger = status.getPercent()
        end)
        TriggerEvent('esx_status:getStatus', 'thirst', function(status)
            thirst = status.getPercent()
        end)
        KOJA.Client.RefreshStatus(hunger, thirst)
    end
elseif KojaLib.Framework == "qb" then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', KOJA.Client.OnPlayerLoaded)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        KOJA.Client.PlayerLoaded = false
    end)

    KOJA.Client.StatusTick = function()
        local metadata = KojaLib.Client.GetPlayerData().metadata or {}
        KOJA.Client.RefreshStatus(metadata.hunger, metadata.thirst)
    end
elseif KojaLib.Framework == "ox" then
    RegisterNetEvent("ox:playerLoaded", KOJA.Client.OnPlayerLoaded)

    AddEventHandler('ox:statusTick', function(data)
        data = data or {}
        KOJA.Client.RefreshStatus(data.food or data.hunger, data.water or data.thirst)
    end)
end
