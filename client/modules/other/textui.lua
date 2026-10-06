KOJA.Client.TextUI = function(data)
    KOJA.Client.SendReactMessage('koja_hud:startTextui', data)
end

KOJA.Client.HideUI = function()
    KOJA.Client.SendReactMessage('koja_hud:cancelTextui')
end

exports('TextUI', KOJA.Client.TextUI)
exports('HideUI', KOJA.Client.HideUI)

RegisterNetEvent('koja_hud:startTextUI', KOJA.Client.TextUI)
RegisterNetEvent('koja_hud:cancelTextUI', KOJA.Client.HideUI)
