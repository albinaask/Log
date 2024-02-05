@tool
extends LogStream

##A default instance of the LogStream. Instanced as the main log singelton.


func _init():
	super("Main", LogLevel.DEFAULT)

