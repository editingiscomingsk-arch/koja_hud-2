Misc = {}
Misc.Utils = {}

Misc.Utils.CustomNotify = function(data)

end

if IsDuplicityVersion() or not KOJA.Microphone or not KOJA.Microphone.Enabled or KOJA.Microphone.Custom then
    return
end

RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
    KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
        status = {
            { id = "voice", status = KojaLib.Client.percent(KOJA.Microphone.Levels[mode] or 0, 100) }
        },
    })
end)
