import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uas_sistem_terbenam/data/datasources/bluetooth_datasrc.dart';
import 'package:uas_sistem_terbenam/data/repo/bluetooth_repo_impl.dart';
import 'package:uas_sistem_terbenam/domain/usecase/bluetooth_usecases.dart';
import 'presentation/bloc/bluetooth_bloc.dart';
import 'presentation/pages/sensor_monitoring_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    final bluetoothDatasource = BluetoothDatasource();
    final bluetoothRepository = BluetoothRepositoryImpl();
    final bluetoothUseCases = BluetoothUseCases(
      bluetoothRepository, 
      bluetoothDatasource
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<BluetoothBloc>(
          create: (context) => BluetoothBloc(
            bluetoothUseCases, 
            bluetoothRepository
          )..add(InitializeBluetoothEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'Sensor Monitoring App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SensorMonitoringPage(),
      ),
    );
  }
}