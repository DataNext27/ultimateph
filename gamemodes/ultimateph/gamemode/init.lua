AddCSLuaFile("shared.lua")

local rootFolder = (GM || GAMEMODE).Folder:sub(11) .. "/gamemode/"

-- add cs lua all the cl_ and sh_ files
local files = file.Find(rootFolder .. "*", "LUA")
for k, v in pairs(files) do
	if v:sub(1, 3) == "cl_" || v:sub(1, 3) == "sh_" then
		AddCSLuaFile(rootFolder .. v)
	end
end

util.AddNetworkString("clientIPE")
util.AddNetworkString("ph_openhelpmenu")
util.AddNetworkString("player_model_sex")

include("sv_chatmsg.lua")
include("shared.lua")
include("sv_ragdoll.lua")
include("sv_playercolor.lua")
include("sv_player.lua")
include("sv_realism.lua")
include("sv_rounds.lua")
include("sv_spectate.lua")
include("sv_respawn.lua")
include("sv_health.lua")
include("sv_killfeed.lua")
include("sv_disguise.lua")
include("sv_teams.lua")
include("sv_taunt.lua")
include("sv_mapvote.lua")
include("sv_bannedmodels.lua")
include("sv_version.lua")
include("sh_init.lua")

resource.AddFile("materials/husklesph/skull.png")
resource.AddFile("sound/husklesph/hphaaaaa2.mp3")

function GM:Initialize()
	self.RoundWaitForPlayers = CurTime()
	self.DeathRagdolls = {}
	self:LoadMapList()
	self:LoadBannedModels()
	self:StartAutoTauntTimer()
end

hook.Add("Think", "StartupVersionCheck", function()
	hook.Remove("Think", "StartupVersionCheck")
	GAMEMODE:CheckForNewVersion()
end)

function GM:InitPostEntity()
	self:InitPostEntityAndMapCleanup()

	RunConsoleCommand("mp_show_voice_icons", "0")
end

function GM:InitPostEntityAndMapCleanup()
	for k, ent in pairs(ents.GetAll()) do
		if ent:GetClass():find("door") then
			ent:Fire("unlock", "", 0)
		end
	end
end

function GM:Think()
	self:RoundsThink()
	self:SpectateThink()
end

function GM:PlayerNoClip(ply)
	timer.Simple(0, function() ply:CalculateSpeed() end)
	return ply:IsSuperAdmin() || ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:EntityTakeDamage(ent, dmginfo)
	if IsValid(ent) then
		if ent:IsPlayer() then
			if IsValid(dmginfo:GetAttacker()) then
				local attacker = dmginfo:GetAttacker()
				if attacker:IsPlayer() then
					if attacker:Team() == ent:Team() then
						return true
					end
				end
			end
		end

		if ent:IsDisguisableAs() then
			local att = dmginfo:GetAttacker()
			if IsValid(att) && att:IsPlayer() && att:IsHunter() then
				if bit.band(dmginfo:GetDamageType(), DMG_CRUSH) != DMG_CRUSH then
					local tdmg = DamageInfo()
					tdmg:SetDamage(math.min(dmginfo:GetDamage(), math.max(self.HunterDamagePenalty:GetInt(), 1)))
					tdmg:SetDamageType(DMG_AIRBOAT)
					tdmg:SetDamageForce(Vector(0, 0, 0))
					att:TakeDamageInfo(tdmg)

					-- increase stat for end of round (Angriest Hunter)
					att.PropDmgPenalty = (att.PropDmgPenalty || 0) + tdmg:GetDamage()
				end
			end
		end
	end
end

function file.ReadDataAndContent(path)
	local f = file.Read(path, "DATA")
	if f then return f end
	f = file.Read(GAMEMODE.Folder .. "/content/data/" .. path, "GAME")
	return f
end

function GM:CleanupMap()
	game.CleanUpMap()
	hook.Call("InitPostEntityAndMapCleanup", self)
	hook.Call("MapCleanup", self)
end

function GM:ShowHelp(ply)
	net.Start("ph_openhelpmenu")
	net.Send(ply)
end

function GM:ShowSpare1(ply)
	net.Start("open_taunt_menu")
	net.Send(ply)
end
