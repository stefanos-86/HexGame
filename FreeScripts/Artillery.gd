# Stuff to keep track of the off-map artillery.

var margin_of_error = 1
var rounds_left = 0
var target_coordinates = null
var turns_to_fire = 0
var owner = null
var id = 0
 
func plot_fire_mission(target_coord):
  target_coordinates = target_coord
  turns_to_fire = 2

func cancel_fire_mission():
  target_coordinates = null
