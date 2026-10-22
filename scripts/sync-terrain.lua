local deepcopy = require("util").table.deepcopy
local function surface_style(mgs)
    local tiles = mgs.autoplace_settings and mgs.autoplace_settings.tile
    local violet, fulgora = false, false
    for name in pairs(tiles and tiles.settings or {}) do
        if name:match("^k2%-violet%-") then violet = true end
        if name:match("^fulgoran%-") then fulgora = true end
    end
    if violet and not fulgora then return false end
    if fulgora and not violet then return true end
end

return function(surface, template, desired_style, previous_style, entities)
    if not surface then return end
    local mgs = surface.map_gen_settings
    local old_style = previous_style
    if old_style == nil then old_style = surface_style(mgs) end
    -- Unknown custom terrain is left intact until an explicit setting change.
    if old_style == nil or old_style == desired_style then return end

    local old_entity = mgs.autoplace_settings.entity
    -- K2 uses an explicit allowlist; custom implicit placement is left intact.
    if not old_entity or old_entity.treat_missing_as_default ~= false then return end
    local target_entity = deepcopy(template.autoplace_settings.entity)
    -- Resource membership belongs to the saved surface, independently of terrain.
    for name in pairs(target_entity.settings) do
        if entities[name] and entities[name].type == "resource" then
            target_entity.settings[name] = nil
        end
    end
    for name, value in pairs(old_entity and old_entity.settings or {}) do
        if entities[name] and entities[name].type == "resource" then
            target_entity.settings[name] = value
        end
    end
    if old_entity then target_entity.treat_missing_as_default = old_entity.treat_missing_as_default end
    mgs.autoplace_settings.entity = target_entity
    mgs.autoplace_settings.tile = deepcopy(template.autoplace_settings.tile)
    mgs.autoplace_settings.decorative = deepcopy(template.autoplace_settings.decorative)
    local expressions = deepcopy(template.property_expression_names or {})
    for key, value in pairs(mgs.property_expression_names or {}) do
        local name = key:match("^entity:(.-):")
        if name and entities[name] and entities[name].type == "resource" then
            expressions[key] = value
        end
    end
    mgs.property_expression_names = expressions
    mgs.cliff_settings = deepcopy(template.cliff_settings)
    for name, value in pairs(template.autoplace_controls or {}) do
        if mgs.autoplace_controls[name] == nil then
            mgs.autoplace_controls[name] = deepcopy(value)
        end
    end
    surface.map_gen_settings = mgs
end
