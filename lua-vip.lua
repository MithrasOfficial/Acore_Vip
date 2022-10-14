--
-- Created by IntelliJ IDEA.
-- User: Silvia
-- Date: 14/10/2022
-- Time: 20:51
-- To change this template use File | Settings | File Templates.
-- Originally created by Honey for Azerothcore
-- requires ElunaLua module


-- This script adds commands to players which are in VIP mode
------------------------------------------------------------------------------------------------
-- ADMIN GUIDE:  -  compile the core with ElunaLua module
--               -  adjust config in this file
--               -  add this script to ../lua_scripts/
--               -  give the players a way to obtain the VIP item
------------------------------------------------------------------------------------------------
-- PLAYER GUIDE: -  obtain the required item for VIP
--               -  .vip activate
--               -  use the VIP commands
------------------------------------------------------------------------------------------------

local Config = {}

-- Name of Eluna dB scheme
Config.customDbName = "ac_eluna"

-- Item which is required to activate VIP mode
Config.ActivationItemEntry = 555

-- Item which is required to enter the VIP instance. Given to the player by using ".vip key"
Config.keyItemEntry = 444

-- The following are the allowed maps to use zone-critical map commands from.
-- Eastern kingdoms, Kalimdor, Outland, Northrend
Config.maps = { 0, 1, 530, 571 }

-- list of allowed models for morphs
Config.morphs = { 987, 4465, 10913 }

-- Required GM Level for commands
Config.GMCommandLevel = 2

-- Teleporting coordinates for the VIP area
Config.VipMap = 0
Config.VipX = 5000
Config.VipY = 5000
Config.VipZ = 250
Config.VipO = 0

------------------------------------------
-- NO ADJUSTMENTS REQUIRED BELOW THIS LINE
------------------------------------------

local PLAYER_EVENT_ON_COMMAND = 42       -- (event, player, command) - player is nil if command used from console. Can return false

------------------------------------------------------------------------------------------------
-- create a custom table, if it doesn't already exist, to store the VIP status:
-- account_id is the unique account id from the auth db
-- activated indicates if the VIP status is turned on. <=0 is off. >0 is on.
-- time_stamp stores when the VIP was activated. For future use.
-- comment can be used when writing to this table from an external source
CharDBQuery('CREATE DATABASE IF NOT EXISTS `'..Config.customDbName..'`;');
CharDBQuery('CREATE TABLE IF NOT EXISTS `'..Config.customDbName..'`.`vip_accounts` (`account_id` INT NOT NULL, `activated` INT DEFAULT 0, `time_stamp` INT DEFAULT 0, `comment` varchar(255) DEFAULT "", PRIMARY KEY (`account_id`) );');
------------------------------------------------------------------------------------------------

local vipPlayers = {}

local function SplitString( inputstr, seperator )
    if seperator == nil then
        seperator = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..seperator.."]+)") do
        table.insert(t, str)
    end
    return t
end

local function HasIndex ( tab, val )
    for index, value in ipairs( tab ) do
        if index == val then
            return true
        end
    end
    return false
end

local function HasValue ( tab, val )
    for index, value in ipairs( tab ) do
        if value == val then
            return true
        end
    end
    return false
end

local function AddIfNotHasValue( tab, val )
    if not HasValue( tab, val ) then
        table.insert( tab, val )
    end
end

local function ActivateVIP( player )
    if player:HasItem( Config.ActivationItemEntry, 1, false ) then
        player:RemoveItem( Config.ActivationItemEntry, 1 )
        CharDBExecute('REPLACE INTO `'..Config.customDbName..'` .`vip_accounts` VALUES ( ' .. player:GetAccountId() .. ', 1, ' .. tonumber( tostring( GetGameTime() ) ) .. ' "", );')
        AddIfNotHasValue( vipPlayers, player:GetAccountId() )
        player:SendBroadcastMessage("VIP mode was activated.")
        return true
    else
        player:SendBroadcastMessage("You do not own the required item.")
        return true
    end
end

local function VIPTeleport( player )
    if not player then
        return
    end

    if player:IsInCombat() then
        player:SendBroadcastMessage( 'This command can not be used in combat.' )
        return true
    end

    if HasValue( Config.maps, player:GetMapId() ) then
        player:Teleport( Config.VipMap, Config.VipX, Config.VipY, Config.VipZ, Config.VipO )
    else
        player:SendBroadcastMessage( 'This command can not be used here.' )
    end
    return true
end

local function GiveVIPKey( player )
    if not player then
        return false
    end

    if not player:HasItem( Config.keyItemEntry, 1, true ) then
        player:Additem( Config.keyItemEntry, 1 )
    else
        player:SendBroadcastMessage('You already own this item.')
    end
    return true
end

local function VIPmorph( player, displayId)
    if not player then
        return
    end

    if not displayId then
        return
    end

    if HasValue( Config.morphs, displayId ) then
        player:SetDisplayId( displayId )
    else
        player:SendBroadcastMessage( displayId .. ' is not an allowed model.')
    end
end

local function Command( event, player, command, chatHandler )
    local commandArray = {}

    if not command then
        return
    end

    -- split the command variable into several strings which can be compared individually
    commandArray = SplitString( command )

    if commandArray[1] ~= 'vip' then
        return
    end

    if commandArray[2] == 'activate' then
        if ActivateVIP( player ) then
            return false
        end
    end

    -- prevent going further if not GM or VIP
    if not HasValue( vipPlayers, player:GetAccountId() ) or chatHandler:IsAvailable( Config.GMCommandLevel ) then
        return
    end

    if commandArray[2] == 'buffs' then
        -- todo: should open a gossip where the player can choose various buffs from to cast on themselfes
    end

    if commandArray[2] == 'respawn' then
        -- todo: revive the targeted NPC
    end

    if commandArray[2] == 'island' then
        if VIPTeleport( player ) then
            return false
        else
            return
        end
    end

    if commandArray[2] == 'changerace' then
        RunCommand( 'character changerace ' .. player:GetName() )
    end

    if commandArray[2] == 'changefaction' then
        RunCommand( 'character changefaction ' .. player:GetName() )
    end

    if commandArray[2] == 'customize' then
        RunCommand( 'character customize ' .. player:GetName() )
    end

    if commandArray[2] == 'morph' then
        -- todo: allow the player to morph into an appearance listed in Config.morphs
        if VIPMorph( player, commandArray[3] ) then
            return true
        else
            return
        end
    end

    if commandArray[2] == 'key' then
        if GiveVIPKey( player ) then
            return false
        else
            return
        end
    end

    if commandArray[2] == 'maxskills' then
        -- Grant highest possible weapon skills
        player:AdvanceSkillsToMax()
    end
end

-- On Startup:
-- Fill the array which stores all VIP account ids
local data_SQL
local row
data_SQL = CharDBQuery('SELECT * FROM `'..Config.customDbName..'`.`vip_accounts`;')

if data_SQL ~= nil then
    repeat
        row = data_SQL:GetRow()
        if row.activated > 0 then
            AddIfNotHasValue( vipPlayers, row.account_id )
        end
    until not data_SQL:NextRow()
else
    PrintError("lua-vip: vip_accounts is empty.")
end

RegisterPlayerEvent( PLAYER_EVENT_ON_COMMAND, Command )
