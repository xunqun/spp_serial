
import 'dart:async';
import 'dart:typed_data';


import '../model/connect_state.dart';

mixin BaseHelper {
  // static const platform = MethodChannel('channel.whiles.app/bluetooth');
  StreamController<List<Map<String, String?>>> scanResultsController = StreamController<List<Map<String, String?>>>.broadcast();
  Stream<List<Map<String, String?>>> get scanResultsStream => scanResultsController.stream;

  StreamController<bool> scanStateController = StreamController<bool>.broadcast();
  Stream<bool> get scanStateStream => scanStateController.stream;

  StreamController<ClientConnectState> clientConnectStateController = StreamController<ClientConnectState>.broadcast();
  Stream<ClientConnectState> get clientConnectStateStream => clientConnectStateController.stream;

  StreamController<ServerConnectState> serverConnectStateController = StreamController<ServerConnectState>.broadcast();
  Stream<ServerConnectState> get serverConnectStateStream => serverConnectStateController.stream;

  StreamController<Uint8List> serverReceivedDataController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get serverReceivedDataStream => serverReceivedDataController.stream;

  StreamController<Uint8List> clientReceivedDataController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get clientReceivedDataStream => clientReceivedDataController.stream;

  Future<void> scan();
  Future<void> stopScan();
  Future<void> connectAsClient(String deviceId);
  Future<void> connectAsServer(bool discoverable);
  Future<void> serverStop();
  Future<void> sendData(Uint8List data);
  Future<void> serverSendData(Uint8List data);
  Future<void> clientDisconnect();
}