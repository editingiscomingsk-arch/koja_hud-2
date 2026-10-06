KOJA.Client.SendNotify = function(data)
    KOJA.Client.SendReactMessage('koja_hud:sendNotify', {
        type = data.type or 'info',
        icon = data.icon or 'fas fa-info-circle',
        color = data.color or '#ffffff',
        title = data.title or 'Notify',
        desc = data.desc or '',
        time = tonumber(data.time) or 5000
    })
end

KOJA.Client.SendNotifyHud = function(data)
    local notification = {
        type = data.type,
        icon = data.icon,
        color = data.color,
        time = data.time,
        title = KOJA.Client.Translate(data.title, data.title),
        desc = KOJA.Client.Translate(data.desc, data.desc),
    }

    if KOJA.Notify == 'hud' then
        KOJA.Client.SendNotify(notification)
    elseif KOJA.Notify == 'custom' then
        Misc.Utils.CustomNotify(notification)
    else
        KojaLib.Client.SendNotify(notification)
    end
end
