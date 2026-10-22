local resources = {"iron-ore", "copper-ore", "coal", "stone", "crude-oil", "uranium-ore"}

return function(surface, startup_settings)
    if not surface then return end

    local mgs = surface.map_gen_settings
    local changed = false

    local function allow(kind, name)
        mgs.autoplace_settings = mgs.autoplace_settings or {}
        local placement = mgs.autoplace_settings[kind]
        if not placement then return end -- An absent list already permits default placement.
        placement.settings = placement.settings or {}
        if placement.settings[name] == nil then
            placement.settings[name] = {}
            changed = true
        end
    end

    local function control(name)
        mgs.autoplace_controls = mgs.autoplace_controls or {}
        if mgs.autoplace_controls[name] == nil then
            mgs.autoplace_controls[name] = {frequency = 1, size = 1, richness = 1}
            changed = true
        end
    end

    for _, name in ipairs(resources) do
        local setting = startup_settings["k2-extra-" .. name]
        if setting and setting.value then
            allow("entity", name)
            control(name)
        end
    end

    local water = startup_settings["k2-extra-water"]
    if water and water.value then
        allow("tile", "water")
        allow("tile", "deepwater")
        control("water")
    end

    if changed then surface.map_gen_settings = mgs end
end
