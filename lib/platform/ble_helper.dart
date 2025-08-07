

import 'dart:typed_data';

import 'package:spp_serial/platform/base_helper.dart';

class BleHelper with BaseHelper{
  static BleHelper? _instance;
  static BleHelper get() {
    if (_instance == null) {
      _instance = BleHelper();
      _instance!._internal();
    }
    return _instance!;
  }

  _internal() {
    // Initialize the BLE platform and set up method call handlers if needed
    // For example, you might want to set up a method call handler here
    // to listen for platform-specific events.
  }
  @override
  Future<void> clientDisconnect() {
    // TODO: implement clientDisconnect
    throw UnimplementedError();
  }

  @override
  Future<void> connectAsClient(String deviceId) {
    // TODO: implement connectAsClient
    throw UnimplementedError();
  }

  @override
  Future<void> connectAsServer(bool discoverable) {
    // TODO: implement connectAsServer
    throw UnimplementedError();
  }

  @override
  Future<void> scan() {
    // TODO: implement scan
    throw UnimplementedError();
  }

  @override
  Future<void> sendData(Uint8List data) {
    // TODO: implement sendData
    throw UnimplementedError();
  }

  @override
  Future<void> serverSendData(Uint8List data) {
    // TODO: implement serverSendData
    throw UnimplementedError();
  }

  @override
  Future<void> serverStop() {
    // TODO: implement serverStop
    throw UnimplementedError();
  }

  @override
  Future<void> stopScan() {
    // TODO: implement stopScan
    throw UnimplementedError();
  }


}