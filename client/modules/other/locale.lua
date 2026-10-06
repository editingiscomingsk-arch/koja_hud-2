local function loadTranslations()
    local resource = GetCurrentResourceName()
    local file = LoadResourceFile(resource, ('locales/%s.json'):format(KOJA.Locale))
        or LoadResourceFile(resource, 'locales/en.json')
    return file and json.decode(file) or {}
end

KOJA.Client.Translations = loadTranslations()

RegisterNUICallback('loadLocale', function(_, cb)
    cb({})
    KOJA.Client.SendReactMessage('setLocale', KOJA.Client.Translations)
end)

KOJA.Client.Translate = function(key, default)
    if type(key) ~= 'string' then return default end

    local result = KOJA.Client.Translations
    for part in key:gmatch("[^%.]+") do
        if type(result) ~= 'table' or result[part] == nil then
            if KOJA.Debug then
                KojaLib.Client.Print(2, true, "Missing translation: " .. key)
            end
            return default
        end
        result = result[part]
    end

    return result
end
