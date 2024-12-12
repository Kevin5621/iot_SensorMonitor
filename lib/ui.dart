// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';

import 'package:permission_handler/permission_handler.dart';

class SensorMonitoringApp extends StatefulWidget {
  const SensorMonitoringApp({super.key});

  @override
  _SensorMonitoringAppState createState() => _SensorMonitoringAppState();
}

class _SensorMonitoringAppState extends State<SensorMonitoringApp> {
  BluetoothConnection? _connection;
  bool _isPermitted = false;
  final int _sensorValueCount = 5;
  
  final List<double> _temperatureReadings = [];
  final List<double> _lightReadings = [];
  
  double _averageTemperature = 0.0;
  double _averageLightIntensity = 0.0;

  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _checkBluetoothPermissions();
  }

  Future<void> _checkBluetoothPermissions() async {
    // Request multiple permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (allGranted) {
      _initializeBluetooth();
    } else {
      // Show a dialog or snackbar explaining why permissions are needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth permissions are required'))
      );
    }
  }

  Future<void> _initializeBluetooth() async {
    // Check if Bluetooth is available
    bool? isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
    
    if (isAvailable ?? false) {
      // Check if Bluetooth is enabled
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      
      if (!(isEnabled ?? false)) {
        // Request to enable Bluetooth
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      _getBondedDevices();
    }
  }

  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      print('Discovered Devices: ${devices.length}');
      devices.forEach((device) {
        print('Device Name: ${device.name}, Address: ${device.address}');
      });
    } catch (error) {
      print('Error getting bonded devices: $error');
    }

    setState(() {
      _devicesList = devices;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      BluetoothConnection connection = 
          await BluetoothConnection.toAddress(device.address);
      
      setState(() {
        _connection = connection;
        _selectedDevice = device;
      });
      
      connection.input!.listen((data) {
        _parseReceivedData(String.fromCharCodes(data));
      }).onDone(() {
        // Connection lost
        setState(() {
          _connection = null;
          _selectedDevice = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth connection lost'))
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}'))
      );
    } catch (error) {
      print('Detailed Connection Error: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $error'),
          duration: const Duration(seconds: 3),
        )
      );
    }
  }

  void _parseReceivedData(String data) {
    try {
      // Format data: "temp:25.5,light:500.0,status:1"
      print('Received data: $data');
      List<String> parts = data.split(',');
      double temperature = double.parse(parts[0].split(':')[1]);
      double lightIntensity = double.parse(parts[1].split(':')[1]);
      int status = int.parse(parts[2].split(':')[1]);

      setState(() {
        _isPermitted = status == 1;
        
        if (_isPermitted) {
          _temperatureReadings.add(temperature);
          _lightReadings.add(lightIntensity);

          // Simpan hanya n terakhir
          if (_temperatureReadings.length > _sensorValueCount) {
            _temperatureReadings.removeAt(0);
            _lightReadings.removeAt(0);
          }

          // Hitung rata-rata
          _averageTemperature = _temperatureReadings.isNotEmpty 
              ? _temperatureReadings.reduce((a, b) => a + b) / _temperatureReadings.length 
              : 0.0;
          
          _averageLightIntensity = _lightReadings.isNotEmpty
              ? _lightReadings.reduce((a, b) => a + b) / _lightReadings.length
              : 0.0;
        }
      });
    } catch (error) {
      print('Error parsing data: $error');
    }
  }

  void _togglePermission() {
    if (_connection != null) {
      setState(() {
        _isPermitted = !_isPermitted;
        
        // Kirim status izin ke Arduino
        _connection?.output.add(utf8.encode('status:${_isPermitted ? 1 : 0}\n'));
      });
    }
  }

bool _isDiscovering = false;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _devicesList.clear();
    });

    _streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      if (!_devicesList.any((device) => device.address == r.device.address)) {
        setState(() {
          _devicesList.add(r.device);
        });
      }
    });

    // Tambahkan timeout 10 detik untuk menghentikan pencarian
    Future.delayed(const Duration(seconds: 10), () {
      if (_isDiscovering) {
        _streamSubscription?.cancel();
        setState(() {
          _isDiscovering = false;
        });
      }
    });

    _streamSubscription!.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
    }

  void _showDeviceListDialog() {
    // Reset daftar perangkat sebelum memulai discovery
    _devicesList.clear();
    
    // Mulai pencarian perangkat
    _startDiscovery();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Bluetooth Devices',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_isDiscovering)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                    ],
                  ),
                ),
                const Divider(),
                _devicesList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _isDiscovering 
                            ? 'Searching for devices...' 
                            : 'No devices found. Tap Refresh or ensure devices are discoverable.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _devicesList.length,
                          itemBuilder: (context, index) {
                            BluetoothDevice device = _devicesList[index];
                            return ListTile(
                              title: Text(
                                device.name ?? 'Unknown Device', 
                                style: const TextStyle(color: Colors.black87),
                              ),
                              subtitle: Text(
                                device.address,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: device.bondState == BluetoothBondState.bonded
                                  ? const Icon(Icons.link, color: Colors.green)
                                  : const Icon(Icons.link_off, color: Colors.red),
                              onTap: () {
                                Navigator.of(context).pop();
                                _connectToDevice(device);
                              },
                            );
                          },
                        ),
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _isDiscovering ? null : _startDiscovery,
                      child: const Text('Refresh'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0F4F8),
                  Color(0xFFE6EAF0),
                ],
              ),
            ),
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sensor Monitoring',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bluetooth, color: Colors.black87),
                        onPressed: _showDeviceListDialog,
                      )
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Connection Status Card
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Device Connection',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Connected Device:',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  _selectedDevice?.name ?? "None",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedDevice != null ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sensor Data Card
                      _buildGlassCard(
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
                              '${_averageTemperature.toStringAsFixed(2)} °C',
                              Icons.thermostat
                            ),
                            const SizedBox(height: 10),
                            _buildSensorReadingRow(
                              'Light Intensity', 
                              '${_averageLightIntensity.toStringAsFixed(2)} lux',
                              Icons.wb_sunny
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Permission Toggle Card
                      _buildGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sensor Permission',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Current Status:',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                Text(
                                  _isPermitted ? 'Allowed' : 'Blocked',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isPermitted ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: ElevatedButton(
                                onPressed: _connection != null ? _togglePermission : null, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isPermitted ? Colors.red : Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  _isPermitted ? 'Block Sensors' : 'Allow Sensors',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
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
      child: child,
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