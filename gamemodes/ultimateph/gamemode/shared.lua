include("cl_colors.lua")
local PlayerMeta = FindMetaTable("Player")
local tabFile = file.Read(GM.Folder .. "/ultimateph.txt", "GAME") || ""
local tab = util.KeyValuesToTable(tabFile)

GM.Name = tab["title"] || "Prop Hunters - Utlimate Edition"
GM.Author = "DataNext, Zikaeroh, MechanicalMind"
-- Credits to waddlesworth for the logo and icon
GM.Email 	= "N/A"
GM.Website = "N/A"
GM.Version = tab["version"] || "unknown"

ROUND_WAIT = 1
ROUND_HIDE = 2
ROUND_SEEK = 3
ROUND_POST = 4
ROUND_MAPVOTE = 5

TEAM_SPEC = 1
TEAM_HUNTER = 2
TEAM_PROP = 3

WIN_NONE = TEAM_SPEC
WIN_HUNTER = TEAM_HUNTER
WIN_PROP = TEAM_PROP

function PlayerMeta:IsSpectator() return self:Team() == TEAM_SPEC end
function PlayerMeta:IsHunter() return self:Team() == TEAM_HUNTER end
function PlayerMeta:IsProp() return self:Team() == TEAM_PROP end

GM.GameState = GAMEMODE && GAMEMODE.GameState || ROUND_WAIT

team.SetUp(TEAM_SPEC, "Spectators", PHWhite, false) -- Setting Joinable to false allows us to use team.BestAutoJoinTeam and have it only include the Hunters/Props teams.
team.SetUp(TEAM_HUNTER, "Hunters", PHBlue)
team.SetUp(TEAM_PROP, "Props", PHRed)

function GM:GetGameState()
	return self.GameState
end

function GM:PlayerSetNewHull(ply, s, hullz, duckz)
	self:PlayerSetHull(ply, s, s, hullz, duckz)
end

function GM:PlayerSetHull(ply, hullx, hully, hullz, duckz)
	hullx = hullx || 16
	hully = hully || 16
	hullz = hullz || 72
	duckz = duckz || hullz / 2
	ply:SetHull(Vector(-hullx, -hully, 0), Vector(hullx, hully, hullz))
	ply:SetHullDuck(Vector(-hullx, -hully, 0), Vector(hullx, hully, duckz))

	if SERVER then
		net.Start("hull_set")
		net.WriteEntity(ply)
		net.WriteFloat(hullx)
		net.WriteFloat(hully)
		net.WriteFloat(hullz)
		net.WriteFloat(duckz)
		net.Broadcast()
		-- TODO send on player spawn
	end
end

function GM:EntityEmitSound(t)
	if not GetConVar("ph_hunter_deaf_onhiding"):GetBool() or self:GetGameState() ~= ROUND_HIDE then
		return
	end

	for _, ply in ipairs(player.GetHumans()) do -- ipairs is preferred when working with tables. player.GetHumans() to ignore bots
		if not ply:IsHunter() then
			continue -- if the player is not a hunter, ignore them
		end

		return false
	end
end

function GM:PlayerFootstep( ply, pos, foot, sound, volume, filter )
	if not GetConVar("ph_props_silent_footsteps"):GetBool() or not ply:IsProp() then
		return
	end

	return true
end

hook.Add('CalcMainActivity', 'PropTpose', function(ply)
	if not GetConVar("ph_props_tpose"):GetBool() or not ply:IsProp() then
		return
	end

	return ACT_INVALID
end)
