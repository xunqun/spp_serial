import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:spp_serial/model/connect_state.dart';
import 'package:spp_serial/model/packet.dart';
import 'package:spp_serial/protocol/factory_client_packet.dart';
import 'package:spp_serial/protocol/packet_client.dart';
import 'package:spp_serial/protocol/packet_server.dart';
import 'package:wakelock_plus/wakelock_plus.dart';


class ConnectedClientScreen extends StatefulWidget {
  const ConnectedClientScreen({super.key});

  @override
  State<ConnectedClientScreen> createState() => _ConnectedClientScreenState();
}

class _ConnectedClientScreenState extends State<ConnectedClientScreen> {
  late StreamSubscription? _dataSub;
  late StreamSubscription? _connSub;
  PacketServer dataReceiver = PacketServer.get();
  Image? image;

  @override
  void initState() {
    WakelockPlus.enable();
    super.initState();
    dataReceiver.onComplete = (data) {
      setState(() {
        image = Image.memory(data);
      });
    };
    _dataSub = PacketClient.get().dataStream.listen((data){
      dataReceiver.handleIncomingPacket(data, (packets) async {
        // send RESENT packet to client\
        // for(int i = 0; i < packets.length; i++){
        //   Channel.get().serverSendData(packets[i]);
        //   await Future.delayed(Duration(milliseconds: 20));
        // }
      });
    });
    _connSub = PacketClient.get().connectStateStream.listen((state) {
        if (state == ClientConnectState.IDLE) {
          // Server started successfully
          if(mounted) {
            Navigator.pop(context);
          }
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    PacketClient.get().disconnect();
    _dataSub?.cancel();
    _connSub?.cancel();
    super.dispose();


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              StreamBuilder(
                  stream: PacketClient.get().dataStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Uint8List? data = snapshot.data;
                      String dataString = String.fromCharCodes(data!).trim();
                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: Text(
                          dataString,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    } else {
                      return SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: const Text(
                          'Waiting for data from client...',
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    }
                  }),
              if(image != null)
                SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: image!,
                ),
            ],
          ),
        ),
      ),
    );
  }


}
