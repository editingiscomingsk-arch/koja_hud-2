KOJA.Client.Session = 0
KOJA.MinimapPos = { x = 0.0, y = 0.0 }
KOJA.MinimapScale = 1.0
KOJA.MinimapVisibility = KOJA.HideMinimapOnFoot and 'vehicle' or 'always'

local MINIMAP_DEFAULTS = {
    EditorBoxScale = 1.12,
    EditorBoxScaleX = 1.28,
    EditorBoxScaleY = 1.12,
    OffsetX = 0.01,      OffsetY = -0.05,
    Width = 0.150,       Height = 0.188888,
    MaskOffsetX = 0.010, MaskOffsetY = -0.030,
    MaskWidth = 0.101,   MaskHeight = 0.159,
    BlurOffsetX = 0.00,  BlurOffsetY = -0.040,
    BlurWidth = 0.250,   BlurHeight = 0.237,
}

KOJA.MiniMap = KOJA.MiniMap or {}
for key, value in pairs(MINIMAP_DEFAULTS) do
    if KOJA.MiniMap[key] == nil then KOJA.MiniMap[key] = value end
end

KOJA.Client.SendReactMessage = function(action, data)
    SendNUIMessage({
        action = action, data = data
    })
end

KOJA.Client.IsSessionActive = function(session)
    return KOJA.Client.PlayerLoaded and session == KOJA.Client.Session
end

KOJA.Client.Start = function()
    KOJA.Client.Session = KOJA.Client.Session + 1
    local session = KOJA.Client.Session

    Wait(1000)
    if session ~= KOJA.Client.Session then return end

    if KOJA.Debug then
        KojaLib.Client.Print(1, true, "HUD STARTED")
    end

    KOJA.Client.SendReactMessage('koja_hud:openHud', true)
    KOJA.Client.SendReactMessage('koja_hud:hideComponents', KOJA.HideComponents)
    if KOJA.Watermark and KOJA.Watermark.Enabled then
        KOJA.Client.SendReactMessage('koja_hud:refreshHud', {
            watermark = { text = KOJA.Watermark.Text or '' }
        })
    end

    KOJA.Client.StartThread(session)
    KOJA.Client.StartVehicleThread(session)
    KOJA.Client.StartCompassThread(session)
    KOJA.Client.StartWeaponThread(session)
    KOJA.Client.StartPauseMenuThread(session)
    KOJA.Client.HideNativeHUDComponents(session)
    KOJA.Client.SetMiniMap()
end

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1000)
    if KOJA.Client.PlayerLoaded or not KOJA.Client.IsPlayerLoaded() then return end
    KOJA.Client.PlayerLoaded = true
    KOJA.Client.Start()
end)

KOJA.Client.SetMiniMap = function()
    if not KOJA.MiniMap.Enabled then
        KOJA.Client.SendReactMessage('koja_hud:minimapRect', { enabled = false })
        return
    end

    RequestStreamedTextureDict("squaremap", false)
    while not HasStreamedTextureDictLoaded("squaremap") do
        Wait(0)
    end

    local defaultAspectRatio = 1920 / 1080
    local resolutionX, resolutionY = GetActiveScreenResolution()
    local aspectRatio = resolutionX / resolutionY
    local minimapOffset = 0
    if aspectRatio > defaultAspectRatio then
        minimapOffset = ((defaultAspectRatio - aspectRatio) / 3.6) - 0.008
    end

    local offsetX = (KOJA.MinimapPos.x or 0.0) * 0.01
    local offsetY = (KOJA.MinimapPos.y or 0.0) * 0.01
    local scale = KOJA.MinimapScale or 1.0

    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")

    SetMinimapComponentPosition("minimap", "L", "B",
        KOJA.MiniMap.OffsetX + minimapOffset + offsetX,
        KOJA.MiniMap.OffsetY + minimapOffset + offsetY,
        KOJA.MiniMap.Width * scale,
        KOJA.MiniMap.Height * scale
    )

    SetMinimapComponentPosition("minimap_mask", "L", "B",
        KOJA.MiniMap.MaskOffsetX + minimapOffset + offsetX,
        KOJA.MiniMap.MaskOffsetY + minimapOffset + offsetY,
        KOJA.MiniMap.MaskWidth * scale,
        KOJA.MiniMap.MaskHeight * scale
    )

    SetMinimapComponentPosition("minimap_blur", "L", "B",
        KOJA.MiniMap.BlurOffsetX + minimapOffset + offsetX,
        KOJA.MiniMap.BlurOffsetY + minimapOffset + offsetY,
        KOJA.MiniMap.BlurWidth * scale,
        KOJA.MiniMap.BlurHeight * scale
    )

    SetBlipAlpha(GetNorthRadarBlip(), 0)

    local boxScale = KOJA.MiniMap.EditorBoxScale or 1.5
    KOJA.Client.SendReactMessage('koja_hud:minimapRect', {
        enabled = true,
        left = (KOJA.MiniMap.OffsetX + minimapOffset) * 100,
        bottom = -(KOJA.MiniMap.OffsetY + minimapOffset) * 100,
        width = KOJA.MiniMap.Width * 100 * (KOJA.MiniMap.EditorBoxScaleX or boxScale),
        height = KOJA.MiniMap.Height * 100 * (KOJA.MiniMap.EditorBoxScaleY or boxScale),
    })

    SetRadarBigmapEnabled(true, false)
    while IsBigmapActive() do
        Wait(0)
        SetRadarBigmapEnabled(false, false)
    end
end

RegisterCommand(KOJA.SettingsCommand, function()
    KOJA.Client.ToggleSettings(true)
end, false)

KOJA.Client.ToggleSettings = function(shouldShow)
    SetNuiFocus(shouldShow, shouldShow)
    KOJA.Client.SendReactMessage('koja_hud:openSettings', shouldShow)
end

RegisterNUICallback("koja_hud:getConfig", function(_, cb)
    cb({
        defaults = {
            minimap = { visibility = KOJA.MinimapVisibility },
            killfeed = {
                enabled = KOJA.Killfeed.Enabled == true,
                anyDistance = KOJA.Killfeed.AnyDistance ~= false,
                distance = KOJA.Killfeed.Distance or 100,
            },
        },
        features = {
            compass = not KOJA.Compass or KOJA.Compass.Enabled ~= false,
            watermark = KOJA.Watermark and KOJA.Watermark.Enabled == true,
        },
        bindKeys = KOJA.Client.GetBindableKeys(),
    })
end)

RegisterNUICallback("koja_hud:closeSettings", function(_, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback("koja_hud:updateMinimap", function(data, cb)
    if type(data) == 'table' then
        if data.x ~= nil or data.y ~= nil then
            KOJA.MinimapPos = {
                x = tonumber(data.x) or KOJA.MinimapPos.x,
                y = tonumber(data.y) or KOJA.MinimapPos.y
            }
        end
        if data.scale ~= nil then
            KOJA.MinimapScale = tonumber(data.scale) or 1.0
        end
    end
    if KOJA.MiniMap.Enabled then
        KOJA.Client.SetMiniMap()
    end
    cb({})
end)

RegisterNUICallback("koja_hud:updateMinimapPosition", function(data, cb)
    KOJA.MinimapPos = {
        x = tonumber(data and data.x) or 0.0,
        y = tonumber(data and data.y) or 0.0
    }
    if KOJA.MiniMap.Enabled then
        KOJA.Client.SetMiniMap()
    end
    cb({})
end)

KOJA.Client.HideComponent = function(component, hide)
    if KOJA.HideComponents[component] == nil then
        if KOJA.Debug then
            KojaLib.Client.Print(3, true, "Invalid component: " .. tostring(component))
        end
        return
    end

    KOJA.HideComponents[component] = hide
    KOJA.Client.SendReactMessage('koja_hud:hideComponents', KOJA.HideComponents)
    if KOJA.Debug then
        KojaLib.Client.Print(1, true, "Component " .. component .. " " .. (hide and "hidden" or "shown"))
    end
end

KOJA.Client.HideComponents = function(components)
    for component, hide in pairs(components) do
        if KOJA.HideComponents[component] ~= nil then
            KOJA.HideComponents[component] = hide
        end
    end
    KOJA.Client.SendReactMessage('koja_hud:hideComponents', KOJA.HideComponents)
end

KOJA.Client.ToggleHud = function(visible)
    KOJA.Client.SendReactMessage('koja_hud:toggleHud', visible)
    if KOJA.Debug then
        KojaLib.Client.Print(1, true, "HUD " .. (visible and "shown" or "hidden"))
    end
end
