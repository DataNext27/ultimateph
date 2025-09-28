local menu

local function createEndRoundMenu()
	menu = vgui.Create("DFrame")
	menu:SetSize(ScrH() * 0.75, ScrH() * 0.75)
	menu:Center()
	menu:MakePopup()
	menu:SetTitle("")
	menu:ShowCloseButton(false)
	menu:SetMouseInputEnabled(true)
	menu:SetKeyboardInputEnabled(false)
	menu:SetDraggable(false)
	menu:SetDeleteOnClose(false)
	menu:DockPadding(math.Clamp(ScreenScaleH(2), 2, 4), ScreenScaleH(12) + math.Clamp(ScreenScaleH(2), 2, 4), math.Clamp(ScreenScaleH(2), 2, 4), math.Clamp(ScreenScaleH(2), 2, 4))

	local closeButton = vgui.Create('DButton', menu)
	closeButton:SetFont('PHIcons')
	closeButton:SetText('r')
	closeButton.Paint = function(s,w,h)
		if not closeButton:IsHovered() then
			draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,0))
		else
			draw.RoundedBox(0, 0, 0, w, h, PHEndDarker)
		end
	end
	closeButton:SetColor(PHWhite)
	closeButton:SetSize(ScreenScaleH(16), ScreenScaleH(12))
	closeButton:SetPos(math.Round(menu:GetWide() - closeButton:GetWide() - math.Clamp(ScreenScaleH(2), 2, 4)), math.Clamp(ScreenScaleH(2), 2, 4))
	closeButton.DoClick = function()
		menu:Close()
	end

	local matBlurScreen = Material("pp/blurscreen")
	function menu:Paint(w, h)
		-- Create a blured background to the entire menu. This makes the content easier
		-- to read against the semi-transparent background.
		local x, y = self:LocalToScreen(0, 0)
		local Fraction = 0.4

		surface.SetMaterial(matBlurScreen)
		surface.SetDrawColor(255, 255, 255, 255)

		for i = 0.33, 1, 0.33 do
			matBlurScreen:SetFloat("$blur", Fraction * 5 * i)
			matBlurScreen:Recompute()
			if render then render.UpdateScreenEffectTexture() end
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end

		-- draw a scaling 2px outline, clamped to a maximum size of 4 pixels. also don't disable clipping and instead position the content inside the outline
		surface.SetDrawColor(PHEndBlack)
		surface.DrawOutlinedRect(0, 0, w, h, math.Clamp(ScreenScaleH(2), 2, 4))

		-- Title bar rectangle (the title bar is a scaling 12px in height)
		surface.SetDrawColor(PHEndDarkest)
		surface.DrawRect(math.Clamp(ScreenScaleH(2), 2, 4), math.Clamp(ScreenScaleH(2), 2, 4), w - math.Clamp(ScreenScaleH(4), 4, 8), ScreenScaleH(12))

		-- Light grey background on lower area
		surface.SetDrawColor(PHEndDarker)
		surface.DrawRect(math.Clamp(ScreenScaleH(2), 2, 4), ScreenScaleH(12) + math.Clamp(ScreenScaleH(2), 2, 4), w - math.Clamp(ScreenScaleH(4), 4, 8), h - ScreenScaleH(12) - math.Clamp(ScreenScaleH(4), 4, 8))

		-- title text
		draw.SimpleText("Round Over!", 'RobotoHUD-12', math.Round((ScreenScaleH(12) / 8) + math.Clamp(ScreenScaleH(2), 2, 4)), (ScreenScaleH(12) + math.Clamp(ScreenScaleH(2), 2, 4)) / 2, PHLessWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	-- Results section (this is just a container for winner, awards, and resultsTimeLeft)
	local resultsPanel = vgui.Create("DPanel", menu)
	resultsPanel:Dock(FILL)

	function resultsPanel:Paint(w, h) end

	menu.setResultsPanelVisibility = function(isVisible)
		resultsPanel:SetVisible(isVisible)
	end

	-- Text label at the top specifying who won
	local winner = vgui.Create("DLabel", resultsPanel)
	winner:Dock(TOP)
	winner:SetTall(draw.GetFontHeight("RobotoHUD-30"))
	winner:SetFont("RobotoHUD-30")
	winner:SetContentAlignment(5) -- Center

	menu.setWinningTeamText = function(winState)
		if winState == WIN_NONE then
			winner:SetText("Round tied")
			winner:SetColor(PHLessWhite)
		else
			winner:SetText(team.GetName(winState) .. " win!")
			winner:SetColor(team.GetColor(winState))
		end
	end

	-- Middle area where the player awards are listed
	local awards = vgui.Create("DScrollPanel", resultsPanel)
	awards:Dock(FILL)

	function awards:Paint(w, h)
		-- Add a dark rectangle over the area for the awards to visually separate it from rest of the menu
		surface.SetDrawColor(PHEndDark) 
		surface.DrawRect(0, 0, w, h)
	end

	local canvas = awards:GetCanvas()
	canvas:DockPadding(0, 0, 0, 0)

	function canvas:OnChildAdded(child)
		-- Awards fill from top to bottom
		child:Dock(TOP)
		child:DockMargin(ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4), 0)
	end

	menu.setPlayerAwards = function(allAwards)
		awards:Clear()

		for _, award in pairs(allAwards) do
			local containerPanel = vgui.Create("DPanel")
			containerPanel:SetTall(draw.GetFontHeight("RobotoHUD-20"))

			function containerPanel:Paint(w, h)
				draw.DrawText(award.name, "RobotoHUD-10", 0, 0, PHWhite, 0)
				draw.DrawText(award.desc, "RobotoHUD-10", 0, draw.GetFontHeight("RobotoHUD-10"), PHLessWhite, 0)
				draw.DrawText(award.winnerName, "RobotoHUD-15", w, (h / 2) - (draw.GetFontHeight("RobotoHUD-20") / 2), team.GetColor(award.winnerTeam), 2)
			end

			awards:AddItem(containerPanel)
		end
	end

	-- Timer at bottom right showing how long until next round/mapvote
	local resultsTimeLeft = vgui.Create("DPanel", resultsPanel)
	resultsTimeLeft:Dock(BOTTOM)
	resultsTimeLeft:SetTall(draw.GetFontHeight("RobotoHUD-15"))

	function resultsTimeLeft:Paint(w, h)
		-- "Extend" the dark rectangle from awards:Paint to make a larger seamless rectangle
		surface.SetDrawColor(PHEndDark)
		surface.DrawRect(0, 0, w, h)

		if GAMEMODE:GetGameState() == ROUND_POST then
			local settings = GAMEMODE:GetRoundSettings()
			local roundTime = settings.NextRoundTime or 30
			local time = math.max(0, roundTime - GAMEMODE:GetStateRunningTime())
			if GAMEMODE.CurrentRound >= GAMEMODE.RoundLimit:GetInt() then
				draw.DrawText("Map vote in " .. math.ceil(time), "RobotoHUD-15", w - ScreenScaleH(2), 0, PHLessWhite, 2)
			else
				draw.DrawText("Next round in " .. math.ceil(time), "RobotoHUD-15", w - ScreenScaleH(2), 0, PHLessWhite, 2)
			end
		end
	end

	-- Map vote section (container for mapList and mapVoteTimeLeft)
	local votemapPanel = vgui.Create("DPanel", menu)
	votemapPanel:Dock(FILL)

	function votemapPanel:Paint(w, h) end

	menu.setVotemapPanelVisibility = function(isVisible)
		votemapPanel:SetVisible(isVisible)
	end

	-- List containing map images, map names, and map votes
	local mapList = vgui.Create("DScrollPanel", votemapPanel)
	menu.MapVoteList = mapList
	mapList:Dock(FILL)
	mapList:DockMargin(0, 0, 0, 0)
	local vbar = mapList:GetVBar()
	vbar:SetWide(0)

	function mapList:Paint(w, h)
		surface.SetDrawColor(PHEndDark)
		surface.DrawRect(0, 0, w, h)
	end

	local canvas = mapList:GetCanvas()
	canvas:DockPadding(ScreenScaleH(8), 0, ScreenScaleH(8), 0)

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, ScreenScaleH(8), 0, 0)
	end

	-- Text showing time until map vote ends
	local mapVoteTimeLeft = vgui.Create("DPanel", votemapPanel)
	mapVoteTimeLeft:Dock(BOTTOM)
	mapVoteTimeLeft:SetTall(draw.GetFontHeight("RobotoHUD-15"))

	function mapVoteTimeLeft:Paint(w, h)
		surface.SetDrawColor(PHEndDark)
		surface.DrawRect(0, 0, w, h)

		if GAMEMODE:GetGameState() == ROUND_MAPVOTE then
			local voteTime = GAMEMODE.MapVoteTime or 30
			local time = math.max(0, voteTime - GAMEMODE:GetMapVoteRunningTime())
			draw.SimpleText("Voting ends in " .. math.ceil(time), "RobotoHUD-15", w - ScreenScaleH(2), 0, PHLessWhite, TEXT_ALIGN_RIGHT)
		end
	end
end

function GM:EndRoundMenuResults(res)
	self:OpenEndRoundMenu()

	menu.setResultsPanelVisibility(true)
	menu.setVotemapPanelVisibility(false)
	menu.Results = res
	menu.setPlayerAwards(res.playerAwards)
	menu.setWinningTeamText(res.winningTeam)
end

function GM:EndRoundMapVote()
	self:OpenEndRoundMenu()

	menu.setResultsPanelVisibility(false)
	menu.setVotemapPanelVisibility(true)
	menu.MapVoteList:Clear()

	for k, map in pairs(self.MapList) do
		local but = vgui.Create("DButton")
		but:SetText("")
		but:SetTall(math.Clamp(ScreenScaleH(32), 32, 64))

		local png
		local path = "maps/" .. map .. ".png"
		if file.Exists(path, "GAME") then
			png = Material(path, "noclamp")
		else
			local path = "maps/thumb/" .. map .. ".png"
			if file.Exists(path, "GAME") then
				png = Material(path, "noclamp")
			else
				local path = "materials/maps/" .. map .. ".png"
				if file.Exists(path, "GAME") then
					png = Material(path, "noclamp")
				end
			end
		end

		local dname = map:gsub("^%a%a%a?_", ""):gsub("_?v[%d%.%-]+$", "")
		dname = dname:gsub("[_]", " "):gsub("([%a])([%a]+)", function(a, b) return a:upper() .. b end)
		local z = tonumber(util.CRC(dname):sub(1, 8))
		local mcol = Color(z % 255, z / 255 % 255, z / 255 / 255 % 255, 50)
		local gray = PHLessWhite

		but.VotesScroll = 0
		but.VotesScrollDir = 1

		function but:Paint(w, h)
			if self.Hovered then
				surface.SetDrawColor(PHEndGray)
				surface.DrawRect(0, 0, w, h)
			end

			draw.SimpleText(dname, "RobotoHUD-15", but:GetTall() / 0.8, but:GetTall() / 16, PHWhite, 0)
			local fg = draw.GetFontHeight("RobotoHUD-15")
			draw.SimpleText(map, "RobotoHUD-L10", but:GetTall() / 0.8, (but:GetTall() / 16) + fg, PHLessWhite, 0)
			if png then
				surface.SetMaterial(png)
				surface.SetDrawColor(PHWhite)
				surface.DrawTexturedRect(0, 0, but:GetTall(), but:GetTall())
			else
				surface.SetDrawColor(PHEndDarkest)
				surface.DrawRect(0, 0, but:GetTall(), but:GetTall())
				surface.SetDrawColor(mcol)
				surface.DrawRect(but:GetTall() / 4, but:GetTall() / 4, but:GetTall() / 2, but:GetTall() / 2)
			end

			local votes = 0
			if GAMEMODE.MapVotesByMap[map] then
				votes = #GAMEMODE.MapVotesByMap[map]
			end
			
			local fg2 = draw.GetFontHeight("RobotoHUD-L10")
			local i = 0
			for ply, map2 in pairs(GAMEMODE.MapVotes) do
				if IsValid(ply) and map2 == map then
					draw.SimpleText(ply:Nick(), "RobotoHUD-L10", w, i * fg2 - self.VotesScroll, PHLessWhite, 2)
					i = i + 1
				end
			end

			if i * fg2 > but:GetTall() then
				self.VotesScroll = self.VotesScroll + FrameTime() * 14 * self.VotesScrollDir
				if self.VotesScroll > i * fg2 - but:GetTall() then
					self.VotesScrollDir = -1
				elseif self.VotesScroll < 0 then
					self.VotesScrollDir = 1
				end
			end
		end

		function but:DoClick()
			RunConsoleCommand("ph_votemap", map)
		end

		menu.MapVoteList:AddItem(but)
	end
end

function GM:OpenEndRoundMenu()
	if not IsValid(menu) then
		createEndRoundMenu()
	end

	menu:SetVisible(true)
end

function GM:CloseEndRoundMenu()
	if IsValid(menu) then
		menu:Close()
	end
end

function GM:ToggleEndRoundMenuVisibility()
	if IsValid(menu) and menu:IsVisible() then
		GAMEMODE:CloseEndRoundMenu()
	else
		GAMEMODE:OpenEndRoundMenu()
	end
end
