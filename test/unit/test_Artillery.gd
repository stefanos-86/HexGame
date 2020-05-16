extends "res://addons/gut/test.gd"
 
var Artillery = preload("res://FreeScripts/Artillery.gd")

# This is not a "pure" unit test, but given that the methods are 
# 2 lines long and that there is no real logc, there's not much to do.

func test_plot_fire_mission():
  var cannon = Artillery.new()
  var target = Vector2(0, 0)
  
  cannon.plot_fire_mission(target)
  assert_false(cannon.ready_to_fire())
  assert_eq(target, cannon.target_coordinates)
 

func test_progress_fire_mission():
  var cannon = Artillery.new()
  cannon.plot_fire_mission(Vector2(0, 0))
  
  for _i in range(0, Artillery.FIRE_DELAY):
    assert_false(cannon.ready_to_fire())
    cannon.progress_fire_mission()
    
  assert_true(cannon.ready_to_fire())


func test_cancel_fire_mission():
  var cannon = Artillery.new()
  cannon.plot_fire_mission(Vector2(0, 0))
  cannon.cancel_fire_mission()
    
  assert_null(cannon.target_coordinates)


func test_fired():
  var cannon = Artillery.new()
  cannon.rounds_left = 10

  cannon.fired()
    
  assert_eq(9, cannon.rounds_left)
