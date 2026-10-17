import 'dart:convert';
import 'dart:io';
import 'package:solardiag_pro/simulator/simulation_scenario.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.first == '--list') {
    stdout.writeln(
      jsonEncode(SimulationScenario.values.map((e) => e.name).toList()),
    );
    return;
  }
  final scenario = SimulationScenario.values.byName(arguments.first);
  final tick = arguments.length > 1 ? int.parse(arguments[1]) : 0;
  final frame = ScenarioFactory.create(scenario, tick: tick);
  stdout.writeln(
    jsonEncode({
      'scenario': scenario.name,
      'tick': tick,
      'simulated': true,
      'pack_voltage_v': frame.snapshot.voltage.value,
      'soc_percent': frame.snapshot.soc.value,
      'alarms': frame.alarmCodes.toList(),
      'link_available': frame.linkAvailable,
      'metadata': frame.metadata,
    }),
  );
}
