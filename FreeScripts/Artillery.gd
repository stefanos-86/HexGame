# Class to represent a gun in the off-map artillery.
# Assume all cannons are equal. Only deals with the logistic.
# The actual is similar to the attack/destruction logic and grouped with it.

const NOT_FIRING = -1
const FIRE_NOW = 0
const FIRE_DELAY = 2

var id = 0
var owner = null

var margin_of_error = 1 # In cells.

var rounds_left = 0
var target_coordinates = null
var turns_to_fire = NOT_FIRING

 
func plot_fire_mission(target_coord):
  target_coordinates = target_coord
  turns_to_fire = FIRE_DELAY

func cancel_fire_mission():
  target_coordinates = null
  turns_to_fire = NOT_FIRING

func progress_fire_mission():
  turns_to_fire -= 1
  
func ready_to_fire():
  return turns_to_fire == FIRE_NOW

func fired():
  rounds_left -= 1
