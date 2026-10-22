local util = require("util")
local nauvis = data.raw.planet.nauvis
local fulgora = data.raw.planet.fulgora

-- ==========================================
-- 1. EGYEDI VÁLTOZATOS IBOLYA CSEMPÉK (TILES) LÉTREHOZÁSA
-- ==========================================
local function replace_filenames(table_node, old_string, new_string)
    for k, v in pairs(table_node) do
        if type(v) == "table" then
            replace_filenames(v, old_string, new_string)
        elseif type(v) == "string" and (k == "picture" or k == "filename" or k == "spritesheet") then
            table_node[k] = string.gsub(v, old_string, new_string)
        end
    end
end

-- map_color: minden csempe kicsit más lila árnyalatot kap, hogy a térkép ne egy egyszínű folt legyen
-- (homok = világosabb, föld = közepes, "fű" = sötétebb, vörös sivatag = vöröses lila)
local tile_mapping = {
    {vanilla = "grass-1", alien = "mineral-violet-dirt-1", new = "k2-violet-grass-1", map_color = {r = 104, g = 58, b = 112}},
    {vanilla = "grass-2", alien = "mineral-violet-dirt-2", new = "k2-violet-grass-2", map_color = {r = 98, g = 54, b = 106}},
    {vanilla = "grass-3", alien = "mineral-violet-dirt-3", new = "k2-violet-grass-3", map_color = {r = 92, g = 50, b = 100}},
    {vanilla = "grass-4", alien = "mineral-violet-dirt-4", new = "k2-violet-grass-4", map_color = {r = 86, g = 46, b = 94}},

    {vanilla = "dirt-1", alien = "mineral-violet-dirt-5", new = "k2-violet-dirt-1", map_color = {r = 118, g = 70, b = 118}},
    {vanilla = "dirt-2", alien = "mineral-violet-dirt-6", new = "k2-violet-dirt-2", map_color = {r = 114, g = 66, b = 114}},
    {vanilla = "dirt-3", alien = "mineral-violet-dirt-1", new = "k2-violet-dirt-3", map_color = {r = 110, g = 63, b = 111}},
    {vanilla = "dirt-4", alien = "mineral-violet-dirt-2", new = "k2-violet-dirt-4", map_color = {r = 106, g = 60, b = 108}},
    {vanilla = "dirt-5", alien = "mineral-violet-dirt-3", new = "k2-violet-dirt-5", map_color = {r = 112, g = 62, b = 106}},
    {vanilla = "dirt-6", alien = "mineral-violet-dirt-4", new = "k2-violet-dirt-6", map_color = {r = 108, g = 59, b = 102}},
    {vanilla = "dirt-7", alien = "mineral-violet-dirt-5", new = "k2-violet-dirt-7", map_color = {r = 116, g = 68, b = 112}},
    {vanilla = "dry-dirt", alien = "mineral-violet-dirt-6", new = "k2-violet-dry-dirt", map_color = {r = 122, g = 74, b = 116}},

    {vanilla = "sand-1", alien = "mineral-violet-sand-1", new = "k2-violet-sand-1", map_color = {r = 146, g = 98, b = 142}},
    {vanilla = "sand-2", alien = "mineral-violet-sand-2", new = "k2-violet-sand-2", map_color = {r = 138, g = 91, b = 135}},
    {vanilla = "sand-3", alien = "mineral-violet-sand-3", new = "k2-violet-sand-3", map_color = {r = 130, g = 84, b = 128}},
    {vanilla = "red-desert-0", alien = "mineral-violet-sand-1", new = "k2-violet-red-desert-0", map_color = {r = 134, g = 72, b = 108}},
    {vanilla = "red-desert-1", alien = "mineral-violet-sand-2", new = "k2-violet-red-desert-1", map_color = {r = 126, g = 66, b = 102}},
    {vanilla = "red-desert-2", alien = "mineral-violet-sand-3", new = "k2-violet-red-desert-2", map_color = {r = 118, g = 61, b = 96}},
    {vanilla = "red-desert-3", alien = "mineral-violet-dirt-6", new = "k2-violet-red-desert-3", map_color = {r = 110, g = 56, b = 90}},
}

local k2_tiles = {}

for _, map in pairs(tile_mapping) do
    if data.raw.tile[map.vanilla] then
        local new_tile = table.deepcopy(data.raw.tile[map.vanilla])
        new_tile.name = map.new

        if new_tile.variants and new_tile.variants.main then
            for i = #new_tile.variants.main, 1, -1 do
                local variant = new_tile.variants.main[i]
                if variant.size and variant.size >= 8 then
                    table.remove(new_tile.variants.main, i)
                end
            end
        end
        if new_tile.variants then
            new_tile.variants.material_background = nil
        end

        if mods["alien-biomes-graphics"] then
            local escaped_vanilla = string.gsub(map.vanilla, "%-", "%%-")
            replace_filenames(new_tile.variants, "__base__/graphics/terrain/" .. escaped_vanilla, "__alien-biomes-graphics__/graphics/terrain/" .. map.alien)
        end

        new_tile.map_color = map.map_color

        if new_tile.layer and new_tile.layer < 0 then
            new_tile.layer = 8
        end

        table.insert(k2_tiles, new_tile)
    end
end

data:extend(k2_tiles)

-- Lila kövek, sziklák és dűnék (részletek a prototypes/decoratives.lua fájlban)
require("prototypes.decoratives")

-- ==========================================
-- 2. K2 BOLYGÓ ALAP DEFINÍCIÓJA ÉS POZÍCIÓJA
-- ==========================================
local k2_distance = 18
local k2_orientation = 0.28

-- A data.lua fázisban az alap bolygók távolsága a gyökérben van, így onnan olvassuk ki őket!
if nauvis and fulgora and nauvis.distance and fulgora.distance then
    -- TÁVOLSÁG: Hajszálpontosan egyenlő távolságra (félútra) Nauvis és Fulgora között
    k2_distance = (nauvis.distance + fulgora.distance) / 2
    
    -- VIZUÁLIS ELHELYEZKEDÉS: +0.05-öt adunk az átlagos orientációhoz, ami lefelé tolja a térképen
    k2_orientation = ((nauvis.orientation + fulgora.orientation) / 2) + 0.05
end

-- Imersite-Asteroids kompatibilitás: minden fém (metallic) aszteroida mellé kerül egy dupla
-- esélyű imersite aszteroida. Működik az útvonalak (spawn_points) és a bolygópálya (probability) listáira is.
local function add_imersite_asteroids(asteroid_list)
    if not mods["Imersite-Asteroids"] then return asteroid_list end

    local imersite_asteroids = {}
    for _, ast in pairs(asteroid_list) do
        if ast.asteroid and string.find(ast.asteroid, "metallic") then
            local new_ast = table.deepcopy(ast)
            new_ast.asteroid = string.gsub(new_ast.asteroid, "metallic", "imersite")

            -- Megduplázzuk a spawnolási esélyüket
            if new_ast.probability then
                new_ast.probability = new_ast.probability * 2.0
            end
            for _, point in pairs(new_ast.spawn_points or {}) do
                point.probability = point.probability * 2.0
            end

            table.insert(imersite_asteroids, new_ast)
        end
    end

    for _, ast in pairs(imersite_asteroids) do
        table.insert(asteroid_list, ast)
    end
    return asteroid_list
end

-- Aszteroidák a bolygó körüli (parkoló) pályán: a Nauvis-közeli és a Fulgora-közeli értékek átlaga
-- a Nauvis-Fulgora útvonalról (a Space Age csak ezeken a pontokon tud bolygóértéket számolni)
local asteroid_util = require("__space-age__.prototypes.planet.asteroid-spawn-definitions")

local function k2_orbit_asteroids()
    local merged, order = {}, {}
    for _, position in pairs({0.1, 0.9}) do
        for _, ast in pairs(asteroid_util.spawn_definitions(asteroid_util.nauvis_fulgora, position)) do
            if not merged[ast.asteroid] then
                merged[ast.asteroid] = table.deepcopy(ast)
                merged[ast.asteroid].probability = 0
                table.insert(order, ast.asteroid)
            end
            merged[ast.asteroid].probability = merged[ast.asteroid].probability + ast.probability / 2
        end
    end

    local result = {}
    for _, name in pairs(order) do
        table.insert(result, merged[name])
    end
    return result
end

local k2_planet = {
    type = "planet",
    name = "k2-planet",
    -- Kis (64px, mipmapes) ikon a menükhöz, a nagy 512px-es kép csak a csillagtérképre kell
    icon = "__k2-planet-mod__/graphics/k2-planet-icon.png",
    icon_size = 64,
    label_orientation = 0.55,
    starmap_icon = "__k2-planet-mod__/graphics/k2-planet.png",
    starmap_icon_size = 512,
    magnitude = nauvis.magnitude,
    subgroup = "planets",
    -- Sorrend a Factoriopédiában és a listákban: Gleba (c) után, Fulgora (d) előtt
    order = "d-a[k2-planet]",
    gravity_pull = 10,

    -- A Factorio alapmotorja kötelezően elvárja, hogy ezek a gyökérben is ott legyenek!
    distance = k2_distance,
    orientation = k2_orientation,
    
    -- A kiegészítő modok és az űrbeli napelem számítás miatt az 'orbit' tábla
    orbit = {
        parent = { type = "space-location", name = "star" },
        distance = k2_distance,
        orientation = k2_orientation
    },

    -- Ha ez a mező nincs megadva, alapértelmezetten 1 (azaz 1%)! Ez adja meg a
    -- napelemek teljesítményét a bolygó KÖRÜLI ŰRBEN (space platform pályán),
    -- külön a surface_properties["solar-power"]-től, ami a felszínre vonatkozik.
    solar_power_in_space = 200,

    surface_properties = {
        ["solar-power"] = 150,
        ["pressure"] = nauvis.surface_properties["pressure"],
        ["magnetic-field"] = nauvis.surface_properties["magnetic-field"],
        ["day-night-cycle"] = nauvis.surface_properties["day-night-cycle"],
        ["gravity"] = 10,
    },
    map_gen_settings = table.deepcopy(nauvis.map_gen_settings),
    pollutant_type = "pollution",

    -- Aszteroidák a bolygó körüli pályán, hogy egy itt parkoló űrplatform is tudjon aszteroidát gyűjteni
    asteroid_spawn_influence = 1,
    asteroid_spawn_definitions = add_imersite_asteroids(k2_orbit_asteroids()),

    -- Felhők a felszínen: a Nauvisé
    -- (az érkezési animációkat és a platform alatti bolygóképet a data-final-fixes.lua állítja be)
    surface_render_parameters = table.deepcopy(nauvis.surface_render_parameters),

    -- Háttérhangok: a Fulgora szeles, mennydörgős hangjai illenek a viharos sivataghoz
    persistent_ambient_sounds = table.deepcopy(fulgora.persistent_ambient_sounds),
}

-- ==========================================
-- 3. ŰRKAPCSOLATOK (ÚTVONALAK) LÉTREHOZÁSA
-- ==========================================

-- Lemásoljuk a Vanilla aszteroida generálási szabályokat a Föld és Fulgora közül
-- (Imersite-Asteroids esetén dupla esélyű imersite aszteroidákkal kiegészítve)
local base_asteroids = add_imersite_asteroids(table.deepcopy(data.raw["space-connection"]["nauvis-fulgora"].asteroid_spawn_definitions))

-- Útvonal: Nauvis -> K2
local k2_connection_1 = {
    type = "space-connection",
    name = "nauvis-k2-planet",
    from = "nauvis",
    to = "k2-planet",
    subgroup = data.raw["space-connection"]["nauvis-fulgora"].subgroup,
    length = 10000, 
    asteroid_spawn_definitions = table.deepcopy(base_asteroids)
}

-- Útvonal: K2 -> Fulgora
local k2_connection_2 = {
    type = "space-connection",
    name = "k2-planet-fulgora",
    from = "k2-planet",
    to = "fulgora",
    subgroup = data.raw["space-connection"]["nauvis-fulgora"].subgroup,
    length = 10000,
    asteroid_spawn_definitions = table.deepcopy(base_asteroids)
}

data:extend({
    k2_planet,
    k2_connection_1,
    k2_connection_2,
    {
        type = "technology",
        name = "planet-discovery-k2-planet",
        -- 256px-es technológia ikon a vanilla bolygó-szimbólummal a sarkában (mint a Fulgoránál)
        icons = util.technology_icon_constant_planet("__k2-planet-mod__/graphics/k2-planet-technology.png"),
        essential = true,
        effects = {
            { type = "unlock-space-location", space_location = "k2-planet", use_icon_overlay_constant = true },
        },
        prerequisites = { "space-science-pack" },
        unit = {
            count = 1000,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1},
                {"space-science-pack", 1}
            },
            time = 60,
        },
        order = "ea[k2-planet]",
    }
})