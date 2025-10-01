scoreboard = scoreboard or {}

function scoreboard:show() -- setup the main parent from which all elements will dock
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

	-- all the scoreboard elements have been broken out into individual functions for the sake of reducing duplicate code and improving modularity. they are called here
	if tobool(ScobBackground) then
		Header(menu, TOP)
	end
	
	SpectatorList(menu, TEAM_SPEC, BOTTOM)
	PlayerList(menu, TEAM_HUNTER, LEFT)
	PlayerList(menu, TEAM_PROP, RIGHT)

	function scoreboard:hide()
		menu:Close()
	end
end

function Header(parent, dock)
	local Header = vgui.Create("DPanel", parent)
	Header:Dock(dock)
	Header:DockMargin(0, 0, 0, ScreenScaleH(2))

	function Header:Paint(w, h)
		surface.SetFont("RobotoHUD-18")
		self:SetTall(draw.GetFontHeight("RobotoHUD-18"))
		draw.SimpleText(GAMEMODE.Name or "", "RobotoHUD-18", ScreenScaleH(2), draw.GetFontHeight("RobotoHUD-18"), PHRed, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end
end

function PlayerList(parent, pteam, dock)
	local PlayerListBG = vgui.Create("DPanel", parent)
	PlayerListBG:Dock(dock)
	PlayerListBG:DockMargin(0, 0, 0, ScreenScale(4))
	PlayerListBG:SetSize(parent:GetWide() / 2 - ScreenScaleH(8), parent:GetTall())

	function PlayerListBG:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 0)
	end

	TeamHeader(PlayerListBG, pteam, TOP, "Join Team") -- call the header early so it docks properly

	local PlayerList = vgui.Create("DListView", PlayerListBG)
	PlayerList:Dock(FILL)
	PlayerList:SetSize(PlayerListBG:GetWide(), PlayerListBG:GetTall())
	PlayerList:SetDataHeight(ScreenScaleH(16))
	PlayerList:SetHeaderHeight(draw.GetFontHeight("RobotoHUD-L18"))
	surface.SetFont("RobotoHUD-L18")
	PlayerList:AddColumn("", 1):SetFixedWidth(ScreenScaleH(16))
	PlayerList:AddColumn("", 2):SetFixedWidth(PlayerList:GetWide() - (ScreenScaleH(16) + surface.GetTextSize("KILLS") + surface.GetTextSize("DEATHS") + surface.GetTextSize("PING")))
	PlayerList:AddColumn("KILLS", 3):SetFixedWidth(surface.GetTextSize("KILLS"))
	PlayerList:AddColumn("DEATHS", 4):SetFixedWidth(surface.GetTextSize("DEATHS"))
	PlayerList:AddColumn("PING", 5):SetFixedWidth(surface.GetTextSize("PING"))
	
	function PlayerList:Paint(w, h)
		surface.SetDrawColor(PHScobDarkest)
		draw.RoundedBoxEx(0, 0, 0, w, h, PHScobDark, true, true, false, false)
	end
	
	for _, ply in ipairs( team.GetPlayers(pteam) ) do
		local line = PlayerList:AddLine(nil, ply:Nick(), ply:Frags(), ply:Deaths(), ply:Ping()) -- leave column 1 empty to override with player's avatar later
		
		function line:Paint( w, h )
			if tobool(GroupTags) and GroupColors[ply:GetUserGroup()] ~= nil then
				surface.SetDrawColor(GroupColors[ply:GetUserGroup()])
				self:DrawFilledRect()
			end
		end

		for id, cln in ipairs( line.Columns ) do
			cln:SetFont("RobotoHUD-L18")
			cln:SetTextColor(PHWhite)

			if id == 1 then -- override the content of column1 with avatar, group, mute and death icons
				local Avatar = vgui.Create( "AvatarImage", cln )
				Avatar:SetPos( 0, 0 )
				Avatar:SetSize(ScreenScaleH(16), ScreenScaleH(16))
				Avatar:SetPlayer( ply, 64 )
				Avatar:Dock(FILL)
				ply.PHAvatar = Avatar

				if not ply:Alive() then
					local DeadMat = vgui.Create("DLabel", ply.PHAvatar)
					DeadMat:Dock(FILL)
					DeadMat:SetTextColor(PHRed)
					DeadMat:SetFont("PHIcons-16")
					DeadMat:SetText("r")
					DeadMat:SetContentAlignment(5)
				end

				if tobool(GroupTags) and GroupIcons[ply:GetUserGroup()] ~= nil then
					local GroupMat = vgui.Create("Material", ply.PHAvatar)
					GroupMat:SetPos(0, 0)
					GroupMat:SetSize(ply.PHAvatar:GetWide() / 3, ply.PHAvatar:GetTall() / 3)
					GroupMat:SetFGColor(PHWhite)
					GroupMat:SetMaterial(GroupIcons[ply:GetUserGroup()])
					GroupMat.AutoSize = false
				end
			end

			if id == 2 then -- adjust text alignment for player names (align left center)
				cln:SetContentAlignment(4)
				continue
			end

			cln:SetContentAlignment(5) -- set the rest to align center center
		end
	end
		
	for id, v in ipairs(PlayerList.Columns) do
		function v.Header:Paint(w, h)
			self:SetFont("RobotoHUD-L14")
			self:SetTextColor(PHLessWhite)
		end

		if id <= 2 then
			v:SetTextAlign(4)
			continue
		end

		v:SetTextAlign(5)
	end
end

function TeamHeader(parent, pteam, dock, text)
	local TeamHeader = vgui.Create("DPanel", parent)
	TeamHeader:SetSize(parent:GetWide(), parent:GetTall() / 16)
	TeamHeader:Dock(dock)

	function TeamHeader:Paint(w, h)
		surface.SetDrawColor(PHScobDarker)
		draw.RoundedBoxEx(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDarker, true, true, false, false)
		draw.SimpleText(team.GetName(pteam), "RobotoHUD-18", ScreenScaleH(2), h / 2, team.GetColor(pteam), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	
	JoinTeam(TeamHeader, pteam, RIGHT, text)
end

function SpectatorList(parent, pteam, dock)
	local SpectatorListBG = vgui.Create("DPanel", parent)
	SpectatorListBG:Dock(dock)
	SpectatorListBG:SetSize(parent:GetWide(), parent:GetTall() / 24)

	function SpectatorListBG:Paint(w, h)
		surface.SetFont("RobotoHUD-18")
		draw.RoundedBox(ScreenScaleH(CornerRadius), 0, 0, w, h, PHScobDark)
	end

	JoinTeam(SpectatorListBG, TEAM_SPEC, LEFT, "Spectate")
	
	local SpectatorList = vgui.Create("DHorizontalScroller", SpectatorListBG)
	SpectatorList:SetTall(draw.GetFontHeight("RobotoHUD-18"))
	SpectatorList:Dock(dock)

	for _, ply in ipairs(team.GetPlayers(TEAM_SPEC)) do
		local line = vgui.Create("DLabel", SpectatorList)
		line:SetColor(PHLessWhite)
		line:SetFont("RobotoHUD-L14")
		line:SetText(ply:Nick())
		line:SetWide(line:GetTextSize() + ScreenScaleH(6))
		SpectatorList:AddPanel(line)
	end
end

function JoinTeam(parent, pteam, dock, text)
	local JoinTeam = vgui.Create("DButton", parent)
	JoinTeam:Dock(dock)
	JoinTeam:SetText("")
	surface.SetFont("RobotoHUD-18")
	JoinTeam:SetWide(surface.GetTextSize(text) + ScreenScaleH(6))

	function JoinTeam:Paint(w, h)
		local col = table.Copy(team.GetColor(pteam))
		if self:IsDown() then
			colMul(col, 0.8)
		elseif self:IsHovered() then
			colMul(col, 1.2)
		end
			
		draw.SimpleText(text, "RobotoHUD-18", w - ScreenScaleH(2), h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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
function scoreboard:refresh()
	timer.Simple(0.1, function() 
		if IsValid(PHScoreboard) then
			RunConsoleCommand("-showscores")
			timer.Simple(0, function() RunConsoleCommand("+showscores") end)
		end
	end)
end

net.Receive("TeamChanged", function(ply)
	scoreboard:refresh()
end)

net.Receive("PlayerDeath", function(ply)
	scoreboard:refresh()
end)
