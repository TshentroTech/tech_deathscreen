local QBCore = exports['qb-core']:GetCoreObject()

-- Server Events (from old version)
RegisterNetEvent('qb-deathscreen:server:OnPlayerDeath', function(reason)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Log death
    local deathLog = {
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        reason = reason,
        timestamp = os.time()
    }
    
    -- Notify emergency services
    NotifyEmergencyServices(src, deathLog)
    
    print(string.format('[DEATH] %s died from %s', deathLog.name, reason))
end)

RegisterNetEvent('qb-deathscreen:server:OnPlayerRevive', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local reviveLog = {
        citizenid = Player.PlayerData.citizenid,
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        timestamp = os.time()
    }
    
    print(string.format('[REVIVE] %s was revived', reviveLog.name))
end)

RegisterNetEvent('qb-deathscreen:server:AttemptRespawn', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has enough money
    if Player.PlayerData.money.bank >= Config.BlacksmithRevive.price then
        -- Remove money
        Player.Functions.RemoveMoney('bank', Config.BlacksmithRevive.price, 'death-respawn')
        
        -- Check if blacksmith item exists (if configured)
        if Config.BlacksmithRevive.item then
            local hasItem = Player.Functions.GetItemByName(Config.BlacksmithRevive.item)
            if hasItem and hasItem.amount > 0 then
                Player.Functions.RemoveItem(Config.BlacksmithRevive.item, 1)
            end
        end
        
        -- Revive player
        TriggerClientEvent('qb-deathscreen:client:RevivePlayer', src)
        
        TriggerClientEvent('QBCore:Notify', src, 
            string.format('You have been revived for $%d', Config.BlacksmithRevive.price), 
            'success'
        )
    else
        TriggerClientEvent('QBCore:Notify', src, 
            string.format('You need $%d to respawn', Config.BlacksmithRevive.price), 
            'error'
        )
    end
end)

RegisterNetEvent('qb-deathscreen:server:RemoveMoney', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        Player.Functions.RemoveMoney('bank', amount, 'auto-respawn')
    end
end)

-- Helper Functions (from old version)
function NotifyEmergencyServices(src, deathLog)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local EmergencyPlayer = QBCore.Functions.GetPlayer(playerId)
        if EmergencyPlayer then
            for _, job in pairs(Config.EmergencyJobs) do
                if EmergencyPlayer.PlayerData.job.name == job then
                    TriggerClientEvent('QBCore:Notify', playerId, 
                        string.format('Emergency: %s needs medical attention', deathLog.name), 
                        'error', 10000
                    )
                    
                    -- Add blip for emergency services
                    TriggerClientEvent('qb-deathscreen:client:AddEmergencyBlip', playerId, {
                        coords = playerCoords,
                        name = deathLog.name
                    })
                end
            end
        end
    end
end

-- Simple server events for death screen

RegisterNetEvent('qb-deathscreen:server:CallEmergency', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z))
    
    -- Notify all emergency services
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        local EmergencyPlayer = QBCore.Functions.GetPlayer(playerId)
        if EmergencyPlayer then
            for _, job in pairs(Config.EmergencyJobs) do
                if EmergencyPlayer.PlayerData.job.name == job then
                    TriggerClientEvent('QBCore:Notify', playerId, 
                        string.format('Emergency: %s needs medical attention at %s', 
                        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, 
                        streetName), 
                        'error', 10000
                    )
                end
            end
        end
    end
    
    -- Notify the caller
    TriggerClientEvent('QBCore:Notify', src, 'Emergency services have been notified!', 'primary')
end)

-- Commands for emergency services (from old version)
QBCore.Commands.Add('revive', 'Revive a player (Emergency Services Only)', {{name = 'id', help = 'Player ID (optional)'}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has emergency job
    local hasPermission = false
    for _, job in pairs(Config.EmergencyJobs) do
        if Player.PlayerData.job.name == job then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    local targetId = args[1] and tonumber(args[1]) or GetClosestPlayerId(src)
    
    if targetId then
        TriggerClientEvent('qb-deathscreen:client:RevivePlayer', targetId)
        TriggerClientEvent('QBCore:Notify', src, string.format('You revived player %d', targetId), 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'No player found', 'error')
    end
end)

-- Helper function to get closest player
function GetClosestPlayerId(src)
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local closestDistance = math.huge
    local closestPlayer = nil
    
    for _, playerId in pairs(QBCore.Functions.GetPlayers()) do
        if playerId ~= src then
            local targetCoords = GetEntityCoords(GetPlayerPed(playerId))
            local distance = #(playerCoords - targetCoords)
            
            if distance < closestDistance and distance < 5.0 then
                closestDistance = distance
                closestPlayer = playerId
            end
        end
    end
    
    return closestPlayer
end

-- Function to trigger death screen for a player
function TriggerDeathScreen(playerId, isDead)
    TriggerClientEvent('qb-deathscreen:client:onPlayerDeath', playerId, isDead)
end

-- Export the function for other resources
exports('TriggerDeathScreen', TriggerDeathScreen)

-- Event to trigger death screen from other resources
RegisterNetEvent('qb-deathscreen:server:TriggerDeathScreen')
AddEventHandler('qb-deathscreen:server:TriggerDeathScreen', function(playerId, isDead)
    TriggerDeathScreen(playerId, isDead)
end)

-- Test command for server-side death screen trigger
QBCore.Commands.Add('testdeathscreen', 'Test death screen (Admin Only)', {{name = 'id', help = 'Player ID (optional)'}}, true, function(source, args)
    local src = source
    local targetId = args[1] and tonumber(args[1]) or src
    
    print(string.format('[DEATHSCREEN] Server test command: Triggering death screen for player %d', targetId))
    TriggerDeathScreen(targetId, true)
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Death screen triggered for player %d', targetId), 'primary')
end)

QBCore.Commands.Add('hidedeathscreen', 'Hide death screen (Admin Only)', {{name = 'id', help = 'Player ID (optional)'}}, true, function(source, args)
    local src = source
    local targetId = args[1] and tonumber(args[1]) or src
    
    print(string.format('[DEATHSCREEN] Server test command: Hiding death screen for player %d', targetId))
    TriggerDeathScreen(targetId, false)
    
    TriggerClientEvent('QBCore:Notify', src, string.format('Death screen hidden for player %d', targetId), 'primary')
end)

-- Discord Webhook Handler
RegisterNetEvent('qb-deathscreen:server:SendDiscordWebhook', function(type, embed)
    if not Config.Discord.enabled or Config.Discord.webhookUrl == "" then
        return
    end
    
    -- Ensure embed has required fields
    embed = embed or {}
    embed.title = embed.title or "Death Screen Event"
    embed.description = embed.description or "An event occurred"
    embed.color = embed.color or 0
    embed.fields = embed.fields or {}
    
    -- Add server timestamp to embed
    embed.footer = embed.footer or {}
    embed.footer.text = embed.footer.text or "Death Screen Logger"
    embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    
    local webhookData = {
        username = Config.Discord.botName or "Death Screen Logger",
        avatar_url = Config.Discord.botAvatar or "",
        embeds = {embed}
    }
    
    local jsonData = json.encode(webhookData)
    if not jsonData then
        print("^1[DEATHSCREEN] Failed to encode webhook data^7")
        return
    end
    
    PerformHttpRequest(Config.Discord.webhookUrl, function(err, text, headers) 
        if err then
            print("^1[DEATHSCREEN] Discord webhook error: " .. tostring(err) .. "^7")
        elseif text then
            print("^2[DEATHSCREEN] Discord webhook sent successfully^7")
        end
    end, 'POST', jsonData, { ['Content-Type'] = 'application/json' })
end)

-- Emergency Services Call