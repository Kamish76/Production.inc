import 'package:flutter/material.dart';

/// Defers building a Tab child until its index is selected for the first time.
/// Once loaded, keeps the child alive in memory across tab changes so
/// inputs and scroll offsets are preserved.
class LazyTabLoader extends StatefulWidget {
  final int index;
  final TabController? controller;
  final WidgetBuilder builder;

  const LazyTabLoader({
    super.key,
    required this.index,
    this.controller,
    required this.builder,
  });

  @override
  State<LazyTabLoader> createState() => _LazyTabLoaderState();
}

class _LazyTabLoaderState extends State<LazyTabLoader>
    with AutomaticKeepAliveClientMixin {
  TabController? _controller;
  bool _hasBeenLoaded = false;

  @override
  bool get wantKeepAlive => _hasBeenLoaded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController =
        widget.controller ?? DefaultTabController.maybeOf(context);
    if (_controller != newController) {
      _controller?.removeListener(_onTabChanged);
      _controller?.animation?.removeListener(_onTabChanged);
      _controller = newController;
      _controller?.addListener(_onTabChanged);
      _controller?.animation?.addListener(_onTabChanged);
      _checkActivation();
    }
  }

  @override
  void didUpdateWidget(LazyTabLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller?.removeListener(_onTabChanged);
      _controller?.animation?.removeListener(_onTabChanged);
      _controller =
          widget.controller ?? DefaultTabController.maybeOf(context);
      _controller?.addListener(_onTabChanged);
      _controller?.animation?.addListener(_onTabChanged);
    }
    _checkActivation();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    _controller?.animation?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() => _checkActivation();

  void _checkActivation() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (!_hasBeenLoaded && ctrl.index == widget.index) {
      if (mounted) {
        setState(() {
          _hasBeenLoaded = true;
        });
        updateKeepAlive();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_hasBeenLoaded) {
      final ctrl = _controller;
      if (ctrl != null && ctrl.index == widget.index) {
        _hasBeenLoaded = true;
      }
    }

    if (!_hasBeenLoaded) {
      return const SizedBox.shrink();
    }

    return widget.builder(context);
  }
}
