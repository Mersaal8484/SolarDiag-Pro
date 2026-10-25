import '../core/battery_models.dart';

enum ResearchTargetCategory { inverter, battery }

class ResearchTarget {
  const ResearchTarget({required this.manufacturer, required this.category});

  final String manufacturer;
  final ResearchTargetCategory category;
  VerificationStatus get status => VerificationStatus.researchTarget;
}

const inverterResearchTargets = <ResearchTarget>[
  ResearchTarget(
    manufacturer: 'Sungrow',
    category: ResearchTargetCategory.inverter,
  ),
  ResearchTarget(
    manufacturer: 'Deye',
    category: ResearchTargetCategory.inverter,
  ),
  ResearchTarget(
    manufacturer: 'Growatt',
    category: ResearchTargetCategory.inverter,
  ),
  ResearchTarget(
    manufacturer: 'Horizon',
    category: ResearchTargetCategory.inverter,
  ),
  ResearchTarget(
    manufacturer: 'Felicity Solar',
    category: ResearchTargetCategory.inverter,
  ),
  ResearchTarget(
    manufacturer: 'Voltronic',
    category: ResearchTargetCategory.inverter,
  ),
];

const batteryResearchTargets = <ResearchTarget>[
  ResearchTarget(
    manufacturer: 'Pylontech',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(
    manufacturer: 'Dyness',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(
    manufacturer: 'Felicity Lithium',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(
    manufacturer: 'Growatt ARK',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(
    manufacturer: 'Deye Lithium',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(
    manufacturer: 'JK BMS',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(manufacturer: 'JBD', category: ResearchTargetCategory.battery),
  ResearchTarget(
    manufacturer: 'Daly',
    category: ResearchTargetCategory.battery,
  ),
  ResearchTarget(
    manufacturer: 'Seplos',
    category: ResearchTargetCategory.battery,
  ),
];

const researchTargets = <ResearchTarget>[
  ...inverterResearchTargets,
  ...batteryResearchTargets,
];
