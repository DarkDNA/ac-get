Package = {}

-- Packages represent both a server-package as well as a
-- package entry in the installed table.
function Package:init(repo, name)
	self.log = new(Logger, "package::" .. repo.hash .. "::" .. name)

	self.repo = repo

	self.files = {
		['executable'] = {},
		['library'] = {},
		['config'] = {},
		['startup'] = {},
		['docs'] = {},
	}

	self.steps = {
		pre_install = {},
		post_install = {},
		pre_upgrade = {},
		post_upgrade = {},
		pre_remove = {},
		post_remove = {}
	}

	self.name = name

	self.version = -1
	self.description = ""
	self.short_desc = ""
	self.dependencies = {}

	-- Legal Mumbo-Jumbo
	self.license = "Unknown"
	self.copyright = "Unknown"
end

function Package:get_url()
	return self.repo.url .. '/' .. self.name
end

function Package:install(state)
	local pkg = self

	self.log:debug("Installing...")

	local task = state:begin_task("install-" .. pkg.name, 0)

	local function install_all(type, files, path, ext)
		local start = task.steps

		task.steps = task.steps + #files

		for i, file in ipairs(files) do
			self.log:verbose("Installing " .. file)

			task:update("Installing " .. file, start + i)

			state:pull_file(pkg, type, 
				file,
				pkg:get_url() .. '/' .. path .. '/' .. file .. ext)
		end
	end

	local function install_all_spec(type, files, path, ext)
		local start = task.steps

		task.steps = task.steps + #files

		for i, file in ipairs(files) do
			if file:sub(-1) == '/' then
				self.log:verbose("Creating directory " .. file)

				task:update("Creating " .. file, start + i)
				
				state:make_dir(pkg, type, file)
			else
				local source, dest = pkg:parse_dest(file)
		
				self.log:verbose("Installing file " .. dest)

				task:update("Installing " .. dest, start + i)

				state:pull_file(pkg, type,
					dest,
					pkg:get_url() .. '/' .. path .. '/' .. source .. ext)
			end
		end
	end

	local ok, err = pcall(function()
		install_all('binaries', self.files['executable'], 'bin', '.lua')
		install_all('startup', self.files['startup'], 'startup', '.lua')
		install_all('docs', self.files['docs'], 'docs', '.txt')

		install_all_spec('libraries', self.files['library'], 'lib', '.lua')
		install_all_spec('config', self.files['config'], 'cfg', '')

		task:done("Installed " .. pkg.name)
	end)

	if not ok then
		self.log:error("Error installing: " .. err)

		task:error("Installing " .. pkg.name)
	end

	return ok, err
end

function Package:remove( state )
	local pkg = self

	self.log:debug("Uninstalling")

	local task = state:begin_task("remove-" .. pkg.name, 1)

	local function remove_all(type, files, path, ext)
		local start = task.steps
		task.steps = task.steps + #files

		for i, file in ipairs(files) do
			self.log:verbose("Removing file " .. file)

			task:update("Removing " .. file, start + i)
			state:remove_file(type, file)
		end
	end

	local function remove_all_spec(type, files, path, ext)
		local start = task.steps

		task.steps = task.steps + #files
		for i, file in ipairs(files) do
			if file:sub(-1) == '/' then
				self.log:verbose("Removing directory " .. file)

				task:update("Removing " .. file, start + i)

				state:remove_dir(type, file)
			else
				local source, dest = pkg:parse_dest(file)

				self.log:verbose("Removing file " .. file)

				task:update("Removing " .. file, start + i)

				state:remove_file(type, dest)
			end
		end
	end

	remove_all('binaries', self.files['executable'])
	remove_all('startup', self.files['startup'])
	remove_all('docs', self.files['docs'])

	remove_all_spec('libraries', self.files['library'])
	remove_all_spec('config', self.files['config'])

	task:done("Removed " .. pkg.name)
end

function Package:run_step(state, step, ...)
	--log.verbose('package::' .. step, 'Beginning...')
	self.log:verbose("Beginning Step " .. step)
	
	for _, script in ipairs(self.steps[step]) do
		local scr = get_url_safe(self.repo.url .. "/" .. self.name .. "/steps/" .. step .. "/" .. script .. ".lua")

		if not scr then
			self.log:error("Step script missing: " .. step .. "/" .. script )
		else
			local f = loadstring(scr.readAll(), self.name .. '-' .. step .. "-" .. script)

			local env = {
				dirs = dirs,
				fs = fs,
				io = io,
				textutils = textutils,
				print = print,
			}

			setfenv(f, env)

			local ok, err = pcall(f, ...)

			if not ok then
				self.log:error("Error running step " .. step .. "/" .. script .. ": " .. err)
			end
		end
	end
end


function Package:update()
	self.description = ""

	self.dependencies = {}

	self.files = {
		['executable'] = {},
		['library'] = {},
		['config'] = {},
		['startup'] = {},
		['docs'] = {},
	}

	self.steps = {
		pre_install = {},
		post_install = {},
		pre_upgrade = {},
		post_upgrade = {},
		pre_remove = {},
		post_remove = {}
	}

	local directives = {}

	-- Files.

	directives["Executable"] = function(value) table.insert(self.files['executable'], value) end
	directives["Library"] = function(value) table.insert(self.files['library'], value) end
	directives["Config"] = function(value) table.insert(self.files['config'], value) end
	directives["Startup"] = function(value) table.insert(self.files['startup'], value) end
	directives["Docs"] = function(value) table.insert(self.files['docs'], value) end

	-- Meta Data!

	directives["Description"] = function(value) self.description = self.description .. value end
	directives["Dependency"] = function(value) table.insert(self.dependencies, value) end
	directives["License"] = function(value) self.license = value end
	directives["Copyright"] = function(value) self.copyright = value end

	-- Cycle hooks!

	directives["Pre-Install"] = function(value) table.insert(self.steps.pre_install, value) end
	directives["Post-Install"] = function(value) table.insert(self.steps.post_install, value) end
	directives["Pre-Upgrade"] = function(value) table.insert(self.steps.pre_upgrade, value) end
	directives["Post-Upgrade"] = function(value) table.insert(self.steps.post_upgrade, value) end
	directives["Pre-Remove"] = function(value) table.insert(self.steps.pre_remove, value) end
	directives["Post-Remove"] = function(value) table.insert(self.steps.post_remove, value) end

	parse_manifest(self:get_url() .. '/details.pkg', directives)

	if self.short_desc == "" then
		self.short_desc = self.description:sub(0, 30)
	end
end

function Package:details()
	return {
		name = self.name,
		version = self.version,
		description = self.description,
		files = self.files,
		dependencies = self.dependencies,
		short_desc = self.short_desc,
		license = self.license,
		copyright = self.copyright,
		steps = self.steps,
	}
end

function Package.from_details(repo, details)
	local pkg = new(Package, repo, details.name)

	if details.short_desc == "" and details.description ~= "" then
		pkg.short_desc = details.description:sub(0, 30)
	else
		pkg.short_desc = details.short_desc
	end

	pkg.version = details.version
	pkg.description = details.description
	pkg.files = details.files
	pkg.license = details.license or "Unknown"
	pkg.copyright = details.copyright or "Unknown"

	if details.dependencies then
		pkg.dependencies = details.dependencies
	end

	if details.steps then
		pkg.steps = details.steps
	end

	return pkg
end

function Package:parse_dest(parts)
	local parts = parts .. ""

	local idx = parts:find(' => ')
	if not idx then
		return parts, parts
	end

	return parts:match("(.+) => (.+)")
end