import 'dart:async';
import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:uas_sistem_terbenam/domain/repo/bluetooth_repo.dart';
import '../../domain/entities/sensor_data_entity.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  BluetoothConnection? _connection;
  final _sensorDataController = StreamController<SensorDataEntity>.broadcast();

  @override
  Future<List<BluetoothDevice>> getBondedDevices() async {
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  @override
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _connection?.input?.listen(_parseReceivedData);
    } catch (error) {
      print('Connection error: $error');
    }
  }

  void _parseReceivedData(List<int> data) {
    try {
      String rawData = String.fromCharCodes(data);
      List<String> parts = rawData.split(',');
      double temperature = double.parse(parts[0].split(':')[1]);
      double lightIntensity = double.parse(parts[1].split(':')[1]);
      int status = int.parse(parts[2].split(':')[1]);

      final sensorData = SensorDataEntity(
        temperature: temperature, 
        lightIntensity: lightIntensity, 
        isPermitted: status == 1
      );

      _sensorDataController.add(sensorData);
    } catch (error) {
      print('Data parsing error: $error');
    }
  }

  @override
  Stream<SensorDataEntity> getSensorData() {
    return _sensorDataController.stream;
  }

  @override
  Future<void> togglePermission(bool isPermitted) async {
    if (_connection != null) {
      _connection?.output.add(utf8.encode('status:${isPermitted ? 1 : 0}\n'));
    }
  }

  @override
  void disconnectDevice() {
    _connection?.dispose();
    _connection = null;
  }
}
