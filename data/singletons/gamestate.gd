extends Node

const SERVER_PORT = 1337
const MAX_PLAYERS = 8
var SERVER_IP = "localhost"
var player_template = preload("res://data/player/character.tscn")
signal players_changed()
#First, let's try to define what do we need our gamestate to do
#we know that we must manage our incoming connections, check them for all players 
#and that we must inform disconnections and so on.

#The network model will go like this:
#A central server is responsible for all the in-game calculations. 
onready var peer = NetworkedMultiplayerENet.new()
var players : Dictionary = {}

func _ready() -> void:
	peer.connect("connection_succeeded", self, "_on_NetworkPeer_connection_succeeded")
	peer.connect("connection_failed", self, "_on_NetworkPeer_connection_failed")
	peer.connect("peer_connected", self, "_on_NetworkPeer_peer_connected")
	peer.connect("peer_disconnected", self, "_on_NetworkPeer_peer_disconnected")
	peer.connect("server_disconnected", self, "_on_NetworkPeer_server_disconnected")
	for args in OS.get_cmdline_args():
		if args == "client":
			client_setup()
		if args == "server":
			server_setup()
	peer.allow_object_decoding = true
func server_setup():
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer
	register_player(1)

func client_setup():
	peer.create_client(IP.resolve_hostname(SERVER_IP), SERVER_PORT)
	get_tree().network_peer = peer

func _on_NetworkPeer_server_disconnected() -> void:
	get_tree().network_peer = null
	pass

func _on_NetworkPeer_peer_disconnected(peer_id) -> void:
	players.erase(peer_id)
	emit_signal("players_changed")
	pass
	
func _on_NetworkPeer_peer_connected(peer_id : int) -> void:
	if get_tree().is_network_server():
		register_player(peer_id)
		for peers in players:
			for player in players:
				if peers != 1:
					rpc_id(peers, "register_player", player)
					
func _on_NetworkPeer_connection_failed() -> void:
	pass
	
func _on_NetworkPeer_connection_succeeded() -> void:
	pass

func create_player(id) -> KinematicBody:
	var new_player =  player_template.instance()
	new_player.name = str(id)
	new_player.set_network_master(id)
	return new_player

remote func register_player(peer_id):
	if not players.has(peer_id):
		players[peer_id] = create_player(peer_id)
	emit_signal("players_changed")
	
