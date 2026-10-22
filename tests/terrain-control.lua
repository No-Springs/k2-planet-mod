local deepcopy = require("util").table.deepcopy
local sync = require("scripts.sync-terrain")
script.on_init(function()
    local violet = game.surfaces.nauvis.map_gen_settings
    violet.autoplace_settings.tile = {treat_missing_as_default = false, settings = {["k2-violet-test"] = {}}}
    violet.autoplace_settings.entity = {treat_missing_as_default = false, settings = {["iron-ore"] = {}}}
    violet.autoplace_settings.decorative = {treat_missing_as_default = false, settings = {}}
    violet.autoplace_controls["iron-ore"] = {frequency = 2, size = 1.5, richness = 4}
    violet.peaceful_mode = true
    local surface = game.create_surface("k2-planet", violet)
    surface.request_to_generate_chunks({0, 0}, 1)
    surface.force_generate_chunk_requests()
    local old_tile = surface.get_tile(0, 0).name
    local fulgora = deepcopy(prototypes.space_location.fulgora.map_gen_settings)
    fulgora.autoplace_settings.tile = {treat_missing_as_default = false, settings = {
        ["fulgoran-rock"] = {}, ["fulgoran-dust"] = {}, ["fulgoran-sand"] = {}, ["fulgoran-dunes"] = {}
    }}
    fulgora.autoplace_settings.entity = {treat_missing_as_default = false, settings = {}}
    fulgora.autoplace_settings.decorative = {treat_missing_as_default = false, settings = {}}
    fulgora.property_expression_names.cliffiness = "0"
    local before = surface.map_gen_settings
    local other = serpent.line(game.surfaces.nauvis.map_gen_settings)
    sync(surface, fulgora, true, nil, prototypes.entity)
    assert(surface.map_gen_settings.seed == before.seed)
    assert(surface.peaceful_mode)
    assert(surface.map_gen_settings.autoplace_controls["iron-ore"].richness == 4)
    assert(surface.map_gen_settings.autoplace_settings.entity.settings["iron-ore"])
    assert(surface.get_tile(0, 0).name == old_tile)
    surface.request_to_generate_chunks({2048, 2048}, 1)
    surface.force_generate_chunk_requests()
    assert(surface.get_tile(2048, 2048).name:match("^fulgoran%-"))
    local snapshot = serpent.line(surface.map_gen_settings)
    sync(surface, fulgora, true, true, prototypes.entity)
    assert(serpent.line(surface.map_gen_settings) == snapshot)
    sync(surface, violet, false, true, prototypes.entity)
    surface.request_to_generate_chunks({4096, 4096}, 1)
    surface.force_generate_chunk_requests()
    assert(surface.get_tile(4096, 4096).name == "k2-violet-test")
    assert(surface.get_tile(2048, 2048).name:match("^fulgoran%-"))
    assert(serpent.line(game.surfaces.nauvis.map_gen_settings) == other)
    sync(nil, fulgora, true, false, prototypes.entity)
    log("K2 TERRAIN TESTS PASSED: violet -> Fulgora -> violet")
end)
