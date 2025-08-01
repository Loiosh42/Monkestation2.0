/// The weight used to pick a positive mutation.
#define POSITIVE_WEIGHT 5
/// The weight used to pick a neutral mutation.
#define NEUTRAL_WEIGHT 2
/// The weight used to pick a negative mutation.
#define NEGATIVE_WEIGHT 2
/// The percent chance that a mutation will have a random (non-stabilizer) chromosome applied, if applicable
#define CHROMOSOME_PROB 70
/// The percent chance that a mutation will have a stabilizer chromosome applied, if another chromosome wasn't already applied.
#define STABILIZER_PROB 15

/obj/item/disk/data/random
	name = "old DNA data disk"
	desc = "A dust-caked disk with DNA mutation info on it. Wonder what it has..."
	read_only = TRUE
	/// A weighted list of mutations, albeit a two layered one, so it will do a weighted pick for mutation quality, then pick a mutation of that quality.
	var/static/list/mutation_weights

/obj/item/disk/data/random/Initialize(mapload)
	. = ..()
	if(isnull(mutation_weights))
		mutation_weights = initialize_mutation_weights()

	var/mutation_type = pick_weight_recursive(mutation_weights)
	var/datum/mutation/mutation = new mutation_type(GET_INITIALIZED_MUTATION(mutation_type))
	roll_for_chromosome(mutation)?.apply(mutation)
	mutations += mutation

/// Randomly returns a valid initialized chromosome or null.
/obj/item/disk/data/random/proc/roll_for_chromosome(datum/mutation/mutation) as /obj/item/chromosome
	RETURN_TYPE(/obj/item/chromosome)
	var/chromosome_type
	var/list/valid_chromosomes = mutation.valid_chromosome_types() - /obj/item/chromosome/stabilizer
	if(length(valid_chromosomes) && prob(CHROMOSOME_PROB))
		chromosome_type = pick(valid_chromosomes)
	else if(prob(STABILIZER_PROB) && mutation.stabilizer_coeff != -1)
		chromosome_type = /obj/item/chromosome/stabilizer
	if(chromosome_type)
		return new chromosome_type

/// Returns a (recursive) weighted list of mutations.
/obj/item/disk/data/random/proc/initialize_mutation_weights() as /list
	RETURN_TYPE(/list)
	. = list()
	var/list/good = list()
	var/list/neutral = list()
	var/list/bad = list()
	for(var/datum/mutation/mutation as anything in GLOB.all_mutations)
		if(mutation::random_locked)
			continue
		var/weight = isnull(mutation::species_allowed) ? 2 : 3
		switch(mutation::quality)
			if(POSITIVE)
				good[mutation] = weight
			if(MINOR_NEGATIVE)
				neutral[mutation] = weight
			if(NEGATIVE)
				bad[mutation] = weight
	.[good] = POSITIVE_WEIGHT
	.[neutral] = NEUTRAL_WEIGHT
	.[bad] = NEGATIVE_WEIGHT

#undef STABILIZER_PROB
#undef CHROMOSOME_PROB
#undef NEGATIVE_WEIGHT
#undef NEUTRAL_WEIGHT
#undef POSITIVE_WEIGHT
