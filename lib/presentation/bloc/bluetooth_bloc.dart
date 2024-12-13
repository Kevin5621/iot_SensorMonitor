import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:uas_sistem_terbenam/domain/repo/bluetooth_repo.dart';
import 'package:uas_sistem_terbenam/domain/usecase/bluetooth_usecases.dart';
import 'package:uas_sistem_terbenam/presentation/bloc/bluetooth_state.dart';
import '../../domain/entities/sensor_data_entity.dart';

// Events
abstract class BluetoothEvent {}
class InitializeBluetoothEvent extends BluetoothEvent {}
class DiscoverDevicesEvent extends BluetoothEvent {}
class ConnectToDeviceEvent extends BluetoothEvent {
  final BluetoothDevice device;
  ConnectToDeviceEvent(this.device);
}
class TogglePermissionEvent extends BluetoothEvent {
  final bool isPermitted;
  TogglePermissionEvent(this.isPermitted);
}

// Bloc
class BluetoothBloc extends Bloc<BluetoothEvent, AppBluetoothState> {
  final BluetoothUseCases _useCases;
  final BluetoothRepository _repository;

  BluetoothBloc(this._useCases, this._repository) : super(AppBluetoothState()) {
    on<InitializeBluetoothEvent>(_onInitializeBluetooth);
    on<DiscoverDevicesEvent>(_onDiscoverDevices);
    on<ConnectToDeviceEvent>(_onConnectToDevice);
    on<TogglePermissionEvent>(_onTogglePermission);

    // Listen to sensor data stream
    _repository.getSensorData().listen((sensorData) {
      add(TogglePermissionEvent(sensorData.isPermitted));
    });
  }

  Future<void> _onInitializeBluetooth(
    InitializeBluetoothEvent event, 
    Emitter<AppBluetoothState> emit
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _useCases.initializeBluetooth();
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false, 
        error: 'Failed to initialize Bluetooth'
      ));
    }
  }

  Future<void> _onDiscoverDevices(
    DiscoverDevicesEvent event, 
    Emitter<AppBluetoothState> emit
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final devices = await _useCases.discoverDevices();
      emit(state.copyWith(
        devices: devices, 
        isLoading: false
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false, 
        error: 'Failed to discover devices'
      ));
    }
  }

  Future<void> _onConnectToDevice(
    ConnectToDeviceEvent event, 
    Emitter<AppBluetoothState> emit
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await _useCases.connectToDevice(event.device);
      emit(state.copyWith(
        connectedDevice: event.device, 
        isLoading: false
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false, 
        error: 'Failed to connect to device'
      ));
    }
  }

  Future<void> _onTogglePermission(
    TogglePermissionEvent event, 
    Emitter<AppBluetoothState> emit
  ) async {
    try {
      await _repository.togglePermission(event.isPermitted);
      emit(state.copyWith(
        sensorData: SensorDataEntity(
          temperature: state.sensorData?.temperature ?? 0.0,
          lightIntensity: state.sensorData?.lightIntensity ?? 0.0,
          isPermitted: event.isPermitted
        )
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle permission'));
    }
  }
}