import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../design/precision_ui.dart';
import '../design/components.dart';
import '../design/solar_icon.dart';
import '../design/solar_icons.g.dart';
import '../l10n/generated/app_localizations.dart';
import '../session/device_session.dart';
import '../trust/library_write_reason.dart';
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
    required this.onOpenSettings,
    required this.studioEnabled,
    required this.contributionsEnabled,
    this.libraryWriteDisabledReason,
  });
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenDesignLab;
  final VoidCallback onOpenDiagnostics;
  final VoidCallback onOpenSettings;
  final bool studioEnabled;
  final bool contributionsEnabled;
  final LibraryWriteDisabledReason? libraryWriteDisabledReason;
  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = DeviceSessionScope.of(context);
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = <Widget>[
      Dashboard(
        onToggleLocale: widget.onToggleLocale,
        onToggleTheme: widget.onToggleTheme,
        onToggleContrast: widget.onToggleContrast,
        onOpenDesignLab: widget.onOpenDesignLab,
        onOpenDiagnostics: widget.onOpenDiagnostics,
        onOpenSettings: widget.onOpenSettings,
        onSelectDestination: (value) => setState(() => index = value),
        embedded: true,
      ),
      const InverterDiagnosticsScreen(),
      const BatteryWorkspace(),
      DeviceLibraryScreen(
        writeDisabledReason: widget.libraryWriteDisabledReason,
      ),
      const LinkScreen(),
      const GatewayScreen(),
      const ParametersScreen(),
      const SessionHistoryScreen(),
      if (widget.studioEnabled) StudioWorkspace(database: session.database),
      if (widget.contributionsEnabled) const ContributionScreen(),
    ];
    final destinations = [
      ('overview', SolarIcons.home, s.overview),
      ('inverter', SolarIcons.inverter, s.inverter),
      ('battery', SolarIcons.battery, s.battery),
      ('library', SolarIcons.library, s.library),
      ('link', SolarIcons.linkDiagnostics, s.link),
      ('gateway', SolarIcons.gateway, s.gateway),
      ('parameters', SolarIcons.configure, s.parameters),
      ('history', SolarIcons.history, s.history),
      if (widget.studioEnabled) ('studio', SolarIcons.research, s.studio),
      if (widget.contributionsEnabled)
        ('contributions', SolarIcons.contribute, s.contribute),
    ];
    const mobileDestinationIndices = [0, 2, 5, 6, 7];
    final mobileSelectedIndex = mobileDestinationIndices.indexOf(index);
    return Scaffold(
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: SafeArea(
          child: Row(
          children: [
            if (wide)
              Container(
                width: 112,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).extension<SolarTokens>()!.palette.surface,
                  border: BorderDirectional(
                    end: BorderSide(
                      color: Theme.of(
                        context,
                      ).extension<SolarTokens>()!.palette.separator,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 22),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [palette.tint, palette.surfaceRaised],
                        ),
                        border: Border.all(color: palette.separator),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: SolarIcon(
                        SolarIcons.solar,
                        color: Theme.of(
                          context,
                        ).extension<SolarTokens>()!.palette.background,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            FocusTraversalOrder(
                              order: NumericFocusOrder(i.toDouble()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                  horizontal: 10,
                                ),
                                child: _RailButton(
                                  key: ValueKey(
                                    'workspace-nav-${destinations[i].$1}',
                                  ),
                                  icon: destinations[i].$2,
                                  label: destinations[i].$3,
                                  selected: index == i,
                                  onTap: () => setState(() => index = i),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    FocusTraversalOrder(
                      order: NumericFocusOrder(destinations.length.toDouble()),
                      child: IconButton(
                        onPressed: widget.onOpenDesignLab,
                        tooltip: s.designLab,
                        icon: SolarIcon(
                          SolarIcons.research,
                          color: Theme.of(
                            context,
                          ).extension<SolarTokens>()!.palette.tint,
                        ),
                      ),
                    ),
                    FocusTraversalOrder(
                      order: NumericFocusOrder(
                        destinations.length.toDouble() + 1,
                      ),
                      child: IconButton(
                        onPressed: widget.onOpenSettings,
                        tooltip: s.settings,
                        icon: SolarIcon(
                          SolarIcons.configure,
                          color: Theme.of(
                            context,
                          ).extension<SolarTokens>()!.palette.tint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            Expanded(
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(100),
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
                    child: PrecisionCanvas(
                      child: IndexedStack(index: index, children: pages),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
                    icon: SolarIcon(destinations[destinationIndex].$2),
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
  final SolarIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<SolarTokens>()!.palette;
    return Tooltip(
      message: label,
      child: Material(
        color: selected
            ? palette.tint.withValues(alpha: .15)
            : palette.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 88,
            height: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SolarIcon(
                  icon,
                  size: 22,
                  color: selected ? palette.tint : palette.labelSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected ? palette.tint : palette.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
