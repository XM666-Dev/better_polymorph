dofile_once("mods/better_polymorph/files/tactic.lua")
dofile_once("mods/better_polymorph/files/utilities.lua")
dofile_once("data/scripts/debug/keycodes.lua")
local nxml = dofile_once("mods/better_polymorph/files/nxml.lua")

local xmls = {}
local function parse_xml(filename)
    local xml = xmls[filename] or nxml.parse_file(filename)
    xmls[filename] = xml
    return xml
end
local function get_attack_index(entity)
    local ai = EntityGetFirstComponentIncludingDisabled(entity, "AnimalAIComponent")
    local attacks = EntityGetComponent(entity, "AIAttackComponent") or {}
    local attack_index = 0
    for i, attack in ipairs(attacks) do
        if ComponentGetValue2(attack, "use_probability") ~= -1 then
            attack_index = i
        end
    end
    if #attacks < 1 and ai ~= nil and ComponentGetValue2(ai, "attack_ranged_enabled") then
        attacks[1] = ai
        local controls = EntityGetFirstComponent(entity, "ControlsComponent")
        attack_index = controls ~= nil and ComponentGetValue2(controls, "polymorph_hax") and 1 or 0
    end
    return attack_index, attacks
end
local function get_item_slot(item)
    local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
    local ability_component = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
    if item_component ~= nil and ability_component ~= nil then
        return ComponentGetValue2(item_component, "inventory_slot") + (ComponentGetValue2(ability_component, "use_gun_script") and 0 or 4)
    end
end
local function get_item(player, index)
    local children = get_children(player)
    local quick_inventory = table.find(children, function(v) return EntityGetName(v) == "inventory_quick" end)
    local items = get_children(quick_inventory)
    table.sort(items, function(a, b)
        return get_item_slot(a) < get_item_slot(b)
    end)
    return items[index]
end
local function block_item_select(player)
    local quick_inventory = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
    local items = get_children(quick_inventory)
    for i, item in ipairs(items) do
        local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
        if item_component ~= nil then
            ComponentSetValue2(item_component, "inventory_slot", -1, 0)
        end
    end
end
local function block_item_change(player, count)
    local inventory = EntityGetFirstComponent(player, "Inventory2Component")
    if inventory ~= nil then
        local quick_inventory = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
        local items = get_children(quick_inventory)
        ComponentSetValue2(inventory, "mSavedActiveItemIndex", (ComponentGetValue2(inventory, "mSavedActiveItemIndex") + count) % #items)
        ComponentSetValue2(inventory, "mInitialized", false)
    end
end

function OnWorldPreUpdate()
    local polymorphed_players = EntityGetWithTag("polymorphed_player")
    for i, player in ipairs(polymorphed_players) do
        if ModSettingGet("better_polymorph.gui") then
            local gui = EntityGetFirstComponent(player, "InventoryGuiComponent") or EntityAddComponent2(player, "InventoryGuiComponent")
            if EntityGetComponent(player, "Inventory2Component") == nil then
                ComponentSetValue2(gui, "mActive", false)
            end
        end
        local controls = EntityGetFirstComponent(player, "ControlsComponent")
        if controls ~= nil then
            local frame = GameGetFrameNum()
            if ModSettingGet("better_polymorph.run") then
                local down = ComponentGetValue2(controls, "mButtonDownLeft") or ComponentGetValue2(controls, "mButtonDownRight") or ComponentGetValue2(controls, "mButtonDownUp") or ComponentGetValue2(controls, "mButtonDownDown")
                local just_down = ComponentGetValue2(controls, "mButtonFrameLeft") == frame or
                    ComponentGetValue2(controls, "mButtonFrameRight") == frame or
                    ComponentGetValue2(controls, "mButtonFrameUp") == frame or
                    ComponentGetValue2(controls, "mButtonFrameDown") == frame
                ComponentSetValue2(controls, "mButtonDownRun", down)
                if just_down then
                    ComponentSetValue2(controls, "mButtonFrameRun", frame)
                end
            end
            if ModSettingGet("better_polymorph.select_attack") and InputIsKeyDown(Key_LSHIFT) then
                local attack_index, attacks = get_attack_index(player)
                if InputIsMouseButtonDown(Mouse_wheel_down) then
                    attack_index = attack_index + 1
                    block_item_change(player, -1)
                end
                if InputIsMouseButtonDown(Mouse_wheel_up) then
                    attack_index = attack_index - 1
                    block_item_change(player, 1)
                end
                attack_index = warp(attack_index, 0, #attacks + 1)
                for i = 1, 8 do
                    if InputIsKeyJustDown(Key_1 + i - 1) then
                        attack_index = i <= #attacks and i or 0
                        block_item_select(player)
                    end
                end
                for i, v in ipairs(attacks) do
                    if ComponentGetTypeName(v) == "AIAttackComponent" then
                        ComponentSetValue2(v, "use_probability", i <= attack_index and 100 or -1)
                    else
                        ComponentSetValue2(controls, "polymorph_hax", attack_index > 0)
                    end
                end
            end
            if ModSettingGet("better_polymorph.hold_attack") and ComponentGetValue2(controls, "mButtonDownFire") and ComponentGetValue2(controls, "polymorph_hax") and frame + 1 >= ComponentGetValue2(controls, "polymorph_next_attack_frame") then
                ComponentSetValue2(controls, "mButtonFrameFire", frame + 1)
            end
        end
        if EntityGetComponent(player, "LuaComponent", "better_polymorph.shot") == nil then
            EntityAddComponent2(player, "LuaComponent", {
                _tags = "better_polymorph.shot",
                script_shot = "mods/better_polymorph/files/shot.lua",
            })
        end
        if EntityGetComponent(player, "VariableStorageComponent", "better_polymorph.polymorphed") == nil then
            EntityAddComponent2(player, "VariableStorageComponent", {_tags = "better_polymorph.polymorphed"})
            if ModSettingGet("better_polymorph.retain_perks") then
                local perks_to_spawn = get_all_perks()
                for i, v in ipairs(perks_to_spawn) do
                    local id, count = unpack(v)
                    for i = 1, count do
                        give_perk_to_enemy(get_perk_with_id(perk_list, id), player, 0, 0, 0, i)
                    end
                end
            end
        end
        if ModSettingGet("better_polymorph.mouse_look") then
            local character_platforming = EntityGetFirstComponent(player, "CharacterPlatformingComponent")
            if character_platforming ~= nil then
                local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
                local inventory = EntityGetFirstComponent(player, "Inventory2Component")
                ComponentSetValue2(character_platforming, "mouse_look",
                    ai ~= nil and (ComponentGetValue2(ai, "attack_melee_enabled") or ComponentGetValue2(ai, "attack_ranged_enabled")) or
                    inventory ~= nil and validate(ComponentGetValue2(inventory, "mActiveItem")) ~= nil
                )
            end
        end
    end
end

local gui = GuiCreate()
function OnWorldPostUpdate()
    GuiStartFrame(gui)
    local widgets = {}
    local function insert_widget(...)
        table.insert(widgets, {...})
    end

    local player = EntityGetWithTag("polymorphed_player")[1]
    local attack_index, attacks = get_attack_index(player)
    for i, attack in ipairs(attacks) do
        local entity_file = ComponentGetValue2(attack, "attack_ranged_entity_file")
        if ModDoesFileExist(entity_file) then
            local x, y = tonumber(MagicNumbersGetValue("UI_BARS_POS_X")) - 1, tonumber(MagicNumbersGetValue("UI_BARS_POS_Y")) + i * 20
            insert_widget(GuiImage, new_id("item_bg_gun" .. i), x, y, "data/ui_gfx/inventory/item_bg_gun.png", 1, 1)
            if i == attack_index then
                insert_widget(GuiImage, new_id("highlight"), x + 10, y + 10, "data/ui_gfx/inventory/highlight.xml", 1, 1, 0, 0, GUI_RECT_ANIMATION_PLAYBACK.Loop)
            end
            local entity_xml = parse_xml(entity_file)
            local base = entity_xml:first_of("Base")
            local component = entity_xml:first_of("SpriteComponent") or entity_xml:first_of("PhysicsImageShapeComponent") or
                base ~= nil and (base:first_of("SpriteComponent") or base:first_of("PhysicsImageShapeComponent")) or nil
            if component ~= nil then
                local image_file = component.attr.image_file
                if ModDoesFileExist(image_file or "") then
                    if image_file:find(".xml$") then
                        local image_xml = parse_xml(image_file)
                        image_file = image_xml.attr.default_animation == nil and image_xml.attr.filename or image_file
                    end
                    local x, y = x, y
                    GuiImage(gui, 1, 0, 0, image_file)
                    local width, height = select(6, GuiGetPreviousWidgetInfo(gui))
                    if not image_file:find(".xml$") then
                        x, y = x - width * 0.5, y - height * 0.5
                    end
                    insert_widget(GuiImage, new_id("image_file" .. i), x + 10, y + 10, image_file, 1, math.min(1, 20 / width, 20 / height), 0, 0, GUI_RECT_ANIMATION_PLAYBACK.Loop)
                end
            end
        end
    end
    for i, widget in ipairs(widgets) do
        GuiZSetForNextWidget(gui, #widgets - i + 1001)
        widget[1](gui, unpack(widget, 2))
    end
end
