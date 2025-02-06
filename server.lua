ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent("lsc_fetchnames")
AddEventHandler("lsc_fetchnames", function(targetId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer then
        local firstName = xPlayer.get("firstName")
        local lastName = xPlayer.get("lastName")

        local formattedName = string.format("%s %s (%d)", firstName, lastName, targetId)
        TriggerClientEvent("lsc_returnname", src, targetId, formattedName)
    else
        TriggerClientEvent("lsc_returnname", src, targetId, "")
    end
end)
