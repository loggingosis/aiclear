local suppressionActive = false
local suppressionEndTime = 0

local function ShowMsg(msg)
    TriggerEvent('chat:addMessage', {
        color = {255, 80, 80},
        multiline = false,
        args = {'AI CLEAR', msg}
    })
end

local function IsPlayerPedEntity(ped)
    for _, player in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(player)
        if playerPed == ped then
            return true
        end
    end
    return false
end

local function DeleteNearbyAmbientPeds(radius)
    local handle, ped = FindFirstPed()
    local success
    local myCoords = GetEntityCoords(PlayerPedId())
    local deleted = 0

    repeat
        if DoesEntityExist(ped) then
            if not IsPedAPlayer(ped) and not IsPlayerPedEntity(ped) then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(myCoords - pedCoords)

                if dist <= radius then
                    -- Skip mission-critical or protected entities if desired
                    if not IsEntityAMissionEntity(ped) then
                        SetEntityAsMissionEntity(ped, true, true)
                    end

                    DeletePed(ped)

                    if DoesEntityExist(ped) then
                        DeleteEntity(ped)
                    end

                    if not DoesEntityExist(ped) then
                        deleted = deleted + 1
                    end
                end
            end
        end

        success, ped = FindNextPed(handle)
    until not success

    EndFindPed(handle)
    return deleted
end

local function DeleteNearbyNpcVehicles(radius)
    local handle, veh = FindFirstVehicle()
    local success
    local myCoords = GetEntityCoords(PlayerPedId())
    local deleted = 0

    repeat
        if DoesEntityExist(veh) then
            local vehCoords = GetEntityCoords(veh)
            local dist = #(myCoords - vehCoords)

            if dist <= radius then
                local driver = GetPedInVehicleSeat(veh, -1)

                -- Delete empty vehicles or vehicles driven by NPCs only
                local shouldDelete = false

                if driver == 0 or not DoesEntityExist(driver) then
                    shouldDelete = true
                elseif DoesEntityExist(driver) and not IsPedAPlayer(driver) then
                    shouldDelete = true
                end

                if shouldDelete then
                    if not IsEntityAMissionEntity(veh) then
                        SetEntityAsMissionEntity(veh, true, true)
                    end

                    DeleteVehicle(veh)

                    if DoesEntityExist(veh) then
                        DeleteEntity(veh)
                    end

                    if not DoesEntityExist(veh) then
                        deleted = deleted + 1
                    end
                end
            end
        end

        success, veh = FindNextVehicle(handle)
    until not success

    EndFindVehicle(handle)
    return deleted
end

local function StartPopulationSuppression(durationMs)
    suppressionActive = true
    suppressionEndTime = GetGameTimer() + durationMs
end

CreateThread(function()
    while true do
        if suppressionActive then
            local now = GetGameTimer()

            if now >= suppressionEndTime then
                suppressionActive = false
            else
                -- Hard suppress ambient world population
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetPedDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)

                SetCreateRandomCops(false)
                SetCreateRandomCopsNotOnScenarios(false)
                SetCreateRandomCopsOnScenarios(false)

                SuppressShockingEventsNextFrame()
                DisableVehicleDistantlights(false)

                Wait(0)
            end
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('deleteallai:run', function()
    local pedRadius = 10000.0
    local vehRadius = 10000.0
    local suppressMs = 15000

    -- Immediate density suppression before deleting
    StartPopulationSuppression(suppressMs)

    -- Multiple passes catch entities that were mid-streaming / mid-task
    local totalPeds = 0
    local totalVehs = 0

    for i = 1, 3 do
        totalPeds = totalPeds + DeleteNearbyAmbientPeds(pedRadius)
        totalVehs = totalVehs + DeleteNearbyNpcVehicles(vehRadius)
        Wait(500)
    end

    ShowMsg(('Ambient AI cleared. Peds removed: %s | Vehicles removed: %s'):format(totalPeds, totalVehs))
end)
