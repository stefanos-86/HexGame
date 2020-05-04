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
  OUT_OF_RANGE,
  DESTROYED
 }

enum armor_part {
  FRONT,
  SIDE,
  REAR
 }
  
enum movement_outcome {
  ARRIVED_AT_DESTINATION,
  NO_MOVE_POINTS,
  ENGAGED_MID_WAY
 }


class FireEffect:
  var armor_part_hit = null
  var final_result = null
 
class MoveEffect:
  var actual_path = null
  var final_result = null

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
  var effect = FireEffect.new()
  
  var distance = terrain.distance_between(shooter, target)
  
  if distance > shooter.gun_max_range:
    effect.final_result = fire_outcome.OUT_OF_RANGE
    return effect
  
  shooter.fire_points -= 1
  
  var hit_p = hit_probability(shooter, target, distance)
  if rng.randf() * 100 > hit_p:
    effect.final_result = fire_outcome.MISS
    return effect
    
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
  
  effect.armor_part_hit = armor_part_hit
  
  print (armor_part.keys()[armor_part_hit])
  print (shot_strength, " vs ", target.armour_thickness[armor_part_hit])
  
  if shot_strength > target.armour_thickness[armor_part_hit]:
    effect.final_result = fire_outcome.DESTROYED
  else:
    effect.final_result = fire_outcome.INEFFECTIVE
  
  return effect

# max_distance = range where the values goes to 0.
func distance_penalty(value_at_no_distance, distance, max_distance):
  var distance_factor = clamp(float(distance) / max_distance, 0, 1)
  return lerp(value_at_no_distance, 0, distance_factor)


# Walk the path one bit at a time and simulate things that can
# happen when moving. Return a data structure that tells the results
# of the movement, with the path actually travelled up to the available
# move points and any engagement that may result along the way.
func movement(unit, planned_path, terrain):
  if planned_path.size() < 1:
    var outcome = MoveEffect.new()
    outcome.actual_path = planned_path
    outcome.final_result = movement_outcome.ARRIVED_AT_DESTINATION
    return outcome
  
  # First step: you are already there, so nothing to simulate or pay for.
  # But the step is still part of the movement.
  var step_counter = 0
  var next_step = planned_path[step_counter]
  var actual_path = [next_step]
  
  step_counter += 1
  var next_step_cost = terrain.movement_cost_for_position(next_step)
  
  while next_step_cost <= unit.move_points and step_counter < planned_path.size():
    next_step = planned_path[step_counter]
    next_step_cost = terrain.movement_cost_for_position(next_step)
    actual_path.append(next_step)
    unit.move_points -= next_step_cost
    
    step_counter += 1
    accelerate(unit)
    
  var outcome = MoveEffect.new()
  outcome.actual_path = actual_path
  
  if step_counter == planned_path.size():
    outcome.final_result = movement_outcome.ARRIVED_AT_DESTINATION
  else:
    outcome.final_result = movement_outcome.NO_MOVE_POINTS
  
  return outcome
    
    
func accelerate(unit):
  if unit.speed == speed_levels.STATIONARY:
    unit.speed = speed_levels.POP_OUT
  else:
    unit.speed = speed_levels.SLOW # TODO: check movement settings.
