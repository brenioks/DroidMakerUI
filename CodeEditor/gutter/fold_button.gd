extends Button

const DROPDOWN_CLOSED_ICON = preload("res://icons/dropdown_closed_icon.png")
const DROPDOWN_ICON = preload("res://icons/dropdown_icon.png")

func _on_toggled(toggled_on: bool) -> void:
	icon = DROPDOWN_CLOSED_ICON if toggled_on else DROPDOWN_ICON
