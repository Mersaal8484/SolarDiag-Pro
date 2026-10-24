import 'package:flutter/material.dart';
import '../design/precision_ui.dart';

import '../app/theme.dart';
import '../l10n/generated/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int page = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final pages = [
      (
        Icons.energy_savings_leaf_outlined,
        s.onboardingPurpose,
        s.onboardingPurposeDetail,
      ),
      (Icons.shield_outlined, s.onboardingReadOnly, s.onboardingReadOnlyDetail),
      (Icons.cable, s.onboardingConnect, s.onboardingConnectDetail),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                key: const Key('onboarding-pages'),
                controller: controller,
                onPageChanged: (value) => setState(() => page = value),
                children: [
                  for (final item in pages)
                    _OnboardingPage(
                      icon: item.$1,
                      title: item.$2,
                      detail: item.$3,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Row(
                children: [
                  for (var i = 0; i < pages.length; i++) ...[
                    Container(
                      width: page == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: page == i ? SolarColors.green : SolarColors.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Spacer(),
                  FilledButton(
                    key: const Key('onboarding-next'),
                    onPressed: page == pages.length - 1
                        ? widget.onComplete
                        : () => controller.nextPage(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                          ),
                    child: Text(
                      page == pages.length - 1
                          ? s.startDiagnostics
                          : s.continueAction,
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E5D8C), Color(0xFF0C2A50)],
                ),
                border: Border.all(color: const Color(0xFF00D5FF), width: 1.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, size: 46, color: SolarColors.green),
            ),
            const SizedBox(height: 30),
            Text(
              'SOLARDIAG PRO',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: SolarColors.green,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 14),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}
