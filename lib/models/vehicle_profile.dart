enum VehicleType { car, bike, truck, supercar }

class VehicleProfile {
  final VehicleType type;
  final String name;
  final String description;
  final String iconAsset;
  final double minRoadWidthMeters;
  final bool excludeMotorways;
  final bool excludeSpeedBumps;
  final bool excludeUnclassified;

  const VehicleProfile({
    required this.type,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.minRoadWidthMeters,
    required this.excludeMotorways,
    required this.excludeSpeedBumps,
    required this.excludeUnclassified,
  });

  static const List<VehicleProfile> profiles = [
    VehicleProfile(
      type: VehicleType.car,
      name: "Standard Car",
      description: "Unrestricted city routing across all road categories.",
      iconAsset: "directions_car",
      minRoadWidthMeters: 0.0,
      excludeMotorways: false,
      excludeSpeedBumps: false,
      excludeUnclassified: false,
    ),
    VehicleProfile(
      type: VehicleType.bike,
      name: "Two-Wheeler",
      description: "Strips motorways and trunk roads for maximum rider safety.",
      iconAsset: "two_wheeler",
      minRoadWidthMeters: 0.0,
      excludeMotorways: true,
      excludeSpeedBumps: false,
      excludeUnclassified: false,
    ),
    VehicleProfile(
      type: VehicleType.truck,
      name: "Heavy Fleet",
      description: "Restricted to roads >= 3m width; avoids residential shortcuts.",
      iconAsset: "local_shipping",
      minRoadWidthMeters: 3.0,
      excludeMotorways: false,
      excludeSpeedBumps: false,
      excludeUnclassified: true,
    ),
    VehicleProfile(
      type: VehicleType.supercar,
      name: "Supercar / Low",
      description: "Zero speed bump tolerance and strict smooth pavement filter.",
      iconAsset: "sports_car",
      minRoadWidthMeters: 0.0,
      excludeMotorways: false,
      excludeSpeedBumps: true,
      excludeUnclassified: true,
    ),
  ];
}
