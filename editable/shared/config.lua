KOJA = {}

-- Print debug logs to the F8 console and register the /testnotify, /testprogress and /testtextui commands.
KOJA.Debug = false

-- Language file loaded from locales/ (en, pl, de, es, fr, hi).
KOJA.Locale = 'en'

-- Chat command that opens the HUD settings menu.
KOJA.SettingsCommand = 'settings'

-- Default minimap visibility: true = only in vehicles, false = always.
-- Players can change it in the settings menu.
KOJA.HideMinimapOnFoot = true

-- Hide the whole HUD while the GTA pause menu (ESC / map) is open.
KOJA.HideHudOnPauseMenu = true

-- Notification system used by the HUD itself: 'hud', 'custom', 'esx', 'qb' or 'ox'.
-- 'custom' calls Misc.Utils.CustomNotify in editable/shared/utils.lua.
KOJA.Notify = 'hud'

-- Set a component to true to force-hide it for everyone.
KOJA.HideComponents = {
    status = false,
    carhud = false,
    progressbar = false,
    notify = false,
    textui = false,
    informations = false
}

-- Show the minimap only when the player has the item below.
KOJA.NeedItemForMinimap = false
KOJA.MinimapItem = 'phone'

KOJA.Microphone = {
    Enabled = true,
    -- false = read the voice range from pma-voice talking modes, true = skip the pma-voice integration.
    Custom = false,
    -- Proximity range (pma-voice mode) mapped to the 0-100 voice bar.
    Levels = {
        [1] = 25,
        [2] = 75,
        [3] = 100,
    },
}

KOJA.Nitro = {
    Enabled = true,
    Key = 'N',
    Desc = 'Toggle nitro',
    -- Owned vehicles table: 'owned_vehicles' (ESX), 'player_vehicles' (QBCore) or your own.
    -- A `nitro` INT column is added to it automatically.
    Tables = {
        GaragesTable = 'owned_vehicles',
        OwnerColumn = 'owner'
    },
    -- Engine power multiplier while nitro is active (1.5 = +50%).
    NitroForce = 1.5,
    -- Nitro units (0-100) used every 100 ms while boosting.
    RemoveNitroOnMilliseconds = 2,
    -- Item used to install nitro. Set to false when you only install it through exports['koja-hud']:SetNitro().
    Item = 'nitro'
}

KOJA.Engine = {
    Enabled = true,
    Key = 'B',
    Desc = 'Toggle engine',
    StartEngineOnEntering = false
}

KOJA.Seatbelt = {
    Enabled = true,
    Key = 'L',
    Desc = 'Toggle seatbelt',
    -- Speed in km/h above which an unbelted player is thrown through the windshield on a crash.
    MaxVehicleSpeedToRagdoll = 70
}

KOJA.CruiseMode = {
    Enabled = true,
    Key = 'T',
    Desc = 'Toggle cruise control',
    -- Minimum speed in km/h to engage cruise control.
    MinSpeed = 20.0
}

KOJA.Compass = {
    Enabled = true
}

-- Client refresh intervals in milliseconds.
KOJA.Refresh = {
    Hud = 1500,
    PauseMenu = 200,
    Compass = 90,
    Weapon = 250,
    Vehicle = 150
}

-- Server name shown at the top of the screen (style and visibility are player settings).
KOJA.Watermark = {
    Enabled = true,
    Text = 'HEXEL RP'
}

-- Vehicle control menu (turn signals, doors, hood, trunk, engine, seatbelt).
KOJA.VehicleMenu = {
    Enabled = true,
    Key = 'U',
    Command = 'vehicle',
    Desc = 'Open vehicle control menu'
}

-- Killfeed defaults, players can change them in the settings menu.
KOJA.Killfeed = {
    Enabled = false,
    AnyDistance = true,
    -- Max kill distance in meters when AnyDistance is false.
    Distance = 100
}

KOJA.StatusEffects = {
    -- Show built-in effects detected on the client (sprinting, swimming).
    Builtin = false
}

-- Custom square minimap. Players move and resize it in the layout editor (Settings -> Edit layout).
KOJA.MiniMap = {
    Enabled = true,
}

-- More UI options (keybind hints, Discord, logo, default player settings) live in editable/shared/js.json.
