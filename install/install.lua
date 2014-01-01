local BASE_URL = 'http://ac-get.darkdna.net'
local INSTALL_SOURCE = BASE_URL .. "/install"
local MANIFEST = BASE_URL .. "/install.manifest"

local args = {...}

if args[1] then
	MANIFEST = args[1]
end

function get_url(url)
	if http == nil then
		error('Need HTTP library enabled.', 2)
	end

	local remote = http.get(url)

	if remote == nil then
		error('Error getting HTTP.', 2)
	end

	return remote
end

-----------------------------------------------------------

local x, y = term.getCursorPos()
local w, h = term.getSize()

local function task_begin(id)
	x, y = term.getCursorPos()
end

local function task_update(id, detail, cur, max)
  local txt = cur .. "/" .. max

  if max == 0 then
    txt = cur .. ""
  end

  term.setCursorPos(x, y)
  term.clearLine()


  if #detail > w - #txt - 1 then
    detail = detail:sub(1, w - #txt - 4) .. "..."
  end


  term.write(detail)

  term.setCursorPos(w - #txt + 1, y)
  term.write(txt)
end

local function task_complete(id, detail)
	  local txt = "Complete"

	  if detail ~= "" then
	    term.setCursorPos(x, y)
	    term.clearLine()


	    if #detail > w - #txt - 1 then
	      detail = detail:sub(1, w - #txt - 4) .. "..."
	    end

	    term.write(detail)
	  end

	  term.setCursorPos(w - #txt + 1, y)
	  term.write(txt)

	  print()
end

local log_f = io.open("/acg-install.log", "w")

local function print_log(lvl, msg)
	log_f:write(lvl .. " - " .. msg .. "\n")
end


local tmp_dir = '/tmp-' .. math.random(65535)
print('Initilizing first run installer in ' .. tmp_dir)

fs.makeDir(tmp_dir)

local _, e = pcall(function()
	local acg_base = get_url(INSTALL_SOURCE .. '/manifest')

	local line = acg_base.readLine();

	local i = 1

	task_begin('get-files')
	repeat

		-- print('  ' .. line)
		task_update('get-files', "Getting " .. line, i, 0)

		local loc_file = fs.open(tmp_dir .. '/' .. line, 'w')
		local acg_file = get_url(INSTALL_SOURCE .. '/' .. line)

		loc_file.write(acg_file.readAll())

		acg_file.close()

		loc_file.close()

		dofile(tmp_dir .. '/' .. line, line)
		
		line = acg_base.readLine()
		i = i + 1
	until line == nil

	task_complete('get-files', 'Get ac-get installer files.')

	i = 1
	local tot = #dirs

	task_begin('make-dirs', 'Making directories')
	for k, v in pairs(dirs) do
		task_update('make-dirs', 'Making ' .. v, i, tot)
		fs.makeDir(v)

		i = i + 1
	end

	task_complete('make-dirs', 'Creating directories.')

	local state = new(State)

	state:hook("task_begin", task_begin)
	state:hook("task_update", task_update)
	state:hook("task_complete", task_complete)

	log.add_target(print_log)

	state:run_manifest(MANIFEST)

	--local repo = state:add_repo(BASE_REPO, 'Base ac-get repo')
	--repo:install_package('ac-get')

	state:save()
end)

if e then
	print("Error executing: " .. e)
end

log_f:close()
fs.delete(tmp_dir)