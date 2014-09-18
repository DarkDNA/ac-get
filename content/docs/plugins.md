---
title: Plugins

v_added: 11
---

Plugins are a new feature in ac-get 11, that allows third parties to define new
package directives. They are *not* designed to allow you to add new commands to
the `ac-get` commandline itself.  


To enable this, there is a new package directive that indicates to ac-get that
it should install the plugin. This directive is `ACG-Plugin`. You should not
attempt to move the plugins around yourself, as the location of the plugins
may change in the future. There is an example plugin located in the
[example repo](/docs/example-repo/) called `example plugin` -- it causes
lib-acg to print "Bacon!" on every state load.  

I look forward to seeing what you guys do with this, and hope to hear from the
community on what they'd like to be able to extend the lib-acg runtime with.  

Plugins are called on the load of lib-acg itself. and they are expected to register themselves like so:

{{% highlight lua %}}
PluginRegistry.state:register({
  load = function()
    print("Hello World!")
  end,
})
{{% /highlight %}}

This will cause anything that loads an ac-get state to print "Hello World!".

The extension points are defined in the plugin-registry.lua file in the source
code.
