--!nonstrict
--!native
--!optimize 2

--!nolint DeprecatedApi
--[[
	###########################
	
	@Authors: @WATDAHECKLOL32
	@File: 	  Loom.luau

	@Date:    4/25/25
	@Bio:     A sweet roblox framework with a built in service wrapper, network manager, service penteration testing functions and more!
	
	@Verison: NOT COMPLETE: V0
	@Release: ALPHA BUILD (NOT COMPLETE) V0

	###########################
]]

--[=[
	@class LOOM
	The core for the LOOM framework
]=]

local Framework = {};
local Services = {};

local getnamecallmethod = require(script.Resources.getNamecallMethod);
local wait: (number?) -> number = task.wait;

local Ran: boolean = false;
local Players = game:GetService("Players");

local Player = Players.LocalPlayer;
local RunService = game:GetService("RunService");

local Client: boolean = RunService:IsClient();
local ServerScriptService = game:GetService("ServerScriptService");

local RawMT = {};

--[=[
	@within LOOM

	@tag Modules
	@param self any -- The LOOM userdata.
	@param Name string -- The moudle to get
	@return any? -- The requried module.
	@yields
]=]
local function GetModule(self: any, Name: string) : any?
	assert(self, "Expected ':' not '.' calling member function GetModule");
	
	if (Client and Player and Player.PlayerScripts and Player.PlayerScripts:FindFirstChildWhichIsA("Actor")) then
		for _,Module in Player.PlayerScripts:FindFirstChildWhichIsA("Actor"):GetDescendants() do
			if (Module and Module:IsA("ModuleScript") and tostring(Module) == Name) then
				return require(Module);
			end;
		end;
	elseif (not Client) then
		for _,Module in ServerScriptService:FindFirstChildWhichIsA("Actor") do
			if (Module and Module:IsA("ModuleScript") and tostring(Module) == Name) then
				return require(Module);
			end;
		end;
	end;
	
	for _,Module in script.Modules:GetDescendants() do
		if (Module and Module:IsA("ModuleScript") and tostring(Module) == Name) then
			return require(Module);
		end;
	end;
	
	warn("Requested module not found", Name);
	return nil;
end;

--[=[
	@within LOOM

	Gets and returns the requried registered LOOM service.
	
	@tag Services
	@param self any -- The LOOM userdata.
	@param Name string -- The requested LOOM service.
	@return any? -- The LOOM Service.
	
	:::danger
	This method will error if init isn't called or service is nil.
	:::
]=]
local function GetService(self: any, Name: string) : any?
	warn(Services);
	
	assert(self, "Expected ':' not '.' calling member function GetService")
	assert(Name, "[G] Attempt to call GetService with a missing ServiceName " .. debug.traceback("", 2));	

	
	if not (Services[Name]) then
		warn("Service not found:", Name);
		return nil;
	end;
	
	return Services[Name];
end;

--[=[
	@within LOOM
	
	Starts up the LOOM Services.
	@yields
	
	:::danger
	Init will error if it is called mutiple times.
	:::
]=]
local function Init() : ()
	if (Ran) then
		assert("[I] Services already registered please use :RegisterService if you wish to add another service [I]");
	end;
	
	Ran = true;
	for _,Service in script.Services:GetDescendants() do
		require(Service);
	end;
end;

--[=[
	@within LOOM

	Hooks a LOOM Service.
	
	@tag Services
	@param Name string -- The service to hook
	@param Target string -- The metamethod to hook
	@param New Function -- The function to re-write the metamethod with.
	
	:::danger
	This method will error with missing parameters.
	:::
]=]
--- @within LOOM
--- @deprecated v0 -- Keep in note this function will be deprecated and replaced with something else.
local function hookservice(Name: string, Target: string, New: any) : any
	local Metatable = RawMT[Name];
	local Old = Metatable[Target];
	
	rawset(Metatable, Target, New);
	return Old;
end;

--[=[
	@within LOOM

	Creates & Registers a new LOOM service.
	
	@tag Services
	@param self any -- The LOOM userdata
	@param Name string -- The name of the new LOOM Service
	@param Closure any -- The functions \ properties of the new LOOM Service.
	@param ReadOnly boolean? -- Sets the Loom service in a table.freeze and also locks the metatable. (Defaults to false)
	@param Type string? -- The string to return when typeof is calle don the Service. (Defaults to "Instance")
	@param LockMessage string? -- The message to return when getmetatable() is called on the Service (Defaults to "Loom Service")
	
	@return any? -- The service that was just created.
	
	:::caution
	ReadOnly parameter will ONLY work in live roblox games, not studio.
	:::
]=]
local function CreateService(self, Name: string, Closure: {}, ReadOnly: boolean?, Type: string?, LockMessage: string) : any?
	export type Closure = typeof(Closure);
	assert(self, "Expected ':' not '.' calling member function RegisterService");
	
	assert(Name, "[R] Attempt to call RegisterService with missing name [R]");
	assert(Closure, "[R] Attempt to call RegisterService with a missing operand [R]");
	
	local Proxy = newproxy(true);
	local ProxyMT = getmetatable(Proxy);
	
	if not (table.isfrozen(Closure)) then
		table.freeze(Closure);
	end;
	
	local CustomMethods = false;
	if (Closure["__namecall"] or Closure["__index"] or Closure["__newindex"]) then
		CustomMethods = true;
	end;

	ProxyMT.__index = function(Self: any, Index: any)
		if Closure["__index"] and CustomMethods then
			Closure["__index"](Self, Index);
			return;
		end;
		
		if Index == "Parent" then
			return game;
		end;


		return Closure[Index];
	end;

	ProxyMT.__newindex = function(Self: any , Index: any, Value: any) : ()
		if Closure["__newindex"] and CustomMethods then
			Closure["__newindex"](Self, Index, Value);
			return;
		end;
		
		if ReadOnly then
			error("Read Only", 2);
		else
			rawset(Self, Index, Value);
		end;
	end;

	ProxyMT.__namecall = function(Self: any, ...) : ()
		if Closure["__namecall"] and CustomMethods then
			Closure["__namecall"](Self, ...);
			return;
		end;
		
		local Method = getnamecallmethod();
		if not Closure[Method] then
			error(Method .. " is not a valid member of " ..Name, 2);
		end;
		return Closure[Method](...);
	end;

	ProxyMT.__call = function(...) : never
		error("attempt to call a Instance value", 2);
	end;

	ProxyMT.__type = Type or "Instance";
	RawMT[Name] = ProxyMT;
	
	if (ReadOnly) then
		if RunService:IsStudio() then
			warn("[R] Service metatable table will only become readonly in live seasions this is for the penteration tools [R]")
		else
			ProxyMT.__metatable = LockMessage or "Loom Service";	
			table.freeze(ProxyMT);
			table.clear(RawMT);
		end;
	end;
	
	Services[Name] = Proxy;
	if Closure["__registered"] then
		Closure["__registered"](Proxy);
	end;
	return Proxy;
end;




Framework.RegisterService = CreateService;
Framework.GetService = GetService;

Framework.Init = Init;
Framework.GetModule = GetModule;

Framework.getnamecallmethod = getnamecallmethod;
Framework.hookmetamethod = hookservice;


export type Self = typeof(Framework);
return setmetatable(Framework, {
	__index = function(Self: Self, Index: string) : any?
		return Services[Index] or rawget(Self, Index);
	end,
	__newindex = function(Self: Self, Index: any, Value: any) : never
		error("Read Only", 2);
	end,
	__metatable = "LOOM";	
});