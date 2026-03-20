local cfg = lib.load('config')

local function logDebug(msg)
    if cfg.debug then
        print(("[density_plus] %s"):format(msg))
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
-- Prevent ambient gang/cop NPCs from being hostile toward the player.
-- =========================
local function setupRelationships()
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_HILLBILLY`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_BALLAS`,    `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MEXICAN`,   `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_FAMILY`,    `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_MARABUNTE`, `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_SALVA`,     `PLAYER`)
    SetRelationshipBetweenGroups(1, `AMBIENT_GANG_LOST`,      `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_1`,   `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_2`,   `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_9`,   `PLAYER`)
    SetRelationshipBetweenGroups(1, `GANG_10`,  `PLAYER`)
    SetRelationshipBetweenGroups(1, `FIREMAN`,  `PLAYER`)
    SetRelationshipBetweenGroups(1, `MEDIC`,    `PLAYER`)
    SetRelationshipBetweenGroups(1, `COP`,      `PLAYER`)
    SetRelationshipBetweenGroups(1, `PRISONER`, `PLAYER`)
end

-- =========================
-- Ambient cops handling
-- =========================
local ambientCopsEnabled = (cfg.ambientCops and cfg.ambientCops.enabled) or false

local COP_PED_MODELS = {
    `s_m_y_cop_01`, `s_f_y_cop_01`,
    `s_m_y_sheriff_01`, `s_f_y_sheriff_01`,
    `s_m_y_hwaycop_01`,
}

local COP_VEH_MODELS = {
    `police`, `police2`, `police3`, `police4`,
    `policeb`, `policet`, `sheriff`, `sheriff2`,
    `fbi`, `fbi2`, `pranger`, `riot`, `riot2`, `polmav`,
}

local POLICE_SCENARIOS = {
    'WORLD_VEHICLE_POLICE_CAR',
    'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
    'WORLD_VEHICLE_POLICE_BIKE',
    'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
    'WORLD_VEHICLE_MILITARY_PLANES_BIG',
}

local DISPATCH_SERVICES = { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15 }

local function setDispatchEnabled(enable)
    for _, s in ipairs(DISPATCH_SERVICES) do
        EnableDispatchService(s, enable)
    end
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
    local ac     = cfg.ambientCops or {}
    local enable = ambientCopsEnabled

    if ac.disableDispatch then setDispatchEnabled(enable) end

    if ac.disableRandomCops then
        SetCreateRandomCops(enable)
        SetCreateRandomCopsNotOnScenarios(enable)
        SetCreateRandomCopsOnScenarios(enable)
        if not enable then DisablePoliceReports() end
    end

    if ac.suppressCopPeds then
        for _, m in ipairs(COP_PED_MODELS) do SetPedModelIsSuppressed(m, not enable) end
    end

    if ac.suppressCopVehicles then
        for _, m in ipairs(COP_VEH_MODELS) do SetVehicleModelIsSuppressed(m, not enable) end
    end

    if ac.disablePoliceScenarios then
        for _, s in ipairs(POLICE_SCENARIOS) do SetScenarioTypeEnabled(s, enable) end
    end

    -- NOTE: audio flags (PoliceScannerDisabled, DistantCopCarSirens) are NOT set here.
    -- GTA resets them continuously, so they are applied in a dedicated repeating loop below.

    -- Always clear wanted level when cops are disabled
    if not enable then
        ClearPlayerWantedLevel(PlayerId())
        SetPlayerWantedLevel(PlayerId(), 0, false)
        SetPlayerWantedLevelNow(PlayerId(), false)
    end

    logDebug(("Ambient cops: %s"):format(enable and "ON" or "OFF"))
end

local function setAmbientCops(enabled)
    ambientCopsEnabled = enabled and true or false
    applyAmbientCopsState()
end
exports('SetAmbientCops', setAmbientCops)

RegisterCommand('cops', function(_, args)
    local v = (args[1] or ''):lower()
    if v == 'on' then
        setAmbientCops(true)
        print('[density_plus] Ambient cops ON')
    elseif v == 'off' then
        setAmbientCops(false)
        print('[density_plus] Ambient cops OFF')
    else
        print(('[density_plus] Usage: /cops on|off (current: %s)'):format(ambientCopsEnabled and 'on' or 'off'))
    end
end, false)

-- Re-apply cops state on every spawn (natives can reset after session restart)
AddEventHandler('playerSpawned', function()
    applyAmbientCopsState()
end)

-- =========================
-- Audio suppression loop
-- DistantCopCarSirens and SetAudioFlag must be called every frame —
-- the engine resets audio flags continuously.
-- DistantCopCarSirens(false) = suppress sirens, (true) = enable them.
-- =========================
CreateThread(function()
    while true do
        if not ambientCopsEnabled then
            DistantCopCarSirens(false)
            SetAudioFlag("PoliceScannerDisabled", true)
        end
        Wait(0)
    end
end)

-- =========================
-- Profiles / State
-- Priority order (highest to lowest):
--   1. manualOverride  — set via SetDensity export
--   2. forcedProfile   — set via SetProfile export, crowd scaling, or server event
--   3. baseProfile     — set automatically by zone detection
-- =========================
local baseProfileName   = "default"
local forcedProfileName = nil
local manualOverride    = nil
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
    if manualOverride    then return manualOverride end
    if forcedProfileName then
        local p = cfg.profiles[forcedProfileName]
        if p then return p end
    end
    return active
end

-- Exports for use by other resources
local function setDensity(typeName, value)
    value = clamp01(value)
    manualOverride = manualOverride or clone(getFinalDensity())
    local valid = { parked=true, vehicle=true, randomvehicles=true, peds=true, scenario=true }
    if valid[typeName] then manualOverride[typeName] = value end
end
exports('SetDensity', setDensity)

local function setProfile(profileName)
    if cfg.profiles[profileName] then
        manualOverride    = nil
        forcedProfileName = profileName
        logDebug(("Forced profile -> %s"):format(profileName))
        return true
    end
    return false
end
exports('SetProfile', setProfile)

local function clearOverrides()
    manualOverride    = nil
    forcedProfileName = nil
    logDebug("Overrides cleared")
end
exports('ClearOverrides', clearOverrides)

exports('ClearDensityOverride', function()
    manualOverride = nil
    logDebug("Manual density override cleared")
end)

-- Server-side broadcast support
-- Usage from a server script:
--   TriggerClientEvent('density_plus:setProfile', -1, 'low')
--   TriggerClientEvent('density_plus:clearOverrides', -1)
RegisterNetEvent('density_plus:setProfile', function(profileName)
    if cfg.profiles[profileName] then
        manualOverride    = nil
        forcedProfileName = profileName
        logDebug(("Server forced profile -> %s"):format(profileName))
    end
end)

RegisterNetEvent('density_plus:clearOverrides', function()
    manualOverride    = nil
    forcedProfileName = nil
    logDebug("Server cleared overrides")
end)

-- =========================
-- Zone detection
-- Iterates the zone list and returns the profile of the first matching zone.
-- List order acts as implicit priority — put more specific zones higher up.
-- =========================
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

-- =========================
-- Nearby player count (used by crowd scaling)
-- Capped at maxPlayerScan to avoid iterating through all 300+ players every check.
-- The scanned counter only increments for other players, not for self (PlayerId skip).
-- =========================
local function countNearbyPlayers(radius, ignoreDead)
    local myPed = PlayerPedId()
    if myPed == 0 or not DoesEntityExist(myPed) then return 0 end

    local myCoords = GetEntityCoords(myPed)
    local r2       = radius * radius
    local count    = 0
    local scanned  = 0
    local maxScan  = cfg.crowdScaling.maxPlayerScan or 60

    for _, pid in ipairs(GetActivePlayers()) do
        if scanned >= maxScan then break end
        if pid ~= PlayerId() then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and DoesEntityExist(ped) then
                if (not ignoreDead) or (not IsEntityDead(ped)) then
                    local c  = GetEntityCoords(ped)
                    local dx = myCoords.x - c.x
                    local dy = myCoords.y - c.y
                    local dz = myCoords.z - c.z
                    if (dx*dx + dy*dy + dz*dz) <= r2 then
                        count = count + 1
                    end
                end
            end
            scanned = scanned + 1
        end
    end

    return count
end

-- Returns the highest-priority threshold profile that matches nearbyPlayers, or nil.
local function chooseCrowdProfile(nearbyPlayers)
    local cs = cfg.crowdScaling
    if not cs or not cs.enabled then return nil end
    if not cs.thresholds         then return nil end

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
-- When the player is inside an interior, outdoor NPC spawning is irrelevant
-- so all multipliers are forced to 0 to save client CPU.
-- =========================
CreateThread(function()
    if cfg.relationshipFriendlyToPlayer then
        setupRelationships()
    end
    applyAmbientCopsState()

    while true do
        local ped        = PlayerPedId()
        local inInterior = ped ~= 0 and GetInteriorFromEntity(ped) ~= 0

        if inInterior then
            -- Inside a building — suppress all outdoor NPC spawning
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        else
            local d = getFinalDensity()
            SetParkedVehicleDensityMultiplierThisFrame(d.parked)
            SetVehicleDensityMultiplierThisFrame(d.vehicle)
            SetRandomVehicleDensityMultiplierThisFrame(d.randomvehicles)
            SetPedDensityMultiplierThisFrame(d.peds)
            SetScenarioPedDensityMultiplierThisFrame(d.scenario, d.scenario)
        end

        Wait(0)
    end
end)

-- =========================
-- Zone switching loop
-- Checks position every zoneCheckIntervalMs ms.
-- Skipped entirely when a forced profile or manual override is active.
-- =========================
CreateThread(function()
    applyProfile("default")

    while true do
        Wait(cfg.zoneCheckIntervalMs or 3000)

        if forcedProfileName or manualOverride then goto continue end

        local ped = PlayerPedId()
        if ped == 0 or not DoesEntityExist(ped) then goto continue end

        local coords = GetEntityCoords(ped)
        local profileName, zoneName = getZoneProfile(coords)

        if profileName ~= baseProfileName then
            applyProfile(profileName)
            if zoneName then logDebug(("Zone -> %s (%s)"):format(zoneName, profileName)) end
        end

        ::continue::
    end
end)

-- =========================
-- Crowd scaling loop
-- Counts nearby players and forces a lower-density profile when thresholds are met.
-- Releases the crowd profile automatically when players disperse.
-- Skipped when a forced profile or manual override is active.
-- =========================
CreateThread(function()
    local cs = cfg.crowdScaling
    if not cs or not cs.enabled then return end

    local lastCrowdProfile = nil

    while true do
        Wait(cs.intervalMs or 4000)

        if forcedProfileName or manualOverride then goto continue end

        local nearby       = countNearbyPlayers(cs.radius or 120.0, cs.ignoreDead ~= false)
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

-- /densityprofile [name]
-- No argument: prints current state (base, forced, override, cops).
-- With argument: forces a profile by name.
RegisterCommand('densityprofile', function(_, args)
    local p = (args[1] or ""):lower()
    if p == "" then
        print(("[density_plus] base=%s forced=%s override=%s cops=%s"):format(
            baseProfileName,
            forcedProfileName or "none",
            manualOverride and "yes" or "no",
            ambientCopsEnabled and "on" or "off"
        ))
        return
    end
    if cfg.profiles[p] then
        manualOverride    = nil
        forcedProfileName = p
        print(("[density_plus] forced profile -> %s"):format(p))
    else
        local opts = {}
        for k in pairs(cfg.profiles) do opts[#opts+1] = k end
        print(("[density_plus] unknown profile. Options: %s"):format(table.concat(opts, " / ")))
    end
end, false)

-- /densityclear — remove all overrides and return to automatic zone + crowd scaling
RegisterCommand('densityclear', function()
    clearOverrides()
    print("[density_plus] overrides cleared (back to zone + crowd scaling)")
end, false)

-- /densitydebug — print the exact multiplier values currently being applied each frame
RegisterCommand('densitydebug', function()
    local d = getFinalDensity()
    print(("[density_plus] parked=%.2f veh=%.2f rand=%.2f peds=%.2f scen=%.2f | profile=%s"):format(
        d.parked, d.vehicle, d.randomvehicles, d.peds, d.scenario,
        forcedProfileName or baseProfileName
    ))
end, false)
