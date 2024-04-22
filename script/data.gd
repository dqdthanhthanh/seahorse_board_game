class_name Data
extends Node

const game_session_path:String = "user://game_session/"
const dot_type:String = ".json"

# thong tin can luu cua 1 game:
# team: thong tin cua tat ca ngua trong team
# game_data: du lieu cai dat trong game
var data:Dictionary = {
	"team": [],
	"game_data": [],
	"team_data": [],
	"team_data_setting": [],
}

# game_data: du lieu cai dat trong game
var game_data:Dictionary = {
	"team_select": 0,
	"horse_count": 4,
	"team_id": 0,
	"teams": ["Green", "Yellow", "Blue", "Red"],
	"dice_number": 0,
	"all_turn": 56,
	"AI_mode": false,
	"AI_only": false,
	"change_turn": true,
}

# thong tin can luu cua ngua
var horse_data:Dictionary = {
	"horse_position": Vector2(0,0),
	"horse_team": 0,
	"horse_id": 0,
	"horse_summon": false,
	"horse_run": true,
	"horse_jump": true,
	"horse_kick": false,
	"horse_pos_id": 0,
	"horse_all_move": 55,
	"horse_level": 0,
}


func _ready() -> void:
	close_data()

# test nhanh luu, tai du lieu
func _input(event: InputEvent) -> void:
	if Input.is_key_label_pressed(KEY_S):
		save_game_data()
	elif Input.is_key_label_pressed(KEY_L):
		load_game_data()

func load_game_data():
	prints("Loading")
	# Lay data tu bo nho qua: get_data()
	# Lay danh sach cac file tu bo nho: get_files_name_path()
	data = get_data(get_files_name_path(game_session_path)[0])
	# Load team data setting: gan cac du lieu menu voi game_data
	var menu = get_parent()
	menu.team_data_setting = data.team_data_setting
	var broad_game:BoardGame = get_parent().get_node("BoardGame")
	# Load game data: gan du lieu tu broad_game voi data da lay duoc
	broad_game.team_data = data.team_data
	broad_game.team_select = data.game_data.team_select
	broad_game.horse_count = data.game_data.horse_count
	broad_game.team_id = data.game_data.team_id
	broad_game.teams = data.game_data.teams
	broad_game.dice_number = data.game_data.dice_number
	broad_game.all_turn = game_data.all_turn
	broad_game.AI_mode = data.game_data.AI_mode
	broad_game.AI_only = data.game_data.AI_only
	broad_game.change_turn = data.game_data.change_turn
	# Load team data: gan du lieu tu cac team, ngua voi data da lay duoc
	for i in broad_game.horse_pos.get_child_count():
		for j in broad_game.horse_pos.get_child(i).get_child_count():
			var horse:HorseClass = broad_game.horse_pos.get_child(i).get_child(j)
			var horse_data:Dictionary = data.team[i][j]
			horse.global_position = str_to_vec2(horse_data.horse_position)
			horse.horse_all_move = horse_data.horse_all_move
			horse.horse_jump = horse_data.horse_jump
			horse.horse_level = horse_data.horse_level
			horse.horse_pos_id = horse_data.horse_pos_id
			horse.horse_run = horse_data.horse_run
			horse.horse_kick = horse_data.horse_kick
			horse.horse_summon = horse_data.horse_summon
			horse.horse_team = horse_data.horse_team
			if horse.horse_level == 0 and horse.horse_summon == true:
				broad_game.move_points.get_child(horse.horse_pos_id).move_points_horse = horse
	# End load data
	close_data()

func save_game_data():
	prints("Saving")
	# Tao thu muc tuy chinh de luu du lieu
	folder_create(game_session_path)
	var broad_game:BoardGame = get_parent().get_node("BoardGame")
	close_data()
	# Save team data setting: gan cac du lieu game_data voi menu
	var menu = get_parent()
	data.team_data_setting = menu.team_data_setting
	# Save game data: gan cac du lieu game_data voi broad_game
	data.team_data = broad_game.team_data
	var new_game_data:Dictionary = game_data.duplicate(true)
	game_data.team_select = broad_game.team_select
	game_data.horse_count = broad_game.horse_count
	game_data.team_id = broad_game.team_id
	game_data.teams = broad_game.teams
	game_data.dice_number = broad_game.dice_number
	game_data.all_turn = broad_game.all_turn
	game_data.AI_mode = broad_game.AI_mode
	game_data.AI_only = broad_game.AI_only
	game_data.change_turn = broad_game.change_turn
	data.game_data = new_game_data
	# Save team data: gan cac du lieu game_data voi team, ngua
	for i in broad_game.horse_pos.get_child_count():
		data.team.append([])
		for j in broad_game.horse_pos.get_child(i).get_child_count():
			var horse:HorseClass = broad_game.horse_pos.get_child(i).get_child(j)
			var new_horse_data:Dictionary = horse_data.duplicate(true)
			new_horse_data.horse_position = horse.global_position
			new_horse_data.horse_all_move = horse.horse_all_move
			new_horse_data.horse_jump = horse.horse_jump
			new_horse_data.horse_level = horse.horse_level
			new_horse_data.horse_pos_id = horse.horse_pos_id
			new_horse_data.horse_run = horse.horse_run
			new_horse_data.horse_kick = horse.horse_kick
			new_horse_data.horse_summon = horse.horse_summon
			new_horse_data.horse_team = horse.horse_team
			data.team[i].append(new_horse_data)
	# End save data: luu lai data save_data() gom duong dan file tuy chon voi data can luu thanh file
	prints(data)
	save_data(game_session_path + "data" + ".json",data)
	close_data()

# dong du lieu
func close_data():
	data.team = []
	data.game_data = []
	data.team_data = []
	data.team_data_setting = []

static func get_data(data_path):
	var file = FileAccess.open(data_path, FileAccess.READ)
	var json_data = JSON.new()
	json_data.parse(file.get_as_text())
	var parse_result = json_data.get_data()
	return parse_result

static func save_data(data_path,value) -> void:
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))

static func get_files_name_path(path : String) -> Array:
	var files:Array = []
	var filesPath = DirAccess.get_files_at(path)
	if filesPath.size() > 0:
		for i in filesPath:
			files.append(path + i)
	return files

static func folder_create(path) -> void:
	DirAccess.make_dir_absolute(path)

static func folder_remove(path) -> void:
	DirAccess.remove_absolute(path)

static func str_to_vec2(string := "") -> Vector2:
	if string:
		var new_string: String = string
		new_string = new_string.erase(0, 1)
		new_string = new_string.erase(new_string.length() - 1, 1)
		var array: Array = new_string.split(", ")
		return Vector2(int(array[0]), int(array[1]))
	return Vector2.ZERO
