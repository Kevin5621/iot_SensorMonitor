import 'package:uas_sistem_terbenam/data/datasources/bluetooth_datasrc.dart';
import 'package:uas_sistem_terbenam/domain/repo/bluetooth_repo.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothUseCases {
  final BluetoothRepository _repository;
  final BluetoothDatasource _datasource;

  BluetoothUseCases(this._repository, this._datasource);

  Future<bool> initializeBluetooth() async {
    bool permissionsGranted = await _datasource.checkBluetoothPermissions();
    if (permissionsGranted) {
      return await _datasource.enableBluetooth();
    }
    return false;
  }

  Future<List<BluetoothDevice>> discoverDevices() async {
    return await _repository.getBondedDevices();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await _repository.connectToDevice(device);
  }
}