extends MultiMeshInstance3D
	

@export var count : int = 500000
	
@export var margin : float = 0.4
@export var travelSpeed : float = 1.0
	
var sqrthree : float = sqrt(3.0)
var one_scale : float = 1.0 / pow(3.0,1.0/4.0)

var color : float = 2.0
@export var obW : float = 1.0
	

var shaderJOT : Shader
var materialJOT : ShaderMaterial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prepareShader()
	generateJOTIn3D()
	showJOT()


func prepareShader() -> void:
	shaderJOT = Shader.new()
	
	#NIE MAM POJĘCIA JESZCZE NA CZYM POLEGAJĄ SHADERY, JAK ZWYKLE NAPISAŁEM ORGINALNY KOD I PORPOSIŁEM CHATA ABY MI ZOPTYMALIZOWAŁ
	shaderJOT.code = """
shader_type spatial;

uniform float obW = 1.0;
uniform float margin = 0.4;

varying vec3 jotColor;


void vertex()
{
	float w = INSTANCE_CUSTOM.x;
	
	jotColor = INSTANCE_CUSTOM.yzw;
	
	
	// Punkt znajduje się poza aktualnym przekrojem 4D
	if (abs(w - obW) > margin)
	{
		// Wyrzucamy go poza przestrzeń clip-space.
		// GPU nie rasteryzauje takiej instancji.
		POSITION = vec4(2.0,2.0,2.0,1.0);
	}
	else
	{
		// Ponieważ używamy POSITION,
		// sami wykonujemy standardową projekcję.
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX,1.0);
	}
}


void fragment()
{
	ALBEDO = jotColor;
}
"""
	
	
	materialJOT = ShaderMaterial.new()
	materialJOT.shader = shaderJOT
	
	material_override = materialJOT


func generateJOTIn3D() -> void:
	
	# WAŻNE:
	# custom_data trzeba włączyć zanim ustawimy instance_count.
	multimesh.instance_count = 0
	
	multimesh.use_custom_data = true
	multimesh.use_colors = false
	
	multimesh.instance_count = count
	
	
	var pos : Vector4 = Vector4(0,0,0,0)
	var tra : Transform3D = Transform3D()
	
	
	for i in range(count):
		var rand = randi_range(0,2)
		var newPos : Vector4 = Vector4(0,0,0,0)
		
		
		match rand:
			0:
				# odbicie x <-> y
				newPos.x = one_scale * pos.y + 2.0
				newPos.y = one_scale * pos.x
				newPos.z = one_scale * pos.z
				newPos.w = one_scale * pos.w
			
			
			1:
				# odbicie y <-> z
				newPos.x = one_scale * pos.x - 1.0
				newPos.y = one_scale * pos.z + sqrthree
				newPos.z = one_scale * pos.y
				newPos.w = one_scale * pos.w
			
			
			2:
				# odbicie z <-> w
				newPos.x = one_scale * pos.x - 1.0
				newPos.y = one_scale * pos.y - sqrthree
				newPos.z = one_scale * pos.w
				newPos.w = one_scale * pos.z
		
		
		pos = newPos
		
		
		# ===============================
		# POZYCJA XYZ
		# ===============================
		
		tra.origin = Vector3(
			pos.x,
			pos.y,
			pos.z
		)
		
		multimesh.set_instance_transform(i,tra)
		
		multimesh.set_instance_custom_data(i,Color(pos.w,pos.x / color,pos.y / color,pos.z / color))


func showJOT() -> void:
	
	materialJOT.set_shader_parameter("obW",obW)
	materialJOT.set_shader_parameter("margin",margin)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	var changed : bool = false
	
	
	if Input.is_action_pressed("travelA"):
		obW -= travelSpeed * delta
		changed = true
	
	
	elif Input.is_action_pressed("travelD"):
		obW += travelSpeed * delta
		changed = true
	
	
	if changed:
		showJOT()
