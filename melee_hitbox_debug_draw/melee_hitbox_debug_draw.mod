return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`melee_hitbox_debug_draw` encountered an error loading the Darktide Mod Framework.")

		new_mod("melee_hitbox_debug_draw", {
			mod_script       = "melee_hitbox_debug_draw/scripts/mods/melee_hitbox_debug_draw/melee_hitbox_debug_draw",
			mod_data         = "melee_hitbox_debug_draw/scripts/mods/melee_hitbox_debug_draw/melee_hitbox_debug_draw_data",
			mod_localization = "melee_hitbox_debug_draw/scripts/mods/melee_hitbox_debug_draw/melee_hitbox_debug_draw_localization",
		})
	end,
	packages = {},
}
