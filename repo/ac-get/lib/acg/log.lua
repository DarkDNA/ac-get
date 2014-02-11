log = {}

CRITICAL = 1
ERROR = 2
WARNING = 3
DEBUG = 4
VERBOSE = 5


log.levels = {
}

log.default_level = CRITICAL

local targets = {}

local function get_level(name)
	for k, lvl in pairs(log.levels) do
		if name:match(k) then
			return lvl
		end
	end

	return log.default_level
end

local function do_log(name, level, ...)
	local lvl = get_level(name)

	if level <= lvl then
		for _, target in ipairs(targets) do
			target(level, "[" .. name  .. "] " .. table.concat({...}, ' '))
		end

		if level == CRITICAL then
			error('[' .. name .. '] ' .. table.concat({...}, ' '), 3)
		end
	end
end

function log.add_target(tgt)
	table.insert(targets, tgt)
end

function log.verbose(name, ...)
	do_log(name, VERBOSE, ...)
end

function log.debug(name, ...)
	do_log(name, DEBUG, ...)
end

function log.warn(name, ...)
	do_log(name, WARNING, ...)
end

function log.error(name, ...)
	do_log(name, ERROR, ...)
end

function log.critical(name, ...)
	do_log(name, CRITICAL, ...)
end

-- Logger Object.

Logger = {}

function Logger:init(name)
	self.name = name

	for k, v in pairs(log) do
		if k ~= "add_target" then
			self[k] = function(self, ...)
				v(self.name, ...)
			end
		end
	end
end
