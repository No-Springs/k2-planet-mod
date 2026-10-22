local sync_extra_resources = require("scripts.sync-extra-resources")

script.on_configuration_changed(function()
    sync_extra_resources(game.surfaces["k2-planet"], settings.startup)
end)
