VERSION = 0

local default_dirs = {
	["binaries"] = "/ac-get/bin",
	["libraries"] = "/ac-get/lib",
	["config"] = "/settings",
	["startup"] = "/ac-get/startup.d",
	["docs"] = "/ac-get/docs/",
	-- ac-get stuff.
	["state"] = "/ac-get/state",
	["repo-state"] = "/ac-get/state/repos"
}

dirs = default_dirs

local f = fs.open('/ac-get-dirs', 'r')

if f ~= nil then
	for k, v in pairs(textutils.unserialize(f.readAll())) do
		dirs[k] = v
	end

	f.close()
end
