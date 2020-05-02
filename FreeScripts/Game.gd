enum factions {RED, BLUE}

enum speed_levels {
  STATIONARY, # Not moving.
  POP_OUT, # 1 hex movement (e. g to get out of cover)
  SLOW,
  FAST}
  
var first_player_in_turn
var current_player
var turn_count

func current_player_name():
  return factions.keys()[current_player]
 
func begin_game():
  first_player_in_turn = factions.RED
  current_player = first_player_in_turn
  turn_count = 1
  
func swap_player():
  if (current_player == factions.RED):
    current_player = factions.BLUE
  else:
    current_player = factions.RED

func next_turn():
  swap_player()
  if (current_player == first_player_in_turn):
    turn_count += 1
  
func hit_probability(attacker, target, distance):
  var p = 100
  p = movement_accuracy_penalty(p, attacker.speed)
  p = movement_accuracy_penalty(p, target.speed)
  
  var distance_factor = clamp(float(distance) / attacker.gun_max_range, 0, 1)
  p = lerp(p, 0, distance_factor)
  return int(p)

func movement_accuracy_penalty(base_hit_probability, speed):
  if speed == speed_levels.SLOW:
    base_hit_probability /= 2
  elif speed == speed_levels.FAST:
    base_hit_probability /= 4
  return base_hit_probability
    
