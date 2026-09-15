@tool
class_name Gutter
extends PanelContainer

@warning_ignore("unused_private_class_variable")
@export_tool_button("Sync Gutter Sizes") var __sync_gutter_sizes = func():
	_on_code_node_set(code_node)
@export var code_node: Node:
	set(new):
		code_node = new
@export var fold_list: PackedInt32Array

@onready var numbers_label = %Numbers
@onready var fold_button_list = %FoldButtonList

static var MIN_WIDTH: int = 0
static var _instance_list: Array[Gutter]

var fold_button = preload("res://CodeEditor/fold_button.tscn")


func _ready() -> void:
	_on_code_node_set(code_node)
	Gutter._instance_list.append(self)


func _on_code_node_set(new: Node):
	numbers_label.text = ""
	
	if not fold_list.is_empty():
		_show_folds()
	else:
		_hide_folds()
	
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

func _show_folds():
	fold_button_list.visible = true
	for i in range(0, fold_list.size() - 1, 2):
		var fold_start: int = fold_list[i]
		#var fold_end: int = fold_list[i + 1]
		
		if fold_start > 1:
			var space = Control.new()
			# After last fold_end
			if i > 1:
				var last_fold_start: int = fold_list[i - 2]
				space.custom_minimum_size.y = 17 * (fold_start - last_fold_start - 1)
			else:
				space.custom_minimum_size.y = 17 * (fold_start - 1)
			fold_button_list.add_child(space)
		
		var fold_button_inst = fold_button.instantiate()
		fold_button_list.add_child(fold_button_inst)

func _hide_folds():
	fold_button_list.visible = false

func _find_nth_occurrence(text: String, target: String, n: int) -> int:
	var pos = -1
	for i in range(n):
		pos = text.find(target, pos + 1)
		if pos == -1:
			break
	return pos
																											   
