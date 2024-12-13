// States
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:uas_sistem_terbenam/domain/entities/sensor_data_entity.dart';

class AppBluetoothState {
  final List<BluetoothDevice>? devices;
  final BluetoothDevice? connectedDevice;
  final SensorDataEntity? sensorData;
  final bool isLoading;
  final String? error;

  const AppBluetoothState({
    this.devices,
    this.connectedDevice,
    this.sensorData,
    this.isLoading = false,
    this.error,
  });

  AppBluetoothState copyWith({
    List<BluetoothDevice>? devices,
    BluetoothDevice? connectedDevice,
    SensorDataEntity? sensorData,
    bool? isLoading,
    String? error,
  }) {
    return AppBluetoothState(
      devices: devices ?? this.devices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      sensorData: sensorData ?? this.sensorData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}