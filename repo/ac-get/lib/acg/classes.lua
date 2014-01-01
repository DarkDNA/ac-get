function new(cls, ...)
	local ret = {}

	for k, v in pairs(cls) do
		if type(v) == 'function' then
			ret[k] = v
		end
	end

	if ret.init ~= nil then
		ret:init(...)
	end

	return ret
end