function GM:HUDPaint()
	self:DrawGameHUD()
	self:DrawRoundTimer()
end

function GM:HUDShouldDraw(name)
	if HudBlacklist[name] then 
		return 
	end

	return true
end

function GM:DrawGameHUD()
	local ply = LocalPlayer()
	
	if self:IsCSpectating() and IsValid(self:GetCSpectatee()) and self:GetCSpectatee():IsPlayer() then
		ply = self:GetCSpectatee()
	end

	if ply ~= LocalPlayer() then
		local col = team.GetColor(ply:Team())
		draw.ShadowText(ply:Nick(), "RobotoHUD-30", ScrW() / 2, ScrH() - ScreenScaleH(2), col, 1, 4)
	end

	local eyeTrace = ply:GetEyeTraceNoCursor()
	if GAMEMODE:HUDShouldDraw("PropHuntersPlayerNames") then
		-- draw names
		if IsValid(eyeTrace.Entity) and eyeTrace.Entity:IsPlayer() and eyeTrace.HitPos:Distance(eyeTrace.StartPos) < NameDistance then
			-- hunters can only see their teams names
			if not ply:IsHunter() or ply:Team() == eyeTrace.Entity:Team() then
				self.LastLooked = eyeTrace.Entity
				self.LookedFade = CurTime()
			end
		end

		if IsValid(self.LastLooked) and self.LookedFade + 2 > CurTime() then
			local name = self.LastLooked:Nick() or "error"
			local col = table.Copy(team.GetColor(self.LastLooked:Team()))
			col.a = (1 - (CurTime() - self.LookedFade) / 2) * 255
			draw.ShadowText(name, "RobotoHUD-20", ScrW() / 2, ScrH() / 1.85, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, col.a))
		end
	end

	if not LocalPlayer():Alive() or not LocalPlayer():IsProp() or (not self:GetGameState() == ROUND_HIDE and LocalPlayer():IsDisguised()) then
		return -- skip over the help text if not above conditions
	end

	-- prop help text
	surface.SetFont("RobotoHUD-15") -- set font for surface.GetTextSize later
	local fontSize = draw.GetFontHeight("RobotoHUD-15")
	local disguise = input.LookupBinding("attack") 
	local rotationLock = input.LookupBinding("menu_context")
	local tauntMenu = input.LookupBinding("gm_showspare1")

	if not disguise or not rotationLock or not tauntMenu then
		draw.ShadowText("UNBOUND!", "RobotoHUD-15", ScreenScale(4), ScrH() / 2, PHRed, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		draw.ShadowText(" Please ensure +attack, +menu_context, and gm_showspare1 are bound!", "RobotoHUD-L15", ScreenScale(4) + surface.GetTextSize("UNBOUND!"), ScrH() / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		draw.ShadowText("* MOUSE1, C, and F3 by default.", "RobotoHUD-L12", ScreenScale(4), ScrH() / 2 + fontSize, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
		return
	end
	
	local totalWidth = math.max(surface.GetTextSize(disguise), surface.GetTextSize(rotationLock), surface.GetTextSize(tauntMenu))
	
	draw.ShadowText(disguise, "RobotoHUD-15", ScreenScale(4) + totalWidth / 2, ScrH() / 2 - fontSize, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
	draw.ShadowText(" Disguise", "RobotoHUD-L15", ScreenScale(4) + totalWidth, ScrH() / 2 - fontSize, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
	
	draw.ShadowText(rotationLock, "RobotoHUD-15", ScreenScale(4) + totalWidth / 2, ScrH() / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
	draw.ShadowText(" Lock Rotation", "RobotoHUD-L15", ScreenScale(4) + totalWidth, ScrH() / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
	
	draw.ShadowText(tauntMenu, "RobotoHUD-15", ScreenScale(4) + totalWidth / 2, ScrH() / 2 + fontSize, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_LEFT)
	draw.ShadowText(" Taunt Menu", "RobotoHUD-L15", ScreenScale(4) + totalWidth, ScrH() / 2 + fontSize, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
end

function GM:DrawRoundTimer()
	if self:GetGameState() == ROUND_WAIT then
		local time = math.ceil(self.StartWaitTime:GetFloat() - self:GetStateRunningTime())
		if time > 0 then
			draw.ShadowText("Waiting for players to join", "RobotoHUD-25", ScrW() / 2, ScreenScaleH(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.ShadowText("Game starts in " .. tostring(time) .. " second" .. (time > 1 and "s" or ""), "RobotoHUD-15", ScrW() / 2, ScreenScaleH(4) + draw.GetFontHeight("RobotoHUD-25"), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		else
			draw.ShadowText("Not enough players to start", "RobotoHUD-25", ScrW() / 2, ScreenScaleH(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.ShadowText("Waiting for more players to join", "RobotoHUD-15", ScrW() / 2, ScreenScaleH(4) + draw.GetFontHeight("RobotoHUD-25"), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
		return
	end

	if self:GetGameState() == ROUND_HIDE then
		local time = math.ceil(self.HidingTime:GetInt() - self:GetStateRunningTime())
		if time > 0 then
			draw.ShadowText("Hunters will be released in", "RobotoHUD-25", ScrW() / 2, ScreenScaleH(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.ShadowText(time, "RobotoHUD-50", ScrW() / 2, ScreenScaleH(4) + draw.GetFontHeight("RobotoHUD-25"), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
		return
	end

	if self:GetGameState() ~= ROUND_SEEK then
		return
	end

	if self:GetStateRunningTime() < 2 then
		draw.ShadowText("GO!", "RobotoHUD-50", ScrW() / 2, ScreenScaleH(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		return
	end

	local settings = self:GetRoundSettings()
	local roundTime = settings.RoundTime or 5 * 60
	local time = tostring(math.max(0, roundTime - self:GetStateRunningTime()))
	draw.ShadowText("Round "..GAMEMODE.CurrentRound.."/"..GAMEMODE.RoundLimit:GetInt(), "RobotoHUD-L15", ScrW() / 2, ScreenScaleH(4), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.ShadowText(string.ToMinutesSeconds(time), "RobotoHUD-20", ScrW() / 2, ScreenScaleH(4) + draw.GetFontHeight("RobotoHUD-L15"), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function GM:PreDrawHUD()
	if self:GetGameState() ~= ROUND_HIDE or not LocalPlayer():IsHunter() then
		return
	end
	
	cam.Start2D()
	surface.SetDrawColor(25, 25, 25, 255)
	surface.DrawRect(0, 0, ScrW(), ScrH())
	cam.End2D()
end

-- former cl_voicepanels.lua
local PANEL = {}
local PlayerVoicePanels = {}

function PANEL:Init()
	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:Dock(LEFT)
	self.Avatar:SetSize(ScreenScaleH(16), ScreenScaleH(16))
	self.Color = color_transparent
	self:SetSize(ScreenScaleH(16), ScreenScaleH(16))
	self:DockPadding(ScreenScaleH(2), ScreenScaleH(2), ScreenScaleH(2), ScreenScaleH(2))
	self:DockMargin(ScreenScaleH(2), ScreenScaleH(2), ScreenScaleH(2), ScreenScaleH(2))
	self:Dock(BOTTOM)
end

function PANEL:Setup(ply)
	self.ply = ply
	self.Avatar:SetPlayer(ply, 64)
	self.Color = team.GetColor(ply:Team())
	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	if not IsValid(self.ply) then return end

	local volume = self.ply:VoiceVolume()
	col = team.GetColor(self.ply:Team())

	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(col.r, col.g, col.b, 120)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(0, 0, w, h)
	surface.SetDrawColor(col.r, col.g, col.b, 120)
	surface.DrawRect(0, 0, math.floor(w * volume), h)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(0, 0, w * volume, h)

	draw.ShadowText(self.ply:Nick(), "RobotoHUD-12", self.Avatar:GetWide() + ScreenScale(4), h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function PANEL:Think()
	if self.fadeAnim then
		self.fadeAnim:Run()
	end
end

function PANEL:FadeOut(anim, delta, data)
	if anim.Finished then
		if IsValid(PlayerVoicePanels[self.ply]) then
			PlayerVoicePanels[self.ply]:Remove()
			PlayerVoicePanels[self.ply] = nil
			return
		end

		return
	end

	self:SetAlpha(255 - (255 * delta))
end

derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")

function GM:PlayerStartVoice(ply)
	if not IsValid(g_VoicePanelList) then return end

	-- There'd be an exta one if voice_loopback is on, so remove it.
	GAMEMODE:PlayerEndVoice(ply)

	if IsValid(PlayerVoicePanels[ply]) then
		if PlayerVoicePanels[ply].fadeAnim then
			PlayerVoicePanels[ply].fadeAnim:Stop()
			PlayerVoicePanels[ply].fadeAnim = nil
		end

		PlayerVoicePanels[ply]:SetAlpha(255)
		return
	end

	if not IsValid(ply) then return end

	local pnl = g_VoicePanelList:Add("VoiceNotify")
	pnl:Setup(ply)
	PlayerVoicePanels[ply] = pnl
end

local function VoiceClean()
	for k, v in pairs(PlayerVoicePanels) do
		if not IsValid(k) or not k:IsPlayer() then
			GAMEMODE:PlayerEndVoice(k)
		end
	end
end
timer.Create("VoiceClean", 10, 0, VoiceClean)

function GM:PlayerEndVoice(ply)
	if IsValid(PlayerVoicePanels[ply]) then
		if PlayerVoicePanels[ply].fadeAnim then return end

		PlayerVoicePanels[ply].fadeAnim = Derma_Anim("FadeOut", PlayerVoicePanels[ply], PlayerVoicePanels[ply].FadeOut)
		PlayerVoicePanels[ply].fadeAnim:Start(2)
	end
end

local function CreateVoiceVGUI()
	g_VoicePanelList = vgui.Create("DPanel")
	g_VoicePanelList:ParentToHUD()
	g_VoicePanelList:DockMargin(0, 0, ScreenScaleH(16), ScreenScaleH(48)) -- align with ammo hud ig
	g_VoicePanelList:Dock(RIGHT)
	g_VoicePanelList:SetSize(ScreenScaleH(136), ScreenScaleH(96))
	g_VoicePanelList:SetPaintBackground(false)
end

hook.Add("InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI)

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
		local finalPos = ScrW() - ScreenScaleH(4) - event.eventWidth
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
	event.x = ScrW() - ScreenScaleH(4) -- This will be offscreen.

	-- Calculate the final width of the entire kill feed event.
	surface.SetFont(FONT)
	event.eventWidth = surface.GetTextSize(event.victimName) + surface.GetTextSize(" ") + surface.GetTextSize(event.message)
	if event.attackerName then
		event.eventWidth = event.eventWidth + surface.GetTextSize(event.attackerName) + surface.GetTextSize(" ")
	end

	-- New events will start at the top.
	event.y = ScreenScaleH(4)

	-- Shift existing events downward.
	for _, kfEvent in ipairs(killFeedEvents) do
		kfEvent.y = kfEvent.y + draw.GetFontHeight(FONT)
	end

	table.insert(killFeedEvents, event)
end)

local function drawKillFeedHUD()
	for _, event in ipairs(killFeedEvents) do
		local widthOffset = event.x

		-- If Murder: [Attacker] [Message] [Victim]
		-- If Suicide: [Victim] [Message]

		if event.attackerName then
			widthOffset = widthOffset + draw.ShadowText(event.attackerName .. " ", FONT, widthOffset, event.y, event.attackerColor)
		else
			widthOffset = widthOffset + draw.ShadowText(event.victimName .. " ", FONT, widthOffset, event.y, event.victimColor)
		end

		widthOffset = widthOffset + draw.ShadowText(event.message .. (event.attackerName and " " or ""), FONT, widthOffset, event.y, event.messageColor)

		if event.attackerName then
			draw.ShadowText(event.victimName, FONT, widthOffset, event.y, event.victimColor)
		end
	end
end

hook.Add("HUDPaint", "ph_kill_feed_hud_paint", drawKillFeedHUD)

-- former cl_aimlaser.lua
local beamMat = Material("ultimateph/aim_laser")
local ray_color = PHGreen
local ray_width = 6

local dotMat = Material("ultimateph/aim_dot")
local dot_color = color_white

local hunters_aim = {}

function GM:PostDrawTranslucentRenderables()
	hunters_aim = {}
	self:GetHuntersAim()

	-- When "ph_hunter_aim_laser" set to 0, nobody can see the beam
	-- set to 1 == spectator only, set to 2 == props and spectator
	-- Also, we don't want the hunters to see the ray, to prevent eventual visual bugs
	local visibility = GetConVar("ph_hunter_aim_laser"):GetInt()

	if visibility == 0 or (visibility == 1 and not LocalPlayer():IsSpectator()) or (visibility == 2 and not (LocalPlayer():IsSpectator() or LocalPlayer():IsProp()))  then 
		return 
	end
	
	for _, h_aim in pairs(hunters_aim) do
		render.SetMaterial(beamMat)
		render.DrawBeam(h_aim.eye_pos, h_aim.looking.HitPos, ray_width, 0, 1, ray_color)

		render.SetMaterial(dotMat)
		local size = math.random(8, 16)
		render.DrawQuadEasy(h_aim.looking.HitPos + h_aim.looking.HitNormal, h_aim.looking.HitNormal, size, size, dot_color, 0)
	end
end

function GM:GetHuntersAim()
	for _, ply in ipairs(player.GetAll()) do
		if not ply:IsHunter() then
			continue
		end

		local t = {}
		t.eye_pos = ply:EyePos()
		t.looking = ply:GetEyeTrace()
		table.insert(hunters_aim, t)
	end
end
