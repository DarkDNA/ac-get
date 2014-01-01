-- This is a part of ac-get -- Please do not modify

os.loadAPI("__LIB__/acg/acg")

local p = shell.path()
p = acg.dirs["binaries"] .. ":" .. p
shell.setPath(p)

p = help.path()
p = acg.dirs["docs"] .. ":" .. p
help.setPath(p)