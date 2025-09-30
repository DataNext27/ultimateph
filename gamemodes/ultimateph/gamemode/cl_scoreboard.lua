scoreboard = scoreboard or {}

function scoreboard:show()
	local menu = vgui.Create("DFrame")
	PHScoreboard = menu
	menu:SetSize(ScreenScale(512), ScreenScaleH(384))
	menu:Center()
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDraggable(false)
	menu:ShowCloseButton(false)
	menu:SetTitle("")
	menu:DockPadding(ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4))

	function menu:Paint(w, h)
		if not tobool(ScobBackground) then
			return
		end

		surface.SetDrawColor(PHScobBlack)
		surface.DrawOutlinedRect(0, 0, w, h, math.Clamp(ScreenScaleH(2), 2, 4))
		surface.SetDrawColor(PHScobDarkest)
		surface.DrawRect(math.Clamp(ScreenScaleH(2), 2, 4), math.Clamp(ScreenScaleH(2), 2, 4), w - math.Clamp(ScreenScaleH(4), 4, 8), h - math.Clamp(ScreenScaleH(4), 4, 8))
	end

	Header(menu, TOP)
	SpectatorList(menu, TEAM_SPEC, BOTTOM)
	HunterList = TeamList(menu, TEAM_HUNTER, LEFT)
	PropList = TeamList(menu, TEAM_PROP, RIGHT)

	function scoreboard:hide()
		menu:Close()
	end
end

function Header(parent, dock)
	local Header = vgui.Create("DPanel", parent)
	Header:Dock(dock)
	Header:DockMargin(0, 0, 0, ScreenScaleH(2))

	function Header:Paint(w, h)
		if not tobool(ScobBackground) then
			return
		end
		
		surface.SetFont("RobotoHUD-25")
		self:SetTall(draw.GetFontHeight("RobotoHUD-25"))
		draw.ShadowText(GAMEMODE.Name or "", "RobotoHUD-25", ScreenScaleH(2), draw.GetFontHeight("RobotoHUD-25"), PHRed, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end
end

function TeamList(parent, pteam, dock)
	local PlayerListBG = vgui.Create("DPanel", parent)
	PlayerListBG:Dock(dock)
	PlayerListBG:DockMargin(0, 0, 0, ScreenScale(4))
	PlayerListBG:SetSize(parent:GetWide() / 2 - ScreenScaleH(8), parent:GetTall())

	function PlayerListBG:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 0)
	end

	TeamHeader(PlayerListBG, pteam, TOP, "Join Team")

	local PlayerList = vgui.Create("DListView", PlayerListBG)
	PlayerList:Dock(dock)
	PlayerList:SetSize(PlayerListBG:GetWide(), PlayerListBG:GetTall())
	PlayerList:SetDataHeight(draw.GetFontHeight("RobotoHUD-L20"))
	PlayerList:SetHeaderHeight(draw.GetFontHeight("RobotoHUD-L20"))
	PlayerList:AddColumn("NAME", 1)
	PlayerList:AddColumn("KILLS", 2)
	PlayerList:AddColumn("DEATHS", 3)
	PlayerList:AddColumn("PING", 4)
	
	function PlayerList:Paint(w, h)
		surface.SetDrawColor(PHScobDarkest)
		draw.RoundedBoxEx(0, 0, 0, w, h, PHScobDark, true, true, false, false)
	end
	
	for _, ply in ipairs( team.GetPlayers(pteam) ) do			
		local line = PlayerList:AddLine(ply:Name(), (ply:Frags() + ply:Deaths()), ply:Deaths(), ply:Ping())			
		function line:Paint( w, h )
			if tobool(GroupTags) and GroupColors[ply:GetUserGroup()] ~= nil then
				surface.SetDrawColor(GroupColors[ply:GetUserGroup()])
				self:DrawFilledRect()
			end
				
			for _, cln in pairs( self.Columns ) do
				cln:SetFont("RobotoHUD-L20")
				cln:SetTextColor(PHWhite)
				cln:SetContentAlignment(5)
			end
		end
	end
		
	for _, v in ipairs(PlayerList.Columns) do
		function v.Header:Paint(w, h)
			self:SetFont("RobotoHUD-L20")
			self:SetTextColor(PHLessWhite)
			v:SetTextAlign(5)
		end
	end
end

function TeamHeader(parent, pteam, dock, text)
	local TeamHeader = vgui.Create("DPanel", parent)
	TeamHeader:SetSize(parent:GetWide(), parent:GetTall() / 16)
	TeamHeader:Dock(dock)

	function TeamHeader:Paint(w, h)
		surface.SetDrawColor(PHScobDarker)
		draw.RoundedBoxEx(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDarker, true, true, false, false)
		draw.ShadowText(team.GetName(pteam), "RobotoHUD-25", ScreenScaleH(2), h / 2, team.GetColor(pteam), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	JoinTeam(TeamHeader, pteam, RIGHT, text)
end

function SpectatorList(parent, pteam, dock)
	local SpectatorListBG = vgui.Create("DPanel", parent)
	SpectatorListBG:Dock(dock)
	SpectatorListBG:SetSize(parent:GetWide(), parent:GetTall() / 24)

	function SpectatorListBG:Paint(w, h)
		surface.SetFont("RobotoHUD-20")
		draw.RoundedBox(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDarker)
	end

	JoinTeam(SpectatorListBG, TEAM_SPEC, LEFT, "Spectate")
	
	local SpectatorList = vgui.Create("DHorizontalScroller", SpectatorListBG)
	SpectatorList:SetTall(draw.GetFontHeight("RobotoHUD-20"))
	SpectatorList:Dock(dock)

	for _, ply in ipairs(team.GetPlayers(TEAM_SPEC)) do
		local line = vgui.Create("DLabel", SpectatorList)
		line:SetColor(PHLessWhite)
		line:SetFont("RobotoHUD-L10")
		line:SetText(ply:Nick())
		line:SetWide(line:GetTextSize() + ScreenScaleH(6))
		SpectatorList:AddPanel(line)
	end
end

function JoinTeam(parent, pteam, dock, text)
	local JoinTeam = vgui.Create("DButton", parent)
	JoinTeam:Dock(dock)
	JoinTeam:SetText("")
	surface.SetFont("RobotoHUD-20")
	JoinTeam:SetWide(surface.GetTextSize(text) + ScreenScaleH(6))

	function JoinTeam:Paint(w, h)
		local col = table.Copy(team.GetColor(pteam))
		if self:IsDown() then
			colMul(col, 0.8)
		elseif self:IsHovered() then
			colMul(col, 1.2)
		end
			
		draw.ShadowText(text, "RobotoHUD-20", w - ScreenScaleH(2), h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	function JoinTeam:DoClick()
		RunConsoleCommand("ph_jointeam", pteam)
	end
end

function GM:ScoreboardShow()
	if IsValid(PHScoreboard) then
		scoreboard:hide()
	end
	scoreboard:show()
end

function GM:ScoreboardHide()
	if IsValid(PHScoreboard) then
		scoreboard:hide()
	end
end

-- hack to update player list w/o constantly running through loops. todo: add a proper refresh function
net.Receive("TeamChanged", function(ply)
	timer.Simple(0.1, function() 
		if IsValid(PHScoreboard) then
			RunConsoleCommand("-showscores")
			timer.Simple(0, function() RunConsoleCommand("+showscores") end)
		end
	end)
end)
