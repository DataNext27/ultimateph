include("cl_colors.lua")
local function createRoboto(s)
	surface.CreateFont("RobotoHUD-" .. s , {
		font = "Roboto-Bold",
		size = math.Round(ScrW() / 1000 * s),
		weight = 700,
		antialias = true,
		italic = false
	})

	surface.CreateFont("RobotoHUD-L" .. s , {
		font = "Roboto",
		size = math.Round(ScrW() / 1000 * s),
		weight = 500,
		antialias = true,
		italic = false
	})
end

for i = 5, 50, 5 do
	createRoboto(i)
end
createRoboto(8)
createRoboto(12)

function draw.ShadowText(n, f, x, y, c, px, py, shadowColor)
	draw.SimpleText(n, f, x + 1, y + 1, shadowColor || color_black, px, py)
	draw.SimpleText(n, f, x, y, c, px, py)
end

function GM:HUDPaint()
	self:DrawGameHUD()
	self:DrawRoundTimer()
end

local helpKeysProps = {
	{"attack", "Disguise as prop"},
	{"menu_context", "Lock prop rotation"},
	{"gm_showspare1", "Taunt"}
}

local function keyName(str)
	str = input.LookupBinding(str)
	return str:upper()
end

function GM:DrawGameHUD()
	local ply = LocalPlayer()
	if self:IsCSpectating() && IsValid(self:GetCSpectatee()) && self:GetCSpectatee():IsPlayer() then
		ply = self:GetCSpectatee()
	end

--	self:DrawHealth(ply)

	if ply != LocalPlayer() then
		local col = team.GetColor(ply:Team())
		draw.ShadowText(ply:Nick(), "RobotoHUD-30", ScrW() / 2, ScrH() - 4, col, 1, 4)
	end

	local tr = ply:GetEyeTraceNoCursor()
	local shouldDraw = hook.Run("HUDShouldDraw", "PropHuntersPlayerNames")
	if shouldDraw != false then
		-- draw names
		if IsValid(tr.Entity) && tr.Entity:IsPlayer() && tr.HitPos:Distance(tr.StartPos) < 500 then
			-- hunters can only see their teams names
			if !ply:IsHunter() || ply:Team() == tr.Entity:Team() then
				self.LastLooked = tr.Entity
				self.LookedFade = CurTime()
			end
		end

		if IsValid(self.LastLooked) && self.LookedFade + 2 > CurTime() then
			local name = self.LastLooked:Nick() || "error"
			local col = table.Copy(team.GetColor(self.LastLooked:Team()))
			col.a = (1 - (CurTime() - self.LookedFade) / 2) * 255
			draw.ShadowText(name, "RobotoHUD-20", ScrW() / 2, ScrH() / 2 + 80, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, col.a))
		end
	end

	local help
	if LocalPlayer():Alive() then
		if LocalPlayer():IsProp() then
			if self:GetGameState() == ROUND_HIDE || (self:GetGameState() == ROUND_SEEK && !LocalPlayer():IsDisguised()) then
				help = helpKeysProps
			end
		end
	end

	if help then
		local fh = draw.GetFontHeight("RobotoHUD-L15")
		local h = #help * fh
		local x = 20
		local y = ScrH() / 2 - h / 2
		local i = 0
		local tw = 0
		for k, t in pairs(help) do
			surface.SetFont("RobotoHUD-15")
			local name = keyName(t[1])
			local w = surface.GetTextSize(name)
			tw = math.max(tw, w)
		end

		for k, t in pairs(help) do
			surface.SetFont("RobotoHUD-15")
			local name = keyName(t[1])
			draw.ShadowText(name, "RobotoHUD-15", x + tw / 2, y + i * fh, color_white, 1, 0)
			draw.ShadowText(t[2], "RobotoHUD-L15", x + tw + 10, y + i * fh, color_white, 0, 0)
			i = i + 1
		end
	end
end

local polyTex = surface.GetTextureID("VGUI/white.vmt")

function GM:HUDShouldDraw(name)
	if name == "CHudHealth" then return true end
	if name == "CHudVoiceStatus" then return false end
	if name == "CHudVoiceSelfStatus" then return false end

	return true
end

function GM:DrawRoundTimer()
	if self:GetGameState() == ROUND_WAIT then
		local time = math.ceil(self.StartWaitTime:GetFloat() - self:GetStateRunningTime())
		if time > 0 then
			draw.ShadowText("Waiting for players to join", "RobotoHUD-25", ScrW() / 2, ScrH() / 10 - draw.GetFontHeight("RobotoHUD-40") / 4, color_white, 1, 4)
			draw.ShadowText("Game starts in " .. tostring(time) .. " second" .. (time > 1 && "s" || ""), "RobotoHUD-15", ScrW() / 2, ScrH() / 10, color_white, 1, 1)
		else
			draw.ShadowText("Not enough players to start game", "RobotoHUD-25", ScrW() / 2, ScrH() / 10 - draw.GetFontHeight("RobotoHUD-40") / 4, color_white, 1, 4)
			draw.ShadowText("Waiting for more players to join", "RobotoHUD-15", ScrW() / 2, ScrH() / 10, color_white, 1, 1)
		end
	elseif self:GetGameState() == ROUND_HIDE then
		local time = math.ceil(self.HidingTime:GetInt() - self:GetStateRunningTime())
		if time > 0 then
			draw.ShadowText("Hunters will be released in", "RobotoHUD-15", ScrW() / 2, ScrH() / 3 - draw.GetFontHeight("RobotoHUD-40") / 2, color_white, 1, 4)
			draw.ShadowText(time, "RobotoHUD-40", ScrW() / 2, ScrH() / 3, color_white, 1, 1)
		end
	elseif self:GetGameState() == ROUND_SEEK then
		if self:GetStateRunningTime() < 2 then
			draw.ShadowText("GO!", "RobotoHUD-50", ScrW() / 2, ScrH() / 3, color_white, 1, 1)
		end

		local settings = self:GetRoundSettings()
		local roundTime = settings.RoundTime || 5 * 60
		local time = math.max(0, roundTime - self:GetStateRunningTime())
		net.Receive("rounds", function(len)
			self.rounds = net.ReadInt(5)
		end)
		if self.rounds == nil then
			self.rounds = 1
		end
		local m = math.floor(time / 60)
		local s = math.floor(time % 60)
		m = tostring(m)
		s = s < 10 && "0" .. s || tostring(s)
		local fh = draw.GetFontHeight("RobotoHUD-L15") * 1
		draw.ShadowText("Round "..self.rounds.." / "..self.RoundLimit:GetInt(), "RobotoHUD-L15", ScrW() / 2, 20, color_white, 1, 3)
		draw.ShadowText(m .. ":" .. s, "RobotoHUD-20", ScrW() / 2, fh + 20, color_white, 1, 3)
	end
end

function GM:PreDrawHUD()
	local client = LocalPlayer()
	if self:GetGameState() == ROUND_HIDE then
		if client:IsHunter() then
			surface.SetDrawColor(25, 25, 25, 255)
			surface.DrawRect(-10, -10, ScrW() + 20, ScrH() + 20)
		end
	end
end

