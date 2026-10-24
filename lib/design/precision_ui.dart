import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Architectural heading for engineering workspaces. All labels are supplied
/// by the calling screen's existing localization, without changing the model.
class PrecisionPageHeading extends StatelessWidget {
  const PrecisionPageHeading({
    required this.title,
    this.subtitle,
    this.icon = Icons.memory_outlined,
    super.key,
  });
  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF172E51), Color(0xFF0D1B32), Color(0xFF10243E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF375477)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF00D5FF).withValues(alpha: .13),
              border: Border.all(
                color: const Color(0xFF00D5FF).withValues(alpha: .35),
              ),
            ),
            child: Icon(icon, color: const Color(0xFF00D5FF), size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOLARDIAG PRO  /  ENGINEERING',
                  style: TextStyle(
                    color: const Color(0xFF00D5FF).withValues(alpha: .9),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFF3F7FF),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFB8C9DF),
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

/// Pure visual accent for technical section headings; contents remain untouched.
class PrecisionSectionHeading extends StatelessWidget {
  const PrecisionSectionHeading({required this.label, super.key, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: Theme.of(context).extension<SolarTokens>()!.palette.tint,
        ),
      ),
      const SizedBox(width: 10),
      if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

/// A reusable high-contrast data label; unit/value supplied only by source.
class PrecisionReading extends StatelessWidget {
  const PrecisionReading({
    required this.label,
    required this.value,
    this.unit,
    this.status,
    super.key,
  });
  final String label, value;
  final String? unit;
  final Color? status;
  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<SolarTokens>()!.palette;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.separator),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: status ?? p.labelPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
