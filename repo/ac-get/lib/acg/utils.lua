function get_url(url)
	if http == nil then
		log.critical('Need HTTP library enabled.')
	end

	log.verbose('Getting', url)

	local remote = http.get(url)

	if remote == nil then
		log.critical('Error getting', url)
	end

	log.verbose('Got it!')

	return remote
end

function get_url_safe(url)
	if http == nil then
		log.critical('Need HTTP library enabled.')
	end

	log.verbose('Getting', url)

	local remote = http.get(url)

	if remote == nil then
		log.error('Error getting', url)
	else
		log.verbose("Got It!")
	end

	return remote
end

function read_lines(fhandle, task, title)
	local i = 1

	local function read_line()
		-- Make the task status be updated
		if task then
			task:update(title, i)
			i = i + 1
		end

		return fhandle.readLine()
	end

	return read_line, fhandle, 0
end

-- Manifest parsing.

function parse_manifest(url, directives)
	local mani = get_url(url)

	assert(mani, "Manifest does not exist")

	for line in read_lines(mani) do
		local idx = line:find(': ')

		if idx then
			local name = line:sub(1, idx - 1)
			local value = line:sub(idx + 2)

			if directives[name] then
				directives[name](value)
			elseif directives.__default then
				directives.__default(name, value)
			end
		end
	end

	mani.close()
end
