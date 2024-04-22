class_name BoardGame
extends Node2D

# scene chua quan ngua can goi len. xem them: horce.script
@export var horse_scene:PackedScene
# vi tri ngua luc xuat phat
@export var horse_pos: Node2D
# xuc xac. xem them: dice.script
@export var dice: Dice
# vi tri de sap xep cac ngua trong chuong luc dau
@export var items_pos:Marker2D
# am thanh
# horce
@export var horse_sfx: AudioStreamPlayer
# dice
@export var dice_sfx: AudioStreamPlayer
# menu
@onready var menu: Control = get_parent()
# ui dieu kien
@export var ui_options: Panel
# ben trong gom cac hanh dong de lua chon
@export var menu_option: VBoxContainer
@export var menu_select: VBoxContainer
# thong so cua cac doi: ten doi, diem len level cho ngua. Team co duoc 18 diem truoc se chien thang
@export var ui_score:VBoxContainer
# Disable cac phim hien thi khi den lua AI dieu khien
@export var ui_disable:Control

# du lieu tro choi: goi cac ham de save va load game. xem them: data.script
@export var game_data: Data

# Gom cac nuoc quan ngua co the di. xem them: move.script
@export var move_points:Node2D
# Cac diem ngua bat dau duoc trieu hoi xuat di. xem them: move.script
@export var start_points:Array[Marker2D]
# Cac diem ngua den cuoi diem chuan bi ve chuong. xem them: move.script
@export var end_points:Array[Marker2D]
# Gom cac diem ngua ve chuong (len level). xem them: move.script
@export var level_points: Node2D

# Nhom ngua da ve chuong (len level). xem them: horce.script
var horses_level:Array[HorseClass]
# Nhom ngua trieu tap ra san thi dau. xem them: horce.script
var horses_summon:Array[HorseClass]

# so luot quan ngua cua moi team
@export var horse_count:int = 4

# doi dang duoc dieu khien
var team_id:int = 0
# ten cac doi co the choi
@export var lable_team_info:Label
@export var teams:Array = ["Green", "Yellow", "Blue", "Red"]
# mau sac cac doi co the choi
@export var teams_color:Array[Color] = [Color.GREEN, Color.YELLOW, Color.BLUE, Color.RED]
# du lieu cac doi trong game dung de hien thi ui thu hang cac doi (lay tu team_data trong game_ui)
var team_data:Array

# so xuc xac thay ra duoc (tu 1-6)
@export var dice_number:int
# so nuoc di het cua quan ngua den khi ve dich
@export var all_turn:int = 56

# kick hoat che do AI
@export var AI_mode:bool = true
# tat ca doi do AI dieu khien
@export var AI_only:bool = true
# toc do AI khi dua ra hanh dong
@export var AI_speed:float = 1.0
# doi luot khi het lua chon
@export var change_turn:bool = true
# chon doi choi
@export var team_select:int = 0

# cac lua chon trong game
# xuc xac de bat dau choi
@export var roll:bool = true
# ket thuc luot di
@export var end:bool = true
# xuat, trieu hoi ngua ra thi dau  khi xuc xac ra 6
@export var summon:bool = false
# ngua di chuyen tung nuoc mot
@export var run:bool = false
# ngua di chuyen nhanh qua cac diem khi xuc xac ra 1
@export var jump:bool = false
# di them 1 nuoc (xuc xac them 1 lan) khi xuc xac ra 6
@export var double_run:bool = false
# loai bo ngua cua doi thu o phia truoc
@export var kick:bool = false
# len level co ngua khi ve dich
@export var level:bool = false

# Xu ly khi bat dau mo chuong trinh len
func create_game(load_game_session:bool = false):
	# danh dau id cho tung nuoc co the di de ghi nho, su dung sau nay: 0 - 55
	# gan cac move_points: 1 script co bien move_points_id
	var all_range:Array = [[0,13],[14,27],[28,41],[42,55]]
	for i in move_points.get_child_count():
		move_points.get_child(i).move_points_id = i
		for j in all_range.size():
			if i >= all_range[j][0] and i <= all_range[j][1]:
				move_points.get_child(i).modulate = teams_color[j]
				move_points.get_child(i).get_child(0).modulate = Color.WHITE
	
	for i in $Broad/UIHorsePosition.get_child_count():
		$Broad/UIHorsePosition.get_child(i).modulate = teams_color[i]
	for i in level_points.get_child_count():
		for j in level_points.get_child(i).get_child_count():
			level_points.get_child(i).get_child(j).get_child(0).modulate = teams_color[i]
			level_points.get_child(i).get_child(j).get_child(1).modulate = Color.BLACK
	
	# gan cac diem start_points, end_points bang code
	var points_array = [0,14,28,42]
	for i in points_array.size():
		start_points[i] = move_points.get_child(points_array[i]+1)
		end_points[i] = move_points.get_child(points_array[i])
		start_points[i].get_child(1).modulate = Color.WHITE
		end_points[i].get_child(1).modulate = Color.WHITE
	
	# ket noi phim chac nang den cac ham xu ly hanh dong trong game
	if !menu_option.get_node("Roll").is_connected("pressed",Callable(self,"options_roll_dice")):
		menu_option.get_node("Roll").connect("pressed",Callable(self,"options_roll_dice"))
		menu_option.get_node("End").connect("pressed",Callable(self,"options_end_turn"))
		menu_option.get_node("Summon").connect("pressed",Callable(self,"create_option_select").bind(0))
		menu_option.get_node("Level").connect("pressed",Callable(self,"create_option_select").bind(1))
		menu_option.get_node("Kick").connect("pressed",Callable(self,"create_option_select").bind(2))
		menu_option.get_node("Jump").connect("pressed",Callable(self,"create_option_select").bind(3))
		menu_option.get_node("Run").connect("pressed",Callable(self,"create_option_select").bind(4))
	
	# xep cac quan ngua ra san tu dong
	# truy vao horse_pos: node HorsePosition duoc Green, Yellow, Blue, Red tu do tao ra cac quan ngua
	# so luot quan ngua can tao ra dua vao horse_count
	# tao ra quan ngua, gan cac du lieu: horse_team, horse_id, color, label
	# xep moi quan ngua mot vi tri khac nhau dua vao items_pos: node ItemPosition gom co cac vi tri 0,1,2,3
	for i in horse_pos.get_child_count():
		if horse_pos.get_child(i).get_child_count() > 0:
			for child in horse_pos.get_child(i).get_children():
				child.queue_free()
	
	for i in horse_pos.get_child_count():
		for j in horse_count:
			var horse:HorseClass = horse_scene.instantiate()
			horse.horse_team = i
			horse.get_node("Sprite").modulate = teams_color[i]
			horse.horse_id = j
			horse.get_node("Label").text = str(j)
			var child = horse_pos.get_child(i)
			child.add_child(horse)
			horse.position += items_pos.get_child(j).position
	await get_tree().create_timer(0.1,false).timeout
	# Tao data team moi
	if load_game_session == false:
		team_data = menu.team_data.duplicate(true)
	# load man choi da choi
	else:
		game_data.load_game_data()
	# cap nhat thong tin cac doi
	update_team_info()
	# bat dau choi
	menu_option_item_active()
	options_setup()

# Cap nhat thong tin cac doi
func update_team_info():
	# Tinh diem cac doi tu so ngua da len level
	var teams_score = [0,0,0,0]
	for i in team_data.size():
		for j in horse_pos.get_child(i).get_child_count():
			var horse = horse_pos.get_child(i).get_child(j)
			teams_score[i] += horse.horse_level
	# Cap nhat diem cac doi
	for i in team_data.size():
		team_data[i].score = teams_score[team_data[i].id]
	# Sap xep thu tu cac doi theo diem
	team_data.sort_custom(sort_score)
	prints(team_data)
	# Cap nhat thong tin cac doi tren ui
	for i in team_data.size():
		ui_score.get_child(i).update_team_info(i+1, team_data[i].name + " Team", team_data[i].score, teams_color[team_data[i].id])

# Sap xep thu tu cac doi theo diem
func sort_score(a, b):
	if a.score > b.score:
		return true
	return false

# Mo hoac dong menu_select
func menu_select_active(active:bool = false):
	menu_select.visible = active

# Mo hoac dong menu_option
func menu_option_active(active:bool = false):
	menu_option.visible = active

# Mo hoac dong cac nut trong menu_option
func menu_option_item_active():
	lable_team_info.text = "Team select: " + teams[team_id]
	menu_option.get_node("Roll").visible = roll
	menu_option.get_node("Level").visible = level
	menu_option.get_node("Summon").visible = summon
	menu_option.get_node("Run").visible = run
	menu_option.get_node("Jump").visible = jump
	menu_option.get_node("Kick").visible = kick
	menu_option.get_node("End").visible = end
	for child in ui_options.get_children():
			if child.visible == true:
				ui_options.show()

# phan xu ly chinh nuoc di trong game.
# ban dau kiem tra: trong cac team co team nao da hoan thanh tro choi, thong bao team do thang cuoc.
# neu chua ben nao hoan thanh thi tien hanh thiet lap:
# cai dat, thiep lap du lieu can thiet truoc khi thuc hien hanh dong, nuoc di.
func options_setup():
	# kiem tra hoan thanh tro choi
	# de hoan thanh can len 4 ngua dung cac vi tri 3,4,5,6
	# check level cac quan ngua co trong game_level [3,4,5,6] hay khong
	# so ngua check duoc (check_horse_count) >= 4 (horse_count) la hoan thanh tro choi
	var game_level:Array
	for i in range(6-horse_count,6):
		game_level.append(i+1)
	var check_horse_count:int = 0
	for child in horse_pos.get_child(team_id).get_children():
		if child.horse_level in game_level:
			check_horse_count += 1
	if check_horse_count >= horse_count:
		lable_team_info.text = "Team win: " + teams[team_id]
		roll = true
		end = true
		summon = false
		run = false
		double_run = false
		jump = false
		kick = false
		level = false
	# tien hanh cai dat truoc
	else:
		# gan gia tri cac quan ngua da trieu hoi: var horses:Array = [], de tien xu ly cac phan tiep:
		# tu cac ngua duoc triep tap: horse_summon. Lay duoc:
		# gan gia tri cac quan ngua da trieu hoi: horses.append(child)
		var horses:Array = []
		for child in horse_pos.get_child(team_id).get_children():
			child.horse_kick = false
			if child.horse_summon == true:
				horses.append(child)
		
		# xu ly nuoc di cua quan ngua da duoc trieu tap
		# gom 2 phan xu ly nuoc di binh thuong(run) va nhay qua cac diem(jump)
		# muc dich kiem tra tat ca cac buoc di cua tung quan ngua de tim ra:
		# - quan ngua co bi chan duong khong di chuyen duoc
		# - quan ngua co the loai (kick) quan ngua doi phuong hay khong
		# neu quan ngua bi chan duong khong the nhay qua cac diem(jump), thi di binh thuong(run)
		
		# Xu ly nhay qua cac diem(jump)
		# tim ra vung qua ngua co the nhay qua diem: all_range = [[0,14],[14,28],[28,42],[42,56]], chinh la giua cac diem emd_points
		# vd quan ngua nam trong khoang (0,14) se nhay den vi tri 14, chinh la end_points[0]
		# neu trong khoang ngua nhay co ngua doi thu chan (enemy_count > 1) thi quan ngua se phai chuyen qua di binh thuong(run)
		# neu quan ngua va cham ngua doi thu (enemy_count < 2) o cac end_points thi loai(kick) ngua doi thu
		# ngua khong the di chuyen tiep khi den diem cuoi, diem len level: horse_all_move < count
		if jump == true:
			jump = false
			if horses.size() > 0:
				for horse in horses:
					horse.horse_jump = true
					var go_pos_id:int = horse.horse_pos_id
					var all_range:Array = [[0,14],[14,28],[28,42],[42,56]]
					var x:int
					for i in all_range:
						if go_pos_id >= i[0] and go_pos_id < i[1]:
							x = i[1]
					var count:int = 0
					var find_jump_count:int = x - go_pos_id
					var enemy_count:int = 0
					while count < find_jump_count:
						var check:Marker2D
						count += 1
						go_pos_id += 1
						if go_pos_id >= 56:
							go_pos_id = 0
						check = move_points.get_child(go_pos_id)
						if check.move_points_horse != null:
							enemy_count += 1
							if count == find_jump_count and enemy_count < 2 and check.move_points_horse.horse_team != team_id :
								prints("horse", horse.horse_id, "kick")
								horse.horse_kick = true
								horse.horse_kick_turn = find_jump_count
								kick = true
							horse.horse_jump = false
							prints("horse", horse.horse_id, "jump stop")
							break
						if count == find_jump_count and horse.horse_all_move > 0:
							prints("horse", horse.horse_id, "jump pass")
							#menu_option.get_node("Jump").text += " " + str(horse.horse_id)
							jump = true
		# Xu ly nuoc di binh thuong(run)
		# so buoc di quan ngua dua vao so xuc xac dice_number
		# neu trong so buoc di co ngua doi thu chan (enemy_count > 1) thi ngua khong the di chuyen
		# neu quan ngua va cham ngua doi thu (enemy_count < 2) o cac end_points thi loai(kick) ngua doi thu
		# ngua khong the di chuyen tiep khi den diem cuoi, diem len level: horse_all_move < count
		if run == true:
			run = false
			if horses.size() > 0:
				for horse in horses:
					horse.horse_run = true
					var go_pos_id:int = horse.horse_pos_id
					var count:int = 0
					count = 0
					var enemy_count:int = 0
					while count < dice_number:
						var check:Marker2D
						count += 1
						go_pos_id += 1
						if move_points.get_child(go_pos_id) in start_points:
							go_pos_id += 1
						if go_pos_id >= 56:
							go_pos_id = 0
						check = move_points.get_child(go_pos_id)
						if check.move_points_horse != null or horse.horse_all_move < count:
							if check.move_points_horse != null:
								enemy_count += 1
								if count == dice_number and enemy_count < 2 and check.move_points_horse.horse_team != team_id:
									prints("horse", horse.horse_id, "kick")
									horse.horse_kick = true
									horse.horse_kick_turn = dice_number
									kick = true
							horse.horse_run = false
							prints("horse", horse.horse_id, "stop", move_points.get_child(go_pos_id).move_points_horse)
							break
						if count == dice_number:
							run = true
		
		# Tuong ung voi cac bien action cho phep mo cac phim chuc nang can thiet
		menu_option_item_active()
		menu_option_active(true)
		menu_select_active()
		
		# xu ly cua ai may neu co
		await options_ai_active()

# xu ly ai
func options_ai_active():
	# xu ly ai neu khong phai team duoc chon dieu khien
	if menu.team_data_setting[team_id].mode == 1:
		AI_mode = true
	else:
		AI_mode = false
	
	ui_disable.visible = AI_mode
	
	# xu ly phan ai trieu hoi ngua:
	# horse_out: ngua da trieu tap, 
	# horse_in: ngua chua triep tap, hoac bi load(da) ve lai chuong
	var horse_out:int = 0
	var horse_in:int = 0
	var count_run:int = 0
	var check_summon:bool = true
	# dem so ngua da khai o tren, ngua da len level (horse_level > 0) thi se khong tinh vao
	for child in horse_pos.get_child(team_id).get_children():
		if child.horse_summon == true:
			if child.horse_level == 0:
				horse_out += 1
				if child.horse_run == true:
					count_run += 1
			if child.horse_pos_id == start_points[team_id].move_points_id:
				check_summon = false
		else:
			horse_in += 1
	# xu ly phan ai trieu hoi ngua:
	# ai se quyet dinh trieu hoi ngua dua vao so ngua dang thi dau, so ngua dang trong chuong
	# co the thay doi ra thong so tot hon
	if summon == true:
		if (horse_out >= 0 and horse_out < 1) and horse_in > 0:
			summon = true
		else:
			summon = false
		if count_run == 0 and check_summon == true and kick == false:
			summon = true
		if level == true and horse_out == 0:
			level = false
	# xu ly ai chon tat ca cac doi neu gan AI_only = true
	if AI_only == true:
		AI_mode = true
	# ai lua chon hanh dong co ban: theo su uu tien: summon-level-kick-jump-run-roll-end
	# co the thay doi, tinh chinh khien ai thong minh, tu nhien hon.
	# do su dung yiel func nen them await de thuc hien chuc nang lien mach khong bi de vao nhau
	if AI_mode == true:
		var horses:Array[HorseClass]
		var horse_select:HorseClass
		if level == true:
			horses = create_option_select(1)
			horse_select = horses.pick_random()
			await get_tree().create_timer(ai_delay(1),false).timeout
			menu_select_active(true)
			await options_horse_level(horse_select, horses)
		elif summon == true:
			horses = create_option_select(0)
			horse_select = horses.pick_random()
			await get_tree().create_timer(ai_delay(0.5),false).timeout
			menu_select_active(true)
			await options_hourse_summon(horse_select, horses)
		elif kick == true:
			horses = create_option_select(2)
			horse_select = horses.pick_random()
			await get_tree().create_timer(ai_delay(0.5),false).timeout
			menu_select_active(true)
			await options_horse_kick(horse_select, horses)
		elif jump == true:
			horses = create_option_select(3)
			horse_select = horses.pick_random()
			await get_tree().create_timer(ai_delay(0.5),false).timeout
			menu_select_active(true)
			await options_horse_jump(horse_select, horses)
		elif run == true:
			horses = create_option_select(4)
			horse_select = horses.pick_random()
			await get_tree().create_timer(ai_delay(0.5),false).timeout
			menu_select_active(true)
			await options_horse_run(horse_select, horses)
		elif roll == true:
			await get_tree().create_timer(ai_delay(0.5),false).timeout
			menu_select_active()
			await options_roll_dice()
		else:
			await get_tree().create_timer(ai_delay(0.2),false).timeout
			menu_select_active()
			await options_end_turn()
		await get_tree().create_timer(ai_delay(1),false).timeout
		menu_select_active()

# thoi gian ai thuc hien hanh dong
func ai_delay(time:float):
	return (time + randf_range(0, 0.5)) * AI_speed

# ket thuc luot
func options_end_turn():
	# doi luot giua cac team theo nguoc ben tay phai
	if change_turn == true:
		if team_id < 3:
			team_id += 1
		else:
			team_id = 0
	prints("Team select ", team_id)
	# cai dat lai 1 so thong so hanh dong
	roll = true
	end = true
	summon = false
	run = false
	double_run = false
	jump = false
	kick = false
	level = false
	options_setup()

# gieo xuc xac
# cai dat mot so hanh dong tu so xuc xac
func options_roll_dice():
	# xoa du lieu ngua vao cac diem ma ngua dang dung
	for i in move_points.get_child_count():
		move_points.get_child(i).move_points_horse = null
	# them du lieu ngua vao cac diem ma ngua dang dung
	for i in horse_pos.get_child_count():
		for j in horse_pos.get_child(i).get_child_count():
			var horse:HorseClass = horse_pos.get_child(i).get_child(j)
			if horse.horse_level == 0 and horse.horse_summon == true:
				move_points.get_child(horse.horse_pos_id).move_points_horse = horse
	
	# gieo xuc xac: duoc dice_number
	roll = false
	menu_option_active()
	dice_sfx.play()
	dice_number = await dice.dice_roll()
	menu_option_active(true)
	prints("Dice is ", dice_number)
	
	# lay cac bac, level ma ngua da dat duoc: level_unlock, tu thong so: horse_level cua ngua, de tien xu ly cac phan tiep:
	var level_unlock:Array = []
	horses_level = []
	for child in horse_pos.get_child(team_id).get_children():
		child.horse_kick = false
		if child.horse_level > 0:
			level_unlock.append(child.horse_level)
	
	# tu viec thay xuc xuc neu co, xu ly:
	# so ngua trong chuong, chua trieu tap: horse_in
	# hanh dong di chuyen run, jump neu so xuc xac = 1 (dice_number == 1)
	# neu ngua trieu tap nam o vi tri xuat phat thi khong the trieu hoi quan ngua khac: check_summon; child.horse_pos_id == start_points[team_id].move_points_id
	# len level neu co ngua da toi dich: child.horse_all_move == 0 and dice_number > child.horse_level and !dice_number in level_unlock
	# them cac ngua da len level vao nhom horses_level de su dung khi can thuc hien hanh dong len level tiep
	# phai dat du 3,4,5,6 moi hoan thanh
	# tu thong so horse_summon cua ngua lay duoc ngua chua triep tap
	var horse_in:int = 0
	var check_summon:bool = true
	for child in horse_pos.get_child(team_id).get_children():
		if child.horse_summon == true:
			run = true
			if dice_number == 1:
				jump = true
			if child.horse_pos_id == start_points[team_id].move_points_id:
				check_summon = false
			if child.horse_all_move == 0 and dice_number > child.horse_level and !dice_number in level_unlock:
				prints("Set Horse Level")
				horses_level.append(child)
				level = true
		if child.horse_summon == false:
			horse_in += 1
	
	# hanh dong trieu tap khi xuc xac == 6
	# neu xuc xac = 6 co them luot nua
	if dice_number == 6:
		if check_summon == true:
			if horse_in > 0:
				summon = true
			else:
				summon = false
		roll = true
	if change_turn == false:
		roll = true
	
	# tien hanh xu ly them
	options_setup()

# them luot neu xuc xac ra 6
func double_turn():
	if dice_number == 6:
		roll = true
	else:
		roll = false

# tao ra ui menu_select
func create_option_select(type:int = 0) -> Array[HorseClass]:
	# tao ra cac lua chon voi so ngua theo tung chuc nang co the su dung
	# lay ra cac ngua co the thuc hien hanh dong
	# neu la AI thi chon ngau nhieu ngua can di chuyen var horse_select = horses.pick_random()
	var horses:Array[HorseClass]
	match type:
		0:#Summon
			menu_select.get_node("Label").text = "Summon"
			for child in horse_pos.get_child(team_id).get_children():
				if child.horse_summon == false:
					horses.append(child)
		1:#Level
			menu_select.get_node("Label").text = "Level"
			horses = horses_level
		2:#Kick
			menu_select.get_node("Label").text = "Kick"
			for child in horse_pos.get_child(team_id).get_children():
				if child.horse_summon == true and child.horse_kick == true and child.horse_all_move > 0:
					horses.append(child)
		3:#Jump
			menu_select.get_node("Label").text = "Jump"
			for child in horse_pos.get_child(team_id).get_children():
				if child.horse_summon == true and child.horse_jump == true and child.horse_all_move > 0:
					horses.append(child)
		4:#Run
			menu_select.get_node("Label").text = "Run"
			for child in horse_pos.get_child(team_id).get_children():
				if child.horse_summon == true and child.horse_run == true and child.horse_all_move > 0:
					horses.append(child)
	# xoa lua chon cu trong menu_select
	if menu_select.get_child_count() > 1:
		for i in menu_select.get_child_count():
			if i > 0:
				menu_select.get_child(i).queue_free()
	# tao ra cac lua chon voi so ngua
	# ket noi chuc nang den tung nut de lua chon
	if horses.size() > 0:
		for i in horses.size():
			var options_select = preload("res://scene/option_select.tscn").instantiate()
			menu_select.add_child(options_select)
			options_select.text = "Horse 0" + str(horses[i].horse_id)
			match type:
				0:
					options_select.connect("pressed",Callable(self,"options_hourse_summon").bind(horses[i],horses))
				1:
					options_select.connect("pressed",Callable(self,"options_horse_level").bind(horses[i],horses))
				2:
					options_select.connect("pressed",Callable(self,"options_horse_kick").bind(horses[i],horses))
				3:
					options_select.connect("pressed",Callable(self,"options_horse_jump").bind(horses[i],horses))
				4:
					options_select.connect("pressed",Callable(self,"options_horse_run").bind(horses[i],horses))
			options_select.connect("pressed",Callable(self,"menu_select_active"))
			options_select.connect("pressed",Callable(self,"menu_option_active"))
	# Mo menu_select
	prints(horses)
	menu_select.show()
	return horses

# trieu tap ngua thi dau
func options_hourse_summon(horse_select:HorseClass = null, horses:Array[HorseClass] = []):
	# cai dat lai 1 so thong so hanh dong
	level = false
	summon = false
	run = false
	jump = false
	kick = false
	# them luot neu xuc xac ra 6
	double_turn()
	# gan du lieu thanh ngua ra san horse_summon = true
	# lay ra diem xuat phat: var horse_start_pos = start_points[team_id]
	# ngua luu thong tin cua diem xuat phat: horse_select.horse_pos_id = horse_start_pos.move_points_id
	# dua ngua ra diem xuat phat: horse_select.global_position = horse_start_pos.global_position
	if horses.size() > 0 and horse_select != null:
		horse_select.horse_summon = true
		var horse_go_pos:Node2D = start_points[team_id]
		prints(horse_go_pos.name)
		horse_select.z_index = 1
		tween_horse_position(horse_select, horse_go_pos, 0.4)
		horse_select.horse_pos_id = horse_go_pos.move_points_id
		prints("Horse summon: ", horse_go_pos.move_points_id)
		await get_tree().create_timer(0.5,false).timeout
		horse_select.z_index = 0
	
	# tien hanh xu ly them
	options_setup()

# len level cho ngua
func options_horse_level(horse_select:HorseClass = null, horses:Array[HorseClass] = []):
	# cai dat lai 1 so thong so hanh dong
	level = false
	summon = false
	run = false
	jump = false
	kick = false
	# them luot neu xuc xac ra 6
	double_turn()
	# xu ly len level:
	# dua vao xuc xac, tim diem len level cho ngua: horse_level_pos = level_points.get_child(team_id).get_child(i)
	# dua ngua ra diem level: horse_select.global_position = horse_level_pos.global_position
	# ngua luu thong tin level: horse_select.horse_level = dice_number
	if horses.size() > 0 and horse_select != null:
		var horse_old_pos:Marker2D = move_points.get_child(horse_select.horse_pos_id)
		var horse_go_pos:Marker2D
		for i in range(horse_select.horse_level, dice_number):
			prints("Horse Level: ", i)
			horse_go_pos = level_points.get_child(team_id).get_child(i)
			horse_select.z_index = 1
			tween_horse_position(horse_select, horse_go_pos, 0.25)
			await get_tree().create_timer(0.3,false).timeout
		horse_select.z_index = 0
		horse_select.horse_level = dice_number
		prints("Horse Level Done: ", horse_select.horse_level)
	# cap nhat thong tin cac doi khi ngua len level
	update_team_info()
	# tien hanh xu ly them
	options_setup()

# di chuyen ngua binh thuong
func options_horse_run(horse_select:HorseClass = null, horses:Array[HorseClass] = []):
	# cai dat lai 1 so thong so hanh dong
	level = false
	summon = false
	run = false
	jump = false
	kick = false
	# them luot neu xuc xac ra 6
	double_turn()
	
	# hang dong di chuyen
	# su dung: for i in dice_number. De xu ly cac buoc di (horse_go_pos) cua ngua cho den khi toi dich
	# dua ngua ra cac diem: horse_select.global_position = horse_go_pos.global_position
	# ngua luu thong tin dich cuoi: horse_go_pos.horse_level = dice_number
	if horses.size() > 0 and horse_select != null:
		var horse_old_pos:Marker2D = move_points.get_child(horse_select.horse_pos_id)
		var go_pos_id:int
		var horse_go_pos:Node2D
		horse_select.horse_all_move -= dice_number
		for i in dice_number:
			go_pos_id = horse_select.horse_pos_id + 1
			if move_points.get_child(go_pos_id) in start_points:
				go_pos_id += 1
				horse_select.horse_all_move -= 1
			prints("Horse Run: ", go_pos_id)
			if go_pos_id > 55:
				go_pos_id -= 56
			horse_go_pos = move_points.get_child(go_pos_id)
			horse_select.z_index = 1
			tween_horse_position(horse_select, horse_go_pos, 0.25)
			horse_select.horse_pos_id = horse_go_pos.move_points_id
			await get_tree().create_timer(0.3,false).timeout
		horse_select.z_index = 0
		horse_select.horse_pos_id = horse_go_pos.move_points_id
		prints("Horse Run Done: ", horse_go_pos.move_points_id)
	
	# tien hanh xu ly them
	options_setup()

# nhay qua cac diem
func options_horse_jump(horse_select:HorseClass = null, horses:Array[HorseClass] = []):
	# cai dat lai 1 so thong so hanh dong
	level = false
	summon = false
	run = false
	jump = false
	kick = false
	# them luot neu xuc xac ra 6
	double_turn()
	
	# hang dong di chuyen
	# tim cac khoang de nhay den cac diem
	# su dung ham lap: while count < find_jump_count. De xu ly cac buoc di (horse_go_pos) cua ngua cho den khi toi dich
	# dua ngua ra cac diem: horse_select.global_position = horse_go_pos.global_position
	# ngua luu thong tin dich cuoi: horse_go_pos.horse_level = dice_number
	if horses.size() > 0 and horse_select != null:
		var horse_old_pos:Marker2D = move_points.get_child(horse_select.horse_pos_id)
		var go_pos_id:int = horse_select.horse_pos_id
		var all_range:Array = [[0,14],[14,28],[28,42],[42,56]]
		var x:int
		for i in all_range:
			if go_pos_id >= i[0] and go_pos_id < i[1]:
				x = i[1]
		horse_select.horse_all_move -= (x - go_pos_id)
		go_pos_id = x
		if go_pos_id >= 56:
			go_pos_id -= 56
		var horse_go_pos:Marker2D = move_points.get_child(go_pos_id)
		tween_horse_position(horse_select, horse_go_pos, 0.4)
		await get_tree().create_timer(0.5,false).timeout
		prints("Horse jump: ", go_pos_id)
		horse_select.z_index = 0
		horse_select.horse_pos_id = horse_go_pos.move_points_id
	
	# tien hanh xu ly them
	options_setup()

# loai(kick) ngua doi phuong
func options_horse_kick(horse_select:HorseClass = null, horses:Array[HorseClass] = []):
	# cai dat lai 1 so thong so hanh dong
	level = false
	summon = false
	run = false
	jump = false
	kick = false
	# them luot neu xuc xac ra 6
	double_turn()
	
	# hang dong di chuyen
	# tu options_horse_run(), options_horse_jump() dua ngua den vi tri ngua doi phuong
	# su dung: for i in horse_select.horse_kick_turn
	# dua ngua doi phuong ve chuong vao reset cac thong so
	# horse_enemy.global_position = horse_pos.get_child(horse_enemy.horse_team).global_position
	if horses.size() > 0 and horse_select != null:
		var horse_old_pos:Marker2D = move_points.get_child(horse_select.horse_pos_id)
		var go_pos_id:int
		var horse_go_pos:Node2D
		horse_select.horse_all_move -= horse_select.horse_kick_turn
		for i in horse_select.horse_kick_turn:
			go_pos_id = horse_select.horse_pos_id + 1
			if move_points.get_child(go_pos_id) in start_points:
				go_pos_id += 1
				horse_select.horse_all_move -= 1
			prints("Horse Run: ", go_pos_id)
			if go_pos_id > 55:
				go_pos_id -= 56
			horse_go_pos = move_points.get_child(go_pos_id)
			horse_select.z_index = 1
			tween_horse_position(horse_select, horse_go_pos, 0.25)
			horse_select.horse_pos_id = horse_go_pos.move_points_id
			if horse_select.horse_kick_turn == dice_number:
				await get_tree().create_timer(0.3,false).timeout
			else:
				await get_tree().create_timer(0.05,false).timeout
		# Loai ngua doi phuong
		horse_select.z_index = 0
		var horse_enemy:HorseClass = horse_go_pos.move_points_horse
		horse_enemy.z_index = 1
		var enemy_back_pos:Vector2 = horse_pos.get_child(horse_enemy.horse_team).global_position + items_pos.get_child(horse_enemy.horse_id).position
		tween_horse_enemy_back_position(horse_enemy, enemy_back_pos, 0.4)
		horse_enemy.horse_summon = false
		horse_enemy.horse_pos_id = 0
		horse_enemy.horse_all_move = 55
		horse_enemy.z_index = 0
		await get_tree().create_timer(0.5,false).timeout
		
		horse_select.horse_pos_id = horse_go_pos.move_points_id
		prints("Horse Kick Done: ", horse_go_pos.move_points_id)
	
	# tien hanh xu ly them
	options_setup()

func tween_horse_position(obj, new_pos:Node2D, time:float = 0.5):
	var tween:Tween = get_tree().create_tween()
	tween.set_process_mode(1)
	tween.tween_property(obj, "global_position", new_pos.global_position, time).set_trans(Tween.TRANS_BOUNCE)
	horse_sfx.play()

func tween_horse_enemy_back_position(obj, new_pos:Vector2, time:float = 0.5):
	var tween:Tween = get_tree().create_tween()
	tween.set_process_mode(1)
	tween.tween_property(obj, "global_position", new_pos, time).set_trans(Tween.TRANS_BOUNCE)
	horse_sfx.play()
