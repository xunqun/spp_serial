import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'spp_serial_platform_interface.dart';

/// An implementation of [SppSerialPlatform] that uses method channels.
class MethodChannelSppSerial extends SppSerialPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('channel.whiles.app/bluetooth');

  @override
  setMethodCallHandler(Future<dynamic>  Function(MethodCall call)? handler) {
    methodChannel.setMethodCallHandler(handler);
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> scan() async {
    await methodChannel.invokeMethod('scan');
  }

  @override
  Future<void> stopScan() async {
    await methodChannel.invokeMethod('stopScan');
  }

  @override
  Future<void> connectAsClient(String deviceId) async {
    await methodChannel.invokeMethod('connectAsClient', {'deviceId': deviceId});
  }

  @override
  Future<void> connectAsServer() async {
    await methodChannel.invokeMethod('connectAsServer');
  }

  @override
  Future<void> serverStop() async {
    await methodChannel.invokeMethod('serverStop');
  }

  @override
  Future<void> disconnect() async {
    await methodChannel.invokeMethod('disconnect');
  }

  @override
  Future<void> sendData(Uint8List data) async {
    await methodChannel.invokeMethod('sendData', {'data': data});
  }

  @override
  Future<void> serverSendData(Uint8List data) async {
    await methodChannel.invokeMethod('serverSendData', {'data': data});
  }

}
