/obj/machinery/jukebox
	name = "jukebox"
	desc = "A classic music player."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "jukebox"
	verb_say = "states"
	density = TRUE
	req_access = list(ACCESS_BAR)
	var/active = FALSE
	var/list/rangers = list()
	var/stop = 0
	var/list/songs = list()
	var/datum/track/selection = null
	/// Volume of the songs played
	var/volume = 100

/obj/machinery/jukebox/disco
	name = "radiant dance machine mark IV"
	desc = "The first three prototypes were discontinued after mass casualty incidents."
	icon_state = "disco"
	req_access = null
	req_one_access = list(ACCESS_HEADS, ACCESS_THEATRE, ACCESS_BAR) // you need one of these
	anchored = FALSE
	var/list/spotlights = list()
	var/list/sparkles = list()

/obj/machinery/jukebox/disco/indestructible
	name = "radiant dance machine mark V"
	desc = "Now redesigned with data gathered from the extensive disco and plasma research."
	req_access = null
	req_one_access = null
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	flags_1 = NODECONSTRUCT_1

/datum/track
	var/song_name = "generic"
	var/song_path = null
	var/song_length = 0
	var/song_beat = 0

/datum/track/New(name, path, length, beat)
	song_name = name
	song_path = path
	song_length = length
	song_beat = beat

/obj/machinery/jukebox/Initialize(mapload)
	. = ..()
	var/list/tracks = flist("config/jukebox_music/sounds/")

	for(var/S in tracks)
		var/datum/track/T = new()
		T.song_path = file("config/jukebox_music/sounds/[S]")
		var/list/L = splittext(S,"+")
		if(L.len != 3)
			continue
		T.song_name = L[1]
		T.song_length = text2num(L[2])
		T.song_beat = text2num(L[3])
		songs |= T

	if(songs.len)
		selection = pick(songs)

/obj/machinery/jukebox/Destroy()
	dance_over()
	return ..()

/obj/machinery/jukebox/attackby(obj/item/O, mob/user, params)
	if(!active && !(flags_1 & NODECONSTRUCT_1))
		if(O.tool_behaviour == TOOL_WRENCH)
			if(!anchored && !isinspace())
				to_chat(user,"<span class='notice'>You secure [src] to the floor.</span>")
				set_anchored(TRUE)
			else if(anchored)
				to_chat(user,"<span class='notice'>You unsecure and disconnect [src].</span>")
				set_anchored(FALSE)
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			return
	return ..()

/obj/machinery/jukebox/update_icon_state()
	icon_state = "[initial(icon_state)][active ? "-active" : null]"
	return ..()

/obj/machinery/jukebox/ui_status(mob/user)
	if(!anchored)
		to_chat(user,"<span class='warning'>This device must be anchored by a wrench!</span>")
		return UI_CLOSE
	if(!allowed(user) && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: Access Denied.</span>")
		user.playsound_local(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	if(!songs.len && !isobserver(user))
		to_chat(user,"<span class='warning'>Error: No music tracks have been authorized for your station. Petition Central Command to resolve this issue.</span>")
		playsound(src, 'sound/misc/compiler-failure.ogg', 25, TRUE)
		return UI_CLOSE
	return ..()

/obj/machinery/jukebox/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Jukebox", name)
		ui.open()

/obj/machinery/jukebox/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	data["songs"] = list()
	for(var/datum/track/S in songs)
		var/list/track_data = list(
			name = S.song_name
		)
		data["songs"] += list(track_data)
	data["track_selected"] = null
	data["track_length"] = null
	data["track_beat"] = null
	if(selection)
		data["track_selected"] = selection.song_name
		data["track_length"] = DisplayTimeText(selection.song_length)
		data["track_beat"] = selection.song_beat
	data["volume"] = volume
	return data

/obj/machinery/jukebox/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle")
			if(QDELETED(src))
				return
			if(!active)
				if(stop > world.time)
					to_chat(usr, "<span class='warning'>Error: The device is still resetting from the last activation, it will be ready again in [DisplayTimeText(stop-world.time)].</span>")
					playsound(src, 'sound/misc/compiler-failure.ogg', 50, TRUE)
					return
				activate_music()
				START_PROCESSING(SSobj, src)
				return TRUE
			else
				stop = 0
				return TRUE
		if("select_track")
			if(active)
				to_chat(usr, "<span class='warning'>Error: You cannot change the song until the current one is over.</span>")
				return
			var/list/available = list()
			for(var/datum/track/S in songs)
				available[S.song_name] = S
			var/selected = params["track"]
			if(QDELETED(src) || !selected || !istype(available[selected], /datum/track))
				return
			selection = available[selected]
			return TRUE
		if("set_volume")
			var/new_volume = params["volume"]
			if(new_volume  == "reset")
				volume = initial(volume)
				return TRUE
			else if(new_volume == "min")
				volume = 0
				return TRUE
			else if(new_volume == "max")
				volume = 100
				return TRUE
			else if(text2num(new_volume) != null)
				volume = text2num(new_volume)
				return TRUE

/obj/machinery/jukebox/proc/activate_music()
	active = TRUE
	update_icon()
	START_PROCESSING(SSmachines, src)
	stop = world.time + selection.song_length
	ui_update()

/obj/machinery/jukebox/disco/activate_music()
	..()
	dance_setup()
	lights_spin()

/obj/machinery/jukebox/disco/proc/dance_setup()
	var/turf/cen = get_turf(src)
	FOR_DVIEW(var/turf/t, 3, get_turf(src),INVISIBILITY_LIGHTING)
		if(t.x == cen.x && t.y > cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_RED
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range  = 1+get_dist(src, L)
			spotlights+=L
			continue
		if(t.x == cen.x && t.y < cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_PURPLE
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range  = 1+get_dist(src, L)
			spotlights+=L
			continue
		if(t.x > cen.x && t.y == cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_DIM_YELLOW
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range = 1+get_dist(src, L)
			spotlights+=L
			continue
		if(t.x < cen.x && t.y == cen.y)
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_GREEN
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range = 1+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x+1 == cen.x && t.y+1 == cen.y) || (t.x+2==cen.x && t.y+2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_ORANGE
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x-1 == cen.x && t.y-1 == cen.y) || (t.x-2==cen.x && t.y-2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_CYAN
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x-1 == cen.x && t.y+1 == cen.y) || (t.x-2==cen.x && t.y+2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_BLUEGREEN
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		if((t.x+1 == cen.x && t.y-1 == cen.y) || (t.x+2==cen.x && t.y-2 == cen.y))
			var/obj/item/flashlight/spotlight/L = new /obj/item/flashlight/spotlight(t)
			L.light_color = LIGHT_COLOR_BLUE
			L.light_power = 30-(get_dist(src,L)*8)
			L.light_range = 1.4+get_dist(src, L)
			spotlights+=L
			continue
		continue
	FOR_DVIEW_END

/obj/machinery/jukebox/disco/proc/hierofunk()
	for(var/i in 1 to 10)
		spawn_atom_to_turf(/obj/effect/temp_visual/hierophant/telegraph/edge, src, 1, FALSE)
		sleep(5)

#define DISCO_INFENO_RANGE (rand(85, 115)*0.01)

/obj/machinery/jukebox/disco/proc/lights_spin()
	for(var/i in 1 to 25)
		if(QDELETED(src) || !active)
			return
		var/obj/effect/overlay/sparkles/S = new /obj/effect/overlay/sparkles(src)
		S.alpha = 0
		sparkles += S
		switch(i)
			if(1 to 8)
				S.orbit(src, 30, TRUE, 60, 36, TRUE)
			if(9 to 16)
				S.orbit(src, 62, TRUE, 60, 36, TRUE)
			if(17 to 24)
				S.orbit(src, 95, TRUE, 60, 36, TRUE)
			if(25)
				S.pixel_y = 7
				S.forceMove(get_turf(src))
		sleep(7)
	if(selection.song_name == "Engineering's Ultimate High-Energy Hustle")
		sleep(280)
	for(var/obj/reveal in sparkles)
		reveal.alpha = 255
	while(active)
		for(var/obj/item/flashlight/spotlight/glow in spotlights) // The multiples reflects custom adjustments to each colors after dozens of tests
			if(QDELETED(src) || !active || QDELETED(glow))
				return
			if(glow.light_color == LIGHT_COLOR_RED)
				glow.light_color = LIGHT_COLOR_BLUE
				glow.light_power = glow.light_power * 1.48
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_BLUE)
				glow.light_color = LIGHT_COLOR_GREEN
				glow.light_range = glow.light_range * DISCO_INFENO_RANGE
				glow.light_power = glow.light_power * 2 // Any changes to power must come in pairs to neutralize it for other colors
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_GREEN)
				glow.light_color = LIGHT_COLOR_ORANGE
				glow.light_power = glow.light_power * 0.5
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_ORANGE)
				glow.light_color = LIGHT_COLOR_PURPLE
				glow.light_power = glow.light_power * 2.27
				glow.light_range = glow.light_range * DISCO_INFENO_RANGE
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_PURPLE)
				glow.light_color = LIGHT_COLOR_BLUEGREEN
				glow.light_power = glow.light_power * 0.44
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_BLUEGREEN)
				glow.light_color = LIGHT_COLOR_DIM_YELLOW
				glow.light_range = glow.light_range * DISCO_INFENO_RANGE
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_DIM_YELLOW)
				glow.light_color = LIGHT_COLOR_CYAN
				glow.light_range = 0
				glow.update_light()
				continue
			if(glow.light_color == LIGHT_COLOR_CYAN)
				glow.light_color = LIGHT_COLOR_RED
				glow.light_power = glow.light_power * 0.68
				glow.light_range = glow.light_range * DISCO_INFENO_RANGE
				glow.update_light()
				continue
		if(prob(2))  // Unique effects for the dance floor that show up randomly to mix things up
			INVOKE_ASYNC(src, PROC_REF(hierofunk))
		sleep(selection.song_beat)
		if(QDELETED(src))
			return

#undef DISCO_INFENO_RANGE

/obj/machinery/jukebox/disco/proc/dance(mob/living/M) //Show your moves
	set waitfor = FALSE
	switch(rand(0,9))
		if(0 to 1)
			dance2(M)
		if(2 to 3)
			dance3(M)
		if(4 to 6)
			dance4(M)
		if(7 to 9)
			dance5(M)

/obj/machinery/jukebox/disco/proc/dance2(mob/living/M)
	for(var/i in 0 to 9)
		dance_rotate(M, CALLBACK(M, TYPE_PROC_REF(/mob, dance_flip)))
		sleep(2 SECONDS)

/mob/proc/dance_flip()
	if(dir == WEST)
		emote("flip")

/obj/machinery/jukebox/disco/proc/dance3(mob/living/M)
	var/matrix/initial_matrix = matrix(M.transform)
	for (var/i in 1 to 75)
		if (!M)
			return
		switch(i)
			if (1 to 15)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (16 to 30)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(1,-1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (31 to 45)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-1,-1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (46 to 60)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-1,1)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (61 to 75)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(1,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		M.setDir(turn(M.dir, 90))
		switch (M.dir)
			if (NORTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (SOUTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,-3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (EAST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (WEST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		sleep(1)
	M.lying_fix()

/obj/machinery/jukebox/disco/proc/dance4(mob/living/M)
	var/speed = rand(1,3)
	set waitfor = 0
	var/time = 30
	while(time)
		sleep(speed)
		for(var/i in 1 to speed)
			M.setDir(pick(GLOB.cardinals))
			for(var/mob/living/carbon/NS in rangers)
				NS.set_resting(!NS.resting, TRUE, TRUE)
		 time--

/obj/machinery/jukebox/disco/proc/dance5(mob/living/M)
	animate(M, transform = matrix(180, MATRIX_ROTATE), time = 1, loop = 0)
	var/matrix/initial_matrix = matrix(M.transform)
	for (var/i in 1 to 60)
		if (!M)
			return
		if (i<31)
			initial_matrix = matrix(M.transform)
			initial_matrix.Translate(0,1)
			animate(M, transform = initial_matrix, time = 1, loop = 0)
		if (i>30)
			initial_matrix = matrix(M.transform)
			initial_matrix.Translate(0,-1)
			animate(M, transform = initial_matrix, time = 1, loop = 0)
		M.setDir(turn(M.dir, 90))
		switch (M.dir)
			if (NORTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (SOUTH)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(0,-3)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (EAST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
			if (WEST)
				initial_matrix = matrix(M.transform)
				initial_matrix.Translate(-3,0)
				animate(M, transform = initial_matrix, time = 1, loop = 0)
		sleep(1)
	M.lying_fix()

/mob/living/proc/lying_fix()
	animate(src, transform = null, time = 1, loop = 0)
	lying_prev = 0

/obj/machinery/jukebox/proc/dance_over()
	for(var/mob/living/L in rangers)
		if(!L || !L.client)
			continue
		L.stop_sound_channel(CHANNEL_JUKEBOX)
	rangers = list()

/obj/machinery/jukebox/disco/dance_over()
	..()
	QDEL_LIST(spotlights)
	QDEL_LIST(sparkles)

/obj/machinery/jukebox/process()
	if(world.time < stop && active)
		var/sound/song_played = sound(selection.song_path)

		for(var/mob/L as anything in rangers)
			if(get_dist(src,L) > 10)
				rangers -= L
				if(!L || !L.client)
					continue
				L.stop_sound_channel(CHANNEL_JUKEBOX)
		for(var/mob/M as() in hearers(10,src))
			if(!M.client || !M.client.prefs.read_player_preference(/datum/preference/toggle/sound_instruments))
				continue
			if(!(M in rangers))
				rangers += M
				M.playsound_local(get_turf(M), null, volume, channel = CHANNEL_JUKEBOX, S = song_played, use_reverb = FALSE)
	else if(active)
		active = FALSE
		STOP_PROCESSING(SSobj, src)
		dance_over()
		playsound(src,'sound/machines/terminal_off.ogg',50,TRUE)
		update_icon()
		stop = world.time + 100
		ui_update()
		return PROCESS_KILL

/obj/machinery/jukebox/disco/process()
	. = ..()
	if(active)
		for(var/mob/living/M in rangers)
			if(prob(5+(allowed(M)*4)) && (M.mobility_flags & MOBILITY_MOVE))
				dance(M)
