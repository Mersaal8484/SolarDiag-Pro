import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/battery_models.dart';
import '../l10n/generated/app_localizations.dart';
import 'accessibility.dart';
import 'solar_icon.dart';
import 'solar_icons.g.dart';
import 'tokens.g.dart';

enum SolarStatus { ok, warning, critical, info, stale, simulated }

Color _statusColor(BuildContext context, SolarStatus status) {
  final p = Theme.of(context).extension<SolarTokens>()!.palette;
  return switch (status) {
    SolarStatus.ok => p.ok,
    SolarStatus.warning => p.warning,
    SolarStatus.critical => p.critical,
    SolarStatus.info || SolarStatus.stale => p.info,
    SolarStatus.simulated => p.simulated,
  };
}

class SolarSurface extends StatelessWidget {
  const SolarSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(SolarSpace.lg),
    this.raised = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<SolarTokens>()!;
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(SolarRadius.card),
      side: BorderSide(
        color: t.palette.separator,
        width: t.highContrast ? 2 : 1,
      ),
    );
    final surface = raised ? t.palette.surfaceRaised : t.palette.surface;
    final content = DecoratedBox(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [(raised ? t.palette.surfaceRaised : surface), surface],
        ),
        shape: shape,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (t.reduceTransparency) return content;
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: content,
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.updatedLabel,
    super.key,
    this.simulated = false,
  });
  final String label, value, unit, updatedLabel;
  final bool simulated;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label, $value $unit, $updatedLabel',
    child: SolarSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              if (simulated) const SimulatedBadge(label: 'SIMULATED'),
            ],
          ),
          const SizedBox(height: SolarSpace.sm),
          ExcludeSemantics(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        softWrap: true,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).extension<SolarTokens>()!.palette.tint,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                    ),
                    const SizedBox(width: SolarSpace.xs),
                    Text(unit, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: SolarSpace.xs),
          Text(updatedLabel, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class RingGauge extends StatelessWidget {
  const RingGauge({
    required this.value,
    required this.label,
    super.key,
    this.size = 148,
  });
  final double value, size;
  final String label;
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      value: '${(value * 100).round()} percent',
      label: label,
      child: TweenAnimationBuilder<double>(
        duration: reduce ? Duration.zero : SolarMotion.slow,
        tween: Tween(end: value.clamp(0, 1)),
        builder: (context, progress, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress,
              Theme.of(context).extension<SolarTokens>()!.palette,
            ),
            child: Center(
              child: Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.palette);
  final double value;
  final SolarPalette palette;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect.deflate(8),
      -.5 * math.pi,
      2 * math.pi,
      false,
      paint..color = palette.separator,
    );
    canvas.drawArc(
      rect.deflate(8),
      -.5 * math.pi,
      2 * math.pi * value,
      false,
      paint..color = palette.tint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.palette != palette;
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.status, super.key});
  final String label;
  final SolarStatus status;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    final symbol = switch (status) {
      SolarStatus.ok => '✓',
      SolarStatus.warning => '!',
      SolarStatus.critical => '×',
      SolarStatus.info => 'i',
      SolarStatus.stale => '…',
      SolarStatus.simulated => 'S',
    };
    return Semantics(
      label: label,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: SolarSpace.md,
          vertical: SolarSpace.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(SolarRadius.chip),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: const BoxConstraints.tightFor(width: 18, height: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: color),
                shape:
                    status == SolarStatus.critical ||
                        status == SolarStatus.warning
                    ? BoxShape.rectangle
                    : BoxShape.circle,
              ),
              child: Text(
                symbol,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: SolarSpace.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionCapsule extends StatelessWidget {
  const ConnectionCapsule({
    required this.gateway,
    required this.interfaceName,
    required this.device,
    required this.profile,
    required this.mode,
    super.key,
  });
  final String gateway, interfaceName, device, profile, mode;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$gateway, $interfaceName, $device, $profile, $mode',
    child: SolarSurface(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: SolarSpace.lg,
        vertical: SolarSpace.md,
      ),
      child: Wrap(
        spacing: SolarSpace.sm,
        runSpacing: SolarSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _segment(SolarIcons.gateway, gateway),
          _arrow(),
          _segment(SolarIcons.canBus, interfaceName),
          _arrow(),
          _segment(SolarIcons.battery, device),
          _arrow(),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(profile, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          ModeBadge(label: mode, status: SolarStatus.info),
        ],
      ),
    ),
  );
  Widget _segment(SolarIconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SolarIcon(icon, size: 16),
      const SizedBox(width: SolarSpace.xs),
      Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ],
  );
  Widget _arrow() => const SolarIcon(SolarIcons.currentFlow, size: 16);
}

class CellTile extends StatelessWidget {
  const CellTile({
    required this.index,
    required this.voltage,
    super.key,
    this.highlight = false,
  });
  final int index;
  final double voltage;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = localizedNumber(context, voltage, fractionDigits: 3);
    return Semantics(
      label: l10n.cellVoltageValue(index, value),
      child: Container(
        padding: const EdgeInsets.all(SolarSpace.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SolarRadius.control),
          border: Border.all(
            color: highlight
                ? Theme.of(context).extension<SolarTokens>()!.palette.warning
                : Theme.of(context).extension<SolarTokens>()!.palette.separator,
            width: highlight ? 2 : .5,
          ),
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  localizedNumber(context, index, fractionDigits: 0),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.voltageUnit)),
          ],
        ),
      ),
    );
  }
}

class CellGrid extends StatelessWidget {
  const CellGrid({required this.values, super.key});
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 2);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisExtent: 124 + ((textScale - 1) * 80),
          mainAxisSpacing: SolarSpace.sm,
          crossAxisSpacing: SolarSpace.sm,
        ),
        itemCount: values.length,
        itemBuilder: (_, i) => CellTile(index: i + 1, voltage: values[i]),
      ),
    );
  }
}

class CellBarChart extends StatelessWidget {
  const CellBarChart({required this.values, super.key});
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    return SizedBox(
      height: 150,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    height:
                        30 +
                        110 * ((values[i] - min) / math.max(.001, max - min)),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).extension<SolarTokens>()!.palette.tint,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CellHeatmap extends StatelessWidget {
  const CellHeatmap({required this.values, super.key});
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final p = Theme.of(context).extension<SolarTokens>()!.palette;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < values.length; i++)
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color.lerp(
                  p.info,
                  p.warning,
                  (values[i] - min) / math.max(.001, max - min),
                ),
                borderRadius: BorderRadius.circular(SolarRadius.chip),
                border: (values[i] == min || values[i] == max)
                    ? Border.all(color: p.labelPrimary, width: 2)
                    : null,
              ),
              child: Text('${i + 1}'),
            ),
        ],
      ),
    );
  }
}

class ModeBadge extends StatelessWidget {
  const ModeBadge({required this.label, required this.status, super.key});
  final String label;
  final SolarStatus status;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: status);
}

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({
    required this.label,
    required this.status,
    super.key,
  });
  final String label;
  final SolarStatus status;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: status);
}

class SimulatedBadge extends StatelessWidget {
  const SimulatedBadge({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: SolarStatus.simulated);
}

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({required this.label, required this.status, super.key});
  final String label;
  final SolarStatus status;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: status);
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({required this.label, required this.status, super.key});
  final String label;
  final SolarStatus status;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: status);
}

class SignedBadge extends StatelessWidget {
  const SignedBadge({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: SolarStatus.ok);
}

class EvidenceChip extends StatelessWidget {
  const EvidenceChip({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: SolarStatus.info);
}

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({
    required this.title,
    required this.message,
    required this.status,
    super.key,
  });
  final String title, message;
  final SolarStatus status;
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(SolarSpace.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          border: BorderDirectional(start: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(SolarRadius.control),
        ),
        child: Row(
          children: [
            SolarIcon(SolarIcons.readOnly, color: color),
            const SizedBox(width: SolarSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({super.key, this.height = 80});
  final double height;
  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock> {
  @override
  Widget build(BuildContext context) => Container(
    height: widget.height,
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).extension<SolarTokens>()!.palette.separator.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(SolarRadius.card),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.message, super.key});
  final String title, message;
  @override
  Widget build(BuildContext context) => SolarSurface(
    child: Padding(
      padding: const EdgeInsets.all(SolarSpace.xxl),
      child: Column(
        children: [
          SolarIcon(
            SolarIcons.library,
            size: 42,
            color: Theme.of(
              context,
            ).extension<SolarTokens>()!.palette.labelSecondary,
          ),
          const SizedBox(height: SolarSpace.md),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class SolarLabeledPanel extends StatelessWidget {
  const SolarLabeledPanel({
    required this.title,
    required this.child,
    super.key,
    this.compact = false,
  });
  final String title;
  final Widget child;
  final bool compact;
  @override
  Widget build(BuildContext context) => SolarSurface(
    padding: EdgeInsets.all(compact ? SolarSpace.md : SolarSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: SolarSpace.md),
        child,
      ],
    ),
  );
}

class DeltaBar extends StatelessWidget {
  const DeltaBar({
    required this.label,
    required this.value,
    super.key,
    this.valueLabel,
    this.warningThreshold = .75,
  });

  final String label;
  final double value;
  final String? valueLabel;
  final double warningThreshold;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0);
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final color = normalized >= warningThreshold ? palette.warning : palette.ok;
    return Semantics(
      label: '$label, ${valueLabel ?? normalized.toStringAsFixed(2)}',
      child: SolarLabeledPanel(
        title: label,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(SolarRadius.chip),
              child: LinearProgressIndicator(
                value: normalized,
                color: color,
                minHeight: 10,
              ),
            ),
            if (valueLabel != null) ...[
              const SizedBox(height: SolarSpace.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(valueLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.label,
    required this.measurements,
    super.key,
    this.color,
  });

  final String label;
  final List<Measurement> measurements;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final reverseTime =
        !(DesignPreferenceScope.maybeOf(context)?.timeAxisLtr ?? true);
    final reported = measurements.where((item) => item.isReported).toList();
    final range = reported.isEmpty
        ? null
        : (
            reported.map((item) => item.value!).reduce(math.min),
            reported.map((item) => item.value!).reduce(math.max),
          );
    return Semantics(
      label: '$label, ${reported.length} of ${measurements.length} samples',
      child: SolarLabeledPanel(
        title: label,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparkPainter(
              points: measurements.map((item) => item.value).toList(),
              min: range?.$1,
              max: range?.$2,
              color: color ?? palette.tint,
              reverseTime: reverseTime,
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.points,
    required this.color,
    required this.reverseTime,
    this.min,
    this.max,
  });
  final List<double?> points;
  final double? min;
  final double? max;
  final Color color;
  final bool reverseTime;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || min == null || max == null) return;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    var drawing = false;
    final span = math.max(max! - min!, .000001);
    for (var i = 0; i < points.length; i++) {
      final value = points[i];
      if (value == null) {
        drawing = false;
        continue;
      }
      final progress = points.length <= 1 ? 0.0 : i / (points.length - 1);
      final x = points.length <= 1
          ? 0.0
          : size.width * (reverseTime ? 1 - progress : progress);
      final y = size.height * (1 - ((value - min!) / span));
      if (!drawing) {
        path.moveTo(x, y);
        drawing = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.reverseTime != reverseTime;
}

class TrendChart extends StatelessWidget {
  const TrendChart({
    required this.label,
    required this.measurements,
    super.key,
  });

  final String label;
  final List<Measurement> measurements;

  @override
  Widget build(BuildContext context) {
    final values = measurements
        .where((item) => item.isReported)
        .map((item) => item.value!)
        .toList();
    final unit = measurements
        .map((item) => item.unit)
        .whereType<String>()
        .firstOrNull;
    final minimum = values.isEmpty ? null : values.reduce(math.min);
    final maximum = values.isEmpty ? null : values.reduce(math.max);
    return SolarLabeledPanel(
      title: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Sparkline(label: label, measurements: measurements),
          const SizedBox(height: SolarSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                minimum == null
                    ? '—'
                    : '${minimum.toStringAsFixed(1)} ${unit ?? ''}',
              ),
              Text(
                maximum == null
                    ? '—'
                    : '${maximum.toStringAsFixed(1)} ${unit ?? ''}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ThermalMap extends StatelessWidget {
  const ThermalMap({
    required this.label,
    required this.readings,
    super.key,
    this.columns = 4,
  });

  final String label;
  final List<TemperatureReading> readings;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final values = readings
        .where((item) => item.measurement.isReported)
        .map((item) => item.measurement.value!)
        .toList();
    final minimum = values.isEmpty ? null : values.reduce(math.min);
    final maximum = values.isEmpty ? null : values.reduce(math.max);
    return SolarLabeledPanel(
      title: label,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: math.max(1, columns),
          mainAxisSpacing: SolarSpace.sm,
          crossAxisSpacing: SolarSpace.sm,
        ),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final reading = readings[index];
          final value = reading.measurement.value;
          final span = math.max((maximum ?? 0) - (minimum ?? 0), .000001);
          final fraction = value == null ? null : (value - minimum!) / span;
          final tileColor = fraction == null
              ? palette.separator
              : Color.lerp(palette.info, palette.warning, fraction)!;
          final marker = value == minimum
              ? 'MIN'
              : value == maximum
              ? 'MAX'
              : null;
          return Semantics(
            label: value == null
                ? '${reading.label}, absent'
                : '${reading.label}, ${value.toStringAsFixed(1)} ${reading.measurement.unit ?? ''}${marker == null ? '' : ', $marker'}',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: .18),
                border: Border.all(color: tileColor),
                borderRadius: BorderRadius.circular(SolarRadius.control),
              ),
              child: Center(
                child: Text(
                  value == null
                      ? '${reading.label}\n—'
                      : '${reading.label}\n${value.toStringAsFixed(1)}°${marker == null ? '' : '\n$marker'}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlarmCard extends StatelessWidget {
  const AlarmCard({
    required this.title,
    required this.message,
    required this.status,
    super.key,
  });

  final String title;
  final String message;
  final SolarStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Semantics(
      liveRegion: true,
      label: '$title, $message',
      child: SolarSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: color,
                shape: status == SolarStatus.critical
                    ? BoxShape.rectangle
                    : BoxShape.circle,
              ),
            ),
            const SizedBox(width: SolarSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: SolarSpace.xs),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineEvent extends StatelessWidget {
  const TimelineEvent({
    required this.title,
    required this.detail,
    super.key,
    this.timestampLabel,
    this.status = SolarStatus.info,
  });

  final String title;
  final String detail;
  final String? timestampLabel;
  final SolarStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, status);
    return Semantics(
      label: [title, detail, timestampLabel].whereType<String>().join(', '),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Container(
                width: 1,
                height: 42,
                color: color.withValues(alpha: .35),
              ),
            ],
          ),
          const SizedBox(width: SolarSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: SolarSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(detail),
                  if (timestampLabel != null)
                    Text(
                      timestampLabel!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParameterRow extends StatelessWidget {
  const ParameterRow({
    required this.title,
    required this.detail,
    super.key,
    this.unit,
    this.editable = false,
    this.editableLabel,
    this.enabled = true,
    this.onTap,
  }) : assert(!editable || editableLabel != null);

  final String title;
  final String detail;
  final String? unit;
  final bool editable;
  final String? editableLabel;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$title, $detail ${unit ?? ''}',
    enabled: enabled,
    button: editable,
    child: ListTile(
      enabled: enabled,
      title: Text(title),
      subtitle: editable ? Text(editableLabel!) : null,
      trailing: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          '$detail${unit == null ? '' : ' $unit'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      onTap: editable && enabled ? onTap : null,
    ),
  );
}

class DiffReviewItem {
  const DiffReviewItem({
    required this.label,
    required this.before,
    required this.after,
    this.validationMessage,
    this.destructive = false,
  });

  final String label;
  final String before;
  final String after;
  final String? validationMessage;
  final bool destructive;
}

class DiffReviewSheet extends StatelessWidget {
  const DiffReviewSheet({
    required this.title,
    required this.items,
    required this.confirmLabel,
    required this.cancelLabel,
    super.key,
    this.stepLabels = const [],
    this.currentStep = 0,
    this.loading = false,
    this.onConfirm,
    this.onCancel,
  });

  final String title;
  final List<DiffReviewItem> items;
  final List<String> stepLabels;
  final int currentStep;
  final String confirmLabel;
  final String cancelLabel;
  final bool loading;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return SolarLabeledPanel(
      title: title,
      child: Column(
        children: [
          if (stepLabels.isNotEmpty)
            Wrap(
              spacing: SolarSpace.sm,
              runSpacing: SolarSpace.sm,
              children: [
                for (var i = 0; i < stepLabels.length; i++)
                  StatusPill(
                    label: '${i + 1}. ${stepLabels[i]}',
                    status: i < currentStep
                        ? SolarStatus.ok
                        : i == currentStep
                        ? SolarStatus.info
                        : SolarStatus.stale,
                  ),
              ],
            ),
          if (stepLabels.isNotEmpty) const SizedBox(height: SolarSpace.md),
          for (final item in items)
            Container(
              padding: const EdgeInsets.symmetric(vertical: SolarSpace.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.separator)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.destructive ? palette.critical : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(item.before)),
                      const Text('→'),
                      Expanded(
                        child: Text(item.after, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                  if (item.validationMessage != null)
                    Text(
                      item.validationMessage!,
                      style: TextStyle(color: palette.critical),
                    ),
                ],
              ),
            ),
          const SizedBox(height: SolarSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: loading ? null : onCancel,
                child: Text(cancelLabel),
              ),
              const SizedBox(width: SolarSpace.sm),
              FilledButton(
                onPressed:
                    loading ||
                        items.any((item) => item.validationMessage != null)
                    ? null
                    : onConfirm,
                child: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(confirmLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AuthorizationSheet extends StatelessWidget {
  const AuthorizationSheet({
    required this.title,
    required this.message,
    required this.actionLabel,
    super.key,
    this.errorMessage,
    this.loading = false,
    this.onAuthorize,
  });

  final String title;
  final String message;
  final String actionLabel;
  final String? errorMessage;
  final bool loading;
  final VoidCallback? onAuthorize;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return SolarLabeledPanel(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message),
          if (errorMessage != null) ...[
            const SizedBox(height: SolarSpace.sm),
            Text(errorMessage!, style: TextStyle(color: palette.critical)),
          ],
          const SizedBox(height: SolarSpace.md),
          FilledButton(
            onPressed: loading ? null : onAuthorize,
            child: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.title,
    required this.detail,
    required this.verificationLabel,
    required this.status,
    super.key,
    this.onTap,
  });

  final String title;
  final String detail;
  final String verificationLabel;
  final SolarStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '$title, $detail, $verificationLabel',
    child: SolarSurface(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(detail),
                ],
              ),
            ),
            VerificationBadge(label: verificationLabel, status: status),
          ],
        ),
      ),
    ),
  );
}

enum LinkLegState { healthy, timeout, offline }

class LinkDiagram extends StatelessWidget {
  const LinkDiagram({
    required this.title,
    required this.inverterLabel,
    required this.linkLabel,
    required this.batteryLabel,
    required this.inverterLeg,
    required this.batteryLeg,
    super.key,
  });

  final String title;
  final String inverterLabel;
  final String linkLabel;
  final String batteryLabel;
  final LinkLegState inverterLeg;
  final LinkLegState batteryLeg;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    Widget leg(LinkLegState state) {
      final color = switch (state) {
        LinkLegState.healthy => palette.ok,
        LinkLegState.timeout => palette.warning,
        LinkLegState.offline => palette.critical,
      };
      final symbol = switch (state) {
        LinkLegState.healthy => '───',
        LinkLegState.timeout => '─ · ─',
        LinkLegState.offline => '─ × ─',
      };
      return Expanded(
        child: Semantics(
          label: state.name,
          child: state == LinkLegState.healthy
              ? SolarAnimatedIcon(
                  icon: SolarIcons.currentFlow,
                  state: SolarAnimatedIconState.linkPulse,
                  color: color,
                )
              : Text(
                  symbol,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
        ),
      );
    }

    Widget node(String value) => Flexible(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.separator),
          borderRadius: BorderRadius.circular(SolarRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SolarSpace.sm),
          child: Text(value, textAlign: TextAlign.center),
        ),
      ),
    );

    return SolarLabeledPanel(
      title: title,
      child: Semantics(
        label:
            '$inverterLabel, ${inverterLeg.name}, $linkLabel, ${batteryLeg.name}, $batteryLabel',
        child: Row(
          children: [
            node(inverterLabel),
            leg(inverterLeg),
            node(linkLabel),
            leg(batteryLeg),
            node(batteryLabel),
          ],
        ),
      ),
    );
  }
}

class ReportPreview extends StatelessWidget {
  const ReportPreview({
    required this.title,
    required this.child,
    super.key,
    this.pageLabel,
  });

  final String title;
  final Widget child;
  final String? pageLabel;

  @override
  Widget build(BuildContext context) => SolarLabeledPanel(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pageLabel != null)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              pageLabel!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        AspectRatio(
          aspectRatio: 1 / math.sqrt(2),
          child: SolarSurface(raised: true, child: child),
        ),
      ],
    ),
  );
}

class HexFieldOverlay {
  const HexFieldOverlay({
    required this.start,
    required this.length,
    required this.label,
    required this.color,
  });

  final int start;
  final int length;
  final String label;
  final Color color;

  bool contains(int offset) => offset >= start && offset < start + length;
}

class HexGrid extends StatelessWidget {
  const HexGrid({
    required this.title,
    required this.bytes,
    super.key,
    this.overlays = const [],
    this.selectedOffset,
    this.bytesPerRow = 16,
    this.onSelected,
  });

  final String title;
  final Uint8List bytes;
  final List<HexFieldOverlay> overlays;
  final int? selectedOffset;
  final int bytesPerRow;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final rowCount = (bytes.length / bytesPerRow).ceil();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SolarLabeledPanel(
        title: title,
        child: SizedBox(
          height: math.min(320, math.max(48, rowCount * 30)).toDouble(),
          child: ListView.builder(
            itemExtent: 30,
            itemCount: rowCount,
            itemBuilder: (context, row) {
              final start = row * bytesPerRow;
              final end = math.min(start + bytesPerRow, bytes.length);
              final rowBytes = bytes.sublist(start, end);
              final ascii = rowBytes
                  .map(
                    (value) => value >= 32 && value <= 126
                        ? String.fromCharCode(value)
                        : '.',
                  )
                  .join();
              return Row(
                children: [
                  SizedBox(
                    width: 66,
                    child: Text(
                      start.toRadixString(16).padLeft(6, '0').toUpperCase(),
                      style: const TextStyle(fontFamily: 'JetBrains Mono'),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      children: [
                        for (var i = 0; i < rowBytes.length; i++)
                          Builder(
                            builder: (context) {
                              final offset = start + i;
                              final overlay = overlays
                                  .where((item) => item.contains(offset))
                                  .firstOrNull;
                              return Semantics(
                                label:
                                    'Offset $offset, ${rowBytes[i]}, ${overlay?.label ?? 'unmapped'}',
                                button: onSelected != null,
                                child: InkWell(
                                  onTap: onSelected == null
                                      ? null
                                      : () => onSelected!(offset),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: selectedOffset == offset
                                          ? palette.tint.withValues(alpha: .22)
                                          : overlay?.color.withValues(
                                              alpha: .16,
                                            ),
                                      border: overlay == null
                                          ? null
                                          : Border(
                                              bottom: BorderSide(
                                                color: overlay.color,
                                              ),
                                            ),
                                    ),
                                    child: Text(
                                      rowBytes[i]
                                          .toRadixString(16)
                                          .padLeft(2, '0')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: bytesPerRow * 9,
                    child: Text(
                      ascii,
                      style: const TextStyle(fontFamily: 'JetBrains Mono'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class FieldOverlay extends StatelessWidget {
  const FieldOverlay({
    required this.title,
    required this.detail,
    super.key,
    this.color,
  });
  final String title;
  final String detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective =
        color ?? Theme.of(context).extension<SolarTokens>()!.palette.info;
    return Semantics(
      label: '$title, $detail',
      child: Container(
        padding: const EdgeInsets.all(SolarSpace.sm),
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: effective, width: 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(detail),
          ],
        ),
      ),
    );
  }
}

class FrameTimeline extends StatelessWidget {
  const FrameTimeline({
    required this.title,
    required this.detail,
    super.key,
    this.active = false,
  });
  final String title;
  final String detail;
  final bool active;

  @override
  Widget build(BuildContext context) => TimelineEvent(
    title: title,
    detail: detail,
    status: active ? SolarStatus.ok : SolarStatus.stale,
  );
}

class ConversationLane extends StatelessWidget {
  const ConversationLane({
    required this.title,
    required this.detail,
    super.key,
    this.response = false,
  });
  final String title;
  final String detail;
  final bool response;

  @override
  Widget build(BuildContext context) => Align(
    alignment: response
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: FractionallySizedBox(
      widthFactor: .78,
      child: SolarLabeledPanel(title: title, child: TechnicalText(detail)),
    ),
  );
}

class DiffView extends StatelessWidget {
  const DiffView({
    required this.title,
    required this.detail,
    super.key,
    this.previousLabel,
    this.currentLabel,
  });
  final String title;
  final String detail;
  final String? previousLabel;
  final String? currentLabel;

  @override
  Widget build(BuildContext context) => SolarLabeledPanel(
    title: title,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(previousLabel ?? detail)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: SolarSpace.sm),
          child: Text('→'),
        ),
        Expanded(child: Text(currentLabel ?? detail)),
      ],
    ),
  );
}

class HypothesisCard extends StatelessWidget {
  const HypothesisCard({
    required this.title,
    required this.detail,
    super.key,
    this.confidence,
    this.evidenceLabels = const [],
  });
  final String title;
  final String detail;
  final double? confidence;
  final List<String> evidenceLabels;

  @override
  Widget build(BuildContext context) => SolarLabeledPanel(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail),
        if (confidence != null) ...[
          const SizedBox(height: SolarSpace.sm),
          LinearProgressIndicator(value: confidence!.clamp(0, 1)),
        ],
        if (evidenceLabels.isNotEmpty) ...[
          const SizedBox(height: SolarSpace.sm),
          Wrap(
            spacing: SolarSpace.sm,
            children: [
              for (final label in evidenceLabels) EvidenceChip(label: label),
            ],
          ),
        ],
      ],
    ),
  );
}

class RedactionPreview extends StatelessWidget {
  const RedactionPreview({
    required this.title,
    required this.detail,
    super.key,
    this.redactedRanges = const [],
  });
  final String title;
  final String detail;
  final List<TextRange> redactedRanges;

  @override
  Widget build(BuildContext context) {
    var preview = detail;
    for (final range in redactedRanges.reversed) {
      if (range.start >= 0 &&
          range.end <= preview.length &&
          range.start <= range.end) {
        preview = preview.replaceRange(
          range.start,
          range.end,
          List.filled(range.end - range.start, '█').join(),
        );
      }
    }
    return SolarLabeledPanel(title: title, child: TechnicalText(preview));
  }
}

class ConsentSheet extends StatelessWidget {
  const ConsentSheet({
    required this.title,
    required this.message,
    required this.confirmLabel,
    super.key,
    this.accepted = false,
    this.onAcceptedChanged,
    this.onConfirm,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final bool accepted;
  final ValueChanged<bool>? onAcceptedChanged;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) => SolarLabeledPanel(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: accepted,
          title: Text(message),
          onChanged: onAcceptedChanged == null
              ? null
              : (value) => onAcceptedChanged!(value ?? false),
        ),
        FilledButton(
          onPressed: accepted ? onConfirm : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class ContributionStatusStepper extends StatelessWidget {
  const ContributionStatusStepper({
    required this.title,
    required this.detail,
    super.key,
    this.steps = const [],
    this.currentStep = 0,
  });
  final String title;
  final String detail;
  final List<String> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) => SolarLabeledPanel(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail),
        const SizedBox(height: SolarSpace.sm),
        for (var i = 0; i < steps.length; i++)
          TimelineEvent(
            title: steps[i],
            detail: '${i + 1}/${steps.length}',
            status: i < currentStep
                ? SolarStatus.ok
                : i == currentStep
                ? SolarStatus.info
                : SolarStatus.stale,
          ),
      ],
    ),
  );
}

class LibraryUpdateCard extends StatelessWidget {
  const LibraryUpdateCard({
    required this.title,
    required this.detail,
    super.key,
    this.actionLabel,
    this.onApply,
    this.loading = false,
  });
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onApply;
  final bool loading;

  @override
  Widget build(BuildContext context) => SolarSurface(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(detail),
            ],
          ),
        ),
        if (actionLabel != null)
          FilledButton(
            onPressed: loading ? null : onApply,
            child: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionLabel!),
          ),
      ],
    ),
  );
}

class RevokedBanner extends SafetyBanner {
  const RevokedBanner({required super.title, required super.message, super.key})
    : super(status: SolarStatus.critical);
}
