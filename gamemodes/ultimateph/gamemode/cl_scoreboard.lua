if GAMEMODE and IsValid(GAMEMODE.ScoreboardPanel) then
	GAMEMODE.ScoreboardPanel:Remove()
end

local menu

surface.CreateFont("ScoreboardPlayer" , {
	font = "coolvetica",
	size = math.Clamp( ScreenScaleH(16), 16, 32 ),
	weight = 500,
	antialias = true,
	italic = false
})

local muted = Material("icon32/muted.png", "noclamp")
local skull = Material("husklesph/skull.png", "noclamp")

local function addPlayerItem(self, mlist, ply, pteam)
	local but = vgui.Create("DButton")
	but.player = ply
	but.ctime = CurTime()
	but:SetTall(draw.GetFontHeight("RobotoHUD-20") + ScreenScaleH(4))
	but:SetText("")

	function but:Paint(w, h)
		surface.SetDrawColor(color_black)

		if IsValid(ply) and ply:IsPlayer() then
			local s = ScreenScaleH(2)
			if not ply:Alive() then
				surface.SetMaterial(skull)
				surface.SetDrawColor(220, 220, 220, 255)
				surface.DrawTexturedRect(s, 0, ScreenScaleH(16), ScreenScaleH(16))
				s = s + ScreenScaleH(16)
			end

			if ply:IsMuted() then
				surface.SetMaterial(muted)

				-- draw mute icon
				surface.SetDrawColor(150, 150, 150, 255)
				surface.DrawTexturedRect(s, 0, ScreenScaleH(16), ScreenScaleH(16))
				s = s + ScreenScaleH(16)
			end

			-- group tags :D
			if tobool(GroupTags) then
				if GroupColors[ply:GetUserGroup()] ~= nil then
					surface.SetDrawColor(GroupColors[ply:GetUserGroup()])
					self:DrawFilledRect()
				end
					
				if GroupNames[ply:GetUserGroup()] then
					draw.SimpleText("["..GroupNames[ply:GetUserGroup()].."]", "RobotoHUD-L20", s, 0, PHScobDarkest, 0)
					s = s + surface.GetTextSize("["..GroupNames[ply:GetUserGroup()].."]") + ScreenScaleH(2)
					draw.SimpleText(ply:Nick(), "RobotoHUD-L20", s, 0, color_white, 0)
					draw.SimpleText(ply:Ping(), "RobotoHUD-L20", w - ScreenScaleH(2), 0, PHHudWhite, 2)
				end
			else
				draw.ShadowText(ply:Nick(), "RobotoHUD-L20", s, 0, PHWHite, 0)
				draw.ShadowText(ply:Ping(), "RobotoHUD-L20", w - ScreenScaleH(2), 0, PHWhite, 2)
			end
		end
	end

	function but:DoClick()
		if IsValid(ply) then
			GAMEMODE:DoScoreboardActionPopup(ply)
		end
	end

	mlist:AddItem(but)
end

local function doPlayerItems(self, mlist, pteam)
	for k, ply in pairs(team.GetPlayers(pteam)) do
		local found = false
		for t, v in pairs(mlist:GetCanvas():GetChildren()) do
			if v.player == ply then
				found = true
				v.ctime = CurTime()
			end
		end

		if not found then
			addPlayerItem(self, mlist, ply, pteam)
		end
	end

	local del = false
	for t, v in pairs(mlist:GetCanvas():GetChildren()) do
		if not v.perm and v.ctime ~= CurTime() then
			v:Remove()
			del = true
		end
	end

	-- make sure the rest of the elements are moved up
	if del then
		timer.Simple(0, function() mlist:GetCanvas():InvalidateLayout() end)
	end
end

local function makeTeamList(parent, pteam)
	local mlist
	local pnl = vgui.Create("DPanel", parent)
	pnl:DockPadding(0, 0, 0, 0)
	local hs = math.Round(draw.GetFontHeight("RobotoHUD-25") * 1.1)

	function pnl:Paint(w, h)
		surface.SetDrawColor(PHScobDark)
		surface.DrawRect(0, hs, w, h - hs )
	end

	function pnl:Think()
		if not self.RefreshWait or self.RefreshWait < CurTime() then
			self.RefreshWait = CurTime() + 0.1
			doPlayerItems(self, mlist, pteam)
		end
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0, 0, 0, ScreenScaleH(2))
	headp:Dock(TOP)
	headp:SetTall(hs)

	function headp:Paint(w, h)
		surface.SetDrawColor(PHScobDarker)
		draw.RoundedBoxEx(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDarker, true, true, false, false)
		draw.ShadowText(team.GetName(pteam), "RobotoHUD-25", ScreenScaleH(6), 0, team.GetColor(pteam), 0)
	end

	local but = vgui.Create("DButton", headp)
	but:Dock(RIGHT)
	but:SetText("")
	surface.SetFont("RobotoHUD-20")
	local tw, th = surface.GetTextSize("Join team")
	but:SetWide(tw + ScreenScaleH(6))

	function but:DoClick()
		RunConsoleCommand("ph_jointeam", pteam)
	end

	function but:Paint(w, h)
		surface.SetDrawColor(team.GetColor(pteam))

		local col = table.Copy(team.GetColor(pteam))
			if self:IsDown() then
				colMul(col, 0.8)
			elseif self:IsHovered() then
				colMul(col, 1.2)
			end
			
		draw.ShadowText("Join team", "RobotoHUD-20", ScreenScaleH(2), h / 2 - th / 2, col, 0)
	end

	mlist = vgui.Create("DScrollPanel", pnl)
	mlist:Dock(FILL)

	function mlist:Paint(w, h)
	end

	-- child positioning
	local canvas = mlist:GetCanvas()
	canvas:DockPadding(ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4))

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, ScreenScaleH(2))
	end

	local head = vgui.Create("DPanel")
	head:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.05)
	head.perm = true

	function head:Paint(w, h)
		draw.ShadowText("Name", "RobotoHUD-15", ScreenScaleH(2), 0, PHLessWhite, 0)
		draw.ShadowText("Ping", "RobotoHUD-15", w - ScreenScaleH(2), 0, PHLessWhite, 2)
	end

	mlist:AddItem(head)
	return pnl
end

function GM:ScoreboardRoundResults(results)
	self:ScoreboardShow()
	menu.ResultsPanel.Results = results
	menu.ResultsPanel:InvalidateLayout()
end

local function createScoreboardPanel()
	menu = vgui.Create("DFrame")
	GAMEMODE.ScoreboardPanel = menu
	menu:SetSize(ScreenScale(512), ScreenScaleH(384))
	menu:Center()
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)
	menu:SetDraggable(false)
	menu:ShowCloseButton(false)
	menu:SetTitle("")
	menu:DockPadding(ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4))

	function menu:PerformLayout()
		if IsValid(menu.HuntersList) then
			menu.HuntersList:SetWidth((self:GetWide() - ScreenScaleH(8)) * 0.5)
		end
	end

	function menu:Paint(w, h)
		if not tobool(ScobBackground) then
			return
		end
		surface.SetDrawColor(PHScobBlack)
		surface.DrawOutlinedRect(0, 0, w, h, math.Clamp(ScreenScaleH(2), 2, 4))
		surface.SetDrawColor(PHScobDarkest)
		surface.DrawRect(math.Clamp(ScreenScaleH(2), 2, 4), math.Clamp(ScreenScaleH(2), 2, 4), w - math.Clamp(ScreenScaleH(4), 4, 8), h - math.Clamp(ScreenScaleH(4), 4, 8))
	end

	menu.Credits = vgui.Create("DPanel", menu)
	menu.Credits:Dock(TOP)
	menu.Credits:DockMargin(0, 0, 0, ScreenScaleH(2))

	function menu.Credits:Paint(w, h)
		if not tobool(ScobBackground) then
			return
		end
		
		surface.SetFont("RobotoHUD-25")
		local t = GAMEMODE.Name or ""
		local tw = surface.GetTextSize(t)
		draw.ShadowText(t, "RobotoHUD-25", ScreenScaleH(2), draw.GetFontHeight("RobotoHUD-25"), PHRed, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		draw.ShadowText("- "..tostring(GAMEMODE.Version or "error") .. ", maintained by DataNext, code by many cool people :)", "RobotoHUD-L12", tw + ScreenScaleH(8), draw.GetFontHeight("RobotoHUD-L12") * 2, PHLessWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end

	function menu.Credits:PerformLayout()
		surface.SetFont("RobotoHUD-25")
		local _, h = surface.GetTextSize(GAMEMODE.Name || "")
		self:SetTall(h)
	end

	local bottom = vgui.Create("DPanel", menu)
	bottom:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.3)
	bottom:Dock(BOTTOM)
	bottom:DockMargin(0, ScreenScaleH(4), 0, 0)

	surface.SetFont("RobotoHUD-15")
	local tw = surface.GetTextSize("Spectate")

	function bottom:Paint(w, h)
		draw.RoundedBox(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDarker)
		local c
		for k, ply in pairs(team.GetPlayers(TEAM_SPEC)) do
			if c then
				c = c .. ", " .. ply:Nick()
			else
				c = ply:Nick()
			end
		end

		if c then
			draw.ShadowText(c, "RobotoHUD-10", tw + ScreenScaleH(4) + ScreenScaleH(2), h / 2, PHWhite, 0, 1)
		end
	end

	local but = vgui.Create("DButton", bottom)
	but:Dock(LEFT)
	but:SetText("")
	but:DockMargin(0, 0, ScreenScaleH(2), 0)
	but:SetWide(tw + ScreenScaleH(4))

	function but:Paint(w, h)
		local colt = table.Copy(PHLessWhite)
		if self:IsDown() then
			colMul(colt, 0.8)
		elseif self:IsHovered() then
			colMul(colt, 1.2)
		end

		draw.RoundedBox(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDarker)
		draw.ShadowText("Spectate", "RobotoHUD-15", w / 2, h / 2, colt, 1, 1)
	end

	function but:DoClick()
		RunConsoleCommand("ph_jointeam", TEAM_SPEC)
	end

	local main = vgui.Create("DPanel", menu)
	main:Dock(FILL)

	function main:Paint(w, h)
		surface.SetDrawColor(PHScobDarkest)
	end

	menu.HuntersList = makeTeamList(main, TEAM_HUNTER)
	menu.HuntersList:Dock(LEFT)
	menu.HuntersList:DockMargin(0, 0, ScreenScaleH(4), 0)
	menu.PropsList = makeTeamList(main, TEAM_PROP)
	menu.PropsList:Dock(FILL)
end

function GM:ScoreboardShow()
	if not IsValid(menu) then
		createScoreboardPanel()
	end

	menu:SetVisible(true)
end

function GM:ScoreboardHide()
	if IsValid(menu) then
		menu:Close()
	end
end

function GM:DoScoreboardActionPopup(ply)
	local actions = DermaMenu()

	if ply:IsAdmin() then
		local admin = actions:AddOption("Is an Admin")
		admin:SetIcon("icon16/shield.png")
	end

	if ply ~= LocalPlayer() then
		local t = "Mute"
		if ply:IsMuted() then
			t = "Unmute"
		end

		local mute = actions:AddOption(t)
		mute:SetIcon("icon16/sound_mute.png")

		function mute:DoClick()
			if IsValid(ply) then
				ply:SetMuted(not ply:IsMuted())
			end
		end
	end

	actions:Open()
end
