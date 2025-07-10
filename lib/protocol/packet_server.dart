import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../model/connect_state.dart';
import '../model/packet.dart';
import '../platform/spp_helper.dart';
import 'base_server.dart';
import 'factory_image_packet.dart';

class PacketServer with BaseServer {
  /// Singleton instance of PacketServer
  static PacketServer? _instance;
  static PacketServer get() {
    _instance ??= PacketServer._internal();
    return _instance!;
  }

  Stream<ServerConnectState> connectStateStream = SppHelper.get().serverConnectStateStream;
  final packets = <List<int>>[];

  /// Timer to control the sending of packets
  Timer? packetTimer;

  PacketServer._internal(){
    packetTimer = Timer.periodic(Duration(milliseconds: packetInterval), (timer) {
      if (packets.isNotEmpty) {
        final packet = packets.removeAt(0);
        // Here you would send the packet to the client
        // For example, using a method like sendPacket(packet);
        sendData(packet);
        print('Sending packet: ${packet.length} bytes');
      }
    });

    // Listen for incoming data
    SppHelper.get().serverReceivedDataStream.listen((data) {
      print('Received data: ${data.length} bytes');
      handleReceivedData(data);
    });
  }

  static const List<int> header = [0xAA, 0x55];
  static const int headerLength = 2;
  static const int metaLength = 1 + 2 + 2; // type + index + length
  static const int checksumLength = 2;

  // Data streams
  Stream<Uint8List> dataStream = SppHelper.get().serverReceivedDataStream;

  final Map<int, String> fileIdMap = {};
  int? totalSize;
  int? totalChunks;
  String postfix = '';
  bool isEndReceived = false;
  Uint8List incompleteBuffer = Uint8List(0);

  // Send internal asset file
  @override
  Future<void> sendAsset(String assetPath) async{

    var id = genId();
    var factory = await ImagePacketFactory.fromAsset(id, assetPath);
    packets.addAll(factory.getPackets());
    fileIdMap[id] = assetPath;
  }

  // Send file in the storage
  @override
  Future<void> sendFile(file) async{
    var id = genId();
    var factory = await ImagePacketFactory.fromFile(id, file);
    packets.addAll(factory.getPackets());
    fileIdMap[id] = file.path;
  }

  @override
  Future<void> sendBytes(List<int> data) async{
    var id = genId();
    var factory = await ImagePacketFactory.fromBytes(id, data, 'jpg');
    packets.addAll(factory.getPackets());
    fileIdMap[id] = '';
  }

  void handleReceivedData(Uint8List data) async{
    // 處理重傳請求
    final type = data[2];
    final fileId = (data[3] << 8) | data[4];
    final index = (data[5] << 8) | data[6];

    if (type == packetTypeToByte(PacketType.resendReq)) {
      print('🔄 Resend request for index $index');
      var file = fileIdMap[fileId]; // 儲存檔案ID與名稱的對應關係
      if(file == null) return;
      var isAsset = file.startsWith('assets/');
      var factory = isAsset
          ? await ImagePacketFactory.fromAsset(fileId, file)
          : await ImagePacketFactory.fromFile(fileId, File(file));

      // 重新發送指定索引的封包
      var packets = factory.getPackets();
      if (index < packets.length) {
        final resendPacket = packets[index];
        // 這裡可以添加發送邏輯，例如通過通道發送
        SppHelper.get().sendData(resendPacket);
      } else {
        print('❌ Invalid resend request for index $index');
      }

    } else {
      print('⚠️ Unknown resend request type: $type');
    }
  }



  void disconnect(){
    SppHelper.get().serverStop();
    isEndReceived = false;
    totalSize = null;
    totalChunks = null;
    postfix = '';
    incompleteBuffer = Uint8List(0);
  }

  sendData(List<int> packet) {
    if (packet.isEmpty) return;
    SppHelper.get().serverSendData(packet);
  }
}
