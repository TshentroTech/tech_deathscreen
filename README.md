## [Download the latest version V3.0.0](https://github.com/TshentroTech/tech_deathscreen/releases/tag/V3.0.0)
## 🤝 **SUPPORT**

- 💬 **Discord**: https://discord.gg/DWdM4h7xbj
- 🛒 **Store**: [TshentroTech.tebex.io](https://tshentrotech-store.tebex.io/package/6981985)
- 📚 **Documentation**: Full setup guides available soon


# 🎮 Tech DeathScreen v3.0.0

[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue.svg)](https://fivem.net/)
[![QBCore](https://img.shields.io/badge/QBCore-Framework-green.svg)](https://github.com/qbcore-framework)
[![Version](https://img.shields.io/badge/Version-2.1.0-orange.svg)](https://github.com/TshentroTech/tech_deathscreen/releases)

> **Professional death screen system with dramatic heartbeat progression, drone-style camera, and enterprise-level security for FiveM QBCore servers.**

---

## 🚀 **MAJOR UPDATE v3.0.0 - COMPLETE OVERHAUL**

### **✨ What's New**
- 🫀 **Automatic Dramatic Heartbeat System** - Progressive BPM with medical-grade ECG
- 📹 **Enhanced Drone-Style Death Camera** - Smooth aerial cinematics  
- 🔒 **OWASP Top 10 Security Compliance** - Enterprise-grade protection
- ⚡ **High-Performance Optimization** - Supports 60+ concurrent players
- 🧹 **Professional Debug System** - Clean, organized logging
- 🎨 **Enhanced Visual Effects** - Critical state animations and transitions

---

## 🎯 **KEY FEATURES**

### **🫀 Dramatic Heartbeat System**
```
Phase 1: Death → 0 BPM (Flatline)
Phase 2: 3 seconds → Gradual increase to 60 BPM (2 minutes)
Phase 3: Time-based → Accelerates to 180 BPM as death timer expires
Final: Last 30 seconds → Maximum intensity with visual effects
```

- **Medical-Grade ECG**: Realistic P, QRS, T wave patterns
- **Audio Synchronization**: Perfect BPM-matched heartbeat sounds
- **Visual States**: Normal, Critical, Final countdown animations
- **Automatic Progression**: No manual intervention required

### **📹 Professional Death Camera**
- **Drone-Style Movement**: Smooth circling above player's body
- **Configurable Settings**: Height, distance, rotation speed
- **Smart Activation**: Only when enabled, complete cleanup when disabled
- **Cinematic Quality**: Professional aerial death scene capture

### **🔒 Enterprise Security (OWASP Top 10)**


### **⚡ High Performance**
- **128+ Player Support**: Optimized for large servers

---

## 📦 **INSTALLATION**

1. **Download** the latest release
2. **Extract** to your `resources` folder
3. **Add** to your `server.cfg`: `ensure tech_deathscreen`
4. **Restart** your server
5. **Configure** settings in `config.lua`

---

## ⚙️ **CONFIGURATION**

### **Basic Settings**
```lua
-- Debug Configuration
Config.Debug = false -- Enable/disable all debug logs

-- Death System
Config.DeathTime = 500 -- Death time in seconds
Config.EnableLastStand = true

-- Death Camera
Config.DeathCamera = {
    enabled = true,        -- Enable automatic death camera
    height = 12.0,         -- Height above player (drone view)
    distance = 3.0,        -- Distance from player
    rotationSpeed = 0.2,   -- Rotation speed (smooth circling)
    bobbingSpeed = 4000,   -- Vertical movement speed
    swayingSpeed = 6000,   -- Horizontal movement speed
}
```

### **Heart Rate System**
```lua
Config.HeartRate = {
    initial = 0,      -- Starting BPM (flatline)
    normal = 60,      -- Normal BPM after stabilization
    dying = 80,       -- Elevated BPM when dying
    critical = 120,   -- High BPM in critical state
    final = 180,      -- Maximum BPM during final countdown
}

Config.HeartbeatTiming = {
    initialDelay = 3000,        -- Delay before first heartbeat (3s)
    stabilizationTime = 120000, -- Time to reach normal BPM (2 min)
    criticalThreshold = 60,     -- Seconds when critical state begins
    finalThreshold = 30,        -- Seconds when final state begins
}
```

---

## 🔧 **API & EXPORTS**

### **Death Screen Control**
```lua
exports['tech_deathscreen']:ShowDeathScreen()
exports['tech_deathscreen']:HideDeathScreen()
exports['tech_deathscreen']:IsDead()
exports['tech_deathscreen']:RevivePlayer()
```

### **Heartbeat Control**
```lua
exports['tech_deathscreen']:UpdateHeartRate(rate)
exports['tech_deathscreen']:StartHeartbeat()
exports['tech_deathscreen']:StopHeartbeat()
exports['tech_deathscreen']:GetCurrentHeartRate()
```

### **Death Camera Control**
```lua
exports['tech_deathscreen']:StartDeathCam()
exports['tech_deathscreen']:StopDeathCam()
exports['tech_deathscreen']:IsDeathCamActive()
```

---

## 🛡️ **SECURITY FEATURES**

### **OWASP Top 10 Compliance**

### **Rate Limiting System**
```lua
Max Requests: 30 per minute per player
Emergency Calls: 5 per minute per player
Button Clicks: 1 second cooldown
Memory Cleanup: Every 5 minutes
```

---

## 📊 **PERFORMANCE**

### **Optimization Results**

### **Technical Specifications**

---

## 🎬 **VISUAL SHOWCASE**

### **Death Screen Phases**

**Phase 1: Death Moment**
- Immediate death screen activation, Flatline ECG (0 BPM), Drone camera starts

**Phase 2: Stabilization (2 minutes)**  
- Gradual heartbeat increase, ECG shows activity, Heart rate: 0 → 60 BPM

**Phase 3: Normal State**
- Steady 60 BPM heartbeat, Regular ECG patterns, Standard visual effects

**Phase 4: Critical State (Final 60 seconds)**
- Heart rate increases to 120 BPM, Enhanced visual effects, Red pulsing intensifies

**Phase 5: Final Countdown (Last 30 seconds)**
- Maximum heart rate (180 BPM), Intense screen effects, ECG line blinking

### **Camera Features**
- **Aerial View**: Professional drone-style perspective
- **Smooth Movement**: Gentle rotation around body
- **Cinematic Quality**: Movie-like death scene capture
- **Dynamic Positioning**: Height and distance variation

---

## 🏆 **CHANGELOG**

### **v3.0.0 - Major Overhaul**
- ✅ Added automatic dramatic heartbeat system with medical-grade ECG
- ✅ Enhanced drone-style death camera with smooth aerial movement
- ✅ Implemented OWASP Top 10 security compliance (all vulnerabilities addressed)
- ✅ Optimized for 60+ player servers with 40% memory reduction
- ✅ Added professional debug system controlled by Config.Debug
- ✅ Enhanced visual effects with critical state animations
- ✅ Hardcoded security settings for consistent protection
- ✅ Complete code cleanup and organization
- ✅ Smart revive system with immediate response vs delayed protection
- ✅ Comprehensive rate limiting and input validation
- ✅ Automatic memory cleanup and garbage collection

### **Key Technical Improvements**
- **Security**: Rate limiting, input sanitization, memory management
- **Performance**: Pre-filtering, smart threading, optimized updates
- **User Experience**: Progressive heartbeat, cinematic camera, visual effects
- **Code Quality**: Clean debug system, organized structure, professional logging

---

## 🤝 **SUPPORT**

- 💬 **Discord**: https://discord.gg/DWdM4h7xbj
- 🛒 **Store**: [TshentroTech.tebex.io](https://tshentrotech-store.tebex.io/package/6981985)
- 📚 **Documentation**: Full setup guides available soon

---

## 📄 **LICENSE**

Custom License - © 2025 TshentroTech. All rights reserved.

---

**Thank you for choosing Tech DeathScreen! 🚀**

*Experience the most professional death screen system available for FiveM QBCore servers.*

