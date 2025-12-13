local mod = get_mod("hitbox_debug_draw")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "lifetime",
				type = "numeric",
				default_value = 3,
				range = {0, 60},
				unit_text = "lifetime"
			}
		}
	}
}
