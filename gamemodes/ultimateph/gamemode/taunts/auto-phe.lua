local hfiles = file.Find("sound/taunts/hunters/*", "THIRDPARTY")
local pfiles = file.Find("sound/taunts/props/*", "THIRDPARTY")

for i=1, #hfiles do
	addTaunt(hfiles[i], "taunts/hunters/" .. hfiles[i], "hunters", nil, {"Auto Hunters"})
end

for i=1, #pfiles do
	addTaunt(pfiles[i], "taunts/hunters/" .. pfiles[i], "props", nil, {"Auto Props"})
end

local files, paths = file.Find("sound/taunts/*", "THIRDPARTY")

for i=1, #paths do
	local ahfiles = file.Find("sound/taunts/" .. paths[1] .. "/" .. "hunters" .. "/*", "THIRDPARTY")
	local apfiles = file.Find("sound/taunts/" .. paths[1] .. "/" .. "props" .. "/*", "THIRDPARTY")
	
	for i=1, #ahfiles do
		addTaunt(ahfiles[i], "taunts/" .. paths[1] .. "/" .. "hunters" .. "/" .. ahfiles[i], "hunters", nil, {"Auto Hunters"})
	end

	for i=1, #apfiles do
		addTaunt(apfiles[i], "taunts/" .. paths[1] .. "/" .. "props" .. "/" .. apfiles[i], "props", nil, {"Auto Props"})
	end
end
