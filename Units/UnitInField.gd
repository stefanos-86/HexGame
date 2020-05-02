extends Node2D

# Data that "instantiates" a unit on the field.
var faction
var type

var move_points
var shot_points

var speed

var gun_max_range

func belongs_to(player):
  return faction == player
