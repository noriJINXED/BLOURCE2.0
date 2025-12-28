local module = {
	Died = false;
	Target = nil;
	SafeZoneLowerThreshold = 10;
	SafeZoneHigherThreshold = 40;
	CurrentNode = nil;
	IsMoving = false;
	NearbyNodes = {};
	ShootingFrequency = 0.2;
	Inventory = {};
}

function module:Init()
	--dummy function, do not use
end

return module