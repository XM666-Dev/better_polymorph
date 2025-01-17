dofile_once("mods/better_polymorph/files/sult.lua")
dofile_once("data/scripts/perks/perk_list.lua")
dofile_once("data/scripts/lib/utilities.lua")

function get_attack_index(attacks)
    local index = 0
    for i, v in ipairs(attacks) do
        if ComponentGetIsEnabled(v) then
            index = i
        end
    end
    return index
end

function warp(value, from, to)
    return (value - from) % (to - from) + from
end

function get_attack_table(ai, attack)
    local animation = "attack_ranged"
    local frames_between
    local action_frame
    local entity_file
    local entity_count_min
    local entity_count_max
    local offset_x
    local offset_y
    if ai ~= nil and ComponentGetValue2(ai, "attack_ranged_enabled") then
        frames_between = ComponentGetValue2(ai, "attack_ranged_frames_between")
        action_frame = ComponentGetValue2(ai, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(ai, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(ai, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(ai, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(ai, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(ai, "attack_ranged_offset_y")
    end
    if attack ~= nil then
        animation = ComponentGetValue2(attack, "animation_name")
        frames_between = ComponentGetValue2(attack, "frames_between")
        action_frame = ComponentGetValue2(attack, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(attack, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(attack, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(attack, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(attack, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(attack, "attack_ranged_offset_y")
    end
    return {
        animation = animation,
        frames_between = frames_between,
        action_frame = action_frame,
        entity_file = entity_file,
        entity_count_min = entity_count_min,
        entity_count_max = entity_count_max,
        offset_x = offset_x,
        offset_y = offset_y,
    }
end

function get_all_perks()
    local perks_to_spawn = {}

    for i, perk_data in ipairs(perk_list) do
        local perk_id = perk_data.id

        if (perk_data.one_off_effect == nil) or (perk_data.one_off_effect == false) then
            local flag_name = get_perk_picked_flag_name(perk_id)
            local pickup_count = tonumber(GlobalsGetValue(flag_name .. "_PICKUP_COUNT", "0"))

            if GameHasFlagRun(flag_name) or (pickup_count > 0) then
                table.insert(perks_to_spawn, { perk_id, pickup_count })
                -- print( "Added " .. perk_id .. ", pickup count " .. tostring( pickup_count ) )
            end
        end
    end

    return perks_to_spawn
end

function give_perk_to_enemy(perk_data, entity_who_picked, entity_item, num_perks, perk_idx, pickup_num)
    -- fetch perk info ---------------------------------------------------

    local pos_x, pos_y = EntityGetTransform(entity_who_picked)

    local perk_id = perk_data.id
    local do_not_remove = perk_data.do_not_remove or false

    -- add game effect
    if perk_data.game_effect ~= nil then
        local game_effect_comp, game_effect_entity = GetGameEffectLoadTo(entity_who_picked, perk_data.game_effect, true)
        if game_effect_comp ~= nil then
            ComponentSetValue(game_effect_comp, "frames", "-1")
        end

        if (do_not_remove == false) then
            ComponentAddTag(game_effect_comp, "perk_component")
            EntityAddTag(game_effect_entity, "perk_entity")
        end
    end

    if perk_data.game_effect2 ~= nil then
        local game_effect_comp, game_effect_entity = GetGameEffectLoadTo(entity_who_picked, perk_data.game_effect2, true)
        if game_effect_comp ~= nil then
            ComponentSetValue(game_effect_comp, "frames", "-1")
        end

        if (do_not_remove == false) then
            ComponentAddTag(game_effect_comp, "perk_component")
            EntityAddTag(game_effect_entity, "perk_entity")
        end
    end

    if perk_data.particle_effect ~= nil then
        local particle_id = EntityLoad("data/entities/particles/perks/" .. perk_data.particle_effect .. ".xml")

        if (do_not_remove == false) then
            EntityAddTag(particle_id, "perk_entity")
        end

        EntityAddChild(entity_who_picked, particle_id)
    end


    if perk_data.func_enemy ~= nil then
        perk_data.func_enemy(entity_item, entity_who_picked, nil, pickup_num)
    elseif perk_data.func ~= nil then
        perk_data.func(entity_item, entity_who_picked, nil, pickup_num)
    end

    -- add ui icon etc
    local entity_icon = EntityLoad("data/entities/misc/perks/enemy_icon.xml", pos_x, pos_y)
    edit_component(entity_icon, "SpriteComponent", function(comp, vars)
        ComponentSetValue(comp, "image_file", perk_data.ui_icon)
    end)
    EntityAddChild(entity_who_picked, entity_icon)
end
