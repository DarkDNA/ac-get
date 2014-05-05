VERSION = 0

local default_dirs = {
	["binaries"] = "/bin",
	["libraries"] = "/lib",
	["config"] = "/cfg",
	["startup"] = "/cfg/startup.d",
	["docs"] = "/docs/",
	-- ac-get stuff.
	["state"] = "/lib/ac-get",
	["repo-state"] = "/lib/ac-get/repos"
}
dirs = default_dirs

if fs.exists('/ac-get-dirs') then
	local f = fs.open('/ac-get-dirs', 'r')

	if f ~= nil then
		for k, v in pairs(textutils.unserialize(f.readAll())) do
			dirs[k] = v
		end

		f.close()
	end
end

for _, fname in ipairs(fs.list(dirs['libraries'] .. '/acg/')) do
	if fname ~= 'acg' and fname ~= "plugins" then
		dofile(dirs['libraries'] .. '/acg/' .. fname)
	end
end

PluginRegistry:load()