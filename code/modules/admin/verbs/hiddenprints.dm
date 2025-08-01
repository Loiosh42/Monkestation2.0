ADMIN_VERB_ONLY_CONTEXT_MENU(cmd_show_hiddenprints, R_ADMIN, FALSE, "Show Hiddenprints", atom/victim)
	var/interface = "A log of every player who has touched [victim], sorted by last touch.<br><br><ol>"
	var/victim_hiddenprints = GET_ATOM_HIDDENPRINTS(victim)

	if(!islist(victim_hiddenprints))
		victim_hiddenprints = list()

	var/list/hiddenprints = flatten_list(victim_hiddenprints)
	list_clear_nulls(hiddenprints)

	if(!length(hiddenprints))
		hiddenprints = list("Nobody has touched this yet!")

	hiddenprints = sort_list(hiddenprints, GLOBAL_PROC_REF(cmp_hiddenprint_lasttime_dsc))
	for(var/record in hiddenprints)
		interface += "<li>[record]</li><br>"

	interface += "</ol>"

	var/datum/browser/hiddenprint_view = new(user.mob, "view_hiddenprints_[REF(victim)]", "[victim]'s hiddenprints", 450, 760)
	hiddenprint_view.set_content(interface)
	hiddenprint_view.open()

/proc/cmp_hiddenprint_lasttime_dsc(a, b)
	var/last_a = copytext(a, findtext(a, "\nLast: "))
	var/last_b = copytext(b, findtext(b, "\nLast: "))
	return cmp_text_dsc(last_a, last_b)
