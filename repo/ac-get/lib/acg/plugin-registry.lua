-- lib-acg plugins registry

-- This should be private.
local Registry = {}

function Registry:init(spec)
  self.plugs = {}

  self.spec = spec
end

function Registry:register(obj)
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

function Registry:iter()
  return ipairs(self.plugs)
end

-- Output the registry, though.

PluginRegistry = {
  package = new(Registry, {
    init = function() end,
    update = function() end,
    directives = function() end,
    install = function() end,
    remove = function() end,
    load = function() end,
    save = function() end,
  }),
  state = new(Registry, {
    load = function() end,
    save = function() end,
    manifest = function() end,
    process = function(inp) return inp end,
  }),
  repo = new(Registry, {
    init = function() end,
    update = function() end,
    load = function() end,
    save = function() end,
  }),
}

function PluginRegistry:load()
  for _, plugin in ipairs(fs.list(dirs['libraries'] .. "/acg/plugins/")) do
    dofile(dirs['libraries'] .. '/acg/plugins/' .. plugin)
  end
end

function PluginRegistry:reload()
  for _, plugins in pairs(self) do
    plugins.plugs = {}
  end

  self:load()
end