local module = {}

local blource = require(game:GetService("ReplicatedStorage").Resources.Blource_Main)

function module:Command(args:{string})
	local WeaponModule = require(blource.ENGINE_VAR.Root.Scripts.Lib.weapon_lib)
	if tonumber(args[1]) == 101 then
		WeaponModule:GiveWeapon("weapon_m1911a1")
		WeaponModule:GiveWeapon("weapon_revolver")
		WeaponModule:GiveWeapon("weapon_hfsword")
		WeaponModule:GiveWeapon("weapon_shotgun")
		WeaponModule:GiveWeapon("weapon_supershotgun")
		WeaponModule:GiveWeapon("weapon_turret")
		WeaponModule:GiveWeapon("weapon_nitrogun")
	end
end

return module
