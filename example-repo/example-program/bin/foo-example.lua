-- Foo Example.

os.loadAPI("__LIB__/example")

local f = fs.open("__CFG__/foo-example", "r")

example.print(f.readAll())

f.close()