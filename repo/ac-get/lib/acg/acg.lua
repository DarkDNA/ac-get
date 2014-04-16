VERSION = 0

dirs = {}

if not fs.exists('__LIB__/acg/dirs') then
	error("Invalid state.")
end

local f = fs.open('__LIB__/acg/dirs', 'r')

for k, v in pairs(textutils.unserialize(f.readAll())) do
	dirs[k] = v
end

f.close()

for _, fname in ipairs(fs.list(dirs['libraries'] .. '/acg/')) do
	if fname ~= 'acg' and fname ~= 'dirs' then
		dofile(dirs['libraries'] .. '/acg/' .. fname)
	end
end