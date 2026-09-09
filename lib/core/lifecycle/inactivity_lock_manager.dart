import 'dart:async';
import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';

/// Manages application background lifecycle and in-app user inactivity.
/// Automatically executes the lock callback when:
/// 1. The app has been in the background/paused for > 2 minutes (120s).
/// 2. User has been inactive within the app for > 2 minutes (120s).
class InactivityLockManager with WidgetsBindingObserver {
  InactivityLockManager({
    required this.onLockTriggered,
    this.timeoutSeconds = AppConstants.autoLockTimeoutSeconds,
  });

  final VoidCallback onLockTriggered;
  final int timeoutSeconds;

  Timer? _inactivityTimer;
  DateTime? _pausedTimestamp;
  bool _isTracking = false;

  void start() {
    if (_isTracking) return;
    _isTracking = true;
    WidgetsBinding.instance.addObserver(this);
    resetTimer();
  }

  void stop() {
    if (!_isTracking) return;
    _isTracking = false;
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _pausedTimestamp = null;
  }

  /// Call whenever user interacts with the app (touch, keyboard, navigation)
  void recordUserActivity() {
    if (!_isTracking) return;
    resetTimer();
  }

  void resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: timeoutSeconds), () {
      onLockTriggered();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isTracking) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedTimestamp ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTimestamp != null) {
        final elapsed = DateTime.now().difference(_pausedTimestamp!).inSeconds;
        _pausedTimestamp = null;
        if (elapsed >= timeoutSeconds) {
          onLockTriggered();
          return;
        }
      }
      resetTimer();
    }
  }

  void dispose() {
    stop();
  }
}
