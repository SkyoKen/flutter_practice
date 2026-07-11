import 'dart:async';

import 'package:flutter/material.dart';

/// Shows short-lived app feedback near the top of the current screen.
class AppMessage {
  AppMessage._();

  static OverlayEntry? _currentEntry;

  static const double _maxWidth = 560;
  static const double _screenMargin = 12;

  static void show(
    BuildContext context, {
    required Widget content,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    _removeCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _AppMessageOverlay(
        backgroundColor: backgroundColor,
        disableAnimations: disableAnimations,
        duration: duration,
        onDismissed: () => _remove(entry),
        child: content,
      ),
    );
    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (!identical(_currentEntry, entry)) return;
    _currentEntry = null;
    entry.remove();
    entry.dispose();
  }

  static void _removeCurrent() {
    final entry = _currentEntry;
    if (entry == null) return;
    _currentEntry = null;
    entry.remove();
    entry.dispose();
  }
}

class _AppMessageOverlay extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool disableAnimations;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppMessageOverlay({
    required this.child,
    required this.backgroundColor,
    required this.disableAnimations,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppMessageOverlay> createState() => _AppMessageOverlayState();
}

class _AppMessageOverlayState extends State<_AppMessageOverlay> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, widget.onDismissed);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final snackBarTheme = theme.snackBarTheme;
    final backgroundColor = widget.backgroundColor ??
        snackBarTheme.backgroundColor ??
        theme.colorScheme.inverseSurface;
    final contentStyle = snackBarTheme.contentTextStyle ??
        TextStyle(
          color: theme.colorScheme.onInverseSurface,
          fontWeight: FontWeight.bold,
        );
    final shape = snackBarTheme.shape ??
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));
    final animationDuration = widget.disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 160);

    return Positioned(
      top: mediaQuery.padding.top + kToolbarHeight + AppMessage._screenMargin,
      left: AppMessage._screenMargin,
      right: AppMessage._screenMargin,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 48,
              maxWidth: AppMessage._maxWidth,
            ),
            child: Semantics(
              container: true,
              liveRegion: true,
              child: TweenAnimationBuilder<double>(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1 - value) * -12),
                      child: child,
                    ),
                  );
                },
                child: Material(
                  key: const ValueKey('app-message'),
                  color: backgroundColor,
                  elevation: snackBarTheme.elevation ?? 6,
                  shape: shape,
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: DefaultTextStyle(
                      style: contentStyle,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
