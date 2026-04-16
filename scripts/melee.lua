local uevrUtils = require('libs/uevr_utils')

local M = {}

local isDisabled  = false
function M.disable(val)
    isDisabled = val

    if val then
        local animInstance = uevrUtils.getValid(pawn, {"Mesh", "AnimScriptInstance"})
        if animInstance then
        	animInstance:SetRootMotionMode(2) -- Everything
            M.print("Re-enabled root motion")
        end
    end
end

local currentLogLevel = LogLevel.Error
function M.setLogLevel(val)
	currentLogLevel = val
end
function M.print(text, logLevel)
	if logLevel == nil then logLevel = LogLevel.Debug end
	if logLevel <= currentLogLevel then
		uevrUtils.print("[melee] " .. text, logLevel)
	end
end

-- The following code courtesy of Praydog
local api = uevr.api
local vr = uevr.params.vr

local SHAnimCombatSubcomp_c = uevrUtils.find_required_object("Class /Script/SHProto.SHAnimCombatSubcomp")
local AnimNotify_MeleeAttackCheck_c = uevrUtils.find_required_object("Class /Script/SHProto.AnimNotify_MeleeAttackCheck")
local AnimNotify_ModifyCombatInputMode_c = uevrUtils.find_required_object("Class /Script/SHProto.AnimNotify_ModifyCombatInputMode")
local AnimNotifyEventReference_c = uevrUtils.find_required_object("ScriptStruct /Script/Engine.AnimNotifyEventReference")
local SHMeleeBaseDamage_c = uevrUtils.find_required_object("Class /Script/SHProto.SHMeleeBaseDamage")
local DamageType_c = uevrUtils.find_required_object("Class /Script/Engine.DamageType")
local SHItemWeaponMelee_c = uevrUtils.find_required_object("Class /Script/SHProto.SHItemWeaponMelee")
local reusable_anim_notify_ref = StructObject.new(AnimNotifyEventReference_c)
local melee_montage = nil
local ANIMNOTIFY_NOTIFY_VTABLE_INDEX = 88
local MELEE_WEAPON_DAMAGE_TYPE_OFFSET = 0x6D8 -- LightEffect + 0x28, might be a way of automating this
local last_anim_notify_melee_obj = nil
local last_anim_notify_modify_combat_input_obj = nil

local AnimMontage_c = api:find_uobject("Class /Script/Engine.AnimMontage")
local UClass_c = api:find_uobject("Class /Script/CoreUObject.Class")
local melee_attack_name = kismet_string_library:Conv_StringToName("MeleeAttack")
local triggered_melee_recently = false

local melee_data = {
    cooldown_time = 0.0,
    accumulated_time = 0.0,
    last_tried_melee_time = 1000.0,
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    last_enemy_hit_time = 0.0,
    root_motion_needs_reset = true,
    known_damage_types = {},
    damage_type_dict = {},
    last_weapon = nil,
    last_repopulate_attempt = 0.0,
    first = true,
    enemy_combo_index = 0,
    hit_enemy = false,
}

local function populate_damage_types()
    if DamageType_c == nil or #melee_data.known_damage_types > 0 then
        return
    end

    local damage_types = DamageType_c:get_objects_matching(true) -- Include defaults

    for k, v in pairs(damage_types) do
        --if v:as_struct() ~= nil then
            M.print("Found damage type: " .. v:get_full_name())
            local c = v:get_class()
            table.insert(melee_data.known_damage_types, c)
            melee_data.damage_type_dict[c:get_fname():to_string()] = c
        --end
    end

    melee_data.last_repopulate_attempt = os.clock()
end

local function lookup_damage_type(name)
    populate_damage_types()

    local v = melee_data.damage_type_dict[name]

    if v ~= nil and UEVR_UObjectHook.exists(v) and v:is_a(UClass_c) and v:get_class_default_object():is_a(DamageType_c) then
        return v
    end

    local now = os.clock()

    if now - melee_data.last_repopulate_attempt > 1.0 then
        melee_data.known_damage_types = {}
        melee_data.damage_type_dict = {}
        populate_damage_types()
    end

    return melee_data.damage_type_dict[name]
end

uevr.sdk.callbacks.on_lua_event(function(event_name, event_string)
    -- if isDisabled then
    --     return
    -- end

    M.print("Lua event received: " .. event_name .. " with string: " .. event_string)
    if event_name == "OnMeleeTraceSuccess" then
        local now = os.clock()
        melee_data.accumulated_time = 0.0
        melee_data.last_tried_melee_time = 0.0

        if event_string == "Enemy" then
            if math.abs(now - melee_data.last_enemy_hit_time) > 1.0 then
                if melee_data.enemy_combo_index ~= 1 then
                    M.print("Combo reset")
                end
                melee_data.enemy_combo_index = 0
            else
                melee_data.enemy_combo_index = ((melee_data.enemy_combo_index + 1) % 3)
                M.print("Combo index: " .. tostring(melee_data.enemy_combo_index))
            end

            melee_data.cooldown_time = 0.5
            melee_data.last_enemy_hit_time = now
            melee_data.hit_enemy = true
        elseif event_string == "Glass" then
            melee_data.cooldown_time = 0.5
        else
            melee_data.cooldown_time = 0.033 -- Environment traces can be more frequent
        end

        melee_data.last_tried_melee_time = 1000.0

        if vr.is_using_controllers() then
            vr.trigger_haptic_vibration(0, 0.1, 0.5, 1.0, vr.get_right_joystick_source())

            triggered_melee_recently = true
        end
    elseif event_name == "OnMeleeHitLeg" then
        if melee_data.last_weapon ~= nil then
            local pistol_damage = lookup_damage_type("PistolDamage_C")

            if pistol_damage ~= nil then
                -- Enable kneecapping damage (makes the enemy fall down sometimes if hit in the leg)
---@diagnostic disable-next-line: undefined-field
                melee_data.last_weapon:write_qword(MELEE_WEAPON_DAMAGE_TYPE_OFFSET, pistol_damage:get_address())
            end
        end
    end
end)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
    if isDisabled then
        return
    end

    melee_data.last_weapon = nil

    -- if not right_hand_component or not left_hand_component then
    --     return
    -- end

    local now = os.clock()
    vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)

    -- Copy without creating new userdata
    melee_data.right_hand_pos:set(melee_data.right_hand_pos_raw.x, melee_data.right_hand_pos_raw.y, melee_data.right_hand_pos_raw.z)

    if melee_data.first then
        melee_data.last_right_hand_raw_pos:set(melee_data.right_hand_pos.x, melee_data.right_hand_pos.y, melee_data.right_hand_pos.z)
        melee_data.first = false
    end

    local velocity = (melee_data.right_hand_pos - melee_data.last_right_hand_raw_pos) * (1 / delta)

    -- Clone without creating new userdata
    melee_data.last_right_hand_raw_pos.x = melee_data.right_hand_pos_raw.x
    melee_data.last_right_hand_raw_pos.y = melee_data.right_hand_pos_raw.y
    melee_data.last_right_hand_raw_pos.z = melee_data.right_hand_pos_raw.z
    melee_data.last_time_messed_with_attack_request = melee_data.last_time_messed_with_attack_request + delta

    local pawn = api:get_local_pawn(0)

    if pawn == nil then
        return
    end

    melee_montage = uevrUtils.getValid(melee_montage)
    if melee_montage == nil or not UEVR_UObjectHook.exists(melee_montage) or not melee_montage:is_a(AnimMontage_c) then
        local montages = AnimMontage_c:get_objects_matching(false)

        for i, v in ipairs(montages) do
            --if v:get_fname():to_string():find("BreakingWall") then
            if v:get_fname():to_string() == "James_SideAttacks_GroundAttack_UpDown" then
            --if v:get_fname():to_string() == "James_StealthAttack_Hit1_v2" then
                melee_montage = v
                M.print("Found montage")
                break
            end
        end
    end

    if AnimNotify_MeleeAttackCheck_c ~= nil and (not last_anim_notify_melee_obj or not UEVR_UObjectHook.exists(last_anim_notify_melee_obj) or not last_anim_notify_melee_obj:is_a(AnimNotify_MeleeAttackCheck_c)) then
        local anim_notifies = AnimNotify_MeleeAttackCheck_c:get_objects_matching(false)

        for i, v in ipairs(anim_notifies) do
            if v:get_outer() == melee_montage then
                last_anim_notify_melee_obj = v
                M.print("Found melee notify obj @ " .. v:get_full_name())
                break
            end
        end
    end

    if AnimNotify_ModifyCombatInputMode_c ~= nil and (not last_anim_notify_modify_combat_input_obj or not UEVR_UObjectHook.exists(last_anim_notify_modify_combat_input_obj) or not last_anim_notify_modify_combat_input_obj:is_a(AnimNotify_ModifyCombatInputMode_c)) then
        last_anim_notify_modify_combat_input_obj = AnimNotify_ModifyCombatInputMode_c:get_class_default_object() -- Will this work? let's find out

        if last_anim_notify_modify_combat_input_obj then
            M.print("Got combat input notify obj")
        end
    end

    populate_damage_types()

    if melee_montage ~= nil and melee_montage.bEnableRootMotionTranslation ~= nil then --and is_allowing_vr_mode then
        -- no way in hell we want to use root motion for melee attacks
        melee_montage.bEnableRootMotionTranslation = false
        --[[melee_montage.bEnableRootMotionTranslation = false
        melee_montage.bEnableRootMotionRotation = false
        melee_montage.RootMotionRootLock = 0]]
        local mesh = pawn.Mesh
        local combat = pawn.Combat

        if combat then
            if combat:read_byte(0x152) == 1 then
                M.print("Combat input mode is 1")
                combat:write_byte(0x152, 0) -- Reset combat input mode so we don't softlock
            end
        end

        if mesh then
            local animation = pawn.Animation
            local anim_instance = mesh.AnimScriptInstance
            local weapon = anim_instance and anim_instance:GetEquippedWeapon() or nil
            local has_melee_weapon = weapon ~= nil and weapon:is_a(SHItemWeaponMelee_c)

            -- Disable root motion
            if anim_instance then
                local is_playing_melee_attack = has_melee_weapon and anim_instance["Is Playing Melee Attack"](anim_instance, {}, {}, {}, {}, {}) or false
                if is_playing_melee_attack or anim_instance:Montage_IsPlaying(melee_montage) then
                    anim_instance:SetRootMotionMode(1) -- IgnoreRootMotion
                    melee_data.root_motion_needs_reset = true
                elseif melee_data.root_motion_needs_reset then
                    -- Enable root motion outside of melee attacks.
                    anim_instance:SetRootMotionMode(3) -- RootMotionFromMontagesOnly
                    melee_data.root_motion_needs_reset = false
                end
            end

            if has_melee_weapon and last_anim_notify_melee_obj then
                melee_data.last_weapon = weapon
                local combat_anim_subcomp = animation:FindSubcomponentByClass(SHAnimCombatSubcomp_c)

                -- Stops normal melee attacks (aka pressing attack button)
                -- We only want attacks to work if we swing the controller
                if melee_data.last_time_messed_with_attack_request >= 0.1 and not triggered_melee_recently and combat_anim_subcomp and vr.is_using_controllers() then
                    local attack = combat_anim_subcomp.Attack
                    if attack then
                        local animdata = attack.PlayAnimationData

                        if animdata then
                            local current_montage = attack.CurrentMontage

                            if current_montage and attack:IsPlaying() then
                                local input_data = attack.InputData
                                if input_data ~= nil then --or (input_data:get_full_name():find("BreakingWall") == nil and input_data:get_full_name():find("Chainsaw") == nil) then
                                    local montageName = input_data:get_full_name()
                                    if montageName:find("BreakingWall") == nil and montageName:find("Chainsaw") == nil then
                                        animdata.BlendInTime = 0.0
                                        animdata.BlendOutTime = 0.0
                                        anim_instance:Montage_SetPosition(current_montage, current_montage:GetPlayLength())

                                        melee_data.last_time_messed_with_attack_request = 0.0
                                    end
                                    if montageName:find("Chainsaw") ~= nil then
                                        anim_instance:SetRootMotionMode(2) -- IgnoreRootMotion
                                        melee_data.root_motion_needs_reset = true
                                    end
                                end
                            end
                        end
                    end
                end

                if melee_data.accumulated_time > 0.1 then
                    triggered_melee_recently = false
                end

                melee_data.accumulated_time = melee_data.accumulated_time + delta
                if melee_data.cooldown_time > 0.0 then
                    melee_data.cooldown_time = melee_data.cooldown_time - delta
                end
                local vel_len = velocity:length()
                local swinging_fast = vel_len >= 2.5
                if melee_data.cooldown_time <= 0.0 and (swinging_fast or math.abs(melee_data.accumulated_time - melee_data.last_tried_melee_time) < 0.1) then
                    if combat_anim_subcomp then
                        local attack = combat_anim_subcomp.Attack
                        if attack and attack.CurrentMontage == nil and attack.InputData == nil then
                            if last_anim_notify_melee_obj then
                                if swinging_fast then
                                    melee_data.last_tried_melee_time = melee_data.accumulated_time
                                end

                                melee_data.hit_enemy = false

                                -- Setting these allows the AnimNotify to actually hit stuff
                                attack.CurrentMontage = melee_montage
                                attack.InputData = melee_montage

                                local animdata = attack.PlayAnimationData

                                if animdata then
                                    animdata.SlotName = melee_attack_name
                                    --attack:PlayOrOverwriteRequest(0.0, animdata, temp_vec3:set(0, 0, 0))
                                end

                                --if anim_instance:GetCurrentActiveMontage() ~= melee_montage then
                                if not anim_instance:Montage_IsPlaying(melee_montage) then
                                    anim_instance:Montage_Play(melee_montage, 1.0, 0, 0.0, false)
                                end

                                -- Triggers Notify function, which does the melee attack traces and damage
                                reusable_anim_notify_ref:write_qword(0x10, last_anim_notify_melee_obj:get_address()) -- 0x10 is the offset of Notify
                                reusable_anim_notify_ref.NotifySource = mesh
                                local last_mesh_context = last_anim_notify_melee_obj:read_qword(0x30) -- 0x30 is the offset of MeshContext
                                last_anim_notify_melee_obj:write_qword(0x30, mesh:get_address()) -- 0x30 is the offset of MeshContext

                                -- We need to directly write the damage type address into the melee weapon
                                -- This is because the game uses this to determine hit reactions.
                                -- AFAIK there is no reflected method to do this, so we have to do it manually.
                                local damage_type_strs = {
                                    "Wdp_Combo_L" .. tostring(melee_data.enemy_combo_index + 1) .. "_DamageType_C", -- This allows us to stumble the enemy first
                                    "IronPipeDamage_C" -- This one allows us to break through breakable walls. I don't know why the previous one doesn't work for this. This one hurts but doesn't stumble
                                }
                                local damage_type = nil

                                for _, dtype_str in ipairs(damage_type_strs) do
                                    damage_type = lookup_damage_type(dtype_str)

                                    if damage_type == nil then
                                        M.print("Failed to find damage type: " .. dtype_str)
                                    else
                                        local defobj = damage_type:get_class_default_object()
                                        if defobj:is_a(SHMeleeBaseDamage_c) then
                                            defobj.bIsGroundHit = true -- Lets attacks hit the ground
                                        end
                                        if weapon ~= nil then
                                            weapon:write_qword(MELEE_WEAPON_DAMAGE_TYPE_OFFSET, damage_type:get_address())
                                        end
                                    end

                                    local pcall_res = pcall(function()
                                        last_anim_notify_melee_obj:DANGEROUS_call_member_virtual(ANIMNOTIFY_NOTIFY_VTABLE_INDEX + 1, mesh, melee_montage, reusable_anim_notify_ref)
                                    end)

                                    if not pcall_res then
                                        M.print("Failed to call melee notify")
                                    end

                                    if melee_data.hit_enemy then
                                        break
                                    end
                                end

                                -- Reset damage type
                                if weapon ~= nil then
                                    weapon:write_qword(MELEE_WEAPON_DAMAGE_TYPE_OFFSET, 0)
                                end

                                -- Reset mesh context
                                last_anim_notify_melee_obj:write_qword(0x30, last_mesh_context)

                                -- Reset the attack request back so we don't break something
                                attack.CurrentMontage = nil
                                attack.InputData = nil

                                if not triggered_melee_recently then
                                    vr.trigger_haptic_vibration(0, 0.1, 0.1, 0.1, vr.get_right_joystick_source()) -- Very light vibration
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

return M