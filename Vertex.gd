extends Node2D

var rb = null
var notify = null
var seNotify = null
var mouseWithin = null
var selected = false
var highlite = true
var anchoredTo = null

func _ready():
	rb = get_node("RigidBody2D")
	rb.connect("mouse_entered", self, "_onMouseEntryExit", [true])
	rb.connect("mouse_exited", self, "_onMouseEntryExit", [false])
	
	var vn = rb.get_node("VisibilityNotifier2D")
	vn.connect("screen_entered", self, "_onScreenEntryExit", [true])
	vn.connect("screen_exited", self, "_onScreenEntryExit", [false])

func _onScreenEntryExit(isEntry):
	if !isEntry && seNotify != null:
		seNotify["target"].call(seNotify["method"], self)
	
func _onMouseEntryExit(isEntry):
	mouseWithin = isEntry
	rb.get_node("HighliteSprite").visible = !selected && mouseWithin && highlite
	
	if notify != null:
		notify["target"].call(notify["method"], self)

func _anyVertexSelected(_v):
	highlite = false

func _anyVertexDeselected(_v):
	highlite = true
	
func setAnchoredWall(wall):
	anchoredTo = wall
	
func anchoredWall():
	return anchoredTo

func notifyOnMouseEntryExit(target, methodName):
	notify = { "target": target, "method": methodName }
	
func notifyOnScreenExit(target, methodName):
	seNotify = { "target": target, "method": methodName }
	
func removeAllObservers():
	notify = null
	seNotify = null
		
func allowHighlite(allow):
	highlite = allow
	
func select():
	if !selected:
		rb.get_node("SelectSprite").visible = true
		rb.get_node("HighliteSprite").visible = false
		selected = true
		
func unselect():
	if selected:
		rb.get_node("SelectSprite").visible = false
		rb.get_node("HighliteSprite").visible = false
		selected = false
		
func isSelected():
	return selected
	
func isMouseWithin():
	return mouseWithin

func parentScene(parent):
	parent.connect("vertex_selected", self, "_anyVertexSelected")
	parent.connect("vertex_deselected", self, "_anyVertexDeselected")
