// So much of atmospherics.dm was used solely by components, so separating this makes things all a lot cleaner.
// On top of that, now people can add component-speciic procs/vars if they want!

/obj/machinery/atmospherics/components
	hide = FALSE
	layer = GAS_PUMP_LAYER
	///Is the component welded?
	var/welded = FALSE
	///Should the component should show the pipe underneath it?
	var/showpipe = TRUE
	///When the component is on a non default layer should we shift everything? Or just the underlay pipe
	var/shift_underlay_only = TRUE
	///Stores the component pipenet
	var/list/datum/pipenet/parents
	///If this is queued for a rebuild this var signifies whether parents should be updated after it's done
	var/update_parents_after_rebuild = FALSE
	///Stores the component gas mixture
	var/list/datum/gas_mixture/airs
	///Handles whether the custom reconcilation handling should be used
	var/custom_reconcilation = FALSE

/obj/machinery/atmospherics/components/New()
	parents = new(device_type)
	airs = new(device_type)

	..()

	for(var/i in 1 to device_type)
		var/datum/gas_mixture/component_mixture = new
		component_mixture.volume = 200
		airs[i] = component_mixture

/obj/machinery/atmospherics/components/Initialize(mapload)
	. = ..()

	if(hide)
		RegisterSignal(src, COMSIG_OBJ_HIDE, PROC_REF(hide_pipe))

// Iconnery

/**
 * Called by update_icon(), used individually by each component to determine the icon state without the pipe in consideration
 */
/obj/machinery/atmospherics/components/proc/update_icon_nopipes()
	return

/**
 * Called in Initialize(), set the showpipe var to true or false depending on the situation, calls update_icon()
 */
/obj/machinery/atmospherics/components/proc/hide_pipe(datum/source, underfloor_accessibility)
	SIGNAL_HANDLER
	showpipe = !!underfloor_accessibility
	update_appearance()

/obj/machinery/atmospherics/components/update_icon()
	update_icon_nopipes()

	underlays.Cut()

	color = null
	plane = showpipe ? GAME_PLANE : FLOOR_PLANE

	if(!showpipe)
		return ..()
	if(pipe_flags & PIPING_DISTRO_AND_WASTE_LAYERS)
		return ..()

	var/connected = 0 //Direction bitset

	var/underlay_pipe_layer = shift_underlay_only ? piping_layer : 3

	for(var/i in 1 to device_type) //adds intact pieces
		if(!nodes[i])
			continue
		var/obj/machinery/atmospherics/node = nodes[i]
		var/node_dir = get_dir(src, node)
		var/mutable_appearance/pipe_appearance = mutable_appearance('icons/obj/atmospherics/pipes/pipe_underlays.dmi', "intact_[node_dir]_[underlay_pipe_layer]")
		pipe_appearance.color = node.pipe_color
		underlays += pipe_appearance
		connected |= node_dir

	for(var/direction in GLOB.cardinals)
		if((initialize_directions & direction) && !(connected & direction))
			var/mutable_appearance/pipe_appearance = mutable_appearance('icons/obj/atmospherics/pipes/pipe_underlays.dmi', "exposed_[direction]_[underlay_pipe_layer]")
			pipe_appearance.color = pipe_color
			underlays += pipe_appearance

	if(!shift_underlay_only)
		PIPING_LAYER_SHIFT(src, piping_layer)
	return ..()

// Pipenet stuff; housekeeping

/obj/machinery/atmospherics/components/nullify_node(i)
	if(parents[i])
		nullify_pipenet(parents[i])
	airs[i] = null
	return ..()

/obj/machinery/atmospherics/components/on_construction(mob/user)
	. = ..()
	update_parents()

/obj/machinery/atmospherics/components/on_deconstruction()
	relocate_airs()
	return ..()

/obj/machinery/atmospherics/components/rebuild_pipes()
	. = ..()
	if(update_parents_after_rebuild)
		update_parents()

/obj/machinery/atmospherics/components/get_rebuild_targets()
	var/list/to_return = list()
	for(var/i in 1 to device_type)
		if(parents[i])
			continue
		parents[i] = new /datum/pipenet()
		to_return += parents[i]
	return to_return

/**
 * Called by nullify_node(), used to remove the pipenet the component is attached to
 * Arguments:
 * * -reference: the pipenet the component is attached to
 */
/obj/machinery/atmospherics/components/proc/nullify_pipenet(datum/pipenet/reference)
	if(!reference)
		CRASH("nullify_pipenet(null) called by [type] on [COORD(src)]")

	for (var/i in 1 to length(parents))
		if (parents[i] == reference)
			reference.other_airs -= airs[i] // Disconnects from the pipenet side
			parents[i] = null // Disconnects from the machinery side.

	reference.other_atmos_machines -= src
	if(custom_reconcilation)
		reference.require_custom_reconcilation -= src

	/**
	 *  We explicitly qdel pipenet when this particular pipenet
	 *  is projected to have no member and cause GC problems.
	 *  We have to do this because components don't qdel pipenets
	 *  while pipes must and will happily wreck and rebuild everything
	 * again every time they are qdeleted.
	 */

	if(!length(reference.other_atmos_machines) && !length(reference.members))
		if(QDESTROYING(reference))
			CRASH("nullify_pipenet() called on qdeleting [reference]")
		qdel(reference)

/obj/machinery/atmospherics/components/return_pipenet_airs(datum/pipenet/reference)
	var/list/returned_air = list()

	for (var/i in 1 to parents.len)
		if (parents[i] == reference)
			returned_air += airs[i]
	return returned_air

/obj/machinery/atmospherics/components/pipenet_expansion(datum/pipenet/reference)
	if(reference)
		return list(nodes[parents.Find(reference)])
	return ..()

/obj/machinery/atmospherics/components/set_pipenet(datum/pipenet/reference, obj/machinery/atmospherics/target_component)
	parents[nodes.Find(target_component)] = reference

/obj/machinery/atmospherics/components/return_pipenet(obj/machinery/atmospherics/target_component = nodes[1]) //returns parents[1] if called without argument
	return parents[nodes.Find(target_component)]

/obj/machinery/atmospherics/components/replace_pipenet(datum/pipenet/Old, datum/pipenet/New)
	parents[parents.Find(Old)] = New

// Helpers

/**
 * Called in most atmos processes and gas handling situations, update the parents pipenets of the devices connected to the source component
 * This way gases won't get stuck
 */
/obj/machinery/atmospherics/components/proc/update_parents()
	if(!SSair.initialized)
		return
	if(rebuilding)
		update_parents_after_rebuild = TRUE
		return
	for(var/i in 1 to device_type)
		var/datum/pipenet/parent = parents[i]
		if(!parent)
			WARNING("Component is missing a pipenet! Rebuilding...")
			SSair.add_to_rebuild_queue(src)
		else
			parent.update = TRUE

/obj/machinery/atmospherics/components/return_pipenets()
	. = list()
	for(var/i in 1 to device_type)
		. += return_pipenet(nodes[i])

/// When this machine is in a pipenet that is reconciling airs, this proc can add pipenets to the calculation.
/// Can be either a list of pipenets or a single pipenet.
/obj/machinery/atmospherics/components/proc/return_pipenets_for_reconcilation(datum/pipenet/requester)
	return list()

/// When this machine is in a pipenet that is reconciling airs, this proc can add airs to the calculation.
/// Can be either a list of airs or a single air mix.
/obj/machinery/atmospherics/components/proc/return_airs_for_reconcilation(datum/pipenet/requester)
	return list()

// UI Stuff

/obj/machinery/atmospherics/components/ui_status(mob/user)
	if(allowed(user))
		return ..()
	to_chat(user, "<span class='danger'>Access denied.</span>")
	return UI_CLOSE

// Tool acts

/obj/machinery/atmospherics/components/return_analyzable_air()
	return airs

/**
 * Handles machinery deconstruction and unsafe pressure release
 */
/obj/machinery/atmospherics/components/proc/crowbar_deconstruction_act(mob/living/user, obj/item/tool, internal_pressure = 0)
	if(!panel_open)
		balloon_alert(user, "open panel!")
		return TRUE

	var/unsafe_wrenching = FALSE
	var/filled_pipe = FALSE
	var/datum/gas_mixture/environment_air = loc.return_air()

	for(var/i in 1 to device_type)
		var/datum/gas_mixture/inside_air = airs[i]
		if(inside_air.total_moles() > 0 || internal_pressure)
			filled_pipe = TRUE
		if(!nodes[i] || (istype(nodes[i], /obj/machinery/atmospherics/components/unary/portables_connector) && !portable_device_connected(i)))
			internal_pressure = internal_pressure > airs[i].return_pressure() ? internal_pressure : airs[i].return_pressure()

	if(!filled_pipe)
		default_deconstruction_crowbar(tool)
		return TRUE

	internal_pressure -= environment_air.return_pressure()

	if(internal_pressure > 2 * ONE_ATMOSPHERE)
		to_chat(user, "<span class='warning'>As you begin deconstructing \the [src] a gush of air blows in your face... maybe you should reconsider?</span>")
		unsafe_wrenching = TRUE

	if(!do_after(user, 2 SECONDS, src))
		return
	if(unsafe_wrenching)
		unsafe_pressure_release(user, internal_pressure)
	tool.play_tool_sound(src, 50)
	deconstruct(TRUE)
	return TRUE

/obj/machinery/atmospherics/components/default_change_direction_wrench(mob/user, obj/item/I)
	. = ..()
	if(!.)
		return FALSE
	set_init_directions()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			if(src in node.nodes)
				node.disconnect(src)
			nodes[i] = null
		if(parents[i])
			nullify_pipenet(parents[i])
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		atmos_init()
		node = nodes[i]
		if(node)
			node.atmos_init()
			node.add_member(src)
			update_parents()
		SSair.add_to_rebuild_queue(src)
	return TRUE

/obj/machinery/atmospherics/components/paint(paint_color)
	if(paintable)
		add_atom_colour(paint_color, FIXED_COLOUR_PRIORITY)
		pipe_color = paint_color
		update_node_icon()
	return paintable

/obj/machinery/atmospherics/components/default_change_direction_wrench(mob/user, obj/item/I)
	. = ..()
	if(!.)
		return FALSE
	set_init_directions()
	reconnect_nodes()
	return TRUE

/obj/machinery/atmospherics/components/proc/reconnect_nodes()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			if(src in node.nodes)
				node.disconnect(src)
			nodes[i] = null
		if(parents[i])
			nullify_pipenet(parents[i])
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		atmos_init()
		node = nodes[i]
		if(node)
			node.atmos_init()
			node.add_member(src)
			update_parents()
		SSair.add_to_rebuild_queue(src)

/**
 * Disconnects all nodes from ourselves, remove us from the node's nodes.
 * Nullify our parent pipenet
 */
/obj/machinery/atmospherics/components/proc/disconnect_nodes()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			if(src in node.nodes) //Only if it's actually connected. On-pipe version would is one-sided.
				node.disconnect(src)
			nodes[i] = null
		if(parents[i])
			nullify_pipenet(parents[i])

/**
 * Connects all nodes to ourselves, add us to the node's nodes.
 * Calls atmos_init() on the node and on us.
 */
/obj/machinery/atmospherics/components/proc/connect_nodes()
	atmos_init()
	for(var/i in 1 to device_type)
		var/obj/machinery/atmospherics/node = nodes[i]
		if(node)
			node.atmos_init()
			node.add_member(src)
	SSair.add_to_rebuild_queue(src)

/**
 * Easy way to toggle nodes connection and disconnection.
 *
 * Arguments:
 * * disconnect - if TRUE, disconnects all nodes. If FALSE, connects all nodes.
 */
/obj/machinery/atmospherics/components/proc/change_nodes_connection(disconnect)
	if(disconnect)
		disconnect_nodes()
		return
	connect_nodes()

/obj/machinery/atmospherics/components/update_layer()
	layer = (showpipe ? initial(layer) : ABOVE_OPEN_TURF_LAYER) + (piping_layer - PIPING_LAYER_DEFAULT) * PIPING_LAYER_LCHANGE + (GLOB.pipe_colors_ordered[pipe_color] * 0.001)

/**
 * Handles air relocation to the pipenet/environment
 */
/obj/machinery/atmospherics/components/proc/relocate_airs(datum/gas_mixture/to_release)
	var/turf/local_turf = get_turf(src)
	for(var/i in 1 to device_type)
		var/datum/gas_mixture/air = airs[i]
		if(!nodes[i] || (istype(nodes[i], /obj/machinery/atmospherics/components/unary/portables_connector) && !portable_device_connected(i)))
			if(!to_release)
				to_release = air
				continue
			to_release.merge(air)
			continue
		var/datum/gas_mixture/parents_air = parents[i].air
		parents_air.merge(air)
	if(to_release)
		local_turf.assume_air(to_release)
