-- former sv_chatmsg.lua
local PlayerMeta = FindMetaTable("Player")

-- Sends a message to an individual player.
function PlayerMeta:PlayerChatMsg(...)
	net.Start("ph_chatmsg")
	net.WriteTable({...})
	net.Send(self)
end

-- Sends a message to every player.
function GlobalChatMsg(...)
	net.Start("ph_chatmsg")
	net.WriteTable({...})
	net.Broadcast()
end

-- former sv_health.lua
local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:SetHMaxHealth(amo)
	self.HMaxHealth = amo
	self:SetNWFloat("HMaxHealth", amo)
	self:SetMaxHealth(amo)
end

function PlayerMeta:GetHMaxHealth()
	return self.HMaxHealth || 100
end

-- former sv_playercolor.lua
local EntityMeta = FindMetaTable("Entity")

function EntityMeta:GetPlayerColor()
	return self.playerColor || Vector()
end

function EntityMeta:SetPlayerColor(vec)
	self.playerColor = vec
	self:SetNWVector("playerColor", vec)
end

-- former sv_realism.lua
function GM:RealismThink()
	for k, ply in pairs(player.GetAll()) do
		if ply:Alive() then
			-- don't increase velocity when jumping off ground
			if ply:KeyPressed(IN_JUMP) && ply.PrevOnGround then
				ply.LastJump = CurTime()

				local curVel = ply:GetVelocity()
				local newVel = ply.PrevSpeed * 1
				newVel.z = curVel.z
				ply:SetLocalVelocity(newVel)
			end

			ply.PrevSpeed = ply:GetVelocity()
			ply.PrevOnGround = ply:OnGround()
		end
	end
end

-- minimum velocity to trigger function is 530
function GM:GetFallDamage(ply, vel)
	if vel > 530 then
		local minvel = vel - 530
		local dmg = math.ceil(minvel / 278 * GAMEMODE.FallDMGMult:GetInt())
		if GAMEMODE.FallDMGNonLethal:GetBool() && ply:Health() <= dmg then dmg = ply:Health() - 1 end
		return dmg
	end
end

-- former sv_respawn.lua
function GM:CanRespawn(ply)
	if ply:IsSpectator() then
		return false
	end

	if self:GetGameState() == ROUND_WAIT or self:GetGameState() == ROUND_HIDE then
		if ply.NextSpawnTime && ply.NextSpawnTime > CurTime() then return end

		if ply:KeyPressed(IN_JUMP) || ply:KeyPressed(IN_ATTACK) then
			return true
		end
	end

	return false
end

-- former sv_ragdoll.lua
local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

local dtypes = {}
dtypes[DMG_GENERIC] = ""
dtypes[DMG_CRUSH] = "Blunt Force"
dtypes[DMG_BULLET] = "Bullet"
dtypes[DMG_SLASH] = "Laceration"
dtypes[DMG_BURN] = "Fire"
dtypes[DMG_VEHICLE] = "Blunt Force"
dtypes[DMG_FALL] = "Fall force"
dtypes[DMG_BLAST] = "Explosion"
dtypes[DMG_CLUB] = "Blunt Force"
dtypes[DMG_SHOCK] = "Shock"
dtypes[DMG_SONIC] = "Sonic"
dtypes[DMG_ENERGYBEAM] = "Enery"
dtypes[DMG_DROWN] = "Hydration"
dtypes[DMG_PARALYZE] = "Paralyzation"
dtypes[DMG_NERVEGAS] = "Nervegas"
dtypes[DMG_POISON] = "Poison"
dtypes[DMG_RADIATION] = "Radiation"
dtypes[DMG_DROWNRECOVER] = ""
dtypes[DMG_ACID] = "Acid"
dtypes[DMG_PLASMA] = "Plasma"
dtypes[DMG_AIRBOAT] = "Energy"
dtypes[DMG_DISSOLVE] = "Energy"
dtypes[DMG_BLAST_SURFACE] = ""
dtypes[DMG_DIRECT] = "Fire"
dtypes[DMG_BUCKSHOT] = "Bullet"

local DeathRagdollsPerPlayer = 3
local DeathRagdollsPerServer = 22

if !PlayerMeta.CreateRagdollOld then
	PlayerMeta.CreateRagdollOld = PlayerMeta.CreateRagdoll
end

function PlayerMeta:CreateRagdoll(attacker, dmginfo)
	local ent = self:GetNWEntity("DeathRagdoll")

	-- remove old player ragdolls
	if !self.DeathRagdolls then self.DeathRagdolls = {} end

	local countPlayerRagdolls = 1
	for k, rag in pairs(self.DeathRagdolls) do
		if IsValid(rag) then
			countPlayerRagdolls = countPlayerRagdolls + 1
		else
			self.DeathRagdolls[k] = nil
		end
	end

	if DeathRagdollsPerPlayer >= 0 && countPlayerRagdolls > DeathRagdollsPerPlayer then
		for i = 0, countPlayerRagdolls do
			if countPlayerRagdolls > DeathRagdollsPerPlayer then
				self.DeathRagdolls[1]:Remove()
				table.remove(self.DeathRagdolls, 1)
				countPlayerRagdolls = countPlayerRagdolls - 1
			else
				break
			end
		end
	end

	-- remove old server ragdolls
	local c2 = 1
	for k, rag in pairs(GAMEMODE.DeathRagdolls) do
		if IsValid(rag) then
			c2 = c2 + 1
		else
			GAMEMODE.DeathRagdolls[k] = nil
		end
	end

	if DeathRagdollsPerServer >= 0 && c2 > DeathRagdollsPerServer then
		for i = 0, c2 do
			if c2 > DeathRagdollsPerServer then
				GAMEMODE.DeathRagdolls[1]:Remove()
				table.remove(GAMEMODE.DeathRagdolls, 1)
				c2 = c2 - 1
			else
				break
			end
		end
	end

	local Data = duplicator.CopyEntTable(self)
	if !util.IsValidRagdoll(Data.Model) then
		return
	end

	local ent = ents.Create("prop_ragdoll")
	duplicator.DoGeneric(ent, Data)
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	ent:Fire("kill", "", 60 * 8)
	if ent.SetPlayerColor then
		ent:SetPlayerColor(self:GetPlayerColor())
	end

	ent:SetNWEntity("RagdollOwner", self)

	ent.Corpse = {}
	ent.Corpse.Name = self:Nick()
	ent.Corpse.CauseDeath = ""
	ent.Corpse.Attacker = ""
	if IsValid(attacker) && attacker:IsPlayer() then
		if attacker == self then
			if ent.Corpse.CauseDeath == "" then
				ent.Corpse.CauseDeath = "Suicide"
			end
		else
			ent.Corpse.Attacker = attacker:Nick()
		end
		-- inflicter doesn't work, do on GM:PlayerDeath
	end

	-- set velocities
	local Vel = self:GetVelocity()
	local iNumPhysObjects = ent:GetPhysicsObjectCount()
	for Bone = 0, iNumPhysObjects-1 do
		local PhysObj = ent:GetPhysicsObjectNum(Bone)
		if IsValid(PhysObj) then
			local Pos, Ang = self:GetBonePosition(ent:TranslatePhysBoneToBone(Bone))
			PhysObj:SetPos(Pos)
			PhysObj:SetAngles(Ang)
			PhysObj:AddVelocity(Vel)
		end
	end

	-- finish up
	self:SetNWEntity("DeathRagdoll", ent)
	table.insert(self.DeathRagdolls, ent)
	table.insert(GAMEMODE.DeathRagdolls, ent)
end

if !PlayerMeta.GetRagdollEntityOld then
	PlayerMeta.GetRagdollEntityOld = PlayerMeta.GetRagdollEntity
end

function PlayerMeta:GetRagdollEntity()
	local ent = self:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollEntityOld()
end

if !PlayerMeta.GetRagdollOwnerOld then
	PlayerMeta.GetRagdollOwnerOld = PlayerMeta.GetRagdollOwner
end

function EntityMeta:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")
	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollOwnerOld()
end

-- former sv_killfeed.lua
local DMG_CLUB_GENERIC = bit.bor(DMG_CLUB, DMG_GENERIC)
local DMG_SLOWBURN_BURN = bit.bor(DMG_SLOWBURN, DMG_BURN)
local DMG_BLAST_SURFACE_BLAST = bit.bor(DMG_BLAST_SURFACE, DMG_BLAST)
local DMG_SONIC_SHOCK = bit.bor(DMG_SONIC, DMG_SHOCK)
local DMG_PLASMA_ENERGYBEAM = bit.bor(DMG_PLASMA, DMG_ENERGYBEAM)
local DMG_NERVEGAS_POISON = bit.bor(DMG_NERVEGAS, DMG_POISON)
local DMG_DISSOLVE_ACID = bit.bor(DMG_DISSOLVE, DMG_ACID)

local attackedMessages = {}
attackedMessages[DMG_CLUB_GENERIC] = {"killed", "destroyed"}
attackedMessages[DMG_CRUSH] = {"threw a prop at", "crushed"}
attackedMessages[DMG_BULLET] = {"shot", "fed lead to"}
attackedMessages[DMG_SLASH] = {"cut", "sliced"}
attackedMessages[DMG_SLOWBURN_BURN] = {"incinerated", "cooked"}
attackedMessages[DMG_VEHICLE] = {"ran over", "flattened"}
attackedMessages[DMG_FALL] = {"pushed", "tripped"}
attackedMessages[DMG_BLAST_SURFACE_BLAST] = {"blew up", "blasted"}
attackedMessages[DMG_SONIC_SHOCK] = {"electrocuted", "zapped"}
attackedMessages[DMG_PLASMA_ENERGYBEAM] = {"atomized", "disintegrated"}
attackedMessages[DMG_DROWN] = {"drowned"}
attackedMessages[DMG_NERVEGAS_POISON] = {"poisoned"}
attackedMessages[DMG_RADIATION] = {"irradiated"}
attackedMessages[DMG_DISSOLVE_ACID] = {"dissolved"}
attackedMessages[DMG_DIRECT] = {"mysteriously killed"}
attackedMessages[DMG_BUCKSHOT] = {"swiss cheesed", "shotgunned"}
attackedMessages[DMG_AIRBOAT] = {"shot too many props"} -- Used for indicating a hunter shot too many props

local suicideMessages = {}
suicideMessages[DMG_CLUB_GENERIC] = {"couldn't take it anymore", "killed themself"}
suicideMessages[DMG_CRUSH] = {"was crushed to death"}
suicideMessages[DMG_BULLET] = {"shot themself"}
suicideMessages[DMG_SLASH] = {"got a paper cut"}
suicideMessages[DMG_SLOWBURN_BURN] = {"burned to death"}
suicideMessages[DMG_VEHICLE] = {"ran themself over"}
suicideMessages[DMG_FALL] = {"fell over"}
suicideMessages[DMG_BLAST_SURFACE_BLAST] = {"blew themself up"}
suicideMessages[DMG_SONIC_SHOCK] = {"electrocuted themself"}
suicideMessages[DMG_PLASMA_ENERGYBEAM] = {"looked into a laser"}
suicideMessages[DMG_DROWN] = {"drowned", "couldn't swim"}
suicideMessages[DMG_NERVEGAS_POISON] = {"ate some hemlock", "couldn't find an antidote"}
suicideMessages[DMG_RADIATION] = {"handled too much uranium"}
suicideMessages[DMG_DISSOLVE_ACID] = {"spilled acid on themself"}
suicideMessages[DMG_DIRECT] = {"mysteriously died"}
suicideMessages[DMG_BUCKSHOT] = {"shotgunned themself"}
suicideMessages[DMG_AIRBOAT] = {"shot too many props"} -- Used for indicating a hunter shot too many props

local function getKillMessage(dmgInfo, tblToUse)
	local message
	for dmgType, messages in pairs(tblToUse) do
		if dmgInfo:IsDamageType(dmgType) then
			message = table.Random(messages)
		end
	end

	return message
end

function GM:AddKillFeed(ply, attacker, dmgInfo)
	local killData = {
		victimName = ply:Nick(),
		victimColor = team.GetColor(ply:Team()),
		messageColor = Color(255, 255, 255, 255)
	}

	if IsValid(attacker) && attacker:IsPlayer() && ply != attacker then
		killData.attackerName = attacker:Nick()
		killData.attackerColor = team.GetColor(attacker:Team())
		killData.message = getKillMessage(dmgInfo, attackedMessages) || "killed"
	else
		killData.message = getKillMessage(dmgInfo, suicideMessages) || "died"
	end

	net.Start("ph_kill_feed_add")
	net.WriteTable(killData)
	net.Broadcast()
end

-- former sv_version.lua
local url = "https://raw.githubusercontent.com/datanext27/ultimateph/master/gamemodes/ultimateph/ultimateph.txt"
local downloadlinks = "https://steamcommunity.com/sharedfiles/filedetails/?id=3028430983"

function GM:CheckForNewVersion(ply)
	local req = {}
	req.url = url
	req.failed = function(reason)
		print("Couldn't get version file.", reason)
	end

	req.success = function(code, body, headers)
		local tab = util.KeyValuesToTable(body)
		if !tab || !tab.version then
			print("Couldn't parse version file.")
			return
		end

		local msg = {}
		if tab.version != GAMEMODE.Version then
			msg = {Color(215, 20, 20), "Out of date!\n",
					Color(255, 222, 102), "You're on version ",
					Color(0, 255, 0), GAMEMODE.Version || "error",
					Color(255, 222, 102), " but the latest is ",
					Color(0, 255, 0), tab.version, "\n",
					Color(255, 222, 102), "Download the latest version from: ",
					Color(11, 191, 227), downloadlinks}
		else
			msg = {Color(0, 255, 0), "Up to date!"}
		end

		if IsValid(ply) then
			ply:PlayerChatMsg(unpack(msg))
		else
			MsgC(unpack(msg))
			MsgC("\n")
		end
	end

	HTTP(req)
end

concommand.Add("ph_version", function(ply)
	local color = Color(255, 149, 129)
	local msg = (GAMEMODE.Name || "") .. " " .. tostring(GAMEMODE.Version || "error")

	if IsValid(ply) then
		ply:PlayerChatMsg(color, msg)
	else
		MsgC(color, msg, "\n") -- Print to the server console
	end

	GAMEMODE:CheckForNewVersion(ply)
end)
