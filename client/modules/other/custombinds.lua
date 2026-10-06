local customBinds = {}
local builtinBinds = {}

local keyControls = {
    A = 34, B = 29, C = 26, D = 35, E = 38, F = 23, G = 47, H = 74,
    K = 311, L = 182, M = 244, N = 249, P = 199, Q = 44, R = 45, S = 33,
    T = 245, U = 303, V = 0, W = 32, X = 73, Y = 246, Z = 20,
    ['1'] = 157, ['2'] = 158, ['3'] = 160, ['4'] = 164, ['5'] = 165,
    ['6'] = 159, ['7'] = 161, ['8'] = 162, ['9'] = 163,
    F1 = 288, F2 = 289, F3 = 170, F5 = 166, F6 = 167, F7 = 168,
    F8 = 169, F9 = 56, F10 = 57, F11 = 344,
    SPACE = 22, TAB = 37, CAPITAL = 137, LSHIFT = 21, LCONTROL = 36, LMENU = 19,
    HOME = 213, INSERT = 121, DELETE = 178, PAGEUP = 10, PAGEDOWN = 11,
    UP = 172, DOWN = 173, LEFT = 174, RIGHT = 175,
    COMMA = 82, PERIOD = 81, MINUS = 84, EQUALS = 83,
    LBRACKET = 39, RBRACKET = 40, GRAVE = 243,
    NUMPAD4 = 108, NUMPAD5 = 60, NUMPAD6 = 107, NUMPAD7 = 117, NUMPAD8 = 61, NUMPAD9 = 118,
    NUMPAD_PLUS = 96, NUMPAD_MINUS = 97, NUMPAD_ENTER = 201,
}

local function sanitizeKey(key)
    if type(key) ~= 'string' then return nil end
    key = key:gsub('[^%w_]', ''):upper()
    if key == '' then return nil end
    return key
end

local function sanitizeCommand(command)
    if type(command) ~= 'string' then return nil end
    command = command:gsub('[";]', '')
    if command == '' then return nil end
    return command
end

local function controlForKey(key)
    local sanitized = sanitizeKey(key)
    return sanitized and keyControls[sanitized]
end

local function defaultBuiltinKeys()
    return {
        engine = KOJA.Engine and KOJA.Engine.Key or 'B',
        seatbelt = KOJA.Seatbelt and KOJA.Seatbelt.Key or 'L',
        cruise = KOJA.CruiseMode and KOJA.CruiseMode.Key or 'T',
        nitro = KOJA.Nitro and KOJA.Nitro.Key or 'N',
        vehicleMenu = KOJA.VehicleMenu and KOJA.VehicleMenu.Key or 'U',
    }
end

local function isBuiltinOverride(bind)
    local key = sanitizeKey(bind.key)
    return bind.id ~= nil and key ~= nil and key ~= sanitizeKey(defaultBuiltinKeys()[bind.id])
end

KOJA.Client.GetBindableKeys = function()
    local keys = {}
    for key in pairs(keyControls) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    return keys
end

RegisterNUICallback('koja_hud:updateCustomBinds', function(data, cb)
    customBinds = {}
    for _, bind in ipairs(type(data) == 'table' and data.binds or {}) do
        local control = controlForKey(bind.key)
        local command = sanitizeCommand(bind.command)
        if control and command then
            customBinds[#customBinds + 1] = { control = control, command = command }
        end
    end
    cb({})
end)

RegisterNUICallback('koja_hud:updateBuiltinBinds', function(data, cb)
    builtinBinds = {}
    local defaults = defaultBuiltinKeys()
    for _, bind in ipairs(type(data) == 'table' and data.binds or {}) do
        local control = controlForKey(bind.key)
        local command = sanitizeCommand(bind.command)
        if control and command and isBuiltinOverride(bind) then
            builtinBinds[#builtinBinds + 1] = {
                control = control,
                command = command,
                releaseCommand = command:gsub('^%+', '-'),
                oldControl = controlForKey(defaults[bind.id]),
            }
        end
    end
    cb({})
end)

CreateThread(function()
    while true do
        if #customBinds > 0 or #builtinBinds > 0 then
            for _, bind in ipairs(builtinBinds) do
                if bind.oldControl then DisableControlAction(0, bind.oldControl, true) end
                if IsControlJustPressed(0, bind.control) then
                    ExecuteCommand(bind.command)
                elseif IsControlJustReleased(0, bind.control) then
                    ExecuteCommand(bind.releaseCommand)
                end
            end
            for _, bind in ipairs(customBinds) do
                if IsControlJustPressed(0, bind.control) then
                    ExecuteCommand(bind.command)
                end
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)
