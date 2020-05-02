const TWO_PI = 2 * PI

enum factions {RED, BLUE}

enum speed_levels {
  STATIONARY, # Not moving.
  POP_OUT, # 1 hex movement (e. g to get out of cover)
  SLOW,
  FAST}
  
enum fire_outcome {
  MISS,
  INEFFECTIVE,
  DESTROYED
 }

enum armor_part {
  FRONT,
  SIDE,
  REAR
 }
  
var first_player_in_turn
var current_player
var turn_count

var rng = RandomNumberGenerator.new()

func current_player_name():
  return factions.keys()[current_player]
 
func begin_game():
  rng.randomize()
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
  p = distance_penalty(p, distance, attacker.gun_max_range)
    
  # Account for size? For heading?
  
  return int(p)

func movement_accuracy_penalty(base_hit_probability, speed):
  if speed == speed_levels.SLOW:
    base_hit_probability /= 2
  elif speed == speed_levels.FAST:
    base_hit_probability /= 4
  return base_hit_probability
    
func fire(shooter, target, terrain):
  var distance = terrain.distance_between(shooter, target)
  var hit_p = hit_probability(shooter, target, distance)

  if rng.randf() * 100 > hit_p:
    return fire_outcome.MISS
    
  var shot_strength = distance_penalty(shooter.gun_penetration_power, distance, shooter.gun_max_range) 
  
  var attack_direction = target.position - shooter.position
  var attack_angle = attack_direction.angle()
  if attack_angle < 0:
    attack_angle += TWO_PI
    
  var bearing = (attack_angle - target.global_rotation) / TWO_PI

  print (attack_direction, " ", attack_angle, " ", target.global_rotation)
  print ("bearing ", bearing)
  
  var p_hit_side = 0
  if (bearing < 0.25):
    p_hit_side = lerp(0, 1, bearing * 4)
  elif(bearing < 0.5):
    p_hit_side = lerp(1, 0, (bearing - 0.25) * 4)
  elif(bearing < 0.75):
    p_hit_side = lerp(0, 1, (bearing - 0.5) * 4)
  else:
    p_hit_side = lerp(1, 0, (bearing - 0.75) * 4)
    
  print ("Side hit " , p_hit_side)
    
  var armor_part_hit = armor_part.REAR
  if rng.randf() <= p_hit_side:
    armor_part_hit = armor_part.SIDE
  elif bearing > 0.25 and bearing < 0.75:
    armor_part_hit = armor_part.FRONT
  
  print (armor_part.keys()[armor_part_hit])
  print (shot_strength, " vs ", target.armour_thickness[armor_part_hit])
  
  if shot_strength > target.armour_thickness[armor_part_hit]:
    return fire_outcome.DESTROYED
    
  return fire_outcome.INEFFECTIVE
  

# max_distance = range where the values goes to 0.
func distance_penalty(value_at_no_distance, distance, max_distance):
  var distance_factor = clamp(float(distance) / max_distance, 0, 1)
  return lerp(value_at_no_distance, 0, distance_factor)
