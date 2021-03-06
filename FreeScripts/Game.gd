# This script has all the "simulation logic" to compute the outcomes
# of movement and engagements. And the turn counting. It had to go somewhere...

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
  NO_FIRE_POINTS,
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

enum movement_stances {
  GO_SLOW,
  GO_FAST
 }

enum fire_stances {
  FIRE_AT_WILL,
  RETURN_FIRE,
  HOLD_FIRE
 }

class FireEffect:
  var armor_part_hit = null
  var final_result = null
  var shooter = null # Needed for reaction fire.
  var target = null # Needed to destroy it.
 
class MoveEffect:
  var actual_path = null
  var final_result = null
  
class ArtilleryEffect:
  var actual_hit = null
  var final_result = null
  var destroyed_target = null

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
  
func _swap_player():
  if (current_player == factions.RED):
    current_player = factions.BLUE
  else:
    current_player = factions.RED
    
func _increment_turn():
  if (current_player == first_player_in_turn):
    turn_count += 1

func next_turn():
  _swap_player()
  _increment_turn()
  
func hit_probability(attacker, target, distance):
  var p = 100
  p = _movement_accuracy_penalty(p, attacker.speed)
  p = _movement_accuracy_penalty(p, target.speed)
  p = _distance_penalty(p, distance, attacker.type.gun_max_range)
    
  # Account for size? For heading?
  
  return int(p)

func _movement_accuracy_penalty(base_hit_probability, speed):
  if speed == speed_levels.SLOW:
    base_hit_probability /= 2
  elif speed == speed_levels.FAST:
    base_hit_probability /= 4
  return base_hit_probability
    
func fire(shooter, target, terrain):
  var effect = FireEffect.new()
  effect.shooter = shooter
  effect.target = target
  
  if shooter.fire_points == 0:
    effect.final_result = fire_outcome.NO_FIRE_POINTS
    return effect
  
  var distance = terrain.distance_between(shooter, target)
  
  if distance > shooter.type.gun_max_range:
    effect.final_result = fire_outcome.OUT_OF_RANGE
    return effect
  
  shooter.fire_points -= 1
  
  var hit_p = hit_probability(shooter, target, distance)
  if rng.randf() * 100 > hit_p:
    effect.final_result = fire_outcome.MISS
    return effect
    
  var shot_strength = _distance_penalty(shooter.type.gun_penetration_power, distance, shooter.type.gun_max_range) 
  
  # Try to figure out the angle at which the projectile is coming into
  # the target, from the target point of view. First compute
  # the direction of the bullet.
  var attack_direction = target.position - shooter.position
  var attack_angle = attack_direction.angle()
  if attack_angle < 0:
    attack_angle += TWO_PI
    
  # Now rotate the incoming attack in the target coordinate system.
  # The target "0" is its front, PI is it's back.
  # Scale so that the angle is in [0, 1] rather than [0, 2*PI]
  # (simplifies things after).
  var bearing = (attack_angle - target.global_rotation) / TWO_PI 
  effect.armor_part_hit = _impact_point(bearing)
  
  if shot_strength > target.type.armour_thickness[effect.armor_part_hit]:
    effect.final_result = fire_outcome.DESTROYED
  else:
    effect.final_result = fire_outcome.INEFFECTIVE
  
  return effect

# max_distance = range where the values goes to 0.
# Hit probability decrease linearly with distance.
func _distance_penalty(value_at_no_distance, distance, max_distance):
  var distance_factor = clamp(float(distance) / max_distance, 0, 1)
  return lerp(value_at_no_distance, 0, distance_factor)

# The probability of hitting the side is 0 when looking head on
# of at the back, but goes to 1 when looking at the side.
#  ^
# 1|  /\    /\
#  | /  \  /  \
#  |/    \/    \
#  +--------------->
#  0  0.5 0.75  1  <== bearing values
#  0 PI/2 3PI/2 PI <== rads   
# So, roll the dice to see if it is a side hit, given the
# probability. If it is not, check the angle again to decide if
# it is front or rear.
func _impact_point(bearing):
  var p_hit_side = 0
  if (bearing < 0.25):
    p_hit_side = lerp(0, 1, bearing * 4)
  elif(bearing < 0.5):
    p_hit_side = lerp(1, 0, (bearing - 0.25) * 4)
  elif(bearing < 0.75):
    p_hit_side = lerp(0, 1, (bearing - 0.5) * 4)
  else:
    p_hit_side = lerp(1, 0, (bearing - 0.75) * 4)
    
  var armor_part_hit = armor_part.REAR
  if rng.randf() <= p_hit_side:
    armor_part_hit = armor_part.SIDE
  elif bearing > 0.25 and bearing < 0.75:
    armor_part_hit = armor_part.FRONT
  
  return armor_part_hit

# Walk the path one bit at a time and simulate things that can
# happen along the way. Return a data structure that tells the results
# of the movement, with the path actually travelled up to the available
# move points and (TODO) any ambush.
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
  if unit.movement_stance == movement_stances.GO_SLOW:
    if unit.speed == speed_levels.STATIONARY:
      unit.speed = speed_levels.POP_OUT
    else:
      unit.speed = speed_levels.SLOW
  else:
    if unit.speed == speed_levels.STATIONARY:
      unit.speed = speed_levels.SLOW
    else:
      unit.speed = speed_levels.FAST

func fire_artillery(cannons, terrain):
  var results = []
  
  for c in cannons:
    var expected_target = c.target_coordinates
    var possible_hits = terrain.within_distance(expected_target, c.margin_of_error)

    var actual_hit_index = rng.randi_range(0, possible_hits.size() -1)
    var actual_hit = possible_hits[actual_hit_index]
    
    var outcome = ArtilleryEffect.new()
    outcome.actual_hit = actual_hit
    outcome.final_result = fire_outcome.MISS
    
    var object_at_hit = terrain.what_is_at(actual_hit) 
    
    if object_at_hit != null:
      var already_hit = false
      for effect in results:
        if effect.destroyed_target == object_at_hit:
            already_hit = false 
      
      # TODO: more complex destruction model? Account for armor?
      if already_hit == false and object_at_hit != null and rng.randf() < 0.3:
        outcome.final_result = fire_outcome.DESTROYED
        outcome.destroyed_target = object_at_hit
      
    results.append(outcome)
    c.fired()
    
  return results

static func by_move_points_desc (a, b):
  return a.move_points > b.move_points # Reverse order!

func reaction_fire(against_this_unit, defender, terrain, opponents):
  var reacting_enemies = []
  for enemy in opponents:
    
    if enemy.move_points > against_this_unit.move_points and enemy.alive == true:
      
      if enemy == defender and enemy.fire_stance == fire_stances.RETURN_FIRE:
        reacting_enemies.append(enemy.fire_stance)
      
      elif enemy.fire_stance == fire_stances.FIRE_AT_WILL:
        reacting_enemies.append(enemy)
  
  reacting_enemies.sort_custom(self, "by_move_points_desc")       
  
  var reactions = []
  for enemy in reacting_enemies:
    var outcome = fire(enemy, against_this_unit, terrain)
    reactions.append(outcome)
    
    if outcome.final_result == fire_outcome.DESTROYED:
      break # Assume people won't fire again on a wrecked unit.
    
  return reactions  
