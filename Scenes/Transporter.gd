extends Node2D

# This class moves object along a path.
# Any time something moves on the map (for an animation)
# this class takes it as a child and follows the animation path.

signal transport_done

var animation_speed
var path_to_follow

var path_length
var moving_object = null
var real_object_parent = null

func _ready():
  path_to_follow = get_parent()


func start_moving(distance_to_cover, speed, moving_obj):
  path_length = distance_to_cover
  animation_speed = speed
  moving_object = moving_obj

  path_to_follow.set_offset(0)
  
  moving_object.position = Vector2(0, 0)
  moving_object.set_rotation(0)

  real_object_parent = moving_obj.get_parent()
  real_object_parent.remove_child(moving_object)
  add_child(moving_object)


func _physics_process(delta):
  if moving_object == null:
   return
  
  var new_offset = path_to_follow.get_offset () + animation_speed * delta  
  
  if (new_offset >= path_length):
    new_offset = path_length # Do not overshoot!
    
    remove_child(moving_object)
    real_object_parent.add_child(moving_object)
    moving_object = null
    
    emit_signal("transport_done")
    return
    
  path_to_follow.set_offset(new_offset)
