extends Node2D

signal transport_done

var animation_speed
var follow_me

var moving = false
var path_length
var moving_object

func _ready():
  follow_me = get_parent()

func reset_at_start(distance_to_cover, speed, moving_obj):
  follow_me.set_offset(0)
  path_length = distance_to_cover
  animation_speed = speed
  moving = true
  moving_object = moving_obj
  
  moving_object.position = Vector2(0, 0)
  moving_object.set_rotation(0)
  moving_object.set_visible(true)
  add_child(moving_object)

func _physics_process(delta):
  if not moving:
   return
  
  var new_offset = follow_me.get_offset () + animation_speed * delta  
  if (new_offset >= path_length):
    new_offset = path_length
    moving = false
    remove_child(moving_object)
    emit_signal("transport_done")
    return
    
  follow_me.set_offset(new_offset)
