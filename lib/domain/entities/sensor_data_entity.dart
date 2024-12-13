class SensorDataEntity {
  final double temperature;
  final double lightIntensity;
  final bool isPermitted;

  const SensorDataEntity({
    required this.temperature,
    required this.lightIntensity,
    required this.isPermitted,
  });
}