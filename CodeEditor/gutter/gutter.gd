@tool
class_name Gutter
extends PanelContainer

signal fold_opened(foldline_start: int, foldline_end: int)
signal fold_closed(foldline_start: int, foldline_end: int)

@warning_ignore("unused_private_class_variable")
@export_tool_button("Sync Gutter Sizes") var __sync_gutter_sizes = func():
	_on_code_node_set(code_node)
@export var code_node: Node:
	set(new):
		code_node = new
@export var fold_list: PackedInt32Array

@onready var numbers_label = %Numbers
@onready var fold_button_list: VBoxContainer = %FoldButtonList

static var MIN_WIDTH: int = 0
static var _instance_list: Array[Gutter]

const FONT_HEIGHT: int = 17
const foldline_button := preload("res://CodeEditor/gutter/fold_button.tscn")

var line_count: int = 0


func _ready() -> void:
	_on_code_node_set(code_node)
	Gutter._instance_list.append(self)


func _on_code_node_set(new: Node):
	numbers_label.text = ""
	fold_list.clear()
	
	if not new:
		new = get_node_or_null("../Code")
		if not new:
			Gutter._update_gutters_width()
			return
		code_node = new
		print("(%s) Gutter: code_node reference is null. Found neighboring" % get_parent().name)
	
	var code_text: String = new.text
	line_count = code_text.count("\n")+1
	for line in range(line_count):
		numbers_label.text += str(line+1) + "\n"
	
	new.gutter = self
	_detect_fold_regions(code_text)
	
	if not fold_list.is_empty():
		_show_folds()
	else:
		_hide_folds()
	
	await get_tree().process_frame
	
	Gutter.MIN_WIDTH = max(Gutter.MIN_WIDTH, size.x)
	print("(%s) GUTTER_WIDTH: %s" % [$"..".name, Gutter.MIN_WIDTH])
	Gutter._update_gutters_width()

static func _update_gutters_width():
	for gutter in Gutter._instance_list:
		gutter.custom_minimum_size.x = Gutter.MIN_WIDTH

func _detect_fold_regions(source: String):
	var splitted_source = source.split('\n')
	for i in range(splitted_source.size()):
		var opening_line = splitted_source[i]
		if not opening_line.contains("{"):
			print("didnt find a open bracket")
			continue
		
		var skip_closing_counter = 0
		for j in range(i, splitted_source.size()):
			var closing_line = splitted_source[j]
			if closing_line.contains("{"):
				skip_closing_counter += 1
			if not closing_line.contains("}"):
				print("didnt find a closing bracket for this opening one")
				continue
			
			if skip_closing_counter > 1:
				skip_closing_counter -= 1
				continue
			var openbracket_line = i
			var closebracket_line = j
			
			fold_list.append(openbracket_line + 1)
			fold_list.append(closebracket_line + 1)
			i += j
			break
	print(fold_list)
	#print("didnt find any complete brackets")

func _show_folds():
	fold_button_list.visible = true
	for child in fold_button_list.get_children():
		queue_free()
	
	for fold in range(0, fold_list.size() - 1, 2):
		var foldline_start: int = fold_list[fold]
		#var foldline_end: int = fold_list[fold + 1]
		
		if foldline_start > 1:
			var space = Control.new()
			# After last foldline_end
			if fold > 1:
				var last_foldline_start: int = fold_list[fold - 2]
				space.custom_minimum_size.y = FONT_HEIGHT * (foldline_start - last_foldline_start - 1) - 1
			else:
				space.custom_minimum_size.y = FONT_HEIGHT * (foldline_start - 1) - 1
			fold_button_list.add_child(space)
		
		var fold_button_inst: Button = foldline_button.instantiate()
		fold_button_inst.name = "Fold%d" % [fold]
		fold_button_inst.toggled.connect(_on_some_fold_button_toggled.bind(fold))
		fold_button_list.add_child(fold_button_inst)

func _hide_folds():
	fold_button_list.visible = false

func offset_fold(fold: int, offset: int):
	if offset == 0 or fold == 0 or fold > line_count:
		return
	var foldline = fold_list[fold]
	var fold_button: Button = fold_button_list.get_node_or_null("Fold%d" % fold)
	if not fold_button:
		printerr("cant offset Fold%d (l %d), button not found" % [fold, foldline])
		return
	var spacer_before: Control = fold_button_list.get_child(fold_button.get_index() - 1)
	if not spacer_before:
		printerr("cant offset Fold%d (l %d), because there's no spacer before it" % [fold, foldline])
		return
	spacer_before.custom_minimum_size.y += offset * FONT_HEIGHT
	fold_list[fold] += offset
	fold_list[fold + 1] += offset


func _on_some_fold_button_toggled(closed: bool, fold: int):
	var foldline_start = fold_list[fold]
	var foldline_end = fold_list[fold + 1]
	var fold_length = foldline_end - foldline_start
	if closed:
		fold_closed.emit(foldline_start, foldline_end)
		print("fold %d closed" % foldline_start)
	else:
		fold_opened.emit(foldline_start, foldline_end)
		print("fold %d opened" % foldline_start)
	
	var next_fold = fold + 2
	if next_fold < fold_list.size():
		offset_fold(next_fold, fold_length * (-1 if closed else 1))
																											   
