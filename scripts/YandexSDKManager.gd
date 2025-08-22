extends Node

var is_initialized = false
var on_ad_complete = null

func _ready():
	on_sdk_initialized("SDK Initialized by addon")

func on_sdk_initialized(result):
	is_initialized = true
	print("Yandex SDK Initialized: " + result)
	gameplay_api_start()
	load_player_data()

func show_ad(on_complete):
	if is_initialized:
		on_ad_complete = on_complete
		if has_node("/root/YandexSDK"):
			var sdk = get_node("/root/YandexSDK")
			sdk.show_fullscreen_adv()
			print("Showing Fullscreen Ad")
			on_ad_complete.call("Ad Closed")
		else:
			print("YandexSDK not available, skipping ad")
			on_ad_complete.call("Ad Closed")

func gameplay_api_start():
	if is_initialized:
		if has_node("/root/YandexSDK"):
			var sdk = get_node("/root/YandexSDK")
			sdk.gameplay_api_start()
			print("Gameplay API Started")
		else:
			print("YandexSDK not available, skipping gameplay API start")

func load_player_data():
	if is_initialized:
		if has_node("/root/YandexSDK"):
			var sdk = get_node("/root/YandexSDK")
			sdk.load_player_data()
			print("Player Data Loaded")
		else:
			print("YandexSDK not available, skipping player data load")
