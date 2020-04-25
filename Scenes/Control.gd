extends Control

func _ready():
  pass

func _input(event):
  if(event.is_action("Shutdown")):
    Shutdown()


func Shutdown():
    get_tree().quit() 
