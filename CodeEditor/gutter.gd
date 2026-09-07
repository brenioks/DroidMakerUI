@tool
class_name Gutter
extends PanelContainer

@export var code_node: Node:
	set(new):
		if Engine.is_editor_hint():
			_on_code_node_set(new)
		code_node = new

@onready var numbers_label = $Label

static var MIN_WIDTH: int = 0
static var _instance_list: Array[Gutter]


func _ready() -> void:
	_on_code_node_set(code_node)
		

func _on_code_node_set(new: Node):
	numbers_label.text = ""
	Gutter._instance_list.append(self)
	if not new:
		new = get_node_or_null("../Code")
		if not new:
			Gutter._update_gutters_width()
			return
		print("(%s) Gutter: code_node reference is null. Found neighboring" % get_parent().name)
	
	var code_text: String = new.text
	var line_count = code_text.count("\n")+1
	for line in range(line_count):
		numbers_label.text += str(line+1) + "\n"
	
	await get_tree().process_frame
	
	Gutter.MIN_WIDTH = max(Gutter.MIN_WIDTH, size.x)
	print("(%s) GUTTER_WIDTH: %s" % [$"..".name, Gutter.MIN_WIDTH])
	Gutter._update_gutters_width()

static func _update_gutters_width():
	for gutter in Gutter._instance_list:
		gutter.custom_minimum_size.x = Gutter.MIN_WIDTH
																											   
