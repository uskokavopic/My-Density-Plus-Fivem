return {
    debug = false,

    -- Set all ambient gang/cop groups as non-hostile toward the player
    relationshipFriendlyToPlayer = true,

    -- =========================
    -- Density profiles (0.0 – 1.0)
    -- These values are tuned for a 300+ player OneSync Infinity server.
    -- The engine spawns NPC traffic and peds on top of real players and their
    -- vehicles, so high values (1.0) cause serious CPU load at scale.
    -- =========================
    profiles = {
        -- General areas outside any named zone
        default = {
            parked         = 0.10,
            vehicle        = 0.20,
            randomvehicles = 0.08,
            peds           = 0.15,
            scenario       = 0.08,
        },

        -- High-density city hotspots (Legion Square, MRPD, Pillbox Hospital)
        city = {
            parked         = 0.05,
            vehicle        = 0.12,
            randomvehicles = 0.06,
            peds           = 0.08,
            scenario       = 0.03,
        },

        -- Highways: more vehicle traffic, almost no pedestrians
        highway = {
            parked         = 0.05,
            vehicle        = 0.30,
            randomvehicles = 0.22,
            peds           = 0.03,
            scenario       = 0.01,
        },

        -- Gang zones: slightly more street life without triggering hostile NPCs
        -- Previously 1.0/1.0 — gang NPCs attacked players and blocked RP actions
        gang = {
            parked         = 0.08,
            vehicle        = 0.12,
            randomvehicles = 0.08,
            peds           = 0.18,
            scenario       = 0.10,
        },

        -- Rural / outskirts areas (Sandy Shores, Paleto Bay)
        rural = {
            parked         = 0.05,
            vehicle        = 0.15,
            randomvehicles = 0.10,
            peds           = 0.05,
            scenario       = 0.03,
        },

        -- Emergency performance mode — triggered by crowd scaling or manually
        low = {
            parked         = 0.05,
            vehicle        = 0.06,
            randomvehicles = 0.03,
            peds           = 0.03,
            scenario       = 0.00,
        },

        -- Full suppression — use for cutscenes, events, or critical server load
        off = {
            parked         = 0.0,
            vehicle        = 0.0,
            randomvehicles = 0.0,
            peds           = 0.0,
            scenario       = 0.0,
        },
    },

    -- =========================
    -- Zone definitions
    -- Each zone switches to the named profile when the player enters its radius.
    -- Zones are checked top-to-bottom; the first match wins (implicit priority).
    -- Radii reduced from 420 m to 200–220 m to prevent profile flickering in
    -- overlapping areas between Legion, MRPD, and Pillbox.
    -- =========================
    zones = {
        -- City hotspots
        { name = "legion",  profile = "city",    x = 215.76,  y = -925.73,  z = 30.69, r = 220.0 },
        { name = "mrpd",    profile = "city",    x = 440.84,  y = -981.14,  z = 30.69, r = 200.0 },
        { name = "pillbox", profile = "city",    x = 307.70,  y = -1433.40, z = 29.90, r = 200.0 },

        -- Gang areas (adjust coords/radii to match your MLOs)
        { name = "grove",     profile = "gang", x = 105.0,  y = -1930.0, z = 20.0, r = 200.0 },
        { name = "ballas",    profile = "gang", x = 80.0,   y = -1960.0, z = 20.0, r = 200.0 },
        { name = "vagos",     profile = "gang", x = 330.0,  y = -2030.0, z = 21.0, r = 220.0 },
        { name = "marabunta", profile = "gang", x = 1200.0, y = -1600.0, z = 50.0, r = 220.0 },

        -- Rural towns
        { name = "sandy",   profile = "rural",   x = 1850.0, y = 3700.0, z = 34.0, r = 500.0 },
        { name = "paleto",  profile = "rural",   x = -120.0, y = 6400.0, z = 31.0, r = 500.0 },

        -- Highway corridor
        { name = "highway", profile = "highway", x = 1100.0, y = 2700.0, z = 40.0, r = 900.0 },
    },

    -- How often (ms) to check which zone the player is in.
    -- 3000 ms is sufficient; checking more often wastes CPU with no benefit.
    zoneCheckIntervalMs = 3000,

    -- =========================
    -- Crowd scaling
    -- Automatically reduces density when many players are nearby.
    -- Thresholds are tuned for 300+ player servers — on large servers a crowd of
    -- 18 players (the old default) is completely normal, not an emergency.
    -- =========================
    crowdScaling = {
        enabled    = true,
        radius     = 120.0,   -- Distance (meters) to scan for nearby players
        intervalMs = 4000,    -- How often to re-count nearby players (ms)
        thresholds = {
            { minPlayers = 45, profile = "low"  }, -- Heavy crowd → emergency mode
            { minPlayers = 25, profile = "city" }, -- Moderate crowd → city mode
        },
        ignoreDead    = true, -- Do not count dead players toward the threshold
        maxPlayerScan = 60,   -- Max players to iterate per check (performance cap)
    },

    -- =========================
    -- Ambient cops
    -- Disabled by default — typical for RP servers (less chaos, better performance).
    -- All sub-options below only take effect when enabled = true/false is toggled.
    -- =========================
    ambientCops = {
        enabled = false,

        disableDispatch         = true, -- Disable GTA dispatch services (police, swat, heli, etc.)
        disableRandomCops       = true, -- Stop random cop peds from spawning on foot / scenarios
        suppressCopPeds         = true, -- Suppress police ped models from the population pool
        suppressCopVehicles     = true, -- Suppress police vehicle models from traffic
        disablePoliceScenarios  = true, -- Disable police roadblock and patrol scenarios

        disablePoliceScannerAudio = true, -- Silence the police scanner audio flag
    },
}
