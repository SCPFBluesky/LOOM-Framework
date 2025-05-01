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
local Storages = {};

local DataStoreService = game:GetService("DataStoreService");
local freeze :({  }) -> {  }, isreadonly: <K, V>({ [K]: V }) -> boolean, clear: <K, V>({ [K]: V }) -> (), insert: (<V>({V}, V) -> ()) & (<V>({V}, number, V) -> ()) = table.freeze, table.isfrozen, table.clear, table.insert;

local Old: <T>(T, string?) -> T = assert;
local setmetatable = setmetatable;

local assert = @checked function(Condition: any, Message: string) : ()
	local succ, err = pcall(function()
		return Old(Condition);
	end);

	if not (succ) then
		warn("[LOOM [C] ] assertion failed! ", Message, "[LOOM [C] ]");
		warn(debug.traceback("assertion failed!", 2));
		
		return;
	end;
end;

--[=[
	@within LOOM

	@tag Modules
	@param self any -- The LOOM userdata.
	@param Name string -- The moudle to get
	@return any? -- The requried module.
	@yields
]=]
@checked local function GetModule(self: any, Name: string) : any?
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

local function GetType(self: any, Name: string)
	return script.Types[Name]	
end;

--[=[
	@within LOOM

	Returns the raw metatable of the requested service
	
	@tag Tools
	@param Service string -- The service to fetch the raw metatable	of
	
	:::danger
	This method will throw an error when it is not called inside a studio playtest.
	:::
	
	@return {}? -- The raw metatable of the service
]=]
local function getrawservice(Service: any) : {}?	
	assert(RunService:IsStudio(), "Attempt to call a studio only function.");
	return RawMT[Service];
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
@checked local function GetService(self: any, Name: string)
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
	assert(not Ran, "[I] Services already registered please use :RegisterService if you wish to add another service [I]");

	Ran = true;
	for _,Service: ModuleScript in script.Services:GetDescendants() do
		if (Service:IsA("ModuleScript")) then
			require(Service);
		end;
	end;
end;

--[=[
	@within LOOM

	Hooks a LOOM Service.
	
	@tag Tools
	@param Service any -- The service to hook
	@param Target string -- The metamethod to hook
	@param New Function -- The function to re-write the metamethod with.
	
	:::danger
	This method will throw an error when it is not called inside a studio playtest.
	:::
	
	@returns any? -- The old metamethod that was replaced.
]=]
--- @within LOOM
--- @deprecated v0 -- Keep in note this function will be deprecated and replaced with something else.
@checked local function hookservice(Service: any, Target: string, New: any) : any
	assert(RunService:IsStudio(), "Attempt to call a studio only function.");
	
	local Metatable = getrawservice(Service);
	local Old = Metatable[Target];

	rawset(Metatable, Target, New);
	return Old;
end;


@checked local function CreateDataStorage(Name: string, Scope: any, Options: Instance) : ()
	local Storage = DataStoreService:GetDataStore(Name, Scope, Options);
	Storages[Name] = Storage;
end;

@checked local function GetDataStore(Name: string) : DataStore?
	assert(Storages[Name], "Could not find " .. Name)
	return Storages[Name];
end;

--[[@checked local function SaveToStorage(Name: string, ...) : string?
	local Storage = GetDataStore(Name);	
	local Args = {...};
	
	local succ, err = pcall(function()
		Storage:SetAsync(unpack(Args));
	end);
	
	if not succ then
		error("Failed to save " .. Name .. " becuase " .. err, 2);
		return nil;
	end;
	
	return "Saved";
end;]]

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
@checked local function CreateService(self, Name: string, Closure: {}, ReadOnly: boolean?, Type: string?, LockMessage: string) : any?
	--export type Closure = typeof(Closure);
	assert(self, "Expected ':' not '.' calling member function RegisterService");

	assert(Name, "[R] Attempt to call RegisterService with missing name [R]");
	assert(Closure, "[R] Attempt to call RegisterService with a missing operand [R]");

	local Proxy = newproxy(true);
	local ProxyMT = getmetatable(Proxy);

	if not (isreadonly(Closure)) then
		freeze(Closure);
	end;

	local CustomMethods = false;
	if (Closure["__namecall"] or Closure["__index"] or Closure["__newindex"]) then
		CustomMethods = true;
	end;

	ProxyMT.__index = @checked function(Self: any, Index: any)
		if Closure["__index"] and CustomMethods then
			Closure["__index"](Self, Index);
			return;
		end;

		if Index == "Parent" then
			return game;
		end;


		return Closure[Index];
	end;

	ProxyMT.__newindex = @checked function(Self: any , Index: any, Value: any) : ()
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

	ProxyMT.__namecall = @checked function(Self: any, ...) : ()
		if Closure["__namecall"] and CustomMethods then
			Closure["__namecall"](Self, ...);
			return;
		end;

		local Method: string = getnamecallmethod();
		if not Closure[Method] then
			error(Method .. " is not a valid member of " ..Name, 2);
		end;
		return Closure[Method](...);
	end;

	ProxyMT.__call = @checked function(...) : never
		error("attempt to call a Instance value", 2);
	end;

	ProxyMT.__type = Type or "Instance";
	ProxyMT.__metatable = LockMessage or "Loom Service";	

	RawMT[Proxy] = ProxyMT;
	if (ReadOnly) then
		if RunService:IsStudio() then
			warn("[R] Service metatable table will only become readonly in live seasions this is for the penteration tools [R]")
		else
			freeze(ProxyMT);
			clear(RawMT);
			
			freeze(RawMT);
		end;
	end;

	Services[Name] = Proxy;
	if Closure["__registered"] then
		Closure["__registered"](Proxy);
	end;
	
	return Proxy;
end;


@checked local function Shared(Name: string) : Object? | Instance? | any?
	return script.Assets[Name];
end;

Framework.RegisterService = CreateService;
Framework.GetService = GetService;

Framework.Init = Init;
Framework.GetModule = GetModule;

Framework.getnamecallmethod = getnamecallmethod;
Framework.hookmetamethod = hookservice;

Framework.GetType = GetType;
Framework.Shared = Shared;

Framework.getrawservice = getrawservice;
--export type Self = typeof(Framework);

return setmetatable(Framework, {
	__index = @checked function(Self: {any}, Index: any) : any?
		return Services[Index] or rawget(Self, Index);
	end,
	__newindex = @checked function(Self: {any}, Index: any, Value: any) : never
		error("Read Only", 2);
	end,
	__metatable = "LOOM";	
});
