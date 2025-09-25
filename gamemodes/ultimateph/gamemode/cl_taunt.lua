include("sh_taunt.lua")
include("cl_colors.lua")

local menu
local lastCursorX
local lastCursorY

local function saveCursor()
	lastCursorX, lastCursorY = input.GetCursorPos()
end

local function restoreCursor()
	if !lastCursorX then return end

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
		if !TauntAllowedForPlayer(LocalPlayer(), t) then continue end

		local but = vgui.Create("DButton")
		but:SetTall(draw.GetFontHeight("RobotoHUD-L15") * 1.0)
		but:SetText("")

		function but:Paint(w, h)
			if self:IsDown() then
				col = PHLesserWhite
			elseif self:IsHovered() then
				col = PHLesserWhite
			else
				col = PHWhite
			end
			draw.ShadowText(t.name, "RobotoHUD-L15", 0, h / 2, col, 0, 1)
			draw.ShadowText(math.Round(t.soundDuration * 10) / 10 .. "s", "RobotoHUD-L10", w, h / 2, col, 2, 1)
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
	but:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.3)
	but:SetText("")
	but.Selected = false
	but.CatName = name

	function but:Paint(w, h)
		local colt = PHWhite
		if !self.Selected then
			col = Color(PHDarker.r, PHDarker.g, PHDarker.b)
			if self:IsDown() then
				col = Color(PHDarker.r, PHDarker.g, PHDarker.b)
			elseif self:IsHovered() then
				col = Color(PHDark.r, PHDark.g, PHDark.b)
			end
		else
			col = Color(PHDark.r, PHDark.g, PHDark.b)
		end

		draw.RoundedBoxEx(4, 0, 0, w, h, col, true, false, true, false)
		draw.ShadowText(dname, "RobotoHUD-15", w / 2, h / 2, colt, 1, 1)
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
			if !TauntAllowedForPlayer(LocalPlayer(), t) then continue end

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

		menu:SetVisible(!menu:IsVisible())
		return
	end

	menu = vgui.Create("DFrame")
	menu:SetSize(ScrW() * 0.4, ScrH() * 0.8)
	menu:Center()
	menu:SetTitle("")
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)
	menu:SetDraggable(false)
	menu:ShowCloseButton(false)
	menu:DockPadding(8, 8 + draw.GetFontHeight("RobotoHUD-25"), 8, 8)
	
	local closeButton = vgui.Create('DButton', menu)
	closeButton:SetFont('marlett')
	closeButton:SetText('r')
	closeButton.Paint = function(s,w,h)
		draw.RoundedBox(0,0,0,w,h,Color(PHDarkest.r, PHDarkest.g, PHDarkest.b))
	end
	closeButton.OnCursorEntered = function()
		closeButton.Paint = function(s,w,h)
			draw.RoundedBox(0,0,0,w,h,Color(PHDarker.r, PHDarker.g, PHDarker.b))
		end
	end
	closeButton.OnCursorExited = function()
		closeButton.Paint = function(s,w,h)
			draw.RoundedBox(0,0,0,w,h,Color(PHDarkest.r, PHDarkest.g, PHDarkest.b))
		end
	end
	closeButton:SetColor(PHWhite)
	closeButton:SetSize(menu:GetWide() / 20, menu:GetTall() / 30)
	closeButton:SetPos(menu:GetWide() / 1.05, 0)
	closeButton.DoClick = function()
		menu:Close()
	end

	function menu:Paint(w, h)
		surface.SetDrawColor(PHDarkest.r, PHDarkest.g, PHDarkest.b)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("RobotoHUD-25")
		local t = "Taunts"
		local tw, th = surface.GetTextSize(t)
		draw.SimpleText(t, "RobotoHUD-25", 8, 2, PHBlue, 0)
		draw.SimpleText(TauntMenuPhrase, "RobotoHUD-L15", 8 + tw + 16, 2 + th * 0.90, PHWhite, 0, 4)
	end

	local leftpnl = vgui.Create("DPanel", menu)
	leftpnl:Dock(LEFT)
	leftpnl:DockMargin(0, 0, 0, 0)
	leftpnl:SetWide(menu:GetWide() * 0.3)
	function leftpnl:Paint(w, h)
	end

	local but = vgui.Create("DButton", leftpnl)
	but:Dock(BOTTOM)
	but:DockMargin(0, 4, 4, 0)
	but:SetTall(draw.GetFontHeight("RobotoHUD-15") * 1.3)
	but:SetText("")

	function but:Paint(w, h)
		local colt = PHWhite
		if self:IsDown() then
			col = Color(PHDark.r, PHDark.g, PHDark.b)
		elseif self:IsHovered() then
			col = Color(PHDark.r, PHDark.g, PHDark.b)
		else
			col = Color(PHDarker.r, PHDarker.g, PHDarker.b)
		end

		draw.RoundedBoxEx(4, 0, 0, w, h, col, true, true, true, true)
		draw.ShadowText("Random", "RobotoHUD-15", w / 2, h / 2, colt, 1, 1)
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
		child:DockMargin(0, 0, 0, 4)
	end

	local mlist = vgui.Create("DScrollPanel", menu)
	menu.TauntList = mlist
	mlist:Dock(FILL)

	function mlist:Paint(w, h)
		surface.SetDrawColor(PHDarkest.r, PHDarkest.g, PHDarkest.b)
		surface.DrawOutlinedRect(0, 0, w, h)
		surface.SetDrawColor(PHDarker.r, PHDarker.g, PHDarker.b)
		surface.DrawRect(1, 1, w - 2, h - 2)
	end

	-- child positioning
	local canvas = mlist:GetCanvas()
	canvas:DockPadding(8, 8, 8, 8)

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 0, 0, 4)
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
