local cfg = lib.load('config')

local function logDebug(msg)
    if cfg.debug then
        print(("[my_density_plus] %s"):format(msg))
    end
end

local function clone(t)
    local out = {}
    for k, v in pairs(t) do out[k] = v end
    return out
end

local function clamp01(v)
    v = tonumber(v) or 0.0
    if v < 0.0 then return 0.0 end
    if v > 1.0 then return 1.0 end
    return v
end

-- =========================
-- Calm AI relationships
-- =========================
local function setupRelationships()
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_HILLBILLY`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_BALLAS`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MEXICAN`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_FAMILY`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MARABUNTE`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_SALVA`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_LOST`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_1`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_2`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_9`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_10`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `FIREMAN`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `MEDIC`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `COP`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `PRISONER`, `PLAYER`)
end

-- =========================
-- Ambient cops handling
-- =========================
local ambientCopsEnabled = (cfg.ambientCops and cfg.ambientCops.enabled) or false

local COP_PED_MODELS = {
    `s_m_y_cop_01`,
    `s_f_y_cop_01`,
    `s_m_y_sheriff_01`,
    `s_f_y_sheriff_01`,
    `s_m_y_hwaycop_01`,
}

local COP_VEH_MODELS = {
    `police`, `police2`, `police3`, `police4`,
    `policeb`, `policet`, `sheriff`, `sheriff2`,
    `fbi`, `fbi2`, `pranger`,
    `riot`, `riot2`,
    `polmav`,
}

local POLICE_SCENARIOS = {
    'WORLD_VEHICLE_POLICE_CAR',
    'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
    'WORLD_VEHICLE_POLICE_BIKE',
    'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
    'WORLD_VEHICLE_MILITARY_PLANES_BIG',
}

local function setDispatchEnabled(enable)
    -- DisableDispatchService takes an integer index (0..)
    -- We'll disable the common ones broadly when turning cops off.
    -- When enable=true, we enable back the same set.
    local services = {
        1,  -- PoliceAutomobile
        2,  -- PoliceHelicopter
        3,  -- FireDepartment
        4,  -- SwatAutomobile
        5,  -- AmbulanceDepartment
        6,  -- PoliceRiders
        7,  -- PoliceVehicleRequest
        8,  -- PoliceRoadBlock
        9,  -- PoliceAutomobileWaitPulledOver
        10, -- PoliceAutomobileWaitCruising
        11, -- Gangs
        12, -- SwatHelicopter
        13, -- PoliceBoat
        14, -- ArmyVehicle
        15, -- BikerBackup
    }

    for _, s in ipairs(services) do
        EnableDispatchService(s, enable)
    end

    -- also: keep player wanted level clean when cops off
    if not enable then
        ClearPlayerWantedLevel(PlayerId())
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
        SetMaxWantedLevel(0)
    else
        SetMaxWantedLevel(5)
    end
end

local function applyAmbientCopsState()
    local ac = cfg.ambientCops or {}

    if ambientCopsEnabled then
        -- Turning ON ambient cops (restore defaults as best as possible)
        if ac.disableDispatch then setDispatchEnabled(true) end
        if ac.disableRandomCops then
            SetCreateRandomCops(true)
            SetCreateRandomCopsNotOnScenarios(true)
            SetCreateRandomCopsOnScenarios(true)
        end

        if ac.suppressCopPeds then
            for _, m in ipairs(COP_PED_MODELS) do
                SetPedModelIsSuppressed(m, false)
            end
        end

        if ac.suppressCopVehicles then
            for _, m in ipairs(COP_VEH_MODELS) do
                SetVehicleModelIsSuppressed(m, false)
            end
        end

        if ac.disablePoliceScenarios then
            for _, s in ipairs(POLICE_SCENARIOS) do
                SetScenarioTypeEnabled(s, true)
            end
        end

        logDebug("Ambient cops: ON")
    else
        -- Turning OFF ambient cops
        if ac.disableDispatch then setDispatchEnabled(false) end

        if ac.disableRandomCops then
            SetCreateRandomCops(false)
            SetCreateRandomCopsNotOnScenarios(false)
            SetCreateRandomCopsOnScenarios(false)
            DisablePoliceReports()
        end

        if ac.suppressCopPeds then
            for _, m in ipairs(COP_PED_MODELS) do
                SetPedModelIsSuppressed(m, true)
            end
        end

        if ac.suppressCopVehicles then
            for _, m in ipairs(COP_VEH_MODELS) do
                SetVehicleModelIsSuppressed(m, true)
            end
        end

        if ac.disablePoliceScenarios then
            for _, s in ipairs(POLICE_SCENARIOS) do
                SetScenarioTypeEnabled(s, false)
            end
        end

        -- extra safety
        ClearPlayerWantedLevel(PlayerId())
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)

        logDebug("Ambient cops: OFF")
    end
end

-- Export to toggle cops
local function setAmbientCops(enabled)
    ambientCopsEnabled = enabled and true or false
    applyAmbientCopsState()
end
exports('SetAmbientCops', setAmbientCops)

-- Command for testing
RegisterCommand('cops', function(_, args)
    local v = (args[1] or ''):lower()
    if v == 'on' then
        setAmbientCops(true)
        print('[my_density_plus] Ambient cops ON')
    elseif v == 'off' then
        setAmbientCops(false)
        print('[my_density_plus] Ambient cops OFF')
    else
        print(('[my_density_plus] Usage: /cops on|off (current: %s)'):format(ambientCopsEnabled and 'on' or 'off'))
    end
end, false)

-- Re-apply on spawn (some natives may reset on session start)
AddEventHandler('playerSpawned', function()
    applyAmbientCopsState()
end)

-- =========================
-- Profiles / State
-- =========================
local baseProfileName = "default"     -- decided by zones
local forcedProfileName = nil         -- decided by crowd scaling or command
local manualOverride = nil            -- decided by SetDensity export
local active = clone(cfg.profiles.default)

local function applyProfile(profileName)
    local p = cfg.profiles[profileName]
    if not p then return false end
    active = clone(p)
    baseProfileName = profileName
    logDebug(("Base profile -> %s"):format(profileName))
    return true
end

local function getFinalDensity()
    if manualOverride then return manualOverride end
    if forcedProfileName then
        local p = cfg.profiles[forcedProfileName]
        if p then return p end
    end
    return active
end

-- Exports
local function setDensity(typeName, value)
    value = clamp01(value)
    manualOverride = manualOverride or clone(getFinalDensity())

    if typeName == 'parked' then
        manualOverride.parked = value
    elseif typeName == 'vehicle' then
        manualOverride.vehicle = value
    elseif typeName == 'randomvehicles' then
        manualOverride.randomvehicles = value
    elseif typeName == 'peds' then
        manualOverride.peds = value
    elseif typeName == 'scenario' then
        manualOverride.scenario = value
    end
end
exports('SetDensity', setDensity)

local function setProfile(profileName)
    if cfg.profiles[profileName] then
        manualOverride = nil
        forcedProfileName = profileName
        logDebug(("Forced profile -> %s"):format(profileName))
        return true
    end
    return false
end
exports('SetProfile', setProfile)

local function clearOverrides()
    manualOverride = nil
    forcedProfileName = nil
    logDebug("Overrides cleared")
end
exports('ClearOverrides', clearOverrides)

local function clearDensityOverride()
    manualOverride = nil
    logDebug("Manual density override cleared")
end
exports('ClearDensityOverride', clearDensityOverride)

-- Zones
local function getZoneProfile(coords)
    if not cfg.zones then return "default", nil end

    for _, z in ipairs(cfg.zones) do
        local dx = coords.x - z.x
        local dy = coords.y - z.y
        local dz = coords.z - z.z
        if (dx*dx + dy*dy + dz*dz) <= (z.r * z.r) then
            return z.profile, z.name
        end
    end

    return "default", nil
end

-- Crowd scaling
local function countNearbyPlayers(radius, ignoreDead)
    local myPed = PlayerPedId()
    if myPed == 0 or not DoesEntityExist(myPed) then return 0 end

    local myCoords = GetEntityCoords(myPed)
    local r2 = radius * radius
    local count = 0

    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and DoesEntityExist(ped) then
                if (not ignoreDead) or (not IsEntityDead(ped)) then
                    local c = GetEntityCoords(ped)
                    local dx = myCoords.x - c.x
                    local dy = myCoords.y - c.y
                    local dz = myCoords.z - c.z
                    if (dx*dx + dy*dy + dz*dz) <= r2 then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

local function chooseCrowdProfile(nearbyPlayers)
    local cs = cfg.crowdScaling
    if not cs or not cs.enabled then return nil end
    if not cs.thresholds then return nil end

    local best, bestMin = nil, -1
    for _, t in ipairs(cs.thresholds) do
        local minP = t.minPlayers or 9999
        if nearbyPlayers >= minP and minP > bestMin and cfg.profiles[t.profile] then
            best, bestMin = t.profile, minP
        end
    end
    return best
end

-- =========================
-- Main density loop (every frame)
-- =========================
CreateThread(function()
    if cfg.relationshipFriendlyToPlayer then
        setupRelationships()
    end

    -- apply cops state on start
    applyAmbientCopsState()

    while true do
        local d = getFinalDensity()

        SetParkedVehicleDensityMultiplierThisFrame(d.parked)
        SetVehicleDensityMultiplierThisFrame(d.vehicle)
        SetRandomVehicleDensityMultiplierThisFrame(d.randomvehicles)
        SetPedDensityMultiplierThisFrame(d.peds)
        SetScenarioPedDensityMultiplierThisFrame(d.scenario, d.scenario)

        Wait(0)
    end
end)

-- Zone switching loop
CreateThread(function()
    applyProfile("default")

    while true do
        Wait(cfg.zoneCheckIntervalMs or 2000)

        -- if user forced profile or manual override is active, don't auto zone-switch
        if forcedProfileName or manualOverride then
            goto continue
        end

        local ped = PlayerPedId()
        if ped == 0 or not DoesEntityExist(ped) then
            goto continue
        end

        local coords = GetEntityCoords(ped)
        local profileName, zoneName = getZoneProfile(coords)

        if profileName ~= baseProfileName then
            applyProfile(profileName)
            if zoneName then logDebug(("Zone -> %s"):format(zoneName)) end
        end

        ::continue::
    end
end)

-- Crowd scaling loop
CreateThread(function()
    local cs = cfg.crowdScaling
    if not cs or not cs.enabled then return end

    local lastCrowdProfile = nil

    while true do
        Wait(cs.intervalMs or 1500)

        -- if user forced profile or manual override is active, don't crowd-force
        if forcedProfileName or manualOverride then
            goto continue
        end

        local nearby = countNearbyPlayers(cs.radius or 140.0, cs.ignoreDead ~= false)
        local crowdProfile = chooseCrowdProfile(nearby)

        if crowdProfile ~= lastCrowdProfile then
            lastCrowdProfile = crowdProfile

            if crowdProfile then
                forcedProfileName = crowdProfile
                logDebug(("Crowd scaling -> %s (nearby=%d)"):format(crowdProfile, nearby))
            else
                forcedProfileName = nil
                logDebug(("Crowd scaling released (nearby=%d)"):format(nearby))
            end
        end

        ::continue::
    end
end)

-- =========================
-- Commands
-- =========================
RegisterCommand('densityprofile', function(_, args)
    local p = (args[1] or ""):lower()
    if p == "" then
        print(("[my_density_plus] base=%s forced=%s override=%s cops=%s"):format(
            baseProfileName,
            forcedProfileName or "none",
            manualOverride and "yes" or "no",
            ambientCopsEnabled and "on" or "off"
        ))
        return
    end

    if cfg.profiles[p] then
        manualOverride = nil
        forcedProfileName = p
        print(("[my_density_plus] forced profile set to %s"):format(p))
    else
        print("[my_density_plus] unknown profile. Options: default/city/highway/gang/low/off")
    end
end, false)

RegisterCommand('densityclear', function()
    clearOverrides()
    print("[my_density_plus] overrides cleared (back to zone + crowd scaling)")
end, false)