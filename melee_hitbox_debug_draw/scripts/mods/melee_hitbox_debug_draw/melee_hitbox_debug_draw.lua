local mod = get_mod("melee_hitbox_debug_draw")


MinionAttack = require("scripts/utilities/minion_attack")
MinionVisualLoadout = require("scripts/utilities/minion_visual_loadout")

local world = nil
local lineobjects = {}


local function main_color() return Color.green() end
local function dodge_color() return Color.red() end


-- local rnd = {}
-- mod:hook(math, "random", function(func)

--     local value = func()
--     table.insert(rnd, value)
--     if #rnd > 2 then
--         table.remove(rnd, 1)
--     end

--     return value

-- end)




function mod.update(dt)
    if world == nil then
        return
    end
    local time = World.time(world)
    for i=#lineobjects, 1, -1 do
        local data = lineobjects[i]
        local expiretime = data["timeadded"] + data["lifetime"]
        if time > expiretime then
            LineObject.reset(data["obj"])
            LineObject.dispatch(world, data["obj"])
            world:destroy_line_object(data["obj"])
            table.remove(lineobjects, i)
        end
    end
end




function _create_temp_line_object(time)

    local lineobject = world:create_line_object()

    local timeadded = World.time(world)



    local data = {}
   -- mod:echo(timeadded)
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
        mod:echo(off)
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

local MAX_SUPPRESS_VALUE_SPREAD = 60
local function _spread_direction(target_unit, minion_unit, shoot_direction, spread, optional_spread_multiplier)
	local spread_multiplier = optional_spread_multiplier or 1
	local spread_angle = rnd[1] * spread * spread_multiplier
	local buff_extension = ScriptUnit.has_extension(target_unit, "buff_system")

	if buff_extension then
		local stat_buffs = buff_extension:stat_buffs()

		if stat_buffs and stat_buffs.elusiveness_modifier then
			spread_angle = spread_angle * stat_buffs.elusiveness_modifier
		end
	end

	local minion_buff_extension = ScriptUnit.has_extension(minion_unit, "buff_system")

	if minion_buff_extension then
		local stat_buffs = minion_buff_extension:stat_buffs()

		if stat_buffs and stat_buffs.minion_accuracy_modifier then
			spread_angle = spread_angle * stat_buffs.minion_accuracy_modifier
		end
	end

	local suppression_extension = ScriptUnit.has_extension(minion_unit, "suppression_system")

	if suppression_extension then
		local suppress_value = suppression_extension:suppress_value()

		if suppress_value > 1 then
			spread_angle = spread_angle * math.min(suppress_value * 3, MAX_SUPPRESS_VALUE_SPREAD)
		end
	end

	local direction_rotation = Quaternion.look(shoot_direction, Vector3.up())
	local pitch = Quaternion(Vector3.right(), spread_angle)
	local roll = Quaternion(Vector3.forward(), rnd[2] * math.two_pi)
	local spread_rotation = Quaternion.multiply(Quaternion.multiply(direction_rotation, roll), pitch)
	local spread_direction = Quaternion.forward(spread_rotation)

	return spread_direction
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
        if mod:get("dodge") then
            LineObject.add_box(lineobject, dodge_color(), pose, dodge_hit_size)
        end
    
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
        
        if mod:get("dodge") then
            local dodge_reach = action_data.dodge_weapon_reach or 2.4
            local dodge_cone = (action_data.dodge_reach_cone or 0.94)
            to = Unit.world_position(unit, 1) + forward * dodge_reach
            angle = math.acos(dodge_cone)
            add_v_cone(lineobject, dodge_color(), base, to, angle, height, 7)
        end

        LineObject.add_sphere(lineobject, Color.light_green(), Unit.world_position(_get_player_unit(), 1), 0.05)


    end
    end
    LineObject.dispatch(world, lineobject)

end





local sweep = function(unit, breed, sweep_node, scratchpad, blackboard, target_unit, action_data, physics_world, sweep_hit_units_cache, override_damage_profile_or_nil, override_damage_type_or_nil, attack_event, optional_ignore_target_unit)
    world = Unit.world(unit)

    mod:echo("sweep")
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

    if mod:get("dodge") then
        local dodge_reach = action_data.dodge_weapon_reach or 2.4
        LineObject.add_sphere(lineobject, dodge_color(), position, dodge_reach)
    end

    LineObject.dispatch(world, lineobject)
end

local shoot_hit_scan =  function(func, p_world, physics_world, unit, target_unit, weapon_item, fx_source_name, shoot_position, shoot_template, optional_spread_multiplier, perception_component, action_data)
    local attachment_unit, node = MinionVisualLoadout.attachment_unit_and_node_from_node_name(weapon_item, fx_source_name)
    local from_position = Unit.world_position(attachment_unit, node)

    local end_position = func(p_world, physics_world, unit, target_unit, weapon_item, fx_source_name, shoot_position, shoot_template, optional_spread_multiplier, perception_component, action_data)

    world = p_world
    mod:echo(World.time(world))
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


