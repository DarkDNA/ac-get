-- lint-mode: ac-get

-- Example ac-get plugin.

PluginRegistry.state:register({
 load = function(state)
    print("Bacon!")
  end,
})
