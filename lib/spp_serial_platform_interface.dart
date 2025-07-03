import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'spp_serial_method_channel.dart';

abstract class SppSerialPlatform extends PlatformInterface {
  /// Constructs a SppSerialPlatform.
  SppSerialPlatform() : super(token: _token);

  static final Object _token = Object();

  static SppSerialPlatform _instance = MethodChannelSppSerial();

  /// The default instance of [SppSerialPlatform] to use.
  ///
  /// Defaults to [MethodChannelSppSerial].
  static SppSerialPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SppSerialPlatform] when
  /// they register themselves.
  static set instance(SppSerialPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  setMethodCallHandler(Future<dynamic>  Function(MethodCall call)? handler) {
    throw UnimplementedError('setMethodCallHandler() has not been implemented.');
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<void> scan() {
    throw UnimplementedError('scan() has not been implemented.');
  }

  Future<void> stopScan() {
    throw UnimplementedError('stopScan() has not been implemented.');
  }

  Future<void> connectAsClient(String deviceId) {
    throw UnimplementedError('connectAsClient() has not been implemented.');
  }

  Future<void> connectAsServer() {
    throw UnimplementedError('connectAsServer() has not been implemented.');
  }

  Future<void> serverStop() {
    throw UnimplementedError('serverStop() has not been implemented.');
  }

  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  Future<void> sendData(Uint8List data) {
    throw UnimplementedError('sendData() has not been implemented.');
  }

  Future<void> serverSendData(Uint8List data) {
    throw UnimplementedError('serverSendData() has not been implemented.');
  }
}
