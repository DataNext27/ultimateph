-- NOTE: Make sure to sync default changes over to ULX.
GM.VoiceHearTeam = CreateConVar("ph_voice_hearotherteam", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Can we hear the voices of opposing teams")
GM.VoiceHearDead = CreateConVar("ph_voice_heardead", 1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Can we hear the voices of dead players and spectators")
GM.DeadSpectateRoam = CreateConVar("ph_dead_canroam", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Can dead players use the roam spectate mode")

GM.RoundLimit = CreateConVar("ph_roundlimit", 10, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Number of rounds before mapvote")
GM.RoundTime = CreateConVar("ph_roundtime", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Time limit before ending the round (0 for automatic time)")
GM.StartWaitTime = CreateConVar("ph_mapstartwait", 30, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Number of seconds to wait for players on map start before starting round")
GM.HidingTime = CreateConVar("ph_hidingtime", 30, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Time before hunters are released")
GM.PostRoundTime = CreateConVar("ph_postroundtime", 15, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Time before next round after end of the round")
GM.MapTimeLimit = CreateConVar("ph_map_time_limit", -1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Minutes before declaring the next round to be the last round (-1 to disable)")

GM.HunterDamagePenalty = CreateConVar("ph_hunter_dmgpenalty", 3, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Amount of damage a hunter should take for shooting an incorrect prop")
GM.HunterGrenadeAmount = CreateConVar("ph_hunter_smggrenades", 1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Amount of SMG grenades hunters should spawn with")
GM.HunterDeafOnHiding = CreateConVar("ph_hunter_deaf_onhiding", 1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Set if hunters can hear while props are hiding (during black screen)")
GM.HunterAimRay = CreateConVar("ph_hunter_aim_laser", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "0 for none, 1 for spectators, 2 for props and spectators")

GM.PropsWinStayProps = CreateConVar("ph_props_onwinstayprops", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "If the props win, they stay on the props team")
GM.PropsSmallSize = CreateConVar("ph_props_small_size", 200, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Size that speed penalty for small size starts to apply (0 to disable)")
GM.PropsJumpPower = CreateConVar("ph_props_jumppower", 1.2, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Jump power bonus for when props are disguised")
GM.PropsCamDistance = CreateConVar("ph_props_camdistance", 1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "The camera distance multiplier for props when disguised")
GM.PropsSilentFootsteps = CreateConVar("ph_props_silent_footsteps", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Does props emit footsteps sounds while moving")
GM.PropTpose = CreateConVar("ph_props_tpose", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Should props be fully animated or Tpose")
GM.PropUndisguisedThirdperson = CreateConVar("ph_props_undisguised_thirdperson", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Should props start in thirdperson")

GM.AutoTeamBalance = CreateConVar("ph_auto_team_balance", 1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Automatically balance teams")
GM.NumberHunter = CreateConVar("ph_nb_hunter", 2, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Set the maximum number of hunters, only works if auto team balance is disable")

GM.TauntMenuPhrase = CreateConVar("ph_taunt_menu_phrase", TauntMenuPhrase, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Phrase shown at the top of the taunt menu")
GM.AutoTauntEnabled = CreateConVar("ph_auto_taunt", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "1 if auto taunts should be enabled")
GM.AutoTauntMin = CreateConVar("ph_auto_taunt_delay_min", 60, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Mininum time to go without taunting")
GM.AutoTauntMax = CreateConVar("ph_auto_taunt_delay_max", 120, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Maximum time to go without taunting")
GM.AutoTauntPropsOnly = CreateConVar("ph_auto_taunt_props_only", 1, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Enable auto taunt for props only")

GM.Secrets =  CreateConVar("ph_secrets", 0, bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE), "Enable secrets")
