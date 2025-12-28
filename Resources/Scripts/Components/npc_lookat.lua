local RunService = game:GetService("RunService")
local module = {
	
}

local Model:Model = script.Parent

function module:Init()
	print("LookAt component added to "..script.Parent.Name)
	--/// Written by: NyaRemi
	--/// Original Head/Waist Script: [https://www.roblox.com/library/1000161193]
	--/// Description: Head/Waist movement script for NPC
	--/// Updates: 6


	------------------ [[ Cofigurations ]] ------------------

	-- [ BASIC ] --
	local LookAtPlayerRange = 30 -- Distance away that NPC can looks
	local LookAtNonPlayer = true -- Looks at other humanoid that isn't player

	-- [Head, Torso, HumanoidRootPart], "Torso" and "UpperTorso" works with both R6 and R15.
	-- Also make sure to not misspell it.
	local PartToLookAt = "Head" -- What should the npc look at. If player doesn't has the specific part it'll looks for RootPart instead.

	local LookBackOnNil = true -- Should the npc look at back straight when player is out of range.

	local SearchLoc = {workspace} -- Will get player from these locations


	-- [ ADVANCED ] --
--[[
	[Horizontal and Vertical limits for head and body tracking.]
	Setting to 0 negates tracking, setting to 1 is normal tracking, and setting to anything higher than 1 goes past real life head/body rotation capabilities.
--]]
	local HeadHorFactor = 1
	local HeadVertFactor = 1
	local BodyHorFactor = 1
	local BodyVertFactor = 1

	-- Don't set this above 1, it will cause glitchy behaviour.
	local UpdateSpeed = 0.3 -- How fast the body will rotates.
	local UpdateDelay = 0.05 -- How fast the heartbeat will update.

	-------------------------------------------------------
	wait(1)



	--
	local Ang = CFrame.Angles
	local aTan = math.atan
	--
	local Players = game:GetService("Players")
	--------------------------------------------
	local Body = Model

	local Head = Body:WaitForChild("Head")
	local Hum = Body:WaitForChild("Humanoid")
	local Core = Body:WaitForChild("HumanoidRootPart")
	local IsR6 = (Hum.RigType.Value==0)
	local Trso = (IsR6 and Body:WaitForChild("Torso")) or Body:WaitForChild("UpperTorso")
	local Neck = (IsR6 and Trso:WaitForChild("Neck")) or Head:WaitForChild("Neck")	
	local Waist = (not IsR6 and Trso:WaitForChild("Waist"))

	local NeckOrgnC0 = Neck.C0
	local WaistOrgnC0 = (not IsR6 and Waist.C0)

	local LookingAtValue = Instance.new("ObjectValue"); LookingAtValue.Parent = Body; LookingAtValue.Name = "LookingAt"
	--------------------------------------------


	-- Necessery Functions

	local ErrorPart = nil
	local function GetValidPartToLookAt(Char, bodypart)
		local pHum = Char:FindFirstChild("Humanoid")
		if not Char and pHum then return nil end
		local pIsR6 = (pHum.RigType.Value==0)
		if table.find({"Torso", "UpperTorso"}, bodypart) then
			if pIsR6 then bodypart = "Torso" else bodypart = "UpperTorso" end
		end
		local ValidPart = Char:FindFirstChild(bodypart) or Char:FindFirstChild("HumanoidRootPart")
		if ValidPart then return ValidPart else
			if ErrorPart ~= bodypart then
				--warn(Body.Name.." can't find part to look: "..tostring(bodypart))
				ErrorPart = bodypart
			end
			return nil end
	end

	local function getClosestPlayer() -- Get the closest player in the range.
		local closest_player, closest_distance = nil, LookAtPlayerRange
		for i = 1, #SearchLoc do
			for _, player in pairs(SearchLoc[i]:GetChildren()) do
				if player:FindFirstChild("Humanoid") and player ~= Body 
					and (Players:GetPlayerFromCharacter(player) or LookAtNonPlayer) 
					and GetValidPartToLookAt(player, PartToLookAt) then

					local distance = (Core.Position - player.PrimaryPart.Position).Magnitude
					if distance < closest_distance then
						closest_player = player
						closest_distance = distance
					end
				end
			end
		end
		return closest_player
	end

	local function rWait(n)
		n = n or 0.05
		local startTime = os.clock()

		while os.clock() - startTime < n do
			game:GetService("RunService").Heartbeat:Wait()
		end
	end

	local function LookAt(NeckC0, WaistC0)
		if not IsR6 then
			if Neck then Neck.C0 = Neck.C0:lerp(NeckC0, UpdateSpeed/2) end
			if Waist then Waist.C0 = Waist.C0:lerp(WaistC0, UpdateSpeed/2) end
		else
			if Neck then Neck.C0 = Neck.C0:lerp(NeckC0, UpdateSpeed/2) end
		end
	end

	--------------------------------------------

	game:GetService("RunService").Heartbeat:Connect(function()
		rWait(UpdateDelay)
		local TrsoLV = Trso.CFrame.lookVector
		local HdPos = Head.CFrame.p
		local player = getClosestPlayer()
		local LookAtPart
		if Neck or Waist then
			if player then
				local success, err = pcall(function()
					LookAtPart = GetValidPartToLookAt(player, PartToLookAt)
					if LookAtPart then
						local Dist = nil;
						local Diff = nil;
						local is_in_front = Core.CFrame:ToObjectSpace(LookAtPart.CFrame).Z < 0
						if is_in_front then
							if LookingAtValue.Value ~= player then
								LookingAtValue.Value = player
							end

							Dist = (Head.CFrame.p-LookAtPart.CFrame.p).magnitude
							Diff = Head.CFrame.Y-LookAtPart.CFrame.Y

							if not IsR6 then
								LookAt(NeckOrgnC0*Ang(-(aTan(Diff/Dist)*HeadVertFactor), (((HdPos-LookAtPart.CFrame.p).Unit):Cross(TrsoLV)).Y*HeadHorFactor, 0), 
									WaistOrgnC0*Ang(-(aTan(Diff/Dist)*BodyVertFactor), (((HdPos-LookAtPart.CFrame.p).Unit):Cross(TrsoLV)).Y*BodyHorFactor, 0))
							else	
								LookAt(NeckOrgnC0*Ang((aTan(Diff/Dist)*HeadVertFactor), 0, (((HdPos-LookAtPart.CFrame.p).Unit):Cross(TrsoLV)).Y*HeadHorFactor))
							end
						elseif LookBackOnNil then
							LookAt(NeckOrgnC0, WaistOrgnC0)
							if LookingAtValue.Value then
								LookingAtValue.Value = nil
							end
						end
					end
				end)
			elseif LookBackOnNil then
				LookAt(NeckOrgnC0, WaistOrgnC0)
				if LookingAtValue.Value then
					LookingAtValue.Value = nil
				end
			end
		end
	end)
end

return module
