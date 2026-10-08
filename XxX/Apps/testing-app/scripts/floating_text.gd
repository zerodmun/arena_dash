class_name FloatingText
extends Node2D
## Animated floating score popup (+10, +25, etc.)

var text := "+10"
var color := Color(1.0, 0.85, 0.2)
var duration := 0.7
var rise_speed := 45.0

var _t := 0.0
var _label: Label


func _ready() -> void:
	z_index = 50
	_label = Label.new()
	_label.text = text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_label.add_theme_constant_override("outline_size", 6)
	_label.position = Vector2(-90, -20)
	_label.size = Vector2(180, 40)
	add_child(_label)


func _process(delta: float) -> void:
	_t += delta
	position.y -= rise_speed * delta
	var progress := _t / duration
	scale = Vector2.ONE * (1.2 - progress * 0.2)
	modulate.a = clampf(1.0 - pow(progress, 2.0), 0.0, 1.0)
	if progress >= 1.0:
		queue_free()


static func spawn(parent: Node, pos: Vector2, txt: String, col: Color = Color(1.0, 0.9, 0.2)) -> void:
	var ft := FloatingText.new()
	ft.global_position = pos
	ft.text = txt
	ft.color = col
	parent.add_child(ft)
