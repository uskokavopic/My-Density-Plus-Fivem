local spawnedPeds = {}

Citizen.CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local waitTime = 1000

        for i, pedData in ipairs(Config.Peds) do
            local pedCoords = vector3(pedData.coords.x, pedData.coords.y, pedData.coords.z)
            local dist = #(playerCoords - pedCoords)
            local drawDist = pedData.distance or 35.0  -- fallback default

            if dist < drawDist then
                waitTime = 500

                if not spawnedPeds[i] or not DoesEntityExist(spawnedPeds[i]) then
                    local model = GetHashKey(pedData.model)
                    RequestModel(model)
                    while not HasModelLoaded(model) do
                        Wait(0)
                    end

                    local ped = CreatePed(4, model, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedData.coords.w, false, false)
                    SetEntityAsMissionEntity(ped, true, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)
                    SetPedCanRagdollFromPlayerImpact(ped, false)
                    SetEntityCanBeDamaged(ped, false)

                    if pedData.animDict and pedData.animName then
                        RequestAnimDict(pedData.animDict)
                        while not HasAnimDictLoaded(pedData.animDict) do
                            Wait(0)
                        end
                        TaskPlayAnim(ped, pedData.animDict, pedData.animName, 8.0, 1.0, -1, 1, 0, false, false, false)
                    end

                    spawnedPeds[i] = ped
                end
            else
                if spawnedPeds[i] and DoesEntityExist(spawnedPeds[i]) then
                    DeleteEntity(spawnedPeds[i])
                    spawnedPeds[i] = nil
                end
            end
        end

        Citizen.Wait(waitTime)
    end
end)
