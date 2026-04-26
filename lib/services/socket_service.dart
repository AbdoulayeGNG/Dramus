import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dramus/core/api/token_storage.dart';
import 'package:dramus/core/api/api_client.dart';

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  final TokenStorage _storage = TokenStorage();
  String? _userId;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Callbacks for message events
  void Function(Map<String, dynamic>)? _onNewMessage;
  void Function(Map<String, dynamic>)? _onStatusUpdate;

  void setCallbacks({
    void Function(Map<String, dynamic>)? onNewMessage,
    void Function(Map<String, dynamic>)? onStatusUpdate,
  }) {
    _onNewMessage = onNewMessage;
    _onStatusUpdate = onStatusUpdate;
  }

  void initialize(String userId) {
    if (_userId == userId && _socket != null) return;

    _userId = userId;
    _connect();
  }

  Future<void> _connect() async {
    if (_userId == null) return;

    final token = await _storage.getAccessToken();
    final baseUrl = ApiClient.instance.dio.options.baseUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');

    debugPrint('SocketService: Connecting to $baseUrl with userId: $_userId');

    _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .build());

    _socket!.onConnect((_) {
      debugPrint('SocketService: Connected');
      _isConnected = true;
      _joinUserRoom();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketService: Disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.onConnectError(
        (data) => debugPrint('SocketService: Connect Error: $data'));
    _socket!.onError((data) => debugPrint('SocketService: Error: $data'));

    _socket!.on('new_message', (data) {
      debugPrint('SocketService: New message received via socket: $data');
      if (_onNewMessage != null) {
        _onNewMessage!(data);
      }
    });

    _socket!.on('message_status_update', (data) {
      debugPrint('SocketService: Message status update: $data');
      if (_onStatusUpdate != null) {
        _onStatusUpdate!(data);
      }
    });
  }

  void _joinUserRoom() {
    if (_socket != null && _userId != null) {
      debugPrint('SocketService: Joining room user_$_userId');
      _socket!.emit('join', 'user_$_userId');
    }
  }

  void markAsDelivered(String messageId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_as_delivered', {'messageId': messageId});
    }
  }

  void markAsRead(String messageId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('mark_as_read', {'messageId': messageId});
    }
  }

  void reconnect() {
    if (_socket != null) {
      debugPrint('SocketService: Manual reconnection');
      _socket!.connect();
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _userId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
