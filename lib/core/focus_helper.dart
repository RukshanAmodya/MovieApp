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
              event.logicalKey == LogicalKeyboardKey.space) {
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

/// Creates a [FocusTraversalGroup] with [OrderedTraversalPolicy]
/// so D-pad navigates predictably through a grid.
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
