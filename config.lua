return {
    debug = false,

    -- Calm AI / gangs toward player
    relationshipFriendlyToPlayer = true,

    -- =========================
    -- Density profiles (0.0 - 1.0)
    -- =========================
    profiles = {
        default = {
            parked = 0.1,
            vehicle = 1.0,
            randomvehicles = 0.05,
            peds = 1.0,
            scenario = 1.0,
        },

        -- Hotspots: keep low for FPS stability
        city = {
            parked = 0.1,
            vehicle = 0.18,
            randomvehicles = 0.12,
            peds = 0.12,
            scenario = 0.04,
        },

        -- Highways: more cars, fewer peds
        highway = {
            parked = 0.1,
            vehicle = 0.45,
            randomvehicles = 0.35,
            peds = 0.06,
            scenario = 0.02,
        },

        -- ✅ Gang zones: more people on streets (selling weed vibe)
        gang = {
            parked = 0.1,
            vehicle = 0.18,
            randomvehicles = 0.12,
            peds = 1.0,
            scenario = 1.0,
        },

        -- Emergency performance mode
        low = {
            parked = 0.1,
            vehicle = 0.10,
            randomvehicles = 0.06,
            peds = 0.05,
            scenario = 0.00,
        },

        off = {
            parked = 0.1,
            vehicle = 0.0,
            randomvehicles = 0.0,
            peds = 0.0,
            scenario = 0.0,
        }
    },

    -- =========================
    -- Zone switching
    -- =========================
    zones = {
        -- City hotspots
        { name = "legion",  profile = "city",    x = 215.76,  y = -925.73, z = 30.69, r = 420.0 },
        { name = "mrpd",    profile = "city",    x = 440.84,  y = -981.14, z = 30.69, r = 420.0 },
        { name = "pillbox", profile = "city",    x = 307.70,  y = -1433.40,z = 29.90, r = 420.0 },

        -- Gang areas (edit these to your map / MLOs)
        { name = "grove",     profile = "gang", x = 105.0,  y = -1930.0, z = 20.0, r = 320.0 },   -- Families / Grove
        { name = "ballas",    profile = "gang", x = 80.0,   y = -1960.0, z = 20.0, r = 320.0 },   -- Ballas area-ish
        { name = "vagos",     profile = "gang", x = 330.0,  y = -2030.0, z = 21.0, r = 340.0 },   -- Rancho/Vagos-ish
        { name = "marabunta", profile = "gang", x = 1200.0, y = -1600.0, z = 50.0, r = 360.0 },   -- East LS-ish

        -- Sandy/Paleto
        { name = "sandy",   profile = "default", x = 1850.0,  y = 3700.0,  z = 34.0,  r = 650.0 },
        { name = "paleto",  profile = "default", x = -120.0,  y = 6400.0,  z = 31.0,  r = 650.0 },

        -- Highway
        { name = "highway", profile = "highway", x = 1100.0,  y = 2700.0,  z = 40.0,  r = 900.0 },
    },

    zoneCheckIntervalMs = 2000,

    -- =========================
    -- ✅ Crowd scaling (auto lower density when many players nearby)
    -- =========================
    crowdScaling = {
        enabled = true,
        radius = 140.0,
        intervalMs = 1500,
        thresholds = {
            { minPlayers = 18, profile = "low" },
            { minPlayers = 10, profile = "city" },
        },
        ignoreDead = true,
    },

    -- =========================
    -- ✅ Ambient cops toggle (NPC police + police vehicles)
    -- =========================
    ambientCops = {
        -- Default: vypnuté (typické pre RP, menej chaosu a lepší výkon)
        enabled = false,

        -- Disable GTA dispatch services (cops/heli/swats etc)
        disableDispatch = true,

        -- Disable random cops spawn (on foot / scenarios)
        disableRandomCops = true,

        -- Suppress police ped models
        suppressCopPeds = true,

        -- Suppress police vehicle models in traffic
        suppressCopVehicles = true,

        -- Disable common police scenario types (roadblocks etc)
        disablePoliceScenarios = true,
    }
}