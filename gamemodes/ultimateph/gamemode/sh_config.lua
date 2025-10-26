-- color
PHScobDark = Color(55, 55, 55, 120) -- scoreboard playerlist
PHScobDarker = Color(68, 68, 68, 120) -- scoreboard header
PHScobDarkest = Color(40, 40, 40, 230) -- scoreboard background
PHScobBlack =  Color(0, 0, 0, 230) -- scoreboard boarder

PHEndDark = Color(20, 20, 20, 150) -- endround playerlist
PHEndDarker = Color(60, 60, 60, 230) -- end round board background, close button hover
PHEndDarkest = Color(40, 40, 40, 230) -- endboard header
PHEndBlack = Color(0, 0, 0, 230) -- endround boarder
PHEndGray = Color(50, 50, 50, 50) -- mapvote hover

PHTauntDark = Color(68, 68, 68, 160) -- taunt buttons
PHTauntDarker = Color(40, 40, 40, 230) -- side panel & title bar
PHTauntDarkest = Color(55, 55, 55, 120) -- taunt list background
PHTauntBlack = Color(0, 0, 0, 230) -- taunt outline

PHWhite = Color(255, 255, 255, 255) -- text
PHLessWhite = Color(190, 190, 190) -- subtext

PHRed = Color(199, 49, 29) -- error, disguise outline, scoreboard text
PHOrange = Color(255, 150, 50) -- hunters
PHGreen = Color(50, 170, 46) -- aim lazer
PHBlue = Color(50, 150, 255) -- props

PHProps = PHBlue
PHHunters = PHOrange
PHScobTextCol = PHRed

-- misc.
PHCornerRadius = "0" -- set to 0 to disable rounded corners. number is in pixels relative to 480p.
PHScobBackground = true -- set to false to disable scoreboard background & credits
PHGroupTags = true -- set to true to enable group tags. requires ULX
PHActEnableAll = false -- set to true to enable all default gmod animations
PHNameDistance = 500 -- adjusts how close you need to be to see a player's name
PHScobText = GM.Name

PHGroupColors = {}
PHGroupColors["superadmin"] = PHRed
PHGroupColors["user"] = PHBlue

PHGroupNames = {}
PHGroupNames["superadmin"] = "Super Admin"

PHGroupIcons = {}
PHGroupIcons["superadmin"] = "icon16/award_star_gold_1.png"

-- ulx admin commands to add to the scoreboard click menu. the first bit is the console command, the second is the name to show
PHULXCommands = {}
PHULXCommands["ulx ph_teamswitch"] = "Team Switch"

-- it is ideal to delete undesired options rather than setting to false. see https://wiki.facepunch.com/gmod/Enums/ACT
PHActWhitelist = {}
PHActWhitelist[ACT_GMOD_GESTURE_BOW] = true
PHActWhitelist[ACT_GMOD_GESTURE_WAVE] = true
PHActWhitelist[ACT_GMOD_GESTURE_AGREE] = true
PHActWhitelist[ACT_GMOD_GESTURE_BECON] = true
PHActWhitelist[ACT_GMOD_GESTURE_DISAGREE] = true
PHActWhitelist[ACT_GMOD_GESTURE_TAUNT_ZOMBIE] = true
PHActWhitelist[ACT_GMOD_TAUNT_LAUGH] = true
PHActWhitelist[ACT_GMOD_TAUNT_CHEER] = true
PHActWhitelist[ACT_GMOD_TAUNT_DANCE] = true
PHActWhitelist[ACT_GMOD_TAUNT_ROBOT] = true
PHActWhitelist[ACT_GMOD_TAUNT_SALUTE] = true
PHActWhitelist[ACT_GMOD_TAUNT_MUSCLE] = true
PHActWhitelist[ACT_GMOD_TAUNT_PERSISTENCE] = true
PHActWhitelist[ACT_SIGNAL_HALT] = true
PHActWhitelist[ACT_SIGNAL_GROUP] = true
PHActWhitelist[ACT_SIGNAL_FORWARD] = true

-- set which HUD elements to hide. see https://wiki.facepunch.com/gmod/HUD_Element_List
-- gamemode-added elements include "PropHuntersPlayerNames", 
PHHudBlacklist = {}
PHHudBlacklist["CHudVoiceSelfStatus"] = true -- you should probably leave this one alone. disabling the custom voice panel is no currently supported
PHHudBlacklist["CHudVoiceStatus"] = true -- same deal here

-- prevent players from being hurt by select map entities. see https://developer.valvesoftware.com/wiki/List_of_entities
PHDamageBlacklist = {}
PHDamageBlacklist["trigger_hurt"] = true
PHDamageBlacklist["env_fire"] = true
PHDamageBlacklist["func_door"] = true

-- some ON_USE entities can be spammed to the point nobody can enter! prevent it here
PHAntiExploit = {}
PHAntiExploit["func_door"] = true
PHAntiExploit["func_door_rotating"] = true
PHAntiExploit["prop_door_rotating"] = true

-- sounds in this table will be played at random when pushing players
PHPushSounds = {}
PHPushSounds[1] = "physics/body/body_medium_impact_hard1.wav"
PHPushSounds[2] = "physics/body/body_medium_impact_hard2.wav"
PHPushSounds[3] = "physics/body/body_medium_impact_hard3.wav"
PHPushSounds[4] = "physics/body/body_medium_impact_hard5.wav"
PHPushSounds[5] = "physics/body/body_medium_impact_hard6.wav"
PHPushSounds[6] = "physics/body/body_medium_impact_soft5.wav"
PHPushSounds[7] = "physics/body/body_medium_impact_soft6.wav"
PHPushSounds[8] = "physics/body/body_medium_impact_soft7.wav"
