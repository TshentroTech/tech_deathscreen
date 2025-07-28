let deathData = {};
let heartbeatAudio;
let flatlineAudio;
let secretMessageTimeout;
let heartRateInterval;
let currentHeartRate = 80;
let deathScreenEnabled = false; // Track if death screen is enabled
let hospitalButtonEnabled = false; // Track if hospital button is enabled
let debugMode = false; // Debug mode for console logs

// Debug logging function
function debugLog(message) {
    if (debugMode) {
        console.log('[DEATHSCREEN] ' + message);
    }
}

// Initialize when document is ready
document.addEventListener('DOMContentLoaded', function() {
    heartbeatAudio = document.getElementById('heartbeat-audio');
    flatlineAudio = document.getElementById('flatline-audio');
    
    // Set audio volumes
    if (heartbeatAudio) heartbeatAudio.volume = 0.3;
    if (flatlineAudio) flatlineAudio.volume = 0.5;
    
    // Check if all required elements exist
    checkRequiredElements();
    
    // Initialize countdown display after a short delay
    setTimeout(() => {
        initializeCountdownDisplay();
    }, 100);
});

// Function to initialize countdown display
function initializeCountdownDisplay() {
    const { hospitalButton, hospitalCountdown } = findHospitalElements();
    
    if (hospitalButton) {
        // Set initial countdown text
        const initialCountdown = window.hospitalButtonDelay || 120;
        hospitalButton.textContent = `Go to Hospital (Available in ${initialCountdown}s)`;
        
        if (hospitalCountdown) {
            hospitalCountdown.textContent = initialCountdown;
        }
        
        debugLog('Countdown display initialized with: ' + initialCountdown);
    }
}

// Function to check if all required elements exist
function checkRequiredElements() {
    const requiredElements = [
        'death-container',
        'hospital-button',
        'hospital-countdown',
        'emergency-button',
        'death-cause',
        'death-time',
        'heart-rate',
        'ecg-path'
    ];
    
    debugLog('Checking required elements...');
    const missingElements = [];
    
    requiredElements.forEach(elementId => {
        const element = document.getElementById(elementId);
        if (!element) {
            missingElements.push(elementId);
        }
    });
    
    if (missingElements.length > 0) {
        debugLog('WARNING: Missing elements: ' + missingElements.join(', '));
    } else {
        debugLog('All required elements found successfully');
    }
    
    return missingElements.length === 0;
}

// Listen for NUI messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    debugLog('NUI Message received: ' + data.action + ', data: ' + JSON.stringify(data));
    
    switch(data.action) {
        case 'enableDeathScreen':
            debugLog('Enabling death screen');
            deathScreenEnabled = true;
            break;
        case 'disableDeathScreen':

            deathScreenEnabled = false;
            hideDeathScreen();
            break;
        case 'showDeathScreen':
            debugLog('Showing death screen with data: ' + JSON.stringify(data));
            showDeathScreen(data);
            break;
        case 'hideDeathScreen':
            // RADICAL PROTECTION: Add delay before hiding
            setTimeout(() => {
                hideDeathScreen();
            }, 1000); // 1 second delay
            break;
        case 'forceResetDeathScreen':

            forceResetDeathScreen();
            break;
        case 'setKillerInfo':

            updateKillerInfo(data.killer);
            break;
        case 'setHospitalButtonDelay':
            debugLog('Setting hospital button delay: ' + data.delay);
            window.hospitalButtonDelay = data.delay;
            break;
        case 'updateTimer':
            updateTimer(data.time);
            break;
        case 'updateHospitalCountdown':
            debugLog('Updating hospital countdown: ' + data.countdown);
            updateHospitalCountdown(data.countdown);
            break;
        case 'enableHospitalButton':
            debugLog('Enabling hospital button from client');
            enableHospitalButton();
            break;
        case 'updateHeartRate':
            updateHeartRate(data.rate);
            break;
        case 'showSecretMessage':
            showSecretMessage(data.message);
            break;
        case 'enableRespawn':
            enableRespawn();
            break;
        case 'updateEmergencyCooldown':
            updateEmergencyCooldown(data);
            break;
        case 'setDebugMode':
            debugMode = data.debug;
            debugLog('Debug mode set to: ' + debugMode);
            break;
        case 'testElements':
            debugLog('Testing elements...');
            checkRequiredElements();
            break;
        default:
            break;
    }
});

function showDeathScreen(data) {
    debugLog('showDeathScreen called with data: ' + JSON.stringify(data));
    
    // Prevent multiple calls
    if (document.getElementById('death-container')?.classList.contains('show')) {
        debugLog('Death screen already shown, skipping');
        return;
    }
    
    deathData = data;
    hospitalButtonEnabled = false; // Reset hospital button state
    
    const container = document.getElementById('death-container');
    const deathCause = document.getElementById('death-cause');
    const deathTime = document.getElementById('death-time');
    
    debugLog('Found elements - container: ' + !!container + ', deathCause: ' + !!deathCause + ', deathTime: ' + !!deathTime);
    
    if (container) {
        debugLog('Container found, updating death information');
        // Update death information
        if (deathCause) deathCause.textContent = data.reason || 'Unknown';
        if (deathTime) deathTime.textContent = formatTime(data.timer || 300);
        
        // Set hospital button delay if provided
        if (data.hospitalButtonDelay) {
            debugLog('Hospital button delay from showDeathScreen: ' + data.hospitalButtonDelay);
            window.hospitalButtonDelay = data.hospitalButtonDelay;
        }
        
        // STRONG PROTECTION: Ensure hospital button starts disabled
        const hospitalButton = document.getElementById('hospital-button');
        const hospitalCountdown = document.getElementById('hospital-countdown');
        
        debugLog('Hospital elements - button: ' + !!hospitalButton + ', countdown: ' + !!hospitalCountdown);
        
        if (hospitalButton && hospitalCountdown) {
            hospitalButton.classList.add('disabled');
            hospitalButton.style.pointerEvents = 'none';
            hospitalButton.style.cursor = 'not-allowed';
            
            // Initialize countdown display
            hospitalCountdown.textContent = data.hospitalButtonDelay || 120;
            hospitalButton.textContent = `Go to Hospital (Available in ${data.hospitalButtonDelay || 120}s)`;
            debugLog('Hospital button initialized as disabled with countdown: ' + (data.hospitalButtonDelay || 120));
        } else {
            debugLog('ERROR: Hospital button or countdown element not found during initialization!');
            debugLog('hospitalButton exists: ' + !!hospitalButton);
            debugLog('hospitalCountdown exists: ' + !!hospitalCountdown);
        }
        
        // Show the death screen
        debugLog('Adding show class to container');
        container.classList.remove('hidden');
        container.classList.add('show');
        
        // Enable death screen
        deathScreenEnabled = true;
        debugLog('Death screen enabled and shown');
        
        // Start heartbeat audio with continuous loop
        if (heartbeatAudio) {
            heartbeatAudio.currentTime = 0;
            heartbeatAudio.loop = true; // Ensure continuous looping
            heartbeatAudio.volume = 0.3; // Set volume
            heartbeatAudio.muted = false; // Ensure audio is not muted
            
            // Add event listener to restart audio if it stops
            heartbeatAudio.addEventListener('ended', function() {
                if (deathScreenEnabled) {
                    heartbeatAudio.currentTime = 0;
                    heartbeatAudio.play().catch(e => {});
                }
            });
            
            // Add event listener for when audio can play
            heartbeatAudio.addEventListener('canplaythrough', function() {
                if (deathScreenEnabled && heartbeatAudio.paused) {
                    heartbeatAudio.play().catch(e => {});
                }
            });
            
            // Start playing
            heartbeatAudio.play().catch(e => {});
        }
        
        // Start heart rate animation
        startHeartRateMonitor();
        
        // Show secret message after delay
        if (data.secretMessage) {
            secretMessageTimeout = setTimeout(() => {
                showSecretMessage(data.secretMessage);
            }, 10000);
        }
        
        // Generate ECG pattern
        generateECGPattern();
    } else {
        debugLog('ERROR: Death container not found!');
    }
}

function hideDeathScreen() {
    
    const container = document.getElementById('death-container');
    
    if (container) {
        // RADICAL PROTECTION: Check if death screen is actually shown
        if (!container.classList.contains('show')) {
            return;
        }
        
        // RADICAL PROTECTION: Add confirmation before hiding
        
        container.classList.add('hidden');
        container.classList.remove('show');
        
        // Stop all audio only when hiding death screen
        if (heartbeatAudio) {
            heartbeatAudio.pause();
            heartbeatAudio.currentTime = 0;
        }
        if (flatlineAudio) {
            flatlineAudio.pause();
            flatlineAudio.currentTime = 0;
        }
        
        // Clear all intervals and timeouts
        clearInterval(heartRateInterval);
        clearTimeout(secretMessageTimeout);
        
        // Hide secret message
        const secretMessage = document.getElementById('secret-message');
        if (secretMessage) secretMessage.classList.add('hidden');
        
        // STRONG PROTECTION: Reset hospital button to disabled state
        const hospitalButton = document.getElementById('hospital-button');
        if (hospitalButton) {
            hospitalButton.classList.add('disabled');
            hospitalButton.style.pointerEvents = 'none';
            hospitalButton.style.cursor = 'not-allowed';
            hospitalButton.textContent = 'Go to Hospital (Available in 120s)';
        }
        
        // Reset state
        document.body.classList.remove('critical-state', 'flatline');
        
    }
    
    // Reset state
    deathScreenEnabled = false;
    hospitalButtonEnabled = false;
}

// Force reset function for emergency cases
function forceResetDeathScreen() {
    
    const container = document.getElementById('death-container');
    if (container) {
        container.classList.add('hidden');
        container.classList.remove('show');
    }
    
    // Stop all audio
    if (heartbeatAudio) {
        heartbeatAudio.pause();
        heartbeatAudio.currentTime = 0;
    }
    if (flatlineAudio) {
        flatlineAudio.pause();
        flatlineAudio.currentTime = 0;
    }
    
    // Clear all intervals and timeouts
    clearInterval(heartRateInterval);
    clearTimeout(secretMessageTimeout);
    
    // Hide secret message
    const secretMessage = document.getElementById('secret-message');
    if (secretMessage) secretMessage.classList.add('hidden');
    
    // STRONG PROTECTION: Reset hospital button to disabled state
    const hospitalButton = document.getElementById('hospital-button');
    if (hospitalButton) {
        hospitalButton.classList.add('disabled');
        hospitalButton.style.pointerEvents = 'none';
        hospitalButton.style.cursor = 'not-allowed';
        hospitalButton.textContent = 'Go to Hospital (Available in 120s)';
    }
    
    // Reset state
    document.body.classList.remove('critical-state', 'flatline');
    
    // Hide cursor
    fetch(`https://${GetParentResourceName()}/hideCursor`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
    
    // Reset death screen enabled state
    deathScreenEnabled = false;
    hospitalButtonEnabled = false;
}

function updateKillerInfo(killer) {
    const killerElement = document.getElementById('killer');
    if (killerElement) {
        killerElement.textContent = killer || 'Unknown';
    }
}

function updateTimer(time) {
    const deathTime = document.getElementById('death-time');
    if (deathTime) deathTime.textContent = formatTime(time);
    
    // Change heart rate based on remaining time
    if (time < 60) {
        updateHeartRate(40); // Critical
        document.body.classList.add('critical-state');
    } else if (time < 120) {
        updateHeartRate(60); // Low
    }
    
    // Flatline at 0 - but keep heartbeat audio playing
    if (time <= 0) {
        updateHeartRate(0);
        document.body.classList.add('flatline');
        
        // Keep heartbeat audio playing even at flatline
        if (heartbeatAudio && heartbeatAudio.paused) {
            heartbeatAudio.play().catch(e => {});
        }
        
        // Play flatline audio if available, but don't stop heartbeat
        if (flatlineAudio) {
            flatlineAudio.currentTime = 0;
            flatlineAudio.play().catch(e => {});
        }
    }
}

// Function to find hospital elements with retry
function findHospitalElements() {
    let hospitalButton = document.getElementById('hospital-button');
    let hospitalCountdown = document.getElementById('hospital-countdown');
    
    // If not found, try alternative selectors
    if (!hospitalButton) {
        hospitalButton = document.querySelector('.hospital-btn');
        debugLog('Trying alternative selector for hospital button: ' + !!hospitalButton);
    }
    
    if (!hospitalCountdown) {
        hospitalCountdown = document.querySelector('#hospital-countdown');
        debugLog('Trying alternative selector for hospital countdown: ' + !!hospitalCountdown);
    }
    
    return { hospitalButton, hospitalCountdown };
}

function updateHospitalCountdown(countdown) {
    const { hospitalButton, hospitalCountdown } = findHospitalElements();
    
    debugLog('Looking for elements - hospitalButton: ' + !!hospitalButton + ', hospitalCountdown: ' + !!hospitalCountdown);
    
    if (hospitalButton && hospitalCountdown) {
        if (countdown > 0) {
            // Still counting down
            hospitalCountdown.textContent = countdown;
            hospitalButton.textContent = `Go to Hospital (Available in ${countdown}s)`;
        } else {
            // Countdown finished, button should be enabled
            hospitalCountdown.textContent = '0';
            hospitalButton.textContent = 'Go to Hospital';
            if (!hospitalButtonEnabled) {
                enableHospitalButton();
            }
        }
        debugLog('Hospital countdown updated to: ' + countdown);
    } else if (hospitalButton) {
        // If we have the button but not the countdown element, update button text only
        if (countdown > 0) {
            hospitalButton.textContent = `Go to Hospital (Available in ${countdown}s)`;
        } else {
            hospitalButton.textContent = 'Go to Hospital';
            if (!hospitalButtonEnabled) {
                enableHospitalButton();
            }
        }
        debugLog('Hospital countdown updated (button only) to: ' + countdown);
    } else {
        debugLog('ERROR: Hospital button or countdown element not found!');
        debugLog('Debug - hospitalButton exists: ' + !!hospitalButton);
        debugLog('Debug - hospitalCountdown exists: ' + !!hospitalCountdown);
        
        // Try to find elements again after a longer delay
        setTimeout(() => {
            const { retryButton, retryCountdown } = findHospitalElements();
            debugLog('Retry - hospitalButton exists: ' + !!retryButton);
            debugLog('Retry - hospitalCountdown exists: ' + !!retryCountdown);
            
            if (retryButton) {
                updateHospitalCountdown(countdown);
            }
        }, 500); // Increased delay to 500ms
    }
}

function updateHeartRate(rate) {
    currentHeartRate = rate;
    const heartRateDisplay = document.getElementById('heart-rate');
    if (heartRateDisplay) heartRateDisplay.textContent = rate;
    
    // Update heartbeat audio speed and ensure it's playing
    if (heartbeatAudio) {
        if (rate > 0) {
            heartbeatAudio.playbackRate = rate / 80; // Normal is 80 BPM
        }
        
        // Ensure heartbeat audio is always playing when death screen is shown
        if (deathScreenEnabled && heartbeatAudio.paused) {
            heartbeatAudio.play().catch(e => {});
        }
    }
}

function startHeartRateMonitor() {
    heartRateInterval = setInterval(() => {
        // Add slight variation to heart rate for realism
        const variation = Math.random() * 10 - 5; // ±5 BPM
        const newRate = Math.max(0, currentHeartRate + variation);
        
        const heartRateDisplay = document.getElementById('heart-rate');
        if (heartRateDisplay) heartRateDisplay.textContent = Math.round(newRate);
        
        // Update ECG pattern
        generateECGPattern();
        
        // Ensure heartbeat audio is playing continuously
        if (heartbeatAudio && deathScreenEnabled && heartbeatAudio.paused) {
            heartbeatAudio.currentTime = 0;
            heartbeatAudio.play().catch(e => {});
        }
    }, 1000);
}

// Function to enable hospital button (called from client)
function enableHospitalButton() {
    debugLog('Enabling hospital button');
    hospitalButtonEnabled = true;
    
    const { hospitalButton, hospitalCountdown } = findHospitalElements();
    
    if (hospitalButton) {
        // Remove disabled class and styles
        hospitalButton.classList.remove('disabled');
        hospitalButton.style.pointerEvents = 'auto';
        hospitalButton.style.cursor = 'pointer';
        hospitalButton.textContent = 'Go to Hospital';
        
        debugLog('Hospital button enabled successfully!');
        
        // Add a visual effect to show it's now clickable
        hospitalButton.style.animation = 'pulse 1s ease-in-out';
        setTimeout(() => {
            hospitalButton.style.animation = '';
        }, 1000);
    } else {
        debugLog('ERROR: Hospital button not found!');
    }
}

// REMOVED: startDeathTimer and startHospitalCountdown functions - now handled by client

function generateECGPattern() {
    const ecgPath = document.getElementById('ecg-path');
    if (!ecgPath) return;
    
    if (currentHeartRate === 0) {
        // Flatline
        ecgPath.setAttribute('d', 'M0,100 L800,100');
        return;
    }
    
    // Generate ECG pattern based on heart rate
    const beats = Math.floor(800 / (60000 / currentHeartRate / 10)); // Approximate beats across screen
    let path = 'M0,100';
    
    for (let i = 0; i < beats; i++) {
        const x = (i / beats) * 800;
        const variation = Math.random() * 20 - 10; // Random variation
        
        // QRS complex simulation
        path += ` L${x - 20},100`;
        path += ` L${x - 10},${80 + variation}`;
        path += ` L${x},${120 + variation}`;
        path += ` L${x + 10},${80 + variation}`;
        path += ` L${x + 20},100`;
    }
    
    path += ' L800,100';
    ecgPath.setAttribute('d', path);
}

function showSecretMessage(message) {
    const secretMessage = document.getElementById('secret-message');
    const secretText = document.getElementById('secret-text');
    
    if (secretMessage && secretText) {
        secretText.textContent = message;
        secretMessage.classList.remove('hidden');
    }
}

function enableRespawn() {
    const respawnButton = document.getElementById('respawn-button');
    if (respawnButton) {
        respawnButton.classList.remove('hidden');
    }
}

function formatTime(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
}

// Button event listeners
document.addEventListener('click', function(e) {
    debugLog('Button clicked: ' + e.target.id);
    
    if (e.target.id === 'respawn-button') {
        debugLog('Respawn button clicked');
        fetch(`https://${GetParentResourceName()}/respawn`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    } else if (e.target.id === 'emergency-button') {
        debugLog('Emergency button clicked');
        
        // Check if button is disabled (cooldown active)
        if (e.target.classList.contains('disabled')) {
            debugLog('Emergency button is disabled due to cooldown');
            return;
        }
        
        // Add visual feedback
        e.target.style.transform = 'scale(0.95)';
        setTimeout(() => {
            e.target.style.transform = '';
        }, 150);
        
        fetch(`https://${GetParentResourceName()}/callEmergency`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    } else if (e.target.id === 'hospital-button') {
        debugLog('Hospital button clicked, enabled state: ' + hospitalButtonEnabled);
        
        // STRONG PROTECTION: Check if hospital button is enabled
        if (!hospitalButtonEnabled) {
            debugLog('Hospital button clicked but not enabled, ignoring click');
            return;
        }
        
        debugLog('Hospital button clicked and enabled, sending request');
        
        // Add visual feedback
        e.target.style.transform = 'scale(0.95)';
        setTimeout(() => {
            e.target.style.transform = '';
        }, 150);
        
        fetch(`https://${GetParentResourceName()}/hospitalRespawn`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});

// Prevent right-click context menu
document.addEventListener('contextmenu', function(e) {
    e.preventDefault();
});

// Debug function to check death screen status
function getDeathScreenStatus() {
    return {
        deathScreenEnabled: deathScreenEnabled,
        hospitalButtonEnabled: hospitalButtonEnabled,
        containerExists: !!document.getElementById('death-container'),
        containerVisible: document.getElementById('death-container')?.classList.contains('show') || false,
        currentHeartRate: currentHeartRate,
        audioLoaded: {
            heartbeat: !!heartbeatAudio,
            flatline: !!flatlineAudio
        }
    };
}

// Function to update emergency cooldown
function updateEmergencyCooldown(data) {
    const emergencyButton = document.getElementById('emergency-button');
    
    if (!emergencyButton) {
        debugLog('Emergency button not found for cooldown update');
        return;
    }
    
    if (data.active) {
        // Cooldown is active
        emergencyButton.textContent = `Call Emergency Services (${data.cooldown}s)`;
        emergencyButton.classList.add('disabled');
        emergencyButton.style.opacity = '0.5';
        emergencyButton.style.cursor = 'not-allowed';
    } else {
        // Cooldown finished
        emergencyButton.textContent = 'Call Emergency Services';
        emergencyButton.classList.remove('disabled');
        emergencyButton.style.opacity = '1';
        emergencyButton.style.cursor = 'pointer';
    }
    
    debugLog('Emergency cooldown updated - Active: ' + data.active + ', Time: ' + data.cooldown);
}