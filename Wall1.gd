extends Control

var mouseIn = false
var anchoredVertex = null

signal anchor_requested(from_wall)

func _ready():
	self.connect("mouse_entered", self, "_mouseEE", [true])
	self.connect("mouse_exited", self, "_mouseEE", [false])
	
func _mouseEE(inMouse):
	mouseIn = inMouse

func _input(event):
	if event.is_action_pressed("click") && mouseIn && anchoredVertex == null:
		emit_signal("anchor_requested", self)
		get_tree().set_input_as_handled()

func setAnchorVertex(v):
	anchoredVertex = v
	anchoredVertex.setAnchoredWall(self)
	get_node("StaticBody2D").input_pickable = false
