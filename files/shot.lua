dofile_once("mods/better_polymorph/files/tactic.lua")

function shot(projectile)
    local player = GetUpdatedEntityID()
    local controls = EntityGetFirstComponent(player, "ControlsComponent")
    local frame = GameGetFrameNum()
    if controls ~= nil and ComponentGetValue2(controls, "mButtonFrameFire") == frame and frame >= ComponentGetValue2(controls, "polymorph_next_attack_frame") and frame >= GetValueInteger("frame", 0) then
        SetValueInteger("frame", frame + 1)
        local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
        local attacks = EntityGetComponentIncludingDisabled(player, "AIAttackComponent") or {}
        local attack_table = get_attack_table(player, ai, attacks)
        if ModSettingGet("better_polymorph.fix_attack") and attack_table ~= nil then
            local x, y = get_attack_ranged_pos(player, attack_table)
            local vector_x, vector_y = ComponentGetValue2(controls, "mAimingVector")
            local center_x, center_y = EntityGetFirstHitboxCenter(player)
            local target_x, target_y = vector_x + center_x, vector_y + center_y
            local player_x, player_y = EntityGetTransform(player)
            SetRandomSeed(player_x + 0.11231 + GameGetFrameNum(), player_y + 0.2341)
            for i = 2, Random(attack_table.entity_count_min, attack_table.entity_count_max) do
                local projectile_entity = EntityLoad(attack_table.entity_file, x, y)
                GameShootProjectile(player, x, y, target_x, target_y, projectile_entity)
            end
            GameShootProjectile(player, x, y, target_x, target_y, projectile, false)
        end
        if ModSettingGet("better_polymorph.attack_animation") and attack_table ~= nil then
            GamePlayAnimation(player, attack_table.animation_name, 2)
        end
    end
    if ModSettingGet("better_polymorph.friendly_fire") then
        local projectile_component = EntityGetFirstComponent(projectile, "ProjectileComponent")
        if projectile_component ~= nil then
            ComponentSetValue2(projectile_component, "mShooterHerdId", -1)
        end
    end
end
