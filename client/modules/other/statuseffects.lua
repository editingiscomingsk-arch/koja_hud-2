KOJA.Client.StatusEffects = {
    Custom = {},
    Builtin = {},
}

local BUILTIN_EFFECTS = {
    { id = 'sprint', icon = 'fa-solid fa-person-running', color = '#8dd82b', check = IsPedSprinting },
    { id = 'swim', icon = 'fa-solid fa-person-swimming', color = '#6ab7ff', check = IsPedSwimming },
}

local function syncEffects()
    local list = {}
    for _, effect in pairs(KOJA.Client.StatusEffects.Builtin) do list[#list + 1] = effect end
    for _, effect in pairs(KOJA.Client.StatusEffects.Custom) do list[#list + 1] = effect end
    KOJA.Client.SendReactMessage('koja_hud:statuseffects', list)
end

local function setEffects(list)
    KOJA.Client.StatusEffects.Custom = {}
    if type(list) == 'table' then
        for _, effect in ipairs(list) do
            if type(effect) == 'table' and effect.id then
                KOJA.Client.StatusEffects.Custom[effect.id] = effect
            end
        end
    end
    syncEffects()
end

exports('SetStatusEffects', setEffects)

exports('AddStatusEffect', function(effect)
    if type(effect) == 'table' and effect.id then
        KOJA.Client.StatusEffects.Custom[effect.id] = effect
        syncEffects()
    end
end)

exports('RemoveStatusEffect', function(id)
    if id and KOJA.Client.StatusEffects.Custom[id] then
        KOJA.Client.StatusEffects.Custom[id] = nil
        syncEffects()
    end
end)

RegisterNetEvent('koja_hud:setStatusEffects', setEffects)

if KOJA.StatusEffects.Builtin then
    CreateThread(function()
        local builtin = KOJA.Client.StatusEffects.Builtin
        while true do
            local ped = PlayerPedId()
            local changed = false

            for _, effect in ipairs(BUILTIN_EFFECTS) do
                local active = effect.check(ped)
                if active and not builtin[effect.id] then
                    builtin[effect.id] = { id = effect.id, icon = effect.icon, color = effect.color }
                    changed = true
                elseif not active and builtin[effect.id] then
                    builtin[effect.id] = nil
                    changed = true
                end
            end

            if changed then syncEffects() end
            Wait(500)
        end
    end)
end
