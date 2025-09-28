-- new colmult
function colMul(color, mul)
	color.r = math.Clamp(math.Round(color.r * mul), 0, 255)
	color.g = math.Clamp(math.Round(color.g * mul), 0, 255)
	color.b = math.Clamp(math.Round(color.b * mul), 0, 255)
end

-- former cl_chatmsg.lua
net.Receive("ph_chatmsg", function(len)
	local tbl = net.ReadTable()
	chat.AddText(unpack(tbl))
end)

-- former cl_fixplayercolor
local EntityMeta = FindMetaTable("Entity")

function EntityMeta:GetPlayerColor()
	return self:GetNWVector("playerColor") || Vector()
end

matproxy.Add({
	name = "PlayerColor",
	init = function(self, mat, values)
		-- Store the name of the variable we want to set
		self.ResultTo = values.resultvar
	end,
	bind = function(self, mat, ent)
		if !IsValid(ent) then return end

		if ent.GetPlayerColorOverride then -- clientside entities can't override functions, so we need an additional one for it
			local col = ent:GetPlayerColorOverride()
			if isvector(col) then
				mat:SetVector(self.ResultTo, col)
			end
		elseif ent.GetPlayerColor then
			local col = ent:GetPlayerColor()
			if isvector(col) then
				mat:SetVector(self.ResultTo, col)
			end
		else
			mat:SetVector(self.ResultTo, Vector(62.0 / 255.0, 88.0 / 255.0, 106.0 / 255.0))
		end
	end
})

-- former cl_health
local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:GetHMaxHealth()
	return self:GetNWFloat("HMaxHealth", 100) || 100
end

-- former cl_spectate.lua
net.Receive("spectating_status", function(length)
	GAMEMODE.SpectateMode = net.ReadInt(8)
	GAMEMODE.Spectating = false
	GAMEMODE.Spectatee = nil
	if GAMEMODE.SpectateMode >= 0 then
		GAMEMODE.Spectating = true
		GAMEMODE.Spectatee = net.ReadEntity()
	end

end)

function GM:IsCSpectating()
	return self.Spectating
end

function GM:GetCSpectatee()
	return self.Spectatee
end

function GM:GetCSpectateMode()
	return self.SpectateMode
end

-- former cl_ragdoll.lua
local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

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

if !EntityMeta.GetRagdollOwnerOld then
	EntityMeta.GetRagdollOwnerOld = EntityMeta.GetRagdollOwner
end

function EntityMeta:GetRagdollOwner()
	local ent = self:GetNWEntity("RagdollOwner")
	if IsValid(ent) then
		return ent
	end

	return self:GetRagdollOwnerOld()
end
