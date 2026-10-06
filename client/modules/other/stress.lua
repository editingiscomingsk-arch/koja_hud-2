local MIN_STRESS, MAX_STRESS = 0, 100
local stress = MIN_STRESS

RegisterNetEvent("koja-hud:addStress", function(value)
    stress = math.min(stress + (tonumber(value) or 0), MAX_STRESS)
end)

RegisterNetEvent("koja-hud:removeStress", function(value)
    stress = math.max(stress - (tonumber(value) or 0), MIN_STRESS)
end)

KOJA.Client.GetPlayerStress = function()
    return stress
end

exports('GetStress', KOJA.Client.GetPlayerStress)
