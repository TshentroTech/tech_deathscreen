Config = {}

-- Debug Configuration
Config.Debug = false -- Enable/disable all debug logs and console output

-- Death System Configuration
Config.DeathTime = 500 -- Death time in seconds (5 minutes)
Config.EnableLastStand = true -- Enable last stand before death
Config.LastStandTime = 60 -- Last stand time in seconds

-- Heart Monitor Settings
Config.HeartRate = {
    normal = 80,
    dying = 120,
    critical = 40,
    flatline = 0
}

-- Voice and Chat Settings
Config.DisableVoice = true -- Disable voice when dead
Config.DisableChat = true -- Disable chat when dead
Config.AllowEmergencyChat = true -- Allow emergency services chat

-- Emergency Services
Config.EmergencyJobs = {
    'ambulance',
    'doctor',
    'ems'
}

-- Emergency Services Configuration
Config.EmergencyServices = {
    cooldownTime = 30, -- Cooldown time in seconds before emergency services can be called again
    enableCooldown = true -- Enable cooldown system for emergency services
}

-- Blacksmith Integration
Config.BlacksmithRevive = {
    enabled = true,
    item = 'revive_kit',
    price = 5000,
    job = 'blacksmith'
}

-- Secret Messages
Config.SecretMessages = {
    "The shadows whisper of ancient secrets...",
    "Only the worthy shall rise again...",
    "Death is but a doorway to power...",
    "The blacksmith holds the key to resurrection..."
}

-- Death Reasons
Config.DeathReasons = {
    ['WEAPON_UNARMED'] = 'beaten to death',
    ['WEAPON_PISTOL'] = 'shot with a pistol',
    ['WEAPON_CARBINERIFLE'] = 'shot with a rifle',
    ['VEHICLE'] = 'vehicle collision',
    ['FALL'] = 'fatal fall',
    ['DROWNING'] = 'drowned',
    ['EXPLOSION'] = 'explosion',
    ['FIRE'] = 'burned alive'
}

-- UI Settings
Config.UI = {
    heartbeatVolume = 0.3,
    animationSpeed = 2000,
    secretMessageDelay = 10000, -- 10 seconds before secret message appears
    pulseIntensity = 0.8,
    hospitalButtonDelay = 120, -- Time in seconds before hospital button becomes available
    showCursor = true, -- Show cursor when death screen is active
    enableSounds = true, -- Enable heartbeat sounds
    enableAnimations = true -- Enable UI animations
}

-- Hospital Configuration
Config.Hospital = {
    respawnTime = 300, -- Time in seconds before auto respawn (5 minutes)
    buttonDelay = 120, -- Time in seconds before hospital button becomes available (2 minutes)
    autoRespawn = true -- Enable automatic respawn after respawnTime
}

-- Auto Respawn Settings
Config.AutoRespawn = {
    enabled = true,
    cost = 5000,
    requireMoney = true,
    forceAfterTime = 360 -- Force respawn after 6 minutes (extra safety)
}

-- Death Camera Configuration
Config.DeathCamera = {
    enabled = true, -- Enable automatic death camera system
    height = 12.0, -- Height above player for camera (increased for better drone view)
    distance = 3.0, -- Distance from player for camera movement (closer to see body clearly)
    rotationSpeed = 0.2, -- Speed of camera rotation around player (smooth drone circling)
    bobbingSpeed = 4000, -- Speed of vertical bobbing effect (slower for stability)
    swayingSpeed = 6000, -- Speed of horizontal swaying effect (slower for stability)
    distanceChangeSpeed = 8000 -- Speed of distance change effect (slower for stability)
}

-- Discord Webhook Configuration
Config.Discord = {
    enabled = true, -- Enable Discord webhook logging
    webhookUrl = "Your Discord webhook URL", -- Your Discord webhook URL (leave empty to disable)
    botName = "Death Screen Logger", -- Bot name for webhook messages
    botAvatar = "", -- Bot avatar URL (optional)
    logDeaths = true, -- Log player deaths
    logEmergencyCalls = true, -- Log emergency service calls
    logHospitalRespawns = true, -- Log hospital respawns
    logRevives = true -- Log player revives
}
