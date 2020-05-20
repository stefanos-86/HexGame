extends "res://addons/gut/test.gd"

var Game = preload("res://FreeScripts/Game.gd")
var game

var mock_terrain = null
var mock_random = null
 
var UnitInField = load("res://Units/UnitInField.gd")

class TestTank:
  var game = preload("res://FreeScripts/Game.gd")
  var gun_max_range = 10
  var gun_penetration_power = 10
  var armour_thickness = {
    game.armor_part.FRONT: 10,
    game.armor_part.SIDE: 5,
    game.armor_part.REAR: 1,
  }
  var max_fire_points = 2
  var max_move_points = 8
  var type_name = "TestTank"

func create_test_tank():
  var test_unit = UnitInField.new()
  test_unit.faction = game.factions.RED
  test_unit.type = TestTank.new()
  test_unit.move_points = 1
  test_unit.fire_points = 1
  test_unit.movement_stance = game.movement_stances.GO_SLOW
  test_unit.fire_stance = game.fire_stances.FIRE_AT_WILL
  return test_unit


func before_each():
  mock_terrain = double('res://Scenes/Terrain.gd').new()
  mock_random = double(RandomNumberGenerator).new()
  
  game = Game.new()
  game.rng = mock_random

  
func test_begin_game():
  game.begin_game()
  assert_eq("RED", game.current_player_name())
  assert_eq(1, game.turn_count)

func test_next_turn__half_turn():
  game.begin_game()
  game.next_turn()
  assert_eq("BLUE", game.current_player_name())
  assert_eq(1, game.turn_count)

func test_next_turn__full_turn():
  game.begin_game()
  game.next_turn()
  game.next_turn()
  assert_eq("RED", game.current_player_name())
  assert_eq(2, game.turn_count)
 

func _set_fire_distance(value):
   stub(mock_terrain, 'distance_between').to_return(value)
  
 
func test_fire__no_fire_points():
  var attacker = create_test_tank()
  attacker.fire_points = 0
  
  var actual = game.fire(attacker, null, null)
  assert_eq(game.fire_outcome.NO_FIRE_POINTS, actual.final_result)


func test_fire__too_far():
  var attacker = create_test_tank()
  
  var too_far = attacker.type.gun_max_range + 1
  _set_fire_distance(too_far)
  
  var actual = game.fire(attacker, null, mock_terrain) 
  assert_eq(game.fire_outcome.OUT_OF_RANGE, actual.final_result)

func test_fire__subtracts_ammo():
  var attacker = create_test_tank()
  var defender = create_test_tank()
  
  _set_fire_distance(1)
  
  var _actual = game.fire(attacker, defender, mock_terrain) 
  assert_eq(0, attacker.fire_points)


func test_fire__no_hit():
  var attacker = create_test_tank()
  var defender = create_test_tank()
  
  _set_fire_distance(1)
  stub(mock_random, 'randf').to_return(1)
  
  var actual = game.fire(attacker, defender, mock_terrain) 
  assert_eq(game.fire_outcome.MISS, actual.final_result)

func test_fire__front_hit():
  var attacker = create_test_tank()
  attacker.position = Vector2(0, 0)
  
  var defender = create_test_tank()
  defender.position = Vector2(1, 0) # Right of the attacker.
  defender.global_rotation = PI     # Looking left, towards the attacker. 
  
  _set_fire_distance(1)
  stub(mock_random, 'randf').to_return(0.1)
  
  var actual = game.fire(attacker, defender, mock_terrain) 
  assert_eq(game.armor_part.FRONT, actual.armor_part_hit)

func test_fire__rear_hit():
  var attacker = create_test_tank()
  attacker.position = Vector2(0, 0)
  
  var defender = create_test_tank()
  defender.position = Vector2(1, 0) # Right of the attacker.
  defender.global_rotation = 0     # Looking right, away from the attaker. 
  
  _set_fire_distance(1)
  stub(mock_random, 'randf').to_return(0.1)
  
  var actual = game.fire(attacker, defender, mock_terrain) 
  assert_eq(game.armor_part.REAR, actual.armor_part_hit)


func test_fire__side_hit():
  var attacker = create_test_tank()
  attacker.position = Vector2(0, 0)
  
  var defender = create_test_tank()
  defender.position = Vector2(1, 0) # Right of the attacker.
  defender.global_rotation = 0     # Looking right, away from the attaker. 
  
  _set_fire_distance(1)
  stub(mock_random, 'randf').to_return(0.1)
  
  var actual = game.fire(attacker, defender, mock_terrain) 
  assert_eq(game.armor_part.REAR, actual.armor_part_hit)


func test_fire__ineffective():
  #Setup a side hit.
  var attacker = create_test_tank()
  attacker.position = Vector2(0, 0)
  var defender = create_test_tank()
  defender.position = Vector2(1, 0)
  defender.global_rotation = -PI / 2
  
  _set_fire_distance(1)
  stub(mock_random, 'randf').to_return(0.1)
  
  defender.type.armour_thickness[game.armor_part.SIDE] = attacker.type.gun_penetration_power + 1
  
  var actual = game.fire(attacker, defender, mock_terrain) 
  assert_eq(game.fire_outcome.INEFFECTIVE, actual.final_result)

