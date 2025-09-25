local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

local allowClasses = {"prop_physics", "prop_physics_multiplayer"}

function PlayerMeta:CanDisguiseAsProp(ent)
	if !self:Alive() then return false end
	if !self:IsProp() then return false end
	if !IsValid(ent) then return false end

	if !table.HasValue(allowClasses, ent:GetClass()) then
		return false
	end

	return true
end

function EntityMeta:IsDisguisableAs()
	if !table.HasValue(allowClasses, self:GetClass()) then
		return false
	end

	return true
end

function PlayerMeta:CanFitHull(hullx, hully, hullz)
	local trace = {}
	trace.start = self:GetPos()
	trace.endpos = self:GetPos()
	trace.filter = self
	trace.maxs = Vector(hullx, hully, hullz)
	trace.mins = Vector(-hullx, -hully, 0)
	local tr = util.TraceHull(trace)
	if tr.Hit then
		return false
	end

	return true
end

function EntityMeta:GetPropSize()
	local hullxy = math.Round(math.Max(self:OBBMaxs().x - self:OBBMins().x, self:OBBMaxs().y - self:OBBMins().y) / 2)
	local hullz = math.Round(self:OBBMaxs().z - self:OBBMins().z)
	return hullxy, hullz
end

function PlayerMeta:GetPropEyePos()
	if !self:IsDisguised() then
		return self:GetShootPos()
	end

	local maxs = self:GetNWVector("disguiseMaxs")
	local mins = self:GetNWVector("disguiseMins")
	local reach = (maxs.z - mins.z) + 10
	local trace = {}
	trace.start = self:GetPos() + Vector(0, 0, 1.5)
	trace.endpos = trace.start + Vector(0, 0, reach + 5)
	local tab = ents.FindByClass("prop_ragdoll")
	table.insert(tab, self)
	trace.filter = tab

	local tr = util.TraceLine(trace)
	return trace.start + (trace.endpos - trace.start):GetNormal() * math.Clamp(trace.start:Distance(tr.HitPos) - 5, 0, reach)
end

function PlayerMeta:GetPropEyeTrace()
	if !self:IsDisguised() then
		local tr = self:GetEyeTraceNoCursor()
		local trace = {}
		trace.start = tr.StartPos
		trace.endpos = trace.start + self:GetAimVector() * 100000
		trace.filter = self
		trace.mask = MASK_SHOT
		return util.TraceLine(trace)
	end

	local trace = {}
	trace.start = self:GetPropEyePos()
	trace.endpos = trace.start + self:GetAimVector() * 100000
	trace.filter = self
	trace.mask = MASK_SHOT
	local tr = util.TraceLine(trace)
	return tr
end

local function checkCorner(mins, maxs, corner, ang)
	corner:Rotate(ang)
	mins.x = math.min(mins.x, corner.x)
	mins.y = math.min(mins.y, corner.y)
	maxs.x = math.max(maxs.x, corner.x)
	maxs.y = math.max(maxs.y, corner.y)
end

function PlayerMeta:CalculateRotatedDisguiseMinsMaxs()
	local maxs = self:GetNWVector("disguiseMaxs")
	local mins = self:GetNWVector("disguiseMins")
	local ang = self:EyeAngles()
	ang.p = 0

	local nmins, nmaxs = Vector(0, 0, mins.z), Vector(0, 0, maxs.z)
	checkCorner(nmins, nmaxs, Vector(maxs.x, maxs.y), ang)
	checkCorner(nmins, nmaxs, Vector(maxs.x, mins.y), ang)
	checkCorner(nmins, nmaxs, Vector(mins.x, mins.y), ang)
	checkCorner(nmins, nmaxs, Vector(mins.x, maxs.y), ang)

	return nmins, nmaxs
end

function PlayerMeta:DisguiseRotationLocked()
	if !self:IsDisguised() then
		return self:GetNWBool("undisguiseRotationLock")
	end
	
	return self:GetNWBool("disguiseRotationLock")
end

function GM:PlayerCanDisguiseCurrentTarget(ply)
	if !IsValid(ply) then return false, nil end

	local horizLeniency = 50
	local minHLeniency = 100
	local verticalLeniency = 100

	if ply:IsProp() then
		local tr = ply:GetPropEyeTrace()
		if IsValid(tr.Entity) then
			if self:IsModelBanned(tr.Entity:GetModel()) then return false, nil end

			local testPos = Vector(tr.StartPos.x, tr.StartPos.y, 0)
			local hitPosition = Vector(tr.HitPos.x, tr.HitPos.y, 0)
			local hitZ = tr.HitPos.z
			local propCurZ = ply:GetPos().z
			local propMaxZ = ply:OBBMaxs().z + propCurZ
			local propMinZ = ply:OBBMins().z + propCurZ
			local withinZRange = hitZ >= propMinZ - verticalLeniency && hitZ <= propMaxZ + verticalLeniency
			local propXY = ply:GetPropSize()
			local withinHorizRange = hitPosition:Distance(testPos) < math.max(propXY + horizLeniency, minHLeniency)
			if withinHorizRange && withinZRange then
				if ply:CanDisguiseAsProp(tr.Entity) then
					return true, tr.Entity
				end
			end
		end
	end

	return false, nil
end

hook.Add('UpdateAnimation', 'PropUndisguiseLock', function(ply)
	if ply:IsDisguised() or !GAMEMODE.PropTpose:GetBool() or !ply:GetNWBool("undisguiseRotationLock") then
		return
	end

	local ang = ply:GetNWAngle("undisguiseRotationLockAng")

	if ang == ply:GetRenderAngles() then
		return
	end
	
	ply:SetRenderAngles(ang)
end)

if CLIENT then
-- former cl_disguise.lua	
	local PlayerMeta = FindMetaTable("Player")
	
	function PlayerMeta:IsDisguised()
		return self:GetNWBool("disguised", false)
	end
	
	local function renderDis(self)
		for k, ply in pairs(player.GetAll()) do
			if ply:Alive() && ply:IsDisguised() then
				local model = ply:GetNWString("disguiseModel")
				if model && model != "" then
					local ent = ply:GetNWEntity("disguiseEntity")
					if IsValid(ent) then
						local mins = ply:GetNWVector("disguiseMins")
						local maxs = ply:GetNWVector("disguiseMaxs")
						local ang = ply:EyeAngles()
						ang.p = 0
						ang.r = 0
						if ply:DisguiseRotationLocked() then
							ang.y = ply:GetNWFloat("disguiseRotationLockYaw")
						end
						local pos = ply:GetPos() + Vector(0, 0, -mins.z)
						local center = (maxs + mins) / 2
						center.z = 0
						center:Rotate(ang)
						ent:SetPos(pos - center)
						ent:SetAngles(ang)
						ent:SetSkin(ply:GetNWInt("disguiseSkin", 1))
					end
				end
			end
		end
	end
	
	function GM:RenderDisguises()
		cam.Start3D(EyePos(), EyeAngles())
		local b, err = pcall(renderDis, self)
		cam.End3D()
		if !b then
			MsgC(Color(255, 0, 0), err .. "\n")
		end
	end
	
	function GM:RenderDisguiseHalo()
		local client = LocalPlayer()
		if client:IsProp() then
			local canDisguise, target = self:PlayerCanDisguiseCurrentTarget(client)
			if canDisguise then
				local col = Color(50, 220, 50)
				local hullxy, hullz = target:GetPropSize()
				if !client:CanFitHull(hullxy, hullxy, hullz) then
					col = Color(220, 50, 50)
				end
				halo.Add({target}, col, 2, 2, 2, true, true)
			end
	
			local tab = {}
			for k, ply in pairs(player.GetAll()) do
				if ply != client && ply:IsProp() && ply:IsDisguised() then
					if IsValid(ply.PropMod) then
						table.insert(tab, ply.PropMod)
					end
				end
			end
			halo.Add(tab, team.GetColor(TEAM_PROP), 2, 2, 2, true, false)
		end
	end
end

if SERVER then
-- former sv_disguise.lua	
	local PlayerMeta = FindMetaTable("Player")
	
	function GM:PlayerDisguise(ply)
		local canDisguise, target = self:PlayerCanDisguiseCurrentTarget(ply)
		if canDisguise then
			if ply.LastDisguise && ply.LastDisguise + 1 > CurTime() then
				return
			end
	
			ply:DisguiseAsProp(target)
		end
	end
	
	function PlayerMeta:DisguiseAsProp(ent)
		local hullxy, hullz = ent:GetPropSize()
		if !self:CanFitHull(hullxy, hullxy, hullz) then
			self:PlayerChatMsg(Color(255, 50, 50), "Not enough room to change")
			return
		end
	
		if !self:IsDisguised() then
			self.OldPlayerModel = self:GetModel()
		end
	
		self:Flashlight(false)
	
		-- create an entity for the disguise
		-- we can't use a clientside entity as it needs a shadow
		local dent = self:GetNWEntity("disguiseEntity")
		if !IsValid(dent) then
			dent = ents.Create("ph_disguise")
			self:SetNWEntity("disguiseEntity", dent)
			dent.PropOwner = self
			dent:SetPos(self:GetPos())
			dent:Spawn()
		end
		dent:SetModel(ent:GetModel())
	
		self:SetNWBool("disguised", true)
		self:SetNWString("disguiseModel", ent:GetModel())
		self:SetNWVector("disguiseMins", ent:OBBMins())
		self:SetNWVector("disguiseMaxs", ent:OBBMaxs())
		self:SetNWInt("disguiseSkin", ent:GetSkin())
		self:SetNWBool("disguiseRotationLock", false)
		self:SetColor(Color(255, 0, 0, 0))
		self:SetRenderMode(RENDERMODE_NONE)
		self:SetModel(ent:GetModel())
		self:SetNoDraw(false)
		self:DrawShadow(false)
		GAMEMODE:PlayerSetNewHull(self, hullxy, hullz, hullz)
	
		local maxHealth = 1
		local volume = 1
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			maxHealth = math.Clamp(math.Round(phys:GetVolume() / 230), 1, 200)
			volume = phys:GetVolume()
		end
	
		self.PercentageHealth = math.min(self:Health() / self:GetHMaxHealth(), self.PercentageHealth || 1)
		local per = math.Clamp(self.PercentageHealth * maxHealth, 1, 200)
		self:SetHealth(per)
		self:SetHMaxHealth(maxHealth)
		self:SetNWFloat("disguiseVolume", volume)
	
		self:CalculateSpeed()
	
		local offset = Vector(0, 0, ent:OBBMaxs().z - self:OBBMins().z + 10)
		self:SetViewOffset(offset)
		self:SetViewOffsetDucked(offset)
	
		self:EmitSound("weapons/bugbait/bugbait_squeeze" .. math.random(1, 3) .. ".wav")
		self.LastDisguise = CurTime()
	
		local eff = EffectData()
		eff:SetOrigin(self:GetPos() + Vector(0, 0, 1))
		eff:SetScale(hullxy)
		eff:SetMagnitude(hullz)
		util.Effect("ph_disguise", eff, true, true)
	end
	
	function PlayerMeta:IsDisguised()
		return self:GetNWBool("disguised", false)
	end
	
	function PlayerMeta:UnDisguise()
		local dent = self:GetNWEntity("disguiseEntity")
		if IsValid(dent) then
			dent:Remove()
		end
	
		self.PercentageHealth = nil
		self:SetNWBool("disguised", false)
		self:SetNWBool("undisguiseRotationLock", false)
		self:SetColor(Color(255, 255, 255, 255))
		self:SetNoDraw(false)
		self:DrawShadow(true)
		self:SetRenderMode(RENDERMODE_NORMAL)
		GAMEMODE:PlayerSetNewHull(self)
		if self.OldPlayerModel then
			self:SetModel(self.OldPlayerModel)
			self.OldPlayerModel = nil
		end
	
		self:SetViewOffset(Vector(0, 0, 64))
		self:SetViewOffsetDucked(Vector(0, 0, 28))
	
		self:CalculateSpeed()
	end
	
	function PlayerMeta:DisguiseLockRotation()
		if !self:IsDisguised() then
			local ang = self:GetRenderAngles()
			self:SetNWAngle("undisguiseRotationLockAng", ang)
			self:SetNWBool("undisguiseRotationLock", true)
			return
		end
		
		local mins, maxs = self:CalculateRotatedDisguiseMinsMaxs()
		local hullx = math.Round((maxs.x - mins.x) / 2)
		local hully = math.Round((maxs.y - mins.y) / 2)
		local hullz = math.Round(maxs.z - mins.z)
		if !self:CanFitHull(hullx, hully, hullz) then
			self:PlayerChatMsg(Color(255, 50, 50), "Not enough room to lock rotation, move into a more open area")
			return
		end
	
		local ang = self:EyeAngles()
		self:SetNWBool("disguiseRotationLock", true)
		self:SetNWFloat("disguiseRotationLockYaw", ang.y)
		GAMEMODE:PlayerSetHull(self, hullx, hully, hullz, hullz)
	end
	
	function PlayerMeta:DisguiseUnlockRotation()
		if !self:IsDisguised() then
			self:SetNWBool("undisguiseRotationLock", false)
			return
		end
		
		local maxs = self:GetNWVector("disguiseMaxs")
		local mins = self:GetNWVector("disguiseMins")
		local hullxy = math.Round(math.Max(maxs.x - mins.x, maxs.y - mins.y) / 2)
		local hullz = math.Round(maxs.z - mins.z)
		if !self:CanFitHull(hullxy, hullxy, hullz) then
			self:PlayerChatMsg(Color(255, 50, 50), "Not enough room to unlock rotation, move into a more open area")
			return
		end
	
		self:SetNWBool("disguiseRotationLock", false)
		GAMEMODE:PlayerSetHull(self, hullxy, hullxy, hullz, hullz)
	end
	
	concommand.Add("ph_lockrotation", function(ply, com, args)
		if !IsValid(ply) or ply:Team() ~= TEAM_PROP then 
			return 
		end
	
		if ply:DisguiseRotationLocked() then
			ply:DisguiseUnlockRotation()
		else
			ply:DisguiseLockRotation()
		end
	end)
end
