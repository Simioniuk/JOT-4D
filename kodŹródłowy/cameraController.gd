extends Camera3D

@export_category("Ustawienia Ruchu WASD i Strzałek")
@export var movement_speed: float = 10.0
@export var movement_smooth: float = 12.0
@export var vertical_speed: float = 8.0

@export_category("Ustawienia Myszy")
@export var mouse_sensitivity: float = 0.003
@export var rotation_smooth: float = 15.0

@export_category("Ograniczenia Pionowe")
@export var min_pitch: float = -85.0
@export var max_pitch: float = 85.0

@export_category("Ustawienia Scrolla (Zoom)")
@export var zoom_speed: float = 2.0
@export var min_fov: float = 30.0
@export var max_fov: float = 90.0
@export var fov_smooth: float = 10.0

# Zmienne docelowe (Target) do płynnej interpolacji
var target_yaw: float = 0.0
var target_pitch: float = 0.0
var target_pos: Vector3 = Vector3.ZERO
var target_fov: float = 75.0

# Aktualne wartości
var current_yaw: float = 0.0
var current_pitch: float = 0.0

func _ready() -> void:
	# Startowe przechwycenie myszy
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	target_pos = global_position
	var euler = quaternion.get_euler()
	target_yaw = euler.y
	target_pitch = euler.x
	current_yaw = target_yaw
	current_pitch = target_pitch
	target_fov = fov

func _unhandled_input(event: InputEvent) -> void:
	# 1. Obrót myszą (Działa TYLKO gdy mysz jest przechwycona)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		target_yaw -= event.relative.x * mouse_sensitivity
		target_pitch -= event.relative.y * mouse_sensitivity
		target_pitch = clamp(target_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		
	# 2. Zoom (Scroll)
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_fov = clamp(target_fov - zoom_speed, min_fov, max_fov)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_fov = clamp(target_fov + zoom_speed, min_fov, max_fov)
			
	# 3. Zwalnianie i przywracanie kontroli myszy (ESC / G)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event.is_action_pressed("capture_camera"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	# --- Sekcja 1: Wyliczanie Obrotu ---
	current_yaw = lerp_angle(current_yaw, target_yaw, rotation_smooth * delta)
	current_pitch = lerp(current_pitch, target_pitch, rotation_smooth * delta)
	
	var q_yaw = Quaternion(Vector3.UP, current_yaw)
	var q_pitch = Quaternion(Vector3.RIGHT, current_pitch)
	quaternion = q_yaw * q_pitch
	
	# --- Sekcja 2: Wyliczanie Ruchu Poziomego (WASD) ---
	# Poruszanie się działa tylko, gdy gracz kontroluje kamerę
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		var forward = -global_transform.basis.z
		var right = global_transform.basis.x
		
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		var move_direction = (forward * input_dir.y + right * input_dir.x)
		target_pos += move_direction * movement_speed * delta
		
		# --- Sekcja 3: Wyliczanie Ruchu Pionowego (Strzałki) ---
		var vertical_input : float = 0.0
		if Input.is_action_pressed("move_up"):
			vertical_input += 1.0
		if Input.is_action_pressed("move_down"):
			vertical_input -= 1.0
			
		target_pos.y += vertical_input * vertical_speed * delta
	
	# --- Sekcja 4: Aplikowanie Płynnego Ruchu i Zoomu ---
	global_position = global_position.lerp(target_pos, movement_smooth * delta)
	fov = lerp(fov, target_fov, fov_smooth * delta)
