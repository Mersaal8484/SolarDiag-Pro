import 'package:flutter/material.dart';

import 'app/solardiag_app.dart';
import 'persistence/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await LocalDatabase.openDefault();
  runApp(SolarDiagApp(database: database));
}
