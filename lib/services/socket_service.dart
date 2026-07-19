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
  final List<void Function(Map<String, dynamic>)> _newMessageListeners = [];
  final List<void Function(Map<String, dynamic>)> _statusUpdateListeners = [];

  void addMessageListener(void Function(Map<String, dynamic>) listener) {
    if (!_newMessageListeners.contains(listener)) {
      _newMessageListeners.add(listener);
    }
  }

  void removeMessageListener(void Function(Map<String, dynamic>) listener) {
    _newMessageListeners.remove(listener);
  }

  void addStatusListener(void Function(Map<String, dynamic>) listener) {
    if (!_statusUpdateListeners.contains(listener)) {
      _statusUpdateListeners.add(listener);
    }
  }

  void removeStatusListener(void Function(Map<String, dynamic>) listener) {
    _statusUpdateListeners.remove(listener);
  }

  void initialize(String userId) {
    if (_userId == userId && _socket != null) return;

    // If user changed, clean previous socket
    if (_userId != null && _userId != userId) {
      disconnect();
    }

    _userId = userId;
    _connect();
  }

  Future<void> _connect() async {
    if (_userId == null) return;

    final token = await _storage.getAccessToken();
    final baseUrl = ApiClient.I.dio.options.baseUrl
        .replaceAll('https://', 'wss://')
        .replaceAll('http://', 'ws://');

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

    _socket!.on('new_message', (data) {
      debugPrint('SocketService: New message received');
      for (final listener in _newMessageListeners) {
        listener(data);
      }
    });

    _socket!.on('message_status_update', (data) {
      for (final listener in _statusUpdateListeners) {
        listener(data);
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

  /// Réinitialise le service (déconnexion socket + nettoyage) lors du logout.
  void reset() {
    disconnect();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
