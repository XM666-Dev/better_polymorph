dofile_once("mods/better_polymorph/files/utilities.lua")
dofile_once("data/scripts/debug/keycodes.lua")

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
            if ModSettingGet("better_polymorph.run") then
                ComponentSetValue2(controls, "mButtonDownRun", InputIsKeyDown(Key_LSHIFT))
                if InputIsKeyJustDown(Key_LSHIFT) then
                    ComponentSetValue2(controls, "mButtonFrameRun", GameGetFrameNum() + 1)
                end
            end
            if ModSettingGet("better_polymorph.select_attack") then
                local attacks = EntityGetComponentIncludingDisabled(player, "AIAttackComponent") or {}
                local attack_index = get_attack_index(attacks)
                if ComponentGetValue2(controls, "mButtonDownChangeItemR") then
                    attack_index = attack_index + ComponentGetValue2(controls, "mButtonCountChangeItemR")
                end
                if ComponentGetValue2(controls, "mButtonDownChangeItemL") then
                    attack_index = attack_index - ComponentGetValue2(controls, "mButtonCountChangeItemL")
                end
                attack_index = warp(attack_index, 1, #attacks + 1)
                for i, v in ipairs(attacks) do
                    EntitySetComponentIsEnabled(player, v, i == attack_index)
                end
            end
            if ModSettingGet("better_polymorph.hold_attack") and ComponentGetValue2(controls, "mButtonDownFire") and GameGetFrameNum() + 1 >= ComponentGetValue2(controls, "polymorph_next_attack_frame") then
                ComponentSetValue2(controls, "mButtonFrameFire", GameGetFrameNum() + 1)
            end
        end
        if EntityGetComponent(player, "LuaComponent", "better_polymorph.shot") == nil then
            EntityAddComponent2(player, "LuaComponent", {
                _tags = "better_polymorph.shot",
                script_shot = "mods/better_polymorph/files/shot.lua",
            })
        end
        if EntityGetComponent(player, "VariableStorageComponent", "better_polymorph.polymorphed") == nil then
            EntityAddComponent2(player, "VariableStorageComponent", { _tags = "better_polymorph.polymorphed" })
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
                local attacks = EntityGetComponentIncludingDisabled(player, "AIAttackComponent") or {}
                local attack_index = get_attack_index(attacks)
                local attack_table = get_attack_table(ai, attacks[attack_index])
                local inventory = EntityGetFirstComponent(player, "Inventory2Component")
                ComponentSetValue2(character_platforming, "mouse_look", attack_table.entity_file ~= nil or inventory ~= nil and validate_entity(ComponentGetValue2(inventory, "mActiveItem")) ~= nil)
            end
        end
    end
end
