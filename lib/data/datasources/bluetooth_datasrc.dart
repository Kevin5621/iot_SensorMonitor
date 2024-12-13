import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothDatasource {
  Future<bool> checkBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> enableBluetooth() async {
    bool? isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
    
    if (isAvailable ?? false) {
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      
      if (!(isEnabled ?? false)) {
        await FlutterBluetoothSerial.instance.requestEnable();
        return true;
      }
      return isEnabled ?? false;
    }
    return false;
  }
}
