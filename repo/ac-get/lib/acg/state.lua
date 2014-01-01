State = {}

function State:init()
	self.repos = {}
	self.installed = {}

	self.hooks = {
		-- Tasks.
		task_begin = {},
		task_update = {},
		task_complete = {},
	}

	self.repo_hash = 0
end

function State:add_repo(url, desc)

	local repo = new(Repo, self, url, desc)
	repo.hash = self:new_repo_hash()

	self.repos[repo.hash] = repo

	repo:update()

	return repo
end

-- Runs the manifest from the given URL
function State:run_manifest(url)
	local directives = {}

	directives["Add-Repo"] = function(val) self:add_repo(val) end
	directives["Install"] = function(val) self:install(val) end
	directives["Run-Manifest"] = function(val) self:run_manifest(val) end

	parse_manifest(url, directives)
end

function State:new_repo_hash()
	self.repo_hash = self.repo_hash + 1

	return self.repo_hash
end

function State:install(pkg_name)
	for _, repo in ipairs(self.repos) do
		local pkg_obj = repo:get_package(pkg_name)

		if pkg_obj ~= nil then
			self:do_install_package(pkg_obj)

			return
		end
	end

	error('No repo provides package "' .. pkg_name .. '"', 2)
end

function State:remove(pkg_name)
	for _, pkg in ipairs(self.installed) do
		if pkg.name == pkg_name then
			self:do_remove_package(pkg.repo:get_package(pkg_name))
			return
		end
	end

	error('Package "' .. pkg_name .. '" is not installed.', 2)
end

function State:do_install_package(pkg)
	pkg:update()

	local inst_pkg = self:get_installed(pkg.name)

	for _, dep in ipairs(pkg.dependencies) do
		self:install(dep)
	end

	if inst_pkg then
		pkg:run_step(self, "pre_upgrade", inst_pkg.version, pkg.version)
	else
		pkg:run_step(self, "pre_install")
	end

	pkg:install(self)

	if inst_pkg then
		pkg:run_step(self, "post_upgrade", inst_pkg.version, pkg.version)
	else
		pkg:run_step(self, "post_install")
	end

	self:mark_installed(pkg)
end


function State:do_remove_package(pkg)
	pkg:run_step(self, "pre_remove")
	pkg:remove(self)
	pkg:run_step(self, "post_remove")

	self:mark_removed(pkg)
end

function State:mark_installed(pkg)
	for _, i_pkg in ipairs(self.installed) do
		if i_pkg.name == pkg.name then
			i_pkg.version = pkg.version

			return
		else
			sleep(0)
		end
	end

	table.insert(self.installed, pkg)
	self:get_package(pkg.name).state = "installed"
end

function State:mark_removed(pkg)
	self:get_package(pkg.name).state = "removed"
	
	for i, i_pkg in ipairs(self.installed) do
		if i_pkg.name == pkg.name then
			table.remove(self.installed, i)

			return
		end
	end
end

function State:is_installed(pkg_name)
	return self:get_installed(pkg_name) ~= nil
end

function State:get_installed(pkg_name)
	for _, pkg in ipairs(self.installed) do
		if pkg.name == pkg_name then
			return pkg
		else
			sleep(0)
		end
	end

	return nil
end

function State:save()
	local f = fs.open(dirs["repo-state"] .. "/index", "w")

	f.write(VERSION .. "\n")

	f.write(self.repo_hash .. "\n") 

	for hash, repo in pairs(self.repos) do
		f.write(hash .. '::' .. repo.url .. '\n')
		repo:save()
	end

	f.close()

	f = fs.open(dirs['state'] .. '/installed', 'w')

	f.write(VERSION .. '\n')

	for _, pkg in ipairs(self.installed) do
		f.write(pkg.repo.hash .. '::' .. pkg.name .. '::' .. pkg.version .. '\n')
	end

	f.close()
end

-- State Manupulation Functions
function State:make_dir(pkg, dtype, name)
	if fs.isDir(dirs[dtype] .. '/' .. name) then
		return
	end

	fs.makeDir(dirs[dtype] .. '/' .. name)
end

function State:pull_file(pkg, ftype, name, url)
	name = dirs[ftype] .. '/' .. name

	local remote = get_url(url)

	local loc = fs.open(name, 'w')

	buff = remote.readAll() .. ""

	sleep(0)

	buff = buff:gsub("__" .. "LIB" .. "__", dirs["libraries"])
	buff = buff:gsub("__" .. "CFG" .. "__", dirs["config"])
	buff = buff:gsub("__" .. "BIN" .. "__", dirs["binaries"])

	loc.write(buff)
	loc.close()

	remote.close()
end


function State:remove_dir(type, name)
	name = dirs[type] .. '/' .. name

	if not fs.exists(name) then
		return
	end

	if not fs.isDir(name) then
		return
	end

	fs.delete(name)
end

function State:remove_file(type, name)
	name = dirs[type] .. '/' .. name

	if not fs.exists(name) then
		return
	end

	fs.delete(name)
end

-- Package state tracking.

function State:get_package(pkg_name)
	return self:get_packages()[pkg_name]
end

function State:get_packages()
	if self._packages then
		return self._packages
	end

	local pkgs = {}

	for _, repo in pairs(self.repos) do
		for _, pkg in ipairs(repo.packages) do
			if pkgs[pkg.name] and pkgs[pkg.name].version < pkg.version then
				pkgs[pkg.name] = pkg
			elseif not pkgs[pkg_name] then
				pkgs[pkg.name] = pkg
			end
		end
	end

	for name, pkg in pairs(pkgs) do
		self:_load_state(name, pkg)
	end

	for _, pkg in ipairs(self.installed) do
		if not pkgs[pkg.name] then
			pkg.state = 'orphaned'

			pkgs[pkg.name] = pkg
		end
	end


	self._packages = pkgs

	return pkgs
end


function State:_load_state(pkg_name, pkg)
	local ipkg = self:get_installed(pkg_name)

	if not ipkg then
		pkg.state = 'available'
	else
		if ipkg.version < pkg.version then
			pkg.state = 'update'
		else
			pkg.state = 'installed'
		end

		pkg.iversion = ipkg.version
	end
end

-- Client Hooks

function State:hook(evt, func)
	if not self.hooks[evt] then
		error("Invalid state hook", 2)
	end

	table.insert(self.hooks[evt], func)
end

function State:call_hook(evt, ...)
	if not self.hooks[evt] then
		error("Invalid state hook", 2)
	end

	for _, func in ipairs(self.hooks[evt]) do
		pcall(func, ...)
	end
end

-- Task Handling

function State:begin_task(id, steps)
	return new(Task, self, id, steps)
end

-- Loading Function

function load_state()
	local state = new(State)

	local f = fs.open(dirs['repo-state'] .. '/index', 'r')

	if tonumber(f.readLine()) > VERSION then
		error('State files too new?')
	end

	state.repo_hash = tonumber(f.readLine())

	local repos = {}

	for line in read_lines(f) do
		local id = line:match('([0-9]+)::')

		local repo = new(Repo, state, line:sub(#id + 3), 'Loading...')
		repo.hash = tonumber(id)
		
		sleep(0)
		repo:load()
		sleep(0)

		state.repos[repo.hash] = repo
	end

	f.close()

	f = fs.open(dirs['state'] .. '/installed', 'r')

	if tonumber(f.readLine()) > VERSION then
		error('State files too new?')
	end

	for line in read_lines(f) do
		local idx = line:find("::")
		local repo_hash = tonumber(line:sub(1, idx-1))
		local idx2 = line:find("::", idx+2)
		local pkg_name = line:sub(idx + 2, idx2 - 1)
		local pkg_version = line:sub(idx2+2)

		local pkg = new(Package, state.repos[repo_hash], pkg_name)
		pkg.version = tonumber(pkg_version)

		table.insert(state.installed, pkg)
	end

	return state
end