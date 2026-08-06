import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TvFocusDetector — wraps a widget, reports focus state, handles Select & D-Pad keys
// ─────────────────────────────────────────────────────────────────────────────

class TvFocusDetector extends StatefulWidget {
  final Widget Function(BuildContext context, bool isFocused) builder;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool autoScroll;
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;

  const TvFocusDetector({
    super.key,
    required this.builder,
    this.onSelect,
    this.focusNode,
    this.autofocus = false,
    this.autoScroll = true,
    this.onKeyEvent,
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

  @override
  void didUpdateWidget(TvFocusDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      } else {
        _focusNode.removeListener(_onFocusChange);
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) {
      final hasFocus = _focusNode.hasFocus;
      if (_isFocused != hasFocus) {
        setState(() => _isFocused = hasFocus);
      }

      if (hasFocus && widget.autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _focusNode.hasFocus) {
            try {
              Scrollable.ensureVisible(
                context,
                alignment: 0.5,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
              );
            } catch (_) {}
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
        if (widget.onKeyEvent != null) {
          final res = widget.onKeyEvent!(node, event);
          if (res != KeyEventResult.ignored) return res;
        }
        if (event is KeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.select ||
              key == LogicalKeyboardKey.enter ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.gameButtonA ||
              key == LogicalKeyboardKey.numpadEnter) {
            if (widget.onSelect != null) {
              widget.onSelect!();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.builder(context, _isFocused),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TvKeyboardShortcuts — global media / back key interceptor
// ─────────────────────────────────────────────────────────────────────────────

class TvKeyboardShortcuts extends StatefulWidget {
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
  State<TvKeyboardShortcuts> createState() => _TvKeyboardShortcutsState();
}

class _TvKeyboardShortcutsState extends State<TvKeyboardShortcuts> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(skipTraversal: true, debugLabel: 'TvKeyboardShortcuts');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.mediaPlayPause ||
              key == LogicalKeyboardKey.mediaPlay ||
              key == LogicalKeyboardKey.mediaPause) {
            widget.onPlayPause?.call();
            return;
          }
          if (key == LogicalKeyboardKey.mediaRewind) {
            widget.onSeekLeft?.call();
            return;
          }
          if (key == LogicalKeyboardKey.mediaFastForward) {
            widget.onSeekRight?.call();
            return;
          }
          if (key == LogicalKeyboardKey.escape ||
              key == LogicalKeyboardKey.backspace ||
              key == LogicalKeyboardKey.goBack) {
            widget.onBack?.call();
            return;
          }
        }
      },
      child: widget.child,
    );
  }
}

