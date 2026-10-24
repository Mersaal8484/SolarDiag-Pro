import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../design/components.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/device_session.dart';
import 'battery_workspace.dart';
import 'dashboard.dart';
import 'contribution_screen.dart';
import 'device_library.dart';
import 'gateway_screen.dart';
import 'inverter_diagnostics_screen.dart';
import 'link_screen.dart';
import 'parameters_screen.dart';
import 'session_history_screen.dart';
import 'studio_workspace.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
    required this.onOpenDesignLab,
    required this.onOpenDiagnostics,
    required this.studioEnabled,
    required this.contributionsEnabled,
  });
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
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = <Widget>[
      Dashboard(
        onToggleLocale: widget.onToggleLocale,
        onToggleTheme: widget.onToggleTheme,
        onToggleContrast: widget.onToggleContrast,
        onOpenDesignLab: widget.onOpenDesignLab,
        onOpenDiagnostics: widget.onOpenDiagnostics,
        onSelectDestination: (value) => setState(() => index = value),
        embedded: true,
      ),
      const InverterDiagnosticsScreen(),
      const BatteryWorkspace(),
      const DeviceLibraryScreen(),
      const LinkScreen(),
      const GatewayScreen(),
      const ParametersScreen(),
      const SessionHistoryScreen(),
      if (widget.studioEnabled) const StudioWorkspace(),
      if (widget.contributionsEnabled) const ContributionScreen(),
    ];
    final destinations = [
      ('overview', Icons.grid_view, s.overview),
      ('inverter', Icons.solar_power_outlined, s.inverter),
      ('battery', Icons.battery_6_bar, s.battery),
      ('library', Icons.library_books_outlined, s.library),
      ('link', Icons.link, s.link),
      ('gateway', Icons.cable, s.gateway),
      ('parameters', Icons.tune, s.parameters),
      ('history', Icons.history, s.history),
      if (widget.studioEnabled) ('studio', Icons.science_outlined, s.studio),
      if (widget.contributionsEnabled)
        ('contributions', Icons.volunteer_activism_outlined, s.contribute),
    ];
    const mobileDestinationIndices = [0, 2, 5, 6, 7];
    final mobileSelectedIndex = mobileDestinationIndices.indexOf(index);
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Container(
                width: 112,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF172E51), Color(0xFF0A192D)],
                  ),
                  border: Border(right: BorderSide(color: Color(0xFF2B4260))),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D5FF), Color(0xFF3478F6)],
                        ),
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
                          key: ValueKey('workspace-nav-${destinations[i].$1}'),
                          icon: destinations[i].$2,
                          label: destinations[i].$3,
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
                        color: SolarColors.onDarkStrong,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      4,
                    ),
                    child: ConnectionCapsule(
                      key: const Key('connection-capsule'),
                      gateway: s.simulatedGateway,
                      interfaceName: s.virtualInterface,
                      device: s.simulatedBms,
                      profile: s.simulatedProfile,
                      mode:
                          '${s.readOnlyMode} · ${_linkLabel(s, session.linkState)}',
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(index: index, children: pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !wide
          ? NavigationBar(
              selectedIndex: mobileSelectedIndex < 0 ? 0 : mobileSelectedIndex,
              onDestinationSelected: (value) =>
                  setState(() => index = mobileDestinationIndices[value]),
              destinations: [
                for (final destinationIndex in mobileDestinationIndices)
                  NavigationDestination(
                    key: ValueKey(
                      'workspace-nav-${destinations[destinationIndex].$1}',
                    ),
                    icon: Icon(destinations[destinationIndex].$2),
                    label: destinations[destinationIndex].$3,
                  ),
              ],
            )
          : null,
    );
  }

  static String _linkLabel(AppLocalizations s, DeviceSessionLinkState state) =>
      switch (state) {
        DeviceSessionLinkState.connecting => s.connecting,
        DeviceSessionLinkState.online => s.online,
        DeviceSessionLinkState.unavailable => s.linkUnavailable,
      };
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    super.key,
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
      color: selected
          ? SolarColors.green.withValues(alpha: .19)
          : SolarColors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 82,
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? SolarColors.green : SolarColors.onDarkMuted,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? SolarColors.onDark
                      : SolarColors.onDarkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
