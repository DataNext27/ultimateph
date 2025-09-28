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
