extends Node

var is_initialized = false
var _ad_close_cb: Callable = Callable()

func _ready():
	_init_webbus()

func _init_webbus() -> void:
	if typeof(WebBus) == TYPE_NIL:
		print("WebBus not available")
		return
	if not WebBus.is_init:
		await WebBus.inited
	is_initialized = true
	# Optional: hook focus to pause game/audio if needed
	WebBus.focused.connect(func():
		if get_tree(): get_tree().paused = false)
	WebBus.unfocused.connect(func():
		if get_tree(): get_tree().paused = true)
	print("WebBus initialized")
	gameplay_api_start()

func show_ad(on_complete: Callable) -> void:
	if not is_initialized:
		_init_webbus()
	if typeof(WebBus) == TYPE_NIL:
		print("WebBus not available, skipping ad")
		on_complete.call_deferred("Ad Closed")
		return
	# Connect one-shot ad_closed to invoke callback
	_ad_close_cb = on_complete
	var on_closed := func():
		WebBus.ad_closed.disconnect(on_closed)
		if _ad_close_cb.is_valid():
			_ad_close_cb.call("Ad Closed")
	WebBus.ad_closed.connect(on_closed)
	WebBus.show_ad()
	print("WebBus: Showing Fullscreen Ad")

func gameplay_api_start():
	if is_initialized and typeof(WebBus) != TYPE_NIL:
		WebBus.start_gameplay()

func gameplay_api_stop():
	if is_initialized and typeof(WebBus) != TYPE_NIL:
		WebBus.stop_gameplay()

func submit_score(leaderboard_name: String, score: int) -> void:
	if is_initialized and typeof(WebBus) != TYPE_NIL:
		WebBus.set_leaderboard_score(leaderboard_name, score)
		print("WebBus: submit score", leaderboard_name, score)
