-- lib-acg plugins registry
-- lint-mode: ac-get

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
    init = function(pkg) end,
    update = function(pkg) end,
    directives = function(pkg) end,
    install = function(pkg) end,
    remove = function(pkg) end,
    load = function(pkg, details) end,
    save = function(pkg, data) end,
  }),
  state = new(Registry, {
    load = function(state) end,
    save = function(state) end,
    manifest = function(state) end,
    process = function(inp) return inp end,
  }),
  repo = new(Registry, {
    init = function(repo) end,
    update = function(repo) end,
    load = function(repo) end,
    save = function(repo) end,
  }),
}

function PluginRegistry:load()
  for _, plugin in ipairs(fs.list(dirs['libraries'] .. "/acg/plugins/")) do
    dofile(dirs['libraries'] .. '/acg/plugins/' .. plugin)
  end
end

function PluginRegistry:reload()
  for _, plugins in pairs(self) do
    if type(plugins) == "table" then
      plugins.plugs = {}
    end
  end

  self:load()
end
