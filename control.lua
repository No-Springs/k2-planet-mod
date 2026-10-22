local sync_extra_resources = require("scripts.sync-extra-resources")
local sync_terrain = require("scripts.sync-terrain")

local function terrain_style()
    return settings.startup["k2-use-old-fulgora-gen"].value
end

script.on_init(function()
    storage.k2_terrain_style = terrain_style()
end)

script.on_configuration_changed(function()
    local desired = terrain_style()
    sync_terrain(game.surfaces["k2-planet"], prototypes.space_location["k2-planet"].map_gen_settings,
        desired, storage.k2_terrain_style, prototypes.entity)
    storage.k2_terrain_style = desired
    sync_extra_resources(game.surfaces["k2-planet"], settings.startup)
end)
