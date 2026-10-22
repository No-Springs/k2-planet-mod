local sync = require("scripts.sync-extra-resources")

script.on_init(function()
    local opts = {}
    for _, name in ipairs({"iron-ore", "copper-ore", "coal", "stone", "crude-oil", "uranium-ore", "water"}) do
        opts["k2-extra-" .. name] = {value = true}
    end
    sync(nil, opts)
    local mgs = game.surfaces.nauvis.map_gen_settings
    mgs.autoplace_settings.entity = {treat_missing_as_default = false, settings = {}}
    mgs.autoplace_controls["iron-ore"] = {frequency = 2, size = 1.5, richness = 4}
    mgs.autoplace_controls["copper-ore"] = {frequency = 1, size = 0, richness = 1}
    mgs.autoplace_controls["coal"] = nil
    mgs.autoplace_settings.tile = {treat_missing_as_default = false, settings = {['grass-1'] = {}}}
    local surface = game.create_surface("k2-planet", mgs)
    local before = surface.map_gen_settings
    local other = serpent.line(game.surfaces.nauvis.map_gen_settings)
    sync(surface, opts)
    local after = surface.map_gen_settings
    for _, name in ipairs({"iron-ore", "copper-ore", "coal", "stone", "crude-oil", "uranium-ore"}) do
        assert(after.autoplace_settings.entity.settings[name], name .. " missing")
    end
    assert(after.autoplace_controls["iron-ore"].frequency == 2)
    assert(after.autoplace_controls["iron-ore"].size == 1.5)
    assert(after.autoplace_controls["iron-ore"].richness == 4)
    assert(after.autoplace_controls["copper-ore"].size == 0)
    assert(after.autoplace_settings.tile.settings.water)
    assert(after.autoplace_settings.tile.settings.deepwater)
    assert(after.seed == before.seed)
    assert(after.peaceful_mode == before.peaceful_mode)
    assert(after.no_enemies_mode == before.no_enemies_mode)
    assert(serpent.line(after.property_expression_names) == serpent.line(before.property_expression_names))
    assert(serpent.line(game.surfaces.nauvis.map_gen_settings) == other)
    local snapshot = serpent.line(after)
    sync(surface, opts)
    assert(serpent.line(surface.map_gen_settings) == snapshot, "not idempotent")
    for _, setting in pairs(opts) do setting.value = false end
    sync(surface, opts)
    assert(serpent.line(surface.map_gen_settings) == snapshot, "disabled options changed surface")
    surface.request_to_generate_chunks({0, 0}, 8)
    surface.force_generate_chunk_requests()
    assert(surface.count_entities_filtered{name = "iron-ore"} > 0, "no iron generated")
    log("K2 EXTRA RESOURCES TESTS PASSED")
end)
