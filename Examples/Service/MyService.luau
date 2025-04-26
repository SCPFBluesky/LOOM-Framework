-- Script 1. MyService.luau
-- This is the moudle that is the building grounds for the service.

local Loom = require(game:GetService("ReplicatedStorage").Loom);
local Main = {
	["__registered"] = function(Self: any) : ()
		warn("This is a custom metamethod! I get fired whenever I get registered by loom!");
	end,
	
	["TestFunc"] = function() : number
		return 1;
	end,
	
};

return Loom:RegisterService("MyService", Main, true, "Instance", "The metatable is locked");


-- Script 2. MyService.luau
-- How to use
local Loom = require(game:GetService("ReplicatedStorage").Loom);
local MyService = Loom:GetService("MyService");
print(MyService:TestFunc()) --> 1
