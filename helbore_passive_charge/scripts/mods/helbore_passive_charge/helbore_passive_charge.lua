local mod = get_mod("helbore_passive_charge")

local is_enabled = true
local wielding_charge = false
local currently_aiming = false
local next_release = false
local next_release_forced = false
local can_release_again = true


mod:io_dofile("helbore_passive_charge/scripts/mods/helbore_passive_charge/create_ui")

mod._toggle_select = function()
    if wielding_charge then 
        is_enabled = not is_enabled
    end
    mod:get_hud_element():set_active(is_enabled)
end

mod:hook_safe(CLASS.PlayerUnitWeaponExtension, "on_slot_wielded", function(self, slot_name, ...)
    if self._player == Managers.player:local_player(1) then
        local wep_template = self._weapons[slot_name].weapon_template
        wielding_charge = wep_template.displayed_attacks and wep_template.displayed_attacks.primary.type == "charge" and wep_template.actions.vent == nil
        --mod:debug("wielding_charge" .. tostring(wielding_charge))
    else
        wielding_charge = false
    end    

    mod:get_hud_element():set_enabled(wielding_charge)

end)

local _get_player_unit = function()
    local plr = Managers.player and Managers.player:local_player(1)
    return plr and plr.player_unit
end

mod:hook_require("scripts/utilities/alternate_fire", function(AlternateFire)
    mod:hook_safe(AlternateFire, "start", function(alternate_fire_component, weapon_tweak_templates_component, spread_control_component, sway_control_component, sway_component, movement_state_component, peeking_component, first_person_extension, animation_extension, weapon_extension, weapon_template, player_unit, ...)
        --mod:debug('alternative fire entered')
        --mod:debug("player unit: %s", tostring(player_unit))
        if player_unit == _get_player_unit() then
            currently_aiming = true
            --mod:debug("currently_aiming: true")
        end
    end)

    mod:hook_safe(AlternateFire, "stop", function(alternate_fire_component, peeking_component, first_person_extension, weapon_tweak_templates_component, animation_extension, weapon_template, player_unit, from_action_input)
        --mod:debug("alternative fire exited")
       -- mod:debug("player unit: %s", tostring(player_unit))
        if player_unit == _get_player_unit() then
            currently_aiming = false
            --mod:debug("currently_aiming: false")
            next_release = false
            next_release_forced = false
            can_release_again = true
        end
    end)
end)

local _input_action_hook = function(func, self, action_name)

    local val = func(self, action_name)

    if not is_enabled then
        return val
    end
    local val = func(self, action_name)




    local is_lmb_action = action_name == "action_one_hold"

    local lmb_release_action_pressed = action_name == "action_one_release" and val

    if wielding_charge then
        if is_lmb_action and can_release_again then
            
            if next_release_forced then
                next_release_forced = false
                --can_release_again = false
                return false
            end

            if next_release then
                next_release = false
                can_release_again = false
                return false
            end
            if currently_aiming then
                if val then
                    next_release = true
                end
                return true
            end
        elseif lmb_release_action_pressed and not can_release_again then
            next_release_forced = true
            can_release_again = true
            return true
        end
    end


    return val

end


mod:hook(CLASS.InputService, "_get", _input_action_hook)
mod:hook(CLASS.InputService, "_get_simulate", _input_action_hook)