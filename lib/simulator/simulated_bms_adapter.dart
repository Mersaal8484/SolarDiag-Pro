import 'dart:convert';

import '../core/battery_models.dart';
import '../core/simulation_clock.dart';
import '../parameters/write_pipeline.dart';
import '../protocol/bms_adapter.dart';
import '../protocol/capabilities.dart';
import '../protocol/device_profile.dart';
import 'simulated_parameter_transport.dart';
import 'simulated_profile_document.dart';
import 'simulation_scenario.dart';

part 'simulated_bms_adapter_impl.dart';
