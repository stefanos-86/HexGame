extends Node2D

# Data that "instantiates" a unit on the field.
var faction
var type

var move_points
var shot_points

func belongs_to(player):
  return faction == player
