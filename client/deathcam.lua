-- Death Camera System
local deathCam = nil
local camCoords = nil
local camRot = nil
local isDeathCamActive = false
local deathCamThread = nil

-- Function to start death camera
function StartDeathCam()
    if isDeathCamActive then 
        DebugLog('[DEATHCAM] Death camera already active, stopping first')
        StopDeathCam()
        Wait(500) -- Wait for cleanup
    end
    
    DebugLog('[DEATHCAM] Starting automatic death camera')
    isDeathCamActive = true
    
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        DebugLog('[DEATHCAM] Player ped not found, cannot start camera')
        isDeathCamActive = false
        return
    end
    
    local playerCoords = GetEntityCoords(playerPed)
    local cameraConfig = Config.DeathCamera
    
    -- Calculate initial camera position (directly above player like a drone)
    camCoords = vector3(
        playerCoords.x,
        playerCoords.y,
        playerCoords.z + cameraConfig.height
    )
    
    camRot = vector3(-90.0, 0.0, 0.0) -- Look straight down at player's body
    
    -- Create death camera
    deathCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    if not deathCam then
        DebugLog('[DEATHCAM] Failed to create camera')
        isDeathCamActive = false
        return
    end
    
    SetCamCoord(deathCam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(deathCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamActive(deathCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    
    -- Start automatic camera movement
    StartCamMovement()
    
    DebugLog('[DEATHCAM] Automatic death camera started successfully')
end

-- Function to stop death camera
function StopDeathCam()
    if not isDeathCamActive then 
        DebugLog('[DEATHCAM] Death camera not active, nothing to stop')
        return 
    end
    
    DebugLog('[DEATHCAM] Stopping death camera')
    isDeathCamActive = false
    
    -- Stop update thread
    if deathCamThread then
        deathCamThread = nil
    end
    
    if deathCam then
        RenderScriptCams(false, true, 1000, true, true)
        SetCamActive(deathCam, false)
        DestroyCam(deathCam, true)
        deathCam = nil
    end
    
    -- Reset variables
    camCoords = nil
    camRot = nil
    
    DebugLog('[DEATHCAM] Death camera stopped successfully')
end

-- Function to start automatic camera movement
function StartCamMovement()
    if deathCamThread then return end
    
    deathCamThread = CreateThread(function()
        while isDeathCamActive and deathCam do
            local playerPed = PlayerPedId()
            if not DoesEntityExist(playerPed) then 
                DebugLog('[DEATHCAM] Player ped not found during movement, stopping camera')
                StopDeathCam()
                break
            end
            
            local playerCoords = GetEntityCoords(playerPed)
            local cameraConfig = Config.DeathCamera
            local currentTime = GetGameTimer()
            
            -- Drone-like rotation around player (circling above the body)
            local rotationSpeed = cameraConfig.rotationSpeed
            local newHeading = camRot.z + rotationSpeed
            if newHeading >= 360.0 then
                newHeading = 0.0
            end
            
            camRot = vector3(-90.0, 0.0, newHeading) -- Always look straight down
            
            -- Very gentle height variation (like a hovering drone)
            local heightVariation = math.sin(currentTime / 5000) * 0.5 -- Minimal height change
            local currentHeight = cameraConfig.height + heightVariation
            
            -- Gentle distance variation (like a drone adjusting its distance)
            local distanceVariation = math.sin(currentTime / 8000) * 0.8 -- Gentle distance change
            local currentDistance = cameraConfig.distance + distanceVariation
            
            -- Calculate drone position (circling around player's body)
            local angle = math.rad(camRot.z)
            local droneX = playerCoords.x + math.cos(angle) * currentDistance
            local droneY = playerCoords.y + math.sin(angle) * currentDistance
            local droneZ = playerCoords.z + currentHeight
            
            camCoords = vector3(droneX, droneY, droneZ)
            SetCamCoord(deathCam, camCoords.x, camCoords.y, camCoords.z)
            
            -- Keep camera looking straight down at player's body
            SetCamRot(deathCam, -90.0, 0.0, camRot.z, 2)
            
            -- Very minimal camera shake (like a stable drone)
            local shakeIntensity = 0.01 -- Almost no shake
            local shakeX = (math.random() - 0.5) * shakeIntensity
            local shakeY = (math.random() - 0.5) * shakeIntensity
            local shakeZ = (math.random() - 0.5) * shakeIntensity
            
            SetCamCoord(deathCam, camCoords.x + shakeX, camCoords.y + shakeY, camCoords.z + shakeZ)
            
            Wait(50) -- Update every 50ms for smooth drone movement
        end
    end)
end

-- Export functions for other resources
exports('StartDeathCam', function()
    StartDeathCam()
end)

exports('StopDeathCam', function()
    StopDeathCam()
end)

exports('IsDeathCamActive', function()
    return isDeathCamActive
end) 