import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../entities/sensor_data_entity.dart';

abstract class BluetoothRepository {
  Future<List<BluetoothDevice>> getBondedDevices();
  Future<void> connectToDevice(BluetoothDevice device);
  Stream<SensorDataEntity> getSensorData();
  Future<void> togglePermission(bool isPermitted);
  void disconnectDevice();
}
