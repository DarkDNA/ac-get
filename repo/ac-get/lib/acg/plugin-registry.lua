-- lib-acg plugins registry

PluginRegistry = {}

function PluginRegistry:init(spec)
  self.plugs = {}

  self.spec = spec
end

function PluginRegistry:register(obj)
  local plug = {}

  for name, def in pairs(self.spec) do
    if type(obj[name]) == type(def) then
      plug[name] = obj[name]
    else
      plug[name] = def
    end
  end

  table.insert(self.plugs, plug)
end

function PluginRegistry:iter()
  return ipairs(self.plugs)
end