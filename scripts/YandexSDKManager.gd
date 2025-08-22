extends Node

var is_initialized = false
var _ad_close_cb: Callable = Callable()
var _reward_close_cb: Callable = Callable()
var _reward_given_cb: Callable = Callable()

func _ready():
	_init_webbus()

func _init_webbus() -> void:
	if typeof(WebBus) == TYPE_NIL:
		print("WebBus not available")
		return
	if not WebBus.is_init:
		await WebBus.inited
	is_initialized = true
	# Hook focus
	WebBus.focused.connect(func(): if get_tree(): get_tree().paused = false)
	WebBus.unfocused.connect(func(): if get_tree(): get_tree().paused = true)
	print("WebBus initialized")
	gameplay_api_start()

func show_ad(on_complete: Callable) -> void:
	if not is_initialized:
		_init_webbus()
	if typeof(WebBus) == TYPE_NIL:
		print("WebBus not available, skipping ad")
		on_complete.call_deferred("Ad Closed")
		return
	_ad_close_cb = on_complete
	var on_closed := func():
		WebBus.ad_closed.disconnect(on_closed)
		if _ad_close_cb.is_valid():
			_ad_close_cb.call("Ad Closed")
	WebBus.ad_closed.connect(on_closed)
	WebBus.show_ad()
	print("WebBus: Showing Fullscreen Ad")

func show_rewarded_ad(on_reward: Callable, on_closed: Callable) -> void:
	if not is_initialized:
		_init_webbus()
	if typeof(WebBus) == TYPE_NIL:
		print("WebBus not available, skipping rewarded ad")
		on_closed.call_deferred("Ad Closed")
		return
	_reward_given_cb = on_reward
	_reward_close_cb = on_closed
	var on_rewarded := func():
		WebBus.reward_added.disconnect(on_rewarded)
		if _reward_given_cb.is_valid():
			_reward_given_cb.call()
	var on_closed := func():
		WebBus.ad_closed.disconnect(on_closed)
		if _reward_close_cb.is_valid():
			_reward_close_cb.call("Ad Closed")
	WebBus.reward_added.connect(on_rewarded)
	WebBus.ad_closed.connect(on_closed)
	WebBus.show_rewarded_ad()
	print("WebBus: Showing Rewarded Ad")

func show_banner() -> void:
	if is_initialized and typeof(WebBus) != TYPE_NIL:
		WebBus.show_banner()

func hide_banner() -> void:
	if is_initialized and typeof(WebBus) != TYPE_NIL:
		WebBus.hide_banner()

func open_auth_dialog() -> void:
	if is_initialized and typeof(WebBus) != TYPE_NIL:
		WebBus.open_auth_dialog()

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
