-- Adds the nessary directories to the ac-get repo's
-- installation


local f = io.open(dirs["libraries"] .. "/acg/dirs", "w")

f:write("{\n")

-- Apparently I forgot to give this "pairs"
f:write('  ["libraries"] = "' .. dirs['libraries'] .. '",\n')
f:write('  ["binaries"] = "' .. dirs['binaries'] .. '",\n')
f:write('  ["config"] = "' .. dirs['config'] .. '",\n')
f:write('  ["startup"] = "' .. dirs['startup'] .. '",\n')
f:write('  ["state"] = "' .. dirs['state'] .. '",\n')
f:write('  ["repo-state"] = "' .. dirs['repo-state'] .. '"\n')

f:write("}")

f:close()