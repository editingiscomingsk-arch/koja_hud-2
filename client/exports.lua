exports("IsSeatbeltOn", function()
    return KOJA.Client.IsSeatbeltOn()
end)

exports("sendNotify", function(data)
    KOJA.Client.SendNotify(data or {})
end)

exports('SetNitro', function()
    KOJA.Client.SetNitro()
end)

exports('GetNitro', function()
    return KOJA.Client.GetNitro()
end)

exports('ToggleHUD', function(visible)
    KOJA.Client.ToggleHud(visible)
end)

exports('HideComponent', function(component, hide)
    KOJA.Client.HideComponent(component, hide)
end)

exports('HideComponents', function(components)
    if type(components) == 'table' then
        KOJA.Client.HideComponents(components)
    end
end)
