import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] with FLAG_SECURE on Android, preventing screenshots
/// and screen recording on sensitive screens (Vault, Secure Notes, Biometrics).
///
/// On iOS, this uses the native secure field trick (UITextField.isSecureTextEntry)
/// via a platform channel. On other platforms it is a no-op pass-through.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const _channel = MethodChannel('com.lifehub.app/secure_screen');

  @override
  void initState() {
    super.initState();
    _setSecure(true);
  }

  @override
  void dispose() {
    _setSecure(false);
    super.dispose();
  }

  Future<void> _setSecure(bool secure) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } on MissingPluginException {
      // Plugin not registered in this build — safe to ignore
    } catch (_) {
      // Native call failed (e.g. test environment) — silently swallow
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
