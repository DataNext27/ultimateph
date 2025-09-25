-- former cl_aimlaser.lua
local beamMat = Material("ultimateph/aim_laser")
local ray_color = Color(50,170,46)
local ray_width = 6

local dotMat = Material("ultimateph/aim_dot")
local dot_color = Color(255,255,255)

local hunters_aim = {}

function GM:PostDrawTranslucentRenderables()
	hunters_aim = {}
	self:GetHuntersAim()

	-- When "ph_hunter_aim_laser" set to 0, nobody can see the beam
	-- set to 1 == spectator only, set to 2 == props and spectator
	-- Also, we don't want the hunters to see the ray, to prevent eventual visual bugs
	local visibility = GetConVar("ph_hunter_aim_laser"):GetInt()

	if visibility == 0 then return end

	if visibility == 1 and not LocalPlayer():IsSpectator() then return end
	if visibility == 2 and not (LocalPlayer():IsSpectator() or LocalPlayer():IsProp()) then return end

	for _, h_aim in pairs(hunters_aim) do
		render.SetMaterial(beamMat)
		render.DrawBeam(h_aim.eye_pos, h_aim.looking.HitPos, ray_width, 0, 1, ray_color)

		render.SetMaterial(dotMat)
		local size = math.random(8, 16)
		render.DrawQuadEasy(h_aim.looking.HitPos + h_aim.looking.HitNormal, h_aim.looking.HitNormal, size, size, dot_color, 0)
	end
end

function GM:GetHuntersAim()
	for _, ply in pairs(player.GetAll()) do
		if ply:IsHunter() then
			local t = {}
			t.eye_pos = ply:EyePos()
			t.looking = ply:GetEyeTrace()
			table.insert(hunters_aim, t)
		end
	end
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

-- formar cl_ragdoll.lua
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

--former cl_killfeed.lua
local killFeedEvents = {}

local KILL_FEED_MESSAGE_TIMEOUT = 10 -- How long a message stays in the kill feed before starting to fade away.
local VISUALS_UPDATE_INTERVAL = 0.05 -- Tick speed of the visual update timer. Smaller number = smoother visuals.
local FADE_TIME = 1.5 -- How long it takes for an expiring kill feed message to fade away.

local NUM_FADE_TICKS = math.floor(FADE_TIME / VISUALS_UPDATE_INTERVAL)
local FADE_AMOUNT = math.floor(255 / NUM_FADE_TICKS)

local FONT = "RobotoHUD-15" -- Font used for kill feed messages.

function GM:ClearKillFeed()
	killFeedEvents = {}
end

-- This timer handles the visual updates for kill feed messages.
-- New messages are given a "slide in" effect wherein they slide in from off-screen.
-- Expiring messages are given a fade out effect.
timer.Create("ph_timer_kill_feed_visuals", VISUALS_UPDATE_INTERVAL, 0, function()
	for i, event in ipairs(killFeedEvents) do
		local finalPos = ScrW() - 10 - event.eventWidth
		-- Handle slide in effect.
		if event.new then
			-- The distance to slide in a single "frame" is going to be proportional to how much distance is
			-- left to the final position. This will be scaled up by 50% to make things go faster.
			local subtractAmt = math.floor((event.x - finalPos) * 0.5)
			-- Always move by at least one pixel.
			if subtractAmt < 1 then
				subtractAmt = 1
			end

			event.x = event.x - subtractAmt
			if event.x < finalPos then
				event.x = finalPos
				event.new = false
			end
		-- Handle the fade out effect.
		elseif event.entryTime + KILL_FEED_MESSAGE_TIMEOUT < CurTime() then
			if event.attackerName then
				event.attackerColor.a = event.attackerColor.a - FADE_AMOUNT
			end
			event.victimColor.a = event.victimColor.a - FADE_AMOUNT
			event.messageColor.a = event.messageColor.a - FADE_AMOUNT
			-- Remove message from the kill feed once it is completely transparent.
			if event.messageColor.a < 0 then
				table.remove(killFeedEvents, i)
			end
		end
	end
end)

net.Receive("ph_kill_feed_add", function(len)
	local event = net.ReadTable()
	event.entryTime = CurTime()
	event.new = true -- New events are events that are in the process of "sliding in" to view.

	-- Starting x position. Individual draw statements will be relative to this value.
	event.x = ScrW() -- This will be offscreen.

	-- Calculate the final width of the entire kill feed event.
	surface.SetFont(FONT)
	event.eventWidth = surface.GetTextSize(event.victimName) + surface.GetTextSize(" ") + surface.GetTextSize(event.message)
	if event.attackerName then
		event.eventWidth = event.eventWidth + surface.GetTextSize(event.attackerName) + surface.GetTextSize(" ")
	end

	-- New events will start at the top.
	event.y = 10

	-- Shift existing events downward.
	for _, kfEvent in ipairs(killFeedEvents) do
		kfEvent.y = kfEvent.y + draw.GetFontHeight(FONT)
	end

	table.insert(killFeedEvents, event)
end)

-- The shadow transparency will be the same as the provided color transparency.
-- Returns the width and height of the NON SHADOW text.
local function drawShadowText(text, font, x, y, color)
	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, color.a))
	return draw.SimpleText(text, font, x, y, color)
end

local function drawKillFeedHUD()
	for _, event in ipairs(killFeedEvents) do
		local widthOffset = event.x

		-- New events need to have clipping disabled so they can be drawn while partially off-screen.
		local oldClippingValue
		if event.new then
			oldClippingValue = DisableClipping(true)
		end

		-- If Murder: [Attacker] [Message] [Victim]
		-- If Suicide: [Victim] [Message]

		if event.attackerName then
			widthOffset = widthOffset + drawShadowText(event.attackerName .. " ", FONT, widthOffset, event.y, event.attackerColor)
		else
			widthOffset = widthOffset + drawShadowText(event.victimName .. " ", FONT, widthOffset, event.y, event.victimColor)
		end

		widthOffset = widthOffset + drawShadowText(event.message .. (event.attackerName && " " || ""), FONT, widthOffset, event.y, event.messageColor)

		if event.attackerName then
			drawShadowText(event.victimName, FONT, widthOffset, event.y, event.victimColor)
		end

		if event.new then
			DisableClipping(oldClippingValue)
		end
	end
end

hook.Add("HUDPaint", "ph_kill_feed_hud_paint", drawKillFeedHUD)
