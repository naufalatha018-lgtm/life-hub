import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain_event.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Dynamic JWT Token interceptor with mutex lock auto-refresh.
class TokenAuthInterceptor {
  String _currentToken = 'initial_jwt_token_2026';
  DateTime _expiresAt = DateTime.now().add(const Duration(minutes: 15));
  Completer<void>? _refreshCompleter;

  /// Returns valid bearer token, executing mutual exclusion refresh if expired.
  Future<String> getAuthorizationBearer() async {
    if (DateTime.now().isBefore(_expiresAt)) {
      return _currentToken;
    }

    // Mutex pattern: ensure only one refresh runs concurrently
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      return _currentToken;
    }

    _refreshCompleter = Completer<void>();
    try {
      // Simulate network auth refresh
      await Future.delayed(const Duration(milliseconds: 50));
      _currentToken = 'refreshed_jwt_${DateTime.now().millisecondsSinceEpoch}';
      _expiresAt = DateTime.now().add(const Duration(minutes: 15));
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }

    return _currentToken;
  }
}

/// Enterprise Real-Time Event Bus & WebSocket Bridge (Laravel Echo Parity).
class EnterpriseEventBridge {
  final TokenAuthInterceptor _authInterceptor;
  final Set<String> _subscribedChannels = {};
  final StreamController<DomainEvent> _eventStreamController =
      StreamController<DomainEvent>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final Random _random = Random();
  bool _isDisposed = false;

  EnterpriseEventBridge({
    TokenAuthInterceptor? authInterceptor,
  }) : _authInterceptor = authInterceptor ?? TokenAuthInterceptor() {
    connect();
  }

  ConnectionStatus get status => _status;
  Stream<DomainEvent> get eventStream => _eventStreamController.stream;
  Set<String> get subscribedChannels => Set.unmodifiable(_subscribedChannels);

  /// Connects to the real-time event infrastructure.
  Future<void> connect() async {
    if (_status == ConnectionStatus.connected || _status == ConnectionStatus.connecting) {
      return;
    }

    _status = ConnectionStatus.connecting;
    try {
      final token = await _authInterceptor.getAuthorizationBearer();
      debugPrint('EventBridge connecting with bearer token: ${token.substring(0, 12)}...');

      // Simulated connection establishment
      await Future.delayed(const Duration(milliseconds: 100));

      _status = ConnectionStatus.connected;
      _reconnectAttempts = 0;
      _startHeartbeat();

      debugPrint('EnterpriseEventBridge connected successfully.');
    } catch (e) {
      _status = ConnectionStatus.disconnected;
      _scheduleReconnect();
    }
  }

  /// Subscribes to a specific channel (public-, private-, or presence-).
  Future<void> subscribe(String channel) async {
    if (channel.startsWith('private-') || channel.startsWith('presence-')) {
      // Auth verification through bearer interceptor
      await _authInterceptor.getAuthorizationBearer();
    }
    _subscribedChannels.add(channel);
    debugPrint('EnterpriseEventBridge subscribed to channel: $channel');
  }

  /// Unsubscribes from a channel.
  void unsubscribe(String channel) {
    _subscribedChannels.remove(channel);
    debugPrint('EnterpriseEventBridge unsubscribed from channel: $channel');
  }

  /// Ingests a raw push payload and dispatches a typed DomainEvent.
  void ingestPayload({
    required String channel,
    required String eventName,
    required Map<String, dynamic> data,
  }) {
    if (!_subscribedChannels.contains(channel) && !channel.startsWith('public-')) {
      return; // Ignore events on unsubscribed private channels
    }

    final domainEvent = DomainEvent.fromPayload(
      eventName: eventName,
      channel: channel,
      data: data,
    );

    _eventStreamController.add(domainEvent);
  }

  /// Maintains 25s heartbeat ping/pong cycle.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_status == ConnectionStatus.connected) {
        // Send heartbeat ping
        debugPrint('EnterpriseEventBridge: ping');
      }
    });
  }

  /// Exponential backoff with random jitter: min(30, 2^n + jitter).
  void _scheduleReconnect() {
    if (_isDisposed) return;

    _status = ConnectionStatus.reconnecting;
    _reconnectAttempts++;

    final exponentialDelay = min(30, pow(2, min(_reconnectAttempts, 5)).toInt());
    final jitter = _random.nextDouble() * 0.5; // Up to 500ms random jitter
    final delaySeconds = exponentialDelay + jitter;

    debugPrint(
      'EnterpriseEventBridge scheduled reconnect attempt #$_reconnectAttempts in ${delaySeconds.toStringAsFixed(1)}s',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: (delaySeconds * 1000).toInt()), () {
      connect();
    });
  }

  void disconnect() {
    _status = ConnectionStatus.disconnected;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventStreamController.close();
  }
}

// ─────────────────────────────────────────────
// RIVERPOD PROVIDERS
// ─────────────────────────────────────────────

final enterpriseEventBridgeProvider = Provider<EnterpriseEventBridge>((ref) {
  final bridge = EnterpriseEventBridge();
  // Auto-subscribe to standard private and presence channels
  bridge.subscribe('private-financial-ledger');
  bridge.subscribe('presence-system-audit');
  bridge.subscribe('public-announcements');

  ref.onDispose(() {
    bridge.dispose();
  });
  return bridge;
});

final domainEventStreamProvider = StreamProvider<DomainEvent>((ref) {
  final bridge = ref.watch(enterpriseEventBridgeProvider);
  return bridge.eventStream;
});
