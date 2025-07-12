local ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

local policeCars = {
    "police", "police2", "police3", "police4", "fbi", "fbi2"
}

local weaponList = {
    "WEAPON_CARBINERIFLE",
    "WEAPON_PISTOL",
    "WEAPON_NIGHTSTICK",
    "WEAPON_STUNGUN"
}

local function drawTextScreen(text)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.5, 0.9)
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function playTrunkSound(vehicle, open)
    local soundName = open and "Trunk_Open" or "Trunk_Close"
    local coords = GetEntityCoords(vehicle)
    PlaySoundFromCoord(-1, soundName, coords.x, coords.y, coords.z, "DLC_HEIST_HACKING_SNAKE_SOUNDS", false, 0, false)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local pos = GetEntityCoords(playerPed)
        local found = false

        if ESX and ESX.GetPlayerData() then
            local playerJob = ESX.GetPlayerData().job and ESX.GetPlayerData().job.name or ""
            if playerJob ~= 'police' then
                Citizen.Wait(1000)
                goto continue
            end
        else
            Citizen.Wait(1000)
            goto continue
        end

        for _, vehicle in ipairs(GetGamePool("CVehicle")) do
            if DoesEntityExist(vehicle) then
                local vehModel = GetEntityModel(vehicle)
                local modelName = GetDisplayNameFromVehicleModel(vehModel):lower()

                for _, allowedModel in ipairs(policeCars) do
                    if modelName == allowedModel then
                        local trunkOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -2.5, 0.0)
                        local _, groundZ = GetGroundZFor_3dCoord(trunkOffset.x, trunkOffset.y, trunkOffset.z + 1.0)
                        local dist = #(pos - vector3(trunkOffset.x, trunkOffset.y, groundZ))

                        if dist < 2.0 then
                            found = true
                            drawTextScreen("~g~[E]~w~ Search Trunk for Gear")

                            if IsControlJustReleased(0, 38) then
                                SetEntityCoords(playerPed, trunkOffset.x, trunkOffset.y, groundZ)
                                SetEntityHeading(playerPed, GetEntityHeading(vehicle))

                                SetVehicleDoorOpen(vehicle, 5, false, false)
                                playTrunkSound(vehicle, true)

                                loadAnimDict("amb@prop_human_bum_bin@base")
                                TaskPlayAnim(playerPed, "amb@prop_human_bum_bin@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)

                                Citizen.Wait(3000)
                                ClearPedTasks(playerPed)

                                for _, weapon in ipairs(weaponList) do
                                    GiveWeaponToPed(playerPed, GetHashKey(weapon), 250, false, false)
                                end
                                SetPedArmour(playerPed, 100)

                                SetVehicleDoorShut(vehicle, 5, false)
                                playTrunkSound(vehicle, false)

                                ESX.ShowNotification("~g~You equipped weapons and full armor.")
                            end
                        end
                    end
                end
            end
        end

        if not found then
            Citizen.Wait(500)
        end

        ::continue::
    end
end)
