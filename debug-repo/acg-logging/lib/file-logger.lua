local f = fs.open("/acg-log", "w")

local levels = {
  "CRITICAL",
  "ERROR",
  "WARNING",
  "DEBUG",
  "VERBOSE"
}

log.add_target(function(level, line)
  f.writeLine("[" .. os.clock() .. " - " .. levels[level] .. "] " .. line)

  f.flush()
end)