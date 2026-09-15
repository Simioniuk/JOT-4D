extends MultiMeshInstance3D 
	 
 #JEŚLI CHODZI O VOXEL TO JEST TO WYGENEROWANE PRZEZ AI, NAPRAWDĘ NIE MAM POJĘCIA JAK ROBIĆ VOXELE
#PISAŁEM NA POCZĄTKU ZWYKŁY MULTIMESH, ALE WIADOMO OPTYMALIZACJA
# Z RESZTĄ NIE UWAŻAM ŻE JAK DAJE MÓJ KOD DO CHATU I MÓWIE MU ŻEBY ZOPTYMLIZOWAŁ TO BYLO TO COŚ ZŁEGO
@export var count : int = 1000000 
	 
@export var margin : float = 0.4 
@export var travelSpeed : float = 1.0 
@export var voxelSize : float = 0.08
@export var voxelBuildDelay : float = 0.15
@export var voxelSampleStep : int = 2
	 
var sqrthree : float = sqrt(3.0) 
var oneST : float = 1.0 / sqrthree 

var sqrtwo : float = sqrt(2.0)
var oneSqrtwo : float = 1.0 / sqrtwo
	 
var color : float = 2.0 
var oneColor : float = 1.0 / color

@export var obW : float = 1.0 
	 
 
var shaderJOT : Shader 
var materialJOT : ShaderMaterial 

var posit : PackedVector4Array = []


# VOXELE
var voxelJOT : MultiMeshInstance3D
var voxelMultiMesh : MultiMesh
var voxelMesh : BoxMesh
var voxelMaterial : StandardMaterial3D


# WĄTEK DO LICZENIA VOXELI
var voxelThread : Thread = Thread.new()

var voxelTimer : float = 0.0
var voxelNeedUpdate : bool = false

# W dla którego aktualnie liczymy voxele
var voxelBuildObW : float = 0.0

 
# Called when the node enters the scene tree for the first time. 
func _ready() -> void: 
	prepareShader()
	prepareVoxels()
	
	generateJOTIn3D() 
	showJOT()
	
	# po starcie od razu przygotujemy pierwszy przekrój voxelowy
	voxelNeedUpdate = true
	voxelTimer = 0.0


func prepareShader() -> void: 
	shaderJOT = Shader.new() 
	 
	#margin = 0.4 
	#NIE MAM POJĘCIA JESZCZE NA CZYM POLEGAJĄ SHADERY, JAK ZWYKLE NAPISAŁEM ORGINALNY KOD I PORPOSIŁEM CHATA ABY MI ZOPTYMALIZOWAŁ 
	shaderJOT.code = """ 
shader_type spatial; 
render_mode unshaded;
 
uniform float obW = 1.0; 
uniform float margin = 0.4; 

uniform bool showPoints = true;
 
varying vec3 jotColor; 
 
 
void vertex() 
{ 
	float w = INSTANCE_CUSTOM.x; 
	 
	jotColor = INSTANCE_CUSTOM.yzw; 
	 
	 
	// Punkt znajduje się poza aktualnym przekrojem 4D 
	if (!showPoints || abs(w - obW) > margin) 
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


func prepareVoxels() -> void:
	
	voxelJOT = MultiMeshInstance3D.new()
	voxelJOT.name = "VoxelJOT"
	
	add_child(voxelJOT)
	
	
	voxelMesh = BoxMesh.new()
	voxelMesh.size = Vector3(
		voxelSize,
		voxelSize,
		voxelSize
	)
	
	
	voxelMaterial = StandardMaterial3D.new()
	
	# dzięki temu kolor instancji MultiMesh
	# będzie kolorem voxela
	voxelMaterial.vertex_color_use_as_albedo = true
	
	# Nie liczymy światła dla miliona kosteczek :)
	voxelMaterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	
	voxelMesh.material = voxelMaterial
	
	
	voxelMultiMesh = MultiMesh.new()
	voxelMultiMesh.transform_format = MultiMesh.TRANSFORM_3D
	
	voxelMultiMesh.use_colors = true
	
	voxelMultiMesh.mesh = voxelMesh
	
	
	voxelJOT.multimesh = voxelMultiMesh
	
	voxelJOT.visible = false

 
func generateJOTIn3D() -> void: 
	 
	# WAŻNE: 
	# custom_data trzeba włączyć zanim ustawimy instance_count. 
	multimesh.instance_count = 0 
	 
	multimesh.use_custom_data = true 
	multimesh.use_colors = false 
	 
	multimesh.instance_count = count 
	
	
	# Rezerwujemy pamięć od razu
	# zamiast robić append milion razy
	posit.resize(count)
	 
	 
	var pos : Vector4 = Vector4(0,0,0,0) 
	var tra : Transform3D = Transform3D.IDENTITY 
	 
	 
	for i in range(count): 
		
		var rand = randi_range(0,2) 
		
		var newPos : Vector4 = Vector4(0,0,0,0) 
		 
		
		pos = obrot(pos) 
		 
		
		match rand: 
			0: 
				newPos.x = oneST * pos.y + 2.0 
				newPos.y = oneST * pos.x 
 
			1: 
				newPos.x = oneST * pos.y - 1.0 
				newPos.y = oneST * pos.x + sqrthree 
 
			2: 
				newPos.x = oneST * pos.y - 1.0 
				newPos.y = oneST * pos.x - sqrthree 
				 
		
		rand = randi_range(0,2) 
		
		
		match rand: 
			0: 
				newPos.z = oneST * pos.w + 2.0 
				newPos.w = oneST * pos.z 
 
			1: 
				newPos.z = oneST * pos.w - 1.0 
				newPos.w = oneST * pos.z + sqrthree 
 
			2: 
				newPos.z = oneST * pos.w - 1.0 
				newPos.w = oneST * pos.z - sqrthree 
		 
		 
		pos = newPos
		
		posit[i] = pos
		
		
		tra.origin = Vector3( 
			pos.x, 
			pos.y, 
			pos.z 
		) 
		 
		multimesh.set_instance_transform(i,tra) 
		 
		multimesh.set_instance_custom_data(
			i,
			Color(
				pos.w,
				pos.x * oneColor,
				pos.y * oneColor,
				pos.z * oneColor
			)
		) 


func obrot(pos : Vector4) -> Vector4: 
	
	var newPos : Vector4 = Vector4(0,0,0,0) 
	
	#newPos.x = pos.z 
	#newPos.y = pos.w 
	#newPos.z = pos.x 
	#newPos.w = pos.y 
	
	
	newPos.x = (pos.z + pos.x) * oneSqrtwo
	newPos.y = (pos.w + pos.y) * oneSqrtwo
	
	newPos.z = (pos.z - pos.x) * oneSqrtwo
	newPos.w = (pos.w - pos.y) * oneSqrtwo
	
	
	return newPos	 
	 
 
func showJOT() -> void: 
	 
	materialJOT.set_shader_parameter("obW",obW) 
	materialJOT.set_shader_parameter("margin",margin) 


func startVoxelBuild() -> void:
	
	# Jeżeli poprzedni wątek jeszcze pracuje,
	# nie uruchamiamy następnego
	if voxelThread.is_started():
		return
	
	
	voxelBuildObW = obW
	
	voxelNeedUpdate = false
	
	
	# Zapamiętujemy W dla którego budujemy przekrój
	var currentW : float = voxelBuildObW
	
	
	voxelThread.start(
		Callable(self,"generateVoxelData").bind(currentW)
	)


func generateVoxelData(currentW : float) -> PackedVector3Array:
	
	var voxels : Dictionary = {}
	
	var oneVoxelSize : float = 1.0 / voxelSize
	
	
	var step : int = maxi(voxelSampleStep,1)
	
	
	for i in range(0,posit.size(),step):
		
		var pos : Vector4 = posit[i]
		
		
		# tylko aktualny przekrój czwartego wymiaru
		if abs(pos.w - currentW) > margin:
			continue
		
		var voxelPos : Vector3i = Vector3i(
			int(floor(pos.x * oneVoxelSize)),
			int(floor(pos.y * oneVoxelSize)),
			int(floor(pos.z * oneVoxelSize))
		)
		
		voxels[voxelPos] = true
	
	
	var voxelData : PackedVector3Array = PackedVector3Array()
	
	voxelData.resize(voxels.size())
	
	
	var index : int = 0
	
	
	for voxelPos in voxels:
		
		# środek kostki
		
		voxelData[index] = Vector3(
			(float(voxelPos.x) + 0.5) * voxelSize,
			(float(voxelPos.y) + 0.5) * voxelSize,
			(float(voxelPos.z) + 0.5) * voxelSize
		)
		
		index += 1
	
	
	return voxelData


func showVoxels(voxelData : PackedVector3Array) -> void:
	
	voxelMultiMesh.instance_count = 0
	
	voxelMultiMesh.use_colors = true
	
	voxelMultiMesh.instance_count = voxelData.size()
	
	
	var tra : Transform3D = Transform3D.IDENTITY
	
	
	for i in range(voxelData.size()):
		
		var pos : Vector3 = voxelData[i]
		
		
		tra.origin = pos
		
		
		voxelMultiMesh.set_instance_transform(
			i,
			tra
		)
		
		
		voxelMultiMesh.set_instance_color(
			i,
			Color(
				pos.x * oneColor,
				pos.y * oneColor,
				pos.z * oneColor,
				1.0
			)
		)
	
	
	voxelJOT.visible = true
	
	materialJOT.set_shader_parameter(
		"showPoints",
		false
	)


func hideVoxels() -> void:
	
	voxelJOT.visible = false
	
	
	# Podczas podróżowania po W
	# pokazujemy ponownie szybką chmurę
	
	materialJOT.set_shader_parameter(
		"showPoints",
		true
	)


# Called every frame. 'delta' is the elapsed time since the previous frame. 
func _process(delta: float) -> void: 
	 
	var changed : bool = false 
	var ruch : float = 0.0
	 
	 
	if Input.is_action_pressed("travelA"): 
		
		ruch = -travelSpeed * delta
		
		changed = true
	 
	 
	elif Input.is_action_pressed("travelD"): 
		
		ruch = travelSpeed * delta
		
		changed = true
	 
	 
	if changed: 
		
		obW += ruch
		
		showJOT()
		hideVoxels()

		voxelTimer = voxelBuildDelay
		
		voxelNeedUpdate = true
	
	
	else:
		if voxelNeedUpdate:
			
			voxelTimer -= delta
			
			
			if voxelTimer <= 0.0:
				
				if !voxelThread.is_started():
					
					startVoxelBuild()
	
	if voxelThread.is_started():
		
		if !voxelThread.is_alive():
			
			var voxelData = voxelThread.wait_to_finish()

			voxelThread = Thread.new()

			if !voxelNeedUpdate:
				
				showVoxels(voxelData)

func _exit_tree() -> void:
	if voxelThread.is_started():
		voxelThread.wait_to_finish()
