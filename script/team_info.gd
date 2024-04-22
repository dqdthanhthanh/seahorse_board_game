extends HBoxContainer


func update_team_info(_rank,_name,_score,_color):
	$Rank.text = str(_rank)
	$Name.text = str(_name)
	$Score.text = str(_score)
	self.modulate = _color
