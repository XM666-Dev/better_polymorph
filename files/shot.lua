dofile_once("mods/better_polymorph/files/utilities.lua")

-- 计算变换矩阵
function createTransformationMatrix(x, y, rotation, scale_x, scale_y)
    local cos_r = math.cos(rotation)
    local sin_r = math.sin(rotation)

    return {
        { scale_x * cos_r, -scale_y * sin_r, x },
        { scale_x * sin_r, scale_y * cos_r,  y },
        { 0,               0,                1 },
    }
end

-- 矩阵相乘
function multiplyMatrices(m1, m2)
    local result = {}
    for i = 1, 3 do
        result[i] = {}
        for j = 1, 3 do
            result[i][j] = m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j] + m1[i][3] * m2[3][j]
        end
    end
    return result
end

-- 从矩阵提取变换参数
function extractTransformationParameters(matrix)
    local scale_x = math.sqrt(matrix[1][1] ^ 2 + matrix[2][1] ^ 2)
    local scale_y = math.sqrt(matrix[1][2] ^ 2 + matrix[2][2] ^ 2)
    local rotation = math.atan2(matrix[2][1], matrix[1][1])
    local x = matrix[1][3]
    local y = matrix[2][3]

    return x, y, rotation, scale_x, scale_y
end

-- 计算两个变换的乘积并返回结果变换的参数
function combineTransformations(x1, y1, rotation1, scale_x1, scale_y1, x2, y2, rotation2, scale_x2, scale_y2)
    local matrix1 = createTransformationMatrix(x1, y1, rotation1, scale_x1, scale_y1)
    local matrix2 = createTransformationMatrix(x2, y2, rotation2, scale_x2, scale_y2)
    local combinedMatrix = multiplyMatrices(matrix1, matrix2)

    return extractTransformationParameters(combinedMatrix)
end

function shot(projectile_entity_id)
    local player = GetUpdatedEntityID()
    local controls = EntityGetFirstComponent(player, "ControlsComponent")
    if controls ~= nil and ComponentGetValue2(controls, "mButtonFrameFire") == GameGetFrameNum() and GameGetFrameNum() >= ComponentGetValue2(controls, "polymorph_next_attack_frame") and GameGetFrameNum() > GetValueInteger("frame", 0) then
        SetValueInteger("frame", GameGetFrameNum())
        local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
        local attacks = EntityGetComponentIncludingDisabled(player, "AIAttackComponent") or {}
        local attack_index = get_attack_index(attacks)
        local attack_table = get_attack_table(ai, attacks[attack_index])
        if ModSettingGet("better_polymorph.fix_attack") and attack_table.entity_file ~= nil then
            local x, y, rotation, scale_x, scale_y = EntityGetTransform(player)
            x, y = combineTransformations(x, y, rotation, scale_x, scale_y, attack_table.offset_x, attack_table.offset_y, 0, 1, 1)
            local target_x, target_y = DEBUG_GetMouseWorld()
            for i = 2, ProceduralRandom(x, y, attack_table.entity_count_min, attack_table.entity_count_max) do
                local projectile_entity = EntityLoad(attack_table.entity_file, x, y)
                GameShootProjectile(player, x, y, target_x, target_y, projectile_entity)
            end
            GameShootProjectile(player, x, y, target_x, target_y, projectile_entity_id, false)
        end
        if ModSettingGet("better_polymorph.attack_animation") then
            GamePlayAnimation(player, attack_table.animation, 2)
        end
    end
    if ModSettingGet("better_polymorph.friendly_fire") then
        local projectile = EntityGetFirstComponent(projectile_entity_id, "ProjectileComponent")
        if projectile ~= nil then
            ComponentSetValue2(projectile, "mShooterHerdId", -1)
        end
    end
end
