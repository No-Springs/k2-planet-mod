-- ==========================================
-- LILA KÖVEK, SZIKLÁK ÉS DŰNÉK A K2 BOLYGÓRA
-- A vanilla sivatagi dekorációkat lemásoljuk, és saját elhelyezési szabályt adunk nekik
-- (foltokban sűrűsödnek, köztük üresebb a sivatag). Csak a K2 bolygón jelennek meg.
-- Ha az alien-biomes-graphics be van kapcsolva (lila sivatag), annak szürke köveit lilára színezzük,
-- és a kész lila dűnéit használjuk. Nélküle a csempék is vanilla színűek, így a kövek is maradnak.
-- ==========================================
local use_alien_biomes = mods["alien-biomes-graphics"] ~= nil

-- Ugyanaz a lila árnyalat, amit az Alien Biomes a saját "violet" köveihez használ
local violet_tint = {r = 165/255, g = 107/255, b = 161/255, a = 1}

-- Foltos zaj (nagyjából -2 és 2 között): ahol nagyobb, ott több a kő és a dűne
data:extend({
    {
        type = "noise-expression",
        name = "k2_decor_noise",
        expression = "multioctave_noise{x = x, y = y, persistence = 0.6, seed0 = map_seed, seed1 = 7341, octaves = 3, input_scale = 1/48}"
    }
})

-- chance: esély csempénként a legsűrűbb foltokban (a "Rocks" csúszkával a térképbeállításoknál állítható)
-- threshold: minél nagyobb, annál ritkább foltokban jelenik meg
-- imersite: ennyi nyers imersite-ot ad a szikla a kő mellé, ha kibányásszák (legkevesebb, legtöbb)
-- A sorrend számít: a játék fentről lefelé haladva rakja le őket (előbb a nagy sziklák, a végén a talajminták)
local decoratives = {
    -- Nagy sziklák (bányászhatók, követ és egy kis imersite-ot adnak)
    {type = "simple-entity",        name = "huge-rock",        chance = 0.002, threshold = 0.8, imersite = {5, 10}},
    {type = "simple-entity",        name = "big-rock",         chance = 0.003, threshold = 0.5, imersite = {2, 5}},
    {type = "simple-entity",        name = "big-sand-rock",    chance = 0.004, threshold = 0.2, imersite = {1, 3}},
    -- Kisebb kövek (át lehet rajtuk sétálni)
    {type = "optimized-decorative", name = "medium-rock",      chance = 0.010, threshold = 0.4},
    {type = "optimized-decorative", name = "medium-sand-rock", chance = 0.010, threshold = 0.4},
    {type = "optimized-decorative", name = "small-rock",       chance = 0.020, threshold = 0.0},
    {type = "optimized-decorative", name = "small-sand-rock",  chance = 0.020, threshold = 0.0},
    {type = "optimized-decorative", name = "tiny-rock",        chance = 0.040, threshold = -0.5},
    -- Talajmintázatok (dűnék, homokfoltok)
    {type = "optimized-decorative", name = "sand-decal",       chance = 0.030, threshold = 0.0},
    {type = "optimized-decorative", name = "sand-dune-decal",  chance = 0.030, threshold = -0.3},
}

-- Vanilla kép -> Alien Biomes kép. Igaz = szürke kép, ezt lilára kell színezni.
local alien_biomes_paths = {
    {"__base__/graphics/decorative/sand%-dune%-decal/", "__alien-biomes-graphics__/graphics/decorative/dune/violet/sand-dune-decal/", false},
    {"__base__/graphics/decorative/sand%-rock/(%a+)%-sand%-rock%-", "__alien-biomes-graphics__/graphics/decorative/sand-rock/sand-%1-rock-", true},
    {"__base__/graphics/decorative/([%a%-]+)/", "__alien-biomes-graphics__/graphics/decorative/%1/", true},
}

local function to_alien_biomes(sprite)
    for _, path in pairs(alien_biomes_paths) do
        local new_filename, found = string.gsub(sprite.filename, path[1], path[2])
        if found > 0 then
            sprite.filename = new_filename
            if path[3] and not sprite.draw_as_shadow then
                sprite.tint = violet_tint
            end
            return
        end
    end
end

local function convert_pictures(node)
    if type(node) ~= "table" then return end
    if type(node.filename) == "string" then
        to_alien_biomes(node)
    end
    for _, child in pairs(node) do
        convert_pictures(child)
    end
end

-- A worldgen-final-fixes.lua ebből a listából engedélyezi őket a K2 bolygón
k2_planet_decoratives = {}

for i, deco in pairs(decoratives) do
    local original = data.raw[deco.type][deco.name]
    if original then
        local copy = table.deepcopy(original)
        copy.name = "k2-violet-" .. deco.name
        copy.localised_name = {(deco.type == "simple-entity" and "entity-name." or "decorative-name.") .. deco.name}

        if use_alien_biomes then
            convert_pictures(copy.pictures)
            if copy.icon then
                copy.icons = {{icon = copy.icon, icon_size = copy.icon_size, tint = violet_tint}}
                copy.icon = nil
            end
        end
        if copy.map_color then
            copy.map_color = {r = 125, g = 85, b = 130}
        end
        if copy.deconstruction_alternative then
            copy.deconstruction_alternative = "k2-violet-" .. copy.deconstruction_alternative
        end

        -- Imersite a kő mellé (a régi "result/count" formát is átalakítjuk "results" listára)
        if deco.imersite and copy.minable and data.raw.item["kr-imersite"] then
            local minable = copy.minable
            if not minable.results then
                minable.results = {{type = "item", name = minable.result, amount = minable.count or 1}}
                minable.result = nil
                minable.count = nil
            end
            table.insert(minable.results, {type = "item", name = "kr-imersite", amount_min = deco.imersite[1], amount_max = deco.imersite[2]})
        end

        -- Minden fajta saját sorrendet (order) kap, különben azonos sorrendnél egy helyre csak egy
        -- kerülne. A saját zaj (own) miatt pedig a fajták nem pont ugyanott sűrűsödnek.
        copy.autoplace = {
            control = "rocks",
            order = string.format("a[k2-violet]-%02d", i),
            default_enabled = false, -- így más bolygókon (pl. Nauvis) nem jelenik meg
            probability_expression = "chance * control:rocks:size * clamp(k2_decor_noise - threshold, 0, 1) * clamp(0.5 + own, 0, 1)",
            local_expressions = {
                chance = deco.chance,
                threshold = deco.threshold,
                own = "multioctave_noise{x = x, y = y, persistence = 0.5, seed0 = map_seed, seed1 = " .. (7400 + i) .. ", octaves = 2, input_scale = 1/24}"
            }
        }

        data:extend({copy})
        table.insert(k2_planet_decoratives, {type = deco.type, name = copy.name})
    end
end
