extends "res://addons/gut/test.gd"

var Game = preload("res://FreeScripts/Game.gd")

var mock_terrain = null
 
var Units = load("res://Scenes/Units.gd")
var units = null

func before_each():
  units = Units.new()
  
  var mock_terrain = double('res://Scenes/Terrain.gd').new()
  stub(mock_terrain, 'cell_to_world').to_return(Vector2(0, 0))
  units.terrain = mock_terrain
  
  units.create_all_units()
  
  
func test_count_remaining_units_of__red():
  var actual = units.count_remaining_units_of(Game.factions.RED)
  assert_eq(6, actual)


func test_count_remaining_units_of__blue():
  var actual = units.count_remaining_units_of(Game.factions.BLUE)
  assert_eq(3, actual)
  
  
func test_count_remaining_units_of__after_destruction():
  var target = units.order_of_battle_of(Game.factions.RED)[0]
  target.mark_destruction()
  var actual = units.count_remaining_units_of(Game.factions.RED)
  assert_eq(5, actual)


func test_order_of_battle_of__blue():
  var actual = units.order_of_battle_of(Game.factions.BLUE)
  assert_eq(Game.factions.BLUE, actual[0].faction)
  assert_eq(Game.factions.BLUE, actual[1].faction)
  assert_eq(Game.factions.BLUE, actual[2].faction)
  assert_eq(3, actual.size())
  
func test_all_units():
  var actual = units.all_units()
  assert_eq(9, actual.size())
  
  
func test_available_fire_support():
  var actual = units.available_fire_support(Game.factions.RED)
  assert_eq(2, actual.size())

func test_ready_fire_missions__nothing_plotted():
  var actual = units.ready_fire_missions(Game.factions.RED)
  assert_eq([], actual)
  
func test_ready_fire_missions__ready_after_progress():
  var test_cannon = units.available_fire_support(Game.factions.RED).front()
  test_cannon.plot_fire_mission(Vector2(0, 0))
  
  units.progress_fire_missions(Game.factions.RED)
  units.progress_fire_missions(Game.factions.RED)
  
  var actual = units.ready_fire_missions(Game.factions.RED)
  assert_eq(1, actual.size())
  
func test_clear_executed_fire_missions():
  var test_cannon = units.available_fire_support(Game.factions.RED).front()
  test_cannon.plot_fire_mission(Vector2(0, 0))
  
  units.progress_fire_missions(Game.factions.RED)
  units.progress_fire_missions(Game.factions.RED)
  
  units.clear_executed_fire_missions(Game.factions.RED)
  
  var actual = units.ready_fire_missions(Game.factions.RED)
  assert_eq([], actual)
