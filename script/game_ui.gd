extends Control


@export var board_game:Node2D
@export var data:Node
@export var ui_option:Panel

# du lieu thiet lap cac doi co do AI dieu khien hay khong
var team_data_setting:Array = [
	{"name": "Green", "mode":0},
	{"name": "Yellow", "mode":1},
	{"name": "Blue", "mode":1},
	{"name": "Red", "mode":1}
]
# du lieu co dinh cac doi, board_game se su dung
const team_data:Array = [
	{"name": "Green", "id":0, "score":0},
	{"name": "Yellow", "id":1, "score":0},
	{"name": "Blue", "id":2, "score":0},
	{"name": "Red", "id":3, "score":0}
]

# thiet lap ban dau
func _ready():
	# thiet lap tinh nang: tao game moi, luu game dang choi, dong va mo menu
	$Menu.show()
	ui_option.hide()
	$ButtonOpen.connect("pressed", meu_game_active.bind(true))
	$Menu/ButtonClose.connect("pressed", meu_game_active)
	$Menu/List/New.connect("pressed", new_game)
	$Menu/List/Save.connect("pressed", save_game_session)
	# tai game
	load_data_setup()

# tai game
func load_data_setup():
	# thiet lap file tai game da luu
	# xoa data load cu neu co
	if $Menu/List/Data.get_child_count() > 0:
		for child in $Menu/List/Data.get_children():
			child.queue_free()
	# tao data load moi
	var file_scene = preload("res://scene/file_data.tscn").instantiate()
	$Menu/List/Data.add_child(file_scene)
	var file_data = data.get_files_name_path(data.game_session_path)
	# ket noi den ham load_game_session() de load game khi nhan vao
	# neu khong co file save thi dat ten file la "Empty Game Session"
	if file_data.size() > 0:
		for i in file_data.size():
			file_scene.text = file_data[i]
			file_scene.connect("pressed", load_game_session)
	else:
		file_scene.text = "Empty Game Session"
	
	# thiet lap hien thi che do dieu khien cua cac tem
	for i in $Menu/List.get_child_count():
		if i < 4:
			var item:OptionButton = $Menu/List.get_child(i).get_node("OptionButton")
			$Menu/List.get_child(i).get_node("Label").text = team_data_setting[i].name + " Team"
			if !item.is_connected("item_selected", team_item.bind(item,i)):
				item.connect("item_selected", team_item.bind(item,i))
			item.selected = team_data_setting[i].mode

# doi che do choi: PLayer, AI cua tung team
func team_item(id:int = 0, item:OptionButton = null, item_id:int = 0):
	team_data_setting[item_id].mode = id
	prints(team_data_setting)

# dong mo menu
func meu_game_active(active:bool = false):
	load_data_setup()
	get_tree().paused = active
	$Menu.visible = active

# tao game moi
func new_game():
	get_tree().paused = false
	await board_game.create_game()
	meu_game_active()
	ui_option.show()

# luu game dang choi
func save_game_session():
	get_tree().paused = false
	await data.save_game_data()
	meu_game_active()
	ui_option.show()

# tai game da luu
func load_game_session():
	get_tree().paused = false
	await board_game.create_game(true)
	meu_game_active()
	ui_option.show()
