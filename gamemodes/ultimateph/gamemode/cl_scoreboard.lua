if GAMEMODE && IsValid(GAMEMODE.ScoreboardPanel) then
	GAMEMODE.ScoreboardPanel:Remove()
end

local menu
include("cl_colors.lua")

GroupColors = {}
GroupColors["owner"] = PHGreen
GroupColors["superadmin"] = PHPink
GroupColors["headadmin"] = PHMauve
GroupColors["admin"] = PHYellow
GroupColors["moderator"] = PHBlue
GroupColors["operator"] = PHPink
GroupColors["superowner"] = PHRed
GroupColors["trusted"] = PHPeach
GroupColors["user"] = PHTeal

GroupNames = {}
GroupNames["owner"] = "Owner"
GroupNames["superadmin"] = "Super Admin"
GroupNames["headadmin"] = "Head Admin"
GroupNames["admin"] = "Admin"
GroupNames["moderator"] = "Moderator"
GroupNames["operator"] = "Operator"
GroupNames["superowner"] = "Super Owner"
GroupNames["trusted"] = "Trusted"
GroupNames["user"] = "User"

surface.CreateFont("ScoreboardPlayer" , {
	font = "coolvetica",
	size = 32,
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
	but:SetTall(draw.GetFontHeight("RobotoHUD-20"))
	but:SetText("")

	function but:Paint(w, h)
		if GroupColors[ply:GetUserGroup()] ~= nil then
			surface.SetDrawColor(Color(GroupColors[ply:GetUserGroup()].r, GroupColors[ply:GetUserGroup()].g, GroupColors[ply:GetUserGroup()].b))
		else 
			surface.SetDrawColor(PHGreen)
		end
		self:DrawFilledRect()
		
		if IsValid(ply) && ply:IsPlayer() then
			local s = 4
			if !ply:Alive() then
				surface.SetMaterial(skull)
				surface.SetDrawColor(220, 220, 220, 255)
				surface.DrawTexturedRect(s, h / 2 - 16, 32, 32)
				s = s + 32 + 4
			end
			
			if ply:IsMuted() then
				surface.SetMaterial(muted)

				-- draw mute icon
				surface.SetDrawColor(150, 150, 150, 255)
				surface.DrawTexturedRect(s, h / 2 - 16, 32, 32)
				s = s + 32 + 4
			end

			local col = color_white
			draw.SimpleText(ply:Ping(), "RobotoHUD-L20", w - 4, 0, col, 2)
			if GroupNames[ply:GetUserGroup()] then
				draw.SimpleText("["..GroupNames[ply:GetUserGroup()].."]", "RobotoHUD-L20", s, 0, PHDarkest, 0)
				s = s + surface.GetTextSize("["..GroupNames[ply:GetUserGroup()].."]") + 4
				draw.SimpleText(ply:Nick(), "RobotoHUD-L20", s, 0, col, 0)
			else
				draw.SimpleText(ply:Nick(), "RobotoHUD-L20", s, 0, col, 0)
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

		if !found then
			addPlayerItem(self, mlist, ply, pteam)
		end
	end

	local del = false
	for t, v in pairs(mlist:GetCanvas():GetChildren()) do
		if !v.perm && v.ctime != CurTime() then
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
		surface.SetDrawColor(PHDarkest)
		surface.DrawLine(0, hs, 0, h - 1)
		surface.DrawLine(w - 1, hs, w - 1, h - 1)
		surface.DrawLine(0, h - 1, w, h - 1)
		surface.SetDrawColor(PHDarker)
		surface.DrawRect(1, hs, w - 2, h - hs)
	end

	function pnl:Think()
		if !self.RefreshWait || self.RefreshWait < CurTime() then
			self.RefreshWait = CurTime() + 0.1
			doPlayerItems(self, mlist, pteam)
		end
	end

	local headp = vgui.Create("DPanel", pnl)
	headp:DockMargin(0, 0, 0, 4)
	headp:Dock(TOP)
	headp:SetTall(hs)

	function headp:Paint(w, h)
		surface.SetDrawColor(68, 68, 68, 255)
		draw.RoundedBoxEx(4, 0, 0, w, h, PHDarkest, true, true, false, false)
		draw.SimpleText(team.GetName(pteam), "RobotoHUD-25", 6, 0, team.GetColor(pteam), 0)
	end

	local but = vgui.Create("DButton", headp)
	but:Dock(RIGHT)
	but:SetText("")
	surface.SetFont("RobotoHUD-20")
	local tw, th = surface.GetTextSize("Join team")
	but:SetWide(tw + 6)

	function but:DoClick()
		RunConsoleCommand("ph_jointeam", pteam)
	end

	function but:Paint(w, h)
		surface.SetDrawColor(team.GetColor(pteam))
		surface.SetDrawColor(color_black)

		local col = table.Copy(team.GetColor(pteam))
		if self:IsDown() then
			surface.SetDrawColor(12, 50, 50, 120)
			col.r = col.r * 0.8
			col.g = col.g * 0.8
			col.b = col.b * 0.8
		elseif self:IsHovered() then
			surface.SetDrawColor(255, 255, 255, 30)
			col.r = col.r * 1.2
			col.g = col.g * 1.2
			col.b = col.b * 1.2
		end

		draw.SimpleText("Join team", "RobotoHUD-20", 2, h / 2 - th / 2, col, 0)
	end

	mlist = vgui.Create("DScrollPanel", pnl)
	mlist:Dock(FILL)

	function mlist:Paint(w, h)
	end

	-- child positioning
	local canvas = mlist:GetCanvas()
	canvas:DockPadding(8, 8, 8, 8)

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, 4)
	end

	local head = vgui.Create("DPanel")
	head:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.05)
	head.perm = true
	local col = Color(190, 190, 190)

	function head:Paint(w, h)
		draw.SimpleText("Name", "RobotoHUD-15", 4, 0, col, 0)
		draw.SimpleText("Ping", "RobotoHUD-15", w - 4, 0, col, 2)
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
	menu:SetSize(ScrW() * 0.8, ScrH() * 0.8)
	menu:Center()
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)
	menu:SetDraggable(false)
	menu:ShowCloseButton(false)
	menu:SetTitle("")
	menu:DockPadding(8, 8, 8, 8)

	function menu:PerformLayout()
		if IsValid(menu.HuntersList) then
			menu.HuntersList:SetWidth((self:GetWide() - 16) * 0.5)
		end
	end

	function menu:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end
	
    local bottom = vgui.Create("DPanel", menu)
	bottom:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.3)
	bottom:Dock(BOTTOM)
	bottom:DockMargin(0, 8, 0, 0)

	surface.SetFont("RobotoHUD-15")
	local tw = surface.GetTextSize("Spectate")

	function bottom:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, PHDarker)
		local c
		for k, ply in pairs(team.GetPlayers(TEAM_SPEC)) do
			if c then
				c = c .. ", " .. ply:Nick()
			else
				c = ply:Nick()
			end
		end

		if c then
			draw.ShadowText(c, "RobotoHUD-10", tw + 8 + 4, h / 2, color_white, 0, 1)
		end
	end

	local but = vgui.Create("DButton", bottom)
	but:Dock(LEFT)
	but:SetText("")
	but:DockMargin(0, 0, 4, 0)
	but:SetWide(tw + 8)

	function but:Paint(w, h)	
	local col = PHWhite
	if self:IsDown() then
		col = PHLessWhite
	elseif self:IsHovered() then
		col = PHLessWhite
	end

		draw.RoundedBox(0, 0, 0, w, h, PHDarkest)
		draw.SimpleText("Spectate", "RobotoHUD-15", w / 2, h / 2, col, 1, 1)
	end

	function but:DoClick()
		RunConsoleCommand("ph_jointeam", TEAM_SPEC)
	end

	local main = vgui.Create("DPanel", menu)
	main:Dock(FILL)

	function main:Paint(w, h)
		surface.SetDrawColor(40, 40, 40, 0)
	end

	menu.HuntersList = makeTeamList(main, TEAM_HUNTER)
	menu.HuntersList:Dock(LEFT)
	menu.HuntersList:DockMargin(0, 0, 8, 0)
	menu.PropsList = makeTeamList(main, TEAM_PROP)
	menu.PropsList:Dock(FILL)
end

function GM:ScoreboardShow()
	if !IsValid(menu) then
		createScoreboardPanel()
	end

	menu:SetVisible(true)
end

function GM:ScoreboardHide()
	if IsValid(menu) then
		menu:Close()
		DermaMenu()
	end
end

function GM:DoScoreboardActionPopup(ply)
	local actions = DermaMenu()

	if ply != LocalPlayer() then
		local t = "Mute"
		if ply:IsMuted() then
			t = "Unmute"
		end

		local mute = actions:AddOption(t)
		mute:SetIcon("icon16/sound_mute.png")

		function mute:DoClick()
			if IsValid(ply) then
				ply:SetMuted(!ply:IsMuted())
			end
		end
	end

	local t = "View Steam Profile"
	local steamprofile = actions:AddOption(t)
	steamprofile:SetIcon("icon16/application.png")

	function steamprofile:DoClick()
		if IsValid(ply) then
			gui.OpenURL("https://steamcommunity.com/profiles/".. ply:SteamID64())
		end
	end

-- this requires ulx
	if LocalPlayer():IsAdmin() then
		local t = "Force Team Switch"
		local switchteams = actions:AddOption(t)
		switchteams:SetIcon("icon16/shield.png")

		function switchteams:DoClick()
			if IsValid(ply) then
				LocalPlayer():ConCommand("ulx teamswitch ".. ply:Nick())
			end
		end
	end

	actions:Open()
end
