return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`hitbox_debug_draw` encountered an error loading the Darktide Mod Framework.")

		new_mod("hitbox_debug_draw", {
			mod_script       = "hitbox_debug_draw/scripts/mods/hitbox_debug_draw/hitbox_debug_draw",
			mod_data         = "hitbox_debug_draw/scripts/mods/hitbox_debug_draw/hitbox_debug_draw_data",
			mod_localization = "hitbox_debug_draw/scripts/mods/hitbox_debug_draw/hitbox_debug_draw_localization",
		})
	end,
	packages = {},
}
