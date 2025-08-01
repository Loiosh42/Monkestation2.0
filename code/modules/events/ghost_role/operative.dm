/datum/round_event_control/operative
	name = "Lone Operative"
	typepath = /datum/round_event/ghost_role/operative
	weight = 1 //its weight is relative to how much stationary and neglected the nuke disk is. See nuclearbomb.dm. Shouldn't be dynamic hijackable. //monkestation edit: changed to 1 to allow it to always have a slim chance to roll
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION
	description = "A single nuclear operative assaults the station."

/datum/round_event/ghost_role/operative
	minimum_required = 1
	role_name = "lone operative"
	fakeable = FALSE

/datum/round_event/ghost_role/operative/spawn_role()
	var/list/candidates = SSpolling.poll_ghost_candidates(check_jobban = ROLE_OPERATIVE, role = ROLE_LONE_OPERATIVE, alert_pic = /obj/machinery/nuclearbomb)
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/spawn_location = find_space_spawn()
	if(isnull(spawn_location))
		return MAP_ERROR

	var/mob/living/carbon/human/operative = new(spawn_location)
	operative.randomize_human_appearance(~RANDOMIZE_SPECIES)
	operative.dna.update_dna_identity()
	var/datum/mind/Mind = new /datum/mind(selected.key)
	Mind.set_assigned_role(SSjob.GetJobType(/datum/job/lone_operative))
	Mind.special_role = ROLE_LONE_OPERATIVE
	Mind.active = TRUE
	Mind.transfer_to(operative)
	if(!operative.client?.prefs.read_preference(/datum/preference/toggle/nuke_ops_species))
		var/species_type = operative.client.prefs.read_preference(/datum/preference/choiced/species)
		operative.set_species(species_type) //Apply the preferred species to our freshly-made body.

	Mind.add_antag_datum(/datum/antagonist/nukeop/lone)

	message_admins("[ADMIN_LOOKUPFLW(operative)] has been made into lone operative by an event.")
	operative.log_message("was spawned as a lone operative by an event.", LOG_GAME)
	spawned_mobs += operative
	return SUCCESSFUL_SPAWN

//-----------------
// Junior Operative
// ----------------
/datum/round_event_control/junior_lone_operative
	name = "Junior Lone Operative"
	typepath = /datum/round_event/ghost_role/junior_operative

	category = EVENT_CATEGORY_INVASION
	description = "A junior nuclear operative infiltrates the station."
	weight = 0
	max_occurrences = 5
	track = EVENT_TRACK_MAJOR
	repeated_mode_adjust = TRUE

/datum/round_event/ghost_role/junior_operative
	minimum_required = 1
	role_name = "junior lone operative"
	fakeable = FALSE

/datum/round_event/ghost_role/junior_operative/spawn_role()
	var/list/candidates = SSpolling.poll_ghost_candidates(check_jobban = ROLE_OPERATIVE, role = ROLE_JUNIOR_LONE_OPERATIVE, alert_pic = /obj/item/clothing/head/helmet/space/syndicate, role_name_text = "Junior Lone Operative")
	if(!length(candidates))
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/spawn_location = find_space_spawn()
	if(isnull(spawn_location))
		return MAP_ERROR

	var/mob/living/carbon/human/operative = new(spawn_location)
	operative.randomize_human_appearance(~RANDOMIZE_SPECIES)
	operative.dna.update_dna_identity()
	var/datum/mind/Mind = new /datum/mind(selected.key)
	Mind.set_assigned_role(SSjob.GetJobType(/datum/job/junior_lone_operative))
	Mind.special_role = ROLE_JUNIOR_LONE_OPERATIVE
	Mind.active = TRUE
	Mind.transfer_to(operative)
	if(!operative.client?.prefs.read_preference(/datum/preference/toggle/nuke_ops_species))
		var/species_type = operative.client.prefs.read_preference(/datum/preference/choiced/species)
		operative.set_species(species_type) //Apply the preferred species to our freshly-made body.

	Mind.add_antag_datum(/datum/antagonist/nukeop/lone/junior)

	message_admins("[ADMIN_LOOKUPFLW(operative)] has been made into a junior lone operative by an event.")
	operative.log_message("was spawned as a junior lone operative by an event.", LOG_GAME)
	spawned_mobs += operative
	return SUCCESSFUL_SPAWN
