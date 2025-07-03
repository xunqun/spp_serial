
import 'package:flutter/services.dart';

import 'spp_serial_platform_interface.dart';

class SppSerial {

  setMethodCallHandler(Future<dynamic>  Function(MethodCall call)? handler) {
    SppSerialPlatform.instance.setMethodCallHandler(handler);
  }

  Future<String?> getPlatformVersion() {
    return SppSerialPlatform.instance.getPlatformVersion();
  }

  Future<void> scan() {
    return SppSerialPlatform.instance.scan();
  }

  Future<void> stopScan() {
    return SppSerialPlatform.instance.stopScan();
  }

  Future<void> connectAsClient(String deviceId) {
    return SppSerialPlatform.instance.connectAsClient(deviceId);
  }

  Future<void> connectAsServer() {
    return SppSerialPlatform.instance.connectAsServer();
  }

  Future<void> serverStop() {
    return SppSerialPlatform.instance.serverStop();
  }

  Future<void> disconnect() {
    return SppSerialPlatform.instance.disconnect();
  }

  Future<void> sendData(Uint8List data) {
    return SppSerialPlatform.instance.sendData(data);
  }

  Future<void> serverSendData(Uint8List data) {
    return SppSerialPlatform.instance.serverSendData(data);
  }




}
