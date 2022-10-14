# WORK IN PROGRESS

## lua-vip
This script adds commands to players which are in VIP mode.

#### Find me on patreon: https://www.patreon.com/Honeys

## Requirements:
Compile your [Azerothcore](https://github.com/azerothcore/azerothcore-wotlk) with [Eluna Lua](https://www.azerothcore.org/catalogue-details.html?id=131435473).
The ElunaLua module itself doesn't require much setup/config. Just specify the subfolder where to put your lua_scripts in its .conf file.

If the directory was not changed, add the .lua script to your `../lua_scripts/` directory.
Adjust the top part of the .lua file with the config flags.

## Admin usage:
-  compile the core with ElunaLua module
-  adjust config in this file
-  add this script to ../lua_scripts/
-  give the players away to obtain the VIP item

## Player Usage:
-  obtain the required item for VIP
-  .vip activate
-  use the VIP commands

## Config:
See the lua file for a description of the config flags.
