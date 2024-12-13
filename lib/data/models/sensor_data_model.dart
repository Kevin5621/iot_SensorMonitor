class SensorDataModel {
  final double temperature;
  final double lightIntensity;
  final bool isPermitted;

  const SensorDataModel({
    required this.temperature,
    required this.lightIntensity,
    required this.isPermitted,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      temperature: json['temperature'] as double,
      lightIntensity: json['lightIntensity'] as double,
      isPermitted: json['status'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'lightIntensity': lightIntensity,
    'status': isPermitted ? 1 : 0,
  };
}