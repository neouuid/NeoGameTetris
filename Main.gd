extends Node2D

const COLS: int = 10
const ROWS: int = 20
const CELL_SIZE: int = 30
const OFFSET_X: int = 50
const OFFSET_Y: int = 50

var grid: Array = []
var current_piece: Array = []
var current_color: Color = Color.WHITE
var current_x: int = 0
var current_y: int = 0
var score: int = 0
var game_over: bool = false

const SHAPES: Array = [
	[[1, 1, 1, 1]], # I
	[[1, 0, 0], [1, 1, 1]], # J
	[[0, 0, 1], [1, 1, 1]], # L
	[[1, 1], [1, 1]], # O
	[[0, 1, 1], [1, 1, 0]], # S
	[[0, 1, 0], [1, 1, 1]], # T
	[[1, 1, 0], [0, 1, 1]]  # Z
]

const COLORS: Array[Color] = [
	Color.CYAN,
	Color.BLUE,
	Color.ORANGE,
	Color.YELLOW,
	Color.GREEN,
	Color.PURPLE,
	Color.RED
]

@onready var timer: Timer = $Timer
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_label: Label = $UI/GameOverLabel

func _ready() -> void:
	init_grid()
	spawn_piece()
	timer.timeout.connect(_on_timer_timeout)
	timer.start(0.5)
	queue_redraw()

func init_grid() -> void:
	grid.clear()
	for y in range(ROWS):
		var row: Array = []
		for x in range(COLS):
			row.append(null)
		grid.append(row)

func spawn_piece() -> void:
	var index: int = randi() % SHAPES.size()
	current_piece = SHAPES[index].duplicate(true)
	current_color = COLORS[index]
	current_x = COLS / 2 - current_piece[0].size() / 2
	current_y = 0
	
	if not is_valid_position(current_piece, current_x, current_y):
		game_over = true
		game_over_label.show()
		timer.stop()

func is_valid_position(piece: Array, grid_x: int, grid_y: int) -> bool:
	for y in range(piece.size()):
		for x in range(piece[y].size()):
			if piece[y][x]:
				var nx: int = grid_x + x
				var ny: int = grid_y + y
				if nx < 0 or nx >= COLS or ny >= ROWS:
					return false
				if ny >= 0 and grid[ny][nx] != null:
					return false
	return true

func lock_piece() -> void:
	for y in range(current_piece.size()):
		for x in range(current_piece[y].size()):
			if current_piece[y][x]:
				var ny: int = current_y + y
				var nx: int = current_x + x
				if ny >= 0:
					grid[ny][nx] = current_color
	clear_lines()
	spawn_piece()

func clear_lines() -> void:
	var lines_cleared: int = 0
	var y: int = ROWS - 1
	while y >= 0:
		var full: bool = true
		for x in range(COLS):
			if grid[y][x] == null:
				full = false
				break
		if full:
			lines_cleared += 1
			grid.remove_at(y)
			var empty_row: Array = []
			for i in range(COLS): empty_row.append(null)
			grid.insert(0, empty_row)
			# Do not decrement y here, because the row above just dropped into y.
		else:
			y -= 1
			
	if lines_cleared > 0:
		score += lines_cleared * 100
		score_label.text = "Score: " + str(score)

func rotate_piece() -> void:
	var new_piece: Array = []
	for x in range(current_piece[0].size()):
		var row: Array = []
		for y in range(current_piece.size() - 1, -1, -1):
			row.append(current_piece[y][x])
		new_piece.append(row)
	
	if is_valid_position(new_piece, current_x, current_y):
		current_piece = new_piece

func _input(event: InputEvent) -> void:
	if game_over:
		if event.is_action_pressed("ui_accept"):
			restart_game()
		return
		
	if event.is_action_pressed("ui_left"):
		if is_valid_position(current_piece, current_x - 1, current_y):
			current_x -= 1
			queue_redraw()
	elif event.is_action_pressed("ui_right"):
		if is_valid_position(current_piece, current_x + 1, current_y):
			current_x += 1
			queue_redraw()
	elif event.is_action_pressed("ui_down"):
		if is_valid_position(current_piece, current_x, current_y + 1):
			current_y += 1
			queue_redraw()
	elif event.is_action_pressed("ui_up"):
		rotate_piece()
		queue_redraw()
	elif event.is_action_pressed("ui_accept"): # Hard drop
		while is_valid_position(current_piece, current_x, current_y + 1):
			current_y += 1
		lock_piece()
		queue_redraw()

func _on_timer_timeout() -> void:
	if not game_over:
		if is_valid_position(current_piece, current_x, current_y + 1):
			current_y += 1
		else:
			lock_piece()
		queue_redraw()

func restart_game() -> void:
	game_over = false
	score = 0
	score_label.text = "Score: 0"
	game_over_label.hide()
	init_grid()
	spawn_piece()
	timer.start()
	queue_redraw()

func _draw() -> void:
	# Draw background
	draw_rect(Rect2(OFFSET_X, OFFSET_Y, COLS * CELL_SIZE, ROWS * CELL_SIZE), Color(0.1, 0.1, 0.1))
	
	# Draw grid lines
	for y in range(ROWS + 1):
		draw_line(Vector2(OFFSET_X, OFFSET_Y + y * CELL_SIZE), Vector2(OFFSET_X + COLS * CELL_SIZE, OFFSET_Y + y * CELL_SIZE), Color(0.2, 0.2, 0.2))
	for x in range(COLS + 1):
		draw_line(Vector2(OFFSET_X + x * CELL_SIZE, OFFSET_Y), Vector2(OFFSET_X + x * CELL_SIZE, OFFSET_Y + ROWS * CELL_SIZE), Color(0.2, 0.2, 0.2))
			
	# Draw locked pieces
	for y in range(ROWS):
		for x in range(COLS):
			if grid[y][x] != null:
				draw_rect(Rect2(OFFSET_X + x * CELL_SIZE + 1, OFFSET_Y + y * CELL_SIZE + 1, CELL_SIZE - 2, CELL_SIZE - 2), grid[y][x])
				
	# Draw current piece
	if not game_over and current_piece.size() > 0:
		for y in range(current_piece.size()):
			for x in range(current_piece[y].size()):
				if current_piece[y][x]:
					draw_rect(Rect2(OFFSET_X + (current_x + x) * CELL_SIZE + 1, OFFSET_Y + (current_y + y) * CELL_SIZE + 1, CELL_SIZE - 2, CELL_SIZE - 2), current_color)
