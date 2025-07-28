# Deathscreen

A FiveM script that adds a custom death screen effect for players, including a heartbeat sound, visual effects, and a drone-style death camera.

## Features

- Custom death camera (drone-style)
- Heartbeat sound effect (`sounds/heartbeat.wav`)
- Stylish HTML/CSS/JS death screen overlay
- Emergency services and hospital respawn system
- Discord webhook logging (deaths, revives, emergency calls)
- Highly configurable via `config.lua`
- QBCore compatible

## Installation

1. Download or clone this repository.
2. Place the `deathscreen` folder in your server's `resources` directory.
3. Add the following line to your `server.cfg`:
   ```
   ensure deathscreen
   ```
4. (Optional) Edit `config.lua` to customize settings.

## Usage

The script will automatically activate when a player dies, showing the custom death screen, playing the heartbeat sound, and enabling respawn options after a delay.

## File Structure

- `client/` - Client-side Lua scripts (main logic, death camera)
- `server/` - Server-side Lua scripts (event handling, revives, logging)
- `html/` - UI files (HTML, JS, CSS)
- `sounds/` - Heartbeat sound effect
- `config.lua` - Configuration file
- `fxmanifest.lua` - Resource manifest

## Requirements

- FiveM server (FXServer)
- QBCore framework
- No additional dependencies

## Support

If you encounter any issues, please open an issue or contact me on the Cfx.re forums.

---

| Code is accessible | Yes |
|--------------------|-----|
| Subscription-based | No  |
| Lines (approximate)| 2,735 |
| Requirements       | QBCore |
| Support            | Yes |

---

## Credits

- Script by tshentro.tech
- For more resources, visit [TshentroTech.tebex.io](https://TshentroTech.tebex.io) 