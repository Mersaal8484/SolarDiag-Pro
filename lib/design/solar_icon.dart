import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'solar_icons.g.dart';
import 'tokens.g.dart';

/// Renders an icon from the generated SolarDiag icon catalog.
///
/// Only icons explicitly marked directional are mirrored in RTL layouts.
class SolarIcon extends StatelessWidget {
  const SolarIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final SolarIconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // SVG strokes use currentColor, which renders black without a filter and
    // disappears on dark surfaces; always resolve a theme-aware color.
    final resolved =
        color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    final picture = SvgPicture.asset(
      icon.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
    );
    final mirror =
        icon.directional &&
        Directionality.maybeOf(context) == TextDirection.rtl;
    return SizedBox.square(
      dimension: size,
      child: mirror
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(-1, 1, 1),
              child: picture,
            )
          : picture,
    );
  }
}

enum SolarAnimatedIconState { balancing, charging, linkPulse, scanning }

/// Motion-enhanced status icon with a static, fully legible fallback.
class SolarAnimatedIcon extends StatefulWidget {
  const SolarAnimatedIcon({
    required this.icon,
    required this.state,
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final SolarIconData icon;
  final SolarAnimatedIconState state;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  State<SolarAnimatedIcon> createState() => _SolarAnimatedIconState();
}

class _SolarAnimatedIconState extends State<SolarAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SolarMotion.springResponse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(
        reverse: widget.state != SolarAnimatedIconState.scanning,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = SolarIcon(
      widget.icon,
      size: widget.size,
      color: widget.color,
      semanticLabel: widget.semanticLabel,
    );
    if (MediaQuery.disableAnimationsOf(context)) return icon;
    return AnimatedBuilder(
      animation: _controller,
      child: icon,
      builder: (context, child) => switch (widget.state) {
        SolarAnimatedIconState.balancing => Transform.translate(
          offset: Offset((_controller.value - .5) * 5, 0),
          child: child,
        ),
        SolarAnimatedIconState.charging => Opacity(
          opacity: .45 + _controller.value * .55,
          child: child,
        ),
        SolarAnimatedIconState.linkPulse => Transform.scale(
          scale: .9 + _controller.value * .1,
          child: child,
        ),
        SolarAnimatedIconState.scanning => Transform.rotate(
          angle: _controller.value * 6.283185307179586,
          child: child,
        ),
      },
    );
  }
}
