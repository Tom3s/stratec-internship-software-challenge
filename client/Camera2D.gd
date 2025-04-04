extends Camera2D

var _targetZoom: float = 1.0

# @export_range(0.00005, 0.5, 0.00005)
var MIN_ZOOM: float = 0.0001
# @export_range(1.0, 50.0, 0.1)
var MAX_ZOOM: float = 40.0
const ZOOM_INCREMENT: float = 0.1
const ZOOM_RATE: float = 8.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	zoom = lerp(zoom, _targetZoom * Vector2.ONE, ZOOM_RATE * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			position -= event.relative * (Vector2.ONE / zoom)
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoomIn()
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoomOut()

func _zoomIn() -> void:
	_targetZoom = max(_targetZoom - ZOOM_INCREMENT * zoom.x, MIN_ZOOM)

func _zoomOut() -> void:
	_targetZoom = min(_targetZoom + ZOOM_INCREMENT * zoom.x, MAX_ZOOM)