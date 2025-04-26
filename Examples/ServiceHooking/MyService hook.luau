local Loom = require(game:GetService("ReplicatedStorage").Loom);
Loom.Init();

local hookservice = Loom.hookmetamethod;

local MyService = Loom:GetService("MyService");
local getnamecallmethod = Loom.getnamecallmethod;

hook = hookservice("MyService", "__namecall", function(Self, ...)
	local CallingScript = getfenv(debug.info(2, "f"));

	local function getcallingscript() -- just for the aesthetics
		return CallingScript.script;	
	end;

	local function checkcaller() -- just  for the aesthetics
		return getcallingscript() == script;	
	end;

	warn(getcallingscript(), "is invoking the __namecall metamethod of MyService", "with", getnamecallmethod(), ...)
	print(checkcaller())
	if not checkcaller() and getnamecallmethod() == "TestFunc" then
		return 100;
	end;

	return hook(Self, ...);
end);

print(Loom:GetService("MyService"):TestFunc());
