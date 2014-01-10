Repo = {}

function Repo:init(state, url, desc)
	self.hash = nil

	self.state = state

	self.url = url
	self.desc = desc
	self.dev_mode = false

	self.packages = {}
end

function Repo:has_package(name)
	for _, pkg in ipairs(self.packages) do
		if pkg.name == name then
			return true
		end
	end
	return false
end

function Repo:install_package(name)
	for _, pkg in ipairs(self.packages) do
		if pkg.name == name then
			self.state:do_install_package(pkg)
			
			return
		else
			sleep()
		end
	end


	log.critical('No package by the name of ' .. name .. ' in repo[' .. self.url .. ']')
end

function Repo:save()
	if self.hash == nil then
		log.critical("repo::unknown::save", "Repo is in an invalid state", 1)
	end

	local f = fs.open(dirs['repo-state'] .. '/' .. self.hash .. '-pkgs', 'w')

	f.write(VERSION .. '\n')

	for _, pkg in ipairs(self.packages) do
		f.write(textutils.serialize(pkg:details()) .. '\n')
	end

	f.close()

	f = fs.open(dirs['repo-state'] .. '/' .. self.hash .. '-desc', 'w')

	f.write(self.desc)

	f.close()
end


-- Pull our state down from the tree!

function Repo:update()
	--log.debug("Updating repo " .. self.url)
	local task = self.state:begin_task("update-repo", 0)

	task:update("Getting Description")

	self.packages = {}
	self.desc = ""

	local remote = get_url(self.url .. '/desc.txt')
	self.desc = remote.readAll()
	remote.close()

	task:update("Getting package list.")

	remote = get_url(self.url .. '/packages.list')

	for line in read_lines(remote, task, "Reading Packages") do
		local idx = line:find("::")

		local pkg_name = line:sub(1, idx - 1)

		local pkg = new(Package, self, pkg_name)

		local idx2 = line:find('::', idx + 2)

		log.verbose("repo::" .. self.hash .. "::update", "Got Package " .. pkg_name)

		if idx2 then
			pkg.version = tonumber(line:sub(idx + 2, idx2 - 1))
			pkg.short_desc = line:sub(idx2 + 2)
		else
			pkg.version = tonumber(line:sub(idx + 2))
		end


		table.insert(self.packages, pkg)
	end

	task:done("Update repo " .. self.url)
end

-- Load from the on-disk cache

function Repo:load()
	local f = fs.open(dirs['repo-state'] .. '/' .. self.hash .. '-pkgs', 'r')

	f.readLine() -- VERSION

	for line in read_lines(f) do
		table.insert(self.packages, Package.from_details(self, textutils.unserialize(line)))
	end

	f.close()

	f = fs.open(dirs['repo-state'] .. '/' .. self.hash .. '-desc', 'r')

	self.desc = f.readAll()

	self.dev_mode = fs.exists(dirs['repo-state'] .. '/' .. self.hash .. '-dev_mode')

	f.close()
end

-- Blah de blah.

function Repo:get_package(pkg_name)
	for _, pkg in ipairs(self.packages) do
		if pkg.name == pkg_name then
			return pkg
		end
	end

	return nil
end