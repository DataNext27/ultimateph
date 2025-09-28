local menu
local lastCursorX
local lastCursorY

local function saveCursor()
	lastCursorX, lastCursorY = input.GetCursorPos()
end

local function restoreCursor()
	if not lastCursorX then 
		return 
	end

	input.SetCursorPos(lastCursorX, lastCursorY)
	lastCursorX = nil
	lastCursorY = nil
end

local function fillList(mlist, taunts, cat)
	menu.CurrentTaunts = taunts
	menu.CurrentTauntCat = cat
	for k, v in pairs(menu.CatList:GetCanvas():GetChildren()) do
		v.Selected = false
		if v.CatName == cat then
			v.Selected = true
		end
	end

	mlist:Clear()
	for k, t in pairs(taunts) do
		if not TauntAllowedForPlayer(LocalPlayer(), t) then 
			continue 
		end

		local but = vgui.Create("DButton")
		but:SetTall(draw.GetFontHeight("RobotoHUD-L15") * 1.0)
		but:SetText("")

		function but:Paint(w, h)
			local col = table.Copy(PHWhite)
			if self:IsDown() then
				colMul(col, 0.5)
			elseif self:IsHovered() then
				colMul(col, 0.8)
			end
			draw.ShadowText(t.name, "RobotoHUD-L15", 0, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.ShadowText(math.Round(t.soundDuration % 60, 2) .. "s", "RobotoHUD-L10", w - ScreenScaleH(2), h / 2, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

		function but:DoClick()
			RunConsoleCommand("ph_taunt", t.sound[math.random(#t.sound)])
			saveCursor()
			menu:Close()
		end

		mlist:AddItem(but)
	end
end

local function addCat(clist, name, taunts, mlist)
	local dname = name:lower():gsub("[_]", " ")
	dname = dname:sub(1, 1):upper() .. dname:sub(2)

	local but = vgui.Create("DButton")
	but:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.25)
	but:SetText("")
	but.Selected = false
	but.CatName = name

	function but:Paint(w, h)
		local col = table.Copy(PHTauntDark)
		local colt = table.Copy(PHLessWhite)
		if not self.Selected then
			colMul(col, 0.7)
			if self:IsDown() then
				colMul(colt, 0.5)
			elseif self:IsHovered() then
				colMul(colt, 1.2)
			end
		else
			colMul(colt, 1.2)
		end

		draw.RoundedBoxEx(ScreenScaleH(CornerRadius), 0, 0, w, h, col, true, false, true, false)
		draw.ShadowText(dname, "RobotoHUD-15", w / 2, h / 2, colt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function but:DoClick()
		fillList(mlist, taunts, name)
		self.Selected = true
	end

	clist:AddItem(but)
	return but
end

local function fillCats(clist, mlist)
	clist:Clear()
	local all = addCat(clist, "all", Taunts, mlist)
	for k, taunts in pairs(TauntCategories) do
		local c = 0
		for a, t in pairs(taunts) do
			if not TauntAllowedForPlayer(LocalPlayer(), t) then continue end

			c = c + 1
		end

		if c > 0 then
			addCat(clist, k, taunts, mlist)
		end
	end

	all.Selected = true
end

local function openTauntMenu()
	restoreCursor()
	if IsValid(menu) then
		fillCats(menu.CatList, menu.TauntList)
		fillList(menu.TauntList, menu.CurrentTaunts, menu.CurrentTauntCat)
		if menu:IsVisible() then
			saveCursor()
		end

		menu:SetVisible(not menu:IsVisible())
		return
	end

	menu = vgui.Create("DFrame")
	menu:SetSize(ScrH() * 0.75, ScrH() * 0.75)
	menu:Center()
	menu:SetTitle("")
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)
	menu:SetDraggable(false)
	menu:ShowCloseButton(false)
	menu:DockPadding(ScreenScaleH(4), ScreenScaleH(4) + draw.GetFontHeight("RobotoHUD-25"), ScreenScaleH(4), ScreenScaleH(4))

	local closeButton = vgui.Create('DButton', menu)
	closeButton:SetFont('PHIcons')
	closeButton:SetText('r')
	closeButton.Paint = function(s,w,h)
		if not closeButton:IsHovered() then
			draw.RoundedBox(0, 0, 0, w, h, Color(0,0,0,0))
		else
			draw.RoundedBox(0, 0, 0, w, h, PHTauntDarker)
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
		-- copy the blur from endround panel for more consistent UI
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
		
		surface.SetDrawColor(PHTauntBlack)
		surface.DrawOutlinedRect(0, 0, w, h, math.Clamp(ScreenScaleH(2), 2, 4))
		surface.SetDrawColor(PHTauntDarker)
		surface.DrawRect(math.Clamp(ScreenScaleH(2), 2, 4), math.Clamp(ScreenScaleH(2), 2, 4), w - math.Clamp(ScreenScaleH(4), 4, 8), h - math.Clamp(ScreenScaleH(4), 4, 8))
		surface.SetFont("RobotoHUD-25")
		local t = "Taunts"
		local tw = surface.GetTextSize(t)
		draw.ShadowText(t, "RobotoHUD-25", ScreenScaleH(4), draw.GetFontHeight("RobotoHUD-25"), PHBlue, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		draw.ShadowText("- ".. TauntMenuPhrase, "RobotoHUD-L15", ScreenScaleH(8) + tw, draw.GetFontHeight("RobotoHUD-L15"), PHLessWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local leftpnl = vgui.Create("DPanel", menu)
	leftpnl:Dock(LEFT)
	leftpnl:DockMargin(0, 0, 0, 0)
	leftpnl:SetWide(menu:GetWide() / 4)
	function leftpnl:Paint(w, h)
	end

	local but = vgui.Create("DButton", leftpnl)
	but:Dock(BOTTOM)
	but:DockMargin(0, ScreenScaleH(2), ScreenScaleH(2), 0)
	but:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.25)
	but:SetText("")

	function but:Paint(w, h)
		local col = table.Copy(PHTauntDark)
		local colt = table.Copy(PHLessWhite)
		if self:IsDown() then
			colMul(colt, 0.5)
		elseif self:IsHovered() then
			colMul(colt, 1.2)
		end

		draw.RoundedBoxEx(ScreenScaleH(CornerRadius), 0, 0, w, h, col, true, true, true, true)
		draw.ShadowText("Random", "RobotoHUD-15", w / 2, h / 2, colt, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function but:DoClick()
		RunConsoleCommand("ph_taunt_random")
		saveCursor()
		menu:Close()
	end

	local clist = vgui.Create("DScrollPanel", leftpnl)
	menu.CatList = clist
	clist:Dock(FILL)
	clist:DockMargin(0, 0, 0, 0)

	function clist:Paint(w, h)
	end

	local canvas = clist:GetCanvas()
	canvas:DockPadding(0, 0, 0, 0)

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, ScreenScaleH(2))
	end

	local mlist = vgui.Create("DScrollPanel", menu)
	menu.TauntList = mlist
	mlist:Dock(FILL)
	
	local vbar = mlist:GetVBar()
	vbar:SetWide(0)

	function mlist:Paint(w, h)
		surface.SetDrawColor(PHTauntDark)
		surface.DrawOutlinedRect(0, 0, w, h, math.Clamp(ScreenScaleH(2), 2, 4))
		surface.SetDrawColor(PHTauntDarkest)
	end

	-- child positioning
	local canvas = mlist:GetCanvas()
	canvas:DockPadding(ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4), ScreenScaleH(4))

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, 0)
	end

	fillList(mlist, Taunts)
	fillCats(clist, mlist, "all")
end

concommand.Add("ph_menu_taunt", openTauntMenu)
net.Receive("open_taunt_menu", openTauntMenu)

net.Receive("ph_set_taunt_menu_phrase", function()
	value_new = net.ReadString()

	-- Prevent this from being done more than once. GMod is weird.
	if TauntMenuPhrase == value_new then return end
	TauntMenuPhrase = value_new
end)
