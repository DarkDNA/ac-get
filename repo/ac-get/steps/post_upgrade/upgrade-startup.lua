-- V6 (Intro) This changes the /startup blurb to use table.sort
-- On the file list, allowing ordered startup scripts.
-- V7 -- Change the pcall behavure to allow shell
-- to be used in the startup scripts again.

-- New Startup Stuff
local startup = [[
--DO NOT REMOVE -- ac-get
local s_dir = '__STARTUP__'
local files = fs.list(s_dir)
table.sort(files)
for _, start in ipairs(files) do
  local ok, err = pcall(function() dofile(s_dir .. '/' .. start) end)
  if not ok then
    printError("Error in startup: " .. err)
  end
end
--DO NOT REMOVE]]

startup = startup:gsub("__STARTUP__", dirs["startup"])

local from, to = ...

if from < 7 then
  local r_f = io.open("/startup", "r")
  local w_f = io.open("/startup.new", "w")
  local p = true
  local did_it = false

  for line in r_f:lines() do
    if line == "--DO NOT REMOVE -- ac-get" then
      w_f:write(startup)
      did_it = true
      p = false
    elseif line == "--DO NOT REMOVE" then
      p = true
    elseif p then
      w_f:write(line .. "\n")
    end
  end

  if not did_it then
    print("WARNING: Could not find ac-get code block in existing")
    print("/startup -- Please verify /startup.new and then")
    print("move to /startup.")

    w_f:write(startup)
  end

  w_f:close()
  r_f:close()

  if did_it then
    fs.move("/startup", "/startup.old")
    fs.move("/startup.new", "/startup")
    print("ATTN: The /startup code has been changed")
    print("  Please verify that it looks right before a")
    print("  Reboot. -- Report bugs on the forum thread.")
  end

  fs.delete(dirs["startup"] .. "/add-path")
end