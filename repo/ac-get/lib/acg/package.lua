Package = {}

-- Packages represent both a server-package as well as a
-- package entry in the installed table.
function Package:init(repo, name)
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
	return self.repo.url .. '/' .. self.name .. '/'
end

function Package:install(state)
	local pkg = self

	local task = state:begin_task("install-" .. pkg.name, 0)

	local function install_all(type, files, path, ext)
		local start = task.steps

		task.steps = task.steps + #files

		for i, file in ipairs(files) do
			-- print("Installing " .. file)
			task:update("Installing " .. file, start + i)

			state:pull_file(pkg, type, 
				file,
				pkg:get_url() .. path .. '/' .. file .. ext)
		end
	end

	local function install_all_spec(type, files, path, ext)
		local start = task.steps

		task.steps = task.steps + #files

		for i, file in ipairs(files) do
			if file:sub(-1) == '/' then
				task:update("Creating " .. file, start + i)
				
				state:make_dir(pkg, type, file)
			else
				local source, dest = pkg:parse_dest(file)
		
				--print("Installing " .. dest)
				task:update("Installing " .. dest, start + i)

				state:pull_file(pkg, type,
					dest,
					pkg:get_url() .. path .. '/' .. source .. ext)
			end
		end
	end

	install_all('binaries', self.files['executable'], 'bin', '.lua')
	install_all('startup', self.files['startup'], 'startup', '.lua')
	install_all('docs', self.files['docs'], 'docs', '.txt')

	install_all_spec('libraries', self.files['library'], 'lib', '.lua')
	install_all_spec('config', self.files['config'], 'cfg', '')

	task:done("Installed " .. pkg.name)
end

function Package:remove( state )
	local pkg = self

	local task = state:begin_task("remove-" .. pkg.name, 1)

	local function remove_all(type, files, path, ext)
		local start = task.steps
		task.steps = task.steps + #files

		for i, file in ipairs(files) do
			task:update("Removing " .. file, start + i)
			state:remove_file(type, file)
		end
	end

	local function remove_all_spec(type, files, path, ext)
		local start = task.steps

		task.steps = task.steps + #files
		for i, file in ipairs(files) do
			if file:sub(-1) == '/' then
				task:update("Removing " .. file, start + i)

				state:remove_dir(type, file)
			else
				local source, dest = pkg:parse_dest(file)

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
	log.verbose('package::' .. step, 'Beginning...')
	
	for _, script in ipairs(self.steps[step]) do
		local scr = get_url_safe(self.repo.url .. "/" .. self.name .. "/steps/" .. step .. "/" .. script .. ".lua")

		if not scr then
			log.error("package::" .. step, "Step script missing: " .. step .. "/" .. script )
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
				log.error("package::" .. step, err)
			end
		end
	end
end


function Package:update()
	local pkg = get_url(self:get_url() .. '/details.pkg');

	if pkg == nil then
		error('No such package on server.')
	end

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


	for line in read_lines(pkg) do
		local idx = line:find(': ')

		if idx then
			local name = line:sub(1, idx - 1)
			local value = line:sub(idx + 2)

			-- Files!
			if name == 'Executable' then
				table.insert(self.files['executable'], value)
			elseif name == 'Library' then
				table.insert(self.files['library'], value)
			elseif name == 'Config' then
				table.insert(self.files['config'], value)
			elseif name == 'Startup' then
				table.insert(self.files['startup'], value)
			elseif name == 'Docs' then
				table.insert(self.files['docs'], value)
			-- Meta Data!
			elseif name == 'Description' then
				self.description = self.description .. value
			elseif name == 'Dependency' then
				table.insert(self.dependencies, value)
			-- Legal Dredgery!
			elseif name == 'License' then
				self.license = value
			elseif name == 'Copyright' then
				self.copyright = value
			-- Install Scripts!
			elseif name == 'Pre-Install' then
				table.insert(self.steps.pre_install, value)
			elseif name == 'Post-Install' then
				table.insert(self.steps.post_install, value)
			elseif name == 'Pre-Upgrade' then
				table.insert(self.steps.pre_upgrade, value)
			elseif name == 'Post-Upgrade' then
				table.insert(self.steps.post_upgrade, value)
			elseif name == 'Pre-Remove' then
				table.insert(self.steps.pre_remove, value)
			elseif name == 'Post-Remove' then
				table.insert(self.steps.post_remove, value)
			end
		end
	end

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