// Shotgun

/obj/item/ammo_casing/shotgun
	name = "shotgun slug"
	desc = "A 12 gauge lead slug."
	icon_state = "blshell"
	worn_icon_state = "shell"
	caliber = CALIBER_SHOTGUN
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*2)
	projectile_type = /obj/projectile/bullet/shotgun_slug

/obj/item/ammo_casing/shotgun/executioner
	name = "executioner slug"
	desc = "A 12 gauge lead slug purpose built to annihilate flesh on impact."
	icon_state = "stunshell"
	projectile_type = /obj/projectile/bullet/shotgun_slug/executioner

/obj/item/ammo_casing/shotgun/pulverizer
	name = "pulverizer slug"
	desc = "A 12 gauge lead slug purpose built to annihilate bones on impact."
	icon_state = "stunshell"
	projectile_type = /obj/projectile/bullet/shotgun_slug/pulverizer

/obj/item/ammo_casing/shotgun/beanbag
	name = "beanbag slug"
	desc = "A weak beanbag slug for riot control."
	icon_state = "bshell"
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*2.5)
	projectile_type = /obj/projectile/bullet/shotgun_beanbag

/obj/item/ammo_casing/shotgun/apds
	name = "armor-piercing slug"
	desc = "A 12-gauge shotgun slug, reloaded with a sabot tungsten penetrator. Armor? What armor!"
	icon_state = "apshell"
	projectile_type = /obj/projectile/bullet/shotgun_slug/apds

/obj/item/ammo_casing/shotgun/incendiary
	name = "incendiary slug"
	desc = "An incendiary-coated shotgun slug."
	icon_state = "ishell"
	projectile_type = /obj/projectile/bullet/incendiary/shotgun

/obj/item/ammo_casing/shotgun/incendiary/no_trail
	name = "precision incendiary slug"
	desc = "An incendiary-coated shotgun slug, specially treated to only ignite on impact."
	projectile_type = /obj/projectile/bullet/incendiary/shotgun/no_trail

/obj/item/ammo_casing/shotgun/dragonsbreath
	name = "dragonsbreath shell"
	desc = "A shotgun shell which fires a spread of incendiary pellets."
	icon_state = "ishell2"
	projectile_type = /obj/projectile/bullet/incendiary/shotgun/dragonsbreath
	pellets = 4
	variance = 35

/obj/item/ammo_casing/shotgun/stunslug
	name = "taser slug"
	desc = "A stunning taser slug."
	icon_state = "stunshell"
	projectile_type = /obj/projectile/bullet/shotgun_stunslug
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*2.5)

/obj/item/ammo_casing/shotgun/meteorslug
	name = "meteorslug shell"
	desc = "A shotgun shell rigged with CMC technology, which launches a massive slug when fired."
	icon_state = "mshell"
	projectile_type = /obj/projectile/bullet/cannonball/meteorslug

/obj/item/ammo_casing/shotgun/pulseslug
	name = "pulse slug"
	desc = "A delicate device which can be loaded into a shotgun. The primer acts as a button which triggers the gain medium and fires a powerful \
	energy blast. While the heat and power drain limit it to one use, it can still allow an operator to engage targets that ballistic ammunition \
	would have difficulty with."
	icon_state = "pshell"
	projectile_type = /obj/projectile/beam/pulse/shotgun

/obj/item/ammo_casing/shotgun/frag12
	name = "FRAG-12 slug"
	desc = "A high explosive breaching round for a 12 gauge shotgun."
	icon_state = "heshell"
	projectile_type = /obj/projectile/bullet/shotgun_frag12

/obj/item/ammo_casing/shotgun/buckshot
	name = "buckshot shell"
	desc = "A 12 gauge buckshot shell."
	icon_state = "gshell"
	projectile_type = /obj/projectile/bullet/pellet/shotgun_buckshot
	pellets = 6 //back to 6
	variance = 25

/obj/item/ammo_casing/shotgun/rubbershot
	name = "rubber shot"
	desc = "A shotgun casing filled with densely-packed rubber balls, used to incapacitate crowds from a distance."
	icon_state = "rshell"
	projectile_type = /obj/projectile/bullet/pellet/shotgun_rubbershot
	pellets = 6 //monkestation edit
	variance = 25 // 6 pellets for 15 stam and 1 damage each
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*2)

/obj/item/ammo_casing/shotgun/incapacitate
	name = "custom incapacitating shot"
	desc = "A shotgun casing filled with... something. used to incapacitate targets."
	icon_state = "bountyshell"
	projectile_type = /obj/projectile/bullet/pellet/shotgun_incapacitate
	pellets = 20//monkestation edit 12 to 20
	variance = 30 //monkestation edit
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*2)

/obj/item/ammo_casing/shotgun/improvised
	name = "improvised shell"
	desc = "An extremely weak shotgun shell with multiple small pellets made out of metal shards."
	icon_state = "improvshell"
	projectile_type = /obj/projectile/bullet/pellet/shotgun_improvised
	custom_materials = list(/datum/material/iron=SMALL_MATERIAL_AMOUNT*2.5)
	pellets = 10
	variance = 25

/obj/item/ammo_casing/shotgun/ion
	name = "ion shell"
	desc = "An advanced shotgun shell which uses a subspace ansible crystal to produce an effect similar to a standard ion rifle. \
	The unique properties of the crystal split the pulse into a spread of individually weaker bolts."
	icon_state = "ionshell"
	projectile_type = /obj/projectile/ion/weak
	pellets = 4
	variance = 35

/obj/item/ammo_casing/shotgun/laserslug
	name = "scatter laser shell"
	desc = "An advanced shotgun shell that uses a micro laser to replicate the effects of a scatter laser weapon in a ballistic package."
	icon_state = "lshell"
	projectile_type = /obj/projectile/beam/weak
	pellets = 6
	variance = 35

/obj/item/ammo_casing/shotgun/techshell
	name = "unloaded technological shell"
	desc = "A high-tech shotgun shell which can be loaded with materials to produce unique effects."
	icon_state = "cshell"
	projectile_type = null

/obj/item/ammo_casing/shotgun/dart
	name = "shotgun dart"
	desc = "A dart for use in shotguns. Can be injected with up to 15 units of any chemical."
	icon_state = "cshell"
	projectile_type = /obj/projectile/bullet/dart
	var/reagent_amount = 15

/obj/item/ammo_casing/shotgun/dart/Initialize(mapload)
	. = ..()
	create_reagents(reagent_amount, OPENCONTAINER)

/obj/item/ammo_casing/shotgun/dart/attackby()
	return

/obj/item/ammo_casing/shotgun/dart/bioterror
	desc = "An improved shotgun dart filled with deadly toxins. Can be injected with up to 30 units of any chemical."
	reagent_amount = 30

/obj/item/ammo_casing/shotgun/dart/bioterror/Initialize(mapload)
	. = ..()
	reagents.add_reagent(/datum/reagent/consumable/ethanol/neurotoxin, 6)
	reagents.add_reagent(/datum/reagent/toxin/spore, 6)
	reagents.add_reagent(/datum/reagent/toxin/mutetoxin, 6) //;HELP OPS IN MAINT
	reagents.add_reagent(/datum/reagent/toxin/coniine, 6)
	reagents.add_reagent(/datum/reagent/toxin/sodium_thiopental, 6)

/obj/item/ammo_casing/shotgun/breacher
	name = "breaching slug"
	desc = "A 12 gauge anti-material slug. Great for breaching airlocks and windows, quickly and efficiently."
	icon_state = "breacher"
	projectile_type = /obj/projectile/bullet/shotgun_breaching
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT*2)
