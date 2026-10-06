local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local CANCEL_CONTROL = 73

KOJA.Client.Progress = {
    id = 0,
    active = false,
    canceled = false,
}

KOJA.Client.CancelProgressbar = function()
    if KOJA.Client.Progress.active then
        KOJA.Client.Progress.canceled = true
    end
    KOJA.Client.SendReactMessage("koja_hud:cancelProgressbar")
end

local function getBlockedControls(inputBlock)
    local controls = {}
    if type(inputBlock) == 'table' and type(inputBlock.keys) == 'table' then
        for _, key in ipairs(inputBlock.keys) do
            if Keys[key] then controls[#controls + 1] = Keys[key] end
        end
    end
    return controls
end

KOJA.Client.StartProgressbar = function(data, callback)
    if type(data) ~= 'table' then return end

    local progress = KOJA.Client.Progress
    progress.id = progress.id + 1
    progress.active = true
    progress.canceled = false

    local id = progress.id
    local duration = (tonumber(data.time) or 0) * 1000

    KOJA.Client.SendReactMessage("koja_hud:startProgressbar", data)

    CreateThread(function()
        local ped = PlayerPedId()
        local animation = data.animation
        local playsAnimation = type(animation) == 'table' and animation.dict and animation.name

        if playsAnimation then
            RequestAnimDict(animation.dict)
            while not HasAnimDictLoaded(animation.dict) do
                Wait(10)
            end
            TaskPlayAnim(ped, animation.dict, animation.name, 8.0, -8.0, duration, 49, 0, false, false, false)
        end

        local blockedControls = getBlockedControls(data.inputBlock)
        local endTime = GetGameTimer() + duration

        while GetGameTimer() < endTime and progress.id == id and not progress.canceled do
            for _, control in ipairs(blockedControls) do
                DisableControlAction(0, control, true)
            end
            if data.cancelable and IsControlJustPressed(0, CANCEL_CONTROL) then
                progress.canceled = true
                KOJA.Client.SendReactMessage("koja_hud:cancelProgressbar")
            end
            Wait(0)
        end

        local isCurrent = progress.id == id
        local finished = isCurrent and not progress.canceled
        if isCurrent then
            progress.active = false
            progress.canceled = false
        end

        if playsAnimation then
            StopAnimTask(ped, animation.dict, animation.name, 1.0)
            RemoveAnimDict(animation.dict)
        end

        if callback then
            callback(finished)
        end
    end)
end

exports("startProgressbar", KOJA.Client.StartProgressbar)
exports("cancelProgressbar", KOJA.Client.CancelProgressbar)
exports("isProgressbarActive", function()
    return KOJA.Client.Progress.active
end)
