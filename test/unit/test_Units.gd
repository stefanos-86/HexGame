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
  
  units.create_all_units(mock_terrain)
  
  
func test_count_units_of__red():
  var actual = units.count_units_of(Game.factions.RED)
  assert_eq(6, actual)


func test_count_units_of__blue():
  var actual = units.count_units_of(Game.factions.BLUE)
  assert_eq(3, actual)


func test_order_of_battle_of__blue():
  var actual = units.order_of_battle_of(Game.factions.BLUE)
  assert_eq(Game.factions.BLUE, actual[0].faction)
  assert_eq(Game.factions.BLUE, actual[1].faction)
  assert_eq(Game.factions.BLUE, actual[2].faction)
  assert_eq(3, actual.size())
  
