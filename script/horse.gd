class_name HorseClass
extends Node2D

# hien thi id ngua dua vao horse_id ben duoi
@export var label:Label
# team cua ngua
@export var horse_team:int = 0
# id cua ngua
@export var horse_id:int = 0
# ngua duoc trieu hoi hay ko
@export var horse_summon:bool = false
# ngua co di chuyen duoc ko
@export var horse_run:bool = true
# ngua co nhay qua cac diem duoc ko
@export var horse_jump:bool = true
# ngua co loai ngua doi phuong ko
@export var horse_kick:bool = false
# so buoc di de ngua loai doi phuong
@export var horse_kick_turn:int = 0
# id diem hien tai
@export var horse_pos_id:int = 0
# so di chuyen ngua cho den khi toi dich
@export var horse_all_move:int = 55
# level cua ngua
@export var horse_level:int = 0

func _ready() -> void:
	# hien thi id ngua
	label.text = str(horse_id)
