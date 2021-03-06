//parent object
/obj/structure/artillery
	name = "Artillery"

/obj/structure/artillery/New(var/loc, var/mob/builder, var/dir)

	if (!dir)
		dir = SOUTH

	var/fake_builder = FALSE

	if (builder == null && dir != null)
		builder = new/mob(loc)
		builder.dir = dir
		fake_builder = TRUE

	var/obj/structure/artillery/base/base = new/obj/structure/artillery/base(loc)
	var/obj/structure/artillery/tube/tube = new/obj/structure/artillery/tube(get_step(base, base.dir))
	base.dir = builder.dir
	tube.dir = builder.dir
	base.other = tube
	tube.other = base
	base.anchored = TRUE
	tube.anchored = TRUE

	if (fake_builder)
		qdel(builder)

	qdel(src)

#define BLIND_FIRE_RANGES list("SHORT", "MEDIUM", "LONG")
#define BLIND_FIRE_DISTANCES list("SHORT" = "35:40", "MEDIUM" = "55:60", "LONG" = "75:80")

//first piece
/obj/structure/artillery/base
	var/obj/item/artillery_shell/loaded = null
	var/obj/structure/artillery/tube/other
	var/offset_x = FALSE
	var/offset_y = FALSE
	var/mob/user = null
	var/state = "CLOSED"
	var/casing_state = "casing"

	// setting for 'blind firing'
	var/blind_fire_toggle = FALSE
	var/blind_fire_dir = SOUTH
	var/blind_fire_dir2 = "NONE"
	var/blind_fire_range = "SHORT"

	// other
//	var/jammed_until = -1

	density = TRUE
	name = "2A61 Pat-B"
	icon = 'icons/obj/artillery_piece.dmi'
	icon_state = "base"
	layer = MOB_LAYER + 1 //just above mobs

/obj/structure/artillery/base/proc/get_blind_fire_dir()
	switch (blind_fire_dir)
		if (NORTH)
			return "NORTH"
		if (EAST)
			return "EAST"
		if (SOUTH)
			return "SOUTH"
		if (WEST)
			return "WEST"

/obj/structure/artillery/base/proc/get_blind_fire_dir2()
	switch (blind_fire_dir2)
		if (EAST)
			return "EAST"
		if (WEST)
			return "WEST"
		if ("NONE")
			return "NONE"

/obj/structure/artillery/base/proc/do_html(var/mob/m)

	if (m)

		m << browse({"

		<br>
		<html>

		<head>
		<style type="text/css">
	{
		color: #00f;
		font-family: Georgia, Arial, sans-serif;
	}
		</style>
		</head>

		<body>

		<script language="javascript">

		function set(input) {
		  window.location="byond://?src=\ref[src];action="+input.name+"&value="+input.value;
		}

		</script>

		<center>
		<big><b>[name]</b></big><br><br>
		<a href='?src=\ref[src];open=1'>Open the shell slot</a><br>
		<a href='?src=\ref[src];close=1'>Close the shell slot</a><br><br>
		<b>Loaded Shells</b><br><br>
		<a href='?src=\ref[src];load_slot_1=1'>[loaded.name]</a><br><br>
		<b>Firing Options</b><br><br>
		Artillery Piece X-coordinate:<input type="text" name="xcoord" readonly value="[x]" onchange="set(this);" /><br>
		Artillery Piece Y-coordinate:<input type="text" name="ycoord" readonly value="[y]" onchange="set(this);" /><br>
		Offset X-coordinate:<input type="text" name="xocoord" value="[offset_x]" onchange="set(this);" /><br>
		Offset Y-coordinate:<input type="text" name="yocoord" value="[offset_y]" onchange="set(this);" /><br>
		Fire At X-coordinate:<input type="text" name="xplusxocoord" value="[offset_x + x]" onchange="set(this);" /><br>
		Fire At Y-coordinate:<input type="text" name="yplusyocoord" value="[offset_y + y]" onchange="set(this);" /><br>
		Blind Firing:
		&nbsp;<a href='?src=\ref[src];blind_fire_toggle=1'>[blind_fire_toggle ? "YES" : "NO"]</a>
		&nbsp;<a href='?src=\ref[src];blind_fire_dir=1'>[get_blind_fire_dir()]</a>
		&nbsp;<a href='?src=\ref[src];blind_fire_dir2=1'>[get_blind_fire_dir2()]</a>
		&nbsp;<a href='?src=\ref[src];blind_fire_dist=1'>[blind_fire_range]</a>
		<br>
		<br>
		<a href='?src=\ref[src];fire=1'><b><big>FIRE!</big></b></a>
		</center>

		</body>
		</html>
		<br>
		"},  "window=artillery_window;border=1;can_close=1;can_resize=1;can_minimize=0;titlebar=1;size=500x500")
	//		<A href = '?src=\ref[src];topic_type=[topic_custom_input];continue_num=1'>

/obj/structure/artillery/base/interact(var/mob/m)
	if (user)
		if (get_dist(src, user) > 1)
			user = null
	restart
	if (user && user != m)
		if (user.client)
			return
		else
			user = null
			goto restart
	else
		user = m
		do_html(user)


/obj/structure/artillery/base/Move()
	valid_coordinates["[x],[y]"] = 0
	..()
	if (other)
		other.loc = (get_step(src, dir) || loc)
	valid_coordinates["[x],[y]"] = 1

/obj/structure/artillery/base/New()
	loaded = new/obj/item/artillery_shell/none(src)

/obj/structure/artillery/base/Del()
	..()

/obj/structure/artillery/base/proc/getNextOpeningClosingState()

	if (state == "CLOSED")
		return "opening"
	else
		if (loaded)
			return "closing_with_shell"
		else
			return "closing_without_shell"

/obj/structure/artillery/base/Topic(href, href_list, hsrc)

	var/mob/user = usr

	if (!user || user.lying)
		return

	user.face_atom(src)

	if (!locate(src) in get_step(user, user.dir))
		to_chat(user, "<span class = 'danger'>Get behind the artillery to use it.</span>")
		return FALSE

	if (!user.can_use_hands())
		to_chat(user, "<span class = 'danger'>You have no hands to use this with.</span>")
		return FALSE

	if (!anchored)
		to_chat(user, "<span class = 'danger'>The artillery piece must be wrenched to the ground to use.</span>")
		return FALSE

	var/value = href_list["value"]

	switch (href_list["action"])
		//we can enter offsets directly
		if ("xocoord")
			offset_x = text2num(value)
		if ("yocoord")
			offset_y = text2num(value)
		//or enter the firing location directly and have them generated
		if ("xplusxocoord")
			var/val = text2num(value)
			offset_x = val - x
		if ("yplusyocoord")
			var/val = text2num(value)
			offset_y = val - y

	if (href_list["fire"])

		//var/area = get_area(user)

		if (AREA_INSIDE)
			to_chat(user, "<span class = 'danger'>You can't fire from inside.</span>")
			return

		if (state == "OPEN")
			to_chat(user, "<span class='danger'>Close the shell loading slot first.</span>")
			return

		if (blind_fire_toggle)

			offset_x = FALSE
			offset_y = FALSE

			var/number_range = splittext(BLIND_FIRE_DISTANCES[blind_fire_range], ":")
			var/lowerbound = text2num(number_range[1])
			var/upperbound = text2num(number_range[2])
			var/add = rand(lowerbound, upperbound)

			switch (blind_fire_dir)
				if (NORTH)
					offset_y += add
				if (SOUTH)
					offset_y -= add
				if (EAST)
					offset_x += add
				if (WEST)
					offset_x -= add

			if (dir == NORTH || dir == SOUTH)
				switch (blind_fire_dir2)
					if (EAST)
						offset_x += add/2
					if (WEST)
						offset_x -= add/2

		var/target_x = offset_x + x
		var/target_y = offset_y + y

		target_x = min(max(target_x, 1), world.maxx)
		target_y = min(max(target_y, 1), world.maxy)

		var/valid_coords_check = FALSE

		if (!blind_fire_toggle)
			if (global.valid_coordinates.Find("[target_x],[target_y]"))
				valid_coords_check = TRUE
			else
				for (var/coords in global.valid_coordinates)
					var/splitcoords = splittext(coords, ",")
					var/coordx = text2num(splitcoords[1])
					var/coordy = text2num(splitcoords[2])
					if (abs(coordx - target_x) <= 15)
						if (abs(coordy - target_y) <= 15)
							valid_coords_check = TRUE
		else
			valid_coords_check = TRUE


		if (!valid_coords_check)
			to_chat(user, "<span class='danger'>You have no knowledge of this location.</span>")
			return

		if (abs(offset_x) > 0 || abs(offset_y) > 0)
			if (abs(offset_x) + abs(offset_y) < 20)
				to_chat(user, "<span class='danger'>This location is too close to fire to.</span>")
				return
			else if (other)
				var/obj/item/artillery_shell/shell = other.use_slot()
				if (shell && do_after(user, 30, src))
					other.fire(target_x, target_y, shell)
					to_chat(user, "<span class='danger'>You fire the artillery!</span>")
				else
					to_chat(user, "<span class='danger'>Load a shell in first.</span>")
					return
		else
			to_chat(user, "<span class='danger>Set an offset x and offset y coordinate.</span>")
			return

	if (href_list["open"])
		if (state == "OPEN")
			return
		flick("opening", src)
		if (do_after(user, 8, src))
			icon_state = "open"
			state = "OPEN"
		spawn (6)
			if (other.drop_casing)
				var/obj/o = new/obj/item/artillery_shell/casing(get_step(src, dir))
				o.icon_state = casing_state
				to_chat(user, "<span class='danger'>The casing falls out of the artillery.</span>")
				if (other)
					other.drop_casing = FALSE
				playsound(get_turf(src), 'sound/effects/Stamp.wav', 100, TRUE)

	if (href_list["close"])
		if (state == "CLOSED")
			return
		flick("closing", src)
		if (do_after(user, 12, src))
			icon_state = ""
			state = "CLOSED"

	for (var/i in 1 to 10)
		if (href_list["load_slot_[i]"])
			if (state == "CLOSED")
				to_chat(user, "<span class = 'danger'>The shell loading slot must be open to add a shell.</span>")
				return

			if (do_after(user, 10, src))
				load_slot(i, user)


	//	flick("opening", src)


	// blind firing

	if (href_list["blind_fire_toggle"])
		blind_fire_toggle = !blind_fire_toggle


	if (href_list["blind_fire_dist"])
		switch (blind_fire_range)
			if ("SHORT")
				blind_fire_range = "MEDIUM"
			if ("MEDIUM")
				blind_fire_range = "LONG"
			if ("LONG")
				blind_fire_range = "SHORT"

	// no cardinal directions for now
	if (href_list["blind_fire_dir"])

		switch (blind_fire_dir)
			if (NORTH)
				blind_fire_dir = EAST
			if (EAST)
				blind_fire_dir = SOUTH
			if (SOUTH)
				blind_fire_dir = WEST
			if (WEST)
				blind_fire_dir = NORTH

		if (blind_fire_dir != SOUTH && blind_fire_dir != NORTH)
			blind_fire_dir2 = "NONE"

	if (href_list["blind_fire_dir2"])

		if (blind_fire_dir != SOUTH && blind_fire_dir != NORTH)
			blind_fire_dir2 = "NONE"
		else
			switch (blind_fire_dir2)
				if ("NONE")
					blind_fire_dir2 = EAST
				if (EAST)
					blind_fire_dir2 = WEST
				if (WEST)
					blind_fire_dir2 = "NONE"

	do_html(user)

/obj/structure/artillery/base/proc/load_slot(var/slot = 1, var/mob/user)
	var/obj/o = user.get_active_hand()
	var/cond_1 = o && istype(o, /obj/item/artillery_shell) && !istype(o, /obj/item/artillery_shell/casing)
	var/cond_2 = !o

	if (cond_1 || cond_2)

		if (!istype(loaded, /obj/item/artillery_shell/none))
			loaded.loc = get_turf(user)

		if (o)
			user.drop_from_inventory(o)
			o.loc = src
			loaded = o
			icon_state = "open_with_shell"
			state = "OPEN"
		else
			icon_state = "open"
			state = "OPEN"
			loaded = new/obj/item/artillery_shell/none(src)

	do_html(user)

/obj/structure/artillery/base/attack_hand(var/mob/attacker)
	interact(attacker)

// todo: loading artillery. This will regenerate the shrapnel and affect our explosion
/obj/structure/artillery/base/attackby(obj/item/W as obj, mob/M as mob)
	if (istype(W, /obj/item/weapon/wrench))
		if (anchored)
			playsound(loc, 'sound/items/Ratchet.ogg', 100, TRUE)
			to_chat(M, "<span class='notice'>Now unsecuring the artillery piece...</span>")
			if (do_after(M, 20, src))
				if (!src) return
				to_chat(M, "<span class='notice'>You unsecured the artillery piece.</span>")
				anchored = FALSE
		else if (!anchored)
			playsound(loc, 'sound/items/Ratchet.ogg', 100, TRUE)
			to_chat(M, "<span class='notice'>Now securing the artillery piece...</span>")
			if (do_after(M, 20, src))
				if (!src) return
				to_chat(M, "<span class='notice'>You secured the artillery piece.</span>")
				anchored = TRUE
	else if (istype(W, /obj/item/artillery_shell) && !istype(W, /obj/item/artillery_shell/none))
		if (!anchored)
			to_chat(M, "<span class = 'danger'>The artillery piece must be wrench to the ground to use.</span>")
			return
		if (state == "CLOSED")
			to_chat(M, "<span class = 'danger'>The shell loading slot must be open to add a shell.</span>")
			return
			// load first and only slot
		load_slot(1, M)

/obj/structure/artillery/base/Destroy()
	..()
	qdel(other)
//second piece

/obj/structure/artillery/tube
	var/obj/structure/artillery/base/other = null
	icon_state = "tube"
	name = ""
	layer = FALSE
	var/drop_casing = FALSE

	proc/fire(var/x, var/y, shell)

		var/explosion = FALSE

		if (istype(shell, /obj/item/artillery_shell))
			var/obj/item/artillery_shell/shell2 = shell
			other.casing_state = shell2.casing_state

		qdel(shell)

		z = other.z //mostly for testing, such as when you teleport the base

		drop_casing = TRUE

		other.icon_state = "firing"

		for (var/mob/m)
			if (m.client)
				var/abs_dist = abs(m.x - other.x) + abs(m.y - other.y)
				if (abs_dist <= 75)
					shake_camera(m, 5, (5 - (abs_dist/20)))

		spawn (10)
			other.icon_state = initial(other.icon_state)

		var/dirX = "NONE"
		var/dirY = "NONE"
		var/direction = NORTH

		if (x > other.x)
			dirX = "EAST"
		else if (x < other.x)
			dirX = "WEST"

		if (y > other.y)
			dirY = "NORTH"
		else if (y < other.y)
			dirY = "SOUTH"

		switch (dirY)
			if ("SOUTH")
				switch (dirX)
					if ("EAST")
						direction = SOUTHEAST
					if ("WEST")
						direction = SOUTHWEST
					if ("NONE")
						direction = SOUTH
			if ("NORTH")
				switch (dirX)
					if ("EAST")
						direction = NORTHEAST
					if ("WEST")
						direction = NORTHEAST
					if ("NONE")
						direction = NORTH
			if ("NONE")
				switch (dirX)
					if ("EAST")
						direction = EAST
					if ("WEST")
						direction = WEST
					if ("NONE")
						direction = null

		if (direction != null) // how did this even happen
			spawn (rand(4,6))
				new/obj/effect/effect/smoke/chem(get_step(src, direction))
			spawn (rand(5,7))
				new/obj/effect/effect/smoke/chem(get_step(src, direction))
			spawn (rand(6,7))
				new/obj/effect/effect/smoke/chem(get_step(src, direction))
			spawn (5)
				new/obj/effect/effect/smoke/chem(get_step(src, pick(NORTH, EAST, SOUTH, WEST)))

		spawn (rand(1,2))
			var/turf/t1 = get_turf(src)
			var/list/heard = playsound(t1, "artillery_out", 100, TRUE)
			playsound(t1, "artillery_out_distant", 100, TRUE, excluded = heard)

		x = x + rand(1,-1)
		y = y + rand(1,-1)

		var/turf/t = locate(x, y, z)
		var/t_x = t.x
		var/t_y = t.y
		var/t_z = t.z

		if (!t)
			return

		var/power_mult = 2.0 //experimental

		var/travel_time = 0

		var/abs_dist = abs(t.x - other.x) + abs(t.y - other.y)

		travel_time = abs((round(abs_dist/50) * 10)) + 50 // must be at least 2 seconds for the incoming sound to
		// work right

		spawn (max(travel_time - 50,0))
			if (prob(66))
				for (var/mob/living/carbon/human/H in range(15, t))
					if (!(H.disabilities & DEAF))
						to_chat(H, "<span class = 'userdanger'>You think you can hear the sound of artillery flying in! Take cover!</span>")

		spawn (travel_time - 20) // the new artillery sound takes about 2 seconds to reach the explosion point, so start playing it now
			var/list/heard = playsound(t, "artillery_in", 100, TRUE)
			playsound(t, "artillery_in_distant", 100, TRUE, 100, excluded = heard)

		spawn (travel_time)

/*
			if (istrueflooring(t) || iswall(t) || t_area.location == AREA_INSIDE)
				var/area/a = t.loc
				var/a_original_integrity = a.artillery_integrity
				if (!a.arty_act(explosion ? 25 : 13))
					for (var/mob/living/L in view(20, t))
						shake_camera(L, 5, 5)
						L << "<span class = 'danger'>You hear something violently smash into the ceiling!</span>"
					message_admins("Artillery shell hit the ceiling at [t.x], [t.y], [t.z].")
					log_admin("Artillery shell hit the ceiling at [t.x], [t.y], [t.z].")
					return
				else if (a_original_integrity)
					t.visible_message("<span class = 'danger'>The ceiling collapses!</span>")
*/

			if (explosion)
				message_admins("HE artillery shell hit at [t.x], [t.y], [t.z].")
				log_admin("HE artillery shell hit at [t.x], [t.y], [t.z].")
				explosion(t, 2*power_mult, 4*power_mult, 6*power_mult, 9*power_mult)
				spawn (1)
					for (var/turf/T in getcircle(locate(t_x,t_y,t_z), 12))
						var/obj/item/projectile/bullet/pellet/fragment/P = new /obj/item/projectile/bullet/pellet/fragment(T)
						P.damage = 12
						P.pellets = 1
						P.range_step = 2
						P.shot_from = name
						P.fragmentate(T)

						//Make sure to hit any mobs in the source turf
						for (var/mob/living/L in T)
							//lying on a frag grenade while the grenade is on the ground causes you to absorb most of the shrapnel.
							//you will most likely be dead, but others nearby will be spared the fragments that hit you instead.
							if (L.lying)
								P.attack_mob(L, FALSE, FALSE)
							else
								P.attack_mob(L, FALSE, 100) //otherwise, allow a decent amount of fragments to pass

/obj/structure/artillery/tube/proc/use_slot()
	var/orig = null
	if (istype(other.loaded, /obj/item/artillery_shell))
		orig = other.loaded
		if (!istype(other.loaded, /obj/item/artillery_shell/none))
			if (!istype(other.loaded, /obj/item/artillery_shell/casing))
				other.loaded = new/obj/item/artillery_shell/none(src)
				return orig
	else
		return orig

/obj/structure/artillery/tube/interact(var/mob/m)
	return

/obj/structure/artillery/tube/New()
	return

/obj/structure/artillery/ex_act(severity)
	return

/obj/structure/artillery/base/ex_act(severity)
	switch(severity)
		if (1.0)
			qdel(src)
			qdel(other)
			return
		if (2.0)
			if (prob(10))
				qdel(src)
				qdel(other)
				return
		if (3.0)
			return
