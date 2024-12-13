import 'package:flutter/material.dart';
import '../../domain/entities/sensor_data_entity.dart';

class SensorReadingsCard extends StatelessWidget {
  final SensorDataEntity? sensorData;

  const SensorReadingsCard({Key? key, this.sensorData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white.withOpacity(0.5),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensor Readings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _buildSensorReadingRow(
            'Temperature', 
            '${sensorData?.temperature.toStringAsFixed(2) ?? '0.00'} °C',
            Icons.thermostat
          ),
          const SizedBox(height: 10),
          _buildSensorReadingRow(
            'Light Intensity', 
            '${sensorData?.lightIntensity.toStringAsFixed(2) ?? '0.00'} lux',
            Icons.wb_sunny
          ),
        ],
      ),
    );
  }

  Widget _buildSensorReadingRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.black54),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}