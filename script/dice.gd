class_name Dice
extends Node2D

@export var icon:Sprite2D

# thiet lap ngau nhien hinh anh ban dau xuc xac
func _ready() -> void:
	self.icon.frame = randi_range(6,29)

# thuc hien viec xuc xac
func dice_roll() -> int:
	# hien ui gieo xuc xac
	get_parent().show()
	# thay doi sprite xuc xac 1 vai lan(3-5) ngau nhien
	var number:int
	for i in randi_range(3,5):
		self.icon.frame = randi_range(6,29)
		number = (self.icon.frame + 1)
		await get_tree().create_timer(0.15,false).timeout
	# tim ra so xuc xac
	while number > 6:
		number -= 6
	#number = 6
	# thay doi sprite xuc xac
	self.icon.frame = number - 1
	await get_tree().create_timer(1,false).timeout
	return self.icon.frame + 1
