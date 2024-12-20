/// Tutel shield, designed to work with the Bobr
/// Comes with a built-in 4 round ammobox to allow for easy reloading
/// I based it off of ammo_box instead of shield because I believe ammo_box is more complicated

/obj/item/ammo_box/advanced/s12gauge/tutel
	name = "Tutel tactical buckler"
	desc = "A lightweight titanium-alloy shield painted to look like wood. It has an integrated shotgun shell tube, allowing you to reload without putting down the shield."
	icon_state = "buckler"
	inhand_icon_state = "buckler"
	custom_materials = list(/datum/material/iron= SHEET_MATERIAL_AMOUNT * 10) //Yes yes, I know, you do still repair it with titanium
	ammo_type = /obj/item/ammo_casing/shotgun
	max_ammo = 4
	caliber = CALIBER_SHOTGUN
	multitype = TRUE
	block_chance = 50
	max_integrity = 50
	slot_flags = ITEM_SLOT_BACK | ITEM_SLOT_BELT
	force = 15
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("shoves", "bashes")
	attack_verb_simple = list("shove", "bash")
	armor_type = /datum/armor/item_shield
	block_sound = 'sound/weapons/block_shield.ogg'
	var/tutel_break_leftover = /obj/item/broken_shield

/obj/item/ammo_box/advanced/s12gauge/tutel/examine(mob/user)
	. = ..()
	var/healthpercent = round((atom_integrity/max_integrity) * 100, 1)
	switch(healthpercent)
		if(50 to 99)
			. += span_info("It looks slightly damaged.")
		if(25 to 50)
			. += span_info("It appears heavily damaged.")
		if(0 to 25)
			. += span_warning("It's falling apart!")

/obj/item/ammo_box/advanced/s12gauge/tutel/proc/shatter(mob/living/carbon/human/owner)
	playsound(owner, shield_break_sound, 50)
	AddComponent(/datum/component/pellet_cloud, projectile_type = /obj/projectile/bullet/shrapnel, magnitude = 1)
	new tutel_break_leftover(get_turf(src))

/obj/item/ammo_box/advanced/s12gauge/tutel/proc/on_shield_block(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", damage = 0, attack_type = MELEE_ATTACK)
	if (atom_integrity <= damage)
		var/turf/owner_turf = get_turf(owner)
		owner_turf.visible_message(span_warning("[hitby] destroys [src]!"))
		shatter(owner)
		qdel(src)
		return FALSE
	take_damage(damage)
	return TRUE

/obj/item/ammo_box/advanced/s12gauge/tutel/attackby(obj/item/attackby_item, mob/user, params)
	if(istype(attackby_item, /obj/item/stack/sheet/mineral/titanium))
		if (atom_integrity >= max_integrity)
			to_chat(user, span_warning("[src] is already in perfect condition."))
			return
		var/obj/item/stack/sheet/mineral/titanium/titanium_sheet = attackby_item
		titanium_sheet.use(1)
		atom_integrity = max_integrity
		to_chat(user, span_notice("You repair [src] with [titanium_sheet]."))
		return
	return ..()

/obj/item/broken_shield
	name = "broken Tutel"
	desc = "A broken tactical shield, it looks as though you could repair it with some titanium.."
	icon_state = "buckler"
	inhand_icon_state = "buckler"
	flags_1 = CONDUCT_1
	force = 9
	throwforce = 10
	w_class = WEIGHT_CLASS_BULKY
	custom_materials = list(/datum/material/titanium = HALF_SHEET_MATERIAL_AMOUNT + SMALL_MATERIAL_AMOUNT * 3)
	attack_verb_continuous = list("hits", "bludgeons", "whacks", "bonks")
	attack_verb_simple = list("hit", "bludgeon", "whack", "bonk")

/obj/item/broken_shield/Initialize(mapload)
	. = ..()

	var/static/list/hovering_item_typechecks = list(
		/obj/item/stack/sheet/mineral/titanium/titanium_sheet = list(
			SCREENTIP_CONTEXT_LMB = "Repair shield",
		),

	)

	AddElement(/datum/element/contextual_screentip_item_typechecks, hovering_item_typechecks)

/obj/item/wirerodbroken_shield/attackby(obj/item/attacking_item, mob/user, params)
	if(istype(attacking_item, /obj/item/stack/sheet/mineral/titanium/titanium_sheet))
		var/datum/crafting_recipe/recipe_to_use = /datum/crafting_recipe/tutel
		user.balloon_alert(user, "crafting spear...")
		if(do_after(user, initial(recipe_to_use.time), src)) // we do initial work here to get the correct timer
			var/obj/item/ammo_box/advanced/s12gauge/tutel/crafted_tutel = new /obj/item/ammo_box/advanced/s12gauge/tutel()

			remove_item_from_storage(user)
			if (!user.transferItemToLoc(attacking_item, crafted_tutel))
				return
			crafted_tutel.CheckParts(list(attacking_item))
			qdel(src)

			user.put_in_hands(crafted_tutel)
			user.balloon_alert(user, "repaired shield")
		return
	return ..()

/datum/crafting_recipe/tutel
	name = "Tutel Repair"
	result = /obj/item/ammo_box/advanced/s12gauge/tutel
	reqs = list(
		/obj/item/broken_shield = 1,
		/obj/item/stack/sheet/mineral/titanium/titanium_sheet = 1,
	)
	time = 15 SECONDS
	category = CAT_WEAPON_MELEE

