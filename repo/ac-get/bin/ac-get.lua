--[[=====================================================
          Utility Functions
    =====================================================]]

local function paged_print(str)
  local nativeScroll = term.scroll

  local _, h = term.getSize()

  local free_lines = h - 2

  term.scroll = function(lines)
    for _=1,lines do
      nativeScroll(1)

      if free_lines <= 0 then
        local _, h = term.getSize()

        term.setCursorPos(1, h)
        term.write("Press any key to continue, or q to exit.")

        local evt, key = os.pullEvent("key")

        term.clearLine()
        term.setCursorPos(1, h)

        if key == keys.q then
          os.pullEvent("char")
          error("Foo Bar Baz")
        elseif key == keys.pageDown then
          free_lines = math.floor(select(2, term.getSize()) * (2/3))
        end
      else
        free_lines = free_lines - 1
      end
    end
  end

  local ok, err = pcall(function()
    print(str)
  end)

  term.scroll = nativeScroll

  if not ok and not err:find("Foo Bar Baz") then
    error(err)
  end
end

local function list_packages(packages, title)
  local name_width = 10
  local ver_width = 3
  local sep = '|'

  for _, pkg in ipairs(packages) do
    if #pkg.name > name_width then  
      name_width = #pkg.name
    end
  end


  local w, h = term.getSize()

  local desc_width = w - name_width - ver_width - #sep * 3

  local str = title

  for _, pkg in ipairs(packages) do
    str = str .. "\n"
    str = str .. (pkg.state or "?"):sub(0, 1)
    str = str .. sep
    str = str .. pkg.name .. string.rep(" ", name_width - #pkg.name)
    str = str .. sep
    str = str .. pkg.version .. string.rep(" ", ver_width - #("" .. pkg.version))
    str = str .. sep

    -- Now the fun bit.
    local desc = pkg.short_desc

    if desc == "" or not desc then
      desc = pkg.description
    end

    if desc == "" or not desc then
      desc = "No description loaded."
    end

    if #desc > desc_width then
      desc = desc:sub(0, desc_width - 3) .. "..."
    end

    str = str .. desc
  end

  paged_print(str)
end

local function confirm(msg)
  print(msg)
  term.write("Y/N> ")
  repeat
    _, char = os.pullEvent("char")
  until char:lower() == "y" or char:lower() == "n"

  print(char)

  return (char:lower() == "y")
end

--[[=====================================================
      Commands!
    =====================================================]]


local commands = {}

commands['add-repo'] = {
  help = "Loads new repositories into the package manager.",
  usage = "<repo-url>",
  run = function(state, args)
  local repo = state:add_repo(args[1], 'Loading...')

  -- We don't need to call update() as it's getting updated
  -- by the add_repo() call.

  state:save()
end
}

commands['install'] = {
  help = "Installs the package",
  usage = "<package>[ package...]",
  run = function(state, args)
  if #args > 0 then
    for _, pkg in ipairs(args) do
      state:install(pkg)
    end
  else
    return 1
  end

  state:save()
end
}

commands['remove'] = {
  usage = '<package>[ [package]...]',
  help = [[Removes the given package(s)?

This command will remove all traces of a package, as well
as any that depend on it.

WARNING: Currently this does not give you any overview of
the changes that it will make.]],
  run = function (state, args) 
  if #args < 1 then
    return 2
  end

  for _, pkg in ipairs(args) do
    state:remove(pkg)
  end

  state:save()
end
}

commands['help'] = {
  help = "shows this screen",
  usage = "[command]",
  run = function(state, args)

  if #args == 0 then
    print('Usage: ' .. acg.dirs['binaries'] .. '/ac-gets <command> [command-args]')
    print()

    print('Commands:')
    for cmd, details in pairs(commands) do
      print('  ' .. cmd .. ' ' .. details.usage)
    end

    return
  end

  local cmd = commands[args[1]]

if cmd == nil then
    error('Unknown command ' .. args[1])
  end


  print('Usage: ' .. acg.dirs['binaries'] .. '/ac-get ' .. args[1] .. ' ' .. cmd.usage)
  print()

  print(cmd['help'])
end
}

commands['update'] = {
  help = [[Updates the given packages.

This command takes a variable number of arguments and
updates any packages in it needing to be updated. If passed
no arguments, it will check all installed packages for
needing an update.]],
  usage = "[package1 [package2 [packagen...]]]",
  run = function(state, args)
  for _, repo in pairs(state.repos) do
    repo:update()
  end

  local changes = {}

  if #args == 0 then
    for _, pkg  in pairs(state:get_packages()) do
      if pkg.state == 'update' then
        table.insert(changes, pkg)
      end
    end
  else
    for _, arg in ipairs(args) do
      local pkg = state:get_package(arg)

      if not pkg then
        print("Unknown package " .. arg)
      else
        if pkg.state == 'update' then
          table.insert(changes, pkg)
        end
      end
    end
  end

  if #changes == 0 then
    print("No changes to make.")

    state:save()
    return
  end

  local str = "To be updated: "

  for _, change in ipairs(changes) do
    str = str .. "\n"
    str = str .. change.name .. " "
    str = str .. change.iversion .. " -> " .. change.version
  end

  paged_print(str)

  if confirm("Changes OK? [Y/N]") then
    for _, change in ipairs(changes) do
      state:install(change.name)
    end
  end

  state:save()

  print("Done.")
end
}

commands['search'] = {
  help = [[Searches for the given package name.

This command searches your installed repos for packages 
matching the given criteria. The criteria is currently
parsed as a lua regulat expression.]],
  usage = '<term>',
  run = function(state, args)

  if #args ~= 1 then
    return 2
  end

  local results = {}
  print("Looking for packages containing " .. args[1])
  for _, pkg in pairs(state:get_packages()) do
    if pkg.name:match(args[1]) or pkg.short_desc:match(args[1]) then
     table.insert(results, pkg)
    end
  end

  if #results == 0 then
    print("No Results for query.")
    return
  end

  list_packages(results, "Search Results for [" .. args[1] .. "]")
end
}

commands['list'] = {
  help = [[Lists packages
You have the following options available to you for listing packages:

  installed - Lists all the packages you have  installed.
  available - Lists all the packages   in all the repos 
                you have installed.
  repos     - Lists all the installed repo URLs you have.]],
  usage = '<type>',
  run = function(state, args)
  local pkgs = {}

  if #args ~= 1 then
    return 2
  end

  if args[1] == 'installed' then
    for _, pkg in ipairs(state.installed) do
      table.insert(pkgs, state:get_package(pkg.name))
    end

    list_packages(pkgs, "Installed Packages")
  elseif args[1] == 'available' then
    for _, pkg in pairs(state:get_packages()) do
      table.insert(pkgs, pkg)
    end

    list_packages(pkgs, "Available packages.")
  elseif args[1] == "repos" then
    local str = "List of repositories:"
    for _, repo in pairs(state.repos) do
      str = str .. "\n" .. repo.url
    end

    local _, h = term.getSize()

    paged_print(str)
  else
    print("Unknown list: " .. args[1])
    print()
    return 1
  end
end
}

commands['info'] = {
  help = [[Shows information about a given package.

Shows information like the repository it belongs to,
and the current (in-repo and downloaded) version of it.
]],
  usage = "<package>",
  run = function(state, args)

  if #args == 0 then
    return 1
  end

  local pkg = state:get_package(args[1])

  if pkg then 
    local data = {}

    data["Name"] = pkg.name

    if pkg.state ~= 'available' then
      data["Version"] = pkg.iversion .. " (Repo: " .. pkg.version ..")"
    elseif pkg.state == 'orphaned' then
      data["Version"] = pkg.version .. " (Orphaned)"
    else
      data["Version"] = pkg.version
    end

    data["State"] = pkg.state

    data["Description"] = pkg.description
    data["Short Desc."] = pkg.short_desc

    data["Repository"] = pkg.repo.url

    data["License"] = pkg.license
    data["Copyright"] = pkg.copyright

    if #pkg.dependencies > 0 then
      data["Deps"] = table.concat(pkg.dependencies, ", ")
    end

    local k_len = 10

    for k, v in pairs(data) do
      if #k > k_len then
        k_len = #k
      end
    end

    local str = 'Package details for ' .. args[1]

    for k, v in pairs(data) do
      str = str .. '\n'
      str = str .. k .. string.rep(" ", k_len - #k) .. " | " .. v
    end

    local _, h = term.getSize()

    paged_print(str)
  else
    print("Error getting package: No Package found.")
  end
end}

commands['history'] = {
  usage = '<package>',
  help = [[Lists the package version history.

This history is optional, and not required for a package
to be a valid package. It is for repo maintainers to
explain what an upgrade will give you.]],
  run = function(state, args)
  if not args[1] then
    return 1
  end

  local pkg = state:get_installed(args[1])

  if not pkg then
    for _, repo in pairs(state.repos) do
      local p = repo:get_package(args[1])
      if p then
        if pkg and pkg.version < p.version then
          pkg = p
        elseif not pkg then
          pkg = p
        end
      end
    end
  end

  if not pkg then
    print("No such package.")
    return
  end


  local url = pkg:get_url() .. "/history.txt"

  local hist = acg.get_url_safe(url)

  if hist then
    local _, h = term.getSize()

    --textutils.pagedPrint(hist.readAll(), h - 2)
    paged_print(hist.readAll())

    hist.close()
  else
    print("Package has no history on server.")
  end
end}

--[[=====================================================
        Main Code Handling.
    =====================================================]]

os.loadAPI("__LIB__/acg/acg")

local args = {...}

local state = acg.load_state()

local x, y = term.getCursorPos()
local w, h = term.getSize()

local prev_task = nil

state:hook("task_begin", function(id)
  x, y = term.getCursorPos()
end)

state:hook("task_update", function(id, detail, cur, max)
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
end)

state:hook("task_complete", function(id, detail)
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
end)

local command = table.remove(args, 1)

local ok, err = pcall(function()
  if not commands[command] then
    if command ~= nil then
      print('Unknown command.')
      print()
    end

    commands['help'].run(state, {})

    return
  end

  local ret = commands[command].run(state, args)

  if ret == 1 then
    commands['help'].run(state, {command})
  elseif ret == 2 then
    print('Usage: __BIN__/ac-get ' .. command .. ' ' .. commands[command].usage)
  end
end)

if not ok then
  printError("Error executing command: " .. err)
end