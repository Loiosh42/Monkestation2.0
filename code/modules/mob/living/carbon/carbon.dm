/mob/living/carbon/Initialize(mapload)
	. = ..()
	create_carbon_reagents()
	update_body_parts() //to update the carbon's new bodyparts appearance
	register_context()

	GLOB.carbon_list += src
	AddComponent(/datum/component/carbon_sprint)
	immune_system = new(src)
	var/static/list/loc_connections = list(
		COMSIG_CARBON_DISARM_PRESHOVE = PROC_REF(disarm_precollide),
		COMSIG_CARBON_DISARM_COLLIDE = PROC_REF(disarm_collision),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	ADD_TRAIT(src, TRAIT_CAN_HOLD_ITEMS, INNATE_TRAIT) // Carbons are assumed to be innately capable of having arms, we check their arms count instead

/mob/living/carbon/Destroy()
	//This must be done first, so the mob ghosts correctly before DNA etc is nulled
	. = ..()

	QDEL_LIST(hand_bodyparts)
	QDEL_LIST(organs)
	QDEL_LIST(bodyparts)
	QDEL_LIST(implants)
	QDEL_NULL(immune_system)
	for(var/wound in all_wounds) // these LAZYREMOVE themselves when deleted so no need to remove the list here
		qdel(wound)
	for(var/scar in all_scars)
		qdel(scar)
	remove_from_all_data_huds()
	QDEL_NULL(dna)
	GLOB.carbon_list -= src

/mob/living/carbon/attackby(obj/item/item, mob/living/user, params)
	if(!all_wounds || !(!(user.istate & ISTATE_HARM) || user == src))
		return ..()

	if(can_perform_surgery(user, params))
		return TRUE

	for(var/i in shuffle(all_wounds))
		var/datum/wound/wound = i
		if(wound.try_treating(item, user))
			return TRUE

	return ..()

/mob/living/carbon/CtrlShiftClick(mob/user)
	..()
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		carbon_user.give(src)

/mob/living/carbon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/hurt = TRUE
	var/extra_speed = 0
	if(throwingdatum.thrower != src)
		extra_speed = min(max(0, throwingdatum.speed - initial(throw_speed)), CARBON_MAX_IMPACT_SPEED_BONUS)

	if(istype(throwingdatum))
		hurt = !throwingdatum.gentle
	if(hurt && hit_atom.density)
		if(isturf(hit_atom))
			Paralyze(2 SECONDS)
			take_bodypart_damage(10 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
		else if(isstructure(hit_atom) && extra_speed)
			Paralyze(1 SECONDS)
			take_bodypart_damage(5 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
		else if(!iscarbon(hit_atom) && extra_speed)
			take_bodypart_damage(5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
	if(iscarbon(hit_atom) && hit_atom != src)
		var/mob/living/carbon/victim = hit_atom
		if(victim.movement_type & FLYING)
			return
		if(hurt)
			victim.take_bodypart_damage(10 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
			take_bodypart_damage(10 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
			victim.Paralyze(2 SECONDS)
			Paralyze(2 SECONDS)
			visible_message(
				span_danger("[src] crashes into [hit_atom][extra_speed ? " really hard" : ""]!"),
				span_userdanger("You[extra_speed ? " violently" : ""] crash into [hit_atom][extra_speed ? " extra hard" : ""]!"),
			)
		playsound(src,'sound/weapons/punch1.ogg',50,TRUE)
		log_combat(src, victim, "crashed into")

//Throwing stuff
/mob/living/carbon/proc/toggle_throw_mode()
	if(stat)
		return
	if(throw_mode)
		throw_mode_off(THROW_MODE_TOGGLE)
	else
		throw_mode_on(THROW_MODE_TOGGLE)


/mob/living/carbon/proc/throw_mode_off(method)
	if(throw_mode > method) //A toggle doesnt affect a hold
		return
	throw_mode = THROW_MODE_DISABLED
	if(hud_used)
		hud_used.throw_icon.icon_state = "act_throw_off"


/mob/living/carbon/proc/throw_mode_on(mode = THROW_MODE_TOGGLE)
	throw_mode = mode
	if(hud_used)
		hud_used.throw_icon.icon_state = "act_throw_on"

/mob/proc/throw_item(atom/target)
	SEND_SIGNAL(src, COMSIG_MOB_THROW, target)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CARBON_THROW_THING, src, target)
	return TRUE

/mob/living/carbon/throw_item(atom/target)
	. = ..()
	throw_mode_off(THROW_MODE_TOGGLE)
	if(!target || !isturf(loc))
		return FALSE
	if(istype(target, /atom/movable/screen))
		return FALSE
	var/atom/movable/thrown_thing
	var/obj/item/held_item = get_active_held_item()
	var/verb_text = pick("throw", "toss", "hurl", "chuck", "fling")
	if(prob(0.5))
		verb_text = "yeet"
	var/neckgrab_throw = FALSE // we can't check for if it's a neckgrab throw when totaling up power_throw since we've already stopped pulling them by then, so get it early
	if(!held_item)
		if(pulling && isliving(pulling) && grab_state >= GRAB_AGGRESSIVE)
			var/mob/living/throwable_mob = pulling
			if(!throwable_mob.buckled)
				thrown_thing = throwable_mob
				if(grab_state >= GRAB_NECK)
					neckgrab_throw = TRUE
				stop_pulling()
				if(HAS_TRAIT(src, TRAIT_PACIFISM))
					to_chat(src, span_notice("You gently let go of [throwable_mob]."))
					return FALSE
	else
		thrown_thing = held_item.on_thrown(src, target)
	if(!thrown_thing)
		return FALSE
	if(isliving(thrown_thing))
		var/turf/start_T = get_turf(loc) //Get the start and target tile for the descriptors
		var/turf/end_T = get_turf(target)
		if(start_T && end_T)
			log_combat(src, thrown_thing, "thrown", addition="grab from tile in [AREACOORD(start_T)] towards tile at [AREACOORD(end_T)]")
	//MONKESTATION EDIT START
	var/feeble = HAS_TRAIT(src, TRAIT_FEEBLE)
	var/leg_aid = HAS_TRAIT(src, TRAIT_NO_LEG_AID)
	if (feeble && !leg_aid && prob(buckled ? 45 : 15))
		return fumble_throw_item(target, thrown_thing)
	//MONKESTATION EDIT START
	var/power_throw = 0
	if(HAS_TRAIT(src, TRAIT_HULK))
		power_throw++
//	if(HAS_TRAIT(src, TRAIT_DWARF)) // MONKESTATION EDIT OLD
	if(HAS_TRAIT(src, TRAIT_DWARF) && !HAS_TRAIT(src, TRAIT_STABLE_DWARF)) // MONKESTATION EDIT NEW
		power_throw--
	if(HAS_TRAIT(thrown_thing, TRAIT_DWARF))
		power_throw++
	if(neckgrab_throw)
		power_throw++
	//MONKESTATION EDIT START
	if (feeble)
		power_throw = 0
	//MONKESTATION EDIT END
	if(isitem(thrown_thing))
		var/obj/item/thrown_item = thrown_thing
		if(thrown_item.throw_verb)
			verb_text = thrown_item.throw_verb
	visible_message(span_danger("[src] [verb_text][plural_s(verb_text)] [thrown_thing][power_throw ? " really hard!" : "."]"), \
					span_danger("You [verb_text] [thrown_thing][power_throw ? " really hard!" : "."]"))
	log_message("has thrown [thrown_thing] [power_throw > 0 ? "really hard" : ""]", LOG_ATTACK)
	var/extra_throw_range = HAS_TRAIT(src, TRAIT_THROWINGARM) ? 2 : 0
	newtonian_move(get_dir(target, src))
	//MONKESTATION EDIT START
	var/total_throw_range = thrown_thing.throw_range + extra_throw_range
	if (feeble)
		total_throw_range = ceil(total_throw_range / (buckled ? 3 : 2))
	// thrown_thing.safe_throw_at(target, thrown_thing.throw_range + extra_throw_range, max(1,thrown_thing.throw_speed + power_throw), src, null, null, null, move_force) - MONKESTATION EDIT ORIGINAL
	thrown_thing.safe_throw_at(target, total_throw_range, max(1,thrown_thing.throw_speed + power_throw), src, null, null, null, move_force)
	if (!feeble || body_position == LYING_DOWN || buckled)
		return
	var/bulky = FALSE
	var/obj/item/I = thrown_thing
	if (istype(I))
		if (I.w_class > WEIGHT_CLASS_NORMAL || (thrown_thing.throwforce && !leg_aid))
			bulky = I.w_class > WEIGHT_CLASS_NORMAL
		else
			return
	if (!bulky && prob(50))
		return
	visible_message(span_danger("[src] looses [src.p_their()] balance."), \
		span_danger("You lose your balance."))
	Knockdown(2 SECONDS)

	//MONKESTATION EDIT END

/mob/living/carbon/proc/canBeHandcuffed()
	return FALSE

/mob/living/carbon/proc/create_carbon_reagents()
	if (!isnull(reagents))
		return

	create_reagents(1000, REAGENT_HOLDER_ALIVE)

/mob/living/carbon/Topic(href, href_list)
	..()
	if(href_list["embedded_object"] && usr.can_perform_action(src, NEED_DEXTERITY))
		var/obj/item/bodypart/L = locate(href_list["embedded_limb"]) in bodyparts
		if(!L)
			return
		var/obj/item/I = locate(href_list["embedded_object"]) in L.embedded_objects
		if(!I || I.loc != src) //no item, no limb, or item is not in limb or in the person anymore
			return
		SEND_SIGNAL(src, COMSIG_CARBON_EMBED_RIP, I, L)
		return

	if(href_list["gauze_limb"])
		var/obj/item/bodypart/gauzed = locate(href_list["gauze_limb"]) in bodyparts
		if(isnull(gauzed?.current_gauze))
			return
		// rest of the sanity is handled in the proc itself
		gauzed.help_remove_gauze(usr)
		return

	if(href_list["show_paper_note"])
		var/obj/item/paper/paper_note = locate(href_list["show_paper_note"])
		if(!paper_note)
			return

		paper_note.show_through_camera(usr)

/mob/living/carbon/on_fall()
	. = ..()
	loc.handle_fall(src)//it's loc so it doesn't call the mob's handle_fall which does nothing

/mob/living/carbon/is_muzzled()
	for (var/obj/item/clothing/clothing in get_equipped_items())
		if(clothing.clothing_flags & BLOCKS_SPEECH)
			return TRUE
	return FALSE

/mob/living/carbon/resist_buckle()
	if(HAS_TRAIT(src, TRAIT_RESTRAINED))
		changeNext_move(CLICK_CD_BREAKOUT)
		last_special = world.time + CLICK_CD_BREAKOUT
		var/buckle_cd = 60 SECONDS
		if(handcuffed)
			var/obj/item/restraints/O = src.get_item_by_slot(ITEM_SLOT_HANDCUFFED)
			buckle_cd = O.breakouttime
		visible_message(span_warning("[src] attempts to unbuckle [p_them()]self!"), \
					span_notice("You attempt to unbuckle yourself... (This will take around [round(buckle_cd/600,1)] minute\s, and you need to stay still.)"))
		if(do_after(src, buckle_cd, target = src, timed_action_flags = IGNORE_HELD_ITEM))
			if(!buckled)
				return
			buckled.user_unbuckle_mob(src,src)
		else
			if(src && buckled)
				to_chat(src, span_warning("You fail to unbuckle yourself!"))
	else
		buckled.user_unbuckle_mob(src,src)

/mob/living/carbon/resist_fire()
	return !!apply_status_effect(/datum/status_effect/stop_drop_roll)

/mob/living/carbon/resist_restraints()
	var/obj/item/I = null
	var/type = 0
	if(handcuffed)
		I = handcuffed
		type = 1
	else if(legcuffed)
		I = legcuffed
		type = 2
	if(I)
		if(type == 1)
			changeNext_move(CLICK_CD_BREAKOUT)
			last_special = world.time + CLICK_CD_BREAKOUT
		if(type == 2)
			changeNext_move(CLICK_CD_RANGE)
			last_special = world.time + CLICK_CD_RANGE
		cuff_resist(I)


/mob/living/carbon/proc/cuff_resist(obj/item/I, breakouttime = 1 MINUTES, cuff_break = 0)
	if(I.item_flags & BEING_REMOVED)
		to_chat(src, span_warning("You're already attempting to remove [I]!"))
		return
	I.item_flags |= BEING_REMOVED
	breakouttime = I.breakouttime
	if(!cuff_break)
		visible_message(span_warning("[src] attempts to remove [I]!"))
		to_chat(src, span_notice("You attempt to remove [I]... (This will take around [DisplayTimeText(breakouttime)] and you need to stand still.)"))
		if(do_after(src, breakouttime, target = src, timed_action_flags = IGNORE_HELD_ITEM))
			. = clear_cuffs(I, cuff_break)
		else
			to_chat(src, span_warning("You fail to remove [I]!"))

	else if(cuff_break == FAST_CUFFBREAK)
		breakouttime = 50
		visible_message(span_warning("[src] is trying to break [I]!"))
		to_chat(src, span_notice("You attempt to break [I]... (This will take around 5 seconds and you need to stand still.)"))
		if(do_after(src, breakouttime, target = src, timed_action_flags = IGNORE_HELD_ITEM))
			. = clear_cuffs(I, cuff_break)
		else
			to_chat(src, span_warning("You fail to break [I]!"))

	else if(cuff_break == INSTANT_CUFFBREAK)
		. = clear_cuffs(I, cuff_break)
	I.item_flags &= ~BEING_REMOVED

/mob/living/carbon/proc/uncuff()
	if (handcuffed)
		var/obj/item/W = handcuffed
		set_handcuffed(null)
		if (buckled?.buckle_requires_restraints)
			buckled.unbuckle_mob(src)
		update_handcuffed()
		if (client)
			client.screen -= W
		if (W)
			W.forceMove(drop_location())
			W.dropped(src)
			if (W)
				W.layer = initial(W.layer)
				SET_PLANE_EXPLICIT(W, initial(W.plane), src)
		changeNext_move(0)
	if (legcuffed)
		var/obj/item/W = legcuffed
		legcuffed = null
		update_worn_legcuffs()
		if (client)
			client.screen -= W
		if (W)
			W.forceMove(drop_location())
			W.dropped(src)
			if (W)
				W.layer = initial(W.layer)
				SET_PLANE_EXPLICIT(W, initial(W.plane), src)
		changeNext_move(0)
	update_equipment_speed_mods() // In case cuffs ever change speed

/mob/living/carbon/proc/clear_cuffs(obj/item/I, cuff_break)
	if(!I.loc || buckled)
		return FALSE
	if(I != handcuffed && I != legcuffed)
		return FALSE
	visible_message(span_danger("[src] manages to [cuff_break ? "break" : "remove"] [I]!"))
	to_chat(src, span_notice("You successfully [cuff_break ? "break" : "remove"] [I]."))

	if(cuff_break)
		. = !((I == handcuffed) || (I == legcuffed))
		qdel(I)
		return TRUE

	else
		if(I == handcuffed)
			handcuffed.forceMove(drop_location())
			set_handcuffed(null)
			I.dropped(src)
			if(buckled?.buckle_requires_restraints)
				buckled.unbuckle_mob(src)
			update_handcuffed()
			return TRUE
		if(I == legcuffed)
			legcuffed.forceMove(drop_location())
			legcuffed = null
			I.dropped(src)
			update_worn_legcuffs()
			return TRUE

/mob/living/carbon/proc/accident(obj/item/I)
	if(!I || (I.item_flags & ABSTRACT) || HAS_TRAIT(I, TRAIT_NODROP))
		return

	dropItemToGround(I)

	var/modifier = 0
	if(HAS_TRAIT(src, TRAIT_CLUMSY))
		modifier -= 40 //Clumsy people are more likely to hit themselves -Honk!

	switch(rand(1,100)+modifier) //91-100=Nothing special happens
		if(-INFINITY to 0) //attack yourself
			INVOKE_ASYNC(I, TYPE_PROC_REF(/obj/item, attack), src, src)
		if(1 to 30) //throw it at yourself
			I.throw_impact(src)
		if(31 to 60) //Throw object in facing direction
			var/turf/target = get_turf(loc)
			var/range = rand(2,I.throw_range)
			for(var/i in 1 to range-1)
				var/turf/new_turf = get_step(target, dir)
				target = new_turf
				if(new_turf.density)
					break
			I.throw_at(target,I.throw_range,I.throw_speed,src)
		if(61 to 90) //throw it down to the floor
			var/turf/target = get_turf(loc)
			I.safe_throw_at(target,I.throw_range,I.throw_speed,src, force = move_force)

/mob/living/carbon/attack_ui(slot, params)
	if(!has_hand_for_held_index(active_hand_index))
		return 0
	return ..()

/mob/living/proc/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	if((HAS_TRAIT(src, TRAIT_NOHUNGER) || HAS_TRAIT(src, TRAIT_TOXINLOVER)) && !force)
		return TRUE
	var/starting_dir = dir
	if(nutrition < 100 && !blood && !force)
		if(message)
			visible_message(span_warning("[src] dry heaves!"), \
							span_userdanger("You try to throw up, but there's nothing in your stomach!"))
		if(stun)
			Stun(20 SECONDS)
		return TRUE
	if(message)
		visible_message(span_danger("[src] throws up!"), span_userdanger("You throw up!"))
		if(!isflyperson(src))
			add_mood_event("vomit", /datum/mood_event/vomit)

	if(stun)
		Stun(8 SECONDS)

	playsound(get_turf(src), 'sound/effects/splat.ogg', 50, TRUE)
	var/turf/T = get_turf(src)
	if(!blood)
		adjust_nutrition(-lost_nutrition)
		adjustToxLoss(-3)
	for(var/i=0 to distance)
		if(blood)
			if(T)
				add_splatter_floor(T)
			if(harm)
				adjustBruteLoss(3)
		else
			if(T)
				T.add_vomit_floor(src, vomit_type, purge_ratio) //toxic barf looks different || call purge when doing detoxicfication to pump more chems out of the stomach.
		T = get_step(T, starting_dir)
		if (T?.is_blocked_turf())
			break
	return TRUE

/mob/living/carbon/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	if((HAS_TRAIT(src, TRAIT_NOHUNGER) || HAS_TRAIT(src, TRAIT_TOXINLOVER)) && !force)
		return TRUE

	if(!has_mouth())
		return TRUE

	SEND_SIGNAL(src, COMSIG_CARBON_VOMITED, distance, force)
	var/starting_dir = dir
	if(nutrition < 100 && !blood && !force)
		if(message)
			visible_message(span_warning("[src] dry heaves!"), \
							span_userdanger("You try to throw up, but there's nothing in your stomach!"))
		if(stun)
			Stun(20 SECONDS)
		return TRUE

	if(is_mouth_covered()) //make this add a blood/vomit overlay later it'll be hilarious
		if(message)
			visible_message(span_danger("[src] throws up all over [p_them()]self!"), \
							span_userdanger("You throw up all over yourself!"))
			add_mood_event("vomit", /datum/mood_event/vomitself)
		distance = 0
	else
		if(message)
			visible_message(span_danger("[src] throws up!"), span_userdanger("You throw up!"))
			if(!isflyperson(src))
				add_mood_event("vomit", /datum/mood_event/vomit)

	if(stun)
		Stun(8 SECONDS)

	playsound(get_turf(src), 'sound/effects/splat.ogg', 50, TRUE)
	var/turf/T = get_turf(src)
	if(!blood)
		adjust_nutrition(-lost_nutrition)
		adjustToxLoss(-3)

	for(var/i=0 to distance)
		if(blood)
			if(T)
				add_splatter_floor(T)
			if(harm)
				adjustBruteLoss(3)
		else
			if(T)
				T.add_vomit_floor(src, vomit_type, purge_ratio) //toxic barf looks different || call purge when doing detoxicfication to pump more chems out of the stomach.
		T = get_step(T, starting_dir)
		if (T?.is_blocked_turf())
			break
	return TRUE

/**
 * Expel the reagents you just tried to ingest
 *
 * When you try to ingest reagents but you do not have a stomach
 * you will spew the reagents on the floor.
 *
 * Vars:
 * * bite: /atom the reagents to expel
 * * amount: int The amount of reagent
 */
/mob/living/carbon/proc/expel_ingested(atom/bite, amount)
	visible_message(span_danger("[src] throws up all over [p_them()]self!"), \
					span_userdanger("You are unable to keep the [bite] down without a stomach!"))

	var/turf/floor = get_turf(src)
	var/obj/effect/decal/cleanable/vomit/spew = new(floor, get_static_viruses())
	bite.reagents?.trans_to(spew, amount, transfered_by = src)

/mob/living/carbon/proc/spew_organ(power = 5, amt = 1)
	for(var/i in 1 to amt)
		if(!organs.len)
			break //Guess we're out of organs!
		var/obj/item/organ/guts = pick(organs)
		var/turf/T = get_turf(src)
		guts.Remove(src)
		guts.forceMove(T)
		var/atom/throw_target = get_edge_target_turf(guts, dir)
		guts.throw_at(throw_target, power, 4, src)


/mob/living/carbon/fully_replace_character_name(oldname,newname)
	. = ..()
	if(dna)
		dna.real_name = real_name
	var/obj/item/bodypart/head/my_head = get_bodypart(BODY_ZONE_HEAD)
	if(my_head)
		my_head.real_name = real_name


/mob/living/carbon/set_body_position(new_value)
	. = ..()
	if(isnull(.))
		return
	if(new_value == LYING_DOWN)
		if(HAS_TRAIT(src, TRAIT_FOOD_SLIDE))
			add_movespeed_modifier(/datum/movespeed_modifier/belly_slide)
		else
			add_movespeed_modifier(/datum/movespeed_modifier/carbon_crawling)
	else
		if(HAS_TRAIT(src, TRAIT_FOOD_SLIDE))
			remove_movespeed_modifier(/datum/movespeed_modifier/belly_slide)
		else
			remove_movespeed_modifier(/datum/movespeed_modifier/carbon_crawling)


//Updates the mob's health from bodyparts and mob damage variables
/mob/living/carbon/updatehealth()
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return
	var/total_burn = 0
	var/total_brute = 0
	for(var/X in bodyparts) //hardcoded to streamline things a bit
		var/obj/item/bodypart/BP = X
		total_brute += (BP.brute_dam * BP.body_damage_coeff)
		total_burn += (BP.burn_dam * BP.body_damage_coeff)
	set_health(round(maxHealth - getOxyLoss() - getToxLoss() - getCloneLoss() - total_burn - total_brute, DAMAGE_PRECISION))
	update_stat()
	on_stamina_update()
	if(((maxHealth - total_burn) < HEALTH_THRESHOLD_DEAD*2) && stat == DEAD )
		become_husk(BURN)
	med_hud_set_health()
	if(stat == SOFT_CRIT)
		add_movespeed_modifier(/datum/movespeed_modifier/carbon_softcrit)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/carbon_softcrit)
	SEND_SIGNAL(src, COMSIG_LIVING_HEALTH_UPDATE)

/mob/living/carbon/on_stamina_update()
	if(!stamina)
		return
	var/stam = stamina.current
	var/max = stamina.maximum
	var/is_exhausted = HAS_TRAIT_FROM(src, TRAIT_EXHAUSTED, STAMINA)
	var/is_stam_stunned = HAS_TRAIT_FROM(src, TRAIT_INCAPACITATED, STAMINA)
	if((stam < max * STAMINA_EXHAUSTION_THRESHOLD_MODIFIER) && !is_exhausted)
		ADD_TRAIT(src, TRAIT_EXHAUSTED, STAMINA)
		ADD_TRAIT(src, TRAIT_NO_SPRINT, STAMINA)
		add_movespeed_modifier(/datum/movespeed_modifier/exhaustion)

	if((stam < max * STAMINA_STUN_THRESHOLD_MODIFIER) && !is_stam_stunned && stat <= SOFT_CRIT)
		stamina_stun()

	if(is_exhausted && (stam > max * STAMINA_EXHAUSTION_THRESHOLD_MODIFIER_EXIT))
		REMOVE_TRAIT(src, TRAIT_EXHAUSTED, STAMINA)
		REMOVE_TRAIT(src, TRAIT_NO_SPRINT, STAMINA)
		remove_movespeed_modifier(/datum/movespeed_modifier/exhaustion)

	update_stamina_hud()

/datum/movespeed_modifier/exhaustion
	id = "exhaustion"
	multiplicative_slowdown = STAMINA_EXHAUSTION_MOVESPEED_SLOWDOWN

/mob/living/carbon/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		if(SSmapping.level_trait(z, ZTRAIT_NOXRAY))
			set_sight(null)
		else if(is_secret_level(z))
			set_sight(initial(sight))
		else
			set_sight(SEE_TURFS|SEE_MOBS|SEE_OBJS)
		set_invis_see(SEE_INVISIBLE_OBSERVER)
		return

	var/new_sight = initial(sight)
	lighting_cutoff = initial(lighting_cutoff)
	lighting_color_cutoffs = list(lighting_cutoff_red, lighting_cutoff_green, lighting_cutoff_blue)

	var/obj/item/organ/internal/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		set_invis_see(eyes.see_invisible)
		new_sight |= eyes.sight_flags
		if(!isnull(eyes.lighting_cutoff))
			lighting_cutoff = eyes.lighting_cutoff
		if(!isnull(eyes.color_cutoffs))
			lighting_color_cutoffs = blend_cutoff_colors(lighting_color_cutoffs, eyes.color_cutoffs)

	if(client.eye && client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return

	if(glasses)
		new_sight |= glasses.vision_flags
		if(glasses.invis_override)
			set_invis_see(glasses.invis_override)
		else
			set_invis_see(min(glasses.invis_view, see_invisible))
		if(!isnull(glasses.lighting_cutoff))
			lighting_cutoff = max(lighting_cutoff, glasses.lighting_cutoff)
		if(length(glasses.color_cutoffs))
			lighting_color_cutoffs = blend_cutoff_colors(lighting_color_cutoffs, glasses.color_cutoffs)


	if(HAS_TRAIT(src, TRAIT_TRUE_NIGHT_VISION))
		lighting_cutoff = max(lighting_cutoff, LIGHTING_CUTOFF_HIGH)

	if(HAS_TRAIT(src, TRAIT_MESON_VISION))
		new_sight |= SEE_TURFS
		lighting_cutoff = max(lighting_cutoff, LIGHTING_CUTOFF_MEDIUM)

	if(HAS_TRAIT(src, TRAIT_THERMAL_VISION))
		new_sight |= SEE_MOBS
		lighting_cutoff = max(lighting_cutoff, LIGHTING_CUTOFF_MEDIUM)

	if(HAS_TRAIT(src, TRAIT_XRAY_VISION))
		new_sight |= SEE_TURFS|SEE_MOBS|SEE_OBJS

	if(see_override)
		set_invis_see(see_override)

	if(SSmapping.level_trait(z, ZTRAIT_NOXRAY))
		new_sight = NONE

	set_sight(new_sight)
	return ..()

/**
 * Calculates how visually impaired the mob is by their equipment and other factors
 *
 * This is where clothing adds its various vision limiting effects, such as welding helmets
 */
/mob/living/carbon/proc/update_tint()
	var/tint = 0
	if(isclothing(head))
		tint += head.tint
	if(isclothing(wear_mask))
		tint += wear_mask.tint
	if(isclothing(glasses))
		tint += glasses.tint

	var/obj/item/organ/internal/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		tint += eyes.tint

	if(tint >= TINT_BLIND)
		become_blind(EYES_COVERED)

	else if(tint >= TINT_DARKENED)
		cure_blind(EYES_COVERED)
		overlay_fullscreen("tint", /atom/movable/screen/fullscreen/impaired, 2)

	else
		cure_blind(EYES_COVERED)
		clear_fullscreen("tint", 0 SECONDS)

//this handles hud updates
/mob/living/carbon/update_damage_hud()
	..() // monkestation edit
	if(!client)
		return

	if(health <= crit_threshold && !HAS_TRAIT(src, TRAIT_NOCRITOVERLAY))
		var/severity = 0
		switch(health)
			if(-20 to -10)
				severity = 1
			if(-30 to -20)
				severity = 2
			if(-40 to -30)
				severity = 3
			if(-50 to -40)
				severity = 4
			if(-50 to -40)
				severity = 5
			if(-60 to -50)
				severity = 6
			if(-70 to -60)
				severity = 7
			if(-90 to -70)
				severity = 8
			if(-95 to -90)
				severity = 9
			if(-INFINITY to -95)
				severity = 10
		if(stat != HARD_CRIT)
			var/visionseverity = 4
			switch(health)
				if(-8 to -4)
					visionseverity = 5
				if(-12 to -8)
					visionseverity = 6
				if(-16 to -12)
					visionseverity = 7
				if(-20 to -16)
					visionseverity = 8
				if(-24 to -20)
					visionseverity = 9
				if(-INFINITY to -24)
					visionseverity = 10
			overlay_fullscreen("critvision", /atom/movable/screen/fullscreen/crit/vision, visionseverity)
		else
			clear_fullscreen("critvision")
		overlay_fullscreen("crit", /atom/movable/screen/fullscreen/crit, severity)
	else
		clear_fullscreen("crit")
		clear_fullscreen("critvision")

	//Oxygen damage overlay
	if(oxyloss)
		var/severity = 0
		switch(oxyloss)
			if(10 to 20)
				severity = 1
			if(20 to 25)
				severity = 2
			if(25 to 30)
				severity = 3
			if(30 to 35)
				severity = 4
			if(35 to 40)
				severity = 5
			if(40 to 45)
				severity = 6
			if(45 to INFINITY)
				severity = 7
		overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/oxy, severity)
	else
		clear_fullscreen("oxy")

	//Fire and Brute damage overlay (BSSR)
	var/hurtdamage = getBruteLoss() + getFireLoss() + damageoverlaytemp
	if(hurtdamage && !HAS_TRAIT(src, TRAIT_NO_DAMAGE_OVERLAY))
		var/severity = 0
		switch(hurtdamage)
			if(5 to 15)
				severity = 1
			if(15 to 30)
				severity = 2
			if(30 to 45)
				severity = 3
			if(45 to 70)
				severity = 4
			if(70 to 85)
				severity = 5
			if(85 to INFINITY)
				severity = 6
		overlay_fullscreen("brute", /atom/movable/screen/fullscreen/brute, severity)
	else
		clear_fullscreen("brute")

/mob/living/carbon/update_health_hud(shown_health_amount)
	if(!client || !hud_used?.healths)
		return

	if(stat == DEAD)
		hud_used.healths.icon_state = "health7"
		return

	if(SEND_SIGNAL(src, COMSIG_CARBON_UPDATING_HEALTH_HUD, shown_health_amount) & COMPONENT_OVERRIDE_HEALTH_HUD)
		return

	if(shown_health_amount == null)
		shown_health_amount = health

	if(shown_health_amount >= maxHealth)
		hud_used.healths.icon_state = "health0"

	else if(shown_health_amount > maxHealth * 0.8)
		hud_used.healths.icon_state = "health1"

	else if(shown_health_amount > maxHealth * 0.6)
		hud_used.healths.icon_state = "health2"

	else if(shown_health_amount > maxHealth * 0.4)
		hud_used.healths.icon_state = "health3"

	else if(shown_health_amount > maxHealth*0.2)
		hud_used.healths.icon_state = "health4"

	else if(shown_health_amount > 0)
		hud_used.healths.icon_state = "health5"

	else
		hud_used.healths.icon_state = "health6"

/mob/living/carbon/update_stamina_hud() //monkestation edit
	if(!client || !hud_used?.stamina)
		return

	//MONKESTATION EDIT START
	var/current_stamina = stamina.current

	if(stamina.current <= (0.20 * STAMINA_MAX)) //stamina stun threshold
		hud_used.stamina.icon_state = "stamina_dead"
	else if(current_stamina <= (0.30 * STAMINA_MAX)) //exhaustion threshold
		hud_used.stamina.icon_state = "stamina_crit"
	else if(current_stamina <= (0.40 * STAMINA_MAX))
		hud_used.stamina.icon_state = "stamina_5"
	else if(current_stamina <= (0.60 * STAMINA_MAX))
		hud_used.stamina.icon_state = "stamina_4"
	else if(current_stamina <= (0.70 * STAMINA_MAX))
		hud_used.stamina.icon_state = "stamina_3"
	else if(current_stamina <= (0.80 * STAMINA_MAX))
		hud_used.stamina.icon_state = "stamina_2"
	else if(current_stamina <= (0.90 * STAMINA_MAX))
		hud_used.stamina.icon_state = "stamina_1"
	else
		hud_used.stamina.icon_state = "stamina_full"
	//MONKESTATION EDIT STOP

/mob/living/carbon/proc/update_spacesuit_hud_icon(cell_state = "empty")
	if(hud_used?.spacesuit)
		hud_used.spacesuit.icon_state = "spacesuit_[cell_state]"


/mob/living/carbon/set_health(new_value)
	. = ..()
	if(. > hardcrit_threshold)
		if(health <= hardcrit_threshold && !HAS_TRAIT(src, TRAIT_NOHARDCRIT))
			ADD_TRAIT(src, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT)
	else if(health > hardcrit_threshold)
		REMOVE_TRAIT(src, TRAIT_KNOCKEDOUT, CRIT_HEALTH_TRAIT)
	if(CONFIG_GET(flag/near_death_experience))
		if(. > HEALTH_THRESHOLD_NEARDEATH)
			if(health <= HEALTH_THRESHOLD_NEARDEATH && !HAS_TRAIT(src, TRAIT_NODEATH))
				ADD_TRAIT(src, TRAIT_SIXTHSENSE, "near-death")
		else if(health > HEALTH_THRESHOLD_NEARDEATH)
			REMOVE_TRAIT(src, TRAIT_SIXTHSENSE, "near-death")


/mob/living/carbon/update_stat()
	if(HAS_TRAIT(src, TRAIT_GODMODE))
		return
	if(stat != DEAD)
		if(health <= HEALTH_THRESHOLD_DEAD && !HAS_TRAIT(src, TRAIT_NODEATH))
			death()
			return
		if(health <= hardcrit_threshold && !HAS_TRAIT(src, TRAIT_NOHARDCRIT))
			set_stat(HARD_CRIT)
		else if(HAS_TRAIT(src, TRAIT_KNOCKEDOUT))
			set_stat(UNCONSCIOUS)
		else if(health <= crit_threshold && !HAS_TRAIT(src, TRAIT_NOSOFTCRIT))
			set_stat(SOFT_CRIT)
		else
			set_stat(CONSCIOUS)
	update_damage_hud()
	update_health_hud()
	update_stamina_hud()
	med_hud_set_status()


//called when we get cuffed/uncuffed
/mob/living/carbon/proc/update_handcuffed()
	if(handcuffed)
		drop_all_held_items()
		stop_pulling()
		throw_alert(ALERT_HANDCUFFED, /atom/movable/screen/alert/restrained/handcuffed, new_master = src.handcuffed)
		add_mood_event("handcuffed", /datum/mood_event/handcuffed)
	else
		clear_alert(ALERT_HANDCUFFED)
		clear_mood_event("handcuffed")
	update_mob_action_buttons() //some of our action buttons might be unusable when we're handcuffed.
	update_worn_handcuffs()
	update_hud_handcuffed()

/mob/living/carbon/revive(full_heal_flags = NONE, excess_healing = 0, force_grab_ghost = FALSE)
	if(excess_healing)
		if(dna && !HAS_TRAIT(src, TRAIT_NOBLOOD))
			blood_volume += (excess_healing * 2) //1 excess = 10 blood

		for(var/obj/item/organ/organ as anything in organs)
			organ.apply_organ_damage(excess_healing * -1) //1 excess = 5 organ damage healed

	return ..()

/mob/living/carbon/heal_and_revive(heal_to = 75, revive_message)
	// We can't heal them if they're missing a heart
	if(needs_heart() && !get_organ_slot(ORGAN_SLOT_HEART))
		return FALSE

	// We can't heal them if they're missing their lungs
	if(!HAS_TRAIT(src, TRAIT_NOBREATH) && !isnull(dna?.species.mutantlungs) && !get_organ_slot(ORGAN_SLOT_LUNGS))
		return FALSE

	// And we can't heal them if they're missing their liver
	if(!HAS_TRAIT(src, TRAIT_LIVERLESS_METABOLISM) && !isnull(dna?.species.mutantliver) && !get_organ_slot(ORGAN_SLOT_LIVER))
		return FALSE

	return ..()

/mob/living/carbon/fully_heal(heal_flags = HEAL_ALL)

	// Should be handled via signal on embedded, or via heal on bodypart
	// Otherwise I don't care to give it a separate flag
	remove_all_embedded_objects()

	if(heal_flags & HEAL_NEGATIVE_DISEASES)
		for(var/datum/disease/disease as anything in diseases)
			if(disease.severity != DISEASE_SEVERITY_POSITIVE)
				disease.cure(FALSE)

	if(heal_flags & HEAL_POSTIVE_DISEASES)
		for(var/datum/disease/disease as anything in diseases)
			if(disease.severity == DISEASE_SEVERITY_POSITIVE)
				disease.cure(FALSE)

	if(heal_flags & HEAL_WOUNDS)
		for(var/datum/wound/wound as anything in all_wounds)
			wound.remove_wound()

	if(heal_flags & HEAL_LIMBS)
		regenerate_limbs()

	if(heal_flags & (HEAL_REFRESH_ORGANS|HEAL_ORGANS))
		regenerate_organs(regenerate_existing = (heal_flags & HEAL_REFRESH_ORGANS))

	if(heal_flags & HEAL_TRAUMAS)
		cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
		// Addictions are like traumas
		if(mind)
			for(var/addiction_type in subtypesof(/datum/addiction))
				mind.remove_addiction_points(addiction_type, MAX_ADDICTION_POINTS) //Remove the addiction!

	if(heal_flags & HEAL_RESTRAINTS)
		QDEL_NULL(handcuffed)
		QDEL_NULL(legcuffed)
		set_handcuffed(null)
		update_handcuffed()

	stamina.revitalize(forced = TRUE)
	return ..()

/mob/living/carbon/can_be_revived()
	if(!get_organ_by_type(/obj/item/organ/internal/brain) && (!mind || !mind.has_antag_datum(/datum/antagonist/changeling)) || HAS_TRAIT(src, TRAIT_HUSK))
		return FALSE
	return ..()

/mob/living/carbon/proc/can_defib()
	if (HAS_TRAIT(src, TRAIT_SUICIDED))
		return DEFIB_FAIL_SUICIDE

	if (HAS_TRAIT(src, TRAIT_HUSK))
		return DEFIB_FAIL_HUSK

	if (HAS_TRAIT(src, TRAIT_DEFIB_BLACKLISTED))
		return DEFIB_FAIL_BLACKLISTED

	if ((getBruteLoss() >= MAX_REVIVE_BRUTE_DAMAGE) || (getFireLoss() >= MAX_REVIVE_FIRE_DAMAGE))
		return DEFIB_FAIL_TISSUE_DAMAGE

	// Only check for a heart if they actually need a heart. Who would've thunk
	if (needs_heart())
		var/obj/item/organ/internal/heart = get_organ_by_type(/obj/item/organ/internal/heart)

		if (!heart)
			return DEFIB_FAIL_NO_HEART

		if (heart.organ_flags & ORGAN_FAILING)
			return DEFIB_FAIL_FAILING_HEART

	var/obj/item/organ/internal/brain/current_brain = get_organ_by_type(/obj/item/organ/internal/brain)

	if (QDELETED(current_brain))
		return DEFIB_FAIL_NO_BRAIN

	if (current_brain.organ_flags & ORGAN_FAILING)
		return DEFIB_FAIL_FAILING_BRAIN

	if (current_brain.suicided || (current_brain.brainmob && HAS_TRAIT(current_brain.brainmob, TRAIT_SUICIDED)))
		return DEFIB_FAIL_NO_INTELLIGENCE

	if(key && key[1] == "@") // Adminghosts
		return DEFIB_NOGRAB_AGHOST

	return DEFIB_POSSIBLE

/mob/living/carbon/harvest(mob/living/user)
	if(QDELETED(src))
		return
	var/organs_amt = 0
	for(var/obj/item/organ/organ as anything in organs)
		if(prob(50))
			organs_amt++
			organ.Remove(src)
			organ.forceMove(drop_location())
	if(organs_amt)
		to_chat(user, span_notice("You retrieve some of [src]\'s internal organs!"))
	remove_all_embedded_objects()

/// Creates body parts for this carbon completely from scratch.
/// Optionally takes a map of body zones to what type to instantiate instead of them.
/mob/living/carbon/proc/create_bodyparts(list/overrides)
	var/l_arm_index_next = -1
	var/r_arm_index_next = 0
	for(var/obj/item/bodypart/bodypart_path as anything in bodyparts)
		var/real_body_part_path = overrides?[initial(bodypart_path.body_zone)] || bodypart_path
		var/obj/item/bodypart/bodypart_instance = new real_body_part_path()
		bodypart_instance.set_owner(src)
		bodyparts.Remove(bodypart_path)
		bodypart_instance.check_adding_composition(src)
		add_bodypart(bodypart_instance)
		switch(bodypart_instance.body_part)
			if(ARM_LEFT)
				l_arm_index_next += 2
				bodypart_instance.held_index = l_arm_index_next //1, 3, 5, 7...
				hand_bodyparts += bodypart_instance
			if(ARM_RIGHT)
				r_arm_index_next += 2
				bodypart_instance.held_index = r_arm_index_next //2, 4, 6, 8...
				hand_bodyparts += bodypart_instance


///Proc to hook behavior on bodypart additions. Do not directly call. You're looking for [/obj/item/bodypart/proc/try_attach_limb()].
/mob/living/carbon/proc/add_bodypart(obj/item/bodypart/new_bodypart)
	SHOULD_NOT_OVERRIDE(TRUE)

	bodyparts += new_bodypart
	new_bodypart.set_owner(src)

	switch(new_bodypart.body_part)
		if(LEG_LEFT, LEG_RIGHT)
			set_num_legs(num_legs + 1)
			if(!new_bodypart.bodypart_disabled)
				set_usable_legs(usable_legs + 1)
		if(ARM_LEFT, ARM_RIGHT)
			set_num_hands(num_hands + 1)
			if(!new_bodypart.bodypart_disabled)
				set_usable_hands(usable_hands + 1)


///Proc to hook behavior on bodypart removals.  Do not directly call. You're looking for [/obj/item/bodypart/proc/drop_limb()].
/mob/living/carbon/proc/remove_bodypart(obj/item/bodypart/old_bodypart)
	SHOULD_NOT_OVERRIDE(TRUE)
	old_bodypart.on_removal()
	bodyparts -= old_bodypart
	switch(old_bodypart.body_part)
		if(LEG_LEFT, LEG_RIGHT)
			set_num_legs(num_legs - 1)
			if(!old_bodypart.bodypart_disabled)
				set_usable_legs(usable_legs - 1)
		if(ARM_LEFT, ARM_RIGHT)
			set_num_hands(num_hands - 1)
			if(!old_bodypart.bodypart_disabled)
				set_usable_hands(usable_hands - 1)


///Updates the bodypart speed modifier based on our bodyparts.
/mob/living/carbon/proc/update_bodypart_speed_modifier()
	var/final_modification = 0
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		final_modification += bodypart.speed_modifier
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/bodypart, TRUE, final_modification)

/mob/living/carbon/proc/create_internal_organs()
	for(var/obj/item/organ/internal/internal_organ in organs)
		internal_organ.Insert(src)

/proc/cmp_organ_slot_asc(slot_a, slot_b)
	return GLOB.organ_process_order.Find(slot_a) - GLOB.organ_process_order.Find(slot_b)

/mob/living/carbon/proc/get_footprint_sprite()
	return FOOTPRINT_SPRITE_PAWS

/mob/living/carbon/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_AI, "Make AI")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_BODYPART, "Modify bodypart")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_ORGANS, "Modify organs")
	VV_DROPDOWN_OPTION(VV_HK_MARTIAL_ART, "Give Martial Arts")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_TRAUMA, "Give Brain Trauma")
	VV_DROPDOWN_OPTION(VV_HK_CURE_TRAUMA, "Cure Brain Traumas")

/mob/living/carbon/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_MODIFY_BODYPART])
		if(!check_rights(R_SPAWN))
			return
		var/edit_action = input(usr, "What would you like to do?","Modify Body Part") as null|anything in list("replace","remove")
		if(!edit_action)
			return
		var/list/limb_list = list()
		if(edit_action == "remove")
			for(var/obj/item/bodypart/B as anything in bodyparts)
				limb_list += B.body_zone
				limb_list -= BODY_ZONE_CHEST
		else
			limb_list = list(BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_CHEST)
		var/result = input(usr, "Please choose which bodypart to [edit_action]","[capitalize(edit_action)] Bodypart") as null|anything in sort_list(limb_list)
		if(result)
			var/obj/item/bodypart/BP = get_bodypart(result)
			var/list/limbtypes = list()
			switch(result)
				if(BODY_ZONE_CHEST)
					limbtypes = typesof(/obj/item/bodypart/chest)
				if(BODY_ZONE_R_ARM)
					limbtypes = typesof(/obj/item/bodypart/arm/right)
				if(BODY_ZONE_L_ARM)
					limbtypes = typesof(/obj/item/bodypart/arm/left)
				if(BODY_ZONE_HEAD)
					limbtypes = typesof(/obj/item/bodypart/head)
				if(BODY_ZONE_L_LEG)
					limbtypes = typesof(/obj/item/bodypart/leg/left)
				if(BODY_ZONE_R_LEG)
					limbtypes = typesof(/obj/item/bodypart/leg/right)
			switch(edit_action)
				if("remove")
					if(BP)
						BP.drop_limb()
						admin_ticket_log("[key_name(usr)] has removed [src]'s [parse_zone(BP.body_zone)]") // MONKESTATION EDIT - tgui tickets
					else
						to_chat(usr, span_boldwarning("[src] doesn't have such bodypart."))
						admin_ticket_log("[key_name(usr)] has attempted to modify the bodyparts of [src]") // MONKESTATION EDIT - tgui tickets
				if("replace")
					var/limb2add = input(usr, "Select a bodypart type to add", "Add/Replace Bodypart") as null|anything in sort_list(limbtypes)
					var/obj/item/bodypart/new_bp = new limb2add()

					if(new_bp.replace_limb(src, special = TRUE))
						admin_ticket_log("[key_name(usr)] has replaced [src]'s [BP.type] with [new_bp.type]") // MONKESTATION EDIT - tgui tickets
						qdel(BP)
					else
						to_chat(usr, "Failed to replace bodypart! They might be incompatible.")
						admin_ticket_log("[key_name(usr)] has attempted to modify the bodyparts of [src]") // MONKESTATION EDIT - tgui tickets

	if(href_list[VV_HK_MAKE_AI])
		if(!check_rights(R_SPAWN))
			return
		if(tgui_alert(usr,"Confirm mob type change?",,list("Transform","Cancel")) != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makeai"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MODIFY_ORGANS])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/manipulate_organs, src)
	if(href_list[VV_HK_MARTIAL_ART])
		if(!check_rights(NONE))
			return
		var/list/artpaths = subtypesof(/datum/martial_art)
		var/list/artnames = list()
		for(var/i in artpaths)
			var/datum/martial_art/M = i
			artnames[initial(M.name)] = M
		var/result = input(usr, "Choose the martial art to teach","JUDO CHOP") as null|anything in sort_list(artnames, GLOBAL_PROC_REF(cmp_typepaths_asc))
		if(!usr)
			return
		if(QDELETED(src))
			to_chat(usr, span_boldwarning("Mob doesn't exist anymore."))
			return
		if(result)
			var/chosenart = artnames[result]
			var/datum/martial_art/MA = new chosenart
			MA.teach(src)
			log_admin("[key_name(usr)] has taught [MA] to [key_name(src)].")
			message_admins(span_notice("[key_name_admin(usr)] has taught [MA] to [key_name_admin(src)]."))
	if(href_list[VV_HK_GIVE_TRAUMA])
		if(!check_rights(NONE))
			return
		var/list/traumas = subtypesof(/datum/brain_trauma)
		var/result = input(usr, "Choose the brain trauma to apply","Traumatize") as null|anything in sort_list(traumas, GLOBAL_PROC_REF(cmp_typepaths_asc))
		if(!usr)
			return
		if(QDELETED(src))
			to_chat(usr, "Mob doesn't exist anymore")
			return
		if(!result)
			return
		var/datum/brain_trauma/BT = gain_trauma(result)
		if(BT)
			log_admin("[key_name(usr)] has traumatized [key_name(src)] with [BT.name]")
			message_admins(span_notice("[key_name_admin(usr)] has traumatized [key_name_admin(src)] with [BT.name]."))
	if(href_list[VV_HK_CURE_TRAUMA])
		if(!check_rights(NONE))
			return
		cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)
		log_admin("[key_name(usr)] has cured all traumas from [key_name(src)].")
		message_admins(span_notice("[key_name_admin(usr)] has cured all traumas from [key_name_admin(src)]."))

/mob/living/carbon/can_resist()
	return bodyparts.len > 2 && ..()

/mob/living/carbon/proc/hypnosis_vulnerable()
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		return FALSE
	if(has_status_effect(/datum/status_effect/hallucination))
		return TRUE
	if(IsSleeping() || IsUnconscious())
		return TRUE
	if(HAS_TRAIT(src, TRAIT_DUMB))
		return TRUE
	if(mob_mood.sanity < SANITY_UNSTABLE)
		return TRUE

/mob/living/carbon/wash(clean_types)
	. = ..()

	// Wash equipped stuff that cannot be covered
	for(var/obj/item/held_thing in held_items)
		if(held_thing.wash(clean_types))
			. = TRUE

	if(back?.wash(clean_types))
		update_worn_back(0)
		. = TRUE

	if(head?.wash(clean_types))
		update_worn_head()
		. = TRUE

	// Check and wash stuff that can be covered
	var/obscured = check_obscured_slots()

	// If the eyes are covered by anything but glasses, that thing will be covering any potential glasses as well.
	if(glasses && is_eyes_covered(ITEM_SLOT_MASK|ITEM_SLOT_HEAD) && glasses.wash(clean_types))
		update_worn_glasses()
		. = TRUE

	if(wear_mask && !(obscured & ITEM_SLOT_MASK) && wear_mask.wash(clean_types))
		update_worn_mask()
		. = TRUE

	if(ears && !(obscured & ITEM_SLOT_EARS) && ears.wash(clean_types))
		update_inv_ears()
		. = TRUE

	if(wear_neck && !(obscured & ITEM_SLOT_NECK) && wear_neck.wash(clean_types))
		update_worn_neck()
		. = TRUE

	if(shoes && !(obscured & ITEM_SLOT_FEET) && shoes.wash(clean_types))
		update_worn_shoes()
		. = TRUE

	if(gloves && !(obscured & ITEM_SLOT_GLOVES) && gloves.wash(clean_types))
		update_worn_gloves()
		. = TRUE

/// if any of our bodyparts are bleeding
/mob/living/carbon/proc/is_bleeding()
	if(HAS_TRAIT(src, TRAIT_NOBLOOD))
		return FALSE
	for(var/obj/item/bodypart/part as anything in bodyparts)
		if(part.get_modified_bleed_rate())
			return TRUE

/// get our total bleedrate
/mob/living/carbon/proc/get_total_bleed_rate()
	if(HAS_TRAIT(src, TRAIT_NOBLOOD))
		return 0
	var/total_bleed_rate = 0
	for(var/obj/item/bodypart/part as anything in bodyparts)
		total_bleed_rate += part.get_modified_bleed_rate()

	return total_bleed_rate

/**
 * generate_fake_scars()- for when you want to scar someone, but you don't want to hurt them first. These scars don't count for temporal scarring (hence, fake)
 *
 * If you want a specific wound scar, pass that wound type as the second arg, otherwise you can pass a list like WOUND_LIST_SLASH to generate a random cut scar.
 *
 * Arguments:
 * * num_scars- A number for how many scars you want to add
 * * forced_type- Which wound or category of wounds you want to choose from, WOUND_LIST_BLUNT, WOUND_LIST_SLASH, or WOUND_LIST_BURN (or some combination). If passed a list, picks randomly from the listed wounds. Defaults to all 3 types
 */
/mob/living/carbon/proc/generate_fake_scars(num_scars, forced_type)
	for(var/i in 1 to num_scars)
		var/datum/scar/scaries = new
		var/obj/item/bodypart/scar_part = pick(bodyparts)

		var/wound_type
		if(forced_type)
			if(islist(forced_type))
				wound_type = pick(forced_type)
			else
				wound_type = forced_type
		else
			for (var/datum/wound/path as anything in shuffle(GLOB.all_wound_pregen_data))
				var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[path]
				if (pregen_data.can_be_applied_to(scar_part, random_roll = TRUE))
					wound_type = path
					break

		if (wound_type) // can feasibly happen, if its an inorganic limb/cant be wounded/scarred
			var/datum/wound/phantom_wound = new wound_type
			scaries.generate(scar_part, phantom_wound)
			scaries.fake = TRUE
			QDEL_NULL(phantom_wound)

/mob/living/carbon/is_face_visible()
	return !(wear_mask?.flags_inv & HIDEFACE) && !(head?.flags_inv & HIDEFACE)

/// Returns whether or not the carbon should be able to be shocked
/mob/living/carbon/proc/should_electrocute(power_source)
	if (ismecha(loc))
		return FALSE

	if (wearing_shock_proof_gloves())
		return FALSE

	if(!get_powernet_info_from_source(power_source))
		return FALSE

	if (HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE

	return TRUE

/// Returns if the carbon is wearing shock proof gloves
/mob/living/carbon/proc/wearing_shock_proof_gloves()
	return gloves?.siemens_coefficient == 0

/// Modifies max_skillchip_count and updates active skillchips
/mob/living/carbon/proc/adjust_skillchip_complexity_modifier(delta)
	skillchip_complexity_modifier += delta

	var/obj/item/organ/internal/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)

	if(!brain)
		return

	brain.update_skillchips()


/// Modifies the handcuffed value if a different value is passed, returning FALSE otherwise. The variable should only be changed through this proc.
/mob/living/carbon/proc/set_handcuffed(new_value)
	if(handcuffed == new_value)
		return FALSE
	. = handcuffed
	handcuffed = new_value
	if(.)
		if(!handcuffed)
			REMOVE_TRAIT(src, TRAIT_RESTRAINED, HANDCUFFED_TRAIT)
	else if(handcuffed)
		ADD_TRAIT(src, TRAIT_RESTRAINED, HANDCUFFED_TRAIT)


/mob/living/carbon/on_lying_down(new_lying_angle)
	. = ..()
	if(!buckled || buckled.buckle_lying != 0)
		lying_angle_on_lying_down(new_lying_angle)


/// Special carbon interaction on lying down, to transform its sprite by a rotation.
/mob/living/carbon/proc/lying_angle_on_lying_down(new_lying_angle)
	if(!new_lying_angle)
		set_lying_angle(pick(90, 270))
	else
		set_lying_angle(new_lying_angle)

/mob/living/carbon/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, disgust))
			set_disgust(var_value)
			. = TRUE
		if(NAMEOF(src, handcuffed))
			set_handcuffed(var_value)
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	return ..()

/mob/living/carbon/get_attack_type()
	if(has_active_hand())
		var/obj/item/bodypart/arm/active_arm = get_active_hand()
		return active_arm.attack_type
	return ..()

/mob/living/carbon/proc/attach_rot()
	if(flags_1 & HOLOGRAM_1)
		return
	if(!(mob_biotypes & (MOB_ORGANIC|MOB_UNDEAD)))
		return
	AddComponent(/datum/component/rot, 6 MINUTES, 10 MINUTES, 1)

/mob/living/carbon/proc/disarm_precollide(datum/source, mob/living/carbon/shover, mob/living/carbon/target)
	SIGNAL_HANDLER
	if(can_be_shoved_into)
		return COMSIG_CARBON_ACT_SOLID

/mob/living/carbon/proc/disarm_collision(datum/source, mob/living/carbon/shover, mob/living/carbon/target, shove_blocked)
	SIGNAL_HANDLER
	if(src == target || LAZYFIND(target.buckled_mobs, src) || !can_be_shoved_into)
		return
	target.Knockdown(SHOVE_KNOCKDOWN_HUMAN)
	if(!is_shove_knockdown_blocked())
		Knockdown(SHOVE_KNOCKDOWN_COLLATERAL)
	target.visible_message(span_danger("[shover] shoves [target.name] into [name]!"),
		span_userdanger("You're shoved into [name] by [shover]!"), span_hear("You hear aggressive shuffling followed by a loud thud!"), COMBAT_MESSAGE_RANGE, src)
	to_chat(src, span_danger("You shove [target.name] into [name]!"))
	log_combat(shover, target, "shoved", addition = "into [name]")
	return COMSIG_CARBON_SHOVE_HANDLED

/mob/living/carbon/ominous_nosebleed()
	var/obj/item/bodypart/head = get_bodypart(BODY_ZONE_HEAD)
	if(isnull(head))
		return ..()
	if(HAS_TRAIT(src, TRAIT_NOBLOOD))
		to_chat(src, span_notice("You get a headache."))
		return
	head.adjustBleedStacks(5)
	visible_message(span_notice("[src] gets a nosebleed."), span_warning("You get a nosebleed."))
