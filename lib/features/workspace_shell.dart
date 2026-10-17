import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../core/battery_models.dart';
import '../integration/compatibility_engine.dart';
import '../integration/compatibility_models.dart';
import '../integration/link_diagnostics.dart';
import '../simulator/simulation_scenario.dart';
import 'dashboard.dart';
import 'contribution_screen.dart';
import 'device_library.dart';
import 'gateway_screen.dart';
import 'link_screen.dart';
import 'parameters_screen.dart';
import 'studio_workspace.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.snapshot,
    required this.scenario,
    required this.onScenarioChanged,
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
    required this.onOpenDesignLab,
    required this.onOpenDiagnostics,
    required this.studioEnabled,
    required this.contributionsEnabled,
  });
  final BatterySnapshot snapshot;
  final SimulationScenario scenario;
  final ValueChanged<SimulationScenario> onScenarioChanged;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenDesignLab;
  final VoidCallback onOpenDiagnostics;
  final bool studioEnabled;
  final bool contributionsEnabled;
  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final battery = BatteryIntegrationProfile(
      chargeVoltageWindow: widget.snapshot.chargeVoltageLimit.value == null
          ? const SourcedValue.unavailable('not_reported')
          : SourcedValue.reported(
              VoltageWindow(
                minimum: widget.snapshot.voltage.value ?? 0,
                maximum: widget.snapshot.chargeVoltageLimit.value!,
              ),
              EvidenceSource.deviceReported,
            ),
      dischargeVoltageWindow: const SourcedValue.unavailable('not_reported'),
      maximumChargeCurrent: widget.snapshot.chargeCurrentLimit.value == null
          ? const SourcedValue.unavailable('not_reported')
          : SourcedValue.reported(
              widget.snapshot.chargeCurrentLimit.value!,
              EvidenceSource.deviceReported,
            ),
      maximumDischargeCurrent:
          widget.snapshot.dischargeCurrentLimit.value == null
          ? const SourcedValue.unavailable('not_reported')
          : SourcedValue.reported(
              widget.snapshot.dischargeCurrentLimit.value!,
              EvidenceSource.deviceReported,
            ),
      chemistry: const SourcedValue.unavailable('profile_required'),
      spokenProtocols: const {},
    );
    const inverter = InverterIntegrationProfile(
      configuredChargeVoltage: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      configuredLowVoltageCutoff: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      configuredChargeCurrent: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      configuredDischargeCurrent: SourcedValue.unavailable(
        'inverter_not_connected',
      ),
      supportedChemistries: {},
      supportedBatteryProtocols: {},
    );
    final assessment = const CompatibilityEngine().assess(
      battery: battery,
      inverter: inverter,
    );
    final link = const LinkDiagnostics().analyze(
      LinkObservation(
        window: Duration.zero,
        expectedMessages: 0,
        receivedMessages: 0,
        timeouts: 0,
        crcFailures: 0,
        inverterSoc: SourcedValue.unavailable('inverter_not_connected'),
        batterySoc: SourcedValue.unavailable('inverter_not_connected'),
      ),
    );
    final pages = <Widget>[
      Dashboard(
        snapshot: widget.snapshot,
        scenario: widget.scenario,
        onScenarioChanged: widget.onScenarioChanged,
        onToggleLocale: widget.onToggleLocale,
        onToggleTheme: widget.onToggleTheme,
        onToggleContrast: widget.onToggleContrast,
        onOpenDesignLab: widget.onOpenDesignLab,
        onOpenDiagnostics: widget.onOpenDiagnostics,
        embedded: true,
      ),
      const DeviceLibraryScreen(),
      LinkScreen(
        assessment: assessment,
        link: link,
        recommendations: const CompatibilityEngine().recommendations(
          assessment,
        ),
        simulated: true,
      ),
      const GatewayScreen(),
      const ParametersScreen(),
      if (widget.studioEnabled) const StudioWorkspace(),
      if (widget.contributionsEnabled) const ContributionScreen(),
    ];
    final destinations = [
      (Icons.grid_view, s.overview),
      (Icons.library_books_outlined, s.pick('Library', 'المكتبة')),
      (Icons.link, s.pick('Link', 'الرابط')),
      (Icons.cable, s.gateway),
      (Icons.tune, s.pick('Parameters', 'المعلمات')),
      if (widget.studioEnabled)
        (Icons.science_outlined, s.pick('Studio', 'الاستوديو')),
      if (widget.contributionsEnabled)
        (Icons.volunteer_activism_outlined, s.pick('Contribute', 'ساهم')),
    ];
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 112,
                color: SolarColors.deep,
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: SolarColors.lime,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.bolt, color: SolarColors.deep),
                    ),
                    const SizedBox(height: 28),
                    for (var i = 0; i < destinations.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 10,
                        ),
                        child: _RailButton(
                          icon: destinations[i].$1,
                          label: destinations[i].$2,
                          selected: index == i,
                          onTap: () => setState(() => index = i),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onOpenDesignLab,
                      tooltip: s.designLab,
                      icon: const Icon(
                        Icons.science_outlined,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(index: index, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !wide
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.$1),
                    label: destination.$2,
                  ),
              ],
            )
          : null,
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Material(
      color: selected ? SolarColors.lime : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 82,
          height: 58,
          child: Icon(
            icon,
            color: selected ? SolarColors.deep : Colors.white60,
          ),
        ),
      ),
    ),
  );
}
