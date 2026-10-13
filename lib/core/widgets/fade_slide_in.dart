/// # FadeSlideIn
///
/// Entrance animation used by the dashboard: the child fades in while rising a
/// few pixels, after an optional [delay].
///
/// Grid items pass `delay: AppDimens.staggerStep * index` so the cards cascade.
/// The widget is index-agnostic, so a grid of two cards and a grid of twenty
/// behave identically.
library;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppDimens.medium,
    this.offset = 18,
  });

  final Widget child;

  /// How long to wait before starting.
  final Duration delay;

  /// How long the animation runs.
  final Duration duration;

  /// Vertical travel in logical pixels.
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
