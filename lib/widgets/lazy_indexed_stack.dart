import 'package:flutter/material.dart';

/// A performance-optimized [IndexedStack] that defers building each child
/// until the first time its index is selected.
///
/// Once an index is visited, the child widget remains in the element tree,
/// preserving scroll positions, inputs, and internal state.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<WidgetBuilder> builders;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.builders,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List<bool>.filled(widget.builders.length, false);
    _markActive(widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.builders.length != _activated.length) {
      final newActivated = List<bool>.filled(widget.builders.length, false);
      for (var i = 0; i < newActivated.length; i++) {
        if (i < _activated.length) {
          newActivated[i] = _activated[i];
        }
      }
      _activated.clear();
      _activated.addAll(newActivated);
    }
    _markActive(widget.index);
  }

  void _markActive(int index) {
    if (index >= 0 && index < _activated.length) {
      _activated[index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: List.generate(widget.builders.length, (i) {
        if (_activated[i]) {
          return widget.builders[i](context);
        }
        return const SizedBox.shrink();
      }),
    );
  }
}
