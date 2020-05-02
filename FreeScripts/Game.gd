enum factions {RED, BLUE}

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
  
