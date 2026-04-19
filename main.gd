extends Node2D
var RNG = RandomNumberGenerator.new()

#Plane Directory:
#Positions 0 & 6 are position holders for offscreen planes. 
var ord_y_positions: PackedInt32Array = [535, 434, 363,291,219,149, 50]
var spacer = 90
var SquSpa = 45
var plane = load("res://f_15c.tscn")
var squadron = load("res://squadron.tscn")
var selplane = "none"
var NuPlane 
var positiongrid = [[],[],[],[],[],[],[]]
var BLUsquadrongrid = []
var REDsquadrongrid = []
var BLUBoneyard = []
var REDBoneyard = []
var oldcell
#UI phases and states:
var state = "standard"
var die
var phase = "BLU"
var MPop = false
var APop = false
var SPop = false
var Commanding
var selsquad
#Based on command button presses, determine the effect of selecting another plane

func _ready() -> void:
	RNG.randomize()
	
	_buildplane("f15", "BLU")
	_debugMove("f15", 1)
	_buildplane("z15", "RED")
	_debugMove("z15", 5)
	_buildsquadron("15s","BLU")
	_buildsquadron("152","BLU")
	_buildsquadron("153","BLU")
	_buildsquadron("zc7", "RED")
	
	#Has to navigate through squadron panel
	#Creates planes and assigns them to the inside of a squadron
	#This should be organized into it's own GD, allowing user to selection Squadrons instead.
	_buildplaneS("Su7", "RED", get_node("Squadron Panel/zc7"))
	_buildplaneS("F-34", "BLU", get_node("Squadron Panel/15s")) #Naming system is incorrect, F-34 is not a real aircraft. 
	_buildplaneS("F-35", "BLU", get_node("Squadron Panel/152"))
	_buildplaneS("F-36", "BLU", get_node("Squadron Panel/153"))
	_buildplaneS("Su8", "RED", get_node("Squadron Panel/zc7"))
	_buildplaneS("Su9", "RED", get_node("Squadron Panel/zc7"))
	_buildplaneS("Su10", "RED", get_node("Squadron Panel/zc7"))
	
	
	
	_teamSwap("BLU")

#var acquired = false
#var acqStat = 2
#var acqMod = 0
#var acqRange = 2
#AA
#var shotRoll = 3
#var shotRange = 2
#var shotammo = true
#AS
#var bombRoll = 2
#var bombRange = 1
#var bombammo = true
#Positioning
#var movRange = 2
#var cell = 0
#var dead = false

func _teamSwap(team: String):
	phase = team
	if team == "RED":
		get_node("Panel").modulate = Color(1,0,0,1)
		for Object in BLUsquadrongrid:
			Object.visible = false
		for Object in REDsquadrongrid:
			Object.visible = true
	elif team == "BLU":
		get_node("Panel").modulate = Color(0,0,1,1)
		for Object in REDsquadrongrid:
			Object.visible = false
		for Object in BLUsquadrongrid:
			Object.visible = true
	#Variables determine whether or not the turn includes a Move, Acquire, or Shoot
	MPop = false
	APop = false
	SPop = false
	get_node("Panel4/MDonel").text = "1/1"
	get_node("Panel5/ADone").text = "1/1"
	get_node("Panel6/SDone").text = "1/1"
	selplane = "none"
	state = "standard"
	_on_cancel_squad_pressed()
		

#Make M/A/SPopit parameterized instead of 3 separate variables
func mark_as_spent(variable: String, label_path: String):
	set(variable, true)
	get_node(label_path).text = "SPENT"

	
func _on_press(name: String):
	print(name)
	if get_node("Squadron Panel").has_node(name):
		#Should this be an undeployed Squadron node
		if state == "Deployment":
			selsquad = get_node("Squadron Panel").get_node(name)
			get_node("Squadron Panel/DeploySquad").visible = true
		return
	elif positiongrid[0].has(get_node(name)):
		if phase == "RED" && state == "shoot":
			_bomb(get_node(name), selplane)
		elif phase == "BLU" && state == "standard":
			if get_node(name).planeslist.size() != 0:
				_on_press(get_node(name).planeslist[0].name)
			pass
		return
	elif positiongrid[6].has(get_node(name)):
		if phase == "BLU" && state == "shoot":
			_bomb(get_node(name), selplane)
		elif phase == "RED" && state == "standard":
			if get_node(name).planeslist.size() != 0:
				_on_press(get_node(name).planeslist[0].name)
		return
	print(get_node(name).cell)
	print(name)
	print(state)
	if (state == "standard"):
		selplane = name
		#Commanding Variable is based on whether or not the selected plane belongs to the player with the turn
		Commanding = (phase == get_node(selplane).loyalty)
		
		if Commanding:
			get_node("Panel3/Label").text = "Plane" + str(name)
			get_node("Panel5/AMod").text = "+" + str(get_node(selplane).acqMod)
			get_node("Panel5/ARange").text = str(get_node(selplane).acqRange)
			get_node("Panel4/MRange").text = str(get_node(selplane).movRange)
			get_node("Panel6/SRange").text = str(get_node(selplane).shotRange)
			get_node("Panel6/SRoll").text = str(get_node(selplane).shotRoll)
			get_node("Panel3/Loyalty").text = str(get_node(selplane).loyalty)
		elif get_node(selplane).acquired:
			get_node("Panel3/Label").text = "Plane" + str(name)
			get_node("Panel5/AMod").text = "+" + str(get_node(selplane).acqMod)
			get_node("Panel5/ARange").text = str(get_node(selplane).acqRange)
			get_node("Panel4/MRange").text = str(get_node(selplane).movRange)
			get_node("Panel6/SRange").text = str(get_node(selplane).shotRange)
			get_node("Panel6/SRoll").text = str(get_node(selplane).shotRoll)
			get_node("Panel3/Loyalty").text = str(get_node(selplane).loyalty)
		else:
			get_node("Panel3/Label").text = "UNKNOWN AIRCRAFT"
			get_node("Panel5/AMod").text = "?"
			get_node("Panel5/ARange").text = "?"
			get_node("Panel4/MRange").text = "?"
			get_node("Panel6/SRange").text = "?"
			get_node("Panel6/SRoll").text = "?"
			get_node("Panel3/Loyalty").text = "?"
			
	elif (state == "acquire"):
		_acquire(selplane, name)
	elif (state == "shoot"):
		_shoot(selplane, name)
	elif (state == "standard"):
		var selsquad = name
		Commanding = (phase == get_node(selplane).loyalty)
	
func _buildplane(inpName: String, inpLoyalty: String):
	NuPlane = plane.instantiate()
	add_child(NuPlane)
	NuPlane.press.connect(_on_press)
	NuPlane.name = (inpName)
	NuPlane.loyalty = (inpLoyalty)
	if inpLoyalty == "RED":
		NuPlane.get_node("PlaneSquare").modulate = Color(0.8,0.1,0.1,1)
	elif inpLoyalty == "BLU":
		NuPlane.get_node("PlaneSquare").modulate = Color(0.1,0.1,0.8,1)


func _buildplaneS(inpName: String, inpLoyalty: String, squadron: Object):
	print(squadron) 
	NuPlane = plane.instantiate()
	add_child(NuPlane)
	NuPlane.press.connect(_on_press)
	NuPlane.name = (inpName)
	NuPlane.loyalty = (inpLoyalty)
	if inpLoyalty == "RED":
		NuPlane.get_node("PlaneSquare").modulate = Color(0.8,0.1,0.1,1)
	elif inpLoyalty == "BLU":
		NuPlane.get_node("PlaneSquare").modulate = Color(0.1,0.1,0.8,1)
	squadron.planeslist.push_front(NuPlane)
	NuPlane.position = Vector2(-50,-50)
	NuPlane.cell = squadron.cell
	NuPlane.home_squad = squadron

func _move(plane_name: String, target: int):
	# Guard
	if state != "move" or MPop:
		return
	
	var plane = get_node(plane_name)
	var distance = abs(plane.cell - target)
	
	if plane.movRange < distance:
		state = "standard"
		return
	#Departure from current cell
	var old_idx = plane.cell
	
	# Boundary handling
	if old_idx == 0 or old_idx == 6:
		print("TRY ERASE")
		plane.home_squad._flyOff(plane)
	
	# Remove from current grid and realign the remaining planes in that row
	positiongrid[old_idx].erase(plane_name)
	if old_idx != 0 and old_idx != 6:
		_realign_row(old_idx)

	# 3. Handle arrival at target cell
	plane.cell = target
	positiongrid[target].append(plane_name)

	# Update Y using array lookup
	if target >= 0 and target < ord_y_positions.size():
		plane.position.y = ord_y_positions[target]
	
	# Calculate new X position
	var stack_pos = positiongrid[target].size() - 1
	plane.position.x = 400 + (stack_pos * spacer)

	# 4. Finalize Action
	mark_as_spent("MPop", "Panel4/MDonel") # Assuming Scene Unique Name for the label
	state = "standard"

# Helper function to keep row spacing consistent
func _realign_row(cell_index: int):
	var row = positiongrid[cell_index]
	for i in range(row.size()):
		var p_node = get_node(row[i])
		p_node.position.x = 400 + (i * spacer)

func _debugMove(plane_name: String, target: int):
	var plane_node = get_node(plane_name)
	var old_cell = plane_node.cell

	# 1. Remove from the old row and realign neighbors
	if old_cell != -1:
		positiongrid[old_cell].erase(plane_name)
		_realign_row(old_cell)

	# 2. Update plane state and add to the new row
	plane_node.cell = target
	positiongrid[target].append(plane_name)

	# 3. Update Y position using the array lookup
	if target >= 0 and target < ord_y_positions.size():
		plane_node.position.y = ord_y_positions[target]
	
	# 4. Update X position for the new slot
	var new_index = positiongrid[target].size() - 1
	plane_node.position.x = 400 + (new_index * spacer)

func _acquire(planeDoer, planeTarget):
	if (get_node(planeDoer).acqRange >= abs(get_node(planeDoer).cell - get_node(planeTarget).cell)) && (!APop) && (get_node(planeDoer).loyalty != get_node(planeTarget).loyalty ):
		if roll(get_node(planeTarget).acqStat,get_node(planeDoer).acqMod):
			get_node(planeTarget)._acquired()
		mark_as_spent("APop", "Panel5/ADone")
	state = "standard"
	selplane = planeDoer
	
func _shoot(planeGunner, planeTarget):
	if get_node("Squadron Panel").has_node(planeTarget):
		#Bombing Sequence
		pass
	if (get_node(planeGunner).shotRange >= abs(get_node(planeGunner).cell - get_node(planeTarget).cell)) && get_node(planeTarget).acquired && (!SPop) && (get_node(planeGunner).loyalty != get_node(planeTarget).loyalty) && get_node(planeGunner).shotammo:
		if roll(get_node(planeGunner).shotRoll,0):
			_die(get_node(planeTarget))
		mark_as_spent("SPop", "Panel6/SDone")
		get_node(planeGunner)._SSpend()
	state = "standard"
	selplane = planeGunner
	
func _debugshoot(planeTarget):
	_die(get_node(planeTarget))

func roll(Require, Modifier):
	die = RNG.randi_range(1,4)
	get_node("Panel9/Label").text = "Rolled a: " + str(die)
	get_node("Panel9/Label2").text = "Needed a: " + str(Require - Modifier)
	if  (die >= Require - Modifier):
		get_node("Panel9/Label3").text = "Success"
		get_node("Panel9/Label3").modulate = Color(0,1,0,1)
	else:
		get_node("Panel9/Label3").text = "Failure"
		get_node("Panel9/Label3").modulate = Color(1,0,0,1)
	return (die >= Require - Modifier)
	


func _on_cell_1_pressed() -> void:
	if (selplane != "none"):
		_move(selplane, 1)


func _on_cell_2_pressed() -> void:
	if (selplane != "none"):
		_move(selplane, 2)


func _on_cell_3_pressed() -> void:
	if (selplane != "none"):
		_move(selplane, 3)


func _on_cell_4_pressed() -> void:
	if (selplane != "none"):
		_move(selplane, 4)


func _on_cell_5_pressed() -> void:
	if (selplane != "none"):
		_move(selplane, 5)


func _on_move_button_pressed() -> void:
	if (selplane != "none") && (Commanding):
		state = "move"
	print(state)

func _on_acquire_button_pressed() -> void:
	if (selplane != "none") && (Commanding):
		state = "acquire"
	print(state)

func _on_shoot_button_pressed() -> void:
	if (selplane != "none") && (Commanding):
		state = "shoot"
	print(state)


func _on_end_turn_pressed() -> void:
	if phase == "RED":
		_teamSwap("BLU")
	elif phase == "BLU":
		_teamSwap("RED")

func _die(planey):
	
	positiongrid[planey.cell].erase(str(planey.name))
	
	planey.cell = 40
	if planey.loyalty == "RED":
		BLUBoneyard.append(planey)
		planey.position.y = 536
		planey.position.x = 50 + (BLUBoneyard.find(planey)) * spacer
	else:
		REDBoneyard.append(planey)
		planey.position.y = 36
		planey.position.x = 50 + (REDBoneyard.find(planey)) * spacer
	
func _bombsquadron(squadron, damage):
	squadron._hit(damage)
	if squadron.damage >= squadron.totalhealth:
		_die(squadron)
	

func _on_tutbutton_pressed() -> void:
	get_node("ForePanel").queue_free()
	pass # Replace with function body.
	
func _buildsquadron(inpName: String, inpLoyalty: String):
	var NuSquad = squadron.instantiate()
	NuSquad.press.connect(_on_press)
	NuSquad.name = (inpName)
	NuSquad.loyalty = (inpLoyalty)
	$"Squadron Panel".add_child(NuSquad, true)
	NuSquad.global_position.y = ord_y_positions[3]
	if inpLoyalty == "RED":
		NuSquad.modulate = Color(0.8,0.1,0.1,1)
		REDsquadrongrid.append(NuSquad)
		_fixOrder(REDsquadrongrid)
	elif inpLoyalty == "BLU":
		NuSquad.modulate = Color(0.1,0.1,0.8,1)
		BLUsquadrongrid.append(NuSquad)
		_fixOrder(BLUsquadrongrid)
func _SquadMenuOpen() -> void:
	get_node("Squadron Panel").visible = true
	state = "Deployment"
	for i in range(1,5):
		for Object in positiongrid[i]:
			get_node(Object).visible = false

func _fixOrder(inpArr: Array):
	for Object in inpArr:
		Object.global_position.x = 420 + (inpArr.find(Object)) * 65


func _on_cancel_squad_pressed() -> void:
	get_node("Squadron Panel/DeploySquad").visible = false
	get_node("Squadron Panel").visible = false
	state = "standard"
	selsquad = null
	for i in range(1,5):
		for Object in positiongrid[i]:
			get_node(Object).visible = true


func _on_deploy_squad_pressed() -> void:
	
	selsquad.deployed = true
	selsquad.reparent(self)
	if selsquad.loyalty == "RED":
		REDsquadrongrid.remove_at(REDsquadrongrid.find(selsquad))
		positiongrid[6].append(selsquad)
		selsquad.position.y = ord_y_positions[6]
		_fixOrder(positiongrid[6])
		_fixOrder(REDsquadrongrid)
		selsquad.cell = 6
		for Object in selsquad.planeslist:
			Object.cell = 6
	elif selsquad.loyalty == "BLU":
		BLUsquadrongrid.remove_at(BLUsquadrongrid.find(selsquad))
		positiongrid[0].append(selsquad)
		selsquad.position.y = ord_y_positions[0]
		_fixOrder(positiongrid[0])
		_fixOrder(BLUsquadrongrid)
		selsquad.cell = 0
		for Object in selsquad.planeslist:
			Object.cell = 0
	_on_cancel_squad_pressed()
	print(positiongrid[0])
	print(positiongrid[6])

func _bomb(planeTarget, planeGunner):
	if (get_node(planeGunner).shotRange >= abs(get_node(planeGunner).cell - planeTarget.cell)) && (!SPop) && (get_node(planeGunner).loyalty != planeTarget.loyalty) && get_node(planeGunner).bombammo:
			if roll(get_node(planeGunner).shotRoll,0):
				_bombsquadron(planeTarget, get_node(planeGunner).bombdamage)
			mark_as_spent("SPop", "Panel6/SDone")
			get_node(planeGunner)._BSpend()
