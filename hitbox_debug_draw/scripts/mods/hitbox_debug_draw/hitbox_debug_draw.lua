local mod = get_mod("hitbox_debug_draw")




MinionAttack = require("scripts/utilities/minion_attack")
MinionVisualLoadout = require("scripts/utilities/minion_visual_loadout")


local perstable = mod:persistent_table("main")
local world = perstable["world"]


local lineobjects
if perstable["lineobjects"] ~= nil then
    lineobjects = perstable["lineobjects"]
else
    lineobjects = {}
    perstable["lineobjects"] = lineobjects
end

mod:command("clear_hitboxes", "", function()
    for i=#lineobjects, 1, -1 do
        lineobjects[i]["lifetime"] = 0
    end
    
end)


local function main_color() return Color.green() end
local function dodge_color() return Color.red() end




local prevtime = 0
function mod.update(dt)
    if world == nil then
        return
    end
    perstable["world"] = world

    local time = World.time(world)
    if prevtime > time then
        -- new world, clearing lineobjects
        lineobjects = {}
    end
    prevtime = time




    for i=#lineobjects, 1, -1 do
        local data = lineobjects[i]
        local expiretime = data["timeadded"] + data["lifetime"]
        if time > expiretime then
            table.remove(lineobjects, i)
            LineObject.reset(data["obj"])
            LineObject.dispatch(world, data["obj"])
            world:destroy_line_object(data["obj"])
        end
    end
end




function _create_temp_line_object(time)

    local lineobject = world:create_line_object()

    local timeadded = World.time(world)



    local data = {}
    data["obj"] = lineobject
    data["timeadded"] = timeadded
    data["lifetime"] = time
    table.insert(lineobjects, data)

    return lineobject

    


end

-- Get local player unit
local _get_player_unit = function()
    local plr = Managers.player and Managers.player:local_player(1)
    return plr and plr.player_unit
end

function _get_weapon_reach(action_data, attack_event)
	local weapon_reach = type(action_data.weapon_reach) == "table" and (action_data.weapon_reach[attack_event] or action_data.weapon_reach.default) or action_data.weapon_reach

	return weapon_reach
end

function add_v_cone(lineobject, color, from, to, angle, height, segments)

    local dir = Vector3.normalize(to - from)
    local length = Vector3.length(to - from)

    local offset = angle * 2 / segments


    function lim_length(in_point)
        local dir = Vector3.normalize(in_point - from)
        return from + dir * length
    end

    

    local ang = Quaternion.axis_angle(Vector3(0, 0, 1), 0.0)
    local rot_dir = Quaternion.rotate(dir, ang)

    LineObject.add_line(lineobject, color, from + Vector3(0, 0, height), from - Vector3(0, 0, height))

    local t = Vector3(0)
    local quat = Quaternion.axis_angle(Vector3(0, 0, 1), angle)
    local start_dir = Quaternion.rotate(quat, dir)


    local loop_start = 1
    local loop_end = segments + 1
    for i=1, segments + 1, 1 do
        local off = offset * (i - 1)
        local new_quat = Quaternion.axis_angle(Vector3(0, 0, 1),-off)
        local rotated = Quaternion.rotate(new_quat, start_dir)
        local tm = from + rotated * length

        local h
        local f
        local dt
        
        local oldt = Vector3(0)
        if not Vector3.equal(t, Vector3(0)) then
            oldt = t
        end
            

        f = from + Vector3(0, 0, height)
        t = tm + Vector3(0, 0, height)



        dt = tm - Vector3(0, 0, height)

        -- forward line to down
        LineObject.add_line(lineobject, color, t, dt)
        --goto continue

        
        if not Vector3.equal(oldt,Vector3(0)) then
            LineObject.add_line(lineobject, color, oldt, t)
            LineObject.add_line(lineobject, color, oldt - Vector3(0, 0, height * 2), t - Vector3(0,0, height * 2))

        end


        local height_segments = segments
        if i == loop_start or i == loop_end then
            f = from + Vector3(0, 0, height)
            local p = tm + Vector3(0, 0, height)
            LineObject.add_line(lineobject, color, f, p)
            f = from - Vector3(0, 0, height)
            p = tm - Vector3(0, 0, height)
            LineObject.add_line(lineobject, color, f, p)
            
        end



        
    ::continue::
    end

end



local melee = function(unit, breed, scratchpad, blackboard, target_unit, action_data, physics_world, override_damage_profile_or_nil, override_damage_type_or_nil, attack_event)
    world = Unit.world(unit)
    local lineobject = _create_temp_line_object(mod:get("lifetime"))

    local attack_type = action_data.attack_type
    if attack_type == "oobb" then
        local position, rotation, hit_size, dodge_hit_size = MinionAttack.melee_oobb_extents(unit, action_data)
        local pose = Matrix4x4.from_translation(position)
        Matrix4x4.set_rotation(pose, rotation)
        LineObject.add_box(lineobject, main_color(), pose, hit_size)
        LineObject.add_box(lineobject, dodge_color(), pose, dodge_hit_size)
    
    else if attack_type == "broadphase" then
        local from_position, broadphase_radius = MinionAttack.melee_broadphase_extents(unit, action_data)
        local dodge_reach = action_data.dodge_weapon_reach or 2.4
        LineObject.add_sphere(lineobject, main_color(), from_position, broadphase_radius)
        LineObject.add_sphere(lineobject, dodge_color(), from_position, dodge_reach)
    else
        local weapon_reach = _get_weapon_reach(action_data, attack_event)
        local DEFAULT_REACH_CONE = 0.75
        local reach_cone = action_data.weapon_reach_cone or DEFAULT_REACH_CONE
        local unit_rotation = Unit.local_rotation(unit, 1)
        local forward = Quaternion.forward(unit_rotation)
        local to = Unit.world_position(unit, 1) + forward * weapon_reach
        local base = Unit.world_position(unit, 1)
        local angle = math.acos(reach_cone)
        local height = (action_data.max_z_diff or 2.2)
        add_v_cone(lineobject, main_color(), base, to, angle, height, 7)
        
        local dodge_reach = action_data.dodge_weapon_reach or 2.4
        local dodge_cone = (action_data.dodge_reach_cone or 0.94)
        to = Unit.world_position(unit, 1) + forward * dodge_reach
        angle = math.acos(dodge_cone)
        add_v_cone(lineobject, dodge_color(), base, to, angle, height, 7)

        --LineObject.add_sphere(lineobject, Color.light_green(), Unit.world_position(_get_player_unit(), 1), 0.05)


    end
    end
    LineObject.dispatch(world, lineobject)

end





local sweep = function(unit, breed, sweep_node, scratchpad, blackboard, target_unit, action_data, physics_world, sweep_hit_units_cache, override_damage_profile_or_nil, override_damage_type_or_nil, attack_event, optional_ignore_target_unit)
    world = Unit.world(unit)

    local node = Unit.node(unit, sweep_node)
    local position = Unit.world_position(unit, node)
    local radius = _get_weapon_reach(action_data, attack_event)
    local collision_filter = action_data.collision_filter
    local shape = action_data.sweep_shape or "sphere"
    local actors, actor_count, extents
    
    local lineobject = _create_temp_line_object(mod:get("lifetime"))

    if shape == "oobb" then
        local sweep_length = action_data.sweep_length
        local sweep_height = action_data.sweep_height
        local sweep_width = action_data.sweep_width
        local rotation = Unit.world_rotation(unit, node)
        extents = Vector3(sweep_width, sweep_length, sweep_height)
        local pose = Matrix4x4.from_translation(position)
        Matrix4x4.set_rotation(pose, rotation)
        LineObject.add_box(lineobject, main_color(), pose, extents)
    else
        LineObject.add_sphere(lineobject, main_color(), position, radius)
    end
    local dodge_reach = action_data.dodge_weapon_reach or 2.4
    LineObject.add_sphere(lineobject, dodge_color(), position, dodge_reach)

    LineObject.dispatch(world, lineobject)
end

local shoot_hit_scan =  function(func, p_world, physics_world, unit, target_unit, weapon_item, fx_source_name, shoot_position, shoot_template, optional_spread_multiplier, perception_component, action_data)
    local attachment_unit, node = MinionVisualLoadout.attachment_unit_and_node_from_node_name(weapon_item, fx_source_name)
    local from_position = Unit.world_position(attachment_unit, node)

    local end_position = func(p_world, physics_world, unit, target_unit, weapon_item, fx_source_name, shoot_position, shoot_template, optional_spread_multiplier, perception_component, action_data)

    world = p_world
    local lineobject = _create_temp_line_object(mod:get("lifetime"))

    LineObject.add_line(lineobject, main_color(), from_position, end_position)
    LineObject.dispatch(world, lineobject)

    return end_position

end



mod:hook_require("scripts/utilities/minion_attack", function(instance)
    mod:hook_safe(instance, "melee", melee)
    mod:hook_safe(instance, "sweep", sweep)
    mod:hook(instance, "shoot_hit_scan", shoot_hit_scan)
end)

local ChaosHoundSettings = require("scripts/settings/specials/chaos_hound_settings")

local LEAP_NODE = "j_head"

mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_chaos_hound_leap_action", function(instance)
    mod:hook_safe(instance, "_check_colliding_players", function(self, unit, scratchpad, action_data, ignore_dot_check)
        world = Unit.world(unit)
        local attacking_unit_pos = Unit.world_position(unit, Unit.node(unit, LEAP_NODE))
        local radius, dodge_radius = ChaosHoundSettings.collision_radius, ChaosHoundSettings.dodge_collision_radius

        local lineobject = _create_temp_line_object(mod:get("lifetime"))

        LineObject.add_sphere(lineobject, main_color(), attacking_unit_pos, radius)
        LineObject.add_sphere(lineobject, dodge_color(), attacking_unit_pos, dodge_radius)

        LineObject.dispatch(world, lineobject)



    end)
end)


mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_mutant_charger_charge_action", function(instance)
    mod:hook_safe(instance, "_check_colliding_players", function(self, unit, scratchpad, action_data)
        world = Unit.world(unit)
        local attacking_unit_pos = POSITION_LOOKUP[unit]
        local radius, dodge_radius = action_data.collision_radius, action_data.dodge_collision_radius

        local lineobject = _create_temp_line_object(mod:get("lifetime"))

        LineObject.add_sphere(lineobject, main_color(), attacking_unit_pos, radius)
        LineObject.add_sphere(lineobject, dodge_color(), attacking_unit_pos, dodge_radius)

        LineObject.dispatch(world, lineobject)



    end)
end)


mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_chaos_spawn_grab_action", function(instance)
    mod:hook_safe(instance, "_update_grabbing", function(self, unit, scratchpad, action_data, t, dt)
        world = Unit.world(unit)
        if scratchpad.grab_timing and t >= scratchpad.grab_timing and scratchpad.perception_component.has_line_of_sight then
            local target_unit = scratchpad.perception_component.target_unit
            local grab_node_name = action_data.grab_node
            local grab_node = Unit.node(unit, grab_node_name)
            local grab_position = Unit.world_position(unit, grab_node)
            local grab_target_node_name = action_data.grab_target_node
            local grab_target_node = Unit.node(target_unit, grab_target_node_name)
            local grab_target_position = Unit.world_position(target_unit, grab_target_node)
            local distance = Vector3.distance(grab_position, grab_target_position)
            local dodge_check_radius = action_data.dodge_grab_check_radius
            local check_radius = action_data.grab_check_radius
        
            local lineobject = _create_temp_line_object(mod:get("lifetime"))
            LineObject.add_sphere(lineobject, main_color(), grab_position, check_radius)
            LineObject.add_sphere(lineobject, dodge_color(), grab_position, dodge_check_radius)
            LineObject.dispatch(world, lineobject)
        end
    end)
end)

mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_leap_action", function(instance)
    mod:hook_safe(instance, "_push_or_catapult_players", function(self, unit, scratchpad, action_data, t)
        world = Unit.world(unit)
        local data = action_data.catapult_or_push_players
        local radius = data.radius
        local unit_position = POSITION_LOOKUP[unit]

        local lineobject = _create_temp_line_object(mod:get("lifetime"))
        LineObject.add_sphere(lineobject, dodge_color(), unit_position, radius)
        LineObject.dispatch(world, lineobject)
        


    end)
end)

mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_charge_action", function(instance)
    mod:hook_safe(instance, "_check_colliding_players", function(self, unit, scratchpad, action_data)
        world = Unit.world(unit)
        local using_close_attack_type = action_data.using_close_attack_type
        local position = POSITION_LOOKUP[unit]

        local lineobject = _create_temp_line_object(mod:get("lifetime"))
        local radius
        if using_close_attack_type then
            radius = action_data.close_collision_radius
            LineObject.add_sphere(lineobject, dodge_color(), position, radius)
        else
            radius = action_data.collision_radius
        end
        LineObject.add_sphere(lineobject, dodge_color(), position, radius)
        LineObject.dispatch(world, lineobject)
        


    end)
end)

mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_dash_action", function(instance)
    mod:hook_safe(instance, "_check_colliding_players", function(self, unit, scratchpad, action_data)
        world = Unit.world(unit)
        local position = POSITION_LOOKUP[unit]
        local radius = action_data.collision_radius
        local lineobject = _create_temp_line_object(mod:get("lifetime"))
        LineObject.add_sphere(lineobject, dodge_color(), position, radius)
        LineObject.dispatch(world, lineobject)

    end)
end)

mod:hook_require("scripts/utilities/attack/explosion", function(instance)
    mod:hook_safe(instance, "create_explosion", function(p_world, physics_world, source_position, optional_impact_normal, attacking_unit, explosion_template)
        world = p_world
        local explosion_radius = explosion_template.radius
        local lineobject = _create_temp_line_object(mod:get("lifetime"))
        LineObject.add_sphere(lineobject, dodge_color(),  source_position, explosion_radius)
        LineObject.dispatch(world, lineobject)

    end)
end)

local renegade_netgunner_actions = require('scripts/settings/breed/breed_actions/renegade/renegade_netgunner_actions')
local played = false
mod:hook_require('scripts/extension_systems/behavior/nodes/actions/bt_shoot_net_action', function(instance)
    mod:hook_safe(instance, '_update_shooting', function(self, unit, breed, dt, t, scratchpad, action_data)
        if played then
            return
        end
        local shoot_data = scratchpad.shoot_data
        local old_sweep_position, direction = shoot_data.sweep_position:unbox(), shoot_data.direction:unbox()
 

        local radius = action_data.net_sweep_radius
        local net_dodge_sweep_radius = action_data.net_dodge_sweep_radius

        local lineobject = _create_temp_line_object(mod:get("lifetime"))

        
        LineObject.add_sphere(lineobject, main_color(), old_sweep_position, radius)


        local offset = radius * 0.3
        local capsule_down = old_sweep_position - Vector3(0, 0, offset)
        local capsule_up = old_sweep_position + Vector3(0, 0, offset)
        LineObject.add_capsule(lineobject, dodge_color(), capsule_down, capsule_up, net_dodge_sweep_radius)

        LineObject.dispatch(world, lineobject)
        played = true
    end)
end)

-- @TODO maybe later 
-- mod:hook_require("scripts/extension_systems/liquid_area/liquid_area_extension", function(instance)
--     mod:hook_safe(instance, "_update_collision_detection", function(self)
--         local broadphase_center, broadphase_radius = self._broadphase_center:unbox(), self._broadphase_radius
--         local lineobject = _create_temp_line_object(mod:get("lifetime"))
--         LineObject.add_sphere(lineobject, dodge_color(), pos, dodge_radius)
--         LineObject.dispatch(world, lineobject)
--     end)
-- end)

-- not hook_safe because the function sets scratchpad.consume_timing to nil after execution
mod:hook_require('scripts/extension_systems/behavior/nodes/actions/bt_beast_of_nurgle_consume_action', function(instance)
    mod:hook(instance, '_update_consuming', function(func, self, unit, scratchpad, action_data, t, dt)
        world = Unit.world(unit)
        if scratchpad.consume_timing and t >= scratchpad.consume_timing then
            
            local consume_node_name = action_data.consume_node
            local consume_node = Unit.node(unit, consume_node_name)
            local consume_position = Unit.world_position(unit, consume_node)
            local consume_check_radius = action_data.consume_check_radius

            local lineobject = _create_temp_line_object(mod:get("lifetime"))
            LineObject.add_sphere(lineobject, dodge_color(), consume_position, consume_check_radius)
            LineObject.dispatch(world, lineobject)


        end
        return func(self, unit, scratchpad, action_data, t, dt)


    end)
end)

mod:hook_require("scripts/extension_systems/behavior/nodes/actions/bt_shoot_liquid_beam_action", function(instance)
    mod:hook_safe(instance, "_shoot_sphere_cast", function (self, unit, t, shoot_position, scratchpad, action_data)
        world = Unit.world(unit)

        local from_position = self:_get_from_position(unit, scratchpad, action_data)
        local dodge_radius = action_data.dodge_radius
        local radius = action_data.radius

        local lineobject = _create_temp_line_object(mod:get("lifetime"))
        LineObject.add_capsule(lineobject, main_color(), from_position, shoot_position, radius)
        LineObject.add_capsule(lineobject, dodge_color(), from_position, shoot_position, dodge_radius)
        LineObject.dispatch(world, lineobject)




    end)
end)
