extends Node
## ENet two-player transport. The host is authoritative over the world.
## Direct-IP connection: LAN works without routing; internet needs a safe VPN or forwarded UDP port.
signal teammate_connected(peer_id: int)
signal teammate_disconnected(peer_id: int)
signal joined_host
signal join_failed
signal controls_received(direction: Vector2, angle: float, firing: bool, interacting: bool)
signal teammate_introduced(job: int, name: String)
signal interact_requested
signal snapshot_received(snapshot: Dictionary)

const PORT := 24566
const MAX_PEERS := 1
var peer_id := 0

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> Error:
	close_game()
	var enet := ENetMultiplayerPeer.new()
	var err: Error = enet.create_server(PORT, MAX_PEERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = enet
	return OK

func join_game(address: String) -> Error:
	var ip := address.strip_edges()
	if ip.is_empty() or ip.length() > 255:
		return ERR_INVALID_PARAMETER
	close_game()
	var enet := ENetMultiplayerPeer.new()
	var err: Error = enet.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = enet
	return OK

func close_game() -> void:
	peer_id = 0
	if multiplayer.multiplayer_peer != null and not (multiplayer.multiplayer_peer is OfflineMultiplayerPeer):
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func is_host() -> bool:
	return multiplayer.has_multiplayer_peer() and multiplayer.is_server() and multiplayer.multiplayer_peer is ENetMultiplayerPeer

func is_guest() -> bool:
	return multiplayer.has_multiplayer_peer() and not multiplayer.is_server()

func introduce_self(job: int, display_name: String) -> void:
	if is_guest():
		guest_introduce.rpc_id(1, clampi(job, 0, 6), display_name.substr(0, 16))

@rpc("any_peer", "call_remote", "reliable")
func guest_introduce(job: int, display_name: String) -> void:
	if is_host() and multiplayer.get_remote_sender_id() == peer_id:
		teammate_introduced.emit(clampi(job, 0, 6), display_name.substr(0, 16))

func send_interaction() -> void:
	if is_guest():
		guest_interact.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func guest_interact() -> void:
	if is_host() and multiplayer.get_remote_sender_id() == peer_id:
		interact_requested.emit()

func send_controls(direction: Vector2, angle: float, firing: bool, interacting: bool) -> void:
	if is_guest():
		guest_controls.rpc_id(1, direction.limit_length(1.0), angle, firing, interacting)

func send_snapshot(world: Dictionary) -> void:
	if is_host() and peer_id > 1:
		host_snapshot.rpc_id(peer_id, world)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func guest_controls(direction: Vector2, angle: float, firing: bool, interacting: bool) -> void:
	if not is_host() or multiplayer.get_remote_sender_id() != peer_id:
		return
	if not is_finite(direction.x) or not is_finite(direction.y) or not is_finite(angle):
		return
	controls_received.emit(direction.limit_length(1.0), angle, firing, interacting)

@rpc("authority", "call_remote", "unreliable_ordered")
func host_snapshot(world: Dictionary) -> void:
	if is_guest() and multiplayer.get_remote_sender_id() == 1:
		snapshot_received.emit(world)

func _on_peer_connected(id: int) -> void:
	if is_host() and (peer_id == 0 or peer_id == id):
		peer_id = id
		teammate_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	if peer_id == id:
		peer_id = 0
		teammate_disconnected.emit(id)

func _on_connected_to_server() -> void:
	joined_host.emit()

func _on_connection_failed() -> void:
	close_game()
	join_failed.emit()

func _on_server_disconnected() -> void:
	close_game()
	join_failed.emit()
