extends Node2D

const MOUSE_COLLIDER_SIZE = 4.0

var _vertexScene = null
var _mouseInVertex = null
var _selectedVertex = null
var _verticies = []
var _activeLine = null
var _hoverLine = null
var _lines = []
var _lineRays = []
var _mouseBody = null
var _mouseColl = null

signal vertex_selected(vertex)
signal vertex_deselected(vertex)

func _ready():
	_vertexScene = preload("res://Vertex.tscn")
	
	# Wall stuff, TODO: make this dynamic!
	get_node("Wall1").connect("anchor_requested", self, "_anchorRequested")
	get_node("Wall2").connect("anchor_requested", self, "_anchorRequested")
	get_node("Wall3").connect("anchor_requested", self, "_anchorRequested")
	
	get_node("Panel/ClearButton").connect("pressed", self, "_clearButtonPressed")

func _newVertex(starting_pos):
	var newVertex = _vertexScene.instance()
	newVertex.notifyOnMouseEntryExit(self, "_vertexEntryExit")
	newVertex.parentScene(self)
	newVertex.allowHighlite(_selectedVertex == null)
	newVertex.position = starting_pos

	if _mouseBody != null:
		newVertex.get_node("RigidBody2D").add_collision_exception_with(_mouseBody)

	add_child(newVertex)
	_verticies.append(newVertex)
	return newVertex
	
func _input(event):
	if event.is_action_pressed("click"):
		if _selectedVertex == null && _mouseInVertex != null:
			if !_mouseInVertex.isSelected():
				_selectedVertex = _mouseInVertex
				_mouseInVertex.select()
				emit_signal("vertex_selected", _mouseInVertex)
		elif _selectedVertex != null && _mouseInVertex == _selectedVertex:
			emit_signal("vertex_deselected", _selectedVertex)
			_selectedVertex.unselect()
			_selectedVertex = null
		elif _hoverLine != null:
			print("LINE CLICK")

func _addVertexAnchorToWall(from_wall):
	var mousePos = get_viewport().get_mouse_position()
	var joint = PinJoint2D.new()
	var nVtx = _newVertex(mousePos)
	
	joint.node_a = from_wall.get_node("StaticBody2D").get_path()
	joint.node_b = nVtx.get_node("RigidBody2D").get_path()
	
	joint.softness = 0
	joint.bias = 0
	joint.position = mousePos
	joint.disable_collision = true
	
	_selectedVertex = nVtx
	nVtx.select()
	add_child(joint)
	from_wall.setAnchorVertex(nVtx)
	return nVtx
	
func _anchorRequested(from_wall):
	if _verticies.size() < 2:
		var isFirst = _verticies.size() == 0
		
		if !isFirst:
			_unselectCurrent()
			
		var nVtx = _addVertexAnchorToWall(from_wall)
		
		if isFirst:
			_activeLine = Line2D.new()
			_activeLine.width = 0.5
			_activeLine.default_color = Color(0, 255, 0)
			_activeLine.antialiased = true
			_activeLine.add_point(nVtx.position)
			_activeLine.add_point(get_viewport().get_mouse_position(), 1)
			add_child(_activeLine)
		else:
			_activeLine.points[1] = nVtx.position
			_activeLine.default_color = Color(255, 255, 255)
			_lines.append(_activeLine)
			
			var lineBody = StaticBody2D.new()
			var lineRay = RayCast2D.new()
			var lp0 = _activeLine.points[0]
			var lp1 = _activeLine.points[1]
			lineRay.position = lp0
			lineRay.cast_to = Vector2(lp1.x - lp0.x, lp1.y - lp0.y)
			lineRay.enabled = true
			
			lineBody.add_child(lineRay)
			lineBody.input_pickable = true
			lineBody.connect("mouse_entered", self, "_lineEntryExit", [_activeLine, true])
			lineBody.connect("mouse_exited", self, "_lineEntryExit", [_activeLine, false])
			add_child(lineBody)
			
			lineRay.exclude_parent = true
			lineRay.add_exception(_verticies[0].get_node("RigidBody2D"))
			lineRay.add_exception(nVtx.get_node("RigidBody2D"))
			lineRay.add_exception(_verticies[0].anchoredWall().get_node("StaticBody2D"))
			lineRay.add_exception(from_wall.get_node("StaticBody2D"))
			
			_lineRays.append([lineRay, _activeLine, false])
			
			_activeLine = null
			_unselectCurrent()
			
			# adds an invisible "mouse collider" that will allow lineRays to detect "mouse-over" collisions
			_mouseBody = StaticBody2D.new()
			_mouseBody.visible = true
			
			#WhyTF doesn't this work!?
			var mSelSprite = Sprite.new()
			var mSelImg = Image.new()
			mSelImg.load("res://platformPack_tile036.png")
			mSelSprite.texture = ImageTexture.new().create_from_image(mSelImg)
			print(mSelImg.get_class())
			print(mSelSprite)
			mSelSprite.z_index = 100
			mSelSprite.visible = true
			_mouseBody.add_child(mSelSprite)
			
			# prevents the mouse collider from moving the verticies around slightly
			_verticies[0].get_node("RigidBody2D").add_collision_exception_with(_mouseBody)
			nVtx.get_node("RigidBody2D").add_collision_exception_with(_mouseBody)
			
			_mouseColl = CollisionPolygon2D.new()
			_mouseBody.add_child(_mouseColl)
			add_child(_mouseBody)
			_positionMouseColl()
			

func _positionMouseColl():
	if _mouseColl != null:
		var mp = get_viewport().get_mouse_position()
		var poly = []
		var s = MOUSE_COLLIDER_SIZE / 2.0
		poly.append(Vector2(mp.x - s, mp.y - s))
		poly.append(Vector2(mp.x + s, mp.y - s))
		poly.append(Vector2(mp.x + s, mp.y + s))
		poly.append(Vector2(mp.x - s, mp.y + s))
		_mouseColl.polygon = poly
		## the sprite, again, WhyTF?!
		_mouseBody.get_children()[0].position = mp
		
func _lineEntryExit(line, isEntry):
	if isEntry:
		line.default_color = Color(0, 255, 255)
		_hoverLine = line
	else:
		line.default_color = Color(255, 255, 255)
		_hoverLine = null
	
func _unselectCurrent():
	_selectedVertex.unselect()
	_selectedVertex = null
	
func _vertexEntryExit(vertex):
	_mouseInVertex = null
	if vertex.isMouseWithin():
		_mouseInVertex = vertex
		
func _clearButtonPressed():
	pass
	
func _physics_process(_delta):
	if _activeLine != null:
		_activeLine.points[1] = get_viewport().get_mouse_position()
			
	if _mouseColl != null:
		_positionMouseColl()
		
	# iterate all lineRays checking for a change in collision state, to simulate entry/exit events
	if _lineRays.size() > 0:
		for ray in _lineRays:
			var isColl = ray[0].is_colliding()
			
			if isColl && !ray[2]:
				_lineEntryExit(ray[1], true)
			elif !isColl && ray[2]:
				_lineEntryExit(ray[1], false)
				
			ray[2] = ray[0].is_colliding()
