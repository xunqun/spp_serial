import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spp_serial/spp_serial.dart';
import '../model/connect_state.dart';
import 'base_helper.dart';

class SppHelper with BaseHelper {

  static SppSerial platform = SppSerial();

  // Singleton pattern to ensure only one instance of Channel exists
  static SppHelper? _instance;
  static SppHelper get() {
    if (_instance == null) {
      _instance = SppHelper();
      _instance!._internal();
    }
    return _instance!;
  }


  _internal(){
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'scanResults':
          // Handle scan results
          final List<Object?> results = call.arguments;
          final List<Map<String, String?>> list = results
              .whereType<Map>() // 过滤出 Map 类型
              .map((e) => Map<String, String?>.from(e as Map)) // 转换为 Map<String, String>
              .toList();
          scanResultsController.add(list);
          break;
        case 'clientScanState':
          // Handle scan state changes
          final bool isScanning = call.arguments;
          scanStateController.add(isScanning);
          break;
        case 'clientConnectState':
          // Handle connection state changes
          final String connectState = call.arguments;
          clientConnectStateController.add(ClientConnectState.findByName(connectState));
          break;
        case 'serverConnectState':
          // Handle server connection state changes
          final String serverConnectState = call.arguments;
          serverConnectStateController.add(ServerConnectState.findByName(serverConnectState));
          break;
        case 'serverReceivedData':
          // Handle received data from server
          final Uint8List data = call.arguments;
          debugPrint("Server received data:");
          serverReceivedDataController.add(data);
          break;
        case 'clientReceivedData':
          // Handle received data from client
          final Uint8List data = call.arguments;
          // print("Client received data: $data");
          clientReceivedDataController.add(data);
          break;
      }
    });
  }

  @override
  Future<void> scan() async {
    try {
      await platform.scan();
    } on PlatformException catch (e) {
      print("Failed to scan: '${e.message}'.");
    }
  }

  @override
  Future<void> stopScan() async {
    try {
      await platform.stopScan();
    } on PlatformException catch (e) {
      print("Failed to stop scan: '${e.message}'.");
    }
  }

  @override
  Future<void> connectAsClient(String deviceId) async {
    try {
      await platform.connectAsClient(deviceId);
    } on PlatformException catch (e) {
      print("Failed to connect: '${e.message}'.");
    }
  }

  @override
  Future<void> connectAsServer(bool discoverable) async {
    try {
      await platform.connectAsServer(discoverable);
    } on PlatformException catch (e) {
      print("Failed to connect as server: '${e.message}'.");
    }
  }

  @override
  Future<void> serverStop() async {
    try {
      await platform.serverStop();
    } on PlatformException catch (e) {
      print("Failed to disconnect server: '${e.message}'.");
    }
  }

  @override
  Future<void> clientDisconnect() async {
    try {
      await platform.disconnect();
    } on PlatformException catch (e) {
      print("Failed to disconnect: '${e.message}'.");
    }
  }

  @override
  Future<void> sendData(List<int> data) async {
    try {
      Uint8List uint8list = Uint8List.fromList(data);
      await platform.sendData(uint8list);
    } on PlatformException catch (e) {
      print("Failed to send data: '${e.message}'.");
    }
  }

  @override
  Future<void> serverSendData(List<int> data) async {
    try {
      Uint8List uint8list = Uint8List.fromList(data);
      await platform.serverSendData(uint8list);
    } on PlatformException catch (e) {
      print("Failed to send data: '${e.message}'.");
    }
  }

}