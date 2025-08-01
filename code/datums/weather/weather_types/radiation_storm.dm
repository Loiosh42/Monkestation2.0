//Radiation storms occur when the station passes through an irradiated area, and irradiate anyone not standing in protected areas (maintenance, emergency storage, etc.)
/datum/weather/rad_storm
	name = "radiation storm"
	desc = "A cloud of intense radiation passes through the area dealing rad damage to those who are unprotected."

	telegraph_duration = 400
	telegraph_message = "<span class='danger'>The air begins to grow warm.</span>"

	weather_message = "<span class='userdanger'><i>You feel waves of heat wash over you! Find shelter!</i></span>"
	weather_overlay = "ash_storm"
	weather_duration_lower = 600
	weather_duration_upper = 1500
	weather_color = "green"
	weather_sound = 'sound/misc/bloblarm.ogg'

	end_duration = 100
	end_message = "<span class='notice'>The air seems to be cooling off again.</span>"

	area_type = /area
	protected_areas = list(/area/station/maintenance,
							/area/station/ai_monitored/turret_protected/ai_upload, /area/station/ai_monitored/turret_protected/ai_upload_foyer,
							/area/station/ai_monitored/turret_protected/aisat/maint, /area/station/ai_monitored/command/storage/satellite,
							/area/station/ai_monitored/turret_protected/ai, /area/station/commons/storage/emergency/starboard,
							/area/station/commons/storage/emergency/port, /area/shuttle, /area/station/common/cryopods, /area/station/security/prison/safe,
							/area/station/security/prison/toilet, /area/icemoon/underground, /area/station/service/hydroponics/garden/abandoned,
							/area/station/security/detectives_office/private_investigators_office, /area/station/security/bitden,
							/area/station/service/library/abandoned, /area/station/service/theater/abandoned, /area/station/service/abandoned_gambling_den,
							/area/station/service/electronic_marketing_den, /area/station/service/kitchen/abandoned, /area/station/medical/abandoned,
							/area/station/science/research/abandoned, /area/station/asteroid, /area/station/command/secure_bunker,
							/area/station/cargo/power_station, /area/station/engineering/power_station, /area/station/science/power_station,
							/area/station/science/power_station, /area/station/security/power_station, /area/station/service/power_station,
							/area/station/medical/aslyum, /area/station/medical/virology/isolation, /area/graveyard/tunnels, /area/graveyard/bunker,
							/area/ruin/space/ancientstation,
						)
	target_trait = ZTRAIT_STATION

	immunity_type = TRAIT_RADSTORM_IMMUNE

/datum/weather/rad_storm/telegraph()
	..()
	status_alarm(TRUE)


/datum/weather/rad_storm/weather_act(mob/living/L)
	if(!prob(40))
		return

	if(!ishuman(L))
		return

	var/mob/living/carbon/human/H = L
	if(!H.can_mutate() || HAS_TRAIT(H, TRAIT_GODMODE))
		return

	// MONKESTATION ADDITION START
	if(HAS_TRAIT(H, TRAIT_RADHEALING))
		H.adjustBruteLoss(-5)
		H.adjustFireLoss(-5)
	// MONKESTATION ADDITION END

	if(HAS_TRAIT(H, TRAIT_RADIMMUNE))
		return

	if (SSradiation.wearing_rad_protected_clothing(H))
		return

	H.random_mutate_unique_identity()
	H.random_mutate_unique_features()

	if(prob(50))
		if(prob(90))
			H.easy_random_mutate(NEGATIVE+MINOR_NEGATIVE)
		else
			H.easy_random_mutate(POSITIVE)
		H.domutcheck()

/datum/weather/rad_storm/end()
	if(..())
		return
	priority_announce("The radiation threat has passed. Please return to your workplaces.", "Anomaly Alert")
	status_alarm(FALSE)

/datum/weather/rad_storm/proc/status_alarm(active) //Makes the status displays show the radiation warning for those who missed the announcement.
	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)
	if(!frequency)
		return

	var/datum/signal/signal = new
	if (active)
		signal.data["command"] = "alert"
		signal.data["picture_state"] = "radiation"
	else
		signal.data["command"] = "shuttle"

	var/atom/movable/virtualspeaker/virt = new(null)
	frequency.post_signal(virt, signal)
