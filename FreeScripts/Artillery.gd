# Stuff to keep track of the off-map artillery.

const NOT_FIRING = -1

var margin_of_error = 1
var rounds_left = 0
var target_coordinates = null
var turns_to_fire = NOT_FIRING
var owner = null
var id = 0


 
func plot_fire_mission(target_coord):
  target_coordinates = target_coord
  turns_to_fire = 2

func cancel_fire_mission():
  target_coordinates = null
  turns_to_fire = NOT_FIRING

func progress_fire_mission():
  turns_to_fire -= 1
  
func ready_to_fire():
  return turns_to_fire == 0

