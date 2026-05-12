import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// A lightweight connectivity service that detects network availability
/// and provides UI feedback when the user goes offline.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _timer;

  /// Start periodic connectivity checks (every 10 seconds)
  void startMonitoring() {
    _checkConnection();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _checkConnection());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (connected != _isOnline) {
        _isOnline = connected;
        _controller.add(_isOnline);
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
      }
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

/// A widget that wraps any screen and shows an offline banner
/// at the top when connectivity is lost.
class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().onConnectivityChanged,
      initialData: ConnectivityService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isOnline ? 0 : 32,
              color: Colors.red.shade700,
              child: isOnline
                  ? const SizedBox.shrink()
                  : const Center(
                      child: Text(
                        '⚠ No internet connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
