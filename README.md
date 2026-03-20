# 🚦 density_plus

> **Population density management for FiveM — built from the ground up for OneSync Infinity servers with 300+ players.**

Automatically controls NPC vehicle and pedestrian density based on location zones, nearby player count, and server-side events. Keeps large RP servers fast and clean without killing the ambient atmosphere.

---

## ✨ Features

- ✅ **Zone-based profiles** — different density per area (city, gang zone, highway, rural, etc.)
- ✅ **Crowd scaling** — auto-reduces density when many real players are nearby
- ✅ **Ambient cops toggle** — full suppression of NPC police: peds, vehicles, dispatch, scenarios, sirens, scanner audio
- ✅ **Interior detection** — outdoor NPC spawning cut to zero when inside a building
- ✅ **Server broadcast** — force profiles on all clients from a server script
- ✅ **Export API** — control density from any other resource
- ✅ **Performance-capped player scan** — `GetActivePlayers()` capped at 60 entries, never iterates 300+ per tick
- ✅ **Zero server CPU cost** — fully client-side, no server script required

---

## 📋 Requirements

| Dependency | Version |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | latest |
| FiveM OneSync | `infinity` |
| FXServer | latest recommended |

---

## 📦 Installation

1. Drop the `density_plus` folder into your `resources` directory
2. Add `ensure density_plus` to your `server.cfg`
3. Tune `config.lua` to match your server's player count and map layout
4. Restart the server

> 💡 **No server-side script needed.** Everything runs client-side. A server script is only needed if you want to use the broadcast events.

---

## ⚙️ Configuration

All settings live in `config.lua`. Heavily commented — below is a summary of each section.

### Density profiles

Each profile is a named table with five multipliers (`0.0 – 1.0`):

```lua
city = {
    parked         = 0.05,  -- parked cars alongside the road
    vehicle        = 0.12,  -- moving traffic
    randomvehicles = 0.06,  -- extra random vehicles added to traffic
    peds           = 0.08,  -- pedestrians on foot
    scenario       = 0.03,  -- scenario peds (sitting, busking, etc.)
}
```

Built-in profiles:

| Profile | Purpose |
|---|---|
| `default` | General areas outside any named zone |
| `city` | Dense city hotspots — Legion Square, MRPD, Pillbox |
| `highway` | Roads and motorways — more vehicles, fewer peds |
| `gang` | Gang territory — slightly more street life |
| `rural` | Sandy Shores, Paleto Bay, outskirts |
| `low` | Emergency performance mode |
| `off` | Full suppression — events, cutscenes, critical load |

> 💡 You can add as many custom profiles as you need.

---

### Zones

Zones are spherical areas defined by a centre coordinate and radius. When a player enters a zone, its profile activates automatically.

```lua
{ name = "legion", profile = "city", x = 215.76, y = -925.73, z = 30.69, r = 220.0 }
```

> ⚠️ Zones are checked **top-to-bottom** — the first match wins. Put smaller / more specific zones higher in the list than large ones.

---

### Crowd scaling

Automatically forces a lower-density profile when many players are nearby.

```lua
crowdScaling = {
    enabled    = true,
    radius     = 120.0,    -- metres to scan for nearby players
    intervalMs = 4000,     -- how often to re-check (ms)
    thresholds = {
        { minPlayers = 45, profile = "low"  },
        { minPlayers = 25, profile = "city" },
    },
    maxPlayerScan = 60,    -- cap on GetActivePlayers() iteration
}
```

> 💡 **Tip for 300+ servers:** 20–30 players in the city is normal daily traffic, not an emergency. Only trigger `low` for genuinely dense situations like events or shootouts.

---

### Ambient cops

Full suppression of NPC law enforcement. Each option is independent.

```lua
ambientCops = {
    enabled                   = false, -- ← master switch
    disableDispatch           = true,  -- GTA dispatch (cops, swat, heli)
    disableRandomCops         = true,  -- random cop peds on foot / scenarios
    suppressCopPeds           = true,  -- police ped models from population pool
    suppressCopVehicles       = true,  -- police vehicles from traffic
    disablePoliceScenarios    = true,  -- roadblocks, patrol scenarios
    disablePoliceScannerAudio = true,  -- police scanner audio
}
```

> ✅ Siren suppression (`DistantCopCarSirens`) runs in a **per-frame loop** — not a one-shot call. The GTA engine resets audio flags every frame, so a loop is required to prevent sirens from bleeding back in.

---

## 💻 Commands

| Command | Description |
|---|---|
| `/densityprofile` | Print current state (base, forced, overrides, cops) |
| `/densityprofile [name]` | Force a profile by name |
| `/densityclear` | Remove all overrides, return to zone + crowd scaling |
| `/densitydebug` | Print exact multiplier values applied this frame |
| `/cops on\|off` | Toggle ambient NPC police |

---

## 🔌 Export API

Control density from any other resource:

```lua
-- Force a single multiplier
exports.density_plus:SetDensity('peds', 0.05)
exports.density_plus:SetDensity('vehicle', 0.10)

-- Force an entire profile
exports.density_plus:SetProfile('low')

-- Clear all overrides (returns to zone + crowd scaling)
exports.density_plus:ClearOverrides()

-- Clear only the manual SetDensity override
exports.density_plus:ClearDensityOverride()

-- Toggle ambient cops
exports.density_plus:SetAmbientCops(false)
```

Valid keys for `SetDensity`: `parked` · `vehicle` · `randomvehicles` · `peds` · `scenario`

---

## 📡 Server broadcast events

Force a profile change on **all clients** from a server script:

```lua
-- Force all clients to 'low'
TriggerClientEvent('density_plus:setProfile', -1, 'low')

-- Release the forced profile on all clients
TriggerClientEvent('density_plus:clearOverrides', -1)
```

> 💡 Useful for server-wide events, shootout zones, scheduled restarts, or admin intervention.

---

## 🔺 Override priority

When multiple systems set density simultaneously, the highest priority wins:

```
1. 🥇 Manual override    →  SetDensity export
2. 🥈 Forced profile     →  SetProfile / crowd scaling / server event
3. 🥉 Base profile       →  automatic zone detection
```

---

## ⚡ OneSync Infinity compatibility

density_plus is built **specifically** for OneSync Infinity. Here is why every design decision is correct for large servers.

### Why standard GTA density values break on 300+ servers

Under OneSync Infinity, **all entities across the entire map are networked server-wide** at all times — unlike legacy FiveM which only synced a local bubble. This means:

- 🚨 Every NPC vehicle and pedestrian is a networked entity the server must track
- 🚨 GTA's default density (`1.0`) was designed for singleplayer, not a 300-player world
- 🚨 Full density × 300 clients = entity cap hit fast → server lag, client frame drops

density_plus solves this with coordinated low-footprint profiles across all clients.

### Why client-side natives are the correct approach

All density multiplier natives are **client-side only** — no server entity spawning, no entity cap risk from this resource. The `Wait(0)` loop is required because the GTA engine resets multipliers every frame.

### GetActivePlayers() cap

Under OneSync Infinity, `GetActivePlayers()` returns **all players on the server** — not a local bubble. Without a cap, crowd scaling would call `GetEntityCoords()` on every one of 300+ players every 4 seconds per client. `maxPlayerScan = 60` prevents this.

### Summary

| OneSync concern | How density_plus handles it |
|---|---|
| All entities networked server-wide | Low multipliers control total NPC entity count |
| `GetActivePlayers()` returns entire server | `maxPlayerScan = 60` caps iteration |
| Multipliers reset every frame by engine | `Wait(0)` loop applies them every single frame |
| Entity cap shared with player vehicles | Low density leaves headroom for player entities |
| Server CPU cost | ✅ Zero — no server script, no server tick |

---

## 📊 Performance notes

| Concern | Solution |
|---|---|
| 300+ player iteration | `maxPlayerScan = 60` — never scans full list |
| Density loop overhead | `Wait(0)` is required — engine mandates per-frame application |
| Zone check frequency | 3000 ms — more frequent = wasted CPU, zero benefit |
| Crowd scaling frequency | 4000 ms — responsive without hammering native calls |
| Player in interior | All outdoor multipliers → `0.0` — zero NPC spawn budget wasted |

---

## 🗺️ Profile override flow

```
Player enters zone
        │
        ▼
Zone profile set as base
        │
        ▼
Crowd scaling check (every 4s)
  ├─ 45+ players nearby  →  forcedProfile = "low"
  ├─ 25+ players nearby  →  forcedProfile = "city"
  └─ Players dispersed   →  forcedProfile = nil
        │
        ▼
External resource calls SetProfile / SetDensity?
  └─ Overrides zone and crowd scaling
        │
        ▼
Server triggers density_plus:setProfile?
  └─ Overrides everything except manual SetDensity
        │
        ▼
✅ Final density applied every frame
```

---

## 📄 License

MIT — free to use, modify, and redistribute. Credit appreciated but not required.
