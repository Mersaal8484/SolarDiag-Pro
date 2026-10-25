import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/generated/app_localizations.dart';
import 'solar_icon.dart';
import 'solar_icons.g.dart';

/// Shared page architecture for the premium diagnostic workspaces.
/// Titles, descriptions and readings are supplied by the original screens.
/// This widget does not interact with the device session or business logic.
class PrecisionPageHeading extends StatelessWidget {
  const PrecisionPageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = SolarIcons.evidence,
  });

  final String title;
  final String? subtitle;
  final SolarIconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 23),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF1A3556), Color(0xFF10253F), Color(0xFF0C1B32)],
          stops: [0, .54, 1],
        ),
        border: Border.all(color: const Color(0xFF365475), width: 1),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 12),
            color: const Color(0xFF030812).withValues(alpha: .22),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF00D5FF).withValues(alpha: .12),
              border: Border.all(
                color: const Color(0xFF00D5FF).withValues(alpha: .35),
              ),
            ),
            child: SolarIcon(icon, color: const Color(0xFF00D5FF), size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SOLARDIAG PRO  /  ENGINEERING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: palette.tint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFF4F8FF),
                    fontWeight: FontWeight.w800,
                    height: 1.24,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFBDCEE2),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// High-contrast and balanced headings for sections of technical data.
class PrecisionSectionHeading extends StatelessWidget {
  const PrecisionSectionHeading({super.key, required this.label, this.icon});

  final String label;
  final SolarIconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Row(
      children: [
        Container(
          width: 4,
          height: 23,
          decoration: BoxDecoration(
            color: palette.tint,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 12),
        if (icon != null) ...[
          SolarIcon(icon!, color: palette.tint, size: 21),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Information tile with a purely visual treatment and no fabricated values.
class PrecisionReading extends StatelessWidget {
  const PrecisionReading({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.freshness,
  });
  final String label;
  final String value;
  final Color? accent;
  final String? freshness;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final semanticsLabel = '$label, $value, '
        '${freshness ?? AppLocalizations.of(context).updatedNow}';
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.surfaceRaised, palette.surface],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: palette.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent ?? palette.tint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                softWrap: true,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent ?? palette.labelPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

/// Keeps the existing child, labels and callbacks, only changing presentation.
class PrecisionPanel extends StatelessWidget {
  const PrecisionPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [palette.surfaceRaised, palette.surface],
        ),
        border: Border.all(color: palette.separator),
      ),
      child: child,
    );
  }
}

/// Unified instrument surface for every feature, including nested studio pages.
/// All original children (labels, actions, models) are passed through untouched.
class PrecisionCard extends StatelessWidget {
  const PrecisionCard({
    super.key,
    required this.child,
    this.clipBehavior = Clip.none,
    this.margin,
  });

  final Widget child;
  final Clip clipBehavior;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<SolarTokens>()!.palette;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(20);
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: palette.separator.withValues(alpha: .9)),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            palette.surfaceRaised.withValues(alpha: isDark ? .84 : .72),
            palette.surface,
          ],
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFF030812).withValues(alpha: .17),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ]
            : const [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
    return Padding(padding: margin ?? const EdgeInsets.all(4), child: content);
  }
}

/// Underlay for page navigation: calm precision-grid detailing, no touch capture.
/// The content itself remains the original screen and controls.
class PrecisionCanvas extends StatelessWidget {
  const PrecisionCanvas({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            dark ? const Color(0xFF0D1B30) : const Color(0xFFF2F7FC),
            palette.background,
            palette.background,
          ],
          stops: const [0, .4, 1],
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (dark)
              PositionedDirectional(
                end: -90,
                top: -110,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          palette.tint.withValues(alpha: .065),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

/// Reusable label/value cell for technical values in sections and forms.
/// It deliberately avoids interpreting measurements or units.
class PrecisionValueStrip extends StatelessWidget {
  const PrecisionValueStrip({
    super.key,
    required this.label,
    required this.value,
    this.icon = SolarIcons.evidence,
    this.warning = false,
  });
  final String label;
  final String value;
  final SolarIconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final accent = warning ? palette.warning : palette.tint;
    return PrecisionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SolarIcon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        value,
                        softWrap: true,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: palette.labelPrimary,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
