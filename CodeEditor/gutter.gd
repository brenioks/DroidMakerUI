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
@onready var folds_label = %Folds

static var MIN_WIDTH: int = 0
static var _instance_list: Array[Gutter]


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
	folds_label.visible = true
	for i in range(0, fold_list.size() - 1, 2):
		var fold_start: int = fold_list[i]
		var fold_end: int = fold_list[i + 1]
		folds_label.text += "\n".repeat(fold_start - 1) + "⌄"
		if fold_end > fold_start:
			folds_label.text += "\n".repeat(fold_end - fold_start) + "."

func _hide_folds():
	folds_label.visible = false

func _find_nth_occurrence(text: String, target: String, n: int) -> int:
	var pos = -1
	for i in range(n):
		pos = text.find(target, pos + 1)
		if pos == -1:
			break
	return pos
																											   
