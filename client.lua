local showNametags = false
local ESX = exports["es_extended"]:getSharedObject()
local renderedNametags = {}

local function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local distance = #(coords - GetGameplayCamCoords())
    local scale = (1 / distance) * 2 * (1 / GetGameplayCamFov()) * 100

    SetTextScale(0.40 * scale, 0.40 * scale)
    SetTextFont(Config.DefaultFont)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(1)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(_x, _y)
end


local function RenderNametags()
    local playerCoords = GetEntityCoords(PlayerPedId())
    renderedNametags = {}

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        if DoesEntityExist(targetPed) and IsEntityOnScreen(targetPed) then
            local distance = #(playerCoords - GetPedBoneCoords(targetPed, 31086))
            if distance < 15.0 then
                local text = player == PlayerId() and 
                    (ESX.PlayerData.firstName or "Unknown") .. " " .. (ESX.PlayerData.lastName or "Player") or 
                    GetPlayerName(player)
                renderedNametags[#renderedNametags + 1] = {coords = GetPedBoneCoords(targetPed, 31086) + vector3(0.0, 0.0, 0.35), text = text}
            end
        end
    end
end

local function DrawNametags()
    for _, nametag in ipairs(renderedNametags) do
        Draw3DText(nametag.coords, nametag.text)
    end
end

RegisterCommand('tognametags', function()
    showNametags = not showNametags
    if showNametags then RenderNametags() end
    lib.notify({description = showNametags and 'Name tags enabled.' or 'Name tags disabled.', type = showNametags and 'success' or 'error'})
end, false)

RegisterCommand('changefont', function()
    local fontOptions = {
        {value = Config.TextFonts.STANDARD, label = 'Standard'},
        {value = Config.TextFonts.CURSIVE, label = 'Cursive'},
        {value = Config.TextFonts.ROCKSTAR_TAG, label = 'Rockstar Tag'},
        {value = Config.TextFonts.CONDENSED, label = 'Condensed'},
        {value = Config.TextFonts.PRICEDOWN, label = 'Pricedown'},
        {value = Config.TextFonts.TAXI, label = 'Taxi'}
    }
    local input = lib.inputDialog('Change Font', {{type = 'select', label = 'Select Font', options = fontOptions}})
    if input and input[1] then Config.DefaultFont = tonumber(input[1]) end
end, false)

CreateThread(function()
    while true do
        if showNametags then
            RenderNametags()
            DrawNametags()
            Wait(0)
        else
            Wait(500)
        end
    end
end)