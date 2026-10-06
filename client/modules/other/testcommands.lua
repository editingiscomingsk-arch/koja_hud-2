if not KOJA.Debug then return end

local notifyPresets = {
    success = { icon = 'fa-solid fa-check', color = '#35c76c', title = 'Success', desc = 'Everything went <strong>fine</strong>.' },
    error   = { icon = 'fa-solid fa-xmark', color = '#e5484d', title = 'Error', desc = 'Something went wrong.' },
    info    = { icon = 'fa-solid fa-info', color = '#00c3ff', title = 'Info', desc = 'Neutral information message.' },
    warning = { icon = 'fa-solid fa-triangle-exclamation', color = '#ffc933', title = 'Warning', desc = 'Careful with that.' },
}

RegisterCommand('testnotify', function(_, args)
    local preset = args[1] and notifyPresets[args[1]:lower()]
    if preset then
        KOJA.Client.SendNotify({
            icon = preset.icon,
            color = preset.color,
            title = preset.title,
            desc = preset.desc,
            time = tonumber(args[2]) or 5000
        })
    else
        for _, data in pairs(notifyPresets) do
            KOJA.Client.SendNotify({
                icon = data.icon,
                color = data.color,
                title = data.title,
                desc = data.desc,
                time = 6000
            })
        end
    end
end, false)

RegisterCommand('testprogress', function(_, args)
    local time = tonumber(args[1]) or 5
    local label = args[2] and table.concat(args, ' ', 2) or ('Testing progressbar (' .. time .. 's)')

    KOJA.Client.StartProgressbar({
        icon = 'fa-solid fa-screwdriver-wrench',
        label = label,
        time = time,
        cancelable = true
    }, function(finished)
        KOJA.Client.SendNotify({
            icon = finished and 'fa-solid fa-check' or 'fa-solid fa-xmark',
            color = finished and '#35c76c' or '#e5484d',
            title = 'Progressbar',
            desc = finished and 'Progressbar finished!' or 'Progressbar canceled (X).',
            time = 3000
        })
    end)
end, false)

RegisterCommand('testtextui', function(_, args)
    local key = args[1] or 'E'
    local desc = args[2] and table.concat(args, ' ', 2) or ("Press '" .. key .. "' to test TextUI")

    KOJA.Client.TextUI({
        type = 'press',
        input = key,
        desc = desc
    })
end, false)

RegisterCommand('hidetextui', function()
    KOJA.Client.HideUI()
end, false)

TriggerEvent('chat:addSuggestion', '/testnotify', 'Test HUD notifications', {
    { name = 'type', help = 'success | error | info | warning (empty = all)' },
    { name = 'time', help = 'display time in ms (optional)' }
})
TriggerEvent('chat:addSuggestion', '/testprogress', 'Test HUD progressbar (cancel with X)', {
    { name = 'seconds', help = 'duration in seconds (default 5)' },
    { name = 'label', help = 'progressbar label (optional)' }
})
TriggerEvent('chat:addSuggestion', '/testtextui', 'Test HUD TextUI', {
    { name = 'key', help = 'key to display (default E)' },
    { name = 'text', help = 'description text (optional)' }
})
TriggerEvent('chat:addSuggestion', '/hidetextui', 'Hide the test TextUI')
