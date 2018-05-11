extends Node2D

#Sprite export from Scene folder
var Block = preload("res://Scenes/Block.xml")
var Circle = preload("res://Scenes/Circle.xml")

const blockSize = 30.0							# Size of block sprite

export var movement_speed = 0.3					# Movement speed of snake

export var width = 14							# Width of snake board
export var height = 14 							# Height of snake board

#Color of sprites
export var wall_color = Color(255, 255, 255)
export var snake_color = Color(255, 255, 255)
export var food_coloring = Color(255, 0, 0)

const startingLength = 4						#Starting Length of Snake
var startingPos = Vector2(3, 12)

var playerSnake									# Snake variable

var board = {}

var roundOver = false
var timer										#Update functionality
var game_timer									#Time Counter
var food										#food variable
var result_text									#Display Game Over

var snake_moving

var snakeLength_text
var resultMenu

class Snake:
	var Block = preload("res://Scenes/Block.xml")
	
	var position = Vector2(0,0)
	var _blocks = []
	var movement = Vector2(0,0)
	var _color
	
	var _roundOver = false
	var _board_node
	var _board = {}
	var _board_width = 0
	var _board_height = 0
	
	# return player's length
	func length():
		return _blocks.size()
		
	# return player's blocks
	func blocks():
		return _blocks
	
	# return player's position
	func pos():
		return position
	
	# set player's directions
	func set_dir(dir):
		if movement.dot(dir) != 0:
			#wrong direction
			return false
		movement = dir
		return true
	
	func dir():
		return movement
	
	# return round over
	func gameover():
		return _roundOver
	
	# set Snake board's Node2D reference for add_child
	func setBoardNode(board_node):
		_board_node = board_node
	
	# set board's reference
	func setBoard(board, width, height):
		_board = board
		_board_width = width
		_board_height = height
	
	# setup snake player
	func setup(pos, dir, length, color):
		if _blocks.size() > 0:
			for block in _blocks:
				block.queue_free()
			_blocks = []
		position = pos
		movement = dir
		_color = color
		for i in range(length):
			var block = Block.instance()
			var block_pos = position - Vector2(1,0) * i
			block.set_modulate(_color)
			block.set_pos(block_pos * blockSize)
			_board_node.add_child(block)
			_board[block_pos] = 1
			_blocks.push_back(block)
		_roundOver = false
	
	# move with movement, switch statement can_move: 1 - hit wall or self, 2 - hit food, 0 -  hit empty tile
	func move():
		var can_move = check_move(movement)
		if can_move == 1:
			_roundOver = true
		
		elif can_move == 2:
			position += movement
			var new_block = Block.instance()
			new_block.set_modulate(_color)
			new_block.set_pos(position * blockSize)
			_blocks.insert(0, new_block)
			_board_node.add_child(new_block)
			_board[position] = 1
		else:
			var tail_block = _blocks[_blocks.size()-1]
			var tail_pos = tail_block.get_pos() / blockSize
			_board[tail_pos] = 0
			position += movement
			tail_block.set_pos(position * blockSize)
			_board[position] = 1
			# remove the tail block and insert to head
			_blocks.resize(_blocks.size()-1)
			_blocks.insert(0, tail_block)
			
		return can_move
		
		
	func tail_pos():
		var tail_block = _blocks[_blocks.size()-1]
		var tail_position = tail_block.get_pos() / blockSize
		return tail_position
		
	# check if the move is avaliable
	func check_move(dir):
		# if snake hit the wall or self, return 1
		# if snake will eat food, return 2
		# if snake will move to an empty tile, return 0
		var attempt_move = position + dir
		if attempt_move.x < 0 || attempt_move.x >= _board_width || attempt_move.y < 0 || attempt_move.y >= _board_height:
			return 1
		return _board[attempt_move]
		
	
###################### end of Class Snake player ########################

func _ready():
	# Starting up game
	GettingNodes()
	snake_wall()
	playerSnake = Snake.new()
	playerSnake.setBoardNode(get_node("."))
	
	setup_game()
	set_process(true)
	set_fixed_process(true)
	
###################### end of _ready #####################

func setup_game():
	
	setup_board()
	playerSnake.setBoard(board, width, height)
	playerSnake.setup(startingPos, Vector2(1, 0), startingLength, snake_color)
	generate_food()
	
	timer = movement_speed
	snake_moving = false
	roundOver = false
	update_snake_length_text()

############################ END OF SETUP #############################

func _process(delta):
	if roundOver:
			get_tree().set_pause(false)
			setup_game()
	
	if Input.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()
	
	timer -= delta
	
	SnakeMove()
	
	if timer < 0:
		#move the players
		var result = playerSnake.move()
		
		# Snake hits food
		if result == 2:
			# Create new food
			generate_food()
			update_snake_length_text()
		
		# Snake hit wall or self
		if result == 1:
			round_over()
			Result()
			
		
		timer = movement_speed
		snake_moving = false

func snake_wall():
	
	var Wall
	# Left and Right walls
	for i in range(0, height):
		Wall = Block.instance()
		Wall.set_modulate(wall_color)
		Wall.set_pos(Vector2(-blockSize, i * blockSize))
		add_child(Wall)
		
		Wall = Block.instance()
		Wall.set_modulate(wall_color)
		Wall.set_pos(Vector2(width * blockSize, i * blockSize))
		add_child(Wall)
	
	# Top and Bottom walls
	for i in range(-1, width + 1):
		Wall = Block.instance()
		Wall.set_modulate(wall_color)
		Wall.set_pos(Vector2( i * blockSize, - blockSize))
		add_child(Wall)
		
		Wall = Block.instance()
		Wall.set_modulate(wall_color)
		Wall.set_pos(Vector2(i * blockSize, height * blockSize))
		add_child(Wall) 
###############################END OF SNAKE BOUNDARIES #########################

func setup_board():
	for i in range(width):
		for j in range(height):
			board[Vector2(i, j)] = 0

############################# END OF BOARD ###############################

func generate_food():
	if food == null:
		# Make snake food
		food = Circle.instance()
		food.set_modulate(food_coloring)
		add_child(food)
	
	var foodPosition = Vector2(0,0)
	# Locate a random drop for food
	if playerSnake.length() > height * width * 0.5:
		var available = []
		for key in board.keys():
			if board[key] == 0:
				available.push_back(key)
		randomize()
		foodPosition = available[randi() % available.size()]
		
	else:
		randomize()
		foodPosition = Vector2(randi() % width, randi() % height)
		while(board[foodPosition] == 1):
			foodPosition = Vector2(randi() % width, randi() % height)
		
	food.set_pos(foodPosition * blockSize)
	board[foodPosition] = 2
	
	#add a function to return position of food. 
########################## END OF CREATING SNAKE FOOD ######################

func round_over():
	for block in playerSnake.blocks():
		block.set_modulate(Color(0.3, 0.3, 0.3))
	roundOver = true
	get_tree().set_pause(true)

################### END OF ROUND ####################################
#player controls

func SnakeMove():
	#gets food position
	var foodPos = food.get_pos()/30 #convert to blocksize
	var playerPos = playerSnake.pos()
	#var result = playerSnake.move(), if result == 1
	var tailPos = playerSnake.tail_pos()
	var nextPos = playerPos.y
	var prevPos = playerPos.y - 1

	#if food is above player
	if playerPos.y > foodPos.y:
		nextPos = playerPos.y - 1 #-1 because up decreases y axis value
		
		#next code doesnt, entirely solve, when snake hits itself, but temporarily does
		if nextPos != tailPos.y: #if next head position intercepts tail's x-axis, then it waits
			playerSnake.set_dir(Vector2(0.0,-1.0)) #go up

	#if food is below player
	elif playerPos.y < foodPos.y:
		playerSnake.set_dir(Vector2(0.0,1.0)) #go down

	#if food is horizontal and at right of player 
	if playerPos.y == foodPos.y && playerPos.x < foodPos.x:
		playerSnake.set_dir(Vector2(1.0,0.0))

	#if food is horizontal and at left of player 
	elif playerPos.y == foodPos.y && playerPos.x > foodPos.x:
		playerSnake.set_dir(Vector2(-1.0,0.0))
	
	
	"""
		var attemptMove = Vector2(1.0, 1.0) #Attempt snake movement
	
	if !snake_moving:
		
		if Input.is_action_pressed("ui_up"):
			attemptMove = Vector2(0.0, -1.0)
		
		elif Input.is_action_pressed("ui_down"):
			attemptMove = Vector2(0.0, 1.0)
			
		elif Input.is_action_pressed("ui_right"):
			attemptMove = Vector2(1.0, 0.0)
		
		elif Input.is_action_pressed("ui_left"):
			attemptMove = Vector2(-1.0, 0.0)
		
		snake_moving = playerSnake.set_dir(attemptMove)
	"""

############################ END OF SNAKE MOVEMENT ################################

func update_snake_length_text():
	snakeLength_text.set_text("Snake length: " + str(playerSnake.length()))
	
######################## END OF TEXT LENGTH ########################################

func GettingNodes():
	snakeLength_text = get_node("../HUD/snakeLengthText")
	result_text = get_node("../HUD/resultMenu/resultText")
	resultMenu = get_node("../HUD/resultMenu")

func Result():
	resultMenu.show()
	result_text.set_text("Game Over\nSnake length: " + str(playerSnake.length()))

func _on_Replay_pressed():
	resultMenu.hide()
	get_tree().set_pause(false)
	get_tree().reload_current_scene()

func _on_Quit_pressed():
	resultMenu.hide()
	get_tree().set_pause(false)
	#TODO: REPLACE WITH MAIN MENU NAVIGATION
	get_tree().change_scene("res://Game.xml")
	
