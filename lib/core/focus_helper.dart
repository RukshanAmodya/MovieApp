import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// D-pad / TV remote key handler helper.
/// Wraps any widget with keyboard navigation, focus detection, and auto-scroll into view.
class TvFocusDetector extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool autoScroll;

  const TvFocusDetector({
    super.key,
    required this.builder,
    this.onSelect,
    this.focusNode,
    this.autofocus = false,
    this.autoScroll = true,
  });

  @override
  State<TvFocusDetector> createState() => _TvFocusDetectorState();
}

class _TvFocusDetectorState extends State<TvFocusDetector> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      final hasFocus = _focusNode.hasFocus;
      setState(() => _isFocused = hasFocus);

      if (hasFocus && widget.autoScroll) {
        // Auto-scroll focused item into view center for smooth TV remote navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusNode.hasFocus) {
            try {
              Scrollable.ensureVisible(
                context,
                alignment: 0.5,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            } catch (_) {
              // Ignore if not inside a Scrollable
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          // Handle all Android TV / TV Remote Select & Enter keys
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.numpadEnter) {
            widget.onSelect?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.builder(context, _isFocused),
    );
  }
}

/// Global key event handler that intercepts Media & Back keys for TV remotes.
class TvKeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onPlayPause;
  final VoidCallback? onSeekLeft;
  final VoidCallback? onSeekRight;

  const TvKeyboardShortcuts({
    super.key,
    required this.child,
    this.onBack,
    this.onPlayPause,
    this.onSeekLeft,
    this.onSeekRight,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          // Media Play/Pause Remote Buttons
          if (key == LogicalKeyboardKey.mediaPlayPause ||
              key == LogicalKeyboardKey.mediaPlay ||
              key == LogicalKeyboardKey.mediaPause) {
            onPlayPause?.call();
            return;
          }

          // Media Rewind / FastForward Remote Buttons
          if (key == LogicalKeyboardKey.mediaRewind) {
            onSeekLeft?.call();
            return;
          }
          if (key == LogicalKeyboardKey.mediaFastForward) {
            onSeekRight?.call();
            return;
          }

          // Back / Escape Remote Buttons
          if (key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.goBack) {
            onBack?.call();
            return;
          }
        }
      },
      child: child,
    );
  }
}
