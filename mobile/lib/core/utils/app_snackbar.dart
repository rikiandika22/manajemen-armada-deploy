import 'dart:async';
import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class AppSnackBar {
  static OverlayEntry? _activeEntry;
  static Timer? _hideTimer;

  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    _show(context, message, type: SnackBarType.success, duration: duration);
  }

  static void showError(BuildContext context, String message, {Duration? duration}) {
    _show(context, message, type: SnackBarType.error, duration: duration);
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    _show(context, message, type: SnackBarType.warning, duration: duration);
  }

  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    _show(context, message, type: SnackBarType.info, duration: duration);
  }

  static void _show(
    BuildContext context,
    String message, {
    required SnackBarType type,
    Duration? duration,
  }) {
    if (!context.mounted) return;
    
    // Remove existing snackbar if any
    _activeEntry?.remove();
    _activeEntry = null;
    _hideTimer?.cancel();
    _hideTimer = null;

    final overlayState = Overlay.of(context);

    // Default duration based on type
    final displayDuration = duration ?? _getDefaultDuration(type);

    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) {
        return _AppSnackBarWidget(
          message: message,
          type: type,
          onDismiss: () {
            if (_activeEntry == entry) {
              _activeEntry?.remove();
              _activeEntry = null;
              _hideTimer?.cancel();
            }
          },
        );
      },
    );

    _activeEntry = entry;
    overlayState.insert(entry);

    // Schedule auto-dismiss
    _hideTimer = Timer(displayDuration, () {
      if (_activeEntry == entry) {
        _activeEntry?.remove();
        _activeEntry = null;
      }
    });
  }

  static Duration _getDefaultDuration(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
      case SnackBarType.info:
        return const Duration(seconds: 2);
      case SnackBarType.warning:
        return const Duration(seconds: 3);
      case SnackBarType.error:
        return const Duration(seconds: 4);
    }
  }
}

class _AppSnackBarWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;

  const _AppSnackBarWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AppSnackBarWidget> createState() => _AppSnackBarWidgetState();
}

class _AppSnackBarWidgetState extends State<_AppSnackBarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get colors based on type
    final Color bgColor;
    final Color borderColor;
    final Color iconColor;
    final IconData icon;

    switch (widget.type) {
      case SnackBarType.success:
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade300;
        iconColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case SnackBarType.error:
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        iconColor = Colors.red;
        icon = Icons.error;
        break;
      case SnackBarType.warning:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        iconColor = Colors.orange;
        icon = Icons.warning_rounded;
        break;
      case SnackBarType.info:
        bgColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        iconColor = Colors.blue;
        icon = Icons.info;
        break;
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12.0, // Just below the status bar
      left: 20.0,
      right: 20.0,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: GestureDetector(
              onTap: _dismiss,
              // Adding swipe up to dismiss
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -5) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
