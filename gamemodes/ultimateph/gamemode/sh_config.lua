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

-- misc.
CornerRadius = "4" -- set to 0 to disable rounded corners. number is in pixels relative to 480p.
ScobBackground = true -- set to false to disable scoreboard background & credits
GroupTags = false -- set to true to enable group tags. requires ULX
ActEnableAll = false -- set to true to enable all default gmod animations
NameDistance = 500 -- adjusts how close you need to be to see a player's name

GroupColors = {}
GroupColors["superadmin"] = PHRed
GroupColors["user"] = PHBlue

GroupNames = {}
GroupNames["superadmin"] = "Super Admin"

GroupIcons = {}
GroupIcons["superadmin"] = "icon16/award_star_gold_1.png"

-- ulx admin commands to add to the scoreboard click menu. the first bit is the console command, the second is the name to show
ULXCommands = {}
ULXCommands["ulx ph_teamswitch"] = "Team Switch"

-- it is ideal to delete undesired options rather than setting to false. see https://wiki.facepunch.com/gmod/Enums/ACT
ActWhitelist = {}
ActWhitelist[ACT_GMOD_GESTURE_BOW] = true
ActWhitelist[ACT_GMOD_GESTURE_WAVE] = true
ActWhitelist[ACT_GMOD_GESTURE_AGREE] = true
ActWhitelist[ACT_GMOD_GESTURE_BECON] = true
ActWhitelist[ACT_GMOD_GESTURE_DISAGREE] = true
ActWhitelist[ACT_GMOD_GESTURE_TAUNT_ZOMBIE] = true
ActWhitelist[ACT_GMOD_TAUNT_LAUGH] = true
ActWhitelist[ACT_GMOD_TAUNT_CHEER] = true
ActWhitelist[ACT_GMOD_TAUNT_DANCE] = true
ActWhitelist[ACT_GMOD_TAUNT_ROBOT] = true
ActWhitelist[ACT_GMOD_TAUNT_SALUTE] = true
ActWhitelist[ACT_GMOD_TAUNT_MUSCLE] = true
ActWhitelist[ACT_GMOD_TAUNT_PERSISTENCE] = true
ActWhitelist[ACT_SIGNAL_HALT] = true
ActWhitelist[ACT_SIGNAL_GROUP] = true
ActWhitelist[ACT_SIGNAL_FORWARD] = true

-- set which HUD elements to hide. see https://wiki.facepunch.com/gmod/HUD_Element_List
-- gamemode-added elements include "PropHuntersPlayerNames", 
HudBlacklist = {}
HudBlacklist["CHudVoiceSelfStatus"] = true -- you should probably leave this one alone. disabling the custom voice panel is no currently supported
HudBlacklist["CHudVoiceStatus"] = true -- same deal here
