--!nonstrict
--!native
--!optimize 2

--[[
	###########################
	
	@Authors: @WATDAHECKLOL32
	@File:    NetworkService.luau

	@Date:    4/25/25
	@Bio:     Loom's network manager
	
	@Verison: V0
	@Release: Public Alpha Build 0.0.0

	###########################
]]

--[=[
	@class NetworkService
	Loom's Network Service.
]=]

local Framework = require(script.Parent.Parent);
local Remote = script.Parent.Parent.Assets.NetEvent;

local RunService = game:GetService("RunService");
local Client: boolean = RunService:IsClient();

local Players = game:GetService("Players");
local NetEvents = {};

local Debug = false;

if (Client) then
	Remote.OnClientEvent:Connect(function(Action: string, ...)
		if not (Action or NetEvents[Action] or ...) then
			warn("[⚠️] Remote is missing a valid action [⚠️]");
			return;
		end;
		
		NetEvents[Action](...);
	end);	
else
	Remote.OnServerEvent:Connect(function(Player: Player, Action: string, ...)
		if not (Action or NetEvents[Action] or ...) then
			warn("[⚠️] Remote is missing a valid action [⚠️]", Player);
			Player:Kick("[⚠️] NetworkService failed to connect to the server [⚠️]");
			return;
		end;
		
		NetEvents[Action](Player, ...);
	end);
end;

--[=[
	@prop      RegisterService  userdata
	@within    NetworkService
	@readonly
	Registers the LOOM NetworkService
]=]
return Framework:RegisterService("NetworkService", table.freeze({
	["FireServer"] = function(Action: string, ...) : ()
		assert(Client, "[N] Attempt to use a client only function [N]");
		if (Debug) then
			warn("[F] FireServer invoked", Action, ...);
		end;
		Remote:FireServer(Action, ...);
	end,

	["BindEvent"] = function(Action: string, Closure: any) : ()
		NetEvents[Action] = Closure;
	end,
	
	["FireAllClientsWithException"] = function(Action: string, Exception: Player, ...) : ()
		assert(not Client, "[N] Attempt to use a server only function [N]");

		if (Debug) then
			warn("[F] FireAllClientsWithException invoked", Exception, Action, ...);
		end;
		
		for _,Player: Player in Players:GetPlayers() do
			if Player ~= Exception then
				Remote:FireClient(Player, Action, ...)
			end;
		end;
	end,

	["FireClient"] = function(ToFire: Player, Action: string, ...) : ()
		assert(not Client, "[N] Attempt to use a server only function [N]");
		if (Debug) then
			warn("[F] FireAllClients invoked", ToFire, Action, ...);
		end;
		Remote:FireClient(ToFire, Action, ...);
	end,
	
	["FireAllClients"] = function(Action: string,  ...) : ()
		assert(not Client, "[N] Attempt to use a server only function [N]");
		Remote:FireAllClients(Action, ...);
	end,
	
}), true, "userdata", "The metatable is locked");