extends Node2D

# Data that "instantiates" a unit on the field, plus some little logic
# to manouver the elements of the units scene (the rest of the code
# need not to know its particular nodes).
var faction
var type

var move_points
var fire_points

var speed

var movement_stance
var fire_stance

var alive = true

func belongs_to(player):
  return faction == player
  
func rotate_turret_towards(point):
  $Tank_turret.look_at(point)

func mark_destruction():
  alive = false
  $Destroyed.visible = true
  
func reset_points():
  move_points = type.max_move_points
  fire_points = type.max_fire_points
  

