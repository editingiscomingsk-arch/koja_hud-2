fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'koja-hud'
author 'Koja Scripts'
version '1.1.0'
description 'Free HUD for FiveM written in Lua & React'

shared_scripts {
    'editable/shared/config.lua',
    'editable/shared/utils.lua',
    'data/*.lua',
    'init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/threads.lua',
    'client/exports.lua',
    'client/modules/vehicle/*.lua',
    'client/modules/other/*.lua',
}

ui_page 'web/build/index.html'

files {
    'web/build/index.html',
    'web/build/**/*',
    'locales/*.json'
}

dependencies {
    'koja-lib',
    'oxmysql'
}

escrow_ignore {
    '/*',
    '/**/*',
    '/**/**/*',
}

dependency '/assetpacks'