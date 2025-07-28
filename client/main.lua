local QBCore = exports['qb-core']:GetCoreObject()

-- ========================================
-- SIMPLE DEATH SCREEN SYSTEM
-- ========================================
-- Shows/hides death screen based on IsEntityDead()
-- No complex revival logic - lets other scripts handle it
-- ========================================

-- Death screen variables
local deathScreenShown = false
local deathScreenEnabled = false
local hospitalButtonEnabled = false
local deathTimer = nil -- Timer for automatic hospital teleportation
local deathStartTime = 0 -- Track when death screen started
local emergencyCooldown = false -- Cooldown for emergency services button
local emergencyCooldownTime = Config.EmergencyServices.cooldownTime or 30 -- Cooldown time in seconds

-- Debug logging function
function DebugLog(message)
    if Config.Debug then
        print('[DEATHSCREEN] ' .. message)
    end
end

-- Helper function to force show death screen if needed
function ForceShowDeathScreen()
    if not deathScreenShown and IsEntityDead(PlayerPedId()) then
        DebugLog('Force showing death screen')
        ShowDeathScreen()
    end
end

-- Helper function to force reset death screen state
function ForceResetDeathScreenState()
    DebugLog('Force resetting death screen state')
    deathScreenShown = false
    hospitalButtonEnabled = false
    StopDeathCam()
    SetNuiFocus(false, false)
    
    -- Clear death timer
    if deathTimer then
        deathTimer = nil
    end
    
    -- Force hide in NUI
    SendNUIMessage({
        action = 'hideDeathScreen'
    })
    
    -- Force reset in NUI as well
    SendNUIMessage({
        action = 'forceResetDeathScreen'
    })
    
    DebugLog('Death screen state reset complete')
end

-- Function to start death timer
function StartDeathTimer()
    if deathTimer then
        DebugLog('Death timer already running')
        return
    end
    
    DebugLog('Starting death timer')
    deathStartTime = GetGameTimer()
    local deathTimeSeconds = Config.DeathTime or 300 -- 5 minutes default
    local hospitalButtonDelay = Config.UI.hospitalButtonDelay or 120 -- 2 minutes default
    
    -- Start timer that automatically sends to hospital after death time
    deathTimer = CreateThread(function()
        local elapsed = 0
        
        while deathScreenShown and elapsed < deathTimeSeconds do
            Wait(1000) -- Check every second
            elapsed = math.floor((GetGameTimer() - deathStartTime) / 1000)
            
            -- Update hospital countdown
            local hospitalCountdown = math.max(0, hospitalButtonDelay - elapsed)
            SendNUIMessage({
                action = 'updateHospitalCountdown',
                countdown = hospitalCountdown
            })
            
            -- Enable hospital button after delay
            if elapsed >= hospitalButtonDelay and not hospitalButtonEnabled then
                DebugLog('Enabling hospital button')
                hospitalButtonEnabled = true
                SendNUIMessage({
                    action = 'enableHospitalButton'
                })
            end
            
            -- Update timer in NUI
            local timeLeft = deathTimeSeconds - elapsed
            SendNUIMessage({
                action = 'updateTimer',
                time = timeLeft
            })
            
            -- Auto teleport to hospital when timer reaches 0
            if elapsed >= deathTimeSeconds then
                DebugLog('Death timer expired, auto teleporting to hospital')
                AutoTeleportToHospital()
                break
            end
        end
    end)
end

-- Function to get current time string
function GetCurrentTimeString()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    local second = GetClockSeconds()
    
    return string.format("2024-01-01 %02d:%02d:%02d", hour, minute, second)
end

-- Function to get current time for display
function GetCurrentTimeDisplay()
    local hour = GetClockHours()
    local minute = GetClockMinutes()
    local second = GetClockSeconds()
    
    return string.format("%02d:%02d:%02d", hour, minute, second)
end

-- Function to send Discord webhook
function SendDiscordWebhook(type, data)
    if not Config.Discord.enabled or Config.Discord.webhookUrl == "" then
        return
    end
    
    -- Ensure data is valid
    data = data or {}
    
    local embed = {
        title = "",
        description = "",
        color = 0,
        fields = {},
        footer = {
            text = "Death Screen Logger • " .. GetCurrentTimeString()
        }
    }
    
    local player = QBCore.Functions.GetPlayerData()
    local playerName = "Unknown"
    local playerId = "Unknown"
    
    if player then
        if player.charinfo and player.charinfo.firstname and player.charinfo.lastname then
            playerName = player.charinfo.firstname .. " " .. player.charinfo.lastname
        end
        if player.citizenid then
            playerId = player.citizenid
        end
    end
    
    if type == "death" then
        embed.title = "💀 Player Death"
        embed.color = 15158332 -- Red
        embed.description = "**" .. playerName .. "** has died"
        embed.fields = {
            {
                name = "👤 Player Info",
                value = "**Name:** " .. playerName .. "\n**ID:** " .. playerId .. "\n**Job:** " .. (player and player.job and player.job.label or "Unknown"),
                inline = true
            },
            {
                name = "📍 Location",
                value = "**Coords:** " .. (data.coords or "Unknown"),
                inline = true
            },
            {
                name = "⚰️ Death Info",
                value = "**Reason:** " .. (data.reason or "Unknown") .. "\n**Time:** " .. GetCurrentTimeDisplay(),
                inline = false
            }
        }
    elseif type == "emergency" then
        embed.title = "🚨 Emergency Call"
        embed.color = 16776960 -- Yellow
        embed.description = "**" .. playerName .. "** called emergency services"
        embed.fields = {
            {
                name = "👤 Player Info",
                value = "**Name:** " .. playerName .. "\n**ID:** " .. playerId,
                inline = true
            },
            {
                name = "📍 Location",
                value = "**Coords:** " .. (data.coords or "Unknown"),
                inline = true
            },
            {
                name = "⏰ Time",
                value = GetCurrentTimeDisplay(),
                inline = true
            }
        }
    elseif type == "hospital" then
        embed.title = "🏥 Hospital Respawn"
        embed.color = 3066993 -- Green
        embed.description = "**" .. playerName .. "** respawned at hospital"
        embed.fields = {
            {
                name = "👤 Player Info",
                value = "**Name:** " .. playerName .. "\n**ID:** " .. playerId,
                inline = true
            },
            {
                name = "⏰ Respawn Time",
                value = GetCurrentTimeDisplay(),
                inline = true
            },
            {
                name = "🔄 Type",
                value = data.type or "Manual",
                inline = true
            }
        }
    elseif type == "revive" then
        embed.title = "💊 Player Revived"
        embed.color = 3066993 -- Green
        embed.description = "**" .. playerName .. "** has been revived"
        embed.fields = {
            {
                name = "👤 Player Info",
                value = "**Name:** " .. playerName .. "\n**ID:** " .. playerId,
                inline = true
            },
            {
                name = "👨‍⚕️ Revived By",
                value = data.revivedBy or "Unknown",
                inline = true
            },
            {
                name = "⏰ Time",
                value = GetCurrentTimeDisplay(),
                inline = true
            }
        }
    end
    
    -- Ensure embed is valid before sending
    if embed.title and embed.description then
        TriggerServerEvent('qb-deathscreen:server:SendDiscordWebhook', type, embed)
    else
        DebugLog('[DISCORD] Invalid embed data, not sending webhook')
    end
end

-- Function to start emergency cooldown
function StartEmergencyCooldown()
    CreateThread(function()
        local timeRemaining = emergencyCooldownTime
        
        while emergencyCooldown and timeRemaining > 0 do
            Wait(1000) -- Wait 1 second
            timeRemaining = timeRemaining - 1
            
            -- Update NUI with cooldown status
            SendNUIMessage({
                action = 'updateEmergencyCooldown',
                cooldown = timeRemaining,
                active = true
            })
        end
        
        -- Cooldown finished
        emergencyCooldown = false
        
        -- Update NUI to show button is available again
        SendNUIMessage({
            action = 'updateEmergencyCooldown',
            cooldown = 0,
            active = false
        })
        
        QBCore.Functions.Notify('Emergency services are now available again.', 'success', 2000)
    end)
end

-- Function to auto teleport to hospital
function AutoTeleportToHospital()
    DebugLog('Auto teleporting to hospital using seat system')
    
    -- Stop death timer
    if deathTimer then
        deathTimer = nil
    end
    
    -- Hide death screen
    HideDeathScreen()
    
    -- Trigger hospital respawn (uses automatic seat system to nearest hospital)
    TriggerEvent('hospital:client:RespawnAtHospital')
    
    -- Send hospital respawn log to Discord
    if Config.Discord.logHospitalRespawns then
        SendDiscordWebhook("hospital", {
            type = "Automatic"
        })
    end
    
    -- Notify player
    QBCore.Functions.Notify('You have been automatically transported to the nearest hospital', 'primary', 5000)
end

-- Simple function to show death screen
function ShowDeathScreen()
    if deathScreenShown then 
        DebugLog('Death screen already shown, skipping')
        return 
    end
    
    DebugLog('Showing death screen (immediateDeathScreen=' .. tostring(immediateDeathScreen) .. ')')
    deathScreenShown = true
    hospitalButtonEnabled = false
    emergencyCooldown = true -- Enable emergency cooldown
    
    -- Start death camera
    StartDeathCam()
    
    -- Send death log to Discord
    if Config.Discord.logDeaths then
        local success, coords = pcall(function()
            local playerCoords = GetEntityCoords(PlayerPedId())
            return string.format("%.2f, %.2f, %.2f", playerCoords.x, playerCoords.y, playerCoords.z)
        end)
        
        if success then
            SendDiscordWebhook("death", {
                coords = coords,
                reason = "Player died"
            })
        else
            DebugLog('[DISCORD] Failed to get player coordinates for death log')
        end
    end
    
    -- Send NUI messages with more debug info
    DebugLog('Sending enableDeathScreen message')
    SendNUIMessage({
        action = 'enableDeathScreen'
    })
    
    DebugLog('Sending showDeathScreen message')
    SendNUIMessage({
        action = 'showDeathScreen',
        reason = 'You have died',
        timer = Config.DeathTime or 300,
        secretMessage = 'The shadows whisper...',
        hospitalButtonDelay = Config.UI.hospitalButtonDelay or 120
    })
    
    -- Also send separate message to set hospital button delay
    DebugLog('Sending hospital button delay: ' .. (Config.UI.hospitalButtonDelay or 120))
    SendNUIMessage({
        action = 'setHospitalButtonDelay',
        delay = Config.UI.hospitalButtonDelay or 120
    })
    
    SetNuiFocus(true, true)
    DebugLog('Death screen messages sent and NUI focus set')
    
    -- Force enable death screen in NUI
    deathScreenEnabled = true
    
    -- Start death timer
    StartDeathTimer()
    
    -- Send initial countdown update
    local hospitalButtonDelay = Config.UI.hospitalButtonDelay or 120
    SendNUIMessage({
        action = 'updateHospitalCountdown',
        countdown = hospitalButtonDelay
    })
    
    -- Prevent immediate hiding
    Wait(1000) -- Wait 1 second to prevent immediate hiding
end

-- RADICAL SOLUTION: Protected hide death screen function
function HideDeathScreen()
    DebugLog('HideDeathScreen called')
    
    -- RADICAL PROTECTION: Only allow hiding if player is actually alive
    local playerPed = PlayerPedId()
    if IsEntityDead(playerPed) then
        DebugLog('RADICAL PROTECTION: Player is still dead, preventing hide')
        return
    end
    
    -- Always ensure NUI focus is removed
    SetNuiFocus(false, false)
    
    if not deathScreenShown then 
        DebugLog('Death screen not shown, but ensured NUI focus removed')
        return 
    end
    
    DebugLog('Hiding death screen')
    deathScreenShown = false
    hospitalButtonEnabled = false
    emergencyCooldown = false -- Reset emergency cooldown
    
    -- Stop death timer
    if deathTimer then
        deathTimer = nil
    end
    
    -- Stop death camera
    StopDeathCam()
    
    -- Send only one message to hide death screen
    SendNUIMessage({
        action = 'hideDeathScreen'
    })
    
    -- Double ensure NUI focus is removed
    SetNuiFocus(false, false)
    DebugLog('Death screen hidden and NUI focus removed')
    
    -- Force disable death screen in NUI
    deathScreenEnabled = false
    
    -- Send revive event to other scripts (commented to avoid infinite loop)
    -- TriggerEvent('qb-deathscreen:client:onPlayerDeath', false)
end

-- Death System Events (from old version)
RegisterNetEvent('qb-deathscreen:client:OnPlayerDeath', function(reason)
    if deathScreenShown then return end
    
    DebugLog('Death event received with reason: ' .. reason)
    
    -- Show death screen with killer info
    ShowDeathScreenWithKiller()
    
    -- Disable player actions
    SetPlayerControl(PlayerId(), false, 0)
    SetPlayerInvincible(PlayerId(), true)
    
    -- Disable voice if configured
    if Config and Config.DisableVoice then
        exports['pma-voice']:SetMumbleProperty('radioEnabled', false)
        exports['pma-voice']:SetMumbleProperty('micClicks', false)
    end
    
    -- Notify server
    TriggerServerEvent('qb-deathscreen:server:OnPlayerDeath', reason)
end)

RegisterNetEvent('qb-deathscreen:client:RevivePlayer', function()
    if not deathScreenShown then return end
    
    DebugLog('Revive event received')
    RevivePlayer()
end)

-- Event-based death detection system (like the reference script)
RegisterNetEvent('qb-deathscreen:client:onPlayerDeath')
AddEventHandler('qb-deathscreen:client:onPlayerDeath', function(isDead)
    if isDead then
        DebugLog('Death event received, showing death screen')
        ShowDeathScreenWithKiller()
    else
        DebugLog('Revive event received, hiding death screen')
        HideDeathScreen()
    end
end)

-- RADICAL SOLUTION: Protected hospital revive events
RegisterNetEvent('hospital:client:Revive')
AddEventHandler('hospital:client:Revive', function()
    DebugLog('Hospital revive event received, checking if player is alive')
    local playerPed = PlayerPedId()
    if not IsEntityDead(playerPed) then
        DebugLog('Player confirmed alive, hiding death screen')
        HideDeathScreen()
    else
        DebugLog('RADICAL PROTECTION: Player still dead, keeping death screen')
    end
end)

RegisterNetEvent('hospital:client:RespawnAtHospital')
AddEventHandler('hospital:client:RespawnAtHospital', function()
    DebugLog('Hospital respawn event received, checking if player is alive')
    local playerPed = PlayerPedId()
    if not IsEntityDead(playerPed) then
        DebugLog('Player confirmed alive, hiding death screen')
        HideDeathScreen()
    else
        DebugLog('RADICAL PROTECTION: Player still dead, keeping death screen')
    end
end)

-- Function to show death screen with killer information
function ShowDeathScreenWithKiller()
    local killername = nil
    
    -- Get killer information
    local PedKiller = GetPedSourceOfDeath(PlayerPedId())
    local killerid = NetworkGetPlayerIndexFromPed(PedKiller)
    
    if IsEntityAVehicle(PedKiller) and IsEntityAPed(GetVehiclePedIsIn(PedKiller, -1)) and IsPedAPlayer(GetPedInVehicleSeat(PedKiller, -1)) then
        killerid = NetworkGetPlayerIndexFromPed(GetPedInVehicleSeat(PedKiller, -1))
    end
    
    if (killerid == -1) then
        killername = "Suicide"
    elseif (killerid == nil) then
        killername = "Unknown"
    elseif (killerid ~= -1) then
        killername = GetPlayerName(killerid)
    end
    
    DebugLog('Killer detected: ' .. killername)
    
    -- Show death screen
    ShowDeathScreen()
    
    -- Send killer information to NUI
    SendNUIMessage({
        action = 'setKillerInfo',
        killer = killername,
        timer = Config.DeathTime or 300,
        reason = 'You have been killed'
    })
    
    -- Send death event to other scripts (commented to avoid infinite loop)
    -- TriggerEvent('qb-deathscreen:client:onPlayerDeath', true)
end

-- Health Monitoring System (from old version)
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local health = GetEntityHealth(playerPed)
        
        -- Check QBCore player data for death states
        QBCore.Functions.GetPlayerData(function(PlayerData)
            if PlayerData.metadata and (PlayerData.metadata["inlaststand"] or PlayerData.metadata["isdead"]) then
                if not deathScreenShown then
                    DebugLog('QBCore metadata detected death state - inlaststand: ' .. tostring(PlayerData.metadata["inlaststand"]) .. ', isdead: ' .. tostring(PlayerData.metadata["isdead"]))
                    local killer, killerWeapon = NetworkGetEntityKillerOfPlayer(PlayerId())
                    local reason = killerWeapon or 'WEAPON_UNARMED'
                    
                    -- Show death screen with killer info
                    ShowDeathScreenWithKiller()
                    
                    -- Trigger death event for other scripts
                    TriggerEvent('qb-deathscreen:client:OnPlayerDeath', reason)
                end
            else
                -- Player is alive according to QBCore metadata
                if deathScreenShown then
                    DebugLog('QBCore metadata shows player is alive, hiding death screen')
                    HideDeathScreen()
                end
            end
        end)
        
        -- Also check entity health as backup
        if health <= 0 and not deathScreenShown then
            DebugLog('Health monitoring: Player died, showing death screen')
            local killer, killerWeapon = NetworkGetEntityKillerOfPlayer(PlayerId())
            local reason = killerWeapon or 'WEAPON_UNARMED'
            
            -- Show death screen with killer info
            ShowDeathScreenWithKiller()
            
            -- Trigger death event for other scripts
            TriggerEvent('qb-deathscreen:client:OnPlayerDeath', reason)
        end
        
        Wait(1000) -- Check every second
    end
end)

-- FALLBACK TIMER: Ensure timer always starts and hospital teleportation always works
CreateThread(function()
    while true do
        Wait(5000) -- Check every 5 seconds
        
        -- If death screen is shown but timer is not running, start it
        if deathScreenShown and not deathTimer and IsEntityDead(PlayerPedId()) then
            DebugLog('FALLBACK: Death screen shown but timer not running, starting timer')
            StartDeathTimer()
        end
        
        -- If death screen has been shown for more than 6 minutes (360 seconds), force hospital teleportation
        if deathScreenShown and deathStartTime > 0 then
            local elapsed = math.floor((GetGameTimer() - deathStartTime) / 1000)
            if elapsed > 360 then -- 6 minutes (1 minute extra buffer)
                DebugLog('FALLBACK: Death screen shown for over 6 minutes, forcing hospital teleportation using seat system')
                AutoTeleportToHospital()
            end
        end
    end
end)

-- RADICAL SOLUTION: NO AUTOMATIC HIDING - Death screen stays until manually hidden
-- CreateThread(function()
--     -- DISABLED: No automatic hiding of death screen
--     -- Death screen will only hide when player manually respawns or uses hospital
-- end)

-- NO REVIVAL EVENTS - Let other scripts handle revival
-- Death screen only shows/hides based on IsEntityDead()

-- NUI Callbacks (from old version)
RegisterNUICallback('respawn', function(data, cb)
    if Config and Config.BlacksmithRevive and Config.BlacksmithRevive.enabled then
        TriggerServerEvent('qb-deathscreen:server:AttemptRespawn')
    end
    cb('ok')
end)

RegisterNUICallback('callEmergency', function(data, cb)
    -- Check if emergency cooldown is enabled and active
    if Config.EmergencyServices.enableCooldown and emergencyCooldown then
        local remainingTime = emergencyCooldownTime
        QBCore.Functions.Notify('Emergency services are busy. Please wait ' .. remainingTime .. ' seconds before calling again.', 'error', 3000)
        cb('cooldown')
        return
    end
    
    -- Trigger emergency call
    TriggerServerEvent('qb-deathscreen:server:CallEmergency')
    QBCore.Functions.Notify('Emergency services have been notified!', 'primary')
    
    -- Send emergency log to Discord
    if Config.Discord.logEmergencyCalls then
        local success, coords = pcall(function()
            local playerCoords = GetEntityCoords(PlayerPedId())
            return string.format("%.2f, %.2f, %.2f", playerCoords.x, playerCoords.y, playerCoords.z)
        end)
        
        if success then
            SendDiscordWebhook("emergency", {
                coords = coords
            })
        else
            DebugLog('[DISCORD] Failed to get player coordinates for emergency log')
        end
    end
    
    -- Start cooldown if enabled
    if Config.EmergencyServices.enableCooldown then
        emergencyCooldown = true
        StartEmergencyCooldown()
    end
    
    cb('ok')
end)

RegisterNUICallback('hospitalRespawn', function(data, cb)
    DebugLog('Hospital respawn button clicked')
    DebugLog('Current state - deathScreenShown: ' .. tostring(deathScreenShown) .. ', hospitalButtonEnabled: ' .. tostring(hospitalButtonEnabled))
    
    -- Additional safety check
    if not deathScreenShown then
        DebugLog('WARNING: Hospital button clicked but death screen not shown')
        cb('error')
        return
    end
    
    if not hospitalButtonEnabled then
        DebugLog('WARNING: Hospital button clicked but not enabled')
        cb('error')
        return
    end
    
    -- Stop death timer
    if deathTimer then
        DebugLog('Stopping death timer')
        deathTimer = nil
    end
    
    -- Hide death screen first
    DebugLog('Hiding death screen')
    HideDeathScreen()
    
    -- Trigger hospital respawn (uses automatic seat system to nearest hospital)
    DebugLog('Triggering hospital respawn event')
    TriggerEvent('hospital:client:RespawnAtHospital')
    
    -- Send hospital respawn log to Discord
    if Config.Discord.logHospitalRespawns then
        SendDiscordWebhook("hospital", {
            type = "Manual"
        })
    end
    
    -- Notify player
    QBCore.Functions.Notify('You are being transported to the nearest hospital...', 'primary', 3000)
    
    DebugLog('Hospital respawn process completed')
    cb('ok')
end)

RegisterNUICallback('showCursor', function(data, cb)
    SetNuiFocus(true, true)
    cb('ok')
end)

RegisterNUICallback('hideCursor', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Event handler for player revival
RegisterNetEvent('hospital:client:Revive', function()
    if Config.Discord.logRevives then
        SendDiscordWebhook("revive", {
            revivedBy = "Medical Staff"
        })
    end
end)

-- Event handler for blacksmith revival
RegisterNetEvent('qb-deathscreen:client:Revived', function()
    if Config.Discord.logRevives then
        SendDiscordWebhook("revive", {
            revivedBy = "Blacksmith"
        })
    end
end)

-- Resource start - ensure clean state
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DebugLog('Resource started, ensuring clean state')
        Wait(1000) -- Wait for everything to load
        
        -- Send debug mode to NUI
        SendNUIMessage({
            action = 'setDebugMode',
            debug = Config.Debug
        })
        
        local playerPed = PlayerPedId()
        if IsEntityDead(playerPed) and not deathScreenShown then
            DebugLog('Resource started and player dead, showing death screen')
            ShowDeathScreenWithKiller()
        elseif not IsEntityDead(playerPed) and deathScreenShown then
            DebugLog('Resource started and player alive, hiding screen')
            HideDeathScreen()
        else
            DebugLog('Resource started, state is consistent')
        end
        
        -- Send death event to other scripts if player is dead
        if IsEntityDead(playerPed) then
            DebugLog('Sending death event to other scripts')
            TriggerEvent('qb-deathscreen:client:onPlayerDeath', true)
        end
    end
end)

-- QBCore Event Handlers
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    DebugLog('QBCore player loaded event received')
    
    -- Check player state after loading
    QBCore.Functions.GetPlayerData(function(PlayerData)
        if PlayerData.metadata and (PlayerData.metadata["inlaststand"] or PlayerData.metadata["isdead"]) then
            DebugLog('Player loaded and is dead according to QBCore metadata')
            if not deathScreenShown then
                ShowDeathScreenWithKiller()
            end
        else
            DebugLog('Player loaded and is alive according to QBCore metadata')
            if deathScreenShown then
                HideDeathScreen()
            end
        end
    end)
end)

-- Handle QBCore death events
RegisterNetEvent('hospital:client:Revive', function()
    DebugLog('QBCore revive event received')
    if deathScreenShown then
        HideDeathScreen()
    end
end)

RegisterNetEvent('hospital:client:RespawnAtHospital', function()
    DebugLog('QBCore hospital respawn event received')
    if deathScreenShown then
        HideDeathScreen()
    end
end)

-- Handle QBCore laststand events
RegisterNetEvent('hospital:client:SetLaststand', function(inLaststand)
    DebugLog('QBCore laststand event received: ' .. tostring(inLaststand))
    if inLaststand and not deathScreenShown then
        ShowDeathScreenWithKiller()
    elseif not inLaststand and deathScreenShown then
        HideDeathScreen()
    end
end)

-- Handle QBCore death events
RegisterNetEvent('hospital:client:SetDead', function(isDead)
    DebugLog('QBCore death event received: ' .. tostring(isDead))
    if isDead and not deathScreenShown then
        ShowDeathScreenWithKiller()
    elseif not isDead and deathScreenShown then
        HideDeathScreen()
    end
end)

-- Player spawn - ensure clean state
AddEventHandler('playerSpawned', function()
    DebugLog('Player spawned event received')
    
    local playerPed = PlayerPedId()
    if not IsEntityDead(playerPed) and deathScreenShown then
        DebugLog('Player spawned and alive, hiding screen')
        HideDeathScreen()
    else
        DebugLog('Player spawned, state is consistent')
    end
end)

-- Revive Player Function (from old version)
function RevivePlayer()
    DebugLog('Reviving player')
    
    deathScreenShown = false
    
    -- Enable player control
    SetPlayerControl(PlayerId(), true, 0)
    SetPlayerInvincible(PlayerId(), false)
    
    -- Restore health
    local playerPed = PlayerPedId()
    SetEntityHealth(playerPed, 200)
    
    -- Stop death camera
    StopDeathCam()
    
    -- Hide death screen
    SendNUIMessage({
        action = 'hideDeathScreen'
    })
    
    -- Re-enable voice
    if Config and Config.DisableVoice then
        exports['pma-voice']:SetMumbleProperty('radioEnabled', true)
        exports['pma-voice']:SetMumbleProperty('micClicks', true)
    end
    
    -- Notify server
    TriggerServerEvent('qb-deathscreen:server:OnPlayerRevive')
    
    QBCore.Functions.Notify('You have been revived!', 'success')
end

-- Debug command to check death screen status
RegisterCommand('deathstatus', function()
    local playerPed = PlayerPedId()
    local isDead = IsEntityDead(playerPed)
    local status = {
        deathScreenShown = deathScreenShown,
        isEntityDead = isDead,
        deathTimer = deathTimer ~= nil,
        hospitalButtonEnabled = hospitalButtonEnabled,
        deathStartTime = deathStartTime,
        elapsed = deathStartTime > 0 and math.floor((GetGameTimer() - deathStartTime) / 1000) or 0
    }
    
    DebugLog('Status: ' .. json.encode(status))
    QBCore.Functions.Notify('Death screen status logged to console', 'primary')
end, false)

-- Debug function to check death screen status
exports('GetDeathScreenStatus', function()
    return {
        deathScreenShown = deathScreenShown,
        isEntityDead = IsEntityDead(PlayerPedId()),
        deathTimer = deathTimer ~= nil,
        hospitalButtonEnabled = hospitalButtonEnabled,
        deathStartTime = deathStartTime,
        elapsed = deathStartTime > 0 and math.floor((GetGameTimer() - deathStartTime) / 1000) or 0
    }
end)

-- Export functions for other resources
exports('IsDead', function()
    return IsEntityDead(PlayerPedId())
end)

exports('ShowDeathScreen', function()
    ShowDeathScreen()
end)

exports('HideDeathScreen', function()
    HideDeathScreen()
end)

exports('RevivePlayer', function()
    if deathScreenShown then
        RevivePlayer()
    end
end)

-- Disable chat when dead (from old version)
CreateThread(function()
    while true do
        if deathScreenShown and Config and Config.DisableChat then
            DisableControlAction(0, 245, true) -- Chat
            DisableControlAction(0, 249, true) -- Push to talk
        end
        Wait(0)
    end
end)