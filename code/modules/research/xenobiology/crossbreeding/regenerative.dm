/*
Regenerative extracts:
	Work like a legion regenerative core.
	Has a unique additional effect.

	HEAVILY REWORKED BY MONKESTATION, SEE [monkestation\code\modules\slimecore\crossbreeding\regenerative]
*/
/obj/item/slimecross/regenerative
	name = "regenerative extract"
	desc = "It's filled with a milky substance, and pulses like a heartbeat."
	effect = "regenerative"
	icon_state = "regenerative"

/obj/item/slimecross/regenerative/proc/core_effect(mob/living/carbon/human/target, mob/user)
	return
/obj/item/slimecross/regenerative/proc/core_effect_before(mob/living/carbon/human/target, mob/user)
	return

/* monkestation edit: overriden in [monkestation\code\modules\slimecore\crossbreeding\regenerative\extract.dm]
/obj/item/slimecross/regenerative/afterattack(atom/target,mob/user,prox)
	. = ..()
	if(!prox || !isliving(target))
		return
	var/mob/living/H = target
	if(H.stat == DEAD)
		to_chat(user, span_warning("[src] will not work on the dead!"))
		return
	if(H != user)
		user.visible_message(span_notice("[user] crushes [src] over [H], the milky goo quickly regenerating all of [H.p_their()] injuries!"),
			span_notice("You squeeze [src], and it bursts over [H], the milky goo regenerating [H.p_their()] injuries."))
	else
		user.visible_message(span_notice("[user] crushes [src] over [user.p_them()]self, the milky goo quickly regenerating all of [user.p_their()] injuries!"),
			span_notice("You squeeze [src], and it bursts in your hand, splashing you with milky goo which quickly regenerates your injuries!"))
	core_effect_before(H, user)
	H.revive(HEAL_ALL)
	core_effect(H, user)
	playsound(target, 'sound/effects/splat.ogg', 40, TRUE)
	qdel(src)
*/

/obj/item/slimecross/regenerative/grey
	colour = "grey" //Has no bonus effect.
	effect_desc = "Rapidly heals the target and does nothing else." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/orange
	colour = "orange"

/obj/item/slimecross/regenerative/orange/core_effect_before(mob/living/target, mob/user)
	target.visible_message(span_warning("\The [src] boils over!"))
	for(var/turf/targetturf in RANGE_TURFS(1,target))
		if(!locate(/obj/effect/hotspot) in targetturf)
			new /obj/effect/hotspot(targetturf)

/obj/item/slimecross/regenerative/purple
	colour = "purple"
	effect_desc = "Rapidly heals the target at an even greater rate, and injects them with some regenerative jelly afterwards. Prevents softcrit while active." // monkestation edit: updates effect_desc to reflect the rework

/* monkestation edit: moved functionality to status effect
/obj/item/slimecross/regenerative/purple/core_effect(mob/living/target, mob/user)
	target.reagents.add_reagent(/datum/reagent/medicine/regen_jelly,10)
*/

/obj/item/slimecross/regenerative/blue
	colour = "blue"
	effect_desc = "Rapidly heals the target and makes the floor wet." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/blue/core_effect(mob/living/target, mob/user)
	if(isturf(target.loc))
		var/turf/open/T = get_turf(target)
		T.MakeSlippery(TURF_WET_WATER, min_wet_time = 10, wet_time_to_add = 5)
		target.visible_message(span_warning("The milky goo in the extract gets all over the floor!"))

/obj/item/slimecross/regenerative/metal
	colour = "metal"
	effect_desc = "Rapidly heals the target and encases the target in a locker." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/metal/core_effect(mob/living/target, mob/user)
	target.visible_message(span_warning("The milky goo hardens and reshapes itself, encasing [target]!"))
	var/obj/structure/closet/C = new /obj/structure/closet(target.loc)
	C.name = "slimy closet"
	C.desc = "Looking closer, it seems to be made of a sort of solid, opaque, metal-like goo."
	target.forceMove(C)

/obj/item/slimecross/regenerative/yellow
	colour = "yellow"
	effect_desc = "Rapidly heals the target and fully recharges a single item on the target. Provides shock immunity while active." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/yellow/core_effect(mob/living/target, mob/user)
	var/list/batteries = list()
	for(var/obj/item/stock_parts/cell/C in target.get_all_contents())
		if(C.charge < C.maxcharge)
			batteries += C
	if(batteries.len)
		var/obj/item/stock_parts/cell/ToCharge = pick(batteries)
		ToCharge.charge = ToCharge.maxcharge
		to_chat(target, span_notice("You feel a strange electrical pulse, and one of your electrical items was recharged."))

/obj/item/slimecross/regenerative/darkpurple
	colour = "dark purple"
	effect_desc = "Rapidly heals the target and gives them purple clothing if they are naked." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/darkpurple/core_effect(mob/living/target, mob/user)
	var/equipped = 0
	equipped += target.equip_to_slot_or_del(new /obj/item/clothing/shoes/sneakers/purple(null), ITEM_SLOT_FEET)
	equipped += target.equip_to_slot_or_del(new /obj/item/clothing/under/color/lightpurple(null), ITEM_SLOT_ICLOTHING)
	equipped += target.equip_to_slot_or_del(new /obj/item/clothing/gloves/color/purple(null), ITEM_SLOT_GLOVES)
	equipped += target.equip_to_slot_or_del(new /obj/item/clothing/head/soft/purple(null), ITEM_SLOT_HEAD)
	if(equipped > 0)
		target.visible_message(span_notice("The milky goo congeals into clothing!"))

/obj/item/slimecross/regenerative/darkblue
	colour = "dark blue"
	effect_desc = "Rapidly heals the target and fireproofs their clothes." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/darkblue/core_effect(mob/living/target, mob/user)
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	var/fireproofed = FALSE
	if(H.get_item_by_slot(ITEM_SLOT_OCLOTHING))
		fireproofed = TRUE
		var/obj/item/clothing/C = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		fireproof(C)
	if(H.get_item_by_slot(ITEM_SLOT_HEAD))
		fireproofed = TRUE
		var/obj/item/clothing/C = H.get_item_by_slot(ITEM_SLOT_HEAD)
		fireproof(C)
	if(fireproofed)
		target.visible_message(span_notice("Some of [target]'s clothing gets coated in the goo, and turns blue!"))

/obj/item/slimecross/regenerative/darkblue/proc/fireproof(obj/item/clothing/C)
	C.name = "fireproofed [C.name]"
	C.remove_atom_colour(WASHABLE_COLOUR_PRIORITY)
	C.add_atom_colour("#000080", FIXED_COLOUR_PRIORITY)
	C.max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	C.resistance_flags |= FIRE_PROOF

/obj/item/slimecross/regenerative/silver
	colour = "silver"
	effect_desc = "Rapidly heals the target, regenerating their nutrition at a far greater rate than normal" // monkestation edit: updates effect_desc to reflect the rework

/* monkestation edit: replaced in [monkestation\code\modules\slimecore\crossbreeding\regenerative\extract.dm]
/obj/item/slimecross/regenerative/silver/core_effect(mob/living/target, mob/user)
	target.set_nutrition(NUTRITION_LEVEL_FULL - 1)
	to_chat(target, span_notice("You feel satiated."))
*/

/obj/item/slimecross/regenerative/bluespace
	colour = "bluespace"
	effect_desc = "Rapidly heals the target and teleports them to where this core was created." // monkestation edit: updates effect_desc to reflect the rework
	var/turf/open/T

/obj/item/slimecross/regenerative/bluespace/core_effect(mob/living/target, mob/user)
	var/turf/old_location = get_turf(target)
	if(do_teleport(target, T, channel = TELEPORT_CHANNEL_QUANTUM)) //despite being named a bluespace teleportation method the quantum channel is used to preserve precision teleporting with a bag of holding
		old_location.visible_message(span_warning("[target] disappears in a shower of sparks!"))
		to_chat(target, span_danger("The milky goo teleports you somewhere it remembers!"))


/obj/item/slimecross/regenerative/bluespace/Initialize(mapload)
	. = ..()
	T = get_turf(src)

/obj/item/slimecross/regenerative/sepia
	colour = "sepia"
	effect_desc = "Rapidly heals the target. After 10 seconds, relocate the target to the initial position the core was used with their previous health status." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/sepia/core_effect_before(mob/living/target, mob/user)
	to_chat(target, span_notice("You try to forget how you feel."))
	target.AddComponent(/datum/component/dejavu)

/obj/item/slimecross/regenerative/cerulean
	colour = "cerulean"
	effect_desc = "Rapidly heals the target and makes a second regenerative core with no special effects." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/cerulean/core_effect(mob/living/target, mob/user)
	src.forceMove(user.loc)
	var/obj/item/slimecross/X = new /obj/item/slimecross/regenerative(user.drop_location())
	X.name = name
	X.desc = desc
	user.put_in_active_hand(X)
	to_chat(user, span_notice("Some of the milky goo congeals in your hand!"))

/obj/item/slimecross/regenerative/pyrite
	colour = "pyrite"
	effect_desc = "Rapidly heals and randomly colors the target." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/pyrite/core_effect(mob/living/target, mob/user)
	target.visible_message(span_warning("The milky goo coating [target] leaves [target.p_them()] a different color!"))
	target.add_atom_colour(rgb(rand(0,255),rand(0,255),rand(0,255)),WASHABLE_COLOUR_PRIORITY)

/obj/item/slimecross/regenerative/red
	colour = "red"
	effect_desc = "Rapidly heals the target and injects them with some ephedrine." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/red/core_effect(mob/living/target, mob/user)
	to_chat(target, span_notice("You feel... <i>faster.</i>"))
	target.reagents.add_reagent(/datum/reagent/medicine/ephedrine,3)

/obj/item/slimecross/regenerative/green
	colour = "green"
	effect_desc = "Rapidly heals the target and changes the species or color of a slime or jellyperson." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/green/core_effect(mob/living/target, mob/user)
	if(isslime(target))
		target.visible_message(span_warning("\The [target] suddenly changes color!"))
		var/mob/living/basic/slime/S = target
		S.start_mutating(TRUE)
	else if(isoozeling(target))
		target.reagents.add_reagent(/datum/reagent/mutationtoxin/jelly, 5)


/obj/item/slimecross/regenerative/pink
	colour = "pink"
	effect_desc = "Rapidly heals the target and injects them with some krokodil." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/pink/core_effect(mob/living/target, mob/user)
	to_chat(target, span_notice("You feel more calm."))
	target.reagents.add_reagent(/datum/reagent/drug/krokodil,4)

/obj/item/slimecross/regenerative/gold
	colour = "gold"
	effect_desc = "Rapidly heals the target and produces a random coin." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/gold/core_effect(mob/living/target, mob/user)
	var/newcoin = pick(/obj/item/coin/silver, /obj/item/coin/iron, /obj/item/coin/gold, /obj/item/coin/diamond, /obj/item/coin/plasma, /obj/item/coin/uranium)
	var/obj/item/coin/C = new newcoin(target.loc)
	playsound(C, 'sound/items/coinflip.ogg', 50, TRUE)
	target.put_in_hand(C)

/obj/item/slimecross/regenerative/oil
	colour = "oil"
	effect_desc = "Rapidly heals the target and flashes everyone in sight." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/oil/core_effect(mob/living/target, mob/user)
	playsound(src, 'sound/weapons/flash.ogg', 100, TRUE)
	for(var/mob/living/L in view(user,7))
		L.flash_act()

/obj/item/slimecross/regenerative/black
	colour = "black"
	effect_desc = "Rapidly heals the target and creates an imperfect duplicate of them made of slime, that fakes their death." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/black/core_effect_before(mob/living/target, mob/user)
	var/dummytype = target.type
	if(ismegafauna(target)) //Prevents megafauna duping in a lame way
		dummytype = /mob/living/basic/slime
		to_chat(user, span_warning("The milky goo flows over [target], falling into a weak puddle."))
	var/mob/living/dummy = new dummytype(target.loc)
	to_chat(target, span_notice("The milky goo flows from your skin, forming an imperfect copy of you."))
	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		var/mob/living/carbon/carbon_dummy = dummy
		carbon_dummy.real_name = carbon_target.real_name
		carbon_target.dna.copy_dna(carbon_dummy.dna, COPY_DNA_SE|COPY_DNA_SPECIES)
		carbon_dummy.updateappearance(mutcolor_update = TRUE)
	dummy.adjustBruteLoss(target.getBruteLoss())
	dummy.adjustFireLoss(target.getFireLoss())
	dummy.adjustToxLoss(target.getToxLoss())
	dummy.death()

/obj/item/slimecross/regenerative/lightpink
	colour = "light pink"
	effect_desc = "Rapidly heals the target and also heals the user." // monkestation edit: updates effect_desc to reflect the rework

/obj/item/slimecross/regenerative/lightpink/core_effect(mob/living/target, mob/user)
	if(!isliving(user))
		return
	if(target == user)
		return
	var/mob/living/U = user
	U.revive(HEAL_ALL)
	to_chat(U, span_notice("Some of the milky goo sprays onto you, as well!"))

/obj/item/slimecross/regenerative/adamantine
	colour = "adamantine"
	effect_desc = "Rapidly heals the target, while boosting their armor and general resilience." // monkestation edit: updates effect_desc to reflect the rework, also a typo fix

/obj/item/slimecross/regenerative/adamantine/core_effect(mob/living/target, mob/user) //WIP - Find out why this doesn't work.
	target.apply_status_effect(/datum/status_effect/slimeskin)

/obj/item/slimecross/regenerative/rainbow
	colour = "rainbow"
	effect_desc = "Fully heals the target, including all forms of damage, wounds, brain traumas, sickness, blood loss, and unsafe body temperature. Does not regrow limbs (except for oozelings) or refresh organs. Temporarily makes them immortal, but pacifistic." // monkestation edit: updates effect_desc to reflect the rework, also a typo fix

/obj/item/slimecross/regenerative/rainbow/core_effect(mob/living/target, mob/user)
	target.apply_status_effect(/datum/status_effect/rainbow_protection)
