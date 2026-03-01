# my_density_plus

Optimized population density management for **FiveM** (focused on **OneSync Infinity** + high player count servers).

✅ This resource **does not spawn** NPCs or vehicles.  
It only **controls GTA ambient population** using native density multipliers → lightweight, stable, and low overhead.

---

## ✅ Features

### 🤝 Calm AI (Relationships)
- Calms gangs / emergency peds toward the player
- Reduces random aggression and unwanted fights
- Cleaner RP experience (fewer random shootouts, fewer “chaos” encounters)

### 🚦 Density Control (Ambient Population)
Controls GTA ambient multipliers:
- Ped density
- Vehicle density
- Random vehicle density
- Parked vehicle density
- Scenario ped density

### 🗺️ Zone Profiles (Hotspot system)
Automatically switches density profiles based on player location.

Includes example zones:
- Legion Square
- MRPD
- Pillbox Hospital
- Sandy Shores
- Paleto Bay
- Highway corridor

### 👥 Crowd Scaling / Auto-FPS Mode
Automatically lowers densities when many players are near you.

Example logic:
- **10+ players nearby** → switches to `city` profile
- **18+ players nearby** → switches to `low` profile

Great for:
- events
- PD / hospital crowds
- city hotspots
- large RP scenes

### 🧱 Streamed YMAP support
Supports `.ymap` files in `stream/` for:
- disabling car generators (NoPixel-style optimization)
- reducing ambient traffic load
- improving city performance

### ⚡ OAL natives optimization (FXv2)
Enabled in `fxmanifest.lua`:

```lua
use_experimental_fxv2_oal 'yes'