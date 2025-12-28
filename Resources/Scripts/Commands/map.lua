local module = {}

local blource = require(game:GetService("ReplicatedStorage").Resources.Blource_Main)

function module:Command(args:{string})
	local map = args[1]
	warn("Request to load map: "..map)
	if map == nil or map == "" then
		warn("Couldn't load map: empty string provided")
	elseif blource.ENGINE_VAR.Root.Maps:FindFirstChild(map) then
		blource:LoadMap(map)
	else
		warn("Couldn't load map: "..map.." is not a valid map name. To get a list of maps, please run 'getmaplist'")
	end
end

return module
