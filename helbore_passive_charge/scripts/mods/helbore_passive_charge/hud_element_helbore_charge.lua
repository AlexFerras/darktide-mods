local mod = get_mod("helbore_passive_charge")

local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")

local color_enabled = { 255, 255, 255, 255 }
local color_disabled = { 160, 160, 160, 160 }

local ui_definitions = {
    scenegraph_definition = {
        screen = UIWorkspaceSettings.screen,
        charge_container = {
            parent = "screen",
            vertical_alignment = "bottom",
            horizontal_alignment = "right",
            size = { 30, 30 },
            position = {
                -380,
                -80,
                10
            }
        }
    },
    widget_definitions = {
        charge = UIWidget.create_definition({
            {
                style_id = "icon",
                value_id = "icon",
                pass_type = "texture",
                value = "content/ui/materials/icons/presets/preset_11",
                style = {
                    size = {nil, nil},
                }
            }
        }, "charge_container")
    }
}

local HudElementHelboreCharge = class("HudElementHelboreCharge", "HudElementBase")

HudElementHelboreCharge.init = function(self, parent, draw_layer, start_scale)
   -- mod:debug("Initializing hud element")
    HudElementHelboreCharge.super.init(self, parent, draw_layer, start_scale, ui_definitions)
end


HudElementHelboreCharge.update = function(self,...)
    if mod:get("hide_widget") then
        HudElementHelboreCharge.set_enabled(self, false)
        return
    end


    local ui_hud = self._parent
    local weapon_handler = ui_hud:element("HudElementPlayerWeaponHandler")
    --mod:echo(weapon_handler)
    if weapon_handler ~= nil and weapon_handler._player_weapons.slot_primary ~= nil then

        local wanted_element = weapon_handler._player_weapons.slot_primary.hud_element_player_weapon
        --mod:echo(wanted_element._widgets_by_name.icon.visible)
        local should_be_enabled = wanted_element and wanted_element._widgets_by_name.icon.visible and mod:is_wielding_charge()
        HudElementHelboreCharge.set_enabled(self, should_be_enabled)

    else
        HudElementHelboreCharge.set_enabled(self, false)--self:set_scenegraph_position("screen", x, y, z, horizontal_alignment, vertical_alignment)
    end
   
    HudElementHelboreCharge.super.update(self, ...)

end

HudElementHelboreCharge.set_enabled = function(self, enabled)
    self._widgets_by_name.charge.style.icon.visible = enabled
end

HudElementHelboreCharge.set_active = function(self, active)
    self._widgets_by_name.charge.style.icon.color = active and color_enabled or color_disabled
end

HudElementHelboreCharge.set_side_length = function(self, side_length)
    local widget_size = self._widgets_by_name.charge.style.icon.size
    widget_size[1] = side_length
    widget_size[2] = side_length
end



return HudElementHelboreCharge
