/datum/mood_event/handcuffed
	description = "<span class='warning'>I guess my antics have finally caught up with me.</span>"
	mood_change = -1

/datum/mood_event/broken_vow //Used for when mimes break their vow of silence
	description = "<span class='boldwarning'>I have brought shame upon my name, and betrayed my fellow mimes by breaking our sacred vow...</span>"
	mood_change = -8

/datum/mood_event/on_fire
	description = "<span class='boldwarning'>I'M ON FIRE!!!</span>"
	mood_change = -12

/datum/mood_event/suffocation
	description = "<span class='boldwarning'>CAN'T... BREATHE...</span>"
	mood_change = -12

/datum/mood_event/cold
	description = "<span class='warning'>It's way too cold in here.</span>"
	mood_change = -5

/datum/mood_event/hot
	description = "<span class='warning'>It's getting hot in here.</span>"
	mood_change = -5

/datum/mood_event/eye_stab
	description = "<span class='boldwarning'>AHHH my eyes, that was really sharp!</span>"
	mood_change = -4
	timeout = 3 MINUTES

/datum/mood_event/delam //SM delamination
	description = "<span class='boldwarning'>Those God damn engineers can't do anything right...</span>"
	mood_change = -2
	timeout = 4 MINUTES

/datum/mood_event/depression
	description = "<span class='warning'>I feel sad for no particular reason.</span>"
	mood_change = -12
	timeout = 2 MINUTES

/datum/mood_event/anxiety
	description = "<span class='warning'>I feel scared around all these people...</span>"
	mood_change = -2
	timeout = 60 SECONDS

/datum/mood_event/anxiety_mute
	description = "<span class='boldwarning'>I can't speak up, not with everyone here!</span>"
	mood_change = -4
	timeout = 2 MINUTES

/datum/mood_event/anxiety_dumb
	description = "<span class='boldwarning'>Oh god, I made a fool of myself.</span>"
	mood_change = -10
	timeout = 2 MINUTES

/datum/mood_event/shameful_suicide //suicide_acts that return SHAME, like sord
	description = "<span class='boldwarning'>I can't even end it all!</span>"
	mood_change = -15
	timeout = 60 SECONDS

/datum/mood_event/dismembered
	description = "<span class='boldwarning'>AHH! MY LIMB! I WAS USING THAT!</span>"
	mood_change = -10
	timeout = 8 MINUTES

/datum/mood_event/tased
	description = "<span class='warning'>There's no \"z\" in \"taser\". It's in the zap.</span>"
	mood_change = -3
	timeout = 2 MINUTES

/datum/mood_event/embedded
	description = "<span class='boldwarning'>Pull it out!</span>"
	mood_change = -7

/datum/mood_event/brain_damage
	mood_change = -3

/datum/mood_event/brain_damage/add_effects()
	var/damage_message = pick_list_replacements(BRAIN_DAMAGE_FILE, "brain_damage")
	description = "<span class='warning'>Hurr durr... [damage_message]</span>"

/datum/mood_event/hulk //Entire duration of having the hulk mutation
	description = "<span class='warning'>HULK SMASH!</span>"
	mood_change = -4

/datum/mood_event/epilepsy //Only when the mutation causes a seizure
	description = "<span class='warning'>I should have paid attention to the epilepsy warning.</span>"
	mood_change = -3
	timeout = 5 MINUTES

/datum/mood_event/nyctophobia
	description = "<span class='warning'>It sure is dark around here...</span>"
	mood_change = -3

/datum/mood_event/family_heirloom_missing
	description = "<span class='warning'>I'm missing my family heirloom...</span>"
	mood_change = -4

/datum/mood_event/healsbadman
	description = "<span class='warning'>I feel a lot better, but wow that was disgusting.</span>" //when you read the latest felinid removal PR and realize you're really not that much of a degenerate
	mood_change = -4
	timeout = 2 MINUTES

/datum/mood_event/painful_medicine
	description = "<span class='warning'>Medicine may be good for me but right now it stings like hell.</span>"
	mood_change = -5
	timeout = 60 SECONDS

/datum/mood_event/spooked
	description = "<span class='warning'>The rattling of those bones...It still haunts me.</span>"
	mood_change = -4
	timeout = 4 MINUTES

/datum/mood_event/notcreeping
	description = "<span class='warning'>The voices are not happy, and they painfully contort my thoughts into getting back on task.</span>"
	mood_change = -6
	timeout = 30
	hidden = TRUE

/datum/mood_event/notcreepingsevere//not hidden since it's so severe
	description = "<span class='boldwarning'>THEY NEEEEEEED OBSESSIONNNN!!!</span>"
	mood_change = -30
	timeout = 30

/datum/mood_event/notcreepingsevere/add_effects(name)
	var/list/unstable = list(name)
	for(var/i in 1 to rand(3,5))
		unstable += copytext_char(name, -1)
	var/unhinged = uppertext(unstable.Join(""))//example Tinea Luxor > TINEA LUXORRRR (with randomness in how long that slur is)
	description = "<span class='boldwarning'>THEY NEEEEEEED [unhinged]!!!</span>"

/datum/mood_event/sapped
	description = "<span class='boldwarning'>Some unexplainable sadness is consuming me...</span>"
	mood_change = -15
	timeout = 90 SECONDS

/datum/mood_event/back_pain
	description = "<span class='boldwarning'>Bags never sit right on my back, this hurts like hell!</span>"
	mood_change = -15

/datum/mood_event/sad_empath
	description = "<span class='warning'>Someone seems upset...</span>"
	mood_change = -2
	timeout = 60 SECONDS

/datum/mood_event/sad_empath/add_effects(mob/sadtarget)
	description = "<span class='warning'>[sadtarget.name] seems upset...</span>"

/datum/mood_event/sacrifice_bad
	description ="<span class='warning'>Those darn savages!</span>"
	mood_change = -5
	timeout = 2 MINUTES

/datum/mood_event/gates_of_mansus
	description = "<span class='boldwarning'>LIVING IN A PERFORMANCE IS WORSE THAN DEATH</span>"
	mood_change = -25
	timeout = 4 MINUTES

/datum/mood_event/nanite_sadness
	description = "<span class='warning robot'>+++++++HAPPINESS SUPPRESSION+++++++</span>"
	mood_change = -7

/datum/mood_event/nanite_sadness/add_effects(message)
	description = "<span class='warning robot'>+++++++[message]+++++++</span>"

/datum/mood_event/sec_insulated_gloves
	description = "<span class='warning'>I look like an Assistant...</span>"
	mood_change = -1

/datum/mood_event/burnt_wings
	description = "<span class='boldwarning'>MY PRECIOUS WINGS!!!</span>"
	mood_change = -10
	timeout = 10 MINUTES

/datum/mood_event/soda_spill
	description = "Cool! That's fine, I wanted to wear that soda, not drink it..."
	mood_change = -2
	timeout = 1 MINUTES

/datum/mood_event/observed_soda_spill
	description = "Ahaha! It's always funny to see someone get sprayed by a can of soda."
	mood_change = 2
	timeout = 30 SECONDS

/datum/mood_event/observed_soda_spill/add_effects(mob/spilled_mob, atom/soda_can)
	if(!spilled_mob)
		return

	description = "Ahaha! [spilled_mob] spilled [spilled_mob.p_their()] [soda_can ? soda_can.name : "soda"] all over [spilled_mob.p_them()]self! Classic."

/datum/mood_event/feline_dysmorphia
	description = "<span class='boldwarning'>I'm so ugly. I wish I was cuter!</span>"
	mood_change = -10

/datum/mood_event/nervous
	description = "<span class='warning'>I feel on edge... Gotta get a grip.</span>"
	mood_change = -3
	timeout = 30 SECONDS

/datum/mood_event/paranoid
	description = "<span class='boldwarning'>I'm not safe! I can't trust anybody!</span>"
	mood_change = -6
	timeout = 30 SECONDS

/datum/mood_event/saw_holopara_death
	description = "<span class='warning'>Oh god, they just painfully turned to dust... What an horrifying sight...</span>"
	mood_change = -10
	timeout = 15 MINUTES

/datum/mood_event/saw_holopara_death/add_effects(name)
	description = "<span class='warning'>Oh god, [name] just painfully turned to dust... What an horrifying sight...</span>"

/datum/mood_event/loud_gong
	description = "<span class='warning'>That loud gong noise really hurt my ears!</span>"
	mood_change = -3
	timeout = 2 MINUTES
