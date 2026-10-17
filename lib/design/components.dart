import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../app/theme.dart';
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: raised ? t.palette.surfaceRaised : t.palette.surface,
        borderRadius: BorderRadius.circular(SolarRadius.card),
        border: Border.all(
          color: t.palette.separator,
          width: t.highContrast ? 2 : .5,
        ),
      ),
      child: Padding(padding: padding, child: child),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: SolarSpace.xs),
                Text(unit, style: Theme.of(context).textTheme.bodySmall),
              ],
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
    return Semantics(
      label: label,
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
            Icon(
              status == SolarStatus.critical
                  ? Icons.error_outline
                  : Icons.circle,
              size: 12,
              color: color,
            ),
            const SizedBox(width: SolarSpace.sm),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment(Icons.hub_outlined, gateway),
            _arrow(),
            _segment(Icons.cable, interfaceName),
            _arrow(),
            _segment(Icons.battery_charging_full, device),
            _arrow(),
            Text(profile),
            const SizedBox(width: SolarSpace.sm),
            ModeBadge(label: mode, status: SolarStatus.info),
          ],
        ),
      ),
    ),
  );
  Widget _segment(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: SolarSpace.xs),
      Text(text),
    ],
  );
  Widget _arrow() => const Icon(Icons.chevron_right, size: 16);
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
  Widget build(BuildContext context) => Semantics(
    label: 'Cell $index, ${voltage.toStringAsFixed(3)} volts',
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
          Text('$index', style: Theme.of(context).textTheme.labelSmall),
          Text(
            voltage.toStringAsFixed(3),
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text('V'),
        ],
      ),
    ),
  );
}

class CellGrid extends StatelessWidget {
  const CellGrid({required this.values, super.key});
  final List<double> values;
  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 110,
      mainAxisSpacing: SolarSpace.sm,
      crossAxisSpacing: SolarSpace.sm,
    ),
    itemCount: values.length,
    itemBuilder: (_, i) => CellTile(index: i + 1, voltage: values[i]),
  );
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 2),
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
    return Wrap(
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
    );
  }
}

class ModeBadge extends StatusPill {
  const ModeBadge({required super.label, required super.status, super.key});
}

class VerificationBadge extends StatusPill {
  const VerificationBadge({
    required super.label,
    required super.status,
    super.key,
  });
}

class SimulatedBadge extends StatelessWidget {
  const SimulatedBadge({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) =>
      StatusPill(label: label, status: SolarStatus.simulated);
}

class ConfidenceBadge extends StatusPill {
  const ConfidenceBadge({
    required super.label,
    required super.status,
    super.key,
  });
}

class RoleBadge extends StatusPill {
  const RoleBadge({required super.label, required super.status, super.key});
}

class SignedBadge extends StatusPill {
  const SignedBadge({required super.label, super.key})
    : super(status: SolarStatus.ok);
}

class EvidenceChip extends StatusPill {
  const EvidenceChip({required super.label, super.key})
    : super(status: SolarStatus.info);
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
            Icon(Icons.shield_outlined, color: color),
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
          Icon(
            Icons.inbox_outlined,
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

class DeltaBar extends SolarLabeledPanel {
  DeltaBar({required String label, required double value, super.key})
    : super(
        title: label,
        child: LinearProgressIndicator(value: value.clamp(0, 1)),
      );
}

class Sparkline extends SolarLabeledPanel {
  const Sparkline({required String label, super.key})
    : super(
        title: label,
        child: const SizedBox(
          height: 48,
          child: CustomPaint(painter: _SparkPainter()),
        ),
      );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF0071E3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .7)
        ..lineTo(size.width * .25, size.height * .4)
        ..lineTo(size.width * .5, size.height * .6)
        ..lineTo(size.width * .75, size.height * .2)
        ..lineTo(size.width, size.height * .35),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TrendChart extends Sparkline {
  const TrendChart({required super.label, super.key});
}

class ThermalMap extends SolarLabeledPanel {
  const ThermalMap({required String label, super.key})
    : super(title: label, child: const LinearProgressIndicator(value: .65));
}

class AlarmCard extends SafetyBanner {
  const AlarmCard({
    required super.title,
    required super.message,
    required super.status,
    super.key,
  });
}

class TimelineEvent extends SolarLabeledPanel {
  TimelineEvent({required super.title, required String detail, super.key})
    : super(child: Text(detail), compact: true);
}

class ParameterRow extends TimelineEvent {
  ParameterRow({required super.title, required super.detail, super.key});
}

class DiffReviewSheet extends SolarLabeledPanel {
  const DiffReviewSheet({
    required super.title,
    required super.child,
    super.key,
  });
}

class AuthorizationSheet extends DiffReviewSheet {
  const AuthorizationSheet({
    required super.title,
    required super.child,
    super.key,
  });
}

class ProfileCard extends TimelineEvent {
  ProfileCard({required super.title, required super.detail, super.key});
}

class LinkDiagram extends SolarLabeledPanel {
  const LinkDiagram({required super.title, super.key})
    : super(
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(Icons.battery_charging_full),
            Expanded(child: Divider()),
            Icon(Icons.solar_power),
          ],
        ),
      );
}

class ReportPreview extends SolarLabeledPanel {
  const ReportPreview({required super.title, required super.child, super.key});
}

class HexGrid extends SolarLabeledPanel {
  const HexGrid({required super.title, super.key})
    : super(
        child: const Text(
          '01 03 00 00 00 02',
          textDirection: TextDirection.ltr,
          style: TextStyle(fontFamily: 'JetBrains Mono'),
        ),
      );
}

class FieldOverlay extends TimelineEvent {
  FieldOverlay({required super.title, required super.detail, super.key});
}

class FrameTimeline extends TimelineEvent {
  FrameTimeline({required super.title, required super.detail, super.key});
}

class ConversationLane extends TimelineEvent {
  ConversationLane({required super.title, required super.detail, super.key});
}

class DiffView extends TimelineEvent {
  DiffView({required super.title, required super.detail, super.key});
}

class HypothesisCard extends TimelineEvent {
  HypothesisCard({required super.title, required super.detail, super.key});
}

class RedactionPreview extends TimelineEvent {
  RedactionPreview({required super.title, required super.detail, super.key});
}

class ConsentSheet extends DiffReviewSheet {
  const ConsentSheet({required super.title, required super.child, super.key});
}

class ContributionStatusStepper extends TimelineEvent {
  ContributionStatusStepper({
    required super.title,
    required super.detail,
    super.key,
  });
}

class LibraryUpdateCard extends TimelineEvent {
  LibraryUpdateCard({required super.title, required super.detail, super.key});
}

class RevokedBanner extends SafetyBanner {
  const RevokedBanner({required super.title, required super.message, super.key})
    : super(status: SolarStatus.critical);
}
