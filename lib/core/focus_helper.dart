import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// D-pad / TV remote key handler helper.
/// Wraps any widget with keyboard navigation and focus detection.
class TvFocusDetector extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autofocus;

  const TvFocusDetector({
    super.key,
    required this.builder,
    this.onSelect,
    this.focusNode,
    this.autofocus = false,
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
      setState(() => _isFocused = _focusNode.hasFocus);
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
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
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

/// Creates a [FocusTraversalGroup] with [ReadingOrderTraversalPolicy]
/// so D-pad navigates predictably through a grid left→right, top→bottom.
class TvGridFocusGroup extends StatelessWidget {
  final Widget child;
  const TvGridFocusGroup({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: child,
    );
  }
}

/// Global key event handler that intercepts D-pad arrow keys and
/// routes them to Flutter's focus system, and handles Back/Escape.
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

          switch (key) {
            case LogicalKeyboardKey.arrowUp:
              FocusManager.instance.primaryFocus
                  ?.focusInDirection(TraversalDirection.up);
              break;
            case LogicalKeyboardKey.arrowDown:
              FocusManager.instance.primaryFocus
                  ?.focusInDirection(TraversalDirection.down);
              break;
            case LogicalKeyboardKey.arrowLeft:
              if (onSeekLeft != null) {
                onSeekLeft!();
              } else {
                FocusManager.instance.primaryFocus
                    ?.focusInDirection(TraversalDirection.left);
              }
              break;
            case LogicalKeyboardKey.arrowRight:
              if (onSeekRight != null) {
                onSeekRight!();
              } else {
                FocusManager.instance.primaryFocus
                    ?.focusInDirection(TraversalDirection.right);
              }
              break;
            case LogicalKeyboardKey.select:
            case LogicalKeyboardKey.enter:
            case LogicalKeyboardKey.space:
            case LogicalKeyboardKey.gameButtonA:
              if (onPlayPause != null) {
                onPlayPause!();
              }
              break;
            case LogicalKeyboardKey.escape:
            case LogicalKeyboardKey.backspace:
            case LogicalKeyboardKey.goBack:
              onBack?.call();
              break;
            default:
              break;
          }
        }
      },
      child: child,
    );
  }
}
