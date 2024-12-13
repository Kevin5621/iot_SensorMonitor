import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:uas_sistem_terbenam/presentation/bloc/bluetooth_bloc.dart';
import 'package:uas_sistem_terbenam/presentation/bloc/bluetooth_state.dart';
import 'package:uas_sistem_terbenam/presentation/widgets/conection_status_card.dart';
import 'package:uas_sistem_terbenam/presentation/widgets/permission_toggle_card.dart';
import 'package:uas_sistem_terbenam/presentation/widgets/sensor_readings_card.dart';

class SensorMonitoringPage extends StatelessWidget {
  const SensorMonitoringPage({super.key});

  void _showDeviceListDialog(BuildContext context) {
    context.read<BluetoothBloc>().add(DiscoverDevicesEvent());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<BluetoothBloc, AppBluetoothState >(
          builder: (context, state) {
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
                          if (state.isLoading)
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
                    state.devices == null || state.devices!.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              state.isLoading 
                                ? 'Searching for devices...' 
                                : 'No devices found. Tap Refresh or ensure devices are discoverable.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              itemCount: state.devices?.length ?? 0,
                              itemBuilder: (context, index) {
                                BluetoothDevice device = state.devices![index];
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
                                    context.read<BluetoothBloc>().add(
                                      ConnectToDeviceEvent(device)
                                    );
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                          ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: state.isLoading ? null : () {
                            context.read<BluetoothBloc>().add(DiscoverDevicesEvent());
                          },
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
            child: BlocBuilder<BluetoothBloc, AppBluetoothState >(
              builder: (context, state) {
                return Column(
                  children: [
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
                            onPressed: () => _showDeviceListDialog(context),
                          )
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ConnectionStatusCard(
                            selectedDevice: state.connectedDevice,
                          ),

                          const SizedBox(height: 16),

                          SensorReadingsCard(
                            sensorData: state.sensorData,
                          ),

                          const SizedBox(height: 16),

                          PermissionToggleCard(
                            isPermitted: state.sensorData?.isPermitted ?? false,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}