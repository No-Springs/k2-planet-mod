local nauvis = data.raw.planet.nauvis
local fulgora = data.raw.planet.fulgora
local k2_planet = data.raw.planet["k2-planet"]

if not k2_planet or not nauvis or not fulgora then return end

if settings.startup["k2-use-old-fulgora-gen"] and settings.startup["k2-use-old-fulgora-gen"].value then
    -- ==========================================
    -- RÉGI FULGORA GENERÁTOR (OPCIONÁLIS)
    -- ==========================================
    k2_planet.map_gen_settings = table.deepcopy(fulgora.map_gen_settings)
    k2_planet.lightning_properties = nil

    -- Csak a Fulgora természetes talaja és kövei maradnak: romok, rom-csempék, roncsok (scrap),
    -- olajtenger és növények nélkül. Engedélyező listát használunk, mert Factorio 2.1 óta a listából
    -- hiányzó dolgok alapból megjelennének, és az újabb Space Age verziók új romokat is hoztak.
    local function only_existing(prototype_type, names)
        local result = {}
        for _, name in pairs(names) do
            if data.raw[prototype_type] and data.raw[prototype_type][name] then
                result[name] = {}
            end
        end
        return result
    end

    local autoplace = k2_planet.map_gen_settings.autoplace_settings
    autoplace.tile = {
        treat_missing_as_default = false,
        settings = only_existing("tile", {"fulgoran-rock", "fulgoran-dust", "fulgoran-sand", "fulgoran-dunes"})
    }
    autoplace.decorative = {
        treat_missing_as_default = false,
        settings = only_existing("optimized-decorative", {"medium-fulgora-rock", "small-fulgora-rock", "tiny-fulgora-rock"})
    }
    autoplace.entity = {
        treat_missing_as_default = false,
        settings = only_existing("simple-entity", {"big-fulgora-rock"})
    }

    -- K2 ércek engedélyezése a Fulgora alapon is
    autoplace.entity.settings["kr-mineral-water"] = {}
    autoplace.entity.settings["kr-imersite"] = {}
    autoplace.entity.settings["kr-rare-metal-ore"] = {}

    k2_planet.map_gen_settings.autoplace_controls["scrap"] = nil
    k2_planet.map_gen_settings.autoplace_controls["fulgurite"] = nil

    k2_planet.map_gen_settings.autoplace_controls["kr-mineral-water"]  = { frequency = 2.0, size = 1.5, richness = 1.5 }
    k2_planet.map_gen_settings.autoplace_controls["kr-imersite"]       = { frequency = 2.0, size = 1.5, richness = 1.5 }
    k2_planet.map_gen_settings.autoplace_controls["kr-rare-metal-ore"] = { frequency = 2.0, size = 1.5, richness = 1.5 }

    k2_planet.map_gen_settings.property_expression_names = k2_planet.map_gen_settings.property_expression_names or {}
    k2_planet.map_gen_settings.property_expression_names["cliffiness"] = "0"
    if k2_planet.map_gen_settings.cliff_settings then
        k2_planet.map_gen_settings.cliff_settings.cliff_elevation_0 = 1024
    end

else
    -- ==========================================
    -- MOSTANI LILA SIVATAG GENERÁTOR (ALAPÉRTELMEZETT)
    -- ==========================================
    k2_planet.map_gen_settings = table.deepcopy(nauvis.map_gen_settings)

    local k2_tile_settings = {}
    for tile_name, _ in pairs(data.raw.tile) do
        if string.find(tile_name, "^k2%-violet%-") then
            k2_tile_settings[tile_name] = {}
        end
    end

    k2_planet.map_gen_settings.autoplace_settings.tile = {
        treat_missing_as_default = false,
        settings = k2_tile_settings
    }

    k2_planet.map_gen_settings.autoplace_settings.entity = {
        treat_missing_as_default = false, 
        settings = {
            ["kr-mineral-water"] = {},
            ["kr-imersite"] = {},
            ["kr-rare-metal-ore"] = {}
        }
    }

    k2_planet.map_gen_settings.autoplace_controls = {
        ["kr-mineral-water"]  = { frequency = 2.0, size = 1.5, richness = 1.5 },
        ["kr-imersite"]       = { frequency = 2.0, size = 1.5, richness = 1.5 },
        ["kr-rare-metal-ore"] = { frequency = 2.0, size = 1.5, richness = 1.5 }
    }

    k2_planet.map_gen_settings.autoplace_settings.decorative = {
        treat_missing_as_default = false,
        settings = {}
    }

    -- Lila kövek, sziklák és dűnék engedélyezése (a prototypes/decoratives.lua hozza létre őket)
    k2_planet.map_gen_settings.autoplace_controls["rocks"] = {}
    for _, deco in pairs(k2_planet_decoratives or {}) do
        local kind = deco.type == "simple-entity" and "entity" or "decorative"
        k2_planet.map_gen_settings.autoplace_settings[kind].settings[deco.name] = {}
    end

    k2_planet.map_gen_settings.property_expression_names = k2_planet.map_gen_settings.property_expression_names or {}
    k2_planet.map_gen_settings.property_expression_names["cliffiness"] = "0"
end

-- ==========================================
-- PLUSZ NYERSANYAGOK A K2 BOLYGÓN (beállításokból, alapból egyik sincs bekapcsolva)
-- ==========================================
local extra_resources = {"iron-ore", "copper-ore", "coal", "stone", "crude-oil", "uranium-ore"}
for _, resource in pairs(extra_resources) do
    if settings.startup["k2-extra-" .. resource].value and data.raw.resource[resource] then
        k2_planet.map_gen_settings.autoplace_settings.entity.settings[resource] = {}
        k2_planet.map_gen_settings.autoplace_controls[resource] = {}
    end
end

-- Víz: tavak a mélyebb részeken (a "Water" csúszkával a térképbeállításoknál állítható)
if settings.startup["k2-extra-water"].value then
    for _, tile_name in pairs({"water", "deepwater"}) do
        if data.raw.tile[tile_name] then
            k2_planet.map_gen_settings.autoplace_settings.tile.settings[tile_name] = {}
        end
    end
    if data.raw["autoplace-control"]["water"] then
        k2_planet.map_gen_settings.autoplace_controls["water"] = {}
    end
end

-- ==========================================
-- K2 ÉRCEK KEZELÉSE A NAUVIS (FÖLD) BOLYGÓN
-- ==========================================
local ores_to_remove = { "kr-imersite", "kr-mineral-water" }

if not settings.startup["k2-allow-nauvis-rare-metals"].value then
    table.insert(ores_to_remove, "kr-rare-metal-ore")
end

for _, resource in ipairs(ores_to_remove) do
    local res_entity = data.raw.resource[resource]
    if res_entity and res_entity.autoplace then
        res_entity.autoplace.default_enabled = false
    end
    
    if nauvis.map_gen_settings.autoplace_controls then
        nauvis.map_gen_settings.autoplace_controls[resource] = nil
    end
    if nauvis.map_gen_settings.autoplace_settings.entity and nauvis.map_gen_settings.autoplace_settings.entity.settings then
        nauvis.map_gen_settings.autoplace_settings.entity.settings[resource] = nil
    end
end