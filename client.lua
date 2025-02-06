local ESX = exports["es_extended"]:getSharedObject()
local renderedNametags = {}
local maskedNames = {}
local playerDataCache = {}
local showNametags = false
local playerFont = Config.DefaultFont

CreateThread(function()
    local savedFont = GetResourceKvpString("playerFont_" .. GetPlayerServerId(PlayerId()))
    if savedFont then
        playerFont = tonumber(savedFont)
    end
end)

local function Draw3DText(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    local distance = #(coords - GetGameplayCamCoords())
    local scale = (1 / distance) * 2 * (1 / GetGameplayCamFov()) * 100

    SetTextScale(0.40 * scale, 0.40 * scale)
    SetTextFont(playerFont)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(1)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(_x, _y)
end

local function GenerateMaskedName(playerId)
    if not maskedNames[playerId] then
        maskedNames[playerId] = "Masked_" .. tostring(math.random(10000000, 99999999))
    end
    return maskedNames[playerId]
end

local function IsWearingMask(ped)
    local drawable = GetPedDrawableVariation(ped, 1)
    return drawable ~= 0
end

local function DrawNametags()
    for _, nametag in ipairs(renderedNametags) do
        Draw3DText(nametag.coords, nametag.text)
    end
end

local function GetESXPlayerName(playerId)
    if playerDataCache[playerId] then
        return playerDataCache[playerId]
    end

    TriggerServerEvent("lsc_fetchnames", playerId)
    return nil
end



local function RenderNametags()
    local playerCoords = GetEntityCoords(PlayerPedId())
    renderedNametags = {}

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local playerId = GetPlayerServerId(player)

        if DoesEntityExist(targetPed) and IsEntityOnScreen(targetPed) then
            local distance = #(playerCoords - GetPedBoneCoords(targetPed, 31086))
            if distance < 10.0 then
                local text

                if IsWearingMask(targetPed) then
                    text = GenerateMaskedName(playerId)
                else
                    maskedNames[playerId] = nil
                    text = GetESXPlayerName(playerId)

                    if not text then
                        goto continue
                    end
                end

                renderedNametags[#renderedNametags + 1] = {
                    coords = GetPedBoneCoords(targetPed, 31086) + vector3(0.0, 0.0, 0.35),
                    text = text
                }
            end
        end
        ::continue::
    end
end

RegisterCommand('tognametags', function()
    showNametags = not showNametags
    lib.notify({
        description = showNametags and 'Name tags enabled.' or 'Name tags disabled.',
        type = showNametags and 'success' or 'error'
    })
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

    if input and input[1] then
        playerFont = tonumber(input[1])
        SetResourceKvp("playerFont_" .. GetPlayerServerId(PlayerId()), tostring(playerFont))
    end
end, false)

RegisterNetEvent("lsc_returnname")
AddEventHandler("lsc_returnname", function(playerId, formattedName)
    if formattedName and formattedName ~= "" then
        playerDataCache[playerId] = formattedName
    else
        playerDataCache[playerId] = nil
    end
end)



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
