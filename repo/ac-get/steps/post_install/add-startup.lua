local data = [[
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

data = data:gsub("__STARTUP__", dirs["startup"])

local f = io.open("/startup", "a")

if f == nil then
	f = io.open("/startup", "w")
end

f:write(data)

f:close()

print("Startup helper installed.")
print("Please reboot computer for change to take effect.")