require("prototypes.worldgen-final-fixes")

-- ==========================================
-- 1. TECHNOLÓGIAI FÁK ÖSSZEKÖTÉSE
-- ==========================================
local k2_planet_tech = data.raw.technology["planet-discovery-k2-planet"]
if k2_planet_tech then 
    k2_planet_tech.prerequisites = {"space-platform-thruster"} 
end

local quarry_techs = {"kr-quarry-minerals-extraction", "kr-quarry"}
for _, tech_name in pairs(quarry_techs) do
    local tech = data.raw.technology[tech_name]
    if tech then 
        tech.prerequisites = {"planet-discovery-k2-planet"}
    end
end

-- ==========================================
-- 2. K2 BOLYGÓ FELSZÍN TULAJDONSÁG
-- (Ez teszi lehetővé, hogy a recepteket a bolygóhoz kössük)
-- ==========================================
if not data.raw["surface-property"]["is-k2-planet"] then
    data:extend({
        { type = "surface-property", name = "is-k2-planet", hidden = true, default_value = 0 }
    })
end

local k2_planet_data = data.raw.planet["k2-planet"]
if k2_planet_data then
    k2_planet_data.surface_properties = k2_planet_data.surface_properties or {}
    k2_planet_data.surface_properties["is-k2-planet"] = 1
end

-- ==========================================
-- 2/B. ÉRKEZÉSI ANIMÁCIÓK ÉS A PLATFORM ALATT LÁTSZÓ BOLYGÓ
-- A Space Age ezeket csak a data-updates fázisban állítja be, ezért itt másoljuk át őket.
-- A platform alatt eddig a Nauvis látszott; most a K2 saját (a Fulgoráéból lilára színezett)
-- felszíne forog alatta, a Fulgora viharos, villámló felhőivel, de olajtenger-csillogás nélkül.
-- ==========================================
local nauvis_planet = data.raw.planet["nauvis"]
local fulgora_planet = data.raw.planet["fulgora"]
if k2_planet_data and nauvis_planet and fulgora_planet then
    k2_planet_data.planet_procession_set = table.deepcopy(nauvis_planet.planet_procession_set)
    k2_planet_data.platform_procession_set = table.deepcopy(nauvis_planet.platform_procession_set)
    k2_planet_data.procession_graphic_catalogue = table.deepcopy(nauvis_planet.procession_graphic_catalogue)

    if fulgora_planet.platform_surface_render_parameters then
        k2_planet_data.platform_surface_render_parameters = table.deepcopy(fulgora_planet.platform_surface_render_parameters)
        local backdrop = k2_planet_data.platform_surface_render_parameters.platform_backdrop
        if backdrop then
            backdrop.planet_surface = {
                filename = "__k2-planet-mod__/graphics/k2-planet-surface.png",
                width = 2048,
                height = 1024
            }
            backdrop.planet_reflectivity = nil
            backdrop.specular_intensity = 0
            backdrop.atmosphere_color = {0.075, 0.05, 0.085, 0.1}
        end
    end
end

-- ==========================================
-- 3. RECEPTEK KORLÁTOZÁSA K2 BOLYGÓRA
-- "Hol lehet gyártani" beállítás:
--   nauvis   = semmi sincs a K2-höz kötve
--   mixed    = az alábbi lista a K2-höz kötve
--   imersite = mint a mixed, plusz minden imersite-ot használó recept (lásd a fájl végén, 7. rész)
-- ==========================================
local production_location = settings.startup["k2-production-location"].value

local function restrict_recipe_to_k2(recipe_name)
    local recipe = data.raw.recipe[recipe_name]
    if recipe then
        recipe.surface_conditions = recipe.surface_conditions or {}
        for _, condition in pairs(recipe.surface_conditions) do
            if condition.property == "is-k2-planet" then return end -- már korlátozva van
        end
        table.insert(recipe.surface_conditions, { property = "is-k2-planet", min = 1, max = 1 })
    end
end

-- A vegyes módban a K2 bolygóhoz kötött receptek
local k2_only_recipes = {
    -- Kőfejtő és az anyaggyár K2-nyersanyagos receptjei
    "kr-quarry-drill",
    "kr-matter-to-kr-rare-metal-ore", "kr-matter-to-kr-rare-metals",
    "kr-matter-to-kr-imersite-powder", "kr-matter-to-kr-mineral-water",
    -- Superior (lila) logisztika
    "kr-superior-transport-belt", "kr-superior-underground-belt",
    "kr-superior-splitter", "kr-superior-loader",
    -- Fejlett technológiai kártya és a hűtött változata
    "kr-advanced-tech-card", "kr-advanced-tech-card-cooling",
}

if production_location ~= "nauvis" then
    for _, recipe_name in pairs(k2_only_recipes) do
        restrict_recipe_to_k2(recipe_name)
    end
end

-- ==========================================
-- 4. FÖLDI RECEPTEK MENTESÍTÉSE RITKAFÉMEKTŐL
-- ==========================================
if settings.startup["k2-remove-nauvis-rare-metals"] and settings.startup["k2-remove-nauvis-rare-metals"].value then
    local nauvis_recipes = { "processing-unit", "nuclear-reactor", "kr-nuclear-locomotive", "kr-electric-mining-drill-mk2" }
    for _, recipe_name in pairs(nauvis_recipes) do
        local recipe = data.raw.recipe[recipe_name]
        if recipe and recipe.ingredients then
            for i = #recipe.ingredients, 1, -1 do
                local ingredient = recipe.ingredients[i]
                local name = ingredient.name or ingredient
                if name == "kr-rare-metals" or name == "rare-metals" then
                    table.remove(recipe.ingredients, i)
                end
            end
        end
    end
end

-- ==========================================
-- 4/B. ELAKADÁS ELLENI VÉDELEM
-- A K2 "Rare metal processing" technológiája csak ritkafémérc bányászásával kutatható, de erre épül a
-- kék áramkör, az atomenergia és (K2SO-ban) a hajtómű is, ami kell a K2 eléréséhez. Ha a Nauvison
-- nincs ritkafém, ez sima kutatás lesz, ugyanakkora áron, mint az előtte lévő "Rare metal mining".
-- ==========================================
if not settings.startup["k2-allow-nauvis-rare-metals"].value then
    local processing_tech = data.raw.technology["kr-rare-metal-processing"]
    local mining_tech = data.raw.technology["kr-rare-metal-mining"]
    if processing_tech and processing_tech.research_trigger then
        processing_tech.research_trigger = nil
        processing_tech.unit = (mining_tech and table.deepcopy(mining_tech.unit)) or {
            count = 50,
            time = 30,
            ingredients = {
                {"automation-science-pack", 1},
                {"logistic-science-pack", 1},
                {"chemical-science-pack", 1}
            }
        }
    end
end

-- ==========================================
-- 5. ÚJ RECEPTEK LÉTREHOZÁSA
-- ==========================================
local adv_imersite_processing = {
    type = "recipe",
    name = "k2-advanced-imersite-processing",
    categories = {"kr-advanced-chemistry"},
    subgroup = "raw-material",
    energy_required = 10,
    enabled = false,
    icons = {
        { icon = "__Krastorio2Assets__/icons/items/imersite-powder.png", icon_size = 64 },
        { icon = "__Krastorio2Assets__/icons/fluids/nitric-acid.png", icon_size = 64, scale = 0.30, shift = {-8, 8} },
        { icon = "__base__/graphics/icons/fluid/steam.png", icon_size = 64, scale = 0.30, shift = {8, 8} }
    },
    ingredients = {
        {type = "item", name = "kr-imersite", amount = 10},
        {type = "fluid", name = "kr-nitric-acid", amount = 50},
        {type = "fluid", name = "steam", amount = 50}
    },
    results = {
        {type = "item", name = "kr-imersite-powder", amount = 10},
        {type = "item", name = "kr-rare-metal-ore", amount_min = 1, amount_max = 3},
        {type = "fluid", name = "kr-dirty-water", amount = 50}
    },
    allow_productivity = true,
}

local mineral_water_filtration = {
    type = "recipe",
    name = "k2-filter-mineral-water",
    categories = {"kr-fluid-filtration"},
    subgroup = "raw-material",
    order = "w014[filter-mineral-water]",
    energy_required = 2,
    enabled = false,
    -- Réteges ikon: víz a háttérben, kis ásványi víz a bal felső sarokban (különben sima víz ikont kapna)
    icons = {
        { icon = "__base__/graphics/icons/fluid/water.png", icon_size = 64 },
        { icon = "__Krastorio2Assets__/icons/fluids/mineral-water.png", icon_size = 64, scale = 0.30, shift = {-8, -8} }
    },
    ingredients = { { type = "fluid", name = "kr-mineral-water", amount = 100 } },
    results = { { type = "fluid", name = "water", amount = 100 } }
}

data:extend({adv_imersite_processing, mineral_water_filtration})

-- ==========================================
-- 6. RECEPTEK FELOLDÁSA A TECHNOLÓGIÁKNÁL
-- ==========================================
for _, tech in pairs(data.raw.technology) do
    if tech.effects then
        local unlocks_advanced_plant = false
        for _, effect in pairs(tech.effects) do
            if effect.type == "unlock-recipe" and effect.recipe == "kr-advanced-chemical-plant" then
                unlocks_advanced_plant = true
                break
            end
        end
        if unlocks_advanced_plant then
            table.insert(tech.effects, { type = "unlock-recipe", recipe = "k2-advanced-imersite-processing" })
        end
    end
end

local dirty_water_tech = data.raw.technology["kr-enriched-ores"]
if dirty_water_tech then
    dirty_water_tech.effects = dirty_water_tech.effects or {}
    local found = false
    for _, effect in pairs(dirty_water_tech.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == "k2-filter-mineral-water" then
            found = true
        end
    end
    if not found then
        table.insert(dirty_water_tech.effects, { type = "unlock-recipe", recipe = "k2-filter-mineral-water" })
    end
end
-- ==========================================
-- 7. IMERSITE-OT HASZNÁLÓ RECEPTEK A K2 BOLYGÓRA
-- (csak ha a "Hol lehet gyártani" beállítás "imersite"; a fájl végén, hogy a saját receptjeink is benne legyenek)
-- ==========================================
if production_location == "imersite" then
    local imersite_items = {
        ["kr-imersite"] = true,
        ["kr-imersite-powder"] = true,
        ["kr-imersite-crystal"] = true,
    }

    local function is_recycling(recipe)
        if recipe.category == "recycling" then return true end
        for _, category in pairs(recipe.categories or {}) do
            if category == "recycling" then return true end
        end
        return false
    end

    for recipe_name, recipe in pairs(data.raw.recipe) do
        if not recipe.parameter and not is_recycling(recipe) then
            for _, ingredient in pairs(recipe.ingredients or {}) do
                if imersite_items[ingredient.name] then
                    restrict_recipe_to_k2(recipe_name)
                    break
                end
            end
        end
    end
end
