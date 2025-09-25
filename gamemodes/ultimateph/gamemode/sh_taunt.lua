Taunts = {}
TauntCategories = {}
AllowedTauntSounds = {}
TauntMenuPhrase = "make annoying fart sounds"

function FilenameToSoundname(filename)
	local sndName = string.Trim(filename)
	sndName = string.Replace(sndName, "/", "_")
	return string.Replace(sndName, ".", "_")
end

function PlayerModelTauntAllowed(ply, whitelist)
	if whitelist == nil then return true end

	local mod = ply:GetModel()
	mod = player_manager.TranslateToPlayerModelName(mod)
	local models = player_manager.AllValidModels()
	for _, v in pairs(whitelist) do
		if !models[v] then
			-- v was not a name, so check it as a path
			v = string.lower(v)
			v = player_manager.TranslateToPlayerModelName(v)
		end

		if mod == v then return true end
	end

	return false
end

local function teamNameToNum(pteam)
	pteam = pteam:lower()
	if pteam == "prop" || pteam == "props" then
		return TEAM_PROP
	elseif pteam == "hunter" || pteam == "hunters" then
		return TEAM_HUNTER
	end
	return nil
end

local function teamNameTableToNumTable(pteams)
	local ret = {}
	for i, pteam in ipairs(pteams) do
		ret[i] = teamNameToNum(pteam)
	end
	return ret
end

function TauntAllowedForPlayer(ply, tauntTable)
	if tauntTable.sex then
		if GAMEMODE && GAMEMODE.PlayerModelSex then
			if tauntTable.sex != GAMEMODE.PlayerModelSex then
				return false
			end
		elseif tauntTable.sex != ply.ModelSex then
			return false
		end
	end

	if type(tauntTable.team) == "table" then
		if !table.HasValue(tauntTable.team, ply:Team()) then
			return false
		end
	elseif tauntTable.team != ply:Team() then
		return false
	end

	return PlayerModelTauntAllowed(ply, tauntTable.allowedModels)
end

-- display name, table of sound files, team (name or id), sex (nil for both), table of category ids, [duration in seconds]
local function addTaunt(name, snd, pteam, sex, cats, duration, allowedModels)
	if !name || type(name) != "string" then return end
	if type(snd) != "table" then snd = {tostring(snd)} end
	if #snd == 0 then error("No sounds for " .. name) return end

	local t = {}
	t.sound = snd
	t.categories = cats
	if type(pteam) == "string" then
		t.team = teamNameToNum(pteam)
	elseif type(pteam) == "table" then
		t.team = teamNameTableToNumTable(pteam)
	else
		t.team = tonumber(pteam)
	end

	if sex && #sex > 0 then
		t.sex = sex
		if sex == "both" || sex == "nil" then
			t.sex = nil
		end
	end

	t.name = name
	t.allowedModels = allowedModels

	local dur, count = 0, 0
	for k, v in pairs(snd) do
		sound.Add({
			name = FilenameToSoundname(v),
			channel = CHAN_AUTO,
			level = 75,
			sound = v
		})

		if !AllowedTauntSounds[v] then AllowedTauntSounds[v] = {} end
		table.insert(AllowedTauntSounds[v], t)
		dur = dur + SoundDuration(v)
		count = count + 1
	end

	t.soundDuration = dur / count
	if tonumber(duration) then
		t.soundDuration = tonumber(duration)
		t.soundDurationOverride = tonumber(duration)
	end

	table.insert(Taunts, t)
	if cats then
		for k, cat in pairs(cats) do
			if !TauntCategories[cat] then TauntCategories[cat] = {} end
			table.insert(TauntCategories[cat], t)
		end
	end
end

local tempG = {}
tempG.addTaunt = addTaunt

-- inherit from _G
local meta = {}
meta.__index = _G
meta.__newindex = _G
setmetatable(tempG, meta)

local function loadTaunts(rootFolder)
	local files = file.Find(rootFolder .. "*.lua", "LUA")
	for k, v in pairs(files) do
		local filePath = rootFolder .. v
		AddCSLuaFile(filePath)

		local f = CompileFile(filePath)
		if !f then
			return
		end

		setfenv(f, tempG)
		local b, err = pcall(f)

		local s = SERVER && "Server" || "Client"
		local c = SERVER && 90 || 0
		if !b then
			MsgC(Color(255, 50, 50 + c), s .. " loading taunts failed: " .. filePath .. "\nError: " .. err .. "\n")
		else
			MsgC(Color(50, 255, 50 + c), s .. " loaded taunts file: " .. filePath .. "\n")
		end
	end
end

function GM:LoadTaunts()
	loadTaunts((GM || GAMEMODE).Folder:sub(11) .. "/gamemode/taunts/")
	loadTaunts("ultimateph/taunts/")
end

GM:LoadTaunts()

if SERVER then
-- former sv_taunt.lua
	util.AddNetworkString("open_taunt_menu")
	
	local PlayerMeta = FindMetaTable("Player")
	
	function PlayerMeta:CanTaunt()
		if !self:Alive() then
			return false
		end
	
		if self.TauntEnd && self.TauntEnd > CurTime() then
			return false
		end
	
		return true
	end
	
	function PlayerMeta:EmitTaunt(filename, durationOverride)
		local duration = SoundDuration(filename)
		if filename:match("%.mp3$") then
			duration = durationOverride || 1
		end
	
		local sndName = FilenameToSoundname(filename)
	
		self:EmitSound(sndName)
		self.TauntEnd = CurTime() + duration + 0.1
		self.TauntAmount = (self.TauntAmount || 0) + 1
		self.AutoTauntDeadline = nil
	
		if !self.TauntsUsed then self.TauntsUsed = {} end
		self.TauntsUsed[sndName] = true
	end
	
	local function ForEachTaunt(ply, taunts, func)
		for k, v in pairs(taunts) do
			if !TauntAllowedForPlayer(ply, v) then continue end
	
			if func(k, v) then return end
		end
	end
	
	local function DoTaunt(ply, snd)
		if !IsValid(ply) then return end
		if !ply:CanTaunt() then return end
	
		local ats = AllowedTauntSounds[snd]
		if !ats then return end
	
		local t
		ForEachTaunt(ply, ats, function(k, v)
			t = v
			return true
		end)
	
		if !t then
			return
		end
	
		ply:EmitTaunt(snd, t.soundDurationOverride)
	end
	
	local function DoRandomTaunt(ply)
		if !IsValid(ply) then return end
		if !ply:CanTaunt() then return end
	
		local potential = {}
		ForEachTaunt(ply, Taunts, function(k, v)
			table.insert(potential, v)
		end)
	
		if #potential == 0 then return end
	
		local t = potential[math.random(#potential)]
		local snd = t.sound[math.random(#t.sound)]
	
		ply:EmitTaunt(snd, t.soundDurationOverride)
	end
	
	concommand.Add("ph_taunt", function(ply, com, args, full)
		DoTaunt(ply, args[1] || "")
	end)
	
	concommand.Add("ph_taunt_random", function(ply, com, args, full)
		DoRandomTaunt(ply)
	end)
	
	util.AddNetworkString("ph_set_taunt_menu_phrase")
	function GM:SetTauntMenuPhrase(phrase, ply)
		net.Start("ph_set_taunt_menu_phrase")
		net.WriteString(phrase)
	
		if ply then
			net.Send(ply)
		else
			net.Broadcast()
		end
	end
	
	cvars.AddChangeCallback("ph_taunt_menu_phrase", function(convar_name, value_old, value_new)
		(GM || GAMEMODE):SetTauntMenuPhrase(value_new)
	end)
	
	function GM:AutoTauntCheck()
		if self.GameState != ROUND_SEEK then return end
	
		local propsOnly = self.AutoTauntPropsOnly:GetBool()
		local minDeadline = self.AutoTauntMin:GetInt()
		local maxDeadline = self.AutoTauntMax:GetInt()
		local badMinMax = minDeadline <= 0 || maxDeadline <= 0 || minDeadline > maxDeadline
	
		for i, ply in ipairs(player.GetAll()) do
			if propsOnly && !ply:IsProp() then
				ply.AutoTauntDeadline = nil
				continue
			end
	
			local begin
			if ply.AutoTauntDeadline then
				local secsLeft = ply.AutoTauntDeadline - CurTime()
				if secsLeft > 0 then
					continue
				end
	
				if !ply.TauntEnd || CurTime() > ply.AutoTauntDeadline then
					DoRandomTaunt(ply)
					begin = ply.TauntEnd
				end
			end
			if !begin then begin = CurTime() end
	
			if badMinMax then continue end
	
			local delta = math.random(minDeadline, maxDeadline)
			ply.AutoTauntDeadline = begin + delta
		end
	end
	
	function GM:StartAutoTauntTimer()
		timer.Remove("AutoTauntCheck")
		local start = self.AutoTauntEnabled:GetBool()
	
		if start then
			timer.Create("AutoTauntCheck", 5, 0, function()
				self:AutoTauntCheck()
			end)
		end
	end
	
	cvars.AddChangeCallback("ph_auto_taunt", function(convar_name, value_old, value_new)
		(GM || GAMEMODE):StartAutoTauntTimer()
	end)
end

if CLIENT then
-- former cl_taunt.lua
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
end
