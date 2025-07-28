fx_version 'cerulean'
game 'gta5'

version '2.0.0'
author 'tshentro.tech'
name 'tech-deathscreen'
description 'Thank you for your purchase TshentroTech.tebex.io'

lua54 'yes'
shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/deathcam.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'sounds/heartbeat.wav'
}