extends Node2D

# Data that "instantiates" a unit on the field.
var faction
var type

var move_points
var fire_points

var speed

var movement_stance
var fire_stance

var alive = true

# TODO: this values belong to the type of the unit.
# They do not change when fielding it. The gun has been installed
# in the tank factory; deploying the vehicle has no effect.
# Same for the armor.
var gun_max_range = 12
var gun_penetration_power = 450 # mm of steel at 90 degrees, point blank.
var armour_thickness = {}
var max_fire_points = 2
var max_move_points = 8

func belongs_to(player):
  return faction == player
  
func rotate_turret_towards(point):
  $Tank_turret.look_at(point)

func mark_destruction():
  alive = false
  $Destroyed.visible = true
  
func reset_points():
  move_points = max_move_points
  fire_points = max_fire_points
