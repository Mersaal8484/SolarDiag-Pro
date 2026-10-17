import 'package:flutter/material.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../core/battery_models.dart';
import 'dashboard.dart';
import 'device_library.dart';
import 'gateway_screen.dart';
import 'link_screen.dart';
import 'parameters_screen.dart';

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.snapshot,
    required this.onToggleLocale,
    required this.onToggleTheme,
    required this.onToggleContrast,
    required this.onOpenDesignLab,
    required this.onOpenDiagnostics,
  });
  final BatterySnapshot snapshot;
  final VoidCallback onToggleLocale;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleContrast;
  final VoidCallback onOpenDesignLab;
  final VoidCallback onOpenDiagnostics;
  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = <Widget>[
      Dashboard(
        snapshot: widget.snapshot,
        onToggleLocale: widget.onToggleLocale,
        onToggleTheme: widget.onToggleTheme,
        onToggleContrast: widget.onToggleContrast,
        onOpenDesignLab: widget.onOpenDesignLab,
        onOpenDiagnostics: widget.onOpenDiagnostics,
        embedded: true,
      ),
      const DeviceLibraryScreen(),
      const LinkScreen(),
      const GatewayScreen(),
      const ParametersScreen(),
    ];
    final destinations = [
      (Icons.grid_view, s.overview),
      (Icons.library_books_outlined, s.pick('Library', 'المكتبة')),
      (Icons.link, s.pick('Link', 'الرابط')),
      (Icons.cable, s.gateway),
      (Icons.tune, s.pick('Parameters', 'المعلمات')),
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
