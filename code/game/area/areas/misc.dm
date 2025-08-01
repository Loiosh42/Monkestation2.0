// Areas that don't fit any of the other files, or only serve one purpose.

/area/space
	icon_state = "space"
	requires_power = TRUE
	always_unpowered = TRUE
	static_lighting = FALSE

	//base_lighting_alpha = 255
	//base_lighting_color = "#FFFFFF"

	power_light = FALSE
	power_equip = FALSE
	power_environ = FALSE
	area_flags = UNIQUE_AREA
	outdoors = TRUE
	ambience_index = AMBIENCE_SPACE
	flags_1 = CAN_BE_DIRTY_1
	sound_environment = SOUND_AREA_SPACE
	ambient_buzz = null //Space is deafeningly quiet


/area/space/Initialize(mapload)
	. = ..()
	if(!SSmapping.level_trait(src.z, ZTRAIT_STARLIGHT))
		set_base_lighting(GLOB.starlight_color, alpha)


/area/space/nearstation
	icon_state = "space_near"
	area_flags = UNIQUE_AREA | AREA_USES_STARLIGHT
	static_lighting = TRUE
/area/misc/start
	name = "start area"
	icon_state = "start"
	requires_power = FALSE
	static_lighting = FALSE
	base_lighting_alpha = 255
	has_gravity = STANDARD_GRAVITY
	ambient_buzz = null

/area/misc/testroom
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	// Mobs should be able to see inside the testroom
	static_lighting = FALSE
	base_lighting_alpha = 255
	name = "Test Room"
	icon_state = "test_room"
