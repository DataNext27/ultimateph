concommand.Add("ph_jointeam", function(ply, com, args)
	local newTeam = tonumber(args[1]) || TEAM_SPEC -- Default to spectators if there's a problem
	if ply:Team() == newTeam then return end

	-- Always able to join spectator team
	-- Can join team hunter or team prop if team sizes are equal
	-- Otherwise, can only join the smaller team
	if newTeam == TEAM_SPEC || team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP) == 0 || newTeam == team.BestAutoJoinTeam() then
		if ply:Alive() then ply:Kill() end
		ply:SetTeam(newTeam)
		GlobalChatMsg(ply:Nick(), " changed team to ", team.GetColor(newTeam), team.GetName(newTeam))
		-- inform the client, currently only for scob updates
		net.Start("TeamChanged")
		net.WriteEntity(ply)
		net.Broadcast()
	else
		ply:PlayerChatMsg("Team full, you cannot join")
	end
end)

function GM:BalanceTeams()
	if !self.AutoTeamBalance:GetBool() && self.NumberHunter:GetInt() < (player.GetCount() + 1) then
		local tabProps = team.GetPlayers(TEAM_PROP)

		local nbHunters = self.NumberHunter:GetInt()

		while team.NumPlayers(TEAM_HUNTER) > nbHunters do
			local players = team.GetPlayers(TEAM_HUNTER)
			local ply = players[math.random(#players)]
			ply:SetTeam(TEAM_PROP)
		end

		for k, ply in pairs(tabProps) do
			if ply:Team() == TEAM_HUNTER then
				ply:SetTeam(TEAM_PROP)
			end
		end
	elseif !self.AutoTeamBalance:GetBool() && (self.NumberHunter:GetInt() > (player.GetCount() + 1)) then
		GlobalChatMsg("There is not enough players to have ", self.NumberHunter:GetInt(), " hunters. Now using Auto Team Balance until there is enough players")

		local teamDiff = team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP)
		if math.abs(teamDiff) <= 1 then return end -- Only balance if teams are off by 2 or more players

		local biggerTeam, smallerTeam = TEAM_PROP, TEAM_HUNTER -- Assume props had more players
		if teamDiff > 1 then -- teamDiff > 1 means hunters had more players
			biggerTeam = TEAM_HUNTER
			smallerTeam = TEAM_PROP
		end

		-- Continuously swap random players from biggerTeam to smallerTeam until sizes are balanced
		teamDiff = math.abs(teamDiff)
		while teamDiff > 1 do
			local players = team.GetPlayers(biggerTeam)
			local ply = players[math.random(#players)]
			ply:SetTeam(smallerTeam)
			GlobalChatMsg(ply:Nick(), " team balanced to ", team.GetColor(smallerTeam), team.GetName(smallerTeam))
			teamDiff = teamDiff - 2
		end
	else
		local teamDiff = team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP)
		if math.abs(teamDiff) <= 1 then return end -- Only balance if teams are off by 2 or more players

		local biggerTeam, smallerTeam = TEAM_PROP, TEAM_HUNTER -- Assume props had more players
		if teamDiff > 1 then -- teamDiff > 1 means hunters had more players
			biggerTeam = TEAM_HUNTER
			smallerTeam = TEAM_PROP
		end

		-- Continuously swap random players from biggerTeam to smallerTeam until sizes are balanced
		teamDiff = math.abs(teamDiff)
		while teamDiff > 1 do
			local players = team.GetPlayers(biggerTeam)
			local ply = players[math.random(#players)]
			ply:SetTeam(smallerTeam)
			GlobalChatMsg(ply:Nick(), " team balanced to ", team.GetColor(smallerTeam), team.GetName(smallerTeam))
			teamDiff = teamDiff - 2
		end
	end
end

function GM:SwapTeams()
	for _, ply in pairs(player.GetAll()) do
		if ply:IsHunter() then
			ply:SetTeam(TEAM_PROP)
		elseif ply:IsProp() then
			ply:SetTeam(TEAM_HUNTER)
		end
	end

	GlobalChatMsg(Color(50, 220, 150), "Teams have been swapped")
end

-- former sv_spectate.lua
local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:CSpectate(mode, spectatee)
	mode = mode || OBS_MODE_IN_EYE
	self:Spectate(mode)
	if IsValid(spectatee) then
		self:SpectateEntity(spectatee)
		self.Spectatee = spectatee
	else
		self:SpectateEntity(Entity(-1))
		self.Spectatee = nil
	end

	self.SpectateMode = mode
	self.Spectating = true
	net.Start("spectating_status")
	net.WriteInt(self.SpectateMode || -1, 8)
	net.WriteEntity(self.Spectatee || Entity(-1))
	net.Send(self)
end

function PlayerMeta:UnCSpectate(mode, spectatee)
	self:UnSpectate()
	self.SpectateMode = nil
	self.Spectatee = nil
	self.Spectating = false
	net.Start("spectating_status")
	net.WriteInt(-1, 8)
	net.WriteEntity(Entity(-1))
	net.Send(self)
end

function PlayerMeta:IsCSpectating()
	return self.Spectating
end

function PlayerMeta:GetCSpectatee()
	return self.Spectatee
end

function PlayerMeta:GetCSpectateMode()
	return self.SpectateMode
end

function GM:SpectateThink()
	for k, ply in pairs(player.GetAll()) do
		if ply:IsCSpectating() && IsValid(ply:GetCSpectatee()) && (!ply.LastSpectatePosSet || ply.LastSpectatePosSet < CurTime()) then
			ply.LastSpectatePosSet = CurTime() + 0.25
			ply:SetPos(ply:GetCSpectatee():GetPos())
		end
	end
end

function GM:SpectateNext(ply, direction)
	direction = direction || 1
	local players = {}
	local index = 1
	for k, v in pairs(player.GetAll()) do
		if v != ply then
			-- can only spectate same team and alive
			if v:Alive() && (v:Team() == ply:Team() || ply:IsSpectator()) then
				table.insert(players, v)
				if v == ply:GetCSpectatee() then
					index = #players
				end
			end
		end
	end

	if #players > 0 then
		index = index + direction
		if index > #players then
			index = 1
		end

		if index < 1 then
			index = #players
		end

		local ent = players[index]
		if IsValid(ent) then
			if ent:IsPlayer() && ent:IsHunter() then
				ply:CSpectate(OBS_MODE_IN_EYE, ent)
			else
				ply:CSpectate(OBS_MODE_CHASE, ent)
			end
		else
			if IsValid(ply:GetRagdollEntity()) then
				if ply:GetCSpectatee() != ply:GetRagdollEntity() then
					ply:CSpectate(OBS_MODE_CHASE, ply:GetRagdollEntity())
				end
			else
				ply:CSpectate(OBS_MODE_ROAMING)
			end
		end
	else
		if IsValid(ply:GetRagdollEntity()) then
			if ply:GetCSpectatee() != ply:GetRagdollEntity() then
				ply:CSpectate(OBS_MODE_CHASE, ply:GetRagdollEntity())
			end
		else
			ply:CSpectate(OBS_MODE_ROAMING)
		end
	end
end

function GM:ChooseSpectatee(ply)
	if !ply.SpectateTime || ply.SpectateTime < CurTime() then
		if ply:KeyPressed(IN_JUMP) then
			if ply:GetCSpectateMode() != OBS_MODE_ROAMING && (ply:IsSpectator() || self.DeadSpectateRoam:GetBool()) then
				ply:CSpectate(OBS_MODE_ROAMING)
			end
		else
			local direction
			if ply:KeyPressed(IN_ATTACK) then
				direction = 1
			elseif ply:KeyPressed(IN_ATTACK2) then
				direction = -1
			end

			if direction then
				self:SpectateNext(ply, direction)
			end
		end
	end

	-- if invalid or dead
	if !IsValid(ply:GetCSpectatee()) && ply:GetCSpectateMode() != OBS_MODE_ROAMING then
		self:SpectateNext(ply)
	end
end
