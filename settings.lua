data:extend({
    -- ==========================================
    -- HOL LEHET GYÁRTANI A K2 DOLGAIT
    -- nauvis   = semmi sincs a K2 bolygóhoz kötve (csak a nyersanyagok vannak ott)
    -- mixed    = a kőfejtő, az anyaggyár K2-receptjei, a Superior logisztika és a fejlett tech kártya a K2-n
    -- imersite = a vegyes megoldás + minden recept, ami imersite-ot használ
    -- ==========================================
    {
        type = "string-setting",
        name = "k2-production-location",
        setting_type = "startup",
        default_value = "mixed",
        allowed_values = {"nauvis", "mixed", "imersite"},
        order = "0"
    },
    {
        type = "bool-setting",
        name = "k2-remove-nauvis-rare-metals",
        setting_type = "startup",
        default_value = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = "k2-allow-nauvis-rare-metals",
        setting_type = "startup",
        default_value = true,
        order = "e"
    },
    -- ==========================================
    -- ÚJ BEÁLLÍTÁS: RÉGI FULGORA GENERÁLÁS
    -- ==========================================
    {
        type = "bool-setting",
        name = "k2-use-old-fulgora-gen",
        setting_type = "startup",
        default_value = false,
        order = "f"
    }
})

-- ==========================================
-- PLUSZ NYERSANYAGOK A K2 BOLYGÓN (alapból mind ki van kapcsolva)
-- ==========================================
local extra_resources = {"water", "iron-ore", "copper-ore", "coal", "stone", "crude-oil", "uranium-ore"}
for i, resource in pairs(extra_resources) do
    data:extend({
        {
            type = "bool-setting",
            name = "k2-extra-" .. resource,
            setting_type = "startup",
            default_value = false,
            order = "g-" .. i
        }
    })
end