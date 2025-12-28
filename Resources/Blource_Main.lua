local module = {
	CLIENT_VAR = {
		Player = game.Players.LocalPlayer;
		PlayerSpeed = 35;
		JumpHeight = 15;
		MaxHealth = 100;
		CurrentMap = "";
		CurrentWeapon = "weapon_base";
		CurrentSaveFile = "default";
		CurrentBindingProfiles = "Default";
		Gamemode = "Default";
		Profiles = {
			Default = {
				["E"] = "interact";
				["LeftShift"] = "dash";
				["LeftControl"] = "slam";
				["R"] = "reload";
				["One"] = "inventory";
				["Two"] = "inventory";
				["Three"] = "inventory";
				["Four"] = "inventory";
				["Five"] = "inventory";
				["Six"] = "inventory";
				["Q"] = "quickchange";
				["W"] = "movement";
				["A"] = "movement";
				["S"] = "movement";
				["D"] = "movement";
				["Tab"] = "pause";
				["MouseButton1"] = "shoot";
			};
			Keyboard = {
				["E"] = "interact";
			};
			Controller = {
				["X"] = "interact";
			};
		};
		ValidBinds = {
			"devconsole";
			"pause";
			"movement";
		};
		CustomValues = { --Unqiue to each game. In this case, values are adjusted for Project Bad Apple's AP400
			MaxStamina = 3;
			Stamina = 3;
			WallRunUnlocked = true;
		};
		Language = "en";
		IsLoaded = false;
	};
	SERVER_VAR = {
		MaxMultiplayerHealth = 100;
		JumpHeight = 5;
		PlayerSpeed = 35;
		CurrentMap = ""
	};
	ENGINE_VAR = {
		Root = game:GetService("ReplicatedStorage").Resources;
		TimeScale = 1;
		Gravity = 135;
		LVL_LOADINGCONFIG = {
			NO_TEX = {
				"trigger";
				"dev_collider";
				"ai_node";
			}
		};
		DefaultValidBinds = {
			"devconsole";
			"pause";
			"movement";
		};
		--Baked lists are permanent during gameplay: they are meant to avoid errors when you forget to move something back and forth from its directory and Workspace.
		BakedWeaponList = {};
		WeaponList = {};
		BakedMapList = {};
	};
	BLOURCE_INPUT = {
		Ver = "0.0.1";
		TranslationActive = true;
		TranslationTable = {
			["ButtonL3"] = "LeftShift";
			["ButtonB"] = "LeftControl";
			["ButtonX"] = "E";
			["ButtonY"] = "R";
			["DPadUp"] = "One";
			["DPadLeft"] = "Two";
			["DPadDown"] = "Three";
			["DPadRight"] = "Four";
			["ButtonR2"] = "MouseButton1";
			["ButtonL2"] = "MouseButton2";
		}
	};
}

--##########################################################################
--[[VARIABLES]]

local LocalPlayer = game:GetService("Players").LocalPlayer
local Root = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local InputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local config = require(script.config)

--##########################################################################
--[[BLOURCE INPUT!!]]

--[[
Translates input from their oririginal structure to a format readable by BLOURCE 2's input functions.
]]

function module.BLOURCE_INPUT:InputTranslation(input:InputObject, processed:boolean)
	local KeyCode = input.KeyCode
	local inputtype = input.UserInputType
	local TranslatedInput = nil
	if KeyCode then
		TranslatedInput = module.BLOURCE_INPUT.TranslationTable[KeyCode.Name]
	else
		TranslatedInput = module.BLOURCE_INPUT.TranslationTable[inputtype.Name]
	end
	--warn("BLOURCE INPUT WARNING: Translated input="..tostring(TranslatedInput))
	if TranslatedInput then
		--warn("BLOURCE INPUT WARNING: Passing translated input of value "..tostring(TranslatedInput))
		return TranslatedInput
	else
		return nil
	end
end

--##########################################################################
--[[FUNCS]]

local function PlayerStats()
	local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	hum.UseJumpPower = false
	hum.WalkSpeed = module.CLIENT_VAR.PlayerSpeed
	hum.JumpHeight = module.CLIENT_VAR.JumpHeight
	local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
end

--##########################################################################
--[[ENGINE FUNCS]]

function module:Disconnect(noMap:boolean)
	local weapon = require(module.ENGINE_VAR.Root.Scripts.Lib.weapon_lib)
	local Map = workspace:FindFirstChild("Map")
	if Map then
		local levelscript:ModuleScript = Map:FindFirstChild("levelscript")
		for i, v in pairs(Map.Entities:GetChildren()) do
			for e, r in pairs(Root.Resources.Entities:GetChildren()) do
				if string.match(v.Name, r.Name) then
					if require(r).OnUnload then
						task.spawn(require(r).OnUnload,v)
					end
				end
			end
		end
		local modlevel = require(levelscript)
		task.spawn(modlevel.OnLevelUnload)
		local GamemodeScript = require(Root.Resources.Scripts.Gamemode:FindFirstChild(modlevel.Gamemode))
		GamemodeScript:OnLevelUnload()
		
		weapon:ClearWeapons()
		if levelscript then
			task.spawn(require(levelscript).OnLevelUnload)
		end
		Map:Destroy()
	end
	if noMap == true then
		weapon:ClearWeapons()
		module.CLIENT_VAR.IsLoaded = false
		module.CLIENT_VAR.ValidBinds = module.ENGINE_VAR.DefaultValidBinds
		LocalPlayer.Character.PrimaryPart.Anchored = true
		Root.Resources.Events.disconnect:Fire()
	end
end

function module:CreateNewSave(ShouldLoad:boolean)
	local defaultsave = Root.Resources.Save.default
	local newsave = defaultsave:Clone()
	newsave.Name = os.time()
	newsave.Parent = Root.Resources.Save
	if ShouldLoad == true then
		module.CLIENT_VAR.CurrentSaveFile = newsave.Name
	end
end

function module:LoadAllSavesFromDataStore(Save:{any})
	for i, v in pairs(Save.Saves) do
		local savemodule = Root.Resources.Save.default:Clone()
		savemodule.Name = i
		savemodule.Parent = Root.Resources.Save
		local save = require(savemodule)
		for e, r in pairs(save) do
			save[e] = v[e]
		end
	end
end

function module:UpdateDataStore()
	local Save = {
		CurrentSaveFile = module.CLIENT_VAR.CurrentSaveFile;
		Saves = {}
	}
	local function deepCopy(t)
		local copy = {}
		for k, v in pairs(t) do
			if type(v) == "table" then
				copy[k] = deepCopy(v)
			else
				copy[k] = v
			end
		end
		return copy
	end
	for i, v in pairs(Root.Resources.Save:GetChildren()) do
		local savemodule = require(v)
		Save.Saves[v.Name] = {}
		Save.Saves[v.Name] = deepCopy(savemodule)
	end
	print(Save)
	Root.Resources.Events.saveData:FireServer(Save)
end

function module:Input(InputName, KeyCode)
	--runs functions with given keycode (so that an input script can know exactly which key you have pressed)
	
end

--[[
Pretty self-explanatory lol
]]

function module:CreateGUI(guiName:string)
	local GUI:ScreenGui = Root.Resources.GUI:FindFirstChild(guiName):Clone()
	if GUI then
		GUI.Parent = LocalPlayer.PlayerGui
		if GUI:FindFirstChild("LOCAL") then
			local localscript = GUI:FindFirstChild("LOCAL")
			if localscript:IsA("LocalScript") then
				localscript.Enabled = true
			end
		end
		return GUI
	else
		warn("not valid gui, try again")
		return nil
	end
end

--[[
The limited function for map loading: very limited, no save loading or anything, meant to test the most basic form of maps and scripts individually
]]

function module:DEVMAP(mapName:string,gameModeOverride:string)
	local OG:Folder = Root.Resources.Maps:FindFirstChild(mapName)
	if OG then
		--Cloning map
		local prevMap = workspace:FindFirstChild("Map")
		if prevMap then
			module:Disconnect(false)
		end
		local loading = module:CreateGUI("LoadingScreen")
		local Map = OG:Clone()
		Map.Parent = workspace
		Map.Name = "Map"
		for i, v in pairs(Map.Static:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Anchored = true
			end
		end
		Root.Resources.Events.mapchange:Fire()
		print("Loading map "..mapName)
		ContentProvider:PreloadAsync(Map:GetDescendants())
		repeat
			task.wait()
		until ContentProvider.RequestQueueSize <= 2
		local levelscript:ModuleScript = Map:FindFirstChild("levelscript")
		for i, v in pairs(Map.Entities:GetChildren()) do
			for e, r in pairs(Root.Resources.Entities:GetChildren()) do
				if string.match(v.Name, r.Name) then
					if require(r).OnLoad then
						task.spawn(require(r).OnLoad, v, v, v)
					end
				end
			end
		end
		for i, v in pairs(Map.Static:GetChildren()) do
			for t, y in pairs(module.ENGINE_VAR.LVL_LOADINGCONFIG.NO_TEX) do
				if y == v.Name:match(y) then
					if v:IsA("BasePart") then
						v.Transparency = 1
					end
					for e, r in pairs(v:GetChildren()) do
						if r:IsA("Texture") then
							r:Destroy()
						end
					end
				end
			end
		end
		if levelscript then
			local modlevel = require(levelscript)
			task.spawn(modlevel.OnLevelLoad)
			local GamemodeScript = require(Root.Resources.Scripts.Gamemode:FindFirstChild(modlevel.Gamemode))
			local NewBindList = GamemodeScript.ValidInputs
			print(NewBindList)
			for i, v in pairs(module.ENGINE_VAR.DefaultValidBinds) do
				table.insert(NewBindList, v)
			end
			module.CLIENT_VAR.ValidBinds = NewBindList
			print(NewBindList)
			print(module.CLIENT_VAR.ValidBinds)
			module.CLIENT_VAR.Gamemode = modlevel.Gamemode
			task.spawn(GamemodeScript.OnLevelLoad)
		end
		config:levelconfig()
		loading:Destroy()
		module.CLIENT_VAR.IsLoaded = true
		module.CLIENT_VAR.CurrentMap = mapName
		LocalPlayer.Character.PrimaryPart.Anchored = false
	else
		warn("Map "..mapName.." doesn't exist")
	end
end

local function map()
	local OG:Folder = Root.Resources.Maps:FindFirstChild(module.CLIENT_VAR.CurrentMap)
	if OG then
		local prevMap = workspace:FindFirstChild("Map")
		if prevMap then
			module:Disconnect(false)
		end
		local loading = module:CreateGUI("LoadingScreen")
		local Map = OG:Clone()
		Map.Parent = workspace
		Map.Name = "Map"
		for i, v in pairs(Map.Static:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Anchored = true
			end
		end
		Root.Resources.Events.mapchange:Fire()
		print("Loading map "..module.CLIENT_VAR.CurrentMap)
		ContentProvider:PreloadAsync(Map:GetDescendants())
		repeat
			task.wait()
		until ContentProvider.RequestQueueSize <= 2
		local levelscript:ModuleScript = Map:FindFirstChild("levelscript")
		for i, v in pairs(Map.Entities:GetChildren()) do
			for e, r in pairs(Root.Resources.Entities:GetChildren()) do
				if string.match(v.Name, r.Name) then
					if require(r).OnLoad then
						task.spawn(require(r).OnLoad, v, v, v)
					end
				end
			end
		end
		for i, v in pairs(Map.Static:GetChildren()) do
			for t, y in pairs(module.ENGINE_VAR.LVL_LOADINGCONFIG.NO_TEX) do
				if y == v.Name:match(y) then
					if v:IsA("BasePart") then
						v.Transparency = 1
					end
					for e, r in pairs(v:GetChildren()) do
						if r:IsA("Texture") then
							r:Destroy()
						end
					end
				end
			end
		end
		if levelscript then
			local modlevel = require(levelscript)
			task.spawn(modlevel.OnLevelLoad)
			local GamemodeScript = require(Root.Resources.Scripts.Gamemode:FindFirstChild(modlevel.Gamemode))
			local NewBindList = GamemodeScript.ValidInputs
			print(NewBindList)
			for i, v in pairs(module.ENGINE_VAR.DefaultValidBinds) do
				table.insert(NewBindList, v)
			end
			module.CLIENT_VAR.ValidBinds = NewBindList
			print(NewBindList)
			print(module.CLIENT_VAR.ValidBinds)
			module.CLIENT_VAR.Gamemode = modlevel.Gamemode
			task.spawn(GamemodeScript.OnLevelLoad)
		end
		config:levelconfig()
		loading:Destroy()
		module.CLIENT_VAR.IsLoaded = true
		LocalPlayer.Character.PrimaryPart.Anchored = false
	end
end

function module:LoadMap(MapName:string)
	if module.ENGINE_VAR.Root.Maps:FindFirstChild(MapName) then
		module.CLIENT_VAR.CurrentMap = MapName
		task.spawn(map)
	else
		warn("BLOURCE Error: attempted to load a non-existing map")
	end
end

function module:RunCommand(fullcommand:string?,shouldPrint)
	--separate full commands to get command name
	local splitcommand = string.split(fullcommand, " ")
	print(splitcommand)
	local command = splitcommand[1]
	table.remove(splitcommand,1)
	if shouldPrint == true or shouldPrint == nil then
		print(command)
	end
	print(splitcommand)
	if module.ENGINE_VAR.Root.Scripts.Commands:FindFirstChild(command) then
		require(module.ENGINE_VAR.Root.Scripts.Commands:FindFirstChild(command)):Command(splitcommand)
	else
		warn("Command "..command.." is not a valid command.")
	end
end

function module:StartScript(ScriptName:string)
	local og:ModuleScript = Root.Resources.Scripts:FindFirstChild(ScriptName)
	if og then
		local Map = workspace:FindFirstChild("Map")
		if Map then
			local ScriptFolder = Map:FindFirstChild("Script")
			if ScriptFolder then
				
			else
				ScriptFolder = Instance.new("Folder")
				ScriptFolder.Name = "Script"
				ScriptFolder.Parent = Map
			end
			local newscript = og:Clone()
			newscript.Parent = ScriptFolder
			task.spawn(require(newscript).Initiate)
		else
			warn("Unable to start new level scripts if no maps are loaded in the first place.")
		end
	else
		warn("Script "..ScriptName.." doesn't exist")
	end
end

function module:addComponentToEntity(objectScript:string, selfRef:ModuleScript)
	local comp:ModuleScript = Root.Resources.Scripts.Components:FindFirstChild(objectScript)
	if comp then
		local comp = comp:Clone()
		comp.Parent = selfRef
		local m = require(comp)
		if m.Init then
			task.spawn(m.Init)
		end
		return comp
	else
		warn("Invalid component requested. Script name: "..objectScript.."; asked from "..selfRef.Name)
		return nil
	end
end

function module:Startup(args)
	--anchors players to ensure that it doesn't fall to death lol-
	if not LocalPlayer.Character then
		repeat 
			wait()
		until LocalPlayer.Character
	end
	LocalPlayer.Character.PrimaryPart.Anchored = true
	workspace.Gravity = module.ENGINE_VAR.Gravity
	local function PlayerStats()
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		hum.UseJumpPower = false
		hum.WalkSpeed = module.CLIENT_VAR.PlayerSpeed
		hum.JumpHeight = module.CLIENT_VAR.JumpHeight
		local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	end
	PlayerStats()
	LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
		LocalPlayer.CharacterAdded:Wait()
		if module.CLIENT_VAR.IsLoaded == true then
			module:DEVMAP(module.CLIENT_VAR.CurrentMap)
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function()
		PlayerStats()
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
			LocalPlayer.CharacterAdded:Wait()
			if module.CLIENT_VAR.IsLoaded == true then
				module:DEVMAP(module.CLIENT_VAR.CurrentMap)
			end
		end)
	end)
	--[[This part was copied directly from the Roblox devforum in order to setup the new audio API. global sounds will be used using traditional
	sound instances, and world sounds will be played through the API]]
	
	-- Get the camera currently being used by the Workspace service
	local camera = workspace.CurrentCamera

	-- We add the necessary audio objects inside the Camera
	local listener = Instance.new("AudioListener", camera)
	local audioOut = Instance.new("AudioDeviceOutput", listener)
	audioOut.Player = LocalPlayer
	-- We make a new wire inside the listener and connect the two audio objects together
	local wire = Instance.new("Wire", listener)

	wire.SourceInstance = listener
	wire.TargetInstance = audioOut
	
	--input thingy
	InputService.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed == false then
			local keycode = Input.KeyCode
			local id = module.CLIENT_VAR.Profiles.Default[keycode.Name] or module.CLIENT_VAR.Profiles.Default[Input.UserInputType.Name]
			if id then
				--print(id.." pressed")
				local inmodule = Root.Resources.Scripts.Inputs:FindFirstChild(id)
				if inmodule and table.find(module.CLIENT_VAR.ValidBinds, id) then
					require(inmodule):OnKeyPressed(keycode)
				end
			else
				local TranslatedInput = module.BLOURCE_INPUT:InputTranslation(Input, GameProcessed)
				if TranslatedInput then
					local id = module.CLIENT_VAR.Profiles.Default[TranslatedInput]
					--warn("BLOURCE INPUT WARNING: Translated input "..TranslatedInput.." from keycode "..keycode.Name.." returned input id "..tostring(id))
					if id then
						local inmodule = Root.Resources.Scripts.Inputs:FindFirstChild(id)
						if inmodule and table.find(module.CLIENT_VAR.ValidBinds, id) then
							require(inmodule):OnKeyPressed(Enum.KeyCode:FromName(TranslatedInput))
						end
				--[[else
					warn("BLOURCE INPUT WARNING: Input translation not found.")]]
					end
				end
			end
		end
		
	end)
	InputService.InputEnded:Connect(function(Input: InputObject, GameProcessed: boolean)
		if GameProcessed == false then
			local keycode = Input.KeyCode
			local id = module.CLIENT_VAR.Profiles.Default[keycode.Name] or module.CLIENT_VAR.Profiles.Default[Input.UserInputType.Name]
			if id then
				--print(id.." released")
				local inmodule = Root.Resources.Scripts.Inputs:FindFirstChild(id)
				if inmodule and table.find(module.CLIENT_VAR.ValidBinds, id) then
					require(inmodule):OnKeyReleased(keycode)
				end
			else
				local TranslatedInput = module.BLOURCE_INPUT:InputTranslation(Input, GameProcessed)
				if TranslatedInput then
					local id = module.CLIENT_VAR.Profiles.Default[TranslatedInput]
					--warn("BLOURCE INPUT WARNING: Translated input "..TranslatedInput.." from keycode "..keycode.Name.." returned input id "..tostring(id))
					if id then
						local inmodule = Root.Resources.Scripts.Inputs:FindFirstChild(id)
						if inmodule and table.find(module.CLIENT_VAR.ValidBinds, id) then
							require(inmodule):OnKeyReleased(Enum.KeyCode:FromName(TranslatedInput))
						end
					end
				end
			end
		end
	end)
	
	--save data
	
	Root.Resources.Events.requestSave:FireServer()
	local Save = Root.Resources.Events.requestSave.OnClientEvent:Wait()
	
	if Save == nil then --new player
		Save = {
			CurrentSaveFile = "";
			Saves = {}
		}
		Root.Resources.Events.saveData:FireServer(Save)
		print("created new save")
	end
	
	module:LoadAllSavesFromDataStore(Save)
	
	print(Save)
	
	Root.Resources.Events.requestPreferences:FireServer()
	local Preferences = Root.Resources.Events.requestPreferences.OnClientEvent:Wait()
	
	print(Preferences)
	
	config:startupconfig()
end

--[[GAME FUNCS]]

--[[
    Bind related keys to their designated actions
    
]]

function module:BindKeyToFunc(KeyTable:{Enum.KeyCode})
    --[[bind commands to keys specified
    example table:
    {
        [Enum.KeyCode.E] = "interact"
    }]]
end

--[[
    Yield thread until correct input is given
]]

function module:WaitForInput(keycode:Enum.KeyCode)
	local Success = false
	repeat
		local input = InputService.InputBegan:Wait()
		if input.KeyCode == keycode then
			Success = true
			break
		end
	until Success == true
end

--[[
    Plays sounds at designed point, or at GUI level (SoundService).
    
]]



function module:PlaySound(Name:string,Volume:number,RollOffDistance:number,IsGUI:boolean,NewAPI:boolean,OriginPart:BasePart)
	local Sound:Sound? = Root.Resources.Sounds:FindFirstChild(Name)
	if Sound then
		if IsGUI then
			if Sound:IsA("Sound") then
				local S = Sound:Clone()
				S.Parent = game:GetService("SoundService")
				S:Play()
				Debris:AddItem(S, S.TimeLength+5)
			end
		else
			if Sound:IsA("Sound") then
				if OriginPart then
					if NewAPI then
						local function connectDevices(source, target)
							local wire = Instance.new("Wire")
							wire.Parent = source
							wire.SourceInstance = source
							wire.TargetInstance = target
						end
						if OriginPart:FindFirstChildOfClass("AudioPlayer") then
							print("audio player already present, assuming emitter is too")
							local audioPlayer = OriginPart:FindFirstChildOfClass("AudioPlayer")
							audioPlayer.Asset = Sound.SoundId
							audioPlayer:Play()
						else
							local audioPlayer = Instance.new("AudioPlayer", OriginPart)
							audioPlayer.Asset = Sound.SoundId
							local emitter = Instance.new("AudioEmitter", OriginPart)
							connectDevices(audioPlayer, emitter)
							audioPlayer:Play()
						end
					else
						local S = Sound:Clone()
						S.Parent = OriginPart
						S:Play()
						S.RollOffMaxDistance = RollOffDistance
						Debris:AddItem(S, S.TimeLength+5)
					end
				else
					warn("Sound "..Name.." was playable, but pointed OriginPart value is not valid.")
				end
			end
		end
	end
end

function module:GetSound(SoundName)
	local Sound = Root.Resources.Sounds:FindFirstChild(SoundName)
	if Sound then
		return Sound	
	else
		return nil
	end
end

--[[
    Damage player by a certain amount
]]

function module:DamagePlayer(amount:number)
	local rEvent:RemoteEvent = Root.Resources.Events.dmgPlr
	rEvent:FireServer(amount)
end

--directly ported from Version 0.9 for compatibility with old modules

function module:GetSaveDataFromString(String:string?)
	local SaveFile = game:GetService("ReplicatedStorage").Resources.Save:FindFirstChild(String)
	if SaveFile then
		return require(SaveFile)
	end
end

--[[LEGACY FUNCTIONS OF VERSION 0.9!!! PLEASE USE THE NEWER MODULES IN RESOURCES.SCRIPTS.LIB!!!]]

function module:AddNotice(text,lifetime)
	warn("Deprecated function. Please use the newer Subtitle module located in Resources.Scripts.Lib")
end

function module:AddSubtitle(text, lifetime, colorid)
	warn("Deprecated function. Please use the newer Subtitle module located in Resources.Scripts.Lib")
end

function module:CreateHitbox()
	warn("Deprecated function. Please use the newer Damage module located in Resources.Scripts.Lib")
end

function module:ShootBullet()
	warn("Deprecated function. Please use the newer Damage module located in Resources.Scripts.Lib")
end

return module
