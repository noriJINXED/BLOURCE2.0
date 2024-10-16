local module = {
    CLIENT_VAR = {
        PlayerSpeed = 35;
        JumpHeight = 15;
        MaxHealth = 100;
        CurrentMap = "";
        CurrentWeapon = "";
        CurrentSaveFile = "";
        CurrentBindingProfiles = "Default";
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
                ["A"] = "quickchange"
            };
            Keyboard = {
                [Enum.KeyCode.E] = "interact";
            };
            Controller = {
                [Enum.KeyCode.X] = "interact";
            };
        };
        CustomValues = { --Unqiue to each game. In this case, values are adjusted for AP400 PART 1 
            MaxStamina = 3;
            Stamina = 3
        };
    };
    SERVER_VAR = {
        MaxMultiplayerHealth = 100;
        JumpHeight = 5;
        PlayerSpeed = 35;
        CurrentMap = ""
    };
    ENGINE_VAR = {
        TimeScale = 1;
        Gravity = 135;
        LVL_LOADINGCONFIG = {
            NO_TEX = {
                "trigger";
                "dev_collider";
                "ai_node";
            }
        };
        --Baked lists are permanent during gameplay: they are meant to avoid errors when you forget to move something back and forth from its directory and Workspace.
        BakedWeaponList = {};
        WeaponList = {};
        BakedMapList = {};
    };
    BLOURCE_INPUT = {
        Ver = "0.0.0";
        TranslationActive = true;
        TranslationTable = {
            ["ButtonX"] = "E";
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

--##########################################################################
--[[BLOURCE INPUT!!]]

--[[
Translates input from their oririginal structure to a format readable by BLOURCE 2's input functions.
]]

function module.BLOURCE_INPUT:InputTranslation(input:InputObject, processed:boolean)
    local KeyCode = input.KeyCode
    local type = input.UserInputType
    local tree = {
        [Enum.UserInputType.Keyboard] = function() 
            return KeyCode.Name
        end;
        [Enum.UserInputType.Gamepad1] = function()
            --If input translation is active then, BLOURCE INPUT should translate an input (like Button_X for example)
            if module.BLOURCE_INPUT.TranslationActive then
                return module.BLOURCE_INPUT.TranslationTable[KeyCode.Name]
            else
                return KeyCode.Name 
            end
        end;
        [Enum.UserInputType.MouseButton1] = function()
            return "MouseButton1"
        end;
        [Enum.UserInputType.MouseButton2] = function()
            return "MouseButton2"
        end;
        [Enum.UserInputType.MouseButton3] = function()
            return "MouseButton3"
        end;
    }
    if processed then
        tree[type]()
    end
end

--##########################################################################
--[[FUNCS]]

--##########################################################################
--[[ENGINE FUNCS]]

function module:Input(InputName, KeyCode)
    --runs functions with given keycode (so that an input script can know exactly which key you have pressed)
    
end

--[[
The limited function for map loading: very limited, no save loading or anything, meant to test the most basic form of maps and scripts individually
]]

function module:DEVMAP(mapName:string,gameModeOverride:string)
    local OG:Folder = Root.Map:FindFirstChild(mapName)
    if OG then
        --Cloning map
        local Map = OG:Clone()
        Map.Parent = workspace
        Map.Name = "Map"
    else
        warn("Map "..mapName.." doesn't exist")
    end
end

--[[
Pretty self-explanatory lol
]]

function module:CreateGUI(guiName:string)
    local GUI:ScreenGui = Root.Resources.GUI:FindFirstChild(guiName)
    GUI.Parent = LocalPlayer.PlayerGui
    if GUI:FindFirstChild("LOCAL") then
        local localscript = GUI:FindFirstChild("LOCAL")
        if localscript:IsA("LocalScript") then
            localscript.Enabled = true
        end
    end
end

function module:Startup(args)
    --anchors players to ensure that it doesn't fall to death lol-
    LocalPlayer.Character.PrimaryPart.Anchored = true
    --input thingy
    InputService.InputBegan:Connect(function(Input: InputObject, GameProcessed: boolean)
        if GameProcessed then
            local keycode = Input.KeyCode
            local id = table.find(module.CLIENT_VAR.Profiles[module.CLIENT_VAR.CurrentBindingProfiles], module.BLOURCE_INPUT:InputTranslation(Input, GameProcessed))
            local inputscriptname = module.CLIENT_VAR.Profiles[module.CLIENT_VAR.CurrentBindingProfiles][id]
            local inmodule:ModuleScript = Root.Resources.Scripts.Inputs:FindFirstChild(inputscriptname)
            if inmodule then
                require(inmodule):OnKeyPressed(keycode)
            end
        end
    end)
    InputService.InputEnded:Connect(function(Input: InputObject, GameProcessed: boolean)
        if GameProcessed then
            local keycode = Input.KeyCode
            local id = table.find(module.CLIENT_VAR.Profiles[module.CLIENT_VAR.CurrentBindingProfiles], module.BLOURCE_INPUT:InputTranslation(Input, GameProcessed))
            local inputscriptname = module.CLIENT_VAR.Profiles[module.CLIENT_VAR.CurrentBindingProfiles][id]
            local inmodule:ModuleScript = Root.Resources.Scripts.Inputs:FindFirstChild(inputscriptname)
            if inmodule then
                require(inmodule):OnKeyReleased(keycode)
            end
        end
    end)
end

--[[GAME FUNCS]]

--[[
    Bind related keys to their designated actions
    
]]

function module:BindKeys(KeyTable:{Enum.KeyCode})
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

function module:PlaySound(Name:string,Volume:number,RollOffDistance:number,IsGUI:boolean,OriginPart:BasePart)
    local Sound:Sound? = Root.Sounds:FindFirstChild(Name)
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
                    local S = Sound:Clone()
                    S.Parent = OriginPart
                    S:Play()
                    S.RollOffMaxDistance = RollOffDistance
                    Debris:AddItem(S, S.TimeLength+5)
                else
                    warn("Sound "..Name.." was playable, but pointed OriginPart value is not valid.")
                end
            end
        end
    end
end

--[[
    Damage player by a certain amount
]]

function module:DamagePlayer(amount:number)
    local rEvent:RemoteEvent = Root.Resources.dmgPlr
    rEvent:FireServer(amount)
end

return module